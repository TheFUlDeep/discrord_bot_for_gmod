local discordia = require('discordia')
local Client = discordia.Client{
	cacheAllMembers = true,
	syncGuilds = true
}
local json = require ("json")
local http = require('http')
local timer = require('timer')
local sleep = timer.sleep
local querystring = require('querystring')
--local utf8 = require("utf8")
--print(utf8)



--package.path = package.path .. "C:\\Same\\DiscordBot\\lua_modules\\?.lua;"
--package.cpath = package.cpath.."C:\\Same\\DiscordBot\\lua_modules\\?.dll;"
--print(package.path) -- where .lua files are searched for
--print(package.cpath)
--local socket require("socket")

local function GetUserMentionString(user)
	if user.mentionString then return string.gsub(user.mentionString,"!","") end
end

local BIGRUS = {"А","Б","В","Г","Д","Е","Ё","Ж","З","И","Й","К","Л","М","Н","О","П","Р","С","Т","У","Ф","Х","Ц","Ч","Ш","Щ","Ъ","Ы","Ь","Э","Ю","Я"}
local smallrus = {"а","б","в","г","д","е","ё","ж","з","и","й","к","л","м","н","о","п","р","с","т","у","ф","х","ц","ч","ш","щ","ъ","ы","ь","э","ю","я"}
local BIG_to_small = {}
for k, v in next, BIGRUS do
   
	BIG_to_small[v] = smallrus[k]
   
end
local function bigrustosmall(str)
   
	local strlow = ""
   
	for v in string.gmatch(str, "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*") do
		strlow = strlow .. (BIG_to_small[v] or v)
	end
   
	return string.lower(strlow) --жтобы англ буквы тоже занижалис
   
end

local function stringfind(where, what, lowerr, startpos, endpos)
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

--TODO пермишны не на целый сервер, а на чат
--TODO !ответить
--TODO коины. +за удержание в топе, -за удаление сообщений
--(передумал. это не нужно но закомментированный блок есть) если в сообщении перед сообщением бота было упоминание, то его тоже надо вычесть
--(не обязательно) если написал бот, то брать не последнее сообщение, а искать сообщение перед ботом. Это для единичных случаев, когда LastMsg не предыдущее (например, из-за того, что бот упал)
--TODO повторять триггер, если фраза в чате есть несколько раз

local function filewrite(file,data)
	print("filewrite",os.date("%H:%M:%S %d.%m.%Y",os.time()),file)
	local f = io.open(file,"w")
	if not f then return end
	f:write(data)
	f:close()
end

local function fileread(file)
	print("fileread",os.date("%H:%M:%S %d.%m.%Y",os.time()),file)
	local f = io.open(file,"r")
	if not f then return end
	local data = f:read()
	f:close()
	return data
end

local BotSettings = {
	['Token'] = "Bot "..(fileread("token.txt") or "");
	['Prefix'] = ";";
}

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
	if not ip then return end
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

local WebServerIPs = fileread("webserverips.txt") and json.decode(fileread("webserverips.txt")) or {} --TODO если у двух серверов будет одинаковый айпи - будет проблема

local BansTBL = {}
local RanksTBL = {}

local function GetGuildIDByWebServerIp(ip)
	for k,v in pairs(WebServerIPs) do
		if v == ip then return k end
	end
end

local function GetRanksBansFromWebServer(WebServerIP)
	HTTPGET(
		WebServerIP,
		"/sync/ranks/",
		nil,
		function(body)  
			RanksTBL[GetGuildIDByWebServerIp(WebServerIP)] = json.decode(body)
		end,
		function(error)
			print("HTTP ERROR "..error)
		end
	)
	
	HTTPGET(
		WebServerIP,
		"/sync/ranks/bans/",
		nil,
		function(body)  
			BansTBL[GetGuildIDByWebServerIp(WebServerIP)] = json.decode(body)
		end,
		function(error)
			print("HTTP ERROR "..error)
		end
	)
end

local function CheckRank(message,steamid) --TODO добавить поиск ника
	GetRanksBansFromWebServer(WebServerIPs[message.guild.id])
	sleep(1000)
	if not steamid or steamid == "" then return end
	HTTPGET(
		WebServerIPs[message.guild.id],
		"/sync/ranks/?SteamID="..steamid,
		nil,
		function(body)  
			if not body or body == "" then table.insert(WatNeedToSend,1,{message.channel,"ничего не найдено"}) return end
			local tbl = json.decode(body)
			if not tbl or TableCount(tbl) < 1 then table.insert(WatNeedToSend,1,{message.channel,"ничего не найдено"}) return end
			table.insert(WatNeedToSend,1,{message.channel,"Информация о "..steamid..". Последний ник на сервере: `"..tbl.Nick.."`. Ранг: "..tbl.Rank})
		end,
		function(error)
			table.insert(WatNeedToSend,1,{message.channel,"HTTP ERROR "..error})
		end
	)
end

