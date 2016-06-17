T=Turtle

-- position manager
pm = {}
pm.waypoints = {}
pm.timeout = 5

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

function move(command)
	--executes single movement instruction (for now)
	--if turning required, will always move forward
	--LEFT and RIGHT and AROUND linked to turn function
	dir = command
	f = nil
	newpos = pm.current
	olddir = pm.facing

	if dir == STAY then
		--easy one
		return
	elseif dir == LEFT then
		pm.turn(LEFT)
		return
	elseif dir == RIGHT then
		pm.turn(RIGHT)
		return
	elseif dir == AROUND then
		pm.turn(AROUND)
		return 

	elseif dir == UP then
		f = T.up
		newpos = pm.current + vector.new(0,1,0)
	elseif dir == DOWN then
		f = T.down
		newpos = pm.current + vector.new(0,-1,0)
	elseif dir == FORWARD then
		f = T.forward
		newpos = pm.current + VEC_ZERO
		if pm.facing == NORTH then
			newpos.z = pos.z - 1
		elseif pm.facing == SOUTH then
			newpos.z = pos.z + 1
		elseif pm.facing == WEST then
			newpos.x = pos.x - 1
		elseif pm.facing == EAST then
			newpos.x = pos.x + 1
		end 
	
	elseif dir == BACKWARD then
		f = T.back
		pos = pm.current + VEC_ZERO
		if pm.facing == NORTH then
			newpos.z = pos.z + 1
		elseif pm.facing == SOUTH then
			newpos.z = pos.z - 1
		elseif pm.facing == WEST then
			newpos.x = pos.x + 1
		elseif pm.facing == EAST then
			newpos.x = pos.x - 1
		end 			

	else --gps TODO
	end 
end

function turn(command)
	dir = command

	if dir == LEFT then
		T.turnLeft()
		if pm.facing == NORTH then
			pm.facing = WEST
		elseif pm.facing == EAST then
			pm.facing = NORTH
		elseif pm.facing == SOUTH then
			pm.facing = EAST
		elseif pm.facing == WEST then
			pm.facing = SOUTH
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
		end	
	end--TODO gps
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






