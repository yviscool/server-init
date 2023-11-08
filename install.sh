#!/bin/sh
##################################################################################
# Version	: 1.50								#
# Date		: 2023-07-09							#
# Author	: yungvenuz							#
# Conact	: 5196666qwe@email.com						#
##################################################################################
# 定义颜色变量
NOCOLOR='\033[0m'
RED='\033[0;31m'        # 错误信息
GREEN='\033[0;32m'      # 成功信息
BLUE='\033[0;34m'       # 信息提示

# 输出带颜色的日志信息
log() {
  if [[ $# -gt 1 ]]; then
    local COLOR=$1
    echo -e "${COLOR}${@:2}${NOCOLOR}"
  else
    echo -e "${@:1}${NOCOLOR}"
  fi
}

##################################################################################
# 安装和配置软件包管理器
##################################################################################

# 设置默认的包管理器
Install=""
Update=""

# 获取系统的环境变量PATH，并根据不同的包管理器设置安装和更新命令
setup_package_manager() {
  path=$(echo $PATH | sed 's/:/ /g')

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
      *)
        ;;
    esac
  done

  if [[ ! $Install ]]; then
    case $LANG in
      zh_CN*) log "${RED}无法识别您的包管理器！" ;;
      zh_TW*) log "${RED}無法識別您的包管理器！" ;;
      *) log "${RED}无法识别您的包管理器！" ;;
    esac
    exit 1
  fi
}

# 更新系统的软件包
update_packages() {
  case $LANG in
    zh_*) log "${GREEN}正在更新软件包..." ;;
    *) log "${GREEN}Updating packages..." ;;
  esac
  yes | sh -c "$Update"
}

##################################################################################
# 安装和配置工具
##################################################################################

# 安装指定的软件包
install_package() {
  local package=$1
  local package_name=$(basename $package)

  # 检查是否已安装该软件包
  if [[ ! $(find $path -maxdepth 1 -name $package_name) ]]; then
    case $LANG in
      zh_CN*) log "${GREEN}正在安装$package_name..." ;;
      zh_TW*) log "${GREEN}正在安裝$package_name..." ;;
      *) log "${GREEN}Installing $package_name..." ;;
    esac
    sh -c "$Install $package"
  fi
}

# 安装常用工具
install_tools() {
  # 使用数组存储需要安装的工具包
  local tools=(
    "git"
    "zsh"
    "jq"
    "ag"
    "unzip"
    "mycli"
    "tmux"
    "axel"
    "lrzsz"
    "glances"
  )

  # 循环安装工具包
  for tool in "${tools[@]}"; do
    install_package $tool
  done
}

# 配置git
config_git() {
  log "${BLUE}配置${FUCHSIA}git${BLUE}..."
  git config --global user.name "YungVenuz"
  git config --global user.email "5196666qwe@gmail.com"
}

##################################################################################
# 安装和配置Node.js版本管理器
##################################################################################

install_nvs() {
  local nvs_dir="$HOME/.nvs"

  if [[ ! -d "$nvs_dir" ]]; then
    export NVS_HOME="$nvs_dir"
    git clone https://mirror.ghproxy.com/https://github.com/jasongin/nvs --depth=1 "$nvs_dir"
    
    . "$nvs_dir/nvs.sh" install
  fi

  if [[ -d "$nvs_dir" ]]; then
    if type 'nvs' 2>/dev/null | grep -q 'function'; then
      :
    else
      export NVS_HOME="$nvs_dir"
      [ -s "$NVS_HOME/nvs.sh" ] && . "$NVS_HOME/nvs.sh"
    fi

    nvs remote node https://npmmirror.com/mirrors/node/
    mkdir -p ~/.npm-global
  fi
}

# 安装Node.js和一些全局包管理工具
install_nodejs() {
  if type 'nvs' 2>/dev/null | grep -q 'function'; then
    if [[ ! "$(command -v node)" ]]; then
      log "${BLUE}正在安装${FUCHSIA}Node.js LTS版本..."
      nvs add lts

      log "${BLUE}正在安装${FUCHSIA}最新版本的Node.js..."
      nvs add latest

      nvs use lts
      nvs link lts

      npm install -g cnpm --registry=https://registry.npmmirror.com
      npm install -g pnpm --registry=https://registry.npmmirror.com
      npm install -g yarn --registry=https://registry.npmmirror.com
      pnpm config registry https://registry.npm.taobao.org
    fi
  fi
}


##################################################################################
# 安装和配置Docker及相关工具
##################################################################################
# 安装Docker
install_docker() {
  if [[ ! -x "$(command -v docker)" ]]; then
    log "${BLUE}正在安装${FUCHSIA}Docker${BLUE}..."
    dnf config-manager --add-repo=http://mirrors.tencent.com/docker-ce/linux/centos/docker-ce.repo
    dnf install -y docker-ce --nobest

    usermod -aG docker $USER
    systemctl enable docker
    systemctl start docker
  fi

  if [[ -x "$(command -v docker)" ]]; then
    log "${BLUE}配置${FUCHSIA}Docker镜像源${BLUE}..."
    cat  > /etc/docker/daemon.json <<EOL
{
    "registry-mirrors": [
        "https://ustc-edu-cn.mirror.aliyuncs.com",
	"https://mirror.ccs.tencentyun.com",
        "https://docker.mirrors.sjtug.sjtu.edu.cn",
        "https://mirror.baidubce.com",
        "https://hub-mirror.c.163.com"
    ]
}
EOL
    log "${BLUE}重启${FUCHSIA}Docker${BLUE}服务"
    systemctl daemon-reload
    systemctl restart docker
  fi
}


