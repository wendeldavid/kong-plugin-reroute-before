local http = require "resty.http"

local plugin = {
  PRIORITY = 715, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1",
}

-- iterator da configuração
local function iter(config_array)
  if type(config_array) ~= "table" then
    return noop
  end

  return function(config_array, i)
    i = i + 1

    local iter_config = config_array[i]
    if iter_config == nil then -- n + 1
      return nil
    end

    local header_name = iter_config.header_name
    local header_value = iter_config.header_value
    local url = iter_config.url

    if header_name == "" then
      header_name = nil
    end
    if header_value == "" then
      header_value = nil
    end
    if url == "" then
      url = nil
    end

    return i, header_name, header_value, url
  end, config_array, 0
end

-- retorna a url a ser chamada
local function getURL(plugin_conf)

  kong.log.debug("buscando url de customização")
  kong.log.debug(plugin_conf.after[1].header_name)

  for _, header_name, header_value, url in iter(plugin_conf.after) do
    local req_header_value = kong.request.get_header(header_name)

    kong.log.debug("iter config -> header_name: "..header_name.." header_value: "..header_value.." url: "..url)

    if (header_value == req_header_value) then
      return url
    end
  end

  return nil
end

local function make_request(plugin_conf, customizationUrl)
  local scheme, host, port, _ = unpack(http:parse_uri(customizationUrl))

  local client = http.new()
  client:set_timeout(plugin_conf.timeout)
  -- client:set_keepalive(10000)
  client:connect(host, port)
  if scheme == "https" then
      local ok, err = client:ssl_handshake()
      if not ok then
          kong.log.err(err)
          return kong.response.exit(500, { message = "An unexpected error occurred" })
      end
  end

  local res, err = client:request{
    path = customizationUrl,
    method = kong.request.get_method(),
    headers = kong.request.get_headers(),
    body = kong.request.get_raw_body(),
    keepalive_timeout = plugin_conf.timeout,
    ssl_verify = false
  }

  kong.log.debug("request feito")

  if not res then
    kong.log.err(err)
    return kong.response.exit(500, { message = "An unexpected error occurred" })
  end

  return res
end

-- runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)

  kong.log.debug("plugin:access -> request")
  kong.log.debug(kong.request)

  kong.log.debug("que seja feita a customização")

  local customizationUrl = getURL(plugin_conf)

  if customizationUrl ~= nil then
    kong.log.debug("faz o after pra fora e pega a resposta e manda pro upstream service")

    local afterRes = make_request(plugin_conf, customizationUrl)

    if not afterRes or afterRes.status >= 300 then
      return kong.response.exit(500, "fuuuuu")
    end

    kong.log.debug("resposta do after")
    kong.log.debug(afterRes)

    kong.log.debug("reaponse has body: "..tostring(afterRes.has_body))

    local body = afterRes:read_body()
    kong.log.debug("response body")
    kong.log.debug(body)

    return kong.service.request.set_raw_body(body)

  end

end

return plugin
