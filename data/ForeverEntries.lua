-- SecretChecklist Data File -- WoW: Forever
-- Loaded instead of data/SecretEntries.lua by SecretChecklist_Camelot.toc.
--
-- Forever has its own item, quest and map ids. The ids below come from
-- Wowhead's Forever database (wowhead.com/forever); the steps and coordinates
-- from the pinned posts of the community's forever-secrets channel and the
-- Wowhead guides linked on each entry. Map ids are the "/way #NNNN" numbers
-- those posts use. Run /secrets validate in the Forever client after editing:
-- it reports any map that refuses a waypoint.
--
-- Two of these are unsolved, so they use kind "mystery": the entry only shows
-- as collected once every step is done, and a step that the community has not
-- worked out yet is written as a note with no id.

local SC = _G.SecretChecklist
if not SC then return end

SC.entries = {
	-- ------------------------------------------------
	-- TOYS
	-- ------------------------------------------------
	{ name = "Alcaz Operative Insignia", kind = "toy", itemID = 279471,
	  source = "Alcaz Prison, then a hidden treasure in Westfall and a faction contact.",
	  guideURL = "https://www.wowhead.com/forever/guide/alcaz-operative-disguise-toy-secret-walkthrough",
	  steps = {
		{ label = "Alcaz Prison — skip The Questioner, free Mason Connery", note = "Do NOT kill the first boss, The Questioner, on the way in. At the end of the dungeon the prisoner Mason Connery asks you to kill The Questioner and bring back his key. Kill him, return the key to Mason." },
		{ label = "More Valuable Than Gold — Moonbrook inn, Westfall", questID = 96337, note = "Mason gives this quest and a note reading 'WF, 43.4, 67.8'. It leads to the second floor of the Moonbrook inn: interact with the floorboards by the box, then turn the quest in for a Document Box. It vendors for 25g — do NOT sell it.", waypoint = { mapID = 1436, x = 0.434, y = 0.678 } },
		{ label = "State Secrets — hand in the Document Box", itemID = 274041, questIDs = { 96376, 96377, 96379 }, note = "Horde: Rix Xizzix in Booty Bay, near the auction house. Alliance: Renzik \"The Shiv\" in the SI:7 building, Old Town, Stormwind. Rewards a Fractured Insignia, gold and experience." },
		{ label = "Collect 6 Fractured Insignia and combine them", itemID = 279450, count = 6, note = "The Fractured Insignia is tradeable: buy the other five or trade with friends. Combining all six teaches the Alcaz Operative Insignia toy (a Defias disguise)." },
	  },
	},

	-- ------------------------------------------------
	-- QUESTS
	-- ------------------------------------------------
	-- The Cozy Sleeping Bag is an ordinary item here, not a toy, so the entry
	-- completes on the chain's last quest. itemID makes it show under the
	-- item's name rather than that quest's title.
	{ name = "Cozy Sleeping Bag", kind = "quest", questID = 79976, itemID = 211527,
	  source = "Quest chain across Azeroth from level 14; also rewards 5 Student Fodder along the way.",
	  guideURL = "https://www.wowhead.com/forever/guide/cozy-sleeping-bag-locations-rewards",
	  steps = {
		{ label = "Burned-Out Remains — start the chain", questIDs = { 79008, 79007 }, note = "Requires level 14. Alliance and Horde visit the same two sites in the opposite order.",
		  factionSubsteps = {
			alliance = {
				{ label = "Westfall, Alexston Farmstead — click the Burned-Out Remains by the wrecked cart and accept the quest", questIDs = { 79008, 79007 }, waypoint = { mapID = 1436, x = 0.370, y = 0.500 } },
				{ label = "The Barrens, burnt tower south of Camp Taurajo — click the remains, turn in and take Stepping Stones from the board", questIDs = { 79008, 79007 }, waypoint = { mapID = 1413, x = 0.460, y = 0.740 } },
			},
			horde = {
				{ label = "The Barrens, burnt tower south of Camp Taurajo — click the Burned-Out Remains and accept the quest", questIDs = { 79008, 79007 }, waypoint = { mapID = 1413, x = 0.460, y = 0.740 } },
				{ label = "Westfall, Alexston Farmstead — click the remains by the wrecked cart, turn in and take Stepping Stones", questIDs = { 79008, 79007 }, waypoint = { mapID = 1436, x = 0.370, y = 0.500 } },
			},
		  },
		},
		{ label = "Stepping Stones — abandoned camp, Stonetalon Mountains", questID = 79192, note = "Take the path northeast of Sun Rock Retreat @ 50.9, 52.3 up to the camp and click the Pocket Litter on top of a box.", waypoint = { mapID = 1442, x = 0.406, y = 0.524 } },
		{ label = "Optional: Rekindle — the camp's fire pit", questID = 80001, note = "Light the fire pit in the middle of the camp with the Simple Wood and Flint and Tinder from the previous quest. Not needed for the bag." },
		{ label = "Scramble — Mound of Dirt", questID = 79980, note = "From the camp, climb the hill straight north and jump across to the Mound of Dirt.", waypoint = { mapID = 1442, x = 0.396, y = 0.498 } },
		{ label = "Wet Job — Eagle Figurine, Loch Modan dam", questID = 79974, note = "Jump onto the carved heads facing the Wetlands to reach the figurine. Tricky to reach safely as Horde.", waypoint = { mapID = 1432, x = 0.494, y = 0.129 } },
		{ label = "Eagle's Fist — Messenger Bag, Thoradin's Wall", questID = 79975, note = "Use the cart on the Hillsbrad side to climb into the wall, go through the room and look outside to the right for the hanging bag.", waypoint = { mapID = 1424, x = 0.873, y = 0.496 } },
		{ label = "This Must Be The Place — Hastily Rolled-Up Satchel", questID = 79976, itemID = 211527, note = "Click the satchel below the Messenger Bag to finish the chain and receive the Cozy Sleeping Bag." },
	  },
	},

	-- ------------------------------------------------
	-- MYSTERIES (unsolved)
	-- ------------------------------------------------
	{ name = "Dawn Waker", kind = "mystery",
	  source = "Unsolved. The rewards look like the blades Eluvi'ana and Eluvi'tor.",
	  guideURL = "https://www.wowhead.com/forever/guide/dawn-waker-secret-walkthrough",
	  steps = {
		{ label = "Coming of Age — Ancient Heirloom ring", questID = 92460, itemID = 264908, note = "Zephras Isle, Thendal Village: Ailee Farheart gives the quest; turn it in to Rorian the Dayseeker nearby for the ring. A second ring is on the top floor @ 41.7, 23.4. Wear it: several later steps only appear with the ring equipped.", waypoint = { mapID = 2521, x = 0.4283, y = 0.2345 } },
		{ label = "Get the Night Watchman's Torch", itemID = 280612, note = "Needed to reveal the Ancient Hilt (and several scavenger-hunt objects)." },
		{ label = "The Ancient Hilt — Ruins of Ban'aethal", questID = 93161, note = "Use the Night Watchman's Torch at the Ruins of Ban'aethal on Zephras Isle to uncover the Ancient Hilt, then take it to Ealaane Nimbuswalker @ 65.94, 74.37.", waypoint = { mapID = 2521, x = 0.5813, y = 0.2406 } },
		{ label = "Eluvi'ana — find the Ancient Skyborne Blade", questID = 97029, itemID = 276188, note = "The blade (item 264501) is somewhere on Zephras Isle; four spawn points are known. Bring it to Ealaane Nimbuswalker for Eluvi'ana.",
		  waypoints = {
			{ mapID = 2521, x = 0.4894, y = 0.7268, label = "Skyborne Blade 1" },
			{ mapID = 2521, x = 0.5040, y = 0.4430, label = "Skyborne Blade 2" },
			{ mapID = 2521, x = 0.6625, y = 0.4315, label = "Skyborne Blade 3" },
			{ mapID = 2521, x = 0.5990, y = 0.8220, label = "Skyborne Blade 4" },
			{ mapID = 2521, x = 0.6594, y = 0.7437, label = "Ealaane Nimbuswalker" },
		  },
		},
		{ label = "Befouled Water Globe", itemID = 282337, note = "Horde: kill Baron Aquanis in Blackfathom Deeps for the Strange Water Globe, turn it in to Je'neu at Zoram'gar Outpost, then talk to him again to get the globe back. Alliance: combine 20 Mathystra Amulet Fragments from the naga at the Ruins of Mathystra, use the amulet at the water structure @ 58.9, 22.6 in Darkshore, kill Baron Marinous, turn his globe in to Onu at the Grove of the Ancients and talk to him again.",
		  factionWaypoint = { horde = { mapID = 1440, x = 0.116, y = 0.342 }, alliance = { mapID = 1439, x = 0.436, y = 0.764 } } },
		{ label = "Zoram Strand — speak with the Highborne Spirit", note = "With the ring equipped and the globe in your bags, a Highborne Spirit appears and sends you to the Tower of Althalaxx in Darkshore.", waypoint = { mapID = 1440, x = 0.1568, y = 0.1933 } },
		{ label = "Narassin's Tome — Tower of Althalaxx", itemID = 282404, note = "Kill Narassin at the top of the tower for the Azsharan Key, open the strongbox behind him for the tome, then return to the Highborne Spirit.", waypoint = { mapID = 1439, x = 0.564, y = 0.265 } },
		{ label = "Show the Hilt, Eluvi'ana and the Tome to Mordent Evenshade", note = "Shen'dralas. He names the three cleansing items below.", waypoint = { mapID = 2652, x = 0.3505, y = 0.4649 } },
		{ label = "Gather the three cleansing items",
		  substeps = {
			{ label = "Star of Elune — Shen'dralar Vault, Feralas (5 players)", itemID = 282548, note = "Vault in the middle of the ground floor of the ogre temple in southern Feralas; ring buff needed to see it. Four players stand on the switches at 58.5, 71.0 (second floor), 57.3, 71.7, 59.7, 72.0 and 61.1, 73.6 and toggle them together; the fifth opens the vault.", waypoint = { mapID = 1444, x = 0.585, y = 0.716 } },
			{ label = "Abyssal Mote — Abyssal Chest underwater, Azshara", itemID = 282547, note = "Requires the quest chain ending in 'Azsharite' (starts at wowhead.com/forever/quest=2721).", waypoint = { mapID = 1447, x = 0.660, y = 0.541 } },
			{ label = "Tears of Anguish — Lake Kel'theril, Winterspring", itemID = 282431, note = "Drop from Anguished and Suffering Highborne after you have talked to Mordent. Ring not required; not a guaranteed drop.", waypoint = { mapID = 1452, x = 0.536, y = 0.432 } },
		  },
		},
		{ label = "Cleanse the globe at the Shrine of Coalescence, Hyjal", itemID = 282699, note = "Bring the three items and the globe; use the globe from your bags at the shrine for the Cleansed Water Globe. Show it to Mordent, who sends you to Prince Tortheldrin in Dire Maul.", waypoint = { mapID = 2482, x = 0.727, y = 0.372 } },
		{ label = "Reach Honored with the Shen'dralar", repReq = { factionID = 809, standingID = 6, standingName = "Honored" }, note = "Prince Tortheldrin only speaks of Eluvi'ana and Eluvi'tor to those Honored with his court." },
		{ label = "Craft the Arcanum of Binding", itemID = 282707, note = "From the Libram of Binding (drops in Dire Maul): 1 Pristine Black Diamond, 2 Large Brilliant Shard, 1 Arcane Crystal." },
		{ label = "Use the Arcanum on the Ancient Hilt — Scrawled Note", itemID = 283387, note = "Speak with Prince Tortheldrin again for the Scrawled Note: \"As night dances on, so must day wake / To rejoin one, its pair must await / So only pure of heart may wield / Blade high or perfect dark must yield // In flames born of air it must be cast / Only then will the spirit bind at last\"" },
		{ label = "UNSOLVED — the hilt and Altairus's breath", note = "Current step. Placing the Ancient Hilt in front of Altairus and having him breathe on it makes him fly away. Clicking the placed hilt with the Night Dancer in your bags channels for 10 seconds, raising the blade high. Nothing happens afterwards yet." },
	  },
	},

	{ name = "Manual Scavenger Hunt", kind = "mystery",
	  source = "Unsolved. Hidden objects that seem based on the old printed game manuals; the end goal is unknown.",
	  guideURL = "https://www.wowhead.com/forever/item=280612/night-watchmans-torch",
	  steps = {
		{ label = "Night Watchman's Torch (tool)", itemID = 280612, note = "Found in Duskwood. Must be out and lit to see several of the stashes below." },
		{ label = "Keystone Fragment — Torn Pages, Undercity sewers", itemIDs = { 281350, 284092, 284093 }, note = "Back entrance of the Undercity sewers, barrel with a Torn Page and a knife. Page reads: 'The furrowed gaze of the orcish warrior lays upon the map, and reveals the key. Page 155'. Reported missing or moved on 06/11.", waypoint = { mapID = 1458, x = 0.2286, y = 0.3619 } },
		{ label = "Stone Key — small pack, Riverglades", itemID = 281358, note = "Behind a sleeping Twilight Peon; jump off at 26.72, 47.74. Formerly in Blackrock Mountain. Reported missing or moved on 06/11.", waypoint = { mapID = 2548, x = 0.2656, y = 0.4558 } },
		{ label = "Burnt Page — Dreadmaul Hold, Blasted Lands", itemID = 281356, note = "Needs the Stone Key. 'Behind three places of mystery is a map. The top of the key is within the first body...' Reported missing or moved on 06/11.", waypoint = { mapID = 1419, x = 0.4519, y = 0.1647 } },
		{ label = "Burnt Page — Thoradin's Wall, Arathi", note = "Barrel next to the Sleeping Bag at Thoradin's Wall; climb starts in Hillsbrad @ 87.61, 47.91. 'Living death on this page you will see... Sewer's trail, a toxic tail.' Visibility unclear since 06/11.", waypoint = { mapID = 1417, x = 0.2269, y = 0.2417 } },
		{ label = "Brittle Key — Hidden Stash, Stonetalon", itemID = 221324, note = "Reported missing or moved on 06/11.", waypoint = { mapID = 1442, x = 0.4071, y = 0.5275 } },
		{ label = "Torn Page — Traveler's Cache, Stranglethorn", itemID = 281347, note = "'The calm comes before the storm.' Since 06/11 a standing torch is there instead of the chest.", waypoint = { mapID = 1434, x = 0.1443, y = 0.2715 } },
		{ label = "Ancient Runestone — Hidden Stash, Alterac Mountains", itemID = 281352, note = "Torch out and lit; near a crashed wooden cart and a shield. Reported missing or moved on 06/11.", waypoint = { mapID = 1416, x = 0.556, y = 0.483 } },
		{ label = "Hidden Stash — Un'Goro, Ringo's cave", note = "Torch out and lit. Cave entrance @ 52.48, 51.10. Contents unknown.", waypoint = { mapID = 1449, x = 0.5216, y = 0.4964 } },
		{ label = "Skeletal Chest — Western Plaguelands (underwater)", note = "Needs a Keystone Fragment nobody has yet. Reported missing or moved on 06/11.", waypoint = { mapID = 1422, x = 0.616, y = 0.728 } },
		{ label = "Other finds — Stormwind note, Redridge orc, Deadmines snake", note = "A new note in Stormwind @ 67.20, 82.53, a dead 'parkour' orc in Redridge and a snake corpse at the Deadmines gate. Purpose unknown.", waypoint = { mapID = 1453, x = 0.6720, y = 0.8253 } },
	  },
	},
}
