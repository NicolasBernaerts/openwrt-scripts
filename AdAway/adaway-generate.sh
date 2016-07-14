#!/bin/sh
#
# Generate AdAway list from public lists
#
# 2016/07/09 - Version 1.0
# 2016/07/14 - Version 1.1, Complete rewrite

# destination file
ADAWAY_DOMAIN="/etc/adaway-domain.conf"
ADAWAY_BLACKLIST="/etc/adaway-blacklist.hosts"

# set temporary file
TMP_FILE=$(mktemp)

# get current IP adress
IP_ADDR=$(ifconfig  | grep 'inet addr:' | grep -v '127.0.0.1' | cut -d: -f2 | cut -d' ' -f1 | head -n 1)

# --------------
#  DOMAIN LISTS 
# --------------

# fanboy easylist
echo "Retrieving fanboy easylist domain list"
wget -q -O - --no-check-certificate https://secure.fanboy.co.nz/easylist.txt | grep "^||" | grep -v "[/$\*=]" | sed "s/||\(.*\)^/\1/" > "${TMP_FILE}"

# concatenate, sort, deduplicate and format final domain list that is used by DNSMasq
echo "Generating final domains list"
sort "${TMP_FILE}" | uniq | sed "s/\(.*\)$/server=\/\1\/${IP_ADDR}/" > "${ADAWAY_DOMAIN}"

# ------------
#  HOST LISTS 
# ------------

# adaway list
echo "Retrieving adaway host list"
wget -q -O - "http://adaway.org/hosts.txt" | grep -v "^#"  | grep -v "localhost" | cut -d' ' -f2 > "${TMP_FILE}"

# winhelp2002 list
echo "Retrieving winhelp2002 host list"
wget -q -O - "http://winhelp2002.mvps.org/hosts.txt" | grep -v "^#" | cut -d' ' -f2 >> "${TMP_FILE}"

# hosts-file.net list
echo "Retrieving hosts-file.net host list"
wget -q -O - --no-check-certificate "https://hosts-file.net/ad_servers.txt" | sed "s/^[0-9\.]*[^0-9a-z]*\(.*\)$/\1/" >> "${TMP_FILE}"

# concatenate, sort, deduplicate and format final hosts list that is used by DNSMasq
echo "Generating final hosts list"
sort "${TMP_FILE}" | uniq | sed "s/\(.*\)$/"${IP_ADDR}"\t\1/" > "${ADAWAY_BLACKLIST}"

# --------
#  RESULT 
# --------

# restart DNSMasq
echo "Restarting DNSMasq"
/etc/init.d/dnsmasq restart

# display result
NBR_DOMAIN=$(wc -l "${ADAWAY_DOMAIN}" | cut -d' ' -f1)
echo "$NBR_DOMAIN domains will now be blocked"
NBR_HOST=$(wc -l "${ADAWAY_BLACKLIST}" | cut -d' ' -f1)
echo "$NBR_HOST hosts will now be blocked"
