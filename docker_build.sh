#!/bin/bash

# Ensure script exits on error
set -e

# Get the directory of this script to run commands from the project root
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Get tag from argument or prompt
TAG="$1"
if [ -z "$TAG" ]; then
    read -p "请输入 Docker 镜像 tag (例如 zb1.0): " TAG
fi

if [ -z "$TAG" ]; then
    echo "错误: tag 不能为空！"
    exit 1
fi

# Validate tag format (letters, digits, underscores, periods, dashes)
if [[ ! "$TAG" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
    echo "错误: tag 格式不合法！仅支持字母、数字、下划线、点(.)和短横线(-)。"
    exit 1
fi

DOCKERFILE="Dockerfile.${TAG}"

if [ ! -f "$DOCKERFILE" ]; then
    echo "错误: 未找到对应的 Dockerfile: $DOCKERFILE"
    exit 1
fi

IMAGE_NAME="ros-desktop-vnc"
FULL_TAG="${IMAGE_NAME}:${TAG}"

BUILD_ARGS=()

# 定义需要传递的环境变量列表（通常主要是代理设置）
# 你可以根据需要在列表中添加你自己的自定义环境变量
VARS_TO_PASS=(
    "http_proxy" "https_proxy" "ftp_proxy" "no_proxy"
    "HTTP_PROXY" "HTTPS_PROXY" "FTP_PROXY" "NO_PROXY"
)

for var in "${VARS_TO_PASS[@]}"; do
    # ${!var} 是 bash 的间接变量引用，用于获取变量的值
    if [ -n "${!var}" ]; then
        BUILD_ARGS+=(--build-arg "$var")
        echo "检测到环境变量: $var=${!var}，将传递给 Docker"
    fi
done

# 如果有传入参数，才移除第一个参数 (TAG)，将剩余的所有参数传递给 docker build
if [ $# -gt 0 ]; then
    shift
fi

echo "开始构建 Docker 镜像: ${FULL_TAG}，使用文件: ${DOCKERFILE}，其它参数: $@..."
docker build "${BUILD_ARGS[@]}" "$@" -f "$DOCKERFILE" -t "$FULL_TAG" .

echo "构建成功"
