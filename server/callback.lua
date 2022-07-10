Callback:RegisterServerCallback("plouffe_carkeys:getVehicleIgnitionState", function(source,cb,vehicleNetId,authkey)
    if Auth:Validate(source,authkey) then
        if Auth:Events(source,"plouffe_carkeys:getVehicleIgnitionState") then
            cb(KeysFnc:IsVehicleConsoleDamaged(vehicleNetId))
        end
    end
end)