# 安装Docker Compose
install_docker_compose() {
  if [[ ! -x "$(command -v docker-compose)" ]]; then
    log "${BLUE}正在安装${FUCHSIA}Docker Compose${BLUE}..."
    curl -L "https://mirror.ghproxy.com/https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  fi
}



# 配置Docker Compose和相关文件
configure_docker_compose() {
  local compose_dir="$HOME/docker-compose"

  if [[ ! -d "$compose_dir" ]]; then
    log "${BLUE}创建${FUCHSIA}Docker Compose${BLUE}目录..."
    mkdir -p "$compose_dir"

    log "${BLUE}写入${FUCHSIA}docker-compose.yml${BLUE}文件..."
    cat > $compose_dir/docker-compose.yml  <<"EOL"
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
    #command: redis-server
    # 设置密码和开启AOF
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
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

    log "${BLUE}写入${FUCHSIA}.env${BLUE}文件..."
    cat > $compose_dir/.env <<"EOL"
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

    log "${BLUE}写入${FUCHSIA}nginx.conf${BLUE}文件..."
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
        listen       80 ;
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
		#root /home/www/;
		alias /home/www;
		autoindex on;
	}

	#location ~ \.txt$ {
	    # root /home/www/;
            #alias /home/www;
            #autoindex on;
	#}


	location /erp/ {
	     proxy_pass http://host.docker.internal:3001/;
	     #proxy_pass http://172.17.87.184:3001/;
	     proxy_redirect off;
	     proxy_set_header X-Real-IP $remote_addr;
             proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	}

	location /etm/ {
	     # ifconfig eth0 | grep inet | grep -v inet6 | awk '{print $2}'
	     proxy_pass http://host.docker.internal:3001/;
	     #proxy_pass http://172.17.87.184:3001/;
	     proxy_redirect off;
	     proxy_set_header X-Real-IP $remote_addr;
             proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	}

	location /cdn {
		rewrite /(.+)$ /$1 break; 
		proxy_pass https://hzxiaoliang.oss-cn-zhangjiakou.aliyuncs.com;
	}

	location /txtype {
		rewrite ^/(.*) https://my-bucket-xrfferp-1253480735.cos-website.ap-shanghai.myqcloud.com;
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

	location = /robots.txt {
	   add_header Content-Type text/plain;
	   return 200 "User-agent: *\nDisallow: /\n";
	}


	#location ~* ^.+\.(jpg|jpeg|png)$ {
	#}


    #access_log  logs/host.access.log  main;

    }



}


EOL


    cat > /opt/dockerdata/nginx/html/index.html <<"EOL"
<h1>just for test</h1>
EOL
  fi
}


# 启动Docker Compose服务
start_docker_compose() {
  if [[ -x "$(command -v docker-compose)" ]]; then
    log "${BLUE}启动${FUCHSIA}Docker Compose${BLUE}服务..."
    cd ${HOME}/docker-compose
    docker-compose up -d
  fi
}


##################################################################################
# 安装和配置Oh-My-Zsh
##################################################################################
# 安装Oh-My-Zsh
install_oh_my_zsh() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "${BLUE}正在安装${FUCHSIA}Oh-My-Zsh${BLUE}..."
    yes | sh -c "$(curl -fsSL https://mirror.ghproxy.com/ohmyzsh/ohmyzsh/raw/master/tools/install.sh)"

    # 切换默认Shell为Zsh
    usermod -s /bin/zsh root
    /bin/zsh

    # 配置NVS在Zsh中
    echo "export NVS_HOME=$HOME/.nvs" >> ~/.zshrc
    echo "[ -s $NVS_HOME/nvs.sh ] && . $NVS_HOME/nvs.sh" >> ~/.zshrc

    # 创建NPM全局目录
    if [[ -d "$HOME/.npm-global" ]]; then
      npm config set prefix ~/.npm-global
      export PATH=$HOME/.npm-global/bin:$PATH
      echo "export PATH=~/.npm-global/bin:$PATH" >> ~/.zshrc
      pnpm config set global-bin-dir $HOME/.npm-global/bin

      # 安装一些全局包
      cnpm i -g pm2
    fi

    # 安装zsh-autosuggestions插件
    git clone https://mirror.ghproxy.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    # 安装zsh-syntax-highlighting插件
    git clone https://mirror.ghproxy.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

    # 配置zsh插件
    sed -i.bak 's/^plugins=(\(.*\))/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
    source ~/.zshrc
  fi
}


##################################################################################
# 主程序入口
##################################################################################

# 设置默认包管理器
setup_package_manager

# 更新系统软件包
update_packages

# 安装和配置工具
install_tools
config_git

# 安装和配置Node.js版本管理器
install_nvs
install_nodejs

# 安装和配置Docker及相关工具
install_docker
install_docker_compose
configure_docker_compose
start_docker_compose

# 安装和配置Oh-My-Zsh
install_oh_my_zsh

# 完成安装
log "${GREEN}安装和配置完成！"
