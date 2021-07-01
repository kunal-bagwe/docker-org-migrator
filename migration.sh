#!/bin/bash

# Constant values 
readonly URL=https://hub.docker.com
readonly VERSION=v2

# Default value for -ip/--include-private if arguement is skipped
visibility="false"
# default value for curl response
size_of_page=1000

# Fetch TOKEN from the DockerHub account
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${DOCKER_USERNAME}'", "password": "'${DOCKER_AUTH}'"}' ${URL}/${VERSION}/users/login/ | jq -r .token)

# Provide help to know the usage of script for execution
help_func()
{
  echo "
  ./org-repo-migrator.sh [OPTIONS] VALUE

  example (using short-args): 
  ./org-repo-migrator.sh -s=\",source-organization\" -d=\"destination-organization\" -sr=\"repo 1 repo 2 ..repo n\"

  example (using long-args):
  ./org-repo-migrator.sh -src=\",source-organization\" -dest=\"destination-organization\" --skip-repos=\"repo 1 repo 2 ..repo n\"

  Options:
  -s, --src               Name of the source organization from where the repository needs to be pulled for migration
  -d, --dest              Name of the destination organization where the repository needs to be migrated
  -sr, --skip-repos       List of repos to include for migration, if none is provided results in inclusion of all the repos
  -ip, --include-private  Include private repos (if true, private and public repos are migrated)
  "
  exit 0
}

# Get the commandline arguements for source, destination, repositories to skip, include public/private repos
for i in "$@"
do 
  case $i in
    -s=*|--src=*)
      src="${i#*=}"
      ;;
    -d=*|--dest=*)
      dest="${i#*=}"
      ;;
    -sr=*|--skip-repos=*)
      skip_repos="${i#*=}"
      ;;
    -ip=*|--include-private=*)
      visibility="${i#*=}"
      # Check value if empty, defaults to false
      if [[ ${visibility} = "" ]]; then
        visibility="false"
      fi
      ;;
  esac
    # take an argument and call help_func()
    option="${1}"
    case ${option} in 
      -h|--help)
        help_func
  esac
done

# Function to check whether the src and dest variables are null or either src or dest variable is null
checkEmpty()
{
  # Check whether src and dest are empty	
  if [[ "${src}" = "" ]] && [[ "${dest}" = "" ]]; then
    echo "
    -s/--src and -d/--dest cannot be left blank. Please follow below conditions:
 
    Use -h/--help to know more
    "
  # Check if src is empty
  elif [[ "${src}" = ""  ]]; then
    echo "-s/--src cannot be left blank, please provide a valid source organization name."
  # Check if dest is empty 
  elif [[ "${dest}" = "" ]]; then
    echo "-d/--dest cannot be left blank, please provide a valid destination organization name."
  fi
}

# Function to check value for the variables are alphanumeric
checkValue()
{
  # Check if src and dest are not as per alphanumeric pattern
  if [[ ! "${src}" =~ ^[[:alnum:]]+$ ]] && [[ ! "${dest}" =~ ^[[:alnum:]]+$  ]]; then
    echo "
    -s/--source and -d/--destination must be set to alphanumberic value
    example:
    -s/--src=\"example123\" -d/dest=\"example123\" "
  # Check whether source follows alphanumeric pattern
  elif [[ ! "${src}" =~ ^[[:alnum:]]+$  ]]; then
    echo "-s/--source must be alphanumeric"
  # Check whether dest follows alphanumeric pattern 
  elif [[ ! "${dest}" =~ ^[[:alnum:]]+$ ]]; then
    echo "-d/--dest must be alphanumeric"
  fi
}
# Function to fetch the list of repositories in a page
fetchRepos(){
  # local  variables defined with alias names
  local url=${1}
  local ver=${2}
  local src=${3}
  local page_count=${4}
  local page_limit=${5}
  local nxt_repo=${6}
  local repo=${7}

  # Fetch the repositories in a single page
  res=$(curl -s -H "Authorization: JWT ${TOKEN}" "${url}/${ver}/repositories/${src}/?page=${page_count}&page_size=${page_limit}")
  # fetch the iteration required for pages
  local nxt=$(echo "${res}" | jq '.next')
  eval $nxt_repo="'$nxt'"
  # Fetch name and visibility of the source repository
  local result=$(echo "${res}" | jq '.results[]|"\(.name)=\(.is_private)"')
  eval $repo="'$result'"
}

#Function to fetch the list of tags in a page for a repository
fetchTags(){
  # local variables defined with alias names
  local url=${1}
  local ver=${2}
  local src=${3}
  local name=${4}
  local page_count=${5}
  local page_limit=${6}
  local new_tags=${7}
  local tags_list=${8}

  # Get the tags in a page              
  tags=$(curl -s -H "Authorization: JWT ${TOKEN}" "${url}/${ver}/repositories/${src}/${name}/tags/?page=${page_count}&page_size=${page_limit}")
  # Check whether the response has the next parameter set
  local tag_next=$(echo "${tags}" | jq '.next')
  eval $new_tags="'$tag_next'"
  # Get the name of the tags for a repositories
  local image_tags=$(echo "${tags}" | jq -r '.results|.[]|.name')
  eval $tags_list="'$image_tags'"
}

