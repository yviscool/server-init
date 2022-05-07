#!/bin/sh
##################################################################################
# Version	: 1.03			#
# Date		: 2021-01-21		#
# Author	: yungvenuz		#
# Conact	: 5196666qwe@email.com	#
##################################################################################
# Colors
NOCOLOR='\033[0m'
RED='\033[0;31m'        # Error message
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'      # Success message
LIGHTGREEN='\033[1;32m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'     # Warning message
BLUE='\033[0;34m'       # Info message
LIGHTBLUE='\033[1;34m'
PURPLE='\033[0;35m'
FUCHSIA='\033[0;35m'
LIGHTPURPLE='\033[1;35m'
CYAN='\033[0;36m'
LIGHTCYAN='\033[1;36m'
DARKGRAY='\033[1;30m'
LIGHTGRAY='\033[0;37m'
WHITE='\033[1;37m'

function log() {
    if [[ $# -gt 1 ]]; then
        local COLOR=$1
        echo -e "${COLOR}${@:2}${NOCOLOR}"
    else
        echo -e "${@:1}${NOCOLOR}"
    fi
}
##################################################################################
path=$(echo $PATH | sed 's/:/ /g')

# get package manager name
for file in $(find $path -maxdepth 1); do
    case ${file##*/} in
    apk)
        Install="apk add"
        Update="apk update"
        ;;
    apt | dnf | pkg | slackpkg | yum | zypper)
        Install="${file##*/} install"
        Update="${file##*/} update"
        ;;
    nix-env | pkgutil)
        Install="${file##*/} -i"
        Update="${file##*/} -u"
        ;;
    pacman | powerpill | yay)
        Install="${file##*/} -S"
        Update="${file##*/} -Syu"
        ;;
    urpmi)
        Install="urpmi"
        Update="urpmi --auto-select"
        ;;
    *) ;;
    esac
done
if [[ ! $Install ]]; then
    case $LANG in
    zh_CN*) log "${RED}无法识别您的包管理器！" ;;
    zh_TW*) log "${RED}無法識別您的包管理器！" ;;
    *) log "${RED}Unable to identify your package management!" ;;
    esac
    exits
fi

# update package
case $LANG in
zh_*) log "${GREEN} 正在更新..." ;;
*) log "${GREEN} Updating..." ;;
esac
yes | sh -c "$Update"

# install package function
Install() {
    for package in $*; do
        if [[ ! $(find $path -maxdepth 1 -name $package) ]]; then
            case $LANG in
            zh_CN*) log "${GREEN} 正在安装$package..." ;;
            zh_TW*) log "${GREEN} 正在安裝$package..." ;;
            *) log "${GREEN} Installing $package..." ;;
            esac
            sh -c "$Install $package"
        fi
    done
}

# install some packages
# yes | Install git zsh jq proxytunnel autojump
yes | Install git zsh jq ag unzip mycli tmux axel lrzsz glances 

# config git
log "${BLUE}config ${FUCHSIA}git${BLUE}..."
git config --global user.name "YungVenuz"
git config --global user.email "5196666qwe@gmail.com"

##################################################################################
# node.js version manager
# node.js version manager
# node.js version manager
# node.js version manager
##################################################################################

# node version manager (nvm)
# curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash
# echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
# echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm' >> ~/.zshrc
# source ~/.zshrc
# nvm install stable
# nvm alias default node

# node version manager (nvs)
# install nvs
if [[ ! -d "$HOME/.nvs" ]]; then
    export NVS_HOME="$HOME/.nvs"
    # git clone https://github.com/jasongin/nvs --depth=1 "$NVS_HOME" # abroad
    git clone https://gitee.com/wsz7777/nvs --depth=1 "$NVS_HOME" # china
    . "$NVS_HOME/nvs.sh" install
fi

# nvs remote aliyun node
if [[ -d "$HOME/.nvs" ]]; then
    if type 'nvs' 2>/dev/null | grep -q 'function'; then
        :
    else
        export NVS_HOME="$HOME/.nvs"
        [ -s "$NVS_HOME/nvs.sh" ] && . "$NVS_HOME/nvs.sh"
    fi

    # if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    nvs remote node https://npmmirror.com/mirrors/node/
    # fi

    mkdir -p ~/.npm-global
fi


