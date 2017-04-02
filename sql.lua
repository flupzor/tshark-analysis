SQLType = {}
function SQLType:new_type(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function SQLType:new(value)
  o = {value=value}
  setmetatable(o, self)
  self.__index = self
  return o
end

function SQLType:get_type()
    return self.type or 'char'
end

function SQLType:create_key(conn, key)
    return conn:escape(key)
end

function SQLType:create_equals_expression(conn, key, value )
    if self.type == 'increment' then
      return string.format('%s = %s + %s', self:create_key(conn, key), self:create_key(conn, key), conn:escape(self.value))
    else
      return string.format('%s = %s', self:create_key(conn, key), self:create_value(conn, value))
    end
end

function SQLType:create_value(conn)
  if self.type == 'char' then
    return string.format('\'%s\'', conn:escape(self.value))
  elseif self.type == 'number' then
    return string.format('%s', conn:escape(self.value))
  elseif self.type == 'boolean' then
    return string.format('%s', conn:escape(self.value and 'TRUE' or 'FALSE'))
  elseif self.type == 'datetime' then
    return string.format('to_timestamp(%d) AT TIME ZONE \'UTC\'', conn:escape(self.value))
  elseif self.type == 'increment' then
    return string.format('%s', conn:escape(self.value))
  end
end

CharType = SQLType:new_type{type='char'}
NumberType = SQLType:new_type{type='number'}
BooleanType = SQLType:new_type{type='boolean'}
DateTimeType = SQLType:new_type{type='datetime'}
IncrementType = SQLType:new_type{type='increment'}

function toType(value)
  if type(value) == 'boolean' then
    return BooleanType:new(value)
  elseif type(value) == 'number' then
    return NumberType:new(value)
  elseif type(value) == 'string' then
    return CharType:new(value)
  else
    return value
  end
end

function create_equals_expression(conn, t, seperator)
  query = {}
  for key, value in pairs(t) do
    o = toType(value)
    table.insert(query, o:create_equals_expression(conn, key))
  end

  return table.concat(query, seperator)
end

function create_clause(conn, t)
  return create_equals_expression(conn, t, ', ')
end

function create_search_condition(conn, t)
  return create_equals_expression(conn, t, ' AND ', false)
end

function create_update(conn, table_name, set_list, where_list)
  set_list = create_clause(conn, set_list)
  where_list = create_search_condition(conn, where_list)

  return string.format('UPDATE %s SET %s WHERE %s', table_name, set_list, where_list)
end

function create_insert(conn, table_name, insert_list)
  local keys_list = {}
  local values_list = {}
  for key, value in pairs(insert_list) do
    o = toType(value)
    table.insert(keys_list, o:create_key(conn, key))
    table.insert(values_list, o:create_value(conn))
  end

  keys_list = table.concat(keys_list, ', ')
  values_list = table.concat(values_list, ', ')

  return string.format('INSERT INTO %s (%s) VALUES ( %s )', table_name, keys_list, values_list)
end

function create_select(conn, table_name, column_list, where_list)
  local column_list = table.concat(column_list, ', ')
  local where_list = create_search_condition(conn, where_list)

  return string.format('SELECT %s FROM %s WHERE %s', column_list, table_name, where_list)
end

local Row = {}
function Row.exists(conn, table_name, key_table)
  column_list = {}
  for column_name, value in pairs(key_table) do
    table.insert(column_list, column_name)
  end
  cursor = assert (conn:execute(create_select(conn, table_name, column_list, key_table)))
  return cursor:numrows() > 0
end
function Row.update(conn, table_name, key_table, update_table)
  assert(conn:execute(create_update(conn, table_name, update_table, key_table)))
end
function Row.insert(conn, table_name, key_table, insert_table, update_table)
  local new_table = {}
  for key, value in pairs(key_table) do
    new_table[key] = value
  end
  for key, value in pairs(insert_table) do
    new_table[key] = value
  end
  for key, value in pairs(update_table) do
    new_table[key] = value
  end

  assert(conn:execute(create_insert(conn, table_name, new_table)))
end

function insert_or_update(conn, table_name, key_table, insert_table, update_table)
  if Row.exists(conn, table_name, key_table) then
    Row.update(conn, table_name, key_table, update_table)
  else
    Row.insert(conn, table_name, key_table, insert_table, update_table)
  end
end

return {
  insert_or_update = insert_or_update,
  CharType = CharType,
  NumberType = NumberType,
  BooleanType = BooleanType,
  DateTimeType = DateTimeType,
  IncrementType = IncrementType,
}
