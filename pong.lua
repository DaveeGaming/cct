---@diagnostic disable: undefined-global

local width, height = term.getSize()

local paddleheight = 4

local paddle1 = {
    x = 1,
    y = height / 2 - paddlesize / 2,
}

local paddle2 = {
    x = width - 1,
    y = height / 2 - paddlesize / 2,
}

local bullet = {
    x = width/2,
    y = height/2,
    velocx = 0,
    velocy = 0,
}


function Draw()
    paintutils.drawFilledBox(paddle1.x,paddle1.y,paddle1.x, paddleheight)
    paintutils.drawFilledBox(paddle2.x,paddle2.y,paddle2.x, paddleheight)
end

function Update()



end



while true do
    Draw()
    Update()
end



