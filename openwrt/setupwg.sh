addresses="10.0.0.2/24"
serverhost="1.2.3.4"
serverport=51820
serverpubkey=""

opkg update
opkg install luci-app-wireguard ntpdate iptables ipset

wg genkey | tee privatekey | wg pubkey > publickey
privatekey=$(cat privatekey)
# publickey=$(wg pubkey <<< $privatekey)

cat >> /etc/config/network << EOF
config interface 'wg'
        option proto 'wireguard'
        option private_key '$privatekey'
        list addresses '$addresses'
        option mtu '1300'
        option listen_port '51820'

config wireguard_wg
        option public_key '$serverpubkey'
        option endpoint_host '$serverhost'
        option endpoint_port '$serverport'
        option persistent_keepalive '25'
        list allowed_ips '0.0.0.0/0'
        option route_allowed_ips '0'
EOF
/etc/init.d/network restart

uci add_list dhcp.@dnsmasq[0].server="8.8.8.8"
uci set dhcp.@dnsmasq[0].noresolv=1
uci commit
/etc/init.d/dnsmasq restart

uci set firewall.@zone[1].network="wan wan6 wg"
uci commit
/etc/init.d/firewall restart

reboot
