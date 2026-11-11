#!/bin/bash

# Ensure script exits on error
set -e

# 用法: ./start_docker.sh <MJPG_HOST> <实例号I>
# MJPG_HOST: 下视相机 MJPEG 拉流地址 (同时用于 FCU_URL)
# I: 实例号, 宿主机映射端口 = 基础端口 + I
MJPG_HOST="${1:?用法: ./start_docker.sh <MJPG_HOST> <实例号I>}"
I="${2:?用法: ./start_docker.sh <MJPG_HOST> <实例号I>}"

# 注入环境变量 (docker compose 引用)
export MJPG_HOST
export MJPG_PORT="${MJPG_PORT:-8090}"

# 宿主机映射端口 = 基础端口 + I
export WEB_PORT=$((6080 + I))     # noVNC web
export VNC_PORT=$((5901 + I))     # VNC 直连
export MQTT_PORT=$((41883 + I))   # mqtt
export HTTP_PORT=$((8000 + I))    # http 接口
export RTSP_PORT=$((8554 + I))    # rtsp

# Get the directory of this script to run commands from the project root
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# 自动检测运行环境是否为 WSL 或 Docker Desktop
if grep -qi -E "microsoft|wsl" /proc/version 2>/dev/null || uname -r | grep -qi -E "microsoft|wsl"; then
    echo "检测到 WSL / Docker Desktop 环境，使用桥接网络启动（映射端口 6080 和 5901）..."
    docker compose -f docker-compose.yml -f docker-compose.wsl.yml down
    docker compose -f docker-compose.yml -f docker-compose.wsl.yml up
else
    echo "检测到原生 Linux 环境，使用 Host 网络模式启动（直接绑定宿主机 6080 端口）..."
    docker compose -f docker-compose.yml -f docker-compose.linux.yml down
    docker compose -f docker-compose.yml -f docker-compose.linux.yml up
fi

echo "容器启动成功！"