local function CheckBan(message,steamid)
	GetRanksBansFromWebServer(WebServerIPs[message.guild.id])
	sleep(1000)
	if not steamid or steamid == "" then return end
	HTTPGET(
		WebServerIPs[message.guild.id],
		"/sync/ranks/bans/?SteamID="..steamid,
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
	if not ip then return end
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
	GetRanksBansFromWebServer(WebServerIPs[message.guild.id])
	sleep(1000)
	if not data or data == "" then table.insert(WatNeedToSend,1,{message.channel,"Неверный SteamID."}) return end
	local start = string.find(data," ")
	if not start then table.insert(WatNeedToSend,1,{message.channel,"Не указана роль."}) return end
	local strsub1 = string.sub(data,1,start - 1)
	if not strsub1:find("STEAM_") then table.insert(WatNeedToSend,1,{message.channel,"Неверный SteamID."}) return end
	local strsub2 = string.sub(data,start + 1)
	if strsub2 ~= "operator" and strsub2 ~= "admin" and strsub2 ~= "user" and strsub2 ~= "tsar" and strsub2 ~= "zamtsar" and strsub2 ~= "superadmin" then message.channel:send("Нельзя установить такую роль.") return end
	HTTPPOST(
		WebServerIPs[message.guild.id],
		"/sync/ranks/",
		nil,
		{SteamID = strsub1,Rank = strsub2,Nick = RanksTBL and RanksTBL[message.guild.id] and RanksTBL[message.guild.id][strsub1] and RanksTBL[message.guild.id][strsub1].Nick or "Unknown"}--,
		--function() table.insert(WatNeedToSend,1,{message.channel,"Игроку "..strsub1.." установлен ранг "..strsub2}) end,
		--function(error) table.insert(WatNeedToSend,1,{message.channel,"HTTP ERROR "..error}) end
	)
end

local function SetBan(message,data)
	GetRanksBansFromWebServer(WebServerIPs[message.guild.id])
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
		WebServerIPs[message.guild.id],
		"/sync/ranks/bans/",
		nil,
		{SteamID = strsub1,Reason = strsub3,Nick = RanksTBL and RanksTBL[message.guild.id] and RanksTBL[message.guild.id][strsub1] and RanksTBL[message.guild.id][strsub1].Nick or "Unknown",WhoBannedID = "Discord",WhoBanned = message.author.name.."("..(GetUserMentionString(message.author))..")",Duration = strsub2}--,
		--function() table.insert(WatNeedToSend,1,{message.channel,"Игроку "..strsub1.." установлен ранг "..strsub2}) end,
		--function(error) table.insert(WatNeedToSend,1,{message.channel,"HTTP ERROR "..error}) end
	)
end

