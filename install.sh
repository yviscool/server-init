#!/bin/bash
#
# Version : 2.1 (Complete & Refined)
# Date    : 2025-10-15
# Author  : YungVenuz
# Desc    : A robust, non-interactive initialization script for Debian-based systems,
#           optimized for users in China. Includes a full suite of development tools
#           and modern Rust-based CLI enhancements.
#

# ---
# 脚本核心设定 (Script Core Configuration)
# ---
# -e: 命令失败时立即退出
# -u: 变量未定义时立即退出
# -o pipefail: 管道中任意命令失败，整个管道视为失败
set -e -u -o pipefail

# ---
# 全局变量和常量 (Global Variables & Constants)
# ---

# 颜色定义
readonly NOCOLOR='\033[0m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[0;33m'
readonly FUCHSIA='\033[0;35m' # 紫红色

# 镜像源URL
readonly NVS_MIRROR_URL="https://gitee.com/lookenghua/nvs.git"
readonly OMZ_MIRROR_URL="https://gitee.com/mirrors/oh-my-zsh.git"
readonly OMZ_PLUGIN_AUTOSUGGESTIONS_URL="https://gitee.com/mirrors/zsh-autosuggestions.git"
readonly OMZ_PLUGIN_SYNTAX_HIGHLIGHTING_URL="https://gitee.com/mirrors/zsh-syntax-highlighting.git"

# ---
# 日志和工具函数 (Logging & Utility Functions)
# ---

log_info() {
    echo -e "${BLUE}INFO: $@${NOCOLOR}"
}

log_success() {
    echo -e "${GREEN}SUCCESS: $@${NOCOLOR}"
}

log_warning() {
    echo -e "${YELLOW}WARNING: $@${NOCOLOR}"
}

