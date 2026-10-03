local ssu = require "::/gui/main/stylesheetutil.lua"

local CARGO_CARD_MIN_WIDTH = 96
local INDICATOR_LABEL_MAX_WIDTH = 160

function data()
	local result = {}
	local a = ssu.makeAdder(result)

	a([[R::ApaszVehicleReadoutHudIconMasterGame > BoxLayout!vehicle-readout-vehicle-display-host,
		R::ApaszVehicleReadoutLineHudIconMaster > BoxLayout!vehicle-readout-vehicle-display-host]], {
		gravity = { 0.5, 0.5 },
		innerSpacing = { 0, 0 },
	})

	a("R::ApaszVehicleReadoutVehicleDisplay BoxLayout!vehicle-readout-display-root", {
		gravity = { 0.5, 0.5 },
		innerSpacing = { 2, 2 },
	})

	a("R::ApaszVehicleReadoutVehicleDisplay BoxLayout!vehicle-readout-display-rows", {
		gravity = { 0.5, 0.5 },
		innerSpacing = { 2, 2 },
	})

	a([[R::ApaszVehicleReadoutVehicleDisplay BoxLayout!vehicle-readout-cargo-row,
		R::ApaszVehicleReadoutVehicleDisplay BoxLayout!vehicle-readout-display-row]], {
		gravity = { 0.5, 0.5 },
		innerSpacing = { 3, 3 },
	})

	a("R::ApaszVehicleReadoutVehicleDisplay BoxLayout!vehicle-readout-cargo-card", {
		gravity = { 0.5, 0.5 },
		innerSpacing = { 0, 0 },
		minSize = { CARGO_CARD_MIN_WIDTH, -1 },
	})

	a([[R::ApaszVehicleReadoutVehicleDisplay BoxLayout!vehicle-readout-cargo-main-row,
		R::ApaszVehicleReadoutVehicleDisplay BoxLayout!vehicle-readout-cargo-quality-row]], {
		gravity = { -1, 0.5 },
		innerSpacing = { 0, 0 },
	})

	a("R::ApaszVehicleReadoutVehicleDisplay ImageView!vehicle-readout-status-icon", {
		gravity = { 0.5, 0.5 },
		size = { 16, 16 },
	})

	a("R::ApaszVehicleReadoutVehicleDisplay BoxLayout!vehicle-readout-striped-indicator", {
		gravity = { 0.5, 0.5 },
		innerSpacing = { 2, 2 },
	})

	a("R::ApaszVehicleReadoutVehicleDisplay Component!vehicle-readout-color-stripe", {
		gravity = { 0.5, 0.5 },
	})

	a("R::ApaszVehicleReadoutVehicleDisplay TextView!iconlabelindicator-label", {
		maxSize = { INDICATOR_LABEL_MAX_WIDTH, -1 },
	})

	return result
end
