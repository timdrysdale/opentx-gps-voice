--[[

gpsv.lua

GPS voice script for opentx 2.2.1

History

Created: Tim Drysdale 2018 June 19

Description:

Calls out named locations when you fly over them. Sound is triggered when you enter a region. Regions are defined as polygons, each point is given by lat and long. This is intended for use as an entertaining gimmick, rather than for safety, due to the nature of GPS.

Usage:
The example below is for the Wicken Model Aero Club, near Milton Keynes in the United Kingdom.
To adapt for your club, modify the list of regions in 

There is currently no support for nested regions. Whichever is the highest priority (highest priority value) that matches 
is the location given.


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
local unknownPosition = {name = "unknown", sound = "/SCRIPTS/TELEMETRY/unknow.wav", priority=0}
local positionName = unknownPosition.name
local priority = unknownPosition.priority
local sound = unknownPosition.sound


--[[ Edit the locations table below to represent your flying field.
     Go easy on the number of regions to avoid performance issues 
--]]

local function loadPositions()
  -- Change this sound file to one that matches your location
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
			sound = "/SCRIPTS/TELEMETRY/trees.wav",  --what is played when you enter this region
			priority = 9
		},
	outside = {
			coords =
				{
				
				{lat=51.990919, lng=-0.864448},
				{lat=51.991888, lng=-0.870113},
				{lat=51.987538, lng=-0.873482},
				{lat=51.985873, lng=-0.866680}
				},
			name = "Outside",
			sound = "/SCRIPTS/TELEMETRY/outside.wav",
			priority = 1 
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
			sound = "/SCRIPTS/TELEMETRY/field.wav",
			priority = 2 
		},
		linedup		= {
			coords =
				{
				
				{lat=51.987067, lng=-0.870670},
				{lat=51.987014, lng=-0.870456},
				{lat=51.990470, lng=-0.864650},
				{lat=51.990371, lng=-0.864591}

				},
			name = "lined up",
			sound = "/SCRIPTS/TELEMETRY/lineup.wav",
			priority = 3 --higher than field, lower than tree
		},

		
		nofly		= {
			coords =
				{
						{lat=51.989878, lng=-0.865453},
						{lat=51.987717, lng=-0.868951},
						{lat=51.986977, lng=-0.866172},
						{lat=51.989337, lng=-0.865003}
				},
			name = "No Flying Zone",
			sound = "/SCRIPTS/TELEMETRY/nofly.wav",
			priority =4
		},
		
		pits	= {
			coords =
				{
					{lat=51.988680, lng=-0.867559},
					{lat=51.988604, lng=-0.867356},
					{lat=51.988560, lng=-0.867378},
					{lat=51.988560, lng=-0.867378},
					{lat=51.988395, lng=-0.867122},
					{lat=51.988610, lng=-0.867685}

				},
			name = "Pits",
			sound = "/SCRIPTS/TELEMETRY/pits.wav",
			priority = 5
		}
}

--[[

old lined up				
				     {lat=51.987919, lng=-0.869085},
					 {lat=51.989432, lng=-0.866510},
					 {lat=51.989419, lng=-0.866274},
					 {lat=51.987906, lng=-0.868978}
					 
pits
51.988680, -0.867559
51.988604, -0.867356
51.988560, -0.867378
51.988560, -0.867378
51.988395, -0.867122
51.988610, -0.867685

Hut - exact
51.988604, -0.867356
51.988560, -0.867378
51.988548, -0.867299
51.988570, -0.867282

strip
51.988555, -0.868042
51.988493, -0.867892
51.988948, -0.867076
51.989041, -0.867205

ditch
51.988995, -0.869019
51.988704, -0.867922
51.988726, -0.867879
51.989042, -0.868973

hedge
51.988835, -0.868439
51.988835, -0.868439
51.988818, -0.868133
51.988886, -0.868364

no fly
51.989878, -0.865453
51.987717, -0.868951
51.986977, -0.866172
51.989337, -0.865003

carpark
51.989337, -0.865003
51.989449, -0.865493
51.989661, -0.865391
51.989634, -0.864870

outer lined up left
51.987696, -0.869561
51.987095, -0.870634
51.987029, -0.870516
51.987650, -0.869389

outer lined up right
51.989784, -0.865976
51.990465, -0.864839
51.990192, -0.864710
51.989783, -0.865633

]]

end

--[[ DO NOT EDIT BELOW THIS LINE - unless you are doing more than updating your regions]]
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

local function init()
  gpsId = getTelemetryId("GPS")
  -- load the positions of the regions for your flying field 
  loadPositions()
end

--[[ insidePolygon is from Peter Gilmour / https://stackoverflow.com/questions/31730923/check-if-point-lies-in-polygon-lua
     Cosmetically modified to use .lat/.lng instead of .x/.y 
--]]

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
  -- check if the point is in a known region 
  local point = {lat = lat, lng = lng}
  local thisPosition
  foundLocation = false
  oldLocation = positionName
  
  --iterate over regions in the locations list
  for index, value in next, locations do
    -- check if we are inside this polygon 
    if insidePolygon(value.coords, point) then

	   if foundLocation == false then
			 priority = value.priority 
			 positionName = value.name
			 sound = value.sound
			 foundLocation = true
		else
			if value.priority >= priority then
				priority = value.priority 
				positionName = value.name
				sound = value.sound
			end
		end
		
	   print("inside", value.name)
	end
  
  end
  
  --revert to unknown location if not in a defined region
  if foundLocation == false then
	   positionName = unknownPosition.name
	   sound = unknownPosition.sound
  end   
  
  --play sound if position is new
  if positionName ~= oldLocation then
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
  lcd.drawText(1,1,"GPS Voice Alert",0)
  lcd.drawText(1,11,"GPS:", 0)
  lcd.drawText(lcd.getLastPos()+2,11,gpsValue,0)
  lcd.drawText(1,22,"Region:", 0)
  lcd.drawText(lcd.getLastPos()+2,22,positionName,0)
end


return{init=init,run=run,background=background}
