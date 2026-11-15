-- =================================================================
-- SecretChecklistValidate.lua
-- Data self-check, run with /secrets validate.
--
-- The entry schema is implicit -- around twenty recognised fields on an entry
-- and as many again on a step, documented only by how the panels happen to read
-- them. A contributor adding a secret has to reverse-engineer it from
-- neighbouring entries, and a typo produces a silently wrong row rather than an
-- error.
--
-- This checks the whole data set against what the code actually requires and
-- reports in one pass. It also answers questions that can only be asked from a
-- live client, such as which waypoint maps the game will accept.
-- =================================================================

local SC = _G.SecretChecklist
if not SC then return end

local KNOWN_KINDS = {
	mount = true, pet = true, toy = true, achievement = true,
	quest = true, transmog = true, housing = true, mystery = true, manual = true,
}

-- The id each kind needs before its status can be resolved at all.
local REQUIRED_ID = {
	mount       = { "mountID", "itemID" },
	pet         = { "speciesID" },
	toy         = { "itemID" },
	achievement = { "achievementID" },
	quest       = { "questID", "questIDs" },
	transmog    = { "itemID" },
	housing     = { "itemID" },
}

local function HasAnyField(entry, fields)
	for _, f in ipairs(fields) do
		if entry[f] ~= nil then return true end
	end
	return false
end

-- Walks every waypoint on a step, including substep and faction variants.
local function ForEachWaypoint(step, fn)
	local function visit(wp)
		if type(wp) == "table" and wp.mapID then fn(wp) end
	end
	visit(step.waypoint)
	for _, wp in ipairs(step.waypoints or {}) do visit(wp) end
	if type(step.factionWaypoint) == "table" then
		visit(step.factionWaypoint.alliance)
		visit(step.factionWaypoint.horde)
	end
	local subLists = { step.substeps }
	if type(step.factionSubsteps) == "table" then
		subLists[#subLists + 1] = step.factionSubsteps.alliance
		subLists[#subLists + 1] = step.factionSubsteps.horde
	end
	for _, list in ipairs(subLists) do
		for _, sub in ipairs(list or {}) do
			visit(sub.waypoint)
			for _, wp in ipairs(sub.waypoints or {}) do visit(wp) end
			if type(sub.factionWaypoint) == "table" then
				visit(sub.factionWaypoint.alliance)
				visit(sub.factionWaypoint.horde)
			end
		end
	end
end

local function Report(problems, label)
	if #problems == 0 then return 0 end
	print(("|cffff4444%s (%d):|r"):format(label, #problems))
	for i = 1, math.min(#problems, 15) do
		print("   " .. problems[i])
	end
	if #problems > 15 then
		print(("   ... and %d more"):format(#problems - 15))
	end
	return #problems
end

function SC:ValidateData()
	local entries = SC.entries or {}
	local byName  = {}
	for _, e in ipairs(entries) do
		if type(e.name) == "string" then byName[e.name] = true end
	end

	local schema, refs, waypoints = {}, {}, {}
	local blockedMaps, totalWaypoints = {}, 0
	local canCheckMaps = C_Map and C_Map.CanSetUserWaypointOnMap

	for i, e in ipairs(entries) do
		local id = type(e.name) == "string" and e.name or ("entry #" .. i)

		if type(e.name) ~= "string" or e.name == "" then
			schema[#schema + 1] = ("entry #%d has no name"):format(i)
		end
		if not KNOWN_KINDS[e.kind] then
			schema[#schema + 1] = ("%s: unknown kind %q"):format(id, tostring(e.kind))
		elseif REQUIRED_ID[e.kind] and not HasAnyField(e, REQUIRED_ID[e.kind]) then
			schema[#schema + 1] = ("%s: kind %q needs one of %s")
				:format(id, e.kind, table.concat(REQUIRED_ID[e.kind], " / "))
		end

		-- Cross-references must name an entry that exists, or the Guides pane
		-- renders them as dead grey text with no indication of the typo.
		for _, field in ipairs({ "requires", "requiredFor", "stepsRef", "partOf" }) do
			local value = e[field]
			local list = (type(value) == "table" and value)
				or (type(value) == "string" and { value })
				or nil
			for _, target in ipairs(list or {}) do
				if not byName[target] then
					refs[#refs + 1] = ("%s: %s -> %q does not match any entry"):format(id, field, target)
				end
			end
		end

		for si, step in ipairs(e.steps or {}) do
			if type(step.label) ~= "string" or step.label == "" then
				schema[#schema + 1] = ("%s: step %d has no label"):format(id, si)
			end
			ForEachWaypoint(step, function(wp)
				totalWaypoints = totalWaypoints + 1
				if canCheckMaps and not C_Map.CanSetUserWaypointOnMap(wp.mapID) then
					if not blockedMaps[wp.mapID] then
						blockedMaps[wp.mapID] = true
						local info = C_Map.GetMapInfo and C_Map.GetMapInfo(wp.mapID)
						waypoints[#waypoints + 1] = ("%s: step %d -> mapID %d (%s) rejects user waypoints")
							:format(id, si, wp.mapID, (info and info.name) or "unknown map")
					end
				end
			end)
		end
	end

	print(("|cffffcc00SecretChecklist:|r validating %d entries, %d waypoints..."):format(#entries, totalWaypoints))
	local total = Report(schema, "Schema problems")
		+ Report(refs, "Broken cross-references")
		+ Report(waypoints, "Maps that reject Blizzard waypoints")

	if total == 0 then
		print("|cff00ff00SecretChecklist:|r data is clean.")
	else
		print(("|cffffcc00SecretChecklist:|r %d problem(s) found."):format(total))
	end
	if not canCheckMaps then
		print("|cffffcc00SecretChecklist:|r C_Map.CanSetUserWaypointOnMap unavailable; waypoint maps not checked.")
	end
	return total
end
