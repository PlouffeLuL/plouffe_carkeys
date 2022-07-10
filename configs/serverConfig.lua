Auth = exports.plouffe_lib:Get("Auth")
Callback = exports.plouffe_lib:Get("Callback")

Server = {
	Init = false,
	hotWiredCars = {},
	lockPickedCars = {},
	damagedConsole = {},
	locked_cars = {}
}

Keys = {}
KeysFnc = {} 

Keys.Player = {}

Keys.PlayerKeys = {}

Keys.MyKeys = {
	keys = {},
	lockpick = {},
	hotwire = {}
}

Keys.Utils = {
	ped = 0,
	pedCoords = vector3(0,0,0),
	inCar = false,
    carId = 0,
	isCuffed = false,
	currentPropList = {},
	currentProp = 0,
	nuiActive = false,
	coolDown = false,
	neonRng = false,
	hydrolicRng = false,
	hydrolicWheels = {1,0,4,5,{4,5},{1,0}},
	windowState = false,
	probeTestActive = false
}

Keys.hotWire = {
	succesChance = 1
}

Keys.Doors = {
	{
		boneName = "door_dside_f",
		partId = 0,
		side = "door_front_left"
	},
	{
		boneName = "door_dside_r",
		partId = 2,
		side = "door_rear_left"
	},
	{
		boneName = "door_pside_f",
		partId = 1,
		side = "door_front_right"
	},
	{
		boneName = "door_pside_r",
		partId = 3,
		side = "door_rear_right"
	}
}

Keys.InputsData = {
	isPressed = false,
	pressTiming = 0
}

Keys.VehicleMenu = {
	Global = {
		{
			id = 1,
			header = "",
			txt = "",
			params = {
				event = "",
				args = {
					fnc = ""
				}
			}
		},
		{
			id = 2,
			header = "Vérouiller / dévérouiller les portes",
			txt = "Vérouiller / dévérouiller les portes de votre véhicule",
			params = {
				event = "",
				args = {
					type = "lockUnlock",
					fnc = "VehicleInterations"
				}
			}
		},
		{
			id = 3,
			header = "Démarreur a distance",
			txt = "Allume / eteind le moteur",
			params = {
				event = "",
				args = {
					type = "engine",
					fnc = "VehicleInterations"
				}
			}
		},
		{
			id = 4,
			header = "Néons",
			txt = "Allume / eteind les néons",
			params = {
				event = "",
				args = {
					type = "neons",
					fnc = "VehicleInterations"
				}
			}
		},
		{
			id = 5,
			header = "Vitres électrique",
			txt = "Monte / descend les vitres électriques",
			params = {
				event = "",
				args = {
					type = "windows",
					fnc = "VehicleInterations"
				}
			}
		},
		{
			id = 6,
			header = "Valise",
			txt = "Ouvre / ferme la valise",
			params = {
				event = "",
				args = {
					type = "trunk",
					fnc = "VehicleInterations"
				}
			}
		},
		{
			id = 7,
			header = "Top light",
			txt = "Ouvre / ferme la lumiere plafoniere",
			params = {
				event = "",
				args = {
					type = "toplight",
					fnc = "VehicleInterations"
				}
			}
		},
		{
			id = 8,
			header = "Lumieres",
			txt = "Ouvre / ferme les lumieres",
			params = {
				event = "",
				args = {
					type = "headlights",
					fnc = "VehicleInterations"
				}
			}
		},
		{
			id = 9,
			header = "Convertible",
			txt = "Ouvre / ferme le toit convertible",
			params = {
				event = "",
				args = {
					type = "convertible",
					fnc = "VehicleInterations"
				}
			}
		},
		{
			id = 10,
			header = "Hydrauliques",
			txt = "System hydraulique",
			params = {
				event = "",
				args = {
					type = "hydro",
					fnc = "VehicleInterations"
				}
			}
		},
	},
	Neon = {
		{
			id = 1,
			header = "Néon devant",
			txt = "Allumer / Eteindre",
			params = {
				event = "",
				args = {
					neonId = 2,
					fnc = "ChangeNeonState"
				}
			}
		},
		{
			id = 2,
			header = "Néon derrière",
			txt = "Allumer / Eteindre",
			params = {
				event = "",
				args = {
					neonId = 3,
					fnc = "ChangeNeonState"
				}
			}
		},
		{
			id = 3,
			header = "Néon gauche",
			txt = "Allumer / Eteindre",
			params = {
				event = "",
				args = {
					neonId = 0,
					fnc = "ChangeNeonState"
				}
			}
		},
		{
			id = 4,
			header = "Néon droite",
			txt = "Allumer / Eteindre",
			params = {
				event = "",
				args = {
					neonId = 1,
					fnc = "ChangeNeonState"
				}
			}
		},
		{
			id = 5,
			header = "Rng",
			txt = "Mettre les néon en mode rng",
			params = {
				event = "",
				args = {
					neonId = "rng",
					fnc = "ChangeNeonState"
				}
			}
		},
		{
			id = 6,
			header = "Retour",
			txt = "Revenir sur le premier menu",
			params = {
				event = "",
				args = {
					neonId = "goback",
					fnc = "ChangeNeonState"
				}
			}
		}
	},
	Hydro = {
		{
			id = 1,
			header = "Hydraulique devant droite",
			txt = "Activer / Desactiver",
			params = {
				event = "",
				args = {
					wheelId = 1,
					fnc = "ChangeHydraulicState"
				}
			}
		},
		{
			id = 2,
			header = "Hydraulique devant gauche",
			txt = "Activer / Desactiver",
			params = {
				event = "",
				args = {
					wheelId = 0,
					fnc = "ChangeHydraulicState"
				}
			}
		},
		{
			id = 3,
			header = "Hydraulique arriere droite",
			txt = "Activer / Desactiver",
			params = {
				event = "",
				args = {
					wheelId = 5,
					fnc = "ChangeHydraulicState"
				}
			}
		},
		{
			id = 4,
			header = "Hydraulique arriere gauche",
			txt = "Activer / Desactiver",
			params = {
				event = "",
				args = {
					wheelId = 4,
					fnc = "ChangeHydraulicState"
				}
			}
		},
		{
			id = 5,
			header = "Hydraulique avant",
			txt = "Activer / Desactiver",
			params = {
				event = "",
				args = {
					wheelId = {1,0},
					fnc = "ChangeHydraulicState"
				}
			}
		},
		{
			id = 6,
			header = "Hydraulique arrier",
			txt = "Activer / Desactiver",
			params = {
				event = "",
				args = {
					wheelId = {4,5},
					fnc = "ChangeHydraulicState"
				}
			}
		},
		{
			id = 7,
			header = "Auto",
			txt = "Mettre les hydrauliques en mode automatique",
			params = {
				event = "",
				args = {
					wheelId = "rng",
					fnc = "ChangeHydraulicState"
				}
			}
		},
		{
			id = 8,
			header = "Retour",
			txt = "Revenir sur le premier menu",
			params = {
				event = "",
				args = {
					neonId = "goback",
					fnc = "ChangeHydraulicState"
				}
			}
		},
	}
}
