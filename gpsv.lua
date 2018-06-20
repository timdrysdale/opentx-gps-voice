--[[

gpsv.lua

GPS voice script for opentx 2.2.1

History

Created: Tim Drysdale 2018 June 19

Description:

Calls out named locations when you fly over them. Sound is triggered when you enter a region. Regions are defined as polygons, each point is given by lat and long. 

Usage:
The example below is for the Wicken Model Aero Club, near Milton Keynes in the United Kingdom.
To adapt for your club, modify the list of regions in 

There is currently no support for nested regions. Whichever is the last region you matched with, is what is announced.
If your table is stored in memory in the same order that you write it in script, 
then you shouldn't have any surprises.  A future version may address this, subject to performance limitations.


Details:

The backbone of the script comes from the opentx gps example.

The entry into a region is calculated using a point in polygon algorithm found here:
https://stackoverflow.com/questions/31730923/check-if-point-lies-in-polygon-lua
(See Peter Gilmour's answer )

Example location sounds are from http://www.fromtexttospeech.com/
US English, Daisy, medium speed, resampled in Audacity to 32kHz 16bit PCM

Note that for 2.2.1 that small negative positions are logged as positive positions,
so you will need to take care when using a previously logged track to find coordinates 
because they could be wrong - whereas if you use https://www.latlong.net/ then you will
get the right points because the value in the system is not affected by the bug.

]]


local gpsValue = "unknown"
local unknownPosition = {name = "unknown", sound = "/SCRIPTS/TELEMETRY/unknow.wav"}
local positionName = unknownPosition.name
local sound = unknownPosition.sound

local function rnd(v,d)
    if d then
     return math.floor((v*10^d)+0.5)/(10^d)
    else
     return math.floor(v+0.5)
    end
end

local function getTelemetryId(name)
    field = getFieldInfo(name)
    if field then
      return field.id
    else
      return -1
    end
end


local function loadPositions()
  -- Put the name of your club into this sound file
  playFile("/SCRIPTS/TELEMETRY/load.wav")

  --The index of each region is arbitrary, helps enforce ordering though
  locations = {
	trees = {
			coords =  --list of latitude and longitudes defining the region (order matters)
				{
					{lat=51.989364, lng=-0.865092}, 
					{lat=51.989688, lng=-0.868386},
					{lat=51.988079, lng=-0.870204},
					{lat=51.987088, lng=-0.866074},
					{lat=51.986723, lng=-0.866320},
					{lat=51.987958, lng=-0.870655},
					{lat=51.990127, lng=-0.868549},
					{lat=51.989757, lng=-0.864858}
				},
			name = "trees",  -- what is shown on screen
			sound = "/SCRIPTS/TELEMETRY/trees.wav"  --what is played when you enter this region
		},
	field = {
			coords =
				{
					{lat=51.989364, lng=-0.865092},
					{lat=51.989688, lng=-0.868386},
					{lat=51.988079, lng=-0.870204},
					{lat=51.987088, lng=-0.866074}
				},
			name = "field",
			sound = "/SCRIPTS/TELEMETRY/field.wav"
		},
		lineup		= {
			coords =
				{
				     {lat=51.987919, lng=-0.869085},
					 {lat=51.989432, lng=-0.866510},
					 {lat=51.989419, lng=-0.866274},
					 {lat=51.987906, lng=-0.868978}
				},
			name = "lined up",
			sound = "/SCRIPTS/TELEMETRY/lineup.wav"
		}
}


end

local function init()
  gpsId = getTelemetryId("GPS")

  loadPositions()
end





local function insidePolygon(polygon, point)
local oddNodes = false
local j = #polygon
for i = 1, #polygon do
    if (polygon[i].lng < point.lng and polygon[j].lng >= point.lng or polygon[j].lng < point.lng and polygon[i].lng >= point.lng) then
        if (polygon[i].lat + ( point.lng - polygon[i].lng ) / (polygon[j].lng - polygon[i].lng) * (polygon[j].lat - polygon[i].lat) < point.lat) then
            oddNodes = not oddNodes;
        end
    end
    j = i;
end
return oddNodes end

local function updatePosition(lat,lng)
  local point = {lat = lat, lng = lng}
  local thisPosition
  foundLocation = false
  oldLocation = positionName
  
  for index, value in next, locations do

    if insidePolygon(value.coords, point) then
       positionName = value.name
	   sound = value.sound
	   foundLocation = true
	   --print(point, "inside:", value.name)
	else
	   --print(point, "outside:", value.name)
	end
  
  end
  
  if foundLocation == false then
	   positionName = unknownPosition.name
	   sound = unknownPosition.sound
  end   
  --print("in: ", positionName)
  
  --play sound if position is new
  if positionName ~= oldLocation then
    print(positionName, sound)
	
	playFile(sound)
  end

end

local function background()
  gpsLatLon = getValue(gpsId)
  
  if (type(gpsLatLon) == "table") then
    gpsValue = rnd(gpsLatLon["lat"],6) .. ", " .. rnd(gpsLatLon["lon"],6)
	updatePosition(gpsLatLon["lat"],gpsLatLon["lon"])
  else
    gpsValue = "not currently available"
  end



end

local function run(e)
  lcd.clear()
  background() -- update current GPS position
  lcd.drawText(1,1,"GPS Tree Alert",0)
  lcd.drawText(1,11,"GPS:", 0)
  lcd.drawText(lcd.getLastPos()+2,11,gpsValue,0)
  lcd.drawText(1,22,"Location:", 0)
  lcd.drawText(lcd.getLastPos()+2,22,positionName,0)
end



--[[
loadPositions()
updatePosition(51.989242,-0.866993)
]]

--[[ test code
print("hello")
loadPositions()
print(locations.trees.name)
for key, value in ipairs(locations.trees.coords)
  do
  print(value.lat, value.lng)
  end

local array = {5, 2, 6, 3, 6}

for index, value in next, locations do
	print(index,value)
	--local point = {lat = 51.989242, lng = -0.866993}
	--local point = {lat = 51.988727, lng = -0.867175}
	local point = {lat = 0.2, lng = 0.2}
	print(insidePolygon(value.coords,point))
	for k2, v2  in ipairs(value.coords)
	do
	   print(v2.lat, v2.lng)
	end
end




local polygon = {{lat=0,lng=0},{lat=1,lng=0},{lat=1,lng=1},{lat=0,lng=1}}

local point = {lat=0.2,lng=0.2}

print(" SIMPLE TEST TRUE?", insidePolygon(polygon,point))

local point = {lat = 51.988727, lng = -0.867175}

print("REAL TEST TRUE?", insidePolygon(locations.field.coords,point))



for key, value in locations
  do
      print(key, value)
  end



updatePosition(51.989242, -0.866993)
updatePosition(51.989612, -0.865588)

--]]

return{init=init,run=run,background=background}
