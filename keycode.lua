---@diagnostic disable: undefined-global, undefined-field

-- Setup
local monitor = peripheral.find("monitor")
local w, h = monitor.getSize()

term.redirect(monitor)
monitor.setTextColor(colors.black)
monitor.setTextScale(0.5)

local buttons = {}
local pressed = false
local password = "2113"
local currText = ""

function newButton(x, y, w, h, text)
	local b = {}

	b.m = monitor
	b.x = x
	b.y = y
	b.w = w
	b.h = h
	b.text = text

	function b.draw(color)
		color = color or colors.white
		paintutils.drawFilledBox(b.x, b.y, b.x + b.w, b.y + b.h, color)
		monitor.setCursorPos(b.x + 1, b.y + 1)
		monitor.write(text)
	end

	function b.clicked(x, y)
		if x >= b.x and y >= b.y and x <= b.x + b.w and y <= b.y + b.h then
			b.draw(colors.gray)
			currText = currText .. text
			os.sleep(0.1)
			b.draw()
		end
	end

	return b
end

function newSideBar()
	local s = {}

	s.x = 14
	s.y = 2
	s.w = 0
	s.h = 7

	function s.draw(color)
		color = color or colors.red
		paintutils.drawFilledBox(s.x, s.y, s.x + s.w, s.y + s.h, color)
	end

	function s.blink()
		for i = 1, 2 do
			paintutils.drawFilledBox(s.x, s.y, s.x + s.w, s.y + s.h, colors.green)
			os.sleep(0.1)
			paintutils.drawFilledBox(s.x, s.y, s.x + s.w, s.y + s.h, colors.red)
			os.sleep(0.1)
		end
	end

	return s
end
local sidebar = newSideBar()

function Init()
	local number = 1

	for y = 2, 10, 3 do
		for x = 2, 10, 4 do
			table.insert(buttons, newButton(x, y, 2, 1, tostring(number)))
			number = number + 1
		end
	end
	monitor.setBackgroundColor(colors.black)
	monitor.clear()
end

function Draw()
	monitor.setBackgroundColor(colors.black)
	monitor.clear()
	for key, value in pairs(buttons) do
		value.draw()
	end

	sidebar.draw()
end

function Update()
	local event, side, x, y = os.pullEvent("monitor_touch")
	for key, value in pairs(buttons) do
		value.clicked(x, y)
	end

	if #currText == 4 then
		if currText == password then
			sidebar.draw(colors.green)
			redstone.setOutput("right", true)
			os.sleep(3)
			redstone.setOutput("right", false)
		else
			sidebar.blink()
		end

		currText = ""
	end
end

Init()
while true do
	Draw()
	Update()
end
