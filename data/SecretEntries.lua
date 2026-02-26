-- SecretChecklist Data File
-- Contains all secret collectible entries

local SC = _G.SecretChecklist
if not SC then return end

-- ==============================================
-- ENTRIES DATA
-- ==============================================

SC.entries = {
	{ name = "Baa'ls Darksign", kind = "pet", speciesID = 2352, itemID = 162578, matchNames = { "Baa'l", "Baa'l", "Baal" } },
	{ name = "Black Dragon's Challenge Dummy", kind = "toy", itemID = 201933 },
	{ name = "Blanchy's Reins", kind = "mount", itemID = 182614, matchNames = { "Blanchy" } },
	{ name = "Bound Shadehound", kind = "mount", itemID = 184168 },
	{ name = "Crimson Tidestallion", kind = "mount", itemID = 169202 },
	{ name = "Courage", kind = "pet", speciesID = 3065, itemID = 184400 },
	{ name = "Enlightened Hearthstone", kind = "toy", itemID = 190196 },
	{ name = "Felreaver Deathcycle (Voidfire Deathcycle)", kind = "mount", itemID = 211089, spellID = 428068, matchNames = { "Voidfire Deathcycle", "Felreaver Deathcycle" } },
	{ name = "Glimr's Cracked Egg", kind = "pet", speciesID = 2888, itemID = 180034, matchNames = { "Glimr" } },
	{ name = "Jenafur", kind = "pet", speciesID = 2795, matchNames = { "Jenafur" } },
	{ name = "Keys to Incognitro, the Indecipherable Felcycle", kind = "mount", itemID = 229348, matchNames = { "Incognitro, the Indecipherable Felcycle" } },
	{ name = "Fathom Dweller (Kosumoth)", kind = "mount", mountID = 838, matchNames = { "Fathom Dweller" } },
	{ name = "Hungering Claw (Kosumoth)", kind = "pet", speciesID = 1932, itemID = 140261, matchNames = { "Hungering Claw" }, linkedSecret = true },
	{ name = "Leaders of Scholomance (Necromantic Knowledge)", kind = "achievement", achievementID = 18558 },
	{ name = "Lucid Nightmare", kind = "mount", itemID = 151623 },
	{ name = "Mimiron's Jumpjets", kind = "mount", itemID = 210022 },
	{ name = "Nazjatar Blood Serpent", kind = "mount", itemID = 161479 },
	{ name = "Nilganihmaht Control Ring", kind = "toy", itemID = 186713 },
	{ name = "Otto", kind = "mount", itemID = 198870 },
	{ name = "Phoenix Wishwing", kind = "pet", speciesID = 3292, itemID = 193373 },
	{ name = "Long-Forgotten Hippogryph", kind = "mount", itemID = 138258, matchNames = { "Long-Forgotten Hippogryph", "Reins of the Long-Forgotten Hippogryph" } },
	{ name = "Riddler's Mind-Worm", kind = "mount", itemID = 147835 },
	{ name = "Slime Serpent", kind = "mount", mountID = 1445 },
	{ name = "Wicker Pup (Spooky Bundle of Sticks)", kind = "pet", speciesID = 2411, itemID = 163497, matchNames = { "Wicker Pup" } },
	{ name = "The Hivemind", kind = "mount", itemID = 156798 },
	{ name = "Thrayir, Eyes of the Siren", kind = "mount", itemID = 232639 },
	{ name = "Tobias' Leash", kind = "pet", speciesID = 4263, itemID = 208151, matchNames = { "Tobias" } },
	{ name = "Uuna (from Uuna's Doll)", kind = "pet", speciesID = 2136, itemID = 153195, matchNames = { "Uuna", "Uuna's Doll", "Uuna's Doll" } },
	{ name = "Waist of Time", kind = "transmog", itemID = 162690 },
	{ name = "Wan'be's Buried Goods", kind = "quest", questID = 52192, icon = 133644 },
	{ name = "Xy Trustee's Gearglider", kind = "mount", itemID = 186639 },
}
