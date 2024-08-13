#!/bin/bash
# Color definitions
bold_red='\033[1;31m'
bold_green='\033[1;32m'
bold_yellow='\033[1;33m'
bold_blue='\033[1;34m'
bold_purple='\033[1;35m'
bold_cyan='\033[1;36m'
bold_white='\033[1;37m'
reset='\033[0m'

# Formatting functions
bold_italic_red() { echo -e "${bold_red}\033[3m$1${reset}"; }
bold_italic_green() { echo -e "${bold_green}\033[3m$1${reset}"; }
bold_italic_yellow() { echo -e "${bold_yellow}\033[3m$1${reset}"; }
bold_italic_blue() { echo -e "${bold_blue}\033[3m$1${reset}"; }
bold_italic_purple() { echo -e "${bold_purple}\033[3m$1${reset}"; }
bold_italic_cyan() { echo -e "${bold_cyan}\033[3m$1${reset}"; }
bold_italic_white() { echo -e "${bold_white}\033[3m$1${reset}"; }
yellow() {
    echo -e "\033[1;33m$1\033[0m"
}

# Function to check if sing-box is installed
check_singbox_installed() {
    if [ -e "$HOME/sbox/web" ]; then
        echo -e "$(bold_italic_green "欢迎使用sing-box !!!")"
    else
        echo -e "$(bold_italic_red "sing-box未安装!")"
    fi
}
# Example usage
echo -e "$(bold_italic_purple "This is a purple text with bold and italic formatting")"


# Function to check if sing-box is running
check_web_status() {
    if pgrep -x "web" > /dev/null; then
        echo -e "$(bold_italic_green "sing-box Running！")"
    else
        echo -e "$(bold_italic_red "sing-box Not running")"
    fi
}

# 获取当前用户名和主机名
#/HOME/sbox=$(whoami)
HOSTNAME=$(hostname)

# 定义存储 UUID 的文件路径
UUID_FILE="${HOME}/sbox/.singbox_uuid"

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

# 设置工作目录
WORKDIR="$HOME/sbox"
    
    # 确保工作目录存在
mkdir -p "$WORKDIR"

# 创建工作目录并设置权限
if [ ! -d "$WORKDIR" ]; then
    mkdir -p "$WORKDIR"
    chmod 777 "$WORKDIR"
fi


read_vless_port() {
    while true; do
        reading "请输入vless-reality端口 (面板开放的tcp端口): " vless_port
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
        reading "请输入hysteria2端口 (面板开放的UDP端口): " hy2_port
        if [[ "$hy2_port" =~ ^[0-9]+$ ]] && [ "$hy2_port" -ge 1 ] && [ "$hy2_port" -le 65535 ]; then
            green "你的hysteria2端口为: $hy2_port"
            break
        else
            yellow "输入错误，请重新输入面板开放的UDP端口"
        fi
    done
}

 read_tuic_port() {
     while true; do
         reading "请输入Tuic端口 (面板开放的UDP端口): " tuic_port
         if [[ "$tuic_port" =~ ^[0-9]+$ ]] && [ "$tuic_port" -ge 1 ] && [ "$tuic_port" -le 65535 ]; then
             green "你的tuic端口为: $tuic_port"
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
      reading "请输入哪吒探针域名或ip：" NEZHA_SERVER
      green "你的哪吒域名为: $NEZHA_SERVER"
      reading "请输入哪吒探针端口（回车跳过默认使用5555）：" NEZHA_PORT
      [[ -z $NEZHA_PORT ]] && NEZHA_PORT="5555"
      green "你的哪吒端口为: $NEZHA_PORT"
      reading "请输入哪吒探针密钥：" NEZHA_KEY
      green "你的哪吒密钥为: $NEZHA_KEY"
  fi
}
  
# 定义颜色
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
  GREEN='\033[1;32m'
  
install_singbox() {
    echo -e "${GREEN}\033[1m正在安装，请稍后......${NC}"
    echo -e "${YELLOW}本脚本支持同时安装二种协议${purple}(vless-reality | hysteria2)${NC}"
    echo -e "${YELLOW}开始运行前，请确保面板中${purple}已开放2个端口，一个用于TCP，一个用于UDP${NC}"
    echo -e "${YELLOW}面板中${purple}Additional services中的Run your own applications${yellow}选项已开启为${purple}Enabled${yellow}状态${NC}"
    
    reading "\n确定继续安装吗?<ENTER默认安装>【y/n】: " choice
     choice=${choice:-y}  # 默认值为 y
    case "$choice" in
        [Yy])
            WORKDIR="$HOME/sbox"
            mkdir -p "$WORKDIR"
            cd "$WORKDIR"
            
            # read_nz_variables
            read_vless_port
            read_hy2_port
            #read_tuic_port
            download_singbox && wait
            generate_config
            run_sb && sleep 3
            get_links
            
            echo -e "$(bold_italic_purple "安装完成！")"
            ;;
        [Nn])
            exit 0
            ;;
        *)
            echo -e "$(bold_italic_red "无效的选择，请输入y或n")"
            menu
            ;;
    esac
}

