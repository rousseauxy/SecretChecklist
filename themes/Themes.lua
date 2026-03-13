-- =================================================================
-- SecretChecklist/themes/Themes.lua
-- Lightweight theme registry inspired by BetterBags (MIT License).
--
-- Each theme is a table:
--   Name        string   Display name shown in options.
--   Description string   Short description shown in options.
--   Available   boolean  false if a required addon (e.g. ElvUI) is absent.
--   colors      table    Named colour arrays {r, g, b, a}.
--
-- Public API (on the SC object):
--   SC:RegisterTheme(key, theme)   Add or override a theme.
--   SC:ApplyTheme(key)             Switch active theme; persists to SavedVariables.
--   SC:ThemeColor(key)             Return {r,g,b,a} for a named colour in the active theme.
-- =================================================================

local SC = _G.SecretChecklist
if not SC then return end

-- ==============================
-- Theme registry
-- ==============================

SC.themes          = {}
SC.currentThemeName = "Default"
SC.themeTargets    = SC.themeTargets or {}   -- populated by Core and panel files

function SC:RegisterTheme(key, theme)
	theme.key     = key
	SC.themes[key] = theme
end

-- Returns {r,g,b,a} for a named colour; falls back to Default then white.
function SC:ThemeColor(key)
	local name  = SC.currentThemeName or "Default"
	local theme = SC.themes[name]
	local c     = theme and theme.colors and theme.colors[key]
	if not c then
		local def = SC.themes["Default"]
		c = def and def.colors and def.colors[key]
	end
	return c or {1, 1, 1, 1}
end

-- Activates the theme.  Updates all registered targets and notifies panels.
function SC:ApplyTheme(key)
	local theme = SC.themes[key]
	if not theme or not theme.Available then
		key   = "Default"
		theme = SC.themes["Default"]
	end
	if not theme then return end

	-- Reset previous theme first
	local oldKey = SC.currentThemeName
	if oldKey and oldKey ~= key then
		local oldTheme = SC.themes[oldKey]
		if oldTheme and oldTheme.OnReset then oldTheme.OnReset() end
	end

	SC.currentThemeName     = key
	SecretChecklistDB.theme = key

	-- Inset background
	local t = SC.themeTargets
	if t.insetBg then
		local c = self:ThemeColor("insetBg")
		t.insetBg:SetColorTexture(c[1], c[2], c[3], c[4])
	end

	-- Divider (stored by TabGuides after creation)
	if t.divider then
		local c = self:ThemeColor("divider")
		t.divider:SetColorTexture(c[1], c[2], c[3], c[4])
	end

	-- Theme-specific extra work (e.g. ElvUI frame skinning)
	if theme.OnApply then theme.OnApply() end

	-- Notify the Guides panel to recolour existing rows
	if SC.onThemeChanged then SC.onThemeChanged() end

	-- Notify the Overview panel to update icon border style
	if SC.updateOverviewIcons then SC.updateOverviewIcons() end
end

-- =================================================================
-- BUILT-IN: Default
-- The classic SecretChecklist dark-amber look.
-- =================================================================
SC:RegisterTheme("Default", {
	Name        = "Default",
	Description = "The classic SecretChecklist dark-amber look.",
	Available   = true,
	colors = {
		insetBg = {0.12, 0.10, 0.08, 0.98},
		rowEven = {0,    0,    0,    0.18},
		rowOdd  = {0,    0,    0,    0.08},
		rowSel  = {0.25, 0.20, 0.10, 0.60},
		rowHov  = {1,    1,    1,    0.06},
		divider = {0.30, 0.25, 0.20, 0.80},
	},
})

