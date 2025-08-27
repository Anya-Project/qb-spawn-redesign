local QBCore = exports['qb-core']:GetCoreObject()
local choosingSpawn = false
local Houses = {}
local cam = nil
local cam2 = nil

local camZPlus1 = 1500
local camZPlus2 = 50
local pointCamCoords = 75
local pointCamCoords2 = 0
local cam1Time = 500
local cam2Time = 1000

local PTFX_DICT = 'core'
local PTFX_ASSET = 'ent_dst_elec_fire_sp'
local PTFX_SCALE = 1.75
local PTFX_DURATION = 1500
local PTFX_AUDIONAME = 'ent_amb_elec_crackle'
local PTFX_AUDIOREF = 0
local LOOP_AMOUNT = 7
local LOOP_DELAY = 75

local lastSelectedColor = '#00A2FF'

RegisterNetEvent('ap-spawn:client:updateTheme', function(newColor)
    lastSelectedColor = newColor
    SendNUIMessage({ action = 'updateTheme', color = newColor })
end)

local function PlaySpawnPtfx(pedId)
    CreateThread(function()
        if not DoesEntityExist(pedId) then return end
        RequestNamedPtfxAsset(PTFX_DICT)
        while not HasNamedPtfxAssetLoaded(PTFX_DICT) do
            Wait(5)
        end
        local particleHandles = {}
        for i = 0, LOOP_AMOUNT do
            UseParticleFxAsset(PTFX_DICT)
            PlaySoundFromEntity(-1, PTFX_AUDIONAME, pedId, PTFX_AUDIOREF, false, 0)
            local particle = StartParticleFxLoopedOnEntity(PTFX_ASSET, pedId, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, PTFX_SCALE, false, false, false)
            table.insert(particleHandles, particle)
            Wait(LOOP_DELAY)
        end
        Wait(PTFX_DURATION)
        for _, particle in ipairs(particleHandles) do
            if DoesParticleFxLoopedExist(particle) then
                StopParticleFxLooped(particle, false)
            end
        end
        RemoveNamedPtfxAsset(PTFX_DICT)
    end)
end

local function SetDisplay(bool)
    choosingSpawn = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({ action = 'showUi', status = bool, color = lastSelectedColor })
end

RegisterNetEvent('qb-spawn:client:openUI', function(value)
    SetEntityVisible(PlayerPedId(), false)
    DoScreenFadeOut(250)
    Wait(1000)
    DoScreenFadeIn(250)
    QBCore.Functions.GetPlayerData(function(PlayerData)
        cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', PlayerData.position.x, PlayerData.position.y, PlayerData.position.z + camZPlus1, -85.00, 0.00, 0.00, 100.00, false, 0)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 1, true, true)
    end)
    Wait(500)
    SetDisplay(value)
end)

