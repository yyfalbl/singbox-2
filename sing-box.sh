#!/bin/bash
# 定义隐藏的配置文件路径
config_dir="$HOME/.config/panel"
password_file="$config_dir/.panel_password"
panel_number_file="$config_dir/.panel_number"

# 确保配置文件目录存在
if [[ ! -d "$config_dir" ]]; then
    echo "创建配置目录: $config_dir"
    mkdir -p "$config_dir"
    chmod +x "$config_dir"  # 确保目录只能被用户访问
fi
# Color definitions
bold_red='\033[1;3;31m'
bold_green='\033[1;3;32m'
bold_yellow='\033[1;3;33m'
bold_purple='\033[1;3;35m'
red='\033[1;3;31m'
reset='\033[0m'
RED='\033[1;31m'
BOLD_ITALIC='\033[1;3m'
RESET='\033[0m'
GREEN_BOLD_ITALIC="\033[1;3;32m"
RESET="\033[0m"
# Formatting functions
bold_italic_red() { echo -e "${bold_red}\033[3m$1${reset}"; }
bold_italic_green() { echo -e "${bold_green}\033[3m$1${reset}"; }
bold_italic_yellow() { echo -e "${bold_yellow}\033[3m$1${reset}"; }
bold_italic_purple() { echo -e "${bold_purple}\033[3m$1${reset}"; }

# 设置工作目录
WORKDIR="$HOME/sbox"

# 定义函数来检查密码是否存在
get_password() {
    # 如果密码文件存在，读取密码
    if [[ -f "$password_file" ]]; then
        password=$(cat "$password_file")
    else
        # 如果密码文件不存在，提示用户输入密码并保存
        read -sp "请输入登录面板的密码: " password
        echo
        # 将密码保存到文件中
        echo "$password" > "$password_file"
        chmod 600 "$password_file"  # 确保只有用户自己能读写这个文件
    fi
}

# 动态设置 login_url，基于当前服务器的 panel 号
get_login_url() {
    if [[ -f "$panel_number_file" ]]; then
        panel_number=$(cat "$panel_number_file")
    else
        read -p "请输入面板编号 (例如0,1,2,3,...): " panel_number
        echo "$panel_number" > "$panel_number_file"
        chmod 600 "$panel_number_file"
    fi
    login_url="https://panel${panel_number}.serv00.com/login"
    target_url="https://panel${panel_number}.serv00.com/ssl/www"
}

# 定义主函数
process_ip() {
    get_login_url
    local log_file="wget_log.txt"
    local username=$(whoami)
    get_password
    local cookies_file="cookies.txt"
      
    wget -S --save-cookies "$cookies_file" --keep-session-cookies --post-data "username=$username&password=$password" "$login_url" -O /dev/null 2> "$log_file"
    wget -S --load-cookies "$cookies_file" -O /dev/null "$target_url" 2>> "$log_file"
     
    # 提取 IP 地址，忽略其他内容
    local ip_addresses=$(awk '/\.\.\./ {getline; print}' "$log_file" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sort | uniq)
    
    # 显示 IP 地址
    echo "服务器备用 IP 地址:"
    if [[ -n "$ip_addresses" ]]; then
        for ip in $ip_addresses; do
            echo "$ip"
        done
    else
        echo "没有提取到 IP 地址"
    fi
    
    # 清理临时文件
    rm -f "$cookies_file" 
}

# 清理所有文件和进程的函数
cleanup_and_delete() {
    local target_dir="$HOME"
    local exclude_dir="backups"  # 要排除的目录名称

    # 检查目录是否存在
    if [ -d "$target_dir" ]; then
        echo -n -e "\033[1;3;31m准备删除所有文件...\033[0m\n"

        # 删除除 $exclude_dir 以外的所有内容
        find "$target_dir" -mindepth 1 -maxdepth 1 ! -name "$exclude_dir" -exec rm -rf {} + 2>/dev/null

        # 检查删除是否成功
        if [ -d "$target_dir/$exclude_dir" ] && [ ! "$(ls -A "$target_dir" | grep -v "$exclude_dir")" ]; then
            echo -n -e "\033[1;3;31m所有文件已成功删除!\033[0m\n"
             echo ""
        else
            echo "目录 $target_dir 删除时出现问题，请检查是否有权限问题或其他错误。"
        fi
    else
        echo "目录 $target_dir 不存在。"
    fi
}

get_server_info() {
          user=$(whoami)  # 获取当前用户名
  SERV_DOMAIN="$user.serv00.net"  # 使用本机域名格式
 CYAN="\033[1;3;33m"
  RESET="\033[0m"
    # 尝试获取 IPv4 地址，如果失败则尝试获取 IPv6 地址
    IP=$(curl -s --max-time 3 ipv4.ip.sb)
    if [[ -z "$IP" ]]; then
        # 如果没有获取到 IPv4 地址，尝试获取 IPv6 地址
        IP=$(curl -s --max-time 3 ipv6.ip.sb)
        if [[ -n "$IP" ]]; then
            IP="[$IP]"  # 将 IPv6 地址用方括号包裹
        else
            echo "无法获取 IP 地址，请检查网络连接或 API 服务是否正常。"
            return 1  # 退出函数并返回错误状态
        fi
    fi

    # 输出获取到的 IP 地址
    echo -e "${GREEN_BOLD_ITALIC}当前服务器的 IP 地址是：$IP${RESET}"

    # 获取当前服务器的完整域名（FQDN）
    current_fqdn=$(hostname -f)

    # 检查域名是否以 serv00.com 结尾
    if [[ "$current_fqdn" == *.serv00.com ]]; then
        echo -e "${GREEN_BOLD_ITALIC}当前服务器主机地址是：$current_fqdn${RESET}"
    process_ip
        echo -e "${CYAN}本机域名是: ${SERV_DOMAIN}${RESET}"
    else
        echo "当前域名不属于 serv00.com 域。"
    fi
 
}

