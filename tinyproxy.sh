#!/bin/bash

# ========== Tinyproxy Manager ==========
# 💡 Developed with ❤️ by niiaco
# =======================================

CONFIG_FILE="/etc/tinyproxy/tinyproxy.conf"
PORT=8888
proxy_user="admin021"
proxy_pass="admin021"
server_ip=$(hostname -I | awk '{print $1}')

# Detect package manager (apt or yum)
detect_pkg_manager() {
  if command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  else
    echo ""
  fi
}

install_tinyproxy() {
  echo "[+] Installing Tinyproxy..."

  PKG_MANAGER=$(detect_pkg_manager)
  if [[ -z "$PKG_MANAGER" ]]; then
    echo "❌ No supported package manager found (apt or yum)."
    exit 1
  fi

  if [[ "$PKG_MANAGER" == "apt" ]]; then
    sudo apt update -y
    sudo apt install tinyproxy -y
  else
    sudo yum install tinyproxy -y
  fi

  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install tinyproxy."
    exit 1
  fi

  echo "[+] Configuring Tinyproxy..."

  sudo tee "$CONFIG_FILE" > /dev/null <<EOF
User nobody
Group nogroup
Port $PORT
Timeout 600
DefaultErrorFile "/usr/share/tinyproxy/default.html"
StatFile "/usr/share/tinyproxy/stats.html"
LogFile "/var/log/tinyproxy/tinyproxy.log"
LogLevel Info
MaxClients 100
MinSpareServers 5
MaxSpareServers 20
StartServers 10
MaxRequestsPerChild 0
Allow 0.0.0.0/0
BasicAuth $proxy_user $proxy_pass
EOF

  sudo chown root:root "$CONFIG_FILE"
  sudo chmod 644 "$CONFIG_FILE"

  echo "[+] Restarting and enabling Tinyproxy service..."
  sudo systemctl restart tinyproxy
  sudo systemctl enable tinyproxy

  # Open firewall port if possible
  if command -v ufw >/dev/null 2>&1; then
    echo "[+] Allowing port $PORT through ufw firewall..."
    sudo ufw allow "$PORT"/tcp
    sudo ufw reload
  elif command -v firewall-cmd >/dev/null 2>&1; then
    echo "[+] Allowing port $PORT through firewalld..."
    sudo firewall-cmd --permanent --add-port=${PORT}/tcp
    sudo firewall-cmd --reload
  else
    echo "⚠️ No firewall manager detected (ufw or firewalld). Please open port $PORT manually if needed."
  fi

  echo "[+] Tinyproxy installed and running on port $PORT."
  read -p "Press Enter to continue..."
}

uninstall_tinyproxy() {
  echo "[!] Uninstalling Tinyproxy..."
  sudo systemctl stop tinyproxy
  sudo systemctl disable tinyproxy

  PKG_MANAGER=$(detect_pkg_manager)
  if [[ "$PKG_MANAGER" == "apt" ]]; then
    sudo apt remove --purge tinyproxy -y
  elif [[ "$PKG_MANAGER" == "yum" ]]; then
    sudo yum remove tinyproxy -y
  fi

  sudo rm -f "$CONFIG_FILE"
  sudo rm -f /var/log/tinyproxy/tinyproxy.log

  echo "[!] Tinyproxy removed."
  read -p "Press Enter to continue..."
}

test_proxy() {
  echo "🌐 Local test (should show your public IP):"
  curl -s -x http://$proxy_user:$proxy_pass@127.0.0.1:$PORT http://ifconfig.me || echo "❌ Local proxy test failed"

  echo -e "\n🌐 Remote test (IP: $server_ip):"
  curl -s -x http://$proxy_user:$proxy_pass@$server_ip:$PORT http://ifconfig.me || echo "❌ Remote proxy test failed"

  echo -e "\n📡 Port test (nc):"
  nc -zv $server_ip $PORT || echo "❌ Port $PORT not reachable"

  read -p "Press Enter to return to menu..."
}

check_status() {
  echo "📊 Checking Tinyproxy service status..."
  sudo systemctl status tinyproxy --no-pager

  echo -e "\n🔎 Checking if port $PORT is listening..."
  (ss -tuln | grep $PORT || netstat -tuln | grep $PORT) || echo "❌ Port $PORT not open or Tinyproxy not listening"

  read -p "Press Enter to return to menu..."
}

view_logs() {
  echo "📜 Showing last 20 lines of Tinyproxy log:"
  sudo tail -n 20 /var/log/tinyproxy/tinyproxy.log
  read -p "Press Enter to return to menu..."
}

# Main menu loop
menu() {
  while true; do
    clear
    echo "========== Tinyproxy Manager =========="
    echo "Server IP: $server_ip"
    echo "Proxy User: $proxy_user"
    echo "Proxy Pass: $proxy_pass"
    echo "---------------------------------------"
    echo "1. Install Tinyproxy"
    echo "2. Uninstall Tinyproxy"
    echo "3. Test Proxy"
    echo "4. Check Status & Port"
    echo "5. View Logs"
    echo "0. Exit"
    echo "======================================="
    echo "💡 Developed with ❤️ by niiaco"
    read -p "Choose an option: " choice

    case $choice in
      1) install_tinyproxy ;;
      2) uninstall_tinyproxy ;;
      3) test_proxy ;;
      4) check_status ;;
      5) view_logs ;;
      0) exit 0 ;;
      *) echo "Invalid option. Press Enter..."; read ;;
    esac
  done
}

# Check if --install is passed as first argument
if [[ "$1" == "--install" ]]; then
  install_tinyproxy
  exit 0
else
  menu
fi
# Make 'tiny' command available system-wide (if not already set)
SCRIPT_PATH="$(realpath "$0")"
LINK_PATH="/usr/local/bin/tiny"

if [[ ! -L "$LINK_PATH" ]]; then
  sudo ln -s "$SCRIPT_PATH" "$LINK_PATH"
  echo "[+] 'tiny' command is now available. You can run this tool by typing: tiny"
fi
