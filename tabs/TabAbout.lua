-- =================================================================
-- SecretChecklistTabAbout.lua
-- Builds the About tab panel for the SecretChecklist addon.
--
-- SC:BuildAboutPanel(frame, L) is called by Initialize() in
-- SecretChecklistFrame.lua after the filter dropdown is configured.
--
-- Sets SC.aboutPanel which SwitchTab uses to show/hide the panel.
-- =================================================================

local SC = _G.SecretChecklist
if not SC then return end

function SC:BuildAboutPanel(frame, L)

	SC.aboutPanel = CreateFrame("Frame", nil, frame.Inset)
	SC.aboutPanel:SetAllPoints(frame.Inset)
	SC.aboutPanel:Hide()
	local aboutPanel = SC.aboutPanel  -- local alias

	local aboutVersion = aboutPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	aboutVersion:SetPoint("TOP", aboutPanel, "TOP", 0, -20)
	aboutVersion:SetText(
		"Version " .. (
			C_AddOns and C_AddOns.GetAddOnMetadata
			and C_AddOns.GetAddOnMetadata("SecretChecklist", "Version")
			or "1.2.1"
		)
	)

	local aboutDesc = aboutPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	aboutDesc:SetPoint("TOP", aboutVersion, "BOTTOM", 0, -8)
	aboutDesc:SetWidth(480)
	aboutDesc:SetJustifyH("CENTER")
	aboutDesc:SetTextColor(0.8, 0.8, 0.8)
	aboutDesc:SetText(
		L["ABOUT_DESC"] or
		"Track secret collectibles in World of Warcraft.\nMounts, Pets, Toys, Achievements, Quests, and Transmog."
	)

	-- Dancing Terky model (between description and thanks section)
	local terkyModel = CreateFrame("DressUpModel", nil, aboutPanel)
	terkyModel:SetSize(180, 180)
	terkyModel:SetPoint("TOP", aboutDesc, "BOTTOM", 0, -12)

	local function StartDance(self)
		self:SetAnimation(69)  -- dance
	end

	-- Terky's display ID is a static game asset (verified: 15398). Hardcoded to avoid
	-- any dependency on the pet journal being loaded.
	local TERKY_DISPLAY_ID = 15398

	local function LoadTerkyModel()
		terkyModel:SetDisplayInfo(TERKY_DISPLAY_ID)
		terkyModel:SetFacing(0)
		terkyModel:SetCamDistanceScale(1.5)
		-- Give the renderer one frame to load the model geometry before starting the animation.
		C_Timer.After(0.2, function()
			if terkyModel:IsShown() then StartDance(terkyModel) end
		end)
	end

	-- Restart dance if it ever ends (safety net for one-shot animation sequences)
	terkyModel:SetScript("OnAnimFinished", function(self) StartDance(self) end)

	-- Load model each time the panel is shown.
	aboutPanel:SetScript("OnShow", function() LoadTerkyModel() end)

	-- Thanks section
	local thanksHeader = aboutPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	thanksHeader:SetPoint("TOP", terkyModel, "BOTTOM", 0, -12)
	thanksHeader:SetJustifyH("CENTER")
	thanksHeader:SetTextColor(1, 0.82, 0)
	thanksHeader:SetText(L["ABOUT_THANKS_HEADER"] or "Special Thanks")

	local thanksText = aboutPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	thanksText:SetPoint("TOP", thanksHeader, "BOTTOM", 0, -8)
	thanksText:SetWidth(480)
	thanksText:SetJustifyH("CENTER")
	thanksText:SetTextColor(0.8, 0.8, 0.8)
	thanksText:SetText(
		L["ABOUT_THANKS_TEXT"] or
		"A huge thank you to the Secret Finding Discord community\nfor all the incredible work they put into discovering\nthese secrets and documenting how to obtain them."
	)

	-- Clickable Discord link button
	local discordURL = "https://discord.gg/wowsecrets"
	local discordBtn = CreateFrame("Button", nil, aboutPanel)
	discordBtn:SetSize(300, 26)
	discordBtn:SetPoint("TOP", thanksText, "BOTTOM", 0, -10)

	local discordText = discordBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	discordText:SetAllPoints()
	discordText:SetJustifyH("CENTER")
	discordText:SetTextColor(0.4, 0.78, 1)
	discordText:SetText(L["ABOUT_DISCORD_LABEL"] or "Secret Finding Discord")

	-- Custom copy popup (same pattern as the Wowhead button in TabGuides)
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
			self:SetText(discordURL)
			self:HighlightText()
		end
	end)

	discordBtn:SetScript("OnEnter", function(self)
		discordText:SetTextColor(0.6, 0.92, 1)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(discordURL, 1, 1, 1)
		GameTooltip:AddLine("Click to copy link", 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	discordBtn:SetScript("OnLeave", function()
		discordText:SetTextColor(0.4, 0.78, 1)
		GameTooltip:Hide()
	end)
	discordBtn:SetScript("OnClick", function(self)
		copyDialog:ClearAllPoints()
		local bx, by = self:GetCenter()
		local scale  = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
		copyDialog:SetPoint("TOP", UIParent, "BOTTOMLEFT",
			bx * scale,
			(by - self:GetHeight() * 0.5) * scale - 4)
		copyBox:SetText(discordURL)
		copyDialog:Show()
		copyBox:SetFocus()
		copyBox:HighlightText()
	end)

	-- Warcraft Secrets thanks
	local wsThanksText = aboutPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	wsThanksText:SetPoint("TOP", discordBtn, "BOTTOM", 0, -16)
	wsThanksText:SetWidth(480)
	wsThanksText:SetJustifyH("CENTER")
	wsThanksText:SetTextColor(0.8, 0.8, 0.8)
	wsThanksText:SetText("Guide content and step data sourced from\nWowhead and Warcraft Secrets — the definitive community\nresources for WoW secret collectibles.")

	local wsURL = "https://warcraft-secrets.com"
	local wsBtn = CreateFrame("Button", nil, aboutPanel)
	wsBtn:SetSize(300, 26)
	wsBtn:SetPoint("TOP", wsThanksText, "BOTTOM", 0, -6)

	local wsBtnText = wsBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	wsBtnText:SetAllPoints()
	wsBtnText:SetJustifyH("CENTER")
	wsBtnText:SetTextColor(1, 0.6, 0.2)
	wsBtnText:SetText("warcraft-secrets.com")

	-- Reuse copyDialog for Warcraft Secrets link (update copyBox text on click)
	wsBtn:SetScript("OnEnter", function(self)
		wsBtnText:SetTextColor(1, 0.78, 0.4)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(wsURL, 1, 1, 1)
		GameTooltip:AddLine("Click to copy link", 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	wsBtn:SetScript("OnLeave", function()
		wsBtnText:SetTextColor(1, 0.6, 0.2)
		GameTooltip:Hide()
	end)
	wsBtn:SetScript("OnClick", function(self)
		copyDialog:ClearAllPoints()
		local bx, by = self:GetCenter()
		local scale  = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
		copyDialog:SetPoint("TOP", UIParent, "BOTTOMLEFT",
			bx * scale,
			(by - self:GetHeight() * 0.5) * scale - 4)
		copyBox:SetText(wsURL)
		copyDialog:Show()
		copyBox:SetFocus()
		copyBox:HighlightText()
	end)

end  -- SC:BuildAboutPanel
