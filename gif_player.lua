---@class Header
---@field Signature string
---@field Version string

---@alias ColorTable {r: number, g: number, b: number}[]

---@class LogicalScreenDescriptor
---@field ScreenWidth number
---@field ScreenHeight number
---@field GCTFlag boolean
---@field ColorResolution number
---@field SortFlag number
---@field GCTSize number
---@field BGColorIndex number
---@field PixelAspectRatio number

---@class ImageDescriptor
---@field ImageLeft number
---@field ImageTop number
---@field ImageWidth number
---@field ImageHeight number
---@field LCTFlag boolean
---@field InterlaceFlag number
---@field SortFlag number
---@field LCTSize number

---@class Extension.Comment
---@field Type "Comment"
---@field Data table

---@class Extension.Application
---@field Type "Application"
---@field Identifier string
---@field AuthenticationCode number
---@field Data table

---@class Extension.PlainText
---@field Type "Plaintext"
---@field TextGridLeft number
---@field TextGridTop number
---@field TextGridWidth number
---@field TextGridHeight number
---@field CharacterCellWidth number
---@field CharacterCellHeight number
---@field TextFGColorIndex number
---@field TextBGColorIndex number
---@field Data table

---@class Extension.GraphicsControl
---@field Type "GCE"
---@field DisposalMethod number
---@field UserInputFlag number
---@field TransparentColorFlag boolean
---@field TransparentColorIndex number
---@field DelayTime number

local LABELS = {
    ExtensionIntroducer = 33,
    ApplicationExtension = 255,
    CommentExtension = 254,
    GraphicControlExtension = 249,
    ImageDescriptor = 44,
    PlainTextExtension = 1,
    Trailer = 59,
}



local monitor = peripheral.find("monitor")

if monitor == nil then
    error("No monitor attached")
end

monitor.setTextScale(0.5)
monitor.clear()

local pixelbox = require("bixelbox_lite")
local box      = pixelbox.new(monitor)


