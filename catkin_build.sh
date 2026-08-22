#!/bin/bash

# Ensure script exits on error
set -e

# Get the directory of this script to run commands from the project root
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Parse arguments: extract --update and keep all other arguments for catkin build
UPDATE=false
CATKIN_ARGS=()

for arg in "$@"; do
    if [ "$arg" = "--update" ]; then
        UPDATE=true
    else
        CATKIN_ARGS+=("$arg")
    fi
done

CONTAINER_NAME="ubuntu_desktop"

# Check if the container is running
if [ ! "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    echo "错误: 容器 ${CONTAINER_NAME} 未运行，请先启动容器。"
    exit 1
fi

# If --update is specified, update/clone the git repositories first
if [ "$UPDATE" = true ]; then
    # Parse the YAML file using Python standard library
    REPOS_DATA=$(python3 -c '
import sys

repos = []
current_repo = {}
with open("config/repos.yaml", "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        # Skip empty lines and comments
        if not line or line.startswith("#"):
            continue
        if line.startswith("- url:") or line.startswith("url:"):
            if current_repo:
                repos.append(current_repo)
                current_repo = {}
            val = line.split(":", 1)[1].strip().strip("\"").strip("\x27")
            current_repo["url"] = val
        elif line.startswith("branch:"):
            val = line.split(":", 1)[1].strip().strip("\"").strip("\x27")
            current_repo["branch"] = val

if current_repo:
    repos.append(current_repo)

for r in repos:
    url = r.get("url", "")
    branch = r.get("branch", "")
    if url:
        print(f"{url}|{branch}")
')

    if [ -z "$REPOS_DATA" ]; then
        echo "未配置任何 Git 仓库，或者 repos.yaml 解析为空。跳过更新步骤。"
    else
        echo "开始在容器中拉取/更新代码..."
        # 确保 src 目录存在
        docker exec -u ubuntu "$CONTAINER_NAME" mkdir -p /home/ubuntu/catkin_ws/src < /dev/null

        echo "$REPOS_DATA" | while IFS='|' read -r URL BRANCH; do
            REPO_NAME=$(basename "$URL" .git)
            CONTAINER_SRC_DIR="/home/ubuntu/catkin_ws/src"
            
            echo "--------------------------------------------------"
            echo "正在处理仓库: $REPO_NAME"
            echo "地址: $URL"
            echo "分支: ${BRANCH:-(默认分支)}"
            
            # Check if the directory already exists in the container
            if docker exec -u ubuntu "$CONTAINER_NAME" [ -d "${CONTAINER_SRC_DIR}/${REPO_NAME}" ] < /dev/null; then
                echo "项目已存在，正在拉取更新..."
                if [ -n "$BRANCH" ]; then
                    docker exec -u ubuntu "$CONTAINER_NAME" bash -i -c "cd ${CONTAINER_SRC_DIR}/${REPO_NAME} && git fetch origin && git checkout ${BRANCH} && git pull origin ${BRANCH}" < /dev/null
                else
                    docker exec -u ubuntu "$CONTAINER_NAME" bash -i -c "cd ${CONTAINER_SRC_DIR}/${REPO_NAME} && git pull" < /dev/null
                fi
            else
                echo "项目不存在，正在进行克隆..."
                if [ -n "$BRANCH" ]; then
                    docker exec -u ubuntu "$CONTAINER_NAME" bash -i -c "cd ${CONTAINER_SRC_DIR} && git clone -b ${BRANCH} ${URL} ${REPO_NAME}" < /dev/null
                else
                    docker exec -u ubuntu "$CONTAINER_NAME" bash -i -c "cd ${CONTAINER_SRC_DIR} && git clone ${URL} ${REPO_NAME}" < /dev/null
                fi
            fi
        done
        echo "--------------------------------------------------"
        echo "所有仓库拉取/更新完成！"
    fi
fi

# Run catkin build with all passed arguments
echo "正在容器中开始编译 (catkin build ${CATKIN_ARGS[*]})..."
docker exec -u ubuntu "$CONTAINER_NAME" bash -i -c "cd /home/ubuntu/catkin_ws && catkin build ${CATKIN_ARGS[*]}" < /dev/null
echo "编译完成！"
