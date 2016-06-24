T=Turtle

-- position manager
pm = {}
pm.waypoints = {}
pm.timeout = 5

--inventory manager
im = {}

-- directional constants
STAY=0
UP=1
DOWN=2
NORTH=3
SOUTH=4
EAST=5
WEST=6	
LEFT=7		--turning only
RIGHT=8		--turning only
AROUND=9	--turning only
FORWARD=10	
BACKWARD=11

-- action constants
TURN = 100
MOVE = 200
PLACE = 300
DIG = 400


--control constants
ERR = -1
OKAY= -2
FAIL= -3
FUEL= -4


VEC_ZERO = vector.new(0,0,0)

--updates orientation an position based on gps
function orient()
	pm.facing=NORTH
	start = vector.new(gps.locate(5))
	-- TODO what if no connection
	
	--this loop figures out some way to move forward
	turns = 0
	no_exit_up = false
	while not T.forward() do
		if turns >= 4 then
			if not T.up() or no_exit_up then
				no_exit_up = true
				if not T.Down() then
					--trapped
					pm.trapped = true
					--TODO throw error or something
				end
			end 
			turns=0
		else
			T.turnLeft()
			turns=turns+1
		end
	end

	--this code figures out direction from gps
	pm.current = vector.new(gps.locate(pm.timeout))
	if pm.current.x > temp.x then
		pm.facing = EAST
	elseif pm.current.x < temp.x then
		pm.facing = WEST
	elseif pm.current.z > temp.z then
		pm.facing = SOUTH
	elseif pm.current.z < temp.z then
		pm.facing = NORTH
	end
end

--updates position based on gps, returns error
function locate()
	temp = vector,new(gps.locate(pm.timeout))
	err = vector.new(pm.current.x - temp.x,
					pm.current.y - temp.y,
					pm.current.z - temp.z)

	pm.current = temp
	return err
end 


function serial(chain)
	for command in chain do 
		dir = math.fmod(command, 100)
		action = math.fmod(command - dir, 1000)
		count = command - action - dir

		for i=1,count do 
			if action == TURN then
				pm.turn(dir)
			elseif action == MOVE then
				pm.move(dir)
			elseif action == PLACE then
				--TODO
			elseif action == DIG then
				--TODO
			else
				--what are they even trying to do.
				return ERR
			end
		end 
	end
end

function loader(text)
	--parses text instructions to serial
	command = parts(split(text, ","))
	serial = {}
	functions 
	for index, block in ipairs(command) do
		if string.len(block) < 2 then
			return ERR
		end 

		action = string.sub(block, 1, 1)
		dir = string.sub(block, 2, 2)
		if string.len(block > 2) then
			count = tonumber(string.sub(block, 3))  --TODO handle potencial error
		else
			count = 1
		end

		if action == "M" then
			serial[index] = MOVE
		elseif action == "T" then
			serial[index] = TURN
		elseif action == "P" then
			serial[index] = PLACE
		elseif action == "D" then
			serial[index] = DIG
		else
			--what are they even trying to do
			return err
		end 

		if dir == "f" then
			serial[index] = score[index] + FORWARD
		elseif dir == "b" then
			serial[index] = score[index] + BACKWARD
		elseif dir == "l" then
			serial[index] = score[index] + LEFT
		elseif dir == "r" then
			serial[index] = score[index] + RIGHT
		elseif dir == "a" then
			serial[index] = score[index] + AROUND
		elseif dir == "u" then
			serial[index] = score[index] + UP
		elseif dir == "d" then
			serial[index] = score[index] + DOWN
		elseif dir == "n" then
			serial[index] = score[index] + NORTH
		elseif dir == "s" then
			serial[index] = score[index] + SOUTH
		elseif dir == "e" then
			serial[index] = score[index] + EAST
		elseif dir == "w" then
			serial[index] = score[index] + WEST
		elseif dir == "o" then
			serial[index] = score[index] + STAY
		else
			--what are they even trying to do
			return ERR
		end 

		serial[index] = serial[index] + (count*1000)
	end
	return serial
end

function loadandrun(text)
	command = serial.loader(text)
	serial = serial.serial(command)
end

function move(command)
	--executes single movement instruction (for now)
	--if no fuel returns FUEL
	--if obstructed returns FAIL
	--if invalid command returns ERR
	--if suuccessful returns OKAY
	--if turning required, will always move forward
	--LEFT RIGHT and AROUND do not apply
	--not sure if this should support cardinals
	--	seeing as how the same thing can be accomplished
	--	with seperate calls to turn(<direction>) and move(FORWARD) 
	dir = command

	if T.getFuelLevel() == 0 then	
		return FUEL
	end


	if dir == STAY then
		--easy one
		return OKAY
	elseif dir == UP then
		if T.up() then
			pm.current = pm.current + vector.new(0,1,0)
			return OKAY
		end

	elseif dir == DOWN then
		if T.down() then
			pm.current = pm.current + vector.new(0,-1,0)
			return OKAY
		end

	elseif dir == FORWARD then
		if T.forward() then
			pm.current = pm.current + cardinal2vec(pm.facing)
			return OKAY
		end

	elseif dir == BACKWARD then
		if T.back() then
			pm.current = pm.current - cardinal2vec(pm.facing) 
			return OKAY
		end

	elseif is_cardinal(dir) then
		--uses a tad bit of recursion
		pm.turn(dir)
		if pm.move(FORWARD) == OKAY then
			return OKAY
		else 
			pm.turn(pm.negate(dir))
			return FAIL
		end
	else
		--what are they even trying to do
		return ERR
	end

	return FAIL
