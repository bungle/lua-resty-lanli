local buffer       = require "resty.lanli.buffer"
local new_buf      = buffer.new
local lib          = require "resty.lanli.library"
local ffi          = require "ffi"
local ffi_gc       = ffi.gc
local ffi_cdef     = ffi.cdef
local bit          = require "bit"
local bor          = bit.bor
local type         = type
local tostring     = tostring
local ipairs       = ipairs
local setmetatable = setmetatable

ffi_cdef[[
typedef enum lanli_tag_type {
  LANLI_TAG_OPEN,
  LANLI_TAG_CLOSE,
  LANLI_TAG_SELFCLOSE
} lanli_tag_type;
typedef enum lanli_element_type {
  LANLI_EL_NORMAL,
  LANLI_EL_VOID,
  LANLI_EL_RAW,
  LANLI_EL_RAW_ESCAPABLE
} lanli_element_type;
typedef enum lanli_flags {
  LANLI_FLAG_COMMENTS_PARSE = (1 << 0),
  LANLI_FLAG_COMMENTS_SKIP = (1 << 1),
  LANLI_FLAG_INVALID_SKIP = (1 << 2),
  LANLI_FLAG_LEVELS_STRICT = (1 << 3)
} lanli_flags;
typedef enum lanli_action {
  LANLI_ACTION_ACCEPT,
  LANLI_ACTION_ESCAPE,
  LANLI_ACTION_SKIP,
  LANLI_ACTION_IGNORE,
  LANLI_ACTION_VERBATIM
} lanli_action;
struct lanli_tag_attribute {
  lanli_buffer *name;
  lanli_buffer *value;
  int has_value;
};
typedef struct lanli_tag_attribute lanli_tag_attribute;
struct lanli_tag {
  size_t level;
  lanli_buffer *name;
  lanli_tag_attribute *attributes;
  size_t attributes_count;
  lanli_tag_type tag_type;
  lanli_element_type type;
  void *opaque;
};
typedef struct lanli_tag lanli_tag;
struct lanli_tag_stack {
  lanli_tag *tags;
  lanli_tag *orig;
  size_t size;
  size_t asize;
  size_t max_attributes;
};
typedef struct lanli_tag_stack lanli_tag_stack;
typedef lanli_action (*lanli_callback)(lanli_tag *tag, const lanli_tag_stack *stack, void *opaque);
struct lanli_document;
typedef struct lanli_document lanli_document;
lanli_document *lanli_document_new(lanli_callback callback, void *opaque, lanli_flags flags, size_t levels, size_t max_nesting, size_t max_attributes) __attribute__ ((malloc));
void lanli_document_render(lanli_document *doc, lanli_buffer *ob, const uint8_t *data, size_t size);
void lanli_document_free(lanli_document *doc);
lanli_action lanli_callback_strict_post(lanli_tag *tag, const lanli_tag_stack *stack, void *opaque);
]]

local flags = {
    comments_parse = lib.LANLI_FLAG_COMMENTS_PARSE,
    comments_skip  = lib.LANLI_FLAG_COMMENTS_SKIP,
    invalid_skip   = lib.LANLI_FLAG_INVALID_SKIP,
    levels_strict  = lib.LANLI_FLAG_LEVELS_STRICT,
}

local document = { flags = flags }
document.__index = document

function document.new(callback, flags, levels, max_nesting, max_attributes)
    local t = type(flags)
    local f = 0
    if t == "number" then
        f = flags
    elseif t == "table" then
        for _, v in ipairs(flags) do
            if type(v) == "number" then
                f = bor(v, f)
            else
                f = bor(flags[v] or 0, f)
            end
        end
    end
    return setmetatable({ context = ffi_gc(lib.lanli_document_new(callback or lib.lanli_callback_strict_post, nil, f, levels or 0, max_nesting or 16, max_attributes or 8), lib.lanli_document_free) }, document)
end
function document:render(data)
    local str = tostring(data)
    local len = #str
    local buf = new_buf(len);
    lib.lanli_document_render(self.context, buf.context, str, len)
    return tostring(buf)
end
function document:free()
    lib.lanli_document_free(self.context)
end

return document
