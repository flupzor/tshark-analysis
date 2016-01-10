do
  local stations = {}
  local access_points = {}

  local current_channel = 1
  local last_channel_change = os.time()

  local wlan_fc_type_f = Field.new("wlan.fc.type")
  local wlan_fc_subtype_f = Field.new("wlan.fc.subtype")
  local wlan_sa_f = Field.new("wlan.sa")

  local last_print = os.time()

  local tap = Listener.new(nil, nil)

  function display_sorted(address_list)
    local _address_list = {}
    local current_time = os.time()

    for addr, last_seen in pairs(address_list) do
      if not access_points[addr] then
        table.insert(_address_list, {addr = addr, last_seen = last_seen})
      end
    end

    local cmp = function (a, b)
      return a.last_seen < b.last_seen
    end

    table.sort(_address_list, cmp)

    os.execute("clear")

    for key, val in pairs(access_points) do
      print(key)
    end

    print("\n")

    print("Address\t\t\tLast seen (in seconds)")
    for i, entry in ipairs(_address_list) do
      print(entry.addr .. "\t" .. current_time - entry.last_seen)
    end
  end

  function tap.draw()
  end

  function tap.packet(pinfo, tvb, frame)
    local fc_type = wlan_fc_type_f()
    local fc_subtype = wlan_fc_subtype_f()
    local sa = wlan_sa_f()
    local current_time = os.time()

    if not fc_type or not fc_subtype or not sa then
      return
    end

    if fc_type.value == 0 and fc_subtype.value == 8 then
      access_points[tostring(sa)] = pinfo.abs_ts
    else

      stations[tostring(sa)] = pinfo.abs_ts

      if current_time - last_print > 1 then
        display_sorted(stations)
        last_print = os.time()
      end
    end

    if current_time - last_channel_change > 1 then
      -- iterate trough channels 1 up to and including 13
      local set_channel = 1 + (current_channel % 14)

      os.execute("ifconfig run0 chan " .. set_channel)

      last_channel_change = os.time()
      current_channel = set_channel
    end
  end

  function tap.reset()
    debug("reset")
  end
end
