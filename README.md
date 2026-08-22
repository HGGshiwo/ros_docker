# ROS Noetic VNC Docker 开发环境

## 0. 构建容器

```bash
./build.sh zb1.0
```

本项目用于快速搭建带自启和自动代码拉取功能的 ROS Noetic VNC 容器环境。

## 1. 启动与进入容器

*   **启动容器**：
    ```bash
    ./start_docker.sh
    ```
*   **进入容器**：
    ```bash
    ./enter_docker.sh
    ```
*   **Web VNC 地址**：[http://localhost:6080](http://localhost:6080) (密码：`ubuntu`)

---

## 2. 配置环境变量

项目根目录下的 `config/my_bashrc` 配置文件允许您自定义终端环境变量、ROS 网络参数（修改并重启容器后生效）：
*   `ROS_IP`：容器本机的 IP 地址。
*   `ROS_MASTER_URI`：ROS Master 节点的连接地址。
*   您也可以在该文件中添加任意其它的自定义环境变量、别名 (alias) 或配置代理。

---

## 3. 配置自启动（在宿主机修改，重启容器生效）

*   **后台进程（如 ROS Launch）**：在 [my_supervisor_conf/](my_supervisor_conf/) 下新建 `.conf` 文件（参考 [my_service.conf.example](my_supervisor_conf/my_service.conf.example)）。
*   **桌面应用（如 RViz）**：在 [my_desktop_autostart/](my_desktop_autostart/) 下新建 `.desktop` 文件（参考 [my_gui.desktop.example](my_desktop_autostart/my_gui.desktop.example)）。

---

## 4. 编译与更新代码

项目提供了便捷的编译脚本 `./catkin_build.sh`，在宿主机上直接运行后，它会自动在容器内以 `ubuntu` 用户身份执行编译和更新操作，完美避免宿主机直接拉取带来的各种外部文件权限问题：

*   **仅执行编译**：
    ```bash
    ./catkin_build.sh [编译参数/指定包名]
    ```
    *例如：直接运行 `./catkin_build.sh` 编译全部包，或者运行 `./catkin_build.sh package_a --jobs 4` 仅编译 `package_a` 并限制 4 线程编译。*

*   **自动更新并执行编译**：
    ```bash
    ./catkin_build.sh --update [编译参数/指定包名]
    ```
    *加上 `--update` 参数时，脚本会首先自动解析 [config/repos.yaml](file:///home/hggshiwo/catkin_ws/ros_docker/config/repos.yaml) 中的配置克隆或更新 Git 仓库，更新完成后再执行对应的编译工作。*

---

## 5. 在容器中直接执行指令

如果您想在容器外直接对容器执行单条指令（比如 ROS 调试指令），且希望能**自动加载完整的 ROS 环境、工作空间环境及自定义 my_bashrc 配置**，可以使用 `./docker_bash.sh` 脚本：

*   **直接执行指令**：
    ```bash
    ./docker_bash.sh rostopic list
    ```
*   **进入容器交互终端**（如果不带任何参数）：
    ```bash
    ./docker_bash.sh
    ```
