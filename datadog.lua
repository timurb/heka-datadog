require "cjson"
require "table"
require "string"
require "os"

local math = require "math"
local l = require "lpeg"
l.locale(l)

local tag_prefix      = read_config("tag_prefix") or error("`tag_prefix` setting required")
local tag_list_str    = read_config("tag_list") or ""
local skip_fields_str = read_config("skip_fields") or ""
local type_as_prefix  = read_config("type_as_prefix")
local ts_from_message = read_config("ts_from_message")

if ts_from_message == nil then
  ts_from_message = true
end

tag_list = {}
for field in tag_list_str:gmatch("[%S]+") do
  tag_list[field] = true
end

skip_fields = {}
for field in skip_fields_str:gmatch("[%S]+") do
  skip_fields[field] = true
end

local prefix = l.P(tag_prefix)
local chars = l.alnum + l.S("_-./")
local grammar = prefix * l.C(l.alpha * chars^0)

function format_tag(key, value)
  return tostring(key) .. ":" .. tostring(value)
end

function process_message()
  local ts
  if ts_from_message then
    ts = math.floor(read_message("Timestamp") / 1e9)
  else
    ts = os.time()
  end

  local typ=read_message("Type")
  local tags = {}
  local metrics = {}

  local msg = decode_message(read_message("raw"))
  if not msg.Fields then
    return -1, "Malformed message (no fields)"
  end

  for _, field in ipairs(msg.Fields) do
    local name = field.name      -- these are related to way Heka works
    local value = field.value[1] --

    local tag = grammar:match(name) or (tag_list[name] and name)
    if tag then
      table.insert(tags, format_tag(tag, value))
    else
      value = tonumber(value)
      if value and not skip_fields[name] then
        if type_as_prefix then
          name = string.format("%s.%s", typ, name)
        end
        metrics[name] = value
      end
    end
  end

  local out = {}
  out.series = {}

  for name, value in pairs(metrics) do
    local message = {}
    message.metric = name
    message.host = msg.Hostname
    message.type = "counter"
    message.tags = tags

    values = {{ts, value}}
    message.points = values
    table.insert(out.series,message)
  end

  inject_payload("","",cjson.encode(out))
  return 0
end
