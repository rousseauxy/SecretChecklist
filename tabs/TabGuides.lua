-- =================================================================
-- SecretChecklistTabGuides.lua
-- Builds the Guides journal tab panel.
--
-- SC:BuildGuidesPanel(frame, L) is called by Initialize() in
-- SecretChecklistFrame.lua after the filter dropdown is configured.
--
-- Shared state access:
--   SC:GetFilterStatus()  -- returns the active status filter string
--   SC:GetFilterKinds()   -- returns the active kind-filter table
--   SC.onFilterChange     -- set here; called by OnFilterChanged in Frame.lua
--   SC.guidesSearchBox    -- set here; used by SwitchTab to anchor FilterDropdown
--   SC.guidesPanel        -- set here; used by SwitchTab to show/hide
-- =================================================================

local SC = _G.SecretChecklist
if not SC then return end

local math_min, math_max = math.min, math.max
local math_rad = math.rad
local tinsert  = table.insert

function SC:BuildGuidesPanel(frame, L)

	-- ==============================================
	-- PANEL FRAME
	-- ==============================================

	SC.guidesPanel = CreateFrame("Frame", nil, frame.Inset)
	SC.guidesPanel:SetAllPoints(frame.Inset)
	SC.guidesPanel:Hide()
	local guidesPanel = SC.guidesPanel  -- local alias for readability

	-- ---- dimension constants ----
	local GP_LEFT_W    = 240   -- width of the list pane
	local GP_DIV_W     = 2     -- divider strip
	local GP_PAD       = 8     -- general padding
	local GP_ROW_H     = 44    -- height of each list row
	local GP_FILTER_H  = 28    -- height reserved at top of list pane for filter dropdown
	local GP_TOP_DRP   = GP_PAD + 20  -- total drop from panel top to list pane start

	-- ---- per-panel state ----
	local guides_entries    = {}   -- filtered entry list
	local guides_rowButtons = {}   -- row button frames in scrollChild
	local guides_selected   = nil  -- currently selected entry
	local scrollFrame, scrollBar   -- scroll widgets assigned in Left Pane section below

	-- ==============================================
	-- FILTERING  (reads shared filter state via SC accessors)
	-- ==============================================

	local function Guides_ApplyFilter()
		local showCollected     = SC:GetShowCollected()
		local showMissing       = SC:GetShowMissing()
		local filterKinds       = SC:GetFilterKinds()
		local mindSeekerOnly    = SC:GetFilterMindSeekerOnly()
		local sortBy            = SC:GetSortBy()
		guides_entries = {}
		for _, e in ipairs(SC.entries or {}) do
			local kindOk   = filterKinds[e.kind] ~= false
			local msOk     = not mindSeekerOnly or e.mindSeeker == true
			local statusOk = true
			if showCollected ~= showMissing then
				local st = SC.GetEntryStatus and SC:GetEntryStatus(e) or "unknown"
				local isCollected = (st == "collected")
				if showCollected and not isCollected then
					statusOk = false
				elseif showMissing and isCollected then
					statusOk = false
				end
			end
			if kindOk and msOk and statusOk then
				tinsert(guides_entries, e)
			end
		end
		-- Sort
		local kindOrder = { mount=1, pet=2, toy=3, achievement=4, transmog=5, quest=6, housing=7 }
		if sortBy == "name" then
			table.sort(guides_entries, function(a, b)
				local na = SC.GetEntryName and SC:GetEntryName(a) or (a.name or "")
				local nb = SC.GetEntryName and SC:GetEntryName(b) or (b.name or "")
				return na:lower() < nb:lower()
			end)
		elseif sortBy == "status" then
			local statusOrder = { missing=1, unknown=2, manual=3, collected=4 }
			table.sort(guides_entries, function(a, b)
				local sa = statusOrder[SC.GetEntryStatus and SC:GetEntryStatus(a) or "unknown"] or 2
				local sb = statusOrder[SC.GetEntryStatus and SC:GetEntryStatus(b) or "unknown"] or 2
				if sa ~= sb then return sa < sb end
				local na = SC.GetEntryName and SC:GetEntryName(a) or (a.name or "")
				local nb = SC.GetEntryName and SC:GetEntryName(b) or (b.name or "")
				return na:lower() < nb:lower()
			end)
		elseif sortBy == "status_col" then
			local statusOrder = { collected=1, missing=2, unknown=3, manual=4 }
			table.sort(guides_entries, function(a, b)
				local sa = statusOrder[SC.GetEntryStatus and SC:GetEntryStatus(a) or "unknown"] or 3
				local sb = statusOrder[SC.GetEntryStatus and SC:GetEntryStatus(b) or "unknown"] or 3
				if sa ~= sb then return sa < sb end
				local na = SC.GetEntryName and SC:GetEntryName(a) or (a.name or "")
				local nb = SC.GetEntryName and SC:GetEntryName(b) or (b.name or "")
				return na:lower() < nb:lower()
			end)
		else -- "type"
			table.sort(guides_entries, function(a, b)
				local ka = kindOrder[a.kind or "unknown"] or 99
				local kb = kindOrder[b.kind or "unknown"] or 99
				if ka ~= kb then return ka < kb end
				local na = SC.GetEntryName and SC:GetEntryName(a) or (a.name or "")
				local nb = SC.GetEntryName and SC:GetEntryName(b) or (b.name or "")
				return na:lower() < nb:lower()
			end)
		end
		if scrollFrame then scrollFrame:SetVerticalScroll(0) end
		if scrollBar   then scrollBar:SetValue(0) end
	end

	-- forward declarations for mutual recursion
	local Guides_RefreshList
	local Guides_ShowDetail

	-- Expose combined refresh so OnFilterChanged in Frame.lua can call it
	SC.onFilterChange = function()
		Guides_ApplyFilter()
		Guides_RefreshList()
	end

	-- ==============================================
	-- LEFT LIST PANE
	-- (starts GP_TOP_DRP px below panel top)
	-- ==============================================

	local listPane = CreateFrame("Frame", nil, guidesPanel)
	listPane:SetPoint("TOPLEFT",    guidesPanel, "TOPLEFT",    GP_PAD, -GP_TOP_DRP)
	listPane:SetPoint("BOTTOMLEFT", guidesPanel, "BOTTOMLEFT", GP_PAD,  GP_PAD)
	listPane:SetWidth(GP_LEFT_W)

	-- ScrollFrame: clips the list rows and handles vertical scrolling
	scrollFrame = CreateFrame("ScrollFrame", nil, listPane)
	scrollFrame:SetPoint("TOPLEFT",     listPane, "TOPLEFT",     0, -GP_PAD)
	scrollFrame:SetPoint("BOTTOMRIGHT", listPane, "BOTTOMRIGHT", 0, 0)

	-- Export top-right of listPane so SwitchTab can anchor FilterDropdown here
	SC.guidesListPane = listPane

	-- ScrollChild: all row buttons live here; height is set per filter result
	local scrollChild = CreateFrame("Frame")
	scrollChild:SetWidth(GP_LEFT_W)
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)

	-- Scrollbar: plain Slider (no UIPanelScrollBarTemplate = no SetVerticalScroll callback)
	scrollBar = CreateFrame("Slider", nil, guidesPanel)
	scrollBar:SetOrientation("VERTICAL")
	scrollBar:SetWidth(6)
	scrollBar:SetPoint("TOPLEFT",    listPane, "TOPRIGHT",    4, -16)
	scrollBar:SetPoint("BOTTOMLEFT", listPane, "BOTTOMRIGHT", 4,  16)
	scrollBar:SetMinMaxValues(0, 0)
	scrollBar:SetValueStep(GP_ROW_H)
	scrollBar:SetObeyStepOnDrag(true)
	scrollBar:SetThumbTexture("Interface\\ChatFrame\\ChatFrameBackground")
	local sbThumb = scrollBar:GetThumbTexture()
	if sbThumb then
		local dThumb = SC:ThemeColor("divider")
		sbThumb:SetColorTexture(dThumb[1], dThumb[2], dThumb[3], dThumb[4])
		sbThumb:SetWidth(6)
		sbThumb:SetHeight(20)
	end
	scrollBar:SetValue(0)
	scrollBar:SetScript("OnValueChanged", function(self, val)
		scrollFrame:SetVerticalScroll(val)
	end)

	-- Vertical divider
	local divider = guidesPanel:CreateTexture(nil, "BACKGROUND")
	divider:SetWidth(GP_DIV_W)
	divider:SetPoint("TOPLEFT",    listPane, "TOPRIGHT",    16, 0)  -- 6 (scrollbar) + 10
	divider:SetPoint("BOTTOMLEFT", listPane, "BOTTOMRIGHT", 16, 0)
	local dC = SC:ThemeColor("divider")
	divider:SetColorTexture(dC[1], dC[2], dC[3], dC[4])
	SC.themeTargets = SC.themeTargets or {}
	SC.themeTargets.divider   = divider
	SC.themeTargets.scrollBar = scrollBar

	-- ==============================================
	-- RIGHT DETAIL PANE
	-- ==============================================

	local detailPane = CreateFrame("Frame", nil, guidesPanel)
	detailPane:SetPoint("TOPLEFT",     divider,    "TOPRIGHT",      GP_PAD, 0)
	detailPane:SetPoint("BOTTOMRIGHT", guidesPanel, "BOTTOMRIGHT", -15, GP_PAD)

	-- Icon (plain, no collection border)
	local detailIcon = detailPane:CreateTexture(nil, "ARTWORK")
	detailIcon:SetSize(48, 48)
	detailIcon:SetPoint("TOPLEFT", detailPane, "TOPLEFT", 0, -GP_PAD)
	detailIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	-- Entry name (right of icon, vertically centered with icon)
	local detailName = detailPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	detailName:SetPoint("LEFT",  detailIcon, "RIGHT",  10, 0)
	detailName:SetPoint("RIGHT", detailPane, "RIGHT",  -6, 0)
	detailName:SetJustifyH("LEFT")
	detailName:SetWordWrap(false)

	-- Kind badge (below icon)
	local detailKind = detailPane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	detailKind:SetPoint("TOPLEFT", detailIcon, "BOTTOMLEFT", 0, -8)

	-- Collected / missing status
	local detailStatus = detailPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	detailStatus:SetPoint("TOPLEFT", detailKind, "BOTTOMLEFT", 0, -4)
	detailStatus:SetJustifyH("LEFT")

	-- Source (gold, word-wrapped)
	local detailSource = detailPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	detailSource:SetPoint("TOPLEFT",  detailStatus, "BOTTOMLEFT", 0,  -6)
	detailSource:SetPoint("TOPRIGHT", detailPane,   "TOPRIGHT",  -6,   0)
	detailSource:SetJustifyH("LEFT")
	detailSource:SetTextColor(1, 0.82, 0)
	detailSource:SetWordWrap(true)

	-- Description (grey, word-wrapped)
	local detailDesc = detailPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	detailDesc:SetPoint("TOPLEFT",  detailSource, "BOTTOMLEFT", 0,  -6)
	detailDesc:SetPoint("TOPRIGHT", detailPane,   "TOPRIGHT",  -6,   0)
	detailDesc:SetJustifyH("LEFT")
	detailDesc:SetTextColor(0.8, 0.8, 0.8)
	detailDesc:SetWordWrap(true)

	-- Wowhead guide link button — same visual template as the Filter dropdown
	-- DropdownButton + WowStyle1FilterDropdownTemplate gives the identical look.
	-- SetScript("OnClick") replaces the built-in dropdown-open handler entirely,
	-- so clicking shows our copy popup instead of a menu.
	local linkBtn = CreateFrame("DropdownButton", nil, detailPane, "WowStyle1FilterDropdownTemplate")
	linkBtn:SetSize(90, 22)
	linkBtn:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", 0, GP_PAD)
	linkBtn:SetText("Wowhead")
	linkBtn.currentURL = ""
	linkBtn:SetEnabled(false)  -- greyed until a URL is present
	-- Hide the dropdown arrow — iterate regions to find it by texture path/atlas
	for _, region in ipairs({ linkBtn:GetRegions() }) do
		local rtype = region.GetObjectType and region:GetObjectType()
		if rtype == "Texture" then
			local atlas = region.GetAtlas and region:GetAtlas()
			local file  = region.GetTexture and region:GetTexture()
			if (atlas and atlas:lower():find("arrow")) or (type(file) == "string" and file:lower():find("arrow")) then
				region:Hide()
			end
		end
	end
	linkBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Wowhead Guide", 1, 0.82, 0)
		if self.currentURL ~= "" then
			GameTooltip:AddLine("Click to copy link", 0.8, 0.8, 0.8)
		else
			GameTooltip:AddLine("No guide link yet", 0.6, 0.6, 0.6)
		end
		GameTooltip:Show()
	end)
	linkBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

	-- Copy-link popup (UIParent child so it floats above the addon frame)
	local copyDialog = CreateFrame("Frame", nil, UIParent)
	copyDialog:SetSize(305, 52)
	copyDialog:SetFrameStrata("FULLSCREEN_DIALOG")
	copyDialog:SetFrameLevel(100)
	copyDialog:SetClampedToScreen(true)
	copyDialog:Hide()

	local copyBg = copyDialog:CreateTexture(nil, "BACKGROUND")
	copyBg:SetAllPoints()
	copyBg:SetColorTexture(0.05, 0.05, 0.08, 0.95)

	local copyBorderLine = copyDialog:CreateTexture(nil, "BORDER")
	copyBorderLine:SetPoint("TOPLEFT",     copyDialog, "TOPLEFT",      1, -1)
	copyBorderLine:SetPoint("BOTTOMRIGHT", copyDialog, "BOTTOMRIGHT", -1,  1)
	copyBorderLine:SetColorTexture(0.35, 0.30, 0.18, 0.9)

	local copyLabel = copyDialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	copyLabel:SetPoint("TOPLEFT", copyDialog, "TOPLEFT", 8, -5)
	copyLabel:SetText("Ctrl+C to copy  ·  Esc to close")
	copyLabel:SetTextColor(0.65, 0.65, 0.65)

	local copyBox = CreateFrame("EditBox", nil, copyDialog)
	copyBox:SetPoint("BOTTOMLEFT",  copyDialog, "BOTTOMLEFT",   8,  6)
	copyBox:SetPoint("BOTTOMRIGHT", copyDialog, "BOTTOMRIGHT", -8,  6)
	copyBox:SetHeight(24)
	copyBox:SetAutoFocus(true)
	copyBox:SetMaxLetters(512)
	copyBox:SetFontObject("ChatFontNormal")
	copyBox:SetJustifyH("LEFT")
	copyBox:SetTextInsets(4, 4, 2, 2)
	local copyBoxBg = copyBox:CreateTexture(nil, "BACKGROUND")
	copyBoxBg:SetAllPoints()
	copyBoxBg:SetColorTexture(0.1, 0.1, 0.15, 0.95)
	copyBox:SetScript("OnEscapePressed",   function() copyDialog:Hide() end)
	copyBox:SetScript("OnEnterPressed",    function() copyDialog:Hide() end)
	copyBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	copyBox:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(copyDialog.currentURL or "")
			self:HighlightText()
		end
	end)

	linkBtn:SetScript("OnClick", function(self)
		local url = self.currentURL or ""
		if url == "" then return end
		copyDialog.currentURL = url
		copyDialog:ClearAllPoints()
		-- Convert button screen position to UIParent coordinate space so the
		-- popup stays put when the main frame is dragged
		local bx, by = self:GetCenter()
		local scale  = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
		copyDialog:SetPoint("TOP", UIParent, "BOTTOMLEFT",
			bx * scale,
			(by - self:GetHeight() * 0.5) * scale - 4)
		copyBox:SetText(url)
		copyDialog:Show()
		copyBox:SetFocus()
		copyBox:HighlightText()
	end)

	-- ==============================================
	-- 3-D MODEL VIEWER
	-- Hidden for achievement / quest / missing model.
	-- Supports drag-to-rotate and scroll-to-zoom.
	-- ==============================================

	local detailModel = CreateFrame("DressUpModel", nil, detailPane)
	detailModel:SetPoint("TOPLEFT",     detailDesc, "BOTTOMLEFT",    0, -10)
	detailModel:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT",   0,   0)
	detailModel:SetUnit("none")
	detailModel:SetFacing(0)

	local modelBg = detailModel:CreateTexture(nil, "BACKGROUND")
	modelBg:SetAllPoints()
	modelBg:SetColorTexture(0, 0, 0, 0)

	-- ModelScene for housing items only (asset is a numeric file ID, needs SetModelByFileID).
	-- Mounts and pets use detailModel (DressUpModel) via SetDisplayInfo which is simpler and reliable.
	local HOUSING_SCENE_ID = (Constants and Constants.HousingCatalogConsts
		and Constants.HousingCatalogConsts.HOUSING_CATALOG_DECOR_MODELSCENEID_DEFAULT) or 861
	local detailModelScene = CreateFrame("ModelScene", nil, detailPane, "PanningModelSceneMixinTemplate")
	detailModelScene:SetPoint("TOPLEFT",     detailDesc, "BOTTOMLEFT",    0, -10)
	detailModelScene:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT",   0,   0)
	detailModelScene:Hide()
	detailModelScene:TransitionToModelSceneID(HOUSING_SCENE_ID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)

	-- Dedicated model for zoomed transmog slot view (mirrors AppearanceTooltip's .Zoomed model).
	-- SetKeepModelOnHide keeps the player loaded between views so TryOn can be called synchronously.
	local detailModelZoomed = CreateFrame("DressUpModel", nil, detailPane)
	detailModelZoomed:SetPoint("TOPLEFT",     detailDesc, "BOTTOMLEFT",    0, -10)
	detailModelZoomed:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT",   0,   0)
	detailModelZoomed:SetKeepModelOnHide(true)
	detailModelZoomed:SetUnit("player")  -- pre-load player model at creation (mirrors AppearanceTooltip's PLAYER_LOGIN)
	detailModelZoomed:Hide()
	detailModelZoomed:SetScript("OnModelLoaded", function(self)
		-- Only re-apply camera (same as AppearanceTooltip – TryOn is called synchronously, not here)
		if self.cameraID and Model_ApplyUICamera then
			Model_ApplyUICamera(self, self.cameraID)
		end
	end)

	detailModel:EnableMouse(true)
	detailModel:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self.isRotating = true
			self.lastMouseX = GetCursorPosition()
		end
	end)
	detailModel:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			self.isRotating = false
		end
	end)
	detailModel:SetScript("OnUpdate", function(self)
		if self.isRotating then
			local x  = GetCursorPosition()
			local dx = x - (self.lastMouseX or x)
			self.lastMouseX = x
			if dx ~= 0 then
				self.modelFacing = (self.modelFacing or 0) + dx * 0.013
				self:SetFacing(self.modelFacing)
			end
		end
	end)
	detailModel:SetScript("OnMouseWheel", function(self, delta)
		self.camScale = math_max(0.3, math_min(5, (self.camScale or 1) - delta * 0.15))
		self:SetCamDistanceScale(self.camScale)
	end)
	-- Reapply transmog slot camera after async model load (same pattern as AppearanceTooltip)
	detailModel:SetScript("OnModelLoaded", function(self)
		if self.cameraID and Model_ApplyUICamera then
			Model_ApplyUICamera(self, self.cameraID)
		end
	end)

	-- ==============================================
	-- POPULATE DETAIL PANE
	-- ==============================================

	Guides_ShowDetail = function(entry)
		guides_selected = entry
		if not entry then
			detailIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			detailKind:SetText("")
			detailName:SetText("")
			detailStatus:SetText("")
			detailSource:SetText("")
			detailDesc:SetText("")
			linkBtn.currentURL = ""
			linkBtn:SetEnabled(false)
			copyDialog:Hide()
			detailModel:Hide()
			detailModelScene:Hide()
			detailModelZoomed:Hide()
			return
		end

		linkBtn.currentURL = entry.wowheadURL or ""
		linkBtn:SetEnabled(linkBtn.currentURL ~= "")

		local icon = SC.GetEntryIcon and SC:GetEntryIcon(entry) or "Interface\\Icons\\INV_Misc_QuestionMark"
		detailIcon:SetTexture(icon)

		local kindColors = {
			mount       = { 0.6, 0.8, 1 },
			pet         = { 0.6, 1,   0.6 },
			toy         = { 1,   0.6, 1   },
			achievement = { 1,   0.82, 0  },
			quest       = { 1,   0.7, 0.3 },
			transmog    = { 0.8, 0.6, 1   },
			housing     = { 1,   0.85, 0.5 },
		}
		local kc      = kindColors[entry.kind] or { 0.8, 0.8, 0.8 }
		local kindStr = entry.kind and (entry.kind:sub(1,1):upper() .. entry.kind:sub(2)) or ""
		detailKind:SetText(kindStr)
		detailKind:SetTextColor(kc[1], kc[2], kc[3])

		local entryName = SC.GetEntryName and SC:GetEntryName(entry) or entry.name or "?"
		detailName:SetText(entryName)

		local status = SC.GetEntryStatus and SC:GetEntryStatus(entry) or "unknown"
		if status == "collected" then
			detailName:SetTextColor(1, 0.82, 0)
		elseif status == "missing" then
			detailName:SetTextColor(0.6, 0.6, 0.6)
		else
			detailName:SetTextColor(1, 1, 1)
		end

		if status == "collected" then
			detailStatus:SetText(L["TOOLTIP_COLLECTED"] or "Collected")
			detailStatus:SetTextColor(0, 1, 0)
		elseif status == "missing" then
			detailStatus:SetText(L["TOOLTIP_NOT_COLLECTED"] or "Not collected")
			detailStatus:SetTextColor(1, 0, 0)
		else
			detailStatus:SetText("")
		end

		local sourceText, descText = ""
		if entry.kind == "mount" then
			local mountID = entry.mountID
			if not mountID and entry.itemID and C_MountJournal and C_MountJournal.GetMountFromItem then
				mountID = C_MountJournal.GetMountFromItem(entry.itemID)
			end
			if mountID and C_MountJournal and C_MountJournal.GetMountInfoExtraByID then
				local _, desc, src = C_MountJournal.GetMountInfoExtraByID(mountID)
				sourceText = src  or ""
				descText   = desc or ""
			end
		elseif entry.kind == "pet" then
			if entry.speciesID and C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID then
				local _, _, _, _, src, desc = C_PetJournal.GetPetInfoBySpeciesID(entry.speciesID)
				sourceText = src  or ""
				descText   = desc or ""
			end
		elseif entry.kind == "achievement" and entry.achievementID then
			local _, _, _, _, _, _, _, desc = GetAchievementInfo(entry.achievementID)
			descText = desc or ""
		elseif entry.kind == "housing" and entry.itemID and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
			local info = C_HousingCatalog.GetCatalogEntryInfoByItem(entry.itemID, false)
			if info then
				sourceText = info.sourceText or ""
			end
		end
		-- Entry-level overrides (for toys and any entry with hand-authored data)
		if type(entry.source) == "string" and entry.source ~= "" then sourceText = entry.source end
		if type(entry.desc)   == "string" and entry.desc   ~= "" then descText   = entry.desc   end
		detailSource:SetText(sourceText)
		detailDesc:SetText(descText)

		-- Hide model entirely for achievement / quest; show only if a model loads
		if entry.kind == "achievement" or entry.kind == "quest" then
			detailModel:Hide()
			detailModelScene:Hide()
			detailModelZoomed:Hide()
			return
		end

		-- Reset both viewers; each block below shows exactly one
		detailModelScene:ClearScene()
		detailModelScene:Hide()
		detailModelZoomed.cameraID = nil
		detailModelZoomed:Hide()
		detailModel:ClearModel()
		detailModel:SetUnit("none")
		detailModel:RefreshCamera()
		detailModel.cameraID    = nil
		detailModel.modelFacing = 0
		detailModel.camScale    = 1
		detailModel:SetFacing(0)
		detailModel:SetCamDistanceScale(1)
		detailModel:Hide()
		local modelSet = false

		if entry.kind == "mount" then
			local mountID = entry.mountID
			if not mountID and entry.itemID and C_MountJournal and C_MountJournal.GetMountFromItem then
				mountID = C_MountJournal.GetMountFromItem(entry.itemID)
			end
			if mountID and C_MountJournal and C_MountJournal.GetMountInfoExtraByID then
				local creatureDisplayID = C_MountJournal.GetMountInfoExtraByID(mountID)
				if creatureDisplayID and creatureDisplayID > 0 then
					detailModel:SetDisplayInfo(creatureDisplayID)
					detailModel:SetCamera(1)
					detailModel:SetFacing(math_rad(30))
					if entry.camScale then
						detailModel:SetCamDistanceScale(entry.camScale)
					end
					modelSet = true
				end
			end
		elseif entry.kind == "pet" and C_PetJournal then
			local creatureDisplayID
			if entry.itemID and C_PetJournal.GetPetInfoByItemID then
				local _, _, _, _, _, _, _, _, _, _, _, displayID = C_PetJournal.GetPetInfoByItemID(entry.itemID)
				creatureDisplayID = displayID
			end
			if (not creatureDisplayID or creatureDisplayID == 0) and entry.speciesID and C_PetJournal.GetPetInfoBySpeciesID then
				local _, _, _, _, _, _, _, _, _, _, _, displayID = C_PetJournal.GetPetInfoBySpeciesID(entry.speciesID)
				creatureDisplayID = displayID
			end
			if creatureDisplayID and creatureDisplayID > 0 then
				detailModel:SetDisplayInfo(creatureDisplayID)
				detailModel.modelFacing = math_rad(20)
				detailModel.camScale    = 1.25
				detailModel:SetFacing(detailModel.modelFacing)
				detailModel:SetCamDistanceScale(detailModel.camScale)
				modelSet = true
			end
		elseif entry.kind == "transmog" and entry.itemID then
			-- Determine inventory type so weapons can be shown without a player body
			local invType = select(4, C_Item.GetItemInfoInstant(entry.itemID))
			local appearanceID = C_TransmogCollection and C_TransmogCollection.GetItemInfo(entry.itemID)
			local cameraID = appearanceID and C_TransmogCollection.GetAppearanceCameraID(appearanceID)
			if cameraID == 0 then cameraID = nil end  -- 0 is truthy in Lua but means no camera
			local heldSlots = {
				INVTYPE_WEAPON=true, INVTYPE_2HWEAPON=true, INVTYPE_WEAPONMAINHAND=true,
				INVTYPE_WEAPONOFFHAND=true, INVTYPE_RANGED=true, INVTYPE_RANGEDRIGHT=true,
				INVTYPE_HOLDABLE=true, INVTYPE_SHIELD=true,
			}
			if heldSlots[invType] then
				-- Weapon/held: display the item floating alone, no player body
				detailModel.cameraID = cameraID
				if cameraID and Model_ApplyUICamera then
					Model_ApplyUICamera(detailModel, cameraID)
					detailModel:SetAnimation(0, 0)
				end
				if appearanceID then
					detailModel:SetItemAppearance(appearanceID)
				else
					detailModel:SetItem(entry.itemID)
				end
				modelSet = true
			else
				-- Worn armor: mirrors AppearanceTooltip's Zoomed model flow exactly.
				-- SetKeepModelOnHide keeps the player loaded so TryOn works synchronously.
				detailModelZoomed.cameraID = cameraID
				detailModelZoomed:SetUnit("player")
				detailModelZoomed:Dress()
				if cameraID and Model_ApplyUICamera then
					Model_ApplyUICamera(detailModelZoomed, cameraID)
					detailModelZoomed:SetAnimation(0, 0)
				end
				detailModelZoomed:TryOn("item:" .. entry.itemID)
				detailModelZoomed:Show()
				-- modelSet stays false; detailModel hidden, detailModelZoomed shown above
			end
		elseif entry.kind == "housing" and entry.itemID then
			if C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
				local info = C_HousingCatalog.GetCatalogEntryInfoByItem(entry.itemID, false)
				if info and info.asset and info.asset > 0 then
					detailModelScene:ClearScene()
					detailModelScene:SetViewInsets(0, 0, 0, 0)
					detailModelScene:TransitionToModelSceneID(HOUSING_SCENE_ID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)
					local actor = detailModelScene:GetActorByTag("decor") or detailModelScene:CreateActor("decor")
					if actor then
						actor:SetPreferModelCollisionBounds(true)
						actor:SetModelByFileID(info.asset)
					end
					detailModelScene:Show()
				end
			end
		end

		detailModel:SetShown(modelSet)
		-- detailModelScene visibility is set explicitly in each block above
	end

	-- ==============================================
	-- ROW BUILDER & LIST REFRESH
	-- ==============================================

	local function Guides_GetOrCreateRow(idx)
		if guides_rowButtons[idx] then return guides_rowButtons[idx] end

		local yOff = -(idx - 1) * GP_ROW_H
		local row  = CreateFrame("Button", nil, scrollChild)
		row:SetHeight(GP_ROW_H)
		row:SetPoint("TOPLEFT",  scrollChild, "TOPLEFT",  0, yOff)
		row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, yOff)

		local rowBg = row:CreateTexture(nil, "BACKGROUND")
		rowBg:SetAllPoints()
		local rbC = SC:ThemeColor(idx % 2 == 0 and "rowEven" or "rowOdd")
		rowBg:SetColorTexture(rbC[1], rbC[2], rbC[3], rbC[4])
		row.rowBg = rowBg

		local selBg = row:CreateTexture(nil, "BACKGROUND")
		selBg:SetAllPoints()
		local scC = SC:ThemeColor("rowSel")
		selBg:SetColorTexture(scC[1], scC[2], scC[3], scC[4])
		selBg:Hide()
		row.selBg = selBg

		local hovTex = row:CreateTexture(nil, "HIGHLIGHT")
		hovTex:SetAllPoints()
		local hcC = SC:ThemeColor("rowHov")
		hovTex:SetColorTexture(hcC[1], hcC[2], hcC[3], hcC[4])
		row:SetHighlightTexture(hovTex)
		row.hovTex = hovTex

		-- Icon (plain, no border)
		local ico = row:CreateTexture(nil, "ARTWORK")
		ico:SetSize(32, 32)
		ico:SetPoint("LEFT", 4, 0)
		ico:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		row.ico = ico

		local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		lbl:SetPoint("LEFT",  ico, "RIGHT", 6,   0)
		lbl:SetPoint("RIGHT", row, "RIGHT", -14, 0)  -- leave room for status dot
		lbl:SetJustifyH("LEFT")
		lbl:SetMaxLines(2)
		row.lbl = lbl

		local dot = row:CreateTexture(nil, "OVERLAY")
		dot:SetSize(6, 6)
		dot:SetPoint("RIGHT", row, "RIGHT", -4, 0)
		row.dot = dot

		row:SetScript("OnClick", function(self)
			Guides_ShowDetail(self.entry)
			for _, r in pairs(guides_rowButtons) do
				r.selBg:SetShown(r.entry == self.entry)
			end
		end)

		guides_rowButtons[idx] = row
		return row
	end

	Guides_RefreshList = function()
		local total    = #guides_entries
		local contentH = math_max(1, total * GP_ROW_H)
		scrollChild:SetHeight(contentH)

		local visibleH  = scrollFrame:GetHeight()
		if not visibleH or visibleH < GP_ROW_H then visibleH = contentH end
		local maxScroll = math_max(0, contentH - visibleH)
		local curScroll = math_min(scrollFrame:GetVerticalScroll(), maxScroll)

		scrollFrame:SetVerticalScroll(curScroll)
		scrollBar:SetMinMaxValues(0, maxScroll)
		scrollBar:SetValue(curScroll)
		scrollBar:SetShown(maxScroll > 0)

		for i = 1, math_max(total, #guides_rowButtons) do
			local entry = guides_entries[i]
			local row   = Guides_GetOrCreateRow(i)

			if entry then
				local icon = SC.GetEntryIcon and SC:GetEntryIcon(entry) or "Interface\\Icons\\INV_Misc_QuestionMark"
				row.ico:SetTexture(icon)

				local status = SC.GetEntryStatus and SC:GetEntryStatus(entry) or "unknown"
				local isCol  = (status == "collected")
				local isMis  = (status == "missing")
				row.ico:SetDesaturated(not isCol)

				local entryName = SC.GetEntryName and SC:GetEntryName(entry) or entry.name or "?"
				row.lbl:SetText(entryName)
				if isCol then
					row.lbl:SetTextColor(1, 0.82, 0)
				elseif isMis then
					row.lbl:SetTextColor(0.5, 0.5, 0.5)
				else
					row.lbl:SetTextColor(0.9, 0.9, 0.9)
				end

				if isCol then
					row.dot:SetColorTexture(0, 1, 0)
				elseif isMis then
					row.dot:SetColorTexture(1, 0, 0)
				else
					row.dot:SetColorTexture(0.5, 0.5, 0.5)
				end
				row.dot:Show()

				row.entry = entry
				row.selBg:SetShown(entry == guides_selected)
				row:Show()
			else
				row:Hide()
				row.entry = nil
				row.selBg:Hide()
			end
		end
	end

	-- Recolour existing rows when the theme changes (called by SC:ApplyTheme)
	SC.onThemeChanged = function()
		for idx, row in ipairs(guides_rowButtons) do
			if row.rowBg then
				local c = SC:ThemeColor(idx % 2 == 0 and "rowEven" or "rowOdd")
				row.rowBg:SetColorTexture(c[1], c[2], c[3], c[4])
			end
			if row.selBg then
				local c = SC:ThemeColor("rowSel")
				row.selBg:SetColorTexture(c[1], c[2], c[3], c[4])
			end
			if row.hovTex then
				local c = SC:ThemeColor("rowHov")
				row.hovTex:SetColorTexture(c[1], c[2], c[3], c[4])
			end
		end
	end

	listPane:EnableMouseWheel(true)
	listPane:SetScript("OnMouseWheel", function(self, delta)
		local cur = scrollFrame:GetVerticalScroll()
		local max = scrollFrame:GetVerticalScrollRange()
		local new = math_max(0, math_min(max, cur - delta * GP_ROW_H))
		scrollFrame:SetVerticalScroll(new)
		scrollBar:SetValue(new)
	end)

	guidesPanel:SetScript("OnShow", function()
		SC:RefreshCaches()
		if SC.updateProgressBar then SC.updateProgressBar() end
		-- Apply preselected entry (set by Overview icon click) before filtering
		if SC.guidesPreselect then
			guides_selected = SC.guidesPreselect
			SC.guidesPreselect = nil
		end
		Guides_ApplyFilter()
		Guides_RefreshList()
		if guides_selected then
			-- Scroll the list so the selected row is visible
			for i, e in ipairs(guides_entries) do
				if e == guides_selected then
					local visH     = scrollFrame:GetHeight() or 0
					local targetY  = (i - 1) * GP_ROW_H
					local scrollTo = math_max(0, targetY - math_max(0, (visH - GP_ROW_H) / 2))
					local maxScroll = math_max(0, #guides_entries * GP_ROW_H - visH)
					scrollTo = math_min(scrollTo, maxScroll)
					scrollFrame:SetVerticalScroll(scrollTo)
					scrollBar:SetValue(scrollTo)
					break
				end
			end
			Guides_ShowDetail(guides_selected)
		elseif #guides_entries > 0 then
			local firstRow = guides_rowButtons[1]
			if firstRow then firstRow:Click() end
		else
			Guides_ShowDetail(nil)
		end
	end)

end  -- SC:BuildGuidesPanel
