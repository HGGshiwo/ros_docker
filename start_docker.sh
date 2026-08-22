#!/bin/bash

# Get the directory of this script to run commands from the project root
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "正在使用 Docker Compose 停止容器..."
docker compose down
echo "容器停止成功！"

echo "正在使用 Docker Compose 启动容器..."
docker compose up -d
echo "容器启动成功！"