## Install nodejs
if type 'nvs' 2>/dev/null | grep -q 'function'; then
    if [[ ! "$(command -v node)" ]]; then
        log "${BLUE} Installing ${FUCHSIA}node LTS..."
        nvs add lts

        log "${BLUE} Installing ${FUCHSIA}node latest..."
        nvs add latest

        # nvs use latest
        # nvs link latest
        nvs use lts
        nvs link lts

        npm install -g cnpm --registry=https://registry.npmmirror.com
    fi
fi


##################################################################################
# docker, docker-compose
# docker, docker-compose
# docker, docker-compose
# docker, docker-compose
##################################################################################

# install docker
if [[ ! -x "$(command -v docker)" ]]; then
    log "${BLUE}Installing ${FUCHSIA}docker${BLUE}..."
    # curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    # curl -fsSL https://get.docker.com | bash -s docker 
    curl -sSL https://get.daocloud.io/docker | bash -s docker --mirror Aliyun
    usermod -aG docker $USER
    systemctl enable docker
    systemctl start docker
fi


if [[  -x "$(command -v docker)" ]]; then
    log "${BLUE}confing${FUCHSIA}docker mirror${BLUE}..."
    # config docker mirror 
    cat  > /etc/docker/daemon.json <<EOL
{
    "registry-mirrors": [
        "https://ustc-edu-cn.mirror.aliyuncs.com",
        "https://docker.mirrors.sjtug.sjtu.edu.cn",
        "https://mirror.baidubce.com",
        "https://hub-mirror.c.163.com"
    ]
}
EOL

    log "${BLUE}restart${FUCHSIA}docker${BLUE} service"
    systemctl daemon-reload
    systemctl restart docker
fi


# intall docker-compose
if [[ ! -x "$(command -v docker-compose)" ]]; then
    log "${BLUE}Installing ${FUCHSIA}docker-compose${BLUE}..."
    # curl -L "https://github.com/docker/compose/releases/download/2.2.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    curl -L https://get.daocloud.io/docker/compose/releases/download/v2.2.3/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi



# config docker-compose, such as compose-file, env-file, nginx-conf
if [[ ! -d "$HOME/docker-compose" ]]; then

    # create docker-compose directory
    log "${BLUE}Creating ${FUCHSIA}docker-compose${BLUE} directory..."
    mkdir -p "$HOME/docker-compose"


    log "${BLUE}write ${FUCHSIA}docker-compose.yml..."
    cat  > $HOME/docker-compose/docker-compose.yml  <<"EOL"
version: '3.7'
services:
  mysql:
    image: mysql
    network_mode: "${DOCKER_NETWORK}"
    container_name: "${MYSQL_NAME}"
    hostname: "${MYSQL_NAME}"
    environment:
      MYSQL_ROOT_PASSWORD: "${MYSQL_ROOT_PASSWORD}"
      MYSQL_ROOT_HOST: '%' # 允许host为任意
    restart: always
    command: mysqld --default-authentication-plugin=mysql_native_password --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    volumes:
      - "${DIR_MYSQL_INIT_SCRIPTS}:/docker-entrypoint-initdb.d/"
      - "${DIR_MYSQL_DATA}:/var/lib/mysql"
      - "${DIR_MYSQL_CONF}:/etc/mysql/conf.d"
    ports:
      - "${MYSQL_PORT_MAPPING}:3306"
  mongo:
    image: 'mongo:${MONGO_VERSION}'
    network_mode: "${DOCKER_NETWORK}"
    container_name: "${MONGODB_NAME}"
    hostname: "${MONGODB_NAME}"
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "1024k"
        max-file: "5"
    environment:
      - "MONGO_INITDB_DATABASE=${MONGO_INITDB_DATABASE}"
      - "MONGO_INITDB_ROOT_USERNAME=${MONGO_INITDB_ROOT_USERNAME}"
      - "MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD}"
    volumes:
      - "${DIR_MONGO_DATA}:/data/db"
      - "${DIR_MONGO_INIT_SCRIPTS}:/docker-entrypoint-initdb.d/"
    ports:
      - "${MONGO_PORT_MAPPING}:27017"
    #这是覆盖掉默认启动命令让mongo不用认证。 如果用这个命令启动上边的超级用户配置要先删掉，不然启动报错
    #command: ["mongod","--noauth"]
  postgres:
    image: postgres
    network_mode: "${DOCKER_NETWORK}"
    container_name: "${POSTGRES_NAME}"
    environment:
      POSTGRES_DB: "postgres"
      POSTGRES_USER: "${POSTGRES_USER}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
    restart: always
    volumes:
      - "${DIR_MONGO_INIT_SCRIPTS}:/docker-entrypoint-initdb.d:ro"
      - "${DIR_POSTGRES_DATA}:/var/lib/postgresql/data:rw"
    ports:
      - "${POSTGRES_PORT_MAPPING}:5432"
  redis:
    image: redis
    network_mode: "${DOCKER_NETWORK}"
    container_name: "${REDIS_NAME}"
    hostname: "${REDIS_NAME}"
    restart: always
    command: redis-server
    # 设置密码和开启AOF
    #command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    volumes:
      - "${DIR_REDIS_DATA}:/data"
    ports:
      - "${REDIS_PORT_MAPPING}:6379"
  nginx:
    image: nginx
    restart: always
    container_name: "${NGINX_NAME}"
    hostname: "${NGINX_NAME}"
    ports:
      - "${NGINX_PORT_MAPPING}:80"
    volumes:
      #数据卷映射地址
      - "${DIR_NGINX_CONF}:/etc/nginx/nginx.conf"
      - "${DIR_NGINX_CONF_DIR}:/etc/nginx/conf.d"
      - "${DIR_NGINX_LOGS}:/var/log/nginx"
      - "${DIR_NGINX_HTML}:/etc/nginx/html"
      - "${DIR_NGINX_HOME}:/home/www"
    extra_hosts:
      # docker version 20 above support host-gateway
      # otherwise use ifconfig eth0 | grep inet | grep -v inet6 | awk '{print $2}' or 172.17.0.1
      - 'host.docker.internal:host-gateway'
