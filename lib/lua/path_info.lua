path_info = {}

function path_info:new(params)
  params = params or {}
  params.json = params.json or '/tmp/nginx-lua/path_info.json'

  setmetatable(params, self)
  self.__index = self
  return params
end

function path_info:parse()
  local pl = require "pl.pretty"
  pl.dump(self)
  local cjson = require("cjson")
  io.input(self.json)
  return cjson.decode(io.read("*a"))
end

return path_info
