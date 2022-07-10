local Callback = exports.plouffe_lib:Get("Callback")
local Utils = exports.plouffe_lib:Get("Utils")

function KeysFnc:Start()
    TriggerEvent('ooc_core:getCore', function(Core)
        while not Core.Player:IsPlayerLoaded() do
            Wait(500)
        end

        Keys.Player = Core.Player:GetPlayerData()

        self:ExportsAllZones()
        self:RegisterEvents()
    end)
end

function KeysFnc:ExportsAllZones()
    -- for k,v in pairs(Keys.Zone) do
    --     exports.plouffe_lib:ValidateZoneData(v)
    -- end
end

function KeysFnc:RegisterEvents()
    RegisterNetEvent("plouffe_lib:inVehicle", function(inVehicle, vehicleId)
        Keys.Utils.inCar = inVehicle
        Keys.Utils.carId = vehicleId
        KeysFnc:InVehicleThread()
    end)

    RegisterNetEvent("evo_main:pedIsArmed", function(isArmed,weaponHash)
        Keys.Utils.isArmed = isArmed
        Keys.Utils.currentWeaponHash = weaponHash
    end)

    RegisterNetEvent("plouffe_carkeys:from_zone", function(data)
        if KeysFnc[data.fnc] then
            KeysFnc[data.fnc](KeysFnc, data)
        end
    end)

    RegisterNetEvent("plouffe_carkeys:updateClientKeys",function(newKeys)
        Keys.MyKeys = newKeys
    end)

    RegisterNetEvent("plouffe_carkeys:updateHotWire",function(hotWiredCars)
        Keys.MyKeys.hotwire = hotWiredCars
    end)

    TriggerServerEvent("plouffe_carkeys:getmykeys",Keys.Utils.MyAuthKey)
end

function KeysFnc:FormatNumberValues(current,original)
    local percent = original * 100 / current
    local answer = ""

    if current < original then
        percent = current * 100 / original
    end

    answer = tostring(percent):sub(0,3)

    if answer ~= "100" then
        answer = answer:sub(0,2)
    end

    if tonumber(answer) then
        return tonumber(answer)
    else
        return 0
    end
end

function KeysFnc:GetarrayLenght(a)
    local cb = 0
    for k,v in pairs(a) do
        cb = cb + 1
    end
    return cb
end

function KeysFnc:AlphabeticArray(a)
    local sortedArray = {}
    local indexArray = {}
    local elements = {}

    for k,v in pairs(a) do
        if v.label then
            sortedArray[v.label] = v
            table.insert(indexArray, v.label)
        end
    end

    table.sort(indexArray)

    for k,v in pairs(indexArray) do
        table.insert(elements, sortedArray[v])
    end

    for k,v in pairs(elements) do
        if v.count then
            v.label = v.label.." x "..tostring(v.count)
        elseif v.amount then
            v.label = v.label.." x "..tostring(v.amount)
        end
    end

    return elements
end

function KeysFnc:RequestAnimDict(dict)
    CreateThread(function()
        RequestAnimDict(dict)
    end)
end

function KeysFnc:PlayAnim(type,dict,anim,flag,disablemovement,removeweapon,createprop)
    Keys.Utils.ped = PlayerPedId()
    Keys.Utils.pedCoords = GetEntityCoords(Keys.Utils.ped)
    local ped = Keys.Utils.ped
    local pedCoords = Keys.Utils.pedCoords

    if createprop then
        local attachCoords = vector3(0,0,0)
        local hash = GetHashKey(createprop.prop)
        local boneindx = GetPedBoneIndex(ped, createprop.bone)

        Keys.Utils.currentProp = CreateObject(hash, pedCoords.x, pedCoords.y, pedCoords.z + 0.2,  true,  true, true)
        table.insert(Keys.Utils.currentPropList, Keys.Utils.currentProp)

        SetEntityCollision(Keys.Utils.currentProp, false, true)
        AttachEntityToEntity(Keys.Utils.currentProp, ped, boneindx, createprop.placement.x, createprop.placement.y, createprop.placement.z, createprop.placement.xR, createprop.placement.yR, createprop.placement.zR, true, true, false, true, 1, true)
    end

    if removeweapon then
        if IsPedArmed(ped,7) then
            SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
            Wait(1900)
        end
    end

    if type == "anim" then
        KeysFnc:RequestAnimDict(dict)

        while not HasAnimDictLoaded(dict) do
            KeysFnc:RequestAnimDict(dict)
            Wait(0)
        end

        if not IsEntityPlayingAnim(ped, dict, anim, 3) then
            TaskPlayAnim(ped, dict, anim, 50.0, 0, -1, flag, 0, false, false, false)
        end

        CreateThread(function()
            if not IsEntityPlayingAnim(ped, dict, anim, 3) then
                TaskPlayAnim(ped, dict, anim, 50.0, 0, -1, flag, 0, false, false, false)
            end

            while Keys.Utils.forceAnim do
                Wait(0)

                if IsPedDeadOrDying(ped, true) then
                    break
                end

                if not IsEntityPlayingAnim(ped, dict, anim, 3) then
                    TaskPlayAnim(ped, dict, anim, 50.0, 0, -1, flag, 0, false, false, false)
                end
            end

            Wait(250)

            if createprop then
                DeleteEntity(Keys.Utils.currentProp)
            end

            StopAnimTask(ped, dict, anim, 1.0)
        end)
    elseif type == "scenario" then
        TaskStartScenarioInPlace(ped, dict, 0, true)

        CreateThread(function()
            while Keys.Utils.forceAnim do
                Wait(0)

                if IsPedDeadOrDying(ped, true) then
                    break
                end
            end

            ClearPedTasks(ped)

            if Keys.FoodTruck.intruck then
                Keys.Utils.reAttachToTruck = true
            end
        end)
    end

    CreateThread(function()
        while Keys.Utils.forceAnim do
            Wait(0)

            if disablemovement then
                if IsPedDeadOrDying(ped, true) then
                    break
                end
                DisableControlAction(0, 30, true)
                DisableControlAction(0, 31, true)
                DisableControlAction(0, 36, true)
                DisableControlAction(0, 21, true)
            else
                break
            end
        end
    end)
