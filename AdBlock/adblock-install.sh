#!/bin/sh
# Install DNSMasq adblocker
#
# Package wget should be installed with
#    $ opkg install wget
#
# 2016/07/09 - Version 1.0

# update /etc/dnsmasq.conf
echo "" >> /etc/dnsmasq.conf
echo "# enable AdBlock list" >> /etc/dnsmasq.conf
echo "addn-hosts=/etc/dnsmasq/adblock.hosts" >> /etc/dnsmasq.conf

# create directory for lists
mkdir -p /etc/dnsmasq

# install AdBlock list generation script
wget -q -O /usr/bin/adblock-generate.sh --no-check-certificate "https://raw.githubusercontent.com/NicolasBernaerts/openwrt-scripts/master/AdBlock/adblock-generate.sh"
chmod +x /usr/bin/adblock-generate.sh

# generate AdBlock list
/usr/bin/adblock-generate.sh
