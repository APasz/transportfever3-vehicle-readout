local compilerPath = assert(arg[1], "Teal compiler path is required")
local gameRoot = assert(arg[2], "Transport Fever 3 directory is required")
local modRoot = assert(arg[3], "Mod directory is required")

local function readFile(path)
	local file = assert(io.open(path, "rb"))
	local content = assert(file:read("*a"))
	file:close()
	return content
end

local function replaceOnce(content, original, replacement)
	local first, last = string.find(content, original, 1, true)
	assert(first ~= nil and last ~= nil, "Expected Teal compiler patch point was not found")
	assert(string.find(content, original, last + 1, true) == nil, "Teal compiler patch point was ambiguous")
	return string.sub(content, 1, first - 1) .. replacement .. string.sub(content, last + 1)
end

local compilerSource = readFile(compilerPath)
compilerSource = replaceOnce(
	compilerSource,
	[[      -- local fd = io.open(tl_filename, "rb")
      -- if fd then
         -- return tl_filename, fd, tried
      -- end]],
	[[      local fd = io.open(tl_filename, "rb")
      if fd then
         return tl_filename, fd, tried
      end]]
)
compilerSource = replaceOnce(
	compilerSource,
	[[   if mod then
      return mod, env.module_filenames[module_name]
   else
      return a_type(w, "invalid", {}), false
   end]],
	[[   if mod then
      return mod, env.module_filenames[module_name]
   end]]
)

log = { error = function() end }
local compilerChunk = assert(load(compilerSource, "@" .. compilerPath, "t", _ENV))
local teal = compilerChunk()

package.path = table.concat({
	gameRoot .. "/api/tealdef/?.lua",
	gameRoot .. "/base/tealdef/?.lua",
	gameRoot .. "/content/?.lua",
	gameRoot .. "/vscode-template/?.lua",
	modRoot .. "/?.lua",
	package.path,
}, ";")

local environment = teal.init_env(false)
local checkCount = 0

local function checkTeal(path, label)
	local result = teal.process(path, environment)
	for _, errors in ipairs({ result.syntax_errors, result.type_errors, result.warnings }) do
		for _, diagnostic in ipairs(errors) do
			io.stderr:write(string.format(
				"%s:%d:%d: %s\n",
				diagnostic.filename or path,
				diagnostic.y,
				diagnostic.x,
				diagnostic.msg
			))
		end
	end
	assert(#result.syntax_errors == 0, label .. " has syntax errors")
	assert(#result.type_errors == 0, label .. " has type errors")
	assert(#result.warnings == 0, label .. " has warnings")
	print(label .. ": OK")
	return result
end

checkTeal(gameRoot .. "/vscode-template/all_def.tl", "Game definitions")
checkTeal(modRoot .. "/vehicle_readout_def.d.tl", "Vehicle Readout definitions")
local policyResult = checkTeal(modRoot .. "/content/vehicle_readout/vehicle_readout_policy.tl", "Vehicle Readout policy")
checkTeal(modRoot .. "/content/vehicle_readout/vehicle_readout.script.tl", "Vehicle Readout UI")

local generatedPolicy, generationError = teal.pretty_print_ast(policyResult.ast, "5.3")
assert(generatedPolicy ~= nil, generationError)
local policyEnvironment = {
	error = error,
	tostring = tostring,
}
local policyChunk = assert(load(generatedPolicy, "@vehicle_readout_policy.tl", "t", policyEnvironment))
local policy = policyChunk()

local function assertEqual(actual, expected, context)
	checkCount = checkCount + 1
	assert(actual == expected, context .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function assertErrors(action, context)
	checkCount = checkCount + 1
	local succeeded = pcall(action)
	assert(not succeeded, context .. ": expected an error")
end

local visibilities = { "All", "SelectedLine", "SelectedVehicle", "None" }
for _, visibility in ipairs(visibilities) do
	for _, additionallyVisible in ipairs({ false, true }) do
		for _, onSelectedLine in ipairs({ false, true }) do
			for _, selectedVehicle in ipairs({ false, true }) do
				local expected = additionallyVisible
					or visibility == "All"
					or (visibility == "SelectedLine" and onSelectedLine)
					or (visibility == "SelectedVehicle" and selectedVehicle)
				assertEqual(
					policy.shouldShowForVehicle(
						visibility,
						additionallyVisible,
						onSelectedLine,
						selectedVehicle
					),
					expected,
					"visibility matrix"
				)
			end
		end
	end
end

local hiddenStateExpectations = {
	EnRoute = "Hidden",
	AtTerminal = "Hidden",
	GoingToDepot = "Icon",
	InDepot = "Hidden",
	AwaitingAssignment = "Label",
	Unassigned = "Label",
	NoPath = "Label",
	UserStopped = "Icon",
}
for stateKind, expected in pairs(hiddenStateExpectations) do
	assertEqual(policy.getHiddenStatePresentation(stateKind), expected, "hidden-state policy for " .. stateKind)
end

local hiddenPresentations = { "Hidden", "Icon", "Label" }
for _, showOperatingState in ipairs({ false, true }) do
	for _, stateIsNotable in ipairs({ false, true }) do
		for _, hiddenPresentation in ipairs(hiddenPresentations) do
			for _, hasNamedDepot in ipairs({ false, true }) do
				local expected = "Hidden"
				if hiddenPresentation == "Label" then
					expected = "Label"
				elseif hasNamedDepot then
					expected = "NamedDepot"
				elseif showOperatingState and stateIsNotable then
					expected = "Label"
				elseif hiddenPresentation ~= "Hidden" then
					expected = hiddenPresentation
				end
				assertEqual(
					policy.resolveStateDisplay(
						showOperatingState,
						stateIsNotable,
						hiddenPresentation,
						hasNamedDepot
					),
					expected,
					"state-display matrix"
				)
			end
		end
	end
end

for _, showDestination in ipairs({ false, true }) do
	for _, destinationKind in ipairs({ "None", "NextStop", "Depot" }) do
		assertEqual(
			policy.shouldShowNextStop(showDestination, destinationKind),
			showDestination and destinationKind == "NextStop",
			"destination matrix"
		)
	end
end

assertErrors(function()
	policy.shouldShowForVehicle("Invalid", false, false, false)
end, "invalid visibility")
assertErrors(function()
	policy.shouldShowForVehicle("Invalid", true, true, true)
end, "invalid visibility with visibility override")
assertErrors(function()
	policy.getHiddenStatePresentation("Invalid")
end, "invalid operational state")
for _, showOperatingState in ipairs({ false, true }) do
	for _, stateIsNotable in ipairs({ false, true }) do
		for _, hasNamedDepot in ipairs({ false, true }) do
			assertErrors(function()
				policy.resolveStateDisplay(showOperatingState, stateIsNotable, "Invalid", hasNamedDepot)
			end, "invalid hidden-state presentation")
		end
	end
end
for _, showDestination in ipairs({ false, true }) do
	assertErrors(function()
		policy.shouldShowNextStop(showDestination, "Invalid")
	end, "invalid destination kind")
end

print(string.format("Policy matrix: %d checks passed", checkCount))
