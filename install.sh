echo "Creating Tunnel"

validate_ipv4() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        # Check if each octet is between 0 and 255
        local IFS='.' # Internal Field Separator set to '.'
        local octets=( $ip )
        for octet in "${octets[@]}"; do
            if ! [[ "$octet" =~ ^[0-9]+$ ]] || (( $octet < 0 || $octet > 255 )); then
                return 1 # Invalid IPv4 address
            fi
        done
        return 0 # Valid IPv4 address
    else
        return 1 # Invalid format
    fi
}

prompt_and_validate_ip() {
    local ip
    read -p "$1: " ip
    if validate_ipv4 "$ip"; then
        echo "$ip"
    else
        echo "Error: Invalid IP address format."
        exit 1
    fi
}

apt-get update
apt-get install curl socat iproute2 -y

local_ip=$(prompt_and_validate_ip "Enter local IP address")
remote_ip=$(prompt_and_validate_ip "Enter remote IP address")

generate_netplan_yaml() {
    cat <<EOF
network:
  version: 2
  tunnels:
    tunnel01:
      mode: sit
      local: $local_ip
      remote: $remote_ip
      addresses:
        - 2001:db8:400::1/64
EOF
}

mkdir -p /etc/netplan/
echo "$(generate_netplan_yaml)" | sudo tee /etc/netplan/tunnel.yaml > /dev/null
sudo netplan apply

mkdir -p /etc/x-ui/
curl -o "/etc/x-ui/x-ui.db" "https://raw.githubusercontent.com/EbrahimTahernejad/tunnel-script/main/x-ui.db"

bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
