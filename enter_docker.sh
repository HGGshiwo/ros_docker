#!/bin/bash

# Get the directory of this script to run commands from the project root
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

CONTAINER_NAME="ubuntu_desktop"

# Check if the container is running
if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    echo "正在以 ubuntu 用户身份进入容器 ${CONTAINER_NAME}..."
    docker exec -it -u ubuntu "${CONTAINER_NAME}" /bin/bash
else
    echo "错误: 容器 ${CONTAINER_NAME} 未运行，请先运行 ./start_docker.sh 启动它。"
    exit 1
fi
