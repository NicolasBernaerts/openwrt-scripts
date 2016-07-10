#!/bin/sh
# Install DNSMasq adblocker
#
# Package wget should be installed with
#    $ opkg install wget
#
# 2016/07/09 - Version 1.0

# update /etc/dnsmasq.conf
echo "" >> /etc/dnsmasq.conf
echo "# enable AdAway list" >> /etc/dnsmasq.conf
echo "addn-hosts=/etc/adaway.hosts" >> /etc/dnsmasq.conf

# install AdBlock list generation script
wget -q -O /usr/bin/adaway-generate.sh --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/adaway-generate.sh"
chmod +x /usr/bin/adaway-generate.sh

# generate AdBlock list
/usr/bin/adaway-generate.sh

# set LUCI 404 as 1x1 pixel
wget -q -O /www/1x1.png --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/1x1.png"
uci set uhttpd.main.error_page='/1x1.png'
uci commit uhttpd

# restart dnsmasq and uhttpd
/etc/init.d/dnsmasq restart
/etc/init.d/uhttpd restart
