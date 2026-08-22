#!/bin/bash
set -e

# 动态修改 /entrypoint.sh 中的 VNC 端口（支持通过 VNC_PORT 环境变量控制，默认为 6080）
if [ -f "/entrypoint.sh" ]; then
    echo "* Patching VNC port in /entrypoint.sh to support VNC_PORT (default: 6080)"
    sed -i 's|websockify --web=/usr/lib/novnc 80|websockify --web=/usr/lib/novnc ${VNC_PORT:-6080}|g' /entrypoint.sh
fi

# 创建 /home/ubuntu 目录以防尚未创建
mkdir -p /home/ubuntu

# 如果 /home/ubuntu/.bashrc 还不存在，从 /etc/skel 拷贝一个默认配置以防 skipped
UBUNTU_BASHRC="/home/ubuntu/.bashrc"
if [ ! -f "$UBUNTU_BASHRC" ]; then
    echo "* Initializing $UBUNTU_BASHRC from /etc/skel/.bashrc"
    cp /etc/skel/.bashrc "$UBUNTU_BASHRC"
fi

# 将 my_bashrc 的内容拼接到 ubuntu 的 .bashrc 之后（防止重复拼接，并确保它在 ROS setup 之后执行）
MY_BASHRC="/etc/my_bashrc"
MARKER="# >>> custom bashrc configuration <<<"

if [ -f "$MY_BASHRC" ] && [ -f "$UBUNTU_BASHRC" ]; then
    if ! grep -q "$MARKER" "$UBUNTU_BASHRC"; then
        echo "Appending ROS setup and $MY_BASHRC to $UBUNTU_BASHRC..."
        # 1. 先把 ROS 的环境载入指令写到 .bashrc 中，这样官方 entrypoint 检查时就不会再重复拼到最末尾了
        echo -e "\n# >>> ROS setup <<<" >> "$UBUNTU_BASHRC"
        echo 'source /opt/ros/${ROS_DISTRO}/setup.bash' >> "$UBUNTU_BASHRC"
        echo '# export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST' >> "$UBUNTU_BASHRC"
        
        # 2. 然后追加自定义的 my_bashrc 内容（这样您的自定义变量/别名就可以在 ROS 环境加载后执行，保证优先级最高）
        echo -e "\n$MARKER" >> "$UBUNTU_BASHRC"
        cat "$MY_BASHRC" >> "$UBUNTU_BASHRC"
        echo -e "\n# <<< end of custom configuration <<<" >> "$UBUNTU_BASHRC"
    fi
fi

# 强制将挂载的各个目录和脚本所有权交给 UID 1000 (即即将创建的 ubuntu 用户)
# 使用 1000:1000 避免在用户创建前运行 chown 导致 "invalid user: ubuntu:ubuntu" 报错
for path in "/home/ubuntu" "$UBUNTU_BASHRC" "/home/ubuntu/.config/autostart" "/home/ubuntu/catkin_ws" "/home/ubuntu/setup_env" "/home/ubuntu/setup_env.sh"; do
    if [ -e "$path" ]; then
        echo "* Setting ownership of $path to 1000:1000"
        chown -R 1000:1000 "$path"
    fi
done

# 执行原镜像自带的 /entrypoint.sh 脚本，并传递所有参数
exec /entrypoint.sh "$@"
