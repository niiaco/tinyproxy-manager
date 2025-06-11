# tinyproxy-manager
a tiny proxy manager in one click

## Quick install

Run this command to install Tinyproxy with default settings:

```bash
curl -fsSL https://raw.githubusercontent.com/niiaco/tinyproxy-manager/main/tinyproxy.sh | bash -s -- --install
```

AFTER INSTALLATION , WHEN EVER YOUR TYPE: tiny , PANEL LOADS,
NOW REPLACE THIS WITH OUTBOUND OF XUI

```json
[
  {
    "tag": "direct",
    "protocol": "freedom",
    "settings": {
      "domainStrategy": "AsIs",
      "redirect": "",
      "noises": []
    }
  },
  {
    "tag": "blocked",
    "protocol": "blackhole",
    "settings": {}
  },
  {
    "tag": "tinyproxy",
    "protocol": "http",
    "settings": {
      "servers": [
        {
          "address": "<your-server-ip>",
          "port": 8888,
          "users": [
            {
              "user": "admin021",
              "pass": "admin021"
            }
          ]
        }
      ]
    }
  }
]
``` 