uninstall_singbox() {
    echo -e "$(bold_italic_purple "正在卸载sing-box，请稍后...")"
    read -p "确定要卸载吗?<ENTER默认Y>【y/n】: " choice
    choice=${choice:-y}  # 默认值为 y
    
  case "$choice" in
    [Yy])
        # 终止相关进程
        for process in 'web' 'bot' 'npm'; do
            pids=$(pgrep -f "$process" 2>/dev/null)
            if [ -n "$pids" ]; then
                kill -9 $pids 2>/dev/null
            fi
        done
        
        # 删除下载目录
        WORKDIR="$HOME/sbox"
        if [ -d "$WORKDIR" ]; then
            rm -rf "$WORKDIR" 2>/dev/null
        fi

        echo -e "$(bold_italic_purple "正在卸载......")"
        sleep 2  # Optional: pause for a brief moment to let the user see the message
        echo -e "$(bold_italic_purple "卸载完成！")"
        ;;
    [Nn])
        exit 0
        ;;
    *)
        echo -e "$(bold_italic_red "无效的选择，请输入y或n")"
        menu
        ;;
esac

}

# Download Dependency Files
download_singbox() {
    ARCH=$(uname -m) && DOWNLOAD_DIR="$HOME/sbox" && mkdir -p "$DOWNLOAD_DIR" && FILE_INFO=()
    
    if [ "$ARCH" == "arm" ] || [ "$ARCH" == "arm64" ] || [ "$ARCH" == "aarch64" ]; then
        FILE_INFO=("https://github.com/eooce/test/releases/download/arm64/sb web" "https://github.com/eooce/test/releases/download/ARM/swith npm")
    elif [ "$ARCH" == "amd64" ] || [ "$ARCH" == "x86_64" ] || [ "$ARCH" == "x86" ]; then
        FILE_INFO=("https://eooce.2go.us.kg/web web" "https://eooce.2go.us.kg/npm npm")
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi

    for entry in "${FILE_INFO[@]}"; do
        URL=$(echo "$entry" | cut -d ' ' -f 1)
        NEW_FILENAME=$(echo "$entry" | cut -d ' ' -f 2)
        FILENAME="$DOWNLOAD_DIR/$NEW_FILENAME"
        
        if [ -e "$FILENAME" ]; then
            echo -e "$(bold_italic_green "$FILENAME already exists, Skipping download")"
        else
            wget -q -O "$FILENAME" "$URL"
            echo -e "$(bold_italic_green "Downloading $FILENAME")"
        fi
        
        chmod +x $FILENAME
    done
}

