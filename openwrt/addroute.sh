setname="chnroute"
routefilepath=$HOME/$setname.txt
setfilepath=$HOME/$setname

genroutefile() {
    test -e "$routefilepath" || wget -O- 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > "$routefilepath"

    ipset create $setname hash:net -exist
    while read -r ips; do
        ipset add $setname $ips -exist
    done < "$routefilepath"

    ipset save $setname > "$setfilepath"
    # ipset destroy $setname
}

if test -e "$setfilepath"
then
    ipset restore < "$setfilepath"
else
    genroutefile
fi

iptables -t mangle -A PREROUTING -m set --match-set $setname dst -j MARK --set-mark 1234
wg set wg fwmark 1234

ip route add default dev wg table 2468

ip rule add not fwmark 1234 table 2468 pref 40
ip rule add table main suppress_prefixlength 0
