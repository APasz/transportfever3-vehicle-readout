local builtin = ug_require "::/gui/main/builtin.lua" as Builtin
local cargo_react_util = ug_require "::/gui/main/cargo_react_util.tl" as CargoReactUtil
local cargo_util = ug_require "::/gui/main/cargo_util.tl" as CargoUtil
local engine_react_util = ug_require "::/gui/main/engine_react_util.tl" as EngineReactUtil
local entity_window_hud = ug_require "::/gui/entity_window/entity_window_hud.tl" as EntityWindowHud
local gui_react_util = ug_require "::/gui/main/gui_react_util.tl" as GuiReactUtil
local hud_icon_toolbox = ug_require "::/gui/main/hud_icon_toolbox.tl" as HudIconToolbox
local lang_util = ug_require "::/scripts/lang_util.tl" as LangUtil
local mathutil = ug_require "::/scripts/mathutil.lua" as MathUtil
local notification_react_util = ug_require "::/game_mechanics/notifications/types/notification_react_util.tl" as NotificationReactUtil
local react = ug_require "::/gui/main/react.lua" as React
local vehicle_readout_policy = ug_require "apasz_vehicle_readout_1::/vehicle_readout/vehicle_readout_policy.tl" as VehicleReadoutPolicy
local styleutil = ug_require "::/gui/main/styleutil.tl" as StyleUtil
local vehicle_react_util = ug_require "::/gui/line_vehicle_mgmt/vehicle_react_util.tl" as VehicleReactUtil
local vehicle_util = ug_require "::/gui/line_vehicle_mgmt/vehicle_util.tl" as VehicleUtil

local MOD_ID = "apasz_vehicle_readout_1"
local VISIBILITY_PARAM_KEY = "apasz_vehicle_readout_visibility"
local ADDITIONAL_VEHICLE_VISIBILITY_PARAM_KEY = "apasz_vehicle_readout_additional_vehicle_visibility"
local SHOW_VEHICLE_NAME_PARAM_KEY = "apasz_vehicle_readout_show_vehicle_name"
local SPEED_PLACEMENT_PARAM_KEY = "apasz_vehicle_readout_speed_style"
local UPDATE_INTERVAL_PARAM_KEY = "apasz_vehicle_readout_update_interval"
local SHOW_LOAD_PERCENTAGE_PARAM_KEY = "apasz_vehicle_readout_show_load_percentage"
local SHOW_DESTINATION_PARAM_KEY = "apasz_vehicle_readout_show_next_stop"
local SHOW_STATE_PARAM_KEY = "apasz_vehicle_readout_show_state"
local SHOW_LINE_PARAM_KEY = "apasz_vehicle_readout_show_line"
local SHOW_CONDITION_PARAM_KEY = "apasz_vehicle_readout_show_condition"
local SHOW_QUALITY_PARAM_KEY = "apasz_vehicle_readout_show_quality"

local SPEED_ICON_PATH = "::/gui/entity_window/icons/symbol_speed.tga"
local LOAD_ICON_PATH = "::/gui/entity_window/icons/symbol_cargo.tga"
local LINE_ICON_PATH = "::/gui/entity_window/icons/symbol_configure_line.tga"
local NEXT_STOP_ICON_PATH = "::/gui/line_vehicle_mgmt/icons/indicator_terminal.tga"
local STATE_MOVING_ICON_PATH = "::/gui/entity_window/icons/playback_play.tga"
local STATE_STOPPED_ICON_PATH = "::/gui/entity_window/icons/stop.tga"
local STATE_DEPOT_ICON_PATH = "::/gui/entity_window/icons/building_depot_arrow.tga"
local STATE_WARNING_ICON_PATH = "::/gui/hud/icons/line_vehicle_warning.tga"
local HAPPY_PASSENGER_ICON_PATH = "::/gui/main/icons/symbol_emote_happy_colored.tga"
local SAD_PASSENGER_ICON_PATH = "::/gui/main/icons/symbol_emote_sad_colored.tga"
local CARGO_QUALITY_ICON_PATH = "::/gui/entity_window/icons/relation_cargo_time.tga"
local LOAD_ANIMATION_ICON_PATH = "::/gui/hud/icons/load_animation.tga"
local UNLOAD_ANIMATION_ICON_PATH = "::/gui/hud/icons/unload_animation.tga"
local FALLBACK_VEHICLE_ICON_PATH = "::/gui/hud/icons/relation_vehicle_train_bus.tga"
local BUS_ICON_PATH = "::/gui/hud/icons/vehicle_bus.tga"
local TRUCK_ICON_PATH = "::/gui/hud/icons/vehicle_truck.tga"
local TRAIN_ICON_PATH = "::/gui/hud/icons/vehicle_train.tga"
local TRAM_ICON_PATH = "::/gui/hud/icons/vehicle_tram.tga"
local AIRCRAFT_ICON_PATH = "::/gui/hud/icons/vehicle_airplane.tga"
local HELICOPTER_ICON_PATH = "::/gui/hud/icons/vehicle_helicopter.tga"
local SHIP_ICON_PATH = "::/gui/hud/icons/vehicle_ship.tga"
local ENTITY_WINDOW_ID_PREFIX = "temp.view.entity_"

local INVALID_ENTITY = -1
local POOR_CONDITION_THRESHOLD = 0.4
local INFERIOR_CONDITION_THRESHOLD = 0.8
local LOADING_SPEED_BOOST_THRESHOLD = 1.5
local LOADING_SPEED_PENALTY_THRESHOLD = 0.75
local LOADING_ANIMATION_BASE_SPEED = 4
local LOADING_ANIMATION_FRAME_COUNT = 12
local UI_VISIBILITY_UPDATE_INTERVAL_SECONDS = 0.5
local MICROSECONDS_PER_SECOND = 1000000
local UI_VISIBILITY_UPDATE_INTERVAL_MICROSECONDS = math.floor(
	UI_VISIBILITY_UPDATE_INTERVAL_SECONDS * MICROSECONDS_PER_SECOND
) as integer
local MAX_NAMED_INDICATOR_WIDTH_UNITS = 20
local ELLIPSIS = "…"

local type VehicleVisibility = VehicleReadoutPolicy.VehicleVisibility

