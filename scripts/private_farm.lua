local sampev = require("samp.events")
local vector3d = require("vector3d")
local router = require("router")
local ffi = require("ffi")
local effil = require("effil")
require("sampfuncs")
require("addon")
require("Tasking")
local json = require 'json'

answers = {
    "ÿ òóò"
}

-- #meowprd
local aq = {} -- loading answers from file
local freeze = false -- freeze state
local slap = { t = false, clock = os.clock() } -- slap states

local done_txt = getPath("accounts\\done.txt")
local done_txt2 = getPath("accounts\\done2.txt")
local banned_txt = getPath("accounts\\banned.txt")
local pass = "123123"
local limit = 150000
local timeout = 600000
local _farm = 3
local salary = 0
local special_action = 0
local current_farm = 0
local spawned = false
local banned_count = 0
local tkan = 0
local flood_alt = true
local timeSinceQuestTake = -1

local last_quest = os.time()

local _farms = {}
local tasks = {}
local names = {}
local surnames = {}

format = string.format
random = math.random

function enum( name )
    return function( array )
        for i, v in ipairs( array ) do
            _G[ v ] = i
        end
    end
end

enum "statuses" {
    "STATUS_NONE",
	"STATUS_START",
    "STATUS_GET_QUEST",
	"STATUS_GET_WORK",
	"STATUS_WORK",
	"STATUS_EAT",
}

function setStatus(_status)
	if _status == STATUS_GET_WORK then floodAltOn(true) end
	status = _status
	status_time = os.time()
end

function getStatus()
	return status
end

function getStatusTimePassed()
	return os.time() - status_time
end

new_player = function(id, nick)
	local mt = {}
	local player = {
        id = id,
		nick = nick or "_unknown",
		stream_in = false,
		skin = 0,
		pos = vector3d(0.0, 0.0, 0.0),
    }

	function player:remove()
		players[self.id] = nil
	end

	setmetatable(player, mt)
	players[id] = player
end

function check_player(id)
	if not players[id] then new_player(id) end
end

local DEBUG = true

wait = Tasking.wait

function newTask(task)
	table.insert(tasks, Tasking.new(task))
end

local flood_pickup = false
local timeSinceLastPickup = os.time()

function floodAltOn(floodPickup)
	flood_alt = true
	if floodPickup then
		flood_pickup = floodPickup
	else
		flood_pickup = false
	end
	print("Íà÷èíàåì òàïàòü ïî ýêðàí÷èêó")
	newTask(function()
		local x, y, z = getBotPosition()
		--go_to({ x = x, y = y, z = z }, 6.0)
		coordStart(x, y, z, 10, 1, true)
		while isCoordActive() do wait(0) end
		updateSync()
		wait(800)
		while flood_alt do 
			if os.time() - timeSinceLastPickup >= 1 then
				timeSinceLastPickup = os.time()
				pickupNearestPickup()
			end
			pressKey(1024)
			updateSync()
			wait(250)
		end
		--flood_alt = true
	end)
end

function floodAltOnNopickup()
	newTask(function()
		local x, y, z = getBotPosition()
		--go_to({ x = x, y = y, z = z }, 6.0)
		coordStart(x, y, z, 10, 1, true)
		while isCoordActive() do wait(0) end
		updateSync()
		wait(300)
		wait(300)
		flood_alt = true
		while flood_alt do 
			pressKey(1024)
			updateSync()
			wait(250)
		end
		--flood_alt = true
	end)
end

function pickupNearestPickup()
    local function getDistance(a, b)
        return math.sqrt(
            math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2) + math.pow(b.z - a.z, 2)
        )
    end

    local pickups = {}
    local x, y, z = getBotPosition()
    for k, v in pairs(getAllPickups()) do
		local distance = getDistance({ x = x, y = y, z = z }, v.position)
		table.insert(pickups, { id = k, dist = distance, pos = v.position })
    end
    table.sort(pickups, function(a, b) return a.dist < b.dist end)
	local near = pickups[1]
    if near ~= nil then 
		if near.dist <= 5 then print("send pick pickup", near.id) sendPickedUpPickup(near.id) end 
	end
end

local servers = {
	["185.169.134.3:7777"  ] = { name = "Phoenix", num = 1 },
	["185.169.134.4:7777"  ] = { name = "Tucson", num = 2 },
	["185.169.134.43:7777" ] = { name = "Scottdale", num = 3 },
	["185.169.134.44:7777" ] = { name = "Chandler", num = 4 },
	["185.169.134.45:7777" ] = { name = "Brainburg", num = 5 },
	["185.169.134.5:7777"  ] = { name = "SaintRose", num = 6 },
	["185.169.134.59:7777" ] = { name = "Mesa", num = 7 },
	["185.169.134.61:7777" ] = { name = "Red-Rock", num = 8 },
	["185.169.134.107:7777"] = { name = "Yuma", num = 9 },
	["185.169.134.109:7777"] = { name = "Surprise", num = 10 },
	["185.169.134.166:7777"] = { name = "Prescott", num = 11 },
	["185.169.134.171:7777"] = { name = "Glendale", num = 12 },
	["185.169.134.172:7777"] = { name = "Kingman", num = 13 },
	["185.169.134.173:7777"] = { name = "Winslow", num = 14 },
	["185.169.134.174:7777"] = { name = "Payson", num = 15 },
	["80.66.82.191:7777"   ] = { name = "Gilbert", num = 16 },
	["80.66.82.190:7777"   ] = { name = "Show-Low", num = 17 },
	["80.66.82.188:7777"   ] = { name = "Casa-Grande", num = 18 },
	["80.66.82.168:7777"   ] = { name = "Page", num = 19 },
	["80.66.82.159:7777"   ] = { name = "Sun-City", num = 20 },
	["80.66.82.200:7777"   ] = { name = "Queen-Creek", num = 21 },
	["80.66.82.144:7777"   ] = { name = "Sedona", num = 22 },
        ["80.66.82.132:7777"   ] = { name = "Holiday", num = 23 },
        ["80.66.82.128:7777"   ] = { name = "Wednesday", num = 24 },
        ["80.66.82.113:7777"   ] = { name = "Yava", num = 25 },
		["80.66.82.82:7777"   ] = { name = "Faraway", num = 26 },
		["80.66.82.87:7777"   ] = { name = "Bumble-bee", num = 27 },
			["80.66.82.54:7777"   ] = { name = "Christmas", num = 28 },
			["80.66.82.39:7777"   ] = { name = "Mirage", num = 29 },
			["80.66.82.33:7777"   ] = { name = "Love", num = 30 },
			["80.66.82.22:7777"   ] = { name = "Drake", num = 31 }
}

math.randomseed(os.time())


local dialogs_raw = {
	{ "{BFBBBA}{E88813}[2/4] Âûáåðèòå âàø ïîë", "Ìóæñêîé", 1, 0, "" },
	{ "{BFBBBA}{E88813}[3/4] Âûáåðèòå öâåò êîæè", "{FFCC99}Ñâåòëûé", 1, random(0, 1), "" },
	{ "{BFBBBA}[4/4] Îòêóäà âû î íàñ óçíàëè?", "Îò äðóçåé", 1, 0, "" },
	{ "{BFBBBA}[4/4] Ââåäèòå íèê ïðèãëàñèâøåãî?", "Îò äðóçåé", 1, 1, "" },
}

function initDialogs()
	dialogs = {}
	for _, data in ipairs(dialogs_raw) do
		table.insert(dialogs, {
			title = data[1],
			text = data[2],
			button = data[3],
			list = data[4],
			input = data[5],
			func = data[6],
		})
	end
end


local coord = {
	delay = 130,
	step = 7,
	state = false,
	speed = 1,
	x = 0.0,
	y = 0.0,
	z = 0.0,
}

-- function sampev.onCreatePickup(id, model, type, pos)
-- 	print("create:", id, model, type, pos.x, pos.y, pos.z)
-- end

-- function sampev.onDestroyPickup(id)
-- 	print("destroy:", id)
-- end

function coord.func()
	while true do
		wait(coord.delay)
		if coord.state then
			local pos = vector3d(getBotPosition())
			local dist = distance_3d(coord.target, pos)
			if dist < coord.step * 1.1 then
				setBotPosition(coord.target:get())
				sendOnfootSync({
					ud = 0,
					key = 0,
					anim = 1189,
					flags = 32772,
				})
				coord.state = false
				if coord.func then coord.func(table.unpack(coord.args)) end
				print("[COORD] Done!")
			else
				local speed = coord.step / (15 / coord.speed)
				if coord.speed < 15 then coord.speed = coord.speed + 1 end

				local vec = vector3d(coord.target.x - pos.x, coord.target.y - pos.y, coord.target.z - pos.z)
				local len = vec:length()

				local new_pos = vector3d(pos.x + vec.x / len * speed, pos.y + vec.y / len * speed, pos.z + vec.z / len * speed)

				local ms = getVelocity(pos, new_pos, (speed > 0.98 and 0.98 or speed)/3.2)
				-- print(ms.x, ms.y, ms.z)

				rotateCharToCoord(new_pos)
				setBotPosition(new_pos:get())

				sendOnfootSync({
					ud = 65408,
					key = 8,
					ms = ms,
					anim = 1231, -- 1231 cj
					flags = 32770,
				})
			end
		end
	end
end

