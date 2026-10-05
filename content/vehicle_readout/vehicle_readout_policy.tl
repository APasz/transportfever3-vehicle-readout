local debugLoggingEnabled = ug_require "apasz_vehicle_readout::/vehicle_readout/logging_config.tl" as boolean
local logging = ug_require "apasz_vehicle_readout::/vehicle_readout/logging.lua" as ModLogging.Module
local logger = logging.new("Vehicle Readout", debugLoggingEnabled)

local vehicle_readout_policy : VehicleReadoutPolicy = {}

vehicle_readout_policy.shouldShowForVehicle = function(
	visibility : VehicleReadoutPolicy.VehicleVisibility,
	isAdditionallyVisible : boolean,
	isOnSelectedLine : boolean,
	isSelectedVehicle : boolean
) : boolean
	if visibility ~= "All"
		and visibility ~= "SelectedLine"
		and visibility ~= "SelectedVehicle"
		and visibility ~= "None"
	then
		return logger.fail("Unhandled visibility: " .. tostring(visibility))
	end

	if isAdditionallyVisible or visibility == "All" then
		return true
	elseif visibility == "SelectedLine" then
		return isOnSelectedLine
	elseif visibility == "SelectedVehicle" then
		return isSelectedVehicle
	end
	return false
end

vehicle_readout_policy.getHiddenStatePresentation = function(
	stateKind : VehicleReadoutPolicy.OperationalStateKind
) : VehicleReadoutPolicy.HiddenStatePresentation
	if stateKind == "AwaitingAssignment" or stateKind == "Unassigned" or stateKind == "NoPath" then
		return "Label"
	elseif stateKind == "GoingToDepot" or stateKind == "UserStopped" then
		return "Icon"
	elseif stateKind == "EnRoute" or stateKind == "AtTerminal" or stateKind == "InDepot" then
		return "Hidden"
	end
	return logger.fail("Unhandled operational state: " .. tostring(stateKind))
end

vehicle_readout_policy.resolveStateDisplay = function(
	showOperatingState : boolean,
	stateIsNotable : boolean,
	hiddenPresentation : VehicleReadoutPolicy.HiddenStatePresentation,
	hasNamedDepotDestination : boolean
) : VehicleReadoutPolicy.StateDisplay
	if hiddenPresentation ~= "Hidden"
		and hiddenPresentation ~= "Icon"
		and hiddenPresentation ~= "Label"
	then
		return logger.fail("Unhandled hidden-state presentation: " .. tostring(hiddenPresentation))
	end

	if hiddenPresentation == "Label" then
		return "Label"
	elseif hasNamedDepotDestination then
		return "NamedDepot"
	elseif showOperatingState and stateIsNotable then
		return "Label"
	elseif hiddenPresentation == "Icon" then
		return "Icon"
	end
	return "Hidden"
end

vehicle_readout_policy.shouldShowNextStop = function(
	showDestination : boolean,
	destinationKind : VehicleReadoutPolicy.DestinationKind
) : boolean
	if destinationKind == "NextStop" then
		return showDestination
	elseif destinationKind == "None" or destinationKind == "Depot" then
		return false
	end
	return logger.fail("Unhandled destination kind: " .. tostring(destinationKind))
end

vehicle_readout_policy.getFloatingSpeedPlacement = function(
	speedDisplay : VehicleReadoutPolicy.SpeedDisplay
) : VehicleReadoutPolicy.FloatingSpeedPlacement
	if speedDisplay == "Off" or speedDisplay == "GameBarOnly" then
		return "Hidden"
	elseif speedDisplay == "Below" or speedDisplay == "BelowGameBar" then
		return "Below"
	elseif speedDisplay == "Above" or speedDisplay == "AboveGameBar" then
		return "Above"
	end
	return logger.fail("Unhandled speed display: " .. tostring(speedDisplay))
end

vehicle_readout_policy.shouldShowGameBarSpeed = function(
	speedDisplay : VehicleReadoutPolicy.SpeedDisplay
) : boolean
	if speedDisplay == "BelowGameBar"
		or speedDisplay == "AboveGameBar"
		or speedDisplay == "GameBarOnly"
	then
		return true
	elseif speedDisplay == "Off" or speedDisplay == "Below" or speedDisplay == "Above" then
		return false
	end
	return logger.fail("Unhandled speed display: " .. tostring(speedDisplay))
end

return vehicle_readout_policy
