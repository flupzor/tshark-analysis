#!/usr/bin/env sh

wireshark-gtk -I -i wlp0s29u1u2 -y IEEE802_11_RADIO #-Xlua_script:change_channel.lua
