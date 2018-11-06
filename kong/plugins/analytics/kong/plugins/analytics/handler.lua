local BasePlugin = require "kong.plugins.base_plugin"
local basic_serializer = require "kong.plugins.log-serializers.basic"
local zlib = require 'zlib'
local AnayticsHandler = BasePlugin:extend()

local ngx_timer_at = ngx.timer.at
local string_format = string.format
local ngx_log = ngx.log
local udp = ngx.socket.udp

local json = require "cjson"

local function log(premature, conf, message)
    if premature then
        return
    end

    local sock = udp()
    sock:settimeout(conf.timeout)

    local ok, err = sock:setpeername(conf.host, conf.port)
    if not ok then
        ngx.log(ngx.ERR, "[analytics-log] could not connect to ", conf.host, ":", conf.port, ": ", err)
        return
    end

    local service_name
    local consumer_name

    if message.service and message.service.name then
        service_name = message.service.name ~= ngx.null and
                message.service.name or message.service.host
    elseif message.api and message.api.name then
        service_name = message.api.name
    else
        service_name = '@'
    end

    if message.consumer and message.consumer.username then
        consumer_name = message.consumer.username
    else
        consumer_name = '@'
    end

    local entry = string_format("service_name=%s consumer_name=%s url=%s status=%d",
        service_name, consumer_name, message.request.url, message.response.status)

    local log_message = {
        ["version"] = "1.1",
        ["host"] = "kong",
        ["short_message"] = entry,
        ["_service_name"] = service_name,
        ["level"] = 4,
        ["tag"] = conf.tag or "kong",
        ["_consumer_name"] = consumer_name
    }
    local str = json.encode(log_message)

    local stream = zlib.deflate()
    local deflated = stream(str, 'finish')
    ok, err = sock:send(deflated)

    if not ok then
        ngx.log(ngx.ERR, " [analytics-log] could not send data to ", conf.host, ":", conf.port, ": ", err)
    else
        ngx.log(ngx.DEBUG, "[analytics-log] sent: ", str)
    end

    ok, err = sock:close()
    if not ok then
        ngx.log(ngx.ERR, "[udp-log] could not close ", conf.host, ":", conf.port, ": ", err)
    end
end

AnayticsHandler.PRIORITY = 11


function AnayticsHandler:new()
    AnayticsHandler.super.new(self, "analytics-plugin")
end

function AnayticsHandler:log(conf)
    AnayticsHandler.super.log(self)

    local message = basic_serializer.serialize(ngx)
    local ok, err = ngx_timer_at(0, log, conf, message)

    if not ok then
        ngx_log(NGX_ERR, "failed to create timer: ", err)
    end
end

return AnayticsHandler