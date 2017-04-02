do
  local ieee80211_types = {
    management = 0,
    control = 1,
    data = 2
  }
  local channel_to_mhz = {
      [1] = 2412,
      [2] = 2417,
      [3] = 2422,
      [4] = 2427,
      [5] = 2432,
      [6] = 2437,
      [7] = 2442,
      [8] = 2447,
      [9] = 2452,
      [10] = 2457,
      [11] = 2462,
      [12] = 2467,
      [13] = 2472,
  }
  mhz_to_channel = {}
  for channel, freq in ipairs(channel_to_mhz) do
      mhz_to_channel[freq] = channel
  end

  local models = require "models"

  local time_channel_change = nil
  local wlan_fc_type_f = Field.new("wlan.fc.type")
  local wlan_fc_subtype_f = Field.new("wlan.fc.subtype")
  local wlan_sa_f = Field.new("wlan.sa")
  local wlan_fc_tods_f = Field.new("wlan.fc.tods")
  local wlan_fc_fromds_f = Field.new("wlan.fc.fromds")
  local wlan_da_f = Field.new("wlan.da")
  local wlan_bssid_f = Field.new("wlan.bssid")
  local wlan_mgt_ssid_f = Field.new("wlan_mgt.ssid")
  local radiotap_freq_f = Field.new("radiotap.channel.freq")

  local tap = Listener.new(nil, nil)

  function tap.draw()
  end

  function tap.packet(pinfo, tvb, frame)
    local time_retrieved = math.floor(pinfo.abs_ts)
    local fc_type = wlan_fc_type_f()
    local fc_subtype = wlan_fc_subtype_f()
    local sa = wlan_sa_f()
    local da = wlan_da_f()
    local fc_fromds = wlan_fc_fromds_f()
    local fc_tods = wlan_fc_tods_f()
    local bssid = wlan_bssid_f()
    local radiotap_freq = radiotap_freq_f()
    local wlan_mgt_ssid = wlan_mgt_ssid_f()

    if not fc_type or not fc_subtype or not sa then
      return
    end

    -- Beacon
    if fc_type.value == ieee80211_types.management and fc_subtype.value == 8 then
      models.AccessPoint:create{
        sensor_name = 'sensor1',
        time_seen = time_retrieved,
        bssid = tostring(bssid),
        name = wlan_mgt_ssid.value,
      }
    end

    -- Probe request
    if fc_type.value == ieee80211_types.management and fc_subtype.value == 4 then
      models.NodeProbe:create{
        sensor_name = 'sensor1',
        time_seen = time_retrieved,
        mac_address = tostring(sa),
        name = wlan_mgt_ssid.value
      }
    end

    -- Data
    if fc_type.value == ieee80211_types.data then
      if fc_tods.value and not fc_fromds.value then
        models.NodeSeen:create{
          sensor_name = 'sensor1',
          time_seen = time_retrieved,
          mac_address = tostring(sa),
          bssid = tostring(bssid),
          associated = true
        }
      elseif fc_fromds.value and not fc_tods.value then
        models.NodeSeen:create{
          sensor_name = 'sensor1',
          time_seen = time_retrieved,
          mac_address = tostring(da),
          bssid = tostring(bssid),
          associated = true
        }
      else
      end
    end

    -- Always AP
    -- Beacon frame: type: 0 subtype 8
    -- Probe Response frame: type: 0 subtype 5

--    -- Beacon frame.
--    if fc_type.value == 0 and fc_subtype.value == 8 then
--      -- access point
--    else
--      -- station
--      register_node(tostring(sa), time_retrieved)
--    end
--
--    if sa == bssid then
--    else if da == bssid then
--    end
  end

  function tap.reset()
  end
end
