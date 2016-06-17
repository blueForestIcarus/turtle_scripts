-- Client for Mote - The Turtle Remote
-- http://hbar.kapsi.fi/ccserver/mote/
-- 2014 Matti Vapa
-- Feel free to modify and redistribute
-- this program. Attribution is appreciated,
-- but not required.
 
-- I take no responsibility on any
-- problems this program might cause
-- to anyone ever. Not that it will.
 
-- version 2.0
-- updated to asynchronous connection to the
-- server for better responsivenes
 
if not http then
  print("HTTP required!")
  return
end
 
print("Checking fuel...")
if turtle.getFuelLevel() == 0 then
  print("Refuel me!")
  return
end
print("Ok!")
 
-- Query this address for commands.
url = "http://hbar.kapsi.fi/ccserver/mote/get/"
 
-- Map the commands returned by the server to functions.
-- These are all of the commands available at the time of
-- writing. If you want more functions, you could use
-- for example "menu" to change between sets of functions.
-- Also note that this works with computers too, so you
-- could use this to control your base doors and machines
-- or anything. The session stays live as long as there
-- was at least one command or query during the last hour
-- (might change if there's need for it).
cmds = {}
cmds.arrowUp = turtle.forward
cmds.arrowDown = turtle.back
cmds.arrowLeft = turtle.turnLeft
cmds.arrowRight = turtle.turnRight
cmds.button1 = turtle.up
cmds.button2 = turtle.dig
cmds.button3 = turtle.place
cmds.button4 = turtle.down
cmds.menu = turtle.attack
 
sID = {...}
if #sID < 1 then
  print("Usage: mote <session ID>")
  print("Parameter session ID is the random numbers and letters")
  print("following /mote/ in the controller URL.")
end
sID = sID[1]
-- We need to send this data to get the commands from server.
data = "sessionId="..sID
 
print("Listening for commands...")
 
-- Initialize the command value
cmd = "null"
 
-- We use this function to asynchronously wait for the command from the server.
-- The server will keep the connection open until there is a command to
-- send or it has been open for 60 seconds.
 
function waitForCmd()
  -- http.request will raise an "http_success" or "http_failure"
  -- event after completion. We'll wait for that and act accordingly.
  http.request(url,data)
  e, u, r = os.pullEvent()
  while e ~= "http_success" and e ~= "http_failure" do
    e, u, r = os.pullEvent()
  end
  if e == "http_failure" then
    error("Could not connect to server.")
  elseif r.getResponseCode() ~= 200 then
    print("Something went wrong!")
    print("Server response code: "..tostring(r.getResponseCode()))
    print("Reason: "..r.readAll())
    error("Bad request. Check your session ID.")
  else
    cmd = r.readAll()
  end
end
 
-- Main loop. If we receive a proper command, we simultaneously execute it
-- and request the next one. This way the program is more responsive compared
-- to continuously polling the server.
while true do
  if cmds[cmd] then
    parallel.waitForAll(cmds[cmd],waitForCmd)
  else
    waitForCmd()
  end
end