EOL

    log "${BLUE}write ${FUCHSIA}docker-compose env..."
    cat > $HOME/docker-compose/.env <<"EOL"
DOCKER_NETWORK=bridge

# mysql
MYSQL_NAME=mysql
# MYSQL_VERSION=5.7 写死了5.7版本 避免路径映射不对
MYSQL_ROOT_PASSWORD=justfortest_tmac_forever
MYSQL_PORT_MAPPING=3306
DIR_MYSQL_CONF=/opt/dockerdata/mysql/conf
DIR_MYSQL_DATA=/opt/dockerdata/mysql/data
# 这个目录里的.sql/.sh 文件会在容器启动时被扫描执行
DIR_MYSQL_INIT_SCRIPTS=/opt/dockerdata/mysql/init

# postgres
POSTGRES_NAME=postgres
# POSTGRES_VERSION=14.0
POSTGRES_USER=postgres
POSTGRES_PASSWORD=justfortest_tmac_forever
POSTGRES_PORT_MAPPING=5432
DIR_POSTGRES_CONF=/opt/dockerdata/postgres/conf
DIR_POSTGRES_DATA=/opt/dockerdata/postgres/data
# 这个目录里的.sql/.sh 文件会在容器启动时被扫描执行
DIR_POSTGRES_INIT_SCRIPTS=/opt/dockerdata/postgres/init


# redis
REDIS_NAME=redis
# REDIS_VERSION=5
REDIS_PASSWORD=justfortest_tmac_forever
REDIS_PORT_MAPPING=6379
DIR_REDIS_DATA=/opt/dockerdata/redis/data

# mongo
MONGODB_NAME=mongo
MONGO_VERSION=latest
MONGO_PORT_MAPPING=27017
MONGO_INITDB_DATABASE=db1
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=justfortest_tmac_forever
DIR_MONGO_DATA=/opt/dockerdata/mongo/data
# 这个目录里的.js/.sh 文件会在容器启动时被扫描执行
DIR_MONGO_INIT_SCRIPTS=/opt/dockerdata/mongo/init


# nginx
NGINX_NAME=nginx
NGINX_VERSION=latest
NGINX_PORT_MAPPING=80
DIR_NGINX_CONF=/opt/dockerdata/nginx/nginx.conf
DIR_NGINX_CONF_DIR=/opt/dockerdata/nginx/conf.d
DIR_NGINX_HTML=/opt/dockerdata/nginx/html
DIR_NGINX_LOGS=/opt/dockerdata/nginx/logs
DIR_NGINX_HOME=${HOME}/static
EOL


    mkdir -p /opt/dockerdata/nginx/html

    log "${BLUE}write ${FUCHSIA}nginx.conf..."
    cat > /opt/dockerdata/nginx/nginx.conf <<"EOL"

