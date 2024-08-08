#!/bin/bash

# 定义颜色
re="\033[0m"
red="\033[1;91m"
green="\e[1;32m"
yellow="\e[1;33m"
purple="\e[1;35m"
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
reading() { read -p "$(red "$1")" "$2"; }

USERNAME=$(whoami)
HOSTNAME=$(hostname)
UUID_FILE="$HOME/.singbox_uuid" # 定义 UUID 的存储位置

# Check if UUID file exists
if [ -f "$UUID_FILE" ]; then
    export UUID=$(cat "$UUID_FILE")  # Read the existing UUID
else
    export UUID=$(uuidgen)  # Generate a new UUID
    echo "$UUID" > "$UUID_FILE"  # Save the UUID to the file
fi

export NEZHA_SERVER=${NEZHA_SERVER:-''}
export NEZHA_PORT=${NEZHA_PORT:-'5555'}     
export NEZHA_KEY=${NEZHA_KEY:-''}

[[ "$HOSTNAME" == "s1.ct8.pl" ]] && WORKDIR="domains/${USERNAME}.ct8.pl/logs" || WORKDIR="domains/${USERNAME}.serv00.net/logs"
[ -d "$WORKDIR" ] || (mkdir -p "$WORKDIR" && chmod 777 "$WORKDIR")

read_vless_port() {
    while true; do
        reading "请输入vless-reality端口（面板开放的tcp端口）: " vless_port
        if [[ "$vless_port" =~ ^[0-9]+$ ]] && [ "$vless_port" -ge 1 ] && [ "$vless_port" -le 65535 ]; then
            green "你的vless-reality端口为: $vless_port"
            break
        else
            yellow "输入错误，请重新输入面板开放的TCP端口"
        fi
    done
}

read_hy2_port() {
    while true; do
        reading "请输入hysteria2端口（面板开放的UDP端口）: " hy2_port
        if [[ "$hy2_port" =~ ^[0-9]+$ ]] && [ "$hy2_port" -ge 1 ] && [ "$hy2_port" -le 65535 ]; then
            green "你的hysteria2端口为: $hy2_port"
            break
        else
            yellow "输入错误，请重新输入面板开放的UDP端口"
        fi
    done
}

read_nz_variables() {
  if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_PORT" ] && [ -n "$NEZHA_KEY" ]; then
      green "使用自定义变量哪吒运行哪吒探针"
      return
  else
      reading "是否需要安装哪吒探针？【y/n】: " nz_choice
      [[ -z $nz_choice ]] && return
      [[ "$nz_choice" != "y" && "$nz_choice" != "Y" ]] && return
      reading "请输入哪吒探针域名或IP：" NEZHA_SERVER
      green "你的哪吒域名为: $NEZHA_SERVER"
      reading "请输入哪吒探针端口（回车跳过默认使用5555）：" NEZHA_PORT
      [[ -z $NEZHA_PORT ]] && NEZHA_PORT="5555"
      green "你的哪吒端口为: $NEZHA_PORT"
      reading "请输入哪吒探针密钥：" NEZHA_KEY
      green "你的哪吒密钥为: $NEZHA_KEY"
  fi
}

