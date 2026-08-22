#!/bin/bash

CONTAINER_NAME="ubuntu_desktop"

# Check if the container is running
if [ ! "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    echo "错误: 容器 ${CONTAINER_NAME} 未运行，请先启动容器。"
    exit 1
fi

# If no arguments are provided, open an interactive bash shell
if [ $# -eq 0 ]; then
    docker exec -it -u ubuntu "$CONTAINER_NAME" /bin/bash
else
    # If arguments are provided, execute them in an interactive bash shell (which automatically sources ~/.bashrc)
    docker exec -it -u ubuntu "$CONTAINER_NAME" bash -i -c '"$@"' bash "$@"
fi
