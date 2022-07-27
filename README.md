# elasticsearch-scripts
Bash scripts for Elasticsearch

## index-export

### Required options:
* `--repo <repository>, -r <repository>`  
  Snapshot repository name.
* `--snapshot <snapshot>, -s <snapshot>`  
  Snapshot name.  

### Optional options:
* `--eshost <host>, -eh <host>`  
  Elasticsearch service host. Default: 127.0.0.1
* `--esport <port>, -ep <port>`  
  Elasticsearch service port. Default: 9200
* `--escontainer <container name>, -ec <continer name>`  
  Elasticsearch docker container name. Default: elasticsearch
* `--index <index>, -i <index>`  
  Index that specified to be exported. Defaultly export all indices.
* `--register-path <path>, -rp <path>`  
  Path of snapshot repository. Used for registering repository if repository doesn't exists. Default: /usr/share/elasticsearch/backup
* `--output <path>, -o <path>`  
  Output path. Defaultly use backup_{time} if index not specified, and use backup_{index} if index is specified.
* `--from-step <step>, -f <step>`  
  Start from which step. Default: 1

### Sample Usage
```
./index-export --repo backup_repo --snapshot sys_snapshot 
```

## index-import

### Required options:
* `--snapshot <snapshot>, -s <snapshot>`  
  Snapshot name.
* `--repo <repository>, -r <repository>`  
  Snapshot repository name.
* `--target <path>, -t <path>`  
  Target path of backup folder.

### Optional options:
* `--eshost <host>, -eh <host>`  
  Elasticsearch service host. Default: 127.0.0.1
* `--esport <port>, -ep <port>`  
  Elasticsearch service port. Default: 9200
* `--escontainer <container name>, -ec <continer name>`  
  Elasticsearch docker container name. Default: elasticsearch
* `--index <index>, -i <index>`  
  Index that specified to be imported. Defaultly import all indices.
* `--register-path <path>, -rp <path>`  
  Path of snapshot repository. Used for registering repository if repository doesn't exists. Default: /usr/share/elasticsearch/backup
* `--from-step <step>, -f <step>`  
  Start from which step. Default: 1

### Sample Usage
```
./index-import --repo backup_repo --snapshot sys_snapshot --target ./sys-backup-2022.07.27
```