user  root;
worker_processes  auto;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;


    client_max_body_size 50m; 

    gzip on;
    gzip_static on;
    gzip_min_length 1024;
    gzip_buffers 4 16k;
    gzip_comp_level 6;
    gzip_types text/plain application/javascript application/x-javascript text/css application/xml text/javascript application/x-httpd-php application/vnd.ms-fontobject font/ttf font/opentype font/x-woff image/svg+xml;
    gzip_vary off;
    gzip_disable "MSIE [1-6]\.";

    server {
        listen       80;
        server_name  localhost;
	    #root         /root/static;
	    index        index.html;
        #charset koi8-r;

        location /images/ {
            root /root/crm/;
            autoindex on;
            log_not_found on;
            access_log on;
            # 缓存七天
            expires 7d;
        }


	    #location ~* ^.+\.(jpg|jpeg|gif|png|bmp|js|css)$ {
        	#access_log off;
        	#root html;
        	#expires 30d;
        	#break;
        #}


        location /static {
            # /home/www/static
            alias /home/www;
            autoindex on;
        }

        #location ~ \.txt$ {
            #root /home/www/;
            #alias /home/www;
            #autoindex on;
        #}


        location /erp/ {
            proxy_pass http://127.0.0.1:3001/;
	    # proxy_pass http://host.docker.internal:3001/;
            proxy_redirect off;
            proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location /cdn {
            rewrite /(.+)$ /$1 break; 
            proxy_pass https://hzxiaoliang.oss-cn-zhangjiakou.aliyuncs.com;
        }
        
        location ~ ^(.+\.php)(.*)$ {
            root              /var/www;
            fastcgi_pass 172.17.0.6:9000;
            fastcgi_index  index.php;
            fastcgi_split_path_info  ^(.+\.php)(.*)$;
            fastcgi_param PATH_INFO $fastcgi_path_info;
            if (!-e $document_root$fastcgi_script_name) {
            return 404;
            }
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }


        #location ~* ^.+\.(jpg|jpeg|png)$ {
        #}


        #access_log  logs/host.access.log  main;

    }



}

EOL


    cat > /opt/dockerdata/nginx/html/index.html<<"EOL"
<h1>just for test</h1>
EOL
fi


# docker-compose up -d
if [[ -x "$(command -v docker-compose)" ]]; then
    log "${BLUE}up ${FUCHSIA}docker-compose${BLUE}..."
    cd ${HOME}/docker-compose
    docker-compose up -d
fi


##################################################################################
# oh-my-zsh
# oh-my-zsh
# oh-my-zsh
# oh-my-zsh
##################################################################################
# Install oh-my-zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "${BLUE} Installing ${FUCHSIA}oh-my-zsh..."
    # yes | sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" # github
    # yes | sh -c "$(curl -fsSL 'https://cdn.jsdelivr.net/gh/ohmyzsh/ohmyzsh@master/tools/install.sh')" # gitee
    # yes | sh -c "$(curl -fsSL 'https://gitee.com/mirrors/oh-my-zsh/blob/master/tools/install.sh')" # gitee
    yes | sh -c "$(curl -fsSL https://gitee.com/wosi/ohmyzsh/raw/master/tools/install.sh)" # gitee
    # change default shell
    chsh -s /bin/zsh

    # config nvs in zsh
    echo "export NVS_HOME=$HOME/.nvs" >>~/.zshrc
    echo "[ -s $NVS_HOME/nvs.sh ] && . $NVS_HOME/nvs.sh" >>~/.zshrc

    # create npm global directory
    if [[ -d "$HOME/.npm-global" ]]; then
        npm config set prefix ~/.npm-global
        export PATH=$HOME/.npm-global/bin:$PATH
        echo "export PATH=~/.npm-global/bin:$PATH" >>~/.zshrc

        # cnpm i -g lazycommit
        # cnpm i -g lazyclone
        cnpm i -g pm2
    fi

    # install zsh-autosuggestions
    # git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://gitee.com/dictxiong/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    # install zsh-syntax-highlighting
    # git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://gitee.com/simonliu009/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

    # config zsh plugins
    sed -i.bak 's/^plugins=(\(.*\)/plugins=(tmux zsh_reload vi-mode z colored-man-pages extract zsh-autosuggestions zsh-syntax-highlighting \1/' ~/.zshrc


    # switch to zsh shell
    zsh
    source ~/.zshrc
fi