---@param n number
---@return table
local function byte2bin(n)
    local t = {}
    for i=7,0,-1 do
        t[#t+1] = math.floor(n / 2^i)
        n = n % 2^i
    end
    return t
end

local function bitlist2num(table, start, len, endian)
    local num = 0
    local endian = endian or "little"
    if endian == "little" then
        for i = 1, len do
            if table[start + len - 1] == nil then return num, "a" end
            num = num + table[start + len - i] * 2^(i - 1)
        end
    elseif endian == "big" then
        for i = 0, len - 1 do
            if table[start + i] == nil then return num, "a" end
            num = num + table[start + i] * 2^(i)
        end
    end

    return num
end

---@param file ccTweaked.fs.BinaryReadHandle 
---@return number
local function read_unsigned(file)
    return file.read() + file.read()
end

---@param file ccTweaked.fs.BinaryReadHandle 
---@return table
local function read_subblock(file)
    local data = {}
    while true do
        local bytes = file.read()
        if bytes > 0 then
            for i = 1, bytes do
                table.insert(data, file.read())
            end
        else break end
    end

    return data
end


---@param file ccTweaked.fs.BinaryReadHandle 
local function read_extension(file)
    local LABEL = file.read()

    local ext = {}
    if LABEL == LABELS.ApplicationExtension then
        local block_size = file.read()

        ---@type Extension.Application
        ext = {
            Type = "Application",
            Identifier = file.read(8) --[[@as string]],
            AuthenticationCode = file.read() + file.read() + file.read(),
            Data = read_subblock(file),
        }
    elseif LABEL == LABELS.CommentExtension then
        ---@type Extension.Comment
        ext = {
            Type ="Comment",
            Data = read_subblock(file)
        }
    elseif LABEL == LABELS.GraphicControlExtension then
        local block_size = file.read()
        local packed_field = byte2bin(file.read())

        ---@type Extension.GraphicsControl
        ext = {
            Type = "GCE",
            DisposalMethod = 1,
            UserInputFlag = 1,
            TransparentColorFlag = false,
            DelayTime = read_unsigned(file),
            TransparentColorIndex = file.read()
        }

        file.read()
    elseif LABEL == LABELS.PlainTextExtension then
        local block_size = file.read()

        ---@type Extension.PlainText
        ext = {
            Type = "Plaintext",
            TextGridLeft = read_unsigned(file),
            TextGridTop = read_unsigned(file),
            TextGridWidth = read_unsigned(file),
            TextGridHeight = read_unsigned(file),
            CharacterCellWidth = file.read(),
            CharacterCellHeight = file.read(),
            TextFGColorIndex = file.read(),
            TextBGColorIndex = file.read(),
            Data = read_subblock(file)
        }
    else
        error("Unknown image extension label: " .. LABEL)
    end

    print("Got extension with type: ["..ext.Type.."]")
    return ext
end

---@param file ccTweaked.fs.BinaryReadHandle 
---@return Header
local function read_header(file)
    return {
        Signature = file.read(3),
        Version = file.read(3)
    }
end

---@param file ccTweaked.fs.BinaryReadHandle 
---@return LogicalScreenDescriptor
local function read_logical_screen_desc(file)
    local w = read_unsigned(file)
    local h = read_unsigned(file)
    local packed_field = byte2bin(file.read())

    ---@type LogicalScreenDescriptor
    local desc = {
        ScreenWidth = w,
        ScreenHeight = h,
        GCTFlag = packed_field[1] ~= 0,
        ColorResolution = bitlist2num(packed_field, 2, 3),
        SortFlag = packed_field[5],
        GCTSize = bitlist2num(packed_field, 6, 3),
        BGColorIndex = file.read(),
        PixelAspectRatio = file.read()
    }
    return desc
end


---@param file ccTweaked.fs.BinaryReadHandle 
---@return ImageDescriptor
local function read_image_descriptor(file)
    ---@type ImageDescriptor
    local image_desc = {
        ImageLeft = read_unsigned(file),
        ImageTop = read_unsigned(file),
        ImageWidth = read_unsigned(file),
        ImageHeight = read_unsigned(file),
    }

    local packed = byte2bin(file.read())

    image_desc.LCTFlag = packed[1] ~= 0
    image_desc.InterlaceFlag = packed[2]
    image_desc.SortFlag = packed[3]
    image_desc.LCTSize = bitlist2num(packed, 6, 3)

    return image_desc
end


local default_colors = {}

for i = 0, 15 do
    table.insert(default_colors, {term.nativePaletteColor(2^i)})
    monitor.setPaletteColor(2^i, term.nativePaletteColor(2^i))
end

local function get_closest_color(r, g, b)
    local closest = 1
    local closest_dist = 10000000000000
    for k, c in ipairs(default_colors) do
        local distance = math.sqrt(math.pow(c[1] - r,2) + math.pow(c[2] - g,2) + math.pow(c[3] - b,2))
        if distance < closest_dist then
            closest_dist = distance
            closest = k
        end
    end

    return closest
end


---@param file ccTweaked.fs.BinaryReadHandle 
---@return ColorTable
local function read_color_table(file, count)
    local tb = {}
    local full_size = 2^(count + 1)
    for i = 1, full_size do
        local r = file.read() / 255
        local g = file.read() / 255
        local b = file.read() / 255
        local color = get_closest_color(r, g, b)
        -- local color = colors.packRGB(r, g, b)
        -- monitor.setPaletteColor(math.floor(2^i), color)
        table.insert(tb, math.floor(color - 1))
    end
    return tb
end


local function deepcopy(obj, seen)
    -- Handle non-tables and previously-seen tables.
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
  
    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[obj] = res
    for k, v in pairs(obj) do res[deepcopy(k, s)] = deepcopy(v, s) end
    return setmetatable(res, getmetatable(obj))
end

---@param file ccTweaked.fs.BinaryReadHandle
---@param gct ColorTable
---@param lsd LogicalScreenDescriptor
---@param graphic_conmtrol Extension.GraphicsControl
local function read_image(file, gct, lsd, graphic_conmtrol)
    print("Got image!")
    local image_desc = read_image_descriptor(file)
    local LCT = {}
    if image_desc.LCTFlag then
    LCT = read_color_table(file, image_desc.LCTSize)
    end

    local LZW_min_size = file.read()
    local image_bytes = read_subblock(file)

    local image_bits = {}

    for i = 1, #image_bytes, 1 do
        local bits = byte2bin(image_bytes[i])
        for j = #bits, 1, -1 do
            table.insert(image_bits, bits[j])
        end
    end

    -- Decode to LZW input stream
    local CODE_TABLE = {}
    for i = 0, #gct - 1, 1 do
        CODE_TABLE[i] = { gct[i + 1] }
    end
    CODE_TABLE[(2 ^ (lsd.GCTSize + 1))] = "clear"
    CODE_TABLE[(2 ^ (lsd.GCTSize + 1)) + 1] = "end"
   
    -- for k, v in pairs(CODE_TABLE) do print(k, v[1]) end

    local color_stream = {}
    local b_size = LZW_min_size + 1

    local idx = 1 + b_size -- First bit is always clear

    local num = bitlist2num(image_bits, idx, b_size, "big")
    local last_num = num
    table.insert(color_stream, table.unpack(CODE_TABLE[num]))
    idx = idx + b_size
    while true do

        if #CODE_TABLE == 2 ^ b_size - 1 then
            b_size = b_size + 1
        end

        local num = bitlist2num(image_bits, idx, b_size, "big")
        -- write("read " .. num .. " ")
        idx = idx + b_size

        if CODE_TABLE[num] and CODE_TABLE[num] == "clear" then
            break
        end

        if CODE_TABLE[num] and CODE_TABLE[num] == "end" then
            break
        end

        if CODE_TABLE[num] then
            for key, value in pairs(CODE_TABLE[num]) do
                table.insert(color_stream, value)
            end

            local base = deepcopy(CODE_TABLE[last_num])
            local K = deepcopy(CODE_TABLE[num][1])
            table.insert(base, K)
            table.insert(CODE_TABLE, base)
        else
            local base = deepcopy(CODE_TABLE[last_num])
            local K = deepcopy(base[1])
            table.insert(base, K)
            table.insert(CODE_TABLE, base)
            for key, value in pairs(base) do
                table.insert(color_stream, value)
            end
        end
        last_num = num
    end

    local bare_canvas   = pixelbox.make_canvas()
    local usable_canvas = pixelbox.setup_canvas(box,bare_canvas,colors.black)

    

    for y = 1, math.floor(image_desc.ImageHeight) do
        for x = 1, math.floor(image_desc.ImageWidth) do
            -- write(color_stream[x] .. " ")
            -- monitor.setCursorPos(x + 1, y)
            
            local color = color_stream[x + (y - 1) * image_desc.ImageWidth]

            if graphic_conmtrol and graphic_conmtrol.TransparentColorFlag then
                if graphic_conmtrol.TransparentColorIndex == color then
                    goto continue
                end
            end

            usable_canvas[y + 1 + image_desc.ImageTop][x + 1 + image_desc.ImageLeft] = 2^(color)
            ::continue::
        end
    end

    return image_desc, usable_canvas
end


local file = fs.open("sample_3.gif", "rb")

if file == nil then
    error("File is not found")
end

local header = read_header(file)
local lsd = read_logical_screen_desc(file)
local GCT = {}
print(header.Signature .. header.Version, lsd.ScreenWidth .. "x".. lsd.ScreenHeight)
if lsd.GCTFlag then
    GCT = read_color_table(file, lsd.GCTSize)
end

---@class Image
---@field GCE Extension.GraphicsControl
---@field Descriptor ImageDescriptor
---@field Canvas table



local images = {}

---@type Image
local image = {}

while true do
    local byte = file.read()


    if byte == LABELS.ExtensionIntroducer then
        local ext = read_extension(file)

        if ext.Type == "GCE" then
            image.GCE = ext
        end
    end

    if byte == LABELS.ImageDescriptor then
        image.Descriptor, image.Canvas = read_image(file, GCT, lsd, graphic_conmtrol)
        table.insert(images, image)
        image = {}
    end
    
    if byte == LABELS.Trailer then
        print("Correctly reached EOF")
        break
    end

end

for i = 1, #images, 1 do
    ---@type Image
    local image = images[i]
    for k, v in pairs(image) do print(k, v) end

    if i ~= 1 then
        if image.GCE and image.GCE.DisposalMethod == 1 then
            for x = 1, lsd.ScreenWidth, 1 do
                for y = 1, lsd.ScreenHeight, 1 do
                    if image.Canvas[x][y] == 32768 then
                        local prev_img = images[i - 1]
                        image.Canvas[x][y] = prev_img.Canvas[x][y]
                    end
                end
            end
        end
    end
end


local idx = 0
while true do
    box:set_canvas(images[idx + 1].Canvas)
    box:render()
    idx = idx + 1
    idx = idx % #images
    sleep(1)
end