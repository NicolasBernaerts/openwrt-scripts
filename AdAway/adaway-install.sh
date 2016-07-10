#!/bin/sh
# Install DNSMasq adblocker
#
# Package wget should be installed with
#    $ opkg install wget
#
# 2016/07/09 - Version 1.0

# create and populate adaway site root
mkdir /www-adaway
wget -q -O /www-adaway/1x1.png --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/1x1.png"
echo "<img width='1' height='1' src='/1x1.png' />" > "/www-adaway/index.html"

# /etc/dnsmasq.conf
# add adaway DNS host list
echo "" >> /etc/dnsmasq.conf
echo "# enable AdAway list" >> /etc/dnsmasq.conf
echo "addn-hosts=/etc/adaway.hosts" >> /etc/dnsmasq.conf

# /etc/config/uhttpd
# change default ports to 1080 and 1443
# add adaway site on ports 80 and 443
cat /etc/config/uhttpd | sed "s/:80/:1080/g" | sed "s/:443/:1443/g" > /tmp/uhttpd.conf
wget -q -O - --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/uhttpd.conf" >> /tmp/uhttpd.conf
mv /tmp/uhttpd.conf /etc/config/uhttpd

# install AdBlock list generation script
wget -q -O /usr/bin/adaway-generate.sh --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/adaway-generate.sh"
chmod +x /usr/bin/adaway-generate.sh

# generate AdBlock list
/usr/bin/adaway-generate.sh

# restart dnsmasq and uhttpd
/etc/init.d/dnsmasq restart
/etc/init.d/uhttpd restart
