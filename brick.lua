t = turtle
L=10

function pd ()
	while t.getItemCount()==0 do
		if t.getSelectedSlot() == 16 then
			print "fuck"
			t.turnRight()
			t.forward()
			exit()
		end
		t.select(t.getSelectedSlot()+1)
	end

	t.placeDown()
end


function f () 
while t.detect() do
	t.up()
	pd()
end

t.forward()

if t.detectDown() then
	t.up()
end

end

t.select(1)

for i=1,100,1 do
for m=1,4,1 do
	for n=0,L-2,1 do
		pd()
		f()
	end
	t.turnLeft()
end

end 