log_error() {
    echo -e "${RED}ERROR: $@${NOCOLOR}" >&2
    exit 1
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查并获取 root 权限
setup_sudo() {
    if [[ $EUID -ne 0 ]]; then
        if ! command_exists sudo; then
            log_error "此脚本需要 sudo 权限，但 sudo 未安装。请以 root 身份运行或安装 sudo。"
        fi
        SUDO='sudo'
        log_info "已检测到非 root 用户，将使用 'sudo' 执行需要权限的命令。"
    else
        SUDO=''
    fi
}

# ---
# 系统初始化 (System Initialization)
# ---

# 检查是否为 Debian 系
check_distro() {
    if ! command_exists apt-get; then
        log_error "此脚本仅适用于 Debian, Ubuntu, Deepin 等使用 apt 的发行版。"
    fi
    log_info "系统兼容性检查通过。"
}

# 更换为清华大学 APT 镜像源
setup_apt_mirror() {
    log_info "正在配置 APT 镜像源为清华大学镜像..."
    local CODENAME
    CODENAME=$(lsb_release -cs)
    local APT_SOURCE_FILE="/etc/apt/sources.list"
    local BACKUP_FILE="/etc/apt/sources.list.bak.$(date +%s)"
    
    if [[ "$CODENAME" == "stable" ]] && grep -q "deepin" /etc/os-release 2>/dev/null; then
        CODENAME="apricot"
        log_warning "检测到 Deepin stable 版本，代号自动设置为 'apricot'。"
    fi

    log_info "系统代号为: ${FUCHSIA}${CODENAME}${BLUE}"
    
    local TUNA_SOURCE_LIST="
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${CODENAME} main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ ${CODENAME} main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${CODENAME}-updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ ${CODENAME}-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${CODENAME}-backports main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ ${CODENAME}-backports main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security ${CODENAME}-security main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security ${CODENAME}-security main contrib non-free"

    ${SUDO} cp "${APT_SOURCE_FILE}" "${BACKUP_FILE}"
    log_info "原 ${APT_SOURCE_FILE} 已备份至 ${BACKUP_FILE}"

    echo "${TUNA_SOURCE_LIST}" | ${SUDO} tee "${APT_SOURCE_FILE}" > /dev/null
    
    log_info "正在更新软件包列表..."
    ${SUDO} apt-get update
    log_success "APT 镜像源配置完成。"
}

# 安装基础及现代命令行工具
install_base_tools() {
    log_info "正在安装基础开发与现代 CLI 工具..."
    local tools=(
        git zsh jq unzip tmux axel lrzsz glances curl wget build-essential openssl
        ripgrep bat tree
    )

    for tool in "${tools[@]}"; do
        if dpkg -s "${tool}" &> /dev/null; then
            log_info "软件包 ${FUCHSIA}${tool}${BLUE} 已安装，跳过。"
        else
            log_info "正在安装 ${FUCHSIA}${tool}${BLUE}..."
            ${SUDO} apt-get install -y "${tool}"
        fi
    done
    
    # 为 Debian/Ubuntu 上的 batcat 创建 bat 别名
    if command_exists batcat && ! command_exists bat; then
        log_info "为 'batcat' 创建 'bat' 符号链接..."
        ${SUDO} ln -sf /usr/bin/batcat /usr/local/bin/bat
    fi

    log_success "基础工具安装完成。"
}

# 安装需要特殊处理的现代工具
install_modern_cli_tools() {
    log_info "正在安装需要特殊配置的现代 CLI 工具 (gh, delta)..."

    # 安装 gh (GitHub CLI)
    if command_exists gh; then
        log_info "GitHub CLI (gh) 已安装，跳过。"
    else
        log_info "正在安装 GitHub CLI (gh)..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | ${SUDO} dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        ${SUDO} chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | ${SUDO} tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        ${SUDO} apt-get update
        ${SUDO} apt-get install -y gh
        log_success "GitHub CLI (gh) 安装成功。"
    fi

    # 安装 delta (git-delta)
    if command_exists delta; then
        log_info "git-delta 已安装，跳过。"
    else
        log_info "正在安装 git-delta..."
        local DELTA_VERSION
        DELTA_VERSION=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | jq -r .tag_name)
        if [ -z "$DELTA_VERSION" ] || [ "$DELTA_VERSION" == "null" ]; then
            log_warning "无法从 GitHub API 获取 delta 最新版本号，跳过安装。"
            return
        fi

        log_info "发现 delta 最新版本: ${FUCHSIA}${DELTA_VERSION}${BLUE}"
        local ARCH
        ARCH=$(dpkg --print-architecture)
        local DEB_URL="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_${ARCH}.deb"
        local DEB_PATH="/tmp/git-delta.deb"

        log_info "正在从 ${DEB_URL} 下载..."
        curl -L -o "${DEB_PATH}" "${DEB_URL}"

        log_info "正在使用 dpkg 安装..."
        ${SUDO} dpkg -i "${DEB_PATH}"
        ${SUDO} apt-get install -f -y # 修复任何可能的依赖问题
        rm "${DEB_PATH}"
        log_success "git-delta 安装成功。"
    fi
}

# 配置 Git
config_git() {
    log_info "正在配置 Git 全局信息..."
    git config --global user.name "YungVenuz"
    git config --global user.email "5196666qwe@email.com"
    git config --global core.autocrlf input
    
    if command_exists delta; then
        log_info "检测到 delta, 正在为您配置 git 使用 delta..."
        git config --global core.pager "delta"
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate "true"
        git config --global delta.side-by-side "true"
        git config --global delta.line-numbers "true"
        git config --global merge.conflictstyle "diff3"
        git config --global diff.colorMoved "default"
    fi
    log_success "Git 配置完成。"
    log_warning "Git email 被设置为 '5196666qwe@email.com'。如果需要，请稍后手动修改。"
}

# ---
# Node.js 环境 (Node.js Environment)
# ---

install_nvs_node() {
    log_info "正在安装 Node.js 版本管理器 nvs..."
    export NVS_HOME="$HOME/.nvs"
    if [ ! -d "$NVS_HOME" ]; then
        git clone --depth=1 "${NVS_MIRROR_URL}" "$NVS_HOME"
        . "$NVS_HOME/nvs.sh" install
    fi
    . "$NVS_HOME/nvs.sh"

    log_info "配置 nvs 国内镜像源..."
    nvs remote node https://npmmirror.com/mirrors/node/
    
    if ! command_exists node; then
        log_info "正在安装 Node.js LTS 版本..."
        nvs add lts
        nvs use lts
        nvs link lts
    fi

    log_info "配置 npm, pnpm, yarn, bun 国内镜像源..."
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global"
    npm config set registry https://registry.npmmirror.com

    local pkgs_to_install=("pnpm" "yarn" "cnpm" "bun")
    for pkg in "${pkgs_to_install[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            log_info "正在全局安装 ${FUCHSIA}${pkg}${BLUE}..."
            npm install -g "$pkg"
        else
            log_info "${FUCHSIA}${pkg}${BLUE} 已安装，跳过。"
        fi
    done
    
    log_success "Node.js 环境配置完成。"
}