generate_config() {
    output=$(./web generate reality-keypair)
    private_key=$(echo "${output}" | awk '/PrivateKey:/ {print $2}')
    public_key=$(echo "${output}" | awk '/PublicKey:/ {print $2}')

    openssl ecparam -genkey -name prime256v1 -out "private.key"
    openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=$USERNAME.serv00.net"

    cat > config.json << EOF
{
  "log": {
    "disabled": true,
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "google",
        "address": "tls://8.8.8.8",
        "strategy": "ipv4_only",
        "detour": "direct"
      }
    ],
    "rules": [
      {
        "rule_set": [
          "geosite-openai"
        ],
        "server": "wireguard"
      },
      {
        "rule_set": [
          "geosite-netflix"
        ],
        "server": "wireguard"
      },
      {
        "rule_set": [
          "geosite-category-ads-all"
        ],
        "server": "block"
      }
    ],
    "final": "google",
    "strategy": "",
    "disable_cache": false,
    "disable_expire": false
  },
  "inbounds": [
    {
      "tag": "hysteria-in",
      "type": "hysteria2",
      "listen": "::",
      "listen_port": $hy2_port,
      "users": [
        {
          "password": "$UUID"
        }
      ],
      "masquerade": {
        "domain": "www.bing.com"
      }
    },
    {
      "tag": "vless-in",
      "type": "vless",
      "listen": "::",
      "listen_port": $vless_port,
      "users": [
        {
          "uuid": "$UUID",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "certificates": [
          {
            "certificate_file": "./cert.pem",
            "key_file": "./private.key"
          }
        ],
        "alpn": [
          "h2",
          "http/1.1"
        ]
      },
      "reality": {
        "handshake": {
          "server": "www.bing.com",
          "server_key": "$public_key",
          "server_names": [
            "www.bing.com"
          ],
          "alpn": [
            "h2",
            "http/1.1"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ]
}
EOF
}

run_sb() {
    if [ -e npm ]; then
        tlsPorts=("443" "8443" "2096" "2087" "2083" "2053")
        if [[ "${tlsPorts[*]}" =~ "${NEZHA_PORT}" ]]; then
            NEZHA_TLS="--tls"
        else
            NEZHA_TLS=""
        fi
        if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_PORT" ] && [ -n "$NEZHA_KEY" ]; then
            export TMPDIR=$(pwd)
            nohup ./npm -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} >/dev/null 2>&1 &
            sleep 2
            pgrep -x "npm" > /dev/null && green "npm 正在运行" || { red "npm 未运行，正在重新启动..."; pkill -x "npm" && nohup ./npm -s "${NEZHA_SERVER}:${NEZHA_PORT}" -p "${NEZHA_KEY}" ${NEZHA_TLS} >/dev/null 2>&1 & sleep 2; purple "npm 已重启"; }
        else
            purple "哪吒变量为空，正在跳过运行"
        fi
    fi

    if [ -e web ]; then
        nohup ./web run -c config.json >/dev/null 2>&1 &
        sleep 2
        pgrep -x "web" > /dev/null && green "web 正在运行" || { red "web 未运行，正在重启..."; pkill -x "web" && nohup ./web run -c config.json >/dev/null 2>&1 & sleep 2; purple "web 已重启"; }
    fi
}

get_links() {
    # 获取 IP
    IP=$(curl -s ipv4.ip.sb || { ipv6=$(curl -s --max-time 1 ipv6.ip.sb); echo "[$ipv6]"; })
    sleep 1
    # 获取 ipinfo
    ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g') 
    sleep 1
    yellow "注意：v2ray或其他软件的跳过证书验证需设置为true，否则hy2或tuic节点可能不通\n"
    cat > list.txt <<EOF
vless://$UUID@$IP:$vless_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.ups.com&fp=chrome&pbk=$public_key&type=tcp&headerType=none#$ISP

hysteria2://$UUID@$IP:$hy2_port/?sni=www.bing.com&alpn=h3&insecure=1#$ISP

tuic://$UUID:admin123@$IP:$tuic_port?sni=www.bing.com&congestion_control=bbr&udp_relay_mode=native&alpn=h3&allow_insecure=1#$ISP
EOF
    cat list.txt
    purple "list.txt 成功保存"
    purple "运行完成！"
    sleep 3
    rm -rf npm boot.log sb.log core
}

#主菜单
menu() {
    clear
    echo ""
    purple "=== Serv00 | sing-box 一键安装脚本 ===\n"
    purple "=== 转载老王脚本，去除 tuic 协议，增加 UUID 自动生成 ===\n"
    echo -e "${green}脚本地址：${re}${yellow}https://github.com/yyfalbl/singbox-2${re}\n"   
    purple "*** 转载请注明出处，请勿滥用 ***\n"
    echo "==============="
    green "1.安装 sing-box"
    echo "==============="
    red "2.卸载 sing-box"
    echo "==============="
    green "3.查看节点信息"
    echo "==============="
    yellow "4. 清理所有进程"
    echo "==============="
    red "0. 退出脚本"
    echo "==========="
    reading "请输入选择（0-4）：" choice
    echo ""
    case "${choice}" in
        1) install_singbox ;;
        2) uninstall_singbox ;;
        3) cat $WORKDIR/list.txt ;;
        4) kill_all_tasks ;;
        0) exit 0 ;;
        *) red "无效的选项，请输入 0 到 4" ;;
    esac
}
menu

