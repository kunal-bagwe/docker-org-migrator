# docker-org-migrator
## Usage
### Using Help Command:

<!-- Code Blocks -->
```bash
$ ./org-repo-migrator.sh -h

  ./org-repo-migrator.sh [OPTIONS] VALUE

  example (using short-args): 
  ./org-repo-migrator.sh -s=",source-organization" -d="destination-organization" -sr="repo 1 repo 2 ..repo n" -ip="true/false" 

  example (using long-args):
  ./org-repo-migrator.sh -src=",source-organization" -dest="destination-organization" --skip-repos="repo 1 repo 2 ..repo n" --include-private="true/false"


  Options:
  -s, --src               Name of the source organization from where the repository needs to be pulled for migration
  -d, --dest              Name of the destination organization where the repository needs to be migrated
  -sr, --skip-repos       List of repos to include for migration, if none is provided results in inclusion of all the repos
  -ip, --include-private  Include private repos (if true, private and public repos are migrated)
```

## Execution of script:

#### Fetch token 
  Export below environment variables to fetch token:

```bash  
  export DOCKER_USERNAME="<dockerhub-username>"
```
```bash
  export DOCKER_AUTH="<dockerhub-password>"
```
  or
```bash
  export DOCKER_AUTH="<dockerhub-access-token>"
```
####  Instead of Password, Personal Access Token can also be used for DOCKER_AUTH variable
#### with short options

./org-repo-migrator.sh -s="" -d="" -sr="" -ip="<true/false>"
```bash
$ ./org-repo-migrator.sh -s="<source-org>" -d="<destination-org>" -sr="<repo names to skip>" -ip="<true/false>"
```
#### with long options

./org-repo-migrator.sh --src="" --dest="" --skip-repos="" --include-private="<true/false>"
``` bash
$ ./org-repo-migrator.sh --src="<source-org>" --dest="<destination-org>" --skip-repos="<repo names to skip>" --include-private="false"
```
## Parameters

-s/--src = DockerHub source organization from where the repositories are to be migrated <br/>
-d/--dest = DockerHub destination organization where the repositories are migrated <br/>
-sr/--skip-repos = List of repo names given in "", to skip for migration <br/>
-ip/--include-private = (optional) if set true, private repos will also be migrated along with public repos <br/>

**Note**: -ip/--include-private is an Optional Parameter, if not included defaults to "false", if included and left "" will result in "false"

``` bash
$ ./org-repo-migrator.sh -s/--src="<source-org"  -d/--dest="<destination-org>" -sr/--skip-repos="<repo names to skip>"  
```
``` bash
$ ./org-repo-migrator.sh -s/--src="<source-org"  -d/--dest="<destination-org>" -sr/--skip-repos="<repo names to skip>" -ip/--include-private=""
```

### example:
```bash
$ ./org-repo-migrator.sh -s/--src="source-org" -d/--dest="remote-org" --skip-repos="repo 1 repo 2 ..repo n" --include-private="false"
```
_--skip-repos_ can be skipped to include all the repositories
