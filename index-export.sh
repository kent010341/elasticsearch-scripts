#!/bin/bash

# default value
es_host=127.0.0.1
es_port=9200
repo=backup_repo
es_container=elasticsearch
register_path="/usr/share/elasticsearch/backup"
from_step=1

is_eh_set=false
is_ep_set=false
is_ec_set=false

while (($#)); do
  case $1 in
    "--eshost" | "-eh")
      shift
      es_host=$1
      is_eh_set=true
      shift
    ;;
    "--esport" | "-ep")
      shift
      es_port=$1
      is_ep_set=true
      shift
    ;;
    "--escontainer" | "-ec")
      shift
      es_container=$1
      is_ec_set=true
      shift
    ;;
    "--index" | "-i")
      shift
      index=$1
      shift
    ;;
    "--repo" | "-r")
      shift
      repo=$1
      shift
    ;;
    "--snapshot" | "-s")
      shift
      snapshot=$1
      shift
    ;;
    "--register-path" | "-rp")
      shift
      register_path=$1
      shift
    ;;
    "--output" | "-o")
      shift
      output=$1
      shift
    ;;
    "--from-step" | "-f")
      shift
      from_step=$1
      shift
    ;;
    "--help" | "-h")
      echo "Required options:"
      echo "    --index <index>, -i <index>"
      echo "        Index that specified to be exported."
      echo 
      echo "Optional options:"
      echo "    --eshost <host>, -eh <host>"
      echo "        Elasticsearch service host. Default: 127.0.0.1"
      echo "    --esport <port>, -ep <port>"
      echo "        Elasticsearch service port. Default: 9200"
      echo "    --escontainer <container name>, -ec <continer name>"
      echo "        Elasticsearch docker container name. Default: elasticsearch"
      echo "    --repo <repository>, -r <repository>"
      echo "        Snapshot repository name. Default: backup_repo"
      echo "    --snapshot <snapshot>, -s <snapshot>"
      echo "        Snapshot name. Default: snapshot_{index}"
      echo "    --register-path <path>, -rp <path>"
      echo "        Path of snapshot repository. Used for registering repository if repository doesn't exists. Default: /usr/share/elasticsearch/backup"
      echo "    --output <path>, -o <path>"
      echo "        Output path. Default: backup_{index}"
      echo "    --from-step <step>, -f <step>"
      echo "        Start from which step. Default: 1"
      exit 0
    ;;
    *)
      echo "unknown argument '$1'"
      echo "Use --help (or -h) to get the usage information."
      exit 1
  esac
done

if [ -z "$index" ]; then
  echo "--index is required."
  exit 1
fi

if [ -z "$snapshot" ]; then    
  snapshot="snapshot_$index"
fi

if [ -z "$output" ]; then
  output="backup_$index"
fi

# checking docker container using elasticsearch image
if [ $from_step -le 1 ]; then
  if $is_ec_set && $is_eh_set && $is_ep_set; then
    echo "[Step 1] Container name, host, port are specified. Skip step 1."
  else
    echo "[Step 1] Checking running Elasticsearch container."

    image_list=$(docker ps --format "{{.Image}}")
    es_count=$(echo $image_list | grep "elasticsearch" | wc -l)
    
    if [ $es_count -gt 1 ]; then
      echo "[Step 1] Warning! You have more than 1 running container using image contains string 'elasticsearch'!"
      echo "[Step 1] Use values: container name: '$es_container', host: $es_host, port: $es_port"
    elif [ $es_count -eq 0 ]; then
      echo "[Step 1] Warning! You don't have any running container using image contains string 'elasticsearch'!"
      echo "[Step 1] Use values: container name: '$es_container', host: $es_host, port: $es_port"
    else
      es_image=$(docker ps --format "{{.Names}} {{.Ports}} {{.Image}}" | grep "elasticsearch")
      if ! $is_ec_set; then
        es_container=$(echo $es_image | cut -d" " -f 1)
      fi
      es_network=$(echo $es_image | cut -d" " -f 2 | cut -d"-" -f 1)
      
      if ! $is_eh_set; then
        es_host=$(echo $es_network | cut -d":" -f 1)
      fi

      if ! $is_ep_set; then
        es_port=$(echo $es_network | cut -d":" -f 2)
      fi

      echo "[Step 1] Found 1 running Elasticsearch container. Container name: '$es_container', host: $es_host, port: $es_port"
    fi
  fi
