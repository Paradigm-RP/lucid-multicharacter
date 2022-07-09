local QBCore = exports['qb-core']:GetCoreObject()

--CODE
local camZPlus1 = 1500
local camZPlus2 = 50
local pointCamCoords = 75
local pointCamCoords2 = 0
local cam1Time = 500
local cam2Time = 1000
local timer = 0

local choosingSpawn = false
local isNew = false





RegisterNUICallback("exit", function(data)
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "ui",
        status = false
    })
    choosingSpawn = false
end)

RegisterNUICallback('chooseAppa', function(data)
    local appaYeet = data.appType
    SetDisplay(false)
    DoScreenFadeOut(500)
    Citizen.Wait(5000)
    TriggerServerEvent("apartments:server:CreateApartment", appaYeet, Apartments.Locations[appaYeet].label)
    FreezeEntityPosition(PlayerPedId(), false)
    SetEntityVisible(PlayerPedId(), true)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    SwitchIN()
end)

RegisterNUICallback('spawnplayer', function(data)
    local location = tostring(data.spawnloc)
    local type = tostring(data.typeLoc)
    local ped = PlayerPedId()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local insideMeta = PlayerData.metadata["inside"]
    DoScreenFadeOut(500)


    if type == "current" then
        TriggerEvent("debug", 'Spawn: Last Location', 'success')
        print('spawning')

        SetDisplay(false)
        Citizen.Wait(2000)
        QBCore.Functions.GetPlayerData(function(PlayerData)
            SetEntityCoords(PlayerPedId(), PlayerData.position.x, PlayerData.position.y, PlayerData.position.z)
            SetEntityHeading(PlayerPedId(), PlayerData.position.a)
            FreezeEntityPosition(PlayerPedId(), false)
            
        end)
        if insideMeta.house ~= nil then
            local houseId = insideMeta.house
            TriggerEvent('qb-houses:client:LastLocationHouse', houseId)
        elseif insideMeta.apartment.apartmentType ~= nil or insideMeta.apartment.apartmentId ~= nil then
            local apartmentType = insideMeta.apartment.apartmentType
            local apartmentId = insideMeta.apartment.apartmentId
            TriggerEvent('qb-apartments:client:LastLocationHouse', apartmentType, apartmentId)
        end
        FreezeEntityPosition(ped, false)
        SetEntityVisible(PlayerPedId(), true)
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
        SwitchIN()

        
    elseif type == "house" then
        TriggerEvent("debug", 'Spawn: Owned House', 'success')

        SetDisplay(false)
        Citizen.Wait(2000)
        TriggerEvent('qb-houses:client:enterOwnedHouse', location)
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
        FreezeEntityPosition(ped, false)
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
        SetEntityVisible(PlayerPedId(), true)
        SwitchIN()
    elseif type == "normal" then
        TriggerEvent("debug", 'Spawn: ' .. Config.Spawns[location].label, 'success')

        local pos = Config.Spawns[location].coords
        SetDisplay(false)
        Citizen.Wait(2000)
        SetEntityCoords(ped, pos.x, pos.y, pos.z)
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
        Citizen.Wait(500)
        SetEntityCoords(ped, pos.x, pos.y, pos.z)
        SetEntityHeading(ped, pos.h)
        FreezeEntityPosition(ped, false)
        SetEntityVisible(PlayerPedId(), true)
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
        SwitchIN()
    end
end)

function SetDisplay(bool)
    choosingSpawn = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = "ui",
        status = bool
    })
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if choosingSpawn then
            DisableAllControlActions(0)
        else
            Citizen.Wait(1000)
        end
    end
end)

RegisterNetEvent('qb-houses:client:setHouseConfig')
AddEventHandler('qb-houses:client:setHouseConfig', function(houseConfig)
    Config.Houses = houseConfig
end)

