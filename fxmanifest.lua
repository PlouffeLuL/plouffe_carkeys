fx_version "adamant"

games { 'gta5'}
lua54 'yes'

client_scripts {
	'configs/clientConfig.lua',
    'client/*.lua'
}

server_scripts {
	'configs/serverConfig.lua',
    'server/*.lua'
}

dependencies {
    "plouffe_lib"
}

server_exports {
    "GiveVehicleKeysFromServer"
}