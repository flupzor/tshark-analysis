-- TODO: This module should use PostgreSQL upsert once raspbian supports PostgreSQL 9.5.
function startswith(str, startswith)
  start = string.sub(str, 0, string.len(startswith))
  return start == startswith
end

local luasql = require "luasql.postgres"
local env = assert (luasql.postgres())
local conn = assert (env:connect("pi"))

local sql = require "sql"

local TimeBlock = {}
function TimeBlock.round_time(timestamp)
  local five_minutes = 60 * 5
  local rounded_time = timestamp - (timestamp % five_minutes)

  return rounded_time
end
function TimeBlock:is_saved()
  return true
end
function TimeBlock:get_table_name()
  return nil
end
function TimeBlock:get_key()
  local rounded_time = self.round_time(self.time_seen)
  return {
    sensor = self.sensor_name,
    start_block = DateTimeType:new(rounded_time),
  }
end
function TimeBlock:get_insert_data()
  return {
    duration = 300,
    first_seen = DateTimeType:new(self.time_seen),
  }
end
function TimeBlock:get_update_data()
  return {
    last_seen = DateTimeType:new(self.time_seen),
    times_seen = IncrementType:new(1),
  }
end
function TimeBlock:new(o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function TimeBlock:create(t)
  local o = self:new(t)
  local table_name = o:get_table_name()
  local key = o:get_key()
  local insert_data = o:get_insert_data()
  local update_data = o:get_update_data()
  if o:is_saved() then
    return sql.insert_or_update(conn, table_name, key, insert_data, update_data)
  end
end

local NodeSeen = TimeBlock:new()
function NodeSeen:is_saved()
   if startswith(self.mac_address, "33:33") then
     return false
   end

  -- TODO should be: 01:00:5e:00:00:00–01:00:5e:7f:ff:ff
   if startswith(self.mac_address, "01:00:5e:00:") then
     return false
   end
   if startswith(self.mac_address, "01:00:5e:7f:") then
     return false
   end

   if startswith(self.mac_address, "ff:ff:ff:ff:ff:ff") then
     return false
   end

  return true
end
function NodeSeen:get_table_name()
  return 'addresses_nodeseen'
end
function NodeSeen:get_key()
  local key = TimeBlock.get_key(self)
  key['mac_address'] = self.mac_address
  key['bssid'] = self.bssid
  return key
end
function NodeSeen:get_insert_data()
  insert_data = TimeBlock.get_insert_data(self)
  return insert_data
end
function NodeSeen:get_update_data()
  update_data = TimeBlock.get_update_data(self)
  update_data['associated'] = self.associated
  return update_data
end

local AccessPoint = TimeBlock:new()
function AccessPoint:get_table_name()
  return 'addresses_accesspoint'
end
function AccessPoint:get_key()
  local key = TimeBlock.get_key(self)
  key['bssid'] = self.bssid
  return key
end
function AccessPoint:get_insert_data()
  insert_data = TimeBlock.get_insert_data(self)
  insert_data['name'] = self.name
  return insert_data
end

local NodeProbe = TimeBlock:new()
function NodeProbe:get_table_name()
  return 'addresses_nodeprobe'
end
function NodeProbe:get_key()
  local key = TimeBlock.get_key(self)
  key['mac_address'] = self.mac_address
  key['name'] = self.name
  return key
end

return {
  NodeSeen = NodeSeen,
  AccessPoint = AccessPoint,
  NodeProbe = NodeProbe
}

