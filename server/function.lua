function KeysFnc:Notify(playerId,type,txt,length)
    if not type then type = "inform" end
    if not length then length = 5000 end
    if not txt or not playerId then return end
    TriggerClientEvent('plouffe_lib:notify', playerId, { type = type, text = txt, length = length})
end

function KeysFnc:GeneratePlayerIndexFromXplayer(xPlayer)
    return xPlayer.identifier.."_"..xPlayer.characterId
end
    
function KeysFnc:AssurePlayerKey(xPlayer)
    local playerIndex = KeysFnc:GeneratePlayerIndexFromXplayer(xPlayer)

    if not Keys.PlayerKeys[playerIndex] then
        Keys.PlayerKeys[playerIndex] = {
            keys = {},
            lockpick = {},
            hotwire = Server.hotWiredCars
        }
    end
end

function KeysFnc:AddPlayerKeys(playerId,useCurrentVehicle)
    local ped = GetPlayerPed(playerId)
    local vehicleId = GetVehiclePedIsIn(ped, false)

    if useCurrentVehicle ~= true then
        vehicleId = NetworkGetEntityFromNetworkId(useCurrentVehicle)
    end

    local plate = GetVehicleNumberPlateText(vehicleId)
    local xPlayer = exports.ooc_core:getPlayerFromId(playerId)
    local playerIndex = KeysFnc:GeneratePlayerIndexFromXplayer(xPlayer)

    if playerIndex and plate then
        Keys.PlayerKeys[playerIndex].keys[plate] = true

        TriggerClientEvent('plouffe_lib:notify', playerId, { type = 'inform', text = 'Vous avez recu les clés du véhicule immatriculer '..tostring(plate), length = 5000 })
    
        KeysFnc:RefreshPlayerKeys(playerIndex,playerId)
    end
end

function KeysFnc:RefreshPlayerKeys(playerIndex,playerId)
    Keys.PlayerKeys[playerIndex].hotwire = Server.hotWiredCars
    TriggerClientEvent("plouffe_carkeys:updateClientKeys", playerId, Keys.PlayerKeys[playerIndex])
end

function KeysFnc:PlayerHotWireCar(playerId,success)
    local ped = GetPlayerPed(playerId)
    local vehicleId = GetVehiclePedIsIn(ped, false)
    local plate = GetVehicleNumberPlateText(vehicleId)

    if not Server.hotWiredCars[plate] then
        local xPlayer = exports.ooc_core:getPlayerFromId(playerId)
        local playerIndex = KeysFnc:GeneratePlayerIndexFromXplayer(xPlayer)
        
        Server.damagedConsole[plate] = true
        Server.hotWiredCars[plate] = {success = success}
        
        if success then
            Keys.PlayerKeys[playerIndex].hotwire[plate] = {success = success}
            TriggerClientEvent("plouffe_carkeys:updateClientKeys", playerId, Keys.PlayerKeys[playerIndex])
        end
        
        KeysFnc:SyncHotWire()
    end
end

function KeysFnc:SyncHotWire()
    for k,v in pairs(Keys.PlayerKeys) do
        v.hotwire = Server.hotWiredCars
    end

    TriggerClientEvent("plouffe_carkeys:updateHotWire", -1, Server.hotWiredCars)
end

function KeysFnc:GivePlayerKey(playerId,target,vehicleNetId)
    local xPlayer = exports.ooc_core:getPlayerFromId(playerId)
    local playerIndex = KeysFnc:GeneratePlayerIndexFromXplayer(xPlayer)
    local myPed = GetPlayerPed(playerId)
    local currentPedVehicle = GetVehiclePedIsIn(myPed, false)
    local vehicleId = NetworkGetEntityFromNetworkId(vehicleNetId)
    local plate = GetVehicleNumberPlateText(vehicleId)

    if Keys.PlayerKeys[playerIndex].keys[plate] then
        if currentPedVehicle ~= 0 and target == nil then
            for i = -1, 6, 1 do
                local pedInSeat = GetPedInVehicleSeat(currentPedVehicle, i)
                if pedInSeat ~= 0 then
                    if pedInSeat ~= myPed then
                        local pedInSeatId = NetworkGetEntityOwner(pedInSeat)
                        local xPed = exports.ooc_core:getPlayerFromId(pedInSeatId)

                        if xPed then
                            local xPedIndex = KeysFnc:GeneratePlayerIndexFromXplayer(xPed)
                            if not Keys.PlayerKeys[xPedIndex].keys[plate] then
                                Keys.PlayerKeys[xPedIndex].keys[plate] = true

                                TriggerClientEvent('plouffe_lib:notify', playerId, { type = 'inform', text = 'Vous donner les clés du véhicule immatriculer '..tostring(plate), length = 5000 })
                                TriggerClientEvent('plouffe_lib:notify', pedInSeatId, { type = 'inform', text = 'Vous avez recu les clés du véhicule immatriculer '..tostring(plate), length = 5000 })
                                
                                KeysFnc:RefreshPlayerKeys(xPedIndex,pedInSeatId)
                                break
                            end
                        end
                    end
                end
            end
        elseif currentPedVehicle == 0 and target == nil then
            for i = -1, 6, 1 do
                local pedInSeat = GetPedInVehicleSeat(vehicleId, i)
                if pedInSeat ~= 0 then
                    if pedInSeat ~= myPed then
                        local pedInSeatId = NetworkGetEntityOwner(pedInSeat)
                        local xPed = exports.ooc_core:getPlayerFromId(pedInSeatId)

                        if xPed then
                            local xPedIndex = KeysFnc:GeneratePlayerIndexFromXplayer(xPed)
                            if not Keys.PlayerKeys[xPedIndex].keys[plate] then
                                Keys.PlayerKeys[xPedIndex].keys[plate] = true

                                TriggerClientEvent('plouffe_lib:notify', playerId, { type = 'inform', text = 'Vous donner les clés du véhicule immatriculer '..tostring(plate), length = 5000 })
                                TriggerClientEvent('plouffe_lib:notify', pedInSeatId, { type = 'inform', text = 'Vous avez recu les clés du véhicule immatriculer '..tostring(plate), length = 5000 })
                                
                                KeysFnc:RefreshPlayerKeys(xPedIndex,pedInSeatId)
                                break
                            end
                        end
                    end
                end
            end
        elseif currentPedVehicle == 0 and target ~= nil then
            local xTarget = exports.ooc_core:getPlayerFromId(target)
            if xTarget then
                local targetIndex = KeysFnc:GeneratePlayerIndexFromXplayer(xTarget)

                Keys.PlayerKeys[targetIndex].keys[plate] = true

                TriggerClientEvent('plouffe_lib:notify', playerId, { type = 'inform', text = 'Vous donner les clés du véhicule immatriculer '..tostring(plate), length = 5000 })
                TriggerClientEvent('plouffe_lib:notify', target, { type = 'inform', text = 'Vous avez recu les clés du véhicule immatriculer '..tostring(plate), length = 5000 })

                KeysFnc:RefreshPlayerKeys(targetIndex,target)
            end
        end
    end
