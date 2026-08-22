#!/bin/bash

# Ensure script exits on error
set -e

# Get the directory of this script to run commands from the project root
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# 自动检测运行环境是否为 WSL 或 Docker Desktop
if grep -qi -E "microsoft|wsl" /proc/version 2>/dev/null || uname -r | grep -qi -E "microsoft|wsl"; then
    echo "检测到 WSL / Docker Desktop 环境，使用桥接网络启动..."
    docker compose -f docker-compose.yml -f docker-compose.wsl.yml up -d
else
    echo "检测到原生 Linux 环境，使用 Host 网络模式启动..."
    docker compose -f docker-compose.yml -f docker-compose.linux.yml up -d
fi

echo "容器启动成功！"
