#!/usr/bin/env sh

# sudo is needed because i change channels in the lua script.
sudo tshark -i run0 -y IEEE802_11_RADIO -q -Xlua_script:ieee80211.lua
