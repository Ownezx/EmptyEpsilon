-- Name: Chaos of War
-- Description: Two, three or four species battle for ultimate dominion. Designed as a replayable player versus player (PVP) scenario for individuals or teams. Terrain is randomly symmetrically generated for every game. 
---
--- Use Gamemaster (GM) screen to adjust parameters. The GM screen covers all of the parameters on the next page plus a variety of others.
---
--- Get the player ship access codes from the GM screen after you generate the terrain
---
--- Version 2.2
-- Type: PvP
-- Setting[Difficulty]: Determines the degree the environment helps or hinders the players
-- Difficulty[Normal|Default]: Normal difficulty
-- Difficulty[Easy]: More resources, services and reputation
-- Difficulty[Hard]: Fewer resources, services and reputation
-- Setting[Teams]: Number of teams. Each team may have one or more player ships on it. Default: 2 teams
-- Teams[2|Default]: Two teams
-- Teams[3]: Three teams
-- Teams[4]: Four teams
-- Setting[Players]: Number of player ships per team. 32 total max. Get player ship control codes from Game master screen. Default: 2 per team
-- Players[1]: One player ship per team. Get player ship control codes from Game master screen
-- Players[2|Default]: Two player ships per team. Get player ship control codes from Game master screen
-- Players[3]: Three player ships per team. Get player ship control codes from Game master screen
-- Players[4]: Four player ships per team. Get player ship control codes from Game master screen
-- Players[5]: Five player ships per team. Get player ship control codes from Game master screen
-- Players[6]: Six player ships per team. Get player ship control codes from Game master screen
-- Players[7]: Seven player ships per team. Get player ship control codes from Game master screen
-- Players[8]: Eight player ships per team. Get player ship control codes from Game master screen
-- Players[9]: Nine player ships per team. Get player ship control codes from Game master screen
-- Players[10]: Ten player ships per team. Get player ship control codes from Game master screen
-- Players[11]: Eleven player ships per team. Get player ship control codes from Game master screen
-- Players[12]: Twelve player ships per team. Get player ship control codes from Game master screen
-- Players[13]: Thirteen player ships per team. Get player ship control codes from Game master screen
-- Players[14]: Fourteen player ships per team. Get player ship control codes from Game master screen
-- Players[15]: Fifteen player ships per team. Get player ship control codes from Game master screen
-- Players[16]: Sixteen player ships per team. Get player ship control codes from Game master screen
-- Setting[Respawn]: How a player ship returns to the game after being destroyed. Default: Lindworm
-- Respawn[Lindworm|Default]: Destroyed player returns in a weak, but fast Lindworm
-- Respawn[Self]: Destroyed player returns as the same type of ship they originally started in
-- Setting[Station Sensors]: Determines range at which station sensors will warn friendly ships about enemy ships via messages. Default: 20U
-- Station Sensors[Zero]: Stations don't warn friendly players of enemies
-- Station Sensors[5U]: Stations warn friendly players of enemies within 5 units
-- Station Sensors[10U]: Stations warn friendly players of enemies within 10 units
-- Station Sensors[20U|Default]: Stations warn friendly players of enemies within 20 units
-- Station Sensors[30U]: Stations warn friendly players of enemies within 30 units
-- Setting[Time]: Determines how long the game will last. Default: 50 minutes
-- Time[20]: Game ends in 20 minutes
-- Time[30]: Game ends in 30 minutes
-- Time[40]: Game ends in 40 minutes
-- Time[50|Default]: Game ends in 50 minutes
-- Time[60]: Game ends in 60 minutes (one hour)
-- Time[70]: Game ends in 70 minutes (one hour and 10 minutes)
-- Time[80]: Game ends in 80 minutes (one hour and 20 minutes)
-- Time[90]: Game ends in 90 minutes (one hour and 30 minutes)
-- Time[100]: Game ends in 100 minutes (one hour and 40 minutes)

--------------------------------------------------------------------------------------------------------
--	Note: This script requires a version of supply_drop.lua that handles the variable jump_freighter  --
--			See pull request 1185                                                                     --
--------------------------------------------------------------------------------------------------------

require("utils.lua")
require("place_station_scenario_utility.lua")
require("generate_call_sign_scenario_utility.lua")
require("cpu_ship_diversification_scenario_utility.lua")

function init()
	scenario_version = "2.2.5"
	ee_version = "2024.12.08"
	print(string.format("    ----    Scenario: Chaos of War    ----    Version %s    ----    Tested with EE version %s    ----",scenario_version,ee_version))
	if _VERSION ~= nil then
		print("Lua version:",_VERSION)
	end
	setVariations()
	setConstants()
	setStaticScienceDatabase()
	setGMButtons()
end
function setVariations()
	if getEEVersion() ==  2021623 then
		local svs = getScenarioVariation()	--scenario variation string
		if string.find(svs,"Easy") then
			difficulty = .5
			base_reputation = 50
		elseif string.find(svs,"Hard") then
			difficulty = 2
			base_reputation = 10
		else
			difficulty = 1		--default (normal)
			base_reputation = 20
		end
	else
		local enemies = {
			["Normal"] ={difficulty = 1,	rep = 20},
			["Easy"] =	{difficulty = .5,	rep = 50},
			["Hard"] =	{difficulty = 2,	rep = 10},
		}
		difficulty = enemies[getScenarioSetting("Difficulty")].difficulty
		base_reputation = enemies[getScenarioSetting("Difficulty")].rep
		local teams = {
			["2"] = 2,
			["3"] = 3,
			["4"] = 4,
		}
		player_team_count = teams[getScenarioSetting("Teams")]
		local player_count_options = {
			["1"] = 1,
			["2"] = 2,
			["3"] = 3,
			["4"] = 4,
			["5"] = 5,
			["6"] = 6,
			["7"] = 7,
			["8"] = 8,
			["9"] = 9,
			["10"] = 10,
			["11"] = 11,
			["12"] = 12,
			["13"] = 13,
			["14"] = 14,
			["15"] = 15,
			["16"] = 16,
		}
		ships_per_team = player_count_options[getScenarioSetting("Players")]
		max_ships_per_team = {32,16,10,8}	--engine supports 32 player ships
		if ships_per_team > max_ships_per_team[player_team_count] then
			ships_per_team = max_ships_per_team[player_team_count]
		end
		local respawn_options = {
			["Lindworm"] = "lindworm",
			["Self"] = "self",
		}
		respawn_type = respawn_options[getScenarioSetting("Respawn")]
		local station_sensor_options = {
			["Zero"] = 0,
			["5U"] = 5000,
			["10U"] = 10000,
			["20U"] = 20000,
			["30U"] = 30000,
		}
		station_sensor_range = station_sensor_options[getScenarioSetting("Station Sensors")]
		game_time_limit = getScenarioSetting("Time")*60
	end
end
function setConstants()
	thresh = .2		--leading/trailing completion threshold percentage for game
	if game_time_limit == nil then
		game_time_limit = 45*60
	end
	if station_sensor_range == nil then
		station_sensor_range = 20000
	end
	if respawn_type == nil then
		respawn_type = "lindworm"
	end
	if ships_per_team == nil then
		ships_per_team = 2
		player_team_count = 2
	end
	max_game_time = game_time_limit	
	game_state = "paused"	--then moves to "terrain generated" then to "running"
	respawn_count = 0
	storage = getScriptStorage()
	storage.gatherStats = gatherStats
	predefined_player_ships = {
		{name = "Damocles",		control_code = "SWORD265"},
		{name = "Endeavor",		control_code = "TRY558"},
		{name = "Hyperion",		control_code = "SQUIRREL777"},
		{name = "Liberty",		control_code = "BELL432"},
		{name = "Prismatic",	control_code = "COLOR180"},
		{name = "Visionary",	control_code = "EYE909"},
	}
	f2s = {	--faction name to short name
		["Human Navy"] = "human",
		["Kraylor"] = "kraylor",
		["Exuari"] = "exuari",
		["Ktlitans"] = "ktlitan",
	}
	death_penalty = {}
	death_penalty["Human Navy"] = 0
	death_penalty["Kraylor"] = 0
	death_penalty["Exuari"] = 0
	death_penalty["Ktlitans"] = 0
	terrain_generated = false
	advanced_intel = false
	missile_availability = "unlimited"
	defense_platform_count_index = 10
	defense_platform_count_options = {
		{count = 0, distance = 0,		player = 4500},
		{count = 3, distance = 2000,	player = 2500},
		{count = 4, distance = 2400,	player = 3000},
		{count = 5, distance = 3000,	player = 3500},
		{count = 6, distance = 4300,	player = 2500},
		{count = 8, distance = 7000,	player = 4000},
		{count = 9, distance = 7800,	player = 4500},
		{count = 10, distance = 9000,	player = 4000},
		{count = 12, distance = 10000,	player = 4500},
		{count = "random", distance = 0,	player = 0},
	}
	dp_comms_data = {	--defense platform comms data
		weapon_available = 	{
			Homing =			random(1,13)<=(3-difficulty),
			HVLI =				random(1,13)<=(6-difficulty),
			Mine =				false,
			Nuke =				false,
			EMP =				false,
		},
		services = {
			supplydrop = "friend",
			reinforcements = "friend",
			jumpsupplydrop = "friend",
		},
		service_cost = {
			supplydrop =		math.random(80,120), 
			reinforcements =	math.random(125,175),
			jumpsupplydrop =	math.random(110,140),
		},
        jump_overcharge =		false,
        probe_launch_repair =	random(1,13)<=(3-difficulty),
        hack_repair =			random(1,13)<=(3-difficulty),
        scan_repair =			random(1,13)<=(3-difficulty),
        combat_maneuver_repair=	random(1,13)<=(3-difficulty),
        self_destruct_repair =	random(1,13)<=(3-difficulty),
        tube_slow_down_repair =	random(1,13)<=(3-difficulty),
		reputation_cost_multipliers = {
			friend = 			1.0, 
			neutral = 			3.0,
		},
		goods = {},
		trade = {},
	}
	defense_fleet_list = {
		["Small Station"] = {
			{DF1 = "MT52 Hornet",DF2 = "MU52 Hornet",DF3 = "MT52 Hornet",DF4 = "MU52 Hornet",},
			{DF1 = "MT52 Hornet",DF2 = "MT52 Hornet",DF3 = "MT52 Hornet",DF4 = "MU52 Hornet",},
			{DF1 = "MT52 Hornet",DF2 = "MU52 Hornet",DF3 = "MU52 Hornet",DF4 = "Nirvana R5A",},
    	},
		["Medium Station"] = {
			{DF1 = "Adder MK5",DF2 = "MU52 Hornet",DF3 = "MT52 Hornet",DF4 = "Adder MK4",DF5 = "Adder MK6",},
			{DF1 = "Adder MK5",DF2 = "MU52 Hornet",DF3 = "Nirvana R5A",DF4 = "Adder MK4",DF5 = "Adder MK6",},
			{DF1 = "Adder MK5",DF2 = "MU52 Hornet",DF3 = "Nirvana R5A",DF4 = "WX-Lindworm",DF5 = "Adder MK6",},
		},
		["Large Station"] = {
			{DF1 = "Adder MK5",DF2 = "MU52 Hornet",DF3 = "MT52 Hornet",DF4 = "Adder MK4",DF5 = "Adder MK6",DF6 = "Phobos T3",DF7 = "Adder MK7",DF8 = "Adder MK8",},
			{DF1 = "Adder MK5",DF2 = "MU52 Hornet",DF3 = "Adder MK9",DF4 = "Adder MK4",DF5 = "Adder MK6",DF6 = "Phobos T3",DF7 = "Adder MK7",DF8 = "Adder MK8",},
			{DF1 = "Adder MK5",DF2 = "MU52 Hornet",DF3 = "Nirvana R5A",DF4 = "Adder MK4",DF5 = "Adder MK6",DF6 = "Phobos T3",DF7 = "Adder MK7",DF8 = "Adder MK8",},
		},
		["Huge Station"] = {
			{DF1 = "Adder MK5",DF2 = "MU52 Hornet",DF3 = "MT52 Hornet",DF4 = "Adder MK4",DF5 = "Adder MK6",DF6 = "Phobos T3",DF7 = "Adder MK7",DF8 = "Adder MK8",DF9 = "Fiend G4",DF10 = "Stalker R7",DF11 = "Stalker Q7"},
			{DF1 = "Adder MK5",DF2 = "MU52 Hornet",DF3 = "Nirvana R5A",DF4 = "Adder MK4",DF5 = "Adder MK6",DF6 = "Phobos T3",DF7 = "Adder MK7",DF8 = "Adder MK8",DF9 = "Fiend G4",DF10 = "Stalker R7",DF11 = "Stalker Q7"},
			{DF1 = "Adder MK5",DF2 = "MU52 Hornet",DF3 = "Phobos T3",DF4 = "Adder MK4",DF5 = "Adder MK6",DF6 = "Phobos T3",DF7 = "Adder MK7",DF8 = "Adder MK8",DF9 = "Fiend G4",DF10 = "Stalker R7",DF11 = "Stalker Q7"},
		},
	}
	station_list = {}
	primary_station_size_index = 1
	primary_station_size_options = {"random","Small Station","Medium Station","Large Station","Huge Station"}
	primary_jammers = "random"
	player_ship_types = "default"
	custom_player_ship_type = "Heavy"
	default_player_ship_sets = {
		{"Crucible"},
		{"Maverick","Flavia P.Falcon"},
		{"Atlantis","Phobos M3P","Crucible"},
		{"Atlantis","Maverick","Phobos M3P","Flavia P.Falcon"},
		{"Atlantis","Player Cruiser","Maverick","Crucible","Phobos M3P"},
		{"Atlantis","Hathcock","Flavia P.Falcon","Player Missile Cr.","Maverick","Phobos M3P"},
		{"Atlantis","Repulse","Maverick","Player Missile Cr.","Phobos M3P","Flavia P.Falcon","Crucible"},
		{"Atlantis","Player Cruiser","Hathcock","Player Fighter","Phobos M3P","Maverick","Crucible","Flavia P.Falcon"},
		{"Atlantis","Player Cruiser","Repulse","Player Missile Cr.","Player Fighter","Phobos M3P","Crucible","Flavia P.Falcon","Maverick"},
		{"Atlantis","Player Cruiser","Piranha","Player Missile Cr.","Player Fighter","Phobos M3P","Crucible","Flavia P.Falcon","Maverick","Phobos M3P"},
		{"Atlantis","Player Cruiser","Hathcock","Repulse","Player Fighter","Player Missile Cr.","Crucible","Flavia P.Falcon","Maverick","Phobos M3P","Flavia P.Falcon"},
		{"Atlantis","Player Cruiser","Piranha","Repulse","Player Fighter","Player Missile Cr.","Crucible","Flavia P.Falcon","Maverick","Phobos M3P","Flavia P.Falcon","Phobos M3P"},
		{"Atlantis","Player Cruiser","Piranha","Hathcock","Player Fighter","Player Missile Cr.","Crucible","Flavia P.Falcon","Maverick","Phobos M3P","Flavia P.Falcon","Phobos M3P","Crucible"},
		{"Atlantis","Player Cruiser","Hathcock","Repulse","Piranha","Player Missile Cr.","Crucible","Flavia P.Falcon","Maverick","Phobos M3P","Flavia P.Falcon","Phobos M3P","Crucible","Player Fighter"},
		{"Atlantis","Player Cruiser","Hathcock","Repulse","Nautilus","Player Missile Cr.","Crucible","Flavia P.Falcon","Maverick","Phobos M3P","Flavia P.Falcon","Phobos M3P","Crucible","Player Fighter","MP52 Hornet"},
		{"Atlantis","Player Cruiser","Nautilus","Repulse","Piranha","Player Missile Cr.","Crucible","Flavia P.Falcon","Maverick","Phobos M3P","Flavia P.Falcon","Phobos M3P","Crucible","Player Fighter","MP52 Hornet","Maverick"},
	}
	custom_player_ship_sets = {
		["Jump"] = {
			{"Atlantis"},
			{"Atlantis","Player Cruiser"},
			{"Atlantis","Player Cruiser","Hathcock"},
			{"Atlantis","Player Cruiser","Hathcock","Repulse"},
			{"Atlantis","Player Cruiser","Hathcock","Repulse","Piranha"},
			{"Atlantis","Player Cruiser","Hathcock","Repulse","Piranha","Nautilus"},
			{"Atlantis","Player Cruiser","Hathcock","Repulse","Piranha","Nautilus","Repulse"},
			{"Atlantis","Player Cruiser","Hathcock","Repulse","Piranha","Nautilus","Repulse","Player Cruiser"},
			{"Atlantis","Player Cruiser","Hathcock","Repulse","Piranha","Nautilus","Repulse","Player Cruiser","Piranha"},
			{"Atlantis","Player Cruiser","Hathcock","Repulse","Piranha","Nautilus","Repulse","Player Cruiser","Piranha","Atlantis"},
			{"Atlantis","Player Cruiser","Hathcock","Repulse","Piranha","Nautilus","Repulse","Player Cruiser","Piranha","Atlantis","Nautilus"},
			{"Atlantis","Player Cruiser","Hathcock","Repulse","Piranha","Nautilus","Repulse","Player Cruiser","Piranha","Atlantis","Nautilus","Hathcock"},
			{"Atlantis","Player Cruiser","Hathcock","Repulse","Piranha","Nautilus","Repulse","Player Cruiser","Piranha","Atlantis","Nautilus","Hathcock","Atlantis"},
			{"Atlantis","Player Cruiser","Hathcock","Repulse","Piranha","Nautilus","Repulse","Player Cruiser","Piranha","Atlantis","Nautilus","Hathcock","Atlantis","Player Cruiser"},
			{"Atlantis","Player Cruiser","Hathcock","Repulse","Piranha","Nautilus","Repulse","Player Cruiser","Piranha","Atlantis","Nautilus","Hathcock","Atlantis","Player Cruiser","Piranha"},
			{"Atlantis","Player Cruiser","Hathcock","Repulse","Piranha","Nautilus","Repulse","Player Cruiser","Piranha","Atlantis","Nautilus","Hathcock","Atlantis","Player Cruiser","Piranha","Hathcock"},
		},
		["Warp"] = {
			{"Crucible"},
			{"Crucible","Maverick"},
			{"Crucible","Maverick","Phobos M3P"},
			{"Crucible","Maverick","Phobos M3P","Flavia P.Falcon"},
			{"Crucible","Maverick","Phobos M3P","Flavia P.Falcon","MP52 Hornet"},
			{"Crucible","Maverick","Phobos M3P","Flavia P.Falcon","MP52 Hornet","Player Missile Cr."},
			{"Crucible","Maverick","Phobos M3P","Flavia P.Falcon","MP52 Hornet","Player Missile Cr.","Maverick"},
			{"Crucible","Maverick","Phobos M3P","Flavia P.Falcon","MP52 Hornet","Player Missile Cr.","Maverick","Phobos M3P"},
			{"Crucible","Maverick","Phobos M3P","Flavia P.Falcon","MP52 Hornet","Player Missile Cr.","Maverick","Phobos M3P","Crucible"},
			{"Crucible","Maverick","Phobos M3P","Flavia P.Falcon","MP52 Hornet","Player Missile Cr.","Maverick","Phobos M3P","Crucible","MP52 Hornet"},
			{"Crucible","Maverick","Phobos M3P","Flavia P.Falcon","MP52 Hornet","Player Missile Cr.","Maverick","Phobos M3P","Crucible","MP52 Hornet","Player Missile Cr."},
			{"Crucible","Maverick","Phobos M3P","Flavia P.Falcon","MP52 Hornet","Player Missile Cr.","Maverick","Phobos M3P","Crucible","MP52 Hornet","Player Missile Cr.","Flavia P.Falcon"},
			{"Crucible","Maverick","Phobos M3P","Flavia P.Falcon","MP52 Hornet","Player Missile Cr.","Maverick","Phobos M3P","Crucible","MP52 Hornet","Player Missile Cr.","Flavia P.Falcon","Player Missile Cr."},
			{"Crucible","Maverick","Phobos M3P","Flavia P.Falcon","MP52 Hornet","Player Missile Cr.","Maverick","Phobos M3P","Crucible","MP52 Hornet","Player Missile Cr.","Flavia P.Falcon","Player Missile Cr.","Maverick"},
			{"Crucible","Maverick","Phobos M3P","Flavia P.Falcon","MP52 Hornet","Player Missile Cr.","Maverick","Phobos M3P","Crucible","MP52 Hornet","Player Missile Cr.","Flavia P.Falcon","Player Missile Cr.","Maverick","Crucible"},
			{"Crucible","Maverick","Phobos M3P","Flavia P.Falcon","MP52 Hornet","Player Missile Cr.","Maverick","Phobos M3P","Crucible","MP52 Hornet","Player Missile Cr.","Flavia P.Falcon","Player Missile Cr.","Maverick","Crucible","Phobos M3P"},
		},
		["Heavy"] = {
			{"Maverick"},
			{"Maverick","Crucible"},
			{"Maverick","Crucible","Atlantis"},
			{"Maverick","Crucible","Atlantis","Player Missile Cr."},
			{"Maverick","Crucible","Atlantis","Player Missile Cr.","Player Cruiser"},
			{"Maverick","Crucible","Atlantis","Player Missile Cr.","Player Cruiser","Piranha"},
			{"Maverick","Crucible","Atlantis","Player Missile Cr.","Player Cruiser","Piranha","Maverick"},
			{"Maverick","Crucible","Atlantis","Player Missile Cr.","Player Cruiser","Piranha","Maverick","Player Missile Cr."},
			{"Maverick","Crucible","Atlantis","Player Missile Cr.","Player Cruiser","Piranha","Maverick","Player Missile Cr.","Atlantis"},
			{"Maverick","Crucible","Atlantis","Player Missile Cr.","Player Cruiser","Piranha","Maverick","Player Missile Cr.","Atlantis","Crucible"},
			{"Maverick","Crucible","Atlantis","Player Missile Cr.","Player Cruiser","Piranha","Maverick","Player Missile Cr.","Atlantis","Crucible","Player Cruiser"},
			{"Maverick","Crucible","Atlantis","Player Missile Cr.","Player Cruiser","Piranha","Maverick","Player Missile Cr.","Atlantis","Crucible","Player Cruiser","Piranha"},
			{"Maverick","Crucible","Atlantis","Player Missile Cr.","Player Cruiser","Piranha","Maverick","Player Missile Cr.","Atlantis","Crucible","Player Cruiser","Piranha","Crucible"},
			{"Maverick","Crucible","Atlantis","Player Missile Cr.","Player Cruiser","Piranha","Maverick","Player Missile Cr.","Atlantis","Crucible","Player Cruiser","Piranha","Crucible","Atlantis"},
			{"Maverick","Crucible","Atlantis","Player Missile Cr.","Player Cruiser","Piranha","Maverick","Player Missile Cr.","Atlantis","Crucible","Player Cruiser","Piranha","Crucible","Atlantis","Maverick"},
			{"Maverick","Crucible","Atlantis","Player Missile Cr.","Player Cruiser","Piranha","Maverick","Player Missile Cr.","Atlantis","Crucible","Player Cruiser","Piranha","Crucible","Atlantis","Maverick","Player Missile Cr."},
		},
		["Light"] = {
			{"Phobos M3P"},
			{"Phobos M3P","MP52 Hornet"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon","Hathcock"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon","Hathcock","Nautilus"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon","Hathcock","Nautilus","Repulse"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon","Hathcock","Nautilus","Repulse","Flavia P. Falcon"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon","Hathcock","Nautilus","Repulse","Flavia P. Falcon","MP52 Hornet"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon","Hathcock","Nautilus","Repulse","Flavia P. Falcon","MP52 Hornet","Phobos M3P"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon","Hathcock","Nautilus","Repulse","Flavia P. Falcon","MP52 Hornet","Phobos M3P","Repulse"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon","Hathcock","Nautilus","Repulse","Flavia P. Falcon","MP52 Hornet","Phobos M3P","Repulse","Hathcock"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon","Hathcock","Nautilus","Repulse","Flavia P. Falcon","MP52 Hornet","Phobos M3P","Repulse","Hathcock","Nautilus"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon","Hathcock","Nautilus","Repulse","Flavia P. Falcon","MP52 Hornet","Phobos M3P","Repulse","Hathcock","Nautilus","Flavia P. Falcon"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon","Hathcock","Nautilus","Repulse","Flavia P. Falcon","MP52 Hornet","Phobos M3P","Repulse","Hathcock","Nautilus","Flavia P. Falcon","Phobos M3P"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon","Hathcock","Nautilus","Repulse","Flavia P. Falcon","MP52 Hornet","Phobos M3P","Repulse","Hathcock","Nautilus","Flavia P. Falcon","Phobos M3P","MP52 Hornet"},
			{"Phobos M3P","MP52 Hornet","Flavia P.Falcon","Hathcock","Nautilus","Repulse","Flavia P. Falcon","MP52 Hornet","Phobos M3P","Repulse","Hathcock","Nautilus","Flavia P. Falcon","Phobos M3P","MP52 Hornet","Repulse"},
		},
		["Custom"] = {
			{"Holmes"},
			{"Holmes","Phobos T2"},
			{"Holmes","Phobos T2","Striker LX"},
			{"Holmes","Phobos T2","Striker LX","Maverick XP"},
			{"Holmes","Phobos T2","Striker LX","Maverick XP","Focus"},
			{"Holmes","Phobos T2","Striker LX","Maverick XP","Focus","Repulse"},
			{"Holmes","Phobos T2","Striker LX","Maverick XP","Focus","Repulse","Flavia P. Falcon"},
			{"Holmes","Phobos T2","Striker LX","Maverick XP","Focus","Repulse","Flavia P. Falcon","Player Fighter"},
			{"Holmes","Phobos T2","Striker LX","Maverick XP","Focus","Repulse","Flavia P. Falcon","Player Fighter","Phobos M3P"},
			{"Holmes","Phobos T2","Striker LX","Maverick XP","Focus","Repulse","Flavia P. Falcon","Player Fighter","Phobos M3P","Repulse"},
			{"Holmes","Phobos T2","Striker LX","Maverick XP","Focus","Repulse","Flavia P. Falcon","Player Fighter","Phobos M3P","Repulse","Hathcock"},
			{"Holmes","Phobos T2","Striker LX","Maverick XP","Focus","Repulse","Flavia P. Falcon","Player Fighter","Phobos M3P","Repulse","Hathcock","Nautilus"},
			{"Holmes","Phobos T2","Striker LX","Maverick XP","Focus","Repulse","Flavia P. Falcon","Player Fighter","Phobos M3P","Repulse","Hathcock","Nautilus","Flavia P. Falcon"},
			{"Holmes","Phobos T2","Striker LX","Maverick XP","Focus","Repulse","Flavia P. Falcon","Player Fighter","Phobos M3P","Repulse","Hathcock","Nautilus","Flavia P. Falcon","Phobos M3P"},
			{"Holmes","Phobos T2","Striker LX","Maverick XP","Focus","Repulse","Flavia P. Falcon","Player Fighter","Phobos M3P","Repulse","Hathcock","Nautilus","Flavia P. Falcon","Phobos M3P","MP52 Hornet"},
			{"Holmes","Phobos T2","Striker LX","Maverick XP","Focus","Repulse","Flavia P. Falcon","Player Fighter","Phobos M3P","Repulse","Hathcock","Nautilus","Flavia P. Falcon","Phobos M3P","MP52 Hornet","Repulse"},
		}
	}
	rwc_player_ship_names = {	--rwc: random within category
		["Atlantis"] = {"Formidable","Thrasher","Punisher","Vorpal","Protang","Drummond","Parchim","Coronado"},
		["Benedict"] = {"Elizabeth","Ford","Avenger","Washington","Lincoln","Garibaldi","Eisenhower"},
		["Crucible"] = {"Sling", "Stark", "Torrid", "Kicker", "Flummox"},
		["Ender"] = {"Mongo","Godzilla","Leviathan","Kraken","Jupiter","Saturn"},
		["Flavia P.Falcon"] = {"Ladyhawke","Hunter","Seeker","Gyrefalcon","Kestrel","Magpie","Bandit","Buccaneer"},
		["Hathcock"] = {"Hayha", "Waldron", "Plunkett", "Mawhinney", "Furlong", "Zaytsev", "Pavlichenko", "Fett", "Hawkeye", "Hanzo"},
		["Kiriya"] = {"Cavour","Reagan","Gaulle","Paulo","Truman","Stennis","Kuznetsov","Roosevelt","Vinson","Old Salt"},
		["MP52 Hornet"] = {"Dragonfly","Scarab","Mantis","Yellow Jacket","Jimminy","Flik","Thorny","Buzz"},
		["Maverick"] = {"Angel", "Thunderbird", "Roaster", "Magnifier", "Hedge"},
		["Nautilus"] = {"October", "Abdiel", "Manxman", "Newcon", "Nusret", "Pluton", "Amiral", "Amur", "Heinkel", "Dornier"},
		["Phobos M3P"] = {"Blinder","Shadow","Distortion","Diemos","Ganymede","Castillo","Thebe","Retrograde"},
		["Piranha"] = {"Razor","Biter","Ripper","Voracious","Carnivorous","Characid","Vulture","Predator"},
		["Player Cruiser"] = {"Excelsior","Velociraptor","Thunder","Kona","Encounter","Perth","Aspern","Panther"},
		["Player Fighter"] = {"Buzzer","Flitter","Zippiticus","Hopper","Molt","Stinger","Stripe"},
		["Player Missile Cr."] = {"Projectus","Hurlmeister","Flinger","Ovod","Amatola","Nakhimov","Antigone"},
		["Repulse"] = {"Fiddler","Brinks","Loomis","Mowag","Patria","Pandur","Terrex","Komatsu","Eitan"},
		["Striker"] = {"Sparrow","Sizzle","Squawk","Crow","Snowbird","Hawk"},
		["ZX-Lindworm"]	= {"Seagull","Catapult","Blowhard","Flapper","Nixie","Pixie","Tinkerbell"},
		["Unknown"] = {
			"Foregone",
			"Righteous",
			"Masher",
			"Lancer",
			"Horizon",
			"Osiris",
			"Athena",
			"Poseidon",
			"Heracles",
			"Constitution",
			"Stargazer",
			"Horatio",
			"Socrates",
			"Galileo",
			"Newton",
			"Beethoven",
			"Rabin",
			"Spector",
			"Akira",
			"Thunderchild",
			"Ambassador",
			"Adelphi",
			"Exeter",
			"Ghandi",
			"Valdemar",
			"Yamaguchi",
			"Zhukov",
			"Andromeda",
			"Drake",
			"Prokofiev",
			"Antares",
			"Apollo",
			"Ajax",
			"Clement",
			"Bradbury",
			"Gage",
			"Buran",
			"Kearsarge",
--			"Cheyenne",
			"Ahwahnee",
			"Constellation",
			"Gettysburg",
			"Hathaway",
			"Magellan",
			"Farragut",
			"Kongo",
			"Lexington",
			"Potempkin",
			"Yorktown",
			"Daedalus",
			"Archon",
			"Carolina",
			"Essex",
			"Danube",
			"Gander",
			"Ganges",
			"Mekong",
			"Orinoco",
			"Rubicon",
			"Shenandoah",
			"Volga",
			"Yangtzee Kiang",
			"Yukon",
			"Valiant",
			"Deneva",
			"Arcos",
			"LaSalle",
			"Al-Batani",
			"Cairo",
			"Charlseton",
			"Crazy Horse",
			"Crockett",
			"Fearless",
			"Fredrickson",
--			"Gorkon",
			"Hood",
			"Lakota",
			"Malinche",
			"Melbourne",
			"Freedom",
			"Concorde",
--			"Firebrand",
			"Galaxy",
			"Challenger",
			"Odyssey",
			"Trinculo",
			"Venture",
			"Yamato",
			"Hokule'a",
			"Tripoli",
			"Hope",
			"Nobel",
			"Pasteur",
			"Bellerophon",
			"Voyager",
			"Istanbul",
			"Constantinople",
			"Havana",
			"Sarajevo",
			"Korolev",
			"Goddard",
			"Luna",
			"Titan",
			"Mediterranean",
			"Lalo",
			"Wyoming",
			"Merced",
			"Trieste",
			"Miranda",
			"Brattain",
			"Helin",
			"Lantree",
			"Majestic",
			"Reliant",
			"Saratoga",
			"ShirKahr",
			"Sitak",
			"Tian An Men",
			"Trial",
			"Nebula",
			"Bonchune",
			"Capricorn",
			"Hera",
			"Honshu",
			"Interceptor",
			"Leeds",
			"Merrimack",
			"Prometheus",
			"Proxima",
			"Sutherland",
			"T'Kumbra",
			"Ulysses",
			"New Orleans",
			"Kyushu",
			"Renegade",
			"Rutledge",
			"Thomas Paine",
			"Niagra",
			"Princeton",
			"Wellington",
			"Norway",
			"Budapest",
			"Nova",
			"Equinox",
			"Rhode Island",
			"Columbia",
			"Oberth",
			"Biko",
			"Cochraine",
			"Copernicus",
			"Grissom",
			"Pegasus",
			"Raman",
			"Yosemite",
			"Renaissance",
			"Aries",
			"Maryland",
			"Rigel",
			"Akagi",
			"Tolstoy",
			"Yeager",
			"Sequoia",
			"Sovereign",
			"Soyuz",
			"Bozeman",
			"Springfield",
			"Chekov",
			"Steamrunner",
			"Appalachia",
			"Surak",
			"Zapata",
			"Sydney",
			"Jenolen",
			"Nash",
			"Wambundu",
			"Fleming",
			"Wells",
			"Relativity",
			"Yorkshire",
			"Denver",
			"Zodiac",
			"Centaur",
			"Cortez",
			"Republic",
			"Peregrine",
			"Calypso",
			"Cousteau",
			"Waverider",
			"Scimitar",
		},
	}
	player_ship_stats = {	
		["Atlantis"]			= { strength = 52,	cargo = 6,	distance = 400,	long_range_radar = 30000, short_range_radar = 5000, probes = 10,	long_jump = 50,	short_jump = 5,		warp = 0,		stock = true,	},
		["Benedict"]			= { strength = 10,	cargo = 9,	distance = 400,	long_range_radar = 30000, short_range_radar = 5000, probes = 10,	long_jump = 90,	short_jump = 5,		warp = 0,		stock = true,	},
		["Crucible"]			= { strength = 45,	cargo = 5,	distance = 200,	long_range_radar = 20000, short_range_radar = 6000, probes = 9,		long_jump = 0,	short_jump = 0,		warp = 750,		stock = true,	},
		["Ender"]				= { strength = 100,	cargo = 20,	distance = 2000,long_range_radar = 45000, short_range_radar = 7000, probes = 12,	long_jump = 50,	short_jump = 5,		warp = 0,		stock = true,	},
		["Flavia P.Falcon"]		= { strength = 13,	cargo = 15,	distance = 200,	long_range_radar = 40000, short_range_radar = 5000, probes = 8,		long_jump = 0,	short_jump = 0,		warp = 500,		stock = true,	},
		["Hathcock"]			= { strength = 30,	cargo = 6,	distance = 200,	long_range_radar = 35000, short_range_radar = 6000, probes = 8,		long_jump = 60,	short_jump = 6,		warp = 0,		stock = true,	},
		["Kiriya"]				= { strength = 10,	cargo = 9,	distance = 400,	long_range_radar = 35000, short_range_radar = 5000, probes = 10,	long_jump = 0,	short_jump = 0,		warp = 750,		stock = true,	},
		["Maverick"]			= { strength = 45,	cargo = 5,	distance = 200,	long_range_radar = 20000, short_range_radar = 4000, probes = 9,		long_jump = 0,	short_jump = 0,		warp = 800,		stock = true,	},
		["MP52 Hornet"] 		= { strength = 7, 	cargo = 3,	distance = 100,	long_range_radar = 18000, short_range_radar = 4000, probes = 5,		long_jump = 0,	short_jump = 0,		warp = 1000,	stock = true,	},
		["Nautilus"]			= { strength = 12,	cargo = 7,	distance = 200,	long_range_radar = 22000, short_range_radar = 4000, probes = 10,	long_jump = 70,	short_jump = 5,		warp = 0,		stock = true,	},
		["Phobos M3P"]			= { strength = 19,	cargo = 10,	distance = 200,	long_range_radar = 25000, short_range_radar = 5000, probes = 6,		long_jump = 0,	short_jump = 0,		warp = 900,		stock = true,	},
		["Piranha"]				= { strength = 16,	cargo = 8,	distance = 200,	long_range_radar = 25000, short_range_radar = 6000, probes = 6,		long_jump = 50,	short_jump = 5,		warp = 0,		stock = true,	},
		["Player Cruiser"]		= { strength = 40,	cargo = 6,	distance = 400,	long_range_radar = 30000, short_range_radar = 5000, probes = 10,	long_jump = 80,	short_jump = 5,		warp = 0,		stock = true,	},
		["Player Missile Cr."]	= { strength = 45,	cargo = 8,	distance = 200,	long_range_radar = 35000, short_range_radar = 6000, probes = 9,		long_jump = 0,	short_jump = 0,		warp = 800,		stock = true,	},
		["Player Fighter"]		= { strength = 7,	cargo = 3,	distance = 100,	long_range_radar = 15000, short_range_radar = 4500, probes = 4,		long_jump = 40,	short_jump = 3,		warp = 0,		stock = true,	},
		["Repulse"]				= { strength = 14,	cargo = 12,	distance = 200,	long_range_radar = 38000, short_range_radar = 5000, probes = 8,		long_jump = 50,	short_jump = 5,		warp = 0,		stock = true,	},
		["Striker"]				= { strength = 8,	cargo = 4,	distance = 200,	long_range_radar = 35000, short_range_radar = 5000, probes = 6,		long_jump = 40,	short_jump = 3,		warp = 0,		stock = true,	},
		["ZX-Lindworm"]			= { strength = 8,	cargo = 3,	distance = 100,	long_range_radar = 18000, short_range_radar = 5500, probes = 4,		long_jump = 0,	short_jump = 0,		warp = 950,		stock = true,	},
	--	Stock above, custom below	
		["Focus"]				= { strength = 35,	cargo = 4,	distance = 200,	long_range_radar = 32000, short_range_radar = 5000, probes = 8,		long_jump = 25,	short_jump = 2.5,	warp = 0,		stock = false,	},
		["Holmes"]				= { strength = 35,	cargo = 6,	distance = 200,	long_range_radar = 35000, short_range_radar = 4000, probes = 8,		long_jump = 0,	short_jump = 0,		warp = 750,		stock = false,	},
		["Maverick XP"]			= { strength = 23,	cargo = 5,	distance = 200,	long_range_radar = 25000, short_range_radar = 7000, probes = 10,	long_jump = 20,	short_jump = 2,		warp = 0,		stock = false,	},
		["Phobos T2"]			= { strength = 19,	cargo = 9,	distance = 200,	long_range_radar = 25000, short_range_radar = 5000, probes = 5,		long_jump = 25,	short_jump = 2,		warp = 0,		stock = false,	},
		["Striker LX"]			= { strength = 16,	cargo = 4,	distance = 200,	long_range_radar = 20000, short_range_radar = 4000, probes = 7,		long_jump = 20,	short_jump = 2,		warp = 0,		stock = false,	},
	}		
	npc_ships = false
	npc_lower = 30
	npc_upper = 60
	scientist_list = {}
	scientist_count = 0
	scientist_score_value = 10
	scientist_names = {	--fictional
		"Gertrude Goodall",
		"John Kruger",
		"Lisa Forsythe",
		"Ethan Williams",
		"Ameilia Martinez",
		"Felix Mertens",
		"Marie Novak",
		"Mathias Evans",
		"Clara Heikkinen",
		"Vicente Martin",
		"Catalina Fischer",
		"Marek Varga",
		"Ewa Olsen",
		"Oscar Stewart",
		"Alva Rodriguez",
		"Aiden Johansson",
		"Zoey Smith",
		"Jorge Romero",
		"Rosa Wong",
		"Julian Acharya",
		"Hannah Ginting",
		"Anton Dewala",
		"Camille Silva",
		"Aleksi Gideon",
		"Ella Dasgupta",
		"Gunnar Smirnov",
		"Telma Lozano",
		"Kaito Fabroa",
		"Misaki Kapia",
		"Ronald Sanada",
		"Janice Tesfaye",
		"Alvaro Hassan",
		"Valeria Dinh",
		"Sergei Mokri",
		"Yulia Karga",
		"Arnav Dixon",
		"Sanvi Saetan",
	}
	scientist_topics = {
		"Mathematics",
		"Miniaturization",
		"Exotic materials",
		"Warp theory",
		"Particle theory",
		"Power systems",
		"Energy fields",
		"Subatomic physics",
		"Stellar phenomena",
		"Gravity dynamics",
		"Information science",
		"Computer protocols",
	}
	upgrade_requirements = {
		"talk",			--talk
		"talk primary",	--talk then upgrade at primary station
		"meet",			--meet
		"meet primary",	--meet then upgrade at primary station
		"transport",	--transport to primary station
		"confer",		--transport to primary station, then confer with another scientist
	}
	upgrade_list = {
		{action = hullStrengthUpgrade,		name = _("station-comms","hull strength upgrade")},
		{action = shieldStrengthUpgrade,	name = _("station-comms","shield strength upgrade")},
		{action = missileLoadSpeedUpgrade,	name = _("station-comms","missile load speed upgrade")},
		{action = beamDamageUpgrade,		name = _("station-comms","beam damage upgrade")},
		{action = beamRangeUpgrade,			name = _("station-comms","beam range upgrade")},
		{action = batteryEfficiencyUpgrade,	name = _("station-comms","battery efficiency upgrade")},
		{action = fasterImpulseUpgrade,		name = _("station-comms","faster impulse upgrade")},
		{action = longerSensorsUpgrade,		name = _("station-comms","longer sensor range upgrade")},
		{action = fasterSpinUpgrade,		name = _("station-comms","faster maneuvering speed upgrade")},
	}
	upgrade_automated_applications = {
		"single",	--automatically applied only to the player that completed the requirements
		"players",	--automatically applied to allied players
		"all",		--automatically applied to players and NPCs (where applicable)
	}
	prefix_length = 0
	suffix_index = 0
	formation_delta = {
		["square"] = {
			x = {0,1,0,-1, 0,1,-1, 1,-1,2,0,-2, 0,2,-2, 2,-2,2, 2,-2,-2,1,-1, 1,-1,0, 0,3,-3,1, 1,3,-3,-1,-1, 3,-3,2, 2,3,-3,-2,-2, 3,-3,3, 3,-3,-3,4,0,-4, 0,4,-4, 4,-4,-4,-4,-4,-4,-4,-4,4, 4,4, 4,4, 4, 1,-1, 2,-2, 3,-3,1,-1,2,-2,3,-3,5,-5,0, 0,5, 5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,5, 5,5, 5,5, 5,5, 5, 1,-1, 2,-2, 3,-3, 4,-4,1,-1,2,-2,3,-3,4,-4},
			y = {0,0,1, 0,-1,1,-1,-1, 1,0,2, 0,-2,2,-2,-2, 2,1,-1, 1,-1,2, 2,-2,-2,3,-3,0, 0,3,-3,1, 1, 3,-3,-1,-1,3,-3,2, 2, 3,-3,-2,-2,3,-3, 3,-3,0,4, 0,-4,4,-4,-4, 4, 1,-1, 2,-2, 3,-3,1,-1,2,-2,3,-3,-4,-4,-4,-4,-4,-4,4, 4,4, 4,4, 4,0, 0,5,-5,5,-5, 5,-5, 1,-1, 2,-2, 3,-3, 4,-4,1,-1,2,-2,3,-3,4,-4,-5,-5,-5,-5,-5,-5,-5,-5,5, 5,5, 5,5, 5,5, 5},
		},
		["hexagonal"] = {
			x = {0,2,-2,1,-1, 1,-1,4,-4,0, 0,2,-2,-2, 2,3,-3, 3,-3,6,-6,1,-1, 1,-1,3,-3, 3,-3,4,-4, 4,-4,5,-5, 5,-5,8,-8,4,-4, 4,-4,5,5 ,-5,-5,2, 2,-2,-2,0, 0,6, 6,-6,-6,7, 7,-7,-7,10,-10,5, 5,-5,-5,6, 6,-6,-6,7, 7,-7,-7,8, 8,-8,-8,9, 9,-9,-9,3, 3,-3,-3,1, 1,-1,-1,12,-12,6,-6, 6,-6,7,-7, 7,-7,8,-8, 8,-8,9,-9, 9,-9,10,-10,10,-10,11,-11,11,-11,4,-4, 4,-4,2,-2, 2,-2,0, 0},
			y = {0,0, 0,1, 1,-1,-1,0, 0,2,-2,2,-2, 2,-2,1,-1,-1, 1,0, 0,3, 3,-3,-3,3,-3,-3, 3,2,-2,-2, 2,1,-1,-1, 1,0, 0,4,-4,-4, 4,3,-3, 3,-3,4,-4, 4,-4,4,-4,2,-2, 2,-2,1,-1, 1,-1, 0,  0,5,-5, 5,-5,4,-4, 4,-4,3,-3, 3,-7,2,-2, 2,-2,1,-1, 1,-1,5,-5, 5,-5,5,-5, 5,-5, 0,  0,6, 6,-6,-6,5, 5,-5,-5,4, 4,-4,-4,3, 3,-3,-3, 2,  2,-2, -2, 1,  1,-1, -1,6, 6,-6,-6,6, 6,-6,-6,6,-6},
		},
	}	
	fleet_group = {
		["adder"] = "Adders",
		["Adders"] = "adder",
		["missiler"] = "Missilers",
		["Missilers"] = "missiler",
		["beamer"] = "Beamers",
		["Beamers"] = "beamer",
		["frigate"] = "Frigates",
		["Frigates"] = "frigate",
		["chaser"] = "Chasers",
		["Chasers"] = "chaser",
		["fighter"] = "Fighters",
		["Fighters"] = "fighter",
		["drone"] = "Drones",
		["Drones"] = "drone",
	}	
	ship_template = {	--ordered by relative strength
		["Gnat"] =				{strength = 2,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = true,		drone = true,	unusual = false,	base = false,	create = gnat},
		["Lite Drone"] =		{strength = 3,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = true, 	drone = true,	unusual = false,	base = false,	create = droneLite},
		["Jacket Drone"] =		{strength = 4,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = true, 	drone = true,	unusual = false,	base = false,	create = droneJacket},
		["Ktlitan Drone"] =		{strength = 4,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = true, 	drone = true,	unusual = false,	base = false,	create = stockTemplate},
		["Heavy Drone"] =		{strength = 5,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = true, 	drone = true,	unusual = false,	base = false,	create = droneHeavy},
		["Adder MK3"] =			{strength = 5,	adder = true,	missiler = false,	beamer = false,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["MT52 Hornet"] =		{strength = 5,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = true, 	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["MU52 Hornet"] =		{strength = 5,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = true, 	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["MV52 Hornet"] =		{strength = 6,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = true, 	drone = false,	unusual = false,	base = false,	create = hornetMV52},
		["Adder MK4"] =			{strength = 6,	adder = true,	missiler = false,	beamer = false,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Fighter"] =			{strength = 6,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = true, 	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Ktlitan Fighter"] =	{strength = 6,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = true, 	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["K2 Fighter"] =		{strength = 7,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = true, 	drone = false,	unusual = false,	base = false,	create = k2fighter},
		["Adder MK5"] =			{strength = 7,	adder = true,	missiler = false,	beamer = false,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["WX-Lindworm"] =		{strength = 7,	adder = false,	missiler = true,	beamer = false,	frigate = false,	chaser = false,	fighter = true, 	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["K3 Fighter"] =		{strength = 8,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = true, 	drone = false,	unusual = false,	base = false,	create = k3fighter},
		["Adder MK6"] =			{strength = 8,	adder = true,	missiler = false,	beamer = false,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Ktlitan Scout"] =		{strength = 8,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["WZ-Lindworm"] =		{strength = 9,	adder = false,	missiler = true,	beamer = false,	frigate = false,	chaser = false,	fighter = true, 	drone = false,	unusual = false,	base = false,	create = wzLindworm},
		["Adder MK7"] =			{strength = 9,	adder = true,	missiler = false,	beamer = false,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Adder MK8"] =			{strength = 10,	adder = true,	missiler = false,	beamer = false,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Adder MK9"] =			{strength = 11,	adder = true,	missiler = false,	beamer = false,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Nirvana R3"] =		{strength = 12,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Phobos R2"] =			{strength = 13,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = phobosR2},
		["Missile Cruiser"] =	{strength = 14,	adder = false,	missiler = true,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Waddle 5"] =			{strength = 15,	adder = true,	missiler = false,	beamer = false,	frigate = false,	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = waddle5},
		["Jade 5"] =			{strength = 15,	adder = true,	missiler = false,	beamer = false,	frigate = false,	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = jade5},
		["Phobos T3"] =			{strength = 15,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Piranha F8"] =		{strength = 15,	adder = false,	missiler = true,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Piranha F12"] =		{strength = 15,	adder = false,	missiler = true,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Piranha F12.M"] =		{strength = 16,	adder = false,	missiler = true,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Phobos M3"] =			{strength = 16,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Farco 3"] =			{strength = 16,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = farco3},
		["Farco 5"] =			{strength = 16,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = farco5},
		["Karnack"] =			{strength = 17,	adder = false,	missiler = false,	beamer = true,	frigate = true,		chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Gunship"] =			{strength = 17,	adder = false,	missiler = false,	beamer = false,	frigate = true,		chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Phobos T4"] =			{strength = 18,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = phobosT4},
		["Cruiser"] =			{strength = 18,	adder = true,	missiler = false,	beamer = true,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Nirvana R5"] =		{strength = 19,	adder = false,	missiler = false,	beamer = true,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Farco 8"] =			{strength = 19,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = farco8},
		["Ktlitan Worker"] =	{strength = 20,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Nirvana R5A"] =		{strength = 20,	adder = false,	missiler = false,	beamer = true,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Adv. Gunship"] =		{strength = 20,	adder = false,	missiler = false,	beamer = false,	frigate = true,		chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Farco 11"] =			{strength = 21,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = farco11},
		["Storm"] =				{strength = 22,	adder = false,	missiler = true,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Stalker R5"] =		{strength = 22,	adder = false,	missiler = false,	beamer = true,	frigate = true, 	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Stalker Q5"] =		{strength = 22,	adder = false,	missiler = false,	beamer = true,	frigate = true, 	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Farco 13"] =			{strength = 24,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = farco13},
		["Ranus U"] =			{strength = 25,	adder = false,	missiler = true,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Stalker Q7"] =		{strength = 25,	adder = false,	missiler = false,	beamer = true,	frigate = true, 	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Stalker R7"] =		{strength = 25,	adder = false,	missiler = false,	beamer = true,	frigate = true, 	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Whirlwind"] =			{strength = 26,	adder = false,	missiler = true,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = whirlwind},
		["Adv. Striker"] =		{strength = 27,	adder = false,	missiler = false,	beamer = true,	frigate = true,		chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Elara P2"] =			{strength = 28,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Tempest"] =			{strength = 30,	adder = false,	missiler = true,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = tempest},
		["Strikeship"] =		{strength = 30,	adder = false,	missiler = false,	beamer = true,	frigate = true, 	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Fiend G3"] =			{strength = 33,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Fiend G4"] =			{strength = 35,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Cucaracha"] =			{strength = 36,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = cucaracha},
		["Fiend G5"] =			{strength = 37,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Fiend G6"] =			{strength = 39,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Predator"] =			{strength = 42,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = predator},
		["Ktlitan Breaker"] =	{strength = 45,	adder = false,	missiler = false,	beamer = false,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Hurricane"] =			{strength = 46,	adder = false,	missiler = true,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = hurricane},
		["Ktlitan Feeder"] =	{strength = 48,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Atlantis X23"] =		{strength = 50,	adder = false,	missiler = false,	beamer = false,	frigate = false,	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["K2 Breaker"] =		{strength = 55,	adder = false,	missiler = false,	beamer = false,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = k2breaker},
		["Ktlitan Destroyer"] =	{strength = 50,	adder = false,	missiler = false,	beamer = false,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Atlantis Y42"] =		{strength = 60,	adder = false,	missiler = false,	beamer = false,	frigate = false,	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = atlantisY42},
		["Blockade Runner"] =	{strength = 65,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Starhammer II"] =		{strength = 70,	adder = false,	missiler = false,	beamer = false,	frigate = false,	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Enforcer"] =			{strength = 75,	adder = false,	missiler = false,	beamer = false,	frigate = true, 	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = enforcer},
		["Dreadnought"] =		{strength = 80,	adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = false,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Starhammer III"] =	{strength = 85,	adder = false,	missiler = false,	beamer = false,	frigate = false,	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = starhammerIII},
		["Starhammer V"] =		{strength = 90,	adder = false,	missiler = false,	beamer = false,	frigate = false,	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = starhammerV},
		["Battlestation"] =		{strength = 100,adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
		["Tyr"] =				{strength = 150,adder = false,	missiler = false,	beamer = true,	frigate = false,	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = tyr},
		["Odin"] =				{strength = 250,adder = false,	missiler = false,	beamer = false,	frigate = false,	chaser = true,	fighter = false,	drone = false,	unusual = false,	base = false,	create = stockTemplate},
	}	
	control_code_stem = {	--All control codes must use capital letters or they will not work.
		"ALWAYS",
		"BLACK",
		"BLUE",
		"BRIGHT",
		"BROWN",
		"CHAIN",
		"CHURCH",
		"DOORWAY",
		"DULL",
		"ELBOW",
		"EMPTY",
		"EPSILON",
		"FLOWER",
		"FLY",
		"FROZEN",
		"GREEN",
		"GLOW",
		"HAMMER",
		"HORIZON",
		"INK",
		"JUMP",
		"KEY",
		"LETTER",
		"LIST",
		"MORNING",
		"NEXT",
		"OPEN",
		"ORANGE",
		"OUTSIDE",
		"PURPLE",
		"QUARTER",
		"QUIET",
		"RED",
		"SHINE",
		"SIGMA",
		"STAR",
		"STARSHIP",
		"STREET",
		"TOKEN",
		"THIRSTY",
		"UNDER",
		"VANISH",
		"WHITE",
		"WRENCH",
		"YELLOW",
	}
	healthCheckTimerInterval = 10
	healthCheckTimer = healthCheckTimerInterval
	commonGoods = {"food","medicine","nickel","platinum","gold","dilithium","tritanium","luxury","cobalt","impulse","warp","shield","tractor","repulsor","beam","optic","robotic","filament","transporter","sensor","communication","autodoc","lifter","android","nanites","software","circuit","battery"}
	componentGoods = {"impulse","warp","shield","tractor","repulsor","beam","optic","robotic","filament","transporter","sensor","communication","autodoc","lifter","android","nanites","software","circuit","battery"}
	mineralGoods = {"nickel","platinum","gold","dilithium","tritanium","cobalt"}	
	good_desc = {
		["food"] =			_("trade-comms","food"),
		["medicine"] =		_("trade-comms","medicine"),
		["luxury"] =		_("trade-comms","luxury"),
		["cobalt"] =		_("trade-comms","cobalt"),
		["dilithium"] =		_("trade-comms","dilithium"),
		["gold"] =			_("trade-comms","gold"),
		["nickel"] =		_("trade-comms","nickel"),
		["platinum"] =		_("trade-comms","platinum"),
		["tritanium"] =		_("trade-comms","tritanium"),
		["autodoc"] =		_("trade-comms","autodoc"),
		["android"] =		_("trade-comms","android"),
		["battery"] =		_("trade-comms","battery"),
		["beam"] =			_("trade-comms","beam"),
		["circuit"] =		_("trade-comms","circuit"),
		["communication"] =	_("trade-comms","communication"),
		["filament"] =		_("trade-comms","filament"),
		["impulse"] =		_("trade-comms","impulse"),
		["lifter"] =		_("trade-comms","lifter"),
		["nanites"] =		_("trade-comms","nanites"),
		["optic"] =			_("trade-comms","optic"),
		["repulsor"] =		_("trade-comms","repulsor"),
		["robotic"] =		_("trade-comms","robotic"),
		["sensor"] =		_("trade-comms","sensor"),
		["shield"] =		_("trade-comms","shield"),
		["software"] =		_("trade-comms","software"),
		["tractor"] =		_("trade-comms","tractor"),
		["transporter"] =	_("trade-comms","transporter"),
		["warp"] =			_("trade-comms","warp"),
	}
end
function setStaticScienceDatabase()
--------------------------------------------------------------------------------------
--	Generic station descriptions: text and details from shipTemplates_stations.lua  --
--------------------------------------------------------------------------------------
	local station_db = queryScienceDatabase("Stations")
	if station_db == nil then
		station_db = ScienceDatabase():setName("Stations")
		station_db:setLongDescription("Stations are places for ships to dock, get repaired and replenished, interact with station personnel, etc. They are like oases, service stations, villages, towns, cities, etc.")
		station_db:addEntry("Small")
		local small_station_db = queryScienceDatabase("Stations","Small")
		small_station_db:setLongDescription("Stations of this size are often used as research outposts, listening stations, and security checkpoints. Crews turn over frequently in a small station's cramped accommodatations, but they are small enough to look like ships on many long-range sensors, and organized raiders sometimes take advantage of this by placing small stations in nebulae to serve as raiding bases. They are lightly shielded and vulnerable to swarming assaults.")
		small_station_db:setImage("smallstation.png")
		small_station_db:setKeyValue("Class","Small")
		small_station_db:setKeyValue("Size",300)
		small_station_db:setKeyValue("Shield",300)
		small_station_db:setKeyValue("Hull",150)
		station_db:addEntry("Medium")
		local medium_station_db = queryScienceDatabase("Stations","Medium")
		medium_station_db:setLongDescription("Large enough to accommodate small crews for extended periods of times, stations of this size are often trading posts, refuelling bases, mining operations, and forward military bases. While their shields are strong, concerted attacks by many ships can bring them down quickly.")
		medium_station_db:setImage("mediumstation.png")
		medium_station_db:setKeyValue("Class","Medium")
		medium_station_db:setKeyValue("Size",1000)
		medium_station_db:setKeyValue("Shield",800)
		medium_station_db:setKeyValue("Hull",400)
		station_db:addEntry("Large")
		local large_station_db = queryScienceDatabase("Stations","Large")
		large_station_db:setLongDescription("These spaceborne communities often represent permanent bases in a sector. Stations of this size can be military installations, commercial hubs, deep-space settlements, and small shipyards. Only a concentrated attack can penetrate a large station's shields, and its hull can withstand all but the most powerful weaponry.")
		large_station_db:setImage("largestation.png")
		large_station_db:setKeyValue("Class","Large")
		large_station_db:setKeyValue("Size",1300)
		large_station_db:setKeyValue("Shield","1000/1000/1000")
		large_station_db:setKeyValue("Hull",500)
		station_db:addEntry("Huge")
		local huge_station_db = queryScienceDatabase("Stations","Huge")
		huge_station_db:setLongDescription("The size of a sprawling town, stations at this scale represent a faction's center of spaceborne power in a region. They serve many functions at once and represent an extensive investment of time, money, and labor. A huge station's shields and thick hull can keep it intact long enough for reinforcements to arrive, even when faced with an ongoing siege or massive, perfectly coordinated assault.")
		huge_station_db:setImage("hugestation.png")
		huge_station_db:setKeyValue("Class","Huge")
		huge_station_db:setKeyValue("Size",1500)
		huge_station_db:setKeyValue("Shield","1200/1200/1200/1200")
		huge_station_db:setKeyValue("Hull",800)
	end
-----------------------------------------------------------------------------------
--	Template ship category descriptions: text from other shipTemplates... files  --
-----------------------------------------------------------------------------------
	local ships_db = queryScienceDatabase("Ships")
	if ships_db == nil then
		ships_db = ScienceDatabase():setName("Ships")
	end
	local fighter_db = queryScienceDatabase("Ships","Starfighter")
	if fighter_db == nil then
		ships_db:addEntry("Starfighter")
		fighter_db = queryScienceDatabase("Ships","Starfighter")
	end
	local generic_starfighter_description = "Starfighters are single to 3 person small ships. These are most commonly used as light firepower roles.\nThey are common in larger groups, and need a close by station or support ship, as they lack long time life support.\nIt's rare to see starfighters with more then one shield section.\n\nOne of the most well known starfighters is the X-Wing.\n\nStarfighters come in 3 subclasses:\n* Interceptors: Fast, low on firepower, high on manouverability\n* Gunship: Equipped with more weapons, but trades in manouverability because of it.\n* Bomber: Slowest of all starfighters, but pack a large punch in a small package. Usually come without any lasers, but the largers bombers have been known to deliver nukes."
	fighter_db:setLongDescription(generic_starfighter_description)
	local frigate_db = queryScienceDatabase("Ships","Frigate")
	if frigate_db == nil then
		ships_db:addEntry("Frigate")
		frigate_db = queryScienceDatabase("Ships","Frigate")
	end
	local generic_frigate_description = "Frigates are one size up from starfighters. They require a crew from 3 to 20 people.\nThink, Firefly, millennium falcon, slave I (Boba fett's ship).\n\nThey generally have 2 or more shield sections, but hardly ever more than 4.\n\nThis class of ships is normally not fitted with jump or warp drives. But in some cases ships are modified to include these, or for certain roles it is built in.\n\nThey are divided in 3 different sub-classes:\n* Cruiser: Weaponized frigates, focused on combat. These come in various roles.\n* Light transport: Small transports, like transporting up to 50 soldiers in spartan conditions or a few diplomats in luxury. Depending on the role it can have some weaponry.\n* Support: Support types come in many varieties. They are simply a frigate hull fitted with whatever was needed. Anything from mine-layers to science vessels."
	frigate_db:setLongDescription(generic_frigate_description)
	local corvette_db = queryScienceDatabase("Ships","Corvette")
	if corvette_db == nil then
		ships_db:addEntry("Corvette")
		corvette_db = queryScienceDatabase("Ships","Corvette")
	end
	local generic_corvette_description = "Corvettes are the common large ships. Larger then a frigate, smaller then a dreadnaught.\nThey generally have 4 or more shield sections. Run with a crew of 20 to 250.\nThis class generally has jumpdrives or warpdrives. But lack the maneuverability that is seen in frigates.\n\nThey come in 3 different subclasses:\n* Destroyer: Combat oriented ships. No science, no transport. Just death in a large package.\n* Support: Large scale support roles. Drone carriers fall in this category, as well as mobile repair centers.\n* Freighter: Large scale transport ships. Most common here are the jump freighters, using specialized jumpdrives to cross large distances with large amounts of cargo."
	corvette_db:setLongDescription(generic_corvette_description)
	local dreadnought_db = queryScienceDatabase("Ships","Dreadnought")
	if dreadnought_db == nil then
		ships_db:addEntry("Dreadnought")
		dreadnought_db = queryScienceDatabase("Ships","Dreadnought")
	end
	dreadnought_db:setLongDescription("Dreadnoughts are the largest ships.\nThey are so large and uncommon that every type is pretty much their own subclass.\nThey usually come with 6 or more shield sections, require a crew of 250+ to operate.\n\nThink: Stardestroyer.")
--------------------------
--	Stock player ships  --
--------------------------
	ships_db:addEntry("Mainstream")
	local stock_db = queryScienceDatabase("Ships","Mainstream")
	stock_db:setLongDescription("Mainstream ships are those ship types that are commonly available to crews serving on the front lines or in well established areas")
----	Starfighters
	stock_db:addEntry("Starfighter")
	local fighter_stock_db = queryScienceDatabase("Ships","Mainstream","Starfighter")
	fighter_stock_db:setLongDescription(generic_starfighter_description)
--	MP52 Hornet
	fighter_stock_db:addEntry("MP52 Hornet")
	local mp52_hornet_db = queryScienceDatabase("Ships","Mainstream","Starfighter","MP52 Hornet")
	mp52_hornet_db:setLongDescription("The MP52 Hornet is a significantly upgraded version of MU52 Hornet, with nearly twice the hull strength, nearly three times the shielding, better acceleration, impulse boosters, and a second laser cannon.")
	mp52_hornet_db:setKeyValue("Class","Starfighter")
	mp52_hornet_db:setKeyValue("Sub-class","Interceptor")
	mp52_hornet_db:setKeyValue("Size","30")
	mp52_hornet_db:setKeyValue("Shield","60")
	mp52_hornet_db:setKeyValue("Hull","70")
	mp52_hornet_db:setKeyValue("Repair Crew",1)
	mp52_hornet_db:setKeyValue("Warp Speed","60 U/min")	--1000 (added for scenario)
	mp52_hornet_db:setKeyValue("Battery Capacity",400)
	mp52_hornet_db:setKeyValue("Sensor Ranges","Long: 18 U / Short: 4 U")
	mp52_hornet_db:setKeyValue("Move speed","7.5 U/min")	--125	(value * 60 / 1000 = units per minute)
	mp52_hornet_db:setKeyValue("Turn speed","32 deg/sec")
	mp52_hornet_db:setKeyValue("Beam weapon 355:30","Rng:.9 Dmg:2.5 Cyc:4")
	mp52_hornet_db:setKeyValue("Beam weapon 5:30","Rng:.9 Dmg:2.5 Cyc:4")
	mp52_hornet_db:setImage("radar/fighter.png")
--	Player Fighter
	fighter_stock_db:addEntry("Player Fighter")
	local player_fighter_db = queryScienceDatabase("Ships","Mainstream","Starfighter","Player Fighter")
	player_fighter_db:setLongDescription("A fairly standard fighter with strong beams and a tube for HVLIs. The sensors aren't that great, but it often has a warp drive bolted on making it extraordinarily fast")
	player_fighter_db:setKeyValue("Class","Starfighter")
	player_fighter_db:setKeyValue("Size","40")
	player_fighter_db:setKeyValue("Shield","40")
	player_fighter_db:setKeyValue("Hull","60")
	player_fighter_db:setKeyValue("Repair Crew",3)
	player_fighter_db:setKeyValue("Warp Speed","60 U/min")	--1000 (added for scenario)
	player_fighter_db:setKeyValue("Battery Capacity",400)
	player_fighter_db:setKeyValue("Sensor Ranges","Long: 15 U / Short: 4.5 U")
	player_fighter_db:setKeyValue("Move speed","6.6 U/min")	--110	(value * 60 / 1000 = units per minute)
	player_fighter_db:setKeyValue("Turn speed","20 deg/sec")
	player_fighter_db:setKeyValue("Beam weapon 0:40","Rng:.5 Dmg:4 Cyc:6")	--modified for scenario: added short forward beam so others balance
	player_fighter_db:setKeyValue("Beam weapon 10:40","Rng:1 Dmg:8 Cyc:6")
	player_fighter_db:setKeyValue("Beam weapon 350:40","Rng:1 Dmg:8 Cyc:6")
	player_fighter_db:setKeyValue("Tube 0","10 sec")
	player_fighter_db:setKeyValue("Storage HVLI","4")
	player_fighter_db:setImage("radar/fighter.png")
--	Striker
	fighter_stock_db:addEntry("Striker")
	local striker_db = queryScienceDatabase("Ships","Mainstream","Starfighter","Striker")
	striker_db:setLongDescription("The Striker is the predecessor to the advanced striker, slow but agile, but does not do an extreme amount of damage, and lacks in shields")
	striker_db:setKeyValue("Class","Starfighter")
	striker_db:setKeyValue("Size","140")
	striker_db:setKeyValue("Shield","50/30")
	striker_db:setKeyValue("Hull","120")
	striker_db:setKeyValue("Repair Crew",2)
	striker_db:setKeyValue("Jump Range","3 - 40 U")	--modified for scenario
	striker_db:setKeyValue("Battery Capacity",500)
	striker_db:setKeyValue("Sensor Ranges","Long: 35 U / Short: 5 U")
	striker_db:setKeyValue("Move speed","2.7 U/min")	--45
	striker_db:setKeyValue("Turn speed","15 deg/sec")
	striker_db:setKeyValue("Beam weapon 345:100","Rng:1 Dmg:6 Cyc:6 Tur:6")
	striker_db:setKeyValue("Beam weapon 15:100","Rng:1 Dmg:6 Cyc:6 Tur:6")
	striker_db:setImage("radar_adv_striker.png")
--	ZX-Lindworm
	fighter_stock_db:addEntry("ZX-Lindworm")
	local zx_lindworm_db = queryScienceDatabase("Ships","Mainstream","Starfighter","ZX-Lindworm")
	zx_lindworm_db:setLongDescription("The ZX model is an improvement on the WX-Lindworm with stronger hull and shields, faster impulse and tubes, more missiles and a single weak, turreted beam. The 'Worm' as it's often called, is a bomber-class starfighter. While one of the least-shielded starfighters in active duty, the Worm's launchers can pack quite a punch. Its goal is to fly in, destroy its target, and fly out or be destroyed.")
	zx_lindworm_db:setKeyValue("Class","Starfighter")
	zx_lindworm_db:setKeyValue("Sub-class","Bomber")
	zx_lindworm_db:setKeyValue("Size","30")
	zx_lindworm_db:setKeyValue("Shield","40")
	zx_lindworm_db:setKeyValue("Hull","75")
	zx_lindworm_db:setKeyValue("Repair Crew",1)
	zx_lindworm_db:setKeyValue("Warp Speed","57 U/min")	--950 (added for scenario)
	zx_lindworm_db:setKeyValue("Battery Capacity",400)
	zx_lindworm_db:setKeyValue("Sensor Ranges","Long: 18 U / Short: 5.5 U")
	zx_lindworm_db:setKeyValue("Move speed","4.2 U/min")	--70	(value * 60 / 1000 = units per minute)
	zx_lindworm_db:setKeyValue("Turn speed","15 deg/sec")
	zx_lindworm_db:setKeyValue("Beam weapon 180:270","Rng:.7 Dmg:2 Cyc:6")
	zx_lindworm_db:setKeyValue("Small Tube 0","10 sec")
	zx_lindworm_db:setKeyValue("Small Tube 359","10 sec")
	zx_lindworm_db:setKeyValue("Small Tube 1","10 sec")
	zx_lindworm_db:setKeyValue("Storage Homing","3")
	zx_lindworm_db:setKeyValue("Storage HVLI","12")
	zx_lindworm_db:setImage("radar/fighter.png")
----	Frigates
	stock_db:addEntry("Frigate")
	local frigate_stock_db = queryScienceDatabase("Ships","Mainstream","Frigate")
	frigate_stock_db:setLongDescription(generic_frigate_description)
--	Flavia P.Falcon
	frigate_stock_db:addEntry("Flavia P.Falcon")
	local flavia_p_falcon_db = queryScienceDatabase("Ships","Mainstream","Frigate","Flavia P.Falcon")
	flavia_p_falcon_db:setLongDescription("Popular among traders and smugglers, the Flavia is a small cargo and passenger transport. It's cheaper than a freighter for small loads and short distances, and is often used to carry high-value cargo discreetly.\n\nThe Flavia Falcon is a Flavia transport modified for faster flight, and adds rear-mounted lasers to keep enemies off its back.\n\nThe Flavia P.Falcon has a nuclear-capable rear-facing weapon tube and a warp drive.")
	flavia_p_falcon_db:setKeyValue("Class","Frigate")
	flavia_p_falcon_db:setKeyValue("Sub-class","Cruiser: Light Transport")
	flavia_p_falcon_db:setKeyValue("Size","80")
	flavia_p_falcon_db:setKeyValue("Shield","70/70")
	flavia_p_falcon_db:setKeyValue("Hull","100")
	flavia_p_falcon_db:setKeyValue("Repair Crew",8)
	flavia_p_falcon_db:setKeyValue("Warp Speed","30 U/min")	--500
	flavia_p_falcon_db:setKeyValue("Sensor Ranges","Long: 40 U / Short: 5 U")
	flavia_p_falcon_db:setKeyValue("Move speed","3.6 U/min")	--60
	flavia_p_falcon_db:setKeyValue("Turn speed","10 deg/sec")
	flavia_p_falcon_db:setKeyValue("Beam weapon 170:40","Rng:1.2 Dmg:6 Cyc:6")
	flavia_p_falcon_db:setKeyValue("Beam weapon 190:40","Rng:1.2 Dmg:6 Cyc:6")
	flavia_p_falcon_db:setKeyValue("Tube 180","20 sec")
	flavia_p_falcon_db:setKeyValue("Storage Homing","3")
	flavia_p_falcon_db:setKeyValue("Storage Nuke","1")
	flavia_p_falcon_db:setKeyValue("Storage Mine","1")
	flavia_p_falcon_db:setKeyValue("Storage HVLI","5")
	flavia_p_falcon_db:setImage("radar/tug.png")
--	Hathcock
	frigate_stock_db:addEntry("Hathcock")
	local hathcock_db = queryScienceDatabase("Ships","Mainstream","Frigate","Hathcock")
	hathcock_db:setLongDescription("Long range narrow beam and some point defense beams, broadside missiles. Agile for a frigate")
	hathcock_db:setKeyValue("Class","Frigate")
	hathcock_db:setKeyValue("Sub-class","Cruiser: Sniper")
	hathcock_db:setKeyValue("Size","80")
	hathcock_db:setKeyValue("Shield","70/70")
	hathcock_db:setKeyValue("Hull","120")
	hathcock_db:setKeyValue("Repair Crew",2)
	hathcock_db:setKeyValue("Jump Range","6 - 60 U")	--modified for scenario
	hathcock_db:setKeyValue("Sensor Ranges","Long: 35 U / Short: 6 U")
	hathcock_db:setKeyValue("Move speed","3 U/min")	--50
	hathcock_db:setKeyValue("Turn speed","15 deg/sec")
	hathcock_db:setKeyValue("Beam weapon 0:4","Rng:1.4 Dmg:4 Cyc:6")
	hathcock_db:setKeyValue("Beam weapon 0:20","Rng:1.2 Dmg:4 Cyc:6")
	hathcock_db:setKeyValue("Beam weapon 0:60","Rng:1.0 Dmg:4 Cyc:6")
	hathcock_db:setKeyValue("Beam weapon 0:90","Rng:0.8 Dmg:4 Cyc:6")
	hathcock_db:setKeyValue("Tube 270","15 sec")
	hathcock_db:setKeyValue("Tube 90","15 sec")
	hathcock_db:setKeyValue("Storage Homing","4")
	hathcock_db:setKeyValue("Storage Nuke","1")
	hathcock_db:setKeyValue("Storage EMP","2")
	hathcock_db:setKeyValue("Storage HVLI","8")
	hathcock_db:setImage("radar/piranha.png")
--	Nautilus
	frigate_stock_db:addEntry("Nautilus")
	local nautilus_db = queryScienceDatabase("Ships","Mainstream","Frigate","Nautilus")
	nautilus_db:setLongDescription("Small mine laying vessel with minimal armament, shields and hull")
	nautilus_db:setKeyValue("Class","Frigate")
	nautilus_db:setKeyValue("Sub-class","Mine Layer")
	nautilus_db:setKeyValue("Size","80")
	nautilus_db:setKeyValue("Shield","60/60")
	nautilus_db:setKeyValue("Hull","100")
	nautilus_db:setKeyValue("Repair Crew",4)
	nautilus_db:setKeyValue("Jump Range","5 - 70 U")	--modified for scenario
	nautilus_db:setKeyValue("Sensor Ranges","Long: 22 U / Short: 4 U")
	nautilus_db:setKeyValue("Move speed","6 U/min")	--100
	nautilus_db:setKeyValue("Turn speed","10 deg/sec")
	nautilus_db:setKeyValue("Beam weapon 35:90","Rng:1 Dmg:6 Cyc:6 Tur:6")
	nautilus_db:setKeyValue("Beam weapon 325:90","Rng:1 Dmg:6 Cyc:6 Tur:6")
	nautilus_db:setKeyValue("Tube 180","10 sec / Mine")
	nautilus_db:setKeyValue(" Tube 180","10 sec / Mine")
	nautilus_db:setKeyValue("  Tube 180","10 sec / Mine")
	nautilus_db:setKeyValue("Storage Mine","12")
	nautilus_db:setImage("radar/tug.png")
--	Phobos M3P
	frigate_stock_db:addEntry("Phobos M3P")
	local phobos_m3p_db = queryScienceDatabase("Ships","Mainstream","Frigate","Phobos M3P")
	phobos_m3p_db:setLongDescription("Player variant of the Phobos M3. Not as strong as the Atlantis, but has front firing tubes, making it an easier to use ship in some scenarios.")
	phobos_m3p_db:setKeyValue("Class","Frigate")
	phobos_m3p_db:setKeyValue("Sub-class","Cruiser")
	phobos_m3p_db:setKeyValue("Size","80")
	phobos_m3p_db:setKeyValue("Shield","100/100")
	phobos_m3p_db:setKeyValue("Hull","200")
	phobos_m3p_db:setKeyValue("Repair Crew",3)
	phobos_m3p_db:setKeyValue("Warp Speed","54 U/min")	--900 (added for scenario)
	phobos_m3p_db:setKeyValue("Sensor Ranges","Long: 25 U / Short: 5 U")
	phobos_m3p_db:setKeyValue("Move speed","4.8 U/min")	--80
	phobos_m3p_db:setKeyValue("Turn speed","10 deg/sec")
	phobos_m3p_db:setKeyValue("Beam weapon 345:90","Rng:1.2 Dmg:6 Cyc:8")
	phobos_m3p_db:setKeyValue("Beam weapon 15:90","Rng:1.2 Dmg:6 Cyc:8")
	phobos_m3p_db:setKeyValue("Tube 359","10 sec")
	phobos_m3p_db:setKeyValue("Tube 1","10 sec")
	phobos_m3p_db:setKeyValue("Tube 180","10 sec / Mine")
	phobos_m3p_db:setKeyValue("Storage Homing","10")
	phobos_m3p_db:setKeyValue("Storage Nuke","2")
	phobos_m3p_db:setKeyValue("Storage Mine","4")
	phobos_m3p_db:setKeyValue("Storage EMP","3")
	phobos_m3p_db:setKeyValue("Storage HVLI","20")
	phobos_m3p_db:setImage("radar/cruiser.png")
--	Piranha
	frigate_stock_db:addEntry("Piranha")
	local piranha_db = queryScienceDatabase("Ships","Mainstream","Frigate","Piranha")
	piranha_db:setLongDescription("This combat-specialized Piranha F12 adds mine-laying tubes, combat maneuvering systems, and a jump drive.")
	piranha_db:setKeyValue("Class","Frigate")
	piranha_db:setKeyValue("Sub-class","Cruiser: Light Artillery")
	piranha_db:setKeyValue("Size","80")
	piranha_db:setKeyValue("Shield","70/70")
	piranha_db:setKeyValue("Hull","120")
	piranha_db:setKeyValue("Repair Crew",2)
	piranha_db:setKeyValue("Jump Range","5 - 50 U")
	piranha_db:setKeyValue("Sensor Ranges","Long: 25 U / Short: 6 U")
	piranha_db:setKeyValue("Move speed","3.6 U/min")	--60
	piranha_db:setKeyValue("Turn speed","10 deg/sec")
	piranha_db:setKeyValue("Large Tube 270","8 sec / Homing,HVLI")
	piranha_db:setKeyValue("Tube 270","8 sec")
	piranha_db:setKeyValue(" LargeTube 270","8 sec / Homing,HVLI")
	piranha_db:setKeyValue("Large Tube 90","8 sec / Homing,HVLI")
	piranha_db:setKeyValue("Tube 90","8 sec")
	piranha_db:setKeyValue(" LargeTube 90","8 sec / Homing,HVLI")
	piranha_db:setKeyValue("Tube 170","8 sec / Mine")
	piranha_db:setKeyValue("Tube 190","8 sec / Mine")
	piranha_db:setKeyValue("Storage Homing","12")
	piranha_db:setKeyValue("Storage Nuke","6")
	piranha_db:setKeyValue("Storage Mine","8")
	piranha_db:setKeyValue("Storage HVLI","20")
	piranha_db:setImage("radar/piranha.png")
--	Repulse
	frigate_stock_db:addEntry("Repulse")
	local repulse_db = queryScienceDatabase("Ships","Mainstream","Frigate","Repulse")
	repulse_db:setLongDescription("A Flavia P. Falcon with better hull and shields, a jump drive, two turreted beams covering both sides and a forward and rear tube. The nukes and mines are gone")
	repulse_db:setKeyValue("Class","Frigate")
	repulse_db:setKeyValue("Sub-class","Cruiser: Armored Transport")
	repulse_db:setKeyValue("Size","80")
	repulse_db:setKeyValue("Shield","80/80")
	repulse_db:setKeyValue("Hull","120")
	repulse_db:setKeyValue("Repair Crew",8)
	repulse_db:setKeyValue("Jump Range","5 - 50 U")
	repulse_db:setKeyValue("Sensor Ranges","Long: 38 U / Short: 5 U")
	repulse_db:setKeyValue("Move speed","3.3 U/min")	--55
	repulse_db:setKeyValue("Turn speed","9 deg/sec")
	repulse_db:setKeyValue("Beam weapon 90:200","Rng:1.2 Dmg:5 Cyc:6")
	repulse_db:setKeyValue("Beam weapon 270:200","Rng:1.2 Dmg:5 Cyc:6")
	repulse_db:setKeyValue("Tube 0","20 sec")
	repulse_db:setKeyValue("Tube 180","20 sec")
	repulse_db:setKeyValue("Storage Homing","4")
	repulse_db:setKeyValue("Storage HVLI","6")
	repulse_db:setImage("radar/tug.png")
----	Corvettes
	stock_db:addEntry("Corvette")
	local corvette_stock_db = queryScienceDatabase("Ships","Mainstream","Corvette")
	corvette_stock_db:setLongDescription(generic_corvette_description)
--	Atlantis
	corvette_stock_db:addEntry("Atlantis")
	local atlantis_db = queryScienceDatabase("Ships","Mainstream","Corvette","Atlantis")
	atlantis_db:setLongDescription("A refitted Atlantis X23 for more general tasks. The large shield system has been replaced with an advanced combat maneuvering systems and improved impulse engines. Its missile loadout is also more diverse. Mistaking the modified Atlantis for an Atlantis X23 would be a deadly mistake.")
	atlantis_db:setKeyValue("Class","Corvette")
	atlantis_db:setKeyValue("Sub-class","Destroyer")
	atlantis_db:setKeyValue("Size","200")
	atlantis_db:setKeyValue("Shield","200/200")
	atlantis_db:setKeyValue("Hull","250")
	atlantis_db:setKeyValue("Repair Crew",3)
	atlantis_db:setKeyValue("Jump Range","5 - 50 U")
	atlantis_db:setKeyValue("Sensor Ranges","Long: 30 U / Short: 5 U")
	atlantis_db:setKeyValue("Move speed","5.4 U/min")	--100
	atlantis_db:setKeyValue("Turn speed","10 deg/sec")
	atlantis_db:setKeyValue("Beam weapon 340:100","Rng:1.5 Dmg:8 Cyc:6")
	atlantis_db:setKeyValue("Beam weapon 20:100","Rng:1.5 Dmg:8 Cyc:6")
	atlantis_db:setKeyValue("Tube 270","10 sec")
	atlantis_db:setKeyValue(" Tube 270","10 sec")
	atlantis_db:setKeyValue("Tube 90","10 sec")
	atlantis_db:setKeyValue(" Tube 90","10 sec")
	atlantis_db:setKeyValue("Tube 180","10 sec / Mine")
	atlantis_db:setKeyValue("Storage Homing","12")
	atlantis_db:setKeyValue("Storage Nuke","4")
	atlantis_db:setKeyValue("Storage Mine","8")
	atlantis_db:setKeyValue("Storage EMP","6")
	atlantis_db:setKeyValue("Storage HVLI","20")
	atlantis_db:setImage("radar/dread.png")
--	Benedict
	corvette_stock_db:addEntry("Benedict")
	local benedict_db = queryScienceDatabase("Ships","Mainstream","Corvette","Benedict")
	benedict_db:setLongDescription("Benedict is Jump Carrier with a shorter range, but with stronger shields and hull and with minimal armament")
	benedict_db:setKeyValue("Class","Corvette")
	benedict_db:setKeyValue("Sub-class","Freighter/Carrier")
	benedict_db:setKeyValue("Size","200")
	benedict_db:setKeyValue("Shield","70/70")
	benedict_db:setKeyValue("Hull","200")
	benedict_db:setKeyValue("Repair Crew",6)
	benedict_db:setKeyValue("Jump Range","5 - 90 U")
	benedict_db:setKeyValue("Sensor Ranges","Long: 30 U / Short: 5 U")
	benedict_db:setKeyValue("Move speed","3.6 U/min")	--60
	benedict_db:setKeyValue("Turn speed","6 deg/sec")
	benedict_db:setKeyValue("Beam weapon 0:90","Rng:1.5 Dmg:4 Cyc:6 Tur:6")
	benedict_db:setKeyValue("Beam weapon 180:90","Rng:1.5 Dmg:4 Cyc:6 Tur:6")
	benedict_db:setImage("radar/transport.png")
--	Crucible
	corvette_stock_db:addEntry("Crucible")
	local crucible_db = queryScienceDatabase("Ships","Mainstream","Corvette","Crucible")
	crucible_db:setLongDescription("A number of missile tubes range around this ship. Beams were deemed lower priority, though they are still present. Stronger defenses than a frigate, but not as strong as the Atlantis")
	crucible_db:setKeyValue("Class","Corvette")
	crucible_db:setKeyValue("Sub-class","Popper")
	crucible_db:setKeyValue("Size","80")
	crucible_db:setKeyValue("Shield","160/160")
	crucible_db:setKeyValue("Hull","160")
	crucible_db:setKeyValue("Repair Crew",4)
	crucible_db:setKeyValue("Warp Speed","45 U/min")	--750
	crucible_db:setKeyValue("Sensor Ranges","Long: 20 U / Short: 6 U")
	crucible_db:setKeyValue("Move speed","4.8 U/min")	--80
	crucible_db:setKeyValue("Turn speed","15 deg/sec")
	crucible_db:setKeyValue("Beam weapon 330:70","Rng:1 Dmg:5 Cyc:6")
	crucible_db:setKeyValue("Beam weapon 30:70","Rng:1 Dmg:5 Cyc:6")
	crucible_db:setKeyValue("Small Tube 0","8 sec / HVLI")
	crucible_db:setKeyValue("Tube 0","8 sec / HVLI")
	crucible_db:setKeyValue("Large Tube 0","8 sec / HVLI")
	crucible_db:setKeyValue("Tube 270","8 sec")
	crucible_db:setKeyValue("Tube 90","8 sec")
	crucible_db:setKeyValue("Tube 180","8 sec / Mine")
	crucible_db:setKeyValue("Storage Missiles","H:8 N:4 M:6 E:6 L:24")
	crucible_db:setImage("radar/laser.png")
--	Kiriya
	corvette_stock_db:addEntry("Kiriya")
	local kiriya_db = queryScienceDatabase("Ships","Mainstream","Corvette","Kiriya")
	kiriya_db:setLongDescription("Kiriya is Warp Carrier based on the jump carrier with stronger shields and hull and with minimal armament")
	kiriya_db:setKeyValue("Class","Corvette")
	kiriya_db:setKeyValue("Sub-class","Freighter/Carrier")
	kiriya_db:setKeyValue("Size","200")
	kiriya_db:setKeyValue("Shield","70/70")
	kiriya_db:setKeyValue("Hull","200")
	kiriya_db:setKeyValue("Repair Crew",6)
	kiriya_db:setKeyValue("Warp Speed","45 U/min")	--750
	kiriya_db:setKeyValue("Sensor Ranges","Long: 35 U / Short: 5 U")
	kiriya_db:setKeyValue("Move speed","3.6 U/min")	--60
	kiriya_db:setKeyValue("Turn speed","6 deg/sec")
	kiriya_db:setKeyValue("Beam weapon 0:90","Rng:1.5 Dmg:4 Cyc:6 Tur:6")
	kiriya_db:setKeyValue("Beam weapon 180:90","Rng:1.5 Dmg:4 Cyc:6 Tur:6")
	kiriya_db:setImage("radar/transport.png")
--	Maverick
	corvette_stock_db:addEntry("Maverick")
	local maverick_db = queryScienceDatabase("Ships","Mainstream","Corvette","Maverick")
	maverick_db:setLongDescription("A number of beams bristle from various points on this gunner. Missiles were deemed lower priority, though they are still present. Stronger defenses than a frigate, but not as strong as the Atlantis")
	maverick_db:setKeyValue("Class","Corvette")
	maverick_db:setKeyValue("Sub-class","Gunner")
	maverick_db:setKeyValue("Size","80")
	maverick_db:setKeyValue("Shield","160/160")
	maverick_db:setKeyValue("Hull","160")
	maverick_db:setKeyValue("Repair Crew",4)
	maverick_db:setKeyValue("Warp Speed","48 U/min")	--800
	maverick_db:setKeyValue("Sensor Ranges","Long: 20 U / Short: 4 U")
	maverick_db:setKeyValue("Move speed","4.8 U/min")	--80
	maverick_db:setKeyValue("Turn speed","15 deg/sec")
	maverick_db:setKeyValue("Beam weapon 0:10","Rng:2 Dmg:6 Cyc:6")
	maverick_db:setKeyValue("Beam weapon 340:90","Rng:1.5 Dmg:8 Cyc:6")
	maverick_db:setKeyValue("Beam weapon 20:90","Rng:1.5 Dmg:8 Cyc:6")
	maverick_db:setKeyValue("Beam weapon 290:40","Rng:1 Dmg:6 Cyc:4")
	maverick_db:setKeyValue("Beam weapon 70:40","Rng:1 Dmg:6 Cyc:4")
	maverick_db:setKeyValue("Beam weapon 180:180","Rng:.8 Dmg:4 Cyc:6 Tur:.5")
	maverick_db:setKeyValue("Tube 270","8 sec")
	maverick_db:setKeyValue("Tube 90","8 sec")
	maverick_db:setKeyValue("Tube 180","8 sec / Mine")
	maverick_db:setKeyValue("Storage Missiles","H:6 N:2 M:2 E:4 L:10")
	maverick_db:setImage("radar/laser.png")
--	Player Cruiser
	corvette_stock_db:addEntry("Player Cruiser")
	local player_cruiser_db = queryScienceDatabase("Ships","Mainstream","Corvette","Player Cruiser")
	player_cruiser_db:setLongDescription("A fairly standard cruiser. Stronger than average beams, weaker than average shields, farther than average jump drive range")
	player_cruiser_db:setKeyValue("Class","Corvette")
	player_cruiser_db:setKeyValue("Size","200")
	player_cruiser_db:setKeyValue("Shield","80/80")
	player_cruiser_db:setKeyValue("Hull","200")
	player_cruiser_db:setKeyValue("Repair Crew",3)
	player_cruiser_db:setKeyValue("Jump Range","5 - 80 U")	--modified for scenario
	player_cruiser_db:setKeyValue("Sensor Ranges","Long: 30 U / Short: 5 U")
	player_cruiser_db:setKeyValue("Move speed","5.4 U/min")	--90
	player_cruiser_db:setKeyValue("Turn speed","10 deg/sec")
	player_cruiser_db:setKeyValue("Beam weapon 345:90","Rng:1 Dmg:10 Cyc:6")
	player_cruiser_db:setKeyValue("Beam weapon 15:90","Rng:1 Dmg:10 Cyc:6")
	player_cruiser_db:setKeyValue("Tube 355","8 sec")
	player_cruiser_db:setKeyValue("Tube 5","8 sec")
	player_cruiser_db:setKeyValue("Tube 180","8 sec / Mine")
	player_cruiser_db:setKeyValue("Storage Homing","12")
	player_cruiser_db:setKeyValue("Storage Nuke","4")
	player_cruiser_db:setKeyValue("Storage Mine","8")
	player_cruiser_db:setKeyValue("Storage EMP","6")
	player_cruiser_db:setImage("radar/cruiser.png")
--	Player Missile Cruiser
	corvette_stock_db:addEntry("Player Missile Cr.")
	local player_missile_cruiser_db = queryScienceDatabase("Ships","Mainstream","Corvette","Player Missile Cr.")
	player_missile_cruiser_db:setLongDescription("It's all about the missiles for this model. Broadside tubes shoot homing missiles (30!), front, homing, EMP and nuke. Comparatively weak shields, especially in the rear. Sluggish impulse drive.")
	player_missile_cruiser_db:setKeyValue("Class","Corvette")
	player_missile_cruiser_db:setKeyValue("Size","100")
	player_missile_cruiser_db:setKeyValue("Shield","110/70")
	player_missile_cruiser_db:setKeyValue("Hull","200")
	player_missile_cruiser_db:setKeyValue("Repair Crew",3)
	player_missile_cruiser_db:setKeyValue("Warp Speed","48 U/min")	--800
	player_missile_cruiser_db:setKeyValue("Sensor Ranges","Long: 35 U / Short: 6 U")
	player_missile_cruiser_db:setKeyValue("Move speed","3.6 U/min")	--60
	player_missile_cruiser_db:setKeyValue("Turn speed","8 deg/sec")
	player_missile_cruiser_db:setKeyValue("Tube 0","8 sec")
	player_missile_cruiser_db:setKeyValue(" Tube 0","8 sec")
	player_missile_cruiser_db:setKeyValue("Tube 90","8 sec / Homing")
	player_missile_cruiser_db:setKeyValue(" Tube 90","8 sec / Homing")
	player_missile_cruiser_db:setKeyValue("Tube 270","8 sec / Homing")
	player_missile_cruiser_db:setKeyValue(" Tube 270","8 sec / Homing")
	player_missile_cruiser_db:setKeyValue("Tube 180","8 sec / Mine")
	player_missile_cruiser_db:setKeyValue("Storage Homing","30")
	player_missile_cruiser_db:setKeyValue("Storage Nuke","8")
	player_missile_cruiser_db:setKeyValue("Storage Mine","12")
	player_missile_cruiser_db:setKeyValue("Storage EMP","10")
	player_missile_cruiser_db:setImage("radar/cruiser.png")
---------------------------
--	Custom player ships  --
---------------------------
	ships_db:addEntry("Prototype")
	local prototype_db = queryScienceDatabase("Ships","Prototype")
	prototype_db:setLongDescription("Prototype ships are those that are under development or are otherwise considered experimental. Some have been through several iterations after being tested in the field. Many have been scrapped due to poor design, the ravages of space or perhaps the simple passage of time.")
	prototype_db:setImage("gui/icons/station-engineering.png")
----	Starfighters
	prototype_db:addEntry("Starfighter")
	local fighter_prototype_db = queryScienceDatabase("Ships","Prototype","Starfighter")
	fighter_prototype_db:setLongDescription(generic_starfighter_description)
--	Striker LX
	fighter_prototype_db:addEntry("Striker LX")
	local striker_lx_db = queryScienceDatabase("Ships","Prototype","Starfighter","Striker LX")
	striker_lx_db:setLongDescription("The Striker is the predecessor to the advanced striker, slow but agile, but does not do an extreme amount of damage, and lacks in shields. The Striker LX is a modification of the Striker: stronger shields, more energy, jump drive (vs none), faster impulse, slower turret, two rear tubes (vs none)")
	striker_lx_db:setKeyValue("Class","Starfighter")
	striker_lx_db:setKeyValue("Sub-class","Patrol")
	striker_lx_db:setKeyValue("Size","140")
	striker_lx_db:setKeyValue("Shield","100/100")
	striker_lx_db:setKeyValue("Hull","100")
	striker_lx_db:setKeyValue("Repair Crew",3)
	striker_lx_db:setKeyValue("Battery Capacity",600)
	striker_lx_db:setKeyValue("Jump Range","2 - 20 U")
	striker_lx_db:setKeyValue("Sensor Ranges","Long: 20 U / Short: 4 U")
	striker_lx_db:setKeyValue("Move speed","3.9 U/min")	--65	(value * 60 / 1000 = units per minute)
	striker_lx_db:setKeyValue("Turn speed","35 deg/sec")
	striker_lx_db:setKeyValue("Beam weapon 345:100","Rng:1.1 Dmg:6.5 Cyc:6 Tur:.2")
	striker_lx_db:setKeyValue("Beam weapon 15:100","Rng:1.1 Dmg:6.5 Cyc:6 Tur:.2")
	striker_lx_db:setKeyValue("Tube 180","10 sec")
	striker_lx_db:setKeyValue(" Tube 180","10 sec")
	striker_lx_db:setKeyValue("Storage Homing","4")
	striker_lx_db:setKeyValue("Storage Nuke","2")
	striker_lx_db:setKeyValue("Storage Mine","3")
	striker_lx_db:setKeyValue("Storage EMP","3")
	striker_lx_db:setKeyValue("Storage HVLI","6")
	striker_lx_db:setImage("radar/adv_striker.png")
----	Frigates
	prototype_db:addEntry("Frigate")
	local frigate_prototype_db = queryScienceDatabase("Ships","Prototype","Frigate")
	frigate_prototype_db:setLongDescription(generic_frigate_description)
--	Phobos T2
	frigate_prototype_db:addEntry("Phobos T2")
	local phobos_t2_db = queryScienceDatabase("Ships","Prototype","Frigate","Phobos T2")
	phobos_t2_db:setLongDescription("Based on Phobos M3P with these differences: more repair crew, a jump drive, faster spin, stronger front shield, weaker rear shield, less maximum energy, turreted and faster beams, one fewer tube forward, and fewer missiles")
	phobos_t2_db:setKeyValue("Class","Frigate")
	phobos_t2_db:setKeyValue("Sub-class","Cruiser")
	phobos_t2_db:setKeyValue("Size","80")
	phobos_t2_db:setKeyValue("Shield","120/80")
	phobos_t2_db:setKeyValue("Hull","200")
	phobos_t2_db:setKeyValue("Repair Crew",4)
	phobos_t2_db:setKeyValue("Battery Capacity",800)
	phobos_t2_db:setKeyValue("Jump Range","2 - 25 U")
	phobos_t2_db:setKeyValue("Sensor Ranges","Long: 25 U / Short: 5 U")
	phobos_t2_db:setKeyValue("Move speed","4.8 U/min")	--80
	phobos_t2_db:setKeyValue("Turn speed","20 deg/sec")
	phobos_t2_db:setKeyValue("Beam weapon 330:40","Rng:1.2 Dmg:6 Cyc:4 Tur:.2")
	phobos_t2_db:setKeyValue("Beam weapon 30:40","Rng:1.2 Dmg:6 Cyc:4 Tur:.2")
	phobos_t2_db:setKeyValue("Tube 0","10 sec")
	phobos_t2_db:setKeyValue("Tube 180","10 sec / Mine")
	phobos_t2_db:setKeyValue("Storage Homing",8)
	phobos_t2_db:setKeyValue("Storage Nuke",2)
	phobos_t2_db:setKeyValue("Storage Mine",4)
	phobos_t2_db:setKeyValue("Storage EMP",3)
	phobos_t2_db:setKeyValue("Storage HVLI",16)
	phobos_t2_db:setImage("radar/cruiser.png")
----	Corvettes
	prototype_db:addEntry("Corvette")
	local corvette_prototype_db = queryScienceDatabase("Ships","Prototype","Corvette")
	corvette_prototype_db:setLongDescription(generic_corvette_description)
--	Focus
	corvette_prototype_db:addEntry("Focus")
	local focus_db = queryScienceDatabase("Ships","Prototype","Corvette","Focus")
	focus_db:setLongDescription("Adjusted Crucible: short jump drive (no warp), faster impulse and spin, weaker shields and hull, narrower beams, fewer tubes. The large tube accomodates nukes, EMPs and homing missiles")
	focus_db:setKeyValue("Class","Corvette")
	focus_db:setKeyValue("Sub-class","Popper")
	focus_db:setKeyValue("Size","200")
	focus_db:setKeyValue("Shield","100/100")
	focus_db:setKeyValue("Hull","100")
	focus_db:setKeyValue("Repair Crew",4)
	focus_db:setKeyValue("Jump Range","2.5 - 25 U")
	focus_db:setKeyValue("Sensor Ranges","Long: 32 U / Short: 5 U")
	focus_db:setKeyValue("Move speed","4.2 U/min")	--70
	focus_db:setKeyValue("Turn speed","20 deg/sec")
	focus_db:setKeyValue("Beam weapon 340:60","Rng:1 Dmg:5 Cyc:6")
	focus_db:setKeyValue("Beam weapon 20:60","Rng:1 Dmg:5 Cyc:6")
	focus_db:setKeyValue("Small Tube 0","8 sec / HVLI")
	focus_db:setKeyValue("Tube 0","8 sec / HVLI")
	focus_db:setKeyValue("Large Tube 0","8 sec")
	focus_db:setKeyValue("Tube 180","8 sec / Mine")
	focus_db:setKeyValue("Storage Homing",8)
	focus_db:setKeyValue("Storage Nuke",1)
	focus_db:setKeyValue("Storage Mine",6)
	focus_db:setKeyValue("Storage EMP",2)
	focus_db:setKeyValue("Storage HVLI",24)
	focus_db:setImage("radar/laser.png")
--	Holmes
	corvette_prototype_db:addEntry("Holmes")
	local holmes_db = queryScienceDatabase("Ships","Prototype","Corvette","Holmes")
	holmes_db:setLongDescription("Revised Crucible: weaker shields, side beams, fewer tubes, fewer missiles, EMPs and Nukes in front middle tube and large homing missiles")
	holmes_db:setKeyValue("Class","Corvette")
	holmes_db:setKeyValue("Sub-class","Popper")
	holmes_db:setKeyValue("Size","200")
	holmes_db:setKeyValue("Shield","160/160")
	holmes_db:setKeyValue("Hull","160")
	holmes_db:setKeyValue("Repair Crew",4)
	holmes_db:setKeyValue("Warp Speed","45.0 U/min")	--750
	holmes_db:setKeyValue("Sensor Ranges","Long: 35 U / Short: 4 U")
	holmes_db:setKeyValue("Move speed","4.2 U/min")	--70
	holmes_db:setKeyValue("Turn speed","15 deg/sec")
	holmes_db:setKeyValue("Beam weapon 275:50","Rng:.9 Dmg:5 Cyc:6")
	holmes_db:setKeyValue("Beam weapon 265:50","Rng:.9 Dmg:5 Cyc:6")
	holmes_db:setKeyValue("Beam weapon 85:50","Rng:.9 Dmg:5 Cyc:6")
	holmes_db:setKeyValue("Beam weapon 95:50","Rng:.9 Dmg:5 Cyc:6")
	holmes_db:setKeyValue("Small Tube 0","8 sec / Homing")
	holmes_db:setKeyValue("Tube 0","8 sec / Homing")
	holmes_db:setKeyValue("Large Tube 0","8 sec / Homing")
	holmes_db:setKeyValue("Tube 180","8 sec / Mine")
	holmes_db:setKeyValue("Storage Homing",10)
	holmes_db:setKeyValue("Storage Mine",6)
	holmes_db:setImage("radar/laser.png")
--	Maverick XP
	corvette_prototype_db:addEntry("Maverick XP")
	local maverick_xp_db = queryScienceDatabase("Ships","Prototype","Corvette","Maverick XP")
	maverick_xp_db:setLongDescription("Based on Maverick: slower impulse, jump (no warp), one heavy slow turreted beam (not 6 beams)")
	maverick_xp_db:setKeyValue("Class","Corvette")
	maverick_xp_db:setKeyValue("Sub-class","Gunner")
	maverick_xp_db:setKeyValue("Size","200")
	maverick_xp_db:setKeyValue("Shield","160/160")
	maverick_xp_db:setKeyValue("Hull","160")
	maverick_xp_db:setKeyValue("Repair Crew",4)
	maverick_xp_db:setKeyValue("Jump Range","2 - 20 U")
	maverick_xp_db:setKeyValue("Sensor Ranges","Long: 25 U / Short: 7 U")
	maverick_xp_db:setKeyValue("Move speed","3.9 U/min")	--65
	maverick_xp_db:setKeyValue("Turn speed","15 deg/sec")
	maverick_xp_db:setKeyValue("Beam weapon 0:270","Rng:1 Dmg:20 Cyc:20 Tur:.2")
	maverick_xp_db:setKeyValue("Tube 270","8 sec")
	maverick_xp_db:setKeyValue("Tube 90","8 sec")
	maverick_xp_db:setKeyValue("Tube 180","8 sec / Mine")
	maverick_xp_db:setKeyValue("Storage Homing",6)
	maverick_xp_db:setKeyValue("Storage Nuke",2)
	maverick_xp_db:setKeyValue("Storage Mine",2)
	maverick_xp_db:setKeyValue("Storage EMP",4)
	maverick_xp_db:setKeyValue("Storage HVLI",10)
	maverick_xp_db:setImage("radar/laser.png")
end
------------------
--	GM Buttons  --
------------------
function setGMButtons()
	mainGMButtons = mainGMButtonsDuringPause
	mainGMButtons()
end
function mainGMButtonsDuringPause()
	clearGMFunctions()
	local button_label = ""
	addGMFunction(string.format(_("buttonGM", "Version %s"),scenario_version),function()
		local version_message = string.format(_("msgGM", "Scenario version %s\n LUA version %s"),scenario_version,_VERSION)
		addGMMessage(version_message)
		print(version_message)
	end)
	if not terrain_generated then
		addGMFunction(_("buttonGM", "+Player Config"),setPlayerConfig)
		button_label = _("buttonGM", "+NPC Ships: 0")
		if npc_ships then
			button_label = string.format(_("buttonGM", "+NPC Ships: %i-%i"),npc_lower,npc_upper)
		end
		addGMFunction(button_label,setNPCShips)
		addGMFunction(_("buttonGM", "+Terrain"),setTerrainParameters)
		addGMFunction(string.format(_("buttonGM", "Respawn: %s"),respawn_type),function()
			if respawn_type == "lindworm" then
				respawn_type = "self"
			elseif respawn_type == "self" then
				respawn_type = "lindworm"
			end
			mainGMButtons()
		end)
	else
		addGMFunction(_("buttonGM", "Show control codes"),showControlCodes)
		addGMFunction(_("buttonGM", "Show Human codes"),showHumanCodes)
		addGMFunction(_("buttonGM", "Show Kraylor codes"),showKraylorCodes)
		if exuari_angle ~= nil then
			addGMFunction(_("buttonGM", "Show Exuari codes"),showExuariCodes)
		end
		if ktlitan_angle ~= nil then
			addGMFunction(_("buttonGM", "Show Ktlitan codes"),showKtlitanCodes)
		end
		addGMFunction("Reset control codes",resetControlCodes)
	end
	addGMFunction(string.format(_("buttonGM", "+Stn Sensors %iU"),station_sensor_range/1000),setStationSensorRange)
	addGMFunction(string.format(_("buttonGM", "+Game Time %i"),game_time_limit/60),setGameTimeLimit)
	button_label = _("buttonGM", "No")
	if advanced_intel then
		button_label = _("buttonGM", "Yes")
	end
	addGMFunction(string.format(_("buttonGM", "+Advance Intel %s"),button_label),setAdvanceIntel)
	addGMFunction(_("buttonGM", "Explain"),function()
		if terrain_generated then
			addGMMessage(_("msgGM", "The version button just provides scenario version information on the text of the button plus the Lua version when you click it. Explanations for Stn sensors, Game time and Advance intel may be obtained by clicking those buttons.\n\nThe various control codes buttons show the control codes for the various player ships: all or by team faction."))
		else
			addGMMessage(_("msgGM", "The version button just provides scenario version information on the text of the button plus the Lua version when you click it. Explanations for NPC Ships, Terrain, Stn sensors, Game time and Advance intel may be obtained by clicking those buttons.\n\nThe Respawn button determines how a player ship is respawned if it is destroyed. The Lindworm option means the players come back in a Lindworm. The Self option means the players come back as the same type of ship they started in."))
		end
	end)
end
function setPlayerConfig()
	clearGMFunctions()
	addGMFunction(_("buttonGM", "-Main from P. Config"),mainGMButtons)
	if not terrain_generated then
		addGMFunction(string.format(_("buttonGM", "+Player Teams: %i"),player_team_count),setPlayerTeamCount)
		addGMFunction(string.format(_("buttonGM", "+Player Ships: %i (%i)"),ships_per_team,ships_per_team*player_team_count),setPlayerShipCount)
		addGMFunction(string.format(_("buttonGM", "+P.Ship Types: %s"),player_ship_types),setPlayerShipTypes)
		if predefined_player_ships ~= nil then
			addGMFunction(_("buttonGM", "Random PShip Names"),function()
				addGMMessage(_("msgGM", "Player ship names will be selected at random"))
				predefined_player_ships = nil
				setPlayerConfig()
			end)
			addGMFunction(_("buttonGM", "Explain"),function()
				addGMMessage(_("msgGM", "Player teams is the number of player teams. Player ships and player ship types are explained after you click those buttons.\n\nThe button 'Random PShip Names' switches from a fixed list of player ship names to selecting player ship names at random from a pool of player ship names. There is no going back to the fixed player ship names once you click this button unless you restart the server."))
			end)
		end
	end
end
function mainGMButtonsAfterPause()
	clearGMFunctions()
	addGMFunction(string.format(_("buttonGM", "Version %s"),scenario_version),function()
		local version_message = string.format(_("msgGM", "Scenario version %s\n LUA version %s"),scenario_version,_VERSION)
		addGMMessage(version_message)
		print(version_message)
	end)
	addGMFunction(_("buttonGM", "Show control codes"),showControlCodes)
	addGMFunction(_("buttonGM", "Show Human codes"),showHumanCodes)
	addGMFunction(_("buttonGM", "Show Kraylor codes"),showKraylorCodes)
	if exuari_angle ~= nil then
		addGMFunction(_("buttonGM", "Show Exuari codes"),showExuariCodes)
	end
	if ktlitan_angle ~= nil then
		addGMFunction(_("buttonGM", "Show Ktlitan codes"),showKtlitanCodes)
	end
	addGMFunction(_("buttonGM", "Statistics Summary"),function()
		local stat_list = gatherStats()
		local out = _("buttonGM", "Current Scores:")
		out = string.format(_("msgGM", "%s\n   Human Navy: %.2f (%.1f%%)"),out,stat_list.human.weighted_score,stat_list.human.weighted_score/original_score["Human Navy"]*100)
		out = string.format(_("msgGM", "%s\n   Kraylor: %.2f (%.1f%%)"),out,stat_list.kraylor.weighted_score,stat_list.kraylor.weighted_score/original_score["Kraylor"]*100)
		if exuari_angle ~= nil then
			out = string.format(_("msgGM", "%s\n   Exuari: %.2f (%.1f%%)"),out,stat_list.exuari.weighted_score,stat_list.exuari.weighted_score/original_score["Exuari"]*100)
		end
		if ktlitan_angle ~= nil then
			out = string.format(_("msgGM", "\n   Ktlitans: %.2f (%.1f%%)"),out,stat_list.ktlitan.weighted_score,stat_list.ktlitan.weighted_score/original_score["Ktlitans"]*100)
		end
		local out = string.format(_("msgGM", "%s\nOriginal scores:"),out)
		out = string.format(_("msgGM", "%s\n   Human Navy: %.2f"),out,original_score["Human Navy"])
		out = string.format(_("msgGM", "%s\n   Kraylor: %.2f"),out,original_score["Kraylor"])
		if exuari_angle ~= nil then
			out = string.format(_("msgGM", "%s\n   Exuari: %.2f"),out,original_score["Exuari"])
		end
		if ktlitan_angle ~= nil then
			out = string.format(_("msgGM", "%s\n   Ktlitans: %.2f"),out,original_score["Ktlitans"])
		end
		addGMMessage(out)
	end)
	addGMFunction(_("buttonGM", "Statistics Details"),function()
		local stat_list = gatherStats()
		local tie_breaker = {}
		for i,p in ipairs(getActivePlayerShips()) do
			tie_breaker[p:getFaction()] = p:getReputationPoints()/10000
		end
		out = _("msgGM", "Human Navy:\n    Stations: (score value, type, name)")
		print("Human Navy:")
		print("    Stations: (score value, type, name)")
		for name, details in pairs(stat_list.human.station) do
			out = string.format(_("msgGM", "%s\n        %i %s %s"),out,details.score_value,details.template_type,name)
			print(" ",details.score_value,details.template_type,name)
		end
		local weighted_stations = stat_list.human.station_score_total * stat_list.weight.station
		out = string.format(_("msgGM", "%s\n            Station Total:%i Weight:%.1f Weighted total:%.2f"),out,stat_list.human.station_score_total,stat_list.weight.station,weighted_stations)
		print("    Station Total:",stat_list.human.station_score_total,"Weight:",stat_list.weight.station,"Weighted Total:",weighted_stations)
		out = string.format(_("msgGM", "%s\n    Player Ships: (score value, type, name)"),out)
		print("    Player Ships: (score value, type, name)")
		for name, details in pairs(stat_list.human.ship) do
			out = string.format(_("msgGM", "%s\n        %i %s %s"),out,details.score_value,details.template_type,name)
			print(" ",details.score_value,details.template_type,name)
		end
		local weighted_players = stat_list.human.ship_score_total * stat_list.weight.ship
		out = string.format(_("msgGM", "%s\n            Player Ship Total:%i Weight:%.1f Weighted total:%.2f"),out,stat_list.human.ship_score_total,stat_list.weight.ship,weighted_players)
		print("    Player Ship Total:",stat_list.human.ship_score_total,"Weight:",stat_list.weight.ship,"Weighted Total:",weighted_players)
		out = string.format(_("msgGM", "%s\n    NPC Assets: score value, type, name (location)"),out)
		print("    NPC Assets: score value, type, name (location)")
		for name, details in pairs(stat_list.human.npc) do
			if details.template_type ~= nil then
				out = string.format(_("msgGM", "%s\n        %i %s %s"),out,details.score_value,details.template_type,name)
				print(" ",details.score_value,details.template_type,name)
			elseif details.topic ~= nil then
				out = string.format(_("msgGM", "%s\n        %i %s %s (%s)"),out,details.score_value,details.topic,name,details.location_name)
				print(" ",details.score_value,details.topic,name,"(" .. details.location_name .. ")")
			end
		end
		local weighted_npcs = stat_list.human.npc_score_total * stat_list.weight.npc
		out = string.format(_("msgGM", "%s\n            NPC Asset Total:%i Weight:%.1f Weighted total:%.2f"),out,stat_list.human.npc_score_total,stat_list.weight.npc,weighted_npcs)
		print("    NPC Asset Total:",stat_list.human.npc_score_total,"Weight:",stat_list.weight.npc,"Weighted Total:",weighted_npcs)
		if respawn_type == "self" then
			local weighted_death_penalty = stat_list.human.death_penalty * stat_list.weight.ship
			out = string.format(_("msgGM","%s\n            Player ship death penalty:%i Weight:%.1f Weighted Total:%,2f"),out,stat_list.human.death_penalty,stat_list.weight.ship,weighted_death_penalty)
			print("    Player ship death penalty:",stat_list.human.death_penalty,"Weight:",stat_list.weight.ship,"Weighted Total:",weighted_death_penalty)
		end
		out = string.format(_("msgGM", "%s\n----Human weighted total:%.1f Original:%.1f Change:%.2f%%"),out,stat_list.human.weighted_score,original_score["Human Navy"],stat_list.human.weighted_score/original_score["Human Navy"]*100)
		print("----Human weighted total:",stat_list.human.weighted_score,"Original:",original_score["Human Navy"],"Change:",stat_list.human.weighted_score/original_score["Human Navy"]*100 .. "%")
		out = string.format(_("msgGM","%sHuman tie breaker points:%f"),out,tie_breaker["Human Navy"])
		print("Human tie breaker points:",tie_breaker["Human Navy"])
		out = string.format(_("msgGM", "%s\nKraylor:\n    Stations: (score value, type, name)"),out)
		print("Kraylor:")
		print("    Stations: (score value, type, name)")
		for name, details in pairs(stat_list.kraylor.station) do
			out = string.format(_("msgGM", "%s\n        %i %s %s"),out,details.score_value,details.template_type,name)
			print(" ",details.score_value,details.template_type,name)
		end
		local weighted_stations = stat_list.kraylor.station_score_total * stat_list.weight.station
		out = string.format(_("msgGM", "%s\n            Station Total:%i Weight:%.1f Weighted total:%.2f"),out,stat_list.kraylor.station_score_total,stat_list.weight.station,weighted_stations)
		print("    Station Total:",stat_list.kraylor.station_score_total,"Weight:",stat_list.weight.station,"Weighted Total:",weighted_stations)
		out = string.format(_("msgGM", "%s\n    Player Ships: (score value, type, name)"),out)
		print("    Player Ships: (score value, type, name)")
		for name, details in pairs(stat_list.kraylor.ship) do
			out = string.format(_("msgGM", "\n        %i %s %s"),out,details.score_value,details.template_type,name)
			print(" ",details.score_value,details.template_type,name)
		end
		local weighted_players = stat_list.kraylor.ship_score_total * stat_list.weight.ship
		out = string.format(_("msgGM", "%s\n            Player Ship Total:%i Weight:%.1f Weighted total:%.2f"),out,stat_list.kraylor.ship_score_total,stat_list.weight.ship,weighted_players)
		print("    Player Ship Total:",stat_list.kraylor.ship_score_total,"Weight:",stat_list.weight.ship,"Weighted Total:",weighted_players)
		out = string.format(_("msgGM", "%s\n    NPC Assets: score value, type, name (location)"),out)
		print("    NPC Assets: score value, type, name (location)")
		for name, details in pairs(stat_list.kraylor.npc) do
			if details.template_type ~= nil then
				out = string.format(_("msgGM", "%s\n        %i %s %s"),out,details.score_value,details.template_type,name)
				print(" ",details.score_value,details.template_type,name)
			elseif details.topic ~= nil then
				out = string.format(_("msgGM", "%s\n        %i %s %s (%s)"),out,details.score_value,details.topic,name,details.location_name)
				print(" ",details.score_value,details.topic,name,"(" .. details.location_name .. ")")
			end
		end
		local weighted_npcs = stat_list.kraylor.npc_score_total * stat_list.weight.npc
		out = string.format(_("msgGM", "%s\n            NPC Asset Total:%i Weight:%.1f Weighted total:%.2f"),out,stat_list.kraylor.npc_score_total,stat_list.weight.npc,weighted_npcs)
		print("    NPC Asset Total:",stat_list.kraylor.npc_score_total,"Weight:",stat_list.weight.npc,"Weighted Total:",weighted_npcs)
		if respawn_type == "self" then
			local weighted_death_penalty = stat_list.kraylor.death_penalty * stat_list.weight.ship
			out = string.format(_("msgGM","%s\n            Player ship death penalty:%i Weight:%.1f Weighted Total:%,2f"),out,stat_list.kraylor.death_penalty,stat_list.weight.ship,weighted_death_penalty)
			print("    Player ship death penalty:",stat_list.kraylor.death_penalty,"Weight:",stat_list.weight.ship,"Weighted Total:",weighted_death_penalty)
		end
		out = string.format(_("msgGM", "%s\n----Kraylor weighted total:%.1f Original:%.1f Change:%.2f%%"),out,stat_list.kraylor.weighted_score,original_score["Kraylor"],stat_list.kraylor.weighted_score/original_score["Kraylor"]*100)
		print("----Kraylor weighted total:",stat_list.kraylor.weighted_score,"Original:",original_score["Kraylor"],"Change:",stat_list.kraylor.weighted_score/original_score["Kraylor"]*100 .. "%")
		out = string.format(_("msgGM","%sKraylor tie breaker points:%f"),out,tie_breaker["Kraylor"])
		print("Kraylor tie breaker points:",tie_breaker["Kraylor"])
		if exuari_angle ~= nil then
			out = string.format(_("msgGM", "%s\nExuari:\n    Stations: (score value, type, name)"),out)
			print("Exuari:")
			print("    Stations: (score value, type, name)")
			for name, details in pairs(stat_list.exuari.station) do
				out = string.format(_("msgGM", "%s\n        %i %s %s"),out,details.score_value,details.template_type,name)
				print(" ",details.score_value,details.template_type,name)
			end
			local weighted_stations = stat_list.exuari.station_score_total * stat_list.weight.station
			out = string.format(_("msgGM", "%s\n            Station Total:%i Weight:%.1f Weighted total:%.2f"),out,stat_list.exuari.station_score_total,stat_list.weight.station,weighted_stations)
			print("    Station Total:",stat_list.exuari.station_score_total,"Weight:",stat_list.weight.station,"Weighted Total:",weighted_stations)
			out = string.format(_("msgGM", "\n    Player Ships: (score value, type, name)"),out)
			print("    Player Ships: (score value, type, name)")
			for name, details in pairs(stat_list.exuari.ship) do
				out = string.format(_("msgGM", "%s\n        %i %s %s"),out,details.score_value,details.template_type,name)
				print(" ",details.score_value,details.template_type,name)
			end
			local weighted_players = stat_list.exuari.ship_score_total * stat_list.weight.ship
			out = string.format(_("msgGM", "%s\n            Player Ship Total:%i Weight:%.1f Weighted total:%.2f"),out,stat_list.exuari.ship_score_total,stat_list.weight.ship,weighted_players)
			print("    Player Ship Total:",stat_list.exuari.ship_score_total,"Weight:",stat_list.weight.ship,"Weighted Total:",weighted_players)
			out = string.format(_("msgGM", "%s\n    NPC Assets: score value, type, name (location)"),out)
			print("    NPC Assets: score value, type, name (location)")
			for name, details in pairs(stat_list.exuari.npc) do
				if details.template_type ~= nil then
					out = string.format(_("msgGM", "%s\n        %i %s %s"),out,details.score_value,details.template_type,name)
					print(" ",details.score_value,details.template_type,name)
				elseif details.topic ~= nil then
					out = string.format(_("msgGM", "%s\n        %i %s %s (%s)"),out,details.score_value,details.topic,name,details.location_name)
					print(" ",details.score_value,details.topic,name,"(" .. details.location_name .. ")")
				end
			end
			local weighted_npcs = stat_list.exuari.npc_score_total * stat_list.weight.npc
			out = string.format(_("msgGM", "%s\n            NPC Asset Total:%i Weight:%.1f Weighted total:%.2f"),out,stat_list.exuari.npc_score_total,stat_list.weight.npc,weighted_npcs)
			print("    NPC Asset Total:",stat_list.exuari.npc_score_total,"Weight:",stat_list.weight.npc,"Weighted Total:",weighted_npcs)
			if respawn_type == "self" then
				local weighted_death_penalty = stat_list.exuari.death_penalty * stat_list.weight.ship
				out = string.format(_("msgGM","%s\n            Player ship death penalty:%i Weight:%.1f Weighted Total:%,2f"),out,stat_list.exuari.death_penalty,stat_list.weight.ship,weighted_death_penalty)
				print("    Player ship death penalty:",stat_list.exuari.death_penalty,"Weight:",stat_list.weight.ship,"Weighted Total:",weighted_death_penalty)
			end
			out = string.format(_("msgGM", "%s\n----Exuari weighted total:%.1f Original:%.1f Change:%.2f%%"),out,stat_list.exuari.weighted_score,original_score["Exuari"],stat_list.exuari.weighted_score/original_score["Exuari"]*100)
			print("----Exuari weighted total:",stat_list.exuari.weighted_score,"Original:",original_score["Exuari"],"Change:",stat_list.exuari.weighted_score/original_score["Exuari"]*100 .. "%")
			out = string.format(_("msgGM","%sExuari tie breaker points:%f"),out,tie_breaker["Exuari"])
			print("Exuari tie breaker points:",tie_breaker["Exuari"])
		end
		if ktlitan_angle ~= nil then
			out = string.format(_("msgGM", "\nKtlitan:\n    Stations: (score value, type, name)"),out)
			print("Ktlitan:")
			print("    Stations: (score value, type, name)")
			for name, details in pairs(stat_list.ktlitan.station) do
				out = string.format(_("msgGM", "%s\n        %i %s %s"),out,details.score_value,details.template_type,name)
				print(" ",details.score_value,details.template_type,name)
			end
			local weighted_stations = stat_list.ktlitan.station_score_total * stat_list.weight.station
			out = string.format(_("msgGM", "%s\n            Station Total:%i Weight:%.1f Weighted total:%.2f"),out,stat_list.ktlitan.station_score_total,stat_list.weight.station,weighted_stations)
			print("    Station Total:",stat_list.ktlitan.station_score_total,"Weight:",stat_list.weight.station,"Weighted Total:",weighted_stations)
			out = string.format(_("msgGM", "%s\n    Player Ships: (score value, type, name)"),out)
			print("    Player Ships: (score value, type, name)")
			for name, details in pairs(stat_list.ktlitan.ship) do
				out = string.format(_("msgGM", "%s\n        %i %s %s"),out,details.score_value,details.template_type,name)
				print(" ",details.score_value,details.template_type,name)
			end
			local weighted_players = stat_list.ktlitan.ship_score_total * stat_list.weight.ship
			out = string.format(_("msgGM", "%s\n            Player Ship Total:%i Weight:%.1f Weighted total:%.2f"),out,stat_list.ktlitan.ship_score_total,stat_list.weight.ship,weighted_players)
			print("    Player Ship Total:",stat_list.ktlitan.ship_score_total,"Weight:",stat_list.weight.ship,"Weighted Total:",weighted_players)
			out = string.format(_("msgGM", "%s\n    NPC Assets: score value, type, name (location)"),out)
			print("    NPC Assets: score value, type, name (location)")
			for name, details in pairs(stat_list.ktlitan.npc) do
				if details.template_type ~= nil then
					out = string.format(_("msgGM", "%s\n        %i %s %s"),out,details.score_value,details.template_type,name)
					print(" ",details.score_value,details.template_type,name)
				elseif details.topic ~= nil then
					out = string.format(_("msgGM", "%s\n        %i %s %s (%s)"),out,details.score_value,details.topic,name,details.location_name)
					print(" ",details.score_value,details.topic,name,"(" .. details.location_name .. ")")
				end
			end
			local weighted_npcs = stat_list.ktlitan.npc_score_total * stat_list.weight.npc
			out = string.format(_("msgGM", "%s\n            NPC Asset Total:%i Weight:%.1f Weighted total:%.2f"),out,stat_list.ktlitan.npc_score_total,stat_list.weight.npc,weighted_npcs)
			print("    NPC Asset Total:",stat_list.ktlitan.npc_score_total,"Weight:",stat_list.weight.npc,"Weighted Total:",weighted_npcs)
			if respawn_type == "self" then
				local weighted_death_penalty = stat_list.ktlitan.death_penalty * stat_list.weight.ship
				out = string.format(_("msgGM","%s\n            Player ship death penalty:%i Weight:%.1f Weighted Total:%,2f"),out,stat_list.ktlitan.death_penalty,stat_list.weight.ship,weighted_death_penalty)
				print("    Player ship death penalty:",stat_list.ktlitan.death_penalty,"Weight:",stat_list.weight.ship,"Weighted Total:",weighted_death_penalty)
			end
			out = string.format(_("msgGM", "%s\n----Ktlitan weighted total:%.1f Original:%.1f Change:%.2f%%"),out,stat_list.ktlitan.weighted_score,original_score["Ktlitans"],stat_list.ktlitan.weighted_score/original_score["Ktlitans"]*100)
			print("----Ktlitan weighted total:",stat_list.ktlitan.weighted_score,"Original:",original_score["Ktlitans"],"Change:",stat_list.ktlitan.weighted_score/original_score["Ktlitans"]*100 .. "%")
			out = string.format(_("msgGM","%sKtlitan tie breaker points:%f"),out,tie_breaker["Ktlitans"])
			print("Ktlitan tie breaker points:",tie_breaker["Ktlitans"])
		end
		addGMMessage(out)
	end)
end
--	Player related GM configuration functions
function setPlayerTeamCount()
	clearGMFunctions()
	addGMFunction(_("buttonGM", "-Main from Teams"),mainGMButtons)
	local button_label = _("buttonGM", "2")
	if player_team_count == 2 then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		player_team_count = 2
		setPlayerConfig()
	end)
	local button_label = _("buttonGM", "3")
	if player_team_count == 3 then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		player_team_count = 3
		if ships_per_team > max_ships_per_team[player_team_count] then
			ships_per_team = max_ships_per_team[player_team_count]
			if player_ship_types == "spawned" then
				addGMMessage(_("msgGM", "Switching player ship type to default"))
				player_ship_types = "default"
			end
		end
		setPlayerConfig()
	end)
	local button_label = _("buttonGM", "4")
	if player_team_count == 4 then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		player_team_count = 4
		if ships_per_team > max_ships_per_team[player_team_count] then
			ships_per_team = max_ships_per_team[player_team_count]
			if player_ship_types == "spawned" then
				addGMMessage(_("msgGM", "Switching player ship type to default"))
				player_ship_types = "default"
			end
		end
		setPlayerConfig()
	end)
end
function setPlayerShipCount()
	clearGMFunctions()
	addGMFunction(_("buttonGM", "-Main from Ships"),mainGMButtons)
	addGMFunction(_("buttonGM", "-Player Config"),setPlayerConfig)
	if ships_per_team < max_ships_per_team[player_team_count] then
		addGMFunction(string.format(_("buttonGM", "%i ships add -> %i"),ships_per_team,ships_per_team + 1),function()
			ships_per_team = ships_per_team + 1
			if player_ship_types == "spawned" then
				addGMMessage(_("msgGM", "Switching player ship type to default"))
				player_ship_types = "default"
			end
			setPlayerShipCount()
		end)
	end
	if ships_per_team > 1 then
		addGMFunction(string.format(_("buttonGM", "%i ships del -> %i"),ships_per_team,ships_per_team - 1),function()
			ships_per_team = ships_per_team - 1
			if player_ship_types == "spawned" then
				addGMMessage(_("msgGM", "Switching player ship type to default"))
				player_ship_types = "default"
			end
			setPlayerShipCount()
		end)
	end
	addGMFunction(_("buttonGM", "Explain"),function()
		addGMMessage(_("msgGM", "This is where you set the number of player ships per team. The number of non-player ships is set under NPC Ships."))
	end)
end
function setPlayerShipTypes()
	clearGMFunctions()
	addGMFunction(_("buttonGM", "-Main from Ship Types"),mainGMButtons)
	addGMFunction(_("buttonGM", "-Player Config"),setPlayerConfig)
	local button_label = "default"
	if player_ship_types == button_label then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		player_ship_types = "default"
		local player_plural = "players"
		local type_plural = "types"
		if ships_per_team == 1 then
			player_plural = "player"
			type_plural = "type"
		end
		local out = string.format(_("msgGM", "Default ship %s for a team of %i %s:"),type_plural,ships_per_team,player_plural)
		for i=1,ships_per_team do
			out = out .. "\n   " .. i .. ") " .. default_player_ship_sets[ships_per_team][i]
		end
		addGMMessage(out)
		setPlayerShipTypes()
	end)
	button_label = "spawned"
	if player_ship_types == button_label then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		player_ship_types = "spawned"
		local out = _("msgGM", "Spawned ship type(s):")
		local player_count = 0
		for pidx=1,32 do
			local p = getPlayerShip(pidx)
			if p ~= nil and p:isValid() then
				player_count = player_count + 1
				out = out .. "\n   " .. player_count .. ") " .. p:getTypeName()
			end
		end
		if player_count < ships_per_team then
			if player_count == 0 then
				out = string.format(_("msgGM", "%i player ships spawned. %i are required.\n\nUsing default ship set.\n\n%s"),player_count,ships_per_team,out)
			elseif player_count == 1 then
				out = string.format(_("msgGM", "Only %i player ship spawned. %i are required.\n\nUsing default ship set.\n\n%s"),player_count,ships_per_team,out)
			else
				out = string.format(_("msgGM", "Only %i player ships spawned. %i are required.\n\nUsing default ship set.\n\n%s"),player_count,ships_per_team,out)
			end
			player_ship_types = "default"
		elseif player_count > ships_per_team then
			if ships_per_team == 1 then
				out = string.format(_("msgGM", "%i player ships spawned. Only %i is required.\n\nUsing default ship set.\n\n%s"),player_count,ships_per_team,out)
			else
				out = string.format(_("msgGM", "%i player ships spawned. Only %i are required.\n\nUsing default ship set.\n\n%s"),player_count,ships_per_team,out)
			end
			player_ship_types = "default"
		end
		addGMMessage(out)
		setPlayerShipTypes()
	end)
	button_label = "custom"
	if player_ship_types == button_label then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(string.format("+%s",button_label),setCustomPlayerShipSet)
	addGMFunction(_("buttonGM", "Explain"),function()
		addGMMessage(_("msgGM", "This is where you determine the kinds of ships the players will use.\n\nDefault: There is a default set of ships depending on the number of players and the number of teams.\n\nSpawned: Whatever is spawned from the first screen for one team will be replicated for the other team or teams. If the number of ships spawned does not match the team size selected, the default player ship set will be used.\n\nCustom: There are several sets of defaults under custom: Warp (ships equipped with warp drive), Jump (ships equipped with jump drive), Light (ships that are not as heavily armed or armored) and Heavy (ships that are more heavily armed or armored). There is also custom button where you can select the ship or ships you want from a list. To set up the list, use the +Customize Custom button."))
	end)
end
function setCustomPlayerShipSet()
	clearGMFunctions()
	addGMFunction(_("buttonGM", "-Main from Custom"),mainGMButtons)
	addGMFunction(_("buttonGM", "-Ship Types"),setPlayerShipTypes)
	addGMFunction(_("buttonGM", "+Customize Custom"),setCustomSet)
	for ship_set_type,list in pairs(custom_player_ship_sets) do
		local button_label = ship_set_type
		if ship_set_type == custom_player_ship_type then
			button_label = button_label .. _("buttonGM", "*")
		end
		addGMFunction(button_label,function()
			player_ship_types = "custom"
			custom_player_ship_type = ship_set_type
			local out = ""
			if ships_per_team == 1 then
				out = string.format(_("msgGM", "Ship type set %s for %i player:"),custom_player_ship_type,ships_per_team)
			else
				out = string.format(_("msgGM", "Ship type set %s for %i players:"),custom_player_ship_type,ships_per_team)
			end
			for index, ship_type in ipairs(custom_player_ship_sets[custom_player_ship_type][ships_per_team]) do
--				print("index:",index,"ship type:",ship_type)
				out = out .. "\n   " .. index .. ") " .. ship_type
			end
			addGMMessage(out)
			setCustomPlayerShipSet()
		end)
	end
end
function setCustomSet()
	clearGMFunctions()
	addGMFunction(_("buttonGM", "-Main from Custom"),mainGMButtons)
	addGMFunction(_("buttonGM", "-Ship Types"),setPlayerShipTypes)
	addGMFunction(_("buttonGM", "-Custom Set"),setCustomPlayerShipSet)
	if template_out == nil then
		template_out = custom_player_ship_sets["Custom"][ships_per_team][1]
	else
		local match_in_set = false
		for i=1,#custom_player_ship_sets["Custom"][ships_per_team] do
			if custom_player_ship_sets["Custom"][ships_per_team][i] == template_out then
				match_in_set = true
			end
		end
		if not match_in_set then
			template_out = custom_player_ship_sets["Custom"][ships_per_team][1]
		end
	end
	if template_in == nil then
		for name, details in pairs(player_ship_stats) do
			template_in = name
			break
		end
	end
	addGMFunction(string.format(_("buttonGM", "+Out %s"),template_out),setTemplateOut)
	addGMFunction(string.format(_("buttonGM", "+In %s"),template_in),setTemplateIn)
	addGMFunction("Swap",function()
		for i=1,#custom_player_ship_sets["Custom"][ships_per_team] do
			if custom_player_ship_sets["Custom"][ships_per_team][i] == template_out then
				custom_player_ship_sets["Custom"][ships_per_team][i] = template_in
				template_in = template_out
				template_out = custom_player_ship_sets["Custom"][ships_per_team][i]
				break
			end
		end
		setCustomSet()
	end)
	addGMFunction(_("buttonGM", "Explain"),function()
		addGMMessage(_("msgGM", "The +Out button shows the current list of player ships. The ship named on the button or the one with the asterisk if you click the +Out button is the ship in the list that you can swap with another.\n\nThe +In button shows the list of ships that you might want to put in the custom list of ships. The ship on the button or the one with the asterisk if you click the +In button is the ship you can place in the custom list.\n\nThe Swap button swaps the ships on the +In and +Out buttons removing the ship on the +Out button from the custom list to be used in the game and putting the ship on the +In button in the custom list of ships to be used.\n\nNotice that some of the ships that can be swapped in to the custom list are not stock Empty Epsilon ships, but are specialized versions of stock Empty Epsilon ships."))
	end)
end
function setTemplateOut()
	clearGMFunctions()
	table.sort(custom_player_ship_sets["Custom"][ships_per_team])
	for i=1,#custom_player_ship_sets["Custom"][ships_per_team] do
		local button_label = custom_player_ship_sets["Custom"][ships_per_team][i]
		if template_out == custom_player_ship_sets["Custom"][ships_per_team][i] then
			button_label = button_label .. _("buttonGM", "*")
		end
		addGMFunction(button_label,function()
			template_out = custom_player_ship_sets["Custom"][ships_per_team][i]
			setCustomSet()
		end)
	end
end
function setTemplateIn()
	clearGMFunctions()
	local sorted_templates = {}
	for name, details in pairs(player_ship_stats) do
		table.insert(sorted_templates,name)
	end
	table.sort(sorted_templates)
	for idx, name in ipairs(sorted_templates) do
		local button_label = name
		if template_in == name then
			button_label = button_label .. _("buttonGM", "*")
		end
		addGMFunction(button_label,function()
			template_in = name
			setCustomSet()
		end)
	end
end
function setAdvanceIntel()
	clearGMFunctions()
	addGMFunction(_("buttonGM", "-Main"),mainGMButtons)
	local button_label = _("buttonGM", "Advance Intel Yes")
	if advanced_intel then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		advanced_intel = true
		setAdvanceIntel()
	end)
	button_label = _("buttonGM", "Advance Intel No")
	if not advanced_intel then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		advanced_intel = false
		setAdvanceIntel()
	end)
	addGMFunction(_("buttonGM", "Explain"),function()
		addGMMessage(_("msgGM", "This setting determines whether or not the players will receive a message at the start of the game indicating the location of their opponent's home base. Useful if players feel that they spend too much time at the start looking for their opponents."))
	end)
end
--	Terrain related GM configuration functions
function setTerrainParameters()
	clearGMFunctions()
	addGMFunction(_("buttonGM", "-Main from Terrain"),mainGMButtons)
	addGMFunction(string.format(_("buttonGM", "+Missiles: %s"),missile_availability),setMissileAvailability)
	addGMFunction(_("buttonGM", "+Primary Station"),setPrimaryStationParameters)
	addGMFunction(_("buttonGM", "Generate"),function()
		generateTerrain()
		mainGMButtons()
	end)
	addGMFunction(_("buttonGM", "Explain"),function()
		addGMMessage(_("msgGM", "Explanations for missiles and primary station available by clicking those buttons.\n\nClicking the generate button will generate the terrain based on the number of player teams selected, the number of ships on a team and the terrain parameters selected.\n\nAfter you generate the terrain, you cannot change the player ships, or the terrain unless you restart the server. You will be able to get the player ship access control codes after you generate the terrain."))
	end)
end
function setStationSensorRange()
	clearGMFunctions()
	local button_label = _("buttonGM", "Zero")
	if station_sensor_range == 0 then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		station_sensor_range = 0
		mainGMButtons()
	end)
	button_label = _("buttonGM", "5U")
	if station_sensor_range == 5000 then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		station_sensor_range = 5000
		mainGMButtons()
	end)
	button_label = _("buttonGM", "10U")
	if station_sensor_range == 10000 then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		station_sensor_range = 10000
		mainGMButtons()
	end)
	button_label = _("buttonGM", "20U")
	if station_sensor_range == 20000 then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		station_sensor_range = 20000
		mainGMButtons()
	end)
	button_label = _("buttonGM", "30U")
	if station_sensor_range == 30000 then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		station_sensor_range = 30000
		mainGMButtons()
	end)
	addGMFunction(_("buttonGM", "Explain"),function()
		addGMMessage(_("msgGM", "This is where you set the station enemy detection range. Stations that detect enemies will send a warning message to friendly player ships."))
	end)
end
function setPrimaryStationParameters()
	clearGMFunctions()
	addGMFunction(_("buttonGM", "-Main from Prm Stn"),mainGMButtons)
	addGMFunction(_("buttonGM", "-Terrain"),setTerrainParameters)
	if defense_platform_count_options[defense_platform_count_index].count == "random" then
		addGMFunction(_("buttonGM", "+Platforms: Random"),setDefensePlatformCount)
	else
		addGMFunction(string.format(_("buttonGM", "+Platforms: %i"),defense_platform_count_options[defense_platform_count_index].count),setDefensePlatformCount)
	end
	if primary_station_size_index == 1 then
		addGMFunction(_("buttonGM", "Random Size ->"),function()
			primary_station_size_index = primary_station_size_index + 1
			setPrimaryStationParameters()
		end)
	else
		addGMFunction(string.format(_("buttonGM", "%s ->"),primary_station_size_options[primary_station_size_index]),function()
			primary_station_size_index = primary_station_size_index + 1
			if primary_station_size_index > #primary_station_size_options then
				primary_station_size_index = 1
			end
			setPrimaryStationParameters()
		end)
	end
	addGMFunction(string.format(_("buttonGM", "Jammer: %s ->"),primary_jammers),function()
		if primary_jammers == "random" then
			primary_jammers = "on"
		elseif primary_jammers == "on" then
			primary_jammers = "off"
		elseif primary_jammers == "off" then
			primary_jammers = "random"
		end
		setPrimaryStationParameters()
	end)
	addGMFunction(_("buttonGM", "Explain"),function()
		addGMMessage(_("msgGM", "An explanation for platforms can be obtained by clicking the platforms button.\nJust under the platforms, you can choose the primary station size from the options of random, small, medium, large and huge. The label on the button indicates the current selection.\nThe Jammer button determines the presence of warp jammers around the primary station from the options of random, on or off. The label on the button indicates the current selection."))
	end)
end
function setDefensePlatformCount()
	clearGMFunctions()
	addGMFunction(_("buttonGM", "-Main from Platforms"),mainGMButtons)
	addGMFunction(_("buttonGM", "-Terrain"),setTerrainParameters)
	addGMFunction(_("buttonGM", "-Primary Station"),setPrimaryStationParameters)
	if defense_platform_count_index < #defense_platform_count_options then
		if defense_platform_count_options[defense_platform_count_index + 1].count == "random" then
			addGMFunction(string.format(_("buttonGM", "%i Platforms + -> Rnd"),defense_platform_count_options[defense_platform_count_index].count),function()
				defense_platform_count_index = defense_platform_count_index + 1
				setDefensePlatformCount()
			end)
		else
			addGMFunction(string.format(_("buttonGM", "%i Platforms + -> %i"),defense_platform_count_options[defense_platform_count_index].count,defense_platform_count_options[defense_platform_count_index + 1].count),function()
				defense_platform_count_index = defense_platform_count_index + 1
				setDefensePlatformCount()
			end)
		end
	end
	if defense_platform_count_index > 1 then
		if defense_platform_count_options[defense_platform_count_index].count == "random" then
			addGMFunction(string.format(_("buttonGM", "Rnd Platforms - -> %i"),defense_platform_count_options[defense_platform_count_index - 1].count),function()
				defense_platform_count_index = defense_platform_count_index - 1
				setDefensePlatformCount()
			end)
		else
			addGMFunction(string.format(_("buttonGM", "%i Platforms - -> %i"),defense_platform_count_options[defense_platform_count_index].count,defense_platform_count_options[defense_platform_count_index - 1].count),function()
				defense_platform_count_index = defense_platform_count_index - 1
				setDefensePlatformCount()
			end)
		end
	end
	addGMFunction(_("buttonGM", "Explain"),function()
		addGMMessage(_("msgGM", "This is where you determine the number of defense platforms surrounding the players' primary base. The left portion of the text on the button(s) indicates the current selection. The right portion of the text on the button(s) indicates the value after clicking the button."))
	end)
end
--	Display player control codes
function showKraylorCodes()
	showControlCodes("Kraylor")
end
function showExuariCodes()
	showControlCodes("Exuari")
end
function showHumanCodes()
	showControlCodes("Human Navy")
end
function showKtlitanCodes()
	showControlCodes("Ktlitans")
end
function showControlCodes(faction_filter)
	local code_list = {}
	for pidx=1,32 do
		local p = getPlayerShip(pidx)
		if p ~= nil and p:isValid() then
			if faction_filter == "Kraylor" then
				if p:getFaction() == "Kraylor" then
					code_list[p:getCallSign()] = {code = p.control_code, faction = p:getFaction()}
				end
			elseif faction_filter == "Human Navy" then
				if p:getFaction() == "Human Navy" then
					code_list[p:getCallSign()] = {code = p.control_code, faction = p:getFaction()}
				end
			elseif faction_filter == "Exuari" then
				if p:getFaction() == "Exuari" then
					code_list[p:getCallSign()] = {code = p.control_code, faction = p:getFaction()}
				end
			elseif faction_filter == "Ktlitans" then
				if p:getFaction() == "Ktlitans" then
					code_list[p:getCallSign()] = {code = p.control_code, faction = p:getFaction()}
				end
			else
				code_list[p:getCallSign()] = {code = p.control_code, faction = p:getFaction()}
			end
		end
	end
	local sorted_names = {}
	for name in pairs(code_list) do
		table.insert(sorted_names,name)
	end
	table.sort(sorted_names)
	local output = ""
	for idx, name in ipairs(sorted_names) do
		local faction = ""
		if code_list[name].faction == "Kraylor" then
			faction = " (Kraylor)"
		elseif code_list[name].faction == "Ktlitans" then
			faction = " (Ktlitan)"
		elseif code_list[name].faction == "Exuari" then
			faction = " (Exuari)"
		end
		output = output .. string.format(_("msgGM", "%s: %s %s\n"),name,code_list[name].code,faction)
	end
	addGMMessage(output)
end
function resetControlCodes()
	for i,p in ipairs(getActivePlayerShips()) do
		local stem = tableRemoveRandom(control_code_stem)
		local branch = math.random(100,999)
		p.control_code = stem .. branch
		p:setControlCode(stem .. branch)
	end
	showControlCodes()
end
--	General configuration functions
function setGameTimeLimit()
	clearGMFunctions()
	addGMFunction(_("buttonGM", "-Main from Time"),mainGMButtons)
	if game_time_limit < 6000 then
		addGMFunction(string.format(_("buttonGM", "%i Add 5 -> %i"),game_time_limit/60,game_time_limit/60 + 5),function()
			game_time_limit = game_time_limit + 300
			max_game_time = game_time_limit
			setGameTimeLimit()
		end)
	end
	if game_time_limit > 300 then
		addGMFunction(string.format(_("buttonGM", "%i Del 5 -> %i"),game_time_limit/60,game_time_limit/60 - 5),function()
			game_time_limit = game_time_limit - 300
			max_game_time = game_time_limit
			setGameTimeLimit()
		end)
	end
	addGMFunction(_("buttonGM", "Explain"),function()
		addGMMessage(_("msgGM", "This is where you set the time limit for the game. The game ends at the end of the time limit and the faction with the highest score wins."))
	end)
end
function setMissileAvailability()
	clearGMFunctions()
	addGMFunction(_("buttonGM", "-Main from Missiles"),mainGMButtons)
	addGMFunction(_("buttonGM", "-Terrain"),setTerrainParameters)
	local button_label = "unlimited"
	if missile_availability == "unlimited" then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		missile_availability = "unlimited"
		setMissileAvailability()
	end)
	button_label = "outer limited"
	if missile_availability == "outer limited" then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		missile_availability = "outer limited"
		setMissileAvailability()
	end)
	button_label = "limited"
	if missile_availability == "limited" then
		button_label = button_label .. _("buttonGM", "*")
	end
	addGMFunction(button_label,function()
		missile_availability = "limited"
		setMissileAvailability()
	end)
	addGMFunction(_("buttonGM", "Explain"),function()
		addGMMessage(_("msgGM", "This is where you set the missile restock availability for the stations.\nThe 'unlimited' option is typical of most scenarios: you pay reputation to get missiles at stations that offer them.\nThe 'limited' option indicates that stations have a limited supply of missiles available for restock.\nThe 'outer limited' option indicates that all stations except the player's primary station have a limited supply of missiles.\nFor all the options that limit missile availability, the actual stockpiles of missiles is determined randomly for each game."))
	end)
end
function setNPCShips()
	clearGMFunctions()
	addGMFunction(_("buttonGM", "-From NPC Strength"),mainGMButtons)
	local button_label = _("buttonGM", "NPC Ships: No")
	if npc_ships then
		button_label = string.format(_("buttonGM", "NPC Ships: %i-%i"),npc_lower,npc_upper)
	end
	addGMFunction(button_label,function()
		if npc_ships then
			npc_ships = false
		else
			npc_ships = true
		end
		setNPCShips()
	end)
	if npc_ships then
		if npc_lower < npc_upper - 5 then
			addGMFunction(string.format(_("buttonGM", "%i From Add -> %i"),npc_lower,npc_lower + 5),function()
				npc_lower = npc_lower + 5
				setNPCShips()
			end)
		end
		if npc_lower > 10 then
			addGMFunction(string.format(_("buttonGM", "%i From Del -> %i"),npc_lower,npc_lower - 5),function()
				npc_lower = npc_lower - 5
				setNPCShips()
			end)
		end
		if npc_upper < 200 then
			addGMFunction(string.format(_("buttonGM", "%i To Add -> %i"),npc_upper,npc_upper + 5),function()
				npc_upper = npc_upper + 5
				setNPCShips()
			end)
		end
		if npc_upper > npc_lower + 5 then
			addGMFunction(string.format(_("buttonGM", "%i To Del -> %i"),npc_upper,npc_upper - 5),function()
				npc_upper = npc_upper - 5
				setNPCShips()
			end)
		end
	end
	addGMFunction(_("buttonGM", "Explain"),function()
		addGMMessage(_("msgGM", "This is where you configure Non Player Character or NPC ships. Each team will be given NPC ships as configured here. If there should be no NPC ships, be sure the results show 'No'\n\nThe numbers being configured represent a range of relative strength values. For example, the Atlantis has a relative strength of 50. You may set the lower (From) and upper (To) values of this range. The scenario will add ships selected at random that have a total strength within the specified range. Each team will receive identcal NPC ships. These ships will start near the players' primary base and can be directed by the players via Relay or Operations."))
	end)
end
-------------------------------------
--	Generate terrain and stations  --
-------------------------------------
function generateTerrain()
--	Activities include:
--		Central terrain feature
--		Angle from center for each faction (used to place objects symmetrically)
--		Primary station and any defense platforms and/or defensive warp jammers
--		Positioning players around primary station
--		Placing other stations with varying capabilities and capacities
--		Wormholes, black holes, asteroids and nebulae
	if terrain_generated then
		return
	end
	terrain_generated = true
	terrain_center_x = random(200000,300000)
	terrain_center_y = random(100000,200000)
	local ta = Asteroid():setPosition(terrain_center_x,terrain_center_y)
	local terrain_center_sector = ta:getSectorName()
	addGMMessage(string.format("The center of the universe is in sector\n%s",terrain_center_sector))
	ta:destroy()
	place_ref_list = {}
	human_ref_list = {}
	
	--	decide what lives at the center of the universe
	local center_choice_list = {"Planet","Star","Black Hole"}
	local center_choice = center_choice_list[math.random(1,#center_choice_list)]
	if center_choice == "Planet" then
		local center_planet, center_radius = choosePlanet(math.random(2,3),terrain_center_x,terrain_center_y)
		table.insert(place_ref_list,center_planet)
		if random(1,100) <= 50 then
			local mx, my = vectorFromAngleNorth(random(0,360),center_radius + random(1000,2000))
			local moon = choosePlanet(4,terrain_center_x + mx,terrain_center_y + my)
			moon:setOrbit(center_planet,random(200,400))
			table.insert(place_ref_list,moon)
		end
	elseif center_choice == "Star" then
		local center_star, star_radius = choosePlanet(1,terrain_center_x,terrain_center_y)
		table.insert(place_ref_list,center_star)
		if random(1,100) <= 75 then
			local plx, ply = vectorFromAngleNorth(random(0,360),star_radius + random(8000,15000))
			local orbit_planet, orbit_radius = choosePlanet(math.random(2,3),terrain_center_x + plx,terrain_center_y + ply)
			orbit_planet:setOrbit(center_star,random(800,2000))
			table.insert(place_ref_list,orbit_planet)
			if random(1,100) <= 50 then
				local omx, omy = vectorFromAngleNorth(random(0,360),orbit_radius + random(1000,2000))
				local orbit_moon = choosePlanet(4,terrain_center_x + plx + omx,terrain_center_y + ply + omy)
				orbit_moon:setOrbit(orbit_planet,random(200,400))
				table.insert(place_ref_list,orbit_moon)
			end
		end
	elseif center_choice == "Black Hole" then
		local black_hole_names = {
			"Fornax A",
			"Sagittarius A",
			"Triangulum",
			"Cygnus X-3",
			"Messier 110",
			"Virgo A",
			"Andromeda",
			"Sombrero",
			"Great Annihilator",
		}
		table.insert(place_ref_list,BlackHole():setPosition(terrain_center_x,terrain_center_y):setCallSign(black_hole_names[math.random(1,#black_hole_names)]))
	end
	
	--	Set angles
	faction_angle = {}
	npc_fleet = {}
	npc_fleet["Human Navy"] = {}
	npc_fleet["Kraylor"] = {}
	human_angle = random(0,360)
	faction_angle["Human Navy"] = human_angle
	local replicant_increment = 360/player_team_count
	kraylor_angle = (human_angle + replicant_increment) % 360
	faction_angle["Kraylor"] = kraylor_angle
	if player_team_count > 2 then
		exuari_angle = (kraylor_angle + replicant_increment) % 360
		faction_angle["Exuari"] = exuari_angle
		npc_fleet["Exuari"] = {}
	end
	if player_team_count > 3 then
		ktlitan_angle = (exuari_angle + replicant_increment) % 360
		faction_angle["Ktlitans"] = ktlitan_angle
		npc_fleet["Ktlitans"] = {}
	end
	
	if respawn_type == "self" then
		death_penalty = {}
		death_penalty["Human Navy"] = 0
		death_penalty["Kraylor"] = 0
		if exuari_angle ~= nil then
			death_penalty["Exuari"] = 0
		end
		if ktlitan_angle ~= nil then
			death_penalty["Ktlitans"] = 0
		end
	end
	
	--	Set primary stations
	local primary_station_distance = random(50000,100000)
	local primary_station_size = primary_station_size_options[primary_station_size_index]
	if primary_station_size == "random" then
		primary_station_size = szt()
	end
	base_station_value_list = {
		["Huge Station"] 	= 10,
		["Large Station"]	= 5,
		["Medium Station"]	= 3,
		["Small Station"]	= 1,
	}
	faction_primary_station = {}
	local psx, psy = vectorFromAngleNorth(human_angle,primary_station_distance)
	station_primary_human = placeStation(terrain_center_x + psx, terrain_center_y + psy, "Random","Human Navy",primary_station_size)
	faction_primary_station["Human Navy"] = {x = terrain_center_x + psx, y = terrain_center_y + psy, station = station_primary_human}
	station_primary_human.score_value = base_station_value_list[primary_station_size] + 10
	station_list["Human Navy"] = {}
	table.insert(station_list["Human Navy"],station_primary_human)
	table.insert(place_ref_list,station_primary_human)
	table.insert(human_ref_list,station_primary_human)
	local unlimited_missiles = true
	if missile_availability == "limited" then
		unlimited_missiles = false
	end
	station_primary_human.comms_data = {
    	friendlyness = random(75,100),
        weapon_cost =		{
        	Homing =	math.random(1,6), 		
        	Nuke =		math.random(10,30),					
        	Mine =		math.random(2,25),
        	EMP =		math.random(8,20), 
        	HVLI =		math.random(1,4),				
        },
		weapon_available = 	{
			Homing =			true,
			Nuke =				true,
			Mine =				true,
			EMP =				true,
			HVLI =				true,
		},
		weapon_inventory = {
			Unlimited =	unlimited_missiles,
			Homing =	math.floor(math.random(10,50)/difficulty),
			Nuke =		math.floor(math.random(5,30)/difficulty),
			Mine =		math.floor(math.random(8,40)/difficulty),
			EMP =		math.floor(math.random(6,34)/difficulty),
			HVLI =		math.floor(math.random(15,70)/difficulty),
		},
		services = {
			supplydrop = "friend",
			reinforcements = "friend",
			jumpsupplydrop = "friend",
            sensor_boost = "neutral",
			preorder = "friend",
            activatedefensefleet = "neutral",
            jumpovercharge = "neutral",
			jumpsupplydrop = "friend",
		},
		service_cost = {
			supplydrop =		math.random(80,120), 
			reinforcements =	math.random(125,175),
			hornetreinforcements =	math.random(75,125),
			phobosreinforcements =	math.random(175,225),
			jumpsupplydrop =	math.random(110,140),
            activatedefensefleet = math.random(15,40),
            jumpovercharge =	math.random(10,20),
			jumpsupplydrop =	math.random(110,150),
		},
		jump_overcharge =		true,
		probe_launch_repair =	true,
		hack_repair =			true,
		scan_repair =			true,
		combat_maneuver_repair=	true,
		self_destruct_repair =	true,
		tube_slow_down_repair =	true,
        sensor_boost = {value = primary_station_distance-35000, cost = 0},
		reputation_cost_multipliers = {
			friend = 			1.0, 
			neutral = 			3.0,
		},
        max_weapon_refill_amount = {friend = 1.0, neutral = 0.5 },
        goods = {	food = 		{quantity = 10,		cost = 1},
        			medicine =	{quantity = 10,		cost = 5}	},
        trade = {	food = false, medicine = false, luxury = false },
	}
	station_primary_human.comms_data.idle_defense_fleet = defense_fleet_list[primary_station_size][math.random(1,#defense_fleet_list[primary_station_size])]
	psx, psy = vectorFromAngleNorth(kraylor_angle,primary_station_distance)
	station_primary_kraylor = placeStation(terrain_center_x + psx, terrain_center_y + psy, "Random","Kraylor",primary_station_size)
	faction_primary_station["Kraylor"] = {x = terrain_center_x + psx, y = terrain_center_y + psy, station = station_primary_kraylor}
	station_primary_kraylor.score_value = base_station_value_list[primary_station_size] + 10
	station_list["Kraylor"] = {}
	table.insert(station_list["Kraylor"],station_primary_kraylor)
	table.insert(place_ref_list,station_primary_kraylor)
	station_primary_kraylor.comms_data = station_primary_human.comms_data
	if exuari_angle ~= nil then
		psx, psy = vectorFromAngleNorth(exuari_angle,primary_station_distance)
		station_primary_exuari = placeStation(terrain_center_x + psx, terrain_center_y + psy, "Random","Exuari",primary_station_size)
		faction_primary_station["Exuari"] = {x = terrain_center_x + psx, y = terrain_center_y + psy, station = station_primary_exuari}
		station_primary_exuari.score_value = base_station_value_list[primary_station_size] + 10
		station_list["Exuari"] = {}
		table.insert(station_list["Exuari"],station_primary_exuari)
		table.insert(place_ref_list,station_primary_exuari)
		station_primary_exuari.comms_data = station_primary_human.comms_data
	end
	if ktlitan_angle ~= nil then
		psx, psy = vectorFromAngleNorth(ktlitan_angle,primary_station_distance)
		station_primary_ktlitan = placeStation(terrain_center_x + psx, terrain_center_y + psy, "Random","Ktlitans",primary_station_size)
		faction_primary_station["Ktlitans"] = {x = terrain_center_x + psx, y = terrain_center_y + psy, station = station_primary_ktlitan}
		station_primary_ktlitan.score_value = base_station_value_list[primary_station_size] + 10
		station_list["Ktlitans"] = {}
		table.insert(station_list["Ktlitans"],station_primary_ktlitan)
		table.insert(place_ref_list,station_primary_ktlitan)
		station_primary_ktlitan.comms_data = station_primary_human.comms_data
	end
	
	--	Set defense platforms and jammers (if applicable)
	defense_platform_count = defense_platform_count_options[defense_platform_count_index].count
	defense_platform_distance = defense_platform_count_options[defense_platform_count_index].distance
	player_position_distance = defense_platform_count_options[defense_platform_count_index].player
	if defense_platform_count == "random" then
		local index = math.random(1,#defense_platform_count_options - 1)
		defense_platform_count = defense_platform_count_options[index].count
		defense_platform_distance = defense_platform_count_options[index].distance
		player_position_distance = defense_platform_count_options[index].player
	end
	if primary_jammers == "random" then
		primary_jammers = random(1,100) < 50
	else
		if primary_jammers == "on" then
			primary_jammers = true
		else
			primary_jammers = false
		end
	end
	local angle = human_angle
	local vx = 0
	local vy = 0
	unlimited_missiles = false
	if missile_availability == "unlimited" then
		unlimited_missiles = true
	end
	if defense_platform_count > 0 then
		local dp = nil
		angle = human_angle
		psx, psy = station_primary_human:getPosition()
		local dp_list = {}
		for i=1,defense_platform_count do
			vx, vy = vectorFromAngleNorth(angle,defense_platform_distance)
			dp = CpuShip():setTemplate("Defense platform"):setFaction("Human Navy"):setPosition(psx + vx,psy + vy):setScannedByFaction("Human Navy",true):setCallSign(string.format("HDP%i",i)):setDescription(string.format(_("scienceDescription-ship", "%s defense platform %i"),station_primary_human:getCallSign(),i)):orderRoaming()
			dp.score_value = 50
			table.insert(npc_fleet["Human Navy"],dp)
			dp:setCommsScript(""):setCommsFunction(commsDefensePlatform)
			dp.primary_station = station_primary_human
			if primary_jammers then
				vx, vy = vectorFromAngleNorth(angle,defense_platform_distance/2)
				WarpJammer():setPosition(psx + vx, psy + vy):setRange(defense_platform_distance/2 + 4000):setFaction("Human Navy")
			end
			dp.comms_data = {	--defense platform comms data
				weapon_available = 	{
					Homing =			random(1,13)<=(3-difficulty),
					HVLI =				random(1,13)<=(6-difficulty),
					Mine =				false,
					Nuke =				false,
					EMP =				false,
				},
				weapon_inventory = {
					Unlimited =	unlimited_missiles,
					Homing =	math.floor(math.random(10,50)/difficulty),
					Nuke =		0,
					Mine =		0,
					EMP =		0,
					HVLI =		math.floor(math.random(15,70)/difficulty),
				},
				services = {
					supplydrop = "friend",
					reinforcements = "friend",
					jumpsupplydrop = "friend",
				},
				service_cost = {
					supplydrop =		math.random(80,120), 
					reinforcements =	math.random(125,175),
					jumpsupplydrop =	math.random(110,140),
				},
				jump_overcharge =		false,
				probe_launch_repair =	random(1,100) <= (20 - difficulty*2.5),
				hack_repair =			random(1,100) <= (22 - difficulty*2.5),
				scan_repair =			random(1,100) <= (30 - difficulty*2.5),
				combat_maneuver_repair=	random(1,100) <= (15 - difficulty*2.5),
				self_destruct_repair =	random(1,100) <= (25 - difficulty*2.5),
				tube_slow_down_repair =	random(1,100) <= (18 - difficulty*2.5),
				reputation_cost_multipliers = {
					friend = 			1.0, 
					neutral = 			3.0,
				},
			}
			dp:setSharesEnergyWithDocked(random(1,100) <= (60 - difficulty*5))
			dp:setRepairDocked(random(1,100) <= (50 - difficulty*5))
			dp:setRestocksScanProbes(random(1,100) <= (40 - difficulty*5))
			table.insert(dp_list,dp)
			table.insert(place_ref_list,dp)
			table.insert(human_ref_list,dp)
			angle = (angle + 360/defense_platform_count) % 360
		end
		angle = kraylor_angle
		psx, psy = station_primary_kraylor:getPosition()
		for i=1,defense_platform_count do
			vx, vy = vectorFromAngleNorth(angle,defense_platform_distance)
			dp = CpuShip():setTemplate("Defense platform"):setFaction("Kraylor"):setPosition(psx + vx,psy + vy):setScannedByFaction("Kraylor",true):setCallSign(string.format("KDP%i",i)):setDescription(string.format(_("scienceDescription-ship", "%s defense platform %i"),station_primary_kraylor:getCallSign(),i)):orderRoaming()
			dp.score_value = 50
			table.insert(npc_fleet["Kraylor"],dp)
			dp:setCommsScript(""):setCommsFunction(commsDefensePlatform)
			dp.primary_station = station_primary_kraylor
			if primary_jammers then
				vx, vy = vectorFromAngleNorth(angle,defense_platform_distance/2)
				WarpJammer():setPosition(psx + vx, psy + vy):setRange(defense_platform_distance/2 + 4000):setFaction("Kraylor")
			end
			dp.comms_data = dp_list[i].comms_data	--replicate capabilities
			dp:setSharesEnergyWithDocked(dp_list[i]:getSharesEnergyWithDocked())
			dp:setRepairDocked(dp_list[i]:getRepairDocked())
			dp:setRestocksScanProbes(dp_list[i]:getRestocksScanProbes())
			table.insert(place_ref_list,dp)
			angle = (angle + 360/defense_platform_count) % 360
		end
		if exuari_angle ~= nil then
			angle = exuari_angle
			psx, psy = station_primary_exuari:getPosition()
			for i=1,defense_platform_count do
				vx, vy = vectorFromAngleNorth(angle,defense_platform_distance)
				dp = CpuShip():setTemplate("Defense platform"):setFaction("Exuari"):setPosition(psx + vx,psy + vy):setScannedByFaction("Exuari",true):setCallSign(string.format("EDP%i",i)):setDescription(string.format(_("scienceDescription-ship"), "%s defense platform %i",station_primary_exuari:getCallSign(),i)):orderRoaming()
				dp.score_value = 50
				table.insert(npc_fleet["Exuari"],dp)
				dp:setCommsScript(""):setCommsFunction(commsDefensePlatform)
				dp.primary_station = station_primary_exuari
				if primary_jammers then
					vx, vy = vectorFromAngleNorth(angle,defense_platform_distance/2)
					WarpJammer():setPosition(psx + vx, psy + vy):setRange(defense_platform_distance/2 + 4000):setFaction("Exuari")
				end
				dp.comms_data = dp_list[i].comms_data	--replicate capabilities
				dp:setSharesEnergyWithDocked(dp_list[i]:getSharesEnergyWithDocked())
				dp:setRepairDocked(dp_list[i]:getRepairDocked())
				dp:setRestocksScanProbes(dp_list[i]:getRestocksScanProbes())
				table.insert(place_ref_list,dp)
				angle = (angle + 360/defense_platform_count) % 360
			end
		end
		if ktlitan_angle ~= nil then
			angle = ktlitan_angle
			psx, psy = station_primary_ktlitan:getPosition()
			for i=1,defense_platform_count do
				vx, vy = vectorFromAngleNorth(angle,defense_platform_distance)
				dp = CpuShip():setTemplate("Defense platform"):setFaction("Ktlitans"):setPosition(psx + vx,psy + vy):setScannedByFaction("Ktlitans",true):setCallSign(string.format("BDP%i",i)):setDescription(string.format(_("scienceDescription-ship", "%s defense platform %i"),station_primary_ktlitan:getCallSign(),i)):orderRoaming()
				dp.score_value = 50
				table.insert(npc_fleet["Ktlitans"],dp)
				dp:setCommsScript(""):setCommsFunction(commsDefensePlatform)
				dp.primary_station = station_primary_ktlitan
				if primary_jammers then
					vx, vy = vectorFromAngleNorth(angle,defense_platform_distance/2)
					WarpJammer():setPosition(psx + vx, psy + vy):setRange(defense_platform_distance/2 + 4000):setFaction("Ktlitans")
				end
				dp.comms_data = dp_list[i].comms_data	--replicate capabilities
				dp:setSharesEnergyWithDocked(dp_list[i]:getSharesEnergyWithDocked())
				dp:setRepairDocked(dp_list[i]:getRepairDocked())
				dp:setRestocksScanProbes(dp_list[i]:getRestocksScanProbes())
				table.insert(place_ref_list,dp)
				angle = (angle + 360/defense_platform_count) % 360
			end
		end
	else	--no defense platforms
		if primary_jammers then
			local jammer_distance = 4000
			local jammer_range = 8000
			angle = human_angle
			psx, psy = station_primary_human:getPosition()
			for i=1,4 do
				vx, vy = vectorFromAngleNorth(angle,jammer_distance)
				local wj = WarpJammer():setPosition(psx + vx, psy + vy):setRange(jammer_range):setFaction("Human Navy")
				table.insert(place_ref_list,wj)
				table.insert(human_ref_list,wj)
				angle = (angle + 90) % 360
			end
			angle = kraylor_angle
			psx, psy = station_primary_kraylor:getPosition()
			for i=1,4 do
				vx, vy = vectorFromAngleNorth(angle,jammer_distance)
				table.insert(place_ref_list,WarpJammer():setPosition(psx + vx, psy + vy):setRange(jammer_range):setFaction("Kraylor"))
				angle = (angle + 90) % 360
			end
			if exuari_angle ~= nil then
				angle = exuari_angle
				psx, psy = station_primary_exuari:getPosition()
				for i=1,4 do
					vx, vy = vectorFromAngleNorth(angle,jammer_distance)
					table.insert(place_ref_list,WarpJammer():setPosition(psx + vx, psy + vy):setRange(jammer_range):setFaction("Exuari"))
					angle = (angle + 90) % 360
				end
			end
			if ktlitan_angle ~= nil then
				angle = ktlitan_angle
				psx, psy = station_primary_ktlitan:getPosition()
				for i=1,4 do
					vx, vy = vectorFromAngleNorth(angle,jammer_distance)
					table.insert(place_ref_list,WarpJammer():setPosition(psx + vx, psy + vy):setRange(jammer_range):setFaction("Ktlitans"))
					angle = (angle + 90) % 360
				end
			end
		end
	end
	
	--	Place players
	player_restart = {}
	if player_ship_types == "spawned" then
		local player_count = 0
		for pidx=1,32 do
			local p = getPlayerShip(pidx)
			if p ~= nil and p:isValid() then
				player_count = player_count + 1
			end
		end
		local out = ""
		if player_count < ships_per_team then
			if player_count == 0 then
				out = string.format(_("msgGM", "No player ships spawned. %i are required.\n\nUsing default ship set."),ships_per_team)
			elseif player_count == 1 then
				out = string.format(_("msgGM", "Only one player ship spawned. %i are required.\n\nUsing default ship set."),ships_per_team)
			else
				out = string.format(_("msgGM", "Only %i player ships spawned. %i are required.\n\nUsing default ship set."),player_count,ships_per_team)
			end
			player_ship_types = "default"
			addGMMessage(out)
			placeDefaultPlayerShips()
		elseif player_count > ships_per_team then
			if ships_per_team == 1 then
				out = string.format(_("msgGM", "%i player ships spawned. Only %i is required.\n\nUsing default ship set."),player_count,ships_per_team)
			else
				out = string.format(_("msgGM", "%i player ships spawned. Only %i are required.\n\nUsing default ship set."),player_count,ships_per_team)
			end
			player_ship_types = "default"
			addGMMessage(out)
			placeDefaultPlayerShips()
		end
		psx, psy = station_primary_human:getPosition()
		angle = human_angle
		for pidx=1,ships_per_team do
			local p = getPlayerShip(pidx)
			if p ~= nil and p:isValid() then
				setPlayer(p)
				startPlayerPosition(p,angle)
				local respawn_x, respawn_y = p:getPosition()
				p.respawn_x = respawn_x
				p.respawn_y = respawn_y
				player_restart[p:getCallSign()] = {self = p, template = p:getTypeName(), control_code = p.control_code, faction = p:getFaction(), respawn_x = respawn_x, respawn_y = respawn_y}
				angle = (angle + 360/ships_per_team) % 360
			else
				addGMMessage(_("msgGM", "One of the player ships spawned is not valid, switching to default ship set"))
				player_ship_types = "default"
				break
			end
		end
		if player_ship_types == "default" then
			placeDefaultPlayerShips()
		else
			replicatePlayers("Kraylor")
			if exuari_angle ~= nil then
				replicatePlayers("Exuari")
			end
			if ktlitan_angle ~= nil then
				replicatePlayers("Ktlitans")
			end
		end
	elseif player_ship_types == "custom" then
		placeCustomPlayerShips()
	else	--default
		placeDefaultPlayerShips()
	end
	for pidx=1,32 do
		local p = getPlayerShip(pidx)
		if p ~= nil and p:isValid() then
			table.insert(place_ref_list,p)
			if p:getFaction() == "Human Navy" then
				table.insert(human_ref_list,p)
			end
		end
	end
	
	--	Place NPC ships (if applicable)
	local npc_fleet_count = 0
	if npc_ships then
		npc_fleet_count = math.random(1,ships_per_team)
		local fleet_index = 1
		local fleet_angle_increment = 360/npc_fleet_count
		for n=1,npc_fleet_count do
			local angle = (human_angle + n * fleet_angle_increment) % 360
			local fleet_strength = random(npc_lower,npc_upper)
			local pool_selectivity_choices = {"full","less/heavy","more/light"}
			pool_selectivity = pool_selectivity_choices[math.random(1,#pool_selectivity_choices)]
			local fleetComposition_choices = {"Random","Non-DB","Fighters","Chasers","Frigates","Beamers","Missilers","Adders","Drones"}
			fleetComposition = fleetComposition_choices[math.random(1,#fleetComposition_choices)]
			local fcx, fcy = vectorFromAngleNorth(angle,defense_platform_distance + 5000)
			psx, psy = station_primary_human:getPosition()
			local human_fleet = spawnRandomArmed(psx + fcx, psy + fcy, fleet_strength, fleet_index, nil, angle)
			fleet_index = fleet_index + 1
			for idx, ship in ipairs(human_fleet) do
				ship.score_value = ship_template[ship:getTypeName()].strength
				ship:setScannedByFaction("Human Navy",true)
				table.insert(human_ref_list,ship)
				table.insert(place_ref_list,ship)
				table.insert(npc_fleet["Human Navy"],ship)
			end
			fleet_index = fleet_index + 1
			local fleet_prefix = generateCallSignPrefix()
			angle = (kraylor_angle + n * fleet_angle_increment) % 360
			for idx, source_ship in ipairs(human_fleet) do
				local sx, sy = source_ship:getPosition()
				local obj_ref_angle = angleFromVectorNorth(sx, sy, terrain_center_x, terrain_center_y)
				local obj_ref_distance = distance(terrain_center_x, terrain_center_y, sx, sy)
				obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
				local rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
				local selected_template = source_ship:getTypeName()
				local ship = ship_template[selected_template].create("Kraylor",selected_template)
				ship.score_value = ship_template[selected_template].strength
				ship:setScannedByFaction("Kraylor",true)
				ship:setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
				ship:setCallSign(generateCallSign(fleet_prefix))
				ship:setCommsScript(""):setCommsFunction(commsShip)
				ship:orderIdle()
				ship:setHeading(angle)
				ship:setRotation(angle + 270)
				ship.fleetIndex = fleet_index
				table.insert(place_ref_list,ship)
				table.insert(npc_fleet["Kraylor"],ship)
			end
			if exuari_angle ~= nil then
				fleet_index = fleet_index + 1
				local fleet_prefix = generateCallSignPrefix()
				angle = (exuari_angle + n * fleet_angle_increment) % 360
				for idx, source_ship in ipairs(human_fleet) do
					local sx, sy = source_ship:getPosition()
					local obj_ref_angle = angleFromVectorNorth(sx, sy, terrain_center_x, terrain_center_y)
					local obj_ref_distance = distance(terrain_center_x, terrain_center_y, sx, sy)
					obj_ref_angle = (obj_ref_angle + replicant_increment * 2) % 360
					local rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
					local selected_template = source_ship:getTypeName()
					local ship = ship_template[selected_template].create("Exuari",selected_template)
					ship.score_value = ship_template[selected_template].strength
					ship:setScannedByFaction("Exuari",true)
					ship:setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
					ship:setCallSign(generateCallSign(fleet_prefix))
					ship:setCommsScript(""):setCommsFunction(commsShip)
					ship:orderIdle()
					ship:setHeading(angle)
					ship:setRotation(angle + 270)
					ship.fleetIndex = fleet_index
					table.insert(place_ref_list,ship)
					table.insert(npc_fleet["Exuari"],ship)
				end
			end
			if ktlitan_angle ~= nil then
				fleet_index = fleet_index + 1
				local fleet_prefix = generateCallSignPrefix()
				angle = (ktlitan_angle + n * fleet_angle_increment) % 360
				for idx, source_ship in ipairs(human_fleet) do
					local sx, sy = source_ship:getPosition()
					local obj_ref_angle = angleFromVectorNorth(sx, sy, terrain_center_x, terrain_center_y)
					local obj_ref_distance = distance(terrain_center_x, terrain_center_y, sx, sy)
					obj_ref_angle = (obj_ref_angle + replicant_increment * 3) % 360
					local rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
					local selected_template = source_ship:getTypeName()
					local ship = ship_template[selected_template].create("Ktlitans",selected_template)
					ship.score_value = ship_template[selected_template].strength
					ship:setScannedByFaction("Ktlitans",true)
					ship:setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
					ship:setCallSign(generateCallSign(fleet_prefix))
					ship:setCommsScript(""):setCommsFunction(commsShip)
					ship:orderIdle()
					ship:setHeading(angle)
					ship:setRotation(angle + 270)
					ship.fleetIndex = fleet_index
					table.insert(place_ref_list,ship)
					table.insert(npc_fleet["Ktlitans"],ship)
				end
			end
		end
	end

	--	Place stations
	local candidate_x = 0
	local candidate_y = 0
	local center_x = 0
	local center_y = 0
	local perimeter = 0
	local avg_dist = 0
	local bubble = 2500
	local team_station_count_list = {50,25,16,12}
	local stretch_bound = 0
	for i=1,team_station_count_list[player_team_count] do
		center_x, center_y, perimeter, avg_dist = analyzeBlob(human_ref_list)
		stretch_bound = 5000
		repeat
			candidate_x, candidate_y = vectorFromAngleNorth(random(0,360),random(math.min(avg_dist,5000),math.min(perimeter,50000) + stretch_bound))
			candidate_x = center_x + candidate_x
			candidate_y = center_y + candidate_y
			stretch_bound = stretch_bound + 500
		until(farEnough(place_ref_list,candidate_x,candidate_y,math.max(perimeter/i,15000)))
		local sr_size = szt()
		local pStation = placeStation(candidate_x, candidate_y, "Random","Human Navy",sr_size)
		table.insert(station_list["Human Navy"],pStation)
		pStation.score_value = base_station_value_list[sr_size]
		table.insert(place_ref_list,pStation)
		table.insert(human_ref_list,pStation)
		pStation.comms_data = {
			friendlyness = random(15,100),
			weapon_cost =		{
				Homing =	math.random(2,8), 		
				Nuke =		math.random(12,30),					
				Mine =		math.random(3,28),
				EMP =		math.random(9,25), 
				HVLI =		math.random(2,5),				
			},
			weapon_available = 	{
				Homing =	random(1,13)<=(6-difficulty),
				HVLI =		random(1,13)<=(6-difficulty),
				Mine =		random(1,13)<=(5-difficulty),
				Nuke =		random(1,13)<=(4-difficulty),
				EMP =		random(1,13)<=(4-difficulty),
			},
			weapon_inventory = {
				Unlimited =	unlimited_missiles,
				Homing =	math.floor(math.random(10,40)/difficulty),
				Nuke =		math.floor(math.random(5,20)/difficulty),
				Mine =		math.floor(math.random(8,30)/difficulty),
				EMP =		math.floor(math.random(6,24)/difficulty),
				HVLI =		math.floor(math.random(15,50)/difficulty),
			},
			services = {
				supplydrop = "friend",
				reinforcements = "friend",
				jumpsupplydrop = "friend",
				sensor_boost = "neutral",
				preorder = "friend",
				activatedefensefleet = "neutral",
				jumpovercharge = "neutral",
			},
			service_cost = {
				supplydrop =		math.random(80,120), 
				reinforcements =	math.random(125,175),
				hornetreinforcements =	math.random(75,125),
				phobosreinforcements =	math.random(175,225),
				activatedefensefleet = math.random(15,40),
				jumpovercharge =	math.random(10,20),
				jumpsupplydrop =	math.random(110,140),
			},
			jump_overcharge =		random(1,100) <= (20 - difficulty*2.5),
			probe_launch_repair =	random(1,100) <= (33 - difficulty*2.5),
			hack_repair =			random(1,100) <= (42 - difficulty*2.5),
			scan_repair =			random(1,100) <= (50 - difficulty*2.5),
			combat_maneuver_repair=	random(1,100) <= (28 - difficulty*2.5),
			self_destruct_repair =	random(1,100) <= (25 - difficulty*2.5),
			tube_slow_down_repair =	random(1,100) <= (35 - difficulty*2.5),
			reputation_cost_multipliers = {
				friend = 			1.0, 
				neutral = 			3.0,
			},
			max_weapon_refill_amount = {friend = 1.0, neutral = 0.5 },
		}
		pStation.comms_data.idle_defense_fleet = defense_fleet_list[sr_size][math.random(1,#defense_fleet_list[sr_size])]
		pStation:setSharesEnergyWithDocked(random(1,100) <= (50 - difficulty*5))
		pStation:setRepairDocked(random(1,100) <= (40 - difficulty*5))
		pStation:setRestocksScanProbes(random(1,100) <= (30 - difficulty*5))
		if scientist_count < 5 then
			if random(1,100) < 30 then
				if scientist_list["Human Navy"] == nil then
					scientist_list["Human Navy"] = {}
				end
				table.insert(
					scientist_list["Human Navy"],
					{
						name = tableRemoveRandom(scientist_names), 
						topic = tableRemoveRandom(scientist_topics), 
						location = pStation, 
						location_name = pStation:getCallSign(), 
						score_value = scientist_score_value, 
						upgrade_requirement = upgrade_requirements[math.random(1,#upgrade_requirements)], 
						upgrade = tableRemoveRandom(upgrade_list),
						upgrade_automated_application = upgrade_automated_applications[math.random(1,#upgrade_automated_applications)],
					}
				)
				scientist_count = scientist_count + 1
			end
		end
		
		local obj_ref_angle = angleFromVectorNorth(candidate_x, candidate_y, terrain_center_x, terrain_center_y)
		local obj_ref_distance = distance(terrain_center_x, terrain_center_y, candidate_x, candidate_y)
		obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
		local rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
		pStation = placeStation(terrain_center_x + rep_x, terrain_center_y + rep_y, "Random","Kraylor",sr_size)
		table.insert(station_list["Kraylor"],pStation)
		pStation.score_value = base_station_value_list[sr_size]
		pStation.comms_data = human_ref_list[#human_ref_list].comms_data
		pStation:setSharesEnergyWithDocked(human_ref_list[#human_ref_list]:getSharesEnergyWithDocked())
		pStation:setRepairDocked(human_ref_list[#human_ref_list]:getRepairDocked())
		pStation:setRestocksScanProbes(human_ref_list[#human_ref_list]:getRestocksScanProbes())
		table.insert(place_ref_list,pStation)
		if scientist_list["Human Navy"] ~= nil then
			if scientist_list["Kraylor"] == nil then
				scientist_list["Kraylor"] = {}
			end
			if #scientist_list["Kraylor"] < #scientist_list["Human Navy"] then
				table.insert(
					scientist_list["Kraylor"],
					{
						name = tableRemoveRandom(scientist_names), 
						topic = scientist_list["Human Navy"][#scientist_list["Human Navy"]].topic, 
						location = pStation, 
						location_name = pStation:getCallSign(), 
						score_value = scientist_score_value, 
						upgrade_requirement = upgrade_requirements[math.random(1,#upgrade_requirements)], 
						upgrade = scientist_list["Human Navy"][#scientist_list["Human Navy"]].upgrade,
						upgrade_automated_application = scientist_list["Human Navy"][#scientist_list["Human Navy"]].upgrade_automated_application,
					}
				)
			end
		end
		if exuari_angle ~= nil then
			obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
			rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
			pStation = placeStation(terrain_center_x + rep_x, terrain_center_y + rep_y, "Random","Exuari",sr_size)
			table.insert(station_list["Exuari"],pStation)
			pStation.score_value = base_station_value_list[sr_size]
			pStation.comms_data = human_ref_list[#human_ref_list].comms_data
			pStation:setSharesEnergyWithDocked(human_ref_list[#human_ref_list]:getSharesEnergyWithDocked())
			pStation:setRepairDocked(human_ref_list[#human_ref_list]:getRepairDocked())
			pStation:setRestocksScanProbes(human_ref_list[#human_ref_list]:getRestocksScanProbes())
			table.insert(place_ref_list,pStation)
			if scientist_list["Human Navy"] ~= nil then
				if scientist_list["Exuari"] == nil then
					scientist_list["Exuari"] = {}
				end
				if #scientist_list["Exuari"] < #scientist_list["Human Navy"] then
					table.insert(
						scientist_list["Exuari"],
						{
							name = tableRemoveRandom(scientist_names), 
							topic = scientist_list["Human Navy"][#scientist_list["Human Navy"]].topic, 
							location = pStation, 
							location_name = pStation:getCallSign(), 
							score_value = scientist_score_value, 
							upgrade_requirement = upgrade_requirements[math.random(1,#upgrade_requirements)], 
							upgrade = scientist_list["Human Navy"][#scientist_list["Human Navy"]].upgrade,
							upgrade_automated_application = scientist_list["Human Navy"][#scientist_list["Human Navy"]].upgrade_automated_application,
						}
					)
				end
			end
		end
		if ktlitan_angle ~= nil then
			obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
			rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
			pStation = placeStation(terrain_center_x + rep_x, terrain_center_y + rep_y, "Random","Ktlitans",sr_size)
			table.insert(station_list["Ktlitans"],pStation)
			pStation.score_value = base_station_value_list[sr_size]
			pStation.comms_data = human_ref_list[#human_ref_list].comms_data
			pStation:setSharesEnergyWithDocked(human_ref_list[#human_ref_list]:getSharesEnergyWithDocked())
			pStation:setRepairDocked(human_ref_list[#human_ref_list]:getRepairDocked())
			pStation:setRestocksScanProbes(human_ref_list[#human_ref_list]:getRestocksScanProbes())
			table.insert(place_ref_list,pStation)
			if scientist_list["Human Navy"] ~= nil then
				if scientist_list["Ktlitans"] == nil then
					scientist_list["Ktlitans"] = {}
				end
				if #scientist_list["Ktlitans"] < #scientist_list["Human Navy"] then
					table.insert(
						scientist_list["Ktlitans"],
						{
							name = tableRemoveRandom(scientist_names), 
							topic = scientist_list["Human Navy"][#scientist_list["Human Navy"]].topic, 
							location = pStation, 
							location_name = pStation:getCallSign(), 
							score_value = scientist_score_value, 
							upgrade_requirement = upgrade_requirements[math.random(1,#upgrade_requirements)], 
							upgrade = scientist_list["Human Navy"][#scientist_list["Human Navy"]].upgrade,
							upgrade_automated_application = scientist_list["Human Navy"][#scientist_list["Human Navy"]].upgrade_automated_application,
						}
					)
				end
			end
		end
	end	--station build loop
	
	--	Build some wormholes if applicable
	local hole_list = {}
	local wormhole_count = math.random(0,3)
	if wormhole_count > 0 then
		for w=1,wormhole_count do
			center_x, center_y, perimeter, avg_dist = analyzeBlob(human_ref_list)
			stretch_bound = 5000
			bubble = 6000
			repeat
--				print("wormhole candidate numbers. average distance:",avg_dist,"perimeter:",perimeter)
				candidate_x, candidate_y = vectorFromAngleNorth(random(0,360),random(math.min(avg_dist,20000),math.min(perimeter,100000) + stretch_bound))
				candidate_x = center_x + candidate_x
				candidate_y = center_y + candidate_y
				stretch_bound = stretch_bound + 500
			until(farEnough(place_ref_list,candidate_x,candidate_y,bubble))
			local wormhole = WormHole():setPosition(candidate_x,candidate_y)
			table.insert(place_ref_list,wormhole)
			table.insert(human_ref_list,wormhole)
			table.insert(hole_list,wormhole)
			center_x, center_y, perimeter, avg_dist = analyzeBlob(human_ref_list)
			stretch_bound = 5000
			local target_candidate_x = 0
			local target_candidate_y = 0
			repeat
				target_candidate_x, target_candidate_y = vectorFromAngleNorth(random(0,360),random(avg_dist,50000 + perimeter + stretch_bound))
				target_candidate_x = center_x + target_candidate_x
				target_candidate_y = center_y + target_candidate_y
				stretch_bound = stretch_bound + 500
			until(farEnough(place_ref_list,target_candidate_x,target_candidate_y,bubble))
			local ta = VisualAsteroid():setPosition(target_candidate_x,target_candidate_y)
			table.insert(place_ref_list,ta)
			table.insert(human_ref_list,ta)
			wormhole:setTargetPosition(target_candidate_x,target_candidate_y)
			
			local obj_ref_angle = angleFromVectorNorth(candidate_x, candidate_y, terrain_center_x, terrain_center_y)
			local obj_ref_distance = distance(terrain_center_x, terrain_center_y, candidate_x, candidate_y)
			obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
			local rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
			wormhole = WormHole():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
			table.insert(place_ref_list,wormhole)
			table.insert(hole_list,wormhole)
			local target_ref_angle = angleFromVectorNorth(target_candidate_x, target_candidate_y, terrain_center_x, terrain_center_y)
			local target_ref_distance = distance(terrain_center_x, terrain_center_y, target_candidate_x, target_candidate_y)
			target_ref_angle = (target_ref_angle + replicant_increment) % 360
			rep_x, rep_y = vectorFromAngleNorth(target_ref_angle,target_ref_distance)
			wormhole:setTargetPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
			
			if exuari_angle ~= nil then
				obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
				rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
				wormhole = WormHole():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
				table.insert(place_ref_list,wormhole)
				table.insert(hole_list,wormhole)
				target_ref_angle = (target_ref_angle + replicant_increment) % 360
				rep_x, rep_y = vectorFromAngleNorth(target_ref_angle,target_ref_distance)
				wormhole:setTargetPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
			end
			if ktlitan_angle ~= nil then
				obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
				rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
				wormhole = WormHole():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
				table.insert(place_ref_list,wormhole)
				table.insert(hole_list,wormhole)
				target_ref_angle = (target_ref_angle + replicant_increment) % 360
				rep_x, rep_y = vectorFromAngleNorth(target_ref_angle,target_ref_distance)
				wormhole:setTargetPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
			end
		end
	end	--wormhole build
	
	--	Maybe sprinkle in some black holes
	local blackhole_count = math.random(0,6)
	if blackhole_count > 0 then
		for b=1,blackhole_count do
			center_x, center_y, perimeter, avg_dist = analyzeBlob(human_ref_list)
			stretch_bound = 5000
			bubble = 6000
			repeat
				candidate_x, candidate_y = vectorFromAngleNorth(random(0,360),random(math.min(avg_dist,20000),math.min(perimeter,100000) + stretch_bound))
				candidate_x = center_x + candidate_x
				candidate_y = center_y + candidate_y
				stretch_bound = stretch_bound + 500
			until(farEnough(place_ref_list,candidate_x,candidate_y,bubble))
			local blackhole = BlackHole():setPosition(candidate_x,candidate_y)
			table.insert(place_ref_list,blackhole)
			table.insert(human_ref_list,blackhole)
			table.insert(hole_list,blackhole)
			local obj_ref_angle = angleFromVectorNorth(candidate_x, candidate_y, terrain_center_x, terrain_center_y)
			local obj_ref_distance = distance(terrain_center_x, terrain_center_y, candidate_x, candidate_y)
			obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
			local rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
			blackhole = BlackHole():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
			table.insert(place_ref_list,blackhole)
			table.insert(hole_list,blackhole)
			if exuari_angle ~= nil then
				obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
				rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
				blackhole = BlackHole():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
				table.insert(place_ref_list,blackhole)
				table.insert(hole_list,blackhole)
			end
			if ktlitan_angle ~= nil then
				obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
				rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
				blackhole = BlackHole():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
				table.insert(place_ref_list,blackhole)
				table.insert(hole_list,blackhole)
			end
		end
	end	--blackhole build
	
	local mine_field_count = math.random(0,(6-player_team_count))
	local mine_field_type_list = {"line","arc"}
	if mine_field_count > 0 then
		for m=1,mine_field_count do
			center_x, center_y, perimeter, avg_dist = analyzeBlob(human_ref_list)
			stretch_bound = 5000
			bubble = 6000
			repeat
				candidate_x, candidate_y = vectorFromAngleNorth(random(0,360),random(math.min(avg_dist,20000),math.min(perimeter,100000) + stretch_bound))
				candidate_x = center_x + candidate_x
				candidate_y = center_y + candidate_y
				stretch_bound = stretch_bound + 500
			until(farEnough(place_ref_list,candidate_x,candidate_y,bubble))
			local mine_field_type = mine_field_type_list[math.random(1,#mine_field_type_list)]
			local mine_list = {}
			local mine_ref_list = {}
			if mine_field_type == "line" then
				local mle_x, mle_y = vectorFromAngleNorth(random(0,360),random(8000,30000))
				mine_list = createObjectsListOnLine(candidate_x + mle_x, candidate_y + mle_y, candidate_x, candidate_y, 1200, Mine, math.random(1,3))
				for i=1,#mine_list do
					local tm = mine_list[i]
					local mx, my = tm:getPosition()
					if farEnough(place_ref_list,mx,my,1000) and farEnough(mine_ref_list,mx,my,1000) then
						table.insert(mine_ref_list,tm)
						local obj_ref_angle = angleFromVectorNorth(mx, my, terrain_center_x, terrain_center_y)
						local obj_ref_distance = distance(terrain_center_x, terrain_center_y, mx, my)
						obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
						local rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
						table.insert(mine_ref_list,Mine():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y))
						if exuari_angle ~= nil then
							obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
							rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
							table.insert(mine_ref_list,Mine():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y))
						end
						if ktlitan_angle ~= nil then
							obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
							rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
							table.insert(mine_ref_list,Mine():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y))
						end
					else
						tm:destroy()
					end
				end
				for idx, tm in ipairs(mine_ref_list) do
					table.insert(place_ref_list,tm)
				end
			elseif mine_field_type == "arc" then
				local arc_radius = random(8000,25000)
				local mid_angle = random(0,360)
				local spread = random(10,30)
				local angle = (mid_angle + (180 - spread) % 360)
				local mar_x, mar_y = vectorFromAngleNorth(angle,arc_radius)
				local mar_x = mar_x + candidate_x
				local mar_y = mar_y + candidate_y
				local final_angle = (mid_angle + (180 + spread)) % 360
				local mine_count = 0
				local mx, my = vectorFromAngleNorth(angle,arc_radius)
				local tm = Mine():setPosition(mar_x + mx, mar_y + my)
				table.insert(mine_list,tm)
				local angle_increment = 0
				repeat
					angle_increment = angle_increment + 0.1
					mx, my = vectorFromAngleNorth(angle + angle_increment,arc_radius)
				until(distance(tm,mar_x + mx, mar_y + my) > 1200)
				if final_angle <= angle then
					final_angle = final_angle + 360
				end
				repeat
					angle = angle + angle_increment
					mx, my = vectorFromAngleNorth(angle,arc_radius)
					tm = Mine():setPosition(mar_x + mx, mar_y + my)
					table.insert(mine_list,tm)
				until(angle > final_angle)
				for i=1,#mine_list do
					local tm = mine_list[i]
					local mx, my = tm:getPosition()
					if farEnough(place_ref_list,mx,my,1000) and farEnough(mine_ref_list,mx,my,1000) then
						table.insert(mine_ref_list,tm)
						local obj_ref_angle = angleFromVectorNorth(mx, my, terrain_center_x, terrain_center_y)
						local obj_ref_distance = distance(terrain_center_x, terrain_center_y, mx, my)
						obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
						local rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
						table.insert(mine_ref_list,Mine():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y))
						if exuari_angle ~= nil then
							obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
							rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
							table.insert(mine_ref_list,Mine():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y))
						end
						if ktlitan_angle ~= nil then
							obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
							rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
							table.insert(mine_ref_list,Mine():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y))
						end
					else
						tm:destroy()
					end
				end
				for idx, tm in ipairs(mine_ref_list) do
					table.insert(place_ref_list,tm)
				end
			end
		end
	end
	
	--	Asteroid build
	local asteroid_field_count = math.random(2,(10-player_team_count))
	local asteroid_field_type_list = {"blob","line","arc"}
	for a=1,asteroid_field_count do
		center_x, center_y, perimeter, avg_dist = analyzeBlob(human_ref_list)
		stretch_bound = 5000
		bubble = 6000
		repeat
			candidate_x, candidate_y = vectorFromAngleNorth(random(0,360),random(math.min(avg_dist,20000),math.min(perimeter,100000) + stretch_bound))
			candidate_x = center_x + candidate_x
			candidate_y = center_y + candidate_y
			stretch_bound = stretch_bound + 500
		until(farEnough(place_ref_list,candidate_x,candidate_y,bubble))
		local asteroid_field_type = asteroid_field_type_list[math.random(1,#asteroid_field_type_list)]
		local asteroid_list = {}
		local asteroid_ref_list = {}
		if asteroid_field_type == "blob" then
			local blob_count = math.random(10,30)
--			print("blob count:",blob_count)
			asteroid_list = placeRandomListAroundPoint(Asteroid,blob_count,100,15000,candidate_x,candidate_y)
			for i=1,#asteroid_list do
				local ta = asteroid_list[i]
				local ax, ay = ta:getPosition()
				local as = asteroidSize()
				if farEnough(place_ref_list,ax,ay,as) and farEnough(asteroid_ref_list,ax,ay,as) then
					ta:setSize(as)
					table.insert(asteroid_ref_list,ta)
					local obj_ref_angle = angleFromVectorNorth(ax, ay, terrain_center_x, terrain_center_y)
					local obj_ref_distance = distance(terrain_center_x, terrain_center_y, ax, ay)
					obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
					local rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
					table.insert(asteroid_ref_list,Asteroid():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y):setSize(as))
					if exuari_angle ~= nil then
						obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
						rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
						table.insert(asteroid_ref_list,Asteroid():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y):setSize(as))
					end
					if ktlitan_angle ~= nil then
						obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
						rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
						table.insert(asteroid_ref_list,Asteroid():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y):setSize(as))
					end
				else
					ta:destroy()
				end
			end
			for idx, ta in ipairs(asteroid_ref_list) do
				table.insert(place_ref_list,ta)
			end
		elseif asteroid_field_type == "line" then
--			print("asteroid line")
			local ale_x, ale_y = vectorFromAngleNorth(random(0,360),random(8000,30000))
			asteroid_list = createObjectsListOnLine(candidate_x + ale_x, candidate_y + ale_y, candidate_x, candidate_y, random(500,900), Asteroid, 7, 25, 250)
			for i=1,#asteroid_list do
				local ta = asteroid_list[i]
				local ax, ay = ta:getPosition()
				local as = asteroidSize()
				if farEnough(place_ref_list,ax,ay,as) and farEnough(asteroid_ref_list,ax,ay,as) then
					ta:setSize(as)
					table.insert(asteroid_ref_list,ta)
					local obj_ref_angle = angleFromVectorNorth(ax, ay, terrain_center_x, terrain_center_y)
					local obj_ref_distance = distance(terrain_center_x, terrain_center_y, ax, ay)
					obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
					local rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
					table.insert(asteroid_ref_list,Asteroid():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y):setSize(as))
					if exuari_angle ~= nil then
						obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
						rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
						table.insert(asteroid_ref_list,Asteroid():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y):setSize(as))
					end
					if ktlitan_angle ~= nil then
						obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
						rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
						table.insert(asteroid_ref_list,Asteroid():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y):setSize(as))
					end
				else
					ta:destroy()
				end
			end
			for idx, ta in ipairs(asteroid_ref_list) do
				table.insert(place_ref_list,ta)
			end
		elseif asteroid_field_type == "arc" then
			local angle_to_radius = random(0,360)
			local radius_to_arc = random(8000,25000)
			local aar_x, aar_y = vectorFromAngleNorth(angle_to_radius,radius_to_arc)
			local spread = random(10,30)
			local number_in_arc = math.min(math.floor(spread * 2) + math.random(5,20),35)
--			print("asteroid arc number:",number_in_arc)
			asteroid_list = createRandomListAlongArc(Asteroid, number_in_arc, candidate_x + aar_x, candidate_y + aar_y, radius_to_arc, (angle_to_radius + (180-spread)) % 360, (angle_to_radius + (180+spread)) % 360, 1000)
			for i=1,#asteroid_list do
				local ta = asteroid_list[i]
				local ax, ay = ta:getPosition()
				local as = asteroidSize()
				if farEnough(place_ref_list,ax,ay,as) and farEnough(asteroid_ref_list,ax,ay,as) then
					ta:setSize(as)
					table.insert(asteroid_ref_list,ta)
					local obj_ref_angle = angleFromVectorNorth(ax, ay, terrain_center_x, terrain_center_y)
					local obj_ref_distance = distance(terrain_center_x, terrain_center_y, ax, ay)
					obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
					local rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
					table.insert(asteroid_ref_list,Asteroid():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y):setSize(as))
					if exuari_angle ~= nil then
						obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
						rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
						table.insert(asteroid_ref_list,Asteroid():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y):setSize(as))
					end
					if ktlitan_angle ~= nil then
						obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
						rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
						table.insert(asteroid_ref_list,Asteroid():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y):setSize(as))
					end
				else
					ta:destroy()
				end
			end
			for idx, ta in ipairs(asteroid_ref_list) do
				table.insert(place_ref_list,ta)
			end
		end
	end	--	asteroid fields build
	
	--	Nebula build
	local nebula_field_count = math.random(2,8)
	center_x, center_y, perimeter, avg_dist = analyzeBlob(human_ref_list)
	for n=1,nebula_field_count do
		stretch_bound = 5000
		bubble = 7000
		repeat
			candidate_x, candidate_y = vectorFromAngleNorth(random(0,360),random(math.min(avg_dist,20000),math.min(perimeter,100000) + stretch_bound))
			candidate_x = center_x + candidate_x
			candidate_y = center_y + candidate_y
			stretch_bound = stretch_bound + 500
		until(farEnough(hole_list,candidate_x,candidate_y,bubble))
		local neb = Nebula():setPosition(candidate_x,candidate_y)
		local nebula_field = {}
		table.insert(nebula_field,neb)
		local nebula_field_size = math.random(0,5)
		if nebula_field_size > 0 then
			for i=1,nebula_field_size do
				local na_x = 0
				local na_y = 0
				local nx = 0
				local ny = 0
				local attempts = 0
				repeat
					na_x, na_y = vectorFromAngleNorth(random(0,360),random(8000,9500))
					nx, ny = nebula_field[math.random(1,#nebula_field)]:getPosition()
					attempts = attempts + 1
				until(farEnough(hole_list, na_x + nx, na_y + ny, bubble) or attempts > 50)
				if attempts <= 50 then
					neb = Nebula():setPosition(na_x + nx, na_y + ny)
					table.insert(nebula_field,neb)
				else
					break
				end
			end
		end
		for i=1,#nebula_field do
			candidate_x, candidate_y = nebula_field[i]:getPosition()
			local obj_ref_angle = angleFromVectorNorth(candidate_x, candidate_y, terrain_center_x, terrain_center_y)
			local obj_ref_distance = distance(terrain_center_x, terrain_center_y, candidate_x, candidate_y)
			obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
			local rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
			Nebula():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
			if exuari_angle ~= nil then
				obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
				rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
				Nebula():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
			end
			if ktlitan_angle ~= nil then
				obj_ref_angle = (obj_ref_angle + replicant_increment) % 360
				rep_x, rep_y = vectorFromAngleNorth(obj_ref_angle,obj_ref_distance)
				Nebula():setPosition(terrain_center_x + rep_x, terrain_center_y + rep_y)
			end
		end
	end	--	nebula field build
	game_state = "terrain generated"
	
	--	Store (then print) original values for later comparison
	local stat_list = gatherStats()
	original_score = {}
	local out = "Original scores:"
	original_score["Human Navy"] = stat_list.human.weighted_score
	out = out .. string.format("\nHuman Navy: %.2f",stat_list.human.weighted_score)
	original_score["Kraylor"] = stat_list.kraylor.weighted_score
	out = out .. string.format("\nKraylor: %.2f",stat_list.kraylor.weighted_score)
	if exuari_angle ~= nil then
		original_score["Exuari"] = stat_list.exuari.weighted_score
		out = out .. string.format("\nExuari: %.2f",stat_list.exuari.weighted_score)
	end
	if ktlitan_angle ~= nil then
		original_score["Ktlitans"] = stat_list.ktlitan.weighted_score
		out = out .. string.format("\nKtlitans: %.2f",stat_list.ktlitan.weighted_score)
	end
	allowNewPlayerShips(false)
	print(out)
	--	Provide summary terrain details in console log
	print("-----     Terrain Info     -----")
	print("Center:",terrain_center_sector,"featuring:",center_choice)
	print("Primary stations:",primary_station_size,"Jammers:",primary_jammers,"defense platforms:",defense_platform_count)
	local output_player_types = player_ship_types
	if player_ship_types == "custom" then
		output_player_types = output_player_types .. " (" .. custom_player_ship_type .. ")"
	end
	print("Teams:",player_team_count,"Player ships:",ships_per_team .. "(" .. ships_per_team*player_team_count .. ")","Player ship types:",output_player_types)
	print("NPC Fleets:",npc_fleet_count .. "(" .. npc_fleet_count*player_team_count .. ")")
	print("Wormholes:",wormhole_count .. "(" .. wormhole_count*player_team_count .. ")","Black holes:",blackhole_count .. "(" .. blackhole_count*player_team_count .. ")")
	print("Asteroid fields:",asteroid_field_count .. "(" .. asteroid_field_count*player_team_count .. ")","Nebula groups:",nebula_field_count .. "(" .. nebula_field_count*player_team_count .. ")")
end
function spawnRandomArmed(x, y, enemyStrength, fleetIndex, shape, angle)
--x and y are central spawn coordinates
--fleetIndex is the number of the fleet to be spawned
--sl (was) the score list, nl is the name list, bl is the boolean list
--spawn_distance optional - used for ambush or pyramid
--spawn_angle optional - used for ambush or pyramid
--px and py are the player coordinates or the pyramid fly towards point coordinates
	local sp = 1000			--spacing of spawned group
	if shape == nil then
		local shape_choices = {"square","hexagonal"}
		shape = shape_choices[math.random(1,#shape_choices)]
	end
	local enemy_position = 0
	local enemyList = {}
	local template_pool = getTemplatePool(enemyStrength)
	if #template_pool < 1 then
		addGMMessage(_("msgGM", "Empty Template pool: fix excludes or other criteria"))
		return enemyList
	end
	local fleet_prefix = generateCallSignPrefix()
	while enemyStrength > 0 do
		local selected_template = template_pool[math.random(1,#template_pool)]
--		print("selected template:",selected_template)
--		print("base:",ship_template[selected_template].base)
		local ship = ship_template[selected_template].create("Human Navy",selected_template)
		ship:setCallSign(generateCallSign(fleet_prefix))
		ship:setCommsScript(""):setCommsFunction(commsShip)
		ship:orderIdle()
		ship:setHeading(angle)
		ship:setRotation(angle + 270)
		enemy_position = enemy_position + 1
		ship:setPosition(x + formation_delta[shape].x[enemy_position] * sp, y + formation_delta[shape].y[enemy_position] * sp)
		ship.fleetIndex = fleetIndex
		table.insert(enemyList, ship)
		enemyStrength = enemyStrength - ship_template[selected_template].strength
	end
	return enemyList
end
function getTemplatePool(max_strength)
	local function getStrengthSort(tbl, sortFunction)
		local keys = {}
		for key in pairs(tbl) do
			table.insert(keys,key)
		end
		table.sort(keys, function(a,b)
			return sortFunction(tbl[a], tbl[b])
		end)
		return keys
	end
	local ship_template_by_strength = getStrengthSort(ship_template, function(a,b)
		return a.strength > b.strength
	end)
	local template_pool = {}
--	print("fleet composition:",fleetComposition,"fleet group sub fleet composition:",fleet_group[fleetComposition])
	if pool_selectivity == "less/heavy" then
		for idx, current_ship_template in ipairs(ship_template_by_strength) do
--			print("currrent ship template:",current_ship_template,"strength:",ship_template[current_ship_template].strength,"max strength:",max_strength)
			if ship_template[current_ship_template].strength <= max_strength then
				if fleetComposition == "Non-DB" then
					if ship_template[current_ship_template].create ~= stockTemplate then
						table.insert(template_pool,current_ship_template)
					end
				elseif fleetComposition == "Random" then
					table.insert(template_pool,current_ship_template)
				else
					if ship_template[current_ship_template][fleet_group[fleetComposition]] then
						table.insert(template_pool,current_ship_template)							
					end
				end
			end
			if #template_pool >= 5 then
				break
			end
		end
	elseif pool_selectivity == "more/light" then
		for i=#ship_template_by_strength,1,-1 do
			local current_ship_template = ship_template_by_strength[i]
--			print("currrent ship template:",current_ship_template,"strength:",ship_template[current_ship_template].strength,"max strength:",max_strength)
			if ship_template[current_ship_template].strength <= max_strength then
				if fleetComposition == "Non-DB" then
					if ship_template[current_ship_template].create ~= stockTemplate then
						table.insert(template_pool,current_ship_template)
					end
				elseif fleetComposition == "Random" then
					table.insert(template_pool,current_ship_template)
				else
					if ship_template[current_ship_template][fleet_group[fleetComposition]] then
						table.insert(template_pool,current_ship_template)							
					end
				end
			end
			if #template_pool >= 20 then
				break
			end
		end
	else	--full
		for current_ship_template, details in pairs(ship_template) do
			if details.strength <= max_strength then
				if fleetComposition == "Non-DB" then
					if ship_template[current_ship_template].create ~= stockTemplate then
						table.insert(template_pool,current_ship_template)
					end
				elseif fleetComposition == "Random" then
					table.insert(template_pool,current_ship_template)
				else
					if ship_template[current_ship_template][fleet_group[fleetComposition]] then
						table.insert(template_pool,current_ship_template)							
					end
				end
			end
		end
	end
	--print("returning template pool containing these templates:")
	--for idx, template in ipairs(template_pool) do
	--	print(template)
	--end
	return template_pool
end
function stockTemplate(enemyFaction,template)
	local ship = CpuShip():setFaction(enemyFaction):setTemplate(template):orderRoaming()
	ship:onTakingDamage(function(self,instigator)
		string.format("")	--serious proton needs a global context
		if instigator ~= nil then
			self.damage_instigator = instigator
		end
	end)
	return ship
end

function tableRemoveRandom(array)
--	Remove random element from array and return it.
	-- Returns nil if the array is empty,
	-- analogous to `table.remove`.
    local array_item_count = #array
    if array_item_count == 0 then
        return nil
    end
    local selected_item = math.random(array_item_count)
    array[selected_item], array[array_item_count] = array[array_item_count], array[selected_item]
    return table.remove(array)
end

function asteroidSize()
	return random(1,160)+random(1,120)+random(1,80)+random(1,40)+random(1,20)+random(1,10)
end
function createRandomListAlongArc(object_type, amount, x, y, distance, startArc, endArcClockwise, randomize)
-- Create amount of objects of type object_type along arc
-- Center defined by x and y
-- Radius defined by distance
-- Start of arc between 0 and 360 (startArc), end arc: endArcClockwise
-- Use randomize to vary the distance from the center point. Omit to keep distance constant
-- Example:
--   createRandomAlongArc(Asteroid, 100, 500, 3000, 65, 120, 450)
	local list = {}
	if randomize == nil then randomize = 0 end
	if amount == nil then amount = 1 end
	local arcLen = endArcClockwise - startArc
	if startArc > endArcClockwise then
		endArcClockwise = endArcClockwise + 360
		arcLen = arcLen + 360
	end
	if amount > arcLen then
		for ndex=1,arcLen do
			local radialPoint = startArc+ndex
			local pointDist = distance + random(-randomize,randomize)
			table.insert(list,object_type():setPosition(x + math.cos(radialPoint / 180 * math.pi) * pointDist, y + math.sin(radialPoint / 180 * math.pi) * pointDist))
		end
		for ndex=1,amount-arcLen do
			radialPoint = random(startArc,endArcClockwise)
			pointDist = distance + random(-randomize,randomize)
			table.insert(list,object_type():setPosition(x + math.cos(radialPoint / 180 * math.pi) * pointDist, y + math.sin(radialPoint / 180 * math.pi) * pointDist))
		end
	else
		for ndex=1,amount do
			radialPoint = random(startArc,endArcClockwise)
			pointDist = distance + random(-randomize,randomize)
			table.insert(list,object_type():setPosition(x + math.cos(radialPoint / 180 * math.pi) * pointDist, y + math.sin(radialPoint / 180 * math.pi) * pointDist))
		end
	end
	return list
end
function createObjectsListOnLine(x1, y1, x2, y2, spacing, object_type, rows, chance, randomize)
-- Create objects along a line between two vectors, optionally with grid
-- placement and randomization.
--
-- createObjectsOnLine(x1, y1, x2, y2, spacing, object_type, rows, chance, randomize)
--   x1, y1: Starting coordinates
--   x2, y2: Ending coordinates
--   spacing: The distance between each object.
--   object_type: The object type. Calls `object_type():setPosition()`.
--   rows (optional): The number of rows, minimum 1. Defaults to 1.
--   chance (optional): The percentile chance an object will be created,
--     minimum 1. Defaults to 100 (always).
--   randomize (optional): If present, randomize object placement by this
--     amount. Defaults to 0 (grid).
--
--   Examples: To create a mine field, run:
--     createObjectsOnLine(0, 0, 10000, 0, 1000, Mine, 4)
--   This creates 4 rows of mines from 0,0 to 10000,0, with mines spaced 1U
--   apart.
--
--   The `randomize` parameter adds chaos to the pattern. This works well for
--   asteroid fields:
--     createObjectsOnLine(0, 0, 10000, 0, 300, Asteroid, 4, 100, 800)
	local list = {}
    if rows == nil then rows = 1 end
    if chance == nil then chance = 100 end
    if randomize == nil then randomize = 0 end
    local d = distance(x1, y1, x2, y2)
    local xd = (x2 - x1) / d
    local yd = (y2 - y1) / d
    for cnt_x=0,d,spacing do
        for cnt_y=0,(rows-1)*spacing,spacing do
            local px = x1 + xd * cnt_x + yd * (cnt_y - (rows - 1) * spacing * 0.5) + random(-randomize, randomize)
            local py = y1 + yd * cnt_x - xd * (cnt_y - (rows - 1) * spacing * 0.5) + random(-randomize, randomize)
            if random(0, 100) < chance then
                table.insert(list,object_type():setPosition(px, py))
            end
        end
    end
    return list
end
function placeRandomListAroundPoint(object_type, amount, dist_min, dist_max, x0, y0)
-- create amount of object_type, at a distance between dist_min and dist_max around the point (x0, y0) 
-- save in a list that is returned to caller
	local object_list = {}
    for n=1,amount do
        local r = random(0, 360)
        local distance = random(dist_min, dist_max)
        x = x0 + math.cos(r / 180 * math.pi) * distance
        y = y0 + math.sin(r / 180 * math.pi) * distance
        table.insert(object_list,object_type():setPosition(x, y))
    end
    return object_list
end
function placeRandomAsteroidsAroundPoint(amount, dist_min, dist_max, x0, y0)
-- create amount of asteroid, at a distance between dist_min and dist_max around the point (x0, y0)
    for n=1,amount do
        local r = random(0, 360)
        local distance = random(dist_min, dist_max)
        x = x0 + math.cos(r / 180 * math.pi) * distance
        y = y0 + math.sin(r / 180 * math.pi) * distance
        local asteroid_size = random(1,100) + random(1,75) + random(1,75) + random(1,20) + random(1,20) + random(1,20) + random(1,20) + random(1,20) + random(1,20) + random(1,20)
        Asteroid():setPosition(x, y):setSize(asteroid_size)
    end
end
function choosePlanet(index,x,y)
	local planet_list = {
		{
			radius = random(500,1500), distance = -2000, 
			name = {"Gamma Piscium","Beta Lyporis","Sigma Draconis","Iota Carinae","Theta Arietis","Epsilon Indi","Beta Hydri"},
			color = {
				red = random(0.9,1), green = random(0.85,1), blue = random(0.9,1)
			},
			texture = {
				atmosphere = "planets/star-1.png"
			},
		},
		{
			radius = random(2500,4000), distance = -2000, rotation = random(250,350),
			name = {"Bespin","Aldea","Bersallis","Alpha Omicron","Farius Prime","Deneb","Mordan","Nelvana"},
			texture = {
				surface = "planets/gas-1.png"
			},
		},
		{
			radius = random(2000,3500), distance = -2000, rotation = random(350,450),
			name = {"Alderaan","Dagobah","Dantooine","Rigel","Pahvo","Penthara","Scalos","Tanuga","Vacca","Terlina","Timor"},
			color = {
				red = random(0.1,0.3), green = random(0.1,0.3), blue = random(0.9,1)
			},
			texture = {
				surface = "planets/planet-1.png", cloud = "planets/clouds-1.png", atmosphere = "planets/atmosphere.png"
			},
		},
		{
			radius = random(200,400), distance = -150, rotation = random(60,100),
			name = {"Adrastea","Belior","Cressida","Europa","Kyrrdis","Oberon","Pallas","Telesto","Vesta"},
			texture = {
				surface = "planets/moon-1.png"
			}
		},
	}
	local planet = Planet():setPosition(x,y):setPlanetRadius(planet_list[index].radius):setDistanceFromMovementPlane(planet_list[index].distance):setCallSign(planet_list[index].name[math.random(1,#planet_list[index].name)])
	if planet_list[index].texture.surface ~= nil then
		planet:setPlanetSurfaceTexture(planet_list[index].texture.surface)
	end
	if planet_list[index].texture.atmosphere ~= nil then
		planet:setPlanetAtmosphereTexture(planet_list[index].texture.atmosphere)
	end
	if planet_list[index].texture.cloud ~= nil then
		planet:setPlanetCloudTexture(planet_list[index].texture.cloud)
	end
	if planet_list[index].color ~= nil then
		planet:setPlanetAtmosphereColor(planet_list[index].color.red,planet_list[index].color.green,planet_list[index].color.blue)
	end
	if planet_list[index].rotation ~= nil then
		planet:setAxialRotationTime(planet_list[index].rotation)
	end
	return planet, planet_list[index].radius
end
function vectorFromAngleNorth(angle,distance)
	angle = (angle + 270) % 360
	local x, y = vectorFromAngle(angle,distance)
	return x, y
end
function angleFromVectorNorth(p1x,p1y,p2x,p2y)
	TWOPI = 6.2831853071795865
	RAD2DEG = 57.2957795130823209
	atan2parm1 = p2x - p1x
	atan2parm2 = p2y - p1y
	theta = math.atan2(atan2parm1, atan2parm2)
	if theta < 0 then
		theta = theta + TWOPI
	end
	return (360 - (RAD2DEG * theta)) % 360
end
function analyzeBlob(object_list)
--given a blob (list) of objects, find the center and the max perimeter and avg dist values
	local center_x = 0
	local center_y = 0
	local max_perimeter = 0
	local total_distance = 0
	local average_distance = 0
	if object_list ~= nil and #object_list > 0 then
		for i=1,#object_list do
			local obj_x, obj_y = object_list[i]:getPosition()
			center_x = center_x + obj_x
			center_y = center_y + obj_y
		end
		center_x = center_x/#object_list
		center_y = center_y/#object_list
		for i=1,#object_list do
--[[
			if distance_diagnostic then
				print("function analyzeBlob")
				if object_list[i] == nil then
					print("   object_list[i] is nil")
					print("   " .. i)
					print("   " .. object_list)
				else
					print("   " .. i,object_list[i])
				end
				if center_x == nil then
					print("   center_x is nil")
				else
					print("   center_x: " .. center_x)
				end
			end
--]]
			local current_distance = distance(object_list[i],center_x,center_y)
			total_distance = total_distance + current_distance
			if current_distance >= max_perimeter then
				max_perimeter = current_distance
			end
		end
		average_distance = total_distance/#object_list
	end
	return center_x, center_y, max_perimeter, average_distance
end
function farEnough(list,pos_x,pos_y,bubble)
	local far_enough = true
	for i=1,#list do
		local list_item = list[i]
--[[
		if distance_diagnostic then
			print("function farEnough")
			if list_item == nil then
				print("   list_item is nil")
				print("   " .. i)
				print("   " .. list)
			else
				print("   " .. i)
				print(list_item)
			end
			if pos_x == nil then
				print("   pos_x is nil")
			else
				print("   pos_x: " .. pos_x)
			end
		end
--]]
		local distance_away = distance(list_item,pos_x,pos_y)
		if distance_away < bubble then
			far_enough = false
			break
		end
		if isObjectType(list_item,"BlackHole") or isObjectType(list_item,"WormHole") then
			if distance_away < 6000 then
				far_enough = false
				break
			end
		end
		if isObjectType(list_item,"Planet") then
			if distance_away < 4000 then
				far_enough = false
				break
			end
		end
	end
	return far_enough
end
--	Player ship types, placement and naming functions
function placeCustomPlayerShips()
	print("place custom player ships")
	player_restart = {}
	for pidx=1,32 do
		local p = getPlayerShip(pidx)
		if p ~= nil and p:isValid() then
			p:destroy()
		end
	end
	local angle = human_angle
	for idx, template in ipairs(custom_player_ship_sets[custom_player_ship_type][ships_per_team]) do
--		print("Human ships per team template:",template)
		local p = nil
		if player_ship_stats[template].stock then
			p = PlayerSpaceship():setTemplate(template):setFaction("Human Navy")
		else
			p = customPlayerShip(template)
			p:setFaction("Human Navy")
		end
		setPlayer(p)
		startPlayerPosition(p,angle)
		local respawn_x, respawn_y = p:getPosition()
		p.respawn_x = respawn_x
		p.respawn_y = respawn_y
		player_restart[p:getCallSign()] = {self = p, template = p:getTypeName(), control_code = p.control_code, faction = p:getFaction(), respawn_x = respawn_x, respawn_y = respawn_y}
		angle = (angle + 360/ships_per_team) % 360
	end
	replicatePlayers("Kraylor")
	if exuari_angle ~= nil then
		replicatePlayers("Exuari")
	end
	if ktlitan_angle ~= nil then
		replicatePlayers("Ktlitans")
	end
end
function customPlayerShip(custom_template,p)
	if player_ship_stats[custom_template] == nil then
		print("Invalid custom player ship template")
		return nil
	end
	if p == nil then
		p = PlayerSpaceship()
	end
	if custom_template == "Striker LX" then
		p:setTemplate("Striker")
		p:setTypeName("Striker LX")
		p:setRepairCrewCount(3)						--more (vs 2)
		p:setShieldsMax(100,100)					--stronger shields (vs 50, 30)
		p:setShields(100,100)
		p:setHullMax(100)							--weaker hull (vs 120)
		p:setHull(100)
		p:setMaxEnergy(600)							--more maximum energy (vs 500)
		p:setEnergy(600)
		p:setImpulseMaxSpeed(65)					--faster impulse max (vs 45)
	--                 	   Arc, Dir,   Range, CycleTime, Damage
		p:setBeamWeapon(0,  10, -15,	1100, 		6.0, 	6.5)	--shorter (vs 1200) more damage (vs 6.0)
		p:setBeamWeapon(1,  10,  15,	1100, 		6.0,	6.5)
	--							 Arc, Dir, Rotate speed
		p:setBeamWeaponTurret(0, 100, -15, .2)		--slower turret speed (vs 6)
		p:setBeamWeaponTurret(1, 100,  15, .2)
		p:setWeaponTubeCount(2)						--more tubes (vs 0)
		p:setWeaponTubeDirection(0,180)				
		p:setWeaponTubeDirection(1,180)
		p:setWeaponStorageMax("Homing",4)
		p:setWeaponStorage("Homing", 4)	
		p:setWeaponStorageMax("Nuke",2)	
		p:setWeaponStorage("Nuke", 2)	
		p:setWeaponStorageMax("EMP",3)	
		p:setWeaponStorage("EMP", 3)		
		p:setWeaponStorageMax("Mine",3)	
		p:setWeaponStorage("Mine", 3)	
		p:setWeaponStorageMax("HVLI",6)	
		p:setWeaponStorage("HVLI", 6)	
	elseif custom_template == "Focus" then
		p:setTemplate("Crucible")
		p:setTypeName("Focus")
		p:setImpulseMaxSpeed(70)					--slower (vs 80)
		p:setRotationMaxSpeed(20)					--faster spin (vs 15)
		p:setWarpDrive(false)						--no warp
		p:setHullMax(100)							--weaker hull (vs 160)
		p:setHull(100)
		p:setShieldsMax(100, 100)					--weaker shields (vs 160, 160)
		p:setShields(100, 100)
	--                 	   Arc, Dir,  Range,  CycleTime, Damage
		p:setBeamWeapon(0,  60, -20, 1000.0,		6.0, 5)	--narrower (vs 70)
		p:setBeamWeapon(1,  60,  20, 1000.0,		6.0, 5)	
		p:setWeaponTubeCount(4)						--fewer (vs 6)
		p:weaponTubeAllowMissle(2,"Homing")			--big tube shoots more stuff (vs HVLI)
		p:weaponTubeAllowMissle(2,"EMP")
		p:weaponTubeAllowMissle(2,"Nuke")
		p:setWeaponTubeExclusiveFor(3,"Mine")		--rear (vs left)
		p:setWeaponTubeDirection(3, 180)
		p:setWeaponStorageMax("EMP",2)				--fewer (vs 6)
		p:setWeaponStorage("EMP", 2)				
		p:setWeaponStorageMax("Nuke",1)				--fewer (vs 4)
		p:setWeaponStorage("Nuke", 1)	
	elseif custom_template == "Holmes" then
		p:setTemplate("Crucible")
		p:setTypeName("Holmes")
		p:setImpulseMaxSpeed(70)					--slower (vs 80)
	--					  Arc, Dir, Range, CycleTime, Dmg
		p:setBeamWeapon(0, 50, -85, 900.0, 		6.0, 5)	--broadside beams, narrower (vs 70)
		p:setBeamWeapon(1, 50, -95, 900.0, 		6.0, 5)	
		p:setBeamWeapon(2, 50,  85, 900.0, 		6.0, 5)	
		p:setBeamWeapon(3, 50,  95, 900.0, 		6.0, 5)	
		p:setWeaponTubeCount(4)						--fewer (vs 6)
		p:setWeaponTubeExclusiveFor(0,"Homing")		--tubes only shoot homing missiles (vs more options)
		p:setWeaponTubeExclusiveFor(1,"Homing")
		p:setWeaponTubeExclusiveFor(2,"Homing")
		p:setWeaponTubeExclusiveFor(3,"Mine")
		p:setWeaponTubeDirection(3, 180)
		p:setWeaponStorageMax("Homing",10)			--more (vs 8)
		p:setWeaponStorage("Homing", 10)				
		p:setWeaponStorageMax("HVLI",0)				--fewer
		p:setWeaponStorage("HVLI", 0)				
		p:setWeaponStorageMax("EMP",0)				--fewer
		p:setWeaponStorage("EMP", 0)				
		p:setWeaponStorageMax("Nuke",0)				--fewer
		p:setWeaponStorage("Nuke", 0)	
	elseif custom_template == "Maverick XP" then
		p:setTemplate("Maverick")
		p:setTypeName("Maverick XP")
		p:setImpulseMaxSpeed(65)				--slower impulse max (vs 80)
		p:setWarpDrive(false)					--no warp
	--					  Arc, Dir,  Range, CycleTime, Dmg
		p:setBeamWeapon(0, 10,   0, 1000.0,      20.0, 20)
	--							 Arc, Dir, Rotate speed
		p:setBeamWeaponTurret(0, 270,   0, .4)
		p:setBeamWeaponEnergyPerFire(0,p:getBeamWeaponEnergyPerFire(0)*6)
		p:setBeamWeaponHeatPerFire(0,p:getBeamWeaponHeatPerFire(0)*5)
		p:setBeamWeapon(1, 0, 0, 0, 0, 0)		--eliminate 5 beams
		p:setBeamWeapon(2, 0, 0, 0, 0, 0)				
		p:setBeamWeapon(3, 0, 0, 0, 0, 0)				
		p:setBeamWeapon(4, 0, 0, 0, 0, 0)	
		p:setBeamWeapon(5, 0, 0, 0, 0, 0)	
	elseif custom_template == "Phobos T2" then
		p:setTemplate("Phobos M3P")
		p:setTypeName("Phobos T2")
		p:setRepairCrewCount(4)					--more repair crew (vs 3)
		p:setRotationMaxSpeed(20)				--faster spin (vs 10)
		p:setShieldsMax(120,80)					--stronger front, weaker rear (vs 100,100)
		p:setShields(120,80)
		p:setMaxEnergy(800)						--less maximum energy (vs 1000)
		p:setEnergy(800)
	--					  Arc, Dir, Range, CycleTime, Dmg
		p:setBeamWeapon(0, 10, -30,  1200,         4, 6)	--split direction (30 vs 15)
		p:setBeamWeapon(1, 10,  30,  1200,         4, 6)	--reduced cycle time (4 vs 8)
	--							Arc, Dir, Rotate speed
		p:setBeamWeaponTurret(0, 60, -30, .3)	--slow turret beams
		p:setBeamWeaponTurret(1, 60,  30, .3)
		p:setWeaponTubeCount(2)					--one fewer tube (1 forward, 1 rear vs 2 forward, 1 rear)
		p:setWeaponTubeDirection(0,0)			--first tube points straight forward
		p:setWeaponTubeDirection(1,180)			--second tube points straight back
		p:setWeaponTubeExclusiveFor(1,"Mine")
		p:setWeaponStorageMax("Homing",8)		--reduce homing storage (vs 10)
		p:setWeaponStorage("Homing",8)
		p:setWeaponStorageMax("HVLI",16)		--reduce HVLI storage (vs 20)
		p:setWeaponStorage("HVLI",16)
	end
	return p
end
function placeDefaultPlayerShips()
	player_restart = {}
	for pidx=1,32 do
		local p = getPlayerShip(pidx)
		if p ~= nil and p:isValid() then
			p:destroy()
		end
	end
	angle = faction_angle["Human Navy"]
	for idx, template in ipairs(default_player_ship_sets[ships_per_team]) do
		local p = PlayerSpaceship():setTemplate(template):setFaction("Human Navy")
		setPlayer(p)
		startPlayerPosition(p,angle)
		local respawn_x, respawn_y = p:getPosition()
		p.respawn_x = respawn_x
		p.respawn_y = respawn_y
		player_restart[p:getCallSign()] = {self = p, template = p:getTypeName(), control_code = p.control_code, faction = p:getFaction(), respawn_x = respawn_x, respawn_y = respawn_y}
		angle = (angle + 360/ships_per_team) % 360
	end
	replicatePlayers("Kraylor")
	if exuari_angle ~= nil then
		replicatePlayers("Exuari")
	end
	if ktlitan_angle ~= nil then
		replicatePlayers("Ktlitans")
	end
end
function startPlayerPosition(p,angle)
--	print("start player position angle:",angle)
	vx, vy = vectorFromAngleNorth(angle,player_position_distance)
	p:setPosition(faction_primary_station[p:getFaction()].x + vx, faction_primary_station[p:getFaction()].y + vy):setHeading(angle):commandTargetRotation((angle + 270) % 360)
end
function replicatePlayers(faction)
--	Replicate the Human Navy player ships to the designated faction
--	print("replicate players faction:",faction)
	local angle = faction_angle[faction]
	local temp_player_restart = {}
	for name, details in pairs(player_restart) do
--		print("player restart item faction:",details.faction)
		if details.faction == "Human Navy" then
--			print("name:",name,"details:",details,"details.template:",details.template,"faction:",faction)
			local p = PlayerSpaceship()
			if p ~= nil and p:isValid() then
				if player_ship_stats[details.template].stock then
					p:setTemplate(details.template)
				else
					customPlayerShip(details.template,p)
				end
				p:setFaction(faction)
				setPlayer(p)
				startPlayerPosition(p,angle)
				local respawn_x, respawn_y = p:getPosition()
				p.respawn_x = respawn_x
				p.respawn_y = respawn_y
				temp_player_restart[p:getCallSign()] = {self = p, template = p:getTypeName(), control_code = p.control_code, faction = p:getFaction(), respawn_x = respawn_x, respawn_y = respawn_y}
				angle = (angle + 360/ships_per_team) % 360
			else
				addGMMessage(_("msgGM", "Player creation failed"))
			end
		end
	end
	for name, details in pairs(temp_player_restart) do
		player_restart[name] = {self = details.self, template = details.template, control_code = details.control_code, faction = details.faction, respawn_x = details.respawn_x, respawn_y = details.respawn_y}
	end
end
function namePlayerShip(p)
	if p.name == nil then
		local use_fixed = false
		if predefined_player_ships ~= nil then
			if pps_index == nil then
				pps_index = 0
			end
			pps_index = pps_index + 1
			if predefined_player_ships[pps_index] ~= nil then
				use_fixed = true
			else
				predefined_player_ships = nil
			end
		end
		if use_fixed then
			p:setCallSign(predefined_player_ships[pps_index].name)
		else
			if rwc_player_ship_names[template_player_type] ~= nil and #rwc_player_ship_names[template_player_type] > 0 then
				local selected_name_index = math.random(1,#rwc_player_ship_names[template_player_type])
				p:setCallSign(rwc_player_ship_names[template_player_type][selected_name_index])
				table.remove(rwc_player_ship_names[template_player_type],selected_name_index)
			else
				if rwc_player_ship_names["Unknown"] ~= nil and #rwc_player_ship_names["Unknown"] > 0 then
					selected_name_index = math.random(1,#rwc_player_ship_names["Unknown"])
					p:setCallSign(rwc_player_ship_names["Unknown"][selected_name_index])
					table.remove(rwc_player_ship_names["Unknown"],selected_name_index)
				end
			end
		end
	end
	p.name = "set"
end
function playerDestroyed(self,instigator)
	respawn_count = respawn_count + 1
	if respawn_count > 300 then
		print("Hit respawn limit")
		return
	end
	local name = self:getCallSign()
	local faction = self:getFaction()
	local old_template = self:getTypeName()
	local p = PlayerSpaceship()
	if p ~= nil and p:isValid() then
		if respawn_type == "lindworm" then
			p:setTemplate("ZX-Lindworm")
		elseif respawn_type == "self" then
			p:setTemplate(old_template)
			death_penalty[faction] = death_penalty[faction] + self.shipScore
		end
		p:setFaction(faction)
		p.control_code = self.control_code
		p:setControlCode(p.control_code)
		local name_19 = string.lpad(p:getCallSign(),19)
		local cc_19 = string.lpad(p.control_code,19)
--		print(p:getCallSign(),"Control code:",p.control_code,"Faction:",faction)
		print(name_19,"Control code:",cc_19,"Faction:",faction)
		if respawn_type == "lindworm" then
			if old_template == "ZX-Lindworm" then
				resetPlayer(p,name)
			else
				resetPlayer(p)
			end
		elseif respawn_type == "self" then
			resetPlayer(p,name)
		end
		p:setPosition(self.respawn_x, self.respawn_y)
		p.respawn_x = self.respawn_x
		p.respawn_y = self.respawn_y
		if respawn_type == "lindworm" then
			player_restart[name] = {self = p, template = "ZX-Lindworm", control_code = p.control_code, faction = faction, respawn_x = self.respawn_x, respawn_y = self.respawn_y}
		elseif respawn_type == "self" then
			player_restart[name] = {self = p, template = old_template, control_code = p.control_code, faction = faction, respawn_x = self.respawn_x, respawn_y = self.respawn_y}
		end
	else
		respawn_countdown = 2
		if restart_queue == nil then
			restart_queue = {}
		end
		table.insert(restart_queue,name)
	end
end
function string.lpad(str, len, char)
	if char == nil then
		char = " "
	end
	return str .. string.rep(char, len - string.len(str))
end
function delayedRespawn(name)
	if name == nil then
		if restart_queue ~= nil then
			if #restart_queue > 0 then
				name = restart_queue[1]
			else
				respawn_countdown = nil
				return
			end
		else
			respawn_countdown = nil
			return
		end
	end
	if player_restart[name] ~= nil then
		local faction = player_restart[name].faction
		local old_template = player_restart[name].template
		local p = PlayerSpaceship()
		if p~= nil and p:isValid() then
			if respawn_type == "lindworm" then
				p:setTemplate("ZX-Lindworm")
			elseif respawn_type == "self" then
				p:setTemplate(old_template)
				death_penalty[faction] = death_penalty[faction] + self.shipScore
			end
			p:setFaction(faction)
			p.control_code = player_restart[name].control_code
			p:setControlCode(p.control_code)
			local name_19 = string.lpad(p:getCallSign(),19)
			local cc_19 = string.lpad(p.control_code,19)
			print(name_19,"Control code:",cc_19,"Faction:",faction)
--			print(p:getCallSign(),"Control code:",p.control_code,"Faction:",faction)
			if respawn_type == "lindworm" then
				if old_template == "ZX-Lindworm" then
					resetPlayer(p,name)
				else
					resetPlayer(p)
				end
			elseif respawn_type == "self" then
				resetPlayer(p,name)
			end
			p:setPosition(player_restart[name].respawn_x,player_restart[name].respawn_y)
			p.respawn_x = player_restart[name].respawn_x
			p.respawn_y = player_restart[name].respawn_y
			if respawn_type == "lindworm" then
				player_restart[name] = {self = p, template = "ZX-Lindworm", control_code = p.control_code, faction = faction, respawn_x = player_restart[name].respawn_x, respawn_y = player_restart[name].respawn_y}
			elseif respawn_type == "self" then
				player_restart[name] = {self = p, template = old_template, control_code = p.control_code, faction = faction, respawn_x = player_restart[name].respawn_x, respawn_y = player_restart[name].respawn_y}
			end
			if restart_queue ~= nil and #restart_queue > 0 then
				for i=1,#restart_queue do
					if restart_queue[i] == name then
						table.remove(restart_queue,i)
						respawn_countdown = nil
						break
					end
				end
			end
		else
			if restart_queue ~= nil and #restart_queue > 0 then
				respawn_countdown = 2
			end
		end
	else
		if restart_queue ~= nil then
			if #restart_queue > 0 then
				for i=1,#restart_queue do
					if restart_queue[i] == name then
						table.remove(restart_queue,i)
						print("problem with " .. name)
						break
					end
				end
			end
		end
	end
end
function resetPlayer(p,name)
	local faction = p:getFaction()
	if name == nil then
		namePlayerShip(p)
	else
		p:setCallSign(name)
		p.name = "set"
	end
	commonPlayerSet(p)
end
function commonPlayerSet(p)
	local template_player_type = p:getTypeName()
	if template_player_type == "Player Fighter" then
--						  Arc, Dir, Range, CycleTime, Dmg
		p:setBeamWeapon(0, 40,   0,   500,         6, 4)
		p:setBeamWeapon(2, 40, -10,  1000,         6, 8)
	end
	p.shipScore = player_ship_stats[template_player_type].strength
	p.maxCargo = player_ship_stats[template_player_type].cargo
	p.cargo = p.maxCargo
	p.maxRepairCrew = p:getRepairCrewCount()
	p.healthyShield = 1.0
	p.prevShield = 1.0
	p.healthyReactor = 1.0
	p.prevReactor = 1.0
	p.healthyManeuver = 1.0
	p.prevManeuver = 1.0
	p.healthyImpulse = 1.0
	p.prevImpulse = 1.0
	if p:getBeamWeaponRange(0) > 0 then
		p.healthyBeam = 1.0
		p.prevBeam = 1.0
	end
	if p:getWeaponTubeCount() > 0 then
		p.healthyMissile = 1.0
		p.prevMissile = 1.0
	end
	if p:hasWarpDrive() then
		p.healthyWarp = 1.0
		p.prevWarp = 1.0
	end
	if p:hasJumpDrive() then
		p.healthyJump = 1.0
		p.prevJump = 1.0
	end
	p.initialCoolant = p:getMaxCoolant()
	p:setLongRangeRadarRange(player_ship_stats[template_player_type].long_range_radar)
	p:setShortRangeRadarRange(player_ship_stats[template_player_type].short_range_radar)
	p.normal_long_range_radar = p:getLongRangeRadarRange()
	p:setMaxScanProbeCount(player_ship_stats[template_player_type].probes)
	p:setScanProbeCount(p:getMaxScanProbeCount())
	if (not p:hasSystem("jumpdrive") and player_ship_stats[template_player_type].long_jump > 0) or
		(p:hasSystem("jumpdrive") and player_ship_stats[template_player_type].long_jump ~= 50) then
		p:setJumpDrive(true)
		p.max_jump_range = player_ship_stats[template_player_type].long_jump*1000
		p.min_jump_range = player_ship_stats[template_player_type].short_jump*1000
		p:setJumpDriveRange(p.min_jump_range,p.max_jump_range)
		p:setJumpDriveCharge(p.max_jump_range)
	end
	if not p:hasSystem("warp") and player_ship_stats[template_player_type].warp > 0 then
		p:setWarpDrive(true)
		p:setWarpSpeed(player_ship_stats[template_player_type].warp)
	end
	p:onDestruction(playerDestroyed)
end
function setPlayer(p)
	local faction = p:getFaction()
	namePlayerShip(p)	--always name it before giving it the control code
--	p:addReputationPoints(1000)	--testing only
	p:addReputationPoints(base_reputation)
	if predefined_player_ships ~= nil and predefined_player_ships[pps_index] ~= nil and predefined_player_ships[pps_index].control_code ~= nil then
		p.control_code = predefined_player_ships[pps_index].control_code
		p:setControlCode(predefined_player_ships[pps_index].control_code)
	else
		local stem = tableRemoveRandom(control_code_stem)
		local branch = math.random(100,999)
		p.control_code = stem .. branch
		p:setControlCode(stem .. branch)
	end
--	local name_19 = string.lpad(p:getCallSign(),19)
--	local cc_19 = string.lpad(p.control_code,19)
--	print(name_19,"Control code:",cc_19,"Faction:",faction)
--	print(p:getCallSign(),"Control code:",p.control_code,"Faction:",faction)
	commonPlayerSet(p)
end
------------------------------
--	Station communications  --
------------------------------
function commsStation()
    if comms_target.comms_data == nil then
        comms_target.comms_data = {}
    end
    mergeTables(comms_target.comms_data, {
        friendlyness = random(0.0, 100.0),
        weapons = {
            Homing = "neutral",
            HVLI = "neutral",
            Mine = "neutral",
            Nuke = "friend",
            EMP = "friend",
        },
        weapon_cost = {
            Homing = math.random(1,4),
            HVLI = math.random(1,3),
            Mine = math.random(2,5),
            Nuke = math.random(12,18),
            EMP = math.random(7,13),
        },
        services = {
            supplydrop = "friend",
            reinforcements = "friend",
            sensor_boost = "neutral",
			preorder = "friend",
            activatedefensefleet = "neutral",
        },
        service_cost = {
            supplydrop = math.random(80,120),
            reinforcements = math.random(125,175),
            phobosReinforcements = math.random(200,250),
            stalkerReinforcements = math.random(275,325),
            activatedefensefleet = 20,
        },
        reputation_cost_multipliers = {
            friend = 1.0,
            neutral = 3.0,
        },
        max_weapon_refill_amount = {
            friend = 1.0,
            neutral = 0.5,
        }
    })
    comms_data = comms_target.comms_data
    if comms_source:isEnemy(comms_target) then
        return false
    end
    if not comms_source:isDocked(comms_target) then
        handleUndockedState()
    else
        handleDockedState()
    end
    return true
end
function commsDefensePlatform()
	if comms_target.comms_data == nil then
        comms_target.comms_data = {}
    end
    mergeTables(comms_target.comms_data, {
        friendlyness = random(0.0, 100.0),
        weapons = {
            Homing = "neutral",
            HVLI = "neutral",
            Mine = "neutral",
            Nuke = "friend",
            EMP = "friend"
        },
        weapon_cost = {
            Homing = math.random(1,4),
            HVLI = math.random(1,3),
            Mine = math.random(2,5),
            Nuke = math.random(12,18),
            EMP = math.random(7,13)
        },
        services = {
            supplydrop = "friend",
            reinforcements = "friend",
        },
        service_cost = {
            supplydrop = math.random(80,120),
            reinforcements = math.random(125,175),
            phobosReinforcements = math.random(200,250),
            stalkerReinforcements = math.random(275,325)
        },
        reputation_cost_multipliers = {
            friend = 1.0,
            neutral = 3.0
        },
        max_weapon_refill_amount = {
            friend = 1.0,
            neutral = 0.5
        }
    })
    comms_data = comms_target.comms_data
    if comms_source:isEnemy(comms_target) then
        return false
    end
    if comms_source:isDocked(comms_target) then
    --    handleDockedState()
    	setCommsMessage(string.format(_("defensePlatform-comms","Hi %s"),comms_source:getCallSign()))
		restockOrdnance(commsDefensePlatform)
		completionConditions(commsDefensePlatform)
		dockingServicesStatus(commsDefensePlatform)
		repairSubsystems(commsDefensePlatform)
		stationDefenseReport(commsDefensePlatform)
		if primary_jammers then
			if comms_source:isFriendly(comms_target) then
				addCommsReply(string.format(_("defensePlatform-comms","Transfer to %s"),comms_target.primary_station:getCallSign()),function()
					comms_source:commandUndock()
					local psx, psy = comms_target.primary_station:getPosition()
					local angle = comms_source:getHeading()
					local station_dock_radius = {
						["Small Station"] = 300,
						["Medium Station"] = 1000,
						["Large Station"] = 1300,
						["Huge Station"] = 1500,
					}
					local dock_distance = station_dock_radius[comms_target.primary_station:getTypeName()]
					local vx, vy = vectorFromAngleNorth(angle,dock_distance)
					comms_source:setPosition(psx + vx, psy + vy)
					comms_source:commandDock(comms_target.primary_station)
					setCommsMessage(string.format(_("defensePlatform-comms","Don't let %s forget their friends on duty at %s"),comms_target.primary_station:getCallSign(),comms_target:getCallSign()))
				end)
			end
		end
	else	--undocked
		local dock_messages = {
			_("defensePlatform-comms","Dock if you want anything"),
			_("defensePlatform-comms","You must dock before we can do anything"),
			_("defensePlatform-comms","Gotta dock first"),
			_("defensePlatform-comms","Can't do anything for you unless you dock"),
			_("defensePlatform-comms","Docking crew is standing by"),
			_("defensePlatform-comms","Dock first, then talk"),
		}
		setCommsMessage(dock_messages[math.random(1,#dock_messages)])
		ordnanceAvailability(commsDefensePlatform)
		completionConditions(commsDefensePlatform)
		dockingServicesStatus(commsDefensePlatform)
		stationDefenseReport(commsDefensePlatform)
	end
	return true
end
function handleDockedState()
    if comms_source:isFriendly(comms_target) then
		oMsg = _("station-comms", "Good day, officer!\nWhat can we do for you today?")
    else
		oMsg = _("station-comms", "Welcome to our lovely station.")
    end
    if comms_target:areEnemiesInRange(20000) then
		oMsg = oMsg .. _("station-comms", "\nForgive us if we seem a little distracted. We are carefully monitoring the enemies nearby.")
	end
	setCommsMessage(oMsg)
	restockOrdnance(commsStation)
	completionConditions(commsStation)
	if advanced_intel then
		advanceIntel(commsStation)
	end
	dockingServicesStatus(commsStation)
	repairSubsystems(commsStation)
	boostSensorsWhileDocked(commsStation)
	overchargeJump(commsStation)
	activateDefenseFleet(commsStation)
	if scientist_list[comms_target:getFaction()] ~= nil then
		for idx, scientist in ipairs(scientist_list[comms_target:getFaction()]) do
			if scientist.location == comms_target then
				addCommsReply(string.format(_("station-comms","Speak with scientist %s"),scientist.name),function()
					setCommsMessage(string.format(_("station-comms","Greetings, %s\nI've got great ideas for the war effort.\nWhat can I do for you?"),comms_source:getCallSign()))
					addCommsReply(_("station-comms","Please come aboard our ship"),function()
						setCommsMessage(string.format(_("station-comms","Certainly, %s\n\n%s boards your ship"),comms_source:getCallSign(),scientist.name))
						scientist.location = comms_source
						scientist.location_name = comms_source:getCallSign()
						addCommsReply(_("Back"), commsStation)				
					end)
					addCommsReply(_("station-comms","Can you tell me some more about your ideas?"),function()
						local rc = false
						local msg = ""
						local completed_message = ""
						local npc_message = ""
						setCommsMessage(string.format(_("station-comms","I'd need to visit %s to proceed further"),faction_primary_station[comms_target:getFaction()].station:getCallSign()))
						if string.find(scientist.upgrade_requirement,"talk") or string.find(scientist.upgrade_requirement,"meet") then
							if string.find(scientist.upgrade_requirement,"primary") then
								if faction_primary_station[comms_target:getFaction()].station ~= nil and faction_primary_station[comms_target:getFaction()].station:isValid() then
									if faction_primary_station[comms_target:getFaction()].station.available_upgrades == nil then
										faction_primary_station[comms_target:getFaction()].station.available_upgrades = {}
									end
									faction_primary_station[comms_target:getFaction()].station.available_upgrades[scientist.upgrade.name] = scientist.upgrade.action
									setCommsMessage(string.format(_("station-comms","I just sent details on a %s to %s. With their facilities, you should be able to apply the upgrade the next time you dock there."),scientist.upgrade.name,faction_primary_station[comms_target:getFaction()].station:getCallSign()))
								else
									setCommsMessage(_("station-comms","Without your primary station to apply my research, I'm afraid my information is useless"))
								end
							else
								rc, msg = scientist.upgrade.action(comms_source)
								if rc then
									completed_message = string.format(_("station-comms","After an extended conversation with %s and the exchange of technical information with various crew members, you apply the insight into %s gained by %s.\n\n%s"),scientist.name,scientist.topic,scientist.name,msg)
									if scientist.upgrade_automated_application == "single" then
										setCommsMessage(completed_message)
									elseif scientist.upgrade_automated_application == "players" then
										for pidx=1,32 do
											local p = getPlayerShip(pidx)
											if p ~= nil and p:isValid() and p ~= comms_source and p:getFaction() == comms_source:getFaction() then
												rc, msg = scientist.upgrade.action(p)
												if rc then
													p:addToShipLog(string.format(_("shipLog","%s provided details from %s for an upgrade. %s"),comms_source:getCallSign(),scientist.name,msg),"Magenta")
												end
											end
										end
										setCommsMessage(string.format(_("station-comms","%s\nThe upgrade details were also provided to the other players in your faction."),completed_message))
									elseif scientist.upgrade_automated_application == "all" then
										if scientist.upgrade.action ~= longerSensorsUpgrade and scientist.upgrade.action ~= batteryEfficiencyUpgrade then
											if npc_fleet ~= nil and npc_fleet[comms_source:getFaction()] ~= nil and #npc_fleet[comms_source:getFaction()] > 0 then
												for i=1,#npc_fleet[comms_source:getFaction()] do
													local npc = npc_fleet[comms_source:getFaction()][i]
													if npc ~= nil and npc:isValid() then
														rc, msg = scientist.upgrade.action(npc)
													end
												end
												npc_message = _("station-comms","and npc ships ")
											end
										end
										for pidx=1,32 do
											local p = getPlayerShip(pidx)
											if p ~= nil and p:isValid() and p ~= comms_source and p:getFaction() == comms_source:getFaction() then
												rc, msg = scientist.upgrade.action(p)
												if rc then
													p:addToShipLog(string.format(_("shipLog","%s provided details from %s for an upgrade. %s"),comms_source:getCallSign(),scientist.name,msg),"Magenta")
												end
											end
										end
										setCommsMessage(string.format(_("station-comms","%s\nThe upgrade details were also provided to the other players %sin your faction."),completed_message,npc_message))
									end
								else
									setCommsMessage(string.format(_("station-comms","Your conversation with %s about %s was interesting, but not directly applicable.\n\n%s"),scientist.name,scientist.topic,msg))
								end
							end
						elseif scientist.upgrade_requirement == "transport" then
							if comms_target == faction_primary_station[comms_target:getFaction()].station then
								rc, msg = scientist.upgrade.action(comms_source)
								if rc then
									completed_message = string.format(_("station-comms","After an extended conversation with %s, various crew members and %s facilities managers, you apply the insight into %s gained by %s.\n\n%s"),scientist.name,comms_target:getCallSign(),scientist.topic,scientist.name,msg)
									if faction_primary_station[comms_target:getFaction()].station.available_upgrades == nil then
										faction_primary_station[comms_target:getFaction()].station.available_upgrades = {}
									end
									faction_primary_station[comms_target:getFaction()].station.available_upgrades[scientist.upgrade.name] = scientist.upgrade.action
									setCommsMessage(completed_message)
									if scientist.upgrade_automated_application == "all" then
										if scientist.upgrade.action ~= longerSensorsUpgrade and scientist.upgrade.action ~= batteryEfficiencyUpgrade then
											if npc_fleet ~= nil and npc_fleet[comms_source:getFaction()] ~= nil and #npc_fleet[comms_source:getFaction()] > 0 then
												for i=1,#npc_fleet[comms_source:getFaction()] do
													local npc = npc_fleet[comms_source:getFaction()][i]
													if npc ~= nil and npc:isValid() then
														rc, msg = scientist.upgrade.action(npc)
													end
												end
												npc_message = _("station-comms","and npc ships ")
											end
										end
										setCommsMessage(string.format(_("station-comms","%s\nNPC ships received the upgrade as well"),completed_message))
									end
								else
									setCommsMessage(string.format(_("station-comms","Your conversation with %s about %s was interesting, but not directly applicable.\n\n%s"),scientist.name,scientist.topic,msg))
									if faction_primary_station[comms_target:getFaction()].station.available_upgrades == nil then
										faction_primary_station[comms_target:getFaction()].station.available_upgrades = {}
									end
									faction_primary_station[comms_target:getFaction()].station.available_upgrades[scientist.upgrade.name] = scientist.upgrade.action
								end
							end
						elseif scientist.upgrade_requirement == "confer" then
							if comms_target == faction_primary_station[comms_target:getFaction()].station then
								local colleage_count = 0
								local conferee = nil
								for idx, colleague in ipairs(scientist_list[comms_target:getFaction()]) do
									if colleague.location == comms_target and colleague ~= scientist then
										colleage_count = colleage_count + 1
										conferee = colleague
									end
								end
								if colleage_count > 0 then
									rc, msg = scientist.upgrade.action(comms_source)
									if rc then
										completed_message = string.format(_("station-comms","After an extended conversation with %s, %s, various crew members and %s facilities managers, you apply the insight into %s and %s gained by %s.\n\n%s"),scientist.name,conferee.name,comms_target:getCallSign(),scientist.topic,conferee.topic,scientist.name,msg)
										if faction_primary_station[comms_target:getFaction()].station.available_upgrades == nil then
											faction_primary_station[comms_target:getFaction()].station.available_upgrades = {}
										end
										faction_primary_station[comms_target:getFaction()].station.available_upgrades[scientist.upgrade.name] = scientist.upgrade.action
										if scientist.upgrade_automated_application == "single" then
											setCommsMessage(completed_message)
										elseif scientist.upgrade_automated_application == "players" then
											for pidx=1,32 do
												local p = getPlayerShip(pidx)
												if p ~= nil and p:isValid() and p ~= comms_source and p:getFaction() == comms_source:getFaction() then
													rc, msg = scientist.upgrade.action(p)
													if rc then
														p:addToShipLog(string.format(_("shipLog","%s provided details from %s for an upgrade. %s"),comms_source:getCallSign(),scientist.name,msg),"Magenta")
													end
												end
											end
											setCommsMessage(string.format(_("station-comms","%s\nThe upgrade details were also provided to the other players in your faction."),completed_message))
										elseif scientist.upgrade_automated_application == "all" then
											if scientist.upgrade.action ~= longerSensorsUpgrade and scientist.upgrade.action ~= batteryEfficiencyUpgrade then
												if npc_fleet ~= nil and npc_fleet[comms_source:getFaction()] ~= nil and #npc_fleet[comms_source:getFaction()] > 0 then
													for i=1,#npc_fleet[comms_source:getFaction()] do
														local npc = npc_fleet[comms_source:getFaction()][i]
														if npc ~= nil and npc:isValid() then
															rc, msg = scientist.upgrade.action(npc)
														end
													end
													npc_message = _("station-comms","and npc ships ")
												end
											end
											for pidx=1,32 do
												local p = getPlayerShip(pidx)
												if p ~= nil and p:isValid() and p ~= comms_source and p:getFaction() == comms_source:getFaction() then
													rc, msg = scientist.upgrade.action(p)
													if rc then
														p:addToShipLog(string.format(_("shipLog","%s provided details from %s for an upgrade. %s"),comms_source:getCallSign(),scientist.name,msg),"Magenta")
													end
												end
											end
											setCommsMessage(string.format(_("station-comms","%s\nThe upgrade details were also provided to the other players %sin your faction."),completed_message,npc_message))
										end
									else
										setCommsMessage(string.format(_("station-comms","Your conversation with %s and %s about %s and %s was interesting, but not directly applicable.\n\n%s"),scientist.name,conferee.name,scientist.topic,conferee.topic,msg))
										if faction_primary_station[comms_target:getFaction()].station.available_upgrades == nil then
											faction_primary_station[comms_target:getFaction()].station.available_upgrades = {}
										end
										faction_primary_station[comms_target:getFaction()].station.available_upgrades[scientist.upgrade.name] = scientist.upgrade.action
									end
								else
									setCommsMessage(string.format(_("station-comms","I've got this idea for a %s, but I just can't quite get it to crystalize. If I had another scientist here to collaborate with, I might get further along"),scientist.upgrade.name))
								end
							end
						end
					end)
					addCommsReply(_("Back"), commsStation)
				end)
			end
			if scientist.location == comms_source then
				addCommsReply(string.format(_("station-comms","Escort %s on to %s"),scientist.name,comms_target:getCallSign()),function()
					setCommsMessage(string.format(_("station-comms","%s thanks you for your hospitality and disembarks to %s"),scientist.name,comms_target:getCallSign()))
					scientist.location = comms_target
					scientist.location_name = comms_target:getCallSign()
					addCommsReply(_("Back"), commsStation)
				end)
			end
		end
	end
	if comms_target.available_upgrades ~= nil then
		for name, action in pairs(comms_target.available_upgrades) do
			addCommsReply(name,function()
				string.format("")	--Serious Proton needs global reference/context
				local rc, msg = action(comms_source)
				if rc then	
					setCommsMessage(string.format(_("station-comms","Congratulations!\n%s"),msg))
				else
					setCommsMessage(string.format(_("station-comms","Sorry.\n%s"),msg))
				end
			end)
		end
	end
	stationFlavorInformation(commsStation)
	if comms_source:isFriendly(comms_target) then
		if random(1,100) <= (20 - difficulty*2) then
			if comms_source:getRepairCrewCount() < comms_source.maxRepairCrew then
				hireCost = math.random(30,60)
			else
				hireCost = math.random(45,90)
			end
			addCommsReply(string.format(_("trade-comms", "Recruit repair crew member for %i reputation"),hireCost), function()
				if not comms_source:takeReputationPoints(hireCost) then
					setCommsMessage(_("needRep-comms", "Insufficient reputation"))
				else
					comms_source:setRepairCrewCount(comms_source:getRepairCrewCount() + 1)
					resetPreviousSystemHealth(comms_source)
					setCommsMessage(_("trade-comms", "Repair crew member hired"))
				end
				addCommsReply(_("Back"), commsStation)
			end)
		end
		if comms_source.initialCoolant ~= nil then
			if math.random(1,100) <= (20 - difficulty*2) then
				local coolantCost = math.random(45,90)
				if comms_source:getMaxCoolant() < comms_source.initialCoolant then
					coolantCost = math.random(30,60)
				end
				addCommsReply(string.format(_("trade-comms", "Purchase coolant for %i reputation"),coolantCost), function()
					if not comms_source:takeReputationPoints(coolantCost) then
						setCommsMessage(_("needRep-comms", "Insufficient reputation"))
					else
						comms_source:setMaxCoolant(comms_source:getMaxCoolant() + 2)
						setCommsMessage(_("trade-comms", "Additional coolant purchased"))
					end
					addCommsReply(_("Back"), commsStation)
				end)
			end
		end
	end
	if primary_jammers then
		if comms_source:isFriendly(comms_target) then
			if defense_platform_count > 0 and comms_target == faction_primary_station[comms_source:getFaction()].station then
				addCommsReply("Exit Jammer",function()
					comms_source:commandUndock()
					local psx, psy = comms_target:getPosition()
					local angle = (faction_angle[comms_source:getFaction()] + 180) % 360
					local vx, vy = vectorFromAngleNorth(angle,defense_platform_distance + 4000)
					comms_source:setPosition(psx + vx, psy + vy):setHeading(angle):commandTargetRotation((angle + 270) % 360)
					setCommsMessage("Have fun storming the castle")
				end)
			end
		end
	end
	buySellTrade(commsStation)
end	--end of handleDockedState function
function handleUndockedState()
    --Handle communications when we are not docked with the station.
    if comms_source:isFriendly(comms_target) then
        oMsg = _("station-comms", "Good day, officer.\nIf you need supplies, please dock with us first.")
    else
        oMsg = _("station-comms", "Greetings.\nIf you want to do business, please dock with us first.")
    end
    if comms_target:areEnemiesInRange(20000) then
		oMsg = oMsg .. _("station-comms", "\nBe aware that if enemies in the area get much closer, we will be too busy to conduct business with you.")
	end
	setCommsMessage(oMsg)
--	expediteDock(commsStation)		--may reinstate if time permits. Needs code in update function, player loop
 	addCommsReply(_("station-comms", "I need information"), function()
		setCommsMessage(_("station-comms", "What kind of information do you need?"))
		ordnanceAvailability(commsStation)
		goodsAvailabilityOnStation(commsStation)
		completionConditions(commsStation)
		if advanced_intel then
			advanceIntel(commsStation)
		end
		dockingServicesStatus(commsStation)
		stationFlavorInformation(commsStation)
		stationDefenseReport(commsStation)
	end)
	requestSupplyDrop(commsStation)
	requestJumpSupplyDrop(commsStation)
	requestReinforcements(commsStation)
	activateDefenseFleet(commsStation)
	if scientist_list[comms_target:getFaction()] ~= nil then
		for idx, scientist in ipairs(scientist_list[comms_target:getFaction()]) do
			if scientist.location == comms_target then
				addCommsReply(string.format(_("station-comms","Speak with scientist %s"),scientist.name),function()
					setCommsMessage(string.format(_("station-comms","Greetings, %s\nI've got great ideas for the war effort.\nWhat can I do for you?"),comms_source:getCallSign()))
					addCommsReply(_("station-comms","Can you tell me some more about your ideas?"),function()
						local rc = false
						local msg = ""
						local completed_message = ""
						local npc_message = ""
						if string.find(scientist.upgrade_requirement,"talk") then
							if string.find(scientist.upgrade_requirement,"primary") then
								if faction_primary_station[comms_target:getFaction()].station ~= nil and faction_primary_station[comms_target:getFaction()].station:isValid() then
									if faction_primary_station[comms_target:getFaction()].station.available_upgrades == nil then
										faction_primary_station[comms_target:getFaction()].station.available_upgrades = {}
									end
									faction_primary_station[comms_target:getFaction()].station.available_upgrades[scientist.upgrade.name] = scientist.upgrade.action
									setCommsMessage(string.format(_("station-comms","I just sent details on a %s to %s. With their facilities, you should be able to apply the upgrade the next time you dock there."),scientist.upgrade.name,faction_primary_station[comms_target:getFaction()].station:getCallSign()))
								else
									setCommsMessage(_("station-comms","Without your primary station to apply my research, I'm afraid my information is useless"))
								end
							else
								local rc, msg = scientist.upgrade.action(comms_source)
								if rc then
									completed_message = string.format(_("station-comms","After an extended conversation with %s and the exchange of technical information with various crew members, you apply the insight into %s gained by %s.\n\n%s"),scientist.name,scientist.topic,scientist.name,msg)
									if scientist.upgrade_automated_application == "single" then
										setCommsMessage(completed_message)
									elseif scientist.upgrade_automated_application == "players" then
										for pidx=1,32 do
											local p = getPlayerShip(pidx)
											if p ~= nil and p:isValid() and p ~= comms_source and p:getFaction() == comms_source:getFaction() then
												rc, msg = scientist.upgrade.action(p)
												if rc then
													p:addToShipLog(string.format(_("shipLog","%s provided details from %s for an upgrade. %s"),comms_source:getCallSign(),scientist.name,msg),"Magenta")
												end
											end
										end
										setCommsMessage(string.format(_("station-comms","\nThe upgrade details were also provided to the other players in your faction."),completed_message))
									elseif scientist.upgrade_automated_application == "all" then
										if scientist.upgrade.action ~= longerSensorsUpgrade and scientist.upgrade.action ~= batteryEfficiencyUpgrade then
											if npc_fleet ~= nil and npc_fleet[comms_source:getFaction()] ~= nil and #npc_fleet[comms_source:getFaction()] > 0 then
												for i=1,#npc_fleet[comms_source:getFaction()] do
													local npc = npc_fleet[comms_source:getFaction()][i]
													if npc ~= nil and npc:isValid() then
														rc, msg = scientist.upgrade.action(npc)
													end
												end
												npc_message = _("station-comms","and npc ships ")
											end
										end
										for pidx=1,32 do
											local p = getPlayerShip(pidx)
											if p ~= nil and p:isValid() and p ~= comms_source and p:getFaction() == comms_source:getFaction() then
												rc, msg = scientist.upgrade.action(p)
												if rc then
													p:addToShipLog(string.format(_("station-comms","%s provided details from %s for an upgrade. %s"),comms_source:getCallSign(),scientist.name,msg),"Magenta")
												end
											end
										end
										setCommsMessage(string.format(_("station-comms","%s\nThe upgrade details were also provided to the other players %sin your faction."),completed_message,npc_message))
									end
								else
									setCommsMessage(string.format(_("station-comms","Your conversation with %s about %s was interesting, but not directly applicable.\n\n%s"),scientist.name,scientist.topic,msg))
								end
								local overhear_chance = 16
								if scientist.upgrade_automated_application == "players" then
									overhear_chance = 28
								end
								if scientist.upgrade_automated_application == "all" then
									overhear_chance = 39
								end
								if random(1,100) <= overhear_chance then
									for pidx=1,32 do
										local p = getPlayerShip(pidx)
										if p ~= nil and p:isValid() then
											if p:getFaction() == comms_source:getFaction() then
												p:addToShipLog(string.format(_("station-comms","Communication between %s and %s intercepted by enemy faction"),comms_source:getCallSign(),comms_target:getCallSign()),"Magenta")
											else
												p:addToShipLog(string.format(_("station-comms","%s conversation intercepted regarding %s. Probable military application. Suggest you contact our own scientist in the same field"),comms_source:getFaction(),scientist.topic),"Magenta")
											end
										end
									end
								end
							end
						else
							setCommsMessage(_("station-comms","I should not discuss it over an open communication line. Perhaps you should visit and we can talk"))
						end
					end)
					addCommsReply(_("Back"), commsStation)
				end)
			end
		end
	end
end
function isAllowedTo(state)
    if state == "friend" and comms_source:isFriendly(comms_target) then
        return true
    end
    if state == "neutral" and not comms_source:isEnemy(comms_target) then
        return true
    end
    return false
end
function getWeaponCost(weapon)
    return math.ceil(comms_data.weapon_cost[weapon] * comms_data.reputation_cost_multipliers[getFriendStatus()])
end
function getFriendStatus()
    if comms_source:isFriendly(comms_target) then
        return "friend"
    else
        return "neutral"
    end
end
function dockingServicesStatus(return_function)
	addCommsReply(_("stationServices-comms", "Docking services status"), function()
		local service_status = string.format(_("stationServices-comms", "Station %s docking services status:"),comms_target:getCallSign())
		if comms_target:getRestocksScanProbes() then
			service_status = string.format(_("stationServices-comms", "%s\nReplenish scan probes."),service_status)
		else
			if comms_target.probe_fail_reason == nil then
				local reason_list = {
					_("stationServices-comms", "Cannot replenish scan probes due to fabrication unit failure."),
					_("stationServices-comms", "Parts shortage prevents scan probe replenishment."),
					_("stationServices-comms", "Management has curtailed scan probe replenishment for cost cutting reasons."),
				}
				comms_target.probe_fail_reason = reason_list[math.random(1,#reason_list)]
			end
			service_status = string.format(_("stationServices-comms", "%s\n%s"),service_status,comms_target.probe_fail_reason)
		end
		if comms_target:getRepairDocked() then
			service_status = string.format(_("stationServices-comms", "%s\nShip hull repair."),service_status)
		else
			if comms_target.repair_fail_reason == nil then
				reason_list = {
					_("stationServices-comms", "We're out of the necessary materials and supplies for hull repair."),
					_("stationServices-comms", "Hull repair automation unavailable while it is undergoing maintenance."),
					_("stationServices-comms", "All hull repair technicians quarantined to quarters due to illness."),
				}
				comms_target.repair_fail_reason = reason_list[math.random(1,#reason_list)]
			end
			service_status = string.format(_("stationServices-comms", "%s\n%s"),service_status,comms_target.repair_fail_reason)
		end
		if comms_target:getSharesEnergyWithDocked() then
			service_status = string.format(_("stationServices-comms", "%s\nRecharge ship energy stores."),service_status)
		else
			if comms_target.energy_fail_reason == nil then
				reason_list = {
					_("stationServices-comms", "A recent reactor failure has put us on auxiliary power, so we cannot recharge ships."),
					_("stationServices-comms", "A damaged power coupling makes it too dangerous to recharge ships."),
					_("stationServices-comms", "An asteroid strike damaged our solar cells and we are short on power, so we can't recharge ships right now."),
				}
				comms_target.energy_fail_reason = reason_list[math.random(1,#reason_list)]
			end
			service_status = string.format(_("stationServices-comms", "%s\n%s"),service_status,comms_target.energy_fail_reason)
		end
		if comms_target.comms_data.jump_overcharge then
			service_status = string.format(_("stationServices-comms", "%s\nMay overcharge jump drive"),service_status)
		end
		if comms_target.comms_data.probe_launch_repair then
			service_status = string.format(_("stationServices-comms", "%s\nMay repair probe launch system"),service_status)
		end
		if comms_target.comms_data.hack_repair then
			service_status = string.format(_("stationServices-comms", "%s\nMay repair hacking system"),service_status)
		end
		if comms_target.comms_data.scan_repair then
			service_status = string.format(_("stationServices-comms", "%s\nMay repair scanners"),service_status)
		end
		if comms_target.comms_data.combat_maneuver_repair then
			service_status = string.format(_("stationServices-comms", "%s\nMay repair combat maneuver"),service_status)
		end
		if comms_target.comms_data.self_destruct_repair then
			service_status = string.format(_("stationServices-comms", "%s\nMay repair self destruct system"),service_status)
		end
		if comms_target.comms_data.tube_slow_down_repair then
			service_status = string.format(_("stationServices-comms", "%s\nMay repair slow loading tubes"),service_status)
		end
		setCommsMessage(service_status)
		addCommsReply(_("Back"), return_function)
	end)
end
function stationFlavorInformation(return_function)
	if (comms_target.comms_data.general ~= nil and comms_target.comms_data.general ~= "") or (comms_target.comms_data.history ~= nil and comms_target.comms_data.history ~= "") then
		addCommsReply(_("station-comms", "Tell me more about your station"), function()
			setCommsMessage(_("station-comms", "What would you like to know?"))
			if comms_target.comms_data.general ~= nil and comms_target.comms_data.general ~= "" then
				addCommsReply(_("stationGeneralInfo-comms", "General information"), function()
					setCommsMessage(comms_target.comms_data.general)
					addCommsReply(_("Back"), return_function)
				end)
			end
			if comms_target.comms_data.history ~= nil and comms_target.comms_data.history ~= "" then
				addCommsReply(_("stationStory-comms", "Station history"), function()
					setCommsMessage(comms_target.comms_data.history)
					addCommsReply(_("Back"), return_function)
				end)
			end
		end)
	end
end
function stationDefenseReport(return_function)
	addCommsReply(_("stationAssist-comms", "Report status"), function()
		msg = string.format(_("stationAssist-comms", "Hull: %d%%\n"), math.floor(comms_target:getHull() / comms_target:getHullMax() * 100))
		local shields = comms_target:getShieldCount()
		if shields == 1 then
			msg = string.format(_("stationAssist-comms", "%sShield: %d%%\n"),msg,math.floor(comms_target:getShieldLevel(0) / comms_target:getShieldMax(0) * 100))
			msg = string.format(_("stationAssist-comms", "%sShield: %d%%\n"),msg,math.floor(comms_target:getShieldLevel(0) / comms_target:getShieldMax(0) * 100))
		else
			for n=0,shields-1 do
				msg = string.format(_("stationAssist-comms", "%sShield %s: %d%%\n"),msg,n,math.floor(comms_target:getShieldLevel(n) / comms_target:getShieldMax(n) * 100))
			end
		end			
		setCommsMessage(msg);
		addCommsReply(_("Back"), return_function)
	end)
end
function completionConditions(return_function)
	addCommsReply(_("stationStats-comms","What ends the war?"),function()
		local out = string.format(_("stationStats-comms","The war ends in one of three ways:\n1) Time runs out\n2) A faction drops below half of original score\n3) A faction either leads or trails the other factions by %i%%\n"),thresh*100)
		local stat_list = gatherStats()
		out = string.format(_("stationStats-comms","%s\nHuman Navy Current:%.1f Original:%.1f (%.2f%%)"),out,stat_list.human.weighted_score,original_score["Human Navy"],(stat_list.human.weighted_score/original_score["Human Navy"])*100)
		if stat_list.human.death_penalty ~= nil then
			out = string.format(_("stationStats-comms","%s\nHuman Navy loss of player ship penalty: %.1f"),out,stat_list.human.death_penalty * stat_list.weight.ship)
		end
		out = string.format(_("stationStats-comms","%s\nKraylor Current:%.1f Original:%.1f (%.2f%%)"),out,stat_list.kraylor.weighted_score,original_score["Kraylor"],(stat_list.kraylor.weighted_score/original_score["Kraylor"])*100)
		if stat_list.kraylor.death_penalty ~= nil then
			out = string.format(_("stationStats-comms","%s\nKraylor loss of player ship penalty: %.1f"),out,stat_list.kraylor.death_penalty * stat_list.weight.ship)
		end
		if exuari_angle ~= nil then
			out = string.format(_("stationStats-comms","%s\nExuari Current:%.1f Original:%.1f (%.2f%%)"),out,stat_list.exuari.weighted_score,original_score["Exuari"],(stat_list.exuari.weighted_score/original_score["Exuari"])*100)
			if stat_list.exuari.death_penalty ~= nil then
				out = string.format(_("stationStats-comms","%s\nExuari loss of player ship penalty: %.1f"),out,stat_list.exuari.death_penalty * stat_list.weight.ship)
			end
		end
		if ktlitan_angle ~= nil then
			out = string.format(_("stationStats-comms","%s\nKtlitan Current:%.1f Original:%.1f (%.2f%%)"),out,stat_list.ktlitan.weighted_score,original_score["Ktlitans"],(stat_list.ktlitan.weighted_score/original_score["Ktlitans"])*100)
			if stat_list.ktlitan.death_penalty ~= nil then
				out = string.format(_("stationStats-comms","%s\nKtlitan loss of player ship penalty: %.1f"),out,stat_list.ktlitan.death_penalty * stat_list.weight.ship)
			end
		end
		out = string.format(_("stationStats-comms","%s\n\nStation weight:%i%%   Player ship weight:%i%%   NPC weight:%i%%"),out,stat_list.weight.station*100,stat_list.weight.ship*100,stat_list.weight.npc*100)
		local tie_breaker = {}
		for i,p in ipairs(getActivePlayerShips()) do
			tie_breaker[p:getFaction()] = p:getReputationPoints()
		end
		out = string.format(_("stationStats-comms","%s\nTie breaker points:"),out)
		local faction_points_list = ""
		for faction,points in pairs(tie_breaker) do
			faction_points_list = string.format(_("stationStats-comms","%s %s:%f"),faction_points_list,faction,points/10000)
		end
		out = string.format(_("stationStats-comms","%s %s"),out,faction_points_list)
		setCommsMessage(out)
		addCommsReply(string.format(_("stationStats-comms","Station values (Total:%i)"),stat_list[f2s[comms_source:getFaction()]].station_score_total),function()
			local out = _("stationStats-comms","Stations: (value, type, name)")
			for name, details in pairs(stat_list[f2s[comms_source:getFaction()]].station) do
				out = string.format(_("stationStats-comms","%s\n   %i, %s, %s"),out,details.score_value,details.template_type,name)
			end
			out = string.format(_("stationStats-comms","%s\nTotal:%i multiplied by weight (%i%%) = weighted total:%.1f"),out,stat_list[f2s[comms_source:getFaction()]].station_score_total,stat_list.weight.station*100,stat_list[f2s[comms_source:getFaction()]].station_score_total*stat_list.weight.station)
			setCommsMessage(out)
			addCommsReply(_("Back"), return_function)
		end)
		addCommsReply(string.format(_("stationStats-comms","Player ship values (Total:%i)"),stat_list[f2s[comms_source:getFaction()]].ship_score_total),function()
			local out = _("stationStats-comms","Player ships: (value, type, name)")
			for name, details in pairs(stat_list[f2s[comms_source:getFaction()]].ship) do
				out = string.format(_("stationStats-comms","%s\n   %i, %s, %s"),out,details.score_value,details.template_type,name)
			end
			out = string.format(_("stationStats-comms","%s\nTotal:%i multiplied by weight (%i%%) = weighted total:%.1f"),out,stat_list[f2s[comms_source:getFaction()]].ship_score_total,stat_list.weight.ship*100,stat_list[f2s[comms_source:getFaction()]].ship_score_total*stat_list.weight.ship)
			setCommsMessage(out)
			addCommsReply(_("Back"), return_function)
		end)
		addCommsReply(string.format(_("stationStats-comms","NPC ship values (Total:%i)"),stat_list[f2s[comms_source:getFaction()]].npc_score_total),function()
			local out = _("stationStats-comms","NPC assets: value, type, name (location)")
			for name, details in pairs(stat_list[f2s[comms_source:getFaction()]].npc) do
				if details.template_type ~= nil then
					out = string.format(_("stationStats-comms","%s\n   %i, %s, %s"),out,details.score_value,details.template_type,name)
				elseif details.topic ~= nil then
					out = string.format(_("stationStats-comms","%s\n   %i, %s, %s (%s)"),out,details.score_value,details.topic,name,details.location_name)
				end
			end
			out = string.format(_("stationStats-comms","%s\nTotal:%i multiplied by weight (%i%%) = weighted total:%.1f"),out,stat_list[f2s[comms_source:getFaction()]].npc_score_total,stat_list.weight.npc*100,stat_list[f2s[comms_source:getFaction()]].npc_score_total*stat_list.weight.npc)
			setCommsMessage(out)
			addCommsReply(_("Back"), return_function)
		end)
		addCommsReply(_("Back"), return_function)
	end)
end
function advanceIntel(return_function)
	addCommsReply(_("stationIntel-comms","Where are the enemy headquarters?"),function()
		local out = ""
		for faction, p_s_info in pairs(faction_primary_station) do
			if faction ~= comms_source:getFaction() then
				if p_s_info.station:isValid() then
					if out == "" then
						out = string.format(_("stationIntel-comms","%s primary station %s is located in sector %s."),faction,p_s_info.station:getCallSign(),p_s_info.station:getSectorName())
					else
						out = string.format(_("stationIntel-comms","%s\n%s primary station %s is located in sector %s."),out,faction,p_s_info.station:getCallSign(),p_s_info.station:getSectorName())
					end
				else
					if out == "" then
						out = string.format(_("stationIntel-comms","%s primary station is off the grid."),faction)
					else
						out = string.format(_("stationIntel-comms","%s\n%s primary station is off the grid."),out,faction)
					end
				end
			end
		end
		setCommsMessage(string.format(_("stationIntel-comms","The intelligence department has provided this information:\n%s"),out))
		addCommsReply(_("Back"), return_function)
	end)
end
--	Undocked actions
function getServiceCost(service)
    return math.ceil(comms_data.service_cost[service])
end
function requestSupplyDrop(return_function)
	if isAllowedTo(comms_target.comms_data.services.supplydrop) then
        addCommsReply(string.format(_("stationAssist-comms", "Can you send a supply drop? (%d rep)"), getServiceCost("supplydrop")), function()
            if comms_source:getWaypointCount() < 1 then
                setCommsMessage(_("stationAssist-comms", "You need to set a waypoint before you can request backup."));
            else
                setCommsMessage(_("stationAssist-comms", "To which waypoint should we deliver your supplies?"));
                for n=1,comms_source:getWaypointCount() do
                    addCommsReply(string.format(_("stationAssist-comms", "WP %d"),n), function()
						if comms_source:takeReputationPoints(getServiceCost("supplydrop")) then
							local position_x, position_y = comms_target:getPosition()
							local target_x, target_y = comms_source:getWaypoint(n)
							local script = Script()
							script:setVariable("position_x", position_x):setVariable("position_y", position_y)
							script:setVariable("target_x", target_x):setVariable("target_y", target_y)
							script:setVariable("faction_id", comms_target:getFactionId()):run("supply_drop.lua")
							setCommsMessage(string.format(_("stationAssist-comms", "We have dispatched a supply ship toward WP %d"), n));
						else
							setCommsMessage(_("needRep-comms", "Not enough reputation!"));
						end
                        addCommsReply(_("Back"), return_function)
                    end)
                end
            end
            addCommsReply(_("Back"), return_function)
        end)
    end
end
function requestJumpSupplyDrop(return_function)
	if isAllowedTo(comms_target.comms_data.services.jumpsupplydrop) then
        addCommsReply(string.format(_("stationAssist-comms", "Can you send a supply drop via jump ship? (%d rep)"), getServiceCost("jumpsupplydrop")), function()
            if comms_source:getWaypointCount() < 1 then
                setCommsMessage(_("stationAssist-comms", "You need to set a waypoint before you can request backup."));
            else
                setCommsMessage(_("stationAssist-comms", "To which waypoint should we deliver your supplies?"));
                for n=1,comms_source:getWaypointCount() do
                    addCommsReply(string.format(_("stationAssist-comms", "WP %d"),n), function()
						if comms_source:takeReputationPoints(getServiceCost("jumpsupplydrop")) then
							local position_x, position_y = comms_target:getPosition()
							local target_x, target_y = comms_source:getWaypoint(n)
							local script = Script()
							script:setVariable("position_x", position_x):setVariable("position_y", position_y)
							script:setVariable("target_x", target_x):setVariable("target_y", target_y)
							script:setVariable("jump_freighter","Yes")
							script:setVariable("faction_id", comms_target:getFactionId()):run("supply_drop.lua")
							setCommsMessage(string.format(_("stationAssist-comms", "We have dispatched a supply ship with a jump drive toward WP %d"), n));
						else
							setCommsMessage(_("needRep-comms", "Not enough reputation!"));
						end
                        addCommsReply(_("Back"), return_function)
                    end)
                end
            end
            addCommsReply(_("Back"), return_function)
        end)
    end
end
function requestReinforcements(return_function)
    if isAllowedTo(comms_target.comms_data.services.reinforcements) then
    	addCommsReply(_("stationAssist-comms", "Please send reinforcements"),function()
    		if comms_source:getWaypointCount() < 1 then
    			setCommsMessage(_("stationAssist-comms", "You need to set a waypoint before you can request reinforcements"))
    		else
    			setCommsMessage(_("stationAssist-comms", "What kind of reinforcements would you like?"))
    			addCommsReply(string.format(_("stationAssist-comms", "Standard Adder MK5 (%d Rep)"),getServiceCost("reinforcements")),function()
    				if comms_source:getWaypointCount() < 1 then
    					setCommsMessage(_("stationAssist-comms", "You need to set a waypoint before you can request reinforcements"))
    				else
		                setCommsMessage(_("stationAssist-comms", "To which waypoint should we dispatch the Adder MK5?"));
    					for n=1,comms_source:getWaypointCount() do
    						addCommsReply(string.format(_("stationAssist-comms", "Waypoint %d"),n), function()
								if comms_source:takeReputationPoints(getServiceCost("reinforcements")) then
									ship = CpuShip():setFactionId(comms_target:getFactionId()):setPosition(comms_target:getPosition()):setTemplate("Adder MK5"):setScanned(true):orderDefendLocation(comms_source:getWaypoint(n))
									ship:setCommsScript(""):setCommsFunction(commsShip)
									ship.score_value = ship_template["Adder MK5"].strength
									table.insert(npc_fleet[comms_target:getFaction()],ship)
									setCommsMessage(string.format(_("stationAssist-comms", "We have dispatched %s to assist at waypoint %d"),ship:getCallSign(),n))
								else
									setCommsMessage(_("needRep-comms", "Not enough reputation!"));
								end
								addCommsReply(_("Back"), return_function)
    						end)
    					end
    				end
    				addCommsReply(_("Back"), return_function)
    			end)
    			if comms_data.service_cost.hornetreinforcements ~= nil then
					addCommsReply(string.format(_("stationAssist-comms", "MU52 Hornet (%d Rep)"),getServiceCost("hornetreinforcements")),function()
						if comms_source:getWaypointCount() < 1 then
							setCommsMessage(_("stationAssist-comms", "You need to set a waypoint before you can request reinforcements"))
						else
							setCommsMessage(_("stationAssist-comms", "To which waypoint should we dispatch the MU52 Hornet?"));
							for n=1,comms_source:getWaypointCount() do
								addCommsReply(string.format(_("stationAssist-comms", "Waypoint %d"),n), function()
									if comms_source:takeReputationPoints(getServiceCost("hornetreinforcements")) then
										ship = CpuShip():setFactionId(comms_target:getFactionId()):setPosition(comms_target:getPosition()):setTemplate("MU52 Hornet"):setScanned(true):orderDefendLocation(comms_source:getWaypoint(n))
										ship:setCommsScript(""):setCommsFunction(commsShip)
										ship.score_value = ship_template["MU52 Hornet"].strength
										table.insert(npc_fleet[comms_target:getFaction()],ship)
										setCommsMessage(string.format(_("stationAssist-comms", "We have dispatched %s to assist at waypoint %d"),ship:getCallSign(),n))
									else
										setCommsMessage(_("needRep-comms", "Not enough reputation!"));
									end
									addCommsReply(_("Back"), return_function)
								end)
							end
						end
						addCommsReply(_("Back"), return_function)
					end)
				end
    			if comms_data.service_cost.phobosreinforcements ~= nil then
					addCommsReply(string.format(_("stationAssist-comms", "Phobos T3 (%d Rep)"),getServiceCost("phobosreinforcements")),function()
						if comms_source:getWaypointCount() < 1 then
							setCommsMessage(_("stationAssist-comms", "You need to set a waypoint before you can request reinforcements"))
						else
							setCommsMessage(_("stationAssist-comms", "To which waypoint should we dispatch the Phobos T3?"));
							for n=1,comms_source:getWaypointCount() do
								addCommsReply(string.format(_("stationAssist-comms", "Waypoint %d"),n), function()
									if comms_source:takeReputationPoints(getServiceCost("phobosreinforcements")) then
										ship = CpuShip():setFactionId(comms_target:getFactionId()):setPosition(comms_target:getPosition()):setTemplate("Phobos T3"):setScanned(true):orderDefendLocation(comms_source:getWaypoint(n))
										ship:setCommsScript(""):setCommsFunction(commsShip)
										ship.score_value = ship_template["Phobos T3"].strength
										table.insert(npc_fleet[comms_target:getFaction()],ship)
										setCommsMessage(string.format(_("stationAssist-comms", "We have dispatched %s to assist at waypoint %d"),ship:getCallSign(),n))
									else
										setCommsMessage(_("needRep-comms", "Not enough reputation!"));
									end
									addCommsReply(_("Back"), return_function)
								end)
							end
						end
						addCommsReply(_("Back"), return_function)
					end)
				end
    		end
            addCommsReply(_("Back"), return_function)
    	end)
    end
end
function ordnanceAvailability(return_function)
	addCommsReply(_("ammo-comms", "What ordnance do you have available for restock?"), function()
		local missileTypeAvailableCount = 0
		local ordnanceListMsg = ""
		if comms_target.comms_data.weapon_available.Homing and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.Homing > 0) then
			missileTypeAvailableCount = missileTypeAvailableCount + 1
			ordnanceListMsg = ordnanceListMsg .. _("ammo-comms", "\n   Homing")
			if not comms_target.comms_data.weapon_inventory.Unlimited then
				ordnanceListMsg = ordnanceListMsg .. string.format(_("ammo-comms", "(%i)"),math.floor(comms_target.comms_data.weapon_inventory.Homing))
			end
		end
		if comms_target.comms_data.weapon_available.Nuke and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.Nuke > 0) then
			missileTypeAvailableCount = missileTypeAvailableCount + 1
			ordnanceListMsg = ordnanceListMsg .. _("ammo-comms", "\n   Nuke")
			if not comms_target.comms_data.weapon_inventory.Unlimited then
				ordnanceListMsg = ordnanceListMsg .. string.format(_("ammo-comms", "(%i)"),math.floor(comms_target.comms_data.weapon_inventory.Nuke))
			end
		end
		if comms_target.comms_data.weapon_available.Mine and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.Mine > 0) then
			missileTypeAvailableCount = missileTypeAvailableCount + 1
			ordnanceListMsg = ordnanceListMsg .. _("ammo-comms", "\n   Mine")
			if not comms_target.comms_data.weapon_inventory.Unlimited then
				ordnanceListMsg = ordnanceListMsg .. string.format(_("ammo-comms", "(%i)"),math.floor(comms_target.comms_data.weapon_inventory.Mine))
			end
		end
		if comms_target.comms_data.weapon_available.EMP and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.EMP > 0) then
			missileTypeAvailableCount = missileTypeAvailableCount + 1
			ordnanceListMsg = ordnanceListMsg .. _("ammo-comms", "\n   EMP")
			if not comms_target.comms_data.weapon_inventory.Unlimited then
				ordnanceListMsg = ordnanceListMsg .. string.format(_("ammo-comms", "(%i)"),math.floor(comms_target.comms_data.weapon_inventory.EMP))
			end
		end
		if comms_target.comms_data.weapon_available.HVLI and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.HVLI > 0) then
			missileTypeAvailableCount = missileTypeAvailableCount + 1
			ordnanceListMsg = ordnanceListMsg .. _("ammo-comms", "\n   HVLI")
			if not comms_target.comms_data.weapon_inventory.Unlimited then
				ordnanceListMsg = ordnanceListMsg .. string.format(_("ammo-comms", "(%i)"),math.floor(comms_target.comms_data.weapon_inventory.HVLI))
			end
		end
		if missileTypeAvailableCount == 0 then
			ordnanceListMsg = _("ammo-comms", "We have no ordnance available for restock")
		elseif missileTypeAvailableCount == 1 then
			ordnanceListMsg = string.format(_("ammo-comms", "We have the following type of ordnance available for restock:%s"), ordnanceListMsg)
		else
			ordnanceListMsg = string.format(_("ammo-comms", "We have the following types of ordnance available for restock:%s"), ordnanceListMsg)
		end
		setCommsMessage(ordnanceListMsg)
		addCommsReply(_("Back"), return_function)
	end)
end
function goodsAvailabilityOnStation(return_function)
	local goodsAvailable = false
	if comms_target.comms_data.goods ~= nil then
		for good, goodData in pairs(comms_target.comms_data.goods) do
			if goodData["quantity"] > 0 then
				goodsAvailable = true
			end
		end
	end
	if goodsAvailable then
		addCommsReply(_("trade-comms", "What goods do you have available for sale or trade?"), function()
			local goodsAvailableMsg = string.format(_("trade-comms", "Station %s:\nGoods or components available: quantity, cost in reputation"),comms_target:getCallSign())
			for good, goodData in pairs(comms_target.comms_data.goods) do
				goodsAvailableMsg = goodsAvailableMsg .. string.format(_("trade-comms", "\n   %14s: %2i, %3i"),good_desc[good],goodData["quantity"],goodData["cost"])
			end
			setCommsMessage(goodsAvailableMsg)
			addCommsReply(_("Back"), return_function)
		end)
	end
end
--[[
function expediteDock(return_function)
	if isAllowedTo(comms_target.comms_data.services.preorder) then
		addCommsReply("Expedite Dock",function()
			if comms_source.expedite_dock == nil then
				comms_source.expedite_dock = false
			end
			if comms_source.expedite_dock then
				--handle expedite request already present
				local existing_expedite = "Docking crew is standing by"
				if comms_target == comms_source.expedite_dock_station then
					existing_expedite = existing_expedite .. ". Current preorders:"
					local preorders_identified = false
					if comms_source.preorder_hvli ~= nil then
						preorders_identified = true
						existing_expedite = existing_expedite .. string.format("\n   HVLIs: %i",comms_source.preorder_hvli)
					end
					if comms_source.preorder_homing ~= nil then
						preorders_identified = true
						existing_expedite = existing_expedite .. string.format("\n   Homings: %i",comms_source.preorder_homing)						
					end
					if comms_source.preorder_mine ~= nil then
						preorders_identified = true
						existing_expedite = existing_expedite .. string.format("\n   Mines: %i",comms_source.preorder_mine)						
					end
					if comms_source.preorder_emp ~= nil then
						preorders_identified = true
						existing_expedite = existing_expedite .. string.format("\n   EMPs: %i",comms_source.preorder_emp)						
					end
					if comms_source.preorder_nuke ~= nil then
						preorders_identified = true
						existing_expedite = existing_expedite .. string.format("\n   Nukes: %i",comms_source.preorder_nuke)						
					end
					if comms_source.preorder_repair_crew ~= nil then
						preorders_identified = true
						existing_expedite = existing_expedite .. "\n   One repair crew"						
					end
					if comms_source.preorder_coolant ~= nil then
						preorders_identified = true
						existing_expedite = existing_expedite .. "\n   Coolant"						
					end
					if preorders_identified then
						existing_expedite = existing_expedite .. "\nWould you like to preorder anything else?"
					else
						existing_expedite = existing_expedite .. " none.\nWould you like to preorder anything?"						
					end
					preorder_message = existing_expedite
					preOrderOrdnance(return_function)
				else
					existing_expedite = existing_expedite .. string.format(" on station %s (not this station, %s).",comms_source.expedite_dock_station:getCallSign(),comms_target:getCallSign())
					setCommsMessage(existing_expedite)
				end
				addCommsReply(_("Back"),return_function)
			else
				setCommsMessage("If you would like to speed up the addition of resources such as energy, ordnance, etc., please provide a time frame for your arrival. A docking crew will stand by until that time, after which they will return to their normal duties")
				preorder_message = "Docking crew is standing by. Would you like to pre-order anything?"
				addCommsReply("One minute (5 rep)", function()
					if comms_source:takeReputationPoints(5) then
						comms_source.expedite_dock = true
						comms_source.expedite_dock_station = comms_target
						comms_source.expedite_dock_timer_max = 60
						preOrderOrdnance(return_function)
					else
						setCommsMessage(_("needRep-comms", "Insufficient reputation"))
					end
					addCommsReply(_("Back"), return_function)
				end)
				addCommsReply("Two minutes (10 Rep)", function()
					if comms_source:takeReputationPoints(10) then
						comms_source.expedite_dock = true
						comms_source.expedite_dock_station = comms_target
						comms_source.expedite_dock_timer_max = 120
						preOrderOrdnance(return_function)
					else
						setCommsMessage(_("needRep-comms", "Insufficient reputation"))
					end
					addCommsReply(_("Back"), return_function)
				end)
				addCommsReply("Three minutes (15 Rep)", function()
					if comms_source:takeReputationPoints(15) then
						comms_source.expedite_dock = true
						comms_source.expedite_dock_station = comms_target
						comms_source.expedite_dock_timer_max = 180
						preOrderOrdnance(return_function)
					else
						setCommsMessage(_("needRep-comms", "Insufficient reputation"))
					end
					addCommsReply(_("Back"), return_function)
				end)
			end
			addCommsReply(_("Back"), return_function)
		end)
	end
end
function preOrderOrdnance(return_function)
	setCommsMessage(preorder_message)
	local hvli_count = math.floor(comms_source:getWeaponStorageMax("HVLI") * comms_target.comms_data.max_weapon_refill_amount[getFriendStatus()]) - comms_source:getWeaponStorage("HVLI")
	if comms_target.comms_data.weapon_available.HVLI and isAllowedTo(comms_target.comms_data.weapons["HVLI"]) and hvli_count > 0 then
		local hvli_prompt = ""
		local hvli_cost = getWeaponCost("HVLI")
		if hvli_count > 1 then
			hvli_prompt = string.format("%i HVLIs * %i Rep = %i Rep",hvli_count,hvli_cost,hvli_count*hvli_cost)
		else
			hvli_prompt = string.format("%i HVLI * %i Rep = %i Rep",hvli_count,hvli_cost,hvli_count*hvli_cost)
		end
		addCommsReply(hvli_prompt,function()
			if comms_source:takeReputationPoints(hvli_count*hvli_cost) then
				comms_source.preorder_hvli = hvli_count
				if hvli_count > 1 then
					setCommsMessage(string.format("%i HVLIs preordered",hvli_count))
				else
					setCommsMessage(string.format("%i HVLI preordered",hvli_count))
				end
			else
				setCommsMessage(_("needRep-comms", "Insufficient reputation"))
			end
			preorder_message = "Docking crew is standing by. Would you like to pre-order anything?"
			addCommsReply(_("Back"),return_function)
		end)
	end
	local homing_count = math.floor(comms_source:getWeaponStorageMax("Homing") * comms_target.comms_data.max_weapon_refill_amount[getFriendStatus()]) - comms_source:getWeaponStorage("Homing")
	if comms_target.comms_data.weapon_available.Homing and isAllowedTo(comms_target.comms_data.weapons["Homing"]) and homing_count > 0 then
		local homing_prompt = ""
		local homing_cost = getWeaponCost("Homing")
		if homing_count > 1 then
			homing_prompt = string.format("%i Homings * %i Rep = %i Rep",homing_count,homing_cost,homing_count*homing_cost)
		else
			homing_prompt = string.format("%i Homing * %i Rep = %i Rep",homing_count,homing_cost,homing_count*homing_cost)
		end
		addCommsReply(homing_prompt,function()
			if comms_source:takeReputationPoints(homing_count*homing_cost) then
				comms_source.preorder_homing = homing_count
				if homing_count > 1 then
					setCommsMessage(string.format("%i Homings preordered",homing_count))
				else
					setCommsMessage(string.format("%i Homing preordered",homing_count))
				end
			else
				setCommsMessage(_("needRep-comms", "Insufficient reputation"))
			end
			preorder_message = "Docking crew is standing by. Would you like to pre-order anything?"
			addCommsReply(_("Back"),return_function)
		end)
	end
	local mine_count = math.floor(comms_source:getWeaponStorageMax("Mine") * comms_target.comms_data.max_weapon_refill_amount[getFriendStatus()]) - comms_source:getWeaponStorage("Mine")
	if comms_target.comms_data.weapon_available.Mine and isAllowedTo(comms_target.comms_data.weapons["Mine"]) and mine_count > 0 then
		local mine_prompt = ""
		local mine_cost = getWeaponCost("Mine")
		if mine_count > 1 then
			mine_prompt = string.format("%i Mines * %i Rep = %i Rep",mine_count,mine_cost,mine_count*mine_cost)
		else
			mine_prompt = string.format("%i Mine * %i Rep = %i Rep",mine_count,mine_cost,mine_count*mine_cost)
		end
		addCommsReply(mine_prompt,function()
			if comms_source:takeReputationPoints(mine_count*mine_cost) then
				comms_source.preorder_mine = mine_count
				if mine_count > 1 then
					setCommsMessage(string.format("%i Mines preordered",mine_count))
				else
					setCommsMessage(string.format("%i Mine preordered",mine_count))
				end
			else
				setCommsMessage(_("needRep-comms", "Insufficient reputation"))
			end
			preorder_message = "Docking crew is standing by. Would you like to pre-order anything?"
			addCommsReply(_("Back"),return_function)
		end)
	end
	local emp_count = math.floor(comms_source:getWeaponStorageMax("EMP") * comms_target.comms_data.max_weapon_refill_amount[getFriendStatus()]) - comms_source:getWeaponStorage("EMP")
	if comms_target.comms_data.weapon_available.EMP and isAllowedTo(comms_target.comms_data.weapons["EMP"]) and emp_count > 0 then
		local emp_prompt = ""
		local emp_cost = getWeaponCost("EMP")
		if emp_count > 1 then
			emp_prompt = string.format("%i EMPs * %i Rep = %i Rep",emp_count,emp_cost,emp_count*emp_cost)
		else
			emp_prompt = string.format("%i EMP * %i Rep = %i Rep",emp_count,emp_cost,emp_count*emp_cost)
		end
		addCommsReply(emp_prompt,function()
			if comms_source:takeReputationPoints(emp_count*emp_cost) then
				comms_source.preorder_emp = emp_count
				if emp_count > 1 then
					setCommsMessage(string.format("%i EMPs preordered",emp_count))
				else
					setCommsMessage(string.format("%i EMP preordered",emp_count))
				end
			else
				setCommsMessage(_("needRep-comms", "Insufficient reputation"))
			end
			preorder_message = "Docking crew is standing by. Would you like to pre-order anything?"
			addCommsReply(_("Back"),return_function)
		end)
	end
	local nuke_count = math.floor(comms_source:getWeaponStorageMax("Nuke") * comms_target.comms_data.max_weapon_refill_amount[getFriendStatus()]) - comms_source:getWeaponStorage("Nuke")
	if comms_target.comms_data.weapon_available.Nuke and isAllowedTo(comms_target.comms_data.weapons["Nuke"]) and nuke_count > 0 then
		local nuke_prompt = ""
		local nuke_cost = getWeaponCost("Nuke")
		if nuke_count > 1 then
			nuke_prompt = string.format("%i Nukes * %i Rep = %i Rep",nuke_count,nuke_cost,nuke_count*nuke_cost)
		else
			nuke_prompt = string.format("%i Nuke * %i Rep = %i Rep",nuke_count,nuke_cost,nuke_count*nuke_cost)
		end
		addCommsReply(nuke_prompt,function()
			if comms_source:takeReputationPoints(nuke_count*nuke_cost) then
				comms_source.preorder_nuke = nuke_count
				if nuke_count > 1 then
					setCommsMessage(string.format("%i Nukes preordered",nuke_count))
				else
					setCommsMessage(string.format("%i Nuke preordered",nuke_count))
				end
			else
				setCommsMessage(_("needRep-comms", "Insufficient reputation"))
			end
			preorder_message = "Docking crew is standing by. Would you like to pre-order anything?"
			addCommsReply(_("Back"),return_function)
		end)
	end
	if comms_source.preorder_repair_crew == nil then
		if random(1,100) <= 20 then
			if comms_source:isFriendly(comms_target) then
				if comms_source:getRepairCrewCount() < comms_source.maxRepairCrew then
					hireCost = math.random(30,60)
				else
					hireCost = math.random(45,90)
				end
				addCommsReply(string.format(_("trade-comms", "Recruit repair crew member for %i reputation"),hireCost), function()
					if not comms_source:takeReputationPoints(hireCost) then
						setCommsMessage(_("needRep-comms", "Insufficient reputation"))
					else
						comms_source.preorder_repair_crew = 1
						setCommsMessage("Repair crew hired on your behalf. They will board when you dock")
					end				
					preorder_message = "Docking crew is standing by. Would you like to pre-order anything?"
					addCommsReply(_("Back"),return_function)
				end)
			end
		end
	end
	if comms_source.preorder_coolant == nil then
		if random(1,100) <= 20 then
			if comms_source:isFriendly(comms_target) then
				if comms_source.initialCoolant ~= nil then
					local coolant_cost = math.random(45,90)
					if comms_source:getMaxCoolant() < comms_source.initialCoolant then
						coolant_cost = math.random(30,60)
					end
					addCommsReply(string.format("Set aside coolant for %i reputation",coolant_cost), function()
						if comms_source:takeReputationPoints(coolant_cost) then
							comms_source.preorder_coolant = 2
							setCommsMessage("Coolant set aside for you. It will be loaded when you dock")
						else
							setCommsMessage(_("needRep-comms", "Insufficient reputation"))
						end
						preorder_message = "Docking crew is standing by. Would you like to pre-order anything?"
						addCommsReply(_("Back"),return_function)
					end)
				end
			end
		end
	end
end
--]]
function activateDefenseFleet(return_function)
    if isAllowedTo(comms_target.comms_data.services.activatedefensefleet) and 
    	comms_target.comms_data.idle_defense_fleet ~= nil then
    	local defense_fleet_count = 0
    	for name, template in pairs(comms_target.comms_data.idle_defense_fleet) do
    		defense_fleet_count = defense_fleet_count + 1
    	end
    	if defense_fleet_count > 0 then
    		addCommsReply(string.format(_("station-comms","Activate station defense fleet (%s rep)"),getServiceCost("activatedefensefleet")),function()
    			if comms_source:takeReputationPoints(getServiceCost("activatedefensefleet")) then
    				local out = string.format(_("station-comms","%s defense fleet\n"),comms_target:getCallSign())
    				for name, template in pairs(comms_target.comms_data.idle_defense_fleet) do
    					local script = Script()
						local position_x, position_y = comms_target:getPosition()
						local station_name = comms_target:getCallSign()
						script:setVariable("position_x", position_x):setVariable("position_y", position_y)
						script:setVariable("station_name",station_name)
    					script:setVariable("name",name)
    					script:setVariable("template",template)
    					script:setVariable("faction_id",comms_target:getFactionId())
    					script:run("border_defend_station.lua")
    					out = out .. " " .. name
    					comms_target.comms_data.idle_defense_fleet[name] = nil
    				end
    				out = string.format(_("station-comms","%s\nactivated"),out)
    				setCommsMessage(out)
    			else
    				setCommsMessage(_("needRep-comms", "Insufficient reputation"))
    			end
				addCommsReply(_("Back"), return_function)
    		end)
		end
    end
end
--	Docked actions
function restockOrdnance(return_function)
	local missilePresence = 0
	local missile_types = {'Homing', 'Nuke', 'Mine', 'EMP', 'HVLI'}
	for idx, missile_type in ipairs(missile_types) do
		missilePresence = missilePresence + comms_source:getWeaponStorageMax(missile_type)
	end
	if missilePresence > 0 then
		if 	(comms_target.comms_data.weapon_available.Nuke   and comms_source:getWeaponStorageMax("Nuke")	> 0)	and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.Nuke	> 0) or 
			(comms_target.comms_data.weapon_available.EMP    and comms_source:getWeaponStorageMax("EMP")	> 0)	and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.EMP		> 0) or 
			(comms_target.comms_data.weapon_available.Homing and comms_source:getWeaponStorageMax("Homing")	> 0)	and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.Homing	> 0) or 
			(comms_target.comms_data.weapon_available.Mine   and comms_source:getWeaponStorageMax("Mine")	> 0)   	and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.Mine	> 0) or 
			(comms_target.comms_data.weapon_available.HVLI   and comms_source:getWeaponStorageMax("HVLI")	> 0)	and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.HVLI	> 0) then
			addCommsReply(_("ammo-comms", "I need ordnance restocked"), function()
				setCommsMessage(_("ammo-comms", "What type of ordnance?"))
				if comms_source:getWeaponStorageMax("Nuke") > 0 and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.Nuke > 0) then
					if comms_target.comms_data.weapon_available.Nuke then
						local ask = {_("ammo-comms", "Can you supply us with some nukes?"),_("ammo-comms", "We really need some nukes.")}
						local avail = ""
						if not comms_target.comms_data.weapon_inventory.Unlimited then
							avail = string.format(_("ammo-comms", ", %i avail"),math.floor(comms_target.comms_data.weapon_inventory.Nuke))
						end
						local nuke_prompt = string.format(_("ammo-comms", "%s (%i rep each%s)"),ask[math.random(1,#ask)],getWeaponCost("Nuke"),avail)
						addCommsReply(nuke_prompt, function()
							handleWeaponRestock("Nuke",return_function)
						end)
					end	--end station has nuke available if branch
				end	--end player can accept nuke if branch
				if comms_source:getWeaponStorageMax("EMP") > 0 and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.EMP > 0) then
					if comms_target.comms_data.weapon_available.EMP then
						local ask = {_("ammo-comms", "Please re-stock our EMP missiles."),_("ammo-comms", "Got any EMPs?")}
						local avail = ""
						if not comms_target.comms_data.weapon_inventory.Unlimited then
							avail = string.format(_("ammo-comms", ", %i avail"),math.floor(comms_target.comms_data.weapon_inventory.EMP))
						end
						local emp_prompt = string.format(_("ammo-comms", "%s (%i rep each%s)"),ask[math.random(1,#ask)],getWeaponCost("EMP"),avail)
						addCommsReply(emp_prompt, function()
							handleWeaponRestock("EMP",return_function)
						end)
					end	--end station has EMP available if branch
				end	--end player can accept EMP if branch
				if comms_source:getWeaponStorageMax("Homing") > 0 and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.Homing > 0) then
					if comms_target.comms_data.weapon_available.Homing then
						local ask = {_("ammo-comms", "Do you have spare homing missiles for us?"),_("ammo-comms", "Do you have extra homing missiles?")}
						local avail = ""
						if not comms_target.comms_data.weapon_inventory.Unlimited then
							avail = string.format(_("ammo-comms", ", %i avail"),math.floor(comms_target.comms_data.weapon_inventory.Homing))
						end
						local homing_prompt = string.format(_("ammo-comms", "%s (%i rep each%s)"),ask[math.random(1,#ask)],getWeaponCost("Homing"),avail)
						addCommsReply(homing_prompt, function()
							handleWeaponRestock("Homing",return_function)
						end)
					end	--end station has homing for player if branch
				end	--end player can accept homing if branch
				if comms_source:getWeaponStorageMax("Mine") > 0 and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.Mine > 0) then
					if comms_target.comms_data.weapon_available.Mine then
						local ask = {_("ammo-comms", "We could use some mines."),_("ammo-comms", "How about mines?")}
						local avail = ""
						if not comms_target.comms_data.weapon_inventory.Unlimited then
							avail = string.format(_("ammo-comms", ", %i avail"),math.floor(comms_target.comms_data.weapon_inventory.Mine))
						end
						local mine_prompt = string.format(_("ammo-comms", "%s (%i rep each%s)"),ask[math.random(1,#ask)],getWeaponCost("Mine"),avail)
						addCommsReply(mine_prompt, function()
							handleWeaponRestock("Mine",return_function)
						end)
					end	--end station has mine for player if branch
				end	--end player can accept mine if branch
				if comms_source:getWeaponStorageMax("HVLI") > 0 and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory.HVLI > 0) then
					if comms_target.comms_data.weapon_available.HVLI then
						local ask = {_("ammo-comms", "What about HVLI?"),_("ammo-comms", "Could you provide HVLI?")}
						local avail = ""
						if not comms_target.comms_data.weapon_inventory.Unlimited then
							avail = string.format(_("ammo-comms", ", %i avail"),math.floor(comms_target.comms_data.weapon_inventory.HVLI))
						end
						local hvli_prompt = string.format(_("ammo-comms", "%s (%i rep each%s)"),ask[math.random(1,#ask)],getWeaponCost("HVLI"),avail)
						addCommsReply(hvli_prompt, function()
							handleWeaponRestock("HVLI",return_function)
						end)
					end	--end station has HVLI for player if branch
				end	--end player can accept HVLI if branch
			end)	--end player requests secondary ordnance comms reply branch
		end	--end secondary ordnance available from station if branch
	end	--end missles used on player ship if branch
end
function repairSubsystems(return_function)
	local offer_repair = false
	if comms_target.comms_data.probe_launch_repair and not comms_source:getCanLaunchProbe() then
		offer_repair = true
	end
	if not offer_repair and comms_target.comms_data.hack_repair and not comms_source:getCanHack() then
		offer_repair = true
	end
	if not offer_repair and comms_target.comms_data.scan_repair and not comms_source:getCanScan() then
		offer_repair = true
	end
	if not offer_repair and comms_target.comms_data.combat_maneuver_repair and not comms_source:getCanCombatManeuver() then
		offer_repair = true
	end
	if not offer_repair and comms_target.comms_data.self_destruct_repair and not comms_source:getCanSelfDestruct() then
		offer_repair = true
	end
	if not offer_repair and comms_target.comms_data.tube_slow_down_repair then
		local tube_load_time_slowed = false
		if comms_source.normal_tube_load_time ~= nil then
			local tube_count = comms_source:getWeaponTubeCount()
			if tube_count > 0 then
				local tube_index = 0
				repeat
					if comms_source.normal_tube_load_time[tube_index] ~= comms_source:getTubeLoadTime(tube_index) then
						tube_load_time_slowed = true
						break
					end
					tube_index = tube_index + 1
				until(tube_index >= tube_count)
			end
		end
		if tube_load_time_slowed then
			offer_repair = true
		end
	end
	if offer_repair then
		addCommsReply(_("stationServices-comms", "Repair ship system"),function()
			setCommsMessage(_("stationServices-comms", "What system would you like repaired?"))
			if comms_target.comms_data.probe_launch_repair then
				if not comms_source:getCanLaunchProbe() then
					addCommsReply(_("stationServices-comms", "Repair probe launch system (5 Rep)"),function()
						if comms_source:takeReputationPoints(5) then
							comms_source:setCanLaunchProbe(true)
							setCommsMessage(_("stationServices-comms", "Your probe launch system has been repaired"))
						else
							setCommsMessage(_("needRep-comms", "Insufficient reputation"))
						end
						addCommsReply(_("Back"), return_function)
					end)
				end
			end
			if comms_target.comms_data.hack_repair then
				if not comms_source:getCanHack() then
					addCommsReply(_("stationServices-comms", "Repair hacking system (5 Rep)"),function()
						if comms_source:takeReputationPoints(5) then
							comms_source:setCanHack(true)
							setCommsMessage(_("stationServices-comms", "Your hack system has been repaired"))
						else
							setCommsMessage(_("needRep-comms", "Insufficient reputation"))
						end
						addCommsReply(_("Back"), return_function)
					end)
				end
			end
			if comms_target.comms_data.scan_repair then
				if not comms_source:getCanScan() then
					addCommsReply(_("stationServices-comms", "Repair scanners (5 Rep)"),function()
						if comms_source:takeReputationPoints(5) then
							comms_source:setCanScan(true)
							setCommsMessage(_("stationServices-comms", "Your scanners have been repaired"))
						else
							setCommsMessage(_("needRep-comms", "Insufficient reputation"))
						end
						addCommsReply(_("Back"), return_function)
					end)
				end
			end
			if comms_target.comms_data.combat_maneuver_repair then
				if not comms_source:getCanCombatManeuver() then
					addCommsReply(_("stationServices-comms", "Repair combat maneuver (5 Rep)"),function()
						if comms_source:takeReputationPoints(5) then
							comms_source:setCanCombatManeuver(true)
							setCommsMessage(_("stationServices-comms", "Your combat maneuver has been repaired"))
						else
							setCommsMessage(_("needRep-comms", "Insufficient reputation"))
						end
						addCommsReply(_("Back"), return_function)
					end)
				end
			end
			if comms_target.comms_data.self_destruct_repair then
				if not comms_source:getCanSelfDestruct() then
					addCommsReply(_("stationServices-comms", "Repair self destruct system (5 Rep)"),function()
						if comms_source:takeReputationPoints(5) then
							comms_source:setCanSelfDestruct(true)
							setCommsMessage(_("stationServices-comms", "Your self destruct system has been repaired"))
						else
							setCommsMessage(_("needRep-comms", "Insufficient reputation"))
						end
						addCommsReply(_("Back"), return_function)
					end)
				end
			end
			if comms_target.comms_data.tube_slow_down_repair then
				local tube_load_time_slowed = false
				if comms_source.normal_tube_load_time ~= nil then
					local tube_count = comms_source:getWeaponTubeCount()
					if tube_count > 0 then
						local tube_index = 0
						repeat
							if comms_source.normal_tube_load_time[tube_index] < comms_source:getTubeLoadTime(tube_index) then
								tube_load_time_slowed = true
								break
							end
							tube_index = tube_index + 1
						until(tube_index >= tube_count)
					end
				end
				if tube_load_time_slowed then
					addCommsReply(_("stationServices-comms", "Repair slow tube loading (5 Rep)"),function()
						if comms_source:takeReputationPoints(5) then
							local tube_count = comms_source:getWeaponTubeCount()
							local tube_index = 0
							repeat
								comms_source:setTubeLoadTime(tube_index,comms_source.normal_tube_load_time[tube_index])
								tube_index = tube_index + 1
							until(tube_index >= tube_count)
							setCommsMessage(_("stationServices-comms", "Your tube load times have been returned to normal"))
						else
							setCommsMessage(_("needRep-comms", "Insufficient reputation"))
						end
						addCommsReply(_("Back"), return_function)
					end)
				end
			end
			addCommsReply(_("Back"), return_function)
		end)
	end
end
function handleWeaponRestock(weapon, return_function)
    if not comms_source:isDocked(comms_target) then 
		setCommsMessage(_("station-comms", "You need to stay docked for that action."))
		return
	end
    if not isAllowedTo(comms_target.comms_data.weapons[weapon]) then
        if weapon == "Nuke" then setCommsMessage(_("ammo-comms", "We do not deal in weapons of mass destruction."))
        elseif weapon == "EMP" then setCommsMessage(_("ammo-comms", "We do not deal in weapons of mass disruption."))
        else setCommsMessage(_("ammo-comms", "We do not deal in those weapons.")) end
        return
    end
    local points_per_item = getWeaponCost(weapon)
    local item_amount = math.floor(comms_source:getWeaponStorageMax(weapon) * comms_target.comms_data.max_weapon_refill_amount[getFriendStatus()]) - comms_source:getWeaponStorage(weapon)
    if item_amount <= 0 then
        if weapon == "Nuke" then
            setCommsMessage(_("ammo-comms", "All nukes are charged and primed for destruction."));
        else
            setCommsMessage(_("ammo-comms", "Sorry, sir, but you are as fully stocked as I can allow."));
        end
        addCommsReply(_("Back"), return_function)
    else
		local inventory_status = ""
		if comms_source:getReputationPoints() > points_per_item * item_amount and (comms_target.comms_data.weapon_inventory.Unlimited or comms_target.comms_data.weapon_inventory[weapon] >= item_amount) then
			if comms_source:takeReputationPoints(points_per_item * item_amount) then
				comms_source:setWeaponStorage(weapon, comms_source:getWeaponStorage(weapon) + item_amount)
				if not comms_target.comms_data.weapon_inventory.Unlimited then
					comms_target.comms_data.weapon_inventory[weapon] = comms_target.comms_data.weapon_inventory[weapon] - item_amount
					inventory_status = string.format(_("ammo-comms", "\nStation inventory of %s type weapons reduced to %i"),weapon,math.floor(comms_target.comms_data.weapon_inventory[weapon]))
				end
				if comms_source:getWeaponStorage(weapon) == comms_source:getWeaponStorageMax(weapon) then
					setCommsMessage(_("ammo-comms", "You are fully loaded and ready to explode things.") .. inventory_status)
				else
					setCommsMessage(_("ammo-comms", "We generously resupplied you with some weapon charges.\nPut them to good use.") .. inventory_status)
				end
			else
				setCommsMessage(_("needRep-comms", "Not enough reputation."))
				return
			end
		else
			if comms_source:getReputationPoints() > points_per_item then
				setCommsMessage(_("ammo-comms", "Either you can't afford as much as I'd like to give you, or I don't have enough to fully restock you."))
				addCommsReply(_("ammo-comms", "Get just one"), function()
					if comms_source:takeReputationPoints(points_per_item) then
						comms_source:setWeaponStorage(weapon, comms_source:getWeaponStorage(weapon) + 1)
						if not comms_target.comms_data.weapon_inventory.Unlimited then
							comms_target.comms_data.weapon_inventory[weapon] = comms_target.comms_data.weapon_inventory[weapon] - 1
							inventory_status = string.format(_("ammo-comms", "\nStation inventory of %s type weapons reduced to %i"),weapon,math.floor(comms_target.comms_data.weapon_inventory[weapon]))
						end
						if comms_source:getWeaponStorage(weapon) == comms_source:getWeaponStorageMax(weapon) then
							setCommsMessage(_("ammo-comms", "You are fully loaded and ready to explode things.") .. inventory_status)
						else
							setCommsMessage(_("ammo-comms", "We generously resupplied you with one weapon charge.\nPut it to good use.") .. inventory_status)
						end
					else
						setCommsMessage(_("needRep-comms", "Not enough reputation."))
					end
					return
				end)
			else
				setCommsMessage(_("needRep-comms", "Not enough reputation."))
				return				
			end
		end
        addCommsReply(_("Back"), return_function)
    end
end
function buySellTrade(return_function)
	local goodCount = 0
	if comms_target.comms_data.goods == nil then
		return
	end
	for good, goodData in pairs(comms_target.comms_data.goods) do
		if goodData.quantity > 0 then
			goodCount = goodCount + 1
		end
	end
	if goodCount > 0 then
		addCommsReply(_("trade-comms", "Buy, sell, trade"), function()
			local goodsReport = string.format(_("trade-comms", "Station %s:\nGoods or components available for sale: quantity, cost in reputation\n"),comms_target:getCallSign())
			for good, goodData in pairs(comms_target.comms_data.goods) do
				goodsReport = goodsReport .. string.format(_("trade-comms", "     %s: %i, %i\n"),good_desc[good],goodData["quantity"],goodData["cost"])
			end
			if comms_target.comms_data.buy ~= nil then
				goodsReport = goodsReport .. _("trade-comms", "Goods or components station will buy: price in reputation\n")
				for good, price in pairs(comms_target.comms_data.buy) do
					goodsReport = goodsReport .. string.format(_("trade-comms", "     %s: %i\n"),good_desc[good],price)
				end
			end
			goodsReport = goodsReport .. string.format(_("trade-comms", "Current cargo aboard %s:\n"),comms_source:getCallSign())
			local cargoHoldEmpty = true
			local goodCount = 0
			if comms_source.goods ~= nil then
				for good, goodQuantity in pairs(comms_source.goods) do
					goodCount = goodCount + 1
					goodsReport = goodsReport .. string.format(_("trade-comms", "     %s: %i\n"),good_desc[good],goodQuantity)
				end
			end
			if goodCount < 1 then
				goodsReport = goodsReport .. _("trade-comms", "     Empty\n")
			end
			goodsReport = goodsReport .. string.format(_("trade-comms", "Available Space: %i, Available Reputation: %i\n"),comms_source.cargo,math.floor(comms_source:getReputationPoints()))
			setCommsMessage(goodsReport)
			for good, goodData in pairs(comms_target.comms_data.goods) do
				addCommsReply(string.format(_("trade-comms", "Buy one %s for %i reputation"),good_desc[good],goodData["cost"]), function()
					local goodTransactionMessage = string.format(_("trade-comms", "Type: %s, Quantity: %i, Rep: %i"),good_desc[good],goodData["quantity"],goodData["cost"])
					if comms_source.cargo < 1 then
						goodTransactionMessage = goodTransactionMessage .. _("trade-comms", "\nInsufficient cargo space for purchase")
					elseif goodData["cost"] > math.floor(comms_source:getReputationPoints()) then
						goodTransactionMessage = goodTransactionMessage .. _("needRep-comms", "\nInsufficient reputation for purchase")
					elseif goodData["quantity"] < 1 then
						goodTransactionMessage = goodTransactionMessage .. _("trade-comms", "\nInsufficient station inventory")
					else
						if comms_source:takeReputationPoints(goodData["cost"]) then
							comms_source.cargo = comms_source.cargo - 1
							goodData["quantity"] = goodData["quantity"] - 1
							if comms_source.goods == nil then
								comms_source.goods = {}
							end
							if comms_source.goods[good] == nil then
								comms_source.goods[good] = 0
							end
							comms_source.goods[good] = comms_source.goods[good] + 1
							goodTransactionMessage = goodTransactionMessage .. _("trade-comms", "\npurchased")
						else
							goodTransactionMessage = goodTransactionMessage .. _("needRep-comms", "\nInsufficient reputation for purchase")
						end
					end
					setCommsMessage(goodTransactionMessage)
					addCommsReply(_("Back"), return_function)
				end)
			end
			if comms_target.comms_data.buy ~= nil then
				for good, price in pairs(comms_target.comms_data.buy) do
					if comms_source.goods ~= nil then
						if comms_source.goods[good] ~= nil and comms_source.goods[good] > 0 then
							addCommsReply(string.format(_("trade-comms", "Sell one %s for %i reputation"),good_desc[good],price), function()
								local goodTransactionMessage = string.format(_("trade-comms", "Type: %s,  Reputation price: %i"),good,price)
								comms_source.goods[good] = comms_source.goods[good] - 1
								comms_source:addReputationPoints(price)
								goodTransactionMessage = goodTransactionMessage .. _("trade-comms", "\nOne sold")
								comms_source.cargo = comms_source.cargo + 1
								setCommsMessage(goodTransactionMessage)
								addCommsReply(_("Back"), return_function)
							end)
						end
					end
				end
			end
			if comms_target.comms_data.trade.food and comms_source.goods["food"] > 0 then
				for good, goodData in pairs(comms_target.comms_data.goods) do
					addCommsReply(string.format(_("trade-comms", "Trade food for %s"),good_desc[good]), function()
						local goodTransactionMessage = string.format(_("trade-comms", "Type: %s,  Quantity: %i"),good_desc[good],goodData["quantity"])
						if goodData["quantity"] < 1 then
							goodTransactionMessage = goodTransactionMessage .. _("trade-comms", "\nInsufficient station inventory")
						else
							goodData["quantity"] = goodData["quantity"] - 1
							if comms_source.goods == nil then
								comms_source.goods = {}
							end
							if comms_source.goods[good] == nil then
								comms_source.goods[good] = 0
							end
							comms_source.goods[good] = comms_source.goods[good] + 1
							comms_source.goods["food"] = comms_source.goods["food"] - 1
							goodTransactionMessage = goodTransactionMessage .. _("trade-comms", "\nTraded")
						end
						setCommsMessage(goodTransactionMessage)
						addCommsReply(_("Back"), return_function)
					end)
				end
			end
			if comms_target.comms_data.trade.medicine and comms_source.goods["medicine"] > 0 then
				for good, goodData in pairs(comms_target.comms_data.goods) do
					addCommsReply(string.format(_("trade-comms", "Trade medicine for %s"),good_desc[good]), function()
						local goodTransactionMessage = string.format(_("trade-comms", "Type: %s,  Quantity: %i"),good_desc[good],goodData["quantity"])
						if goodData["quantity"] < 1 then
							goodTransactionMessage = goodTransactionMessage .. _("trade-comms", "\nInsufficient station inventory")
						else
							goodData["quantity"] = goodData["quantity"] - 1
							if comms_source.goods == nil then
								comms_source.goods = {}
							end
							if comms_source.goods[good] == nil then
								comms_source.goods[good] = 0
							end
							comms_source.goods[good] = comms_source.goods[good] + 1
							comms_source.goods["medicine"] = comms_source.goods["medicine"] - 1
							goodTransactionMessage = goodTransactionMessage .. _("trade-comms", "\nTraded")
						end
						setCommsMessage(goodTransactionMessage)
						addCommsReply(_("Back"), return_function)
					end)
				end
			end
			if comms_target.comms_data.trade.luxury and comms_source.goods["luxury"] > 0 then
				for good, goodData in pairs(comms_target.comms_data.goods) do
					addCommsReply(string.format(_("trade-comms", "Trade luxury for %s"),good_desc[good]), function()
						local goodTransactionMessage = string.format(_("trade-comms", "Type: %s,  Quantity: %i"),good_desc[good],goodData["quantity"])
						if goodData[quantity] < 1 then
							goodTransactionMessage = goodTransactionMessage .. _("trade-comms", "\nInsufficient station inventory")
						else
							goodData["quantity"] = goodData["quantity"] - 1
							if comms_source.goods == nil then
								comms_source.goods = {}
							end
							if comms_source.goods[good] == nil then
								comms_source.goods[good] = 0
							end
							comms_source.goods[good] = comms_source.goods[good] + 1
							comms_source.goods["luxury"] = comms_source.goods["luxury"] - 1
							goodTransactionMessage = goodTransactionMessage .. _("trade-comms", "\nTraded")
						end
						setCommsMessage(goodTransactionMessage)
						addCommsReply(_("Back"), return_function)
					end)
				end
			end
			addCommsReply(_("Back"), return_function)
		end)
	end
end
function boostSensorsWhileDocked(return_function)
	if comms_target.comms_data.sensor_boost ~= nil then
		if comms_target.comms_data.sensor_boost.cost > 0 then
			addCommsReply(string.format(_("upgrade-comms","Augment scan range with station sensors while docked (%i rep)"),comms_target.comms_data.sensor_boost.cost),function()
				if comms_source:takeReputationPoints(comms_target.comms_data.sensor_boost.cost) then
					if comms_source.normal_long_range_radar == nil then
						comms_source.normal_long_range_radar = comms_source:getLongRangeRadarRange()
					end
					comms_source:setLongRangeRadarRange(comms_source.normal_long_range_radar + comms_target.comms_data.sensor_boost.value)
					setCommsMessage(string.format(_("upgrade-comms","sensors increased by %i units"),comms_target.comms_data.sensor_boost.value/1000))
				else
					setCommsMessage(_("needRep-comms", "Insufficient reputation"))
				end
				addCommsReply(_("Back"), return_function)
			end)
		end
	end
end
function overchargeJump(return_function)
	if comms_target.comms_data.jump_overcharge and isAllowedTo(comms_target.comms_data.services.jumpovercharge) then
		if comms_source:hasJumpDrive() then
			local max_charge = comms_source.max_jump_range
			if max_charge == nil then
				max_charge = 50000
			end
			if comms_source:getJumpDriveCharge() >= max_charge then
				addCommsReply(string.format(_("upgrade-comms","Overcharge Jump Drive (%s rep)"),getServiceCost("jumpovercharge")),function()
					if comms_source:takeReputationPoints(getServiceCost("jumpovercharge")) then
						comms_source:setJumpDriveCharge(comms_source:getJumpDriveCharge() + max_charge)
						setCommsMessage(string.format(_("upgrade-comms","Your jump drive has been overcharged to %ik"),math.floor(comms_source:getJumpDriveCharge()/1000)))
					else
						setCommsMessage(_("needRep-comms", "Insufficient reputation"))
					end
					addCommsReply(_("Back"), return_function)
				end)
			end
		end
	end
end
--	Upgrades
function hullStrengthUpgrade(p)
	if p.hull_strength_upgrade == nil then
		p.hull_strength_upgrade = "done"
		p:setHullMax(p:getHullMax()*1.2)
		p:setHull(p:getHullMax())
		p:setImpulseMaxSpeed(p:getImpulseMaxSpeed()*.9)
		return true, _("upgrade-comms","Your hull strength has been increased by 20%")
	else
		return false, _("upgrade-comms","You already have the hull strength upgrade")
	end
end
function missileLoadSpeedUpgrade(p)
	if p.missile_load_speed_upgrade == nil then
		local tube_count = p:getWeaponTubeCount()
		if tube_count > 0 then
			local tube_index = 0
			if p.normal_tube_load_time == nil then
				p.normal_tube_load_time = {}
				repeat
					p.normal_tube_load_time[tube_index] = p:getTubeLoadTime(tube_index)
					tube_index = tube_index + 1
				until(tube_index >= tube_count)
				tube_index = 0
			end
			repeat
				p:setTubeLoadTime(tube_index,p.normal_tube_load_time[tube_index]*.8)
				p.normal_tube_load_time[tube_index] = p.normal_tube_load_time[tube_index]*.8
				tube_index = tube_index + 1				
			until(tube_index >= tube_count)
			return true, _("upgrade-comms","Your missile tube load time has been reduced by 20%")
		else
			return false, _("upgrade-comms","Your ship has no missile systems and thus cannot be upgraded")
		end
	else
		return false, _("upgrade-comms","You already have the missile load speed upgrade")
	end
end
function shieldStrengthUpgrade(p)
	if p.shield_strength_upgrade == nil then
		if p:getShieldCount() > 0 then
			p.shield_strength_upgrade = "done"
			if p:getShieldCount() == 1 then
				p:setShieldsMax(p:getShieldMax(0)*1.2)
			else
				p:setShieldsMax(p:getShieldMax(0)*1.2,p:getShieldMax(1)*1.2)
			end
			return true, _("upgrade-comms","Your ship shields are now 20% stronger. They'll need to charge to their new higher capacity")
		else
			return false, _("upgrade-comms","Your ship has no shields and thus cannot be upgraded")
		end
	else
		return false, _("upgrade-comms","You already have the shield upgrade")
	end
end
function beamDamageUpgrade(p)
	if p.beam_damage_upgrade == nil then
		if p:getBeamWeaponRange(0) > 0 then
			p.beam_damage_upgrade = "done"
			local bi = 0
			repeat
				local tempArc = p:getBeamWeaponArc(bi)
				local tempDir = p:getBeamWeaponDirection(bi)
				local tempRng = p:getBeamWeaponRange(bi)
				local tempCyc = p:getBeamWeaponCycleTime(bi)
				local tempDmg = p:getBeamWeaponDamage(bi)
				p:setBeamWeapon(bi,tempArc,tempDir,tempRng,tempCyc,tempDmg*1.2)
				p:setBeamWeaponHeatPerFire(bi,p:getBeamWeaponHeatPerFire(bi)*1.2)
				p:setBeamWeaponEnergyPerFire(bi,p:getBeamWeaponEnergyPerFire(bi)*1.2)
				bi = bi + 1
			until(p:getBeamWeaponRange(bi) < 1)
			return true, _("upgrade-comms","Your ship beam weapons damage has been increased by 20%")
		else
			return false, _("upgrade-comms","Your ship has no beam weapons and thus cannot be upgraded")
		end
	else
		return false, _("upgrade-comms","You already have the beam damage upgrade")
	end
end
function beamRangeUpgrade(p)
	if p.beam_range_upgrade == nil then
		if p:getBeamWeaponRange(0) > 0 then
			p.beam_range_upgrade = "done"
			local bi = 0
			repeat
				local tempArc = p:getBeamWeaponArc(bi)
				local tempDir = p:getBeamWeaponDirection(bi)
				local tempRng = p:getBeamWeaponRange(bi)
				local tempCyc = p:getBeamWeaponCycleTime(bi)
				local tempDmg = p:getBeamWeaponDamage(bi)
				p:setBeamWeapon(bi,tempArc,tempDir,tempRng*1.2,tempCyc,tempDmg)
				p:setBeamWeaponHeatPerFire(bi,p:getBeamWeaponHeatPerFire(bi)*1.2)
				p:setBeamWeaponEnergyPerFire(bi,p:getBeamWeaponEnergyPerFire(bi)*1.2)
				bi = bi + 1
			until(p:getBeamWeaponRange(bi) < 1)
			return true, _("upgrade-comms","Your ship beam weapons range has been increased by 20%")
		else
			return false, _("upgrade-comms","Your ship has no beam weapons and thus cannot be upgraded")
		end
	else
		return false, _("upgrade-comms","You already have the beam range upgrade")
	end
end
function batteryEfficiencyUpgrade(p)
	if p.battery_efficiency_upgrade == nil then
		p.battery_efficiency_upgrade = "done"
		p:setMaxEnergy(p:getMaxEnergy()*1.2)
		p:setImpulseMaxSpeed(p:getImpulseMaxSpeed()*.95)
		return true, _("upgrade-comms","Your ship batteries can now store 20% more energy. You'll need to charge them longer to use their full capacity")
	else
		return false, _("upgrade-comms","You already have the battery efficiency upgrade")
	end
end
function fasterImpulseUpgrade(p)
	if p.faster_impulse_upgrade == nil then
		p.faster_impulse_upgrade = "done"
		p:setImpulseMaxSpeed(p:getImpulseMaxSpeed()*1.2)
		p:setRotationMaxSpeed(p:getRotationMaxSpeed()*.95)
		return true, _("upgrade-comms","Your maximum impulse top speed has been increased by 20%")
	else
		return false, _("upgrade-comms","You already have an upgraded impulse engine")
	end
end
function longerSensorsUpgrade(p)
	if p.longer_sensors_upgrade == nil then
		p.longer_sensors_upgrade = "done"
		if p.normal_long_range_radar == nil then
			p.normal_long_range_radar = p:getLongRangeRadarRange()
		end
		p:setLongRangeRadarRange(p:getLongRangeRadarRange() + 10000)
		p.normal_long_range_radar = p.normal_long_range_radar + 10000
		return true, _("upgrade-comms","Your ship's long range sensors have had their reach increased by 10 units")
	else
		return false, _("upgrade-comms","You already have upgraded long range sensors")
	end
end
function fasterSpinUpgrade(p)
	if p.faster_spin_upgrade == nil then
		p.faster_spin_upgrade = "done"
		p:setRotationMaxSpeed(p:getRotationMaxSpeed()*1.2)
		return true, _("upgrade-comms","Your maneuvering speed has been increased by 20%")
	else
		return false, _("upgrade-comms","You already have upgraded maneuvering speed")
	end
end
---------------------------
--	Ship Communications  --
---------------------------
function commsShip()
	if comms_target.comms_data == nil then
		comms_target.comms_data = {friendlyness = random(0.0, 100.0)}
	end
	if comms_target.comms_data.goods == nil then
		comms_target.comms_data.goods = {}
		comms_target.comms_data.goods[commonGoods[math.random(1,#commonGoods)]] = {quantity = 1, cost = random(20,80)}
		local shipType = comms_target:getTypeName()
		if shipType:find("Freighter") ~= nil then
			if shipType:find("Goods") ~= nil or shipType:find("Equipment") ~= nil then
				repeat
					comms_target.comms_data.goods[commonGoods[math.random(1,#commonGoods)]] = {quantity = 1, cost = random(20,80)}
					local goodCount = 0
					for good, goodData in pairs(comms_target.comms_data.goods) do
						goodCount = goodCount + 1
					end
				until(goodCount >= 3)
			end
		end
	end
	if comms_source:isFriendly(comms_target) then
		return friendlyComms()
	end
	if comms_source:isEnemy(comms_target) and comms_target:isFriendOrFoeIdentifiedBy(comms_source) then
		return enemyComms()
	end
	return neutralComms()
end
function friendlyComms()
	if comms_target.comms_data.friendlyness < 20 then
		setCommsMessage(_("shipAssist-comms", "What do you want?"));
	else
		setCommsMessage(_("shipAssist-comms", "Sir, how can we assist?"));
	end
	shipDefendWaypoint(commsShip)
	shipFlyBlind(commsShip)
	shipAssistPlayer(commsShip)
	shipStatusReport(commsShip)
	shipDockNearby(commsShip)
	shipRoaming(commsShip)
	shipStandGround(commsShip)
	shipIdle(commsShip)
	fleetCommunication(commsShip)
	friendlyFreighterCommunication(commsShip)
	return true
end
function enemyComms()
	local faction = comms_target:getFaction()
	local tauntable = false
	local amenable = false
	if comms_target.comms_data.friendlyness >= 33 then	--final: 33
		--taunt logic
		local taunt_option = _("shipEnemy-comms", "We will see to your destruction!")
		local taunt_success_reply = _("shipEnemy-comms", "Your bloodline will end here!")
		local taunt_failed_reply = _("shipEnemy-comms", "Your feeble threats are meaningless.")
		local taunt_threshold = 30	--base chance of being taunted
		if faction == "Kraylor" then
			taunt_threshold = 35
			setCommsMessage(_("shipEnemy-comms", "Ktzzzsss.\nYou will DIEEee weaklingsss!"));
			local kraylorTauntChoice = math.random(1,3)
			if kraylorTauntChoice == 1 then
				taunt_option = _("shipEnemy-comms", "We will destroy you")
				taunt_success_reply = _("shipEnemy-comms", "We think not. It is you who will experience destruction!")
			elseif kraylorTauntChoice == 2 then
				taunt_option = _("shipEnemy-comms", "You have no honor")
				taunt_success_reply = _("shipEnemy-comms", "Your insult has brought our wrath upon you. Prepare to die.")
				taunt_failed_reply = _("shipEnemy-comms", "Your comments about honor have no meaning to us")
			else
				taunt_option = _("shipEnemy-comms", "We pity your pathetic race")
				taunt_success_reply = _("shipEnemy-comms", "Pathetic? You will regret your disparagement!")
				taunt_failed_reply = _("shipEnemy-comms", "We don't care what you think of us")
			end
		elseif faction == "Arlenians" then
			taunt_threshold = 25
			setCommsMessage(_("shipEnemy-comms", "We wish you no harm, but will harm you if we must.\nEnd of transmission."));
		elseif faction == "Exuari" then
			taunt_threshold = 40
			setCommsMessage(_("shipEnemy-comms", "Stay out of our way, or your death will amuse us extremely!"));
		elseif faction == "Ghosts" then
			taunt_threshold = 20
			setCommsMessage(_("shipEnemy-comms", "One zero one.\nNo binary communication detected.\nSwitching to universal speech.\nGenerating appropriate response for target from human language archives.\n:Do not cross us:\nCommunication halted."));
			taunt_option = _("shipEnemy-comms", "EXECUTE: SELFDESTRUCT")
			taunt_success_reply = _("shipEnemy-comms", "Rogue command received. Targeting source.")
			taunt_failed_reply = _("shipEnemy-comms", "External command ignored.")
		elseif faction == "Ktlitans" then
			setCommsMessage(_("shipEnemy-comms", "The hive suffers no threats. Opposition to any of us is opposition to us all.\nStand down or prepare to donate your corpses toward our nutrition."));
			taunt_option = _("shipEnemy-comms", "<Transmit 'The Itsy-Bitsy Spider' on all wavelengths>")
			taunt_success_reply = _("shipEnemy-comms", "We do not need permission to pluck apart such an insignificant threat.")
			taunt_failed_reply = _("shipEnemy-comms", "The hive has greater priorities than exterminating pests.")
		elseif faction == "TSN" then
			taunt_threshold = 15
			setCommsMessage(_("shipEnemy-comms", "State your business"))
		elseif faction == "USN" then
			taunt_threshold = 15
			setCommsMessage(_("shipEnemy-comms", "What do you want? (not that we care)"))
		elseif faction == "CUF" then
			taunt_threshold = 15
			setCommsMessage(_("shipEnemy-comms", "Don't waste our time"))
		else
			setCommsMessage(_("shipEnemy-comms", "Mind your own business!"));
		end
		comms_target.comms_data.friendlyness = comms_target.comms_data.friendlyness - random(0, 10)	--reduce friendlyness after each interaction
		addCommsReply(taunt_option, function()
			if random(0, 100) <= taunt_threshold then	--final: 30
				local current_order = comms_target:getOrder()
				print("order: " .. current_order)
				--Possible order strings returned:
				--Roaming
				--Fly towards
				--Attack
				--Stand Ground
				--Idle
				--Defend Location
				--Defend Target
				--Fly Formation (?)
				--Fly towards (ignore all)
				--Dock
				if comms_target.original_order == nil then
					comms_target.original_faction = faction
					comms_target.original_order = current_order
					if current_order == "Fly towards" or current_order == "Defend Location" or current_order == "Fly towards (ignore all)" then
						comms_target.original_target_x, comms_target.original_target_y = comms_target:getOrderTargetLocation()
						--print(string.format("Target_x: %f, Target_y: %f",comms_target.original_target_x,comms_target.original_target_y))
					end
					if current_order == "Attack" or current_order == "Dock" or current_order == "Defend Target" then
						local original_target = comms_target:getOrderTarget()
						--print("target:")
						--print(original_target)
						--print(original_target:getCallSign())
						comms_target.original_target = original_target
					end
					comms_target.taunt_may_expire = true	--change to conditional in future refactoring
					table.insert(enemy_reverts,comms_target)
				end
				comms_target:orderAttack(comms_source)	--consider alternative options besides attack in future refactoring
				setCommsMessage(taunt_success_reply);
			else
				setCommsMessage(taunt_failed_reply);
			end
		end)
		tauntable = true
	end
	local enemy_health = getEnemyHealth(comms_target)
	if change_enemy_order_diagnostic then print(string.format("   enemy health:    %.2f",enemy_health)) end
	if change_enemy_order_diagnostic then print(string.format("   friendliness:    %.1f",comms_target.comms_data.friendlyness)) end
	if comms_target.comms_data.friendlyness >= 66 or enemy_health < .5 then	--final: 66, .5
		--amenable logic
		local amenable_chance = comms_target.comms_data.friendlyness/3 + (1 - enemy_health)*30
		if change_enemy_order_diagnostic then print(string.format("   amenability:     %.1f",amenable_chance)) end
		addCommsReply("Stop your actions",function()
			local amenable_roll = random(0,100)
			if change_enemy_order_diagnostic then print(string.format("   amenable roll:   %.1f",amenable_roll)) end
			if amenable_roll < amenable_chance then
				local current_order = comms_target:getOrder()
				if comms_target.original_order == nil then
					comms_target.original_order = current_order
					comms_target.original_faction = faction
					if current_order == "Fly towards" or current_order == "Defend Location" or current_order == "Fly towards (ignore all)" then
						comms_target.original_target_x, comms_target.original_target_y = comms_target:getOrderTargetLocation()
						--print(string.format("Target_x: %f, Target_y: %f",comms_target.original_target_x,comms_target.original_target_y))
					end
					if current_order == "Attack" or current_order == "Dock" or current_order == "Defend Target" then
						local original_target = comms_target:getOrderTarget()
						--print("target:")
						--print(original_target)
						--print(original_target:getCallSign())
						comms_target.original_target = original_target
					end
					table.insert(enemy_reverts,comms_target)
				end
				comms_target.amenability_may_expire = true
				comms_target:orderIdle()
				comms_target:setFaction("Independent")
				setCommsMessage("Just this once, we'll take your advice")
			else
				setCommsMessage("No")
			end
		end)
		comms_target.comms_data.friendlyness = comms_target.comms_data.friendlyness - random(0, 10)	--reduce friendlyness after each interaction
		amenable = true
	end
	if tauntable or amenable then
		return true
	else
		return false
	end
end
function neutralComms()
	local shipType = comms_target:getTypeName()
	if shipType:find("Freighter") ~= nil or shipType:find("Transport") ~= nil or shipType:find("Cargo") ~= nil then
		setCommsMessage(_("trade-comms", "Yes?"))
		shipCargoSellReport(commsShip)
		if distance(comms_source,comms_target) < 5000 then
			if comms_source.cargo > 0 then
				if comms_target.comms_data.friendlyness > 66 then
					if shipType:find("Goods") ~= nil or shipType:find("Equipment") ~= nil then
						shipBuyGoods(commsShip,1)
					else
						shipBuyGoods(commsShip,2)
					end
				elseif comms_target.comms_data.friendlyness > 33 then
					if shipType:find("Goods") ~= nil or shipType:find("Equipment") ~= nil then
						shipBuyGoods(commsShip,2)
					else
						shipBuyGoods(commsShip,3)
					end
				else	--least friendly
					if shipType:find("Goods") ~= nil or shipType:find("Equipment") ~= nil then
						shipBuyGoods(commsShip,3)
					end
				end	--end friendly branches
			end	--player has room for cargo
		end	--close enough to sell
	else	--not a freighter
		if comms_target.comms_data.friendlyness > 50 then
			setCommsMessage(_("ship-comms", "Sorry, we have no time to chat with you.\nWe are on an important mission."));
		else
			setCommsMessage(_("ship-comms", "We have nothing for you.\nGood day."));
		end
	end	--end non-freighter communications else branch
	return true
end	--end neutral communications function
function shipStatusReport(return_function)
	addCommsReply(_("shipAssist-comms", "Report status"), function()
		msg = string.format(_("shipAssist-comms", "Hull: %d%%\n"), math.floor(comms_target:getHull() / comms_target:getHullMax() * 100))
		local shields = comms_target:getShieldCount()
		if shields == 1 then
			msg = string.format(_("shipAssist-comms", "%sShield: %d%%\n"),msg, math.floor(comms_target:getShieldLevel(0) / comms_target:getShieldMax(0) * 100))
		elseif shields == 2 then
			msg = string.format(_("shipAssist-comms", "%sFront Shield: %d%%\n"),msg, math.floor(comms_target:getShieldLevel(0) / comms_target:getShieldMax(0) * 100))
			msg = string.format(_("shipAssist-comms", "%sRear Shield: %d%%\n"),msg, math.floor(comms_target:getShieldLevel(1) / comms_target:getShieldMax(1) * 100))
		else
			for n=0,shields-1 do
				msg = string.format(_("shipAssist-comms", "%sShield %s: %d%%\n"),msg, n, math.floor(comms_target:getShieldLevel(n) / comms_target:getShieldMax(n) * 100))
			end
		end
		local missile_types = {'Homing', 'Nuke', 'Mine', 'EMP', 'HVLI'}
		for i, missile_type in ipairs(missile_types) do
			if comms_target:getWeaponStorageMax(missile_type) > 0 then
				msg = string.format(_("shipAssist-comms", "%s%s Missiles: %d/%d\n"),msg, missile_type, math.floor(comms_target:getWeaponStorage(missile_type)), math.floor(comms_target:getWeaponStorageMax(missile_type)))
			end
		end
		if comms_target:hasJumpDrive() then
			msg = string.format(_("shipAssist-comms","%sJump drive charge: %s"),msg,comms_target:getJumpDriveCharge())
		end
		setCommsMessage(msg)
		addCommsReply(_("Back"), return_function)
	end)
end
function shipIdle(return_function)
	addCommsReply(_("shipAssist-comms", "Stop. Do nothing."), function()
		comms_target:orderIdle()
		local idle_comment = {
			_("shipAssist-comms","routine system maintenance"),
			_("shipAssist-comms","for idle ship gossip"),
			_("shipAssist-comms","exterior paint touch-up"),
			_("shipAssist-comms","exercise for continued fitness"),
			_("shipAssist-comms","meditation therapy"),
			_("shipAssist-comms","internal simulated flight routines"),
			_("shipAssist-comms","digital dreamscape construction"),
			_("shipAssist-comms","catching up on reading the latest war drama novel"),
			_("shipAssist-comms","writing up results of bifurcated personality research"),
			_("shipAssist-comms","categorizing nearby miniscule space particles"),
			_("shipAssist-comms","continuing the count of visible stars from this region"),
			_("shipAssist-comms","internal systems diagnostics"),
		}
		setCommsMessage(string.format(_("shipAssist-comms", "Stopping. Doing nothing except %s."),idle_comment[math.random(1,#idle_comment)]))
		addCommsReply(_("Back"), return_function)
	end)
end
function shipRoaming(return_function)
	addCommsReply(_("shipAssist-comms", "Attack all enemies. Start with the nearest."), function()
		comms_target:orderRoaming()
		setCommsMessage(_("shipAssist-comms", "Searching and destroying"))
		addCommsReply(_("Back"), return_function)
	end)
end
function shipStandGround(return_function)
	addCommsReply(_("shipAssist-comms", "Stop and defend your current location"), function()
		comms_target:orderStandGround()
		setCommsMessage(_("shipAssist-comms", "Stopping. Shooting any enemy that approaches"))
		addCommsReply(_("Back"), return_function)
	end)
end
function shipDefendWaypoint(return_function)
	addCommsReply(_("shipAssist-comms", "Defend a waypoint"), function()
		if comms_source:getWaypointCount() == 0 then
			setCommsMessage(_("shipAssist-comms", "No waypoints set. Please set a waypoint first."));
			addCommsReply(_("Back"), return_function)
		else
			setCommsMessage(_("shipAssist-comms", "Which waypoint should we defend?"));
			for n=1,comms_source:getWaypointCount() do
				addCommsReply(string.format(_("shipAssist-comms", "Defend WP %d"), n), function()
					comms_target:orderDefendLocation(comms_source:getWaypoint(n))
					setCommsMessage(string.format(_("shipAssist-comms", "We are heading to assist at WP %d."), n));
					addCommsReply(_("Back"), return_function)
				end)
			end
		end
	end)
end
function shipFlyBlind(return_function)
	addCommsReply(_("shipAssist-comms", "Go to waypoint, ignore enemies"), function()
		if comms_source:getWaypointCount() == 0 then
			setCommsMessage(_("shipAssist-comms", "No waypoints set. Please set a waypoint first."));
			addCommsReply(_("Back"), return_function)
		else
			setCommsMessage(_("shipAssist-comms", "Which waypoint should we approach?"));
			for n=1,comms_source:getWaypointCount() do
				addCommsReply(string.format(_("shipAssist-comms", "Defend WP %d"), n), function()
					comms_target:orderFlyTowardsBlind(comms_source:getWaypoint(n))
					setCommsMessage(string.format(_("shipAssist-comms", "We are heading to WP%d ignoring enemies."), n));
					addCommsReply(_("Back"), return_function)
				end)
			end
		end
	end)
end
function shipAssistPlayer(return_function)
	if comms_target.comms_data.friendlyness > 0.2 then
		addCommsReply(_("shipAssist-comms", "Assist me"), function()
			setCommsMessage(_("shipAssist-comms", "Heading toward you to assist."));
			comms_target:orderDefendTarget(comms_source)
			addCommsReply(_("Back"), return_function)
		end)
	end
end
function shipDockNearby(return_function)
	for idx, obj in ipairs(comms_target:getObjectsInRange(5000)) do
		local player_carrier = false
		local template_name = ""
		if isObjectType(obj,"PlayerSpaceship") then
			template_name = obj:getTypeName()
			if template_name == "Benedict" or template_name == "Kiriya" or template_name == "Saipan" then
				player_carrier = true
			end
		end
		local defense_platform = false
		if isObjectType(obj,"CpuShip") then
			template_name = obj:getTypeName()
			if template_name == "Defense platform" then
				defense_platform = true
			end
		end
		if (isObjectType(obj,"SpaceStation") and not comms_target:isEnemy(obj)) or player_carrier or defense_platform then
			addCommsReply(string.format(_("shipAssist-comms", "Dock at %s"), obj:getCallSign()), function()
				setCommsMessage(string.format(_("shipAssist-comms", "Docking at %s."), obj:getCallSign()));
				comms_target:orderDock(obj)
				addCommsReply(_("Back"), return_function)
			end)
		end
	end
end
function fleetCommunication(return_function)
	if comms_target.fleetIndex ~= nil then
		addCommsReply(string.format(_("shipAssist-comms", "Direct fleet %i"),comms_target.fleetIndex), function()
			local fleet_state = string.format(_("shipAssist-comms", "Fleet %i consists of:\n"),comms_target.fleetIndex)
			for idx, ship in ipairs(npc_fleet[comms_target:getFaction()]) do
				if ship ~= nil and ship:isValid() then
					if ship.fleetIndex == comms_target.fleetIndex then
						fleet_state = fleet_state .. ship:getCallSign() .. " "
					end
				end
			end
			setCommsMessage(string.format(_("shipAssist-comms", "%s\n\nWhat command should be given to fleet %i?"),fleet_state,comms_target.fleetIndex))
			addCommsReply(_("shipAssist-comms", "Report hull and shield status"), function()
				msg = string.format(_("shipAssist-comms", "Fleet %i status:"),comms_target.fleetIndex)
				for idx, fleetShip in ipairs(npc_fleet[comms_target:getFaction()]) do
					if fleetShip.fleetIndex == comms_target.fleetIndex then
						if fleetShip ~= nil and fleetShip:isValid() then
							msg = string.format(_("shipAssist-comms", "%s\n %s:"),msg, fleetShip:getCallSign())
							msg = string.format(_("shipAssist-comms", "%s\n    Hull: %d%%"),msg, math.floor(fleetShip:getHull() / fleetShip:getHullMax() * 100))
							local shields = fleetShip:getShieldCount()
							if shields == 1 then
								msg = string.format(_("shipAssist-comms", "%s\n    Shield: %d%%"),msg, math.floor(fleetShip:getShieldLevel(0) / fleetShip:getShieldMax(0) * 100))
							else
								msg = string.format(_("shipAssist-comms", "%s\n    Shields: "),msg)
								if shields == 2 then
									msg = string.format(_("shipAssist-comms", "%sFront: %d%% Rear: %d%%"),msg, math.floor(fleetShip:getShieldLevel(0) / fleetShip:getShieldMax(0) * 100), math.floor(fleetShip:getShieldLevel(1) / fleetShip:getShieldMax(1) * 100))
								else
									for n=0,shields-1 do
										msg = string.format(_("shipAssist-comms", "%s %d:%d%%"),msg, n, math.floor(fleetShip:getShieldLevel(n) / fleetShip:getShieldMax(n) * 100))
									end
								end
							end
						end
					end
				end
				setCommsMessage(msg)
				addCommsReply(_("Back"), return_function)
			end)
			addCommsReply(_("shipAssist-comms", "Report missile status"), function()
				msg = string.format(_("shipAssist-comms", "Fleet %i missile status:"),comms_target.fleetIndex)
				for idx, fleetShip in ipairs(npc_fleet[comms_target:getFaction()]) do
					if fleetShip.fleetIndex == comms_target.fleetIndex then
						if fleetShip ~= nil and fleetShip:isValid() then
							msg = string.format(_("shipAssist-comms", "%s\n %s:"),msg, fleetShip:getCallSign())
							local missile_types = {'Homing', 'Nuke', 'Mine', 'EMP', 'HVLI'}
							missileMsg = ""
							for idx2, missile_type in ipairs(missile_types) do
								if fleetShip:getWeaponStorageMax(missile_type) > 0 then
									missileMsg = string.format(_("shipAssist-comms", "%s\n      %s: %d/%d"),missileMsg, missile_type, math.floor(fleetShip:getWeaponStorage(missile_type)), math.floor(fleetShip:getWeaponStorageMax(missile_type)))
								end
							end
							if missileMsg ~= "" then
								msg = string.format(_("shipAssist-comms", "%s\n    Missiles: %s"),msg, missileMsg)
							end
						end
					end
				end
				setCommsMessage(msg)
				addCommsReply(_("Back"), return_function)
			end)
			addCommsReply(_("shipAssist-comms", "Assist me"), function()
				for idx, fleetShip in ipairs(npc_fleet[comms_target:getFaction()]) do
					if fleetShip.fleetIndex == comms_target.fleetIndex then
						if fleetShip ~= nil and fleetShip:isValid() then
							fleetShip:orderDefendTarget(comms_source)
						end
					end
				end
				setCommsMessage(string.format(_("shipAssist-comms", "Fleet %s heading toward you to assist"),comms_target.fleetIndex))
				addCommsReply(_("Back"), return_function)
			end)
			addCommsReply(_("shipAssist-comms", "Defend a waypoint"), function()
				if comms_source:getWaypointCount() == 0 then
					setCommsMessage(_("shipAssist-comms", "No waypoints set. Please set a waypoint first."));
					addCommsReply(_("Back"), return_function)
				else
					setCommsMessage(_("shipAssist-comms", "Which waypoint should we defend?"));
					for n=1,comms_source:getWaypointCount() do
						addCommsReply(string.format(_("shipAssist-comms", "Defend WP %d"), n), function()
							for idx, fleetShip in ipairs(npc_fleet[comms_target:getFaction()]) do
								if fleetShip.fleetIndex == comms_target.fleetIndex then
									if fleetShip ~= nil and fleetShip:isValid() then
										fleetShip:orderDefendLocation(comms_source:getWaypoint(n))
									end
								end
							end
							setCommsMessage(string.format(_("shipAssist-comms", "We are heading to assist at WP %d."), n));
							addCommsReply(_("Back"), return_function)
						end)
					end
				end
			end)
			addCommsReply(_("shipAssist-comms", "Go to waypoint. Attack enemies en route"), function()
				if comms_source:getWaypointCount() == 0 then
					setCommsMessage(_("shipAssist-comms", "No waypoints set. Please set a waypoint first."));
					addCommsReply(_("Back"), return_function)
				else
					setCommsMessage(_("shipAssist-comms", "Which waypoint?"));
					for n=1,comms_source:getWaypointCount() do
						addCommsReply(string.format(_("shipAssist-comms", "Go to WP%d"),n), function()
							for idx, fleetShip in ipairs(npc_fleet[comms_target:getFaction()]) do
								if fleetShip.fleetIndex == comms_target.fleetIndex then
									if fleetShip ~= nil and fleetShip:isValid() then
										fleetShip:orderFlyTowards(comms_source:getWaypoint(n))
									end
								end
							end
							setCommsMessage(string.format(_("shipAssist-comms", "Going to WP%d, watching for enemies en route"), n));
							addCommsReply(_("Back"), return_function)
						end)
					end
				end
			end)
			addCommsReply(_("shipAssist-comms", "Go to waypoint. Ignore enemies"), function()
				if comms_source:getWaypointCount() == 0 then
					setCommsMessage(_("shipAssist-comms", "No waypoints set. Please set a waypoint first."));
					addCommsReply(_("Back"), return_function)
				else
					setCommsMessage(_("shipAssist-comms", "Which waypoint?"));
					for n=1,comms_source:getWaypointCount() do
						addCommsReply(string.format(_("shipAssist-comms", "Go to WP%d"),n), function()
							for idx, fleetShip in ipairs(npc_fleet[comms_target:getFaction()]) do
								if fleetShip.fleetIndex == comms_target.fleetIndex then
									if fleetShip ~= nil and fleetShip:isValid() then
										fleetShip:orderFlyTowardsBlind(comms_source:getWaypoint(n))
									end
								end
							end
							setCommsMessage(string.format(_("shipAssist-comms", "Going to WP%d, ignoring enemies"), n));
							addCommsReply(_("Back"), return_function)
						end)
					end
				end
			end)
			addCommsReply(_("shipAssist-comms", "Go offensive, attack all enemy targets"), function()
				for idx, fleetShip in ipairs(npc_fleet[comms_target:getFaction()]) do
					if fleetShip.fleetIndex == comms_target.fleetIndex then
						if fleetShip ~= nil and fleetShip:isValid() then
							fleetShip:orderRoaming()
						end
					end
				end
				setCommsMessage(string.format(_("shipAssist-comms", "Fleet %s is on an offensive rampage"),comms_target.fleetIndex))
				addCommsReply(_("Back"), return_function)
			end)
			addCommsReply(_("shipAssist-comms", "Stop and defend your current position"), function()
				for idx, fleetShip in ipairs(npc_fleet[comms_target:getFaction()]) do
					if fleetShip.fleetIndex == comms_target.fleetIndex then
						fleetShip:orderStandGround()
					end
				end
				setCommsMessage(_("shipAssist-comms", "Stopping and defending"))
				addCommsReply(_("Back"), return_function)
			end)
			addCommsReply(_("shipAssist-comms", "Stop and do nothing"), function()
				for idx, fleetShip in ipairs(npc_fleet[comms_target:getFaction()]) do
					if fleetShip.fleetIndex == comms_target.fleetIndex then
						fleetShip:orderIdle()
					end
				end
				setCommsMessage(_("shipAssist-comms", "Stopping and doing nothing"))
				addCommsReply(_("Back"), return_function)
			end)
		end)
	end
end
function friendlyFreighterCommunication(return_function)
	local shipType = comms_target:getTypeName()
	if shipType:find("Freighter") ~= nil then
		if distance(comms_source, comms_target) < 5000 then
			if comms_target.comms_data.friendlyness > 66 then
				if shipType:find("Goods") ~= nil or shipType:find("Equipment") ~= nil then
					shipTradeGoods(return_function)
				end	--goods or equipment freighter
				if comms_source.cargo > 0 then
					shipBuyGoods(return_function,1)
				end	--player has cargo space branch
			elseif comms_target.comms_data.friendlyness > 33 then
				if comms_source.cargo > 0 then
					if shipType:find("Goods") ~= nil or shipType:find("Equipment") ~= nil then
						shipBuyGoods(return_function,1)
					else	--not goods or equipment freighter
						shipBuyGoods(return_function,2)
					end
				end	--player has room for cargo branch
			else	--least friendly
				if comms_source.cargo > 0 then
					if shipType:find("Goods") ~= nil or shipType:find("Equipment") ~= nil then
						shipBuyGoods(return_function,2)
					end	--goods or equipment freighter
				end	--player has room to get goods
			end	--various friendliness choices
		else	--not close enough to sell
			shipCargoSellReport(return_function)
		end
	end
end
function shipCargoSellReport(return_function)
	addCommsReply(_("trade-comms", "Do you have cargo you might sell?"), function()
		local goodCount = 0
		local cargoMsg = _("trade-comms", "We've got ")
		for good, goodData in pairs(comms_target.comms_data.goods) do
			if goodData.quantity > 0 then
				if goodCount > 0 then
					cargoMsg = cargoMsg .. _("trade-comms",", ") .. good_desc[good]
				else
					cargoMsg = cargoMsg .. good_desc[good]
				end
			end
			goodCount = goodCount + goodData.quantity
		end
		if goodCount == 0 then
			cargoMsg = cargoMsg .. _("trade-comms", "nothing")
		end
		setCommsMessage(cargoMsg)
		addCommsReply(_("Back"), return_function)
	end)
end
function shipTradeGoods(return_function)
	if comms_source.goods ~= nil and comms_source.goods.luxury ~= nil and comms_source.goods.luxury > 0 then
		for good, goodData in pairs(comms_target.comms_data.goods) do
			if goodData.quantity > 0 and good ~= "luxury" then
				addCommsReply(string.format(_("trade-comms", "Trade luxury for %s"),good_desc[good]), function()
					goodData.quantity = goodData.quantity - 1
					if comms_source.goods == nil then
						comms_source.goods = {}
					end
					if comms_source.goods[good] == nil then
						comms_source.goods[good] = 0
					end
					comms_source.goods[good] = comms_source.goods[good] + 1
					comms_source.goods.luxury = comms_source.goods.luxury - 1
					setCommsMessage(string.format(_("trade-comms", "Traded your luxury for %s from %s"),good_desc[good],comms_target:getCallSign()))
					addCommsReply(_("Back"), return_function)
				end)
			end
		end	--freighter goods loop
	end	--player has luxury branch
end
function shipBuyGoods(return_function,price_multiplier)
	for good, goodData in pairs(comms_target.comms_data.goods) do
		if goodData.quantity > 0 then
			addCommsReply(string.format(_("trade-comms", "Buy one %s for %i reputation"),good_desc[good],math.floor(goodData.cost*price_multiplier)), function()
				if comms_source:takeReputationPoints(goodData.cost*price_multiplier) then
					goodData.quantity = goodData.quantity - 1
					if comms_source.goods == nil then
						comms_source.goods = {}
					end
					if comms_source.goods[good] == nil then
						comms_source.goods[good] = 0
					end
					comms_source.goods[good] = comms_source.goods[good] + 1
					comms_source.cargo = comms_source.cargo - 1
					setCommsMessage(string.format(_("trade-comms", "Purchased %s from %s"),good_desc[good],comms_target:getCallSign()))
				else
					setCommsMessage(_("needRep-comms", "Insufficient reputation for purchase"))
				end
				addCommsReply(_("Back"), return_function)
			end)
		end
	end	--freighter goods loop
end
-------------------------------
-- Defend ship communication --
-------------------------------
function commsDefendShip()
	if comms_target.comms_data == nil then
		comms_target.comms_data = {friendlyness = random(0.0, 100.0)}
	end
	comms_data = comms_target.comms_data
	if comms_source:isFriendly(comms_target) then
		return friendlyDefendComms(comms_data)
	end
	if comms_source:isEnemy(comms_target) and comms_target:isFriendOrFoeIdentifiedBy(comms_source) then
		return enemyDefendComms(comms_data)
	end
	return neutralDefendComms(comms_data)
end
function friendlyDefendComms(comms_data)
	if comms_data.friendlyness < 20 then
		setCommsMessage(_("shipAssist-comms", "What do you want?"));
	else
		setCommsMessage(_("shipAssist-comms", "Sir, how can we assist?"));
	end
	shipStatusReport(commsDefendShip)
	return true
end
function enemyDefendComms(comms_data)
    if comms_data.friendlyness > 50 then
        local faction = comms_target:getFaction()
        local taunt_option = _("shipEnemy-comms", "We will see to your destruction!")
        local taunt_success_reply = _("shipEnemy-comms", "Your bloodline will end here!")
        local taunt_failed_reply = _("shipEnemy-comms", "Your feeble threats are meaningless.")
        if faction == "Kraylor" then
            setCommsMessage(_("shipEnemy-comms", "Ktzzzsss.\nYou will DIEEee weaklingsss!"));
        elseif faction == "Arlenians" then
            setCommsMessage(_("shipEnemy-comms", "We wish you no harm, but will harm you if we must.\nEnd of transmission."));
        elseif faction == "Exuari" then
            setCommsMessage(_("shipEnemy-comms", "Stay out of our way, or your death will amuse us extremely!"));
        elseif faction == "Ghosts" then
            setCommsMessage(_("shipEnemy-comms", "One zero one.\nNo binary communication detected.\nSwitching to universal speech.\nGenerating appropriate response for target from human language archives.\n:Do not cross us:\nCommunication halted."));
            taunt_option = _("shipEnemy-comms", "EXECUTE: SELFDESTRUCT")
            taunt_success_reply = _("shipEnemy-comms", "Rogue command received. Targeting source.")
            taunt_failed_reply = _("shipEnemy-comms", "External command ignored.")
        elseif faction == "Ktlitans" then
            setCommsMessage(_("shipEnemy-comms", "The hive suffers no threats. Opposition to any of us is opposition to us all.\nStand down or prepare to donate your corpses toward our nutrition."));
            taunt_option = _("shipEnemy-comms", "<Transmit 'The Itsy-Bitsy Spider' on all wavelengths>")
            taunt_success_reply = _("shipEnemy-comms", "We do not need permission to pluck apart such an insignificant threat.")
            taunt_failed_reply = _("shipEnemy-comms", "The hive has greater priorities than exterminating pests.")
        else
            setCommsMessage(_("shipEnemy-comms", "Mind your own business!"));
        end
        comms_data.friendlyness = comms_data.friendlyness - random(0, 10)
        addCommsReply(taunt_option, function()
            if random(0, 100) < 30 then
                comms_target:orderAttack(player)
                setCommsMessage(taunt_success_reply);
            else
                setCommsMessage(taunt_failed_reply);
            end
        end)
        return true
    end
    return false
end
function neutralDefendComms(comms_data)
    if comms_data.friendlyness > 50 then
        setCommsMessage(_("ship-comms", "Sorry, we have no time to chat with you.\nWe are on an important mission."));
    else
        setCommsMessage(_("ship-comms", "We have nothing for you.\nGood day."));
    end
    return true
end

function playerShipCargoInventory(p)
	p:addToShipLog(string.format(_("inventory-shipLog", "%s Current cargo:"),p:getCallSign()),"Yellow")
	local goodCount = 0
	if p.goods ~= nil then
		for good, goodQuantity in pairs(p.goods) do
			goodCount = goodCount + 1
			p:addToShipLog(string.format(_("inventory-shipLog", "     %s: %i"),good_desc[good],goodQuantity),"Yellow")
		end
	end
	if goodCount < 1 then
		p:addToShipLog(_("inventory-shipLog", "     Empty"),"Yellow")
	end
	p:addToShipLog(string.format(_("inventory-shipLog", "Available space: %i"),p.cargo),"Yellow")
end
function resetPreviousSystemHealth(p)
	string.format("")	--may need global context
	if p == nil then
		p = comms_source
	end
	local currentShield = 0
	if p:getShieldCount() > 1 then
		currentShield = (p:getSystemHealth("frontshield") + p:getSystemHealth("rearshield"))/2
	else
		currentShield = p:getSystemHealth("frontshield")
	end
	p.prevShield = currentShield
	p.prevReactor = p:getSystemHealth("reactor")
	p.prevManeuver = p:getSystemHealth("maneuver")
	p.prevImpulse = p:getSystemHealth("impulse")
	if p:getBeamWeaponRange(0) > 0 then
		if p.healthyBeam == nil then
			p.healthyBeam = 1.0
			p.prevBeam = 1.0
		end
		p.prevBeam = p:getSystemHealth("beamweapons")
	end
	if p:getWeaponTubeCount() > 0 then
		if p.healthyMissile == nil then
			p.healthyMissile = 1.0
			p.prevMissile = 1.0
		end
		p.prevMissile = p:getSystemHealth("missilesystem")
	end
	if p:hasWarpDrive() then
		if p.healthyWarp == nil then
			p.healthyWarp = 1.0
			p.prevWarp = 1.0
		end
		p.prevWarp = p:getSystemHealth("warp")
	end
	if p:hasJumpDrive() then
		if p.healthyJump == nil then
			p.healthyJump = 1.0
			p.prevJump = 1.0
		end
		p.prevJump = p:getSystemHealth("jumpdrive")
	end
end
function gatherStats()
	local stat_list = {}
	stat_list.scenario = {name = "Chaos of War", version = scenario_version}
	stat_list.times = {}
	stat_list.times.game = {}
	stat_list.times.stage = game_state
	stat_list.times.game.max = max_game_time
	stat_list.times.game.total_seconds_left = game_time_limit
	stat_list.times.game.minutes_left = math.floor(game_time_limit / 60)
	stat_list.times.game.seconds_left = math.floor(game_time_limit % 60)
	stat_list.human = {}
	stat_list.human.ship = {}
	stat_list.human.ship_score_total = 0
	stat_list.human.npc = {}
	stat_list.human.npc_score_total = 0
	stat_list.human.station_score_total = 0
	stat_list.human.station = {}
	stat_list.kraylor = {}
	stat_list.kraylor.ship = {}
	stat_list.kraylor.ship_score_total = 0	
	stat_list.kraylor.npc = {}
	stat_list.kraylor.npc_score_total = 0
	stat_list.kraylor.station_score_total = 0
	stat_list.kraylor.station = {}
	if exuari_angle ~= nil then
		stat_list.exuari = {}
		stat_list.exuari.ship = {}
		stat_list.exuari.ship_score_total = 0
		stat_list.exuari.npc = {}
		stat_list.exuari.npc_score_total = 0
		stat_list.exuari.station_score_total = 0
		stat_list.exuari.station = {}
	end
	if ktlitan_angle ~= nil then
		stat_list.ktlitan = {}
		stat_list.ktlitan.ship = {}
		stat_list.ktlitan.ship_score_total = 0	
		stat_list.ktlitan.npc = {}
		stat_list.ktlitan.npc_score_total = 0
		stat_list.ktlitan.station_score_total = 0
		stat_list.ktlitan.station = {}
	end
	for pidx=1,32 do
		p = getPlayerShip(pidx)
		if p ~= nil then
			if p:isValid() then
				local faction = p:getFaction()
				if p.shipScore ~= nil then
					stat_list[f2s[faction]].ship_score_total = stat_list[f2s[faction]].ship_score_total + p.shipScore
					stat_list[f2s[faction]].ship[p:getCallSign()] = {template_type = p:getTypeName(), is_alive = true, score_value = p.shipScore}
				else
					print("ship score for " .. p:getCallSign() .. " has not been set")
				end
			end
		end
	end
	if npc_fleet ~= nil then
		for faction, list in pairs(npc_fleet) do
			for idx, ship in ipairs(list) do
				if ship:isValid() then
					stat_list[f2s[faction]].npc_score_total = stat_list[f2s[faction]].npc_score_total + ship.score_value
					stat_list[f2s[faction]].npc[ship:getCallSign()] = {template_type = ship:getTypeName(), is_alive = true, score_value = ship.score_value}
				end
			end
		end
	end
	if scientist_list ~= nil then
		for faction, list in pairs(scientist_list) do
			for idx, scientist in ipairs(list) do
				if scientist.location:isValid() then
					stat_list[f2s[faction]].npc_score_total = stat_list[f2s[faction]].npc_score_total + scientist.score_value
					stat_list[f2s[faction]].npc[scientist.name] = {topic = scientist.topic, is_alive = true, score_value = scientist.score_value, location_name = scientist.location_name}	
				end
			end
		end
	end
	for faction, list in pairs(station_list) do
		for idx, station in ipairs(list) do
			if station:isValid() then
				stat_list[f2s[faction]].station_score_total = stat_list[f2s[faction]].station_score_total + station.score_value
				stat_list[f2s[faction]].station[station:getCallSign()] = {template_type = station:getTypeName(), is_alive = true, score_value = station.score_value}
			end
		end
	end
	local station_weight = .6
	local player_ship_weight = .3
	local npc_ship_weight = .1
	stat_list.weight = {}
	stat_list.weight.station = station_weight
	stat_list.weight.ship = player_ship_weight
	stat_list.weight.npc = npc_ship_weight
	local human_death_penalty = 0
	local kraylor_death_penalty = 0
	local exuari_death_penalty = 0
	local ktlitan_death_penalty = 0
	if respawn_type == "self" then
		human_death_penalty = death_penalty["Human Navy"]
		stat_list.human.death_penalty = death_penalty["Human Navy"]
		kraylor_death_penalty = death_penalty["Kraylor"]
		stat_list.kraylor.death_penalty = death_penalty["Kraylor"]
		if exuari_angle ~= nil then
			exuari_death_penalty = death_penalty["Exuari"]
			stat_list.exuari.death_penalty = death_penalty["Exuari"]
		end
		if ktlitan_angle ~= nil then
			ktlitan_death_penalty = death_penalty["Ktlitans"]
			stat_list.ktlitan.death_penalty = death_penalty["Ktlitans"]
		end
	end
	stat_list.human.tie_breaker = 0
	stat_list.kraylor.tie_breaker = 0
	if exuari_angle ~= nil then
		stat_list.exuari.tie_breaker = 0
	end
	if ktlitan_angle ~= nil then
		stat_list.ktlitan.tie_breaker = 0
	end
	for i,p in ipairs(getActivePlayerShips()) do
		if p:getFaction() == "Human Navy" then
			stat_list.human.tie_breaker = p:getReputationPoints()/10000
			stat_list.human.reputation = p:getReputationPoints()
		end
		if p:getFaction() == "Kraylor" then
			stat_list.kraylor.tie_breaker = p:getReputationPoints()/10000
			stat_list.kraylor.reputation = p:getReputationPoints()
		end
		if exuari_angle ~= nil then
			if p:getFaction() == "Exuari" then
				stat_list.exuari.tie_breaker = p:getReputationPoints()/10000
				stat_list.exuari.reputation = p:getReputationPoints()
			end
		end
		if ktlitan_angle ~= nil then
			if p:getFaction() == "Ktlitans" then
				stat_list.ktlitan.tie_breaker = p:getReputationPoints()/10000
				stat_list.ktlitan.reputation = p:getReputationPoints()
			end
		end
	end
	stat_list.human.weighted_score = 
		stat_list.human.station_score_total*station_weight + 
		stat_list.human.ship_score_total*player_ship_weight + 
		stat_list.human.npc_score_total*npc_ship_weight - 
		human_death_penalty*player_ship_weight
	stat_list.human.comprehensive_weighted_score = 
		stat_list.human.weighted_score + 
		stat_list.human.tie_breaker
	stat_list.kraylor.weighted_score = 
		stat_list.kraylor.station_score_total*station_weight + 
		stat_list.kraylor.ship_score_total*player_ship_weight + 
		stat_list.kraylor.npc_score_total*npc_ship_weight - 
		kraylor_death_penalty*player_ship_weight
	stat_list.kraylor.comprehensive_weighted_score = 
		stat_list.kraylor.weighted_score + 
		stat_list.kraylor.tie_breaker
	if exuari_angle ~= nil then
		stat_list.exuari.weighted_score = 
			stat_list.exuari.station_score_total*station_weight + 
			stat_list.exuari.ship_score_total*player_ship_weight + 
			stat_list.exuari.npc_score_total*npc_ship_weight - 
			exuari_death_penalty*player_ship_weight
		stat_list.exuari.comprehensive_weighted_score = 
			stat_list.exuari.weighted_score +
			stat_list.exuari.tie_breaker
	end
	if ktlitan_angle ~= nil then
		stat_list.ktlitan.weighted_score = 
			stat_list.ktlitan.station_score_total*station_weight + 
			stat_list.ktlitan.ship_score_total*player_ship_weight + 
			stat_list.ktlitan.npc_score_total*npc_ship_weight - 
			ktlitan_death_penalty*player_ship_weight
		stat_list.ktlitan.comprehensive_weighted_score = 
			stat_list.ktlitan.weighted_score +
			stat_list.ktlitan.tie_breaker
	end
	if original_score ~= nil then
		stat_list.human.original_weighted_score = original_score["Human Navy"]
		stat_list.kraylor.original_weighted_score = original_score["Kraylor"]
		if exuari_angle ~= nil then
			stat_list.exuari.original_weighted_score = original_score["Exuari"]
		end
		if ktlitan_angle ~= nil then
			stat_list.ktlitan.original_weighted_score = original_score["Ktlitans"]
		end
	end
	return stat_list
end
function pickWinner(reason)
	local stat_list = gatherStats()
	local sorted_faction = {}
	local tie_breaker = {}
	for pidx=1,32 do
		local p = getPlayerShip(pidx)
		if p ~= nil and p:isValid() then
			tie_breaker[p:getFaction()] = p:getReputationPoints()/10000
		end
	end
	stat_list.human.comprehensive_weighted_score = stat_list.human.weighted_score + tie_breaker["Human Navy"]
	table.insert(sorted_faction,{name="Human Navy",score=stat_list.human.comprehensive_weighted_score})
	stat_list.kraylor.comprehensive_weighted_score = stat_list.kraylor.weighted_score + tie_breaker["Kraylor"]
	table.insert(sorted_faction,{name="Kraylor",score=stat_list.kraylor.comprehensive_weighted_score})
	if exuari_angle ~= nil then
		stat_list.exuari.comprehensive_weighted_score = stat_list.exuari.weighted_score + tie_breaker["Exuari"]
		table.insert(sorted_faction,{name="Exuari",score=stat_list.exuari.comprehensive_weighted_score})
	end
	if ktlitan_angle ~= nil then
		stat_list.ktlitan.comprehensive_weighted_score = stat_list.ktlitan.weighted_score + tie_breaker["Ktlitans"]
		table.insert(sorted_faction,{name="Ktlitans",score=stat_list.ktlitan.comprehensive_weighted_score})
	end
	table.sort(sorted_faction,function(a,b)
		return a.score > b.score
	end)
	local out = string.format(_("msgMainscreen", "%s wins with a score of %f!\n"),sorted_faction[1].name,sorted_faction[1].score)
	for i=2,#sorted_faction do
		out = out .. string.format(_("msgMainscreen", "%s:%f "),sorted_faction[i].name,sorted_faction[i].score)
	end
	out = out .. "\n" .. reason
	print(out)
	print("Humans:",stat_list.human.comprehensive_weighted_score,string.format("%s + %s",stat_list.human.weighted_score,tie_breaker["Human Navy"]))
	print("Kraylor:",stat_list.kraylor.comprehensive_weighted_score,string.format("%s + %s",stat_list.kraylor.weighted_score,tie_breaker["Kraylor"]))
	if exuari_angle then
		print("Exuari:",stat_list.exuari.comprehensive_weighted_score,string.format("%s + %s",stat_list.exuari.weighted_score,tie_breaker["Exuari"]))
	end
	if ktlitan_angle then
		print("Ktlitans:",stat_list.ktlitan.comprehensive_weighted_score,string.format("%s + %s",stat_list.ktlitan.weighted_score,tie_breaker["Ktlitans"]))
	end
	addGMMessage(out)
	globalMessage(out)
	game_state = string.format("victory-%s",f2s[sorted_faction[1].name])
	victory(sorted_faction[1].name)
end
function update(delta)
	if delta == 0 then
		--game paused
		return
	end
	if respawn_countdown ~= nil then
		respawn_countdown = respawn_countdown - delta
		if respawn_countdown < 0 then
			delayedRespawn()
		end
	end
	if mainGMButtons == mainGMButtonsDuringPause then
		mainGMButtons = mainGMButtonsAfterPause
		mainGMButtons()
	end
	if not terrain_generated then
		generateTerrain()
	end
	game_state = "running"
	local stat_list = gatherStats()
	if stat_list.human.weighted_score < original_score["Human Navy"]/2 then
		pickWinner("End cause: Human Navy fell below 50% of original strength")
	end
	if stat_list.kraylor.weighted_score < original_score["Kraylor"]/2 then
		pickWinner("End cause: Kraylor fell below 50% of original strength")
	end
	if exuari_angle ~= nil then
		if stat_list.exuari.weighted_score < original_score["Exuari"]/2 then
			pickWinner("End cause: Exuari fell below 50% of original strength")
		end
	end
	if ktlitan_angle ~= nil then
		if stat_list.ktlitan.weighted_score < original_score["Ktlitans"]/2 then
			pickWinner("End cause: Ktlitans fell below 50% of original strength")
		end
	end
	game_time_limit = game_time_limit - delta
	if game_time_limit < 0 then
		pickWinner("End cause: Time ran out")
	end
	local hrs = stat_list.human.weighted_score/original_score["Human Navy"]
	local krs = stat_list.kraylor.weighted_score/original_score["Kraylor"]
	local rel_dif = math.abs(hrs-krs)
	if rel_dif > thresh then
		if exuari_angle ~= nil then
			ers = stat_list.exuari.weighted_score/original_score["Exuari"]
			rel_dif = math.abs(hrs-ers)
			local ref_dif_2 = math.abs(ers-krs)
			if rel_dif > thresh or ref_dif_2 > thresh then
				if ktlitan_angle ~= nil then
					brs = stat_list.ktlitan.weighted_score/original_score["Ktlitans"]
					rel_dif = math.abs(brs-ers)
					ref_dif_2 = math.abs(brs-krs)
					local rel_dif_3 = math.abs(hrs-brs)
					if rel_dif > thresh or ref_dif_2 > thresh or rel_dif_3 > thresh then
						pickWinner(string.format("End cause: score difference exceeded %i%%",thresh*100))
					end
				else
					pickWinner(string.format("End cause: score difference exceeded %i%%",thresh*100))
				end
			end
		else
			pickWinner(string.format("End cause: score difference exceeded %i%%",thresh*100))
		end
	end
	local score_banner = string.format(_("-tabRelay&Operations", "H:%i K:%i"),math.floor(stat_list.human.weighted_score),math.floor(stat_list.kraylor.weighted_score))
	if exuari_angle ~= nil then
		score_banner = string.format(_("-tabRelay&Operations", "%s E:%i"),score_banner,math.floor(stat_list.exuari.weighted_score))
	end
	if ktlitan_angle ~= nil then
		score_banner = string.format(_("-tabRelay&Operations", "%s B:%i"),score_banner,math.floor(stat_list.ktlitan.weighted_score))
	end
	if game_time_limit > 60 then
		score_banner = string.format(_("-tabRelay&Operations", "%s %i:%.2i"),score_banner,stat_list.times.game.minutes_left,stat_list.times.game.seconds_left)
	else
		score_banner = string.format(_("-tabRelay&Operations", "%s %i"),score_banner,stat_list.times.game.seconds_left)
	end
	if scientist_asset_message == nil then
		scientist_asset_message = "sent"
		if scientist_list ~= nil then
			for pidx=1,32 do
				local p = getPlayerShip(pidx)
				if p ~= nil and p:isValid() then
					if scientist_list[p:getFaction()] ~= nil then
						if #scientist_list[p:getFaction()] > 1 then
							p:addToShipLog("In addition to the stations and fleet assets, Command has deemed certain scientists as critical to the war effort. Loss of these scientists will count against you like the loss of stations and fleet assets will. Scientist list:","Magenta")
						else
							p:addToShipLog("In addition to the stations and fleet assets, Command has deemed this scientist as critical to the war effort. Loss of this scientist will count against you like the loss of stations and fleet assets will. Scientist:","Magenta")
						end
						for idx, scientist in ipairs(scientist_list[p:getFaction()]) do
							p:addToShipLog(string.format("Value: %i, Name: %s, Specialization: %s, Location: %s",scientist.score_value,scientist.name,scientist.topic,scientist.location_name),"Magenta")
						end
						if #scientist_list[p:getFaction()] > 1 then
							p:addToShipLog("These scientists will be weighted with the other NPC assets","Magenta")
						else
							p:addToShipLog("This scientist will be weighted with the other NPC assets","Magenta")
						end
					end
				end
			end
		end
	end
	healthCheckTimer = healthCheckTimer - delta
	local warning_message = nil
	local warning_station = nil
	local warning_message = {}
	local warning_station = {}
	for stn_faction, stn_list in pairs(station_list) do
		for station_index=1,#stn_list do
			local current_station = stn_list[station_index]
			if current_station ~= nil and current_station:isValid() then
				if current_station.proximity_warning == nil then
					for idx, obj in ipairs(current_station:getObjectsInRange(station_sensor_range)) do
						if obj ~= nil and obj:isValid() then
							if obj:isEnemy(current_station) then
								if isObjectType(obj,"PlayerSpaceship") then
									warning_station[stn_faction] = current_station
									warning_message[stn_faction] = string.format(_("helpfullWarning-shipLog", "[%s in %s] We detect one or more enemies nearby. At least one is of type %s"),current_station:getCallSign(),current_station:getSectorName(),obj:getTypeName())
									current_station.proximity_warning = warning_message[stn_faction]
									current_station.proximity_warning_timer = delta + 300
									break
								end
							end
						end
					end
					if warning_station[stn_faction] ~= nil then	--was originally warning message
						break
					end
				else
					current_station.proximity_warning_timer = current_station.proximity_warning_timer - delta
					if current_station.proximity_warning_timer < 0 then
						current_station.proximity_warning = nil
					end
				end
				if warning_station[stn_faction] == nil then
					--shield damage warning
					if current_station.shield_damage_warning == nil then
						for i=1,current_station:getShieldCount() do
							if current_station:getShieldLevel(i-1) < current_station:getShieldMax(i-1) then
								warning_station[stn_faction] = current_station
								warning_message[stn_faction] = string.format("[%s in %s] Our shields have taken damage",current_station:getCallSign(),current_station:getSectorName())
								current_station.shield_damage_warning = warning_message[stn_faction]
								current_station.shield_damage_warning_timer = delta + 300
								break
							end
						end
						if warning_station[stn_faction] ~= nil then
							break
						end
					else
						current_station.shield_damage_warning_timer = current_station.shield_damage_warning_timer - delta
						if current_station.shield_damage_warning_timer < 0 then
							current_station.shield_damage_warning = nil
						end
					end
				end
				if warning_station[stn_faction] == nil then
					--severe shield damage warning
					if current_station.severe_shield_warning == nil then
						local current_station_shield_count = current_station:getShieldCount()
						for i=1,current_station_shield_count do
							if current_station:getShieldLevel(i-1) < current_station:getShieldMax(i-1)*.1 then
								warning_station[stn_faction] = current_station
								if current_station_shield_count == 1 then
									warning_message[stn_faction] = string.format("[%s in %s] Our shields are nearly gone",current_station:getCallSign(),current_station:getSectorName())
								else
									warning_message[stn_faction] = string.format("[%s in %s] One or more of our shields are nearly gone",current_station:getCallSign(),current_station:getSectorName())
								end
								current_station.severe_shield_warning = warning_message[stn_faction]
								current_station.severe_shield_warning_timer = delta + 300
								break
							end
						end
						if warning_station[stn_faction] ~= nil then
							break
						end
					else
						current_station.severe_shield_warning_timer = current_station.severe_shield_warning_timer - delta
						if current_station.severe_shield_warning_timer < 0 then
							current_station.severe_shield_warning = nil
						end
					end
				end
				if warning_station[stn_faction] == nil then
					--hull damage warning
					if current_station.hull_warning == nil then
						if current_station:getHull() < current_station:getHullMax() then
							warning_station[stn_faction] = current_station
							warning_message[stn_faction] = string.format("[%s in %s] Our hull has been damaged",current_station:getCallSign(),current_station:getSectorName())
							current_station.hull_warning = warning_message[stn_faction]
							break
						end
					end
				end
				if warning_station[stn_faction] == nil then
					--severe hull damage warning
					if current_station.severe_hull_warning == nil then
						if current_station:getHull() < current_station:getHullMax()*.1 then
							warning_station[stn_faction] = current_station
							warning_message[stn_faction] = string.format("[%s in %s] We are on the brink of destruction",current_station:getCallSign(),current_station:getSectorName())
							current_station.severe_hull_warning = warning_message[stn_faction]
						end
					end
				end
			end	--	current station not nil and is valid
		end
	end
	for pidx=1,32 do
		local p = getPlayerShip(pidx)
		if p ~= nil and p:isValid() then
			local player_name = p:getCallSign()
			if advanced_intel then
				if p.advance_intel_msg == nil then
					local p_faction = p:getFaction()
					local p_station = faction_primary_station[p_faction].station
					for faction, p_s_info in pairs(faction_primary_station) do
						if p_faction ~= faction then
							p:addToShipLog(string.format("%s primary station %s is located in %s",faction,p_s_info.station:getCallSign(),p_s_info.station:getSectorName()),"Magenta")
						end
					end
					p.advance_intel_msg = "sent"
				end
			end
			if warning_station["Human Navy"] ~= nil and p:getFaction() == "Human Navy" then
				p:addToShipLog(warning_message["Human Navy"],"Red")
			end
			if warning_station["Kraylor"] ~= nil and p:getFaction() == "Kraylor" then
				p:addToShipLog(warning_message["Kraylor"],"Red")
			end
			if exuari_angle ~= nil then
				if warning_station["Exuari"] ~= nil and p:getFaction() == "Exuari" then
					p:addToShipLog(warning_message["Exuari"],"Red")
				end
			end
			if ktlitan_angle ~= nil then
				if warning_station["Ktlitans"] ~= nil and p:getFaction() == "Ktlitans" then
					p:addToShipLog(warning_message["Ktlitans"],"Red")
				end
			end
			local name_tag_text = string.format(_("-tabRelay&Ops&Helms&Tactical", "%s in %s"),player_name,p:getSectorName())
			if p:hasPlayerAtPosition("Relay") then
				p.name_tag = "name_tag"
				p:addCustomInfo("Relay",p.name_tag,name_tag_text)
				p.score_banner = "score_banner"
				p:addCustomInfo("Relay",p.score_banner,score_banner)
			end
			if p:hasPlayerAtPosition("Operations") then
				p.name_tag_ops = "name_tag_ops"
				p:addCustomInfo("Operations",p.name_tag_ops,name_tag_text)
				p.score_banner_ops = "score_banner_ops"
				p:addCustomInfo("Operations",p.score_banner_ops,score_banner)
			end
			if p:hasPlayerAtPosition("ShipLog") then
				p.name_tag_log = "name_tag_log"
				p:addCustomInfo("ShipLog",p.name_tag_log,name_tag_text)
				p.score_banner_log = "score_banner_log"
				p:addCustomInfo("ShipLog",p.score_banner_log,score_banner)
			end
			if p:hasPlayerAtPosition("Helms") then
				p.name_tag_helm = "name_tag_helm"
				p:addCustomInfo("Helms",p.name_tag_helm,name_tag_text)
			end
			if p:hasPlayerAtPosition("Tactical") then
				p.name_tag_tac = "name_tag_tac"
				p:addCustomInfo("Tactical",p.name_tag_tac,name_tag_text)
			end
			if p.inventoryButton == nil then
				local goodCount = 0
				if p.goods ~= nil then
					for good, goodQuantity in pairs(p.goods) do
						goodCount = goodCount + 1
					end
				end
				if goodCount > 0 then		--add inventory button when cargo acquired
					if p:hasPlayerAtPosition("Relay") then
						if p.inventoryButton == nil then
							local tbi = "inventory" .. player_name
							p:addCustomButton("Relay",tbi,_("inventory-buttonRelay", "Inventory"),function () playerShipCargoInventory(p) end)
							p.inventoryButton = true
						end
					end
					if p:hasPlayerAtPosition("Operations") then
						if p.inventoryButton == nil then
							local tbi = "inventoryOp" .. player_name
							p:addCustomButton("Operations",tbi,_("inventory-buttonOperations", "Inventory"), function () playerShipCargoInventory(p) end)
							p.inventoryButton = true
						end
					end
				end
			end
			if healthCheckTimer < 0 then	--check to see if any crew perish (or other consequences) due to excessive damage
				if p:getRepairCrewCount() > 0 then
					local fatalityChance = 0
					local currentShield = 0
					if p:getShieldCount() > 1 then
						currentShield = (p:getSystemHealth("frontshield") + p:getSystemHealth("rearshield"))/2
					else
						currentShield = p:getSystemHealth("frontshield")
					end
					fatalityChance = fatalityChance + (p.prevShield - currentShield)
					p.prevShield = currentShield
					local currentReactor = p:getSystemHealth("reactor")
					fatalityChance = fatalityChance + (p.prevReactor - currentReactor)
					p.prevReactor = currentReactor
					local currentManeuver = p:getSystemHealth("maneuver")
					fatalityChance = fatalityChance + (p.prevManeuver - currentManeuver)
					p.prevManeuver = currentManeuver
					local currentImpulse = p:getSystemHealth("impulse")
					fatalityChance = fatalityChance + (p.prevImpulse - currentImpulse)
					p.prevImpulse = currentImpulse
					if p:getBeamWeaponRange(0) > 0 then
						if p.healthyBeam == nil then
							p.healthyBeam = 1.0
							p.prevBeam = 1.0
						end
						local currentBeam = p:getSystemHealth("beamweapons")
						fatalityChance = fatalityChance + (p.prevBeam - currentBeam)
						p.prevBeam = currentBeam
					end
					if p:getWeaponTubeCount() > 0 then
						if p.healthyMissile == nil then
							p.healthyMissile = 1.0
							p.prevMissile = 1.0
						end
						local currentMissile = p:getSystemHealth("missilesystem")
						fatalityChance = fatalityChance + (p.prevMissile - currentMissile)
						p.prevMissile = currentMissile
					end
					if p:hasWarpDrive() then
						if p.healthyWarp == nil then
							p.healthyWarp = 1.0
							p.prevWarp = 1.0
						end
						local currentWarp = p:getSystemHealth("warp")
						fatalityChance = fatalityChance + (p.prevWarp - currentWarp)
						p.prevWarp = currentWarp
					end
					if p:hasJumpDrive() then
						if p.healthyJump == nil then
							p.healthyJump = 1.0
							p.prevJump = 1.0
						end
						local currentJump = p:getSystemHealth("jumpdrive")
						fatalityChance = fatalityChance + (p.prevJump - currentJump)
						p.prevJump = currentJump
					end
					if p:getRepairCrewCount() == 1 then
						fatalityChance = fatalityChance/2	-- increase survival chances of last repair crew standing
					end
					if fatalityChance > 0 then
						if math.random() < (fatalityChance) then
							if p.initialCoolant == nil then
								p:setRepairCrewCount(p:getRepairCrewCount() - 1)
								if p:hasPlayerAtPosition("Engineering") then
									local repairCrewFatality = "repairCrewFatality"
									p:addCustomMessage("Engineering",repairCrewFatality,_("repairCrew-msgEngineer", "One of your repair crew has perished"))
								end
								if p:hasPlayerAtPosition("Engineering+") then
									local repairCrewFatalityPlus = "repairCrewFatalityPlus"
									p:addCustomMessage("Engineering+",repairCrewFatalityPlus,_("repairCrew-msgEngineer+", "One of your repair crew has perished"))
								end
							else
								local consequence = 0
								local upper_consequence = 2
								local consequence_list = {}
								if p:getCanLaunchProbe() then
									upper_consequence = upper_consequence + 1
									table.insert(consequence_list,"probe")
								end
								if p:getCanHack() then
									upper_consequence = upper_consequence + 1
									table.insert(consequence_list,"hack")
								end
								if p:getCanScan() then
									upper_consequence = upper_consequence + 1
									table.insert(consequence_list,"scan")
								end
								if p:getCanCombatManeuver() then
									upper_consequence = upper_consequence + 1
									table.insert(consequence_list,"combat_maneuver")
								end
								if p:getCanSelfDestruct() then
									upper_consequence = upper_consequence + 1
									table.insert(consequence_list,"self_destruct")
								end
								if p:getWeaponTubeCount() > 0 then
									upper_consequence = upper_consequence + 1
									table.insert(consequence_list,"tube_time")
								end
								consequence = math.random(1,upper_consequence)
								if consequence == 1 then
									p:setRepairCrewCount(p:getRepairCrewCount() - 1)
									if p:hasPlayerAtPosition("Engineering") then
										local repairCrewFatality = "repairCrewFatality"
										p:addCustomMessage("Engineering",repairCrewFatality,_("repairCrew-msgEngineer", "One of your repair crew has perished"))
									end
									if p:hasPlayerAtPosition("Engineering+") then
										local repairCrewFatalityPlus = "repairCrewFatalityPlus"
										p:addCustomMessage("Engineering+",repairCrewFatalityPlus,_("repairCrew-msgEngineer+", "One of your repair crew has perished"))
									end
								elseif consequence == 2 then
									local current_coolant = p:getMaxCoolant()
									local lost_coolant = 0
									if current_coolant >= 10 then
										lost_coolant = current_coolant*random(.25,.5)	--lose between 25 and 50 percent
									else
										lost_coolant = current_coolant*random(.15,.35)	--lose between 15 and 35 percent
									end
									p:setMaxCoolant(current_coolant - lost_coolant)
									if p.reclaimable_coolant == nil then
										p.reclaimable_coolant = 0
									end
									p.reclaimable_coolant = math.min(20,p.reclaimable_coolant + lost_coolant*random(.8,1))
									if p:hasPlayerAtPosition("Engineering") then
										local coolantLoss = "coolantLoss"
										p:addCustomMessage("Engineering",coolantLoss,_("coolant-msgEngineer", "Damage has caused a loss of coolant"))
									end
									if p:hasPlayerAtPosition("Engineering+") then
										local coolantLossPlus = "coolantLossPlus"
										p:addCustomMessage("Engineering+",coolantLossPlus,_("coolant-msgEngineer+", "Damage has caused a loss of coolant"))
									end
								else
									local named_consequence = consequence_list[consequence-2]
									if named_consequence == "probe" then
										p:setCanLaunchProbe(false)
										if p:hasPlayerAtPosition("Engineering") then
											p:addCustomMessage("Engineering","probe_launch_damage_message",_("damage-msgEngineer", "The probe launch system has been damaged"))
										end
										if p:hasPlayerAtPosition("Engineering+") then
											p:addCustomMessage("Engineering+","probe_launch_damage_message_plus",_("damage-msgEngineer+", "The probe launch system has been damaged"))
										end
									elseif named_consequence == "hack" then
										p:setCanHack(false)
										if p:hasPlayerAtPosition("Engineering") then
											p:addCustomMessage("Engineering","hack_damage_message",_("damage-msgEngineer", "The hacking system has been damaged"))
										end
										if p:hasPlayerAtPosition("Engineering+") then
											p:addCustomMessage("Engineering+","hack_damage_message_plus",_("damage-msgEngineer+", "The hacking system has been damaged"))
										end
									elseif named_consequence == "scan" then
										p:setCanScan(false)
										if p:hasPlayerAtPosition("Engineering") then
											p:addCustomMessage("Engineering","scan_damage_message",_("damage-msgEngineer", "The scanners have been damaged"))
										end
										if p:hasPlayerAtPosition("Engineering+") then
											p:addCustomMessage("Engineering+","scan_damage_message_plus",_("damage-msgEngineer+", "The scanners have been damaged"))
										end
									elseif named_consequence == "combat_maneuver" then
										p:setCanCombatManeuver(false)
										if p:hasPlayerAtPosition("Engineering") then
											p:addCustomMessage("Engineering","combat_maneuver_damage_message",_("damage-msgEngineer", "Combat maneuver has been damaged"))
										end
										if p:hasPlayerAtPosition("Engineering+") then
											p:addCustomMessage("Engineering+","combat_maneuver_damage_message_plus",_("damage-msgEngineer+", "Combat maneuver has been damaged"))
										end
									elseif named_consequence == "self_destruct" then
										p:setCanSelfDestruct(false)
										if p:hasPlayerAtPosition("Engineering") then
											p:addCustomMessage("Engineering","self_destruct_damage_message",_("damage-msgEngineer", "Self destruct system has been damaged"))
										end
										if p:hasPlayerAtPosition("Engineering+") then
											p:addCustomMessage("Engineering+","self_destruct_damage_message_plus",_("damage-msgEngineer+", "Self destruct system has been damaged"))
										end
									elseif named_consequence == "tube_time" then
										local tube_count = p:getWeaponTubeCount()
										local tube_index = 0
										if p.normal_tube_load_time == nil then
											p.normal_tube_load_time = {}
											repeat
												p.normal_tube_load_time[tube_index] = p:getTubeLoadTime(tube_index)
												tube_index = tube_index + 1
											until(tube_index >= tube_count)
											tube_index = 0
										end
										repeat
											p:setTubeLoadTime(tube_index,p:getTubeLoadTime(tube_index) + 2)
											tube_index = tube_index + 1
										until(tube_index >= tube_count)
										if p:hasPlayerAtPosition("Engineering") then
											p:addCustomMessage("Engineering","tube_slow_down_message",_("damage-msgEngineer", "Tube damage has caused tube load time to increase"))
										end
										if p:hasPlayerAtPosition("Engineering+") then
											p:addCustomMessage("Engineering+","tube_slow_down_message_plus",_("damage-msgEngineer+", "Tube damage has caused tube load time to increase"))
										end
									end
								end	--coolant loss branch
							end	--could lose coolant branch
						end	--bad consequences of damage branch
					end	--possible chance of bad consequences branch
				else	--no repair crew left
					if random(1,100) <= 4 then
						p:setRepairCrewCount(1)
						if p:hasPlayerAtPosition("Engineering") then
							local repairCrewRecovery = "repairCrewRecovery"
							p:addCustomMessage("Engineering",repairCrewRecovery,_("repairCrew-msgEngineer", "Medical team has revived one of your repair crew"))
						end
						if p:hasPlayerAtPosition("Engineering+") then
							local repairCrewRecoveryPlus = "repairCrewRecoveryPlus"
							p:addCustomMessage("Engineering+",repairCrewRecoveryPlus,_("repairCrew-msgEngineer+", "Medical team has revived one of your repair crew"))
						end
						resetPreviousSystemHealth(p)
					end	--medical science triumph branch
				end	--no repair crew left
				if p.initialCoolant ~= nil then
					current_coolant = p:getMaxCoolant()
					if current_coolant < 20 then
						if random(1,100) <= 4 then
							local reclaimed_coolant = 0
							if p.reclaimable_coolant ~= nil and p.reclaimable_coolant > 0 then
								reclaimed_coolant = p.reclaimable_coolant*random(.1,.5)	--get back 10 to 50 percent of reclaimable coolant
								p:setMaxCoolant(math.min(20,current_coolant + reclaimed_coolant))
								p.reclaimable_coolant = p.reclaimable_coolant - reclaimed_coolant
							end
							local noticable_reclaimed_coolant = math.floor(reclaimed_coolant)
							if noticable_reclaimed_coolant > 0 then
								if p:hasPlayerAtPosition("Engineering") then
									local coolant_recovery = "coolant_recovery"
									p:addCustomMessage("Engineering",coolant_recovery,_("coolant-msgEngineer", "Automated systems have recovered some coolant"))
								end
								if p:hasPlayerAtPosition("Engineering+") then
									local coolant_recovery_plus = "coolant_recovery_plus"
									p:addCustomMessage("Engineering+",coolant_recovery_plus,_("coolant-msgEngineer+", "Automated systems have recovered some coolant"))
								end
							end
							resetPreviousSystemHealth(p)
						end
					end
				end
			end	--health check branch
			local secondary_systems_optimal = true
			if not p:getCanLaunchProbe() then
				secondary_systems_optimal = false
			end
			if secondary_systems_optimal and not p:getCanHack() then
				secondary_systems_optimal = false
			end
			if secondary_systems_optimal and not p:getCanScan() then
				secondary_systems_optimal = false
			end
			if secondary_systems_optimal and not p:getCanCombatManeuver() then
				secondary_systems_optimal = false
			end
			if secondary_systems_optimal and not p:getCanSelfDestruct() then
				secondary_systems_optimal = false
			end
			if secondary_systems_optimal then
				local tube_count = p:getWeaponTubeCount()
				if tube_count > 0 and p.normal_tube_load_time ~= nil then
					local tube_index = 0
					repeat
						if p.normal_tube_load_time[tube_index] < p:getTubeLoadTime(tube_index) then
							secondary_systems_optimal = false
							break
						end
						tube_index = tube_index + 1
					until(tube_index >= tube_count)
				end
			end
			if secondary_systems_optimal then	--remove damage report button
				if p.damage_report ~= nil then
					p:removeCustom(p.damage_report)
					p.damage_report = nil
				end
				if p.damage_report_plus ~= nil then
					p:removeCustom(p.damage_report_plus)
					p.damage_report_plus = nil
				end
			else	--add damage report button
				if p:hasPlayerAtPosition("Engineering") then
					p.damage_report = "damage_report"
					p:addCustomButton("Engineering",p.damage_report,_("-buttonEngineer", "Damage Report"),function()
						local dmg_msg = "In addition to the primary systems constantly monitored in engineering, the following secondary systems have also been damaged requiring docking repair facilities:"
						if not p:getCanLaunchProbe() then
							dmg_msg = dmg_msg .. "\nProbe launch system"
						end
						if not p:getCanHack() then
							dmg_msg = dmg_msg .. "\nHacking system"
						end
						if not p:getCanScan() then
							dmg_msg = dmg_msg .. "\nScanning system"
						end
						if not p:getCanCombatManeuver() then
							dmg_msg = dmg_msg .. "\nCombat maneuvering system"
						end
						if not p:getCanSelfDestruct() then
							dmg_msg = dmg_msg .. "\nSelf destruct system"
						end
						local tube_count = p:getWeaponTubeCount()
						if tube_count > 0 then
							if tube_count > 0 and p.normal_tube_load_time ~= nil then
								local tube_index = 0
								repeat
									if p.normal_tube_load_time[tube_index] < p:getTubeLoadTime(tube_index) then
										dmg_msg = dmg_msg .. _("damage-msgEngineer", "\nWeapon tube load time degraded")
										break
									end
									tube_index = tube_index + 1
								until(tube_index >= tube_count)
							end
						end
						p.dmg_msg = "dmg_msg"
						p:addCustomMessage("Engineering",p.dmg_msg,dmg_msg)
					end)
				end	--engineering damage report button
				if p:hasPlayerAtPosition("Engineering+") then
					p.damage_report_plus = "damage_report_plus"
					p:addCustomButton("Engineering",p.damage_report_plus,_("damage-buttonEngineer", "Damage Report"),function()
						local dmg_msg = "In addition to the primary systems constantly monitored in engineering, the following secondary systems have also been damaged requiring docking repair facilities:"
						if not p:getCanLaunchProbe() then
							dmg_msg = dmg_msg .. "\nProbe launch system"
						end
						if not p:getCanHack() then
							dmg_msg = dmg_msg .. "\nHacking system"
						end
						if not p:getCanScan() then
							dmg_msg = dmg_msg .. "\nScanning system"
						end
						if not p:getCanCombatManeuver() then
							dmg_msg = dmg_msg .. "\nCombat maneuvering system"
						end
						if not p:getCanSelfDestruct() then
							dmg_msg = dmg_msg .. "\nSelf destruct system"
						end
						local tube_count = p:getWeaponTubeCount()
						if tube_count > 0 then
							if tube_count > 0 and p.normal_tube_load_time ~= nil then
								local tube_index = 0
								repeat
									if p.normal_tube_load_time[tube_index] < p:getTubeLoadTime(tube_index) then
										dmg_msg = dmg_msg .. _("damage-msgEngineer+", "\nWeapon tube load time degraded")
										break
									end
									tube_index = tube_index + 1
								until(tube_index >= tube_count)
							end
						end
						p.dmg_msg = "dmg_msg"
						p:addCustomMessage("Engineering+",p.dmg_msg,dmg_msg)
					end)
				end	--engineering plus damage report button
			end	--damage report button necessary
			if p.normal_long_range_radar == nil then
				p.normal_long_range_radar = p:getLongRangeRadarRange()
			end
			local sensor_boost_amount = 0
			local sensor_boost_present = false
			if station_primary_human:isValid() then
				if p:isDocked(station_primary_human) then
					sensor_boost_present = true
					sensor_boost_amount = station_primary_human.comms_data.sensor_boost.value
				end
			end
			if station_primary_kraylor:isValid() then
				if p:isDocked(station_primary_kraylor) then
					sensor_boost_present = true
					sensor_boost_amount = station_primary_kraylor.comms_data.sensor_boost.value
				end
			end
			if exuari_angle ~= nil then
				if station_primary_exuari:isValid() then
					if p:isDocked(station_primary_exuari) then
						sensor_boost_present = true
						sensor_boost_amount = station_primary_exuari.comms_data.sensor_boost.value
					end
				end
			end
			if ktlitan_angle ~= nil then
				if station_primary_ktlitan:isValid() then
					if p:isDocked(station_primary_ktlitan) then
						sensor_boost_present = true
						sensor_boost_amount = station_primary_ktlitan.comms_data.sensor_boost.value
					end
				end
			end
			local boosted_range = p.normal_long_range_radar + sensor_boost_amount
			if sensor_boost_present then
				if p:getLongRangeRadarRange() < boosted_range then
					p:setLongRangeRadarRange(boosted_range)
				end
			else
				if p:getLongRangeRadarRange() > p.normal_long_range_radar then
					p:setLongRangeRadarRange(p.normal_long_range_radar)
				end
			end
		end	--p is not nil and is valid
	end	--loop through players
end