function checker()
	while true do
		wait(500)
		if not isBotConnected() then
			setStatus(STATUS_NONE)
			goto skip
		end
		if paused then
			if os.clock() - paused > 60.0 then
				resume()
			end
			goto skip
		end
		if timeSinceQuestTake ~= -1 and os.time() - timeSinceQuestTake >= 3 then
			print('Íå ñìîãëè îòêðûòü ìåíþ âûáîðà èíñòðóìåíòà/óðîæàÿ, òðàéíåì åùå ðàç...')
			timeSinceQuestTake = -1
			sendClickTextdraw(65535, 1000)
			floodAltOn(true)
		end

		--[[if getStatusTimePassed() > 300 then
			if getBotScore() >= 2 then
				reconnect()
			end
		end]]
		-- if status == STATUS_GET_QUEST and not router.isReplaying() then
		-- end
		if not_quest and os.time() - not_quest > 60 and status == STATUS_GET_QUEST then
			nextFarm()
			not_quest = nil
		--elseif status == STATUS_START and getStatusTimePassed() > 120 then
		--	print("Íå ìîæåì çàéòè â ôåðìó")
		--	reconnect()
		--elseif status == STATUS_GET_QUEST and os.time() - last_quest > 300 then
		--	reconnect()
		elseif status == STATUS_GET_QUEST and getStatusTimePassed() > 60 and distance_3d(farm.ambar, vector3d(getBotPosition())) < 3.0 then
			setStatus(STATUS_GET_QUEST)
			router.play(farm_route.."ambar-around", false, floodAltOn)
		elseif status == STATUS_GET_WORK and not coord.state and not router.isReplaying() then
			if not checkQuest() or getStatusTimePassed() > 20 then
				flood_alt = false
				setStatus(STATUS_GET_QUEST)
				-- go_to(farm.ambar, 0.98, floodAltOn)
				Tasking.defer(router.play, random(500, 2000), farm_route.."beds\\"..quest.bed.."-bed-ambar", false, floodAltOn)
			end
		elseif status == STATUS_WORK and not coord.state and not router.isReplaying() then
			if getStatusTimePassed() > 20 then
				flood_alt = false
				special_action = 0
				setStatus(STATUS_GET_QUEST)
				-- go_to(farm.ambar, 0.98, floodAltOn)
				Tasking.defer(router.play, random(500, 2000), farm_route.."beds\\"..quest.bed.."-bed-ambar", false, floodAltOn)
			end
		end
		::skip::
	end
end


function isCoordAtFarm(x, y)
	return x > farm.corners[1].x and 
		x < farm.corners[2].x and 
		y > farm.corners[1].y and 
		y < farm.corners[2].y
end

function checkQuest()
	return (quest and labels[quest.id] and labels[quest.id].text == quest.text and distance_3d(labels[quest.id].pos, quest.pos))
end

function newQuest(id, text, pos, dialog1, dialog2, bed, action, plant)
	return {
		id = id,
		text = text,
		pos = pos,
		dialog1 = dialog1,
		dialog2 = dialog2,
		bed = bed,
		action = action,
		plant = plant
	}
end

plants = {
	["Ðîæü"] = {2074},
	["Ìîðêîâü"] = {2075},
	["Êàðòîôåëü"] = {2076},
	["Ë¸í"] = {2077},
	["Õëîïîê"] = {2078},
	["Ïøåíèöà"] = {2079},
	["Îãóðöû"] = {2080},
	["Ïîìèäîðû"] = {2081}
	-- Åñëè ïðèãîäèòñÿ - çàïàðèìñÿ ñ ýòèì
	-- ["Áåëûé âèíîãðàä"] = {2071, 2074},
	-- ["×àé"] = {2071, 2075},
	-- ["Ïðÿíûå òðàâû"] = {2071, 2076},
	-- ["Êàíàáèñ"] = {2071, 2077},
	-- ["Êóêóðóçà"] = {2071, 2078},
	-- ["Ôèîëåòîâûé âèíîãðàä"] = {2071, 2079},
	-- ["Ëå÷åáíàÿ òðàâà"] = {2071, 2080},
	-- ["Ïîäñîëíóõ"] = {2071, 2081}
}

function router.getSpecialAction()
	return special_action
end

function router.onPlay(route, loop)
 	if paused then return false end 
end

PATTERN_RAKING = { pattern = "äëÿ íà÷àëà ðîñòà íåîáõîäèìî ïðîïîëîòü", dialog1 = 1, dialog2 = 18890, action = "raking" }
PATTERN_WATERING = { pattern = "äëÿ íà÷àëà ðîñòà íåîáõîäèìî ïîëèòü", dialog1 = 1, dialog2 = 19468, action = "watering" }
PATTERN_HARVESTING = { pattern = "ìîæíî ñîáðàòü óðîæàé", dialog1 = 1, dialog2 = 19626, action = "harvesting" }
PATTERN_DIGGING = { pattern = "ñâîáîäíîå ìåñòî", dialog1 = 1, dialog2 = 19626, action = "digging" }
PATTERN_PLANTING = { pattern = "âûêîïàíà ÿìêà", dialog1 = 0, dialog2 = 19626, action = "planting" }
function findQuest(...)
	local quests = {}
	for id, label in pairs(labels) do
		if isCoordAtFarm(label.pos.x, label.pos.y) and not hasPlayerInRaduis(label.pos, 4.0) then
			local plant = label.text:match("'(.-)'")
			if not plant and not plants[plant] and not label.text:find(PATTERN_DIGGING.pattern) then goto skip end
			local bed
			for k, v in ipairs(farm.beds) do
				if distance_3d(v, label.pos) < 3.0 then
					bed = k
				end
			end
			if bed then
				for k, pattern in ipairs({...}) do
					if label.text:find(pattern.pattern) then
						if not actions[pattern.action][plant] then goto skip end
						if pattern == PATTERN_PLANTING then
							table.insert(quests, {
								dist = distance_3d(farm.ambar, label.pos),
								quest = newQuest(id, label.text, label.pos, pattern.dialog1, plants[plant], bed, pattern.action, plant)
							})
							goto skip
							-- return newQuest(id, label.text, label.pos, pattern.dialog1, plants[plant], bed, pattern.action, plant)
						end
						table.insert(quests, {
							dist = distance_3d(farm.ambar, label.pos),
							quest = newQuest(id, label.text, label.pos, pattern.dialog1, pattern.dialog2, bed, pattern.action, plant or "xxx")
						})
						goto skip
						-- return newQuest(id, label.text, label.pos, pattern.dialog1, pattern.dialog2, bed, pattern.action, plant or "xxx")
					end
				end
			end
			::skip::
		end
	end
	if #quests == 0 then return false end
	table.sort(quests, function(x, y) return x.dist < y.dist end)
	return quests[1].quest
end


function hasPlayerInRaduis(pos, radius, skin)
	for id, player in pairs(players) do
		if distance_3d(pos, player.pos) < radius and (not skin or skin == player.skin) then
			return id
		end
	end
	return false
end

function isInAnyCar()
	return getVehicle() ~= 0
end

function pause()
	print("Ïàóçà...")
	paused = os.clock()
	if router.isReplaying() then router.stop() end
end

function resume()
	print("Ïðîäîëæàåì ðàáîòó")
	if distance_3d(vector3d(getBotPosition()), farm.ambar) > 100 then
		reconnect()
		print("Äàëåêî îò àìáàðà, ðåêîííåêòèìñÿ...")
		return
	end
	setStatus(STATUS_GET_QUEST)
	paused = false
	go_to(farm.ambar, 0.98, floodAltOn)
end

function reset()
	freeze = false
	slap = { t = false, clock = os.clock() }

	players = {}
	objects = {}
	labels = {}
	forced_key = nil
	setStatus(STATUS_NONE)
	hungry = false
	no_food = false
	paused = false
	flood_alt = false
	special_action = 0
	actions = {
		raking = {},
		watering = {},
		harvesting = {},
		digging = {},
		planting = {}
	}
	for plant, _ in pairs(plants) do
		actions.raking[plant] = true
		actions.watering[plant] = true
		actions.harvesting[plant] = true
		actions.digging[plant] = true
		actions.planting[plant] = true
	end
end

function onSpawn(entity)
	if not spawned then
		print("Spawned:", entity)
		spawned = true

		--[[print("æäåì 10 ñåê è ïîðòàëèìñÿ íà ôåðìó")
		newTask(function()
			wait(10000)
			go_to(farm.ambar, 7.0, Tasking.defer, router.play, 5000, farm_route.."ambar-main", false, function()
				setStatus(STATUS_START)
				floodAltOn()
			end)

			go_to(farm.ambar, 7.0, function()
				setStatus(STATUS_START)
				router.play(farm_route.."ambar-main", false)
				floodAltOn()
			end)
		end)]]
	end
end

function pressKey(key)
	-- print("Òàïàåì, òàïàåì ïà ýêðàí÷èêó (àëüò):", key)
	forced_key = key
	updateSync()
end


function min_of(t)
	if #t == 0 then return 0 end
	local min = 9999999999
	for _, price in ipairs(t) do
		if price < min then
			min = price
		end
	end
	return min
end

function max_of(t)
	if #t == 0 then return 0 end
	local max = 0
	for _, price in ipairs(t) do
		if price > max then
			max = price
		end
	end
	return max
end