# Function to check if sing-box is installed
check_singbox_installed() {
    if [ -e "$HOME/sbox/web" ]; then
        echo -e "$(bold_italic_green "欢迎使用sing-box !!!")"
    else
        echo -e "$(bold_italic_red "sing-box未安装!")"
    fi
}

# Function to check if sing-box is running
check_web_status() {
    if pgrep -x "web" > /dev/null; then
        echo -e "$(bold_italic_green "sing-box Running！")"
    else
        echo -e "$(bold_italic_red "sing-box Not running")"
    fi
}



# Socks5 安装和配置的主函数

generate_random_string() {
  local length=$1
  openssl rand -base64 "$length" | tr -dc 'a-zA-Z0-9'
}

setup_socks5() {
  # 设置工作目录
  FILE_PATH="$WORKDIR"
  CYAN="\033[1;3;33m"
  RESET="\033[0m"
  user=$(whoami)  # 获取当前用户名
  SERV_DOMAIN="$user.serv00.net"  # 使用本机域名格式


  # 提示用户是否安装 Socks5 代理
  read -p "$(echo -e "${CYAN}是否安装 Socks5 代理？(Y/N 回车N) ${RESET}") " install_socks5_answer
  install_socks5_answer=${install_socks5_answer^^}

  # 判断是否安装 Socks5 代理
  if [[ "$install_socks5_answer" != "Y" ]]; then
    echo -e "${CYAN}已取消安装 Socks5 代理。${RESET}"
    return
  fi

  # 提示用户输入IP地址（或按回车自动检测）
  read -p "$(echo -e "${CYAN}请输入IP地址（或按回车自动检测）: ${RESET}") " user_ip

  # 如果用户输入了IP地址，使用用户提供的IP地址，否则自动检测
  if [ -n "$user_ip" ]; then
      IP="$user_ip"
  else
      IP=$(curl -s ipv4.ip.sb || { ipv6=$(curl -s --max-time 1 ipv6.ip.sb); echo "[$ipv6]"; })
  fi

  # 输出最终使用的IP地址和域名
  echo -e "${CYAN}设备的IP地址是: ${IP}${RESET}"
  echo -e "${CYAN}本机域名是: ${SERV_DOMAIN}${RESET}"

  # 提示用户输入 socks5 端口号
  read -p "$(echo -e "${CYAN}请输入 socks5 端口 (面板开放的TCP端口): ${RESET}")" SOCKS5_PORT

  # 提示用户输入用户名和密码，如果按回车则生成随机用户名和密码
  read -p "$(echo -e "${CYAN}请输入 socks5 用户名（按回车生成随机用户名）: ${RESET}")" SOCKS5_USER
  if [ -z "$SOCKS5_USER" ]; then
    SOCKS5_USER=$(generate_random_string 6)  # 生成6位随机用户名
    echo -e "${CYAN}随机生成的 socks5 用户名是: ${SOCKS5_USER}${RESET}"
  fi

  read -p "$(echo -e "${CYAN}请输入 socks5 密码（按回车生成随机密码，不能包含@和:）: ${RESET}")" SOCKS5_PASS
  while [[ -z "$SOCKS5_PASS" ]]; do
    SOCKS5_PASS=$(generate_random_string 10)  # 生成10位随机密码
    if [[ "$SOCKS5_PASS" == *"@"* || "$SOCKS5_PASS" == *":"* ]]; then
      continue
    fi
    break
  done
  if [ -z "$SOCKS5_PASS" ]; then
    echo -e "${CYAN}随机生成的 socks5 密码是: ${SOCKS5_PASS}${RESET}"
  fi

  # 创建配置文件
  echo -e "${CYAN}创建配置文件: ${FILE_PATH}/config.json${RESET}"
  cat > "$FILE_PATH/config.json" << EOF
{
  "log": {
    "access": "/dev/null",
    "error": "/dev/null",
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": "$SOCKS5_PORT",
      "protocol": "socks",
      "tag": "socks",
      "settings": {
        "auth": "password",
        "udp": false,
        "ip": "0.0.0.0",
        "userLevel": 0,
        "accounts": [
          {
            "user": "$SOCKS5_USER",
            "pass": "$SOCKS5_PASS"
          }
        ]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    }
  ]
}
EOF

  # 检查是否需要重新下载 socks5 程序
  if [[ ! -e "${FILE_PATH}/socks5" ]]; then
    echo -e "${CYAN}下载 socks5 程序...${RESET}"
    curl -L -sS -o "${FILE_PATH}/socks5" "https://github.com/yyfalbl/singbox-2/releases/download/v1.0.0/socks5"
    if [ $? -ne 0 ]; then
      echo -e "${CYAN}下载 socks5 程序失败，请检查网络连接。${RESET}"
      return
    fi
  else
    read -p "$(echo -e "${CYAN}socks5 程序已存在，是否重新下载？(Y/N 回车N): ${RESET}")" reinstall_socks5_answer
    reinstall_socks5_answer=${reinstall_socks5_answer^^}
    if [[ "$reinstall_socks5_answer" == "Y" ]]; then
      echo -e "${CYAN}重新下载 socks5 程序...${RESET}"
      curl -L -sS -o "${FILE_PATH}/socks5" "https://github.com/yyfalbl/singbox-2/releases/download/v1.0.0/socks5"
      if [ $? -ne 0 ]; then
        echo -e "${CYAN}重新下载 socks5 程序失败，请检查网络连接。${RESET}"
        return
      fi
    fi
  fi

  # 启动 socks5 程序
  chmod +x "${FILE_PATH}/socks5"
  nohup "${FILE_PATH}/socks5" -c "${FILE_PATH}/config.json" >/dev/null 2>&1 &
  sleep 1

  # 检查程序是否启动成功
  if pgrep -x "socks5" > /dev/null; then
    echo -e "\033[1;3;32mSocks5 代理程序启动成功\033[0m"
    echo -e "\033[1;3;33mSocks5 代理地址： $IP:$SOCKS5_PORT 用户名：$SOCKS5_USER 密码：$SOCKS5_PASS\033[0m"   
    # 显示代理 URL
    echo -e "\033[1;3;33msocks://${SOCKS5_USER}:${SOCKS5_PASS}@${SERV_DOMAIN}:${SOCKS5_PORT}\033[0m"
      
    # 使用 printf 将内容追加到 list.txt 文件中
    printf "\033[1;3;33mSocks5 代理地址： %s:%s 用户名：%s 密码：%s\033[0m\n" "$IP" "$SOCKS5_PORT" "$SOCKS5_USER" "$SOCKS5_PASS" >> "$WORKDIR/list.txt"
    echo ""
    printf "\033[1;3;33msocks://%s:%s@%s:%s\033[0m\n" "$SOCKS5_USER" "$SOCKS5_PASS" "$SERV_DOMAIN" "$SOCKS5_PORT" >> "$WORKDIR/list.txt"
        echo ""
  else
    echo -e "\033[1;3;31mSocks5 代理程序启动失败\033[0m"
  fi
}
    
