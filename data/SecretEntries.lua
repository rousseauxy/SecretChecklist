-- SecretChecklist Data File
-- Contains all secret collectible entries

local SC = _G.SecretChecklist
if not SC then return end

-- ==============================================
-- ENTRIES DATA
-- ==============================================

SC.entries = {
	-- ------------------------------------------------
	-- MOUNTS
	-- ------------------------------------------------
	{ name = "Blanchy's Reins",                              kind = "mount", mindSeeker = true, itemID = 182614,                   wowheadURL = "https://www.wowhead.com/news/sinrunner-blanchy-mount-obtained-special-mounting-animation-317673" },
	{ name = "Bound Shadehound",                             kind = "mount", mindSeeker = true, itemID = 184168,  camScale = 1.5,                   wowheadURL = "https://www.wowhead.com/news/bound-shadehound-mount-craftable-maw-mount-in-patch-9-0-5-320988" },
	{ name = "Crimson Tidestallion",                         kind = "mount", mindSeeker = true, itemID = 169202,                   wowheadURL = "https://www.wowhead.com/item=169202/crimson-tidestallion#comments:id=3130821" },
	{ name = "Fathom Dweller (Kosumoth)",                    kind = "mount", mindSeeker = true, mountID = 838,                     wowheadURL = "https://www.wowhead.com/guide/kosumoth-the-hungering-secret-mount-pet" },
	{ name = "Felreaver Deathcycle (Voidfire Deathcycle)",   kind = "mount", mindSeeker = true, itemID = 211089,                   wowheadURL = "https://www.wowhead.com/news/voidfire-deathcycle-earned-from-horrific-visions-in-patch-11-1-5-375774" },
	{ name = "Keys to Incognitro, the Indecipherable Felcycle", kind = "mount", mindSeeker = true, itemID = 229348,                wowheadURL = "https://www.wowhead.com/guide/secrets/ratts-revenge-incognitro-felcycle-guide" },
	{ name = "Long-Forgotten Hippogryph",                    kind = "mount", mindSeeker = true, itemID = 138258,                   wowheadURL = "https://www.wowhead.com/guide/reins-of-the-long-forgotten-hippogryph-mount" },
	{ name = "Lucid Nightmare",                              kind = "mount", mindSeeker = true, itemID = 151623,                   wowheadURL = "https://www.wowhead.com/guide/lucid-nightmare-secret-mount" },
	{ name = "Mimiron's Jumpjets",                           kind = "mount", mindSeeker = true, itemID = 210022,                   wowheadURL = "https://www.wowhead.com/news/secrets-of-azeroth-community-clue-4-solution-mimirons-jumpjets-mount-now-334998" },
	{ name = "Nazjatar Blood Serpent",                       kind = "mount", mindSeeker = true, itemID = 161479,                   wowheadURL = "https://www.wowhead.com/item=161479/nazjatar-blood-serpent" },
	{ name = "Nilganihmaht Control Ring",                    kind = "mount", mindSeeker = true, itemID = 186713,  camScale = 3,      wowheadURL = "https://www.wowhead.com/news/hand-of-nilganihmaht-secret-mount-in-chains-of-domination-322780" },
	{ name = "Otto",                                         kind = "mount", mindSeeker = true, itemID = 198870,                   wowheadURL = "https://www.wowhead.com/news/otto-mount-found-fish-around-the-dragon-isles-for-otter-mount-330658" },
	{ name = "Riddler's Mind-Worm",                          kind = "mount", mindSeeker = true, itemID = 147835,                   wowheadURL = "https://www.wowhead.com/guide/riddlers-mind-worm-secret-mount" },
	{ name = "Slime Serpent",                                kind = "mount", mindSeeker = true, mountID = 1445,                    wowheadURL = "https://www.wowhead.com/guide/shadowlands-mount-guide-10510#:~:text=The%20Necrotic%20Wake-,Slime%20Serpent,-Description%3A%20This" },
	{ name = "The Hivemind",                                 kind = "mount", mindSeeker = true, itemID = 156798,                   wowheadURL = "https://www.wowhead.com/guide/the-hivemind" },
	{ name = "Thrayir, Eyes of the Siren",                   kind = "mount", mindSeeker = true, itemID = 232639,                   wowheadURL = "https://www.wowhead.com/news/how-to-obtain-thrayir-eyes-of-the-siren-in-patch-11-0-7-stormcrow-mount-354470" },
	{ name = "Xy Trustee's Gearglider",                      kind = "mount", mindSeeker = true, itemID = 186639,                   wowheadURL = "https://www.wowhead.com/news/xy-trustees-gearglider-mount-and-cartel-transmorpher-toy-discovered-by-wow-379066" },
	{ name = "Pattie's Cap",                                 kind = "mount", itemID = 208152, linkedSecret = true,                 wowheadURL = "https://www.wowhead.com/item=208152/patties-cap#guides" },

	-- ------------------------------------------------
	-- PETS
	-- ------------------------------------------------
	{ name = "Baa'ls Darksign",                              kind = "pet",   mindSeeker = true, speciesID = 2352, itemID = 162578,  wowheadURL = "https://www.wowhead.com/guide/baal-secret-demonic-goat-battle-pet" },
	{ name = "Courage",                                      kind = "pet",   mindSeeker = true, speciesID = 3065, itemID = 184400,  wowheadURL = "https://www.wowhead.com/news/secret-battle-pet-courage-found-321354" },
	{ name = "Glimr's Cracked Egg",                          kind = "pet",   mindSeeker = true, speciesID = 2888, itemID = 180034,  wowheadURL = "https://www.wowhead.com/news/secret-purple-murloc-battle-pet-find-glimr-and-the-glimmerfin-tribe-in-grizzly-318904" },
	{ name = "Jenafur",                                      kind = "pet",   mindSeeker = true, speciesID = 2795,                   wowheadURL = "https://www.wowhead.com/guide/jenafur-secret-cat-battle-pet" },
	{ name = "Phoenix Wishwing",                             kind = "pet",   mindSeeker = true, speciesID = 3292, itemID = 193373,  wowheadURL = "https://www.wowhead.com/news/new-secret-discovered-phoenix-wishwing-battle-pet-332187#news-post-332187" },
	{ name = "Tobias' Leash",                                kind = "pet",   mindSeeker = true, speciesID = 4263, itemID = 208151,  wowheadURL = "https://www.wowhead.com/news/secrets-of-azeroth-event-tenth-community-satchel-found-event-spoilers-334983" },
	{ name = "Uuna (from Uuna's Doll)",                      kind = "pet",   mindSeeker = true, speciesID = 2136, itemID = 153195,  wowheadURL = "https://www.wowhead.com/guide/uunas-storyline-a-dark-place-5508" },
	{ name = "Wicker Pup (Spooky Bundle of Sticks)",         kind = "pet",   mindSeeker = true, speciesID = 2411, itemID = 163497,  wowheadURL = "https://www.wowhead.com/item=163497/spooky-bundle-of-sticks#comments" },
	{ name = "Sun Darter Hatchling",                         kind = "pet",   speciesID = 382, itemID = 142223,                      wowheadURL = "https://www.wowhead.com/guide/sun-darter-hatchling-secret-pet" },
	{ name = "Terky",                                        kind = "pet",   speciesID = 1073, itemID = 22780,                        wowheadURL = "https://www.wowhead.com/object=244447/white-murloc-egg" },
	{ name = "Hungering Claw (Kosumoth)",                    kind = "pet",   speciesID = 1932, itemID = 140261,  linkedSecret = true,  wowheadURL = "https://www.wowhead.com/guide/kosumoth-the-hungering-secret-mount-pet" },
	{ name = "Gortham",                                      kind = "pet",   speciesID = 4967, itemID = 262774,  linkedSecret = true,  wowheadURL = "https://www.wowhead.com/npc=256567/gortham" },

	-- ------------------------------------------------
	-- TOYS
	-- ------------------------------------------------
	{ name = "Black Dragon's Challenge Dummy",               kind = "toy",   mindSeeker = true, itemID = 201933,                   wowheadURL = "https://www.wowhead.com/item=201933/black-dragons-challenge-dummy#comments" },
	{ name = "Enlightened Hearthstone",                      kind = "toy",   mindSeeker = true, itemID = 190196,  source = "Ponderer's Portal", desc = "Teleports you to your heartstone location", wowheadURL = "https://www.wowhead.com/news/enlightened-hearthstone-hidden-hearthstone-toy-found-in-zereth-mortis-337545" },
	{ name = "Cartel Transmorpher",                          kind = "toy",   mindSeeker = true, itemID = 249713, linkedSecret = true,  wowheadURL = "https://www.wowhead.com/news/xy-trustees-gearglider-mount-and-cartel-transmorpher-toy-discovered-by-wow-379066" },
	{ name = "Tricked-Out-Thinking Cap" ,                 	 kind = "toy",    itemID = 206696,  wowheadURL = "https://www.wowhead.com/guide/world-events/secrets-of-azeroth" },
	{ name = "Torch of Pyrreth" ,                             kind = "toy",   itemID = 208092,  wowheadURL = "https://www.wowhead.com/guide/world-events/secrets-of-azeroth" },
	{ name = "Idol of Ohn'ahra" ,                             kind = "toy",   itemID = 207730,  wowheadURL = "https://www.wowhead.com/guide/world-events/secrets-of-azeroth" },

	-- ------------------------------------------------
	-- ACHIEVEMENTS
	-- ------------------------------------------------
	{ name = "Leaders of Scholomance (Necromantic Knowledge)", kind = "achievement", mindSeeker = true, achievementID = 18558,     wowheadURL = "https://www.wowhead.com/news/how-to-enter-old-scholomance-farm-once-removed-transmog-items-333981" },
	{ name = "Mind-Seeker",                                  kind = "achievement", mindSeeker = true, achievementID = 62189,       wowheadURL = "https://www.wowhead.com/news/join-the-secret-cabal-of-mind-seekers-new-secret-discovery-in-progress-380212" },
	{ name = "You Conduit!",                                 kind = "achievement", mindSeeker = true, achievementID = 61585,       wowheadURL = "https://www.wowhead.com/achievement=61585/you-conduit#comments:id=6300813" },
  { name = "Whodunnit?", 																 kind = "achievement", achievementID = 18646,       wowheadURL = "https://www.wowhead.com/guide/world-events/secrets-of-azeroth" },
	-- ------------------------------------------------
	-- TRANSMOG
	-- ------------------------------------------------
	{ name = "Waist of Time",                                kind = "transmog", mindSeeker = true, itemID = 162690,                wowheadURL = "https://www.wowhead.com/guide/waist-of-time-secret-belt-transmog" },

	-- ------------------------------------------------
	-- QUESTS
	-- ------------------------------------------------
	{ name = "Wan'be's Buried Goods",                        kind = "quest",  mindSeeker = true, questID = 52192,  icon = 133644,   wowheadURL = "https://www.wowhead.com/object=296454/wanbes-buried-goods#comments:id=6275341" },

	-- ------------------------------------------------
	-- HOUSING
	-- ------------------------------------------------
	{ name = "Shu'halo Perspective Painting",            kind = "housing", itemID = 246857,                  wowheadURL = "https://www.wowhead.com/news/how-to-buy-the-shuhalo-perspective-painting-for-less-than-gold-cap-380630" },

}
