#!/usr/bin/env sh

tshark -I -i wlp0s29u1u2 -y IEEE802_11_RADIO -q -Xlua_script:ieee80211.lua