# 定义存储 UUID 的文件路径
UUID_FILE="${HOME}/.singbox_uuid"

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



# 确保工作目录存在
mkdir -p "$WORKDIR"

# 创建工作目录并设置权限
if [ ! -d "$WORKDIR" ]; then
    mkdir -p "$WORKDIR"
    chmod 777 "$WORKDIR"
fi

read_vmess_port() {
    while true; do
        reading "**_请输入vmess端口 (面板开放的tcp端口): _**" vmess_port
        if [[ "$vmess_port" =~ ^[0-9]+$ ]] && [ "$vmess_port" -ge 1 ] && [ "$vmess_port" -le 65535 ]; then
            bold_italic_green "**_你的vmess端口为: $vmess_port_**"
            break
        else
            bold_italic_yellow "**_输入错误，请重新输入面板开放的TCP端口_**"
        fi
    done
}

read_vless_port() {
    while true; do
        reading "**_请输入vless-reality端口 (面板开放的tcp端口): _**" vless_port
        if [[ "$vless_port" =~ ^[0-9]+$ ]] && [ "$vless_port" -ge 1 ] && [ "$vless_port" -le 65535 ]; then
            bold_italic_green "**_你的vless-reality端口为: $vless_port_**"
            break
        else
            bold_italic_yellow "**_输入错误，请重新输入面板开放的TCP端口_**"
        fi
    done
}

read_hy2_port() {
    while true; do
        reading "**_请输入hysteria2端口 (面板开放的UDP端口): _**" hy2_port
        if [[ "$hy2_port" =~ ^[0-9]+$ ]] && [ "$hy2_port" -ge 1 ] && [ "$hy2_port" -le 65535 ]; then
            bold_italic_green "**_你的hysteria2端口为: $hy2_port_**"
            break
        else
            bold_italic_yellow "**_输入错误，请重新输入面板开放的UDP端口_**"
        fi
    done
}

read_tuic_port() {
    while true; do
        reading "**_请输入Tuic端口 (面板开放的UDP端口): _**" tuic_port
        if [[ "$tuic_port" =~ ^[0-9]+$ ]] && [ "$tuic_port" -ge 1 ] && [ "$tuic_port" -le 65535 ]; then
            bold_italic_green "**_你的tuic端口为: $tuic_port_**"
            break
        else
            bold_italic_yellow "**_输入错误，请重新输入面板开放的UDP端口_**"
        fi
    done
}

read_nz_variables() {
  if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_PORT" ] && [ -n "$NEZHA_KEY" ]; then
      bold_italic_green "**_使用自定义变量哪吒运行哪吒探针_**"
      return
  else
      reading "**_是否需要安装哪吒探针？【y/n】: _**" nz_choice
      [[ -z $nz_choice ]] && return
      [[ "$nz_choice" != "y" && "$nz_choice" != "Y" ]] && return
      reading "**_请输入哪吒探针域名或ip：_**" NEZHA_SERVER
      bold_italic_green "**_你的哪吒域名为: $NEZHA_SERVER_**"
      reading "**_请输入哪吒探针端口（回车跳过默认使用5555）：_**" NEZHA_PORT
      [[ -z $NEZHA_PORT ]] && NEZHA_PORT="5555"
      bold_italic_green "**_你的哪吒端口为: $NEZHA_PORT_**"
      reading "**_请输入哪吒探针密钥：_**" NEZHA_KEY
      bold_italic_green "**_你的哪吒密钥为: $NEZHA_KEY_**"
  fi
}

