Auth = exports.plouffe_lib:Get("Auth")

CreateThread(function()
    local players = GetPlayers()
    
    for k,v in pairs(players) do
        local xPlayer = exports.ooc_core:getPlayerFromId(v)
        if xPlayer then
            KeysFnc:AssurePlayerKey(xPlayer)
        end
    end
end)

RegisterNetEvent("plouffe_carkeys:sendConfig",function()
    local playerId = source
    local registred, key = Auth:Register(playerId)

    if registred then
        local cbArray = Keys
        cbArray.Utils.MyAuthKey = key
        TriggerClientEvent("plouffe_carkeys:getConfig",playerId,cbArray)
    else
        TriggerClientEvent("plouffe_carkeys:getConfig",playerId,nil)
    end
end)

RegisterNetEvent("plouffe_carkeys:getKeys",function(useCurrentVehicle,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_carkeys:getKeys") then
            KeysFnc:AddPlayerKeys(playerId,useCurrentVehicle)
        end
    end
end)

RegisterNetEvent("plouffe_carkeys:hotWiredCar",function(success,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_carkeys:hotWiredCar") then
            KeysFnc:PlayerHotWireCar(playerId,success)
        end
    end
end)

RegisterNetEvent("plouffe_carkeys:giveOtherPlayerKeys",function(vehicleNetId,target,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_carkeys:giveOtherPlayerKeys") then
            KeysFnc:GivePlayerKey(playerId,target,vehicleNetId)
        end
    end
end)

RegisterNetEvent("plouffe_carkeys:lockUnlock",function(vehicleNetId,plate,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_carkeys:lockUnlock") then
            KeysFnc:LockUnlock(playerId,vehicleNetId,plate)
        end
    end
end)

RegisterNetEvent("plouffe_carkeys:lockpickedVehicle",function(vehicleNetId,type,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_carkeys:lockpickedVehicle") then
            KeysFnc:LockPickedVehicle(playerId,vehicleNetId,type)
        end
    end
end)

RegisterNetEvent("plouffe_carkeys:failedLockpick",function(vehicleNetId,remove,item,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_carkeys:failedLockpick") then
            KeysFnc:OnFailedLockpick(playerId,vehicleNetId,remove,item)
        end
    end
end)

RegisterNetEvent("plouffe_carkeys:getmykeys",function(authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_carkeys:getmykeys") then
            local xPlayer = exports.ooc_core:getPlayerFromId(playerId)
            local playerIndex = KeysFnc:GeneratePlayerIndexFromXplayer(xPlayer)

            KeysFnc:AssurePlayerKey(xPlayer)
            
            TriggerClientEvent("plouffe_carkeys:updateClientKeys", playerId, Keys.PlayerKeys[playerIndex])
        end
    end
end)