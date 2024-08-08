#！/bin/bash

# 定义颜色
re=“\033[0m”
红色=“\033[1;91米”
green=“\e[1;32米”
黄色=“\e[1;33米”
紫色=“\e[1;35米”
red（） { echo -e “\e[1;91米$1\033[0米”; }
green（） { echo -e “\e[1;32米$1\033[0米”; }
yellow（） { echo -e “\e[1;33m$1\033[0m”; }
purple（） { echo -e “\e[1;35米$1\033[0米”; }
reading（） { read -p “$（红色 ”$1“）”： “$2”; }

用户名=$（whoami）
HOSTNAME=$（主机名）
UUID_FILE=“$HOME/.singbox_uuid” # 定义 UUID 的存储位置

# Check if UUID file exists
if [ -f "$UUID_FILE" ]; then
    export UUID=$(cat "$UUID_FILE")  # Read the existing UUID
还
    export UUID=$(uuidgen)  # Generate a new UUID
    echo "$UUID" > "$UUID_FILE"  # Save the UUID to the file
fi

export NEZHA_SERVER=${NEZHA_SERVER:-''}
export NEZHA_PORT=${NEZHA_PORT:-'5555'}     
export NEZHA_KEY=${NEZHA_KEY:-''}

[[ "$HOSTNAME" == "s1.ct8.pl" ]] && WORKDIR="domains/${USERNAME}.ct8.pl/logs" || WORKDIR="domains/${USERNAME}.serv00.net/logs"
[ -d “$WORKDIR” ] ||（MKDIR -P “$WORKDIR” & CHMOD 777 “$WORKDIR”)

read_vless_port() {
    虽然是真的; 做
Reading “请输入vless-reality端口 （面板开放的tcp端口）： ” vless_port
        if [[ “$vless_port” =~ ^[0-9]+$ ]] && [ “$vless_port” -ge 1 ] && [ “$vless_port” -le 65535 ]; 然后
green “你的vless-reality端口为： $vless_port”
            破
        还
yellow “输入错误，请重新输入面板开放的TCP端口”
        fi
    做
}

read_hy2_port() {
    虽然是真的; 做
阅读 “请输入hysteria2端口 （面板开放的UDP端口）： ” hy2_port
        if [[ “$hy 2_port” =~ ^[0-9]+$ ]] && [ “$hy 2_port” -ge 1 ] && [ “$hy 2_port” -le 65535 ]; 然后
绿色 “你的hysteria2端口为： $hy 2_port”
            破
        还
yellow “输入错误，请重新输入面板开放的UDP端口”
        fi
    做
}


read_nz_variables() {
  if [ -n “$NEZHA_SERVER” ] && [ -n “$NEZHA_PORT” ] && [ -n “$NEZHA_KEY”] ]; 然后
绿色 “使用自定义变量哪吒运行哪吒探针”
      返回
  还
阅读 “是否需要安装哪吒探针？【y/n】： ” nz_choice
      [[ -z $nz_choice ]] && 返回
      [[ “$nz_choice” ！= “y” & “$nz_choice” ！= “Y” ]] && return
阅读“请输入哪吒探针域名或IP：”NEZHA_SERVER
green “你的哪吒域名为： $NEZHA_SERVER”
阅读 “请输入哪吒探针端口（回车跳过默认使用5555）：”NEZHA_PORT
      [[ -z $NEZHA_PORT ]] && NEZHA_PORT=“5555”
绿色 “你的哪吒端口为： $NEZHA_PORT”
阅读 “请输入哪吒探针密钥：” NEZHA_KEY
绿色 “你的哪吒密钥为： $NEZHA_KEY”
  fi
}
“rule_set”： [
“Geosite-Netflix”
],
“outbound”： “wireguard-out”
},
      {
“rule_set”： [
“geosite-category-ads-all”
],
        "outbound": "block"
      }
],
“rule_set”： [
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
EOF（英语：EOF）
}

# 运行文件
run_sb() {
  如果 [ -e npm ]; 然后
tlsPorts=（“443”， “8443”， “2096”， “2087”， “2083”， “2053”)
    if [[ “${tlsPorts[*]}” =~ “${NEZHA_PORT}” ]]; 然后
NEZHA_TLS=“--tls”
    还
NEZHA_TLS=""
    fi
    if [ -n “$NEZHA_SERVER” ] && [ -n “$NEZHA_PORT” ] && [ -n “$NEZHA_KEY”] ]; 然后
        出口TMPDIR=$（pwd）
nohup ./npm -s ${NEZHA_SERVER}：${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} >/dev/null 2>&1 &
睡眠 2
pgrep -x “npm” > /dev/null && green “npm 正在运行” ||{ 红色 “npm 未运行，正在重新启动...“;pkill -x “npm” && nohup ./npm -s “${NEZHA_SERVER}：${NEZHA_PORT}” -p “${NEZHA_KEY}” ${NEZHA_TLS} >/dev/null 2>&1 & sleep 2;紫色“npm 已重启”; }
    还
紫色“哪吒变量为空，正在跳过运行”
    fi
  fi

  如果 [ -e web ]; 然后
nohup ./web run -c config.json >/dev/null 2>&1 &
睡眠 2
pgrep -x “web” > /dev/null && green “web is running” ||{ 红色 “网络未运行，正在重启...“;pkill -x “web” & nohup ./web run -c config.json >/dev/null 2>&1 & sleep 2;紫色的“Web 已重新启动”; }
  fi

}

get_links(){
# 获取 IP
IP=$（curl -s ipv4.ip.sb || { ipv6=$（curl -s --max-time 1 ipv6.ip.sb）; 回声 “[$ipv 6]”;）
睡眠 1
# 获取 ipinfo
ISP=$（curl -s https://speed.cloudflare.com/meta | awk -F\“ '{打印 $26”-“$18}' | sed -e 's/ /_/g'） 
睡眠 1
黄色 “注意：v2ray或其他软件的跳过证书验证需设置为true，否则hy2或tuic节点可能不通\n”
猫 > list.txt <<EOF
vless://$UUID@$IP：$vless_port？encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.ups.com&fp=chrome&pbk=$public_key&type=tcp&headerType=none#$ISP

歇斯底里2：//$UUID@$IP：$hy 2_port/？sni=www.bing.com&alpn=h3&insecure=1#$ISP

tuic://$UUID:admin123@$IP:$tuic_port?sni=www.bing.com&congestion_control=bbr&udp_relay_mode=native&alpn=h3&allow_insecure=1#$ISP
EOF（英语：EOF）
猫list.txt
紫色“list.txt成功保存”
紫色的“跑步完成！
睡眠 3
rm -rf npm boot.log sb.log 核心

}

#主菜单
菜单() {
清楚
   回波 ""
紫色 “=== Serv00|sing-box一键安装脚本 ===\n”
purple “=== 转载老王脚本，去除tuic协议，增加UUID自动生成 ===\n”
   echo -e “${green}脚本地址：${re}${yellow}https://github.com/yyfalbl/singbox-2${re}\n”   
   purple   "***转载请著名出处，请勿滥用***\n"
   回波  "==============="
绿色“1.安装sing-box”
   回波  "==============="
红色“2.卸载sing-box”
   回波  "==============="
绿色“3.查看节点信息”
   回波  "==============="
   yellow "4. 清理所有进程"
   回波  "==============="
红色“0。退出脚本”
   回波 "==========="
阅读 “请输入选择（0-3）： ” choice
   回波 ""
    大小写 “${choice}” 
1） install_singbox ;;
2） uninstall_singbox ;;
3） 猫 $WORKDIR/list.txt ;;
        4) kill_all_tasks ;;
0） 退出 0 ;;
        *) red "无效的选项，请输入 0 到 4" ;;
    ESAC公司
}
菜单

