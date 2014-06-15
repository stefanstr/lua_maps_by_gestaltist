#!/usr/local/bin/lua
----------------------------------------
-- TILED 2D MAP GENERATION ALGORITHMS --
-- by gestaltist -----------------------
----------------------------------------

-- License: do whatever you want with this code. No warranty given. --

maps = {}

function maps.initialize (seed)
	seed = seed or os.time()
	math.randomseed(seed)
end

maps.process = {} -- collects functions used to reprocess a given map according to certain rules
maps.generate = {} -- contains convenience functions processing on empty maps (i.e., creating new ones)
maps.tools = {} -- contains helper functions like identifying rooms

-- CELLULAR AUTOMATA --
function maps.generate.cellular (width, height,iterations, initial_percent_of_walls, rules)
		local map = {}
		for w=1, width do 
			map[w] = {}
		for h=1, height do
			map[w][h] = (math.random(100) < initial_percent_of_walls) -- initializing with random walls
		end
	end
	return maps.process.cellular(map, width, height,iterations, rules)
end

function maps.process.cellular (map, width, height,iterations, rules)
	-- initializing 2 maps to use for iterations
	-- this function only works with 2 types of values for individual cells: 
		-- false means no wall
		-- true means wall
	-- rules is a map with any of the following rules as keys and numbers
		-- allowed keys for the rules table are:
		--"include_self" = whether the cell itself should be counted as part of the neighborhood. Default is false. 
		--[numeric key] = state (number of neighboring walls is the key, its value (state) says what should happen)
			-- possible states are:
				-- "flip", i.e., change wall to no wall and vice versa
				--	"stay", i.e., no action
				-- "floor", i.e., change to floor
				-- "wall", i.e., change to wall
		-- "frame" - will put a wall on the outermost cells of the map after all transformations
			-- "start" - before transformations
			-- "end" - after transformations
			-- "both" - both
		--"neighborhood" = 1  (von neumann) or 2 (von neumann extended) - otherwise, moore neighborhood is used
			-- = 20 = Moore calculated separately for one away and two away
			-- = 21 = Von Neumann calculated separately for one away and two away
			-- with these two neighborhoods values or rules are tables that store the behavior for
			-- one tile away and two tiles away, e.g., rules[1] = {"wall", "stay"}
			-- include_self is ignored for this kind of rules
			
	-- fullproofing the map against out of range queries (makes neighborhood calculations easier) --
	local _mtrow = {__index = function () return false end}
	local _mt = {__index = function () return setmetatable({}, _mtrow) end}
	local map = setmetatable(map, _mt)
	local map2 = setmetatable({}, _mt) -- needed as a temporary map during the iterations

	-- initializing temporary map
	for w=1, width do 
		map2[w] = {}
		for h=1, height do
			map2[w][h] = false 
		end
	end
	
	if rules.frame == "start" or rules.frame == "both" then -- add walls to the edges of the map
		for x=1, width do
			map[x][1] = true
			map[x][height] = true
		end
		for y=2, height-1 do
			map[1][y] = true
			map[width][y] = true
		end
	end

	local rn = rules.neighborhood
	for n=1, iterations do -- main loop
		for w=1, width do
			for h=1, height do
				if (rn == 20) or (rn == 21) then -- two-tier neighborhood
					-- calculate the number of neighbors --
					local neighbors = {}
					neighbors[1] = 0 -- 1 tile away
					neighbors[2] = 0 -- 2 tiles away
					if rn == 21 then -- von neumann neighborhood
						for n=(-2), 2 do
							if (n ~= 0) then
								if math.abs(n) == 1 then
									if map[w+n][h] then neighbors[1] = neighbors[1] + 1 end
									if map[w][h+n] then neighbors[1] = neighbors[1] + 1 end	
								elseif math.abs(n) == 2 then
									if map[w+n][h] then neighbors[2] = neighbors[2] + 1 end
									if map[w][h+n] then neighbors[2] = neighbors[2] + 1 end	
								end		
							end
						end	
					else -- Moore neighborhood 
						for nx=(-2), 2 do
							for ny=(-2), 2 do
								if (nx ~= 0) or (ny ~= 0) then
									if math.abs(nx) == 2 or math.abs(ny) == 2 then
										if map[w+nx][h+ny] then neighbors[2] = neighbors[2] + 1 end
									else
										if map[w+nx][h+ny] then neighbors[1] = neighbors[1] + 1 end
									end
								end
							end
						end
					end
					-- make sure all rules exist for the next loop --
					for i=0, 24 do
						if not rules[i] then
							rules[i] = {"stay", "stay"}
						end
					end
					-- take action based on the number of neighbors and store the results in the temporary map --
					for i=1, 2 do
						if rules[neighbors[i]][i] == "flip" then
							map2[w][h] = not map[w][h]
						elseif rules[neighbors[i]][i] == "floor" then
							map2[w][h] = false
						elseif rules[neighbors[i]][i] == "wall" then
							map2[w][h] = true
						else
							map2[w][h] = map[w][h]
						end
					end
				else
					-- calculate the number of neighbors --
					local neighbors = 0 
					if rn then -- von neumann neighborhood
						for n=(-rn), rn do
							if (n ~= 0) then
								if map[w+n][h] then neighbors = neighbors + 1 end
								if map[w][h+n] then neighbors = neighbors + 1 end	
							elseif rules.include_self then
								if map[w][h] then neighbors = neighbors + 1 end
							end		
						end	
					else -- Moore neighborhood used as default
						for nx=(-1), 1 do
							for ny=(-1), 1 do
								if (nx ~= 0) or (ny ~= 0) then
									if map[w+nx][h+ny] then neighbors = neighbors + 1 end
								elseif rules.include_self then
									if map[w][h] then neighbors = neighbors + 1 end
								end
							end
						end
					end
					-- take action based on the number of neighbors and store the results in the temporary map --
					if rules[neighbors] == "flip" then
						map2[w][h] = not map[w][h]
					elseif rules[neighbors] == "floor" then
						map2[w][h] = false
					elseif rules[neighbors] == "wall" then
						map2[w][h] = true
					else
						map2[w][h] = map[w][h]
					end
				end
			end
		end
		map, map2 = map2, map -- swap maps so the actual map stores the results of the iteration. map2 will be overwritten anyway
	end
	
	if rules.frame == "end" or rules.frame == "both" then -- add walls to the edges of the map
		for x=1, width do
			map[x][1] = true
			map[x][height] = true
		end
		for y=2, height-1 do
			map[1][y] = true
			map[width][y] = true
		end
	end
	
	return setmetatable(map, {}) -- removing the metatable _mt
