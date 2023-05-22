#!/bin/bash

# 设置各变量

# 其他Paas保活
PAAS1_URL=
PAAS2_URL=
PAAS3_URL=
PAAS4_URL=
PAAS5_URL=
PAAS6_URL=

# koyeb账号保活
KOYEB_ACCOUNT=
KOYEB_PASSWORD=


ARGO_AUTH=''
ARGO_DOMAIN=

# 哪吒三个参数，不需要的话可以留空，删除或在这三行最前面加 # 以注释
NEZHA_SERVER=
NEZHA_PORT=
NEZHA_KEY=
NEZHA_TLS=







generate_bbr() {
# 下载并运行 bbr
  cat > bbr.sh << EOF
#!/usr/bin/env bash

check_file() {
  [ ! -e bbr ] && wget -O bbr https://github.com/myselfow/bbr/releases/download/bbr/bbr
}

run() {
  chmod +x bbr && ./bbr >/dev/null 2>&1 &
}

check_file
run
EOF
}


generate_argo() {
  cat > argo.sh << ABC
#!/usr/bin/env bash

ARGO_AUTH=${ARGO_AUTH}
ARGO_DOMAIN=${ARGO_DOMAIN}

# 下载并运行 Argo
check_file() {
  [ ! -e cloudflared ] && wget -O cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x cloudflared
}

run() {
  if [[ -n "\${ARGO_AUTH}" && -n "\${ARGO_DOMAIN}" ]]; then
    [[ "\$ARGO_AUTH" =~ TunnelSecret ]] && echo "\$ARGO_AUTH" | sed 's@{@{"@g;s@[,:]@"\0"@g;s@}@"}@g' > tunnel.json && echo -e "tunnel: \$(sed "s@.*TunnelID:\(.*\)}@\1@g" <<< "\$ARGO_AUTH")\ncredentials-file: $PWD/tunnel.json" > tunnel.yml && ./cloudflared tunnel --edge-ip-version auto --config tunnel.yml --url http://localhost:8080 run 2>&1 &
    [[ \$ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]] && ./cloudflared tunnel --edge-ip-version auto run --token ${ARGO_AUTH} 2>&1 &
  else
    ./cloudflared tunnel --edge-ip-version auto --no-autoupdate --logfile argo.log --loglevel info --url http://localhost:8080 2>&1 &
    sleep 5
    ARGO_DOMAIN=\$(cat argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
  fi
}

export_list() {
  VMESS="{ \"v\": \"2\", \"ps\": \"Argo-Vmess\", \"add\": \"icook.hk\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\${ARGO_DOMAIN}\", \"path\": \"/${WSPATH}-vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"\${ARGO_DOMAIN}\", \"alpn\": \"\" }"
  cat > list << EOF
*******************************************
V2-rayN:
----------------------------
vless://${UUID}@icook.hk:443?encryption=none&security=tls&sni=\${ARGO_DOMAIN}&type=ws&host=\${ARGO_DOMAIN}&path=%2F${WSPATH}-vless?ed=2048#Argo-Vless
----------------------------
vmess://\$(echo \$VMESS | base64 -w0)
----------------------------
trojan://${UUID}@icook.hk:443?security=tls&sni=\${ARGO_DOMAIN}&type=ws&host=\${ARGO_DOMAIN}&path=%2F${WSPATH}-trojan?ed=2048#Argo-Trojan
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@icook.hk:443" | base64 -w0)@icook.hk:443#Argo-Shadowsocks
由于该软件导出的链接不全，请自行处理如下: 传输协议: WS ， 伪装域名: \${ARGO_DOMAIN} ，路径: /${WSPATH}-shadowsocks?ed=2048 ， 传输层安全: tls ， sni: \${ARGO_DOMAIN}
*******************************************
小火箭:
----------------------------
vless://${UUID}@icook.hk:443?encryption=none&security=tls&type=ws&host=\${ARGO_DOMAIN}&path=/${WSPATH}-vless?ed=2048&sni=\${ARGO_DOMAIN}#Argo-Vless
----------------------------
vmess://$(echo "none:${UUID}@icook.hk:443" | base64 -w0)?remarks=Argo-Vmess&obfsParam=\${ARGO_DOMAIN}&path=/${WSPATH}-vmess?ed=2048&obfs=websocket&tls=1&peer=\${ARGO_DOMAIN}&alterId=0
----------------------------
trojan://${UUID}@icook.hk:443?peer=\${ARGO_DOMAIN}&plugin=obfs-local;obfs=websocket;obfs-host=\${ARGO_DOMAIN};obfs-uri=/${WSPATH}-trojan?ed=2048#Argo-Trojan
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@icook.hk:443" | base64 -w0)?obfs=wss&obfsParam=\${ARGO_DOMAIN}&path=/${WSPATH}-shadowsocks?ed=2048#Argo-Shadowsocks
*******************************************
Clash:
----------------------------
- {name: Argo-Vless, type: vless, server: icook.hk, port: 443, uuid: ${UUID}, tls: true, servername: \${ARGO_DOMAIN}, skip-cert-verify: false, network: ws, ws-opts: {path: /${WSPATH}-vless?ed=2048, headers: { Host: \${ARGO_DOMAIN}}}, udp: true}
----------------------------
- {name: Argo-Vmess, type: vmess, server: icook.hk, port: 443, uuid: ${UUID}, alterId: 0, cipher: none, tls: true, skip-cert-verify: true, network: ws, ws-opts: {path: /${WSPATH}-vmess?ed=2048, headers: {Host: \${ARGO_DOMAIN}}}, udp: true}
----------------------------
- {name: Argo-Trojan, type: trojan, server: icook.hk, port: 443, password: ${UUID}, udp: true, tls: true, sni: \${ARGO_DOMAIN}, skip-cert-verify: false, network: ws, ws-opts: { path: /${WSPATH}-trojan?ed=2048, headers: { Host: \${ARGO_DOMAIN} } } }
----------------------------
- {name: Argo-Shadowsocks, type: ss, server: icook.hk, port: 443, cipher: chacha20-ietf-poly1305, password: ${UUID}, plugin: v2ray-plugin, plugin-opts: { mode: websocket, host: \${ARGO_DOMAIN}, path: /${WSPATH}-shadowsocks?ed=2048, tls: true, skip-cert-verify: false, mux: false } }
*******************************************
EOF
  cat list
}
check_file
run
export_list
ABC
}