# ---
# Docker 环境 (Docker Environment)
# ---

install_docker() {
    if command_exists docker; then
        log_info "Docker 已安装，跳过安装步骤。"
    else
        log_info "正在安装 Docker Engine..."
        ${SUDO} apt-get install -y ca-certificates curl gnupg
        
        ${SUDO} install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | ${SUDO} gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        ${SUDO} chmod a+r /etc/apt/keyrings/docker.gpg

        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          ${SUDO} tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        ${SUDO} apt-get update
        ${SUDO} apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        log_success "Docker 安装成功！"
    fi

    log_info "正在配置 Docker..."
    ${SUDO} usermod -aG docker "${USER}"
    log_info "已将用户 ${FUCHSIA}${USER}${BLUE} 添加到 docker 组。您需要重新登录才能免 sudo 使用 docker。"

    local DOCKER_DAEMON_JSON='/etc/docker/daemon.json'
    local DOCKER_MIRRORS_CONFIG='
{
    "registry-mirrors": [
        "https://ustc-edu-cn.mirror.aliyuncs.com",
        "https://mirror.ccs.tencentyun.com",
        "https://docker.mirrors.sjtug.sjtu.edu.cn",
        "https://hub-mirror.c.163.com",
        "https://mirror.baidubce.com"
    ]
}
'
    echo "${DOCKER_MIRRORS_CONFIG}" | ${SUDO} tee "${DOCKER_DAEMON_JSON}" > /dev/null
    
    log_info "正在启动并设置 Docker 开机自启..."
    ${SUDO} systemctl enable --now docker
    ${SUDO} systemctl restart docker
    log_success "Docker 配置完成并已成功启动。"
}

configure_dev_docker_compose() {
    log_info "正在为您配置一套常用的开发数据库 Docker Compose 环境..."
    local COMPOSE_DIR="$HOME/docker-compose-dev"
    
    if [ -d "${COMPOSE_DIR}" ]; then
        log_warning "目录 ${FUCHSIA}${COMPOSE_DIR}${YELLOW} 已存在，跳过配置。"
        return
    fi
    mkdir -p "${COMPOSE_DIR}"

    log_info "正在生成数据库安全密码..."
    PASS_LEN=16
    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c${PASS_LEN})
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c${PASS_LEN})
    REDIS_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c${PASS_LEN})
    MONGO_INITDB_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c${PASS_LEN})
    
    declare -g FINAL_MYSQL_PASS="${MYSQL_ROOT_PASSWORD}"
    declare -g FINAL_POSTGRES_PASS="${POSTGRES_PASSWORD}"
    declare -g FINAL_REDIS_PASS="${REDIS_PASSWORD}"
    declare -g FINAL_MONGO_PASS="${MONGO_INITDB_ROOT_PASSWORD}"

    local DOCKER_DATA_BASE="$HOME/docker-data"
    log_info "创建 Docker 数据卷目录于 ${FUCHSIA}${DOCKER_DATA_BASE}${BLUE}..."
    mkdir -p \
        "${DOCKER_DATA_BASE}/mysql/conf" "${DOCKER_DATA_BASE}/mysql/data" "${DOCKER_DATA_BASE}/mysql/init" \
        "${DOCKER_DATA_BASE}/postgres/data" "${DOCKER_DATA_BASE}/redis/data" "${DOCKER_DATA_BASE}/mongo/data" \
        "${DOCKER_DATA_BASE}/nginx/conf.d" "${DOCKER_DATA_BASE}/nginx/html" "${DOCKER_DATA_BASE}/nginx/logs"

    log_info "正在写入 ${FUCHSIA}docker-compose.yml${BLUE} 和 ${FUCHSIA}.env${BLUE} 文件..."

    cat > "${COMPOSE_DIR}/.env" <<EOL
