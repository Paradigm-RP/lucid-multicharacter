local QBCore = exports['qb-core']:GetCoreObject()
local charPed = nil

Citizen.CreateThread(function()
   while true do
      Citizen.Wait(0)
      if NetworkIsSessionStarted() then
         DisplayRadar(false)
         TriggerEvent('qb-multicharacter:client:chooseChar')
         return
      end
   end
end)

local spawnCoords = {
   ['x'] = 434.05877,
   ['y'] = -645.6762,
   ['z'] = 27.73022,
   ['h'] = 80.605484
}

function LoadAnim(dict)
   while not HasAnimDictLoaded(dict) do
      RequestAnimDict(dict)
      Wait(10)
   end
end

local startingAnims = {
   {
      anim = "single_team_loop_boss",
      dict = "anim@heists@heist_corona@single_team"
   }
}
local anims = {
   {anim = "shakeoff_1", dict = "move_m@_idles@shake_off"},
   {anim = "wave_e", dict = "friends@frj@ig_1"},
   {anim = "wave_b", dict = "friends@frj@ig_1"}
}

--- CODE


local choosingCharacter = false
local cam = nil
function openCharMenu(bool)

   QBCore.Functions.TriggerCallback(
       'lucid-multicharacter:server:getPermissions', function(data)
          SetNuiFocus(bool, bool)
          SendNUIMessage({action = "ui", toggle = bool, allowedSlots = data, usePermission = Config.useSlotsByPermission, userCanDeleteCharacter = Config.userCanDeleteCharacter})
          choosingCharacter = bool
          skyCam(bool)
          
      end)
end

RegisterNUICallback('deleteCharacter', function(data)
   local citizenid = data.citizenid
   TriggerServerEvent('lucid-multicharacter:server:deleteCharacter', citizenid)
end)

RegisterNUICallback('closeUI', function()
   openCharMenu(false)
end)

RegisterNUICallback('disconnectButton', function()
   SetEntityAsMissionEntity(charPed, true, true)
   TriggerServerEvent('qb-multicharacter:server:disconnect')
end)

