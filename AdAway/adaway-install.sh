#!/bin/sh
# Install DNSMasq adblocker
#
# Package wget should be installed with
#    $ opkg install wget
#
# 2016/07/09 - Version 1.0

# /etc/dnsmasq.conf
# add adaway DNS host list
echo "Declare adaway configuration in DNSMasq"
echo "" >> /etc/dnsmasq.conf
echo "# enable AdAway list" >> /etc/dnsmasq.conf
echo "addn-hosts=/etc/adaway.hosts" >> /etc/dnsmasq.conf

# /etc/config/uhttpd
# change LUCI default ports to 1080 and 1443
# add adaway site on ports 80
echo "Change LUCI default ports to 1080 and 1443 add declare adaway site on port 80"
cat /etc/config/uhttpd | sed "s/:80/:1080/g" | sed "s/:443/:1443/g" > /tmp/uhttpd.conf
wget -q -O - --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/uhttpd.conf" >> /tmp/uhttpd.conf
mv etc/config/uhttpd etc/config/uhttpd.org
mv /tmp/uhttpd.conf /etc/config/uhttpd

# restart uhttpd
echo "Restarting uhttpd"
/etc/init.d/uhttpd restart

# create and populate adaway site root
echo "Create and populate adaway web site root"
mkdir /www-adaway
wget -q -O /www-adaway/1x1.png --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/1x1.png"
echo "<img width='1' height='1' src='/1x1.png' />" > "/www-adaway/index.html"

# install adaway list generation script
wget -q -O /usr/bin/adaway-generate.sh --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdAway/adaway-generate.sh"
chmod +x /usr/bin/adaway-generate.sh

# generate AdBlock list
/usr/bin/adaway-generate.sh
