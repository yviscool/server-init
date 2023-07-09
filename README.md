# server-init


# 服务器初始化脚本 - Server Initialization Script

这是一个用于服务器初始化的Bash脚本，它可以自动化安装和配置各种工具和软件，方便快捷地进行服务器端的运维工作。该脚本包含了安装和配置包管理器、Docker及相关工具、Oh-My-Zsh等功能，并提供了简单明了的中文注释，使脚本更加易于理解和使用。

This is a Bash script for server initialization that automates the installation and configuration of various tools and software, making server administration tasks easier and more efficient. The script includes features such as installing and configuring package managers, Docker and related tools, Oh-My-Zsh, etc. It also provides clear and concise comments in Chinese for better understanding and usage.

## 功能特点 - Features

- 自动识别系统中的包管理器，并设置默认的包管理器 - Automatically detects the package manager in the system and sets the default one.
- 更新系统软件包 - Updates system packages.
- 安装和配置常用工具，如Git、Zsh、JQ等 - Installs and configures common tools such as Git, Zsh, JQ, etc.
- 配置Git全局设置 - Configures global settings for Git.
- 安装和配置Node.js版本管理器（NVS）- Installs and configures the Node.js version manager (NVS).
- 安装最新的LTS版本和最新版本的Node.js，并设置默认版本 - Installs the latest LTS and latest versions of Node.js and sets the default version.
- 安装和配置Docker及相关工具，包括Docker Compose - Installs and configures Docker and related tools, including Docker Compose.
- 配置Docker Compose文件，包括映射目录和端口设置 - Configures Docker Compose files, including directory mapping and port settings.
- 启动Docker Compose服务 - Starts Docker Compose services.
- 安装和配置Oh-My-Zsh，并设置Zsh为默认Shell - Installs and configures Oh-My-Zsh and sets Zsh as the default shell.
- 安装自动补全和语法高亮插件 - Installs auto-completion and syntax highlighting plugins.
- 提供简单明了的中文注释，方便理解和修改脚本 - Provides clear and concise comments in Chinese for easy understanding and script modification.

## 使用方法 - Usage

服务器初始化的安装脚本
```bash
$ curl -o- https://raw.githubusercontent.com/yviscool/server-init/master/install.sh | bash
```
or 

1. 在服务器上创建一个新的Bash脚本文件，例如`init_server.sh`。
   Create a new Bash script file on your server, e.g., `init_server.sh`.
2. 将服务器初始化脚本的内容复制到`init_server.sh`文件中。
   Copy the contents of the server initialization script into `init_server.sh`.
3. 执行以下命令使脚本文件可执行：
   Run the following command to make the script file executable:
   chmod +x init_server.sh
4. 运行脚本文件：
   Run the script file:
   ./init_server.sh
脚本将自动运行，并按照注释和说明进行安装和配置。
The script will run automatically and perform the installation and configuration according to the comments and instructions.

> 注意：在运行脚本之前，请确保具备足够的权限以安装和配置软件，并且仔细阅读脚本中的注释和说明。
> Note: Before running the script, make sure you have sufficient permissions to install and configure software, and carefully read the comments and instructions in the script.

## 注意事项 - Notes

- 请注意，此脚本仅作为参考和示例，您可以根据自己的需求进行修改和定制。
Please note that this script is for reference and demonstration purposes only. You can modify and customize it according to your own needs.
- 在运行脚本之前，请确保已经备份了重要的数据，并理解脚本中的每个操作。
Before running the script, ensure that you have backed up important data and understand each operation in the script.
- 脚本中的安装和配置命令可能会因操作系统或软件版本的差异而有所不同，请根据实际情况进行调整。
The installation and configuration commands in the script may vary depending on the operating system and software versions. Please adjust them accordingly based on your specific environment.

