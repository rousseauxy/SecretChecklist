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

	local aboutTitle = aboutPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	aboutTitle:SetPoint("CENTER", 0, 60)
	aboutTitle:SetText(L["ADDON_NAME"] or "Secrets Checklist")

	local aboutVersion = aboutPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	aboutVersion:SetPoint("TOP", aboutTitle, "BOTTOM", 0, -8)
	aboutVersion:SetText(
		"Version " .. (
			C_AddOns and C_AddOns.GetAddOnMetadata
			and C_AddOns.GetAddOnMetadata("SecretChecklist", "Version")
			or "1.2.1"
		)
	)

	local aboutAuthor = aboutPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	aboutAuthor:SetPoint("TOP", aboutVersion, "BOTTOM", 0, -4)
	aboutAuthor:SetText(L["ABOUT_BY"] or "By Calaglyn")

	local aboutDesc = aboutPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	aboutDesc:SetPoint("TOP", aboutAuthor, "BOTTOM", 0, -20)
	aboutDesc:SetWidth(480)
	aboutDesc:SetJustifyH("CENTER")
	aboutDesc:SetTextColor(0.8, 0.8, 0.8)
	aboutDesc:SetText(
		L["ABOUT_DESC"] or
		"Track secret collectibles in World of Warcraft.\nMounts, Pets, Toys, Achievements, Quests, and Transmog."
	)

end  -- SC:BuildAboutPanel