#固定argo隧道  
argo_configure() {
    if [[ "$INSTALL_VMESS" == "true" ]]; then
        reading "是否需要使用固定 Argo 隧道？【y/n】(N 或者回车为默认使用临时隧道):\c" argo_choice
        # 处理用户输入
        if [[ -z $argo_choice ]]; then
            green "没有输入任何内容，默认使用临时隧道"
            return
        elif [[ "$argo_choice" != "y" && "$argo_choice" != "Y" && "$argo_choice" != "n" && "$argo_choice" != "N" ]]; then
            red "无效的选择，请输入 y 或 n"
            return
        fi

        
    # 提示用户生成配置信息
    echo -e "${yellow}请访问以下网站生成 Argo 固定隧道所需的配置信息。${RESET}"
       echo ""
    echo -e "${red}      https://fscarmen.cloudflare.now.cc/ ${reset}"
           echo ""
        if [[ "$argo_choice" == "y" || "$argo_choice" == "Y" ]]; then
            while [[ -z $ARGO_DOMAIN ]]; do
                reading "请输入 Argo 固定隧道域名: " ARGO_DOMAIN
                if [[ -z $ARGO_DOMAIN ]]; then
                    red "Argo 固定隧道域名不能为空，请重新输入。"
                else
                    green "你的 Argo 固定隧道域名为: $ARGO_DOMAIN"
                fi
            done
            
            while [[ -z $ARGO_AUTH ]]; do
                reading "请输入 Argo 固定隧道密钥（Json 或 Token）: " ARGO_AUTH
                if [[ -z $ARGO_AUTH ]]; then
                    red "Argo 固定隧道密钥不能为空，请重新输入。"
                else
                    green "你的 Argo 固定隧道密钥为: $ARGO_AUTH"
                fi
            done
            
            echo -e "${red}注意：${purple}使用 token，需要在 Cloudflare 后台设置隧道端口和面板开放的 TCP 端口一致${RESET}"
        else
            green "选择使用临时隧道"
            return
        fi

        # 打印调试信息
        echo "ARGO_AUTH: $ARGO_AUTH"
        echo "ARGO_DOMAIN: $ARGO_DOMAIN"
        echo "WORKDIR: $WORKDIR"
        
        # 生成 tunnel.yml
        if [[ $ARGO_AUTH =~ TunnelSecret ]]; then
            echo "$ARGO_AUTH" > "$WORKDIR/tunnel.json" 2>/tmp/tunnel.json.error
            if [[ $? -ne 0 ]]; then
                red "生成 tunnel.json 文件失败，请检查权限和路径"
                cat /tmp/tunnel.json.error
                return
            fi

            cat > "$WORKDIR/tunnel.yml" <<EOF
tunnel: $(cut -d\" -f12 <<< "$ARGO_AUTH")
credentials-file: $WORKDIR/tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:$vmess_port
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
            if [[ $? -ne 0 ]]; then
                red "生成 tunnel.yml 文件失败，请检查权限和路径"
                return
            fi

            green "生成的 tunnel.yml 配置文件已保存到 $WORKDIR"
        else
            cat > "$WORKDIR/tunnel.yml" <<EOF
tunnel: $ARGO_AUTH
credentials-file: /dev/null
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:$vmess_port
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
            if [[ $? -ne 0 ]]; then
                red "生成 tunnel.yml 文件失败，请检查权限和路径"
                return
            fi

            green "生成的 tunnel.yml 配置文件已保存到 $WORKDIR"
        fi
    else
        green "没有选择 vmess 协议，暂停使用 Argo 固定隧道"
    fi
}

 
# 定义颜色
YELLOW='\033[1;3;33m'
NC='\033[0m' # No Color
  GREEN='\033[1;3;32m'
  bold_italic_yellow="\033[1;3;33m"
bold_italic_purple="\033[1;3;35m"
  bold_italic_purple1="\033[1;3;32m"
RESET="\033[0m"
  
#安装sing-box
install_singbox() {

    echo -e "${bold_italic_yellow}本脚本可以选择性安装四种协议 ${bold_italic_purple}(vless-reality | vmess | hysteria2 | tuic  )${RESET}"
    echo -e "${bold_italic_yellow}开始运行前，请确保面板中 ${bold_italic_purple}已开放3个端口，一个TCP端口，两个UDP端口${RESET}"
    echo -e "${bold_italic_yellow}面板中 ${bold_italic_purple}Additional services中的Run your own applications${bold_italic_yellow}选项已开启为 ${bold_italic_purple1}Enabled${bold_italic_yellow} 状态${RESET}"

    echo -e "${bold_italic_yellow}确定继续安装吗?<ENTER默认安装>【y/n】${reset}:\c"  
    read -p "" choice
    choice=${choice:-y}  # Default to y

    if [[ "$choice" != [Yy] ]]; then
        echo -e "$(bold_italic_red "安装已取消")"
        exit 0
    fi

    WORKDIR="$HOME/sbox"
    mkdir -p "$WORKDIR"
    cd "$WORKDIR"

    CERT_PATH="${HOME}/sbox/cert.pem"
    PRIVATE_KEY_PATH="${HOME}/sbox/private.key"
# 显示选项函数
display_options() {
    echo -e "${GREEN}\033[1m\033[3m请选择需要安装的服务（请输入对应的序号）：${RESET}"
    echo -e "${bold_italic_yellow}1: vless-reality${RESET}"
    echo -e "${bold_italic_yellow}2: vmess${RESET}"
    echo -e "${bold_italic_yellow}3: hysteria2${RESET}"
    echo -e "${bold_italic_yellow}4: tuic${RESET}"
    echo -e "${bold_italic_yellow}5: 安装两个协议${RESET}"
    echo -e "${bold_italic_yellow}6: 安装三个协议${RESET}"
}

# 初始化安装选项
INSTALL_VLESS="false"
INSTALL_VMESS="false"
INSTALL_HYSTERIA2="false"
INSTALL_TUIC="false"

# 循环直到获取有效输入
while true; do
    # 显示选项并读取用户选择
    display_options
    read -p "$(echo -e ${bold_italic_yellow}请输入你的选择${RESET}): " choices

    # 处理用户选择
    if [[ "$choices" == "5" ]]; then
        echo -e "${bold_italic_yellow}请选择要安装的两个协议（请输入对应的序号，用空格分隔）${RESET}"
        read -p "$(echo -e ${bold_italic_yellow}请输入你的选择${RESET}): " choices
    elif [[ "$choices" == "6" ]]; then
        echo -e "${bold_italic_yellow}请选择要安装的三个协议（请输入对应的序号，用空格分隔）${RESET}"
        read -p "$(echo -e ${bold_italic_yellow}请输入你的选择${RESET}): " choices
    fi

    # 设置安装选项
    valid_choice=true
    for choice in $choices; do
        case "$choice" in
            1) INSTALL_VLESS="true" ;;
            2) INSTALL_VMESS="true" ;;
            3) INSTALL_HYSTERIA2="true" ;;
            4) INSTALL_TUIC="true" ;;
            *)
             # echo -e "${RED}\033[1m\033[1;3;31m无效的选择,请重新输入正确的序号!${RESET}"
                valid_choice=false
                break
                ;;
        esac
    done

    # 如果所有选择都是有效的，则退出循环
    if $valid_choice; then
        break
    else
      echo -e "${RED}\033[1m\033[1;3;31m输入错误，请重新输入!!!${RESET}"
       
    fi
