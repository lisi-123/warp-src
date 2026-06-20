#!/bin/bash

# 更新软件包列表
apt-get update

# 安装必需的软件包
apt install sudo -y
sudo apt install git -y
sudo apt install curl -y
sudo apt install nano -y

# 网络调优
CONF="/etc/sysctl.conf"

# 删除旧配置
sed -i '
/net.core.default_qdisc/d
/net.ipv4.tcp_congestion_control/d
/net.ipv4.tcp_ecn/d
/net.ipv4.tcp_fastopen/d
/net.ipv4.tcp_mtu_probing/d
/net.ipv4.tcp_notsent_lowat/d
/net.ipv4.tcp_limit_output_bytes/d
/net.ipv4.tcp_sack/d
/net.ipv4.tcp_timestamps/d
/net.ipv4.tcp_window_scaling/d
' "$CONF"

# 写入新配置
cat >> "$CONF" << 'EOF'

# BBR 优化
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# TCP 队列
net.core.somaxconn = 4096

# TCP 优化
net.ipv4.tcp_ecn=0
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_mtu_probing=0

EOF

# 应用配置
sysctl --system

# 修改为上海时区
sudo timedatectl set-timezone Asia/Shanghai

# 安装warp并设置本地socks5代理
wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh <<< $'2\n12\n1\n1\n40000\n'

# 修一下wireproxy模式的小bug
mkdir -p /etc/systemd/system/wireproxy.service.d

cat >/etc/systemd/system/wireproxy.service.d/override.conf <<'EOF'
[Unit]
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=
ExecStartPre=/bin/sleep 20
ExecStart=/usr/bin/wireproxy -c /etc/wireguard/proxy.conf
RestartSec=10
EOF

systemctl daemon-reload
systemctl restart wireproxy

# 输出完成信息
echo "已自动配置warp解锁"