generate_config() {
    output=$(./web generate reality-keypair)
    private_key=$(echo "${output}" | awk '/PrivateKey:/ {print $2}')
    public_key=$(echo "${output}" | awk '/PublicKey:/ {print $2}')

    openssl ecparam -genkey -name prime256v1 -out "$WORKDIR/private.key"
    openssl req -new -x509 -days 3650 -key "$WORKDIR/private.key" -out "$WORKDIR/cert.pem" -subj "/CN=$USERNAME.serv00.net"

    cat > "$WORKDIR/config.json" << EOF
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
     "masquerade": "https://bing.com",
     "tls": {
         "enabled": true,
         "alpn": [
             "h3"
         ],
         "certificate_path": "cert.pem",
         "key_path": "private.key"
        }
    },
    {
        "tag": "vless-reality-vesion",
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
            "enabled": true,
            "server_name": "www.ups.com",
            "reality": {
                "enabled": true,
                "handshake": {
                    "server": "www.ups.com",
                    "server_port": 443
                },
                "private_key": "$private_key",
                "short_id": [
                  ""
                ]
            }
        }
    }
    # {
    #   "tag": "tuic-in",
    #   "type": "tuic",
    #   "listen": "::",
    #   "listen_port": $tuic_port,
    #   "users": [
    #     {
    #       "uuid": "$UUID",
    #       "password": "admin123"
    #     }
    #   ],
    #   "congestion_control": "bbr",
    #   "tls": {
    #     "enabled": true,
    #     "alpn": [
    #       "h3"
    #     ],
    #     "certificate_path": "cert.pem",
    #     "key_path": "private.key"
    #   }
    # }

 ],
    "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    },
    {
      "type": "dns",
      "tag": "dns-out"
    },
    {
      "type": "wireguard",
      "tag": "wireguard-out",
      "server": "162.159.195.100",
      "server_port": 4500,
      "local_address": [
        "172.16.0.2/32",
        "2606:4700:110:83c7:b31f:5858:b3a8:c6b1/128"
      ],
      "private_key": "mPZo+V9qlrMGCZ7+E6z2NI6NOV34PD++TpAR09PtCWI=",
      "peer_public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
      "reserved": [
        26,
        21,
        228
      ]
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      },
      {
        "rule_set": [
          "geosite-openai"
        ],
        "outbound": "wireguard-out"
      },
      {
        "rule_set": [
          "geosite-netflix"
        ],
        "outbound": "wireguard-out"
      },
      {
        "rule_set": [
          "geosite-category-ads-all"
        ],
        "outbound": "block"
      }
    ],
    "rule_set": [
      {
        "tag": "geosite-netflix",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-netflix.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-openai",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/openai.srs",
        "download_detour": "direct"
      },      
      {
        "tag": "geosite-category-ads-all",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs",
        "download_detour": "direct"
      }
    ],
    "final": "direct"
   },
   "experimental": {
      "cache_file": {
      "path": "cache.db",
      "cache_id": "mycacheid",
      "store_fakeip": true
    }
  }
}
EOF
}
# running files
run_sb() {
    if [ -e "$WORKDIR/npm" ]; then
        tlsPorts=("443" "8443" "2096" "2087" "2083" "2053")
        if [[ "${tlsPorts[*]}" =~ "${NEZHA_PORT}" ]]; then
            NEZHA_TLS="--tls"
        else
            NEZHA_TLS=""
        fi
        if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_PORT" ] && [ -n "$NEZHA_KEY" ]; then
            export TMPDIR=$(pwd)
            nohup "$WORKDIR/npm" -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} >/dev/null 2>&1 &
            sleep 2
            pgrep -x "npm" > /dev/null && green "npm is running" || { red "npm is not running, restarting..."; pkill -x "npm" && nohup "$WORKDIR/npm" -s "${NEZHA_SERVER}:${NEZHA_PORT}" -p "${NEZHA_KEY}" ${NEZHA_TLS} >/dev/null 2>&1 & sleep 2; purple "npm restarted"; }
        else
            purple "NEZHA variable is empty, skipping running"
        fi
    fi

    if [ -e "$WORKDIR/web" ]; then
        nohup "$WORKDIR/web" run -c "$WORKDIR/config.json" >/dev/null 2>&1 &
        sleep 2
        pgrep -x "web" > /dev/null && green "web is running" || { red "web is not running, restarting..."; pkill -x "web" && nohup "$WORKDIR/web" run -c "$WORKDIR/config.json" >/dev/null 2>&1 & sleep 2; purple "web restarted"; }
    fi
}
get_links() {
    # 提示用户输入IP地址
    read -p "请输入IP地址（或按回车自动检测）: " user_ip

    # 如果用户输入了IP地址，使用用户提供的IP地址
    if [ -n "$user_ip" ]; then
        IP=$user_ip
    else
        # 自动检测IP地址
        IP=$(curl -s ipv4.ip.sb || { ipv6=$(curl -s --max-time 1 ipv6.ip.sb); echo "[$ipv6]"; })
    fi

    # 输出最终使用的IP地址
    echo "设备的IP地址是: $IP"

    # 获取IP信息
    ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')

    yellow "注意：v2ray或其他软件的跳过证书验证需设置为true,否则hy2或tuic节点可能不通\n"

    # 生成并保存配置文件
    cat > "$WORKDIR/list.txt" <<EOF
           vless://$UUID@$IP:$vless_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.ups.com&fp=chrome&pbk=$public_key&type=tcp&headerType=none#$ISP

          hysteria2://$UUID@$IP:$hy2_port/?sni=www.bing.com&alpn=h3&insecure=1#$ISP
    
         tuic://$UUID:admin123@$IP:$tuic_port?sni=www.bing.com&congestion_control=bbr&udp_relay_mode=native&alpn=h3&allow_insecure=1#$ISP  

EOF

    cat "$WORKDIR/list.txt"
    purple "list.txt saved successfully"
    purple "Running done!"
    sleep 3
    rm -rf "$WORKDIR/npm" "$WORKDIR/boot.log" "$WORKDIR/sb.log" "$WORKDIR/core"
}


