local discordia = require('discordia')
local Client = discordia.Client()
local json = require ("json")
local http = require('http')
local timer = require('timer')
local sleep = timer.sleep
local querystring = require('querystring')
--local utf8 = require("utf8")
--print(utf8)
--TODO при сохранении данных добавить еще вначале айди сервера, чтобы бот был мультисерверным


--package.path = package.path .. "C:\\Same\\DiscordBot\\lua_modules\\?.lua;"
--package.cpath = package.cpath.."C:\\Same\\DiscordBot\\lua_modules\\?.dll;"
--print(package.path) -- where .lua files are searched for
--print(package.cpath)
--local socket require("socket")

local BotSettings = {
	['Token'] = "Bot".."your token";
	['Prefix'] = ";";
}

local BIGRUS = {"А","Б","В","Г","Д","Е","Ё","Ж","З","И","Й","К","Л","М","Н","О","П","Р","С","Т","У","Ф","Х","Ц","Ч","Ш","Щ","Ъ","Ы","Ь","Э","Ю","Я"}
local smallrus = {"а","б","в","г","д","е","ё","ж","з","и","й","к","л","м","н","о","п","р","с","т","у","ф","х","ц","ч","ш","щ","ъ","ы","ь","э","ю","я"}
local BIG_to_small = {}
for k, v in next, BIGRUS do
   
	BIG_to_small[v] = smallrus[k]
   
end
function bigrustosmall(str)
   
	local strlow = ""
   
	for v in string.gmatch(str, "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*") do
		strlow = strlow .. (BIG_to_small[v] or v)
	end
   
	return string.lower(strlow) --жтобы англ буквы тоже занижалис
   
end