fi

# check if output folder has contents
if [ $from_step -le 2 ]; then
  echo "[Step 2] Check if folder '$output' exists."
  if [ -d $output ]; then
    echo "[Step 2] Folder '$output' exists."
    echo "[Step 2] Check if the folder '$output' has contents."
    if [ -z "$(ls -A $output)" ]; then
      echo "[Step 2] Folder '$output' has no content."
    else
      echo "[Step 2] Folder '$output' has contents, stop exporting."
      echo "[Step 2] Change the output path to an non-existent folder or an empty folder."
      exit 1
    fi
  else
    echo "[Step 2] Folder '$output' doesn't exist."
  fi
fi

# remove existing repository
if [ $from_step -le 3 ]; then
  echo "[Step 3] Check if the repository '$repo' is registered."
  curl --silent --fail-with-body "http://$es_host:$es_port/_snapshot/$repo"

  if [ $? -eq 0 ]; then
    echo
    echo "[Step 3] Repository has already registered. Unregister it."
    curl -X DELETE --silent --fail-with-body "http://$es_host:$es_port/_snapshot/$repo"
    if [ $? -eq 0 ]; then
      echo
      echo "[Step 3] Unregister succeed."
    else
      echo
      echo "[Step 3] Unregister failed. You can retry from this step with option '--from-step 3'."
      exit 1
    fi
  else
    echo "[Step 3] Repository hasn't registered."
  fi
fi

# clean folder
if [ $from_step -le 4 ]; then
  echo "[Step 4] Remove snapshot files at snapshot repository."
  docker exec -i $es_container rm -rf "$register_path"

  if [ $? -eq 0 ]; then
    echo "[Step 4] Remove succeed."
  else
    echo "[Step 4] Remove failed.  You can retry from this step with option '--from-step 4'."
    exit 1
  fi

  docker exec -i $es_container mkdir "$register_path"
  docker exec -i $es_container chown -R elasticsearch:root "$register_path"

  if [ $? -ne 0 ]; then
    echo "[Step 4] Modify ownership failed. You can retry from this step with option '--from-step 4'."
    exit 1
  fi
fi

# checking repository register
if [ $from_step -le 5 ]; then
  echo "[Step 5] Register repository."
  curl --fail-with-body -X PUT "http://$es_host:$es_port/_snapshot/$repo" \
    -H "Content-Type: application/json" \
    -d "{\"type\":\"fs\",\"settings\":{\"location\":\"$register_path\"}}"
  
  if [ $? -eq 0 ]; then
    echo
    echo "[Step 5] Register succeed."
  else
    echo
    echo "[Step 5] Register failed. You can retry from this step with option '--from-step 5'."
    exit 1
  fi
fi

# creating snapshot
if [ $from_step -le 6 ]; then
  echo "[Step 6] Start creating snapshot with index '$index'"

  curl --fail-with-body -X PUT "http://$es_host:$es_port/_snapshot/$repo/$snapshot?wait_for_completion=true" \
    -H "Content-Type: application/json" \
    -d "{\"indices\":[\"$index\"]}"

  if [ $? -eq 0 ]; then
    echo
    echo "[Step 6] Creating snapshot succeed."
  else
    echo
    echo "[Step 6] Creating snapshot failed. You can retry from this step with option '--from-step 6'."
    exit 1
  fi
fi

# unregister
if [ $from_step -le 7 ]; then
  echo "[Step 7] Unregister repository."
  curl --fail-with-body -X DELETE "http://$es_host:$es_port/_snapshot/$repo"

  if [ $? -ne 0 ]; then
    echo
    echo "[Step 7] Unregister failed. You can retry from this step with option '--from-step 7'."
    exit 1
  fi
fi

# Copy from docker container
if [ $from_step -le 8 ]; then
  echo
  echo "[Step 8] Copy folder '$register_path' from docker container '$es_container' to '$output'"
  docker cp $es_container:$register_path $output

  if [ $? -ne 0 ]; then
    echo "[Step 8] copied failed. You can retry from this step with option '--from-step 8'."
    exit 1
  fi
fi

echo
echo "Done!!"
echo "Repository name: $repo, Snapshot name: $snapshot, index: $index, output: $output"