local function Unban(message,data)
	GetRanksBansFromWebServer(WebServerIPs[message.guild.id])
	sleep(1000)
	if not data or data == "" or not data:find("STEAM_") then table.insert(WatNeedToSend,1,{message.channel,"Неверный SteamID."}) return end
	HTTPPOST(
		WebServerIPs[message.guild.id],
		"/sync/ranks/bans/",
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

local MsgStats = fileread("MsgStats.txt") and json.decode(fileread("MsgStats.txt")) or {}
local LastMsg = fileread("O:\\LastMsg.txt") and json.decode(fileread("O:\\LastMsg.txt")) or {}	-- channel, msg, user

local function GenerateChatUsersTbl(GuildID)
	local usertstbl = {}
	if GuildID and MsgStats[GuildID] then
		for k,v in pairs(MsgStats[GuildID]) do
			for k1,v1 in pairs(v) do
				if not usertstbl[k1] then usertstbl[k1] = {} end
				if not usertstbl[k1]["all"] then usertstbl[k1]["all"] = 0 end
				if not usertstbl[k1]["notall"] then usertstbl[k1]["notall"] = 0 end
				if v1["all"] then usertstbl[k1]["all"] = usertstbl[k1]["all"] + v1["all"] end
				if v1["notall"] then usertstbl[k1]["notall"] = usertstbl[k1]["notall"] + v1["notall"] end
			end
		end
	end
	return usertstbl
end

local function MsgsByUserEverywhere(usermentionstring,GuildID)
	local usertstbl = GenerateChatUsersTbl(GuildID)
	
	local topall = GetTop(usertstbl,usertstbl[usermentionstring]["all"],true)
	local topNotall = GetTop(usertstbl,usertstbl[usermentionstring]["notall"])
	local AllChatters = TableCount(usertstbl)
	return usertstbl[usermentionstring]["all"], usertstbl[usermentionstring]["notall"], topall, topNotall, AllChatters
end

local mentionedUsers = fileread("mentionedUsers.txt") and json.decode(fileread("mentionedUsers.txt")) or {}

local function GenerateMentionsUsersTbl(GuildID)
	local mentionsuserstbl = {}
	if GuildID and mentionedUsers[GuildID] then
		for k,v in pairs(mentionedUsers[GuildID]) do
			for k1,v1 in pairs(v) do
				if not mentionsuserstbl[k1] then mentionsuserstbl[k1] = v1 else mentionsuserstbl[k1] = mentionsuserstbl[k1] + v1 end
			end
		end
	end
	return mentionsuserstbl
end

local function GetStat(message,usermentionstring)
	local FirstMessagePrinted = false
	local str = ""
	if not usermentionstring:find("%d") then usermentionstring = GetUserMentionString(message.author) end
	usermentionstring = string.gsub(usermentionstring,"!","")
	if MsgStats[message.guild.id] then
		for k,v in pairs(MsgStats[message.guild.id]) do
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
					--filewrite("test.txt",json.encode(mentionedUsers))
					if mentionedUsers[message.guild.id] and mentionedUsers[message.guild.id][k] then
						local mentionedN = mentionedUsers[message.guild.id][k][k1] or 0
						local top = mentionedUsers[message.guild.id][k][k1] and GetTop(mentionedUsers[message.guild.id][k],mentionedN,nil,true) or 0
						str = str.."Упоминаний: "..mentionedN..". Топ "..top.."/"..TableCount(mentionedUsers[message.guild.id][k]).."\n"
					else
						str = str.."Упоминаний: 0. Топ 0/0\n"
					end
				end
			end
		end
	end
	if not FirstMessagePrinted or str == "" then 
		message.channel:send("Информация о "..usermentionstring.." отсутствует.") 
	else
		local AllMsgsAll, AllMsgsNotAll, TopAll, TopNotAll, AllChatters = MsgsByUserEverywhere(usermentionstring,message.guild.id)
		str = str.."\nСообщений всего: "..AllMsgsAll..". Топ "..TopAll.."/"..AllChatters.."\nСообщений всего не подряд: "..AllMsgsNotAll..". Топ "..TopNotAll.."/"..AllChatters.."\n"
		local mentionsusers = GenerateMentionsUsersTbl(message.guild.id)
		local mentionsN = mentionsusers[usermentionstring] or 0
		--filewrite("test.txt",mentionsusers[usermentionstring])
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

local TriggersPrintTbl = fileread("TriggersPrintTbl.txt") and json.decode(fileread("TriggersPrintTbl.txt")) or {}

local function AddChatTrigger(message,data)
	local arg1,arg2 = ConvertDataToTwoArgs(data)
	if not arg1 or not arg2 then 
		message.channel:send('Команда введена некорректно. Пример: `!добавить чат-триггер [[сергей]] [[лох]]`.')
		return
	end
	arg1 = bigrustosmall(arg1)
	--arg2 = bigrustosmall(arg2)
	
	if TriggersPrintTbl[message.guild.id] and TriggersPrintTbl[message.guild.id][arg1] and FindInTable(TriggersPrintTbl[message.guild.id][arg1],arg2) then message.channel:send("Данный триггер уже существует.") return end
	if not TriggersPrintTbl[message.guild.id] then TriggersPrintTbl[message.guild.id] = {} end
	if not TriggersPrintTbl[message.guild.id][arg1] then TriggersPrintTbl[message.guild.id][arg1] = {} end
	table.insert(TriggersPrintTbl[message.guild.id][arg1],1,arg2)
	filewrite("TriggersPrintTbl.txt",json.encode(TriggersPrintTbl))
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
	if not TriggersPrintTbl[message.guild.id] or not TriggersPrintTbl[message.guild.id][arg1] then message.channel:send("Данного чат-триггера не существует") return end
	if arg2 then
		local FounArg2 = FindInTable(TriggersPrintTbl[message.guild.id][arg1],arg2)
		if not FounArg2 then 
			message.channel:send("Данного чат-триггера не существует.") 
			return
		else
			TriggersPrintTbl[message.guild.id][arg1][FounArg2] = ""
			NormirTable(TriggersPrintTbl[message.guild.id][arg1])
			filewrite("TriggersPrintTbl.txt",json.encode(TriggersPrintTbl))
			message.channel:send("Чат-триггер был успешно удален.")
		end
	else 
		TriggersPrintTbl[message.guild.id][arg1] = nil
		filewrite("TriggersPrintTbl.txt",json.encode(TriggersPrintTbl))
		message.channel:send("Чат-триггеры были успешно удалены.") 
	end
end

local function ShowChatTriggers(message,a)
	local str = ""
	if TriggersPrintTbl[message.guild.id] then
		for k,v in pairs(TriggersPrintTbl[message.guild.id]) do
			str = str..'Триггеры на "'..k..'": '
			str = str..json.encode(v).."\n"
		end
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

local function GetAllMessagedAndMentionsCountInChannel(mentionString,GuildID)
	local all = 0
	local notall = 0
	if GuildID and MsgStats[GuildID] and MsgStats[GuildID][mentionString] then
		for k,v in pairs(MsgStats[GuildID][mentionString]) do
			if v["all"] then all = all + v["all"] end
			if v["notall"] then notall = notall + v["notall"] end
		end
	end
	
	local Mentions = 0
	if GuildID and mentionedUsers[GuildID] and mentionedUsers[GuildID][mentionString] then
		for k,v in pairs(mentionedUsers[GuildID][mentionString]) do
			Mentions = Mentions + v
		end
	end
	
	return all,notall,Mentions
end

local function GetAllMessagedAndMentionsCount(GuildID)
	local MsgCount = 0
	if GuildID and MsgStats[GuildID] then
		for k,v in pairs(MsgStats[GuildID]) do
			for k1,v1 in pairs(v) do
				if v1["all"] then MsgCount = MsgCount + v1["all"] end
			end
		end
	end
	
	local MentionsCount = 0
	if GuildID and mentionedUsers[GuildID] then
		for k,v in pairs(mentionedUsers[GuildID]) do
			for k1,v1 in pairs(v) do
				MentionsCount = MentionsCount + v1
			end
		end
	end
	
	return MsgCount,MentionsCount
end

local function TopChatters(message,a)
	local str = ""
	
	local MsgCount,MentionsCount = GetAllMessagedAndMentionsCount(message.guild.id)
	
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
	local mentionsusers = GenerateMentionsUsersTbl(message.guild.id)
	local TopAllMentions = GetTopOne(mentionsusers,nil,true)
	for k,v in pairs(TopAllMentions) do
		str = str..v[1].." - упоминаний: "..v[2].."\n"
	end

	--tоп канал
	local chatstbl = {}
	if MsgStats[message.guild.id] then
		for k,v in pairs(MsgStats[message.guild.id]) do
			if not chatstbl[k] then chatstbl[k] = {} end
			if not chatstbl[k]["all"] then chatstbl[k]["all"] = 0 end
			if not chatstbl[k]["notall"] then chatstbl[k]["notall"] = 0 end
			for k1,v1 in pairs(v) do
				if v1["all"] then chatstbl[k]["all"] = chatstbl[k]["all"] + v1["all"] end
				if v1["notall"] then chatstbl[k]["notall"] = chatstbl[k]["notall"] + v1["notall"] end
			end
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
	if mentionedUsers[message.guild.id] then
		for k,v in pairs(mentionedUsers[message.guild.id]) do
			if not chatmenstionstbl[k] then chatmenstionstbl[k] = 0 end
			for k1,v1 in pairs(v) do
				chatmenstionstbl[k] = chatmenstionstbl[k] + v1
			end
		end
	end
	local TopMentionsChat = GetTopOne(chatmenstionstbl,nil,true)
	str = str.."Канал, в котором больше всего упоминаний:\n"
	for k,v in pairs(TopMentionsChat) do
		str = str..v[1].." - упоминаний: "..v[2].."\n"
	end
	
	--топ юзер в каждом канале
	if MsgStats[message.guild.id] then
		for k,v in pairs(MsgStats[message.guild.id]) do
			local TopOneInChannelAll = GetTopOne(v,true)
			local TopOneInChannelNotAll = GetTopOne(v)
			str = str.."\nКанал "..k..":\n"
			local all,notall,Mentions = GetAllMessagedAndMentionsCountInChannel(k,message.guild.id)
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
			
			local TopOneInChannelMentions = mentionedUsers[message.guild.id] and mentionedUsers[message.guild.id][k] and GetTopOne(mentionedUsers[message.guild.id][k],nil,true) or {}
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
	end
	Send(message.channel,str)
	--message.channel:send(str)
end

local function GetMemberByMentionString(message,str)
	str = string.gsub(str,"!","")
	local members = message.guild.members:toArray()
	for k,v in pairs(members) do
		if GetUserMentionString(v.user) == str then return v end
	end
end

local function GetRole(message,data)
	--print(message.member.highestRole.id)
	--print(message.member.highestRole.name)
	local memb = (not data or not string.find(data,"%d")) and message.member or GetMemberByMentionString(message,data)

	if not memb then message.channel:send("Пользователь не найден") return end
	local str = ""
	local roleIDs = memb.roles:toArray()
	for k,v in pairs(roleIDs) do 
		--print(k,v)
		str = str..tostring(v)..": "..Client:getRole(v).name.."\n"
		--print(Client:getRole(v).name)
	end
	local mentionString = GetUserMentionString(message.author)
	mentionString = string.gsub(mentionString,"!","")
	if str ~= "" then 
		str = "Роли игрока "..GetUserMentionString(memb.user)..": \n"..str 
		message.channel:send(str)
	else
		message.channel:send("У "..GetUserMentionString(memb.user).."  нет ролей.")
	end
end

local function Date(message,a)
	message.channel:send("16е мая 2019го года")
end

local function CurChannel(message,data)
	message.channel:send((GetUserMentionString(message.author))..", это канал `"..message.channel.mentionString.."`, ID: "..tostring(message.channel.id))
end

local JoiningMessageChannel = fileread("JoiningMessageChannel.txt") and json.decode(fileread("JoiningMessageChannel.txt")) or {}
local JoiningMessages = fileread("JoiningMessages.txt") and json.decode(fileread("JoiningMessages.txt")) or {}

local function ShowJoiningMessages(message,a)
	if not JoiningMessages[message.guild.id] or type(JoiningMessages[message.guild.id]) ~= "table" then message.channel:send("У меня в списке нет ни одного приветственного сообщения.") return end
	local JoiningMessagesN = TableCount(JoiningMessages[message.guild.id])
	if JoiningMessagesN < 1 then message.channel:send("У меня в списке нет ни одного приветственного сообщения.") return end
	local str = ""
	for k,v in pairs(JoiningMessages[message.guild.id]) do
		str = str..k..":\n"
		str = str..v.."\n\n"
	end
	Send(message.channel,str)
	if not JoiningMessageChannel[message.guild.id] then
		message.channel:send("Приветственные сообщения не будут отображаться, пока вы не укажете канал для них (!канал приветственных сообщений)")
	end
end

local function AddJoiningMessage(message,data)
	if not JoiningMessages[message.guild.id] then JoiningMessages[message.guild.id] = {} end
	table.insert(JoiningMessages[message.guild.id],1,data)
	filewrite("JoiningMessages.txt",json.encode(JoiningMessages))
	message.channel:send("Приветственное сообщение добавлено")
	if not JoiningMessageChannel[message.guild.id] then
		message.channel:send("Приветственные сообщения не будут отображаться, пока вы не укажете канал для них (!канал приветственных сообщений)")
	end
end

local function RemoveJoiningMessages(message,data)
	if not JoiningMessages[message.guild.id] or not JoiningMessages[message.guild.id][tonumber(data)] then
		message.channel:send("Данного сообщения не существует")
		return
	else
		JoiningMessages[message.guild.id][tonumber(data)] = nil
		message.channel:send("Приветственное сообщение успешно удалено")
	end
	filewrite("JoiningMessages.txt",json.encode(JoiningMessages))
end

local function Server(message,data)
	message.channel:send(message.guild.id)
end

local CommandsRolesPermissions = fileread("CommandsRolesPermissions.txt") and json.decode(fileread("CommandsRolesPermissions.txt")) or {}

local CommandsUsersPermissions = fileread("CommandsUsersPermissions.txt") and json.decode(fileread("CommandsUsersPermissions.txt")) or {}

local function AddAccessToCommandForRole(message,data)
	local arg1,arg2 = ConvertDataToTwoArgs(data)
	if not arg1 or not arg2 then 
		message.channel:send('Команда введена некорректно. Пример: `!дать доступ к команде для роли [[!добавить чат-триггер]] [[594611225762070541]]`.')
		return
	end
	
	if not CommandsTbl[arg1] then message.channel:send('Команда не найдена') return end
	if not message.guild:getRole(arg2) then message.channel:send('Роль не найдена') return end
	
	if not CommandsRolesPermissions[message.guild.id] then CommandsRolesPermissions[message.guild.id] = {} end
	if not CommandsRolesPermissions[message.guild.id][arg1] then CommandsRolesPermissions[message.guild.id][arg1] = {} end
	if FindInTable(CommandsRolesPermissions[message.guild.id][arg1],arg2) then 
		message.channel:send('Данная роль уже имеет доступ к этой команде') 
		return
	else
		table.insert(CommandsRolesPermissions[message.guild.id][arg1],1,arg2)
		message.channel:send('Роли '..arg2.." выдан доступ к команде "..arg1) 
		filewrite("CommandsRolesPermissions.txt",json.encode(CommandsRolesPermissions))
	end
end

local function AddAccessToCommandForUser(message,data)
	local arg1,arg2 = ConvertDataToTwoArgs(data)
	if not arg1 or not arg2 then 
		message.channel:send('Команда введена некорректно. Пример: `!дать доступ к команде для роли [[!добавить чат-триггер]] [[594611225762070541]]`.')
		return
	end
	arg2 = string.gsub(arg2,"!","")
	if not GetMemberByMentionString(message,arg2) then message.channel:send('Игрок не найден') return end
	if not CommandsTbl[arg1] then message.channel:send('Команда не найдена') return end
	if not CommandsTbl[arg1][3] then message.channel:send('К этой команде доступ имеют все') return end
	
	if not CommandsUsersPermissions[message.guild.id] then CommandsUsersPermissions[message.guild.id] = {} end
	if not CommandsUsersPermissions[message.guild.id][arg1] then CommandsUsersPermissions[message.guild.id][arg1] = {} end
	if FindInTable(CommandsUsersPermissions[message.guild.id][arg1],arg2) then 
		message.channel:send('Данная роль уже имеет доступ к этой команде') 
		return
	else
		table.insert(CommandsUsersPermissions[message.guild.id][arg1],1,arg2)
		message.channel:send('Юзеру '..arg2.." выдан доступ к команде "..arg1) 
		filewrite("CommandsUsersPermissions.txt",json.encode(CommandsUsersPermissions))
	end
end

local function RemoveAccessToCommandForRole(message,data)
	local arg1,arg2 = ConvertDataToTwoArgs(data)
	if not arg1 or not arg2 then 
		message.channel:send('Команда введена некорректно. Пример: `!дать доступ к команде для роли [[!добавить чат-триггер]] [[594611225762070541]]`.')
		return
	end
	
	if not CommandsTbl[arg1] then message.channel:send('Команда не найдена') return end
	if not message.guild:getRole(arg2) then message.channel:send('Роль не найдена') return end
	if not CommandsRolesPermissions[message.guild.id] or not CommandsRolesPermissions[message.guild.id][arg1] then message.channel:send("К этой команде и так не было доступа") return end
	local Found = FindDeepInTable(CommandsRolesPermissions[message.guild.id][arg1],arg2)
	if not Found then 
		message.channel:send("Роль "..arg2.." не имеет доступа к этой команде") 
		return
	else
		CommandsRolesPermissions[message.guild.id][arg1][Found] = nil
		message.channel:send("Роль "..arg2.." больше не имеет доступа к команде "..arg1) 
		filewrite("CommandsRolesPermissions.txt",json.encode(CommandsRolesPermissions))
	end
end

local function RemoveAccessToCommandForUser(message,data)
	local arg1,arg2 = ConvertDataToTwoArgs(data)
	if not arg1 or not arg2 then 
		message.channel:send('Команда введена некорректно. Пример: `!дать доступ к команде для роли [[!добавить чат-триггер]] [[594611225762070541]]`.')
		return
	end
	arg2 = string.gsub(arg2,"!","")
	if not CommandsTbl[arg1] then message.channel:send('Команда не найдена') return end
	if not GetMemberByMentionString(message,arg2) then message.channel:send('Игрок не найден') return end
	if not CommandsUsersPermissions[message.guild.id] or not CommandsUsersPermissions[message.guild.id][arg1] then message.channel:send("К этой команде и так не было доступа") return end
	local Found = FindDeepInTable(CommandsUsersPermissions[message.guild.id][arg1],arg2)
	if not Found then 
		message.channel:send("Роль "..arg2.." не имеет доступа к этой команде") 
		return
	else
		CommandsUsersPermissions[message.guild.id][arg1][Found] = nil
		message.channel:send("Роль "..arg2.." больше не имеет доступа к команде "..arg1) 
		filewrite("CommandsUsersPermissions.txt",json.encode(CommandsUsersPermissions))
	end
end

local function GetAccesses(message,data)
	local str = ""
	for comm,v in pairs(CommandsTbl) do
		local users
		local roles
		if CommandsUsersPermissions[message.guild.id] and CommandsUsersPermissions[message.guild.id][comm] then
			users = json.encode(CommandsUsersPermissions[message.guild.id][comm])
		end
		if CommandsRolesPermissions[message.guild.id] and CommandsRolesPermissions[message.guild.id][comm] then
			roles = json.encode(CommandsRolesPermissions[message.guild.id][comm])
		end
		if users or roles then
			if not users then users = "" end
			if not roles then roles = "" end
			str = str ~= "" and str.."\n\n" or str
			str = str.."Команда `"..comm.."`: "..users.." "..roles
		end
	end
	if str ~= "" then Send(message.channel,str) end
end


local function SetWebServerIp(message,data)
	WebServerIP = data
	WebServerIPs[message.guild.id] = data
	filewrite("webserverips.txt",json.encode(WebServerIPs))
	message.channel:send("Готово")
end

local BotChannelsTbl = fileread("botchannels.txt") and json.decode(fileread("botchannels.txt")) or {}

local function SetBotChannel(message,data)
	if BotChannelsTbl[message.guild.id] and BotChannelsTbl[message.guild.id] == message.channel.mentionString then
		BotChannelsTbl[message.guild.id] = nil
		message.channel:send("Теперь с ботом можно общться в любом канале этого сервера")
	else
		BotChannelsTbl[message.guild.id] = message.channel.mentionString
		message.channel:send("Теперь с ботом можно общться только в этом канале")
	end
	filewrite("botchannels.txt",json.encode(BotChannelsTbl))
end

local function JoiningMessageChannelF(message,data)
	if not JoiningMessageChannel[message.guild.id] or JoiningMessageChannel[message.guild.id] ~= message.channel.id then
		JoiningMessageChannel[message.guild.id] = message.channel.id
		message.channel:send("Теперь приветственные сообщения будут писаться в канал "..message.channel.mentionString)
	else
		JoiningMessageChannel[message.guild.id] = nil
		message.channel:send("Теперь приветственные не будут отображаться")
	end
	filewrite("JoiningMessageChannel.txt",json.encode(JoiningMessageChannel))
end

local ServerInfoMessages = fileread("ServerInfoMessages.txt") and json.decode(fileread("ServerInfoMessages.txt")) or {}

local function AddServerInfoMessages(message,data)
	if ServerInfoMessages[message.guild.id] and type(ServerInfoMessages[message.guild.id]) == "table" and ServerInfoMessages[message.guild.id].channel and ServerInfoMessages[message.guild.id].messages and type(ServerInfoMessages[message.guild.id].messages) == "table" then
		local Channel = Client:getChannel(ServerInfoMessages[message.guild.id].channel)
		if Channel then
			for k,v in pairs(ServerInfoMessages[message.guild.id].messages) do
				local Message = Channel:getMessage(v)
				if Message then Message:delete() end
			end
		end
	end
	message:delete()
	ServerInfoMessages[message.guild.id] = {}
	ServerInfoMessages[message.guild.id].channel = message.channel.id
	ServerInfoMessages[message.guild.id].messages = {message.channel:send("serverinfo").id}
	filewrite("ServerInfoMessages.txt",json.encode(ServerInfoMessages))
end

local function Reply(message,data)
end

CommandsTbl["!стата"] = {GetStat,120}	-- command, function, cooldown, not for all users	-- TODO , возможно кулдауны по ролям. Функция что-то возвращает при ошибке или отсутствии доступа
CommandsTbl["!бан"] = {SetBan,0,true}	
CommandsTbl["!добавить чат-триггер"] = {AddChatTrigger,0,true}	
CommandsTbl["!бот"] = {ImGay,120}	
CommandsTbl["!чат-триггеры"] = {ShowChatTriggers,120}	
CommandsTbl["!удалить чат-триггер"] = {RemoveChatTrigger,0,true}	
CommandsTbl["!команды"] = {ShowAllCommands,120}	
CommandsTbl["!топ"] = {TopChatters,120}	
CommandsTbl["!роли"] = {GetRole,120}	
CommandsTbl["!дата"] = {Date,120}	
CommandsTbl["!канал"] = {CurChannel,0,true}	
CommandsTbl["!приветственные сообщения"] = {ShowJoiningMessages,120}	
CommandsTbl["!добавить приветственное сообщение"] = {AddJoiningMessage,0,true}
CommandsTbl["!удалить приветственное сообщение"] = {RemoveJoiningMessages,0,true}
CommandsTbl["!чекранг"] = {CheckRank,30} --TODO
--CommandsTbl["!чекранг2"] = {CheckRank2,0}
CommandsTbl["!чекбан"] = {CheckBan,30}
CommandsTbl["!разбан"] = {Unban,0,true}
CommandsTbl["!сетранг"] = {SetRank,0,true}
CommandsTbl["!сервер"] = {Server,0,true}
CommandsTbl["!дать доступ к команде для роли"] = {AddAccessToCommandForRole,0,true}
CommandsTbl["!убрать доступ к команде у роли"] = {RemoveAccessToCommandForRole,0,true}
CommandsTbl["!дать доступ к команде для юзера"] = {AddAccessToCommandForUser,0,true}
CommandsTbl["!убрать доступ к команде у юзера"] = {RemoveAccessToCommandForUser,0,true}
CommandsTbl["!доступы"] = {GetAccesses,30}
CommandsTbl["!информация о серверах"] = {AddServerInfoMessages,0,true}
CommandsTbl["!айпи веб-сервера"] = {SetWebServerIp,0,true}
CommandsTbl["!канал приветственных сообщений"] = {JoiningMessageChannelF,0,true}
CommandsTbl["!канал для общения с ботом"] = {SetBotChannel,0,true}
CommandsTbl["!ответить"] = {Reply,30} --TODO
--CommandsTbl["!сетранг2"] = {SetRank2,0,{"461651884906643457"}}

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


--обновление информации о серверах
local ServerNames = {}
local ServersInfo = {}
local LoadServerInfoOnStartUp = true
local NeedUpdateServerInfo = {}

local function UpdateServersInfo(GuildID)
	local messages = ServerInfoMessages and ServerInfoMessages[GuildID] and ServerInfoMessages[GuildID].messages and type(ServerInfoMessages[GuildID].messages) == "table" and ServerInfoMessages[GuildID].messages
	if not messages then return end

	local Channel = ServerInfoMessages[GuildID] and ServerInfoMessages[GuildID].channel and Client:getChannel(ServerInfoMessages[GuildID].channel)
	if not Channel then return end
	
	if not WebServerIP and Channel.guild then WebServerIP = WebServerIPs[Channel.guild.id] end
	
	if not NeedUpdateServerInfo[Channel.guild.id] then return end
	NeedUpdateServerInfo[Channel.guild.id] = false
	if not ServersInfo[Channel.guild.id] or type(ServersInfo[Channel.guild.id]) ~= "table" then return end
	
	while TableCount(ServersInfo[Channel.guild.id]) > TableCount(ServerInfoMessages[GuildID].messages) do
		table.insert(ServerInfoMessages[GuildID].messages,1,Channel:send("serverinfo").id)
		filewrite("ServerInfoMessages.txt",json.encode(ServerInfoMessages))
	end
	
	messages = ServerInfoMessages[GuildID].messages
	
	local i = 0
	for ip,v in pairs(ServersInfo[Channel.guild.id]) do
		i = i + 1
		if messages[i] then
			local Message = Channel:getMessage(messages[i])
			if Message then
				if Message.content ~= "" then Message:setContent("") end
				if type(v) == "table" then
					if not ServerNames[Channel.guild.id] then ServerNames[Channel.guild.id] = {} end
					ServerNames[Channel.guild.id][i] = v.ServerName
					local IconURL = "https://images-ext-1.discordapp.net/external/DVrAzp7wY7c2P_dreWdW3Ai8Lj0wTEMB_ZuD28pMW98/%3Fwidth%3D858%26height%3D677/https/media.discordapp.net/attachments/502070663725449236/592392019620528132/3af2ae0dd9f712a5475117200c3f4ed8.png"--TODO зависимость от количества игроков
					local PlayersInfo = ""
					if v.Players then
						--local PlayersCount = 0
						for k,ply in pairs(v.Players) do
							--[[PlayersCount = PlayersCount + 1
							if PlayersCount == 1 then PlayersInfo = PlayersInfo.."\n" else PlayersInfo = PlayersInfo.."\n\n" end
							PlayersInfo = PlayersInfo..ply.Nick.." ("..ply.SteamID..")["..ply.Rank.."], онлайн "..ply.Time.." сек."
							if ply.Position then PlayersInfo = PlayersInfo.."\nместоположение "..ply.Position end]]
							PlayersInfo = PlayersInfo.."\n`"..ply.Nick.."` ("..ply.SteamID..")" -- сделал максимально коротко
						end
					end
					Message:setEmbed{
						description = "**Сервер:** "..v.ServerName.."\n\n**Карта:** "..v.Map.."\n\n**Игроков:** "..v.PlayerCount.."/"..v.MaxPlayers..PlayersInfo.."\n\n**IP:** "..ip.."\n**Ссылка на подключение:** steam://connect/"..ip,
						--url = {"steam://connect/93.170.123.99:27018"}, -- не работает
						--timestamp = "asdsad",-- не работает
						footer = {		--маленький текст снизу
							text = "\n\n\nАктуально на "..os.date("%H:%M:%S %d.%m.%Y",v.LastUpdate).." (МСК)",
						--	icon_url = "https://cdn.discordapp.com/attachments/434738851815227402/608034671204237332/1.PNG" -- маленькая картинка
						},
						thumbnail = {
							url = IconURL,--картинка справа сверху
							--height = 100,	--размеры не меняются
							--width = 100
						},
						--[[provider = {			--хз шоета
							url = "https://www.youtube.com/feed/subscriptions",
							name = "asd"
						},]]
						--description = "*ссылка* на подключение\nsteam://connect/"..ip, --маленький текст, но больше, чем footer
						color = discordia.Color("#FFFFFF").value -- черный цвет
					}
				else
					Message:setEmbed{
						title = "**Сервер:** "..(ServerNames[Channel.guild.id] and ServerNames[Channel.guild.id][i] or i).."\n\n**"..v.."**",
						image = {
							url = "https://cs5.pikabu.ru/post_img/2015/11/25/10/1448471547_356077498.jpg"
						}
					}
				end
			elseif ServerInfoMessages[GuildID] and ServerInfoMessages[GuildID].messages then
				for k,msgid in pairs(ServerInfoMessages[GuildID].messages) do
					local Msg = Channel:getMessage(msgid)
					if Msg then Msg:delete() end
				end
				ServerInfoMessages[GuildID] = nil
				filewrite("ServerInfoMessages.txt",json.encode(ServerInfoMessages))
			end
		end
	end
end

Client:on('ready', function()-- так можно делать сколько угодно таймеров
	local function Timer()
		--print("Timer")
		sleep(500)
		CheckWatNeedToSend()
		Timer()
	end
	Timer()
end)

Client:on('ready', function()
	local function Timer()
		--print("Timer")
		sleep(5 * 1000)
		for k,v in pairs(ServerInfoMessages) do
			UpdateServersInfo(k)
		end
		Timer()
	end
	Timer()
end)


Client:on('ready', function()
	local function Timer()
		if WebServerIPs then
			for k,v in pairs(WebServerIPs) do
				HTTPGET( 
					WebServerIPs[k],
					"/serverinfo/",
					nil,
					function(body)
						ServersInfo[k] = body
						if not body then return end
						body = json.decode(body)
						ServersInfo[k] = body
						NeedUpdateServerInfo[k] = true
					end
				)
			end
		end
		
		sleep(30 * 1000)
		Timer()
	end
	Timer()
end)

Client:on('ready', function()-- так можно делать сколько угодно таймеров
	Client:setGame("!команды")
	--Client:setStatus("offline")
end)

	--[[for channel1,tbl1 in pairs(LastMsg) do
		tbl.user
		tbl.mentionedUsers
		tbl.msg
		tbl.notall
	end]]
	
--local CallCount = 0
Client:on('messageCreate', function(message)
	--CallCount = CallCount + 1
	if not message.guild then return end
	
	if not WebServerIP then WebServerIP = WebServerIPs[message.guild.id] end
	
	local user = string.gsub(message.author.mentionString,"!","")
	
	if user == "<@514387864650514467>" then return end
	
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
	
	local msg = message.content
	local channel = message.channel.mentionString
	
	if message.author.bot then
		if LastMsg[channel] then
			if MsgStats[message.guild.id] and MsgStats[message.guild.id][channel] and MsgStats[message.guild.id][channel][LastMsg[channel].user] and MsgStats[message.guild.id][channel][LastMsg[channel].user]["all"] and type(MsgStats[message.guild.id][channel][LastMsg[channel].user]["all"]) == "number" and MsgStats[message.guild.id][channel][LastMsg[channel].user]["all"] > 0 then MsgStats[message.guild.id][channel][LastMsg[channel].user]["all"] = MsgStats[message.guild.id][channel][LastMsg[channel].user]["all"] - 1 end
			if LastMsg[channel].notall and MsgStats[message.guild.id] and MsgStats[message.guild.id][channel] and MsgStats[message.guild.id][channel][LastMsg[channel].user] and MsgStats[message.guild.id][channel][LastMsg[channel].user]["notall"] and type(MsgStats[message.guild.id][channel][LastMsg[channel].user]["notall"]) == "number" and MsgStats[message.guild.id][channel][LastMsg[channel].user]["notall"] > 0 then MsgStats[message.guild.id][channel][LastMsg[channel].user]["notall"] = MsgStats[message.guild.id][channel][LastMsg[channel].user]["notall"] - 1 end
			--уменьшение количества упоминаний
			--[[if LastMsg[channel] and LastMsg[channel].user and LastMsg[channel].mentionedUsers and mentionedUsers[message.guild.id] and mentionedUsers[message.guild.id][channel] then
				for k,v in pairs(LastMsg[channel].mentionedUsers) do
					for k1,v1 in pairs(mentionedUsers[message.guild.id][channel]) do
						for k2,v2 in pairs(v1) do
							if k2 == v and mentionedUsers[message.guild.id][channel][k2] > 0 then
								mentionedUsers[message.guild.id][channel][k2] = mentionedUsers[message.guild.id][channel][k2] - 1
							end
						end
					end
				end
			end]]
		end
	end
	
	if message.author.bot then return end
	local deleted = false
	local ItWasCommand = false
	
	--если человек пишет два идентичных сообщеняи подряд, то его второе сообщение удаляется
	if message.content ~= "" and LastMsg[channel] then
		if LastMsg[channel].user == user and LastMsg[channel].msg == msg then 
			message:delete()
			deleted = true
		end
	end
	
	if deleted then return end
	
	local contentLower = bigrustosmall(message.content)
	
	if not BotChannelsTbl[message.guild.id] or BotChannelsTbl[message.guild.id] == channel then
		for k,v in pairs(CommandsTbl) do
			if string.sub(contentLower,1,#k) == k then
				ItWasCommand = true
				if v[3] and (message.member:hasPermission(message.channel, "administrator") or CommandsRolesPermissions[message.guild.id] and CommandsRolesPermissions[message.guild.id][k] and MemberHasRole(message.member,CommandsRolesPermissions[message.guild.id][k]) or CommandsUsersPermissions[message.guild.id] and CommandsUsersPermissions[message.guild.id][k] and FindInTable(CommandsUsersPermissions[message.guild.id][k],user)) or not v[3] then
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
	end
	
	if ItWasCommand then return end
	
	local mentionedUsersInMessage = message.mentionedUsers:toArray()
	if not mentionedUsers[message.guild.id] then mentionedUsers[message.guild.id] = {} end
	if not mentionedUsers[message.guild.id][channel] then mentionedUsers[message.guild.id][channel] = {} end
	
	for k,v in pairs(mentionedUsersInMessage) do
		v = string.gsub(v.mentionString,"!","")
		if v ~= user then
			if not mentionedUsers[message.guild.id][channel][v] then mentionedUsers[message.guild.id][channel][v] = 1 else mentionedUsers[message.guild.id][channel][v] = mentionedUsers[message.guild.id][channel][v] + 1 end
		end
	end
	
	if TriggersPrintTbl[message.guild.id] then
		for k,v in pairs(TriggersPrintTbl[message.guild.id]) do
			if contentLower:find(k) then 
				local TblSize = TableCount(v)
				message.channel:send(v[math.random(1,TblSize)])
			end
		end
	end
	
	--увеличение каунтера при написании человеком любого сообщения
	local all = nil
	if not MsgStats[message.guild.id] then MsgStats[message.guild.id] = {} end
	if not MsgStats[message.guild.id][channel] then MsgStats[message.guild.id][channel] = {} end
	if not MsgStats[message.guild.id][channel][user] then MsgStats[message.guild.id][channel][user] = {} end
	MsgStats[message.guild.id][channel][user]["all"] = type(MsgStats[message.guild.id][channel][user]["all"]) == "number" and MsgStats[message.guild.id][channel][user]["all"] + 1 or 1
	all = true
	--message.channel:send(MsgStats[message.guild.id][channel][user]["all"])
	if not LastMsg[channel] or LastMsg[channel].user ~= user then
		MsgStats[message.guild.id][channel][user]["notall"] = type(MsgStats[message.guild.id][channel][user]["notall"]) == "number" and MsgStats[message.guild.id][channel][user]["notall"] + 1 or 1
		all = false
	end
	
	LastMsg[channel] = {}
	LastMsg[channel].user = user
	LastMsg[channel].msg = msg
	LastMsg[channel].notall = not all
	
	--для уменьшения количества упоминаний
	--[[local MentionedUsers = {}
	for k,v in pairs(mentionedUsersInMessage) do
		if v.mentionString then MentionedUsers[#MentionedUsers + 1] = string.gsub(v.mentionString,"!","") end
	end
	LastMsg[channel].mentionedUsers = MentionedUsers]]
	
	filewrite("MsgStats.txt", json.encode(MsgStats))
	filewrite("mentionedUsers.txt", json.encode(mentionedUsers))
	filewrite("O:\\LastMsg.txt", json.encode(LastMsg))
	
	--print(CallCount)
end)

--local playing = nil
--local CurVoiceChannel = nil
--local JoinedToVoiceChannel = false	-- это нужно?
Client:on('memberJoin', function(member)
	local channel = Client:getChannel(JoiningMessageChannel[member.guild.id])
	if not channel then return end
	if not WebServerIP and channel.guild then WebServerIP = WebServerIPs[channel.guild.id] end
	local msg = "Тут типо рандомное приветственное сообщение."
	local JoiningMessagesN = TableCount(JoiningMessages)
	local user = GetUserMentionString(member.user)
	if JoiningMessagesN > 0 then
		msg = JoiningMessages[math.random(1,JoiningMessagesN)]
		while msg:find("@user") do
			msg = string.gsub(msg,"@user",user)
		end
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
	if not WebServerIP and channel.guild then WebServerIP = WebServerIPs[channel.guild.id] end
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

Client:run(BotSettings.Token,{activity = "!команды"})