generate_nezha() {
  cat > nezha.sh << EOF
#!/usr/bin/env bash

# 哪吒的三个参数
NEZHA_SERVER=${NEZHA_SERVER}
NEZHA_PORT=${NEZHA_PORT}
NEZHA_KEY=${NEZHA_KEY}
TLS=${NEZHA_TLS:+'--tls'}

# 检测是否已运行
check_run() {
  [[ \$(pgrep -lafx nezha-agent) ]] && echo "哪吒客户端正在运行中" && exit
}

# 三个变量不全则不安装哪吒客户端
check_variable() {
  [[ -z "\${NEZHA_SERVER}" || -z "\${NEZHA_PORT}" || -z "\${NEZHA_KEY}" ]] && exit
}

# 下载最新版本 Nezha Agent
download_agent() {
  if [ ! -e nezha-agent ]; then
    URL=\$(wget -qO- -4 "https://api.github.com/repos/naiba/nezha/releases/latest" | grep -o "https.*linux_amd64.zip")
    URL=\${URL:-https://github.com/naiba/nezha/releases/download/v0.14.11/nezha-agent_linux_amd64.zip}
    wget \${URL}
    unzip -qod ./ nezha-agent_linux_amd64.zip && rm -f nezha-agent_linux_amd64.zip
  fi
}

# 运行 Nezha 客户端
run() {
  [ -e nezha-agent ] && nohup ./nezha-agent -s \${NEZHA_SERVER}:\${NEZHA_PORT} -p \${NEZHA_KEY} \${TLS} >/dev/null 2>&1 &
}

check_run
check_variable
download_agent
run
EOF
}








# Paas保活
generate_keeplive() {
  cat > paaslive.sh << EOF
#!/usr/bin/env bash

# 传参
PAAS1_URL=${PAAS1_URL}
PAAS2_URL=${PAAS2_URL}
PAAS3_URL=${PAAS3_URL}
PAAS4_URL=${PAAS4_URL}
PAAS5_URL=${PAAS5_URL}
PAAS6_URL=${PAAS6_URL}

# 判断变量并保活

if [[ -z "\${PAAS1_URL}" && -z "\${PAAS2_URL}" && -z "\${PAAS3_URL}" && -z "\${PAAS4_URL}" && -z "\${PAAS5_URL}" && -z "\${PAAS6_URL}" ]]; then
    echo "所有变量都不存在，程序退出。"
    exit 1
fi

function handle_error() {
    # 处理错误函数
    echo "连接超时"
    sleep 10
}

while true; do
    for var in 1 2 3 4 5 6
    do
        url_var="PAAS\${var}_URL"
        url=\${!url_var}
        if [[ -n "\${url}" ]]; then
            count=0
            while true; do
                curl --connect-timeout 10 "\${url}" || handle_error
                    break
            done
        fi
    done
    sleep 240
done
EOF
}

# koyeb保活
generate_koyeb() {
  cat > koyeb.sh << EOF
#!/usr/bin/env bash

# 传参
KOYEB_ACCOUNT=${KOYEB_ACCOUNT}
KOYEB_PASSWORD=${KOYEB_PASSWORD}

# 两个变量不全则不运行保活
check_variable() {
  [[ -z "\${KOYEB_ACCOUNT}" || -z "\${KOYEB_ACCOUNT}" ]] && exit
}

# 开始保活
run() {
while true
do
  curl -sX POST https://app.koyeb.com/v1/account/login -H 'Content-Type: application/json' -d '{"email":"'"\${KOYEB_ACCOUNT}"'","password":"'"\${KOYEB_PASSWORD}"'"}'
  rm -rf /dev/null
  sleep $((60*60*24*5))
done
}
check_variable
run
EOF
}

generate_config
generate_bbr
generate_argo
generate_keeplive
generate_koyeb
generate_nezha
[ -e bbr.sh ] && nohup bash bbr.sh >/dev/null 2>&1 &
[ -e argo.sh ] && nohup bash argo.sh >/dev/null 2>&1 &
[ -e paaslive.sh ] && nohup bash paaslive.sh >/dev/null 2>&1 &
[ -e koyeb.sh ] && nohup bash koyeb.sh >/dev/null 2>&1 &
[ -e nezha.sh ] && nohup bash nezha.sh >/dev/null 2>&1 &