-- =================================================================
-- BUILT-IN: ElvUI
-- Flat dark theme matching ElvUI's aesthetic.
-- Only available when ElvUI is loaded.
-- Inspired by BetterBags' ElvUI theme (MIT License, Antonio Lobato).
-- =================================================================
SC:RegisterTheme("ElvUI", {
	Name        = "ElvUI",
	Description = "A flat dark theme matching ElvUI's aesthetic. Requires ElvUI.",
	Available   = (ElvUI ~= nil),
	colors = {
		insetBg = {0.06, 0.06, 0.06, 1.00},
		rowEven = {0.10, 0.10, 0.10, 0.80},
		rowOdd  = {0.07, 0.07, 0.07, 0.70},
		rowSel  = {0.15, 0.40, 0.70, 0.50},
		rowHov  = {1,    1,    1,    0.08},
		divider = {0.20, 0.20, 0.20, 1.00},
	},
	OnApply = function()
		if not ElvUI then return end
		local E = unpack(ElvUI)  ---@type ElvUI
		local S = E:GetModule("Skins")
		local frame = _G.SecretChecklistFrame
		if not frame or not S then return end

		-- Non-destructively hide PortraitFrameTemplate chrome (NineSlice border,
		-- background and title streaks).  We hide rather than strip so OnReset can
		-- simply call Show() to restore them.
		if frame.NineSlice      then frame.NineSlice:Hide() end
		if frame.Bg             then frame.Bg:Hide() end
		if frame.TopTileStreaks then frame.TopTileStreaks:Hide() end

		-- Hide the portrait container entirely in ElvUI mode.
		-- The About easter egg is now on the title text instead.
		if frame.PortraitContainer then frame.PortraitContainer:Hide() end

		-- Skin the close button once (S:HandleCloseButton is idempotent via IsSkinned).
		local closeBtn = frame.CloseButton
		if closeBtn and S.HandleCloseButton and not closeBtn.IsSkinned then
			S:HandleCloseButton(closeBtn)
		end
		if closeBtn then closeBtn:Show() end

		-- Add an ElvUI backdrop to the main frame once; show it on subsequent applies.
		if not frame.backdrop and frame.CreateBackdrop then
			frame:CreateBackdrop("Transparent")
		end
		if frame.backdrop then frame.backdrop:Show() end

		-- Add ElvUI backdrop to the inset content area.
		if frame.Inset then
			if not frame.Inset.backdrop and frame.Inset.CreateBackdrop then
				frame.Inset:CreateBackdrop("Transparent")
			end
			if frame.Inset.backdrop then frame.Inset.backdrop:Show() end
		end

		-- Hide the theme-colored inset background texture (replaced by backdrop above).
		if SC.themeTargets and SC.themeTargets.insetBg then
			SC.themeTargets.insetBg:Hide()
		end

		-- Tab decoration: create a WoW BackdropTemplate child frame per tab, sized
		-- to match the button.  Store as btn.elvBg so it can be toggled without
		-- touching ElvUI internals (avoids HandleTab's early-return guard and
		-- StripTextures destroying our atlas objects).
		if SC.tabButtons_list then
			for _, btn in ipairs(SC.tabButtons_list) do
				-- Hide our original atlas textures
				for _, p in ipairs({"LeftActive","RightActive","MiddleActive","Left","Right","Middle"}) do
					if btn[p] then btn[p]:Hide() end
				end
				if not btn.elvBg then
					local bg = CreateFrame("Frame", nil, btn, "BackdropTemplate")
					local spacing = E.PixelMode and 1 or 3
					bg:SetPoint("TOPLEFT",     btn, "TOPLEFT",     spacing,  E.PixelMode and -1 or -3)
					bg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -spacing,  3)
					bg:SetFrameLevel(math.max(1, btn:GetFrameLevel() - 1))
					local blankTex = (E.Media and E.Media.Textures and E.Media.Textures.White8x8)
						or "Interface\\ChatFrame\\ChatFrameBackground"
					bg:SetBackdrop({
						bgFile   = blankTex,
						edgeFile = blankTex,
						edgeSize = 1,
						insets   = { left = 1, right = 1, top = 1, bottom = 1 },
					})
					local br, bg2, bb = 0.3, 0.3, 0.3
					if E.media and E.media.bordercolor then
						br, bg2, bb = E.media.bordercolor[1], E.media.bordercolor[2], E.media.bordercolor[3]
					end
					bg:SetBackdropColor(0.06, 0.06, 0.06, 1)
					bg:SetBackdropBorderColor(br, bg2, bb, 1)
					btn.elvBg = bg
				end
				btn.elvBg:Show()
			end
		end

		-- Style the scrollbar to match the divider: flat colored thumb.
		if SC.themeTargets and SC.themeTargets.scrollBar then
			local sb = SC.themeTargets.scrollBar
			sb:SetWidth(6)
			sb:SetThumbTexture("Interface\\ChatFrame\\ChatFrameBackground")
			local thumb = sb:GetThumbTexture()
			if thumb then
				local c = SC:ThemeColor("divider")
				thumb:SetColorTexture(c[1], c[2], c[3], c[4])
				thumb:SetWidth(6)
				thumb:SetHeight(20)
			end
		end
	end,
	OnReset = function()
		local frame = _G.SecretChecklistFrame
		if not frame then return end

		-- Restore PortraitFrameTemplate chrome.
		if frame.NineSlice         then frame.NineSlice:Show() end
		if frame.Bg                then frame.Bg:Show() end
		if frame.TopTileStreaks    then frame.TopTileStreaks:Show() end
		if frame.PortraitContainer then frame.PortraitContainer:Show() end

		-- Restore the original red close button (S:HandleCloseButton is not reversible).
		local closeBtn = frame.CloseButton
		if closeBtn then
			if closeBtn.Texture then closeBtn.Texture:Hide() end
			closeBtn:SetNormalAtlas("RedButton-Exit")
			closeBtn:SetPushedAtlas("RedButton-exit-pressed")
			closeBtn:SetDisabledAtlas("RedButton-Exit-Disabled")
			closeBtn:SetHighlightAtlas("RedButton-Highlight", "ADD")
		end

		-- Hide ElvUI backdrops added during OnApply.
		if frame.backdrop then frame.backdrop:Hide() end
		if frame.Inset and frame.Inset.backdrop then frame.Inset.backdrop:Hide() end

		-- Restore the theme-colored inset background texture.
		if SC.themeTargets and SC.themeTargets.insetBg then
			SC.themeTargets.insetBg:Show()
			local c = SC:ThemeColor("insetBg")
			SC.themeTargets.insetBg:SetColorTexture(c[1], c[2], c[3], c[4])
		end

		-- Hide tab BackdropTemplate frames and restore original atlas textures + active state.
		if SC.tabButtons_list then
			for _, btn in ipairs(SC.tabButtons_list) do
				if btn.elvBg then btn.elvBg:Hide() end

				local isActive = btn.tabID == (SC.currentTab or 1)
				if btn.LeftActive then
					btn.LeftActive:SetAtlas("uiframe-activetab-left", true)
					if isActive then btn.LeftActive:Show() else btn.LeftActive:Hide() end
				end
				if btn.RightActive then
					btn.RightActive:SetAtlas("uiframe-activetab-right", true)
					if isActive then btn.RightActive:Show() else btn.RightActive:Hide() end
				end
				if btn.MiddleActive then
					btn.MiddleActive:SetAtlas("_uiframe-activetab-center", true)
					if isActive then btn.MiddleActive:Show() else btn.MiddleActive:Hide() end
				end
				if btn.Left then
					btn.Left:SetAtlas("uiframe-tab-left", true)
					if isActive then btn.Left:Hide() else btn.Left:Show() end
				end
				if btn.Right then
					btn.Right:SetAtlas("uiframe-tab-right", true)
					if isActive then btn.Right:Hide() else btn.Right:Show() end
				end
				if btn.Middle then
					btn.Middle:SetAtlas("_uiframe-tab-center", true)
					if isActive then btn.Middle:Hide() else btn.Middle:Show() end
				end
				if btn.Text then
					btn.Text:SetFontObject(isActive and "GameFontHighlightSmall" or "GameFontNormalSmall")
				end
			end
		end

		-- Restore default scrollbar.
		if SC.themeTargets and SC.themeTargets.scrollBar then
			local sb = SC.themeTargets.scrollBar
			sb:SetWidth(6)
			local thumb = sb:GetThumbTexture()
			if thumb then
				local c = SC:ThemeColor("divider")
				thumb:SetColorTexture(c[1], c[2], c[3], c[4])
				thumb:SetWidth(6)
				thumb:SetHeight(20)
			end
		end
	end,
})
