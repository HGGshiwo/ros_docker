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
sleep 3

# 2. 启动第一个 launch (它会自动初始化并拉起 ROS Master)
run_in_terminal "Bridge Mavlink Node" "roslaunch bridge_mavlink bridge_mavlink.launch"

# 3. 延时 5 秒，等待第一个 launch 把 ROS Master 彻底建立起来
sleep 5

# 4. 启动第二个 launch (它会直接接入上一步创建好的 Master)
run_in_terminal "Bridge Routes Node" "roslaunch bridge_routes bridge_routes.launch"