local enum AdditionalVehicleVisibility
	"Neither"
	"DetailWindow"
	"Followed"
	"Both"
end

local enum SpeedPlacement
	"Off"
	"Below"
	"Above"
end

local type DestinationKind = VehicleReadoutPolicy.DestinationKind

local type ModParams = {string : number}

local record Settings
	visibility : VehicleVisibility
	additionalVehicleVisibility : AdditionalVehicleVisibility
	showVehicleName : boolean
	speedPlacement : SpeedPlacement
	updateIntervalSeconds : number
	showLoadPercentage : boolean
	showDestination : boolean
	showState : boolean
	showLine : boolean
	showCondition : boolean
	showQuality : boolean
end

local record OperationalState
	label : string
	icon : string
	warning : boolean
	notable : boolean
	hiddenPresentation : VehicleReadoutPolicy.HiddenStatePresentation
end

local record VehicleSnapshot
	available : boolean
	vehicleName : string
	vehicleIcon : string
	vehicleColor : Vec4f | nil
	speed : number
	topSpeed : number
	stateLabel : string
	stateIcon : string
	stateWarning : boolean
	stateNotable : boolean
	hiddenStatePresentation : VehicleReadoutPolicy.HiddenStatePresentation
	lineName : string
	lineColor : Vec4f | nil
	destinationKind : DestinationKind
	destinationName : string
	condition : number
	conditionLabel : string
	conditionIcon : string
end

local type NotificationCacheAccess = function(Engine.Entity) : {Notification}
local type EmptyCargoItemFactory = function() : TreeNodeId

local record VehicleDisplayParams
	entity : Engine.Entity
	showEmptyState : boolean
	notificationCacheAccessFn : NotificationCacheAccess | nil
end

local VISIBILITIES : {integer : VehicleVisibility} = {
	[1] = "All",
	[2] = "SelectedLine",
	[3] = "SelectedVehicle",
	[4] = "None",
}

local ADDITIONAL_VEHICLE_VISIBILITIES : {integer : AdditionalVehicleVisibility} = {
	[1] = "Neither",
	[2] = "DetailWindow",
	[3] = "Followed",
	[4] = "Both",
}

local SPEED_PLACEMENTS : {integer : SpeedPlacement} = {
	[1] = "Off",
	[2] = "Below",
	[3] = "Above",
}

local UPDATE_INTERVALS : {integer : number} = {
	[1] = 0.5,
	[2] = 1.0,
	[3] = 2.0,
	[4] = 5.0,
	[5] = 15.0,
}

local BOOLEAN_VALUES : {integer : boolean} = {
	[1] = false,
	[2] = true,
}

local function readMappedParam<T>(
	params : ModParams,
	key : string,
	values : {integer : T},
	defaultValue : T
) : T
	local rawValue = params[key]
	if rawValue == nil then
		return defaultValue
	end
	if type(rawValue) ~= "number" then
		error("Vehicle Readout parameter '" .. key .. "' must be a number")
	end

	local numericValue = rawValue as number
	if numericValue ~= math.floor(numericValue) then
		error("Vehicle Readout parameter '" .. key .. "' must be an integer")
	end

	local value = values[numericValue as integer]
	if value == nil then
		error("Vehicle Readout parameter '" .. key .. "' has invalid value " .. tostring(numericValue))
	end
	return value
end

local DEFAULT_SETTINGS : Settings = {
	visibility = "All",
	additionalVehicleVisibility = "Neither",
	showVehicleName = false,
	speedPlacement = "Below",
	updateIntervalSeconds = 0.5,
	showLoadPercentage = true,
	showDestination = false,
	showState = false,
	showLine = false,
	showCondition = false,
	showQuality = false,
}

local function loadSettings() : Settings
	local allModParams = api.engine.config.getModParams()
	local params = (allModParams[MOD_ID] or {}) as ModParams
	local result : Settings = {
		visibility = readMappedParam(params, VISIBILITY_PARAM_KEY, VISIBILITIES, DEFAULT_SETTINGS.visibility),
		additionalVehicleVisibility = readMappedParam(
			params,
			ADDITIONAL_VEHICLE_VISIBILITY_PARAM_KEY,
			ADDITIONAL_VEHICLE_VISIBILITIES,
			DEFAULT_SETTINGS.additionalVehicleVisibility
		),
		showVehicleName = readMappedParam(
			params,
			SHOW_VEHICLE_NAME_PARAM_KEY,
			BOOLEAN_VALUES,
			DEFAULT_SETTINGS.showVehicleName
		),
		speedPlacement = readMappedParam(
			params,
			SPEED_PLACEMENT_PARAM_KEY,
			SPEED_PLACEMENTS,
			DEFAULT_SETTINGS.speedPlacement
		),
		updateIntervalSeconds = readMappedParam(
			params,
			UPDATE_INTERVAL_PARAM_KEY,
			UPDATE_INTERVALS,
			DEFAULT_SETTINGS.updateIntervalSeconds
		),
		showLoadPercentage = readMappedParam(
			params,
			SHOW_LOAD_PERCENTAGE_PARAM_KEY,
			BOOLEAN_VALUES,
			DEFAULT_SETTINGS.showLoadPercentage
		),
		showDestination = readMappedParam(
			params,
			SHOW_DESTINATION_PARAM_KEY,
			BOOLEAN_VALUES,
			DEFAULT_SETTINGS.showDestination
		),
		showState = readMappedParam(params, SHOW_STATE_PARAM_KEY, BOOLEAN_VALUES, DEFAULT_SETTINGS.showState),
		showLine = readMappedParam(params, SHOW_LINE_PARAM_KEY, BOOLEAN_VALUES, DEFAULT_SETTINGS.showLine),
		showCondition = readMappedParam(
			params,
			SHOW_CONDITION_PARAM_KEY,
			BOOLEAN_VALUES,
			DEFAULT_SETTINGS.showCondition
		),
		showQuality = readMappedParam(params, SHOW_QUALITY_PARAM_KEY, BOOLEAN_VALUES, DEFAULT_SETTINGS.showQuality),
	}
	return result
end

local settings : Settings = DEFAULT_SETTINGS
local uiVisibilitySubscriptionCounts : {Engine.Entity : integer} = {}
local uiVisibilityByEntity : {Engine.Entity : boolean} = {}
local uiVisibilityPollClock = api.type.Clock.new()
local nextUiVisibilityPollTime = 0

