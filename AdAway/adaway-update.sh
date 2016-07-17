#!/bin/sh
#
# Generate AdAway list from public lists
#
# 2016/07/09 - Version 1.0
# 2016/07/14 - Version 1.1, Complete rewrite 
#              Now includes installation steps

# destination file
ADAWAY_BLACKLIST="/etc/adaway-blacklist.hosts"

# set temporary file
TMP_FILE=$(mktemp)
TMP_DOMAIN=$(mktemp)
TMP_HOST=$(mktemp)

# get current IP adress
IP_ADDR=$(ifconfig  | grep 'inet addr:' | grep -v '127.0.0.1' | cut -d: -f2 | cut -d' ' -f1 | head -n 1)

# --------------
#  INSTALLATION 
# --------------

# DNSMasq
IS_INSTALLED=$(grep "adaway.conf" /etc/dnsmasq.conf)
if [ "${IS_INSTALLED}" = "" ]
then
  # get adaway dnsmasq configuration file
  echo "get dnsmasq configuration for adaway"
  wget -q -O /etc/adaway.conf --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/adaway.conf"

  # declare adaway configuration in dnsmasq
  echo "Declare adaway configuration in DNSMasq"
  echo "" >> /etc/dnsmasq.conf
  echo "# enable Adaway" >> /etc/dnsmasq.conf
  echo "conf-file=/etc/adaway.conf" >> /etc/dnsmasq.conf
fi

# uhttpd
IS_INSTALLED=$(grep "adaway" /etc/config/uhttpd)
if [ "${IS_INSTALLED}" = "" ]
then
  # backup original file
  echo "Backup uhttpd configuration file"
  cp /etc/config/uhttpd /etc/config/uhttpd.org

  # change LUCI default ports to 1080 and 1443
  echo "Change LUCI default ports to 1080 and 1443"
  sed "s/:80/:1080/g" /etc/config/uhttpd | sed "s/:443/:1443/g" > ${TMP_FILE}
  mv ${TMP_FILE} /etc/config/uhttpd

  # add adaway site on ports 80
  echo "Add adaway site declaration to uhttpd"
  wget -q -O - --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/uhttpd.conf" >> /etc/config/uhttpd

  # create and populate adaway site root
  echo "Create and populate adaway web site root"
  mkdir /www-adaway
  wget -q -O /www-adaway/image.png --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/image.png"
  wget -q -O /www-adaway/index.html --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/index.html"

  # restart uhttpd
  echo "Restart uhttpd"
  /etc/init.d/uhttpd restart
fi

# ---------------------
#  DOMAIN LISTS UPDATE 
# ---------------------

# domain list
echo "Retrieve adaway domains blacklist"
wget -q -O ${TMP_DOMAIN} --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/list-domains"

# generate dnsmasq domain configuration
echo "Generate dnsmasq domain blacklist"
sed "s/^\(.*\)$/address=\/\1\/${IP_ADDR}/" ${TMP_DOMAIN} > /etc/adaway-domain.conf

# -------------------
#  HOST LISTS UPDATE 
# -------------------

echo "Retrieve adaway hosts blacklist"

# adaway list
echo "  * https://adaway.org/hosts.txt"
wget -q -O - --no-check-certificate "https://adaway.org/hosts.txt" | grep -v "^#"  | grep -v "localhost" | cut -d' ' -f2 > "${TMP_HOST}"

# winhelp2002 list
echo "  * http://winhelp2002.mvps.org/hosts.txt"
wget -q -O - "http://winhelp2002.mvps.org/hosts.txt" | grep -v "^#" | cut -d' ' -f2 >> "${TMP_HOST}"

# hosts-file.net list
echo "  * https://hosts-file.net/ad_servers.txt"
wget -q -O - --no-check-certificate "https://hosts-file.net/ad_servers.txt" | sed "s/^[0-9\.]*[^0-9a-z]*\(.*\)$/\1/" >> "${TMP_HOST}"

# fanboy easylist
echo "  * https://secure.fanboy.co.nz/easylist.txt"
wget -q -O - --no-check-certificate "https://secure.fanboy.co.nz/easylist.txt" | grep "^||" | grep -v "[/$\*=]" | sed "s/||\(.*\)^/\1/" >> "${TMP_HOST}"

# loop thru domains to remove hosts from these domains
echo "Remove hosts from blacklisted domains"
while read DOMAIN; do
  # remove any non ascii char
  DOMAIN=$(echo ${DOMAIN} | xargs)

  # display current domain
  echo "  - ${DOMAIN}"

  # remove hosts from this domain
  grep -v "${DOMAIN}" ${TMP_HOST} > ${TMP_FILE}
  rm ${TMP_HOST}
  mv ${TMP_FILE} ${TMP_HOST}
done < ${TMP_DOMAIN}

# concatenate, sort, deduplicate and format final hosts list that is used by DNSMasq
echo "Generate final hosts list"
sed "s/\r//g" ${TMP_HOST} | sed "/^$/d" | sort | uniq | sed "s/\(.*\)$/"${IP_ADDR}"\t\1/" > "${ADAWAY_BLACKLIST}"

# --------
#  RESULT 
# --------

# display result
NBR_LINE=$(wc -l "${TMP_DOMAIN}" | cut -d' ' -f1)
echo "$NBR_LINE domains will now be blocked"
NBR_LINE=$(wc -l "${ADAWAY_BLACKLIST}" | cut -d' ' -f1)
echo "$NBR_LINE hosts will now be blocked"

# restart DNSMasq
echo "Restart DNSMasq"
/etc/init.d/dnsmasq restart

# remove temporary file
rm -f ${TMP_FILE} ${TMP_DOMAIN} ${TMP_HOST}
