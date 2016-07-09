#!/bin/sh
#
# Generate AdBlock list from public and private lists
#
# 2016/07/09 - Version 1.0

# set your own private list URL
URL_LIST="https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdBlock/adblock-blacklist.list"

# destination file
FINAL_LIST="/etc/dnsmasq/adblock.hosts"

# set temporary file
TMP_LIST="/tmp/adblock.list"

# get current IP adress
IP_ADDR=$(ifconfig  | grep 'inet addr:' | grep -v '127.0.0.1' | cut -d: -f2 | cut -d' ' -f1 | head -n 1)

# retrieve public lists
echo "Retrieving public lists"
wget -q -O - http://www.mvps.org/winhelp2002/hosts.txt | grep "0.0.0.0" | sed "s/0.0.0.0[ ]*//" | sed "s/.$//" > "$TMP_LIST"
wget -q -O - http://adaway.org/hosts.txt | grep "127.0.0.1" | sed "s/127.0.0.1[ ]*//" >> "$TMP_LIST"
wget -q -O - http://www.malwaredomainlist.com/hostslist/hosts.txt | grep "127.0.0.1" | sed "s/127.0.0.1[ ]*//" | sed "s/.$//" >> "$TMP_LIST"
wget -q -O - --no-check-certificate https://hosts-file.net/ad_servers.txt | grep "127.0.0.1" | sed "s/127.0.0.1\t//" | sed "s/.$//" >> "$TMP_LIST"

# retrieve private list
echo "Retrieving private list"
wget -q -O - --no-check-certificate "$URL_LIST" >> "$TMP_LIST"

# concatenate, sort, deduplicate and format final list that is used by DNSMasq
echo "Generating final adblock list"
grep -v "#" "$TMP_LIST" | grep -v "^localhost" | grep -v "^127.0.0.1"| sort | uniq | sed "s/\(.*\)$/"$IP_ADDR"\t\1/" > "$FINAL_LIST"

# display result
NBR_SITE=$(wc -l "$FINAL_LIST" | cut -d' ' -f1)
echo "$NBR_SITE sites will now be blocked"

# restart DNSMasq
/etc/init.d/dnsmasq restart