local function getTransportVehicle(entity : Engine.Entity) : Engine.Component.TransportVehicle | nil
	if entity < 0 or not api.engine.entityExists(entity) then
		return nil
	end
	return api.engine.getComponent(entity, api.type.ComponentType.TRANSPORT_VEHICLE)
end

local function isExistingLine(entity : Engine.Entity | nil) : boolean
	if entity == nil then
		return false
	end
	local lineEntity = entity as Engine.Entity
	if lineEntity < 0 or not api.engine.entityExists(lineEntity) then
		return false
	end
	local line : Engine.Component.Line = api.engine.getComponent(lineEntity, api.type.ComponentType.LINE)
	return line ~= nil
end

local function getSelectedLine(userParam : HudIconToolbox.HudIconMasterUserParam) : Engine.Entity
	local selectedEntity = userParam.selectedEntity
	if isExistingLine(selectedEntity) then
		return selectedEntity
	end
	-- Vehicle windows expose their assigned line to render peers; that does not mean the line is selected.
	return INVALID_ENTITY
end

local function shouldShowForVehicle(
	entity : Engine.Entity,
	transportVehicle : Engine.Component.TransportVehicle,
	userParam : HudIconToolbox.HudIconMasterUserParam,
	isAdditionallyVisibleVehicle : boolean,
	selectedLine? : Engine.Entity
) : boolean
	local isOnSelectedLine = false
	if settings.visibility == "SelectedLine" then
		local lineEntity = selectedLine or getSelectedLine(userParam)
		isOnSelectedLine = lineEntity ~= INVALID_ENTITY and transportVehicle.line == lineEntity
	end
	return vehicle_readout_policy.shouldShowForVehicle(
		settings.visibility,
		isAdditionallyVisibleVehicle,
		isOnSelectedLine,
		userParam.selectedEntity == entity
	)
end

local function includesFollowedVehicle(visibility : AdditionalVehicleVisibility) : boolean
	return visibility == "Followed" or visibility == "Both"
end

local function includesDetailWindowVehicle(visibility : AdditionalVehicleVisibility) : boolean
	return visibility == "DetailWindow" or visibility == "Both"
end

local function registerUiVisibilitySubscription(entity : Engine.Entity)
	uiVisibilitySubscriptionCounts[entity] = (uiVisibilitySubscriptionCounts[entity] or 0) + 1
end

local function unregisterUiVisibilitySubscription(entity : Engine.Entity)
	local subscriptionCount = uiVisibilitySubscriptionCounts[entity]
	if subscriptionCount == nil then
		error("Attempted to unregister an unknown Vehicle Readout UI visibility subscription")
	elseif subscriptionCount == 1 then
		uiVisibilitySubscriptionCounts[entity] = nil
		uiVisibilityByEntity[entity] = nil
	else
		uiVisibilitySubscriptionCounts[entity] = subscriptionCount - 1
	end
end

local function updateAdditionalVehicleVisibility()
	local additionalVisibility = settings.additionalVehicleVisibility
	local includeFollowed = includesFollowedVehicle(additionalVisibility)
	local includeDetailWindow = includesDetailWindowVehicle(additionalVisibility)
	local followedEntity = INVALID_ENTITY
	if includeFollowed then
		followedEntity = api.gui.camera.getFollowEntity()[1]
	end

	for entity, __ in pairs(uiVisibilitySubscriptionCounts) do
		local shouldShow = followedEntity == entity
		if not shouldShow and includeDetailWindow then
			local windowId = ENTITY_WINDOW_ID_PREFIX .. tostring(entity)
			shouldShow = api.gui.byId.isVisibleRecursive(windowId)
		end
		uiVisibilityByEntity[entity] = shouldShow
	end
end

local function useIsAdditionallyVisibleVehicle(entity : Engine.Entity) : boolean
	if settings.additionalVehicleVisibility == "Neither" then
		return false
	end

	local subscribedEntity : Engine.Entity = react.useRef(entity):get()
	local state : ReactStateT<boolean> = react.useState(uiVisibilityByEntity[subscribedEntity] or false)
	react.onMount(function()
		registerUiVisibilitySubscription(subscribedEntity)
	end)
	react.onUnmount(function()
		unregisterUiVisibilitySubscription(subscribedEntity)
	end)
	-- UI queries are main-thread only. Any stepping HUD may schedule the globally throttled shared poll.
	react.onStepTimer(function()
		local shouldShow = uiVisibilityByEntity[subscribedEntity] or false
		if state:old() ~= shouldShow then
			state:set(shouldShow)
		end

		local currentTime = uiVisibilityPollClock:getTime()
		if currentTime < nextUiVisibilityPollTime then
			return
		end
		nextUiVisibilityPollTime = currentTime + UI_VISIBILITY_UPDATE_INTERVAL_MICROSECONDS
		react.enqueueJoin(function()
			updateAdditionalVehicleVisibility()
		end, "ApaszVehicleReadout:updateAdditionalVehicleVisibility")
	end, UI_VISIBILITY_UPDATE_INTERVAL_SECONDS)
	return state:old()
end

local function shouldReplaceLineVehicleHud(
	entity : Engine.Entity,
	userParam : HudIconToolbox.HudIconMasterUserParam,
	isAdditionallyVisibleVehicle : boolean
) : boolean
	local transportVehicle = getTransportVehicle(entity)
	if transportVehicle == nil then
		return false
	end
	local selectedLine = getSelectedLine(userParam)
	local vehicle = transportVehicle as Engine.Component.TransportVehicle
	return selectedLine ~= INVALID_ENTITY
		and vehicle.line == selectedLine
		and shouldShowForVehicle(entity, vehicle, userParam, isAdditionallyVisibleVehicle, selectedLine)
end

local function shouldReplaceVehicleHud(
	entity : Engine.Entity,
	userParam : HudIconToolbox.HudIconMasterUserParam,
	isAdditionallyVisibleVehicle : boolean
) : boolean
	local transportVehicle = getTransportVehicle(entity)
	if transportVehicle == nil then
		return false
	end
	return shouldShowForVehicle(
		entity,
		transportVehicle as Engine.Component.TransportVehicle,
		userParam,
		isAdditionallyVisibleVehicle
	)