function stringfind(where, what, lowerr, startpos, endpos)
	local Exeption = false
	if not where or not what then --[[print("[STRINGFIND EXEPTION] cant find required arguments")]] return false end
	if type(where) ~= "string" or type(what) ~= "string" then --[[print("[STRINGFIND EXEPTION] not string")]] return false
	elseif string.len(what) > string.len(where) then --[[print("[STRINGFIND EXEPTION] string what you want to find bigger than string where you want to find it")]] Exeption = true 
	end
	if startpos and type(startpos) ~= "number" then startpos = tonumber(startpos) end
	if endpos and type(endpos) ~= "number" then endpos = tonumber(endpos) end
	local strlen1 = string.len(where)
	local strlen2 = string.len(what)
	if not startpos or startpos == 0 then startpos = 1 end
	if startpos < 1 then startpos = strlen1 + startpos + 1 end
	if not endpos or endpos == 0 then endpos = strlen1 end
	if endpos < 1 then endpos = strlen1 + endpos + 1 end
	if endpos > strlen1 then --[[print("[STRINGFIND EXEPTION] end position bigger then source string (source string size = "..#where..")")]] Exeption = true end
	if endpos < startpos then --[[print("[STRINGFIND EXEPTION] end position smaller then start position")]] Exeption = true end
	if startpos > strlen1 - strlen2 + 1 then --[[print("[STRINGFIND EXEPTION] string from your start position smaller then string what you want to find")]] Exeption = true end
	if endpos - startpos + 1 < strlen2 then --[[print("[STRINGFIND EXEPTION] section for finding smaller than string what you want to find")]] Exeption = true end
	if Exeption then return false end
	if lowerr then 
		where = bigrustosmall(where)
		what = bigrustosmall(what)
	end
	for i = startpos, endpos do
		if i + strlen2 - 1 > endpos then return false
		elseif string.sub(where, i, i + strlen2 - 1) == what then return i
		end
	end
	return false
end

--TODO не занижать чат-триггеры
--TODO приветственные сообщения
--TODO коины. +за удержание в топе, -за удаление сообщений
--TODO если в сообщении перед сообщением бота было упоминание, то его тоже надо вычесть
--TODO если написал бот, то брать не последнее сообщение, а искать сообщение перед ботом
--TODO повторять триггер, если фраза в чате есть несколько раз
--TODO бот вылетает при вызове команды в личных сообщениях
--TODO отправление ботом сообщения в канал по id через личные сообщения
--TODO изменение статы при редактировании?

local function filewrite(file,data)
	local f = io.open(file,"w")
	if not f then return end
	f:write(data)
	f:close()
end

local function fileread(file)
	local f = io.open(file,"r")
	if not f then return end
	local data = f:read()
	f:close()
	return data
end

local function PrintTable(tbl,sdvig)
	if not sdvig then sdvig = "" end
	for k,v in pairs(tbl) do
		print(sdvig..tostring(k)..":",v)
		if type(v) == "table" then PrintTable(v,sdvig.."	") end
	end
end 

local function TableCount(tbl)
	if type(tbl) ~= "table" then return 0 end
	local i = 0
	for k,v in pairs(tbl) do
		i = i + 1
	end
	return i
end

local WatNeedToSend = {}

local function CheckWatNeedToSend()
	for k,v in pairs(WatNeedToSend) do
		v[1]:send(v[2])
		WatNeedToSend[k] = nil
	end
end

local function HTTPGET(ip,path,port,OnResponse,OnError)
	local options = {
	  host = ip,
	  port = port or 80,
	  path = path
	}
	local req = http.request(options, function (res)
		local chunk1 = ""
		--local error = ""
		res:on('data', function(chunk) chunk1 = chunk1..chunk end)
		--[[res:on("error",function(e) 			--?????
			error = "\nproblem"..e.message
			print(error)
		end)]]
		res:on("end",function() 
			if res.statusCode == 200 then
				OnResponse(chunk1) 
			else
				OnError(res.statusCode--[[..error]])
			end
		end)
	end)
	req:done()
end

local WebServerIP = "your web-server ip"

local BansTBL = {}
local RanksTBL = {}

local function GetRanksBansFromWebServer()
	HTTPGET(
		WebServerIP,
		"/metrostroi/sync/ranks/",
		nil,
		function(body)  
			RanksTBL = json.decode(body)
		end,
		function(error)
			print("HTTP ERROR "..error)
		end
	)
	
	HTTPGET(
		WebServerIP,
		"/metrostroi/sync/ranks/bans/",
		nil,
		function(body)  
			BansTBL = json.decode(body)
		end,
		function(error)
			print("HTTP ERROR "..error)
		end
	)
end
GetRanksBansFromWebServer()

local function CheckRank(message,steamid)
	GetRanksBansFromWebServer()
	sleep(1000)
	if not steamid or steamid == "" then return end
	HTTPGET(
		WebServerIP,
		"/metrostroi/sync/ranks/?SteamID="..steamid,
		nil,
		function(body)  
			if not body or body == "" then table.insert(WatNeedToSend,1,{message.channel,"ничего не найдено"}) return end
			local tbl = json.decode(body)
			if not tbl or TableCount(tbl) < 1 then table.insert(WatNeedToSend,1,{message.channel,"ничего не найдено"}) return end
			table.insert(WatNeedToSend,1,{message.channel,"Информация о "..steamid..". Последний ник на сервере: "..tbl.Nick..". Ранг: "..tbl.Rank})
		end,
		function(error)
			table.insert(WatNeedToSend,1,{message.channel,"HTTP ERROR "..error})
		end
	)
end

local function CheckBan(message,steamid)
	GetRanksBansFromWebServer()
	sleep(1000)
	if not steamid or steamid == "" then return end
	HTTPGET(
		WebServerIP,
		"/metrostroi/sync/ranks/bans/?SteamID="..steamid,
		nil,
		function(body)  
			if not body or body == "" then table.insert(WatNeedToSend,1,{message.channel,"ничего не найдено"}) return end
			local tbl = json.decode(body)
			if not tbl or TableCount(tbl) < 1 then table.insert(WatNeedToSend,1,{message.channel,"ничего не найдено"}) return end
			table.insert(WatNeedToSend,1,{message.channel,"Информация о "..steamid..".\nНик при бане: "..tbl.Nick..".\nПричина: "..tbl.Reason..".\nЗабанил: "..tbl.WhoBanned..", его SteamID: "..tbl.WhoBannedID..".\nДата бана: "..os.date("%H:%M:%S %d/%m/%Y",tbl.BanDate)..".\nДата разбана: "..(tbl.UnBanDate ~= "perma" and os.date("%H:%M:%S %d/%m/%Y",tbl.UnBanDate) or "никогда")..(tbl.UnBanDate ~= "perma" and ".\nДо разбана осталось "..math.floor((tbl.UnBanDate - os.time()) / 60).." мин." or "")})
		end,
		function(error)
			table.insert(WatNeedToSend,1,{message.channel,"HTTP ERROR "..error})
		end
	)
end

local function TableToXWwwFormUrlencoded(tbl)
	local str = ""
	str = querystring.stringify(tbl)
	--print(str)
	--[[for k,v in pairs(tbl) do
		if str == "" then 
			str = k.."="..v
		else
			str = str.."&"..k.."="..v
		end
	end]]
	return str
end

local function HTTPPOST(ip,path,port,data,OnResponse,OnError)
	if not data then return end
	if type(data) == "table" then data = TableToXWwwFormUrlencoded(data) end
	--print(data)
	local options = {
	  host = ip,
	  port = port or 80,
	  path = path,
	  method = 'POST',
	  headers = {}
	}
	options.headers["content-type"] = "application/x-www-form-urlencoded; charset=utf8"				-- оно работает?
	options.headers["content-length"] = #data
	--options.headers["transfer-encoding"] = "utf8"
	local req = http.request(options, function(res)
		--res:on('data', function(chunk) print(chunk) end)
		res:on("error",function(e)print(e.message)end)
		--[[res:on("end",function(asd) 					-- не работает
			print("asdasdasdasdasdsadsadas")
			if res.statusCode ~= 200 then
				OnError(res.statusCode)--..error)
			else
				print("asd")
				OnResponse()
			end
		end)]]
	end)
	req:write(data)
	req:done()
end

local function SetRank(message,data)
	GetRanksBansFromWebServer()
	sleep(1000)
	if not data or data == "" then table.insert(WatNeedToSend,1,{message.channel,"Неверный SteamID."}) return end
	local start = string.find(data," ")
	if not start then table.insert(WatNeedToSend,1,{message.channel,"Не указана роль."}) return end
	local strsub1 = string.sub(data,1,start - 1)
	if not strsub1:find("STEAM_") then table.insert(WatNeedToSend,1,{message.channel,"Неверный SteamID."}) return end
	local strsub2 = string.sub(data,start + 1)
	if strsub2 ~= "operator" and strsub2 ~= "admin" and strsub2 ~= "user" and strsub2 ~= "tsar" and strsub2 ~= "zamtsar" and strsub2 ~= "superadmin" then message.channel:send("Нельзя установить такую роль.") return end
	HTTPPOST(
		WebServerIP,
		"/metrostroi/sync/ranks/",
		nil,
		{SteamID = strsub1,Rank = strsub2,Nick = RanksTBL and RanksTBL[strsub1] and RanksTBL[strsub1].Nick or "Unknown"}--,
		--function() table.insert(WatNeedToSend,1,{message.channel,"Игроку "..strsub1.." установлен ранг "..strsub2}) end,
		--function(error) table.insert(WatNeedToSend,1,{message.channel,"HTTP ERROR "..error}) end
	)
end

local RanksTBL2 = {}

local function GetRanksBansFromWebServer2()
	HTTPGET(
		WebServerIP,
		"/metrostroi/sync/ranksmetadmin/",
		nil,
		function(body)  
			RanksTBL2 = json.decode(body)
		end,
		function(error)
			print("HTTP ERROR "..error)
		end
	)
end
GetRanksBansFromWebServer2()

local function SetRank2(message,data)
	GetRanksBansFromWebServer2()
	sleep(1000)
	if not data or data == "" then table.insert(WatNeedToSend,1,{message.channel,"Неверный SteamID."}) return end
	local start = string.find(data," ")
	if not start then table.insert(WatNeedToSend,1,{message.channel,"Не указана длительность."}) return end
	local strsub1 = string.sub(data,1,start - 1)
	if not strsub1:find("STEAM_") then table.insert(WatNeedToSend,1,{message.channel,"Неверный SteamID."}) return end
	local start2 = string.find(data," ",start + 1)
	local strsub2 = string.sub(data,start + 1,start2 and start2 - 1)
	--if not tonumber(strsub2) then table.insert(WatNeedToSend,1,{message.channel,"Неправильный формат длительности."}) return end
	if strsub2 == "0" then strsub2 = "perma" end
	local strsub3 = not start2 and "console" or string.sub(data,start2 + 1)
	--if strsub2 ~= "operator" and strsub2 ~= "admin" and strsub2 ~= "user" and strsub2 ~= "tsar" and strsub2 ~= "zamtsar" and strsub2 ~= "superadmin" then message.channel:send("Нельзя установить такую роль.") return end
	HTTPPOST(
		WebServerIP,
		"/metrostroi/sync/ranksmetadmin/",
		nil,
		{SteamID = strsub1,Rank = strsub2,Nick = RanksTBL2 and RanksTBL2[strsub1] and RanksTBL2[strsub1].Nick or "Unknown",Reason = strsub3}--,
		--function() table.insert(WatNeedToSend,1,{message.channel,"Игроку "..strsub1.." установлен ранг "..strsub2}) end,
		--function(error) table.insert(WatNeedToSend,1,{message.channel,"HTTP ERROR "..error}) end
	)
end

local function CheckRank2(message,steamid)
	GetRanksBansFromWebServer2()
	sleep(1000)
	if not steamid or steamid == "" then return end
	HTTPGET(
		WebServerIP,
		"/metrostroi/sync/ranksmetadmin/?SteamID="..steamid,
		nil,
		function(body)  
			if not body or body == "" then table.insert(WatNeedToSend,1,{message.channel,"ничего не найдено"}) return end
			local tbl = json.decode(body)
			if not tbl or TableCount(tbl) < 1 then table.insert(WatNeedToSend,1,{message.channel,"ничего не найдено"}) return end
			table.insert(WatNeedToSend,1,{message.channel,"Информация о "..steamid..". Последний ник на сервере: "..tbl.Nick..". Ранг: "..tbl.Rank..(tbl.Reason and ". Причина: "..tbl.Reason.."." or ".")})
		end,
		function(error)
			table.insert(WatNeedToSend,1,{message.channel,"HTTP ERROR "..error})
		end
	)
end

local function SetBan(message,data)
	GetRanksBansFromWebServer()
	sleep(1000)
	if not data or data == "" then table.insert(WatNeedToSend,1,{message.channel,"Неверный SteamID."}) return end
	local start = string.find(data," ")
	if not start then table.insert(WatNeedToSend,1,{message.channel,"Не указана длительность."}) return end
	local strsub1 = string.sub(data,1,start - 1)
	if not strsub1:find("STEAM_") then table.insert(WatNeedToSend,1,{message.channel,"Неверный SteamID."}) return end
	local start2 = string.find(data," ",start + 1)
	local strsub2 = string.sub(data,start + 1,start2 and start2 - 1)
	if not tonumber(strsub2) then table.insert(WatNeedToSend,1,{message.channel,"Неправильный формат длительности."}) return end
	if strsub2 == "0" then strsub2 = "perma" end
	local strsub3 = not start2 and "без причины" or string.sub(data,start2 + 1)
	HTTPPOST(
		WebServerIP,
		"/metrostroi/sync/ranks/bans/",
		nil,
		{SteamID = strsub1,Reason = strsub3,Nick = RanksTBL and RanksTBL[strsub1] and RanksTBL[strsub1].Nick or "Unknown",WhoBannedID = "Discord",WhoBanned = message.author.name.."("..message.author.mentionString..")",Duration = strsub2}--,
		--function() table.insert(WatNeedToSend,1,{message.channel,"Игроку "..strsub1.." установлен ранг "..strsub2}) end,
		--function(error) table.insert(WatNeedToSend,1,{message.channel,"HTTP ERROR "..error}) end
	)
end

local function Unban(message,data)
	GetRanksBansFromWebServer()
	sleep(1000)
	if not data or data == "" or not data:find("STEAM_") then table.insert(WatNeedToSend,1,{message.channel,"Неверный SteamID."}) return end
	HTTPPOST(
		WebServerIP,
		"/metrostroi/sync/ranks/bans/",
		nil,
		{SteamID = data,Unbanned = "unbanned"}--,
		--function() table.insert(WatNeedToSend,1,{message.channel,"Игроку "..strsub1.." установлен ранг "..strsub2}) end,
		--function(error) table.insert(WatNeedToSend,1,{message.channel,"HTTP ERROR "..error}) end
	)
end


local function Send(channel,data)
	local pos = 1000
	if #data >= 2000 then
		::hmm::
		local Start,End,String = string.find(data,"\n",pos)											-- разрезает стринг по ентеру, но не по двойному ентеру
		if string.sub(data,Start - 1,Start + 1):find("\n\n") then pos = pos + 2 goto hmm end
		if Start then 
			channel:send(string.sub(data,1,Start - 1)) 
			Send(channel,string.sub(data,Start)) 
		else
			Start,End,String = string.find(data,". ",1000)					-- разрезает по концу предложения
			if Start then 
				channel:send(string.sub(data,1,Start)) 
				Send(channel,string.sub(data,Start + 2))
			else
				Start,End,String = string.find(data,": ",1000)					-- разрезает по двоеточию с пробелом
				if Start then 
					channel:send(string.sub(data,1,Start)) 
					Send(channel,string.sub(data,Start + 2))
				else
					Start,End,String = string.find(data,":",1000)					-- разрезает по двоеточию
					if Start then 
						channel:send(string.sub(data,1,Start)) 
						Send(channel,string.sub(data,Start + 1))
					else
						Start,End,String = string.find(data," ",1000)				-- разрезает стринг по пробелу
						if Start then 
							channel:send(string.sub(data,1,Start - 1)) 
							Send(channel,string.sub(data,Start + 1))
						end
					end
				end
			end
		end
	else
		channel:send(data)
	end
end

local function GetTop(channeltbl,value,all,nofield)
	local top = 1
	if all then all = "all" else all = "notall" end
	if not nofield then
		for k,v in pairs(channeltbl) do
			if v[all] and v[all] > value then top = top + 1 end
		end
	else 
		for k,v in pairs(channeltbl) do
			if v > value then top = top + 1 end
		end
	end
	return top
end

local MsgStats = fileread("C:\\Same\\DiscordBot\\MsgStats.txt") and json.decode(fileread("C:\\Same\\DiscordBot\\MsgStats.txt")) or {}
local LastMsg = fileread("O:\\LastMsg.txt") and json.decode(fileread("O:\\LastMsg.txt")) or {}	-- channel, msg, user

local function GenerateChatUsersTbl()
	local usertstbl = {}
	for k,v in pairs(MsgStats) do
		for k1,v1 in pairs(v) do
			if not usertstbl[k1] then usertstbl[k1] = {} end
			if not usertstbl[k1]["all"] then usertstbl[k1]["all"] = 0 end
			if not usertstbl[k1]["notall"] then usertstbl[k1]["notall"] = 0 end
			if v1["all"] then usertstbl[k1]["all"] = usertstbl[k1]["all"] + v1["all"] end
			if v1["notall"] then usertstbl[k1]["notall"] = usertstbl[k1]["notall"] + v1["notall"] end
		end
	end
	return usertstbl
end

local function MsgsByUserEverywhere(usermentionstring)
	local usertstbl = GenerateChatUsersTbl()
	
	local topall = GetTop(usertstbl,usertstbl[usermentionstring]["all"],true)
	local topNotall = GetTop(usertstbl,usertstbl[usermentionstring]["notall"])
	local AllChatters = TableCount(usertstbl)
	return usertstbl[usermentionstring]["all"], usertstbl[usermentionstring]["notall"], topall, topNotall, AllChatters
end

local mentionedUsers = fileread("C:\\Same\\DiscordBot\\mentionedUsers.txt") and json.decode(fileread("C:\\Same\\DiscordBot\\mentionedUsers.txt")) or {}

local function GenerateMentionsUsersTbl()
	local mentionsuserstbl = {}
	for k,v in pairs(mentionedUsers) do
		for k1,v1 in pairs(v) do
			if not mentionsuserstbl[k1] then mentionsuserstbl[k1] = v1 else mentionsuserstbl[k1] = mentionsuserstbl[k1] + v1 end
		end
	end
	return mentionsuserstbl
end

local function GetStat(message,usermentionstring)
	local FirstMessagePrinted = false
	local str = ""
	if not usermentionstring:find("%d") then usermentionstring = message.author.mentionString end
	usermentionstring = string.gsub(usermentionstring,"!","")
	for k,v in pairs(MsgStats) do
		local TblSize = TableCount(v)
		for k1,v1 in pairs(v) do
			if usermentionstring:find(k1) then
				if not FirstMessagePrinted then
					--message.channel:send("Информация об игроке "..k1)
					str = str.."Информация об игроке "..k1
					FirstMessagePrinted = true
				end
				str = str.."\nКанал "..k..":\n"
				for k2,v2 in pairs(v1) do
					if k2 == "all" then
						--message.channel:send("Канал: "..k..". Сообщений всего: "..v2..". Топ "..GetTop(v,v2,all).."/"..TblSize)
						str = str.."Сообщений всего: "..v2..". Топ "..GetTop(v,v2,true).."/"..TblSize.."\n"
					else
						--message.channel:send("Канал: "..k..". Сообщений не подряд: "..v2..". Топ "..GetTop(v,v2).."/"..TblSize)
						str = str.."Сообщений не подряд: "..v2..". Топ "..GetTop(v,v2).."/"..TblSize.."\n"
					end
				end
				--filewrite("C:\\Same\\DiscordBot\\test.txt",json.encode(mentionedUsers))
				if mentionedUsers[k] then
					local mentionedN = mentionedUsers[k][k1] or 0
					local top = mentionedUsers[k][k1] and GetTop(mentionedUsers[k],mentionedN,nil,true) or 0
					str = str.."Упоминаний: "..mentionedN..". Топ "..top.."/"..TableCount(mentionedUsers[k]).."\n"
				else
					str = str.."Упоминаний: 0. Топ 0/0\n"
				end
			end
		end
	end
	if not FirstMessagePrinted or str == "" then 
		message.channel:send("Информация о "..usermentionstring.." отсутствует.") 
	else
		local AllMsgsAll, AllMsgsNotAll, TopAll, TopNotAll, AllChatters = MsgsByUserEverywhere(usermentionstring)
		str = str.."\nСообщений всего: "..AllMsgsAll..". Топ "..TopAll.."/"..AllChatters.."\nСообщений всего не подряд: "..AllMsgsNotAll..". Топ "..TopNotAll.."/"..AllChatters.."\n"
		local mentionsusers = GenerateMentionsUsersTbl()
		local mentionsN = mentionsusers[usermentionstring] or 0
		--filewrite("C:\\Same\\DiscordBot\\test.txt",mentionsusers[usermentionstring])
		local top = mentionsusers[usermentionstring] and GetTop(mentionsusers,mentionsN,nil,true) or 0
		str = str.."Упоминаний всего: "..mentionsN..". Топ "..top.."/"..TableCount(mentionsusers)
		Send(message.channel,str)
	end
end

local function EndingRussian(value)
	local strsub = string.sub(value,-1)
	local strsub10 = string.len(value) > 1 and string.sub(value,-2,-2) or "2"
	if strsub10 ~= "1" then
		if strsub == "1" then 
			return "у"
		elseif strsub == "2" or strsub == "3" or strsub == "4" then 
			return "ы"
		else 
			return ""
		end
	else 
		return ""
	end
end

local function Ban(message,b)
	message.channel:send("А может ты?")
end

local function FindDeepInTable(tbl,value)
	for k,v in pairs(tbl) do
		if type(v) ~= "table" then 
			if v == value then return true end
		else
			return FindDeepInTable(v,value)
		end
	end
	return false
end

local function FindInTable(tbl,value)
	for k,v in pairs(tbl) do
		if v == value then return k end
	end
	return false
end

--TODO получить стимайди из профиля юзера

local function ConvertDataToTwoArgs(data)
	if string.sub(data,1,2) ~= "[[" then return nil end
	if not string.sub(data,4):find("]]") then return nil end
	local Start,End,String = data:find("]]")
	local arg1 = string.sub(data,3,Start - 1)
	
	data = string.sub(data, End + 2)
	local arg2
	if string.sub(data,1,2) ~= "[[" then arg2 = nil end
	if not string.sub(data,4):find("]]") then arg2 = nil end
	local arg2 = string.sub(data,3,-3)
	
	if arg2 == "" then arg2 = nil end
	if arg1 == "" then arg1 = nil end
	return arg1,arg2
end

local TriggersPrintTbl = fileread("C:\\Same\\DiscordBot\\TriggersPrintTbl.txt") and json.decode(fileread("C:\\Same\\DiscordBot\\TriggersPrintTbl.txt")) or {}

local function AddChatTrigger(message,data)
	local arg1,arg2 = ConvertDataToTwoArgs(data)
	if not arg1 or not arg2 then 
		message.channel:send('Команда введена некорректно. Пример: `!добавить чат-триггер [[сергей]] [[лох]]`.')
		return
	end
	arg1 = bigrustosmall(arg1)
	arg2 = bigrustosmall(arg2)
	if TriggersPrintTbl[arg1] and FindInTable(TriggersPrintTbl[arg1],arg2) then message.channel:send("Данный триггер уже существует.") end
	if not TriggersPrintTbl[arg1] then TriggersPrintTbl[arg1] = {} end
	table.insert(TriggersPrintTbl[arg1],1,arg2)
	filewrite("C:\\Same\\DiscordBot\\TriggersPrintTbl.txt",json.encode(TriggersPrintTbl))
	message.channel:send("Чат-триггер успешно добавлен.")
end

local function NormirTable(tbl)
	local TblSize = TableCount(tbl)
	for k,v in pairs(tbl) do
		if v == "" then 
			if k ~= TblSize then 
				tbl[k] = tbl[TblSize] tbl[TblSize] = nil
			else 
				tbl[TblSize] = nil
			end
		end
	end
end

local function RemoveChatTrigger(message,data)
	arg1,arg2 = ConvertDataToTwoArgs(data)
	if not arg1 then message.channel:send('Команда введена некорректно. Приер: `!удалить чат-триггер [[сергей]]` или `!удалить чат-триггер [[сергей]] [[лох]]`.') return end
	if not TriggersPrintTbl[arg1] then message.channel:send("Данного чат-триггера не существует") return end
	if arg2 then
		local FounArg2 = FindInTable(TriggersPrintTbl[arg1],arg2)
		if not FounArg2 then 
			message.channel:send("Данного чат-триггера не существует.") 
			return
		else
			TriggersPrintTbl[arg1][FounArg2] = ""
			NormirTable(TriggersPrintTbl[arg1])
			filewrite("C:\\Same\\DiscordBot\\TriggersPrintTbl.txt",json.encode(TriggersPrintTbl))
			message.channel:send("Чат-триггер был успешно удален.")
		end
	else 
		TriggersPrintTbl[arg1] = nil
		filewrite("C:\\Same\\DiscordBot\\TriggersPrintTbl.txt",json.encode(TriggersPrintTbl))
		message.channel:send("Чат-триггеры были успешно удалены.") 
	end
end

local function ShowChatTriggers(message,a)
	local str = ""
	for k,v in pairs(TriggersPrintTbl) do
		str = str..'Триггеры на "'..k..'": '
		str = str..json.encode(v).."\n"
	end
	--str = str.."```"
	--message.channel:send(str)
	Send(message.channel,str)
end

local function ImGay(message,a)
	message.channel:send("Я пидорас конченый нахуй.")
end

local CommandsTbl = {}

local function ShowAllCommands(message,a)
	--PrintTable(CommandsTbl)
	--for k,v in pairs(CommandsTbl) do print(k) end
	local str = ""
	local TblSize = TableCount(CommandsTbl)
	local i = 0
	for k,v in pairs(CommandsTbl) do
		i = i + 1
		str = str..k..", "
	end
	message.channel:send("Список моих команд:\n"..string.sub(str,1,-3))
end

local function GetTopOne(tbl,all,nofield)
	if all then all = "all" else all = "notall" end
	--сначала ищу просто наибольший
	local maxvalue = 0
	local maxindex = nil
	if not nofield then
		for k,v in pairs(tbl) do
			if v[all] > maxvalue then maxvalue = v[all] maxindex = k end
		end
	else
		for k,v in pairs(tbl) do
			if v > maxvalue then maxvalue = v maxindex = k end
		end
	end
	
	--потом смотрю, нет ли еще с таким же количеством
	local maxtbl = {}
	maxtbl[1] = {maxindex, maxvalue}
	if not nofield then
		for k,v in pairs(tbl) do
			if k ~= maxindex then
				if v[all] == maxvalue then table.insert(maxtbl,1,{k,v[all]}) end
			end
		end
	else
		for k,v in pairs(tbl) do
			if k ~= maxindex then
				if v == maxvalue then table.insert(maxtbl,1,{k,v}) end
			end
		end
	end
	
	return maxtbl
end

local function GetAllMessagedAndMentionsCountInChannel(mentionString)
	local all = 0
	local notall = 0
	if MsgStats[mentionString] then
		for k,v in pairs(MsgStats[mentionString]) do
			if v["all"] then all = all + v["all"] end
			if v["notall"] then notall = notall + v["notall"] end
		end
	end
	
	local Mentions = 0
	if mentionedUsers[mentionString] then
		for k,v in pairs(mentionedUsers[mentionString]) do
			Mentions = Mentions + v
		end
	end
	
	return all,notall,Mentions
end

local function GetAllMessagedAndMentionsCount()
	local MsgCount = 0
	for k,v in pairs(MsgStats) do
		for k1,v1 in pairs(v) do
			if v1["all"] then MsgCount = MsgCount + v1["all"] end
		end
	end
	
	local MentionsCount = 0
	for k,v in pairs(mentionedUsers) do
		for k1,v1 in pairs(v) do
			MentionsCount = MentionsCount + v1
		end
	end
	
	return MsgCount,MentionsCount
end

local function TopChatters(message,a)
	local str = ""
	
	local MsgCount,MentionsCount = GetAllMessagedAndMentionsCount()
	
	str = "Всего сообщений "..MsgCount.."\nВсего упоминаний "..MentionsCount.."\n\n"
	
	--топ юзер всезде
	local userstbl = GenerateChatUsersTbl()
	local TopOneUserAll = GetTopOne(userstbl,true)
	local TopOneUserNotAll = GetTopOne(userstbl)

	str = str.."Человек, написавший больше всего сообщений:\n"
	for k,v in pairs(TopOneUserAll) do
		str = str..v[1].." - сообщений: "..v[2].."\n"
	end
	
	str = str.."Человек, написавший больше всего сообщений не подряд:\n"
	for k,v in pairs(TopOneUserNotAll) do
		str = str..v[1].." - сообщений: "..v[2].."\n"
	end
	
	str = str.."Человек, с наибольшем количеством упоминаний:\n"
	local mentionsusers = GenerateMentionsUsersTbl()
	local TopAllMentions = GetTopOne(mentionsusers,nil,true)
	for k,v in pairs(TopAllMentions) do
		str = str..v[1].." - упоминаний: "..v[2].."\n"
	end

	--tоп канал
	local chatstbl = {}
	for k,v in pairs(MsgStats) do
		if not chatstbl[k] then chatstbl[k] = {} end
		if not chatstbl[k]["all"] then chatstbl[k]["all"] = 0 end
		if not chatstbl[k]["notall"] then chatstbl[k]["notall"] = 0 end
		for k1,v1 in pairs(v) do
			if v1["all"] then chatstbl[k]["all"] = chatstbl[k]["all"] + v1["all"] end
			if v1["notall"] then chatstbl[k]["notall"] = chatstbl[k]["notall"] + v1["notall"] end
		end
	end
	
	local TopOneChatAll = GetTopOne(chatstbl, true)
	local TopOneChatNotAll = GetTopOne(chatstbl)
	--PrintTable(TopOneChatAll)
	--PrintTable(TopOneChatNotAll)
	str = str.."\nСамый популярный канал по всем сообщениям:\n"
	for k,v in pairs(TopOneChatAll) do
		str = str..v[1].." - сообщений: "..v[2].."\n"
	end
	
	str = str.."Самый популярный канал по сообщениям, написанным не подряд:\n"
	for k,v in pairs(TopOneChatNotAll) do
		str = str..v[1].." - сообщений: "..v[2].."\n"
	end
	
	local chatmenstionstbl = {}
	for k,v in pairs(mentionedUsers) do
		if not chatmenstionstbl[k] then chatmenstionstbl[k] = 0 end
		for k1,v1 in pairs(v) do
			chatmenstionstbl[k] = chatmenstionstbl[k] + v1
		end
	end
	local TopMentionsChat = GetTopOne(chatmenstionstbl,nil,true)
	str = str.."Канал, в котором больше всего упоминаний:\n"
	for k,v in pairs(TopMentionsChat) do
		str = str..v[1].." - упоминаний: "..v[2].."\n"
	end
	
	--топ юзер в каждом канале
	for k,v in pairs(MsgStats) do
		local TopOneInChannelAll = GetTopOne(v,true)
		local TopOneInChannelNotAll = GetTopOne(v)
		str = str.."\nКанал "..k..":\n"
		local all,notall,Mentions = GetAllMessagedAndMentionsCountInChannel(k)
		str = str.."Всего сообщений "..all.."\n"
		str = str.."Всего сообщений, написанных не подряд "..notall.."\n"
		str = str.."Всего упоминаний "..notall.."\n"
		str = str.."Человек, написавший больше всего сообщений:\n"
		for k1,v1 in pairs(TopOneInChannelAll) do
			str = str..v1[1].." - сообщений: "..v1[2].."\n"
		end
		str = str.."Человек, написавший больше всего сообщений не подряд:\n"
		for k1,v1 in pairs(TopOneInChannelNotAll) do
			str = str..v1[1].." - сообщений: "..v1[2].."\n"
		end
		
		local TopOneInChannelMentions = mentionedUsers[k] and GetTopOne(mentionedUsers[k],nil,true) or {}
		if TableCount(TopOneInChannelMentions) > 0 then
			local MentionsPrinted = false
			for k1,v1 in pairs(TopOneInChannelMentions) do
				if v1[1] and v1[2] then
					if not MentionsPrinted then str = str.."Человек, которого упоминали больше всего:\n" MentionsPrinted = true end
					str = str..v1[1].." - упоминаний: "..v1[2].."\n"
				end
			end
		end
	end
	Send(message.channel,str)
	--message.channel:send(str)
end

local function GetUserByMentionString(str)		-- не используется TODO
	local users = Client.users:toArray()
	for k,v in pairs(users) do
		local user = getUser(v)
		if user.mentionString == str then return user end
	end
	return false
end

local function GetRole(message,data)
	--print(message.member.highestRole.id)
	--print(message.member.highestRole.name)
	local memb = message.member
	--[[if not data:find("%d") then		-- TODO роли выбранного игрока
		
	end]]
	local str = ""
	local roleIDs = memb.roles:toArray()
	for k,v in pairs(roleIDs) do 
		print(k,v)
		str = str..tostring(v)..": "..Client:getRole(v).name.."\n"
		--print(Client:getRole(v).name)
	end
	local mentionString = message.author.mentionString
	mentionString = string.gsub(mentionString,"!","")
	if str ~= "" then 
		str = "Роли игрока "..mentionString..": \n"..str 
		message.channel:send(str)
	else
		message.channel:send(mentionString..", у тебя нет ролей.")
	end
end

local function Date(message,a)
	message.channel:send("16е мая 2019го года")
end

local function CurChannel(message,data)
	message.channel:send(message.author.mentionString..", это канал `"..message.channel.mentionString.."`, ID: "..tostring(message.channel.id))
end

local JoiningMessages = fileread("C:\\Same\\DiscordBot\\JoiningMessages.txt") and json.decode(fileread("C:\\Same\\DiscordBot\\JoiningMessages.txt")) or {}

local function ShowJoiningMessages(message,a)
	local str = ""
	local JoiningMessagesN = TableCount(JoiningMessages)
	if JoiningMessagesN < 1 then message.channel:send("У меня в списке нет ни одного приветственного сообщения.") return end
	for k,v in pairs(JoiningMessages) do
		str = str..k..":\n"
		str = str..v.."\n\n"
	end
	Send(message.channel,str)
end

local function AddJoiningMessage(message,data)	--TODO
	
end

local function RemoveJoiningMessages(message,data)	--TODO
	
end

CommandsTbl["!стата"] = {GetStat,120}	-- command, function, cooldown	-- TODO , возможно кулдауны по ролям. Функция что-то возвращает при ошибке или отсутствии доступа
CommandsTbl["!бан"] = {SetBan,0,{"461651884906643457"}}	
CommandsTbl["!добавить чат-триггер"] = {AddChatTrigger,0,{"461651884906643457","578304137045737472","550388390982320128"}}	
CommandsTbl["!бот"] = {ImGay,120}	
CommandsTbl["!чат-триггеры"] = {ShowChatTriggers,120}	
CommandsTbl["!удалить чат-триггер"] = {RemoveChatTrigger,0,{"461651884906643457","578304137045737472","550388390982320128"}}	
CommandsTbl["!команды"] = {ShowAllCommands,120}	
CommandsTbl["!топ"] = {TopChatters,120}	
CommandsTbl["!роли"] = {GetRole,120}	
CommandsTbl["!дата"] = {Date,120}	
CommandsTbl["!канал"] = {CurChannel,0,{"461651884906643457"}}	
CommandsTbl["!приветственные сообщения"] = {ShowJoiningMessages,0,{"461651884906643457"}}	
CommandsTbl["!добавить приветственное сообщение"] = {AddJoiningMessage,0,{"461651884906643457"}}	--TODO
CommandsTbl["!удалить приветственное сообщение"] = {RemoveJoiningMessages,0,{"461651884906643457"}}	--TODO
CommandsTbl["!чекранг"] = {CheckRank,0}
CommandsTbl["!чекранг2"] = {CheckRank2,0}
CommandsTbl["!чекбан"] = {CheckBan,0}
CommandsTbl["!разбан"] = {Unban,0,{"461651884906643457"}}
CommandsTbl["!сетранг"] = {SetRank,0,{"461651884906643457"}}
CommandsTbl["!сетранг2"] = {SetRank2,0,{"461651884906643457"}}

local CommandUsed = {}	-- command, user, whenUsed
for k,v in pairs(CommandsTbl) do
	CommandUsed[k] = {}
end

local function MemberHasRole(member,tbl)
	for k,v in pairs(tbl) do
		if member:hasRole(v) then return true end
	end
	return false
end

Client:on('ready', function()
	local function Timer()
		--print("Timer")
		sleep(1 * 1000)
		CheckWatNeedToSend()
		Timer()
	end
	Timer()
end)

--[[Client:on('ready', function()		-- так можно делать сколько угодно таймеров
	local function Timer5()
		print("Timer5")
		sleep(5 * 1000)
		Timer5()
	end
	Timer5()
end)]]

Client:on('messageCreate', function(message)
	if message.author.mentionString == "<@514387864650514467>" then return end
	
	--print(#message.content)
	--print(message.author.name)
	--print(message.author.tag)
	--print(message.author.username)
	--print(message.author.mentionString)		--уникальный и не меняется при смене ника (возможно поменяется при перезаходе?)
	--print(message.author.avatarURL)
	--print(message.author.mutualGuilds)
	--print(string.sub(message.content,1,9))
	--print(message.channel)
	--print(message.channel.mentionString) -- для упоминания канала
	--print(message.channel.type) 		-- непонятно
	
	local user = message.author.mentionString
	local msg = message.content
	local channel = message.channel.mentionString
	
	if message.author.bot then
		if LastMsg[channel] then
			if MsgStats[channel] and MsgStats[channel][LastMsg[channel].user] and MsgStats[channel][LastMsg[channel].user]["all"] and type(MsgStats[channel][LastMsg[channel].user]["all"]) == "number" and MsgStats[channel][LastMsg[channel].user]["all"] > 0 then MsgStats[channel][LastMsg[channel].user]["all"] = MsgStats[channel][LastMsg[channel].user]["all"] - 1 end
			if LastMsg[channel].notall and MsgStats[channel] and MsgStats[channel][LastMsg[channel].user] and MsgStats[channel][LastMsg[channel].user]["notall"] and type(MsgStats[channel][LastMsg[channel].user]["notall"]) == "number" and MsgStats[channel][LastMsg[channel].user]["notall"] > 0 then MsgStats[channel][LastMsg[channel].user]["notall"] = MsgStats[channel][LastMsg[channel].user]["notall"] - 1 end
		end
	end
	
	if message.author.bot then return end
	local deleted = false
	local ItWasCommand = false
	
	--если человек пишет два идентичных сообщеняи подряд, то его второе сообщение удаляется
	if LastMsg[channel] then
		if LastMsg[channel].user == user and LastMsg[channel].msg == msg then 
			message:delete()
			deleted = true
		end
	end
	
	if deleted then return end
	
	local contentLower = bigrustosmall(message.content)
	
	for k,v in pairs(CommandsTbl) do
		if string.sub(contentLower,1,#k) == k then
			ItWasCommand = true
			if (v[3] and MemberHasRole(message.member,v[3])) or not v[3] then
				if (not CommandUsed[k][user] or os.time() - CommandUsed[k][user] >= v[2]) then
					CommandUsed[k][user] = os.time()
					local data = string.sub(message.content, #k + 2)
					v[1](message,data)
				else
					local timestamp = v[2] - (os.time() - CommandUsed[k][user])
					message.channel:send(user..", ты сможешь воспользоваться этой командой через "..timestamp.." секунд"..EndingRussian(timestamp)..".")
				end
			else 
				message.channel:send(user..", у тебя нет доступа к этой команде.")
			end
		end
	end
	
	if ItWasCommand then return end
	
	local mentionedUsersInMessage = message.mentionedUsers:toArray()
	if not mentionedUsers[channel] then mentionedUsers[channel] = {} end
	for k,v in pairs(mentionedUsersInMessage) do
		v = string.gsub(v.mentionString,"!","")
		if v ~= message.author.mentionString then
			if not mentionedUsers[channel][v] then mentionedUsers[channel][v] = 1 else mentionedUsers[channel][v] = mentionedUsers[channel][v] + 1 end
		end
	end
	
	for k,v in pairs(TriggersPrintTbl) do
		if contentLower:find(k) then 
			local TblSize = TableCount(v)
			message.channel:send(v[math.random(1,TblSize)])
		end
	end
	
	--увеличение каунтера при написании человеком любого сообщения
	local all = nil
	if not MsgStats[channel] then MsgStats[channel] = {} end
	if not MsgStats[channel][user] then MsgStats[channel][user] = {} end
	MsgStats[channel][user]["all"] = type(MsgStats[channel][user]["all"]) == "number" and MsgStats[channel][user]["all"] + 1 or 1
	all = true
	--message.channel:send(MsgStats[channel][user]["all"])
	if not LastMsg[channel] or LastMsg[channel].user ~= user then
		MsgStats[channel][user]["notall"] = type(MsgStats[channel][user]["notall"]) == "number" and MsgStats[channel][user]["notall"] + 1 or 1
		all = false
	end
	
	LastMsg[channel] = {}
	LastMsg[channel].user = user
	LastMsg[channel].msg = msg
	LastMsg[channel].notall = not all
	
	filewrite("C:\\Same\\DiscordBot\\MsgStats.txt", json.encode(MsgStats))
	filewrite("C:\\Same\\DiscordBot\\mentionedUsers.txt", json.encode(mentionedUsers))
	filewrite("O:\\LastMsg.txt", json.encode(LastMsg))
end)

--local playing = nil
--local CurVoiceChannel = nil
--local JoinedToVoiceChannel = false	-- это нужно?
Client:on('memberJoin', function(member)							--TODO возможность добавлять и удалять приветственные сообщения
	local channel = Client:getChannel("502070663725449236")
	local msg = "Тут типо рандомное приветственное сообщение."
	local JoiningMessagesN = TableCount(JoiningMessages)
	if JoiningMessagesN > 0 then
		msg = JoiningMessages[math.random(1,JoiningMessagesN)]
	end
	Send(channel,msg)
end)

Client:on('voiceChannelJoin', function(member,channel)
	--print(member)
	--print(channel)
	--print(CurVoiceChannel)
	if member == "514387864650514467" then return end
	--if not JoinedToVoiceChannel or channel ~= CurVoiceChannel and not playing then
		channel:join()
		--CurVoiceChannel = channel
		--JoinedToVoiceChannel = true
	--end
end)

--[[Client:on('typingStart', function(userid,channelId,timestamp)
	local channel = Client:getChannel(channelId)
	local user = Client:getUser(userid)
	print(timestamp)
	channel:send(user.mentionString.." *печатает*")
end)]]

--[[Client:on('voiceChannelLeave', function(member,channel)
	--print(channel)
	--print(channel.connectedMembers:count())
	--print(channel)
	--print(CurVoiceChannel)
	if member:find("514387864650514467") then return nil end
	print(member)
	print(CurVoiceChannel)
	--print(channel.connectedMembers:count())
	--if CurVoiceChannel.channel.connectedMembers:count() < 2 then print("asd") end --and JoinedToVoiceChannel then CurVoiceChannel:close() JoinedToVoiceChannel = false end
end)]]

Client:run(BotSettings.Token,{activity = ""})