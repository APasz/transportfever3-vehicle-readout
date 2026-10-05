local GAME_BAR_ORDER = 10

function data()
	return {
		type = "react-plugin ::GameBarInfoDisplayExtension",
		data = {
			filePath = "apasz_vehicle_readout::/vehicle_readout/vehicle_readout.script@GameBarVehicleReadout",
			order = GAME_BAR_ORDER,
			priority = GAME_BAR_ORDER,
		},
	}
end
