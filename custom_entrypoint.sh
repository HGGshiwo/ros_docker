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
# 重新从模板创建 /home/ubuntu/.bashrc，确保环境干净且每次都是最新配置
echo "* Initializing clean $UBUNTU_BASHRC from /etc/skel/.bashrc"
cp /etc/skel/.bashrc "$UBUNTU_BASHRC"

# 将 ROS 环境和 my_bashrc 的加载写入 ubuntu 的 .bashrc 中（确保在 ROS setup 之后执行）
MY_BASHRC="/etc/my_bashrc"
MARKER="# >>> custom bashrc configuration <<<"

if [ -f "$MY_BASHRC" ] && [ -f "$UBUNTU_BASHRC" ]; then
    echo "Appending ROS setup and $MY_BASHRC to $UBUNTU_BASHRC..."
    # 1. 先把 ROS 的环境载入指令写到 .bashrc 中（这里使用双引号以展开 $ROS_DISTRO 变量，如 noetic，防止官方 entrypoint 重复拼接）
    echo -e "\n# >>> ROS setup <<<" >> "$UBUNTU_BASHRC"
    echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> "$UBUNTU_BASHRC"
    echo '# export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST' >> "$UBUNTU_BASHRC"
    
    # 2. 然后动态载入挂载的 my_bashrc（这样在宿主机修改 my_bashrc 就会即时生效，无需重建或重启容器）
    echo -e "\n$MARKER" >> "$UBUNTU_BASHRC"
    echo "source $MY_BASHRC" >> "$UBUNTU_BASHRC"
    echo -e "\n# <<< end of custom configuration <<<" >> "$UBUNTU_BASHRC"
fi

# 强制将挂载的各个目录和脚本所有权交给 UID 1000 (即即将创建的 ubuntu 用户)
# 使用 1000:1000 避免在用户创建前运行 chown 导致 "invalid user: ubuntu:ubuntu" 报错

# 1. 仅改变 /home/ubuntu 目录本身的权限，不进行递归（避免修改只读挂载文件如 .gitconfig 的所有权而报错）
if [ -d "/home/ubuntu" ]; then
    echo "* Setting ownership of /home/ubuntu to 1000:1000"
    chown 1000:1000 "/home/ubuntu"
fi

# 2. 递归地将其它挂载的子目录和可写文件所有权修改为 1000:1000
for path in "$UBUNTU_BASHRC" "/home/ubuntu/.config" "/home/ubuntu/catkin_ws" "/home/ubuntu/setup_env" "/home/ubuntu/setup_env.sh" "/home/ubuntu/my_terminal_autostart"; do
    if [ -e "$path" ]; then
        echo "* Setting ownership of $path to 1000:1000"
        chown -R 1000:1000 "$path"
    fi
done

# 执行原镜像自带的 /entrypoint.sh 脚本，并传递所有参数
exec /entrypoint.sh "$@"
