#!/bin/bash

LOCK_FILE="/tmp/warp-socks5-check.lock"
COOLDOWN_FILE="/tmp/warp-socks5-recover.time"
COOLDOWN=600   # 10分钟

# 防止多个脚本同时运行
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

check_url() {
    local url=$1
    local success_count=0

    for i in {1..3}; do
        echo "尝试访问 $url，第 $i 次"

        if curl -s \
            --socks5-hostname 127.0.0.1:40000 \
            --max-time 6 \
            "$url" >/dev/null; then
            success_count=$((success_count + 1))
        fi

        sleep 1
    done

    [[ $success_count -gt 0 ]]
}

need_cooldown() {
    [ ! -f "$COOLDOWN_FILE" ] && return 1

    local now
    local last

    now=$(date +%s)
    last=$(cat "$COOLDOWN_FILE" 2>/dev/null)

    [ $((now - last)) -lt "$COOLDOWN" ]
}

if check_url "https://cp.cloudflare.com/generate_204"; then
    echo "SOCKS5 代理正常（通过 Cloudflare）"

elif check_url "https://www.google.com/generate_204"; then
    echo "SOCKS5 代理正常（通过 Google）"

elif curl -s \
    --socks5-hostname 127.0.0.1:40000 \
    --resolve 1.1.1.1:443:1.1.1.1 \
    --max-time 6 \
    https://1.1.1.1/cdn-cgi/trace >/dev/null; then

    echo "SOCKS5 正常（1.1.1.1）"

else
    echo "SOCKS5 代理不可用"

    if need_cooldown; then
        echo "恢复冷却中，跳过 warp y"
        exit 0
    fi

    # 记录恢复时间
    date +%s > "$COOLDOWN_FILE"

    echo "$(date '+%F %T') - SOCKS5 代理不可用，执行 warp y" \
        >> /root/warp-socks5/socks5-check.log

    if ss -nltp | grep -q wireproxy; then
        echo "检测到 wireproxy，执行两次 warp y"

        /bin/warp y
        sleep 1
        /bin/warp y

    else
        echo "未检测到 wireproxy，仅执行一次 warp y"

        /bin/warp y
    fi
fi
