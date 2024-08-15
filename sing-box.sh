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
CYAN='\033[0;36m'
RESET='\033[0m'

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

read_vmess_port() {
    
    GREEN='\033[38;5;82m'      # Green color
BOLD='\033[1m'            # Bold text
ITALIC='\033[3m'          # Italic text
RESET='\033[0m'           # Reset to default
    
    while true; do
        reading"${GREEN}${BOLD}${ITALIC}请输入vmess端口 (面板开放的tcp端口): ${RESET}" vmess_port
        if [[ "$vmess_port" =~ ^[0-9]+$ ]] && [ "$vmess_port" -ge 1 ] && [ "$vmess_port" -le 65535 ]; then
            green "你的vmess端口为: $vmess_port"
            break
        else
            yellow "输入错误，请重新输入面板开放的TCP端口"
        fi
    done
}

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
  bold_italic_yellow="\033[1;3;33m"
bold_italic_purple="\033[1;3;35m"
RESET="\033[0m"
  
#安装sing-box
install_singbox() {
     echo -e "${bold_italic_yellow}本脚本可以选择性安装四种协议 ${bold_italic_purple}(vless-reality | vmess | hysteria2 | tuic | 固定argo隧道 )${RESET}"
    echo -e "${bold_italic_yellow}开始运行前，请确保面板中 ${bold_italic_purple}已开放3个端口，一个TCP端口，两个UDP端口${RESET}"
    echo -e "${bold_italic_yellow}面板中 ${bold_italic_purple}Additional services中的Run your own applications${bold_italic_yellow}选项已开启为 ${bold_italic_purple}Enabled${bold_italic_yellow} 状态${RESET}"

    # 使用黄色粗体显示提示信息
   echo -e "${bold_italic_yellow}确定继续安装吗?<ENTER默认安装>【y/n】${reset}: "
    read -p "" choice
    choice=${choice:-y}  # Default to y

    if [[ "$choice" != [Yy] ]]; then
        echo -e "$(bold_italic_red "安装已取消")"
        exit 0
    fi

    # Continue with the installation process
    WORKDIR="$HOME/sbox"
    mkdir -p "$WORKDIR"
    cd "$WORKDIR"

    # Set certificate and key paths
    CERT_PATH="${HOME}/sbox/cert.pem"
    PRIVATE_KEY_PATH="${HOME}/sbox/private.key"

    # Display service options with numbers
    echo -e "${GREEN}\033[1m\033[3m请选择需要安装的服务（请输入对应的序号）：${RESET}"
  echo -e "${bold_italic_yellow}1: vless-reality${RESET}"
  echo -e "${bold_italic_yellow}2: vmess${RESET}"

echo -e "${bold_italic_yellow}4: hysteria2${RESET}"
echo -e "${bold_italic_yellow}5: tuic${RESET}"
echo -e "${bold_italic_yellow}6: 全部安装${RESET}"
read -p "$(echo -e ${bold_italic_yellow}请输入你的选择${RESET}): " choices


    # Initialize installation variables
    INSTALL_VLESS="false"
    INSTALL_VMESS="false"
    INSTALL_HYSTERIA2="false"
    INSTALL_TUIC="false"

    # Process user input
    for choice in $choices; do
        case "$choice" in
            1) INSTALL_VLESS="true" ;;
            2) INSTALL_VMESS="true" ;;
            3) INSTALL_HYSTERIA2="true" ;;
            4) INSTALL_TUIC="true" ;;
            5) INSTALL_VLESS="true"; INSTALL_HYSTERIA2="true"; INSTALL_TUIC="true" ;;
            *) echo -e "$(bold_italic_red "无效的选择: $choice")" ;;
        esac
    done

    # Read port numbers for selected services
   if [ "$INSTALL_VLESS" = "true" ]; then
     read -p "$(echo -e "${RED}\033[1m\033[3m请输入vless-reality端口 (面板开放的tcp端口): ${RESET}")" vless_port
fi

   if [ "$INSTALL_VMESS" = "true" ]; then
     read -p "$(echo -e "${RED}\033[1m\033[3m请输入vmess端口 (面板开放的tcp端口): ${RESET}")" vmess_port
fi
argo_configure
if [ "$INSTALL_HYSTERIA2" = "true" ]; then
read -p "$(echo -e "${RED}\033[1m\033[3m请输入hysteria2端口 (面板开放的udp端口): ${RESET}")" hy2_port
fi

if [ "$INSTALL_TUIC" = "true" ]; then
      read -p "$(echo -e "${RED}\033[1m\033[3m请输入tuic端口 (面板开放的udp端口): ${RESET}")" tuic_port
fi
    # Download sing-box
    download_singbox && wait

    # Generate configuration file
    generate_config

    # Configure services based on user selection
    if [ "$INSTALL_VLESS" = "true" ]; then
       echo -e "$(echo -e "${GREEN}\033[1m\033[3m配置 VLESS...${RESET}")"
        # Your VLESS configuration code here
    fi
    
     if [ "$INSTALL_VMESS" = "true" ]; then
       echo -e "$(echo -e "${GREEN}\033[1m\033[3m配置 VMESS...${RESET}")"
        # Your VMESS configuration code here
    fi

    if [ "$INSTALL_HYSTERIA2" = "true" ]; then
     echo -e "$(echo -e "${GREEN}\033[1m\033[3m配置 Hysteria2...${RESET}")"
        # Your Hysteria2 configuration code here
    fi

    if [ "$INSTALL_TUIC" = "true" ]; then
       echo -e "$(echo -e "${GREEN}\033[1m\033[3m配置 TUIC...${RESET}")"
        # Your TUIC configuration code here
    fi

    # Run sing-box
    run_sb && sleep 3

    # Get links
    get_links
    
    echo -e "$(bold_italic_purple "安装完成！")"
}

#固定argo隧道
argo_configure() {
    
    # Define color codes
BRIGHT_BLUE='\033[38;5;33m' # Bright blue color
BOLD='\033[1m'             # Bold text
ITALIC='\033[3m'           # Italic text
RESET='\033[0m'            # Reset to default
    
  if [[ -z $ARGO_AUTH || -z $ARGO_DOMAIN ]]; then
     reading "${BRIGHT_BLUE}${BOLD}${ITALIC}是否需要使用固定argo隧道？【y/n】：${RESET}" argo_choice
      [[ -z $argo_choice ]] && return
      [[ "$argo_choice" != "y" && "$argo_choice" != "Y" && "$argo_choice" != "n" && "$argo_choice" != "N" ]] && { red "无效的选择，请输入y或n"; return; }
      if [[ "$argo_choice" == "y" || "$argo_choice" == "Y" ]]; then
          # 读取 ARGO_DOMAIN 变量
          while [[ -z $ARGO_DOMAIN ]]; do
            reading "请输入argo固定隧道域名: " ARGO_DOMAIN
            if [[ -z $ARGO_DOMAIN ]]; then
                red "ARGO固定隧道域名不能为空，请重新输入。"
            else
                green "你的argo固定隧道域名为: $ARGO_DOMAIN"
            fi
          done
        
          # 读取 ARGO_AUTH 变量
          while [[ -z $ARGO_AUTH ]]; do
            reading "请输入argo固定隧道密钥（Json或Token）: " ARGO_AUTH
            if [[ -z $ARGO_AUTH ]]; then
                red "ARGO固定隧道密钥不能为空，请重新输入。"
            else
                green "你的argo固定隧道密钥为: $ARGO_AUTH"
            fi
          done           
    # reading "请输入argo固定隧道域名: " ARGO_DOMAIN
   #        green "你的argo固定隧道域名为: $ARGO_DOMAIN"
   #        reading "请输入argo固定隧道密钥（Json或Token）: " ARGO_AUTH
   #        green "你的argo固定隧道密钥为: $ARGO_AUTH"
    echo -e "${red}注意：${purple}使用token，需要在cloudflare后台设置隧道端口和面板开放的tcp端口一致${re}"
      else
          green "ARGO隧道变量未设置，将使用临时隧道"
          return
      fi
  fi

  if [[ $ARGO_AUTH =~ TunnelSecret ]]; then
    echo $ARGO_AUTH > tunnel.json
    cat > tunnel.yml << EOF
tunnel: $(cut -d\" -f12 <<< "$ARGO_AUTH")
credentials-file: tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:$vmess_port
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
  else
    green "ARGO_AUTH mismatch TunnelSecret,use token connect to tunnel"
  fi
}
  
uninstall_singbox() {
    echo -e "$(bold_italic_purple "正在卸载sing-box，请稍后...")"
    read -p $'\033[1;3;38;5;220m确定要卸载吗?<ENTER默认Y>【y/n】:\033[0m ' choice
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
      # if [[ -z $ARGO_AUTH || -z $ARGO_DOMAIN ]]; then
      #   FILE_INFO=("https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-sb web")
      # else
        FILE_INFO=("https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-sb web" "https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-bot13 bot")
      # fi
      # FILE_INFO=("https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-sb web" "https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-bot13 bot" "https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-swith npm")
  elif [ "$ARCH" == "amd64" ] || [ "$ARCH" == "x86_64" ] || [ "$ARCH" == "x86" ]; then
      # if [[ -z $ARGO_AUTH || -z $ARGO_DOMAIN ]]; then
      #   FILE_INFO=("https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/amd64-web web")
      # else
        FILE_INFO=("https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/amd64-web web" "https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/amd64-bot bot")
      # fi
      # FILE_INFO=("https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/amd64-web web" "https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-bot bot" "https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-npm npm")
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
    
 # Define color codes
YELLOW="\033[33m"
RESET="\033[0m"
 
 # Define default paths using the current user's home directory
CERT_PATH="${HOME}/sbox/cert.pem"
PRIVATE_KEY_PATH="${HOME}/sbox/private.key"
 
generate_config() {
    # Generate reality key pair
    output=$(./web generate reality-keypair)
    private_key=$(echo "${output}" | awk '/PrivateKey:/ {print $2}')
    public_key=$(echo "${output}" | awk '/PublicKey:/ {print $2}')

    # Generate TLS certificate and key
    openssl ecparam -genkey -name prime256v1 -out "$WORKDIR/private.key"
    openssl req -new -x509 -days 3650 -key "$WORKDIR/private.key" -out "$WORKDIR/cert.pem" -subj "/CN=$HOSTNAME"

   # 确保用户提供了端口号
if [ -z "$vless_port" ] && [ -z "$vmess_port" ] && [ -z "$hy2_port" ] && [ -z "$tuic_port" ]; then
    echo "Error: No port number provided. Configuration file will not be generated."
    return 1
fi

    # Create configuration file based on selected services
    cat > "$WORKDIR/config.json" <<EOF
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
    $(if [ "$INSTALL_VLESS" = "true" ]; then
        echo '{
          "tag": "vless-reality-version",
          "type": "vless",
          "listen": "::",
          "listen_port": '"$vless_port"',
          "users": [
            {
              "uuid": "'"$UUID"'",
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
              "private_key": "'"$private_key"'",
              "short_id": [
                ""
              ]
            }
          }
        }'
      fi)
    $(if [ "$INSTALL_VMESS" = "true" ]; then
        echo '{
          "tag": "vmess-ws-in",
          "type": "vmess",
          "listen": "::",
          "listen_port": '"$vmess_port"',
          "users": [
            {
              "uuid": "'"$UUID"'"
            }
          ],
          "transport": {
            "type": "ws",
            "path": "/vmess",
            "early_data_header_name": "Sec-WebSocket-Protocol"
          }
        }'
      fi)
    $(if [ "$INSTALL_HYSTERIA2" = "true" ]; then
        echo '{
          "tag": "hysteria-in",
          "type": "hysteria2",
          "listen": "::",
          "listen_port": '"$hy2_port"',
          "users": [
            {
              "password": "'"$UUID"'"
            }
          ],
          "masquerade": "https://bing.com",
          "tls": {
            "enabled": true,
            "alpn": [
              "h3"
            ],
            "certificate_path": "'"$CERT_PATH"'",
            "key_path": "'"$PRIVATE_KEY_PATH"'"
          }
        }'
      fi)
    $(if [ "$INSTALL_TUIC" = "true" ]; then
        echo '{
          "tag": "tuic-in",
          "type": "tuic",
          "listen": "::",
          "listen_port": '"$tuic_port"',
          "users": [
            {
              "uuid": "'"$UUID"'",
              "password": "admin123"
            }
          ],
          "congestion_control": "bbr",
          "tls": {
            "enabled": true,
            "alpn": [
              "h3"
            ],
            "certificate_path": "'"$CERT_PATH"'",
            "key_path": "'"$PRIVATE_KEY_PATH"'"
          }
        }'
      fi)
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
       # else
        #     purple "NEZHA variable is empty, skipping running"
        fi
    fi

    if [ -e "$WORKDIR/web" ]; then
        nohup "$WORKDIR/web" run -c "$WORKDIR/config.json" >/dev/null 2>&1 &
        sleep 2
        pgrep -x "web" > /dev/null && green "web is running" || { red "web is not running, restarting..."; pkill -x "web" && nohup "$WORKDIR/web" run -c "$WORKDIR/config.json" >/dev/null 2>&1 & sleep 2; purple "web restarted"; }
    fi
    
      if [ -e $WORKDIR/bot ]; then
    if [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
      args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token ${ARGO_AUTH}"
    elif [[ $ARGO_AUTH =~ TunnelSecret ]]; then
      args="tunnel --edge-ip-version auto --config tunnel.yml run"
    else
      args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile boot.log --loglevel info --url http://localhost:$vmess_port"
    fi
    nohup $WORKDIR/bot $args >/dev/null 2>&1 &
    sleep 2
    pgrep -x "bot" > /dev/null && green "bot is running" || { red "bot is not running, restarting..."; pkill -x "bot" && nohup $WORKDIR/bot "${args}" >/dev/null 2>&1 & sleep 2; purple "bot restarted"; }
  fi
}
get_links() {
  
    get_argodomain() {
    if [[ -n $ARGO_AUTH ]]; then
      echo "$ARGO_DOMAIN"
    else
      grep -oE 'https://[[:alnum:]+\.-]+\.trycloudflare\.com' boot.log | sed 's@https://@@'
    fi
  }
argodomain=$(get_argodomain)
echo -e "\e[1;32mArgoDomain:\e[1;35m${argodomain}\e[0m\n"
sleep 1
  
    # 提示用户输入IP地址
   read -p "$(echo -e "${CYAN}\033[1m请输入IP地址（或按回车自动检测）: ${RESET}")" user_ip

    # 如果用户输入了IP地址，使用用户提供的IP地址
    if [ -n "$user_ip" ]; then
        IP=$user_ip
    else
        # 自动检测IP地址
        IP=$(curl -s ipv4.ip.sb || { ipv6=$(curl -s --max-time 1 ipv6.ip.sb); echo "[$ipv6]"; })
    fi

    # 输出最终使用的IP地址
    echo -e "${CYAN}\033[1m设备的IP地址是: $IP${RESET}"
    # 获取IP信息
      USERNAME=$(whoami)
   echo ""
    yellow "注意：v2ray或其他软件的跳过证书验证需设置为true,否则hy2或tuic节点可能不通\n"

    # 生成并保存配置文件
cat <<EOF > "$WORKDIR/list.txt"
$(if [ "$INSTALL_VLESS" = "true" ]; then
    echo -e "${YELLOW}\033[1mvless://$UUID@$IP:$vless_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.ups.com&fp=chrome&pbk=$public_key&type=tcp&headerType=none#${USERNAME}${RESET}"
fi)

$(if [ "$INSTALL_VMESS" = "true" ]; then
    echo -e "${YELLOW}\033[1mvmess://$(echo "{ \"v\": \"2\", \"ps\": \"${USERNAME}\", \"add\": \"$IP\", \"port\": \"$vmess_port\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\", \"path\": \"/vmess?ed=2048\", \"tls\": \"\", \"sni\": \"\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)${RESET}"
fi)

$(if [ "$INSTALL_VMESS" = "true" ]; then
    echo -e "${YELLOW}\033[1mvmess://$(echo "{ \"v\": \"2\", \"ps\": \"${USERNAME}\", \"add\": \"www.visa.com\", \"port\": \"443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)${RESET}"
fi)

$(if [ "$INSTALL_HYSTERIA2" = "true" ]; then
    echo -e "${YELLOW}\033[1mhysteria2://$UUID@$IP:$hy2_port/?sni=www.bing.com&alpn=h3&insecure=1#${USERNAME}${RESET}"
fi)

$(if [ "$INSTALL_TUIC" = "true" ]; then
    echo -e "${YELLOW}\033[1mtuic://$UUID:admin123@$IP:$tuic_port?sni=www.bing.com&congestion_control=bbr&udp_relay_mode=native&alpn=h3&allow_insecure=1#${USERNAME}${RESET}"
fi)
EOF

# 显示生成的 list.txt 内容
cat "$WORKDIR/list.txt"
purple "list.txt saved successfully"
purple "Running done!"

# 清理临时文件
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
# Function to prompt user for choice and kill processes accordingly
manage_processes() {
  # Define color codes
  RED_BOLD='\033[1;31m'
  RESET='\033[0m'
    RED_BOLD='\033[1;31m'
  YELLOW='\033[1;33m'
  RESET='\033[0m'
  
  # 获取当前用户名
  USERNAME=$(whoami)
  
  echo -e "${RED_BOLD}请选择要执行的操作:${RESET}"
  echo -e "${RED_BOLD}1. 清理所有进程,会断开连接${RESET}"
  echo -e "${RED_BOLD}2. 只清理当前用户的进程${RESET}"
printf "${YELLOW}输入选择 (1 或 2): ${RESET}"
  read -r choice

  case $choice in
    1)
      if pkill -kill -u "$USERNAME"; then
        echo -e "${RED_BOLD}已成功清理所有进程。${RESET}"
      else
        echo -e "${RED_BOLD}清理进程失败。请检查是否有足够的权限或进程是否存在。${RESET}"
      fi
      ;;
    2)
      if pkill -u "$USERNAME"; then
        echo -e "${RED_BOLD}已成功清理所有属于用户 $USERNAME 的进程。${RESET}"
      else
        echo -e "${RED_BOLD}清理进程失败。请检查是否有足够的权限或进程是否存在。${RESET}"
      fi
      ;;
    *)
      echo -e "${RED_BOLD}无效的选择。${RESET}"
      ;;
  esac

  sleep 2  # Optional: pause to allow the user to see the message before exiting
}


# 主菜单
menu() {
   clear
   echo ""
   purple "=== Serv00|sing-box一键安装脚本 ===\n"
   purple "=== 脚本更新，VLESS VMESS HY2 TUIC  协议，增加UUID自动生成 ===\n"
    purple "===  固定argo隧道 注意最多只能安装三个协议！ ===\n"
  echo -e "${green}脚本地址：${re}\033[1;3;33mhttps://github.com/yyfalbl/singbox-2\033[0m${re}\n"
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
   yellow "4. 清理系统进程"
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
        3) cat $WORKDIR/list.txt ;;
        4) manage_processes ;;
        5) start_web ;;
        6) stop_web ;;
        0) exit 0 ;;
        *) red "无效的选项，请输入 0 到 5" ;;
    esac
}

menu