end

function KeysFnc:LockUnlock(playerId,vehicleNetId,plate)
    if vehicleNetId then
        local vehicleId = NetworkGetEntityFromNetworkId(vehicleNetId)
        local xPlayer = exports.ooc_core:getPlayerFromId(playerId)
        local playerIndex = KeysFnc:GeneratePlayerIndexFromXplayer(xPlayer)
        
        if Keys.PlayerKeys[playerIndex].keys[plate] then
            KeysFnc:ChangeLockStatus(vehicleId,playerId)
        end
    else
        local ped = GetPlayerPed(playerId)
        local vehicleId = GetVehiclePedIsIn(ped)

        KeysFnc:ChangeLockStatus(vehicleId,playerId)
    end
end

function KeysFnc:ChangeLockStatus(vehicleId,playerId)
    local doorState = GetVehicleDoorLockStatus(vehicleId)
    local plate = GetVehicleNumberPlateText(vehicleId)
    
    -- if doorState == 2 then
    if Server.locked_cars[plate] then 
        Server.locked_cars[plate] = nil
        SetVehicleDoorsLocked(vehicleId, 1)
        self:Notify(playerId,"success","Portes dévérouiller")
    else
        Server.locked_cars[plate] = true
        SetVehicleDoorsLocked(vehicleId, 2)
        self:Notify(playerId,"error","Portes vérouiller")
    end
end

function KeysFnc:LockPickedVehicle(playerId,vehicleNetId,type)
    if type == "door" then
        local vehicleId = NetworkGetEntityFromNetworkId(vehicleNetId)
        SetVehicleDoorsLocked(vehicleId, 1)
    elseif type == "ignition" then
        local xPlayer = exports.ooc_core:getPlayerFromId(playerId)
        local playerIndex = KeysFnc:GeneratePlayerIndexFromXplayer(xPlayer)
        local vehicleId = NetworkGetEntityFromNetworkId(vehicleNetId)
        local plate = GetVehicleNumberPlateText(vehicleId)

        Keys.PlayerKeys[playerIndex].lockpick[plate] = true
        Server.lockPickedCars[plate] = true
        Server.damagedConsole[plate] = true

        TriggerClientEvent("plouffe_carkeys:updateClientKeys", playerId, Keys.PlayerKeys[playerIndex])
    end
end

function KeysFnc:IsVehicleConsoleDamaged(vehicleNetId)
    local vehicleId = NetworkGetEntityFromNetworkId(vehicleNetId)
    local plate = GetVehicleNumberPlateText(vehicleId)

    return Server.damagedConsole[plate]
end

function KeysFnc:OnFailedLockpick(playerId,vehicleNetId,remove,item)
    local vehicleId = NetworkGetEntityFromNetworkId(vehicleNetId)
    local plate = GetVehicleNumberPlateText(vehicleId)

    if remove then
        exports.ox_inventory:RemoveItem(playerId,item,1)
    end

    Server.damagedConsole[plate] = true
end

function KeysFnc:GiveVehicleKeysFromServer(playerId,vehicleNetId)
    local xPlayer = exports.ooc_core:getPlayerFromId(playerId)
    local playerIndex = KeysFnc:GeneratePlayerIndexFromXplayer(xPlayer)
    local vehicleId = NetworkGetEntityFromNetworkId(vehicleNetId)
    local plate = GetVehicleNumberPlateText(vehicleId)

    Keys.PlayerKeys[playerIndex].keys[plate] = true
    self:RefreshPlayerKeys(playerIndex,playerId)

    TriggerClientEvent('plouffe_lib:notify', playerId, { type = 'inform', text = 'Vous avez recu les clés du véhicule immatriculer '..tostring(plate), length = 5000 })
end

function GiveVehicleKeysFromServer(playerId,vehicleNetId)
    KeysFnc:GiveVehicleKeysFromServer(playerId,vehicleNetId)
end