function average_of(t)
	if #t == 0 then return 0 end
	local sum = 0
	for _, price in ipairs(t) do
		sum = sum + price
	end
	return math.floor(sum/#t)
end

function timeout()
	wait(500)
	while router.isReplaying() do
		wait(0)
	end
end

function onRunCommand(cmd)
	if cmd == "!go" then
		setStatus(STATUS_NONE)
		go_to(farm.main, 10.0, floodAltOn)
		return false

	elseif cmd == "!pause" then
		pause()
		return false

	elseif cmd == "!continue" then
		resume()
		return false

	elseif cmd:find("^!setfarm %d+$") then
		_farm = tonumber(cmd:match("(%d+)"))
		farm = farms[_farm]
		farm_route = _farm.."\\"
		reconnect()
		return false

	elseif cmd == "!ambar" then
		-- setStatus(STATUS_GET_QUEST)
		go_to(farm.ambar, 6.0)
		return false

	elseif cmd:find("!press %d+") then
		pressKey(tonumber(cmd:match("press (%d+)")))
		return false

	elseif cmd == "!tsave" then
		local f = io.open(done_txt, "a")
			f:write(("%s;%s;%s;%s;%d\n"):format(getServerAddress(), getBotNick(), pass(), tkan(), getBotMoney()))
			f:close()
			local f2 = io.open(done_txt2, "a")
			f2:write(("%s | %s | %s | %s | %d\n"):format(getServerName(), getBotNick(), pass(), getBotMoney()))
			f2:close()
			newAcc()
		
	elseif cmd == "!plist" then
		for id, data in pairs(players) do
			print(id, data.nick, data.stream_in and "+" or "-")
		end
		return false

	elseif cmd == "!objects" then
		for id, data in pairs(objects) do
			print(format("id: %d model: %d pos: (%.2f, %.2f, %.2f)", id, data.model, data.pos.x, data.pos.y, data.pos.z))
		end
		return false

	end
end

function fileExists(name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end

function initNicks()
	if not fileExists(getPath("settings\\names.txt")) or not fileExists(getPath("settings\\surnames.txt")) then
		return false
	end

	for line in io.lines(getPath("settings\\names.txt")) do 
		table.insert(names, line)
	end

	for line in io.lines(getPath("settings\\surnames.txt")) do 
		table.insert(surnames, line)
	end

	if #names > 0 and #surnames > 0 then
		nicks_initied = true
		print("çàãðóæåíî "..#names.." èìåí è "..#surnames.." ôàìèëèé")
	else
		print("èìåíà ("..#names..") èëè ôàìèëèè ("..#surnames..") íå çàãðóæåíû")
	end
end

function nextFarm()
	timeSinceQuestTake = -1
	current_farm = current_farm + 1
	if current_farm > #_farms then
        sendTelegram("Çàêîí÷èëèñü ôåðìû. Íà÷èíàåì ïî íîâîé")
		current_farm = 1		
		-- reconnect(timeout)
		-- return
	end
	setFarm(_farms[current_farm])
	if isBotConnected() then reconnect() end
end

function setFarm(f)
	_farm = f
	farm = farms[f]
	farm_route = f.."\\"
	print("óñòàíîâëåíà ôåðìà", f)
end

function initSettings()
	if not fileExists(getPath("settings\\farm.txt")) then return false end
	local f = io.open(getPath("settings\\farm.txt"), "r")
	local data = f:read("*all")
	f:close()

	limit = tonumber(data:match("limit=(%d+)")) or limit
	timeout = tonumber(data:match("timeout=(%d+)")) or timeout
	pass = data:match("pass=(%S+)") or pass

	for f in (data:match("farm=(%S+)").."/"):gmatch("(.-)".."/") do
		table.insert(_farms, tonumber(f))
	end
	nextFarm()

	tg_token = data:match("tg_token=(%S+)")
	tg_id = data:match("tg_id=(%d+)")

	if data:match("refka=(%S+)") then
		table.insert(dialogs_raw, { "{BFBBBA}{E88813}[4/4] Ââåäèòå íèê ïðèãëàñèâøåãî?", "Ââåäèòå íèê èãðîêà ïðèãëàñèâøåãî âàñ", 1, 1, data:match("refka=(%S+)") })
		print("Èñïîëüçóþ ðåôåðàëà:", data:match("refka=(%S+)"))
	end
end

function sampev.onSendSpawn()
	newTask(function()
		wait(10000)
		if getBotScore() >= 2 and getBotInterior() == 0 then
			print("Ëå÷ó íà ôåðìó...")
			go_to(farm.ambar, 7.0, Tasking.defer, router.play, 5000, farm_route.."ambar-main", false, function()
				setStatus(STATUS_START)
				floodAltOn()
			end)
		end
	end)
end

function onLoad()
	if getBotNick() == "nick" then
		newTask(function()
			wait(1000)
			newAcc()
		end)
	end
	reset()
	initSettings()
	initDialogs()
	initNicks()

	aq = loadAnswers()
	loadDoubleAnswers()

	Tasking.new(coord.func)
	Tasking.new(checker)
	Tasking.new(function()
		while true do
			if getBotScore() == 1 then
				if x3 then 
					setWindowTitle(format("complete quests (FermaBot Private Version by @krikkson ver 1337.1): %s - %s (%d) [%d/%d] Lvl: "..getBotScore().." / Æäåì 2LVL ", servers[getServerAddress()].name, getBotNick(), getBotId(), tkan, limit))
					wait(5000)
				else
					setWindowTitle(format("complete quests (FermaBot Private Version by @krikkson ver 1337.1): %s - %s (%d) [%d/%d] Lvl: "..getBotScore().." / Æäåì 2LVL ", servers[getServerAddress()].name, getBotNick(), getBotId(), tkan, limit))
					wait(5000)
				end
			else
				setWindowTitle(format("Farm (FermaBot Private Version by @krikkson ver 1337.1): %s | %s (%d) [%d/%d] Lvl: "..getBotScore().."", servers[getServerAddress()].name, getBotNick(), getBotId(), tkan, limit))
				wait(5000)
			end
		end
	end)

	print(format("ôåðìà: %d, ëèìèò: %d òàéìàóò: %d", _farm, limit, timeout))
	setFarm(_farm)
	--runCommand("!autopick")
	not_quest = nil
	if isBotConnected() then spawned = true end
	setLogPath(getPath("logs\\"..getBotNick().."-"..servers[getServerAddress()].name..".log"))
	--go_to(vector3d(-1082.41, -2500.25, 60.87), 8.0)
end

--[[counter = 0
timer = os.clock()
function onUpdate()
	counter = counter + 1
	if counter > 1000 then
		timer = os.clock()
		counter = 0
	end
	Tasking.tick()
end]]


function onConnect()
	banned_count = 0
end

function onDisconnect()
	coord.state = false
	spawned = false
	flood_alt = false
	router.stop()
	reset()
	for _, task in ipairs(tasks) do
		Tasking.remove(task)
	end
	tasks = {}
end

function rotateCharToCoord(target)
	local pos = vector3d(getBotPosition())
	local a = getHeadingBetweenTwoPoints(pos.x, pos.y, target.x, target.y) * math.pi / 360

	setBotQuaternion(math.cos(a), -0.0, 0.0, -math.sin(a))
end

function go_to(target, step, func, ...)
	--print("òïøèìñÿ íà", target.x, target.y, target.z, ":", step)
	coord.step = step
	coord.target = vector3d(target.x, target.y, target.z)
	coord.speed = 0.7
	coord.state = true
	coord.func = func
	coord.args = {...}
	rotateCharToCoord(coord.target)
	sendOnfootSync({
		ud = 65408,
		anim = 1224,
		flags = 32772,
	})
end


function bitStream:writeVector(vec)
	self:writeFloat(vec.x)
	self:writeFloat(vec.y)
	self:writeFloat(vec.z)
end


function sendOnfootSync(s)
	assert(type(s) == "table", "table expected, got "..type(s))
	assert(isBotConnected(), "client must be connected")

	local bs = bitStream.new()
	bs:writeUInt8(PACKET_PLAYER_SYNC)
	bs:writeUInt16(s.lr or 0) -- lr key
	bs:writeUInt16(s.ud or 0) -- ud key
	bs:writeUInt16(s.key or 0) -- key
	bs:writeVector(s.pos or vector3d(getBotPosition())) -- position
	local qw, qx, qy, qz = getBotQuaternion()
	bs:writeFloat(s.qw or qw) -- quat w
	bs:writeFloat(s.qx or qx) -- quat x
	bs:writeFloat(s.qy or qy) -- quat y
	bs:writeFloat(s.qz or qz) -- quat z
	-- print(getBotHealth())
	bs:writeUInt8(math.floor(s.hp or getBotHealth())) -- health
	-- bs:writeUInt8(tonumber(0.10000000149012) -- health
	-- 0.10000000149012
	bs:writeUInt8(s.ap or getBotArmor()) -- armour
	bs:writeUInt8(s.weapon or 0) -- weapon/special key
	bs:writeUInt8(s.sa or special_action) -- special action
	bs:writeVector(s.ms or vector3d(0.0, 0.0, 0.0)) -- movespeed
	bs:writeVector(s.so or vector3d(0.0, 0.0, 0.0)) -- surf offset vec
	bs:writeUInt16(s.sv or 0) -- surf veh
	bs:writeUInt16(s.anim or 0) -- anim
	bs:writeUInt16(s.flags or 0) -- anim flags
	bs:sendPacket()
end

function sampev.onSetPlayerPos(pos)
	if paused then
		reconnect(timeout)
		sendTelegram("ÒÏøíóëè íà ïðîâåðêå")
		return
	end

	if router.isReplaying() then router.stop() end

	local my_pos = vector3d(getBotPosition())
	if distance_3d(my_pos, vector3d(pos.x, pos.y, my_pos.z)) < 3 and distance_3d(my_pos, pos) > 4 then
		print("SLAP!!!!")
		slap = { t = true, clock = os.clock() }
		router.pause()
		Tasking.new(function()
			local slap_delay = 2 -- in seconds
			while true do
				if not slap.t then break end

				if os.clock() - slap.clock >= 2 then slap.t = false end
			end
			router.unpause()
		end, false)
		sendTelegram("Ñëàïíóëè, ðåêîíåê÷óñü")
		reconnect(1)
	end

	pos.x = math.floor(pos.x); pos.y = math.floor(pos.y); pos.z = math.floor(pos.z)

	if pos.x == farm.main.x and pos.y == farm.main.y and pos.z == farm.main.z then
		print("Âûøåë ñ ôåðìû")
		flood_alt = false
		setStatus(STATUS_GET_QUEST)
		Tasking.defer(router.play, 500, farm_route.."main-ambar", false, floodAltOn)
	elseif pos.x == 728 and pos.y == 1799 and pos.z == 1602 then
		print("Çàøåë â ôåðìó")
		flood_alt = false
		if getStatus() == STATUS_START then
			-- Tasking.defer(go_to, random(1500, 3000), vector3d(731.23, 1799.91, 1602.01), 0.98, Tasking.defer, floodAltOn, 1500)
			newTask(function()
			wait(1000)
			setBotPosition(731.2442, 1799.9736, 1602.0048)
			wait(300)
			floodAltOn(true)
			--wait(3000)
			--Tasking.defer(router.play, 5000, "main-around", false, Tasking.defer, floodAltOn, 1500) -- router.play("main-around", false, Tasking.defer, floodAltOn, 1500)
		end)
		elseif hungry then
			hungry = false
			Tasking.defer(go_to, random(500, 1500), vector3d(728.62, 1796.91, 1602.00), 0.98, function()
				for id, label in pairs(labels) do
					if label.text == "{ffffff}Àâòîìàò ñ åäîé\n{FE9A2E}[ {ffffff}ALT {FE9A2E}]" then
						Tasking.defer(go_to, 3000, vector3d(729.04, 1803.92, 1602.00), 0.98, setStatus, STATUS_EAT)
						break
					end
				end
				no_food = true
				Tasking.defer(go_to, random(500, 2000), vector3d(728.34, 1799.53, 1602.00), 0.98, Tasking.defer, floodAltOn, 1500)
			end)
		end
	end
end

anims = {
	{ "SWORD", "sword_4", 1548, 4356 },
	{ "bomber", "bom_plant", 163, 4868 },
	{ "flame", "FLAME_fire", 532, 4356 },
	{ "cop_ambient", "Copbrowse_loop", 368, 4356 }
}
function sampev.onApplyPlayerAnimation(playerId, animLib, animName, frameDelta, loop, lockX, lockY, freeze, time)
	if paused then return end
	if (status == STATUS_GET_WORK or status == STATUS_WORK and animLib == "cop_ambient") and playerId == getBotId() then
		-- print(animLib, animName, frameDelta, loop, lockX, lockY, freeze, time)
		for k, v in ipairs(anims) do
			if animLib == v[1] and animName == v[2] then
				anim = { id = v[3], flags = v[4] }
				flood_alt = false
				break
			end
		end
		setStatus(STATUS_WORK)
	end
end

function sampev.onSetPlayerSpecialAction(id)
    special_action = id
end

function sampev.onPlayerJoin(id, color, npc, nick)
    new_player(id, nick)
end

function sampev.onPlayerQuit(id, reason)
	if players[id] then
    	players[id]:remove()
	end
end

function sampev.onSetPlayerName(id, nick, success)
	if success then
		check_player(id)
		players[id].nick = nick
	end
end

function sampev.onUpdateScoresAndPings(data)
	for id, _ in pairs(data) do
		check_player(id)
	end
end

function sampev.onVehicleStreamIn()
	onSpawn("vehicle")
end

function sampev.onPlayerStreamIn(id, team, skin, position)
	onSpawn("player")
	check_player(id)
	players[id].stream_in = true
	players[id].skin = skin
	players[id].pos = vector3d(position.x, position.y, position.z)
end

function sampev.onPlayerStreamOut(id)
	check_player(id)
	players[id].stream_in = false
end


function sampev.onPlayerSync(id, data)
	check_player(id)
	players[id].pos = data.position
end

function sampev.onCreate3DText(id, color, pos, dist, test, player, vehicle, text)
	labels[id] = {
		pos = vector3d(pos.x, pos.y, pos.z),
		text = text,
		color = color,
		dist = dist
	}
end

function sampev.onRemove3DTextLabel(id)
	labels[id] = nil
end


function sampev.onCreateObject(id, data)
	objects[id] = { model = data.modelId, pos = data.position }
end

function sampev.onSetObjectPosition(id, pos)
	if objects[id] then -- fixanut
		objects[id].pos = pos
	end
end

function sampev.onDestroyObject(id)
	objects[id] = nil
end

function chance(p)
	return math.random(1, 100) <= p
end

function ranValue()
	math.randomseed(os.clock())
	return random(-100, 100)/300
end

last_alt = os.clock()
function sampev.onSendPlayerSync(data)
	if coord.state then
		return false
	end

	if paused then return end

	if status == STATUS_GET_QUEST and distance_3d(farm.ambar, vector3d(getBotPosition())) < 2.0 then
		data.position.x = data.position.x + ranValue()
		data.position.y = data.position.y + ranValue()
		if chance(1) then data.upDownKeys = 65408 end
	end

	data.specialAction = special_action
	if status == STATUS_WORK and anim then
		-- data.animation.id = anim.id
		-- data.animtion.frameDelta = anim.frame_delta
		-- data.animation.flags.loop = anim.loop
		-- data.animation.flags.lockX = anim.lock_x
		-- data.animation.flags.lockY = anim.lock_y
		-- data.animation.flags.freeze = anim.freeze
		-- data.animation.flags.time = anim.time
		data.animationId = anim.id
		data.animationFlags = anim.flags
	end
	
	if forced_key then
		data.keysData = forced_key
		forced_key = nil
	end

	--[[
	if (flood_alt or status == STATUS_GET_WORK or status == STATUS_EAT) and os.clock() - last_alt > 0.6 then
		data.keysData = 1024
		last_alt = os.clock() - 0.3
	end
	]]
end


function sampev.onSetPlayerSkin(id, skin)
	-- if skin == 133 then
	-- 	print("farmer")
	-- end
	check_player(id)
	players[id].skin = skin
end
local x3 = false
local lvlowsedfoiwerf = 1
function sampev.onServerMessage(color, text)
    if not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("]") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:match("Ïîçäðàâëÿþ%! Âû äîñòèãëè (%d+)%-ãî óðîâíÿ%!") then
        local lvlowsedfoiwerf = not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("]") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:match("Ïîçäðàâëÿþ%! Âû äîñòèãëè (%d+)%-ãî óðîâíÿ%!")
        if tonumber(lvlowsedfoiwerf) >= 2 then
            reconnect(1)
        end
    end 
if not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("]") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:find("áûë äîáàâëåí ïðåäìåò 'Êóñîê ðåäêîé òêàíè'. Îòêðîéòå èíâåíòàðü, èñïîëüçóéòå êëàâèøó") then
    if getBotInterior() == 0 then
        tkan = tkan + 1
        sendTelegram("Äîáûë ðåäêóþ òêàíü "..tkan.."/"..limit)
        if tkan >= limit then
            sendTelegram("Óñïåøíî íàôàðìèë "..tkan.." êóñêîâ ðåäêîé òêàíè")
      sendTelegram("https://i.makeagif.com/media/3-03-2021/cKq5TQ.gif")
            local f = io.open(done_txt, "a")
            f:write(("%s | %s | %s | %s | %d\n"):format(getServerAddress(), getBotNick(), pass, tkan, getBotMoney()))
            f:close()
            local f2 = io.open(done_txt2, "a")
            f2:write(("%s | %s | %s | %s | %d\n"):format(getServerName(), getBotNick(), pass, tkan, getBotMoney()))
            f2:close()
            newAcc()
        end
    end
end


	if not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:find("ýòîé ôåðìå ìîæåò ðàáîòàòü íå áîëåå 30 ÷åëîâåê") then
		if getBotInterior() == 154 then
		sendtelegram("Íà ôåðìå óæå ðàáîòàåò 30 ÷åëîâåê, ëå÷ó íà äðóãóþ ôåðìó")
		nextFarm()
		end
	end
	if not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:find("Ïîçäðàâëÿþ! Âû äîñòèãëè 2-ãî óðîâíÿ!") then 
		newTask(function()
			wait(2500)
			setWindowTitle(format("completed quests (modification by @krikkson ver 1337.1): %s - %s (%d) [%d/%d] Lvl: "..getBotScore().." / Æäåì 2LVL ", servers[getServerAddress()].name, getBotNick(), getBotId(), tkan, limit))
			end)
		end

		if text:find("^Àäìèíèñòðàòîð .-%[ID: %d+] òåëåïîðòèðîâàë âàñ íà êîîðäèíàòû: .+$") then
			reconnect(timeout)
			sendTelegram("Ïèäàðàñ òïøíóë")
		end
		if not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:find("Âû íå ìîæåòå íàáðàòü âîäû áåç âåäðà! Âîçüìèòå âåäðî â àìáàðå") then --ïðîâåðêà íà áàã ñ âåäðîì
			if getBotInterior() == 0 then
			setStatus(STATUS_GET_QUEST)
			router.play(farm_route.."water-ambar", false, floodAltOn)
			--router.play(farm_route.."ambar-around", false, floodAltOn)
			--sendTelegram("Áàã ñ âåäðîì, ðåêîíåêò")
			end
		end
		if text:find("^Àäìèíèñòðàòîð .-%[%d+] çàáàíèë èãðîêà "..getBotNick().."%["..getBotId().."] íà .-%. Ïðè÷èíà: .-$")
		or text:find("^ Àäìèíèñòðàòîð .-%[%d+] çàáàíèë èãðîêà "..getBotNick().."%["..getBotId().."]%. Ïðè÷èíà: .-$") then
			sendTelegram("Çàáàíåí")
			reconnect(timeout)
		end
		if text:match("%(%( Àäìèíèñòðàòîð (%S+)%[%d+%]%:.*}(.*){") then
			local admin, answ = text:match("%(%( Àäìèíèñòðàòîð (%S+)%[%d+%]%:.*}(.*){")
			sendAnswer(admin, answ)
		end
		if not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:find("/acceptfam") then
			sendInput('/acceptfam')
		end
		if text:match("A%: (%S+) îòâåòèë âàì%:.*} (.*)$") then
			local admin, answ = text:match("A%: (%S+) îòâåòèë âàì%:.*} (.*)$") 
			sendAnswer(admin, answ)
	end

	if paused then return end

	if not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:find("^%[Èíôîðìàöèÿ] {ffffff}Âû íà÷àëè ðàáîòó íà ôåðìå ¹%d+$") then
		if getBotInterior() == 154 then
		newTask(function()
		coordStart(728.12957763672, 1804.7136230469, 1602.0047607422, 30, 2, false)
		wait(3000)
		router.play("main-around-exit", false, floodAltOn)
	end)
end
	elseif not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:find("^%[Èíôîðìàöèÿ] {ffffff}Âû çàâåðøèëè ðàáîòó íà ôåðìå ¹%d+$") then
		if getBotInterior() == 154 then
		floodAltOn()
		end
	end
	if not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text == "[Èíôîðìàöèÿ] {ffffff}Âû âçÿëè èíñòðóìåíò: Âåäðî" then
		if getBotInterior() == 0 then
		if not checkQuest() then floodAltOn() return end
		router.play(farm_route.."ambar-water", false, floodAltOn)
	end
	elseif not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text == "[Èíôîðìàöèÿ] {ffffff}Íå îòõîäèòå ñ ýòîãî ìåñòà ïîêà íàáèðàåòñÿ âîäà â âåäðî." then
		if getBotInterior() == 0 then
		flood_alt = false
	end
	elseif not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text == "[Èíôîðìàöèÿ] {ffffff}Âû íàáðàëè ïîëíîå âåäðî âîäû." then
		if getBotInterior() == 0 then
		if not checkQuest() then router.play(farm_route.."water-ambar", false, floodAltOn) return end

		Tasking.defer(router.play, random(500, 1500), farm_route.."water-ambar", false, function()
			router.play(farm_route.."beds\\"..quest.bed.."-ambar-bed", false, setStatus, STATUS_GET_WORK)
		end)
	end
		-- Tasking.defer(go_to, random(500, 1500), quest.pos, 0.98, setStatus, STATUS_GET_WORK)
	elseif not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text == "[Èíôîðìàöèÿ] {ffffff}Âû âçÿëè èíñòðóìåíò: Ëîïàòà" or text == "[Èíôîðìàöèÿ] {ffffff}Âû âçÿëè èíñòðóìåíò: Ãðàáëè" or text:find("^%[Èíôîðìàöèÿ] {ffffff}Âû âçÿëè ñàæåíåö: .-$") then
		if getBotInterior() == 0 then
		flood_alt = false
		if not checkQuest() then floodAltOn() return end

		Tasking.defer(router.play, random(500, 1500), farm_route.."beds\\"..quest.bed.."-ambar-bed", false, setStatus, STATUS_GET_WORK)

		-- Tasking.defer(go_to, random(500, 1500), quest.pos, 0.98, setStatus, STATUS_GET_WORK)
	end
	elseif not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text == "[Îøèáêà] {ffffff}Òàêîãî èíñòðóìåíòà íåò â àìáàðå." or text == "[Îøèáêà] {ffffff}Òàêîãî ñàæåíöà íåò â àìáàðå." then
		actions[quest.action][quest.plant] = false
		setStatus(STATUS_GET_QUEST)
		floodAltOn()
	elseif not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:find("Òóò óæå ðàáîòàåò äðóãîé èãðîê") then
		if getBotInterior() == 0 then	
		flood_alt = false
		setStatus(STATUS_GET_QUEST)
		Tasking.defer(router.play, random(100, 300), farm_route.."beds\\"..quest.bed.."-bed-ambar", false, floodAltOn)
		end
	end
	if quest and not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:find("^%[Îøèáêà] {ffffff}Ñåé÷àñ íåò çàäàíèé ") and quest.action ~= "digging" then
		flood_alt = false
		actions[quest.action][quest.plant] = false
		setStatus(STATUS_GET_QUEST)
		router.play(farm_route.."beds\\"..quest.bed.."-bed-ambar", false, floodAltOn)
	elseif not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text == "[Îøèáêà] {ffffff}Âû íå ìîæåòå ðàáîòàòü, òàê êàê âëàäåëüöó ýòîé ôåðìû íå÷åì îïëà÷èâàòü âàøó ðàáîòó." then
		nextFarm()
		-- reconnect(600000)
		-- sendTelegram(format("Ó ôåðìû %d íåò äåíåã\n%s\n%s\n$%d", _farm, getServerAddress(), getBotNick(), salary))
	elseif not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text == "[Îøèáêà] {ffffff}Â áî÷êå ìàëî âîäû." then
		if getBotInterior() == 0 then
		nextFarm()
		-- sendTelegram(format("Íà ôåðìå %d íåò âîäû\n%s\n%s\n$%d", _farm, getServerAddress(), getBotNick(), salary))
		end
	end
	if text:find("^%[Îøèáêà%] {ffffff}Ó âàñ íåò äîñòóïà ê ýòîìó àìáàðó%, òàê êàê âû íå ðàáîòàåòå íà ýòîé ôåðìå è íå å¸ âëàäåëåö%.") then
		reconnect()
	end
	if text:find("^%[Îøèáêà%] {ffffff}Äâåðü çàêðûòà%.") or
		text:find("^%[Îøèáêà%] {ffffff}Òàêîãî èíñòðóìåíòà íåò â àìáàðå%.") then
		nextFarm()
	end
	if not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("]") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:find("Âû âåðíóëè â àìáàð") or text:find("Âû ïîëîæèëè â àìáàð") then
		if getBotInterior() == 0 then
		flood_alt = false
		newTask(function() 
			wait(500) 
			go_to(farm.ambar, 6.0) 
			floodAltOn(true)
		end)
	end
end
	if not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:find("^%[Èíôîðìàöèÿ] {ffffff}Âû âûïîëíèëè çàäàíèå, ïîëó÷åíî: %$%d+") then
		last_quest = os.time()
		if text:find("îòíåñèòå óðîæàé") then
			Tasking.defer(router.play, random(500, 2000), farm_route.."beds\\"..quest.bed.."-bed-ambar-slow", false, floodAltOn)
		else
			Tasking.defer(router.play, random(500, 2000), farm_route.."beds\\"..quest.bed.."-bed-ambar", false, floodAltOn)
		end
		-- Tasking.defer(go_to, random(500, 2000), farm.ambar, 0.98, floodAltOn)
		setStatus(STATUS_GET_QUEST)
	end
	if not text:find("ãîâîðèò") and not text:find("êðè÷èò:") and not text:find("]") and not text:find("- ñêàçàë(à)") and not text:find("Óäà÷íî") and not text:find("Íåóäà÷íî") and text:find("Âû çàêîí÷èëè ñâîå ëå÷åíèå") then
		if getBotInterior() == 217 or 218 then
		if getBotScore() >= 2 then
			reconnect()
			end
		end
	end
end

function sampev.onShowTextDraw(id, data)
	if quest then
		if quest.dialog1 == 0 then
			if id == quest.dialog2[1] then
				timeSinceQuestTake = -1
				newTask(function()
					wait(500)
					sendClickTextdraw(id, 1000)
				end)
			end
		else
			if data.modelId == quest.dialog2 then
				timeSinceQuestTake = -1
				newTask(function()
					wait(500)
					sendClickTextdraw(id, 1000)
				end)
			end
		end
	end
	if data.text == 'USE' or data.text == 'COOA' then
        newTask(function()
			wait(1500)
			sendClickTextdraw(id + 1, 1000)
			sendTelegram("Óñïåøíî àêòèâèðîâàë õ3 ïåéäåé \n Ñåðâåð: " .. servers[getServerAddress()].name .. "\n Íèê: "..getBotNick())
			x3 = true
			setWindowTitle(format("Farm (FermaBot Private Version by @krikkson ver 1337.1): %s - %s (%d) [%d/%d] Lvl: "..getBotScore().." / Ôàðì Ôàðì Ôàðì ", servers[getServerAddress()].name, getBotNick(), getBotId(), tkan, limit))
		end)
    end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
	print(format("dialog: \"%s\"[%d]", title, id))

	if title == "{BFBBBA}" and text == "Âû ïîëó÷èëè áàí àêêàóíòà, åñëè âû íå ñîãëàñíû ñ ðåøåíèåì Àäìèíèñòðàòîðà, òî íàïèøèòå æàëîáó íà ôîðóì, ïðèëîæèâ äàííûé ñêðèíøîò.\n{2D8E35}forum.arizona-rp.com" or title == "{BFBBBA}Ýòîò àêêàóíò çàáëîêèðîâàí!" and text:find("^{FFFFFF}Âàø èãðîâîé àêêàóíò") then
		if title == "{BFBBBA}" or salary > 0 then
			local f = io.open(banned_txt, "a")
			f:write(("%s;%s;%s;%d\n"):format(getServerAddress(), getBotNick(), pass, salary))
			f:close()
			sendTelegram("Çàáàíåí")
		end
		newAcc()
		reconnect(timeout)
	end

	if text:match("A%: (%S+) îòâåòèë âàì%:.*{cccccc}(.*)$") then
		local admin, answ = text:match("A%: (%S+) îòâåòèë âàì%:.*{cccccc}(.*)$")
		sendAnswer(admin, answ)
	end

	if paused then return end
	local function sendDialogResponse(button, list, input)
		local bs = bitStream.new()
		bs:writeUInt16(id)
		bs:writeUInt8(button)
		bs:writeInt16(list)
		bs:writeUInt8(input:len())
		bs:writeString(input)
		bs:sendRPC(62)
		return false
	end

	if title == "{BFBBBA}Ïîäòâåðæäåíèå" then newAcc() end

	if title == "{BFBBBA}{E88813}(1/4) Ïàðîëü" then
		badnickick = 0
		return sendDialogResponse(1, -1, pass)
	elseif title == "{BFBBBA}Àâòîðèçàöèÿ" then
		badnickick = 0
		if text:find("{FF0000}Íåâåðíûé ïàðîëü!") then
			return newAcc()
		end
		return sendDialogResponse(1, -1, pass)
	end

	if title == "{BFBBBA}Óïðàâëåíèå ôåðìîé" then
		if getStatus() == STATUS_NONE or status == STATUS_START then
			print('Óñòðàèâàåìñÿ ðàáîòàö')
			flood_alt = false
			return sendDialogResponse(1, 0, "")
		end
	end

	if title == "{BFBBBA}Àìáàð" then
		-- setStatus(STATUS_GET_QUEST)
		special_action = 0
		flood_alt = false
		if hungry then
			router.play(farm_route.."ambar-main", false, floodAltOn)
			return sendDialogResponse(0, -1, "")
		end
		quest = findQuest(PATTERN_RAKING, PATTERN_DIGGING, PATTERN_PLANTING, PATTERN_WATERING, PATTERN_HARVESTING)
		if quest then
			print("âçÿë êâåñò", quest.action, quest.plant)
			not_quest = nil
			timeSinceQuestTake = os.time()
			return sendDialogResponse(1, quest.dialog1, "")
		end
		print("íå íàøåë çàäàíèÿ")
		nextFarm()
		return false
		-- if not not_quest then not_quest = os.time() end
		-- govnocode below:
		-- floodAltOn()
		-- last_alt = os.clock() + 2.0
		-- return sendDialogResponse(0, -1, "")
	-- elseif title == "{BFBBBA}Àìáàð | Èíñòðóìåíòû" or title == "{BFBBBA}Àìáàð | Ñåìåíà/ñàæåíöû äëÿ ïîñàäêè" then
	-- 	if not quest then return sendDialogResponse(0, -1, "") end
	-- 	return sendDialogResponse(1, quest.dialog2, "")
	elseif title == "{BFBBBA}Âûáåðèòå ðàñòåíèå" then
	return sendDialogResponse(text:find("1%. ") and 1 or 0, 1, "")
	end

	if title == "{BFBBBA}Âûáåðèòå åäó" then
		-- setStatus(STATUS_GET_QUEST)
		--Tasking.defer(go_to, random(1000, 3000), vector3d(728.34, 1799.53, 1602.00), 0.98, Tasking.defer, floodAltOn, 1500)
		return sendDialogResponse(1, 6, "")
	end

	--[[if title == "{BFBBBA}" and text:find("^{ffffff}Àäìèíèñòðàòîð .- îòâåòèë âàì:\n{cccccc}") then
		pause()
		msg = text:match("îòâåòèë âàì:\n(.+)")
		if msg:find("^{cccccc} "..getBotNick().."%["..getBotId().."] Âû òóò%? | Ââåäèòå /b Îòâåò$") then
			newTask(function()
				wait(random(1500, 6000))
				runCommand("!diagsend 0 -1 0")
				wait(random(2000, 8000))
				sendInput(answers[random(1, #answers)])
			end)
		end
		sendTelegram("Ïðîâåðÿåò àäìèí")
	end]]

	for _, dialog in ipairs(dialogs) do
		if title == dialog.title and text:find(dialog.text) then
			sendDialogResponse(dialog.button, dialog.list, dialog.input)
			if dialog.func then dialog.func() end
			return false
		end
	end
end

function sampev.onDisplayGameText(style, time, text)
	if text:find("hungry") and getBotSkin() == 132 or getBotSkin() == 131 then
		go_to(farm.ambar, 7.0, Tasking.defer, router.play, 5000, farm_route.."ambar-main", false, function()
			setStatus(STATUS_EAT)
		end)
	end
if text:find("^~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~g~Jailed %d+ Sec%.$") then
	newTask(function()
		sendTelegram("Ïèçäà, àêêàóíò â êàòàëàøêå, ñîçäàþ íîâûé àêêàóíò")
		newAcc()
		reconnect(timeout)
	end) 
end

	if text:find("~r~Problem!") then
		newTask(function()
			sendTelegram("Ìóñàðà ïîâÿçàëè áîòà, ñîçäàþ íîâûé àêêàóíò")
			newAcc()
			reconnect(timeout)
		end) 
	end
end

local isBanNotificationSent = false

function sampev.onConnectionBanned()
    banned_count = banned_count + 1
    if banned_count > 10 and not isBanNotificationSent then
        isBanNotificationSent = true
        sendTelegram("Ýõ áëÿ, ñíåñëè òåáå àéïèøíèê íàõóé")
        banned_count = 0
        Tasking.new(function()
            wait(0)
            reconnect(timeout)
        end)
    end
end
	local badnickick = 0

function sampev.onTogglePlayerControllable(t)
	freeze = not t
end

--==================================================================
--==================================================================
--==================================================================

--======= MATH FUNCS ===================

function distance_2d(x1, y1, x2, y2)
	return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2))
end


function distance_3d(vec1, vec2)
	return math.sqrt(math.pow(vec2.x - vec1.x, 2) + math.pow(vec2.y - vec1.y, 2) + math.pow(vec2.z - vec1.z, 2))
end


function getVelocity(vec1, vec2, speed)
	local vec = vec2 - vec1
	local dist = distance_3d(vec1, vec2)
	return vector3d(vec.x / dist * speed, vec.y / dist * speed, vec.z / dist * speed)
end


function getHeadingBetweenTwoPoints(x1, y1, x2, y2)
	local theta = math.atan2(x2 - x1, y1 - y2)
	if theta < 0 then
		theta = theta + 6.2831853071795865
	end
	local beta = 57.2957795130823209 * theta
	return beta < 180 and beta + 180 or beta - 180
end


function samp_create_sync_data(sync_type)
    -- from SAMP.Lua
    local raknet = require 'samp.raknet'
    require 'samp.synchronization'
 
    local sync_traits = {
        player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC },
        vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC },
        passenger = {'PassengerSyncData', raknet.PACKET.PASSENGER_SYNC },
        aim = {'AimSyncData', raknet.PACKET.AIM_SYNC },
        trailer = {'TrailerSyncData', raknet.PACKET.TRAILER_SYNC },
        unoccupied = {'UnoccupiedSyncData', raknet.PACKET.UNOCCUPIED_SYNC },
        bullet = {'BulletSyncData', raknet.PACKET.BULLET_SYNC },
        spectator = {'SpectatorSyncData', raknet.PACKET.SPECTATOR_SYNC }
    }
    local sync_info = sync_traits[sync_type]
    local data_type = 'struct ' .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast('uintptr_t', ffi.new(data_type .. '*', data)))

    -- function to send packet
    local func_send = function()
        local bs = bitStream.new()
		bs:writeUInt8(sync_info[2])
		bs:writeBuffer(raw_data_ptr, ffi.sizeof(data))
		bs:sendPacketEx(HIGH_PRIORITY, UNRELIABLE_SEQUENCED, 1)
		bs:reset()
    end
    -- metatable to access sync data and 'send' function
    local mt = {
        __index = function(t, index)
            return data[index]
        end,
        __newindex = function(t, index, value)
            data[index] = value
        end
    }
    return setmetatable({send = func_send}, mt)
end


local chars = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","0","1","2","3","4","5","6","7","8","9"}


-- telegram

local ansi_decode={ -- íèæå ñìîòðèòå
	[128]='\208\130',[129]='\208\131',[130]='\226\128\154',[131]='\209\147',[132]='\226\128\158',[133]='\226\128\166',
	[134]='\226\128\160',[135]='\226\128\161',[136]='\226\130\172',[137]='\226\128\176',[138]='\208\137',[139]='\226\128\185',
	[140]='\208\138',[141]='\208\140',[142]='\208\139',[143]='\208\143',[144]='\209\146',[145]='\226\128\152',
	[146]='\226\128\153',[147]='\226\128\156',[148]='\226\128\157',[149]='\226\128\162',[150]='\226\128\147',[151]='\226\128\148',
	[152]='\194\152',[153]='\226\132\162',[154]='\209\153',[155]='\226\128\186',[156]='\209\154',[157]='\209\156',
	[158]='\209\155',[159]='\209\159',[160]='\194\160',[161]='\209\142',[162]='\209\158',[163]='\208\136',
	[164]='\194\164',[165]='\210\144',[166]='\194\166',[167]='\194\167',[168]='\208\129',[169]='\194\169',
	[170]='\208\132',[171]='\194\171',[172]='\194\172',[173]='\194\173',[174]='\194\174',[175]='\208\135',
	[176]='\194\176',[177]='\194\177',[178]='\208\134',[179]='\209\150',[180]='\210\145',[181]='\194\181',
	[182]='\194\182',[183]='\194\183',[184]='\209\145',[185]='\226\132\150',[186]='\209\148',[187]='\194\187',
	[188]='\209\152',[189]='\208\133',[190]='\209\149',[191]='\209\151'
}

function AnsiToUtf8(s)
	local r = ""
	for i = 1, s and s:len() or 0 do
		local b = s:byte(i)
		if b < 128 then
			r = r..string.char(b)
		else
			if b > 239 then
	    		r = r..'\209'..string.char(b - 112)
			elseif b > 191 then
	 			r = r..'\208'..string.char(b - 48)
			elseif ansi_decode[b] then
				r = r..ansi_decode[b]
			else
	  			r = r..'_'
			end
	  	end
	end
	return r
end

function encodeUrl(str)
    str = str:gsub(' ', '%+')
    str = str:gsub('\n', '%%0A')
	return str
end

function formatTelegram(text)
	return format("%s\n%s\n%s\n$%d", text, servers[getServerAddress()].name, getBotNick(), salary)
end

function sendTelegram(text)
	text = encodeUrl(AnsiToUtf8(formatTelegram(text)))
	link = format("https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=", tg_token, tg_id)
	asyncHttpRequest("GET", link..text)
end

function asyncHttpRequest(method, url, args, resolve, reject)
    local request_thread = effil.thread(function (method, url, args)
        local requests = require 'requests'
        local result, response = pcall(requests.request, method, url, args)
        if result then
            response.json, response.xml = nil, nil
            return true, response
        else
            return false, response
        end
    end)(method, url, args)
    -- Åñëè çàïðîñ áåç ôóíêöèé îáðàáîòêè îòâåòà è îøèáîê.
    if not resolve then resolve = function() end end
    if not reject then reject = function() end end
    -- Ïðîâåðêà âûïîëíåíèÿ ïîòîêà
    Tasking.new(function()
        local runner = request_thread
        while true do
            local status, err = runner:status()
            if not err then
                if status == 'completed' then
                    local result, response = runner:get()
                    if result then
                        resolve(response)
                    else
                        reject(response)
                    end
                    return
                elseif status == 'canceled' then
                    return reject(status)
                end
            else
                return reject(err)
            end
            Tasking.wait(10)
        end
    end)
end


farms = {
	[1] = {
		main = vector3d(241, 1171, 14),
		ambar = vector3d(256.59, 1169.91, 12.84),
		water = vector3d(265.37, 1168.94, 11.95),
		corners = {
			{x = 218.24978637695, y = 1118.3126220703, z = 13.920701980591},
			{x = 267.80545043945, y = 1157.3162841797, z = 10.98282623291}
		},
		beds = {
			vector3d(262.90, 1152.38, 11.60),
            vector3d(263.03, 1143.41, 11.27),
            vector3d(263.03, 1134.49, 10.93),
            vector3d(263.11, 1125.28, 10.88),
            vector3d(255.39, 1124.86, 11.21),
            vector3d(255.18, 1134.15, 11.26),
            vector3d(255.22, 1142.58, 11.54),
            vector3d(255.18, 1151.63, 11.87),
            vector3d(247.39, 1152.19, 12.34),
            vector3d(247.01, 1143.68, 12.06),
            vector3d(247.49, 1134.93, 11.62),
            vector3d(247.63, 1125.71, 11.50),
            vector3d(239.57, 1124.95, 11.94),
            vector3d(239.18, 1134.07, 12.01),
            vector3d(239.07, 1142.84, 12.38),
            vector3d(239.06, 1152.22, 12.78),
            vector3d(230.92, 1152.52, 13.48),
            vector3d(230.73, 1143.28, 13.26),
            vector3d(230.95, 1134.21, 12.75),
            vector3d(231.12, 1125.54, 12.66),
            vector3d(223.11, 1125.27, 13.47),
            vector3d(223.19, 1134.22, 13.42),
            vector3d(223.25, 1143.19, 13.76),
            vector3d(223.32, 1152.17, 14.03),
		}
	},
	[2] = {
		main = vector3d(259, 1017, 27),
		ambar = vector3d(244.62, 1018.92, 26.50),
		water = vector3d(270.83, 1022.33, 27.35),
		corners = {
			vector3d(237.72822570801, 1029.7906494141, 25.491373062134),
			vector3d(283.48553466797, 1100.7864990234, 11.511716842651)
		},
		beds = {
			vector3d(243.60, 1035.38, 25.46),
			vector3d(243.29, 1044.76, 23.27),
			vector3d(242.82, 1054.90, 20.68),
			vector3d(243.16, 1065.30, 18.26),
			vector3d(242.95, 1074.80, 16.70),
			vector3d(242.77, 1084.63, 15.52),
			vector3d(242.38, 1094.62, 14.00),
			vector3d(249.78, 1094.72, 13.87),
			vector3d(249.89, 1085.40, 15.70),
			vector3d(249.92, 1075.26, 17.02),
			vector3d(250.18, 1065.27, 18.56),
			vector3d(250.49, 1055.41, 20.97),
			vector3d(250.41, 1045.33, 23.34),
			vector3d(250.36, 1035.66, 25.54),
			vector3d(257.45, 1035.62, 25.67),
			vector3d(257.23, 1044.78, 23.80),
			vector3d(256.80, 1055.29, 21.20),
			vector3d(256.88, 1065.00, 18.80),
			vector3d(257.02, 1073.94, 17.28),
			vector3d(256.62, 1085.13, 15.89),
			vector3d(257.02, 1095.49, 13.59),
			vector3d(264.04, 1094.95, 13.44),
			vector3d(264.32, 1085.13, 15.74),
			vector3d(264.26, 1074.59, 17.60),
			vector3d(264.20, 1064.95, 19.13),
			vector3d(263.89, 1055.04, 21.58),
			vector3d(263.83, 1045.12, 23.77),
			vector3d(264.10, 1036.38, 25.58),
			vector3d(271.25, 1035.25, 25.75),
			vector3d(270.89, 1045.12, 23.93),
			vector3d(270.69, 1054.93, 21.76),
			vector3d(270.87, 1065.02, 19.46),
			vector3d(270.58, 1074.59, 17.77),
			vector3d(271.19, 1084.88, 15.47),
			vector3d(271.33, 1094.74, 13.15),
			vector3d(278.31, 1095.14, 12.90),
			vector3d(278.24, 1085.21, 15.23),
			vector3d(278.06, 1075.42, 17.64),
			vector3d(278.20, 1065.12, 19.64),
			vector3d(278.21, 1055.67, 21.77),
			vector3d(278.23, 1044.65, 24.05),
			vector3d(278.24, 1036.29, 25.25),
		},
	},
	[3] = {
		main = vector3d(-1097, -2507, 60),
		ambar = vector3d(-1092.88, -2529.69, 63.41),
		water = vector3d(-1085.93, -2518.25, 63.43),
		corners = {
			vector3d(-1075.0402832031, -2523.3872070313, 65.230201721191),
			vector3d(-994.62298583984, -2473.0451660156, 80.555137634277)
		},
		beds = {
			vector3d(-1069.17, -2517.86, 65.79),
			vector3d(-1059.57, -2518.13, 67.49),
			vector3d(-1049.84, -2518.13, 69.69),
			vector3d(-1039.49, -2518.16, 72.01),
			vector3d(-1029.75, -2518.18, 74.39),
			vector3d(-1029.03, -2510.36, 73.88),
			vector3d(-1039.32, -2510.22, 71.20),
			vector3d(-1049.14, -2510.04, 68.97),
			vector3d(-1059.00, -2509.86, 66.66),
			vector3d(-1068.76, -2510.12, 64.72),
			vector3d(-1069.64, -2501.96, 63.66),
			vector3d(-1059.53, -2502.36, 65.84),
			vector3d(-1049.59, -2501.95, 68.01),
			vector3d(-1039.64, -2501.77, 70.21),
			vector3d(-1029.74, -2502.12, 72.98),
			vector3d(-1028.74, -2494.20, 72.40),
			vector3d(-1038.99, -2493.81, 69.65),
			vector3d(-1048.68, -2493.83, 67.34),
			vector3d(-1058.79, -2494.16, 65.06),
			vector3d(-1069.12, -2494.23, 62.92),
			vector3d(-1069.15, -2486.16, 62.05),
			vector3d(-1059.60, -2485.92, 64.04),
			vector3d(-1050.01, -2485.83, 66.18),
			vector3d(-1040.18, -2486.09, 68.55),
			vector3d(-1029.65, -2486.31, 71.56),
			vector3d(-1028.87, -2478.54, 70.87),
			vector3d(-1038.86, -2478.69, 68.22),
			vector3d(-1049.38, -2478.61, 65.78),
			vector3d(-1058.66, -2478.53, 63.50),
		}
	},
	[4] = {
		main = vector3d(-1045, -2577, 79),
		ambar = vector3d(-1033.95, -2573.54, 80.67),
		water = vector3d(-1014.79, -2567.87, 82.19),
		corners = {
			vector3d(-1079.6032714844, -2567.4880371094, 72.828239440918),
			vector3d(-994.09826660156, -2522.8913574219, 85.263885498047)
		},
		beds = {
			vector3d(-1058.89, -2528.25, 68.75),
			vector3d(-1058.61, -2535.09, 69.44),
			vector3d(-1059.07, -2542.71, 70.23),
			vector3d(-1059.17, -2551.65, 71.90),
			vector3d(-1059.25, -2559.13, 73.45),
			vector3d(-1049.54, -2560.17, 75.85),
			vector3d(-1049.40, -2552.04, 74.15),
			vector3d(-1049.50, -2544.11, 72.69),
			vector3d(-1049.61, -2536.06, 71.78),
			vector3d(-1048.96, -2528.17, 71.01),
			vector3d(-1039.21, -2527.45, 73.12),
			vector3d(-1038.49, -2535.10, 73.98),
			vector3d(-1039.20, -2544.54, 75.11),
			vector3d(-1039.57, -2551.69, 76.37),
			vector3d(-1039.28, -2559.32, 77.93),
			vector3d(-1029.30, -2560.14, 79.42),
			vector3d(-1029.01, -2552.13, 78.11),
			vector3d(-1029.18, -2544.40, 77.30),
			vector3d(-1029.32, -2536.02, 76.27),
			vector3d(-1029.13, -2528.23, 75.56),
			vector3d(-1019.67, -2526.83, 77.65),
			vector3d(-1019.24, -2535.20, 78.61),
			vector3d(-1019.18, -2543.32, 79.43),
			vector3d(-1019.19, -2551.96, 80.22),
			vector3d(-1009.27, -2551.66, 82.72),
			vector3d(-1009.68, -2544.17, 81.87),
			vector3d(-1009.43, -2535.92, 81.29),
			vector3d(-1009.14, -2528.18, 81.00),
			vector3d(-998.98, -2526.82, 84.08),
			vector3d(-998.65, -2534.84, 84.57),
			vector3d(-999.02, -2542.79, 84.88),
		}
	},
	[5] = {
		main = vector3d(-495, -1590, 6), 
		ambar = vector3d(-495.77, -1614.30, 6.76), 
		water = vector3d(-472.63, -1585.81, 8.69),
		corners = {
			vector3d(-462.91900634766, -1667.6383056641, 11.071342468262),
			vector3d(-384.56832885742, -1565.8736572266, 21.964479446411)
		},
		beds = {
			vector3d(-450.02, -1582.85, 14.29),
			vector3d(-440.03, -1583.47, 16.75),
			vector3d(-429.71, -1583.17, 18.93),
			vector3d(-428.73, -1590.22, 18.86),
			vector3d(-438.53, -1590.98, 16.76),
			vector3d(-448.92, -1591.47, 13.99),
			vector3d(-459.43, -1599.00, 10.75),
			vector3d(-449.35, -1599.15, 13.36),
			vector3d(-439.68, -1599.14, 16.00),
			vector3d(-430.10, -1599.20, 18.19),
			vector3d(-429.03, -1607.43, 18.18),
			vector3d(-438.75, -1608.34, 15.55),
			vector3d(-448.86, -1608.66, 12.85),
			vector3d(-458.72, -1608.29, 10.32),
			vector3d(-459.05, -1615.77, 9.97),
			vector3d(-449.18, -1616.18, 12.45),
			vector3d(-439.79, -1616.52, 14.78),
			vector3d(-428.93, -1616.31, 17.66),
			vector3d(-429.52, -1624.49, 17.04),
			vector3d(-439.37, -1624.17, 14.56),
			vector3d(-448.59, -1624.54, 12.08),
			vector3d(-458.14, -1624.76, 9.66),
			vector3d(-459.20, -1631.94, 9.36),
			vector3d(-449.09, -1632.21, 11.70),
			vector3d(-438.13, -1632.54, 14.33),
			vector3d(-429.39, -1632.36, 16.58),
			vector3d(-429.54, -1640.25, 16.04),
			vector3d(-439.07, -1640.45, 13.64),
			vector3d(-447.76, -1640.48, 11.59),
			vector3d(-447.31, -1647.80, 11.50),
		}
	}
}


-- #meowprd
function loadAnswers()
	local file = getPath("settings\\farm_answers.json")
	
	if not fileExists(file) then
		local f = io.open(file, "w")
		if f then
			local t = { ["Âîïðîñ"] = { "Îòâåò1", "Îòâåò2" } }
			f:write(json.encode(t))
			f:close()
		else
			print("Error create farm_answers.json")
			print(select(2, io.open(file, "w")))
			return {}
		end
	end

	local f = io.open(file, "r")
	if f then
		local loaded = json.decode(f:read("*a"))
		local count = 0
		for _, _ in pairs(loaded) do count = count + 1 end
		print(string.format("Çàãðóæåíî %d îòâåòîâ", count))
		return loaded
	else
		print("Error open farm_answers.json")
		print(select(2, io.open(file, "r")))
		return {}
	end
	return {}
end

function getAnswer(q)
	local function lower(s)
		for i = 192, 223 do s = s:gsub(string.char(i), string.char(i + 32)) end
		s = s:gsub(string.char(168), string.char(184))
		return string.lower(s)
	end

	local q = lower(q)
	for k, v in pairs(aq) do
		if q:find(lower(k)) then return true, v end
	end
	return false, {}
end

function sendAnswer(admin, answ)
	pause()
	local res, o = getAnswer(answ)
	print(string.format("Àäìèí %s çàäàë âîïðîñ %s | îòâåòû %s - %d", admin, answ, (res and "íàéäåíû" or "íå íàéäåíû"), #o))
	reconnect()
	newTask(function()
		wait(random(1500, 6000))
		runCommand("!diagsend 0 -1 0")
		wait(random(2000, 8000))
		if o and #o > 0 then
			local use = o[math.random(1, #o)]
			print(string.format("Îòïðàâëÿþ îòâåò íà âîïðîñ: %s", use))
			sendInput(use)
		else
			print("Íå íàéäåíû îòâåòû íà âîïðîñ!")
			reconnect(timeout)
			local answers = loadDoubleAnswers()
			math.randomseed(os.clock())
			local use = answers[math.random(1, #answers)]
			print(string.format("Îòïðàâëÿþ îòâåò íà âîïðîñ: %s", use))
			sendInput(use)
		end
	end)
	sendTelegram(string.format("Äîëáîåá %s çàäàë âîïðîñ %s | îòâåòû %s", admin, answ, (res and "íàéäåíû" or "íå íàéäåíû")))
end

function sendMessageToChat(message)
    print("Sending message to chat:", message)
end

function loadDoubleAnswers()
    local file = getPath("settings\\farm_res_answers.json")
    local json = require("json")

    local function fileExists(filename)
        local f = io.open(filename, "r")
        if f then
            f:close()
            return true
        else
            return false
        end
    end

    local file = "farm_res_answers.json"

    if not fileExists(file) then
        local f = io.open(file, "w")
        if f then
            local t = {
                "ÿ òóò"
            }
            f:write(json.encode(t))
            f:close()
            print("Created empty farm_res_answers.json")
            return t
        else
            print("Error create farm_res_answers.json")
            print(select(2, io.open(file, "w")))
            return {}
        end
    end

    local f = io.open(file, "r")
    if f then
        local loaded = json.decode(f:read("*a"))
        print(string.format("Çàãðóæåíî %d îòâåòîâ (reserve)", #loaded))
        return loaded
    else
        print("Error open farm_answers.json")
        print(select(2, io.open(file, "r")))
        return {}
    end
end

loadDoubleAnswers() 

function newAcc()
	if not nicks_initied then
		setBotNick("")
		print("èìåíà è/èëè ôàìèëèè íå çàãðóæåíû. íåâîçìîæíî ñãåíåíèðîâàòü íèê")
		no_connect = true
		return false
	end
	tkan = 0
	badnickick = 0
	local new_nick
	repeat
		new_nick = names[random(1, #names)].."_"..surnames[random(1, #surnames)]
	until new_nick:len() <= 24 -- samp limit
	setBotNick(new_nick)
	setLogPath(getPath("logs\\"..new_nick.."-"..servers[getServerAddress()].name..".log"))

	if isBotConnected() then reconnect() end
end
