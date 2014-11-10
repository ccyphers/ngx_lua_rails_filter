local path_filter = {}

function path_filter:new(params)
  params = params or {}
  params.path_info_json = params.path_info_json or '/tmp/nginx-lua/path_info.json'
  params.table_closures = require("table_closures")
  params.paths = require("path_info"):new({json = params.path_info_json}):parse()
  params.redis_config = params.redis_config or {}
  params.redis_config.host = params.redis_config.host or '127.0.0.1'
  params.redis_config.port = params.redis_config.port or 6379
  params.redis = require "redis"
  params.md5 = require "md5"
  params.redis_client = params.redis.connect(params.redis_config.host, params.redis_config.port)
  setmetatable(params, self)
  self.__index = self
  return params
end


function path_filter:ngx_request_method()
  local str = ngx.var.request
  local x = string.find(str, " ")
  return string.sub(str, 0, x-1)
end

function path_filter:ngx_request_path()
  local str = ngx.var.request
  local x = string.find(str, " ")
  str = string.sub(str, x+1, #str)
  x = string.find(str, " ")
  return string.sub(str, 1, x-1)
end

function path_filter:process_static_assets(path)
  local x,y=string.find(path, "/assets")
  if x then
    if x == 1 then
      return true
    end
  end
  return false
end


function path_filter:match(method, path)
  local ct1 = string.num_matches(path, "/")
  local ct2=-1

  local static = self:process_static_assets(path)

  if static then
    return true
  end

  for x in self.table_closures.get(self.paths) do
    if x.method == method then
      ct2 = string.num_matches(x.path, "/")
      if ct1 == ct2 then
        if string.match(path, x.path) then
          local last = string.sub_for_nth_match(x.path, "/", ct1)
          local is_pattern = string.sub_for_nth_match(last, "%%", 1)

          if is_pattern == "" then
            local last2 = string.sub_for_nth_match(path, "/", ct1)
            if not (last == last2) then
              return false
            end
          end

          return x
        end
      end
    end
  end
  return false
end

function path_filter:handle_auth(item)
  if item.auth_required then
    local s = self.session:decrypt()
    local id = ""
    local crypt = ""

    for x in self.table_closures.get(s['warden.user.user.key']) do
      if type(x) == 'table' then
        for y in self.table_closures.get(x) do
          id = y
        end
      elseif type(x) == 'string' then
        crypt = x
      end
    end

    if not self.redis_client:get(self.md5.sumhexa(id .. crypt)) then
      ngx.body = ""
      ngx.status = 401
      ngx.exit(401)
    end

  end
end

function path_filter:perform()
  local method = self:ngx_request_method()
  local path = string.sub_for_nth_match(self:ngx_request_path(), "?", 0)


  local match = self:match(method, path)

  if not match then
    ngx.status = 404
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end

  return match

end

return path_filter