DATA_BASE_PATH=${DOCKER_DATA_BASE}
MYSQL_NAME=mysql-dev
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_PORT_MAPPING=3306
POSTGRES_NAME=postgres-dev
POSTGRES_USER=postgres
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_PORT_MAPPING=5432
REDIS_NAME=redis-dev
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_PORT_MAPPING=6379
MONGO_NAME=mongo-dev
MONGO_PORT_MAPPING=27017
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD}
NGINX_NAME=nginx-dev
NGINX_PORT_MAPPING=80
NGINX_WEB_ROOT=${HOME}/www
EOL

    cat > "${COMPOSE_DIR}/docker-compose.yml" <<'EOL'
version: '3.8'
services:
  mysql:
    image: mysql:8.0
    container_name: ${MYSQL_NAME}
    restart: always
    environment: { MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}, MYSQL_ROOT_HOST: '%' }
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - ${DATA_BASE_PATH}/mysql/conf:/etc/mysql/conf.d
      - ${DATA_BASE_PATH}/mysql/data:/var/lib/mysql
      - ${DATA_BASE_PATH}/mysql/init:/docker-entrypoint-initdb.d
    ports: ["${MYSQL_PORT_MAPPING}:3306"]
    networks: [dev-net]
  postgres:
    image: postgres:14
    container_name: ${POSTGRES_NAME}
    restart: always
    environment: { POSTGRES_DB: postgres, POSTGRES_USER: ${POSTGRES_USER}, POSTGRES_PASSWORD: ${POSTGRES_PASSWORD} }
    volumes: [- ${DATA_BASE_PATH}/postgres/data:/var/lib/postgresql/data]
    ports: ["${POSTGRES_PORT_MAPPING}:5432"]
    networks: [dev-net]
  redis:
    image: redis:6.2-alpine
    container_name: ${REDIS_NAME}
    restart: always
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    volumes: [- ${DATA_BASE_PATH}/redis/data:/data]
    ports: ["${REDIS_PORT_MAPPING}:6379"]
    networks: [dev-net]
  mongo:
    image: mongo:latest
    container_name: ${MONGO_NAME}
    restart: always
    environment: { MONGO_INITDB_ROOT_USERNAME: ${MONGO_INITDB_ROOT_USERNAME}, MONGO_INITDB_ROOT_PASSWORD: ${MONGO_INITDB_ROOT_PASSWORD} }
    volumes: [- ${DATA_BASE_PATH}/mongo/data:/data/db]
    ports: ["${MONGO_PORT_MAPPING}:27017"]
    networks: [dev-net]
  nginx:
    image: nginx:latest
    container_name: ${NGINX_NAME}
    restart: always
    ports: ["${NGINX_PORT_MAPPING}:80"]
    volumes:
      - ${DATA_BASE_PATH}/nginx/conf.d:/etc/nginx/conf.d
      - ${DATA_BASE_PATH}/nginx/logs:/var/log/nginx
      - ${DATA_BASE_PATH}/nginx/html:/usr/share/nginx/html
      - ${NGINX_WEB_ROOT}:/var/www/html
    networks: [dev-net]
networks:
  dev-net:
    driver: bridge
EOL
    
    echo "<h1>Welcome from Docker Nginx!</h1>" > "${DOCKER_DATA_BASE}/nginx/html/index.html"
    mkdir -p "${HOME}/www"
    
    log_info "运行 'docker compose up -d' 启动服务..."
    cd "${COMPOSE_DIR}" && docker compose up -d
    
    log_success "Docker Compose 开发环境已在 ${FUCHSIA}${COMPOSE_DIR}${GREEN} 中配置并启动。"
}


