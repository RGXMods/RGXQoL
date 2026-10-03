----------------------------------------------------------------------
-- 	RGX QoL 1.0.0 (derived from RGX QoL Plus 1.15.150)
----------------------------------------------------------------------

--	01:Functions 02:Locks   03:Restart 40:Player   45:Rest
--	60:Events    62:Profile 70:Logout  80:Commands 90:Panel

----------------------------------------------------------------------
-- 	RGX QoL
----------------------------------------------------------------------

	-- Create global table
	_G.RGXQoLDB = _G.RGXQoLDB or {}

	-- Create locals
	-- Create locals
	local RGXQoLLC = {}
	RGXQoLLC.FeatureSetup = {}          -- option -> setup hook, wired from feature blocks

	-- WoW Forever beta safety: guarded hook helper for functions this
	-- client may lack. Scopes to RGXQoL only -- does NOT replace the
	-- global hooksecurefunc (that taints every addon's secure hooks).
	local function SafeHookSecure(name, func)
		if type(name) == "string" and _G[name] == nil then
			return
		end
		return hooksecurefunc(name, func)
	end

	-- WoW Forever beta safety: shadow risky WoW API globals with safe
	-- fallbacks so the entire 14k-line file can use the standard names
	-- without nil crashes on the beta client.
	local GetItemInfoFromHyperlink = _G.GetItemInfoFromHyperlink or function(link)
		if type(link) == "string" then return tonumber(link:match("item:(%d+)")) end
	end
	local SetRaidTarget = _G.SetRaidTarget or function() end
	local UninviteUnit = _G.C_PartyInfo and _G.C_PartyInfo.RemoveFromParty or _G.UninviteUnit or function() end
	local AcceptResurrect = _G.AcceptResurrect or function() end
	local DeclineResurrect = _G.DeclineResurrect or function() end
	local TakeTaxiNode = _G.TakeTaxiNode or function() end
	local PickupContainerItem = _G.C_Container and _G.C_Container.PickupContainerItem or _G.PickupContainerItem or function() end
	local GetContainerNumSlots = _G.C_Container and _G.C_Container.GetContainerNumSlots or _G.GetContainerNumSlots or function() return 0 end
	local GetContainerItemInfo = _G.C_Container and _G.C_Container.GetContainerItemInfo or _G.GetContainerItemInfo or function() return nil end
	local GetContainerNumFreeSlots = _G.C_Container and _G.C_Container.GetContainerNumFreeSlots or _G.GetContainerNumFreeSlots or function() return 0 end
	local SelectQuestLogEntry = _G.SelectQuestLogEntry or function() end
	local GetItemQualityColor = _G.GetItemQualityColor or function() return 1, 1, 1, "ffffff", 1 end
	local GetNumTalentTabs = _G.GetNumTalentTabs or function() return 0 end
	local UnitIsGroupLeader = _G.UnitIsGroupLeader or function() return false end
	local UnitInRaid = _G.UnitInRaid or function() return false end
	local UnitInParty = _G.UnitInParty or function() return false end
	local ClientVersion = GetBuildInfo()
	local GameLocale = GetLocale()
	local void

	-- Version
	RGXQoLLC["AddonVer"] = "1.15.150"

	-- Get locale table
	local void, RGXQoLAddon = ...
	local L = RGXQoLAddon.L

	-- Check Wow version is valid
	do
		local gameversion, gamebuild, gamedate, gametocversion = GetBuildInfo()
		if gametocversion and gametocversion > 19999 then
			-- Game client is not Wow Classic
			C_Timer.After(2, function()
				print(L["RGX QO: WRONG VERSION INSTALLED!"])
			end)
			return
		end
		if gametocversion and gametocversion == 11504 then
			-- Used for upcoming game patch
			RGXQoLLC.NewPatch = true
		end
	end

	-- Check for ElvUI
	if C_AddOns.IsAddOnLoaded("ElvUI") then RGXQoLLC.ElvUI = unpack(ElvUI) end

----------------------------------------------------------------------
--	L00: RGX QoL
----------------------------------------------------------------------

	-- Initialise variables
	RGXQoLLC["ShowErrorsFlag"] = 1

	-- Class colors
	do
		local void, playerClass = UnitClass("player")
		if CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[playerClass] then
			RGXQoLLC["RaidColors"] = CUSTOM_CLASS_COLORS
		else
			RGXQoLLC["RaidColors"] = RAID_CLASS_COLORS
		end
	end

	-- Create event frame
	local RGXQoLEvt = CreateFrame("FRAME")
	RGXQoLEvt:RegisterEvent("ADDON_LOADED")
	RGXQoLEvt:RegisterEvent("PLAYER_LOGIN")

	-- Set bindings translations
	_G.BINDING_NAME_RGXQO_GLOBAL_TOGGLE = L["Toggle panel"]
	_G.BINDING_NAME_RGXQO_GLOBAL_RARE = L["Announce rare"]

----------------------------------------------------------------------
--	L01: Functions
----------------------------------------------------------------------

	-- Print text
	function RGXQoLLC:Print(text)
		DEFAULT_CHAT_FRAME:AddMessage(L[text], 1.0, 0.85, 0.0)
	end
	-- Load a string variable or set it to default if it's not set to "On" or "Off"
	function RGXQoLLC:LoadVarChk(var, def)
		if RGXQoLDB[var] and type(RGXQoLDB[var]) == "string" and RGXQoLDB[var] == "On" or RGXQoLDB[var] == "Off" then
			RGXQoLLC[var] = RGXQoLDB[var]
		else
			RGXQoLLC[var] = def
			RGXQoLDB[var] = def
		end
	end

	-- Load a numeric variable and set it to default if it's not within a given range
	function RGXQoLLC:LoadVarNum(var, def, valmin, valmax)
		if RGXQoLDB[var] and type(RGXQoLDB[var]) == "number" and RGXQoLDB[var] >= valmin and RGXQoLDB[var] <= valmax then
			RGXQoLLC[var] = RGXQoLDB[var]
		else
			RGXQoLLC[var] = def
			RGXQoLDB[var] = def
		end
	end

	-- Load an anchor point variable and set it to default if the anchor point is invalid
	function RGXQoLLC:LoadVarAnc(var, def)
		if RGXQoLDB[var] and type(RGXQoLDB[var]) == "string" and RGXQoLDB[var] == "CENTER" or RGXQoLDB[var] == "TOP" or RGXQoLDB[var] == "BOTTOM" or RGXQoLDB[var] == "LEFT" or RGXQoLDB[var] == "RIGHT" or RGXQoLDB[var] == "TOPLEFT" or RGXQoLDB[var] == "TOPRIGHT" or RGXQoLDB[var] == "BOTTOMLEFT" or RGXQoLDB[var] == "BOTTOMRIGHT" then
			RGXQoLLC[var] = RGXQoLDB[var]
		else
			RGXQoLLC[var] = def
			RGXQoLDB[var] = def
		end
	end

	-- Load a string variable and set it to default if it is not a string (used with minimap exclude list)
	function RGXQoLLC:LoadVarStr(var, def)
		if RGXQoLDB[var] and type(RGXQoLDB[var]) == "string" then
			RGXQoLLC[var] = RGXQoLDB[var]
		else
			RGXQoLLC[var] = def
			RGXQoLDB[var] = def
		end
	end
	-- Toggle Zygor addon
	function RGXQoLLC:ZygorToggle()
		if select(2, C_AddOns.GetAddOnInfo("ZygorGuidesViewerClassic")) then
			if not C_AddOns.IsAddOnLoaded("ZygorGuidesViewerClassic") then
				if RGXQoLLC:PlayerInCombat() then
					return
				else
					C_AddOns.EnableAddOn("ZygorGuidesViewerClassic")
					ReloadUI()
				end
			else
				C_AddOns.DisableAddOn("ZygorGuidesViewerClassic")
				ReloadUI()
			end
		else
			-- Zygor cannot be found
			RGXQoLLC:Print("Zygor addon not found.")
		end
		return
	end
	-- Check if player is in LFG queue (battleground)
	function RGXQoLLC:IsInLFGQueue()

		-- Looking for Group realms (check for everything)
		if C_LFGList.HasActiveEntryInfo() then
			return true
		end

		-- Realms without Looking for Group (just check for battlegrounds)
		for i = 1, GetMaxBattlefieldID() do
			local status = GetBattlefieldStatus(i)
			if status == "queued" or status == "confirmed" then
				return true
			end
		end

	end
----------------------------------------------------------------------
--	L02: Locks
----------------------------------------------------------------------
----------------------------------------------------------------------
--	L03: Restarts
----------------------------------------------------------------------
----------------------------------------------------------------------
--	L40: Player
----------------------------------------------------------------------

	function RGXQoLLC:Player()

		-- RGXQoLLC.NewPatch - Set WorldFrame level to ensure world frame mouse events work (WorldFrame:IsMouseMotionFocus())
		-- In case invalid WorldFrame frame level is stored in layout-local cache
		WorldFrame:SetFrameLevel(1)

		----------------------------------------------------------------------
		--	Automatic summon (no reload required)
		----------------------------------------------------------------------

		do

			-- Event function
			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1)
				if not UnitAffectingCombat("player") then
					local sName = C_SummonInfo.GetSummonConfirmSummoner()
					local sLocation = C_SummonInfo.GetSummonConfirmAreaName()
					RGXQoLLC:Print(L["The summon from"] .. " " .. sName .. " (" .. sLocation .. ") " .. L["will be automatically accepted in 10 seconds unless cancelled."])
					C_Timer.After(10, function()
						local sNameNew = C_SummonInfo.GetSummonConfirmSummoner()
						local sLocationNew = C_SummonInfo.GetSummonConfirmAreaName()
						if sName == sNameNew and sLocation == sLocationNew then
							-- Automatically accept summon after 10 seconds if summoner name and location have not changed
							C_SummonInfo.ConfirmSummon()
							StaticPopup_Hide("CONFIRM_SUMMON")
						end
					end)
				end
				return
			end)

			-- Function to set event
			local function SetEvent()
				if RGXQoLLC["AutoAcceptSummon"] == "On" then
					frame:RegisterEvent("CONFIRM_SUMMON")
				else
					frame:UnregisterEvent("CONFIRM_SUMMON")
				end
			end

			-- Register the setup hook (options bridge calls it on change); run at load
			RGXQoLLC.FeatureSetup.AutoAcceptSummon = SetEvent
			SetEvent()

		end

		----------------------------------------------------------------------
		-- Automate gossip (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to skip gossip
			local function SkipGossip(skipAltKeyRequirement)
				if not skipAltKeyRequirement and not IsAltKeyDown() then return end
				local gossipInfoTable = C_GossipInfo.GetOptions()
				if gossipInfoTable and #gossipInfoTable == 1 and C_GossipInfo.GetNumAvailableQuests() == 0 and C_GossipInfo.GetNumActiveQuests() == 0 and gossipInfoTable[1] and gossipInfoTable[1].gossipOptionID then
					C_GossipInfo.SelectOption(gossipInfoTable[1].gossipOptionID)
				end
			end

			-- Create gossip event frame
			local gossipFrame = CreateFrame("FRAME")

			-- Function to setup events
			local function SetupEvents()
				if RGXQoLLC["AutomateGossip"] == "On" then
					gossipFrame:RegisterEvent("GOSSIP_SHOW")
				else
					gossipFrame:UnregisterEvent("GOSSIP_SHOW")
				end
			end

			-- Register the setup hook (options bridge calls it on change); run at load
			RGXQoLLC.FeatureSetup.AutomateGossip = SetupEvents
			SetupEvents()

			-- Create tables for specific NPC IDs (these are automatically selected with no alt key requirement)
			local npcTable = {

				-- Stable masters (https://www.wowhead.com/classic/npcs?filter=27%3B1%3B0)
				10060, 10063, 9984, 11119, 9985, 11104, 10062, 10085, 9978, 10051, 9988, 10054, 9989, 9981, 10056, 13616, 14741, 10045, 10052, 10047, 10055, 9986, 15722, 6749, 10061, 15131, 9979, 13617, 11105, 10053, 9983, 9982, 10050, 9980, 11117, 10046, 10059, 16094, 10058, 9987, 10048, 9977, 10057, 10049, 11069, 9976,

				-- Banker (https://www.wowhead.com/classic/npcs?filter=19;1;0)
				8356, 2456, 4549, 7799, 4209, 4155, 8123, 3318, 3309, 2455, 2625, 2457, 3320, 2461, 2460, 4208, 8124, 5099, 8119, 8357, 3496, 2459, 4550, 2996, 13917, 2458, 5060,

				-- Flightmaster (https://www.wowhead.com/classic/npcs?filter=21;1;0)
				10583, 352, 8019, 3838, 10897, 3615, 3310, 2299, 12578, 4312, 4267, 1571, 1572, 12616, 16227, 2409, 3841, 2432, 2861, 12740, 12636, 4321, 11900, 1573, 2859, 11138, 11901, 6706, 6726, 8610, 11899, 1387, 931, 12596, 3305, 8609, 2858, 8018, 4407, 15177, 12577, 2995, 523, 4319, 7823, 10378, 2851, 2835, 2226, 4317, 7824, 12617, 2941, 4551, 13177, 11139, 6026, 8020, 2389, 4314, 15178,

				-- Trainer (https://www.wowhead.com/classic/npcs?filter=28;1;0)
				11073, 11865, 2836, 7948, 5482, 11867, 11052, 11097, 8736, 5159, 11072, 4160, 11869, 11870, 7406, 1386, 8126, 2327, 3399, 11098, 1346, 5513, 11868, 11557, 2704, 6287, 4165, 4732, 5567, 11866, 5174, 2399, 11074, 5518, 7944, 4611, 6707, 3373, 6291, 3412, 3352, 12042, 7088, 7870, 4211, 1218, 1292, 4212, 4258, 6306, 4752, 1317, 7311, 9584, 928, 5497, 11017, 4217, 5938, 2485, 5150, 5958, 4210, 4204, 13084, 3494, 4576, 4773, 3026, 3354, 3007, 2489, 4156, 1470, 6286, 2627, 1231, 4578, 4753, 7868, 5499, 2834, 2818, 5144, 2329, 7866, 1430, 4772, 3067, 4591, 3690, 2798, 3355, 4254, 6018, 8738, 5479, 918, 5137, 5564, 4163, 7869, 1103, 5566, 7867, 3347, 4568, 3009, 3032, 3181, 5164, 5517, 1215, 4146, 13417, 7871, 3033, 914, 5493, 3064, 3363, 1701, 5480, 2492, 5491, 6292, 8144, 1300, 3601, 3602, 6289, 3401, 5511, 5957, 4218, 14740, 913, 5943, 4606, 5885, 908, 4586, 6295, 1632, 7954, 5127, 3154, 1651, 3357, 1226, 3607, 3001, 5515, 11031, 6297, 5941, 4616, 1382, 377, 1681, 3404, 3175, 10089, 5880, 6387, 2837, 11177, 2391, 8306, 4552, 11037, 5506, 5498, 3345, 1411, 5177, 5392, 3344, 514, 10993, 328, 8308, 3596, 5153, 2879, 3332, 7089, 11096, 3171, 11068, 11178, 3087, 3039, 3173, 3523, 1355, 5157, 11406, 5504, 5939, 1385, 3365, 13283, 8128, 3706, 5171, 10088, 4598, 3594, 3327, 11146, 3605, 1700, 5484, 6094, 2132, 1699, 5165, 12030, 3184, 3066, 5496, 895, 5516, 7953, 8140, 927, 3136, 5161, 3599, 1241, 4215, 1232, 7232, 986, 1234, 3170, 917, 3964, 3062, 3044, 3169, 1703, 3967, 460, 4595, 3172, 4609, 2367, 3174, 6288, 4138, 5501, 3063, 3597, 944, 5759, 11401, 4213, 2857, 6290, 2131, 3603, 957, 4584, 3324, 376, 915, 3484, 3013, 3031, 3041, 11029, 4588, 1702, 3963, 6299, 461, 4205, 11081, 4219, 7087, 3036, 3325, 11397, 3030, 3011, 5172, 5489, 10086, 5145, 3328, 3549, 5502, 4089, 1383, 912, 10266, 11046, 3047, 4087, 4573, 3290, 3353, 3179, 4596, 1473, 3306, 3137, 3185, 5146, 3688, 7230, 916, 2326, 11065, 812, 5149, 2129, 459, 4214, 3620, 2124, 198, 1228, 5884, 3604, 4614, 11071, 11025, 2878, 8146, 3595, 3048, 5695, 3065, 5173, 3593, 2856, 4090, 10090, 7946, 4582, 3069, 11083, 5883, 2114, 4607, 5612, 1229, 4091, 3028, 2998, 3600, 8153, 5116, 10276, 3403, 2855, 6014, 4900, 4605, 5148, 837, 8141, 5115, 3046, 10277, 11066, 4566, 3038, 5492, 7231, 1901, 5113, 3703, 911, 12032, 12025, 4159, 543, 375, 3157, 3004, 3606, 2390, 4608, 5167, 3557, 4563, 3707, 1404, 3598, 2130, 906, 4583, 11041, 4567, 5117, 3155, 3042, 3034, 3407, 11026, 11050, 3326, 3698, 4898, 926, 925, 2128, 4593, 3545, 5690, 3153, 9465, 8142, 988, 12961, 3061, 1680, 2126, 3156, 5143, 3478, 5147, 11051, 5784, 3406, 7949, 4594, 3965, 223, 2119, 10930, 1676, 3622, 4193, 3059, 3043, 11047, 11070, 3045, 5166, 2127, 5500, 5505, 11048, 1246, 3408, 4320, 7315, 3060, 1466, 11028, 5811, 4092, 4564, 3704, 11067, 11049, 11042, 11084, 5141, 3040, 5495, 1683, 5994, 3624, 5114, 5142, 2123, 2122, 7312, 11044, 3555, 331, 3008, 985, 987, 5882, 4565, 1458, 10278, 3049,

				-- Vendor (https://www.wowhead.com/classic/npcs?filter=29;1;0)
				2805, 13476, 3955, 12919, 844, 2664, 2685, 8125, 8137, 1312, 8139, 3323, 66, 12944, 12022, 1448, 1257, 2626, 12033, 7947, 11189, 2480, 340, 14921, 10667, 4561, 1243, 4229, 4169, 4897, 5494, 14754, 1285, 7775, 222, 12245, 3410, 12246, 9499, 16015, 14846, 1286, 5940, 5110, 3369, 11278, 8145, 4173, 5132, 5175, 4877, 1307, 1441, 734, 4890, 11536, 2810, 3313, 2679, 5519, 4230, 11557, 5594, 3482, 1351, 11188, 14624, 1321, 3614, 4453, 4165, 12942, 7852, 1303, 3556, 8361, 13699, 15419, 13698, 1297, 12943, 2670, 1465, 3335, 5942, 7564, 2832, 6777, 5754, 4730, 2482, 5817, 4585, 5816, 2381, 11056, 3539, 5133, 3027, 3334, 3490, 14753, 3362, 10857, 11185, 5101, 2118, 10856, 12941, 3348, 5162, 7976, 3537, 3881, 13219, 4085, 3935, 3562, 2821, 3534, 3658, 1148, 3413, 4086, 4878, 15174, 2848, 2803, 4217, 16376, 2687, 3133, 15179, 4610, 7978, 10618, 2622, 2682, 1298, 4574, 4879, 9087, 1302, 3015, 2699, 3342, 4083, 4305, 8666, 13217, 15293, 11057, 4981, 225, 8679, 1460, 3409, 2481, 11187, 7854, 4226, 9636, 1313, 3319, 4182, 3495, 3164, 6576, 12043, 12959, 6779, 3954, 4590, 3529, 1275, 1287, 1323, 12799, 9544, 2672, 1304, 3956, 167, 3960, 14322, 5188, 1289, 6548, 12805, 1261, 1146, 5128, 1319, 3180, 4891, 3322, 5120, 6301, 2483, 3497, 7955, 10118, 8160, 3314, 1291, 483, 384, 14637, 4220, 14437, 6929, 8157, 3361, 3489, 2393, 8307, 3368, 2698, 4307, 894, 8364, 3488, 4170, 3134, 15127, 2397, 1325, 8118, 1694, 3081, 1347, 5160, 3018, 1247, 3550, 2684, 3366, 1669, 4232, 6735, 4225, 8665, 11038, 4569, 4575, 8122, 1691, 15471, 1299, 15176, 12957, 12777, 6746, 1149, 1309, 7952, 2816, 3498, 2383, 277, 13216, 11555, 9179, 6730, 3561, 1682, 3017, 2688, 12384, 1250, 5483, 5111, 2380, 491, 3499, 5193, 15126, 3541, 5178, 4617, 3168, 5565, 14740, 8305, 5411, 11874, 4592, 3333, 4562, 6568, 4604, 7683, 989, 8158, 3685, 4241, 4265, 4782, 3492, 3546, 12782, 5151, 1318, 2843, 2819, 8131, 5123, 4555, 11116, 1454, 5158, 4203, 6740, 12792, 14847, 12958, 13218, 8161, 3542, 5783, 1684, 5122, 4731, 4884, 4894, 7744, 5757, 3135, 1459, 14450, 1326, 5124, 2806, 12021, 233, 3367, 3493, 3962, 4589, 3025, 2683, 2663, 4235, 3682, 12956, 6367, 5100, 3186, 5815, 1671, 2394, 2357, 3543, 3029, 4194, 777, 4602, 2839, 6738, 1456, 8362, 3958, 8178, 3317, 14522, 1668, 151, 1453, 6731, 6807, 5814, 3346, 3005, 8878, 4556, 1348, 11106, 4200, 3548, 4175, 3554, 4896, 8934, 7940, 2812, 4256, 10216, 3316, 295, 8150, 4553, 5821, 5520, 1263, 3608, 14480, 3481, 3097, 958, 14481, 4184, 843, 8401, 6382, 1301, 2840, 2084, 829, 2846, 3162, 2697, 3578, 3091, 960, 3536, 5049, 5107, 4571, 3684, 1685, 3405, 1673, 3364, 2838, 3577, 14860, 1692, 5155, 4892, 8403, 8678, 12783, 11184, 8359, 14301, 3019, 4167, 9501, 6747, 6791, 7772, 2401, 3360, 5848, 5753, 3044, 3479, 7879, 14581, 14371, 10369, 11287, 4236, 1463, 3095, 4886, 6930, 1471, 1237, 4557, 1322, 5108, 12796, 3609, 5812, 3074, 5611, 1687, 1238, 5103, 5170, 7737, 2388, 3683, 15898, 4888, 13018, 5510, 983, 3592, 3350, 274, 9548, 4216, 2668, 15197, 190, 10293, 7942, 14337, 2908, 4885, 1147, 11118, 5698, 2997, 15175, 3351, 4186, 4177, 6495, 1457, 3518, 1469, 8129, 1316, 3096, 4587, 12097, 3589, 227, 5819, 226, 5109, 8681, 2849, 4597, 3187, 3953, 1214, 4172, 4234, 3951, 11183, 9549, 3611, 5106, 12960, 54, 4180, 5503, 8360, 981, 3934, 8931, 12023, 2814, 3012, 8177, 1695, 2669, 12096, 3178, 12027, 5169, 4899, 4228, 1294, 4191, 5163, 956, 836, 12795, 4223, 4181, 8176, 3165, 3000, 11703, 1273, 8508, 10361, 5138, 14964, 1324, 3088, 7714, 7733, 3610, 4231, 3359, 3970, 4577, 12026, 9553, 2136, 3530, 1198, 3356, 5189, 4560, 3400, 3572, 5173, 228, 2116, 5125, 1310, 2845, 3090, 1333, 6928, 12196, 6741, 5688, 4876, 3072, 13435, 5748, 4883, 1295, 5758, 3587, 3330, 4603, 1645, 17598, 10380, 7945, 1320, 8363, 1350, 4889, 15864, 896, 15011, 2842, 12962, 3485, 9552, 3552, 2046, 5152, 1450, 2365, 6028, 5102, 3020, 5569, 4601, 5820, 3085, 12807, 1452, 12045, 7943, 4187, 6736, 3700, 3483, 16256, 954, 4615, 5749, 3937, 1339, 3076, 3321, 9555, 14739, 2364, 3014, 13420, 15354, 4581, 1407, 9551, 3023, 14844, 3779, 3500, 1650, 9676, 3163, 2808, 4222, 11137, 8404, 465, 12793, 4255, 152, 4266, 1462, 3003, 4043, 14963, 4600, 1362, 3291, 980, 1104, 3486, 3477, 1464, 6272, 11103, 6790, 13430, 790, 5121, 6027, 3621, 14961, 3533, 15315, 3625, 15199, 4185, 9099, 984, 3079, 10364, 1349, 1315, 4240, 6328, 12019, 14962, 1314, 3158, 2140, 6300, 6567, 1213, 3358, 2117, 5119, 2265, 2264, 12776, 2352, 6727, 7731, 9356, 2847, 5512, 793, 3021, 3331, 15353, 13418, 1697, 1381, 5870, 5139, 3159, 12028, 4257, 4558, 791, 12781, 5190, 1670, 3480, 2134, 11182, 3312, 1308, 3532, 4599, 3553, 5508, 5135, 4570, 4221, 4554, 4559, 4195, 3177, 3349, 4189, 13433, 2135, 2113, 2366, 5514, 5570, 4084, 4164, 6091, 3411, 15006, 5140, 2137, 1328, 3969, 3298, 3705, 13436, 5112, 3933, 8152, 8358, 3160, 4188, 6739, 6734, 6737, 1686, 3491, 3590, 15012, 2115, 258, 3487, 372, 5509, 3078, 3329, 74, 4190, 5871, 8143, 13434, 12031, 3961, 7941, 3613, 3531, 959, 1461, 13429, 7485, 12029, 8398, 5126, 14738, 3551, 3528, 1474, 3161, 955, 12785, 3089, 14737, 12794, 3053, 3092, 3016, 15124, 2999, 6298, 982, 4259, 4954, 1678, 6376, 8116, 3882, 3952, 6496, 3075, 3166, 6373, 1296, 1698, 3591, 5750, 2820, 3343, 3093, 5886, 3547, 3948, 16458, 1305, 3544, 8121, 3884, 1311, 5134, 3588, 3002, 3689, 12784, 5129, 1672, 4580, 2303, 5156, 3010, 3073, 12024, 3883, 3959, 5154, 945, 3138, 13432, 5191, 3612, 3022, 4192, 3315, 4875, 8117, 3167, 5944, 2225, 10379, 4893, 5620, 1240, 3522, 6374, 4168, 4775, 4082, 3086, 3708, 3540, 3080, 2844, 78, 6574, 789, 15125, 14731, 11186, 3077, 4171, 4233, 4183, 1249, 10367, 14845, 1690, 13431, 1341, 8159,

				-- Battlemaster (https://www.wowhead.com/classic/npcs?filter=20;1;0)
				14981, 907, 14982, 7427, 12197, 5118, 347, 15007, 7410, 3890, 15106, 10360, 14990, 15006, 15008, 15102, 2302, 857, 2804, 14991, 15103, 15105, 14942, 12198,

			}

			-- Event handler
			gossipFrame:SetScript("OnEvent", function()
				-- Special treatment for specific NPCs
				local npcGuid = UnitGUID("npc") or nil
				if npcGuid and not IsShiftKeyDown() then
					local void, void, void, void, void, npcID = strsplit("-", npcGuid)
					if npcID then
						-- Skip gossip with no alt key requirement
						if npcID == "999999999"	-- Reserved for future use
						or tContains(npcTable, tonumber(npcID))
						then
							SkipGossip(true) 	-- true means skip alt key requirement
							return
						end
					end
				end
				-- Process gossip
				SkipGossip()
			end)

			-- Show battleground name in battfield frame labels
			SafeHookSecure("BattlefieldFrame_Update", function()
				if RGXQoLLC["AutomateGossip"] == "On" then
					local localizedName = GetBattlegroundInfo()
					if localizedName then
						BattlefieldFrameFrameLabel:SetText(localizedName)
					end
				end
			end)

		end

		----------------------------------------------------------------------
		--	Automate quests (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to determine if override key is being held
			local function IsOverrideKeyDown()
				if RGXQoLLC["AutoQuestKeyMenu"] == 1 and IsShiftKeyDown()
				or RGXQoLLC["AutoQuestKeyMenu"] == 2 and IsAltKeyDown()
				or RGXQoLLC["AutoQuestKeyMenu"] == 3 and IsControlKeyDown()
				or RGXQoLLC["AutoQuestKeyMenu"] == 4 and IsMetaKeyDown()
				then
					return true
				end
			end

			-- Funcion to ignore specific NPCs
			local function isNpcBlocked(actionType)
				local npcGuid = UnitGUID("npc") or nil -- works when SoftTargetInteract set to 3
				if npcGuid then
					local void, void, void, void, void, npcID = strsplit("-", npcGuid)
					if npcID then
						-- Ignore specific NPCs for selecting, accepting and turning-in quests (required if automation has consequences)
						if npcID == "15192"	-- Anachronos (Caverns of Time)
						or npcID == "3430" 	-- Mangletooth (Blood Shard quests, Barrens)
						or npcID == "14828" -- Gelvas Grimegate (Darkmoon Faire Ticket Redemption, Elwynn Forest and Mulgore)
						or npcID == "14921" -- Rin'wosho the Trader (Zul'Gurub Isle, Stranglethorn Vale)
						or npcID == "15864" -- Valadar Starsong (Coin of Ancestry Collector, Moonglade)
						or npcID == "15909" -- Fariel Starsong (Coin of Ancestry Collector, Moonglade)
						or npcID == "15540" -- Windcaller Kaldon (Badge Collector, Silithus)
						-- Ignore supply officers
						or npcID == "213077" -- Elaine Compton <Supply Officer> (Stormwind)
						or npcID == "214099" -- Tamelyn Aldridge <Supply Officer> (Ironforge)
						or npcID == "214101" -- Marcy Baker <Supply Officer> (Darnassus)
						or npcID == "214070" -- Jornah <Supply Officer> (Orgrimmar)
						or npcID == "214096" -- Dokimi <Supply Officer> (Thunder Bluff)
						or npcID == "214098" -- Gishah <Supply Officer> (Undercity)
						then
							return true
						end
						-- Ignore specific NPCs for accepting quests only
						if actionType == "Accept" then
							-- Escort quests
							if npcID == "467" -- The Defias Traitor (The Defias Brotherhood)
							or npcID == "349" -- Corporal Keeshan (Missing In Action)
							or npcID == "1379" -- Miran (Protecting the Shipment)
							or npcID == "7766" -- Tyrion (The Attack!)
							or npcID == "1978" -- Deathstalker Erland (Escorting Erland)
							or npcID == "7784" -- Homing Robot OOX-17/TN (Rescue OOX-17/TN!)
							or npcID == "2713" -- Kinelory (Hints of a New Plague?)
							or npcID == "2768" -- Professor Phizzlethorpe (Sunken Treasure)
							or npcID == "2610" -- Shakes O'Breen (Death From Below)
							or npcID == "2917" -- Prospector Remtravel (The Absent Minded Prospector)
							or npcID == "7806" -- Homing Robot OOX-09/HL (Rescue OOX-09/HL!)
							or npcID == "3439" -- Wizzlecrank's Shredder (The Escape)
							or npcID == "3465" -- Gilthares Firebough (Free From the Hold)
							or npcID == "3568" -- Mist (Mist)
							or npcID == "3584" -- Therylune (Therylune's Escape)
							or npcID == "4484" -- Feero Ironhand (Supplies to Auberdine)
							or npcID == "3692" -- Volcor (Escape Through Force)
							or npcID == "4508" -- Willix the Importer (Willix the Importer)
							or npcID == "4880" -- "Stinky" Ignatz (Stinky's Escape)
							or npcID == "4983" -- Ogron (Questioning Reethe)
							or npcID == "5391" -- Galen Goodward (Galen's Escape)
							or npcID == "5644" -- Dalinda Malem (Return to Vahlarriel)
							or npcID == "5955" -- Tooga (Tooga's Quest)
							or npcID == "7780" -- Rin'ji (Rin'ji is Trapped!)
							or npcID == "7807" -- Homing Robot OOX-22/FE (Rescue OOX-22/FE!)
							or npcID == "7774" -- Shay Leafrunner (Wandering Shay)
							or npcID == "7850" -- Kernobee (A Fine Mess)
							or npcID == "8284" -- Dorius Stonetender (Suntara Stones)
							or npcID == "8380" -- Captain Vanessa Beltis (A Crew Under Fire)
							or npcID == "8516" -- Belnistrasz (Extinguishing the Idol)
							or npcID == "9020" -- Commander Gor'shak (What Is Going On?)
							or npcID == "9520" -- Grark Lorkrub (Precarious Predicament)
							or npcID == "9623" -- A-Me 01 (Chasing A-Me 01)
							or npcID == "9598" -- Arei (Ancient Spirit)
							or npcID == "9023" -- Marshal Windsor (Jail Break!)
							or npcID == "9999" -- Ringo (A Little Help From My Friends)
							or npcID == "10427" -- Pao'ka Swiftmountain (Homeward Bound)
							or npcID == "10300" -- Ranshalla (Guardians of the Altar)
							or npcID == "10646" -- Lakota Windsong (Free at Last)
							or npcID == "10638" -- Kanati Greycloud (Protect Kanati Greycloud)
							or npcID == "11016" -- Captured Arko'narin (Rescue From Jaedenar)
							or npcID == "11218" -- Kerlonian Evershade (The Sleeper Has Awakened)
							or npcID == "11711" -- Sentinel Aynasha (One Shot. One Kill.)
							or npcID == "11625" -- Cork Gizelton (Bodyguard for Hire)
							or npcID == "11626" -- Rigger Gizelton (Gizelton Caravan)
							or npcID == "1842" -- Highlord Taelan Fordring (In Dreams)
							or npcID == "12277" -- Melizza Brimbuzzle (Get Me Out of Here!)
							or npcID == "12580" -- Reginald Windsor (The Great Masquerade)
							or npcID == "12818" -- Ruul Snowhoof (Freedom to Ruul)
							or npcID == "11856" -- Kaya Flathoof (Protect Kaya)
							or npcID == "12858" -- Torek (Torek's Assault)
							or npcID == "12717" -- Muglash (Vorsha the Lasher)
							or npcID == "13716" -- Celebras the Redeemed (The Scepter of Celebras)
							then
								return true
							end
						end
						-- Ignore specific NPCs for selecting quests only (only used for items that have no other purpose)
						if actionType == "Select" then
							if npcID == "12944" -- Lokhtos Darkbargainer (Thorium Brotherhood, Blackrock Depths)
							-- Ahn'Qiraj War Effort (Alliance, Ironforge)
							or npcID == "15446" -- Bonnie Stoneflayer (Light Leather Collector)
							or npcID == "15458" -- Commander Stronghammer (Alliance Ambassador)
							or npcID == "15431" -- Corporal Carnes (Iron Bar Collector)
							or npcID == "15432" -- Dame Twinbraid (Thorium Bar Collector)
							or npcID == "15453" -- Keeper Moonshade (Runecloth Bandage Collector)
							or npcID == "15457" -- Huntress Swiftriver (Spotted Yellowtail Collector)
							or npcID == "15450" -- Marta Finespindle (Thick Leather Collector)
							or npcID == "15437" -- Master Nightsong (Purple Lotus Collector)
							or npcID == "15452" -- Nurse Stonefield (Silk Bandage Collector)
							or npcID == "15434" -- Private Draxlegauge (Stranglekelp Collector)
							or npcID == "15448" -- Private Porter (Medium Leather Collector)
							or npcID == "15456" -- Sarah Sadwhistle (Roast Raptor Collector)
							or npcID == "15451" -- Sentinel Silversky (Linen Bandage Collector)
							or npcID == "15445" -- Sergeant Major Germaine (Arthas' Tears Collector)
							or npcID == "15383" -- Sergeant Stonebrow (Copper Bar Collector)
							or npcID == "15455" -- Slicky Gastronome (Rainbow Fin Albacore Collector)
							-- Ahn'Qiraj War Effort (Horde, Orgrimmar)
							or npcID == "15512" -- Apothecary Jezel (Purple Lotus Collector)
							or npcID == "15508" -- Batrider Pele'keiki (Firebloom Collector)
							or npcID == "15533" -- Bloodguard Rawtar (Lean Wolf Steak Collector)
							or npcID == "15535" -- Chief Sharpclaw (Baked Salmon Collector)
							or npcID == "15525" -- Doctor Serratus (Rugged Leather Collector)
							or npcID == "15534" -- Fisherman Lin'do (Spotted Yellowtail Collector)
							or npcID == "15539" -- General Zog (Horde Ambassador)
							or npcID == "15460" -- Grunt Maug (Tin Bar Collector)
							or npcID == "15528" -- Healer Longrunner (Wool Bandage Collector)
							or npcID == "15477" -- Herbalist Proudfeather (Peacebloom Collector)
							or npcID == "15529" -- Lady Callow (Mageweave Bandage Collector)
							or npcID == "15459" -- Miner Cromwell (Copper Bar Collector)
							or npcID == "15469" -- Senior Sergeant T'kelah (Mithril Bar Collector)
							or npcID == "15522" -- Sergeant Umala (Thick Leather Collector)
							or npcID == "15515" -- Skinner Jamani (Heavy Leather Collector)
							or npcID == "15532" -- Stoneguard Clayhoof (Runecloth Bandage Collector)
							-- Alliance Commendations
							or npcID == "15764" -- Officer Ironbeard (Ironforge Commendations)
							or npcID == "15762" -- Officer Lunalight (Darnassus Commendations)
							or npcID == "15766" -- Officer Maloof (Stormwind Commendations)
							or npcID == "15763" -- Officer Porterhouse (Gnomeregan Commendations)
							-- Horde Commendations
							or npcID == "15768" -- Officer Gothena (Undercity Commendations)
							or npcID == "15765" -- Officer Redblade (Orgrimmar Commendations)
							or npcID == "15767" -- Officer Thunderstrider (Thunder Bluff Commendations)
							or npcID == "15761" -- Officer Vu'Shalay (Darkspear Commendations)
							-- Battlegrounds (Alliance)
							or npcID == "13442" -- Arch Druid Renferal (Storm Crystal, Alterac Valley)
							-- Battlegrounds (Horde)
							or npcID == "13236" -- Primalist Thurloga (Stormpike Soldier's Blood, Alterac Valley)
							-- Scourgestones
							or npcID == "11039" -- Duke Nicholas Zverenhoff (Eastern Plaguelands)
							-- Un'Goro crystals
							or npcID == "9117" 	-- J. D. Collie (Un'Goro Crater)
							then
								return true
							end
						end
					end
				end
			end

			-- Function to check if quest requires a blocked item
			local function QuestRequiresBlockedItem()
				for i = 1, 6 do
					local progItem = _G["QuestProgressItem" ..i] or nil
					if progItem and progItem:IsShown() and progItem.type == "required" then
						if progItem.objectType == "item" then
							local name, texture, numItems = GetQuestItemInfo("required", i)
							if name then
								local itemID = C_Item.GetItemInfoInstant(name)
								if itemID then
									if itemID == 9999999999 then -- Reserved for future use
										return true
									end
								end
							end
						end
					end
				end
			end

			-- Function to check if quest requires gold
			local function QuestRequiresGold()
				local goldRequiredAmount = GetQuestMoneyToGet()
				if goldRequiredAmount and goldRequiredAmount > 0 then
					return true
				end
			end

			-- Function to check if quest title has requirements met
			local function DoesQuestHaveRequirementsMet(title)
				if title and title ~= "" then

					if not title then

					-- Battlemasters
					elseif title == L["Concerted Efforts"] or title == L["For Great Honor"] then
						-- Requires 3 Alterac Valley Mark of Honor, 3 Arathi Basin Mark of Honor, 3 Warsong Gulch Mark of Honor (must be before other Mark of Honor quests)
						if C_Item.GetItemCount(20560) >= 3 and C_Item.GetItemCount(20559) >= 3 and C_Item.GetItemCount(20558) >= 3 then return true end
					elseif title == L["Remember Alterac Valley!"] or title == L["Invaders of Alterac Valley"] then
						-- Requires 3 Alterac Valley Mark of Honor
						if C_Item.GetItemCount(20560) >= 3 then return true end
					elseif title == L["Claiming Arathi Basin"] or title == L["Conquering Arathi Basin"] then
						-- Requires 3 Arathi Basin Mark of Honor
						if C_Item.GetItemCount(20559) >= 3 then return true end
					elseif title == L["Fight for Warsong Gulch"] or title == L["Battle of Warsong Gulch"] then
						-- Requires 3 Warsong Gulch Mark of Honor
						if C_Item.GetItemCount(20558) >= 3 then return true end

					-- Cloth quartermasters
					elseif title == L["A Donation of Wool"] then
						-- Requires 60 Wool Cloth
						if C_Item.GetItemCount(2592) >= 60 then return true end
					elseif title == L["A Donation of Silk"] then
						-- Requires 60 Silk Cloth
						if C_Item.GetItemCount(4306) >= 60 then return true end
					elseif title == L["A Donation of Mageweave"] then
						-- Requires 60 Mageweave
						if C_Item.GetItemCount(4338) >= 60 then return true end
					elseif title == L["A Donation of Runecloth"] then
						-- Requires 60 Runecloth
						if C_Item.GetItemCount(14047) >= 60 then return true end
					elseif title == L["Additional Runecloth"] then
						-- Requires 20 Runecloth
						if C_Item.GetItemCount(14047) >= 20 then return true end
					elseif title == L["Gurubashi, Vilebranch, and Witherbark Coins"] then
						-- Requires 1 Gurubashi Coin, 1 Vilebranch Coin, 1 Witherbark Coin
						if C_Item.GetItemCount(19701) >= 1 and C_Item.GetItemCount(19702) >= 1 and C_Item.GetItemCount(19703) >= 1 then return true end
					elseif title == L["Sandfury, Skullsplitter, and Bloodscalp Coins"] then
						-- Requires 1 Sandfury Coin, 1 Skullsplitter Coin, 1 Bloodscalp Coin
						if C_Item.GetItemCount(19704) >= 1 and C_Item.GetItemCount(19705) >= 1 and C_Item.GetItemCount(19706) >= 1 then return true end
					elseif title == L["Zulian, Razzashi, and Hakkari Coins"] then
						-- Requires 1 Zulian Coin, 1 Razzashi Coin, 1 Hakkari Coin
						if C_Item.GetItemCount(19698) >= 1 and C_Item.GetItemCount(19699) >= 1 and C_Item.GetItemCount(19700) >= 1 then return true end
					elseif title == L["Frostsaber E'ko"] then
						-- Requires 3 Frostsaber E'ko
						if C_Item.GetItemCount(12430) >= 3 then return true end
					elseif title == L["Winterfall E'ko"] then
						-- Requires 3 Winterfall E'ko
						if C_Item.GetItemCount(12431) >= 3 then return true end
					elseif title == L["Shardtooth E'ko"] then
						-- Requires 3 Shardtooth E'ko
						if C_Item.GetItemCount(12432) >= 3 then return true end
					elseif title == L["Wildkin E'ko"] then
						-- Requires 3 Wildkin E'ko
						if C_Item.GetItemCount(12433) >= 3 then return true end
					elseif title == L["Chillwind E'ko"] then
						-- Requires 3 Chillwind E'ko
						if C_Item.GetItemCount(12434) >= 3 then return true end
					elseif title == L["Ice Thistle E'ko"] then
						-- Requires 3 Ice Thistle E'ko
						if C_Item.GetItemCount(12435) >= 3 then return true end
					elseif title == L["Frostmaul E'ko"] then
						-- Requires 3 Ice Thistle E'ko
						if C_Item.GetItemCount(12436) >= 3 then return true end

					else return true
					end
				end
			end

			-- Create event frame
			local qFrame = CreateFrame("FRAME")

			-- Function to setup events
			local function SetupEvents()
				if RGXQoLLC["AutomateQuests"] == "On" then
					qFrame:RegisterEvent("QUEST_DETAIL")
					qFrame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
					qFrame:RegisterEvent("QUEST_PROGRESS")
					qFrame:RegisterEvent("QUEST_COMPLETE")
					qFrame:RegisterEvent("QUEST_GREETING")
					qFrame:RegisterEvent("QUEST_AUTOCOMPLETE")
					qFrame:RegisterEvent("GOSSIP_SHOW")
					qFrame:RegisterEvent("QUEST_FINISHED")
				else
					qFrame:UnregisterAllEvents()
				end
			end

			-- Register the setup hook (options bridge calls it on change); run at load
			RGXQoLLC.FeatureSetup.AutomateQuests = SetupEvents
			SetupEvents()

			-- Event handler
			qFrame:SetScript("OnEvent", function(self, event, arg1)


				-- Clear progress items when quest interaction has ceased
				if event == "QUEST_FINISHED" then
					for i = 1, 6 do
						local progItem = _G["QuestProgressItem" ..i] or nil
						if progItem and progItem:IsShown() then
							progItem:Hide()
						end
					end
					return
				end

				-- Check for SHIFT key modifier
				if RGXQoLLC["AutoQuestShift"] == "On" and not IsOverrideKeyDown() then return
				elseif RGXQoLLC["AutoQuestShift"] == "Off" and IsOverrideKeyDown() then return
				end

				----------------------------------------------------------------------
				-- Accept quests automatically
				----------------------------------------------------------------------

				-- Accept quests with a quest detail window
				if event == "QUEST_DETAIL" then
					if RGXQoLLC["AutoQuestAvailable"] == "On" then
						-- Don't accept blocked quests
						if isNpcBlocked("Accept") then return end
						-- Accept quest
						AcceptQuest()
						-- HideUIPanel(QuestFrame)
					end
				end

				-- Accept quests which require confirmation (such as sharing escort quests)
				if event == "QUEST_ACCEPT_CONFIRM" then
					if RGXQoLLC["AutoQuestAvailable"] == "On" then
						ConfirmAcceptQuest()
						StaticPopup_Hide("QUEST_ACCEPT")
					end
				end

				----------------------------------------------------------------------
				-- Turn-in quests automatically
				----------------------------------------------------------------------

				-- Turn-in progression quests
				if event == "QUEST_PROGRESS" and IsQuestCompletable() then
					if RGXQoLLC["AutoQuestCompleted"] == "On" then
						-- Don't continue quests for blocked NPCs
						if isNpcBlocked("Complete") then return end
						-- Don't continue if quest requires blocked item
						if QuestRequiresBlockedItem() then return end
						-- Don't continue if quest requires gold
						if QuestRequiresGold() then return end
						-- Continue quest
						CompleteQuest()
					end
				end

				-- Turn in completed quests if only one reward item is being offered
				if event == "QUEST_COMPLETE" then
					if RGXQoLLC["AutoQuestCompleted"] == "On" then
						-- Don't complete quests for blocked NPCs
						if isNpcBlocked("Complete") then return end
						-- Don't complete if quest requires blocked item
						if QuestRequiresBlockedItem() then return end
						-- Don't complete if quest requires gold
						if QuestRequiresGold() then return end
						-- Complete quest
						if GetNumQuestChoices() <= 1 then
							GetQuestReward(GetNumQuestChoices())
						end
					end
				end

				-- Show quest dialog for quests that use the objective tracker (it will be completed automatically)
				if event == "QUEST_AUTOCOMPLETE" then
					if RGXQoLLC["AutoQuestCompleted"] == "On" then
						local index = GetQuestLogIndexByID(arg1)
						if GetQuestLogIsAutoComplete(index) then
							ShowQuestComplete(index)
						end
					end
				end

				----------------------------------------------------------------------
				-- Select quests automatically
				----------------------------------------------------------------------

				if event == "GOSSIP_SHOW" or event == "QUEST_GREETING" then

					-- Select quests
					if UnitExists("npc") or QuestFrameGreetingPanel:IsShown() then

						-- Don't select quests for blocked NPCs
						if isNpcBlocked("Select") then return end

						-- Select quests
						if event == "QUEST_GREETING" then
							-- Select quest greeting completed quests
							if RGXQoLLC["AutoQuestCompleted"] == "On" then
								for i = 1, GetNumActiveQuests() do
									local title, isComplete = GetActiveTitle(i)
									if title and isComplete then
										return SelectActiveQuest(i)
									end
								end
							end
							-- Select quest greeting available quests
							if RGXQoLLC["AutoQuestAvailable"] == "On" then
								for i = 1, GetNumAvailableQuests() do
									local title, isComplete = GetAvailableTitle(i)
									if title and not isComplete then
										return SelectAvailableQuest(i)
									end
								end
							end
						else
							-- Select gossip completed quests
							-- questInfo.isComplete can return false for completed quests with no objectives in Classic Era (test with first quest for level 1 Orc) (does not currently apply to Wrath Classic or Dragonflight)
							if RGXQoLLC["AutoQuestCompleted"] == "On" then
								local gossipQuests = C_GossipInfo.GetActiveQuests()
								for titleIndex, questInfo in ipairs(gossipQuests) do
									if questInfo.title and (questInfo.isComplete or questInfo.questID and IsQuestComplete(questInfo.questID)) then
										if questInfo.questID then
											return C_GossipInfo.SelectActiveQuest(questInfo.questID)
										end
									end
								end
							end
							-- Select gossip available quests
							if RGXQoLLC["AutoQuestAvailable"] == "On" then
								local GossipQuests = C_GossipInfo.GetAvailableQuests()
								for titleIndex, questInfo in ipairs(GossipQuests) do
									if questInfo.questID and DoesQuestHaveRequirementsMet(questInfo.questID) then
										return C_GossipInfo.SelectAvailableQuest(questInfo.questID)
									end
								end
							end
						end
					end
				end

			end)

		end

		----------------------------------------------------------------------
		--	Sell junk automatically (no reload required)
		----------------------------------------------------------------------

		do

			-- Create sell junk banner
			local StartMsg = CreateFrame("FRAME", nil, MerchantFrame)
			StartMsg:ClearAllPoints()
			StartMsg:SetPoint("BOTTOMLEFT", 4, 4)
			StartMsg:SetSize(160, 22)
			StartMsg:SetToplevel(true)
			StartMsg:Hide()

			StartMsg.s = StartMsg:CreateTexture(nil, "BACKGROUND")
			StartMsg.s:SetAllPoints()
			StartMsg.s:SetColorTexture(0.1, 0.1, 0.1, 1.0)

			StartMsg.f = StartMsg:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			StartMsg.f:SetAllPoints();
			StartMsg.f:SetText(L["SELLING JUNK"])

			-- Declarations
			local IterationCount, totalPrice = 500, 0
			local SellJunkTicker

			-- Create custom NewTicker function (from Wrath)
			local function RGXQoLNewTicker(duration, callback, iterations)
				local ticker = setmetatable({}, TickerMetatable)
				ticker._remainingIterations = iterations
				ticker._callback = function()
					if (not ticker._cancelled) then
						callback(ticker)
						--Make sure we weren't cancelled during the callback
						if (not ticker._cancelled) then
							if (ticker._remainingIterations) then
								ticker._remainingIterations = ticker._remainingIterations - 1
							end
							if (not ticker._remainingIterations or ticker._remainingIterations > 0) then
								C_Timer.After(duration, ticker._callback)
							end
						end
					end
				end
				C_Timer.After(duration, ticker._callback)
				return ticker
			end

			-- Create configuration panel
			-- Pure event frame (configuration panel removed; options live in the framework panel)
			local SellJunkFrame = CreateFrame("FRAME")
			-- Function to stop selling
			local function StopSelling()
				if SellJunkTicker then SellJunkTicker._cancelled = true; end
				StartMsg:Hide()
				SellJunkFrame:UnregisterEvent("ITEM_LOCKED")
				SellJunkFrame:UnregisterEvent("UI_ERROR_MESSAGE")
			end
			-- Saved-value whitelist (the saved AutoSellExcludeList string drives it; no editbox)
			local whiteList = {}
			local function UpdateWhiteList()
				wipe(whiteList)
				local whiteString = (RGXQoLLC["AutoSellExcludeList"] or ""):gsub("[^,%d]", "")
				local tList = {strsplit(",", whiteString)}
				for k = 1, #tList do
					local id = tonumber(tList[k])
					if id then whiteList[id] = true end
				end
			end
			UpdateWhiteList()

			-- Vendor function
			local function SellJunkFunc()

				-- Variables
				local SoldCount, Rarity, ItemPrice = 0, 0, 0
				local CurrentItemLink, void

				-- Traverse bags and sell grey items
				for BagID = 0, 4 do
					for BagSlot = 1, C_Container.GetContainerNumSlots(BagID) do
						CurrentItemLink = C_Container.GetContainerItemLink(BagID, BagSlot)
						if CurrentItemLink then
							void, void, Rarity, void, void, void, void, void, void, void, ItemPrice = C_Item.GetItemInfo(CurrentItemLink)
							-- Don't sell whitelisted items
							local itemID = GetItemInfoFromHyperlink(CurrentItemLink)
							if itemID and whiteList[itemID] then
								if Rarity == 0 then
									-- Junk item to keep
									Rarity = 3
									ItemPrice = 0
								elseif Rarity == 1 then
									-- White item to sell
									Rarity = 0
								end
							end
							-- Continue
							local cInfo = C_Container.GetContainerItemInfo(BagID, BagSlot)
							local itemCount = cInfo.stackCount
							if Rarity == 0 and ItemPrice ~= 0 then
								SoldCount = SoldCount + 1
								if MerchantFrame:IsShown() then
									-- If merchant frame is open, vendor the item
									C_Container.UseContainerItem(BagID, BagSlot)
									-- Perform actions on first iteration
									if SellJunkTicker._remainingIterations == IterationCount then
										-- Calculate total price
										totalPrice = totalPrice + (ItemPrice * itemCount)
									end
								else
									-- If merchant frame is not open, stop selling
									StopSelling()
									return
								end
							end
						end
					end
				end

				-- Stop selling if no items were sold for this iteration or iteration limit was reached
				if SoldCount == 0 or SellJunkTicker and SellJunkTicker._remainingIterations == 1 then
					StopSelling()
					if totalPrice > 0 and RGXQoLLC["AutoSellShowSummary"] == "On" then
						RGXQoLLC:Print(L["Sold junk for"] .. " " .. (GetCoinText or GetMoneyString or function(v) return tostring(v) end)(totalPrice) .. ".")
					end
				end

			end

			-- Function to setup events
			local function SetupEvents()
				if RGXQoLLC["AutoSellJunk"] == "On" then
					SellJunkFrame:RegisterEvent("MERCHANT_SHOW");
					SellJunkFrame:RegisterEvent("MERCHANT_CLOSED");
				else
					SellJunkFrame:UnregisterEvent("MERCHANT_SHOW")
					SellJunkFrame:UnregisterEvent("MERCHANT_CLOSED")
				end
			end

			-- Register the setup hook (options bridge calls it on change); run at load
			RGXQoLLC.FeatureSetup.AutoSellJunk = function() SetupEvents(); UpdateWhiteList() end
			if RGXQoLLC["AutoSellJunk"] == "On" then SetupEvents() end

			-- Event handler
			SellJunkFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
				if event == "MERCHANT_SHOW" then
					-- Check for vendors that refuse to buy items
					SellJunkFrame:RegisterEvent("UI_ERROR_MESSAGE")
					-- Reset variable
					totalPrice = 0
					-- Do nothing if shift key is held down
					if IsShiftKeyDown() then return end
					-- Cancel existing ticker if present
					if SellJunkTicker then SellJunkTicker._cancelled = true; end
					-- Sell grey items using ticker (ends when all grey items are sold or iteration count reached)
					SellJunkTicker = RGXQoLNewTicker(0.2, SellJunkFunc, IterationCount)
					SellJunkFrame:RegisterEvent("ITEM_LOCKED")
				elseif event == "ITEM_LOCKED" then
					StartMsg:Show()
					SellJunkFrame:UnregisterEvent("ITEM_LOCKED")
				elseif event == "MERCHANT_CLOSED" then
					-- If merchant frame is closed, stop selling
					StopSelling()
				elseif event == "UI_ERROR_MESSAGE" then
					if arg2 and (arg2 == ERR_VENDOR_DOESNT_BUY or arg2 == ERR_TOO_MUCH_GOLD) then
						-- Vendor refuses to buy items or player at gold limit
						StopSelling()
					end
				end
			end)

		end

		----------------------------------------------------------------------
		--	Repair automatically (no reload required)
		----------------------------------------------------------------------

		do

			-- Repair when suitable merchant frame is shown
			local function RepairFunc()
				if IsShiftKeyDown() then return end
				if CanMerchantRepair() then -- If merchant is capable of repair
					-- Process repair
					local RepairCost, CanRepair = GetRepairAllCost()
					if CanRepair then -- If merchant is offering repair
						if GetMoney() >= RepairCost then
							RepairAllItems()
							-- Show cost summary
							if RGXQoLLC["AutoRepairShowSummary"] == "On" then
								RGXQoLLC:Print(L["Repaired for"] .. " " .. (GetCoinText or GetMoneyString or function(v) return tostring(v) end)(RepairCost) .. ".")
							end
						end
					end
				end
			end

			-- Create event frame
			local RepairFrame = CreateFrame("FRAME")

			-- Function to setup event
			local function SetupEvent()
				if RGXQoLLC["AutoRepairGear"] == "On" then
					RepairFrame:RegisterEvent("MERCHANT_SHOW")
				else
					RepairFrame:UnregisterEvent("MERCHANT_SHOW")
				end
			end

			-- Register the setup hook (options bridge calls it on change); run at load
			RGXQoLLC.FeatureSetup.AutoRepairGear = SetupEvent
			SetupEvent()

			-- Event handler
			RepairFrame:SetScript("OnEvent", RepairFunc)

		end

		----------------------------------------------------------------------
		-- Automatically accept resurrection requests (no reload required)
		----------------------------------------------------------------------

		do

			-- Event frame (configuration panel removed)
			local AcceptResPanel = CreateFrame("FRAME")

			-- Function to set resurrect event
			local function SetResEvent()
				if RGXQoLLC["AutoAcceptRes"] == "On" then
					AcceptResPanel:RegisterEvent("RESURRECT_REQUEST")
				else
					AcceptResPanel:UnregisterEvent("RESURRECT_REQUEST")
				end
			end

			-- Register the setup hook (options bridge calls it on change); run at load
			RGXQoLLC.FeatureSetup.AutoAcceptRes = SetResEvent
			SetResEvent()

			-- Handle event
			AcceptResPanel:SetScript("OnEvent", function(self, event, arg1)
				if event == "RESURRECT_REQUEST" then

					-- Exclude Chained Spirit (Zul'Gurub)
					local chainLoc

					-- Exclude Chained Spirit (Zul'Gurub)
					chainLoc = "Chained Spirit"
					if 	   GameLocale == "zhCN" then chainLoc = "??????"
					elseif GameLocale == "zhTW" then chainLoc = "????"
					elseif GameLocale == "ruRU" then chainLoc = "????????? ???"
					elseif GameLocale == "koKR" then chainLoc = "??? ??"
					elseif GameLocale == "esMX" then chainLoc = "Esp�ritu encadenado"
					elseif GameLocale == "ptBR" then chainLoc = "Esp�rito Acorrentado"
					elseif GameLocale == "deDE" then chainLoc = "Angeketteter Geist"
					elseif GameLocale == "esES" then chainLoc = "Esp�ritu encadenado"
					elseif GameLocale == "frFR" then chainLoc = "Esprit encha�n�"
					elseif GameLocale == "itIT" then chainLoc = "Spirito Incatenato"
					end
					if arg1 == chainLoc then return	end

					-- Resurrect
					local resTimer = GetCorpseRecoveryDelay()
					if resTimer and resTimer > 0 then
						-- Resurrect has a delay so wait before resurrecting
						C_Timer.After(resTimer + 1, function()
							if not UnitAffectingCombat(arg1) or RGXQoLLC["AutoResNoCombat"] == "Off" then
								if RGXQoLLC["AutoAcceptRes"] == "On" then
									AcceptResurrect()
									StaticPopup_Hide("RESURRECT_NO_TIMER")
								end
							end
						end)
					else
						-- Resurrect has no delay so resurrect now
						if not UnitAffectingCombat(arg1) or RGXQoLLC["AutoResNoCombat"] == "Off" then
							AcceptResurrect()
							StaticPopup_Hide("RESURRECT_NO_TIMER")
						end
					end

					return

				end
			end)

		end

		----------------------------------------------------------------------
		-- Automatically release in battlegrounds
		----------------------------------------------------------------------

		do

			-- Release in battlegrounds
			SafeHookSecure("StaticPopup_Show", function(sType)
				if sType and sType == "DEATH" and RGXQoLLC["AutoReleasePvP"] == "On" then
					if C_DeathInfo.GetSelfResurrectOptions() and #C_DeathInfo.GetSelfResurrectOptions() > 0 then return end
					local InstStat, InstType = IsInInstance()
					if InstStat and InstType == "pvp" then
						-- Exclude specific maps
						local mapID = C_Map.GetBestMapForUnit("player") or nil
						if mapID then
							if mapID == 1459 and RGXQoLLC["AutoReleaseNoAlterac"] == "On" then return end -- Alterac Valley
						end
						-- Release automatically
						local delay = RGXQoLLC["AutoReleaseDelay"] / 1000
						C_Timer.After(delay, function()
							local dialog = StaticPopup_Visible("DEATH")
							if dialog then
								if IsShiftKeyDown() then
									ActionStatus_DisplayMessage(L["Automatic Release Cancelled"], true)
								else
									StaticPopup_OnClick(_G[dialog], 1)
								end
							end
						end)
					end
				end
			end)

		end

		----------------------------------------------------------------------
		--	Minimap button (framework module)
		----------------------------------------------------------------------

		do

			-- Framework minimap button; left-click opens the options panel
			local MM = _G.RGXFramework and _G.RGXFramework.GetMinimap and _G.RGXFramework:GetMinimap()
			if MM and not RGXQoLLC.minimapButton then
				RGXQoLLC.minimapButton = MM:Create({
					name = "RGXQoL_MinimapButton",
					icon = "Interface\\AddOns\\RGX-Framework\\media\\logo.tga",
					defaultAngle = 220,
					storage = RGXQoLDB,
					angleKey = "minimapAngle",
					tooltip = {
						title = "|cff8B1538RGX|r |cffffffffQoL|r",
						lines = {
							{ left = "|cff8B1538Left-Click|r", right = "|cffffffffOpen options|r" },
							{ left = "|cff4ecdc4Left-Drag|r", right = "|cffffffffMove around minimap|r" },
							{ left = "|cffe74c3cCtrl+Right-Click|r", right = "|cffffffffHide minimap icon|r" },
						},
					},
					onLeftClick = function() if OpenOptionsShared then OpenOptionsShared() end end,
					onCtrlRight = function(btn)
						btn:SetVisible(false)
						RGXQoLLC["ShowMinimapIcon"] = "Off"
					end,
				})
			end

			-- Bridge the visibility toggle and apply it
			RGXQoLLC.FeatureSetup.ShowMinimapIcon = function()
				if RGXQoLLC.minimapButton then
					RGXQoLLC.minimapButton:SetVisible(RGXQoLLC["ShowMinimapIcon"] == "On")
				end
			end
			RGXQoLLC.FeatureSetup.ShowMinimapIcon()

		end

		-- Auction House Extras
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Final code for Player
		----------------------------------------------------------------------

		-- Show first run message
		if not RGXQoLDB["FirstRunMessageSeen"] then
			C_Timer.After(1, function()
				RGXQoLLC:Print(L["Enter"] .. " |cff00ff00" .. "/qol" .. "|r " .. L["or click the minimap button to open RGX QoL Plus."])
				RGXQoLDB["FirstRunMessageSeen"] = true
			end)
		end

		-- Register logout event to save settings
		RGXQoLEvt:RegisterEvent("PLAYER_LOGOUT")

		-- Update addon memory usage (speeds up initial value)
		UpdateAddOnMemoryUsage()

		-- Release memory
		RGXQoLLC.Player = nil

	end

----------------------------------------------------------------------
-- 	L60: Default events
----------------------------------------------------------------------

	local function eventHandler(self, event, arg1, arg2, ...)

		----------------------------------------------------------------------
		-- L62: Profile events
		----------------------------------------------------------------------

		if event == "ADDON_LOADED" then
			if arg1 == "RGXQoL" then

				-- Replace old var names with new ones
				local function UpdateVars(oldvar, newvar)
					if RGXQoLDB[oldvar] and not RGXQoLDB[newvar] then RGXQoLDB[newvar] = RGXQoLDB[oldvar]; RGXQoLDB[oldvar] = nil end
				end

				UpdateVars("MuteStriders", "MuteMechSteps")					-- 1.14.45 (1st June 2022)

				-- Mute game sounds split with Mute mount sounds

				-- Automation
				RGXQoLLC:LoadVarChk("AutomateQuests", "Off")				-- Automate quests
				RGXQoLLC:LoadVarChk("AutoQuestShift", "Off")				-- Automate quests requires shift
				RGXQoLLC:LoadVarChk("AutoQuestAvailable", "On")			-- Accept available quests
				RGXQoLLC:LoadVarChk("AutoQuestCompleted", "On")			-- Turn-in completed quests
				RGXQoLLC:LoadVarNum("AutoQuestKeyMenu", 1, 1, 4)			-- Automate quests override key
				RGXQoLLC:LoadVarChk("AutomateGossip", "Off")				-- Automate gossip
				RGXQoLLC:LoadVarChk("AutoAcceptSummon", "Off")				-- Accept summon
				RGXQoLLC:LoadVarChk("AutoAcceptRes", "Off")				-- Accept resurrection
				RGXQoLLC:LoadVarChk("AutoResNoCombat", "On")				-- Accept resurrection exclude combat
				RGXQoLLC:LoadVarChk("AutoReleasePvP", "Off")				-- Release in PvP
				RGXQoLLC:LoadVarChk("AutoReleaseNoAlterac", "Off")			-- Release in PvP Exclude Alterac Valley
				RGXQoLLC:LoadVarNum("AutoReleaseDelay", 200, 200, 3000)	-- Release in PvP Delay

				RGXQoLLC:LoadVarChk("AutoSellJunk", "Off")					-- Sell junk automatically
				RGXQoLLC:LoadVarChk("AutoSellShowSummary", "On")			-- Sell junk summary in chat
				RGXQoLLC:LoadVarStr("AutoSellExcludeList", "")				-- Sell junk exclude list
				RGXQoLLC:LoadVarChk("AutoRepairGear", "Off")				-- Repair automatically
				RGXQoLLC:LoadVarChk("AutoRepairShowSummary", "On")			-- Repair show summary in chat

				-- Settings
				RGXQoLLC:LoadVarChk("ShowMinimapIcon", "On")				-- Show minimap button
				RGXQoLLC:LoadVarChk("UseEnglishLanguage", "Off")			-- Use English language



				-- Build the framework options page and sync the boolean bridge
				RGXQoLLC:BuildOptionsCanvas()
			end
			return
		end

		if event == "PLAYER_LOGIN" then
			RGXQoLLC:Player()


			collectgarbage()
			return
		end

		-- Save locals back to globals on logout
		if event == "PLAYER_LOGOUT" then

			-- Run the logout function without wipe flag
			RGXQoLLC:PlayerLogout(false)

			-- Automation
			RGXQoLDB["AutomateQuests"]			= RGXQoLLC["AutomateQuests"]
			RGXQoLDB["AutoQuestShift"]			= RGXQoLLC["AutoQuestShift"]
			RGXQoLDB["AutoQuestAvailable"]		= RGXQoLLC["AutoQuestAvailable"]
			RGXQoLDB["AutoQuestCompleted"]		= RGXQoLLC["AutoQuestCompleted"]
			RGXQoLDB["AutoQuestKeyMenu"]		= RGXQoLLC["AutoQuestKeyMenu"]
			RGXQoLDB["AutomateGossip"]			= RGXQoLLC["AutomateGossip"]
			RGXQoLDB["AutoAcceptSummon"] 		= RGXQoLLC["AutoAcceptSummon"]
			RGXQoLDB["AutoAcceptRes"] 			= RGXQoLLC["AutoAcceptRes"]
			RGXQoLDB["AutoResNoCombat"] 		= RGXQoLLC["AutoResNoCombat"]
			RGXQoLDB["AutoReleasePvP"] 		= RGXQoLLC["AutoReleasePvP"]
			RGXQoLDB["AutoReleaseNoAlterac"] 	= RGXQoLLC["AutoReleaseNoAlterac"]
			RGXQoLDB["AutoReleaseDelay"] 		= RGXQoLLC["AutoReleaseDelay"]

			RGXQoLDB["AutoSellJunk"] 			= RGXQoLLC["AutoSellJunk"]
			RGXQoLDB["AutoSellShowSummary"] 	= RGXQoLLC["AutoSellShowSummary"]
			RGXQoLDB["AutoSellExcludeList"] 	= RGXQoLLC["AutoSellExcludeList"]
			RGXQoLDB["AutoRepairGear"] 		= RGXQoLLC["AutoRepairGear"]
			RGXQoLDB["AutoRepairShowSummary"] 	= RGXQoLLC["AutoRepairShowSummary"]

			-- Settings
			RGXQoLDB["ShowMinimapIcon"] 		= RGXQoLLC["ShowMinimapIcon"]
			RGXQoLDB["UseEnglishLanguage"] 	= RGXQoLLC["UseEnglishLanguage"]




		end

	end

--	Register event handler
	RGXQoLEvt:SetScript("OnEvent", eventHandler);

----------------------------------------------------------------------
--	L70: Player logout
----------------------------------------------------------------------

	-- Player Logout
	function RGXQoLLC:PlayerLogout(wipe)

		----------------------------------------------------------------------
		-- Restore default values for options that do not require reloads
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Restore default values for options that require reloads
		----------------------------------------------------------------------

		-- Enhance minimap restore round minimap if wipe or enhance minimap is toggled off

		-- Silence rested emotes

		-- Show free bag slos

		----------------------------------------------------------------------
		-- Do other stuff during logout
		----------------------------------------------------------------------

		-- Store the auction house duration and price type values if auction house option is enabled

	end

----------------------------------------------------------------------
-- 	Options panel functions
----------------------------------------------------------------------
	function RGXQoLLC:GetAddonVersion()
		if C_AddOns and C_AddOns.GetAddOnMetadata then
			local ok, v = pcall(C_AddOns.GetAddOnMetadata, "RGXQoL", "Version")
			if ok and v and v ~= "" then return v end
		end
		return RGXQoLLC["AddonVer"]
	end

----------------------------------------------------------------------
-- 	L80: Commands
----------------------------------------------------------------------

	-- Slash command function
	function RGXQoLLC:SlashFunc(str)
		if str and str ~= "" then
			-- Get parameters in lower case with duplicate spaces removed
			local str, arg1, arg2, arg3 = strsplit(" ", string.lower(str:gsub("%s+", " ")))
			-- Traverse parameters
			if str == "wipe" then
				-- Wipe settings
				RGXQoLLC:PlayerLogout(true) -- Run logout function with wipe parameter
				wipe(RGXQoLDB)
				RGXQoLEvt:UnregisterAllEvents(); -- Don't save any settings
				ReloadUI();
			elseif str == "nosave" then
				-- Prevent RGX QoL from overwriting RGXQoLDB at next logout
				RGXQoLEvt:UnregisterEvent("PLAYER_LOGOUT")
				RGXQoLLC:Print("RGX QoL will not overwrite RGXQoLDB at next logout.")
				return
			elseif str == "reset" then
				-- Panel preferences are framework-managed now; nothing position/scale to reset
				RGXQoLLC:Print("The options panel is hosted in the game settings window; there is no panel position to reset. Use /qol wipe to reset all settings.")
				return
			elseif str == "taint" then
				-- Set taint log level
				if arg1 and arg1 ~= "" then
					arg1 = tonumber(arg1)
					if arg1 and arg1 >= 0 and arg1 <= 2 then
						if arg1 == 0 then
							-- Disable taint log
							ConsoleExec("taintLog 0")
							RGXQoLLC:Print("Taint level: Disabled (0).")
						elseif arg1 == 1 then
							-- Basic taint log
							ConsoleExec("taintLog 1")
							RGXQoLLC:Print("Taint level: Basic (1).")
						elseif arg1 == 2 then
							-- Full taint log
							ConsoleExec("taintLog 2")
							RGXQoLLC:Print("Taint level: Full (2).")
						end
					else
						RGXQoLLC:Print("Invalid taint level.")
					end
				else
					-- Show current taint level
					local taintCurrent = GetCVar("taintLog")
					if taintCurrent == "0" then
						RGXQoLLC:Print("Taint level: Disabled (0).")
					elseif taintCurrent == "1" then
						RGXQoLLC:Print("Taint level: Basic (1).")
					elseif taintCurrent == "2" then
						RGXQoLLC:Print("Taint level: Full (2).")
					end
				end
				return
			elseif str == "quest" then
				-- Show quest completed status
				if arg1 and arg1 ~= "" then
					if arg1 == "wipe" then
						-- Wipe quest log
						return
					elseif tonumber(arg1) and tonumber(arg1) < 999999999 then
						-- Show quest information
						local questCompleted = C_QuestLog.IsQuestFlaggedCompleted(arg1)
						local questTitle = C_QuestLog.GetQuestInfo(arg1) or L["Unknown"]
						C_Timer.After(0.5, function()
							local questTitle = C_QuestLog.GetQuestInfo(arg1) or L["Unknown"]
							if questCompleted then
								RGXQoLLC:Print(questTitle .. " (" .. arg1 .. "):" .. "|cffffffff " .. L["Completed."])
							else
								RGXQoLLC:Print(questTitle .. " (" .. arg1 .. "):" .. "|cffffffff " .. L["Not completed."])
							end
						end)
					else
						RGXQoLLC:Print("Invalid quest ID.")
					end
				else
					RGXQoLLC:Print("Missing quest ID.")
				end
				return
			elseif str == "rest" then
				-- Show rested bubbles
				RGXQoLLC:Print(L["Rested bubbles"] .. ": |cffffffff" .. (math.floor(20 * (GetXPExhaustion() or 0) / UnitXPMax("player") + 0.5)))
				return
			elseif str == "zygor" then
				-- Toggle Zygor addon
				RGXQoLLC:ZygorToggle()
				return
			elseif str == "npcid" then
				-- Print NPC ID
				local npcName = UnitName("target")
				local npcGuid = UnitGUID("target") or nil
				if npcName and npcGuid then
					local void, void, void, void, void, npcID = strsplit("-", npcGuid)
					if npcID then
						RGXQoLLC:Print(npcName .. ": |cffffffff" .. npcID)
					end
				end
				return
			elseif str == "id" then
				-- Show web link
				-- Store frame under mouse
				local mouseFocus = GetMouseFoci()[1]
				-- ItemRefTooltip or GameTooltip
				local tooltip
				if ItemRefTooltip:IsMouseMotionFocus() then tooltip = ItemRefTooltip else tooltip = GameTooltip end
				-- Process tooltip
				if tooltip:IsShown() then
					-- Item
					local void, itemLink = tooltip:GetItem()
					if itemLink then
						local itemID = GetItemInfoFromHyperlink(itemLink)
						if itemID then
							RGXQoLLC.FactoryEditBox.f:SetText(L["Item"] .. ": " .. itemLink .. " (" .. itemID .. ")")
							return
						end
					end
					-- Spell
					local name, spellID = tooltip:GetSpell()
					if name and spellID then
						RGXQoLLC.FactoryEditBox.f:SetText(L["Spell"] .. ": " .. name .. " (" .. spellID .. ")")
						return
					end
					-- NPC
					local npcName = UnitName("mouseover")
					local npcGuid = UnitGUID("mouseover") or nil
					if npcName and npcGuid then
						local void, void, void, void, void, npcID = strsplit("-", npcGuid)
						if npcID then
							RGXQoLLC.FactoryEditBox.f:SetText(L["NPC"] .. ": " .. npcName .. " (" .. npcID .. ")")
							return
						end
					end
					-- Buffs and debuffs
					for i = 1, BUFF_MAX_DISPLAY do
						if _G["BuffButton" .. i] and mouseFocus == _G["BuffButton" .. i] then
							local BuffData = C_UnitAuras.GetBuffDataByIndex("player", i)
							if BuffData then
								local spellName = BuffData.name
								local spellID = BuffData.spellId
								if spellName and spellID then
									RGXQoLLC.FactoryEditBox.f:SetText(L["Spell"] .. ": " .. spellName .. " (" .. spellID .. ")")
								end
							end
							return
						end
					end
					for i = 1, DEBUFF_MAX_DISPLAY do
						if _G["DebuffButton" .. i] and mouseFocus == _G["DebuffButton" .. i] then
							local DebuffData = C_UnitAuras.GetDebuffDataByIndex("player", i)
							if DebuffData then
								local spellName = DebuffData.name
								local spellID = DebuffData.spellId
								if spellName and spellID then
									RGXQoLLC.FactoryEditBox.f:SetText(L["Spell"] .. ": " .. spellName .. " (" .. spellID .. ")")
								end
							end
							return
						end
					end
					-- Unknown tooltip (this must be last)
					local tipTitle = GameTooltipTextLeft1:GetText()
					if tipTitle then
						-- Show unknown link
						local unitFocus
						if mouseFocus == WorldFrame then unitFocus = "mouseover" else unitFocus = select(2, GameTooltip:GetUnit()) end
						if not unitFocus or not UnitIsPlayer(unitFocus) then
							tipTitle = tipTitle:gsub("|c%x%x%x%x%x%x%x%x", "") -- Remove color tag
							return
						end
					end
				end
				return
			elseif str == "tooltip" then
				-- Print tooltip frame name
				pcall(function()
					local enumf = EnumerateFrames()
					while enumf do
						if (enumf:GetObjectType() == "GameTooltip" or strfind((enumf:GetName() or ""):lower(),"tip")) and enumf:IsVisible() and enumf:GetPoint() then
							print(enumf:GetName())
						end
						enumf = EnumerateFrames(enumf)
					end
					collectgarbage()
					return
				end)
			elseif str == "rsnd" then
				-- Restart sound system
				Sound_GameSystem_RestartSoundSystem()
				RGXQoLLC:Print("Sound system restarted.")
				return
			elseif str == "event" then
				-- List events (used for debug)
				RGXQoLLC["DbF"] = RGXQoLLC["DbF"] or CreateFrame("FRAME")
				if not RGXQoLLC["DbF"]:GetScript("OnEvent") then
					RGXQoLLC:Print("Tracing started.")
					RGXQoLLC["DbF"]:RegisterAllEvents()
					RGXQoLLC["DbF"]:SetScript("OnEvent", function(self, event)
						if event == "ACTIONBAR_UPDATE_COOLDOWN"
						or event == "BAG_UPDATE_COOLDOWN"
						or event == "CHAT_MSG_TRADESKILLS"
						or event == "COMBAT_LOG_EVENT_UNFILTERED"
						or event == "SPELL_UPDATE_COOLDOWN"
						or event == "SPELL_UPDATE_USABLE"
						or event == "UNIT_POWER_FREQUENT"
						or event == "UPDATE_INVENTORY_DURABILITY"
						then return
						else
							print(event)
						end
					end)
				else
					RGXQoLLC["DbF"]:UnregisterAllEvents()
					RGXQoLLC["DbF"]:SetScript("OnEvent", nil)
					RGXQoLLC:Print("Tracing stopped.")
				end
				return
			elseif str == "game" then
				-- Show game build
				local version, build, gdate, tocversion = GetBuildInfo()
				RGXQoLLC:Print(L["World of Warcraft"] .. ": |cffffffff" .. version .. "." .. build .. " (" .. gdate .. ") (" .. tocversion .. ")")
				return
			elseif str == "config" then
				-- Show maximum camera distance
				RGXQoLLC:Print(L["Camera distance"] .. ": |cffffffff" .. GetCVar("cameraDistanceMaxZoomFactor"))
				-- Show screen effects
				-- Show particle density
				RGXQoLLC:Print(L["Particle density"] .. ": |cffffffff" .. GetCVar("particleDensity"))
				RGXQoLLC:Print(L["Weather density"] .. ": |cffffffff" .. GetCVar("weatherDensity"))
				-- Show config
				RGXQoLLC:Print("SynchroniseConfig: |cffffffff" .. GetCVar("synchronizeConfig"))
				-- Show raid restrictions
				local unRaid = GetAllowLowLevelRaid()
				if unRaid and unRaid == true then
					RGXQoLLC:Print("GetAllowLowLevelRaid: |cffffffff" .. "True")
				else
					RGXQoLLC:Print("GetAllowLowLevelRaid: |cffffffff" .. "False")
				end
				return
			elseif str == "tipcol" then
				-- Show default tooltip title color
				if GameTooltipTextLeft1:IsShown() then
					local r, g, b, a = GameTooltipTextLeft1:GetTextColor()
					r = r <= 1 and r >= 0 and r or 0
					g = g <= 1 and g >= 0 and g or 0
					b = b <= 1 and b >= 0 and b or 0
					RGXQoLLC:Print(L["Tooltip title color"] .. ": " .. strupper(string.format("%02x%02x%02x", r * 255, g * 255, b * 255) .. "."))
				else
					RGXQoLLC:Print("No tooltip showing.")
				end
				return
			elseif str == "list" then
				-- Enumerate frames
				local frame = EnumerateFrames()
				while frame do
					if (frame:IsVisible() and MouseIsOver(frame)) then
						RGXQoLLC:Print(frame:GetName() or string.format("[Unnamed Frame: %s]", tostring(frame)))
					end
					frame = EnumerateFrames(frame)
				end
				return
			elseif str == "grid" then
				-- Toggle frame alignment grid
				return
			elseif str == "chk" then
				-- List truncated checkbox labels
				if RGXQoLLC["TruncatedLabelsList"] then
					for i, v in pairs(RGXQoLLC["TruncatedLabelsList"]) do
						RGXQoLLC:Print(RGXQoLLC["TruncatedLabelsList"][i])
					end
				else
					RGXQoLLC:Print("Checkbox labels are Ok.")
				end
				return
			elseif str == "cv" then
				-- Print and set console variable setting
				if arg1 and arg1 ~= "" then
					if GetCVar(arg1) then
						if arg2 and arg2 ~= ""  then
							if tonumber(arg2) then
								SetCVar(arg1, arg2)
							else
								RGXQoLLC:Print("Value must be a number.")
								return
							end
						end
						RGXQoLLC:Print(arg1 .. ": |cffffffff" .. GetCVar(arg1))
					else
						RGXQoLLC:Print("Invalid console variable.")
					end
				else
					RGXQoLLC:Print("Missing console variable.")
				end
				return
			elseif str == "play" then
				-- Play sound ID
				if arg1 and arg1 ~= "" then
					if tonumber(arg1) then
						-- Stop last played sound ID
						if RGXQoLLC.SNDcanitHandle then
							StopSound(RGXQoLLC.SNDcanitHandle)
						end
						-- Play sound ID
						RGXQoLLC.SNDcanitPlay, RGXQoLLC.SNDcanitHandle = PlaySound(arg1, "Master", false, false)
						if not RGXQoLLC.SNDcanitPlay then RGXQoLLC:Print(L["Invalid sound ID"] .. ": |cffffffff" .. arg1) end
					else
						RGXQoLLC:Print(L["Invalid sound ID"] .. ": |cffffffff" .. arg1)
					end
				else
					RGXQoLLC:Print("Missing sound ID.")
				end
				return
			elseif str == "stop" then
				-- Stop last played sound ID
				if RGXQoLLC.SNDcanitHandle then
					StopSound(RGXQoLLC.SNDcanitHandle)
				end
				return
			elseif str == "wipecds" then
				-- Wipe cooldowns
				ReloadUI()
				return
			elseif str == "tipchat" then
				-- Print tooltip contents in chat
				local numLines = GameTooltip:NumLines()
				if numLines then
					for i = 1, numLines do
						print(_G["GameTooltipTextLeft" .. i]:GetText() or "")
					end
				end
				return
			elseif str == "tiplang" then
				-- Tooltip tag locale code constructor
				local msg = ""
				msg = msg .. 'if GameLocale == "' .. GameLocale .. '" then '
				msg = msg .. 'ttLevel = "' .. LEVEL .. '"; '
				msg = msg .. 'ttBoss = "' .. BOSS .. '"; '
				msg = msg .. 'ttElite = "' .. ELITE .. '"; '
				msg = msg .. 'ttRare = "' .. ITEM_QUALITY3_DESC .. '"; '
				msg = msg .. 'ttRareElite = "' .. ITEM_QUALITY3_DESC .. " " .. ELITE .. '"; '
				msg = msg .. 'ttRareBoss = "' .. ITEM_QUALITY3_DESC .. " " .. BOSS .. '"; '
				msg = msg .. 'ttTarget = "' .. TARGET .. '"; '
				msg = msg .. "end"
				print(msg)
				return
			elseif str == "con" then
				-- Show the developer console
				DeveloperConsole:SetFontHeight(28)
				DeveloperConsole:Toggle(true)
				return
			elseif str == "movie" then
				-- Playback movie by ID
				arg1 = tonumber(arg1)
				if arg1 and arg1 ~= "" then
					-- Play movie by ID
					if IsMoviePlayable(arg1) then
						MovieFrame_PlayMovie(MovieFrame, arg1)
					else
						RGXQoLLC:Print("Movie not playable.")
					end
				else
					-- List playable movie IDs
					local count = 0
					for i = 1, 1000 do
						if IsMoviePlayable(i) then
							print(i)
							count = count + 1
						end
					end
					RGXQoLLC:Print("Total movies: |cffffffff" .. count)
				end
				return
			elseif str == "cin" then
				-- Play opening cinematic (only works if character has never gained XP) (used for testing)
				OpeningCinematic()
				return
			elseif str == "skit" then
				-- Play a test sound kit
				PlaySound("1020", "Master", false, true)
				return
			elseif str == "marker" then
				-- Prevent showing raid target markers on self
				if not RGXQoLLC.MarkerFrame then
					RGXQoLLC.MarkerFrame = CreateFrame("FRAME")
					RGXQoLLC.MarkerFrame:RegisterEvent("RAID_TARGET_UPDATE")
				end
				RGXQoLLC.MarkerFrame.Update = true
				if RGXQoLLC.MarkerFrame.Toggle == false then
					-- Show markers
					RGXQoLLC.MarkerFrame:SetScript("OnEvent", nil)
					ActionStatus_DisplayMessage(L["Self Markers Allowed"], true)
					RGXQoLLC.MarkerFrame.Toggle = true
				else
					-- Hide markers
					SetRaidTarget("player", 0)
					RGXQoLLC.MarkerFrame:SetScript("OnEvent", function()
						if RGXQoLLC.MarkerFrame.Update == true then
							RGXQoLLC.MarkerFrame.Update = false
							SetRaidTarget("player", 0)
						end
						RGXQoLLC.MarkerFrame.Update = true
					end)
					ActionStatus_DisplayMessage(L["Self Markers Blocked"], true)
					RGXQoLLC.MarkerFrame.Toggle = false
				end
				return
			elseif str == "af" then
				-- Automatically follow player target using ticker
				if RGXQoLLC.followTick then
					-- Existing ticker is active so cancel it
					RGXQoLLC.followTick:Cancel()
					RGXQoLLC.followTick = nil
					FollowUnit("player")
					RGXQoLLC:Print("AutoFollow disabled.")
				else
					-- No ticker is active so create one
					local targetName, targetRealm = UnitName("target")
					if not targetName or not UnitIsPlayer("target") or UnitIsUnit("player", "target") then
						RGXQoLLC:Print("Invalid target.")
						return
					end
					if targetRealm then targetName = targetName .. "-" .. targetRealm end
					if RGXQoLLC.followTick then
						RGXQoLLC.followTick:Cancel()
					end
					FollowUnit(targetName, true)
					RGXQoLLC.followTick = C_Timer.NewTicker(0.5, function()
						FollowUnit(targetName, true)
					end)
					RGXQoLLC:Print(L["AutoFollow"] .. ": |cffffffff" .. targetName .. "|r.")
				end
				return
			elseif str == "mapid" then
				-- Print map ID
				if WorldMapFrame:IsShown() then
					-- Show world map ID
					local mapID = WorldMapFrame.mapID or nil
					local artID = C_Map.GetMapArtID(mapID) or nil
					local mapName = C_Map.GetMapInfo(mapID).name or nil
					if mapID and artID and mapName then
						RGXQoLLC:Print(mapID .. " (" .. artID .. "): " .. mapName .. " (map)")
					end
				else
					-- Show character map ID
					local mapID = C_Map.GetBestMapForUnit("player") or nil
					local artID = C_Map.GetMapArtID(mapID) or nil
					local mapName = C_Map.GetMapInfo(mapID).name or nil
					if mapID and artID and mapName then
						RGXQoLLC:Print(mapID .. " (" .. artID .. "): " .. mapName .. " (player)")
					end
				end
				return
			elseif str == "pos" then
				-- Map POI code builder
				local mapID = C_Map.GetBestMapForUnit("player") or nil
				local mapName = C_Map.GetMapInfo(mapID).name or nil
				local mapRects = {}
				local tempVec2D = CreateVector2D(0, 0)
				local void
				-- Get player map position
				tempVec2D.x, tempVec2D.y = UnitPosition("player")
				if not tempVec2D.x then return end
				local mapRect = mapRects[mapID]
				if not mapRect then
					mapRect = {}
					void, mapRect[1] = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0))
					void, mapRect[2] = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(1, 1))
					mapRect[2]:Subtract(mapRect[1])
					mapRects[mapID] = mapRect
				end
				tempVec2D:Subtract(mapRects[mapID][1])
				local pX, pY = tempVec2D.y/mapRects[mapID][2].y, tempVec2D.x/mapRects[mapID][2].x
				pX = string.format("%0.1f", 100 * pX)
				pY = string.format("%0.1f", 100 * pY)
				if mapID and mapName and pX and pY then
					ChatFrame1:Clear()
					local dnType, dnTex = "Dungeon", "dnTex"
					if arg1 == "raid" then dnType, dnTex = "Raid", "rdTex" end
					if arg1 == "portal" then dnType = "Portal" end
					print('[' .. mapID .. '] =  --[[' .. mapName .. ']] {{' .. pX .. ', ' .. pY .. ', L[' .. '"Name"' .. '], L[' .. '"' .. dnType .. '"' .. '], ' .. dnTex .. '},},')
				end
				return
			elseif str == "mapref" then
				-- Print map reveal structure code
				if not WorldMapFrame:IsShown() then
					RGXQoLLC:Print("Open the map first!")
					return
				end
				ChatFrame1:Clear()
				local msg = ""
				local mapID = WorldMapFrame.mapID
				local mapName = C_Map.GetMapInfo(mapID).name
				local mapArt = C_Map.GetMapArtID(mapID)
				msg = msg .. "--[[" .. mapName .. "]] [" .. mapArt .. "] = {"
				local exploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures(mapID);
				if exploredMapTextures then
					for i, exploredTextureInfo in ipairs(exploredMapTextures) do
						local twidth = exploredTextureInfo.textureWidth or 0
						if twidth > 0 then
							local theight = exploredTextureInfo.textureHeight or 0
							local offsetx = exploredTextureInfo.offsetX
							local offsety = exploredTextureInfo.offsetY
							local filedataIDS = exploredTextureInfo.fileDataIDs
							msg = msg .. "[" .. '"' .. twidth .. ":" .. theight .. ":" .. offsetx .. ":" .. offsety .. '"' .. "] = " .. '"'
							for fileData = 1, #filedataIDS do
								msg = msg .. filedataIDS[fileData]
								if fileData < #filedataIDS then
									msg = msg .. ", "
								else
									msg = msg .. '",'
									if i < #exploredMapTextures then
										msg = msg .. " "
									end
								end
							end
						end
					end
					msg = msg .. "},"
					print(msg)
				end
				return
			elseif str == "mk" then
				-- Print a map key
				if not arg1 then RGXQoLLC:Print("Key missing!") return end
				if not tonumber(arg1) then RGXQoLLC:Print("Must be a number!") return end
				local key = arg1
				ChatFrame1:Clear()
				print('"' .. mod(floor(key / 2^36), 2^12) .. ":" .. mod(floor(key / 2^24), 2^12) .. ":" .. mod(floor(key / 2^12), 2^12) .. ":" .. mod(key, 2^12) .. '"')
				return
			elseif str == "map" then
				-- Set map by ID, print currently showing map ID or print character map ID
				if not arg1 then
					-- Print map ID
					if WorldMapFrame:IsShown() then
						-- Show world map ID
						local mapID = WorldMapFrame.mapID or nil
						local artID = C_Map.GetMapArtID(mapID) or nil
						local mapName = C_Map.GetMapInfo(mapID).name or nil
						if mapID and artID and mapName then
							RGXQoLLC:Print(mapID .. " (" .. artID .. "): " .. mapName .. " (map)")
						end
					else
						-- Show character map ID
						local mapID = C_Map.GetBestMapForUnit("player") or nil
						local artID = C_Map.GetMapArtID(mapID) or nil
						local mapName = C_Map.GetMapInfo(mapID).name or nil
						if mapID and artID and mapName then
							RGXQoLLC:Print(mapID .. " (" .. artID .. "): " .. mapName .. " (player)")
						end
					end
					return
				elseif not tonumber(arg1) or not C_Map.GetMapInfo(arg1) then
					-- Invalid map ID
					RGXQoLLC:Print("Invalid map ID.")
				else
					-- Set map by ID
					WorldMapFrame:SetMapID(tonumber(arg1))
				end
				return
			elseif str == "cls" then
				-- Clear chat frame
				ChatFrame1:Clear()
				return
			elseif str == "al" then
				-- Enable auto loot
				SetCVar("autoLootDefault", "1")
				RGXQoLLC:Print("Auto loot is now enabled.")
				return
			elseif str == "realm" then
				-- Show list of connected realms
				local titleRealm = GetRealmName()
				local userRealm = GetNormalizedRealmName()
				local connectedServers = GetAutoCompleteRealms()
				if titleRealm and userRealm and connectedServers then
					RGXQoLLC:Print(L["Connections for"] .. "|cffffffff " .. titleRealm)
					if #connectedServers > 0 then
						local count = 1
						for i = 1, #connectedServers do
							if userRealm ~= connectedServers[i] then
								RGXQoLLC:Print(count .. ".  " .. connectedServers[i])
								count = count + 1
							end
						end
					else
						RGXQoLLC:Print("None")
					end
				end
				return
			elseif str == "dup" then
				-- Print music track duplicates
				local found
				for i, e in pairs(RGXQoLAddon["ZoneList"]) do
					if RGXQoLAddon["ZoneList"][e] then
						for a, b in pairs(RGXQoLAddon["ZoneList"][e]) do
							local same = {}
							if b.tracks then
								for k, v in pairs(b.tracks) do
									if not strfind(v, "|c") then
										if tContains(same, v) then
											found = true
											print("|cffec51ff" .. L["Dup"] .. ": |r" .. e .. ": " .. b.zone .. ":", v)
										end
										tinsert(same, v)
									end
								end
							end
						end
					end
				end
				if not found then
					RGXQoLLC:Print("No media duplicates found.")
				end
				return
			elseif str == "help" then
				-- Command list (chat output; legacy help window removed with the old UI)
				local color1 = "|cffffffaa"
				RGXQoLLC:Print(color1 .. "/qol|r Toggle options panel")
				RGXQoLLC:Print(color1 .. "/qol wipe|r Wipe all addon settings (reloads UI)")
				RGXQoLLC:Print(color1 .. "/qol realm|r Show realms connected to yours")
				RGXQoLLC:Print(color1 .. "/qol rest|r Show number of rested XP bubbles remaining")
				RGXQoLLC:Print(color1 .. "/qol quest <id>|r Show quest completion status")
				RGXQoLLC:Print(color1 .. "/qol grid|r Toggle frame alignment grid")
				RGXQoLLC:Print(color1 .. "/qol id|r Print NPC ID")
				RGXQoLLC:Print(color1 .. "/qol zygor|r Toggle the Zygor addon (reloads UI)")
				RGXQoLLC:Print(color1 .. "/qol movie <id>|r Play a movie by its ID")
				RGXQoLLC:Print(color1 .. "/qol marker|r Block target markers (toggle)")
				RGXQoLLC:Print(color1 .. "/qol rsnd|r Restart the sound system")
				RGXQoLLC:Print(color1 .. "/qol ra|r Announce target in chat (rares)")
				RGXQoLLC:Print(color1 .. "/qol con|r Launch the developer console")
				RGXQoLLC:Print(color1 .. "/rl|r Reload the UI")
				return
			elseif str == "ra" then
				-- Announce target name, health percentage, coordinates and map pin link in General chat channel
				local genChannel
				if GameLocale == "deDE" 	then genChannel = "Allgemein"
				elseif GameLocale == "esMX" then genChannel = "General"
				elseif GameLocale == "esES" then genChannel = "General"
				elseif GameLocale == "frFR" then genChannel = "G�n�ral"
				elseif GameLocale == "itIT" then genChannel = "Generale"
				elseif GameLocale == "ptBR" then genChannel = "Geral"
				elseif GameLocale == "ruRU" then genChannel = "?????"
				elseif GameLocale == "koKR" then genChannel = "??"
				elseif GameLocale == "zhCN" then genChannel = "??"
				elseif GameLocale == "zhTW" then genChannel = "??"
				else							 genChannel = "General"
				end
				if genChannel then
					local index = GetChannelName(genChannel)
					if index and index > 0 then
						local mapID = C_Map.GetBestMapForUnit("player")
						local pos = C_Map.GetPlayerMapPosition(mapID, "player")
						if pos.x and pos.x ~= "0" and pos.y and pos.y ~= "0" then
							local uHealth = UnitHealth("target")
							local uHealthMax = UnitHealthMax("target")
							-- Announce in chat
							if uHealth and uHealth > 0 and uHealthMax and uHealthMax > 0 then
								-- Get unit classification (elite, rare, rare elite or boss)
								local unitType, unitTag = UnitClassification("target"), ""
								if unitType then
									if unitType == "rare" or unitType == "rareelite" then unitTag = "(" .. L["Rare"] .. ") " elseif unitType == "worldboss" then unitTag = "(" .. L["Boss"] .. ") " end
								end
								C_ChatInfo.SendChatMessage(format("%%t " .. unitTag .. "(%d%%)%s", uHealth / uHealthMax * 100, " " .. string.format("%.0f", pos.x * 100) .. ":" .. string.format("%.0f", pos.y * 100)), "CHANNEL", nil, index)
								-- C_ChatInfo.SendChatMessage(format("%%t " .. unitTag .. "(%d%%)%s", uHealth / uHealthMax * 100, " " .. string.format("%.0f", pos.x * 100) .. ":" .. string.format("%.0f", pos.y * 100)), "WHISPER", nil, GetUnitName("player")) -- Debug
							else
								RGXQoLLC:Print("Invalid target.")
							end
						else
							RGXQoLLC:Print("Cannot announce in this zone.")
						end
					else
						RGXQoLLC:Print("Cannot find General chat channel.")
					end
				end
				return
			elseif str == "perf" then
				-- Average FPS during combat
				local fTab = {}
				if not RGXQoLLC.perf then
					RGXQoLLC.perf = CreateFrame("FRAME")
				end
				local fFrm = RGXQoLLC.perf
				local k, startTime = 0, 0
				if fFrm:IsEventRegistered("PLAYER_REGEN_DISABLED") then
					fFrm:UnregisterAllEvents()
					fFrm:SetScript("OnUpdate", nil)
					RGXQoLLC:Print("PERF unloaded.")
				else
					fFrm:RegisterEvent("PLAYER_REGEN_DISABLED")
					fFrm:RegisterEvent("PLAYER_REGEN_ENABLED")
					RGXQoLLC:Print("Waiting for combat to start...")
				end
				fFrm:SetScript("OnEvent", function(self, event)
					if event == "PLAYER_REGEN_DISABLED" then
						RGXQoLLC:Print("Monitoring FPS during combat...")
						fFrm:SetScript("OnUpdate", function()
							k = k + 1
							fTab[k] = GetFramerate()
						end)
						startTime = GetTime()
					else
						fFrm:SetScript("OnUpdate", nil)
						local tSum = 0
						for i = 1, #fTab do
							tSum = tSum + fTab[i]
						end
						local timeTaken = string.format("%.0f", GetTime() - startTime)
						if tSum > 0 then
							RGXQoLLC:Print("Average FPS for " .. timeTaken .. " seconds of combat: " .. string.format("%.0f", tSum / #fTab))
						end
					end
				end)
				return
			elseif str == "col" then
				-- Convert color values
				RGXQoLLC:Print("|n")
				local r, g, b = tonumber(arg1), tonumber(arg2), tonumber(arg3)
				if r and g and b then
					-- RGB source
					RGXQoLLC:Print("Source: |cffffffff" .. r .. " " .. g .. " " .. b .. " ")
					-- RGB to Hex
					if r > 1 and g > 1 and b > 1 then
						-- RGB to Hex
						RGXQoLLC:Print("Hex: |cffffffff" .. strupper(string.format("%02x%02x%02x", r, g, b)) .. " (from RGB)")
					else
						-- Wow to Hex
						RGXQoLLC:Print("Hex: |cffffffff" .. strupper(string.format("%02x%02x%02x", r * 255, g * 255, b * 255)) .. " (from Wow)")
						-- Wow to RGB
						local rwow = string.format("%.0f", r * 255)
						local gwow = string.format("%.0f", g * 255)
						local bwow = string.format("%.0f", b * 255)
						if rwow ~= "0.0" and gwow ~= "0.0" and bwow ~= "0.0" then
							RGXQoLLC:Print("RGB: |cffffffff" .. rwow .. " " .. gwow .. " " .. bwow .. " (from Wow)")
						end
					end
					-- RGB to Wow
					local rwow = string.format("%.1f", r / 255)
					local gwow = string.format("%.1f", g / 255)
					local bwow = string.format("%.1f", b / 255)
					if rwow ~= "0.0" and gwow ~= "0.0" and bwow ~= "0.0" then
						RGXQoLLC:Print("Wow: |cffffffff" .. rwow .. " " .. gwow .. " " .. bwow)
					end
					RGXQoLLC:Print("|n")
				elseif arg1 and strlen(arg1) == 6 and strmatch(arg1,"%x") and arg2 == nil and arg3 == nil then
					-- Hex source
					local rhex, ghex, bhex = string.sub(arg1, 1, 2), string.sub(arg1, 3, 4), string.sub(arg1, 5, 6)
					if strmatch(rhex,"%x") and strmatch(ghex,"%x") and strmatch(bhex,"%x") then
						RGXQoLLC:Print("Source: |cffffffff" .. strupper(arg1))
						RGXQoLLC:Print("Wow: |cffffffff" .. string.format("%.1f", tonumber(rhex, 16) / 255) ..  "  " .. string.format("%.1f", tonumber(ghex, 16) / 255) .. "  " .. string.format("%.1f", tonumber(bhex, 16) / 255))
						RGXQoLLC:Print("RGB: |cffffffff" .. tonumber(rhex, 16) .. "  " .. tonumber(ghex, 16) .. "  " .. tonumber(bhex, 16))
					else
						RGXQoLLC:Print("Invalid arguments.")
					end
					RGXQoLLC:Print("|n")
				else
					RGXQoLLC:Print("Invalid arguments.")
				end
				return
			elseif str == "click" then
				-- Click a button (optional x number of times)
				local mouseFoci = GetMouseFoci()
				if mouseFoci then
					local frame = mouseFoci[#mouseFoci]
					local ftype = frame:GetObjectType()
					if frame and ftype and ftype == "Button" then
						if arg1 and tonumber(arg1) > 1 and tonumber(arg1) < 1000 then
							for i =1, tonumber(arg1) do C_Timer.After(0.1 * i, function() frame:Click() end) end
						else
							frame:Click()
						end
					else
						RGXQoLLC:Print("Hover the pointer over a button.")
					end
					return
				end
			elseif str == "frame" then
				-- Print frame name under mouse
				local mouseFoci = GetMouseFoci()
				if mouseFoci then
					local frame = mouseFoci[#mouseFoci]
					local ftype = frame:GetObjectType()
					if frame and ftype then
						local fname = frame:GetName()
						local issecure, tainted = issecurevariable(fname)
						if issecure then issecure = "Yes" else issecure = "No" end
						if tainted then tainted = "Yes" else tainted = "No" end
						if fname then
							RGXQoLLC:Print("Name: |cffffffff" .. fname)
							RGXQoLLC:Print("Type: |cffffffff" .. ftype)
							RGXQoLLC:Print("Secure: |cffffffff" .. issecure)
							RGXQoLLC:Print("Tainted: |cffffffff" .. tainted)
						end
					end
				end
				return
			elseif str == "arrow" then
				-- Arrow (left: drag, shift/ctrl: rotate, mouseup: loc, pointer must be on arrow stem)
				local f = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer)
				f:SetSize(64, 64)
				f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				f:SetFrameLevel(500)
				f:SetParent(WorldMapFrame.ScrollContainer)
				f:SetScale(0.6)

				f.t = f:CreateTexture(nil, "ARTWORK")
				f.t:SetAtlas("Garr_LevelUpgradeArrow")
				f.t:SetAllPoints()

				f.f = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
				f.f:SetText("0.0")

				local x = 0
				f:SetScript("OnUpdate", function()
					if IsShiftKeyDown() then
						x = x + 0.01
						if x > 6.3 then x = 0 end
						f.t:SetRotation(x)
						f.f:SetFormattedText("%.1f", x)
					elseif IsControlKeyDown() then
						x = x - 0.01
						if x < 0 then x = 6.3 end
						f.t:SetRotation(x)
						f.f:SetFormattedText("%.1f", x)
					end
					-- Print coordinates when mouse is in right place
					local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
					if x and y and x > 0 and y > 0 then
						if MouseIsOver(f, -31, 31, 31, -31) then
							ChatFrame1:Clear()
							print(('{"Arrow", ' .. floor(x * 1000 + 0.5) / 10) .. ',', (floor(y * 1000 + 0.5) / 10) .. ', L["Step 1"], L["Start here."], arTex, nil, nil, nil, nil, nil, ' .. f.f:GetText() .. "},")
							PlaySoundFile(567412, "Master", false, true)
						end
					end
				end)

				f:SetMovable(true)
				f:SetScript("OnMouseDown", function(self, btn)
					if btn == "LeftButton" then
						f:StartMoving()
					end
				end)

				f:SetScript("OnMouseUp", function()
					f:StopMovingOrSizing()
					--ChatFrame1:Clear()
					--local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
					--if x and y and x > 0 and y > 0 and MouseIsOver(f) then
					--	print(('{"Arrow", ' .. floor(x * 1000 + 0.5) / 10) .. ',', (floor(y * 1000 + 0.5) / 10) .. ', L["Step 1"], L["Start here."], ' .. f.f:GetText() .. "},")
					--end
				end)
				return
			elseif str == "dis" then
				-- Disband group
				if not RGXQoLLC:IsInLFGQueue() and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
					local x = GetNumGroupMembers() or 0
					for i = x, 1, -1 do
						if GetNumGroupMembers() > 0 then
							local name = GetRaidRosterInfo(i)
							if name and name ~= UnitName("player") then
								UninviteUnit(name)
							end
						end
					end
				else
					RGXQoLLC:Print("You cannot do that while in group finder.")
				end
				return
			elseif str == "reinv" then
				-- Disband and reinvite raid
				if not RGXQoLLC:IsInLFGQueue() then
					if UnitIsGroupLeader("player") then
						-- Disband
						local groupNames = {}
						local x = GetNumGroupMembers() or 0
						for i = x, 1, -1 do
							if GetNumGroupMembers() > 0 then
								local name = GetRaidRosterInfo(i)
								if name and name ~= UnitName("player") then
									UninviteUnit(name)
									tinsert(groupNames, name)
								end
							end
						end
						-- Reinvite
						C_Timer.After(0.1, function()
							for k, v in pairs(groupNames) do
								C_PartyInfo.InviteUnit(v)
							end
						end)
					else
						RGXQoLLC:Print("You need to be group leader.")
					end
				else
					RGXQoLLC:Print("You cannot do that while in group finder.")
				end
				return
			elseif str == "mem" or str == "m" then
				-- Print this addon's memory usage in chat
				UpdateAddOnMemoryUsage()
				RGXQoLLC:Print("Memory usage: |cffffffff" .. string.format("%.2f", GetAddOnMemoryUsage("RGXQoL") / 1024) .. "|r MB")
				return
			elseif str == "gossinfo" then
				-- Print gossip frame information
				if GossipFrame:IsShown() then
					local npcName = UnitName("npc")
					local npcGuid = UnitGUID("npc") or nil
					if npcName and npcGuid then
						local void, void, void, void, void, npcID = strsplit("-", npcGuid)
						if npcID then
							RGXQoLLC:Print(npcName .. ": |cffffffff" .. npcID)
						end
					end
					RGXQoLLC:Print("Available quests: |cffffffff" .. C_GossipInfo.GetNumAvailableQuests())
					RGXQoLLC:Print("Active quests: |cffffffff" .. C_GossipInfo.GetNumActiveQuests())
					local gossipInfoTable = C_GossipInfo.GetOptions()
					if gossipInfoTable and gossipInfoTable[1] and gossipInfoTable[1].name then
						RGXQoLLC:Print("Gossip count: |cffffffff" .. #gossipInfoTable)
						RGXQoLLC:Print("Gossip name: |cffffffff" .. gossipInfoTable[1].name)
					else
						RGXQoLLC:Print("Gossip info: |cffffffff" .. "Nil")
					end
					if GossipTitleButton1 and GossipTitleButton1:GetText() then
						RGXQoLLC:Print("First option: |cffffffff" .. GossipTitleButton1:GetText())
					end
					-- RGXQoLLC:Print("Gossip text: |cffffffff" .. GetGossipText())
					if not IsShiftKeyDown() then
						SelectGossipOption(1)
					end
				else
					RGXQoLLC:Print("Gossip frame not open.")
				end
				return
			elseif str == "svars" then
				-- Print saved variables (checkbox/slider/dropdown browser was removed with the legacy UI)
				RGXQoLLC:Print(L["Saved Variables"] .. "|n")
				RGXQoLLC:Print(L["Modifying saved variables must start with |cffffffff/qol nosave|r to prevent your changes from being reverted during reload or logout."] .. "|n")
				RGXQoLLC:Print(L['Syntax is |cffffffff/run RGXQoLDB[' .. '"' .. 'setting name' .. '"' .. '] = ' .. '"' .. 'value' .. '" |r(case sensitive).'])
				RGXQoLLC:Print(L["When done, |cffffffff/reload|r to save your changes."] .. "|n")
				for key, value in pairs(RGXQoLDB) do
					RGXQoLLC:Print("|cffffffff" .. key .. "|r = |cff1eff0c" .. tostring(value) .. "|r")
				end
				return
			elseif str == "tags" then
				-- Print open menu tags (such as dropdown menus)
				Menu.PrintOpenMenuTags()
				return
			elseif str == "taintmap" then
				-- TaintMap
				if RGXQoLLC.TaintMap then
					RGXQoLLC.TaintMap:Cancel()
					RGXQoLLC.TaintMap = nil
					RGXQoLLC:Print("TaintMap stopped.")
					return
				end
				RGXQoLLC.TaintMap = C_Timer.NewTicker(1, function()
					for k,v in pairs(WorldMapFrame) do
						local ok, who = issecurevariable(WorldMapFrame, k)
						if not ok then
							print("Tainted:", k, "by", who or "unknown")
						end
					end
				end)
				RGXQoLLC:Print("TaintMap started.")
				return
			elseif str == "admin" then
				-- Preset profile (used for testing)
				RGXQoLEvt:UnregisterAllEvents()						-- Prevent changes
				wipe(RGXQoLDB)									-- Wipe settings
				RGXQoLLC:PlayerLogout(true)					-- Reset permanent settings
				-- Automation
				RGXQoLDB["AutomateQuests"] = "On"				-- Automate quests
				RGXQoLDB["AutoQuestShift"] = "Off"				-- Automate quests requires shift
				RGXQoLDB["AutoQuestAvailable"] = "On"			-- Accept available quests
				RGXQoLDB["AutoQuestCompleted"] = "On"			-- Turn-in completed quests
				RGXQoLDB["AutoQuestKeyMenu"] = 1				-- Automate quests override key
				RGXQoLDB["AutomateGossip"] = "On"				-- Automate gossip
				RGXQoLDB["AutoAcceptSummon"] = "On"			-- Accept summon
				RGXQoLDB["AutoAcceptRes"] = "On"				-- Accept resurrection
				RGXQoLDB["AutoReleasePvP"] = "On"				-- Release in PvP
				RGXQoLDB["AutoSellJunk"] = "On"				-- Sell junk automatically
				RGXQoLDB["AutoSellExcludeList"] = ""			-- Sell junk exclusions list
				RGXQoLDB["AutoRepairGear"] = "On"				-- Repair automatically

				-- Settings
				RGXQoLDB["UseEnglishLanguage"] = "On"			-- Use English language

				-- Function to assign cooldowns
				local function setIcon(pclass, pspec, sp1, pt1, sp2, pt2, sp3, pt3, sp4, pt4, sp5, pt5)
					-- Set spell ID
					-- Set pet checkbox
				end

				-- Create main table

				-- Create class tables

				-- Assign cooldowns
				setIcon("WARRIOR", 		1, --[[1]] 0, 0, 		--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 0, 0)
				setIcon("PALADIN", 		1, --[[1]] 0, 0, 		--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 19740, 0) -- nil, nil, nil, nil, Might
				setIcon("HUNTER", 		1, --[[1]] 136, 1, 		--[[2]] 118455, 1, 	--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 5384, 0) -- Mend Pet, nil, nil, nil, Feign Death
				setIcon("SHAMAN", 		1, --[[1]] 0, 0, 		--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 215864, 0, 	--[[5]] 546, 0) -- nil, nil, nil, Rainfall, Water Walking
				setIcon("ROGUE", 		1, --[[1]] 1784, 0, 	--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 2823, 0, 	--[[5]] 3408, 0) -- Stealth, nil, nil, Deadly Poison, Crippling Poison
				setIcon("DRUID", 		1, --[[1]] 0, 0, 		--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 0, 0)
				setIcon("MAGE", 		1, --[[1]] 235450, 0, 	--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 0, 0) -- Prismatic Barrier
				setIcon("WARLOCK", 		1, --[[1]] 0, 0, 		--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 0, 0)
				setIcon("PRIEST", 		1, --[[1]] 17, 0, 		--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 0, 0) -- Power Word: Shield



				-- Set chat font sizes
				RunScript('for i = 1, 50 do if _G["ChatFrame" .. i] then FCF_SetChatWindowFontSize(self, _G["ChatFrame" .. i], 20) end end')

				-- Reload
				ReloadUI()
			else
				RGXQoLLC:Print("Invalid parameter.")
			end
			return
		else
				-- Open the framework-hosted options panel
				if OpenOptionsShared then OpenOptionsShared() end
		end
	end

	-- Slash command for global function
	_G.SLASH_RGXQoL1 = "/qol"
		SlashCmdList["RGXQoL"] = function(self)
		-- Run slash command function
		RGXQoLLC:SlashFunc(self)
		-- Redirect tainted variables
		RunScript('ACTIVE_CHAT_EDIT_BOX = ACTIVE_CHAT_EDIT_BOX')
		RunScript('LAST_ACTIVE_CHAT_EDIT_BOX = LAST_ACTIVE_CHAT_EDIT_BOX')
	end

	-- Slash command for UI reload
	_G.SLASH_RGXQO_RL1 = "/rl"
	SlashCmdList["RGXQO_RL"] = function()
		ReloadUI()
	end


----------------------------------------------------------------------
--	L95: Options panel (RGX-Framework) — one settings page of cards
----------------------------------------------------------------------

	-- The legacy Leatrix window/pages/nav/gear machinery is gone. Options live
	-- in a single settings-integrated page built from framework controls.
	-- Runtime code keeps reading the legacy "On"/"Off" strings in RGXQoLLC;
	-- the bridge below translates those to booleans for the framework
	-- controls and back, so existing saved variables and presets keep working.

	-- Bridge key (framework boolean storage) -> legacy option key
	local BridgeKeys = {
		automateQuests        = "AutomateQuests",
		autoQuestAvailable    = "AutoQuestAvailable",
		autoQuestCompleted    = "AutoQuestCompleted",
		autoQuestShift        = "AutoQuestShift",
		autoQuestKeyMenu      = "AutoQuestKeyMenu",
		automateGossip        = "AutomateGossip",
		autoAcceptSummon      = "AutoAcceptSummon",
		autoAcceptRes         = "AutoAcceptRes",
		autoResNoCombat       = "AutoResNoCombat",
		autoReleasePvP        = "AutoReleasePvP",
		autoReleaseNoAlterac  = "AutoReleaseNoAlterac",
		autoReleaseDelay      = "AutoReleaseDelay",
		autoSellJunk          = "AutoSellJunk",
		autoSellShowSummary   = "AutoSellShowSummary",
		autoRepairGear        = "AutoRepairGear",
		autoRepairShowSummary = "AutoRepairShowSummary",
		showMinimapIcon       = "ShowMinimapIcon",
		useEnglishLanguage    = "UseEnglishLanguage",
	}

	-- Bridge keys that carry numbers (not On/Off)
	local NumericBridgeKeys = { autoQuestKeyMenu = true, autoReleaseDelay = true }

	local BridgeStore = {}
	local OpenOptionsShared -- set by BuildOptionsCanvas, used by the minimap button
	local ReloadButton, ReloadLabel

	-- Read legacy strings into the bridge store (call after profile load)
	local function SyncBridgeFromLegacy()
		for bkey, legacy in pairs(BridgeKeys) do
			local v = RGXQoLLC[legacy]
			if NumericBridgeKeys[bkey] then
				BridgeStore[bkey] = tonumber(v) or (bkey == "autoQuestKeyMenu" and 1 or 200)
			else
				BridgeStore[bkey] = (v == "On")
			end
		end
	end

	-- Bridge change -> legacy string + feature setup hook + reload check
	local function OnBridgeChange(bkey, value)
		local legacy = BridgeKeys[bkey]
		if not legacy then return end
		if NumericBridgeKeys[bkey] then
			RGXQoLLC[legacy] = math.floor(tonumber(value) or 1)
		else
			RGXQoLLC[legacy] = value and "On" or "Off"
		end
		local setup = RGXQoLLC.FeatureSetup and RGXQoLLC.FeatureSetup[legacy]
		if setup then setup() end
		RGXQoLLC:ReloadCheck()
	end

	-- Reload-needed state drives the Addon card reload button
	function RGXQoLLC:ReloadCheck()
		local needs = (RGXQoLLC["UseEnglishLanguage"] ~= RGXQoLDB["UseEnglishLanguage"])
		if ReloadButton then
			if needs then
				ReloadButton:Enable()
				if ReloadLabel then ReloadLabel:Show() end
			else
				ReloadButton:Disable()
				if ReloadLabel then ReloadLabel:Hide() end
			end
		end
	end

	local function BridgeToggle(frame, label, bkey, tip)
		frame:Toggle(label, BridgeStore, bkey, BridgeStore[bkey], function(v) OnBridgeChange(bkey, v) end)
	end

	function RGXQoLLC:BuildOptionsCanvas()

		local UI = _G.RGXUI
		if not UI or not UI.CreateOptionsPanel then
			RGXQoLLC:Print("RGX-Framework UI module not found; options unavailable.")
			return
		end

		SyncBridgeFromLegacy()

		local panel = UI:CreateOptionsPanel({
			addonName = "RGXQoL",
			title = "RGX QoL",
			subtitle = "Quality of life enhancements for WoW Forever",
			icon = "Interface\\AddOns\\RGX-Framework\\media\\logo.tga",
			brand = "8B1538",
			version = "v" .. tostring(RGXQoLLC:GetAddonVersion()),
			author = "RealmGX, derived from Leatrix Plus by Leatrix",
			width = 760,
			height = 620,
			tabs = {
				{
					text = L["General"],
					content = function(frame)

						-- Character card
						frame:Section(L["Character"])
						BridgeToggle(frame, L["Automate quests"], "automateQuests")
						BridgeToggle(frame, L["Accept available quests automatically"], "autoQuestAvailable")
						BridgeToggle(frame, L["Turn-in completed quests automatically"], "autoQuestCompleted")
						BridgeToggle(frame, L["Require override key for quest automation"], "autoQuestShift")
						frame:Slider(L["Override key"] .. " (1=SHIFT 2=ALT 3=CTRL 4=CMD)", BridgeStore, "autoQuestKeyMenu", 1, 4, BridgeStore["autoQuestKeyMenu"] or 1, "")
						BridgeToggle(frame, L["Automate gossip"], "automateGossip")
						BridgeToggle(frame, L["Accept summon"], "autoAcceptSummon")
						BridgeToggle(frame, L["Accept resurrection"], "autoAcceptRes")
						BridgeToggle(frame, L["Exclude combat resurrection"], "autoResNoCombat")
						BridgeToggle(frame, L["Release in PvP"], "autoReleasePvP")
						BridgeToggle(frame, L["Exclude Alterac Valley"], "autoReleaseNoAlterac")
						frame:Slider(L["Release delay"] .. " (ms)", BridgeStore, "autoReleaseDelay", 200, 3000, BridgeStore["autoReleaseDelay"] or 200, "ms")

						-- Vendors card
						frame:Section(L["Vendors"])
						BridgeToggle(frame, L["Sell junk automatically"], "autoSellJunk")
						BridgeToggle(frame, L["Show vendor summary in chat"], "autoSellShowSummary")
						BridgeToggle(frame, L["Repair automatically"], "autoRepairGear")
						BridgeToggle(frame, L["Show repair summary in chat"], "autoRepairShowSummary")

						-- Addon card
						frame:Section(L["Addon"])
						local mmw = BridgeToggle(frame, L["Show minimap button"], "showMinimapIcon")
						local engw = BridgeToggle(frame, L["Use English language"], "useEnglishLanguage")

						-- Reload UI button, wired to the reload-needed state
						ReloadButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
						ReloadButton:SetSize(120, 22)
						ReloadButton:SetText(L["Reload UI"])
						if engw and engw.GetObjectName and engw:GetObjectName() then end
						local anchorFrame = engw or mmw
						if anchorFrame then
							ReloadButton:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -10)
						else
							ReloadButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -400)
						end
						ReloadButton:SetScript("OnClick", function() ReloadUI() end)
						ReloadLabel = ReloadButton:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
						ReloadLabel:SetPoint("RIGHT", ReloadButton, "LEFT", -10, 0)
						ReloadLabel:SetText(L["Your UI needs to be reloaded."])
						ReloadLabel:Hide()
						RGXQoLLC:ReloadCheck()

					end,
				},
			},
		})

		RGXQoLLC.QoLPanel = panel


		OpenOptionsShared = function()
			if panel and panel.Open then panel:Open() end
		end

	end