done

    validate_port() {
        local port=$1
        if [[ ! $port =~ ^[0-9]+$ ]] || [ "$port" -lt 1000 ] || [ "$port" -gt 65535 ]; then
            return 1
        else
            return 0
        fi
    }

    prompt_port() {
        local prompt_message=$1
        local port_variable=$2

        while true; do
            read -p "$(echo -e "${RED}\033[1m\033[1;3;32m$prompt_message: ${RESET}")" port
            if validate_port "$port"; then
                eval "$port_variable=$port"
                break
            else
                echo -e "${RED}\033[1m\033[1;3;31m无效的端口号，请输入1000到65535之间的数字。${RESET}"
            fi
        done
    }

    if [ "$INSTALL_VLESS" = "true" ]; then
        prompt_port "请输入vless-reality端口 (面板开放的tcp端口)" vless_port
    fi

    if [ "$INSTALL_VMESS" = "true" ]; then
        prompt_port "请输入vmess端口 (面板开放的tcp端口)" vmess_port

        echo -e "${bold_italic_yellow}是否使用Argo功能?<ENTER默认开启>【y/n】${RESET}:\c"
        read -p "" argo_choice
        argo_choice=${argo_choice:-y}  # 默认开启

        if [[ "$argo_choice" == [Yy] ]]; then
            argo_configure
        else
            echo -e "$(bold_italic_green "跳过Argo功能配置...")"
            ARGO_DOMAIN=""  # 清除 Argo 域名
        fi
    fi

    if [ "$INSTALL_HYSTERIA2" = "true" ]; then
        prompt_port "请输入hysteria2端口 (面板开放的udp端口)" hy2_port
    fi

    if [ "$INSTALL_TUIC" = "true" ]; then
        prompt_port "请输入tuic端口 (面板开放的udp端口)" tuic_port
    fi

    download_singbox && wait
    generate_config

    if [ "$INSTALL_VLESS" = "true" ]; then
        echo -e "$(echo -e "${GREEN}\033[1m\033[3m配置 VLESS...${RESET}")"
    fi

    if [ "$INSTALL_VMESS" = "true" ]; then
        echo -e "$(echo -e "${GREEN}\033[1m\033[3m配置 VMESS...${RESET}")"
    fi

    if [ "$INSTALL_HYSTERIA2" = "true" ]; then
        echo -e "$(echo -e "${GREEN}\033[1m\033[3m配置 Hysteria2...${RESET}")"
    fi

    if [ "$INSTALL_TUIC" = "true" ]; then
        echo -e "$(echo -e "${GREEN}\033[1m\033[3m配置 TUIC...${RESET}")"
    fi

    # 运行 sing-box
    run_sb && sleep 3

    # 获取链接
    get_links
    
    # 仅在 Argo 配置存在时显示 ArgoDomain 信息
    if [[ -n $ARGO_DOMAIN ]]; then
        echo -e "ArgoDomain:${ARGO_DOMAIN}"
    fi

    echo -e "$(bold_italic_purple "安装完成！")"
}

    
uninstall_singbox() {
   
    echo -e "$(bold_italic_purple "正在卸载 sing-box，请稍后...")"
    read -p $'\033[1;3;38;5;220m确定要卸载吗?<ENTER默认Y>【y/n】:\033[0m ' choice
    choice=${choice:-y}  # 默认值为 y

    case "$choice" in
        [Yy])
            # 终止 sing-box 相关进程
            for process in 'web' 'bot' 'npm'; do
                pids=$(pgrep -f "$process" 2>/dev/null)
                if [ -n "$pids" ]; then
                    kill -9 $pids 2>/dev/null
                    echo -e "$(bold_italic_purple "已终止 $process 进程。")"
                fi
            done

            # 终止 Socks5 代理进程
            if pgrep -x "socks5" > /dev/null; then
                pkill -9 sosks5
                echo -e "$(bold_italic_purple "已终止 Socks5 代理进程。")"
            fi

            # 删除下载目录
            WORKDIR="$HOME/sbox"
            if [ -d "$WORKDIR" ]; then
                rm -rf "$WORKDIR" 2>/dev/null
                echo -e "$(bold_italic_purple "已删除工作目录：$WORKDIR。")"
            fi

            # 删除 Socks5 配置文件
            SOCKS5_CONFIG="$WORKDIR/config.json"
            if [ -f "$SOCKS5_CONFIG" ]; then
                rm -f "$SOCKS5_CONFIG" 2>/dev/null
                echo -e "$(bold_italic_purple "已删除 Socks5 配置文件：$SOCKS5_CONFIG。")"
            fi

            echo -e "$(bold_italic_purple "正在卸载......")"
            sleep 2  # 可选：暂停片刻让用户看到消息
            echo -e "$(bold_italic_purple "卸载完成！")"
            ;;
      
        [Nn])
            echo -e "$(bold_italic_purple "已取消卸载。")"
            exit 0
            ;;
        *)
            echo -e "$(bold_italic_red "无效的选择，请输入 y 或 n")"
            menu
            ;;
    esac
}

# Download Dependency Files
download_singbox() {
    ARCH=$(uname -m) && DOWNLOAD_DIR="$HOME/sbox" && mkdir -p "$DOWNLOAD_DIR" && FILE_INFO=()
    
     if [ "$ARCH" == "arm" ] || [ "$ARCH" == "arm64" ] || [ "$ARCH" == "aarch64" ]; then
          FILE_INFO=("https://github.com/yyfalbl/singbox-2/releases/download/v1.0.0/arm64-sb web" "https://github.com/yyfalbl/singbox-2/releases/download/v1.0.0/arm64-bot13 bot")
     
  elif [ "$ARCH" == "amd64" ] || [ "$ARCH" == "x86_64" ] || [ "$ARCH" == "x86" ]; then
     
FILE_INFO=("https://github.com/yyfalbl/singbox-2/releases/download/v1.0.0/amd64-web web" "https://github.com/yyfalbl/singbox-2/releases/download/v1.0.0/amd64-bot bot")
     
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
YELLOW="\033[1;3;33m"
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
        "rule_set": ["geosite-openai"],
        "server": "wireguard"
      },
      {
        "rule_set": ["geosite-netflix"],
        "server": "wireguard"
      },
      {
        "rule_set": ["geosite-category-ads-all"],
        "server": "block"
      }
    ],
    "final": "google",
    "strategy": "",
    "disable_cache": false,
    "disable_expire": false
  },
  "inbounds": [
EOF

    # Track whether any services are added
    service_added=false

    # Append VLESS configuration if selected
    if [ "$INSTALL_VLESS" = "true" ]; then
        cat >> "$WORKDIR/config.json" <<EOF
    {
      "tag": "vless-reality-version",
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
          "short_id": [""]
        }
      }
    }
EOF
        service_added=true
    fi

    # Append VMESS configuration if selected
    if [ "$INSTALL_VMESS" = "true" ]; then
        [ "$service_added" = true ] && echo "," >> "$WORKDIR/config.json"
        cat >> "$WORKDIR/config.json" <<EOF
    {
      "tag": "vmess-ws-in",
      "type": "vmess",
      "listen": "::",
      "listen_port": $vmess_port,
      "users": [
        {
          "uuid": "$UUID"
        }
      ],
      "transport": {
        "type": "ws",
        "path": "/vmess",
        "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    }
EOF
        service_added=true
    fi

    # Append Hysteria2 configuration if selected
    if [ "$INSTALL_HYSTERIA2" = "true" ]; then
        [ "$service_added" = true ] && echo "," >> "$WORKDIR/config.json"
        cat >> "$WORKDIR/config.json" <<EOF
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
        "alpn": ["h3"],
        "certificate_path": "$CERT_PATH",
        "key_path": "$PRIVATE_KEY_PATH"
      }
    }
EOF
        service_added=true
    fi

    # Append TUIC configuration if selected
    if [ "$INSTALL_TUIC" = "true" ]; then
        [ "$service_added" = true ] && echo "," >> "$WORKDIR/config.json"
        cat >> "$WORKDIR/config.json" <<EOF
    {
      "tag": "tuic-in",
      "type": "tuic",
      "listen": "::",
      "listen_port": $tuic_port,
      "users": [
        {
          "uuid": "$UUID",
          "password": "admin123"
        }
      ],
      "congestion_control": "bbr",
      "tls": {
        "enabled": true,
        "alpn": ["h3"],
        "certificate_path": "$CERT_PATH",
        "key_path": "$PRIVATE_KEY_PATH"
      }
    }
EOF
    fi

    # Continue writing the rest of the configuration
    cat >> "$WORKDIR/config.json" <<EOF
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
      "reserved": [26, 21, 228]
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
        "rule_set": ["geosite-openai"],
        "outbound": "wireguard-out"
      },
      {
        "rule_set": ["geosite-netflix"],
        "outbound": "wireguard-out"
      },
      {
        "rule_set": ["geosite-category-ads-all"],
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
  green() {
    echo -e "\e[32;3;1m$1\e[0m"
}
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
        pgrep -x "web" > /dev/null && green "WEB is running" || { red "web is not running, restarting..."; pkill -x "web" && nohup "$WORKDIR/web" run -c "$WORKDIR/config.json" >/dev/null 2>&1 & sleep 2; purple "web restarted"; }
    fi
    
      if [ -e $WORKDIR/bot ]; then
    if [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
      args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token ${ARGO_AUTH}"
    elif [[ $ARGO_AUTH =~ TunnelSecret ]]; then
      args="tunnel --edge-ip-version auto --config $WORKDIR/tunnel.yml run"
    else
      args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile $WORKDIR/boot.log --loglevel info --url http://localhost:8080"
    fi
    nohup $WORKDIR/bot $args >/dev/null 2>&1 &
    sleep 2
    pgrep -x "bot" > /dev/null && green "BOT is running" || { red "bot is not running, restarting..."; pkill -x "bot" && nohup $WORKDIR/bot "${args}" >/dev/null 2>&1 & sleep 2; purple "bot restarted"; }
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
echo -e "\e[1;3;32mArgoDomain:\e[1;3;35m${argodomain}\e[0m\n"
sleep 1
  
    # 提示用户输入IP地址
   read -p "$(echo -e "${CYAN}\033[1;3;31m请输入IP地址（或按回车自动检测）: ${RESET}") " user_ip

    # 如果用户输入了IP地址，使用用户提供的IP地址
    if [ -n "$user_ip" ]; then
        IP=$user_ip
    else
        # 自动检测IP地址
        IP=$(curl -s ipv4.ip.sb || { ipv6=$(curl -s --max-time 1 ipv6.ip.sb); echo "[$ipv6]"; })
    fi

current_fqdn=$(hostname -f)

# 检查域名是否以 serv00.com 结尾
if [[ "$current_fqdn" == *.serv00.com ]]; then
echo -e "${GREEN_BOLD_ITALIC}当前服务器的地址是：$current_fqdn${RESET}"
   # echo "该服务器属于 serv00.com 域"

    # 提取子域名（假设子域名在主域名前缀的第一部分）
    subdomain=${current_fqdn%%.*}    
  fi  
    
    # 输出最终使用的IP地址
    echo -e "${CYAN}\033[1;3;32m设备的IP地址是: $IP${RESET}"
    # 获取用户名信息
      USERNAME=$(whoami)
   echo ""
  printf "${RED}${BOLD_ITALIC}注意：v2ray或其他软件的跳过证书验证需设置为true, 否则hy2或tuic节点可能不通${RESET}\n"

    # 生成并保存配置文件
cat <<EOF > "$WORKDIR/list.txt"
$(if [ "$INSTALL_VLESS" = "true" ]; then
    printf "${YELLOW}\033[1mvless://$UUID@$IP:$vless_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.ups.com&fp=chrome&pbk=$public_key&type=tcp&headerType=none#${USERNAME}-${subdomain}${RESET}\n"
fi)

$(if [ "$INSTALL_VMESS" = "true" ]; then
    printf "${YELLOW}\033[1mvmess://$(echo "{ \"v\": \"2\", \"ps\": \"${USERNAME}-${subdomain}\", \"add\": \"$IP\", \"port\": \"$vmess_port\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\", \"path\": \"/vmess?ed=2048\", \"tls\": \"\", \"sni\": \"\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)${RESET}\n"
fi)

$(if [ "$INSTALL_VMESS" = "true" ] && [ -n "$argodomain" ]; then
    printf "${YELLOW}\033[1mvmess://$(echo "{ \"v\": \"2\", \"ps\": \"${USERNAME}-${subdomain}\", \"add\": \"www.visa.com\", \"port\": \"443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)${RESET}\n"
fi)

$(if [ "$INSTALL_HYSTERIA2" = "true" ]; then
    printf "${YELLOW}\033[1mhysteria2://$UUID@$IP:$hy2_port/?sni=www.bing.com&alpn=h3&insecure=1#${USERNAME}-${subdomain}${RESET}\n"
fi)

$(if [ "$INSTALL_SOCKS5" = "true" ]; then
    printf "${YELLOW}\033[1mSocks5 代理地址： $IP:$SOCKS5_PORT 用户名：$SOCKS5_USER 密码：$SOCKS5_PASS${RESET}\n"
    printf "${YELLOW}\033[1msocks://${SOCKS5_USER}:${SOCKS5_PASS}@${SERV_DOMAIN}:${SOCKS5_PORT}${RESET}\n"
fi)

$(if [ "$INSTALL_TUIC" = "true" ]; then
    printf "${YELLOW}\033[1mtuic://$UUID:admin123@$IP:$tuic_port?sni=www.bing.com&congestion_control=bbr&udp_relay_mode=native&alpn=h3&allow_insecure=1#${USERNAME}-${subdomain}${RESET}\n"
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
    green() {
        echo -e "\\033[1;3;32m$*\\033[0m"
    }

    red() {
        echo -e "\\033[1;3;31m$*\\033[0m"
    }

    purple() {
        echo -e "\\033[1;3;35m$*\\033[0m"
    }

    # 保存光标位置
    echo -n -e "\033[1;3;31m正在启动sing-box服务,请稍后......\033[0m\n"
    sleep 1  # 可选：在启动进程前稍作停顿

    # 启动 web 进程
    if [ -e "$WORKDIR/web" ]; then
        chmod +x "$WORKDIR/web"
        
        # 启动 web 进程
        nohup "$WORKDIR/web" run -c "$WORKDIR/config.json" >"$WORKDIR/web.log" 2>&1 &
        sleep 2

        # 检查 web 进程是否启动成功
        if pgrep -x "web" > /dev/null; then
            # 清除初始消息，换行
            echo -ne "\r\033[K"
            green "WEB进程启动成功,并正在运行！"
        else
            # 清除初始消息，换行
            echo -ne "\r\033[K"
            red "web进程启动失败，请重试。检查日志以获取更多信息。"
        #    echo "查看日志文件以获取详细信息: $WORKDIR/web.log"
        fi
    else
        # 清除初始消息，换行
        echo -ne "\r\033[K"
        red "web可执行文件未找到，请检查路径是否正确。"
    fi

    # 检查是否安装了 Argo
      if [ -e "$WORKDIR/tunnel.yml" ]; then
        # 启动 bot 进程
        if [ -e "$WORKDIR/bot" ]; then
            # 准备 args 变量
            args="${args:-tunnel --edge-ip-version auto --config $WORKDIR/tunnel.yml run}"

            # 启动 bot
            nohup "$WORKDIR/bot" $args >/dev/null 2>&1 &
            sleep 2

            # 检查 bot 是否启动成功
            if pgrep -x "bot" > /dev/null; then
                green "BOT进程启动成功,并正在运行！"
            else
                red "bot进程启动失败，正在重启..."
                pkill -x "bot" && nohup "$WORKDIR/bot" $args >/dev/null 2>&1 &
                sleep 2

                if pgrep -x "bot" > /dev/null; then
                    purple "bot重新启动成功！"
                else
                    red "bot重新启动失败，请检查日志以获取更多信息。"
                fi
            fi
        fi
    else
        green "Argo未安装或未配置，跳过启动 bot 进程。"
    fi
}
    
#停止sing-box服务
stop_web() {
    echo -n -e "\033[1;3;33m正在清理 web 和 bot 进程，请稍后......\033[0m\n"
    sleep 1  # Optional: pause for a brief moment before killing tasks

    # 查找 web 进程的 PID
    WEB_PID=$(pgrep -f 'web')

    if [ -n "$WEB_PID" ]; then
        # 杀死 web 进程
        kill -9 $WEB_PID
        echo -n -e "\033[1;3;31m已成功停止 WEB 进程!\033[0m\n"
    else
        echo "未找到 web 进程，可能已经停止。"
    fi

    # 查找 bot 进程的 PID
    BOT_PID=$(pgrep -f 'bot')

    if [ -n "$BOT_PID" ]; then
        # 杀死 bot 进程
        kill -9 $BOT_PID
           echo -n -e "\033[1;3;31m已成功停止 BOT 进程!\033[0m\n"
    else
         echo -n -e "\033[1;3;31m未找到BOT进程，可能已经停止了!\033[0m\n"
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
  RED_BOLD='\033[1;3;31m'
  RESET='\033[0m'
    RED_BOLD='\033[1;3;31m'
  YELLOW='\033[1;3;33m'
  RESET='\033[0m'
  
  # 获取当前用户名
  USERNAME=$(whoami)
  
  echo -e "${RED_BOLD}请选择要执行的操作:${RESET}"
  echo -e "${RED_BOLD}1. 清理所有进程,可能会断开ssh连接${RESET}"
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
# 定义颜色函数
red() {
    echo -e "\\033[1;3;31m$*\\033[0m"
}

green() {
    echo -e "\\033[1;32m$*\\033[0m"
}

yellow() {
    echo -e "\\033[1;33m$*\\033[0m"
}

purple() {
    echo -e "\\033[1;35m$*\\033[0m"
}
 reading() {
    echo -ne "\\033[1;3;33m$1\\033[0m"  # 显示黄色加粗斜体的提示
    read -r "$2"  # 读取用户输入
}
    magenta() {
    echo -e "\033[1;3;33m$1\033[0m"
}
bold_italic_orange() {
    echo -e "\033[1;3;38;5;208m$1\033[0m"
}
    pink() {
    echo -e "\033[1;35m$1\033[0m"
}
    bold_italic_light_blue() {
    echo -e "\033[1;3;36m$1\033[0m"
}    
# 主菜单
# 主菜单
menu() {
   clear
      while true; do
   echo ""
   magenta "=== SERV00和CT8|SING-BOX一键安装脚本 ==="
   echo ""
  bold_italic_orange "\033[1;3m=== 脚本支持:VLESS VMESS HY2 TUIC socks5 协议，UUID自动生成 ===\033[0m\n"
    magenta "=== 支持安装：单，双，三个协议(面板最多只能开放3个端口)，自由选择 ===\n"
  bold_italic_light_blue "=== 固定argo隧道 可以优选ip或优选域名！  ===\n"
    bold_italic_light_blue "=== argo隧道配置文件生成网址  https://fscarmen.cloudflare.now.cc/ ===\n"
  echo -e "${green}\033[1;3;33m脚本地址：\033[0m${re}\033[1;3;33mhttps://github.com/yyfalbl/singbox-2\033[0m${re}\n"
   purple "\033[1;3m*****转载请著名出处，请勿滥用*****\033[0m\n"
   echo ""
    get_server_info
    echo ""
   # Example usage
   check_singbox_installed
   echo ""
   # 显示 web 进程状态（仅在 sing-box 已安装时显示）
   echo ""  # 添加空行
   check_web_status
   echo ""  # 添加空行

   echo ""

   green "\033[1;3m1. 安装sing-box\033[0m"
   echo "==============="
   green "\033[1;3m2. 安装Socks5\033[0m"
   echo "==============="
   red "\033[1;3m3. 卸载sing-box和socks5\033[0m"
   echo "==============="
   bold_italic_light_blue "\033[1;3m4. 查看节点信息\033[0m"
   echo "==============="
   yellow "\\033[1;3m5. 清理系统进程\\033[0m"
   echo "==============="
   green "\033[1;3m6. 启动sing-box服务\033[0m"
   echo "==============="
   pink "\033[1;3m7. 停止sing-box服务\033[0m"
   echo "==============="
   pink "\033[1;3m8. 系统初始化\033[0m"
   echo "==============="
   red "\033[1;3m0. 退出脚本\033[0m"
   echo "==========="
   reading "请输入选择(0-8): " choice
   echo ""
   case "${choice}" in
        1)
            install_singbox
             read -p "$(echo -e "${YELLOW}${BOLD_ITALIC}操作完成，按任意键继续...${RESET}")" -n1 -s
            clear
            ;;
        2)
            setup_socks5
             read -p "$(echo -e "${YELLOW}${BOLD_ITALIC}操作完成，按任意键继续...${RESET}")" -n1 -s
            clear
            ;;
        3)
            uninstall_singbox
            read -p "$(echo -e "${YELLOW}${BOLD_ITALIC}操作完成，按任意键继续...${RESET}")" -n1 -s
            clear
            ;;
        4)
            cat $WORKDIR/list.txt
            read -p "$(echo -e "${YELLOW}${BOLD_ITALIC}操作完成，按任意键继续...${RESET}")" -n1 -s
            clear
            ;;
        5)
            manage_processes
            read -p "$(echo -e "${YELLOW}${BOLD_ITALIC}操作完成，按任意键继续...${RESET}")" -n1 -s
            clear
            ;;
        6)
            start_web
            read -p "$(echo -e "${YELLOW}${BOLD_ITALIC}操作完成，按任意键继续...${RESET}")" -n1 -s
            clear
            ;;
        7)
            stop_web
            read -p "$(echo -e "${YELLOW}${BOLD_ITALIC}操作完成，按任意键继续...${RESET}")" -n1 -s
            clear
            ;;
        8)
            cleanup_and_delete
            read -p "$(echo -e "${YELLOW}${BOLD_ITALIC}操作完成，按任意键继续...${RESET}")" -n1 -s
            clear
            ;;  
        0) exit 0 ;;   
      *)
            red "\033[1;3m无效的选项，请输入 0 到 8\033[0m"
            echo ""
            ;;
    esac
    done 
   
}
menu
