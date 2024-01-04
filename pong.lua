
local width, height = term.getSize()

local paddleheight = 6

local paddle1 = {
    x = 1,
    y = height / 2 - paddleheight / 2,
}

local paddle2 = {
    x = width - 1,
    y = height / 2 - paddleheight / 2,
}

local bullet = {
    x = width/2,
    y = height/2,
    velocx = 0,
    velocy = 0,
}


function Draw()
    paintutils.drawFilledBox(paddle1.x,paddle1.y,paddle1.x, paddleheight, colors.white)
    paintutils.drawFilledBox(paddle2.x,paddle2.y,paddle2.x, paddleheight, colors.white)
end

function Update()
    local event, key, is_held = os.pullEvent("key")
    if key == keys.w then
        paddle1.x = paddle1.x + 1
    elseif key == keys.s then
        paddle1.x = paddle1.x - 1
    end


    if key == keys.up then
        paddle1.x = paddle1.x + 1
    elseif key == keys.down then
        paddle1.x = paddle1.x - 1
    end

end



while true do
    Draw()
    Update()
end



