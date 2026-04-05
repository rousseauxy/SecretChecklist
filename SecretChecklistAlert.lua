-- =================================================================
-- SecretChecklistAlert.lua
-- Shows a toast alert (using WoW's AlertFrame system) when the
-- player newly collects a tracked secret during a play session.
--
-- Alert fires when:
--   mount/pet/toy  → journal update event triggers a diff vs snapshot
--   achievement     → ACHIEVEMENT_EARNED event
--   quest          → QUEST_TURNED_IN event
--
-- Clicking the toast opens the addon and navigates to the guide.
-- =================================================================

local SC = _G.SecretChecklist
if not SC then return end

-- ==============================================
-- MIXIN  (referenced by name in the XML template)
-- ==============================================

SecretChecklist_AlertFrameMixin = {}

function SecretChecklist_AlertFrameMixin:OnLoad()
	-- Dark background panel – no custom texture file needed; uses
	-- SetColorTexture so this works with any WoW client version.
	local bg = self:CreateTexture(nil, "BACKGROUND", nil, -8)
	bg:SetAllPoints()
	bg:SetColorTexture(0.04, 0.03, 0.09, 0.96)
	self._defaultBg = bg

	-- Gold top accent line
	local topLine = self:CreateTexture(nil, "BACKGROUND", nil, -7)
	topLine:SetHeight(2)
	topLine:SetPoint("TOPLEFT",  0, 0)
	topLine:SetPoint("TOPRIGHT", 0, 0)
	topLine:SetColorTexture(0.80, 0.65, 0.10, 1)
	self._topLine = topLine

	-- Subtle bottom line
	local botLine = self:CreateTexture(nil, "BACKGROUND", nil, -7)
	botLine:SetHeight(1)
	botLine:SetPoint("BOTTOMLEFT",  0, 0)
	botLine:SetPoint("BOTTOMRIGHT", 0, 0)
	botLine:SetColorTexture(0.40, 0.32, 0.05, 1)
	self._botLine = botLine

	-- Apply ElvUI skin immediately if that theme is already active
	SC:ApplyAlertTheme(self)
end

function SecretChecklist_AlertFrameMixin:SetAlert(entry, icon)
	self.entry = entry
	self.Icon.Texture:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
	self.Name:SetText("Secret Collected!")
	self.Label:SetText(SC:GetEntryName(entry))

	-- Trigger the glow / shine animations
	if self.glow  then self.glow:Show();  self.glow.animIn:Play()  end
	if self.shine then self.shine:Show(); self.shine.animIn:Play() end
end

function SecretChecklist_AlertFrameMixin:OnEnter()
	if not self.entry then return end
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", -10, -2)
	GameTooltip:SetText(SC:GetEntryName(self.entry), 1, 1, 1)
	GameTooltip:AddLine("Click to view guide", 0.6, 0.6, 0.6)
	GameTooltip:Show()
end

function SecretChecklist_AlertFrameMixin:OnLeave()
	GameTooltip:Hide()
end

function SecretChecklist_AlertFrameMixin:OnClick(button, down)
	-- Right-click / standard close handling from the alert system
	if AlertFrame_OnClick and AlertFrame_OnClick(self, button, down) then
		return
	end
	-- Left-click: open the checklist and jump straight to the guide entry
	if self.entry then
		SC:OpenSecretsFrame()
		if SC.OpenGuideForEntry then
			SC:OpenGuideForEntry(self.entry)
		end
	end
end

-- ==============================================
-- THEME INTEGRATION
-- ==============================================

-- Called from OnLoad (when frame first spawns) and from ApplyTheme via Themes.lua.
-- Skins a single alert frame instance to match the active theme.
function SC:ApplyAlertTheme(alertFrame)
	if not alertFrame then return end
	local isElvUI = (SC.currentThemeName == "ElvUI") and ElvUI

	if isElvUI then
		local E = unpack(ElvUI)
		-- Replace the plain colour bg with an ElvUI Transparent backdrop
		if alertFrame._defaultBg then alertFrame._defaultBg:Hide() end
		if alertFrame._topLine   then alertFrame._topLine:Hide()   end
		if alertFrame._botLine   then alertFrame._botLine:Hide()   end
		if not alertFrame.backdrop and alertFrame.CreateBackdrop then
			alertFrame:CreateBackdrop("Transparent")
		end
		if alertFrame.backdrop then alertFrame.backdrop:Show() end
		-- Accent the icon border with ElvUI's border colour
		if alertFrame.Icon then
			local br, bg, bb = 0.3, 0.3, 0.3
			if E.media and E.media.bordercolor then
				br, bg, bb = E.media.bordercolor[1], E.media.bordercolor[2], E.media.bordercolor[3]
			end
			if alertFrame.Icon.Overlay then
				alertFrame.Icon.Overlay:SetVertexColor(br, bg, bb, 1)
			end
		end
	else
		-- Restore default look
		if alertFrame._defaultBg then alertFrame._defaultBg:Show() end
		if alertFrame._topLine   then alertFrame._topLine:Show()   end
		if alertFrame._botLine   then alertFrame._botLine:Show()   end
		if alertFrame.backdrop   then alertFrame.backdrop:Hide()   end
		if alertFrame.Icon and alertFrame.Icon.Overlay then
			alertFrame.Icon.Overlay:SetVertexColor(1, 1, 1, 1)
		end
	end
end

-- Re-skins all currently pooled/visible alert frame instances.
-- Called by Themes.lua OnApply / OnReset via SC.onAlertThemeChanged.
function SC:RefreshAlertTheme()
	if not alertSubSystem then return end
	-- The sub-system keeps an internal pool; iterate the global frame pool via
	-- the named template pattern ContainedAlertFrame uses.
	local i = 1
	while true do
		local f = _G["SecretChecklist_AlertFrame_Template" .. i]
		if not f then break end
		self:ApplyAlertTheme(f)
		i = i + 1
	end
end

-- ==============================================
-- ALERT SYSTEM
-- ==============================================

local alertSubSystem = nil

function SC:InitAlertSystem()
	if not AlertFrame or not AlertFrame.AddQueuedAlertFrameSubSystem then return end

	local function SetUp(frame, entry, icon)
		frame:SetAlert(entry, icon)
	end

	alertSubSystem = AlertFrame:AddQueuedAlertFrameSubSystem(
		"SecretChecklist_AlertFrame_Template",
		SetUp,
		4,   -- max simultaneous toasts
		10   -- vertical spacing between stacked toasts
	)
end

function SC:FireSecretAlert(entry)
	if not alertSubSystem then return end
	if SecretChecklistDB and SecretChecklistDB.alertsEnabled == false then return end
	alertSubSystem:AddAlert(entry, SC:GetEntryIcon(entry))
end

-- ==============================================
-- COLLECTION SNAPSHOT  (diff-based detection)
-- ==============================================
--
-- SC._alertSnapshot  – keyed by entry table reference
--   true   = confirmed collected at snapshot time
--   false  = confirmed missing  at snapshot time
--   nil    = status was unknown at snapshot time
--
-- Alerts fire only when snapshot is false AND current status is collected.
-- This ensures we never alert for items already owned before this session.
-- ==============================================

SC._alertSnapshot = nil
SC._alertReady    = false

function SC:BuildAlertSnapshot()
	SC._alertSnapshot = {}
	for _, entry in ipairs(SC.entries or {}) do
		if entry.kind ~= "manual" and entry.kind ~= "housing" then
			local status = SC:GetEntryStatus(entry)
			if status == "collected" then
				SC._alertSnapshot[entry] = true
			elseif status == "missing" then
				SC._alertSnapshot[entry] = false
			end
			-- "unknown" intentionally left as nil
		end
		-- housing entries are excluded here; their snapshots are managed by
		-- CheckHousingCollections, triggered by HOUSING_STORAGE_ENTRY_UPDATED
		-- (per-item ownership change) and HOUSE_DECOR_ADDED_TO_CHEST events.
	end
	SC._alertReady = true
end

function SC:CheckForNewCollections()
	if not SC._alertReady or not SC._alertSnapshot then return end
	for _, entry in ipairs(SC.entries or {}) do
		-- Housing is excluded: its catalog data loads asynchronously and would
		-- cause false-positive toasts. Use CheckHousingCollections instead.
		if entry.kind ~= "manual" and entry.kind ~= "housing" then
			local status     = SC:GetEntryStatus(entry)
			local isCollected = (status == "collected")
			local isMissing   = (status == "missing")
			local snapshot    = SC._alertSnapshot[entry]

			if isCollected then
				if snapshot == false then
					-- Confirmed transition: missing → collected
					SC:FireSecretAlert(entry)
				end
				SC._alertSnapshot[entry] = true
			elseif isMissing and snapshot == nil then
				-- First confirmed missing reading; set it so future collection fires
				SC._alertSnapshot[entry] = false
			end
			-- "unknown" status: leave snapshot unchanged
		end
	end
end

-- Called when HOUSING_STORAGE_ENTRY_UPDATED fires (a specific entry's ownership changed)
-- or HOUSE_DECOR_ADDED_TO_CHEST fires (item looted into housing chest).
-- Silently sets the housing snapshot on first read; fires alert only on missing→collected transitions.
function SC:CheckHousingCollections()
	if not SC._alertSnapshot then return end
	for _, entry in ipairs(SC.entries or {}) do
		if entry.kind == "housing" then
			local status    = SC:GetEntryStatus(entry)
			local snapshot  = SC._alertSnapshot[entry]
			if status == "collected" then
				if snapshot == false then
					-- Confirmed transition: missing → collected during this session
					SC:FireSecretAlert(entry)
				end
				-- snapshot == nil means catalog just loaded with item already owned –
				-- do NOT toast; just record as collected.
				SC._alertSnapshot[entry] = true
			elseif status == "missing" then
				SC._alertSnapshot[entry] = false
			end
			-- "unknown" status: leave snapshot unchanged
		end
	end
end
