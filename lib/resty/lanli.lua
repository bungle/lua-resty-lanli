local setmetatable = setmetatable

local lanli = {}

function lanli:__call()
    -- TODO: Implement sane defaults
end

return setmetatable({
    buffer   = require "resty.lanli.buffer",
    document = require "resty.lanli.document",
    escape   = require "resty.lanli.escape",
    version  = require "resty.lanli.version"
}, lanli)
