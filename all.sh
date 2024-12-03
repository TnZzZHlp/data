#!/bin/bash

setup(){
    #安装必备软件
    apt update -y
    apt install sudo tree btop nload net-tools bash-completion -y

    #ssh
    curl -fsSL -o /tmp/sshd_config https://gh.tnzzz.top/gh/https://raw.githubusercontent.com/TnZzZHlp/data/main/sshd_config
    curl -fsSL -o /tmp/authorized_keys https://gh.tnzzz.top/gh/https://raw.githubusercontent.com/TnZzZHlp/data/main/authorized_keys
    curl -fsSL -o /tmp/sshd_config.sha256.sum https://gh.tnzzz.top/gh/https://raw.githubusercontent.com/TnZzZHlp/data/main/sshd_config.sha256.sum
    curl -fsSL -o /tmp/authorized_keys.sha256.sum https://gh.tnzzz.top/gh/https://raw.githubusercontent.com/TnZzZHlp/data/main/authorized_keys.sha256.sum

    if [ "$(sha256sum /tmp/sshd_config | awk '{print $1}')" = "$(cat /tmp/sshd_config.sha256.sum)" ]; then
        echo "sha256校验通过"
        #判断文件是否存在
        if [ -f "/etc/ssh/sshd_config" ]; then
            rm /etc/ssh/sshd_config
            mv /tmp/sshd_config /etc/ssh/sshd_config
        else
            mv /tmp/sshd_config /etc/ssh/sshd_config
        fi
    else
        echo "sha256校验失败"
    fi

    if [ "$(sha256sum /tmp/authorized_keys | awk '{print $1}')" = "$(cat /tmp/authorized_keys.sha256.sum)" ]; then
        echo "sha256校验通过"
        #判断文件夹是否存在
        if [ -d "/root/.ssh" ]; then
            rm -r /root/.ssh
            mkdir /root/.ssh
            mv /tmp/authorized_keys /root/.ssh/authorized_keys
            service sshd restart
        else
            mkdir /root/.ssh
            mv /tmp/authorized_keys /root/.ssh/authorized_keys
            service sshd restart
        fi
    else
        echo "sha256校验失败"
    fi

    #删除临时文件
    if [ -d "/tmp/sshd_config" ]; then
        rm /tmp/sshd_config
    fi

    if [ -d "/tmp/authorized_keys" ]; then
        rm /tmp/authorized_keys
    fi

    if [ -d "/tmp/sshd_config.sha256.sum" ]; then
        rm /tmp/sshd_config.sha256.sum
    fi

    if [ -d "/tmp/sshd_config.sha256.sum" ]; then
        echo "yes"
    fi

    if [ -d "/tmp/authorized_keys.sha256.sum" ]; then
        rm /tmp/authorized_keys.sha256.sum
    fi
}

#换源
change(){
    curl -L https://gh.tnzzz.top/gh/https://github.com/RubyMetric/chsrc/releases/download/latest/chsrc-x64-linux -o chsrc && chmod +x ./chsrc && ./chsrc
}

#BBR
bbr(){
    apt update -y
    curl -fsSL -o tcp.sh "https://gh.tnzzz.top/gh/https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
}

#更新内核
upgrade_core(){
    apt update -y
    apt-get upgrade linux-image-amd64 -y
}

#流媒体检测
media(){
    apt update -y
    apt install curl wget -y
    bash <(curl -fsSL check.unlock.media)
}

if [ "$1" = "" ]; then
    echo "setup - 安装必备软件"
    echo "change - 换源"
    echo "bbr - BBR"
    echo "upgrade_core - 更新内核"
    echo "media - 流媒体检测"
    exit 1
else
    $1
fi