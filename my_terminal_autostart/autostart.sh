#!/bin/bash

# 定义启动终端的函数
# 参数 1: 窗口标题 (title)
# 参数 2: 要执行的命令 (cmd)
run_in_terminal() {
    local title="$1"
    local cmd="$2"
    echo ">> 正在启动终端 [ $title ] 执行命令: '$cmd'"
    # 自动使用 bash -i 开启交互终端，并在命令结束后通过 exec bash 保持窗口开启
    terminator --title="$title" -e "bash -i -c '$cmd; exec bash'" &
}

# 1. 等待 VNC 桌面环境初始化完毕
sleep 30

# 2. 启动主 launch (它会自动初始化并拉起 ROS Master)
#    MJPG_HOST / MJPG_PORT 由 start_docker.sh 通过 docker compose 注入
#    dji.launch 内部已 include rtsp_streams.launch, 不再单独启动 rtsp
run_in_terminal "dankong" "roslaunch dankong dji.launch mjpg_host:=${MJPG_HOST} mjpg_port:=${MJPG_PORT}"
