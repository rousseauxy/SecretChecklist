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
	{ name = "Blanchy's Reins", kind = "mount", mindSeeker = true, itemID = 182614, wowheadURL = "https://www.wowhead.com/news/sinrunner-blanchy-mount-obtained-special-mounting-animation-317673",
	  steps = {
		{ label = "Day 1 – Handful of Oats (×8)",          questID = 62038, itemID = 182581, count = 8, note = "Westfall @ 56.50, 36.68 – scattered around Saldean's Farm (requires level 55)", waypoint = { mapID = 52, x = 0.5650, y = 0.3668 } },
		{ label = "Day 2 – Grooming Brush",                questID = 62042, itemID = 182585, count = 1, note = "Revendreth @ 63.26, 61.63 – talk to Snickersnee",                                                                                                              waypoint = { mapID = 1525, x = 0.6326, y = 0.6163 } },
		{ label = "Day 3 – Sturdy Horseshoe (×4)",         questID = 62047, itemID = 182595, count = 4, note = "Revendreth Southeast – scattered on roads" },
		{ label = "Day 4 – Bucket of Clean Water",         questID = 62049, itemID = 182620, count = 1, note = "Pick up Empty Water Bucket in Revendreth @ 63.26, 61.63, then fill it in Ardenweald or Bastion",                                                                   waypoint = { mapID = 1525, x = 0.6326, y = 0.6163 } },
		{ label = "Day 5 – Comfortable Saddle Blanket",    questID = 62048, itemID = 182597, count = 1, note = "Revendreth @ 51.10, 78.82 – bought from Ta'tru (weekly rotation: 30× Creeping Crawler Meat / Aethereal Meat / Phantasmal Haunch / Shadowy Shank, or 10× Marrowroot)", waypoint = { mapID = 1525, x = 0.5110, y = 0.7882 } },
		{ label = "Day 6 – Dredhollow Apple (×3)",         questID = 62050, itemID = 179271, count = 3, note = "Revendreth @ 40.86, 46.74 – bought from Mims",                                                                                                                    waypoint = { mapID = 1525, x = 0.4086, y = 0.4674 } },
	  },
	},
	{ name = "Bound Shadehound",                             kind = "mount", mindSeeker = true, itemID = 184168, camScale = 1.5, wowheadURL = "https://www.wowhead.com/news/bound-shadehound-mount-craftable-maw-mount-in-patch-9-0-5-320988" },
	{ name = "Crimson Tidestallion",                         kind = "mount", mindSeeker = true, itemID = 169202, wowheadURL = "https://www.wowhead.com/item=169202/crimson-tidestallion#comments:id=3130821" },
	{ name = "Fathom Dweller (Kosumoth)",                    kind = "mount", mindSeeker = true, mountID = 838, wowheadURL = "https://www.wowhead.com/guide/kosumoth-the-hungering-secret-mount-pet",
	  steps = {
	    { label = "1. Talk to Drak'thul",          questID = 43715, note = "Broken Shore @ 37.00, 71.00 – talk until he tells you to go away",              waypoint = { mapID = 646, x = 0.3700, y = 0.7100 } },
	    { label = "2. Weathered Relic from cave",  questID = 43725, note = "Broken Shore @ 58.54, 54.05 – loot it from the cave",                            waypoint = { mapID = 646, x = 0.5854, y = 0.5405 } },
	    { label = "3. Return to Drak'thul",        questID = 43728, note = "Broken Shore @ 37.00, 71.00 – show the relic, talk until he sends you away",     waypoint = { mapID = 646, x = 0.3700, y = 0.7100 } },
	    { label = "4. Orb 1 – Azsuna",             questID = 43730, note = "Azsuna @ 37.96, 37.41",                                                          waypoint = { mapID = 630, x = 0.3796, y = 0.3741 } },
	    { label = "5. Orb 2 – Stormheim",          questID = 43731, note = "Stormheim @ 32.92, 75.90",                                                       waypoint = { mapID = 634, x = 0.3292, y = 0.7590 } },
	    { label = "6. Orb 3 – Val'sharah",         questID = 43732, note = "Val'sharah @ 41.51, 81.18",                                                      waypoint = { mapID = 641, x = 0.4151, y = 0.8118 } },
	    { label = "7. Orb 4 – Broken Shore",       questID = 43733, note = "Broken Shore @ 29.16, 78.57",                                                    waypoint = { mapID = 646, x = 0.2916, y = 0.7857 } },
	    { label = "8. Orb 5 – Azsuna",             questID = 43734, note = "Azsuna @ 59.37, 13.13",                                                          waypoint = { mapID = 630, x = 0.5937, y = 0.1313 } },
	    { label = "9. Orb 6 – Stormheim",          questID = 43735, note = "Stormheim @ 76.00, 3.00 – swim north, underwater cave near a shark",             waypoint = { mapID = 634, x = 0.7600, y = 0.0300 } },
	    { label = "10. Orb 7 – Highmountain",      questID = 43736, note = "Highmountain @ 55.84, 38.47",                                                    waypoint = { mapID = 650, x = 0.5584, y = 0.3847 } },
	    { label = "11. Orb 8 – Azsuna",            questID = 43737, note = "Azsuna @ 54.02, 26.18",                                                          waypoint = { mapID = 630, x = 0.5402, y = 0.2618 } },
	    { label = "12. Orb 9 – Eye of Azshara",    questID = 43760, note = "Eye of Azshara @ 79.52, 89.31",                                                  waypoint = { mapID = 790, x = 0.7952, y = 0.8931 } },
	    { label = "13. Orb 10 – Broken Shore",     questID = 43761, note = "Broken Shore @ 37.05, 71.05",                                                    waypoint = { mapID = 646, x = 0.3705, y = 0.7105 } },
	    { label = "14. Activate Kosumoth",         questID = 45479, note = "Eye of Azshara @ 46.00, 52.00 – reward cycles between Fathom Dweller and Hungering Claw biweekly", waypoint = { mapID = 790, x = 0.4600, y = 0.5200 } },
	  },
	},
	{ name = "Felreaver Deathcycle (Voidfire Deathcycle)",   kind = "mount", mindSeeker = true, itemID = 211089, wowheadURL = "https://www.wowhead.com/news/voidfire-deathcycle-earned-from-horrific-visions-in-patch-11-1-5-375774" },
	{ name = "Keys to Incognitro, the Indecipherable Felcycle", kind = "mount", mindSeeker = true, itemID = 229348, wowheadURL = "https://www.wowhead.com/guide/secrets/ratts-revenge-incognitro-felcycle-guide",
	  steps = {
	    { label = "Orb 1 – Love",           questID = 84676, note = "Earn 3× The Light of Their Love buff – visit Humble Monument (N. Barrens @ 55.0, 40.2) and Olgra (Nagrand or Maldraxxus) with Torch of Pyrreth active",                                                                 waypoint = { mapID = 10,   x = 0.5500, y = 0.4020 } },
	    { label = "Orb 2 – Pray",           questID = 84677, note = "BFA Vale of Eternal Blossoms @ 83.69, 27.58 – Ny'alotha Obelisk; summon Perky Pug with Dogg/Yipp-Saron Costume, activate N'Zoth eye buff, then /pray targeting the Obelisk",                                           waypoint = { mapID = 1530, x = 0.8369, y = 0.2758 } },
	    { label = "Orb 3 – Hate",           questID = 84780, note = "Karazhan Catacombs @ 51.19, 78.27 – fish Astral Key from Astral Soup bowl, get Starry-Eyed Goggles from Astral Chest, then enter 9 console codes to collect all 9 Pieces of Hate (questID TBD – tracked via Orb 4 proxy)", waypoint = { mapID = 46,   x = 0.5119, y = 0.7827 } },
	    { label = "Orb 4 – Doom",           questID = 84780, note = "Western Plaguelands @ 52.06, 83.19 – Uther's Tomb; summon a Doomguard via Scroll of Fel Binding or Warlock Ritual of Doom, click Hidden Graffiti on the floor while the Doomguard is alive",                           waypoint = { mapID = 22,   x = 0.5206, y = 0.8319 } },
	    { label = "Orb 5 – Muffin",         questID = 84781, note = "Timeless Isle @ 43.07, 41.29 – Cave of Lost Spirits; enter via Zarhym, defeat Jeremy Feasel using only secret battle pets; then trade 9× Pieces of Hate + Golden Muffin at Pointless Treasure Salesman in Booty Bay", waypoint = { mapID = 554,  x = 0.4307, y = 0.4129 } },
	    { label = "Orb 6 – Altars",         questID = 84811, note = "N. Stranglethorn (uninstanced Zul'gurub) @ 77.08, 46.31 – use Torch of Pyrreth at 5 Altars of Acquisition, appease each NPC with matching mount/pet/toy; use Starry-Eyed Goggles to find and loot Chest of Acquisitions", waypoint = { mapID = 50,   x = 0.7708, y = 0.4631 } },
	    { label = "Orb 7 – Watchers",       questID = 84823, note = "Azsuna, Isle of Watchers @ 44.18, 72.41 – collect 4 colored owl buffs from Owl of the Watchers statues with Fledgling Warden Owl summoned; clear Vault of the Wardens through Cordana, solve sentry statue puzzle, loot Warden's Mirror", waypoint = { mapID = 630,  x = 0.4418, y = 0.7241 } },
	    { label = "Orb 8 – Rats",           questID = 84837, note = "Karazhan Catacombs @ 59.87, 42.62 – deposit Warden's Mirror + Ancient Shaman Blood into the Enigma Machine, count Rats, position statues on pressure plates 3 times",                                                  waypoint = { mapID = 46,   x = 0.5987, y = 0.4262 } },
	    { label = "Orb 9 – Cipher",                           note = "Azj-Kahet, Pillar-nest Vosh @ 55.03, 19.09 – use Starry-Eyed Goggles + Relic of Crystal Connections to teleport to hidden console, enter code 84847078 → loot Felcycle keys (awards Ratts' Revenge FoS)",              waypoint = { mapID = 2255, x = 0.5503, y = 0.1909 } },
	    { label = "Orb 10 – Oddsight Focus", itemID = 260533, count = 1, note = "Waking Shores @ 19.4, 36.3 – loot Bubblefilled Flounder while dead → feed Hek the Hungry Hornswog → place egg at Valdrakken duck nest @ 39.8, 78.7 → find To'no (Forbidden Reach) for 2nd dialogue; requires Mind-Seeker", waypoint = { mapID = 2022, x = 0.1940, y = 0.3630 } },
	    { label = "Orb 11 – ???",                             note = "??? – still being investigated by the Secret Finding Discord" },
	    { label = "Orb 12 – ???",                             note = "??? – still being investigated by the Secret Finding Discord" },
	  },
	},
	{ name = "Long-Forgotten Hippogryph",                    kind = "mount", mindSeeker = true, itemID = 138258, wowheadURL = "https://www.wowhead.com/guide/reins-of-the-long-forgotten-hippogryph-mount" },
	{ name = "Lucid Nightmare",                              kind = "mount", mindSeeker = true, itemID = 151623, wowheadURL = "https://www.wowhead.com/guide/lucid-nightmare-secret-mount" },
	{ name = "Mimiron's Jumpjets",                           kind = "mount", mindSeeker = true, itemID = 210022, wowheadURL = "https://www.wowhead.com/news/secrets-of-azeroth-community-clue-4-solution-mimirons-jumpjets-mount-now-334998" },
	{ name = "Nazjatar Blood Serpent",                       kind = "mount", mindSeeker = true, itemID = 161479, wowheadURL = "https://www.wowhead.com/item=161479/nazjatar-blood-serpent" },
	{ name = "Nilganihmaht Control Ring",                    kind = "mount", mindSeeker = true, itemID = 186713,  camScale = 3, wowheadURL = "https://www.wowhead.com/news/hand-of-nilganihmaht-secret-mount-in-chains-of-domination-322780" },
	{ name = "Otto",                                         kind = "mount", mindSeeker = true, itemID = 198870, wowheadURL = "https://www.wowhead.com/news/otto-mount-found-fish-around-the-dragon-isles-for-otter-mount-330658" },
	{ name = "Riddler's Mind-Worm",                          kind = "mount", mindSeeker = true, itemID = 147835, wowheadURL = "https://www.wowhead.com/guide/riddlers-mind-worm-secret-mount" },
	{ name = "Slime Serpent",                                kind = "mount", mindSeeker = true, mountID = 1445, wowheadURL = "https://www.wowhead.com/guide/shadowlands-mount-guide-10510#:~:text=The%20Necrotic%20Wake-,Slime%20Serpent,-Description%3A%20This" },
	{ name = "The Hivemind",                                 kind = "mount", mindSeeker = true, itemID = 156798, wowheadURL = "https://www.wowhead.com/guide/the-hivemind" },
	{ name = "Thrayir, Eyes of the Siren",                   kind = "mount", mindSeeker = true, itemID = 232639, wowheadURL = "https://www.wowhead.com/news/how-to-obtain-thrayir-eyes-of-the-siren-in-patch-11-0-7-stormcrow-mount-354470" },
	{ name = "Xy Trustee's Gearglider",                      kind = "mount", mindSeeker = true, itemID = 186639, wowheadURL = "https://www.wowhead.com/news/xy-trustees-gearglider-mount-and-cartel-transmorpher-toy-discovered-by-wow-379066" },
	{ name = "Pattie's Cap",                                 kind = "mount", itemID = 208152, wowheadURL = "https://www.wowhead.com/item=208152/patties-cap#guides" },

	-- ------------------------------------------------
	-- PETS
	-- ------------------------------------------------
	{ name = "Baa'ls Darksign",                              kind = "pet",   mindSeeker = true, speciesID = 2352, itemID = 162578,  wowheadURL = "https://www.wowhead.com/guide/baal-secret-demonic-goat-battle-pet" },
	{ name = "Courage",                                      kind = "pet",   mindSeeker = true, speciesID = 3065, itemID = 184400,  wowheadURL = "https://www.wowhead.com/news/secret-battle-pet-courage-found-321354" },
	{ name = "Glimr's Cracked Egg",                          kind = "pet",   mindSeeker = true, speciesID = 2888, itemID = 180034,  wowheadURL = "https://www.wowhead.com/news/secret-purple-murloc-battle-pet-find-glimr-and-the-glimmerfin-tribe-in-grizzly-318904" },
	{ name = "Jenafur",                                      kind = "pet",   mindSeeker = true, speciesID = 2795, wowheadURL = "https://www.wowhead.com/guide/jenafur-secret-cat-battle-pet" },
	{ name = "Phoenix Wishwing",                             kind = "pet",   mindSeeker = true, speciesID = 3292, itemID = 193373,  wowheadURL = "https://www.wowhead.com/news/new-secret-discovered-phoenix-wishwing-battle-pet-332187#news-post-332187" },
	{ name = "Tobias' Leash",                                kind = "pet",   mindSeeker = true, speciesID = 4263, itemID = 208151,  wowheadURL = "https://www.wowhead.com/news/secrets-of-azeroth-event-tenth-community-satchel-found-event-spoilers-334983" },
	{ name = "Uuna (from Uuna's Doll)",                      kind = "pet",   mindSeeker = true, speciesID = 2136, itemID = 153195,  wowheadURL = "https://www.wowhead.com/guide/uunas-storyline-a-dark-place-5508" },
	{ name = "Wicker Pup (Spooky Bundle of Sticks)",         kind = "pet",   mindSeeker = true, speciesID = 2411, itemID = 163497,  wowheadURL = "https://www.wowhead.com/item=163497/spooky-bundle-of-sticks#comments" },
	{ name = "Sun Darter Hatchling",                         kind = "pet",   speciesID = 382, itemID = 142223, wowheadURL = "https://www.wowhead.com/guide/sun-darter-hatchling-secret-pet" },
	{ name = "Terky",                                        kind = "pet",   speciesID = 1073, itemID = 22780, wowheadURL = "https://www.wowhead.com/object=244447/white-murloc-egg" },
	{ name = "Hungering Claw (Kosumoth)",                    kind = "pet",   speciesID = 1926, itemID = 140261, linkedSecret = true,  stepsRef = "Fathom Dweller (Kosumoth)",  wowheadURL = "https://www.wowhead.com/guide/kosumoth-the-hungering-secret-mount-pet" },
	{ name = "Gortham",                                      kind = "pet",   speciesID = 4967, itemID = 262774,  wowheadURL = "https://www.wowhead.com/npc=256567/gortham" },

	-- ------------------------------------------------
	-- TOYS
	-- ------------------------------------------------
	{ name = "Black Dragon's Challenge Dummy",               kind = "toy",   mindSeeker = true, itemID = 201933, wowheadURL = "https://www.wowhead.com/item=201933/black-dragons-challenge-dummy#comments" },
	{ name = "Enlightened Hearthstone",                      kind = "toy",   mindSeeker = true, itemID = 190196, wowheadURL = "https://www.wowhead.com/news/enlightened-hearthstone-hidden-hearthstone-toy-found-in-zereth-mortis-337545" },
	{ name = "Cartel Transmorpher",                          kind = "toy",   mindSeeker = true, itemID = 249713,  wowheadURL = "https://www.wowhead.com/news/xy-trustees-gearglider-mount-and-cartel-transmorpher-toy-discovered-by-wow-379066" },
	{ name = "Tricked-Out-Thinking Cap" ,                 	 kind = "toy",    itemID = 206696,  wowheadURL = "https://www.wowhead.com/guide/world-events/secrets-of-azeroth" },
	{ name = "Torch of Pyrreth" ,                             kind = "toy",   itemID = 208092,  wowheadURL = "https://www.wowhead.com/guide/world-events/secrets-of-azeroth" },
	{ name = "Idol of Ohn'ahra" ,                             kind = "toy",   itemID = 207730,  wowheadURL = "https://www.wowhead.com/guide/world-events/secrets-of-azeroth" },
	{ name = "Starry-Eyed Goggles",                          kind = "toy",   itemID = 228966, wowheadURL = "https://www.wowhead.com/item=228966/starry-eyed-goggles" },

	-- ------------------------------------------------
	-- ACHIEVEMENTS
	-- ------------------------------------------------
	{ name = "Leaders of Scholomance (Necromantic Knowledge)", kind = "achievement", mindSeeker = true, achievementID = 18558, wowheadURL = "https://www.wowhead.com/news/how-to-enter-old-scholomance-farm-once-removed-transmog-items-333981" },
	{ name = "Mind-Seeker",                                  kind = "achievement", mindSeeker = true, achievementID = 62189, wowheadURL = "https://www.wowhead.com/news/join-the-secret-cabal-of-mind-seekers-new-secret-discovery-in-progress-380212" },
	{ name = "You Conduit!",                                 kind = "achievement", mindSeeker = true, achievementID = 61585, wowheadURL = "https://www.wowhead.com/achievement=61585/you-conduit#comments:id=6300813" },
  { name = "Whodunnit?",                                  kind = "achievement", achievementID = 18646, wowheadURL = "https://www.wowhead.com/guide/world-events/secrets-of-azeroth" },
	{ name = "Azeroth's Greatest Detective",                 kind = "achievement", achievementID = 40870,  wowheadURL = "https://www.wowhead.com/achievement=40870/azeroths-greatest-detective" },
	-- ------------------------------------------------
	
	-- ------------------------------------------------
	-- TRANSMOG
	-- ------------------------------------------------
	{ name = "Waist of Time",                                kind = "transmog", mindSeeker = true, itemID = 162690, wowheadURL = "https://www.wowhead.com/guide/waist-of-time-secret-belt-transmog" },

	-- ------------------------------------------------
	-- QUESTS
	-- ------------------------------------------------
	{ name = "Wan'be's Buried Goods",                        kind = "quest",  mindSeeker = true, questID = 52192,  icon = 133644, wowheadURL = "https://www.wowhead.com/object=296454/wanbes-buried-goods#comments:id=6275341" },

	-- ------------------------------------------------
	-- MYSTERIES
	-- ------------------------------------------------
	{ name = "12 Orb Mystery",                    kind = "mystery", wowheadURL = "https://www.wowhead.com/guide/secrets/ratts-revenge-incognitro-felcycle-guide",
	  steps = {
	    { label = "Orb 1 – Love",           questID = 84676, note = "N. Barrens, Humble Monument @ 55.0, 40.2",               waypoint = { mapID = 10,   x = 0.5500, y = 0.4020 } },
	    { label = "Orb 2 – Pray",           questID = 84677, note = "BFA Vale of Eternal Blossoms @ 83.69, 27.58",             waypoint = { mapID = 1530, x = 0.8369, y = 0.2758 } },
	    { label = "Orb 3 – Hate",           questID = 84780, note = "Karazhan Catacombs @ 51.19, 78.27 (questID TBD – tracked via Orb 4 proxy)",    waypoint = { mapID = 46,   x = 0.5119, y = 0.7827 } },
	    { label = "Orb 4 – Doom",           questID = 84780, note = "Western Plaguelands, Uther's Tomb @ 52.06, 83.19",        waypoint = { mapID = 22,   x = 0.5206, y = 0.8319 } },
	    { label = "Orb 5 – Muffin",         questID = 84781, note = "Timeless Isle, Cave of Lost Spirits @ 43.07, 41.29",     waypoint = { mapID = 554,  x = 0.4307, y = 0.4129 } },
	    { label = "Orb 6 – Altars",         questID = 84811, note = "N. Stranglethorn, uninstanced Zul'gurub @ 77.08, 46.31", waypoint = { mapID = 50,   x = 0.7708, y = 0.4631 } },
	    { label = "Orb 7 – Watchers",       questID = 84823, note = "Azsuna, Isle of Watchers @ 44.18, 72.41",                waypoint = { mapID = 630,  x = 0.4418, y = 0.7241 } },
	    { label = "Orb 8 – Rats",           questID = 84837, note = "Karazhan Catacombs @ 59.87, 42.62",                      waypoint = { mapID = 46,   x = 0.5987, y = 0.4262 } },
	    { label = "Orb 9 – Cipher",                           note = "Azj-Kahet, Pillar-nest Vosh @ 55.03, 19.09",              waypoint = { mapID = 2255, x = 0.5503, y = 0.1909 } },
	    { label = "Orb 10 – Oddsight Focus", itemID = 260533, count = 1, note = "Waking Shores @ 19.4, 36.3 (start: Bubblefilled Flounder, looted while dead)", waypoint = { mapID = 2022, x = 0.1940, y = 0.3630 } },
	    { label = "Orb 11 – ???",                             note = "??? – still being investigated" },
	    { label = "Orb 12 – ???",                             note = "??? – still being investigated" },
	  },
	},

	-- ------------------------------------------------
	-- HOUSING
	-- ------------------------------------------------
	{ name = "Shu'halo Perspective Painting",            kind = "housing", itemID = 246857, wowheadURL = "https://www.wowhead.com/news/how-to-buy-the-shuhalo-perspective-painting-for-less-than-gold-cap-380630" },

}
