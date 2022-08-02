# elasticsearch-scripts
Bash scripts for Elasticsearch

## index-export

### What it does?
Export index stored in Elasticsearch deployed with Docker as files. You can bring them anywhere and restore them anytime you want!  

The steps it does:  

1. Check if the output folder exists, if so, check if there's any content in this folder, and if there's anything in it, the exporting process will be canceled.
2. Check if the snapshot repository is registered. If so, unregistered it.
3. Remove all contents in the folder that snapshot repository registered with. (by deleting and recreating the folder)
4. Register snapshot repository.
5. Create snapshot with index specified.
6. Unregister snapshot repository.
7. Copy all contents in the folder that snapshot repository registered with to output folder.

### Required options:
* `--index <index>, -i <index>`  
  Index that specified to be exported.

### Optional options:
* `--eshost <host>, -eh <host>`  
  Elasticsearch service host. Default: 127.0.0.1
* `--esport <port>, -ep <port>`  
  Elasticsearch service port. Default: 9200
* `--escontainer <container name>, -ec <continer name>`  
  Elasticsearch docker container name. Default: elasticsearch  
* `--repo <repository>, -r <repository>`  
  Snapshot repository name. Default: backup_repo
* `--snapshot <snapshot>, -s <snapshot>`  
  Snapshot name. Default: snapshot_{index}
* `--register-path <path>, -rp <path>`  
  Path of snapshot repository. Used for registering repository if repository doesn't exists. Default: /usr/share/elasticsearch/backup
* `--output <path>, -o <path>`  
  Output path. Default: backup_{index}
* `--from-step <step>, -f <step>`  
  Start from which step. Default: 1

### Sample Usage
```
./index-export --index index-2022.07.27
```

## index-import

### What it does?
Import index to the Elasticsearch deployed with Docker.  

The steps it does:  

1. Check if the index has already existed. If so, the importing process will be canceled.
2. Check if the snapshot repository is registered. If so, unregistered it.
3. Remove all contents in the folder that snapshot repository registered with. (by deleting and recreating the folder)
4. Copy all files from 'target' to the folder that snapshot repository registered with.
5. Modify the ownership of the folder that snapshot repository registered with, just in case the copy-paste will have a different ownership.
6. Register snapshot repository.
7. Check the snapshot is loaded.
8. Import with Restore API.

### Required options:
* `--repo <repository>, -r <repository>`  
  Snapshot repository name.
* `--snapshot <snapshot>, -s <snapshot>`  
  Snapshot name.
* `--target <path>, -t <path>`  
  Target path of backup folder.
* `--index <index>, -i <index>`  
  Index that specified to be imported.

### Optional options:
* `--eshost <host>, -eh <host>`  
  Elasticsearch service host. Default: 127.0.0.1
* `--esport <port>, -ep <port>`  
  Elasticsearch service port. Default: 9200
* `--escontainer <container name>, -ec <continer name>`  
  Elasticsearch docker container name. Default: elasticsearch
* `--register-path <path>, -rp <path>`  
  Path of snapshot repository. Used for registering repository if repository doesn't exists. Default: /usr/share/elasticsearch/backup
* `--from-step <step>, -f <step>`  
  Start from which step. Default: 1

### Sample Usage
```
./index-import --repo backup_repo --snapshot sys_snapshot --target ./backup_index-2022.07.27 --index index-2022.07.27
```
