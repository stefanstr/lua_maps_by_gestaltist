require ("mapgeneration")

function love.load ()
	maps.initialize()
	love.graphics.setBackgroundColor(0, 255, 0)
	wx, wy = love.window.getDimensions()
	tile = 10
	border = 1
	tx = wx/tile - 2 * border
	ty = wy/tile - 2 * border
	iter = 5
	percentage_walls = 45
	rules = {}
	rules.neighborhood = 1
	rules.include_self = true
	rules.frame = "start"
	rules[0] = "floor"
	rules[1] = "floor"
	rules[2] = "stay"
	rules[3] = "wall"
	rules[4] = "wall"
	rules[5] = "wall"
	
	map = maps.generate.cellular (tx, ty, iter, percentage_walls, rules)
end

function love.keypressed (key)
	if key == "r" then
		map = maps.generate.cellular (tx, ty, 1, percentage_walls, {})
	elseif key == "t" then
		map = maps.generate.cellular  (tx, ty, 1, percentage_walls, rules)
	elseif key == "i" then
		map = maps.process.invert (map)
	elseif key == "j" then
		iter = math.random(1, 20)
		map = maps.generate.cellular (tx, ty, iter, percentage_walls, rules)
	elseif key == "up" then
		percentage_walls = percentage_walls + 1
		map = maps.generate.cellular (tx, ty, iter, percentage_walls, rules)
	elseif key == "down" then
		percentage_walls = percentage_walls - 1		
		map = maps.generate.cellular (tx, ty, iter, percentage_walls, rules)
	elseif key == "z" then
		map = maps.process.removeDisconnected (map)
	elseif key == "x" then
		map = maps.process.removeDisconnected (map, 1)
	elseif key == "p" then
		map = maps.generate.prim(tx, ty)
	elseif key == "v" then
		local rls = {}
		rls.include_self = true
		rls[1] = "floor"
		rls[2] = "floor"
		rls[8] = "wall"
		rls[7] = "wall"
		rls[4] = "flip"

		map = maps.process.cellular(map, tx, ty, iter, rls)
	end
end

function love.draw ()
	for w=1, tx do
		for h=1, ty do
			if map[w][h] then
				love.graphics.setColor(0, 0, 0)
			else
				love.graphics.setColor(255, 255, 255)
			end
			love.graphics.rectangle("fill", (w-1 + border) * tile, (h-1 + border) * tile, tile, tile)
		end
	end
end