RegisterNetEvent('qb-houses:client:setHouseConfig', function(houseConfig) Houses = houseConfig end)
RegisterNetEvent('qb-spawn:client:setupSpawns', function(cData, new, apps)
    if not new then
        QBCore.Functions.TriggerCallback('qb-spawn:server:getOwnedHouses', function(houses)
            local myHouses = {}
            if houses ~= nil and #houses > 0 then
                for i = 1, #houses, 1 do
                    myHouses[#myHouses + 1] = {house = houses[i].house, label = Houses[houses[i].house].adress}
                end
            end
            SendNUIMessage({action = 'setupLocations', locations = QB.Spawns, houses = myHouses, isNew = new})
        end, cData.citizenid)
    elseif new then
        SendNUIMessage({action = 'setupAppartements', locations = apps, isNew = new})
    end
end)

RegisterNUICallback('exit', function(_, cb) SetDisplay(false); cb('ok') end)

local function SetCam(campos)
    cam2 = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', campos.x, campos.y, campos.z + camZPlus1, 300.00, 0.00, 0.00, 110.00, false, 0)
    PointCamAtCoord(cam2, campos.x, campos.y, campos.z + pointCamCoords)
    SetCamActiveWithInterp(cam2, cam, cam1Time, true, true)
    if DoesCamExist(cam) then DestroyCam(cam, true) end
    Wait(cam1Time)
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', campos.x, campos.y, campos.z + camZPlus2, 300.00, 0.00, 0.00, 110.00, false, 0)
    PointCamAtCoord(cam, campos.x, campos.y, campos.z + pointCamCoords2)
    SetCamActiveWithInterp(cam, cam2, cam2Time, true, true)
    SetEntityCoords(PlayerPedId(), campos.x, campos.y, campos.z)
end

RegisterNUICallback('setCam', function(data, cb)
    local location = tostring(data.posname); local type = tostring(data.type)
    DoScreenFadeOut(200); Wait(500); DoScreenFadeIn(200)
    if DoesCamExist(cam) then DestroyCam(cam, true) end
    if DoesCamExist(cam2) then DestroyCam(cam2, true) end
    if type == 'current' then QBCore.Functions.GetPlayerData(function(PlayerData) SetCam(PlayerData.position) end)
    elseif type == 'house' then SetCam(Houses[location].coords.enter)
    elseif type == 'normal' then SetCam(QB.Spawns[location].coords)
    elseif type == 'appartment' then SetCam(Apartments.Locations[location].coords.enter) end
    cb('ok')
end)

RegisterNUICallback('getCoords', function(data, cb)
    local locationKey = tostring(data.name); local type = tostring(data.type); local dossierData = {}
    if type == 'current' then
        local pData = QBCore.Functions.GetPlayerData()
        dossierData.coords = pData.position; dossierData.label = 'Last Location'; dossierData.district = 'UNKNOWN'; dossierData.weather = 'VARIABLE'
    elseif type == 'house' then
        dossierData.coords = Houses[locationKey].coords.enter; dossierData.label = Houses[locationKey].adress; dossierData.district = 'PRIVATE PROPERTY'; dossierData.weather = 'STABLE'
    elseif type == 'normal' then
        local spawnData = QB.Spawns[locationKey]
        if spawnData then dossierData.coords = spawnData.coords; dossierData.label = spawnData.label; dossierData.district = spawnData.district or 'N/A'; dossierData.weather = spawnData.weather or 'N/A' end
    elseif type == 'appartment' then
        dossierData.coords = Apartments.Locations[locationKey].coords.enter; dossierData.label = Apartments.Locations[locationKey].label; dossierData.district = 'RESIDENTIAL TOWER'; dossierData.weather = 'STABLE'
    end
    if dossierData.coords and dossierData.label then SendNUIMessage({ action = 'updateDossierData', dossier = dossierData }) end
    cb('ok')
end)

local function PreSpawnPlayer()
    SetDisplay(false)
    DoScreenFadeOut(500)
    Wait(2000)
end

local function PostSpawnPlayer()
    local ped = PlayerPedId() 
    
    FreezeEntityPosition(ped, false)
    RenderScriptCams(false, true, 500, true, true)
    if DoesCamExist(cam) then DestroyCam(cam, true) end
    if DoesCamExist(cam2) then DestroyCam(cam2, true) end
    
    SetEntityVisible(ped, true) 
    
    DoScreenFadeIn(1200)
    PlaySpawnPtfx(ped)
    Wait(PTFX_DURATION + 200)

    if exports['ap_multicharacter'] then
        exports['ap_multicharacter']:ToggleMulticharacterHud(true)
    end
end

RegisterNUICallback('chooseAppa', function(data, cb)
    local appaYeet = data.appType
    SetDisplay(false)
    DoScreenFadeOut(500)
    Wait(5000)
    TriggerServerEvent('apartments:server:CreateApartment', appaYeet, Apartments.Locations[appaYeet].label, true)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    PostSpawnPlayer() 
    cb('ok')
end)

RegisterNUICallback('spawnplayer', function(data, cb)
    local location = tostring(data.spawnloc)
    local type = tostring(data.typeLoc)
    local ped = PlayerPedId()
    
    if type == 'current' then
        PreSpawnPlayer()
        QBCore.Functions.GetPlayerData(function(pd)
            SetEntityCoords(ped, pd.position.x, pd.position.y, pd.position.z)
            SetEntityHeading(ped, pd.position.a)
            FreezeEntityPosition(ped, false)
        end)
        local PlayerData = QBCore.Functions.GetPlayerData()
        local insideMeta = PlayerData.metadata['inside']
        if insideMeta.house ~= nil then TriggerEvent('qb-houses:client:LastLocationHouse', insideMeta.house)
        elseif insideMeta.apartment.apartmentType ~= nil or insideMeta.apartment.apartmentId ~= nil then
            TriggerEvent('qb-apartments:client:LastLocationHouse', insideMeta.apartment.apartmentType, insideMeta.apartment.apartmentId)
        end
    elseif type == 'house' then
        PreSpawnPlayer()
        TriggerEvent('qb-houses:client:enterOwnedHouse', location)
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    elseif type == 'normal' then
        PreSpawnPlayer()
        local pos = QB.Spawns[location].coords
        SetEntityCoords(ped, pos.x, pos.y, pos.z)
        Wait(500)
        SetEntityCoords(ped, pos.x, pos.y, pos.z)
        SetEntityHeading(ped, pos.w)
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    end

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    PostSpawnPlayer() 
    cb('ok')
end)

CreateThread(function()
    while true do
        if choosingSpawn then DisableAllControlActions(0); Wait(0) else Wait(1000) end
    end
end)

exports('GetHouseConfig', function() return Houses end)
exports('GetApartmentConfig', function() return Apartments end)