end

local function makeOperationalState(
	kind : VehicleReadoutPolicy.OperationalStateKind,
	label : string,
	icon : string,
	warning : boolean,
	notable : boolean
) : OperationalState
	return {
		label = label,
		icon = icon,
		warning = warning,
		notable = notable,
		hiddenPresentation = vehicle_readout_policy.getHiddenStatePresentation(kind),
	}
end

local function getOperationalState(
	transportVehicle : Engine.Component.TransportVehicle,
	speed : number
) : OperationalState
	if transportVehicle.state == api.type["enum"].TransportVehicleState.IN_DEPOT then
		if not isExistingLine(transportVehicle.line) then
			return makeOperationalState(
				"AwaitingAssignment",
				_("APASZ_VEHICLE_READOUT_STATE_AWAITING_ASSIGNMENT"),
				LINE_ICON_PATH,
				false,
				true
			)
		end
		return makeOperationalState(
			"InDepot",
			_("APASZ_VEHICLE_READOUT_STATE_IN_DEPOT"),
			STATE_DEPOT_ICON_PATH,
			false,
			true
		)
	elseif transportVehicle.noPath then
		return makeOperationalState(
			"NoPath",
			_("APASZ_VEHICLE_READOUT_STATE_NO_PATH"),
			STATE_WARNING_ICON_PATH,
			true,
			true
		)
	elseif transportVehicle.state == api.type["enum"].TransportVehicleState.GOING_TO_DEPOT then
		return makeOperationalState(
			"GoingToDepot",
			_("APASZ_VEHICLE_READOUT_STATE_GOING_TO_DEPOT"),
			STATE_DEPOT_ICON_PATH,
			false,
			true
		)
	elseif not isExistingLine(transportVehicle.line) then
		return makeOperationalState(
			"Unassigned",
			_("APASZ_VEHICLE_READOUT_STATE_UNASSIGNED"),
			LINE_ICON_PATH,
			false,
			true
		)
	elseif transportVehicle.userStopped then
		return makeOperationalState(
			"UserStopped",
			speed > 0.0 and _("APASZ_VEHICLE_READOUT_STATE_STOPPING") or _("APASZ_VEHICLE_READOUT_STATE_STOPPED"),
			STATE_STOPPED_ICON_PATH,
			false,
			true
		)
	elseif transportVehicle.state == api.type["enum"].TransportVehicleState.AT_TERMINAL then
		local label = _("APASZ_VEHICLE_READOUT_STATE_AT_TERMINAL")
		if transportVehicle.loadState == api.type.TransportVehicle.LoadState.Loading then
			label = _("APASZ_VEHICLE_READOUT_STATE_LOADING")
		elseif transportVehicle.loadState == api.type.TransportVehicle.LoadState.Unloading then
			label = _("APASZ_VEHICLE_READOUT_STATE_UNLOADING")
		elseif transportVehicle.loadState == api.type.TransportVehicle.LoadState.WaitForScheduledDeparture then
			label = _("APASZ_VEHICLE_READOUT_STATE_WAITING")
		elseif transportVehicle.loadState == api.type.TransportVehicle.LoadState.Departing then
			label = _("APASZ_VEHICLE_READOUT_STATE_DEPARTING")
		end
		return makeOperationalState("AtTerminal", label, LOAD_ICON_PATH, false, true)
	end
	return makeOperationalState(
		"EnRoute",
		_("APASZ_VEHICLE_READOUT_STATE_EN_ROUTE"),
		STATE_MOVING_ICON_PATH,
		false,
		false
	)
end

local function getEntityName(entity : Engine.Entity) : string
	if entity < 0 or not api.engine.entityExists(entity) then
		return ""
	end
	local name : Engine.Component.Name | nil = api.engine.getComponent(entity, api.type.ComponentType.NAME)
	if name == nil then
		return ""
	end
	return (name as Engine.Component.Name).name
end

local function getVehicleIcon(entity : Engine.Entity) : string
	local iconType = vehicle_react_util.getVehicleIconType(entity)
	if iconType == api.type["enum"].VehicleIconType.Bus then
		return BUS_ICON_PATH
	elseif iconType == api.type["enum"].VehicleIconType.Truck then
		return TRUCK_ICON_PATH
	elseif iconType == api.type["enum"].VehicleIconType.TrainSteam
		or iconType == api.type["enum"].VehicleIconType.TrainElectric
		or iconType == api.type["enum"].VehicleIconType.TrainDiesel
	then
		return TRAIN_ICON_PATH
	elseif iconType == api.type["enum"].VehicleIconType.Tram then
		return TRAM_ICON_PATH
	elseif iconType == api.type["enum"].VehicleIconType.Aircraft then
		return AIRCRAFT_ICON_PATH
	elseif iconType == api.type["enum"].VehicleIconType.Helicopter then
		return HELICOPTER_ICON_PATH
	elseif iconType == api.type["enum"].VehicleIconType.Ship then
		return SHIP_ICON_PATH
	end
	return FALLBACK_VEHICLE_ICON_PATH
end

local function getVehicleColor(
	transportVehicle : Engine.Component.TransportVehicle
) : Vec4f | nil
	for _, vehiclePart in ipairs(transportVehicle.transportVehicleConfig.vehicles) do
		local color = vehiclePart.part.color
		if color.x >= 0.0 then
			return api.type.Vec4f.new(color, 1.0)
		end
	end
	return nil
end