RegisterNUICallback('selectCharacter', function(data)
   local cData = data.cData
   local randAnims = math.random(1, #anims)
   LoadAnim(anims[randAnims]["dict"])
   TaskPlayAnim(charPed, anims[randAnims]["dict"], anims[randAnims]["anim"],
                2.0, 2.0, 60000, 1, 0, false, false, false)
   Citizen.Wait(3500)
   DoScreenFadeOut(10)
   Citizen.Wait(1000)
   TriggerServerEvent('qb-multicharacter:server:loadUserData', cData)
   SetEntityAsMissionEntity(charPed, true, true)
   DeleteEntity(charPed)
   NetworkEndTutorialSession()
   openCharMenu(false)
end)

RegisterNetEvent('qb-multicharacter:client:closeNUI')
AddEventHandler('qb-multicharacter:client:closeNUI', function()
   SetNuiFocus(false, false)
end)

local Countdown = 1

RegisterNetEvent('qb-multicharacter:client:chooseChar')
AddEventHandler('qb-multicharacter:client:chooseChar', function()
   SetEntityVisible(PlayerPedId(), false, false)
   local interior = GetInteriorAtCoords(405.1,-953.96,-99.1)

   SetNuiFocus(false, false)
   DoScreenFadeOut(10)
   
   Citizen.Wait(500)
   SetEntityCoords(PlayerPedId(), Config.HiddenCoords.x, Config.HiddenCoords.y,
   Config.HiddenCoords.z)
   FreezeEntityPosition(PlayerPedId(), true)
   LoadInterior(interior)
   while not IsInteriorReady(interior) do
       Citizen.Wait(1000)
   end
   FreezeEntityPosition(PlayerPedId(), true)
   Citizen.Wait(1000)
   ShutdownLoadingScreenNui()
   NetworkSetTalkerProximity(0.0)
   openCharMenu(true)

end)

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

RegisterNetEvent('lucid-multicharacter:client:spawn')
AddEventHandler('lucid-multicharacter:client:spawn', function()
   local timer = GetGameTimer()
   SetNuiFocus(false, false)
   ToggleSound(true)
   ToggleSound(muteSound)
   DoScreenFadeIn(0)

   if not IsPlayerSwitchInProgress() then SwitchOutPlayer(PlayerPedId(), 1, 1) end
   while GetPlayerSwitchState() ~= 5 do
      Citizen.Wait(0)
      ClearScreen()
   end

   ClearScreen()
   SetEntityCoords(PlayerPedId(), spawnCoords.x, spawnCoords.y, spawnCoords.z)
   SetEntityHeading(PlayerPedId(), spawnCoords.h)
   Citizen.Wait(0)
   while true do
      ClearScreen()
      Citizen.Wait(0)
      if GetGameTimer() - timer > 5000 then
         SwitchInPlayer(PlayerPedId())
         ClearScreen()
         CreateThread(function()
            Wait(1000)
            DoScreenFadeOut(350)
         end)

         while GetPlayerSwitchState() ~= 12 do
            Citizen.Wait(0)
            ClearScreen()
         end

         break
      end
   end
   DoScreenFadeIn(0)
   SetTimecycleModifier('default')
   SetCamActive(cam, false)
   DestroyCam(cam, true)
   RenderScriptCams(false, false, 1, true, true)
   FreezeEntityPosition(PlayerPedId(), false)
   StopCamShaking(cam, true)
   DoScreenFadeIn(250)
   ToggleSound(false)
   FreezeEntityPosition(PlayerPedId(), false)
   SetEntityVisible(PlayerPedId(), true)
   TriggerEvent('qb-weathersync:client:EnableSync')
   TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
   TriggerEvent('QBCore:Client:OnPlayerLoaded')
   SetEntityHealth(PlayerPedId(), 200.0)
   Citizen.Wait(200)
   NetworkEndTutorialSession()
   TriggerEvent('qb-clothes:client:CreateFirstCharacter')
end)

function selectChar()
   openCharMenu(true)
end

RegisterNetEvent('qb-multicharacter:settoggle')
AddEventHandler('qb-multicharacter:settoggle', function(toggle)
   SendNUIMessage({action = "ui", toggle = toggle})
end)


RegisterNUICallback('cDataPed', function(data)
   local cData = data.cData
   SetEntityAsMissionEntity(charPed, true, true)
   DeleteEntity(charPed)
   local randStartingAnims = math.random(1, #startingAnims)

   if cData ~= nil then
      QBCore.Functions.TriggerCallback('qb-multicharacter:server:getSkin',
                                       function(model, data)
         model = model ~= nil and tonumber(model) or false
         if model then
           Citizen.CreateThread(function()
                    RequestModel(model)
                    while not HasModelLoaded(model) do
                        Citizen.Wait(0)
                    end
                    charPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98, Config.PedCoords.h, false, true)
                    Citizen.Wait(200)

                    LoadAnim(startingAnims[randStartingAnims]["dict"])
                    if randStartingAnims == 2 or randStartingAnims == 3 or randStartingAnims == 4 then
                        TaskPlayAnim(charPed, startingAnims[randStartingAnims]["dict"], startingAnims[randStartingAnims]["anim"], 2.0, 2.0, 3000, 1, 0, false, false, false)
                    else
                        TaskPlayAnim(charPed, startingAnims[randStartingAnims]["dict"], startingAnims[randStartingAnims]["anim"], 2.0, 2.0, -1, 1, 0, false, false, false)
                    end
                    SetPedComponentVariation(charPed, 0, 0, 0, 2)
                    FreezeEntityPosition(charPed, false)
                    SetEntityInvincible(charPed, true)
                    PlaceObjectOnGroundProperly(charPed)
                    SetBlockingOfNonTemporaryEvents(charPed, true)
                    data = json.decode(data)
          
                    TriggerEvent('qb-clothing:client:loadPlayerClothing', data, charPed)
                end)
         else
            Citizen.CreateThread(function()
               local randommodels = {"mp_m_freemode_01", "mp_f_freemode_01"}
               local model = GetHashKey(randommodels[math.random(1,
                                                                 #randommodels)])
               RequestModel(model)
               while not HasModelLoaded(model) do Citizen.Wait(0) end
               charPed = CreatePed(2, model, Config.PedCoords.x,
                                   Config.PedCoords.y,
                                   Config.PedCoords.z - 0.98,
                                   Config.PedCoords.h, false, true)

               Citizen.Wait(200)

               LoadAnim(startingAnims[randStartingAnims]["dict"])
               if randStartingAnims == 2 or randStartingAnims == 3 or
                   randStartingAnims == 4 then
                  TaskPlayAnim(charPed,
                               startingAnims[randStartingAnims]["dict"],
                               startingAnims[randStartingAnims]["anim"], 2.0,
                               2.0, 3000, 1, 0, false, false, false)
               else
                  TaskPlayAnim(charPed,
                               startingAnims[randStartingAnims]["dict"],
                               startingAnims[randStartingAnims]["anim"], 2.0,
                               2.0, -1, 1, 0, false, false, false)
               end
               SetPedComponentVariation(charPed, 0, 0, 0, 2)
               FreezeEntityPosition(charPed, false)
               SetEntityInvincible(charPed, true)
               PlaceObjectOnGroundProperly(charPed)
               SetBlockingOfNonTemporaryEvents(charPed, true)
            end)
         end
         DoScreenFadeIn(1000)
      end, cData.citizenid)
   else

      Citizen.CreateThread(function()
         local randommodels = {"mp_m_freemode_01", "mp_f_freemode_01"}
         local model = GetHashKey(randommodels[math.random(1, #randommodels)])
         RequestModel(model)
         while not HasModelLoaded(model) do Citizen.Wait(0) end
         charPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y,
                             Config.PedCoords.z - 0.98, Config.PedCoords.h,
                             false, true)
         Citizen.Wait(200)
         LoadAnim(startingAnims[randStartingAnims]["dict"])

         if randStartingAnims == 2 or randStartingAnims == 3 or
             randStartingAnims == 4 then
            TaskPlayAnim(charPed, startingAnims[randStartingAnims]["dict"],
                         startingAnims[randStartingAnims]["anim"], 2.0, 2.0,
                         3000, 1, 0, false, false, false)
         else
            TaskPlayAnim(charPed, startingAnims[randStartingAnims]["dict"],
                         startingAnims[randStartingAnims]["anim"], 2.0, 2.0, -1,
                         1, 0, false, false, false)
         end
         SetPedComponentVariation(charPed, 0, 0, 0, 2)
         FreezeEntityPosition(charPed, false)
         SetEntityInvincible(charPed, true)
         PlaceObjectOnGroundProperly(charPed)
         SetBlockingOfNonTemporaryEvents(charPed, true)
         DoScreenFadeIn(1000)

      end)
   end
end)

RegisterNUICallback('setupCharacters', function()
   QBCore.Functions.TriggerCallback("test:yeet", function(result)
      SendNUIMessage({action = "setupCharacters", characters = result})
   end)
end)

RegisterNetEvent('lucid:characterDeleted')
AddEventHandler('lucid:characterDeleted', function()
   Citizen.Wait(1000)
   SendNUIMessage({action = "characterDeleted"})


end)

RegisterNUICallback('removeBlur', function()
   SetTimecycleModifier('default')
end)

RegisterNUICallback('createNewCharacter', function(data)
   local cData = data
   DoScreenFadeOut(150)
   if cData.gender == "man" then
      cData.gender = 0
   elseif cData.gender == "woman" then
      cData.gender = 1
   end

   TriggerServerEvent('qb-multicharacter:server:createCharacter', cData)
   TriggerServerEvent('qb-multicharacter:server:GiveStarterItems')
   Citizen.Wait(500)
end)


function skyCam(bool)
   SetRainFxIntensity(0.0)
   TriggerEvent('qb-weathersync:client:DisableSync')
   SetWeatherTypePersist('EXTRASUNNY')
   SetWeatherTypeNow('EXTRASUNNY')
   SetWeatherTypeNowPersist('EXTRASUNNY')
   NetworkOverrideClockTime(12, 0, 0)

   if bool then
   
      SetTimecycleModifier('hud_def_blur')
      SetTimecycleModifierStrength(1.0)
      FreezeEntityPosition(PlayerPedId(), false)

      cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 407.6979, -968.4216, -98.90416,0.0, 0.0, 154.45, 45.5, false, 0)


      SetCamActive(cam, true)
      RenderScriptCams(true, false, 1, true, true)
      ShakeCam(cam, "DRUNK_SHAKE", 0.4)
      DoScreenFadeIn(10)

   else

      SetTimecycleModifier('default')
      SetCamActive(cam, false)
      DestroyCam(cam, true)
      RenderScriptCams(false, false, 1, true, true)
      FreezeEntityPosition(PlayerPedId(), false)
      StopCamShaking(cam, true)

   end
end
