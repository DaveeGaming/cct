---@diagnostic disable: undefined-global
local tunnelLenght = 50

for i = 1, tunnelLenght do
	turtle.digUp()
	turtle.digDown()
	turtle.dig()
	turtle.forward()
end