end

function KeysFnc:CreatePed(coords,heading,weapon,model,network,mission,cb)
    local validModel, modelHash = KeysFnc:AssureModel(KeysFnc:ValidateModel(model))
    local createdPed = CreatePed(1, modelHash, coords or GetEntityCoords(PlayerPedId()), heading or GetEntityHeding(PlayerPedId()), network or false, mission or false)

    if KeysFnc:AssurePed(createdPed) then
        if weapon then
            for k,v in pairs(weapon) do
                local validWeapon, weapon = KeysFnc:AssureWeapon(KeysFnc:ValidateModel(v))
                if validWeapon then
                    GiveWeaponToPed(createdPed, weapon, 100, false, true)
                end
            end
        end
        cb(createdPed)
    end
end

function KeysFnc:CreateVehicle(coords,heading,model,network,mission,cb)
    local model = KeysFnc:ValidateModel(model)
    local loaded = KeysFnc:AssureModel(model)
    if loaded then
        local vehicle = CreateVehicle(model, coords, heading, network, mission)
        cb(vehicle)
    end
end

function KeysFnc:RequestModel(model)
    CreateThread(function()
        RequestModel(model)
    end)
end

function KeysFnc:ValidateModel(model)
    if type(model) == "string" then
        return GetHashKey(model)
    elseif type(model) == "number" then
        return model
    elseif #model then
        if model.model then
            return model[math.random(1,#model)].model
        else
            return model[math.random(1,#model)]
        end
    end
    return "","ERROR INVALID REQUEST"
end

function KeysFnc:AssureModel(model)
    local maxTimes,currentTime = 5000, 0
    KeysFnc:RequestModel(model)
    while not HasModelLoaded(model) and currentTime < maxTimes do
        KeysFnc:RequestModel(model)
        Wait(0)
        currentTime = currentTime + 1
    end
    return HasModelLoaded(model), GetHashKey(model)
end

function KeysFnc:AssureWeapon(weapon)
    local hash = GetHashKey(weapon)
    if IsWeaponValid(weapon) then
        return true,weapon
    elseif IsWeaponValid(hash) then
        return true,hash
    end
    return false, 0
end

function KeysFnc:AssurePed(ped)
    local init = GetGameTimer()
    while not DoesEntityExist(ped) and GetGameTimer() - init <= 1000 do
        Wait(0)
    end
    return DoesEntityExist(ped)
end

function KeysFnc:SetAttributes(ped)
    SetBlockingOfNonTemporaryEvents(ped, true)

    SetEntityInvincible(ped, true)
    return true
end

function KeysFnc:RequestControlOfEntity(entity)
    CreateThread(function()
        NetworkRequestControlOfEntity(entity)
    end)
end

function KeysFnc:GetNetWorkControl(entity)
    local init = GetGameTimer()
    KeysFnc:RequestControlOfEntity(entity)

    while not NetworkHasControlOfEntity(entity) and GetGameTimer() - init <= 10000 do
        KeysFnc:RequestControlOfEntity(entity)
        Wait(250)
    end

    return NetworkHasControlOfEntity(entity)
end

function KeysFnc:IsPedAccessibleForMission(ped)
    if (not ped or ped == -1) then
        return false, "Ped Is nil"
    elseif #(GetEntityCoords(ped) - Keys.Utils.pedCoords) >= 100.0 then
        return false, "To Far"
    elseif ped == Keys.Utils.ped then
        return false, "Same Ped"
    elseif IsPedInAnyVehicle(ped,true) then
        return false, "In Vehicle"
    elseif IsPedArmed(ped,7) then
        return false, "Ped Armed"
    elseif IsPedSwimming(ped) ~= 1 then
        return false, "Ped Is Swiming"
    elseif IsPedFleeing(ped) then
        return false, "Ped Is fleeing"
    elseif IsPedRagdoll(ped) then
        return false, "Ped Is In ragdoll"
    elseif NetworkGetEntityOwner(ped) == -1 then
        return false, "Ped Is a local ped"
    elseif IsPedInMeleeCombat(ped) then
        return false, "Ped is in combat"
    elseif GetPedType(ped) ~= 28 then
        return false, "Ped Is an animal"
    elseif IsPedAPlayer(ped) then
        return false, "Ped Is a player ped"
    elseif IsPedDeadOrDying(ped) then
        return false, "Ped Is Dead"
    end

    return true
end

function KeysFnc:CanPedBeAWitness(ped)
    if (not ped or ped == -1) then
        return false, "Ped Is nil"
    elseif #(GetEntityCoords(ped) - Keys.Utils.pedCoords) >= 250.0 then
        return false, "To Far"
    elseif ped == Keys.Utils.ped then
        return false, "Same Ped"
    elseif IsPedInMeleeCombat(ped) then
        return false, "Ped is in combat"
    elseif GetPedType(ped) == 28 then
        return false, "Ped Is an animal"
    elseif IsPedAPlayer(ped) then
        return false, "Ped Is a player ped"
    elseif IsPedDeadOrDying(ped) then
        return false, "Ped Is Dead"
    end

    return true, "nil"
end

function KeysFnc:SelfCoolDown(time)
    if Keys.Utils.coolDown then
        return
    end

    CreateThread(function()
        Keys.Utils.coolDown = true
        Wait(time)
        Keys.Utils.coolDown = false
    end)
end

function KeysFnc:GetClosestVehicle(radius)
    Keys.Utils.ped = PlayerPedId()
    Keys.Utils.pedCoords = GetEntityCoords(Keys.Utils.ped)
	local plyOffset = GetOffsetFromEntityInWorldCoords(Keys.Utils.ped, 0.0, 1.0, 0.0)
	local rayHandle = StartShapeTestCapsule(Keys.Utils.pedCoords.x, Keys.Utils.pedCoords.y, Keys.Utils.pedCoords.z, plyOffset.x, plyOffset.y, plyOffset.z, radius, 10, Keys.Utils.ped, 7)
	local _, _, _, _, vehicle = GetShapeTestResult(rayHandle)
	return vehicle
end

function KeysFnc:InteractionMenu()
    Keys.Utils.ped = PlayerPedId()
    exports.ooc_menu:Open(Keys.Menu.interaction, function(params)
        if not params then
            return
        end

        if KeysFnc[params.fnc] then
            KeysFnc[params.fnc]("", params)
        end
    end)
end

function KeysFnc:HasVehicleAcces(plate)
    if Keys.MyKeys.keys[plate] or
    Keys.MyKeys.lockpick[plate] or
    KeysFnc:GetHotWireState(plate) == "hotwired" then
        return true
    end
    return false
end

function KeysFnc:IsDriver()
    return GetPedInVehicleSeat(Keys.Utils.carId, -1) == Keys.Utils.ped
end

function KeysFnc:ShouldShutDown()
    if  (IsVehicleEngineStarting(Keys.Utils.carId) or GetIsVehicleEngineRunning(Keys.Utils.carId)) and
        not KeysFnc:HasVehicleAcces(Keys.Utils.currentPlate) then
        return true
    end
    return false
end

function KeysFnc:GetHotWireState(plate)
    if not Keys.MyKeys.hotwire[plate] then
        return "new"
    elseif Keys.MyKeys.hotwire[plate] and Keys.MyKeys.hotwire[plate].success then
        return "hotwired"
    end
    return "broken"
end

function KeysFnc:CanHotWireCurrent()
    if Keys.Utils.inCar and
        KeysFnc:IsDriver() and
        not LocalPlayer.state.cuffed and
        not LocalPlayer.state.dead and
        Keys.Utils.nuiActive and
        not KeysFnc:HasVehicleAcces(Keys.Utils.currentPlate) then
            return true
    end
    return false
end

function KeysFnc:InVehicleThread()
    CreateThread(function()
        while Keys.Utils.inCar do
            local sleepTimer = 1000
            Keys.Utils.ped = PlayerPedId()
            Keys.Utils.currentPlate = GetVehicleNumberPlateText(Keys.Utils.carId)

            if KeysFnc:IsDriver() and not LocalPlayer.state.cuffed and not LocalPlayer.state.dead then
                sleepTimer = 100
                if KeysFnc:ShouldShutDown() then
                    if IsThisModelAHeli(GetEntityModel(Keys.Utils.carId)) then
                        SetHeliBladesSpeed(Keys.Utils.carId, 0.0)
                    end
                    SetVehicleEngineOn(Keys.Utils.carId, false, true, true)
                end

                if KeysFnc:GetHotWireState(Keys.Utils.currentPlate) == "new" and not Keys.Utils.nuiActive and not KeysFnc:HasVehicleAcces(Keys.Utils.currentPlate) then
                    Keys.Utils.nuiActive = true
                    exports.plouffe_lib:ShowNotif("blue","hotwireCar","[H] Pour hotwire")
                end

                if Keys.Utils.nuiActive then
                    if KeysFnc:HasVehicleAcces(Keys.Utils.currentPlate) then
                        Keys.Utils.nuiActive = false
                        exports.plouffe_lib:HideNotif("hotwireCar")
                    end
                end
            end

            Wait(sleepTimer)
        end

        if Keys.Utils.nuiActive then
            Keys.Utils.nuiActive = false
            exports.plouffe_lib:HideNotif("hotwireCar")
        end
    end)
end

function KeysFnc:HotWireCurrent()
    Keys.Utils.forceAnim = true

    KeysFnc:PlayAnim("anim","mini@repair","fixing_a_player",49,false,false,false)

    Utils:ProgressCircle({
        name = "hotwire_shit_cars",
        duration = 45000,
        label = "Hotwire en cours..",
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }
    }, function(cancelled)
        Keys.Utils.forceAnim = false
        if not cancelled then
            KeysFnc:OnHotWireCurrent()
        end
    end)
end

function KeysFnc:OnHotWireCurrent()
    local randi = math.random(0,10)

    if randi <= Keys.hotWire.succesChance then
        Utils:Notify("success", "Vous avez réussi", 5000)
        SetEntityAsMissionEntity(Keys.Utils.carId)
        TriggerServerEvent("plouffe_carkeys:hotWiredCar", true, Keys.Utils.MyAuthKey)
    else
        exports.plouffe_status:Add("Stress", 50)
        Utils:Notify("error", "Vous avez échouer", 5000)
        TriggerServerEvent("plouffe_carkeys:hotWiredCar", false, Keys.Utils.MyAuthKey)
        KeysFnc:DoEffectOnHotWireFail()
    end
end

function KeysFnc:GiveKeys()

    if Keys.Utils.inCar then
        local plate = GetVehicleNumberPlateText(Keys.Utils.carId)
        if Keys.MyKeys.keys[plate] then
            TriggerServerEvent("plouffe_carkeys:giveOtherPlayerKeys", NetworkGetNetworkIdFromEntity(Keys.Utils.carId), nil, Keys.Utils.MyAuthKey)
        else
            Utils:Notify("error", "Vous n'avez pas les clés de ce véhicule", 5000)
        end
    else
        local vehicleId = KeysFnc:GetClosestVehicle(6.0)

        if vehicleId and vehicleId ~= 0 then
            local plate = GetVehicleNumberPlateText(vehicleId)
            local closestPlayer, distance = Utils:GetClosestPlayer()
            local targetId = nil

            if closestPlayer ~= -1 and distance <= 3.5 then
                targetId = GetPlayerServerId(closestPlayer)
                if IsPedInAnyVehicle(GetPlayerPed(closestPlayer), true) then
                    targetId = nil
                end
            end

            if Keys.MyKeys.keys[plate] then
                TriggerServerEvent("plouffe_carkeys:giveOtherPlayerKeys", NetworkGetNetworkIdFromEntity(vehicleId), targetId, Keys.Utils.MyAuthKey)
            else
                Utils:Notify("error", "Vous n'avez pas les clés de ce véhicule", 5000)
            end

        else
            Utils:Notify("error", "Impossible de trouver un véhicule", 5000)
        end
    end
end

function KeysFnc:CheckDoorStatus(vehicleId)
    for k,v in pairs(Keys.Doors) do
        if GetIsDoorValid(vehicleId, v.partId) == 1 then
            if IsVehicleDoorDamaged(vehicleId, v.partId) then
                return false
            end
        end
    end
    return true
end

function KeysFnc:EnumerateAllNearsCarsForKeys()
    Keys.Utils.ped = PlayerPedId()
    Keys.Utils.pedCoords = GetEntityCoords(Keys.Utils.ped)

    local distance = 1.0
    local starTimer = GetGameTimer()
    local vehicleId = 0

    repeat
        local plyOffset = GetOffsetFromEntityInWorldCoords(Keys.Utils.ped, 0.0, distance, 0.0)
        local rayHandle = StartShapeTestCapsule(Keys.Utils.pedCoords.x, Keys.Utils.pedCoords.y, Keys.Utils.pedCoords.z, plyOffset.x, plyOffset.y, plyOffset.z, 10.0, 10, Keys.Utils.ped, 7)
        local _, _, _, _, closeCarId = GetShapeTestResult(rayHandle)
        local plate = GetVehicleNumberPlateText(closeCarId)
        distance = distance + 1

        if Keys.MyKeys.keys[plate] then
            vehicleId = closeCarId
        end
    until distance > 120 or GetGameTimer() - starTimer > 10000 or vehicleId ~= 0

    return vehicleId
end

function KeysFnc:LockUnlockCar()
    if Keys.Utils.coolDown then
        return
    end

    if Keys.Utils.inCar then
        if KeysFnc:CheckDoorStatus(Keys.Utils.inCar) then
            KeysFnc:SelfCoolDown(1000)
            local plate = GetVehicleNumberPlateText(Keys.Utils.carId)
            TriggerServerEvent("plouffe_carkeys:lockUnlock", false, plate, Keys.Utils.MyAuthKey)
        else
            Utils:Notify("error", "Les portes de ce véhicule sont endomager", 5000)
        end
    else
        local vehicleId = KeysFnc:EnumerateAllNearsCarsForKeys()

        if vehicleId and vehicleId ~= 0 then
            if KeysFnc:CheckDoorStatus(vehicleId) then
                local plate = GetVehicleNumberPlateText(vehicleId)
                KeysFnc:SelfCoolDown(1000)
                KeysFnc:PlayAnim("anim","anim@mp_player_intmenu@key_fob@","fob_click",49,false,false,false)
                TriggerServerEvent("plouffe_carkeys:lockUnlock", NetworkGetNetworkIdFromEntity(vehicleId), plate, Keys.Utils.MyAuthKey)
            else
                Utils:Notify("error", "Les portes de ce véhicule sont endomager", 5000)
            end
        else
            Utils:Notify("error", "Aucun véhicule trouver / vous n'avez pas les clées", 5000)
        end
    end
end

function KeysFnc:OpenVehicleInteractionMenu()
    local vehicleId = KeysFnc:EnumerateAllNearsCarsForKeys()

    if vehicleId and vehicleId ~= 0 then
        local vehicleModel = GetEntityModel(vehicleId)
        local textLabel = tostring(GetDisplayNameFromVehicleModel(vehicleModel)):lower()
        local plate = tostring(GetVehicleNumberPlateText(vehicleId)):upper()
        local firstLetter = textLabel:sub(1,textLabel:len() - (textLabel:len() -1 )):upper()
        local lowLabel = textLabel:sub(2,textLabel:len())

        Keys.VehicleMenu.Global[1] = {
            id = 1,
            header = "Véhicule: "..firstLetter..lowLabel,
            txt = "Plaque: "..plate,
            params = {
                event = "",
                args = {
                    fnc = ""
                }
            }
        }

        exports.ooc_menu:Open(Keys.VehicleMenu.Global,function(params)
            if not params then
                return
            end

            if KeysFnc[params.fnc] then
                KeysFnc[params.fnc]("",params,vehicleId)
            end
        end)
    end
end

function KeysFnc:VehicleInterations(params,vehicleId)
    local type = params.type

	if 	type == "lockUnlock" then
        KeysFnc:LockUnlockCar()
    else
        if KeysFnc:GetNetWorkControl(vehicleId) then
            if type == "engine" then
                if GetIsVehicleEngineRunning(vehicleId) then
                    SetVehicleEngineOn(vehicleId,false,true,true)
                else
                    SetVehicleEngineOn(vehicleId,true,true,true)
                end

                KeysFnc:PlayAnim("anim","anim@mp_player_intmenu@key_fob@","fob_click",49,false,false,false)
                KeysFnc:OpenVehicleInteractionMenu()
            elseif type == "windows" then
                Keys.Utils.windowState = not Keys.Utils.windowState

                if Keys.Utils.windowState then
                    RollDownWindows(vehicleId)
                else
                    for i = 0, 6, 1 do
                        RollUpWindow(vehicleId, i)
                    end
                end

                KeysFnc:PlayAnim("anim","anim@mp_player_intmenu@key_fob@","fob_click",49,false,false,false)
                KeysFnc:OpenVehicleInteractionMenu()
            elseif type == "trunk" then
                if GetVehicleDoorAngleRatio(vehicleId, 5) > 0.5 then
                    SetVehicleDoorShut(vehicleId, 5, true)
                else
                    SetVehicleDoorOpen(vehicleId, 5, false, true)
                end

                KeysFnc:PlayAnim("anim","anim@mp_player_intmenu@key_fob@","fob_click",49,false,false,false)
                KeysFnc:OpenVehicleInteractionMenu()
            elseif type == "toplight" then
                if IsVehicleInteriorLightOn(vehicleId) then
                    SetVehicleInteriorlight(vehicleId, false)
                else
                    SetVehicleInteriorlight(vehicleId, true)
                end

                KeysFnc:PlayAnim("anim","anim@mp_player_intmenu@key_fob@","fob_click",49,false,false,false)
                KeysFnc:OpenVehicleInteractionMenu()
            elseif type == "headlights" then
                local hasLight, lightsOn, highBeamOn = GetVehicleLightsState(vehicleId)
                local lightMultiplier = GetVehicleLightMultiplier(vehicleId)

                if lightMultiplier < 1.0 then
                    SetVehicleLightMultiplier(vehicleId, 1.0)
                else
                    SetVehicleLightMultiplier(vehicleId, 0.0)
                end

                KeysFnc:PlayAnim("anim","anim@mp_player_intmenu@key_fob@","fob_click",49,false,false,false)
                KeysFnc:OpenVehicleInteractionMenu()
            elseif type == "convertible" then
                if IsVehicleAConvertible(vehicleId, false) then
                    local roofState = GetConvertibleRoofState(vehicleId)
                    if roofState == 0 then
                        LowerConvertibleRoof(vehicleId, false)
                    elseif roofState == 2 then
                        RaiseConvertibleRoof(vehicleId, false)
                    end
                else
                    Utils:Notify("error", "Ce véhicule na pas de convertible")
                end

                KeysFnc:PlayAnim("anim","anim@mp_player_intmenu@key_fob@","fob_click",49,false,false,false)
                KeysFnc:OpenVehicleInteractionMenu()
            elseif type == "neons" then
                KeysFnc:NeonMenu(vehicleId)
            elseif type == "hydro" then
                KeysFnc:HydroMenu(vehicleId)
            end
        end
    end
end

function KeysFnc:NeonMenu(vehicleId)
    exports.ooc_menu:Open(Keys.VehicleMenu.Neon, function(params)
        if not params then
            return
        end

        local state = true
        if params.neonId == "rng" then
            KeysFnc:DoNeonRng(vehicleId)

            KeysFnc:PlayAnim("anim","anim@mp_player_intmenu@key_fob@","fob_click",49,false,false,false)
            KeysFnc:NeonMenu(vehicleId)
        elseif params.neonId == "goback" then
            KeysFnc:OpenVehicleInteractionMenu()
        else
            if IsVehicleNeonLightEnabled(vehicleId, params.neonId) then
                state = false
            end

            SetVehicleNeonLightEnabled(vehicleId,params.neonId,state)

            KeysFnc:PlayAnim("anim","anim@mp_player_intmenu@key_fob@","fob_click",49,false,false,false)
            KeysFnc:NeonMenu(vehicleId)
        end
    end)
end

function KeysFnc:DoNeonRng(vehicleId)
    Keys.Utils.neonRng = not Keys.Utils.neonRng

    CreateThread(function()
        while Keys.Utils.neonRng and DoesEntityExist(vehicleId) and (GetPedInVehicleSeat(vehicleId, -1) == 0 or GetPedInVehicleSeat(vehicleId, -1) == PlayerPedId()) do
            local randi = math.random(0,3)
            local state = true

            if IsVehicleNeonLightEnabled(vehicleId, randi) then
                state = false
            end

            SetVehicleNeonLightEnabled(vehicleId,randi,state)

            Wait(100)
        end

        for i = 0, 3, 1 do
            SetVehicleNeonLightEnabled(vehicleId,i,true)
        end
    end)
end

function KeysFnc:HydroMenu(vehicleId)
    exports.ooc_menu:Open(Keys.VehicleMenu.Hydro, function(params)
        if not params then
            return
        end

        local state = true
        if params.wheelId == "rng" then
            KeysFnc:DoHydroRng(vehicleId)

            KeysFnc:PlayAnim("anim","anim@mp_player_intmenu@key_fob@","fob_click",49,false,false,false)
            KeysFnc:HydroMenu(vehicleId)
        elseif params.neonId == "goback" then
            KeysFnc:OpenVehicleInteractionMenu()
        else
            if type(params.wheelId) == "string" or type(params.wheelId) == "number" then
                local currentValue = GetHydraulicWheelValue(vehicleId, params.wheelId)

                if currentValue >= 1.0 then
                    SetHydraulicWheelValue(vehicleId, params.wheelId, 0.0)
                else
                    SetHydraulicWheelValue(vehicleId, params.wheelId, 2.0)
                end
            else
                for k,v in pairs(params.wheelId) do
                    local currentValue = GetHydraulicWheelValue(vehicleId,v)

                    if currentValue >= 1.0 then
                        SetHydraulicWheelValue(vehicleId, v, 0.0)
                    else
                        SetHydraulicWheelValue(vehicleId, v, 2.0)
                    end
                end
            end

            KeysFnc:PlayAnim("anim","anim@mp_player_intmenu@key_fob@","fob_click",49,false,false,false)
            KeysFnc:HydroMenu(vehicleId)
        end
    end)
end

function KeysFnc:DoHydroRng(vehicleId)
    Keys.Utils.hydrolicRng = not Keys.Utils.hydrolicRng

    CreateThread(function()
        while Keys.Utils.hydrolicRng and DoesEntityExist(vehicleId) and (GetPedInVehicleSeat(vehicleId, -1) == 0 or GetPedInVehicleSeat(vehicleId, -1) == PlayerPedId()) do
            local randi = math.random(1,#Keys.Utils.hydrolicWheels)
            local wheelId = Keys.Utils.hydrolicWheels[randi]

            if type(wheelId) == "table" then
                for k,v in pairs(wheelId) do
                    local currentValue = GetHydraulicWheelValue(vehicleId,v)

                    if currentValue >= 1.0 then
                        SetHydraulicWheelValue(vehicleId, v, 0.0)
                    else
                        SetHydraulicWheelValue(vehicleId, v, 2.0)
                    end
                end
            else
                local currentValue = GetHydraulicWheelValue(vehicleId, wheelId)

                if currentValue >= 1.0 then
                    SetHydraulicWheelValue(vehicleId, wheelId, 0.0)
                else
                    SetHydraulicWheelValue(vehicleId, wheelId, 2.0)
                end
            end

            Wait(750)
        end
    end)
end

function KeysFnc:GetScanValues(state, max)
    if state == 1 then
        return {
            x = 0 - max,
            y = max,
            xAddition = max * 2,
            yAddition = max * 2
        }
    elseif state == 2 then
        return {
            x = max,
            y = max,
            xAddition = max * 2,
            yAddition = max * 2
        }
    elseif state == 3 then
        return {
            x = max,
            y = 0 - max,
            xAddition = max * 2,
            yAddition = max * 2
        }
    elseif state == 4 then
        return {
            x = 0 - max,
            y = 0 - max,
            xAddition = max * 2,
            yAddition = max * 2
        }
    end

    return
end

function KeysFnc:FindWitness(inVehicle)
    if Keys.Utils.probeTestActive then
        return 0
    end

    Keys.Utils.probeTestActive = true
    Keys.Utils.ped = PlayerPedId()
    Keys.Utils.pedCoords = GetEntityCoords(Keys.Utils.ped)
    local initialCoords = Keys.Utils.pedCoords
    local currentScanState = 1
    local maxScanDistance = 1
    local values = KeysFnc:GetScanValues(currentScanState, maxScanDistance)
    local done = false
    local starTimer = GetGameTimer()
    local _, _, _, _, pedId,vehicle = false,false,false,false,0,0
    local ignoredPed = {}

    repeat
        local plyOffset = GetOffsetFromEntityInWorldCoords(Keys.Utils.ped, values.x + 0.0, values.y + 0.0, 0.0)
        local rayHandle = StartShapeTestCapsule(Keys.Utils.pedCoords.x, Keys.Utils.pedCoords.y, Keys.Utils.pedCoords.z, plyOffset.x, plyOffset.y, plyOffset.z, 50.0, 12, Keys.Utils.ped, 7)
        _, _, _, _, pedId = GetShapeTestResult(rayHandle)
        local canBeWitness, reason =  KeysFnc:CanPedBeAWitness(pedId)

        if currentScanState == 1 then
            if values.xAddition > 0 then
                values.x = values.x + 1
                values.xAddition = values.xAddition - 1
            else
                currentScanState = currentScanState + 1
                values = KeysFnc:GetScanValues(currentScanState, maxScanDistance)
            end
        elseif currentScanState == 2 then
            if values.yAddition > 0 then
                values.y = values.y - 1
                values.yAddition = values.yAddition - 1
            else
                currentScanState = currentScanState + 1
                values = KeysFnc:GetScanValues(currentScanState, maxScanDistance)
            end
        elseif currentScanState == 3 then
            if values.xAddition > 0 then
                values.x = values.x - 1
                values.xAddition = values.xAddition - 1
            else
                currentScanState = currentScanState + 1
                values = KeysFnc:GetScanValues(currentScanState, maxScanDistance)
            end
        elseif currentScanState == 4 then
            if values.yAddition > 0 then
                values.y = values.y + 1
                values.yAddition = values.yAddition - 1
            else
                currentScanState = 1
                maxScanDistance = maxScanDistance + 1
            end
        end

        if not canBeWitness then
            pedId = 0
        end

        Wait(0)
    until done or GetGameTimer() - starTimer > 1000000 or pedId ~= 0 or maxScanDistance > 20 or #(GetEntityCoords(Keys.Utils.ped) - initialCoords) > 15.0

    if pedId ~= 0 then
        Keys.Utils.probeTestActive = false
        return pedId
    end

    if inVehicle then
        currentScanState = 1
        maxScanDistance = 1
        values = KeysFnc:GetScanValues(currentScanState, maxScanDistance)
        done = false
        starTimer = GetGameTimer()
        _, _, _, _, pedId,vehicle = false,false,false,false,0,0
        ignoredPed = {}

        repeat
            local add = false
            local plyOffset = GetOffsetFromEntityInWorldCoords(Keys.Utils.ped, values.x + 0.0, values.y + 0.0, 0.0)
            local rayHandle = StartShapeTestCapsule(Keys.Utils.pedCoords.x, Keys.Utils.pedCoords.y, Keys.Utils.pedCoords.z, plyOffset.x, plyOffset.y, plyOffset.z, 50.0, 10, Keys.Utils.ped, 7)
            _, _, _, _, vehicle = GetShapeTestResult(rayHandle)
            pedId = KeysFnc:EnumerateSeatToFindFirstPed(vehicle, ignoredPed)
            local canBeWitness, reason =  KeysFnc:CanPedBeAWitness(pedId)

            if currentScanState == 1 then
                if values.xAddition > 0 then
                    values.x = values.x + 1
                    values.xAddition = values.xAddition - 1
                else
                    currentScanState = currentScanState + 1
                    values = KeysFnc:GetScanValues(currentScanState, maxScanDistance)
                end
            elseif currentScanState == 2 then
                if values.yAddition > 0 then
                    values.y = values.y - 1
                    values.yAddition = values.yAddition - 1
                else
                    currentScanState = currentScanState + 1
                    values = KeysFnc:GetScanValues(currentScanState, maxScanDistance)
                end
            elseif currentScanState == 3 then
                if values.xAddition > 0 then
                    values.x = values.x - 1
                    values.xAddition = values.xAddition - 1
                else
                    currentScanState = currentScanState + 1
                    values = KeysFnc:GetScanValues(currentScanState, maxScanDistance)
                end
            elseif currentScanState == 4 then
                if values.yAddition > 0 then
                    values.y = values.y + 1
                    values.yAddition = values.yAddition - 1
                else
                    currentScanState = 1
                    maxScanDistance = maxScanDistance + 1
                end
            end

            if not canBeWitness then
                ignoredPed[pedId] = true
                pedId = 0
            end

            Wait(0)
        until done or GetGameTimer() - starTimer > 1000000 or pedId ~= 0 or maxScanDistance > 15 or #(GetEntityCoords(Keys.Utils.ped) - initialCoords) > 15.0
    end

    Keys.Utils.probeTestActive = false
    return pedId
end

function KeysFnc:EnumerateSeatToFindFirstPed(vehicle, ignoredPed)
    for i = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)), 1 do
        local pedInSeat = GetPedInVehicleSeat(vehicle,i)
        if pedInSeat ~= 0 and not ignoredPed[pedInSeat] then
            return pedInSeat
        end
    end

    return 0
end

function KeysFnc:Checkignition()
    if Keys.Utils.carId ~= 0 then
        Keys.Utils.forceAnim = true

        KeysFnc:PlayAnim("anim","mini@repair","fixing_a_player",49,false,false,false)

        Utils:ProgressCircle({
            name = "checking_ignition_state",
            duration = 7500,
            label = "Vérification en cours..",
            useWhileDead = false,
            canCancel = true,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }
        }, function(cancelled)
            if not cancelled then
                Callback:Await("plouffe_carkeys:getVehicleIgnitionState", function(isBroken)

                    if isBroken then
                        Utils:Notify("error","L'ignition de ce véchicule semble avoir été endommager")
                    else
                        Utils:Notify("success","L'ignition de ce véchicule semble intact")
                    end

                    Keys.Utils.forceAnim = false
                end, NetworkGetNetworkIdFromEntity(Keys.Utils.carId), Keys.Utils.MyAuthKey)
            end
        end)
    else
        Utils:Notify("error","Aucun véhicule trouver", 5000)
    end
end

function KeysFnc:DoEffectOnHotWireFail()
    CreateThread(function()
        Keys.Utils.ped = PlayerPedId()
        Keys.Utils.pedCoords = GetEntityCoords(Keys.Utils.ped)
        local coords = GetOffsetFromEntityInWorldCoords(Keys.Utils.ped, 0.0, 1.0, 0.0)
        local smoke_particle_asset = "core"
        local smoke_particle = "veh_backfire"
        local startEffect = UseParticleFxAssetNextCall(smoke_particle_asset)
        local effect = StartNetworkedParticleFxNonLoopedAtCoord(smoke_particle, coords, -1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, false, false, false)
    end)
end

function KeysFnc.LockPickCurrent(item)
    if not LocalPlayer.state.cuffed and not LocalPlayer.state.dead then
        local speed = math.ceil(math.random(6, 15))
        local amount = math.random(5,7)
        local plate = GetVehicleNumberPlateText(Keys.Utils.carId)
        local alertRandi = math.random(0,10)

        if item == "advancedlockpick" then
            speed = math.ceil(math.random(12, 15))
            amount = math.random(3,5)
        end

        if Keys.Utils.inCar and KeysFnc:IsDriver() then
            if KeysFnc:GetHotWireState(plate) ~= "broken" then
                Keys.Utils.forceAnim = true

                KeysFnc:PlayAnim("anim","mini@repair","fixing_a_player",49,false,false,false)
                local success = exports.roundbar:Start(amount, speed)

                if success then
                    Utils:Notify("success", "Vous avez réussi a lockpick le véhicule", 5000)
                    TriggerServerEvent("plouffe_carkeys:lockpickedVehicle",NetworkGetNetworkIdFromEntity(Keys.Utils.carId),"ignition",Keys.Utils.MyAuthKey)
                else
                    exports.plouffe_status:Add("Stress", 50)
                    CreateThread(function()
                        local removeItem = false
                        SetVehicleAlarm(Keys.Utils.carId, true)
                        SetVehicleAlarmTimeLeft(Keys.Utils.carId, 60000)
                        StartVehicleAlarm(Keys.Utils.carId)

                        if math.random(0,10) <= 3 then
                            removeItem = true
                        end

                        TriggerServerEvent("plouffe_carkeys:failedLockpick", NetworkGetNetworkIdFromEntity(Keys.Utils.carId), removeItem, item, Keys.Utils.MyAuthKey)

                        local witness = KeysFnc:FindWitness(true)
                        if witness ~= 0 then
                            TaskReactAndFleePed(witness,Keys.Utils.ped)
                            exports.plouffe_dispatch:SendAlert("StolenCar")
                        end
                    end)
                end

                Keys.Utils.forceAnim = false
            else
                Utils:Notify("error", "La console de ce véhicule est semble etre endommager", 5000)
            end
        else
            if not Keys.Utils.inCar then
                local vehicleId = KeysFnc:GetClosestVehicle(2.0)
                plate = GetVehicleNumberPlateText(vehicleId)

                if vehicleId and vehicleId ~= 0 then
                    Keys.Utils.forceAnim = true

                    KeysFnc:PlayAnim("anim","veh@break_in@0h@p_m_one@","low_force_entry_ds",49,false,false,false)

                    local success = exports.roundbar:Start(amount, speed)

                    if success then
                        Utils:Notify("success", "Vous avez réussi a lockpick le véhicule", 5000)
                        TriggerServerEvent("plouffe_carkeys:lockpickedVehicle",NetworkGetNetworkIdFromEntity(Keys.Utils.carId),"door",Keys.Utils.MyAuthKey)
                        KeysFnc:GetNetWorkControl(vehicleId)
                        SetVehicleDoorsLocked(vehicleId, 1)
                        SetEntityAsMissionEntity(vehicleId)
                    else
                        exports.plouffe_status:Add("Stress", 50)
                        CreateThread(function()
                            local stolenCarDriver = GetPedInVehicleSeat(vehicleId, -1)
                            if math.random(0,10) <= 3 then
                                TriggerServerEvent("plouffe_carkeys:removeitem", item, Keys.Utils.MyAuthKey)
                            end
                            if stolenCarDriver ~= 0 then
                                if KeysFnc:CanPedBeAWitness(stolenCarDriver) then
                                    TaskReactAndFleePed(stolenCarDriver,Keys.Utils.ped)
                                end
                            else
                                SetVehicleAlarm(vehicleId, true)
                                SetVehicleAlarmTimeLeft(vehicleId, 60000)
                                StartVehicleAlarm(vehicleId)
                            end
                            local witness = KeysFnc:FindWitness(true)
                            if witness ~= 0 then
                                TaskReactAndFleePed(witness,Keys.Utils.ped)
                                exports.plouffe_dispatch:SendAlert("StolenCarIgnoreDriver")
                            end
                        end)
                    end
                    Keys.Utils.forceAnim = false

                end
            end
        end
    end
end
exports("lockpickVehicle", KeysFnc.LockPickCurrent)

function getSpecificVehicleKey(vehicleId)
    TriggerServerEvent("plouffe_carkeys:getKeys", NetworkGetNetworkIdFromEntity(vehicleId), Keys.Utils.MyAuthKey)
end
exports("getSpecificVehicleKey", getSpecificVehicleKey)

function getCurrentVehicleKeys()
    CreateThread(function()
        local initTimer = GetGameTimer()

        while not IsPedInAnyVehicle(PlayerPedId(), false) and GetGameTimer() - initTimer < 10000 do
            Wait(100)
        end

        TriggerServerEvent("plouffe_carkeys:getKeys", true, Keys.Utils.MyAuthKey)
    end)
end
exports("getCurrentVehicleKeys", getCurrentVehicleKeys)

RegisterCommand("checkIgnition", function()
    if not LocalPlayer.state.cuffed and not LocalPlayer.state.dead and KeysFnc:IsDriver() then
        KeysFnc:Checkignition()
    end
end, false)

RegisterCommand("givekey", function()
    if not LocalPlayer.state.cuffed and not LocalPlayer.state.dead then
        KeysFnc:GiveKeys()
    end
end, false)

RegisterCommand("+hotWireCurrentCar", function()
    if KeysFnc:CanHotWireCurrent() then
        if KeysFnc:GetHotWireState(Keys.Utils.currentPlate) == "broken" then
            Utils:Notify("error", "Ce véhicule semble endomager", 5000)
        elseif KeysFnc:GetHotWireState(Keys.Utils.currentPlate) ~= "hotwired" and KeysFnc:GetHotWireState(Keys.Utils.currentPlate) ~= "broken" then
            KeysFnc:HotWireCurrent()
        end
    end
end)

RegisterCommand("+lockUnlock", function()
    Keys.InputsData.isPressed = true

    while Keys.InputsData.isPressed and Keys.InputsData.pressTiming < 100 do
        Wait(0)
        Keys.InputsData.pressTiming = Keys.InputsData.pressTiming + 1
    end

    if not LocalPlayer.state.cuffed and not LocalPlayer.state.dead then
        if Keys.InputsData.pressTiming >= 100 then
            KeysFnc:OpenVehicleInteractionMenu()
        else
            KeysFnc:LockUnlockCar()
        end
    end

    Keys.InputsData.pressTiming = 0
end)

RegisterCommand("-lockUnlock", function()
    Keys.InputsData.isPressed = false
end)

RegisterKeyMapping('+lockUnlock', 'Vérouiller / dévérouiller un véhicule', 'keyboard', 'U')
RegisterKeyMapping('+hotWireCurrentCar', 'HotWire un véhicule', 'keyboard', 'H')