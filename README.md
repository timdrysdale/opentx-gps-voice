# opentx-gps-voice

Lua script for opentx 2.2 that calls out named locations when you fly over them. 

## Description

Sound is triggered when you enter a region. Regions are defined as polygons, each point is given by lat and long. This is intended for use as an entertaining gimmick, rather than for safety, due to the nature of GPS.

## Usage
The script is currently configured for the Wicken Model Aero Club, near Milton Keynes in the United Kingdom.
To adapt for your club, modify the list of regions in the loadPositions() function.

There is currently no support for nested regions. Whichever is the highest priority (highest priority value) that matches 
is the location given. So if you have a small area within a larger area, and you want to hear the name of the smaller area announced, 
then make sure the smaller area has a higher priority number.

## Installation

Copy the lua script gpsv.lua and the all the wav files to ```/SCRIPTS/TELEMETRY``` on your SD card, then choose one of your telemetry screens to be a script, and choose the gpsv script from the menu. 

## Code / details

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

## Testing

Currently tested on opentx 2.2.1 simulator for x9d+
not tested on hardware - so performance has not been assessed.

## History

Created 2018 June 19 Tim Drysdale
