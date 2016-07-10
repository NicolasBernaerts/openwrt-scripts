#!/bin/sh
#
# Generate AdBlock list from public and private lists
#
# 2016/07/09 - Version 1.0

# set your own private list URL
URL_LIST="https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/adaway-blacklist.list"

# destination file
FINAL_LIST="/etc/adaway.hosts"

# set temporary file
TMP_LIST="/tmp/adaway.list"

# get current IP adress
IP_ADDR=$(ifconfig  | grep 'inet addr:' | grep -v '127.0.0.1' | cut -d: -f2 | cut -d' ' -f1 | head -n 1)

# retrieve public lists
echo "Retrieving public lists"
wget -q -O - "http://adaway.org/hosts.txt" | grep -v "^#" | sed "s/^[0-9 \.\t]*//" | cut -d' ' -f1 > "$TMP_LIST"
wget -q -O - "http://winhelp2002.mvps.org/hosts.txt" | grep -v "^#" | sed "s/^[0-9 \.\t]*//" | cut -d' ' -f1 > "$TMP_LIST"
wget -q -O - --no-check-certificate "https://hosts-file.net/ad_servers.txt" | grep -v "^#" | sed "s/^[0-9 \.\t]*//" | cut -d' ' -f1  >> "$TMP_LIST"
wget -q -O - --no-check-certificate "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext" | grep -v "^#" | sed "s/^[0-9 \.\t]*//" | cut -d' ' -f1  >> "$TMP_LIST"

# retrieve private list
echo "Retrieving private list"
wget -q -O - --no-check-certificate "$URL_LIST" >> "$TMP_LIST"

# concatenate, sort, deduplicate and format final list that is used by DNSMasq
echo "Generating final adblock list"
sort "$TMP_LIST" | uniq | sed "s/\(.*\)$/"$IP_ADDR"\t\1/" > "$FINAL_LIST"

# display result
NBR_SITE=$(wc -l "$FINAL_LIST" | cut -d' ' -f1)
echo "$NBR_SITE sites will now be blocked"

# restart DNSMasq
echo "Restarting DNSMasq"
/etc/init.d/dnsmasq restart