RegisterNetEvent('apartments:client:setupSpawnUI')
AddEventHandler('apartments:client:setupSpawnUI', function(bool, cData)
    TriggerEvent('qb-weathersync:client:EnableSync')
    QBCore.Functions.TriggerCallback('apartments:GetOwnedApartment', function(result)
        if result ~= nil then
            TriggerEvent('qb-spawn:client:setupSpawns', cData, false, nil)
            TriggerEvent('qb-spawn:client:openUI', true)
            TriggerEvent("apartments:client:SetHomeBlip", result.type)
        else
            TriggerEvent('qb-spawn:client:setupSpawns', cData, true, Apartments.Locations)
            TriggerEvent('qb-spawn:client:openUI', true)
        end
    end, cData.citizenid)
    TriggerEvent('qb-spawn:client:setupSpawns', cData, false, nil)
    TriggerEvent('qb-spawn:client:openUI', bool,true)
end)

RegisterNetEvent('qb-spawn:client:setupSpawns')
AddEventHandler('qb-spawn:client:setupSpawns', function(cData, new, apps)
    isNew = new
    if not new then
        QBCore.Functions.TriggerCallback('qb-spawn:server:isJailed', function(lmfao, tt)

            if lmfao == false then  
                QBCore.Functions.TriggerCallback('qb-spawn:server:getOwnedHouses', function(houses)
                    local myHouses = {}
                    
                    if houses ~= nil then
                        for i = 1, (#houses), 1 do
                            table.insert(myHouses, {
                                house = houses[i].house,
                                label = Config.Houses[houses[i].house].adress,
                            })
                        end
                    end
                    SendNUIMessage({
                        action = "setupLocations",
                        locations = Config.Spawns,
                        houses = myHouses,
                    })
                  --  Citizen.Wait(500)
            
                end, cData.citizenid)
            else
                SetDisplay(false)
                Citizen.Wait(2000)
                SetEntityCoords(PlayerPedId(), 1769.14, 257709, 45.72)
                TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
                TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
                Citizen.Wait(500)
                SetEntityCoords(PlayerPedId(), 1769.14, 257709, 45.72)
                SetEntityHeading(PlayerPedId(), 269.01)
                FreezeEntityPosition(PlayerPedId(), false)
                SetEntityVisible(PlayerPedId(), true)
                TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
                TriggerEvent('QBCore:Client:OnPlayerLoaded')
                SwitchIN()
                TriggerEvent('beginJail', tt)
            end
        end, cData.citizenid)
    elseif new then
        SendNUIMessage({
            action = "setupAppartements",
            locations = apps,
        })
    end
    TriggerEvent("debug", 'Spawn: Setup', 'success')
end)


-- Gta V Switch
local cloudOpacity = 0.01
local muteSound = true

function SwitchIN()
    local timer = GetGameTimer()
    while true do
        ClearScreen()
        Citizen.Wait(0)
        if GetGameTimer() - timer > 5000 then
            SwitchInPlayer(PlayerPedId())
            ClearScreen()
            while GetPlayerSwitchState() ~= 12 do
                Citizen.Wait(0)
                ClearScreen()
            end
            DoScreenFadeIn(500)
            break
        end
    end

    TriggerEvent('qb-weathersync:client:EnableSync')
	SetEntityHealth(PlayerPedId(), 200.0)


end




function ToggleSound(state)
    if state then
        StartAudioScene("MP_LEADERBOARD_SCENE");
    else
        StopAudioScene("MP_LEADERBOARD_SCENE");
    end
end

function ClearScreen()
    SetCloudHatOpacity(cloudOpacity)
    HideHudAndRadarThisFrame()
    SetDrawOrigin(0.0, 0.0, 0.0, 0)
end

RegisterNetEvent('qb-spawn:client:openUI')
AddEventHandler('qb-spawn:client:openUI', function(value)
    SetEntityVisible(PlayerPedId(), false)
    ToggleSound(muteSound)
    if not IsPlayerSwitchInProgress() then
        CreateThread(function()
            Wait(1000)
            DoScreenFadeIn(750)
        end)
        SwitchOutPlayer(PlayerPedId(), 1, 1)
    end
    while GetPlayerSwitchState() ~= 5 do
        Citizen.Wait(0)
        ClearScreen()
    end

    ClearScreen()
    Citizen.Wait(0)
    
    ToggleSound(false)
    SetDisplay(value)

    TriggerEvent("debug", 'Spawn: Open UI', 'success')
end)