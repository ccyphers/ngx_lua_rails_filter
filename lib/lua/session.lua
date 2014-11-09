local session = {}

function session:new(params)
  params = params or {}
  params.sha1 = require("bgcrypto.sha1")
  params.cbc_decrypt = require("bgcrypto.aes").cbc_decrypter()
  params.base64 = require('base64')
  params.cgi = require("cgi")
  params.cjson = require("cjson")
  setmetatable(params, self)
  self.__index = self
  return params
end

function session:verify_message_signature(signed_message, expected)
  local key = self.sha1.pbkdf2(self.password, self.sign_salt, 1000, 64)
  local hmac     = self.sha1.hmac.new(key)
  hmac:update(signed_message)
  local digest = hmac:digest()
  hmac:destroy()
  local hexdigest = ""

  for b in string.gfind(digest, ".") do
    --hexdigest = hexdigest .. string.format("%02x", string.byte(b))
     hexdigest = hexdigest .. string.format("%02X", string.byte(b))
  end

  --print("VERIFYING SIGNATURE comparing ---" .. hexdigest .. "---- to ---" .. expected)
   return string.upper(expected) == hexdigest
  --return expected == hexdigest

end

-- In case there is garbage data after the last }
function session:clean(data)
  local num_closing_brackets = string.num_matches(data, "}")
  if num_closing_brackets > 0 then
    local garbage_data = string.sub_for_nth_match(data, "}", num_closing_brackets)
    x, y = string.find(data, garbage_data, nil, true)
    if x > 1 then
      return string.sub(data, 1, x-1)
    end
  end
  return data
end


function session:decrypt()

  --require('mobdebug').start('127.0.0.1')
  --print('blah')
  --require('mobdebug').done()

  local cookie = load("return ngx.var.cookie_" .. self.cookie_name)()

  if not cookie then
    return {session_id = "-1"}
  end

  print("COOKIE " .. cookie)
  cookie = self.cgi.unescape(cookie)


  local x,y = string.find(cookie, "--", nil, true)
  local left = string.sub(cookie, 1, x-1)
  local right = string.sub(cookie, y+1, #cookie)

  if not self:verify_message_signature(left, right) then
    return {session_id = "-1"}
  end


  local right_decoded = self.base64.decode(right)
  local left_decoded = self.base64.decode(left)
  local key = self.sha1.pbkdf2(self.password, self.salt, 1000, 32)

  x,y = string.find(left_decoded, "--", nil, true)
  local left_data = self.base64.decode(string.sub(left_decoded, 1, x-1))

  local iv = self.base64.decode(string.sub(left_decoded, y+1, #left_decoded))

  self.cbc_decrypt:open(key, iv)
  local decrypt = self.cbc_decrypt:write(left_data)
  self.cbc_decrypt:close()
local pl = require 'pl.pretty'
pl.dump(decrypt)
  local session_table = self:clean(decrypt)

  return self.cjson.decode(session_table)
end

return session