local function getLineAndDestination(
	transportVehicle : Engine.Component.TransportVehicle,
	includeLineDetails : boolean
) : string, Vec4f | nil, DestinationKind, string
	local line : Engine.Component.Line | nil = nil
	local lineNameText = ""
	local lineColor : Vec4f | nil = nil
	if transportVehicle.line >= 0 and api.engine.entityExists(transportVehicle.line) then
		line = api.engine.getComponent(transportVehicle.line, api.type.ComponentType.LINE)
		if line ~= nil and includeLineDetails then
			lineNameText = getEntityName(transportVehicle.line)
			local colorComponent : Engine.Component.Color | nil = api.engine.getComponent(
				transportVehicle.line,
				api.type.ComponentType.COLOR
			)
			if colorComponent ~= nil then
				lineColor = api.type.Vec4f.new((colorComponent as Engine.Component.Color).color, 1.0)
			end
		end
	end

	if transportVehicle.state == api.type["enum"].TransportVehicleState.GOING_TO_DEPOT then
		local depotName = getEntityName(transportVehicle.depot)
		return lineNameText, lineColor, depotName ~= "" and "Depot" or "None", depotName
	end
	if line == nil then
		return "", nil, "None", ""
	end
	local validLine = line as Engine.Component.Line
	if transportVehicle.stopIndex < 0 or transportVehicle.stopIndex >= #validLine.stops then
		return lineNameText, lineColor, "None", ""
	end

	local stop = validLine.stops[transportVehicle.stopIndex + 1]
	if stop == nil or stop.stationGroup < 0 or not api.engine.entityExists(stop.stationGroup) then
		return lineNameText, lineColor, "None", ""
	end
	local stopName = getEntityName(stop.stationGroup)
	return lineNameText, lineColor, stopName ~= "" and "NextStop" or "None", stopName
end

-- CargoTypeInfo.spoiledCount can be nil while cargo data is rebuilt during loading or unloading.
local function getQualityFontColor(total : integer, bad? : integer) : GuiReactUtil.LabelFontColor
	local badCount = bad or 0
	if badCount == 0 then
		return "Normal"
	elseif badCount * 2 > total then
		return "Poor"
	end
	return "Inferior"
end

local function getPassengerHappinessIcon(unhappyCount? : integer) : string
	return (unhappyCount or 0) > 0 and SAD_PASSENGER_ICON_PATH or HAPPY_PASSENGER_ICON_PATH
end

local function getConditionFontColor(condition : number) : GuiReactUtil.LabelFontColor
	if condition < POOR_CONDITION_THRESHOLD then
		return "Poor"
	elseif condition < INFERIOR_CONDITION_THRESHOLD then
		return "Inferior"
	end
	return "Normal"
end

local function makeIndicator(
	iconPath : string,
	label : string,
	tooltip : string,
	fontColor : GuiReactUtil.LabelFontColor
) : TreeNodeId
	return gui_react_util.makeContentLabelIndictator{
		iconPath = iconPath,
		label = label,
		tooltip = tooltip,
		labelFontColor = fontColor,
		labelMode = "HudIconMain",
		shippingState = "Vehicle",
	}
end

local function formatCargoCount(cargoInfo : CargoUtil.CargoTypeInfo) : string
	return lang_util.format(_("{count}/{capacity}"), {
		count = lang_util.formatInt(cargoInfo.count),
		capacity = lang_util.formatInt(cargoInfo.capacity),
	})
end

