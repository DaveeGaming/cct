---@class Extension.Comment
---@field Type "Comment"
---@field Data table

---@class Extension.Application
---@field Type "Application"
---@field Identifier number
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
---@field TransparentColorFlag number
---@field TransparentColorIndex number
---@field DelayTime number

local LABELS = {
    ApplicationExtension = 255,
    CommentExtension = 254,
    GraphicControlExtension = 249,
    ImageDescriptor = 44,
    PlainTextExtension = 1,
    Trailer = 59,
}

local function read_extension(file)
    local LABEL = file.read()

    local ext = {}
    if LABEL == LABELS.ApplicationExtension then
        ---@type Extension.Application
        ext = {}
        ext.Type = "Application"
    elseif LABEL == LABELS.CommentExtension then
        ---@type Extension.Comment
        ext = {}
        ext.Type ="Comment"
    elseif LABEL == LABELS.GraphicControlExtension then
        ---@type Extension.GraphicsControl
        ext = {}
        ext.Type = "GCE"
        local block_size = file.read()
        local packed_field = file.read()

        ext.DelayTime = file.read(2)
        ext.TransparentColorIndex = file.read()
    elseif LABEL == LABELS.PlainTextExtension then
        ---@type Extension.PlainText
        ext = {}
        ext.Type = "Plaintext"
    else
        error("Unknown image extension label: " + LABEL)
    end

    return ext
end