# Function to pull repository from src organization
pullRepos(){
  # local variables defined with alias names
  local src_org=${1}
  local src_repo=${2}
  local repo_tag=${3}

  echo "Pulling ${src_repo}:${repo_tag} from source ${src_org} organization"
  # Pulling repository from the source organzation    
  docker pull "${src_org}"/"${src_repo}":"${repo_tag}" > /dev/null
  echo "Pull ${src_repo}:${repo_tag} successful" 
}

# Function to tag repository 
tagRepos(){
  # local variables defined with alias names
  local src=${1}
  local repo_name=${2}
  local tag_ver=${3}
  local dest=${4}  

  echo "Tagging the repository from ${src}/${repo_name}:${tag_ver} to ${dest}/${repo_name}:${tag_ver}"
  # Tagging a repository with tag to to destination org with tag
  docker tag "${src}"/"${repo_name}":"${tag_ver}" "${dest}"/"${repo_name}":"${tag_ver}" > /dev/null
  echo "Tagging to ${dest}/${repo_name}:${tag_ver} successful"
}

# Function to push repository to destination organization
pushRepos(){
  # local variables defined with alias names
  local dest=${1}
  local repo_name=${2}
  local tag_ver=${3}

  echo "Pushing to ${dest}  organization the ${repo_name}:${tag_ver}  repository"
  # Pushing the repository to destination org with specific tag
  docker push "${dest}"/"${repo_name}":"${tag_ver}" > /dev/null
  echo "Push successful for ${dest}/${repo_name}:${tag_ver}"
}

# Initializing function when script execution starts
main()
{
  # Check if src or dest variable is empty and call checkEmpty() function for further checks
  if [[ "${src}" = ""  ]] || [[ "${dest}" = "" ]]; then
    checkEmpty
    exit 1
  # Check src or dest variable is alphanumeric and call checkValue() function for further checks
  elif [[ ! "${src}" =~ ^[[:alnum:]]+$ ]] || [[ ! "${dest}" =~ ^[[:alnum:]]+$ ]]; then
    checkValue
    exit 1
  fi
  # Loop to iterate on the number of repositories in every page
  for (( repo_page=1;;repo_page++ ));
  do
    # Function to fetch the repositories in every page
    fetchRepos "${URL}" "${VERSION}" "${src}" "${repo_page}" "${size_of_page}" list_of_repos repo_names
    # Loop over the number of repositories in source organization 
    for i  in $repo_names
    do
      # Fetch the name of the repository
      name=$(echo ${i} | sed -e 's/\"//g' -e 's/=.*//')
      # If condition to check whether the repository is to be skipped
      if [[ ! "${skip_repos[@]}" =~ "${name}" ]]; then
        # Fetch the repository privacy whether public/private repository    
        repo_visibility=$(echo $i | sed -e 's/\"//g' -e 's/.*=//g')
        # Fetch the image tags for the repos
        for (( tag_page=1;;tag_page++ ));
        do
          # Fetch the tags for the repository
	  fetchTags "${URL}" "${VERSION}" "${src}" "${name}" "${tag_page}" "${size_of_page}" list_of_tags tags
          # Loop to fetch a tag from source org repos and apply to the destination org repos
	  for tag in $tags
          do
            if [[ "${visibility}" = "false"  ]]; then
              # Check whether the repo is public/private repository	    
              if [[ "${repo_visibility}" = "${visibility}" ]]; then	    
                # Function to pull a repository from source organization
                pullRepos ${src} ${name} ${tag}
	        # Function to tag repository from source organization to destination organization
                tagRepos ${src} ${name} ${tag} ${dest}
	        # Function to push repository to destination organization
                pushRepos ${dest} ${name} ${tag}
              fi
	    else
              if [[ "${repo_visibility}" = "true" || "${repo_visibility}" = "false" ]]; then
                # Function to pull a repository from source organization
	        pullRepos ${src} ${name} ${tag}
	        # Function to tag repository from source organization to destination organization
	        tagRepos ${src} ${name} ${tag} ${dest}
	        # Function to push repository to destination organization
	        pushRepos ${dest} ${name} ${tag}
	      fi  
	    fi   
          done
	  # Check if the tag_next is null or not for tags
	  if [[ ! $list_of_tags = "null" ]]; then 
            # If the tag_next is not null continue looping
            continue
	  else
            # Stop execution if there are no further tags for the repostiory to fetch		    
	    break
	  fi
	done
      else
        # Skip current repository as added in skip_repos variable
        continue
      fi
    done
    # Check if the nxt is null or not for repositories
    if [[ ! $list_of_repos = "null" ]]; then
      # if variable nxt is not null continue looping  
      continue
    else
      # Stop execution if there are no further repositories to fetch
      break
    fi
  done
}

# Start execution
main