local function makeCargoLoadingIndicator(cargoInfo : CargoUtil.CargoTypeInfo) : TreeNodeId | nil
	local loadSpeedModifiers = cargoInfo.loadSpeedModifiers
	if loadSpeedModifiers == nil then
		return nil
	end

	local loading = cargoInfo.loadState == api.type.TransportVehicle.LoadState.Loading
	local unloading = cargoInfo.loadState == api.type.TransportVehicle.LoadState.Unloading
	local totalPenalty = loadSpeedModifiers:getTotalPenalty()
	if totalPenalty <= 0.0 or (not loading and not unloading) then
		return nil
	end

	local loadSpeedModifier = 1.0 / totalPenalty
	local styleClass = "loading-indicator"
	if loadSpeedModifier > LOADING_SPEED_BOOST_THRESHOLD then
		styleClass = styleClass .. ",boosted-up"
	elseif loadSpeedModifier < LOADING_SPEED_PENALTY_THRESHOLD then
		styleClass = styleClass .. ",boosted-down"
	end

	local tooltips : {string} = {}
	if loadSpeedModifiers.stockCompatibility ~= 1.0 then
		tooltips[#tooltips + 1] = cargo_react_util.makeTooltipStockCompatibility(loadSpeedModifiers)
	end
	local vehicleCompatibility = loadSpeedModifiers.vehicleCompatibility
		+ loadSpeedModifiers.vehicleIncompatibility
		+ loadSpeedModifiers.vehicleOverlength
	if vehicleCompatibility ~= 1.0 then
		tooltips[#tooltips + 1] = cargo_react_util.makeTooltipVehicleCompatibility(loadSpeedModifiers)
	end

	local gameSpeed = cargoInfo.gameSpeed or 0
	local animationSpeed = gameSpeed == 0
		and 0
		or math.max(LOADING_ANIMATION_BASE_SPEED - mathutil.round(gameSpeed * loadSpeedModifier), 1)
	return builtin.ImageView{
		meta = {
			class = styleClass,
			tooltip = table.concat(tooltips, "\n"),
		},
		path = loading and LOAD_ANIMATION_ICON_PATH or UNLOAD_ANIMATION_ICON_PATH,
		coord = api.type.Vec2i.new(4, 3),
		startFrame = 0,
		numFrames = LOADING_ANIMATION_FRAME_COUNT,
		animationSpeed = animationSpeed,
	}
end

local function makeCenteredCargoRow(styleClass : string, child : TreeNodeId) : TreeNodeId
	return builtin.BoxLayout{
		meta = { class = styleClass },
		orientation = builtin.type.Orientation.Horizontal,
		children = {
			gui_react_util.makeHorizontalSpacer(),
			child,
			gui_react_util.makeHorizontalSpacer(),
		},
	}
end

local function makeEmptyCargoCard() : TreeNodeId
	return builtin.BoxLayout{
		meta = { class = "vehicle-readout-cargo-card" },
		orientation = builtin.type.Orientation.Vertical,
		children = {
			makeCenteredCargoRow(
				"vehicle-readout-cargo-main-row",
				makeIndicator(
					LOAD_ICON_PATH,
					_("APASZ_VEHICLE_READOUT_EMPTY"),
					_("APASZ_VEHICLE_READOUT_EMPTY_TOOLTIP"),
					"Default"
				)
			),
		},
	}
end

local function makeCargoBadge(
	cargoInfo : CargoUtil.CargoTypeInfo,
	shippingState : GuiReactUtil.ShippingState
) : TreeNodeId
	local fraction = cargoInfo.capacity > 0 and cargoInfo.count / cargoInfo.capacity or 0.0
	local loadPercentage = api.util.toStringPercentPrecision(fraction, 0)
	local loadTooltipPercentage = api.util.toStringPercentPrecision(fraction, 1)
	local cargoLabel = formatCargoCount(cargoInfo)
	if settings.showLoadPercentage then
		cargoLabel = cargoLabel .. " (" .. loadPercentage .. ")"
	end

	local loadTooltip = lang_util.format(_("APASZ_VEHICLE_READOUT_LOAD_TOOLTIP"), {
		count = lang_util.formatInt(cargoInfo.count),
		capacity = lang_util.formatInt(cargoInfo.capacity),
		percentage = loadTooltipPercentage,
	})
	local qualityFontColor = getQualityFontColor(cargoInfo.count, cargoInfo.spoiledCount)
	local cargoBadge = cargo_react_util.makeCargoIconLabelIndicator{
		cargoType = cargoInfo.cargoType,
		cargoTypes = cargoInfo.cargoTypes,
		label = cargoLabel,
		labelTooltip = loadTooltip,
		labelFontColor = qualityFontColor,
		labelMode = "HudIconMain",
		loadingIndicator = makeCargoLoadingIndicator(cargoInfo),
		shippingState = shippingState,
	}
	local cardChildren : {TreeNodeId} = {
		makeCenteredCargoRow("vehicle-readout-cargo-main-row", cargoBadge),
	}
	if settings.showQuality and cargoInfo.averageQuality ~= nil then
		local qualityPercentage = api.util.toStringPercentPrecision(cargoInfo.averageQuality, 0)
		local qualityTooltipPercentage = api.util.toStringPercentPrecision(cargoInfo.averageQuality, 1)
		local isPassenger = cargoInfo.cargoType == cargo_util.getPassengerCargoTypeId()
		local qualityIcon = isPassenger
			and getPassengerHappinessIcon(cargoInfo.spoiledCount)
			or CARGO_QUALITY_ICON_PATH
		local qualityTooltip = lang_util.format(
			isPassenger
				and _("APASZ_VEHICLE_READOUT_PASSENGER_QUALITY_TOOLTIP")
				or _("APASZ_VEHICLE_READOUT_CARGO_QUALITY_TOOLTIP"),
			{
				percentage = qualityTooltipPercentage,
				bad = lang_util.formatInt(cargoInfo.spoiledCount or 0),
				count = lang_util.formatInt(cargoInfo.count),
			}
		)
		local qualityBadge = gui_react_util.makeContentLabelIndictator{
			iconPath = qualityIcon,
			label = qualityPercentage,
			tooltip = qualityTooltip,
			labelFontColor = qualityFontColor,
			labelMode = "HudIconMain",
			shippingState = shippingState,
		}
		cardChildren[#cardChildren + 1] = makeCenteredCargoRow("vehicle-readout-cargo-quality-row", qualityBadge)
	end
	return builtin.BoxLayout{
		meta = { class = "vehicle-readout-cargo-card" },
		orientation = builtin.type.Orientation.Vertical,
		children = cardChildren,
	}
end

local function makeVehicleCargoList(
	entity : Engine.Entity,
	showEmptyState : boolean
) : TreeNodeId
	local getEmptyItem : EmptyCargoItemFactory | nil = nil
	if showEmptyState then
		getEmptyItem = function() : TreeNodeId
			return makeEmptyCargoCard()
		end
	end

	return cargo_react_util.LocationCargoList{
		locationParams = {
			vehicleEntity = entity,
			getTendency = false,
			showEmpty = false,
		},
		layout = "FLOW",
		sortOrder = "CAPACITY",
		groupIfAllEmpty = false,
		getCargoItemLayout = makeCargoBadge,
		getEmptyItem = getEmptyItem,
		shippingState = "Vehicle",
	}
end

local function makeEmptySnapshot() : VehicleSnapshot
	return {
		available = false,
		vehicleName = "",
		vehicleIcon = FALLBACK_VEHICLE_ICON_PATH,
		vehicleColor = nil,
		speed = 0.0,
		topSpeed = 0.0,
		stateLabel = "",
		stateIcon = STATE_MOVING_ICON_PATH,
		stateWarning = false,
		stateNotable = false,
		hiddenStatePresentation = "Hidden",
		lineName = "",
		lineColor = nil,
		destinationKind = "None",
		destinationName = "",
		condition = 1.0,
		conditionLabel = "",
		conditionIcon = "",
	}
end

local function unavailableSnapshot(previous? : VehicleSnapshot) : VehicleSnapshot
	if previous ~= nil and not previous.available then
		return previous
	end
	return makeEmptySnapshot()
end

local function sampleVehicle(
	entity : Engine.Entity,
	previous? : VehicleSnapshot
) : VehicleSnapshot
	local transportVehicle = getTransportVehicle(entity)
	if transportVehicle == nil then
		return unavailableSnapshot(previous)
	end
	local vehicle = transportVehicle as Engine.Component.TransportVehicle

	local result = makeEmptySnapshot()
	result.available = true
	if settings.showVehicleName then
		result.vehicleName = getEntityName(entity)
		result.vehicleIcon = getVehicleIcon(entity)
		result.vehicleColor = getVehicleColor(vehicle)
	end

	local showSpeed = settings.speedPlacement ~= "Off"
	local needsSpeed = showSpeed or vehicle.userStopped
	local currentSpeed = needsSpeed and api.engine.util.vehicle.getSpeed(entity) or 0.0
	if showSpeed then
		local vehicleData = api.engine.system.carriageListSystem.getVehicleData(entity)
		result.speed = currentSpeed
		result.topSpeed = vehicleData.topSpeed
	end
	local operationalState = getOperationalState(vehicle, currentSpeed)
	result.stateLabel = operationalState.label
	result.stateIcon = operationalState.icon
	result.stateWarning = operationalState.warning
	result.stateNotable = operationalState.notable
	result.hiddenStatePresentation = operationalState.hiddenPresentation

	if settings.showLine or settings.showDestination then
		result.lineName, result.lineColor, result.destinationKind, result.destinationName = getLineAndDestination(
			vehicle,
			settings.showLine
		)
	end
	if settings.showCondition then
		result.condition = vehicle_util.getAvgMaintenanceState(entity)
		result.conditionLabel = vehicle_util.getConditionText(result.condition)
		result.conditionIcon = vehicle_util.getConditionIcon(result.condition)
	end
	return result
end

local function getUtf8SequenceLength(firstByte : integer) : integer
	if firstByte <= 127 then
		return 1
	elseif firstByte >= 194 and firstByte <= 223 then
		return 2
	elseif firstByte >= 224 and firstByte <= 239 then
		return 3
	elseif firstByte >= 240 and firstByte <= 244 then
		return 4
	end
	error("Invalid UTF-8 leading byte in Vehicle Readout label: " .. tostring(firstByte))
end

local function truncateNamedIndicatorLabel(label : string) : string
	local byteIndex = 1
	local displayWidth = 0
	while byteIndex <= #label do
		local firstByte = string.byte(label, byteIndex)
		if firstByte == nil then
			error("Failed to read UTF-8 byte from Vehicle Readout label")
		end
		local sequenceLength = getUtf8SequenceLength(firstByte as integer)
		local characterWidth = sequenceLength == 1 and 1 or 2
		if displayWidth + characterWidth > MAX_NAMED_INDICATOR_WIDTH_UNITS then
			return string.sub(label, 1, byteIndex - 1) .. ELLIPSIS
		end
		if byteIndex + sequenceLength - 1 > #label then
			error("Incomplete UTF-8 sequence in Vehicle Readout label")
		end
		for offset = 1, sequenceLength - 1 do
			local continuationByte = string.byte(label, byteIndex + offset)
			if continuationByte == nil or continuationByte < 128 or continuationByte > 191 then
				error("Invalid UTF-8 continuation byte in Vehicle Readout label")
			end
		end
		byteIndex = byteIndex + sequenceLength
		displayWidth = displayWidth + characterWidth
	end
	return label
end

local function makeNamedIndicator(
	iconPath : string,
	label : string,
	tooltip : string,
	fontColor : GuiReactUtil.LabelFontColor
) : TreeNodeId
	return makeIndicator(iconPath, truncateNamedIndicatorLabel(label), tooltip, fontColor)
end

local function makeStripedNamedIndicator(
	iconPath : string,
	label : string,
	tooltip : string,
	stripeColor : Vec4f | nil
) : TreeNodeId
	local indicator = makeNamedIndicator(iconPath, label, tooltip, "Default")
	if stripeColor == nil then
		return indicator
	end
	return builtin.BoxLayout{
		meta = { class = "vehicle-readout-striped-indicator" },
		orientation = builtin.type.Orientation.Horizontal,
		children = {
			builtin.Component{
				meta = {
					class = "vehicle-readout-color-stripe",
					tooltip = tooltip,
					styleSheet = styleutil.makeStyle{
						backgroundColor = stripeColor,
						size = { 4, 16 },
					},
				},
				layout = builtin.BoxLayout{},
			},
			indicator,
		},
	}
end

local function makeLineIndicator(snapshot : VehicleSnapshot) : TreeNodeId
	local tooltip = lang_util.format(_("APASZ_VEHICLE_READOUT_LINE_TOOLTIP"), { name = snapshot.lineName })
	return makeStripedNamedIndicator(
		LINE_ICON_PATH,
		snapshot.lineName,
		tooltip,
		snapshot.lineColor
	)
end

local function makeSpeedText(snapshot : VehicleSnapshot) : TreeNodeId
	local currentSpeed = api.util.formatSpeed(snapshot.speed)
	local tooltip = lang_util.format(_("APASZ_VEHICLE_READOUT_SPEED_TOOLTIP"), {
		current = currentSpeed,
		top = api.util.formatSpeed(snapshot.topSpeed),
	})
	return makeIndicator(
		SPEED_ICON_PATH,
		currentSpeed,
		tooltip,
		"Default"
	)
end

-- Replacement recipes need a concrete layout root; vanilla fallbacks deliberately receive no style class.
local function makeHudHost(child : TreeNodeId, custom : boolean) : TreeNodeId
	return builtin.BoxLayout{
		meta = custom and { class = "vehicle-readout-vehicle-display-host" } or nil,
		orientation = builtin.type.Orientation.Horizontal,
		children = { child },
	}
end

local function appendDisplayRow(rows : {TreeNodeId}, children : {TreeNodeId})
	if #children == 0 then
		return
	end
	rows[#rows + 1] = builtin.BoxLayout{
		meta = { class = "vehicle-readout-display-row" },
		orientation = builtin.type.Orientation.Horizontal,
		children = children,
	}
end

local VehicleDisplay = react.RegisterRecipe("ApaszVehicleReadoutVehicleDisplay", function(
	params : VehicleDisplayParams
) : TreeNodeId
	local state = engine_react_util.useStepStateTimer(function(previous? : VehicleSnapshot) : VehicleSnapshot
		return sampleVehicle(params.entity, previous)
	end, settings.updateIntervalSeconds)
	local snapshot = state:old()
	if not snapshot.available then
		return builtin.BoxLayout{}
	end

	local primaryChildren : {TreeNodeId} = {}
	if settings.showVehicleName and snapshot.vehicleName ~= "" then
		primaryChildren[#primaryChildren + 1] = makeStripedNamedIndicator(
			snapshot.vehicleIcon,
			snapshot.vehicleName,
			lang_util.format(_("APASZ_VEHICLE_READOUT_VEHICLE_TOOLTIP"), { name = snapshot.vehicleName }),
			snapshot.vehicleColor
		)
	end
	if settings.speedPlacement == "Below" then
		primaryChildren[#primaryChildren + 1] = makeSpeedText(snapshot)
	end
	local hasNamedDepotDestination = settings.showDestination
		and snapshot.destinationKind == "Depot"
		and snapshot.destinationName ~= ""
	local stateDisplay = vehicle_readout_policy.resolveStateDisplay(
		settings.showState,
		snapshot.stateNotable,
		snapshot.hiddenStatePresentation,
		hasNamedDepotDestination
	)
	local stateIndicator : TreeNodeId | nil = nil
	if stateDisplay == "NamedDepot" then
		local depotStateLabel = lang_util.format(_("APASZ_VEHICLE_READOUT_STATE_GOING_TO_NAMED_DEPOT"), {
			name = snapshot.destinationName,
		})
		stateIndicator = makeNamedIndicator(
			STATE_DEPOT_ICON_PATH,
			depotStateLabel,
			lang_util.format(_("APASZ_VEHICLE_READOUT_DEPOT_TOOLTIP"), { name = snapshot.destinationName }),
			"Default"
		)
	elseif stateDisplay == "Label" then
		stateIndicator = makeIndicator(
			snapshot.stateIcon,
			snapshot.stateLabel,
			snapshot.stateLabel,
			snapshot.stateWarning and "Warning" or "Default"
		)
	elseif stateDisplay == "Icon" then
		stateIndicator = builtin.ImageView{
			meta = {
				class = "vehicle-readout-status-icon",
				tooltip = snapshot.stateLabel,
			},
			path = snapshot.stateIcon,
		}
	end

	local secondaryChildren : {TreeNodeId} = {}
	if settings.showLine and snapshot.lineName ~= "" then
		secondaryChildren[#secondaryChildren + 1] = makeLineIndicator(snapshot)
	end
	if vehicle_readout_policy.shouldShowNextStop(settings.showDestination, snapshot.destinationKind) then
		secondaryChildren[#secondaryChildren + 1] = makeNamedIndicator(
			NEXT_STOP_ICON_PATH,
			snapshot.destinationName,
			lang_util.format(_("APASZ_VEHICLE_READOUT_NEXT_STOP_TOOLTIP"), { name = snapshot.destinationName }),
			"Default"
		)
	end
	local statusChildren : {TreeNodeId} = {}
	if stateIndicator ~= nil then
		statusChildren[#statusChildren + 1] = stateIndicator
	end
	if settings.showCondition and snapshot.conditionIcon ~= "" then
		local conditionTooltip = lang_util.format(_("APASZ_VEHICLE_READOUT_CONDITION_TOOLTIP"), {
			condition = snapshot.conditionLabel,
			percentage = api.util.toStringPercentPrecision(snapshot.condition, 1),
		})
		statusChildren[#statusChildren + 1] = makeIndicator(
			snapshot.conditionIcon,
			snapshot.conditionLabel,
			conditionTooltip,
			getConditionFontColor(snapshot.condition)
		)
	end

	local rows : {TreeNodeId} = {}
	if settings.speedPlacement == "Above" then
		appendDisplayRow(rows, { makeSpeedText(snapshot) })
	end
	rows[#rows + 1] = builtin.BoxLayout{
		meta = { class = "vehicle-readout-cargo-row" },
		orientation = builtin.type.Orientation.Horizontal,
		children = {
			makeVehicleCargoList(params.entity, params.showEmptyState),
		},
	}
	appendDisplayRow(rows, primaryChildren)
	appendDisplayRow(rows, secondaryChildren)
	appendDisplayRow(rows, statusChildren)

	local rootChildren : {TreeNodeId} = {}
	if params.notificationCacheAccessFn ~= nil then
		rootChildren[#rootChildren + 1] = notification_react_util.NotificationHudIcons{
			accessNotificationCacheFn = params.notificationCacheAccessFn,
			entity = params.entity,
		}
	end
	rootChildren[#rootChildren + 1] = builtin.BoxLayout{
		meta = { class = "vehicle-readout-display-rows" },
		orientation = builtin.type.Orientation.Vertical,
		children = rows,
	}

	return builtin.BoxLayout{
		meta = { class = "vehicle-readout-display-root" },
		orientation = builtin.type.Orientation.Horizontal,
		children = rootChildren,
	}
end)

local function makeCustomVehicleHud(
	params : Builtin.HudIconParam,
	userParam : HudIconToolbox.HudIconMasterUserParam,
	showEmptyState : boolean,
	includeNotifications : boolean
) : TreeNodeId
	local notificationCacheAccessFn : NotificationCacheAccess | nil = nil
	if includeNotifications then
		notificationCacheAccessFn = userParam.accessNotificationCacheFn
	end
	return makeHudHost(VehicleDisplay{
		entity = params.entity,
		showEmptyState = showEmptyState,
		notificationCacheAccessFn = notificationCacheAccessFn,
	}, true)
end

local VehicleReadoutHudIconMasterGame = react.RegisterRecipe("ApaszVehicleReadoutHudIconMasterGame", function(
	params : Builtin.HudIconParam,
	userParam : HudIconToolbox.HudIconMasterUserParam
) : TreeNodeId
	react.setMouseTransparent(true)
	local isAdditionallyVisibleVehicle = useIsAdditionallyVisibleVehicle(params.entity)
	react.setLightweight(true)
	if not shouldReplaceVehicleHud(params.entity, userParam, isAdditionallyVisibleVehicle) then
		return makeHudHost(react.CallOriginalRecipe(hud_icon_toolbox.HudIconMasterGame, params, userParam), false)
	end
	return makeCustomVehicleHud(
		params,
		userParam,
		not userParam.hideEmptyVehicles,
		true
	)
end)

local VehicleReadoutLineHudIconMaster = react.RegisterRecipe("ApaszVehicleReadoutLineHudIconMaster", function(
	params : Builtin.HudIconParam,
	userParam : EntityWindowHud.EntityWindowHudUserParam
) : TreeNodeId
	react.setMouseTransparent(true)
	local isAdditionallyVisibleVehicle = useIsAdditionallyVisibleVehicle(params.entity)
	react.setLightweight(true)
	if not shouldReplaceLineVehicleHud(params.entity, userParam, isAdditionallyVisibleVehicle) then
		return makeHudHost(react.CallOriginalRecipe(entity_window_hud.LineHudIconMaster, params, userParam), false)
	end
	return makeCustomVehicleHud(
		params,
		userParam,
		true,
		params.entity == userParam.selectedEntity
	)
end)

local function doReplace(replacementApi : ReactReplacementApi)
	settings = loadSettings()
	replacementApi.ReplaceRecipe(hud_icon_toolbox.HudIconMasterGame, VehicleReadoutHudIconMasterGame)
	replacementApi.ReplaceRecipe(entity_window_hud.LineHudIconMaster, VehicleReadoutLineHudIconMaster)
end

return {
	doReplace = doReplace,
}