end
-------------------

-- REMOVING DISCONNECTED ROOMS --

-- helper function for identifying the room a cell is in
function maps.tools.getRoom (map, x, y, _checked)

	local function needs_checking (x, y, checked)
		if (x < 1) or (x > #map) or (y < 1) or (y > #map[1]) -- out of bounds
			or checked[x][y] or map[x][y] then -- has been checked or is a wall
			return false
		else
			return true
		end
	end
	
	local function merge_rooms (room1, room2)
		for k,v in pairs(room2) do table.insert(room1, v) end
	end
	
	local room = {{["x"]=x; ["y"]=y}}
	local checked = _checked or {}
	if #checked == 0 then
		for x=1, #map do 
			checked[x] = {}
			for y=1, #map[1] do
				checked[x][y] = false
			end
		end
	end
	checked[x][y] = true
	
	if needs_checking(x-1, y, checked) then
		merge_rooms(room, maps.tools.getRoom(map, x-1, y, checked))
	end
	if needs_checking(x+1, y, checked) then
		merge_rooms(room, maps.tools.getRoom(map, x+1, y, checked))
	end
	if needs_checking(x, y-1, checked) then
		merge_rooms(room, maps.tools.getRoom(map, x, y-1, checked))
	end
	if needs_checking(x, y+1, checked) then
		merge_rooms(room, maps.tools.getRoom(map, x, y+1, checked))
	end
	
	return room
end


-- this function identifies rooms that have no connection to the rest of the map and removes them
-- (i.e., it removes all rooms besides the biggest one)
-- unless "how_many" is given - in which case only so many smallest rooms will be removed
function maps.process.removeDisconnected (map, how_many) 
	local width = #map
	local height = #map[1]
	local rooms = {} -- this will contain all found rooms
	local to_check = {} -- this will contain coords of all cells, see below:
	for w=1, width do
		to_check[w] = {}
		for h=1, height do
			to_check[w][h] = true
		end
	end
	
	-- assign cells to rooms
	for w=1, width do
		for h=1, height do
			if to_check[w][h] then
				if map[w][h] then -- the cell is a wall
					to_check[w][h] = false
				else -- the cell is a floor
					-- get the room that cell is in --
					local room = maps.tools.getRoom(map, w, h)
					-- add it to the list of rooms --
					table.insert(rooms, room)
					-- remove all the cells in the room from the check
					for _, v in pairs(room) do
						to_check[v.x][v.y] = false
					end
				end				
			end
		end
	end
	-- sort rooms to find the biggest ones
	table.sort(rooms, function (r1, r2) return #r1 > #r2 end)
	
	-- creating the map to be returned as a result
	map2 = {}
	for w=1, width do 
		map2[w] = {}
		for h=1, height do
			map2[w][h] = map[w][h] -- copying the input map
		end
	end
	
	-- removing all rooms besides the biggest one
	if #rooms > 1 then
		local stop = (how_many and #rooms-how_many+1) or 2
		for r=#rooms, stop, -1 do
			for _, v in pairs(rooms[r]) do
				map2[v.x][v.y] = true
			end
		end
	end	
	return map2
end
-------------------

-- INVERT WALLS AND FLOOR --

function maps.process.invert (map)
	map2 = {}
	for w=1, #map do 
		map2[w] = {}
		for h=1, #map[1] do
			map2[w][h] = not map[w][h] 
		end
	end
	return map2
end
-------------------

-- MAZE VIA A MODIFIED PRIM'S ALGORITHM --
--http://en.wikipedia.org/wiki/Prim%27s_algorithm

function maps.generate.prim (width, height, no_frame) 
-- if no_frame is true, the algorithm will not leave a wall around the maze
-- no_frame only has an effect on mazes with an even number of rows or columns
	-- initialize the map with all walls --
	local map = {}
	local in_the_maze = {} -- temporary map with additional info
	for w=1, width do
		map[w] = {}
		in_the_maze[w] = {}
		for h=1, height do
			map[w][h] = true
			in_the_maze[w][h] = false
		end
	end
	
	
	local walls = {} -- the wall list
	
	-- helper function 
	local function add_walls (rx, ry) -- add walls around a given cell to the list
	-- I am saving the coordinates to the wall but also to the "cell on the opposite
	-- side", which is crucial for this algorithm.
		if (rx > 1) and not in_the_maze[rx-1][ry] and map[rx-1][ry] then
			table.insert(walls, {x=rx-1, y=ry, op_x=rx-2, op_y=ry})
		end
		if (rx < width) and not in_the_maze[rx+1][ry] and map[rx+1][ry] then
			table.insert(walls, {x=rx+1, y=ry, op_x=rx+2, op_y=ry})
		end
		if (ry > 1) and not in_the_maze[rx][ry-1] and map[rx][ry-1] then
			table.insert(walls, {x=rx, y=ry-1, op_x=rx, op_y=ry-2})
		end
		if (ry < height) and not in_the_maze[rx][ry+1] and map[rx][ry+1] then
			table.insert(walls, {x=rx, y=ry+1, op_x=rx, op_y=ry+2})
		end
	end
	
	if not no_frame then
		width = width - 1
		height = height - 1
	end
	
	-- start of the algorithm --
	-- pick a cell at random --
	local rx = math.random(1, math.floor(width/2)) * 2
	local ry = math.random(1, math.floor(height/2)) * 2
	-- mark it as part of the maze --
	in_the_maze[rx][ry] = true
	map[rx][ry] = false
	-- add the walls of the cell to the wall list --
	add_walls(rx, ry)
	
	-- while there are walls in the list --
	while #walls > 0 do
		-- pick a random wall from the list
		local current_wall = math.random(#walls)
		local cw = walls[current_wall]
		
		-- is the cell on the opposite side in the maze or out of bounds?
		if (cw.op_x < 1) or (cw.op_x > width) or (cw.op_y < 1) or (cw.op_y > height)
											or in_the_maze[cw.op_x][cw.op_y] then
			-- then remove the wall from the list --
			table.remove(walls, current_wall)
		else
			-- make the wall a passage --
			map[cw.x][cw.y] = false
			in_the_maze[cw.x][cw.y] = true
			
			-- add cell on the opposite side to the maze --
			map[cw.op_x][cw.op_y] = false
			in_the_maze[cw.op_x][cw.op_y] = true
			-- add walls  to the list --			
			add_walls(cw.op_x, cw.op_y)
		end
	end
	return map
end

-- TEST 

if arg[0] == 'mapgeneration.lua' then
	rules = {}
	rules.neighborhood = 20 -- two-tiered Moore
	maxi = {"wall", "stay"}
	mini = {"stay", "floor"}
	for i=5, 12 do
		rules[i] = maxi
	end
	rules[2] = mini
	rules[1] = mini
	rules[0] = mini
	
	map = maps.generate.cellular(24,24, 5, 45, rules)
	map = maps.process.removeDisconnected(map)
	for _,v in pairs(map) do
		io.write("\n")
		for _, z in pairs(v) do
			if z then io.write("#") 
			else io.write(" ") end
		end
	end
end