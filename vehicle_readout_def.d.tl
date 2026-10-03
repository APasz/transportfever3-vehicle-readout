global record VehicleReadoutPolicy
	enum VehicleVisibility
		"All"
		"SelectedLine"
		"SelectedVehicle"
		"None"
	end

	enum DestinationKind
		"None"
		"NextStop"
		"Depot"
	end

	enum OperationalStateKind
		"EnRoute"
		"AtTerminal"
		"GoingToDepot"
		"InDepot"
		"AwaitingAssignment"
		"Unassigned"
		"NoPath"
		"UserStopped"
	end

	enum HiddenStatePresentation
		"Hidden"
		"Icon"
		"Label"
	end

	enum StateDisplay
		"Hidden"
		"Icon"
		"Label"
		"NamedDepot"
	end

	shouldShowForVehicle : function(
		VehicleVisibility,
		boolean,
		boolean,
		boolean
	) : boolean
	getHiddenStatePresentation : function(OperationalStateKind) : HiddenStatePresentation
	resolveStateDisplay : function(
		boolean,
		boolean,
		HiddenStatePresentation,
		boolean
	) : StateDisplay
	shouldShowNextStop : function(boolean, DestinationKind) : boolean
end
