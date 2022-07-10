Keys = {}
KeysFnc = {} 
TriggerServerEvent("plouffe_carkeys:sendConfig")

RegisterNetEvent("plouffe_carkeys:getConfig",function(list)
	if list == nil then
		CreateThread(function()
			while true do
				Wait(0)
				Keys = nil
				KeysFnc = nil
			end
		end)
	else
		Keys = list
		KeysFnc:Start()
	end
end)