end

function refuel()
	--TODO this could be much better
	for i = 1, 16 do -- loop through the slots
		turtle.select(i) -- change to the slot
		if turtle.refuel(0) then -- if it's valid fuel
			turtle.refuel(8)
			return true
		end
	end

	-- out of fuel
	return false
end

function cardinal2vec(dir)
	vec = vector.new(0,0,0)
	if dir == NORTH then
		vec.z = -1
	elseif dir == SOUTH then
		vec.z = 1
	elseif dir == WEST then
		vec.x = -1
	elseif dir == EAST then
		vec.x = 1
	else
		--must be cardinal direction
		return ERR end
	return vec
end

function is_cardinal(dir)
	if (dir == NORTH)
		or (dir == SOUTH)
		or (dir == EAST)
		or (dir == WEST)
	then
		return true
	else 
		return false
	end
end

function turn(command)
	dir = command

	if dir == STAY then
		--easy one
		return

	elseif dir == LEFT then
		T.turnLeft()
		if pm.facing == NORTH then
			pm.facing = WEST
		elseif pm.facing == EAST then
			pm.facing = NORTH
		elseif pm.facing == SOUTH then
			pm.facing = EAST
		elseif pm.facing == WEST then
			pm.facing = SOUTH
		else
			--UNREACHABLE
		end
		
	elseif dir == RIGHT then
		T.turnRight()
		if pm.facing == NORTH then
			pm.facing = EAST
		elseif pm.facing == EAST then
			pm.facing = SOUTH
		elseif pm.facing == SOUTH then
			pm.facing = WEST
		elseif pm.facing == WEST then
			pm.facing = NORTH
		else
			--UNREACHABLE
		end	
	elseif dir == AROUND then
		T.turnRight()
		T.turnRight()
		if pm.facing == NORTH then
			pm.facing = SOUTH
		elseif pm.facing == EAST then
			pm.facing = WEST
		elseif pm.facing == SOUTH then
			pm.facing = NORTH
		elseif pm.facing == WEST then
			pm.facing = WEST
		else 
			--UNREACHABLE
		end	
	

	elseif is_cardinal(dir) then 
		turning = whichway(pm.facing, dir)
		--I am not sure whether this should be implemented like so...
		--or if it should just call turn(turning), going with this for now
		if turning == STAY then
			--easy one: do nothing
		elseif turning == AROUND then
			T.turnRight()
			T.turnRight()
		elseif turning == RIGHT then
			T.turnRight()
		elseif turning == LEFT then
			T.turnLeft()
		else
			--UNREACHABLE
		end
		pm.facing = dir

	end

end

function negate(dir)
	if dir == NORTH then
		return SOUTH
	elseif dir == EAST then
		return WEST
	elseif dir == SOUTH then
		return NORTH 
	elseif dir == WEST then
		return EAST 
	elseif dir == LEFT then
		return RIGHT
	elseif dir == RIGHT then 
		return LEFT
	elseif dir == FORWARD then
		return BACKWARD
	elseif dir == BACKWARD then
		return FORWARD
	elseif dir == AROUND then
		return STAY 	
	else 
		--what are they even trying to negate?
		return ERR 	
	end
end

function whichway(olddir, newdir)
	--returns LEFT, RIGHT, AROUND, or STAY
	--returns how to go from olddir to newdir
	--where olddir and newdir are cardinals
	if olddir == newdir then
		return STAY

	elseif oldir == pm.negate(newdir) then
		return AROUND

	elseif (olddir == NORTH and newdir == EAST) 
		or (olddir == EAST and newdir == SOUTH)
		or (olddir == SOUTH and newdir == WEST)
		or (olddir == WEST and newdir == NORTH)
	then
		return RIGHT
	
	elseif (olddir == NORTH and newdir == WEST) 
		or (olddir == EAST and newdir == NORTH)
		or (olddir == SOUTH and newdir == EAST)
		or (olddir == WEST and newdir == SOUTH)
	then
		return LEFT 
	
	else
		--what are they even passing?
		return ERR
	end 




function digforward(times)
	T.dig()
	T.forward() --TODO error proof
	if times > 1 then
		digforward(times-1)
	end
end


function farm()
	--todo go to center of farm, plant height
	--todo replant
	command "((Df,Mf)4,Tl,Df,Tl,(Df,Mf)7,Df,Tr,Df,Mf,Tr,(Df,Mf)5, Df,Tl,Df,Mf,Tl,(Df,Mf)3,Df,Tr,Df,Mf,Tr,Df,Mf,Df,Tr,Mf4,Tr)2"
	serial.loadandrun(command)
	
	for i=1,2 do
		digforward(4)
		T.turnLeft()
		digforward(1)
		T.turnLeft()
		digforward(7)
		T.dig()
		T.turnRight()
		digforward(1)
		T.turnRight()
		digforward(5)
		T.dig()
		T.turnLeft()
		digforward(1)
		T.turnLeft()
		digforward(3)
		T.dig()
		T.turnRight()
		digforward(1)
		T.turnRight()
		digforward(1)
		T.dig()
		T.turnRight()
		T.forward(4)
		T.turnRight()
	end
end	
	
	

os.loadAPI(points)
pm.orient()--TODO this isnt a function of pm yet