# 定义颜色函数
green() { echo -e "\e[1;32m$1\033[0m"; }
red() { echo -e "\e[1;91m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
reading() { read -p "$(red "$1")" "$2"; }

# 启动 web 函数
    
start_web() {
    # Save the cursor position
    echo -n "正在启动web进程，请稍后......"
    sleep 1  # Optional: pause for a brief moment before starting the process

    if [ -e "$WORKDIR/web" ]; then
        chmod +x "$WORKDIR/web"
        
        # Start the web process
        nohup "$WORKDIR/web" run -c "$WORKDIR/config.json" >"$WORKDIR/web.log" 2>&1 &
        sleep 2

        if pgrep -x "web" > /dev/null; then
            # Clear the initial message and move to the next line
            echo -ne "\r\033[K"
            green "web进程启动成功，并正在运行！"
        else
            # Clear the initial message and move to the next line
            echo -ne "\r\033[K"
            red "web进程启动失败，请重试。检查日志以获取更多信息。"
            echo "查看日志文件以获取详细信息: $WORKDIR/web.log"
        fi
    else
        # Clear the initial message and move to the next line
        echo -ne "\r\033[K"
        red "web可执行文件未找到，请检查路径是否正确。"
    fi
}
    
#停止sing-box服务
    stop_web() {
echo -n -e "\033[1;91m正在清理 sing-box 进程，请稍后......\033[0m"
  sleep 1  # Optional: pause for a brief moment before killing tasks

  # 查找 web 进程的 PID
  WEB_PID=$(pgrep -f 'web')

  if [ -n "$WEB_PID" ]; then
    # 杀死 sing-box 进程
    kill -9 $WEB_PID
    echo "已成功停止 sing-box 服务。"
  else
    echo "未找到 sing-box 进程，可能已经停止。"
  fi

  sleep 2  # Optional: pause to allow the user to see the message before exiting

}
    
# 检查 sing-box 是否已安装
is_singbox_installed() {
    if [ -e "$WORKDIR/web" ]; then
        echo "web 文件存在"
    else
        echo "web 文件不存在"
    fi
    if [ -e "$WORKDIR/npm" ]; then
        echo "npm 文件存在"
    else
        echo "npm 文件不存在"
    fi
    [ -e "$WORKDIR/web" ] || [ -e "$WORKDIR/npm" ]
}
# 终止所有进程
kill_all_tasks() {
  echo -n -e "\033[1;91m正在清理所有进程，请稍后......\033[0m"
  sleep 1  # Optional: pause for a brief moment before killing tasks

  # 获取当前用户名
  USERNAME=$(whoami)
  
  # 调试：打印当前用户名
  echo "当前用户名: $USERNAME"

  # 尝试使用 pkill 来终止所有属于当前用户的进程
  if pkill -u "$USERNAME"; then
    echo "已成功清理所有进程。"
  else
    echo "清理进程失败。请检查是否有足够的权限或进程是否存在。"
  fi

  sleep 2  # Optional: pause to allow the user to see the message before exiting
}

# 主菜单
menu() {
   clear
   echo ""
   purple "=== Serv00|sing-box一键安装脚本 ===\n"
   purple "=== 转载老王脚本，去除tuic协议，增加UUID自动生成 ===\n"
   echo -e "${green}脚本地址：${re}${yellow}https://github.com/yyfalbl/singbox-2${re}\n"
   purple "*****转载请著名出处，请勿滥用*****\n"
   echo ""
   # Example usage
check_singbox_installed
   echo ""
# 显示 web 进程状态（仅在 sing-box 已安装时显示）
  
      echo ""  # 添加空行
       check_web_status
       echo ""  # 添加空行

   echo ""
   green "1. 安装sing-box"
   echo  "==============="
   red "2. 卸载sing-box"
   echo  "==============="
   green "3. 查看节点信息"
   echo  "==============="
   yellow "4. 清理所有进程"
   echo  "==============="
   green "5. 启动web服务"
   echo  "==============="
   green "6. 停止web服务"
   echo  "==============="
   red "0. 退出脚本"
   echo "==========="
   reading "请输入选择(0-6): " choice
   echo ""
    case "${choice}" in
        1) install_singbox ;;
        2) uninstall_singbox ;;
        3) cat $HOME/list.txt ;;
        4) kill_all_tasks ;;
        5) start_web ;;
        6) stop_web ;;
        0) exit 0 ;;
        *) red "无效的选项，请输入 0 到 5" ;;
    esac
}

menu
