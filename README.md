# warp自动部署

执行安装脚本：


```bash
apt-get install wget -y && wget -O setup.sh https://raw.githubusercontent.com/lisi-123/warp-socks5/main/setup.sh && chmod +x setup.sh && ./setup.sh

```

<br>


执行 warp 唤起warp管理面板




```bash
 {
    "tag": "socks5-warp",
    "protocol": "socks",
    "settings": {
      "servers": [
        {
          "address": "127.0.0.1",
          "port": 40000
        }
      ]
    }
  }
```

<br>
<br>
