local lib          = require "resty.lanli.library"
local ffi          = require "ffi"
local ffi_gc       = ffi.gc
local ffi_str      = ffi.string
local ffi_cdef     = ffi.cdef
local rawget       = rawget
local tonumber     = tonumber
local tostring     = tostring
local setmetatable = setmetatable

ffi_cdef[[
typedef void *(*lanli_realloc_callback)(void *, size_t);
typedef void (*lanli_free_callback)(void *);
struct lanli_buffer {
  uint8_t *data;
  size_t size;
  size_t asize;
  size_t unit;
  lanli_realloc_callback data_realloc;
  lanli_free_callback data_free;
};
typedef struct lanli_buffer lanli_buffer;
void lanli_buffer_init(lanli_buffer *buffer, size_t unit, lanli_realloc_callback data_realloc, lanli_free_callback data_free);
void lanli_buffer_uninit(lanli_buffer *buf);
lanli_buffer *lanli_buffer_new(size_t unit) __attribute__ ((malloc));
void lanli_buffer_reset(lanli_buffer *buf);
void lanli_buffer_grow(lanli_buffer *buf, size_t neosz);
void lanli_buffer_put(lanli_buffer *buf, const uint8_t *data, size_t size);
void lanli_buffer_puts(lanli_buffer *buf, const char *str);
void lanli_buffer_putc(lanli_buffer *buf, uint8_t c);
//int lanli_buffer_putf(lanli_buffer *buf, FILE* file);
void lanli_buffer_set(lanli_buffer *buf, const uint8_t *data, size_t size);
void lanli_buffer_sets(lanli_buffer *buf, const char *str);
int lanli_buffer_eq(const lanli_buffer *buf, const uint8_t *data, size_t size);
int lanli_buffer_eqs(const lanli_buffer *buf, const char *str);
int lanli_buffer_prefix(const lanli_buffer *buf, const char *prefix);
void lanli_buffer_slurp(lanli_buffer *buf, size_t size);
const char *lanli_buffer_cstr(lanli_buffer *buf);
void lanli_buffer_printf(lanli_buffer *buf, const char *fmt, ...) __attribute__ ((format (printf, 2, 3)));
void lanli_buffer_put_utf8(lanli_buffer *buf, unsigned int codepoint);
void lanli_buffer_free(lanli_buffer *buf);
]]

local buffer = {}
function buffer:__index(key)
    if     key == "data"  then
        return tostring(self)
    elseif key == "size"  then
        return tonumber(self.context.size)
    elseif key == "asize" then
        return tonumber(self.context.asize)
    elseif key == "unit"  then
        return tonumber(self.context.unit)
    else
        return rawget(buffer, key)
    end
end
function buffer.new(size)
    return setmetatable({ context = ffi_gc(lib.lanli_buffer_new(size or 64), lib.lanli_buffer_free) }, buffer)
end
function buffer:reset()
    lib.lanli_buffer_reset(self.context)
end
function buffer:grow(size)
    lib.lanli_buffer_grow(self.context, size)
end
function buffer:put(str)
    lib.lanli_buffer_put(self.context, str, #str)
end
function buffer:puts(str)
    lib.lanli_buffer_puts(self.context, str)
end
function buffer:set(str)
    lib.lanli_buffer_set(self.context, str, #str)
end
function buffer:sets(str)
    lib.lanli_buffer_sets(self.context, str)
end
function buffer:eq(str)
    return tonumber(lib.lanli_buffer_eq(self.context, str, #str)) == 1
end
function buffer:eqs(str)
    return tonumber(lib.lanli_buffer_eqs(self.context, str)) == 1
end
function buffer:prefix(prefix)
    return tonumber(lib.lanli_buffer_prefix(self.context, prefix))
end
function buffer:slurp(size)
    lib.lanli_buffer_slurp(self.context, size)
end
function buffer:cstr()
    return lib.lanli_buffer_cstr(self.context)
end
function buffer:printf(format, ...)
    lib.lanli_buffer_printf(self.context, format, ...)
end
function buffer:free()
    lib.lanli_buffer_free(self.context)
end
function buffer:__len()
    return tonumber(self.context.size)
end
function buffer.__eq(x, y)
    return tostring(x) == tostring(y)
end
function buffer.__concat(x, y)
    return tostring(x) .. tostring(y)
end
function buffer:__tostring()
    return ffi_str(self.context.data, self.context.size)
end

return buffer