# ---
# Oh My Zsh 环境
# ---

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_warning "Oh My Zsh 已安装，跳过。"
        return
    fi
    
    log_info "正在安装 Oh My Zsh..."
    git clone --depth=1 "${OMZ_MIRROR_URL}" "$HOME/.oh-my-zsh"
    cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"

    log_info "正在安装 zsh 插件 (autosuggestions, syntax-highlighting)..."
    local ZSH_CUSTOM_PLUGINS="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    git clone --depth=1 "${OMZ_PLUGIN_AUTOSUGGESTIONS_URL}" "${ZSH_CUSTOM_PLUGINS}/zsh-autosuggestions"
    git clone --depth=1 "${OMZ_PLUGIN_SYNTAX_HIGHLIGHTING_URL}" "${ZSH_CUSTOM_PLUGINS}/zsh-syntax-highlighting"

    log_info "正在自动配置 .zshrc 文件..."
    sed -i 's/^plugins=(git)/plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
    
    echo '' >> "$HOME/.zshrc"
    echo '# NVS and NPM Global Configuration' >> "$HOME/.zshrc"
    echo 'export NVS_HOME="$HOME/.nvs"' >> "$HOME/.zshrc"
    echo '[ -s "$NVS_HOME/nvs.sh" ] && \. "$NVS_HOME/nvs.sh"' >> "$HOME/.zshrc"
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.zshrc"
    
    if [[ "$SHELL" != *"/zsh" ]]; then
        log_info "正在尝试将默认 shell 切换为 Zsh..."
        if command_exists chsh; then
            if [[ $EUID -eq 0 ]]; then
                chsh -s "$(command -v zsh)"
                log_success "root 用户的默认 shell 已切换为 Zsh。"
            else
                log_warning "请手动运行 'chsh -s $(command -v zsh)' 并输入密码以切换默认 shell。"
            fi
        else
            log_warning "'chsh' 命令不存在，无法自动切换 shell。请手动切换。"
        fi
    fi
    log_success "Oh My Zsh 安装配置完成。"
}

# ---
# 最终总结
# ---

final_summary() {
    echo -e "${FUCHSIA}======================================================================${NOCOLOR}"
    echo -e "${FUCHSIA}            🚀 环境初始化全部完成! 🚀            ${NOCOLOR}"
    echo -e "${FUCHSIA}======================================================================${NOCOLOR}"
    
    echo -e "${GREEN}关键信息摘要:${NOCOLOR}"
    echo -e "  - ${BLUE}Git 用户名:${NOCOLOR} $(git config --global user.name)"
    echo -e "  - ${BLUE}Node.js 版本:${NOCOLOR} $(. $HOME/.nvs/nvs.sh && nvs current)"
    echo -e "  - ${BLUE}Docker 版本:${NOCOLOR} $(docker --version 2>/dev/null || echo 'Not found')"
    
    if [ -n "${FINAL_MYSQL_PASS-}" ]; then
        echo -e "\n${YELLOW}Docker Compose 开发环境密码 (请妥善保管):${NOCOLOR}"
        echo -e "  - ${BLUE}Compose 目录:${NOCOLOR} $HOME/docker-compose-dev"
        echo -e "  - ${BLUE}MySQL root 密码:${FUCHSIA} ${FINAL_MYSQL_PASS}${NOCOLOR}"
        echo -e "  - ${BLUE}PostgreSQL 密码:${FUCHSIA} ${FINAL_POSTGRES_PASS}${NOCOLOR}"
        echo -e "  - ${BLUE}Redis 密码:${FUCHSIA} ${FINAL_REDIS_PASS}${NOCOLOR}"
        echo -e "  - ${BLUE}MongoDB root 密码:${FUCHSIA} ${FINAL_MONGO_PASS}${NOCOLOR}"
    fi
    
    echo -e "\n${GREEN}后续步骤建议:${NOCOLOR}"
    echo -e "  1. ${YELLOW}为了使所有环境变量和 docker 用户组生效，请重新登录服务器或桌面环境。${NOCOLOR}"
    echo -e "  2. 如果你的默认 shell 没有自动切换，请手动运行: ${FUCHSIA}chsh -s $(command -v zsh)${NOCOLOR}"
    echo -e "  3. 你现在可以进入 ${FUCHSIA}$HOME/docker-compose-dev${NOCOLOR} 目录，使用 ${FUCHSIA}docker compose ps${NOCOLOR} 查看服务状态。"
    
    echo -e "${FUCHSIA}======================================================================${NOCOLOR}"
}

# ---
# 主函数 (Main Function)
# ---

main() {
    setup_sudo
    check_distro
    
    # setup_apt_mirror # 可选：如果需要更换为国内源，请取消此行注释
    
    install_base_tools
    install_modern_cli_tools
    config_git
    install_nvs_node
    install_docker
    configure_dev_docker_compose
    install_oh_my_zsh
    
    final_summary
}

# ---
# 脚本入口 (Script Entry Point)
# ---

main "$@"
