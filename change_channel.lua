do
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
  local time_channel_change = nil
  local tap = Listener.new(nil, nil)
  local radiotap_freq_f = Field.new("radiotap.channel.freq")

  function tap.draw()
  end

  function tap.packet(pinfo, tvb, frame)
    local radiotap_freq = radiotap_freq_f()
    local current_channel = mhz_to_channel[radiotap_freq.value]
    local current_time = os.time()
    local time_retrieved = math.floor(pinfo.abs_ts)

    -- Pretend the first time a frame is processed the channel is changed.
    if not time_channel_change then
      time_channel_change = time_retrieved
    end

    if (current_time - time_channel_change) > 1 then
      print("Changing channel")
      -- iterate trough channels 1 up to and including 13
      local set_channel = 1 + (current_channel % 13)

--      os.execute("dumpcap -i wlp0s29u1u2 -k " .. channel_to_mhz[set_channel])
--      os.execute("dumpcap -i phy0.mon -k " .. channel_to_mhz[set_channel])

      time_channel_change = current_time
    end
  end

  function tap.reset()
  end
end
