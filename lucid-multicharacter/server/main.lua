local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('qb-multicharacter:server:disconnect')
AddEventHandler('qb-multicharacter:server:disconnect', function()
    local src = source

    DropPlayer(src, "You have disconnected from the server")
end)

RegisterServerEvent('qb-multicharacter:server:loadUserData')
AddEventHandler('qb-multicharacter:server:loadUserData', function(cData)
    local src = source
	local bool = QBCore.Player.Login(src, cData.citizenid)
	    if bool then
        QBCore.Commands.Refresh(src)
        loadHouseData()
        
        TriggerClientEvent('apartments:client:setupSpawnUI', src, true, cData)
	end
end)

RegisterServerEvent('lucid:setmugshotprofile')
AddEventHandler('lucid:setmugshotprofile',function(url,citizenid)
    exports.oxmysql:execute("UPDATE `players` SET `mugshot` = '".. url .."' WHERE `citizenid` = '".. citizenid .."'", function(result) 
    end)
end) 


RegisterServerEvent('qb-multicharacter:server:createCharacter')
AddEventHandler('qb-multicharacter:server:createCharacter', function(data)
    local src = source
    local newData = {}
  
    newData.cid = data.cid
    newData.charinfo = data
    --QBCore.Player.CreateCharacter(src, data)
    local bool, citizenid = QBCore.Player.Login(src, false, newData)
    
    if bool then
    
        QBCore.Commands.Refresh(src)
        Citizen.Wait(1000)
        loadHouseData()
        TriggerClientEvent("qb-multicharacter:client:closeNUI", src)
        TriggerClientEvent('lucid-multicharacter:client:spawn', src, true,newData)

        GiveStarterItems(src)
	end
end)

function GiveStarterItems(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    for k, v in pairs(QBCore.Shared.StarterItems) do
        local info = {}
        if v.item == "id_card" then
            info.citizenid = Player.PlayerData.citizenid
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.gender = Player.PlayerData.charinfo.gender
            info.nationality = Player.PlayerData.charinfo.nationality
        elseif v.item == "driver_license" then
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.type = "A1-A2-A | AM-B | C1-C-CE"
        end
        Player.Functions.AddItem(v.item, 1, false, info)
    end
end



QBCore.Functions.CreateCallback("qb-multicharacter:server:GetUserCharacters", function(source, cb)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')

    exports.oxmysql:execute('SELECT * FROM players WHERE license = ?', {license}, function(result)
        cb(result)
    end)
end)

QBCore.Functions.CreateCallback("qb-multicharacter:server:GetServerLogs", function(source, cb)
    exports.oxmysql:execute('SELECT * FROM server_logs', function(result)
        cb(result)
    end)
end)

QBCore.Functions.CreateCallback("lucid-multicharacter:server:getPermissions", function(source, cb)
    local license = QBCore.Functions.GetIdentifier(source, 'license')
    exports.oxmysql:execute("SELECT * FROM multichar_permissions WHERE license = ?", {license}, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)


RegisterServerEvent('lucid-multicharacter:server:deleteCharacter')
AddEventHandler('lucid-multicharacter:server:deleteCharacter', function(citizenid)
    local src = source
    print(src)
    print(citizenid)
    QBCore.Player.DeleteCharacter(src, citizenid)
    Citizen.Wait(500)
    TriggerClientEvent('lucid:characterDeleted', src)
end)

QBCore.Functions.CreateCallback("qb-multicharacter:server:getSkin", function(source, cb, cid)
    local src = source

    exports.oxmysql:execute("SELECT * FROM `playerskins` WHERE `citizenid` = '"..cid.."' AND `active` = 1", function(result)
        if result[1] ~= nil then
            cb(result[1].model, result[1].skin)
        else
            cb(nil)
        end
    end)
end)

QBCore.Commands.Add("addslot", "Add character slot(s)", {}, false, function(source, args)

    if args[1] and args[2] then
        if tonumber(args[2]) == nil then
            TriggerClientEvent('QBCore:Notify', source, "You must specify how many slots to add", "error")
            return 
        end
        if tonumber(args[2] ) < 2 or tonumber(args[2]) > 4 then
            TriggerClientEvent('QBCore:Notify', source, "Allowed slot must be between 2 and 4", "error")
            return
        end
        QBCore.Functions.ExecuteSql(false,"INSERT INTO `multichar_permissions` (`license`, `slot`) VALUES ('"..args[1].."', '"..args[2].."')", function(result)
        end)
    else
        TriggerClientEvent('QBCore:Notify', source, "You entered a missing value /addslot steamid slot(2-4)", "error")

    end
end, "god")

QBCore.Commands.Add("removeslot", "Remove character slot(s)", {}, false, function(source, args)

    if args[1] and args[2] then
        if tonumber(args[2]) == nil then
            TriggerClientEvent('QBCore:Notify', source, "You must specify how many slots to remove", "error")
            return 
        end
        if tonumber( args[2] ) < 2 or tonumber(args[2]) > 4 then
            TriggerClientEvent('QBCore:Notify', source, "Allowed slot must be between 2 and 4", "error")
            return
        end
        exports.oxmysql:execute(false,"DELETE from `multichar_permissions` WHERE steam = '"..args[1].."' AND slot ='"..args[2].."'", function(result)
        end)
    else
        TriggerClientEvent('QBCore:Notify', source, "You entered a missing value /removeslot steamid slot(2-4)", "error")
    end
end, "god")

function loadHouseData()
    local HouseGarages = {}
    local Houses = {}
	--[[QBCore.Functions.ExecuteSql(false, "SELECT * FROM `houselocations`", function(result)
		if result[1] ~= nil then
			for k, v in pairs(result) do
				local owned = false
				if tonumber(v.owned) == 1 then
					owned = true
				end
				local garage = v.garage ~= nil and json.decode(v.garage) or {}
				Houses[v.name] = {
					coords = json.decode(v.coords),
					owned = v.owned,
					price = v.price,
					locked = true,
					adress = v.label, 
					tier = v.tier,
					garage = garage,
					decorations = {},
				}
				HouseGarages[v.name] = {
					label = v.label,
					takeVehicle = garage,
				}
			end
		end
		TriggerClientEvent("qb-garages:client:houseGarageConfig", -1, HouseGarages)
		TriggerClientEvent("qb-houses:client:setHouseConfig", -1, Houses)
	end)]]
end