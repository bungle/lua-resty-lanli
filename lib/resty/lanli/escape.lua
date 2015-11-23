local buffer       = require "resty.lanli.buffer"
local new_buf      = buffer.new
local lib          = require "resty.lanli.library"
local ffi          = require "ffi"
local ffi_cdef     = ffi.cdef
local setmetatable = setmetatable
local tostring     = tostring

ffi_cdef[[
void lanli_escape_html(lanli_buffer *ob, const uint8_t *data, size_t size);
void lanli_unescape_html(lanli_buffer *ob, const uint8_t *data, size_t size);
]]

local escape = {}

function escape.html(source)
    local str = tostring(source)
    local len = #str
    local buf = new_buf(len);
    lib.lanli_escape_html(buf.context, str, len);
    return tostring(buf)
end

return setmetatable(escape, { __call = function(_, source, secure)
    return escape.html(source, secure)
end })