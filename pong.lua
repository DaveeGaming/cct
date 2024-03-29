
local width, height = term.getSize()

local paddleheight = 6

local paddle1 = {
    x = 2,
    y = height / 2 - paddleheight / 2,
    points = 0
}

local paddle2 = {
    x = width - 1,
    y = height / 2 - paddleheight / 2,
    points = 0
}

local bullet = {
    x = width/2,
    y = height/2,
    velocx = 1,
    velocy = 1,
}


function Draw()
    term.clear()
    term.setBackgroundColor(colors.white)
    paintutils.drawFilledBox(paddle1.x,paddle1.y,paddle1.x, paddle1.y + paddleheight)
    paintutils.drawFilledBox(paddle2.x,paddle2.y,paddle2.x, paddle2.y + paddleheight)
    paintutils.drawFilledBox(bullet.x, bullet.y, bullet.x, bullet.y)
    term.setBackgroundColor(colors.black)
    term.setCursorPos(width/2-5,2)
    term.write(paddle1.points .. "  " .. paddle2.points)

end

function Input()
    os.startTimer(0.2)
    local event, key, is_held = os.pullEvent("key")
    if event == "timer" then
           -- nothin
    elseif event == "key" then
         if key == keys.w then
            paddle1.y = paddle1.y - 1
        elseif key == keys.s then
            paddle1.y = paddle1.y + 1
        end
    
        if key == keys.up then
            paddle2.y = paddle2.y - 1
        elseif key == keys.down then
            paddle2.y = paddle2.y + 1
        end
    end
end

function Update()

    if bullet.y <= 1 or bullet.y >= height - 1 then bullet.velocy = bullet.velocy * -1 end

    if bullet.x == paddle1.x then 
       bullet.velocx = bullet.velocx * -1 
    elseif bullet.x == paddle2.x then 
       bullet.velocx = bullet.velocx * -1 
    elseif bullet.x < 0 then
        paddle2.points = paddle2.points + 1
    elseif bullet.x > width then
        paddle1.points = paddle1.points + 1
    end

    bullet.x = bullet.x + bullet.velocx
    bullet.y = bullet.y + bullet.velocy
end



while true do
    Draw()
    Input()
    Update()
end



