----------------------------------------------------------------------
-- 	Leatrix Plus 1.15.150 (12th August 2026)
----------------------------------------------------------------------

--	01:Functions 02:Locks   03:Restart 40:Player   45:Rest
--	60:Events    62:Profile 70:Logout  80:Commands 90:Panel

----------------------------------------------------------------------
-- 	Leatrix Plus
----------------------------------------------------------------------

	-- Create global table
	_G.RGXQoLDB = _G.RGXQoLDB or {}

	-- Create locals
	local RGXQoLLC, RGXQoLCB, RGXQoLDropList, RGXQoLConfigList, RGXQoLLockList = {}, {}, {}, {}, {}

	-- WoW Forever beta safety: skip secure hooks for functions this client
	-- lacks (the beta exposes a mixed API surface)
	local LeaPlusRawHook = hooksecurefunc
	hooksecurefunc = function(name, func, ...)
		if type(name) == "string" and _G[name] == nil then
			return
		end
		return LeaPlusRawHook(name, func, ...)
	end
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
				print(L["LEATRIX PLUS: WRONG VERSION INSTALLED!"])
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
--	L00: Leatrix Plus
----------------------------------------------------------------------

	-- Initialise variables
	RGXQoLLC["ShowErrorsFlag"] = 1
	RGXQoLLC["NumberOfPages"] = 8
	RGXQoLLC["MainPanelHeight"] = 370

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
	_G.BINDING_NAME_RGXQO_GLOBAL_WEBLINK = L["Show web link"]
	_G.BINDING_NAME_RGXQO_GLOBAL_RARE = L["Announce rare"]

----------------------------------------------------------------------
--	L01: Functions
----------------------------------------------------------------------

	-- Print text
	function RGXQoLLC:Print(text)
		DEFAULT_CHAT_FRAME:AddMessage(L[text], 1.0, 0.85, 0.0)
	end

	-- Lock and unlock an item
	function RGXQoLLC:LockItem(item, lock)
		if not item then return end
		if lock then
			item:Disable()
			item:SetAlpha(0.3)
		else
			item:Enable()
			item:SetAlpha(1.0)
		end
	end

	-- Hide configuration panels
	function RGXQoLLC:HideConfigPanels()
		for k, v in pairs(RGXQoLConfigList) do
			v:Hide()
		end
	end

	-- Decline a shared quest if needed
	function RGXQoLLC:CheckIfQuestIsSharedAndShouldBeDeclined()
		if RGXQoLLC["NoSharedQuests"] == "On" then
			local npcName = UnitName("questnpc")
			if npcName and UnitIsPlayer(npcName) then
				if UnitInParty(npcName) or UnitInRaid(npcName) then
					if not RGXQoLLC:FriendCheck(npcName) then
						DeclineQuest()
						return
					end
				end
			end
		end
	end

	-- Show a single line prefilled editbox with copy functionality
	function RGXQoLLC:ShowSystemEditBox(word, focuschat)
		if not RGXQoLLC.FactoryEditBox then
			-- Create frame for first time
			local eFrame = CreateFrame("FRAME", nil, UIParent)
			RGXQoLLC.FactoryEditBox = eFrame
			eFrame:SetSize(700, 110)
			eFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
			eFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			eFrame:SetFrameLevel(5000)
			eFrame:SetScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then
					eFrame:Hide()
				end
			end)
			-- Add background color
			eFrame.t = eFrame:CreateTexture(nil, "BACKGROUND")
			eFrame.t:SetAllPoints()
			eFrame.t:SetColorTexture(0.05, 0.05, 0.05, 0.9)
			-- Add copy title
			eFrame.f = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.f:SetPoint("TOPLEFT", x, y)
			eFrame.f:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -52)
			eFrame.f:SetWidth(676)
			eFrame.f:SetJustifyH("LEFT")
			eFrame.f:SetWordWrap(false)
			-- Add copy label
			eFrame.c = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.c:SetPoint("TOPLEFT", x, y)
			eFrame.c:SetText(L["Press CTRL/C to copy"])
			eFrame.c:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -82)
			-- Add cancel label
			eFrame.x = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.x:SetPoint("TOPRIGHT", x, y)
			eFrame.x:SetText(L["Right-click to close"])
			eFrame.x:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -82)
			-- Create editbox
			eFrame.b = CreateFrame("EditBox", nil, eFrame, "InputBoxTemplate")
			eFrame.b:ClearAllPoints()
			eFrame.b:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 16, -12)
			eFrame.b:SetSize(672, 24)
			eFrame.b:SetFontObject("GameFontNormalLarge")
			eFrame.b:SetTextColor(1.0, 1.0, 1.0, 1)
			eFrame.b:SetBlinkSpeed(0)
			eFrame.b:SetHitRectInsets(99, 99, 99, 99)
			eFrame.b:SetAutoFocus(true)
			eFrame.b:SetAltArrowKeyMode(true)
			-- Editbox texture
			eFrame.t = CreateFrame("FRAME", nil, eFrame.b, "BackdropTemplate")
			eFrame.t:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
			eFrame.t:SetPoint("LEFT", -6, 0)
			eFrame.t:SetWidth(eFrame.b:GetWidth() + 6)
			eFrame.t:SetHeight(eFrame.b:GetHeight())
			eFrame.t:SetBackdropColor(1.0, 1.0, 1.0, 0.3)
			-- Handler
			eFrame.b:SetScript("OnKeyDown", function(void, key)
				if key == "C" and (IsControlKeyDown() or IsMetaKeyDown()) then
					C_Timer.After(0.1, function()
						eFrame:Hide()
						ActionStatus_DisplayMessage(L["Copied to clipboard."], true)
						if RGXQoLLC.FactoryEditBoxFocusChat then
							local eBox = ChatEdit_ChooseBoxForSend()
							ChatEdit_ActivateChat(eBox)
						end
					end)
				end
			end)
			-- Prevent changes
			eFrame.b:SetScript("OnEscapePressed", function() eFrame:Hide() end)
			eFrame.b:SetScript("OnEnterPressed", eFrame.b.HighlightText)
			eFrame.b:SetScript("OnMouseDown", eFrame.b.ClearFocus)
			eFrame.b:SetScript("OnMouseUp", eFrame.b.HighlightText)
			eFrame.b:SetFocus(true)
			eFrame.b:HighlightText()
			eFrame:Show()
		end
		if focuschat then RGXQoLLC.FactoryEditBoxFocusChat = true else RGXQoLLC.FactoryEditBoxFocusChat = nil end
		RGXQoLLC.FactoryEditBox:Show()
		RGXQoLLC.FactoryEditBox.b:SetText(word)
		RGXQoLLC.FactoryEditBox.b:HighlightText()
		RGXQoLLC.FactoryEditBox.b:SetScript("OnChar", function() RGXQoLLC.FactoryEditBox.b:SetFocus(true) RGXQoLLC.FactoryEditBox.b:SetText(word) RGXQoLLC.FactoryEditBox.b:HighlightText() end)
		RGXQoLLC.FactoryEditBox.b:SetScript("OnKeyUp", function() RGXQoLLC.FactoryEditBox.b:SetFocus(true) RGXQoLLC.FactoryEditBox.b:SetText(word) RGXQoLLC.FactoryEditBox.b:HighlightText() end)
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

	-- Show tooltips for checkboxes
	function RGXQoLLC:TipSee()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = self:GetParent()
		if parent:GetParent() and parent:GetParent():GetObjectType() == "ScrollFrame" then
			-- Scrolling frame tooltips have different parent
			parent = self:GetParent():GetParent():GetParent():GetParent()
		end
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Show tooltips for dropdown menu tooltips
	function RGXQoLLC:ShowDropTip()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = self:GetParent():GetParent():GetParent()
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Show tooltips for configuration buttons and dropdown menus
	function RGXQoLLC:ShowTooltip()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = RGXQoLLC["PageF"]
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (RGXQoLLC["PageF"]:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Create configuration button
	function RGXQoLLC:CfgBtn(name, parent)
		local CfgBtn = CreateFrame("BUTTON", nil, parent)
		RGXQoLCB[name] = CfgBtn
		CfgBtn:SetWidth(20)
		CfgBtn:SetHeight(20)
		CfgBtn:SetPoint("LEFT", parent.f, "RIGHT", 0, 0)

		CfgBtn.t = CfgBtn:CreateTexture(nil, "BORDER")
		CfgBtn.t:SetAllPoints()
		CfgBtn.t:SetTexture("Interface\\WorldMap\\Gear_64.png")
		CfgBtn.t:SetTexCoord(0, 0.50, 0, 0.50);
		CfgBtn.t:SetVertexColor(1.0, 0.82, 0, 1.0)

		CfgBtn:SetHighlightTexture("Interface\\WorldMap\\Gear_64.png")
		CfgBtn:GetHighlightTexture():SetTexCoord(0, 0.50, 0, 0.50);

		CfgBtn.tiptext = L["Click to configure the settings for this option."]
		CfgBtn:SetScript("OnEnter", RGXQoLLC.ShowTooltip)
		CfgBtn:SetScript("OnLeave", GameTooltip_Hide)
	end

	-- Create a help button to the right of a fontstring
	function RGXQoLLC:CreateHelpButton(frame, panel, parent, tip)
		RGXQoLLC:CfgBtn(frame, panel)
		RGXQoLCB[frame]:ClearAllPoints()
		RGXQoLCB[frame]:SetPoint("LEFT", parent, "RIGHT", -parent:GetWidth() + parent:GetStringWidth(), 0)
		RGXQoLCB[frame]:SetSize(25, 25)
		RGXQoLCB[frame].t:SetTexture("Interface\\COMMON\\help-i.blp")
		RGXQoLCB[frame].t:SetTexCoord(0, 1, 0, 1)
		RGXQoLCB[frame].t:SetVertexColor(0.9, 0.8, 0.0)
		RGXQoLCB[frame]:SetHighlightTexture("Interface\\COMMON\\help-i.blp")
		RGXQoLCB[frame]:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
		RGXQoLCB[frame].tiptext = L[tip]
		RGXQoLCB[frame]:SetScript("OnEnter", RGXQoLLC.TipSee)
	end

	-- Show a footer
	function RGXQoLLC:MakeFT(frame, text, left, width)
		local footer = RGXQoLLC:MakeTx(frame, text, left, 96)
		footer:SetWidth(width); footer:SetJustifyH("LEFT"); footer:SetWordWrap(true); footer:ClearAllPoints()
		footer:SetPoint("BOTTOMLEFT", left, 96)
		return footer
	end

	-- Capitalise first character in a string
	function RGXQoLLC:CapFirst(str)
		return gsub(string.lower(str), "^%l", strupper)
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

	-- Show memory usage stat
	function RGXQoLLC:ShowMemoryUsage(frame, anchor, x, y)

		-- Create frame
		local memframe = CreateFrame("FRAME", nil, frame)
		memframe:ClearAllPoints()
		memframe:SetPoint(anchor, x, y)
		memframe:SetWidth(100)
		memframe:SetHeight(20)

		-- Create labels
		local pretext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		pretext:SetPoint("TOPLEFT", 0, 0)
		pretext:SetText(L["Memory Usage"])

		local memtext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		memtext:SetPoint("TOPLEFT", 0, 0 - 30)

		-- Create stat
		local memstat = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		memstat:SetPoint("BOTTOMLEFT", memtext, "BOTTOMRIGHT")
		memstat:SetText("(calculating...)")

		-- Create update script
		local memtime = -1
		memframe:SetScript("OnUpdate", function(self, elapsed)
			if memtime > 2 or memtime == -1 then
				UpdateAddOnMemoryUsage();
				memtext = GetAddOnMemoryUsage("RGXQoL")
				memtext = math.floor(memtext + .5) .. " KB"
				memstat:SetText(memtext);
				memtime = 0;
			end
			memtime = memtime + elapsed;
		end)

		-- Release memory
		RGXQoLLC.ShowMemoryUsage = nil

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

	-- Check if player is in combat
	function RGXQoLLC:PlayerInCombat()
		if (UnitAffectingCombat("player")) then
			RGXQoLLC:Print("You cannot do that in combat.")
			return true
		end
	end

	--  Hide panel and pages
	function RGXQoLLC:HideFrames()

		-- Hide option pages
		for i = 0, RGXQoLLC["NumberOfPages"] do
			if RGXQoLLC["Page"..i] then
				RGXQoLLC["Page"..i]:Hide();
			end;
		end

		-- Hide options panel
		RGXQoLLC["PageF"]:Hide();

	end

	-- Find out if Leatrix Plus is showing (main panel or config panel)
	function RGXQoLLC:IsPlusShowing()
		if RGXQoLLC["PageF"]:IsShown() then return true end
		for k, v in pairs(RGXQoLConfigList) do
			if v:IsShown() then
				return true
			end
		end
	end

	-- Check if a name is in your friends list or guild (does not check realm as realm is unknown for some checks)
	function RGXQoLLC:FriendCheck(name, guid)

		-- Do nothing if name is empty (such as whispering from the Battle.net app)
		if not name then return end

		-- Update friends list
		C_FriendList.ShowFriends()

		-- Remove realm (since we have GUID checking)
		name = strsplit("-", name, 2)

		-- Check character friends
		for i = 1, C_FriendList.GetNumFriends() do
			-- Return true is character name matches and GUID matches if there is one (realm is not checked)
			local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
			local charFriendName = C_FriendList.GetFriendInfoByIndex(i).name
			charFriendName = strsplit("-", charFriendName, 2)
			if (name == charFriendName) and (guid and (guid == friendInfo.guid) or true) then
				return true
			end
		end

		-- Check Battle.net friends
		local numfriends = BNGetNumFriends()
		for i = 1, numfriends do
			local numtoons = C_BattleNet.GetFriendNumGameAccounts(i)
			for j = 1, numtoons do
				local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
				local characterName = gameAccountInfo.characterName
				local client = gameAccountInfo.clientProgram
				if client == "WoW" and characterName == name then
					return true
				end
			end
		end

		-- Check guild members if guild is enabled (new members may need to press J to refresh roster)
		if RGXQoLLC["FriendlyGuild"] == "On" then
			local gCount = GetNumGuildMembers()
			for i = 1, gCount do
				local gName, void, void, void, void, void, void, void, gOnline, void, void, void, void, gMobile, void, void, gGUID = GetGuildRosterInfo(i)
				if gOnline and not gMobile then
					gName = strsplit("-", gName, 2)
					-- Return true if character name matches including GUID if there is one
					if (name == gName) and (guid and (guid == gGUID) or true) then
						return true
					end
				end
			end
		end

	end

----------------------------------------------------------------------
--	L02: Locks
----------------------------------------------------------------------

	-- Function to set lock state for configuration buttons
	function RGXQoLLC:LockOption(option, item, reloadreq)
		if reloadreq then
			-- Option change requires UI reload
			if RGXQoLLC[option] ~= RGXQoLDB[option] or RGXQoLLC[option] == "Off" then
				RGXQoLLC:LockItem(RGXQoLCB[item], true)
			else
				RGXQoLLC:LockItem(RGXQoLCB[item], false)
			end
		else
			-- Option change does not require UI reload
			if RGXQoLLC[option] == "Off" then
				RGXQoLLC:LockItem(RGXQoLCB[item], true)
			else
				RGXQoLLC:LockItem(RGXQoLCB[item], false)
			end
		end
	end

--	Set lock state for configuration buttons
	function RGXQoLLC:SetDim()
		RGXQoLLC:LockOption("AutomateQuests", "AutomateQuestsBtn", false)			-- Automate quests
		RGXQoLLC:LockOption("AutoAcceptRes", "AutoAcceptResBtn", false)			-- Accept resurrection
		RGXQoLLC:LockOption("AutoReleasePvP", "AutoReleasePvPBtn", false)			-- Release in PvP
		RGXQoLLC:LockOption("AutoSellJunk", "AutoSellJunkBtn", false)				-- Sell junk automatically
		RGXQoLLC:LockOption("AutoRepairGear", "AutoRepairBtn", false)				-- Repair automatically
		RGXQoLLC:LockOption("InviteFromWhisper", "InvWhisperBtn", false)			-- Invite from whispers
		RGXQoLLC:LockOption("FilterChatMessages", "FilterChatMessagesBtn", true)	-- Filter chat messages
		RGXQoLLC:LockOption("MailFontChange", "MailTextBtn", true)					-- Resize mail text
		RGXQoLLC:LockOption("QuestFontChange", "QuestTextBtn", true)				-- Resize quest text
		RGXQoLLC:LockOption("BookFontChange", "BookTextBtn", true)					-- Resize book text
		RGXQoLLC:LockOption("MinimapModder", "ModMinimapBtn", true)				-- Enhance minimap
		RGXQoLLC:LockOption("TipModEnable", "MoveTooltipButton", true)				-- Enhance tooltip
		RGXQoLLC:LockOption("EnhanceDressup", "EnhanceDressupBtn", true)			-- Enhance dressup
		RGXQoLLC:LockOption("EnhanceQuestLog", "EnhanceQuestLogBtn", true)			-- Enhance quest log
		RGXQoLLC:LockOption("EnhanceTrainers", "EnhanceTrainersBtn", true)			-- Enhance trainers
		RGXQoLLC:LockOption("EnhanceFlightMap", "EnhanceFlightMapBtn", true)		-- Enhance flight map
		RGXQoLLC:LockOption("ShowCooldowns", "CooldownsButton", true)				-- Show cooldowns
		RGXQoLLC:LockOption("ShowBorders", "ModBordersBtn", true)					-- Show borders
		RGXQoLLC:LockOption("ShowPlayerChain", "ModPlayerChain", true)				-- Show player chain
		RGXQoLLC:LockOption("ShowDruidPowerBar", "ShowDruidPowerBarBtn", true)		-- Show druid power bar
		RGXQoLLC:LockOption("ShowWowheadLinks", "ShowWowheadLinksBtn", true)		-- Show Wowhead links
		RGXQoLLC:LockOption("ShowFlightTimes", "ShowFlightTimesBtn", true)			-- Show flight times
		RGXQoLLC:LockOption("ManageWidget", "ManageWidgetButton", true)			-- Manage widget
		RGXQoLLC:LockOption("ManageTimer", "ManageTimerButton", true)				-- Manage timer
		RGXQoLLC:LockOption("ClassColFrames", "ClassColFramesBtn", true)			-- Class colored frames
		RGXQoLLC:LockOption("SetWeatherDensity", "SetWeatherDensityBtn", false)	-- Set weather density
		RGXQoLLC:LockOption("MuteGameSounds", "MuteGameSoundsBtn", false)			-- Mute game sounds
		RGXQoLLC:LockOption("MuteMountSounds", "MuteMountSoundsBtn", false)		-- Mute mount sounds
		RGXQoLLC:LockOption("MuteCustomSounds", "MuteCustomSoundsBtn", false)		-- Mute custom sounds
		RGXQoLLC:LockOption("StandAndDismount", "DismountBtn", true)				-- Dismount me
	end

----------------------------------------------------------------------
--	L03: Restarts
----------------------------------------------------------------------

	-- Set the reload button state
	function RGXQoLLC:ReloadCheck()

		-- Chat
		if	(RGXQoLLC["UseEasyChatResizing"]	~= RGXQoLDB["UseEasyChatResizing"])	-- Use easy resizing
		or	(RGXQoLLC["NoCombatLogTab"]		~= RGXQoLDB["NoCombatLogTab"])			-- Hide the combat log
		or	(RGXQoLLC["NoChatButtons"]			~= RGXQoLDB["NoChatButtons"])			-- Hide chat buttons
		or	(RGXQoLLC["UnclampChat"]			~= RGXQoLDB["UnclampChat"])			-- Unclamp chat frame
		or	(RGXQoLLC["MoveChatEditBoxToTop"]	~= RGXQoLDB["MoveChatEditBoxToTop"])	-- Move editbox to top
		or	(RGXQoLLC["MoreFontSizes"]			~= RGXQoLDB["MoreFontSizes"])			-- More font sizes
		or	(RGXQoLLC["NoStickyChat"]			~= RGXQoLDB["NoStickyChat"])			-- Disable sticky chat
		or	(RGXQoLLC["UseArrowKeysInChat"]	~= RGXQoLDB["UseArrowKeysInChat"])		-- Use arrow keys in chat
		or	(RGXQoLLC["NoChatFade"]			~= RGXQoLDB["NoChatFade"])				-- Disable chat fade
		or	(RGXQoLLC["ClassColorsInChat"]		~= RGXQoLDB["ClassColorsInChat"])		-- Use class colors in chat
		or	(RGXQoLLC["RecentChatWindow"]		~= RGXQoLDB["RecentChatWindow"])		-- Recent chat window
		or	(RGXQoLLC["MaxChatHstory"]			~= RGXQoLDB["MaxChatHstory"])			-- Increase chat history
		or	(RGXQoLLC["FilterChatMessages"]	~= RGXQoLDB["FilterChatMessages"])		-- Filter chat messages
		or	(RGXQoLLC["RestoreChatMessages"]	~= RGXQoLDB["RestoreChatMessages"])	-- Restore chat messages

		-- Text
		or	(RGXQoLLC["HideErrorMessages"]		~= RGXQoLDB["HideErrorMessages"])		-- Hide error messages
		or	(RGXQoLLC["NoHitIndicators"]		~= RGXQoLDB["NoHitIndicators"])		-- Hide portrait text
		or	(RGXQoLLC["HideZoneText"]			~= RGXQoLDB["HideZoneText"])			-- Hide zone text
		or	(RGXQoLLC["HideKeybindText"]		~= RGXQoLDB["HideKeybindText"])		-- Hide keybind text
		or	(RGXQoLLC["HideMacroText"]			~= RGXQoLDB["HideMacroText"])			-- Hide macro text
		or	(RGXQoLLC["HideRaidGroupLabels"]	~= RGXQoLDB["HideRaidGroupLabels"])	-- Hide raid group labels

		or	(RGXQoLLC["MailFontChange"]		~= RGXQoLDB["MailFontChange"])			-- Resize mail text
		or	(RGXQoLLC["QuestFontChange"]		~= RGXQoLDB["QuestFontChange"])		-- Resize quest text
		or	(RGXQoLLC["BookFontChange"]		~= RGXQoLDB["BookFontChange"])			-- Resize book text

		-- Interface
		or	(RGXQoLLC["MinimapModder"]			~= RGXQoLDB["MinimapModder"])			-- Enhance minimap
		or	(RGXQoLLC["HideMiniDayNight"]		~= RGXQoLDB["HideMiniDayNight"])		-- Hide the day and night indicator
		or	(RGXQoLLC["HideMiniZoneText"]		~= RGXQoLDB["HideMiniZoneText"])		-- Hide the zone text bar
		or	(RGXQoLLC["SquareMinimap"]			~= RGXQoLDB["SquareMinimap"])			-- Square minimap
		or	(RGXQoLLC["MinimapButtonBag"]		~= RGXQoLDB["MinimapButtonBag"])		-- Minimap button bag
		or	(RGXQoLLC["HideMiniTracking"]		~= RGXQoLDB["HideMiniTracking"])		-- Hide tracking button
		or	(RGXQoLLC["HideMiniLFG"]			~= RGXQoLDB["HideMiniLFG"])			-- Hide the Looking for Group button
		or	(RGXQoLLC["MiniExcludeList"]		~= RGXQoLDB["MiniExcludeList"])		-- Minimap exclude list
		or	(RGXQoLLC["TipModEnable"]			~= RGXQoLDB["TipModEnable"])			-- Enhance tooltip
		or	(RGXQoLLC["TipNoHealthBar"]		~= RGXQoLDB["TipNoHealthBar"])			-- Tooltip hide health bar
		or	(RGXQoLLC["EnhanceDressup"]		~= RGXQoLDB["EnhanceDressup"])			-- Enhance dressup
		or	(RGXQoLLC["EnhanceQuestLog"]		~= RGXQoLDB["EnhanceQuestLog"])		-- Enhance quest log
		or	(RGXQoLLC["EnhanceQuestTaller"]	~= RGXQoLDB["EnhanceQuestTaller"])		-- Enhance quest taller
		or	(RGXQoLLC["EnhanceProfessions"]	~= RGXQoLDB["EnhanceProfessions"])		-- Enhance professions
		or	(RGXQoLLC["EnhanceTrainers"]		~= RGXQoLDB["EnhanceTrainers"])		-- Enhance trainers
		or	(RGXQoLLC["EnhanceFlightMap"]		~= RGXQoLDB["EnhanceFlightMap"])		-- Enhance flight map

		or	(RGXQoLLC["ShowVolume"]			~= RGXQoLDB["ShowVolume"])				-- Show volume slider
		or	(RGXQoLLC["AhExtras"]				~= RGXQoLDB["AhExtras"])				-- Show auction controls
		or	(RGXQoLLC["ShowCooldowns"]			~= RGXQoLDB["ShowCooldowns"])			-- Show cooldowns
		or	(RGXQoLLC["DurabilityStatus"]		~= RGXQoLDB["DurabilityStatus"])		-- Show durability status
		or	(RGXQoLLC["ShowVanityControls"]	~= RGXQoLDB["ShowVanityControls"])		-- Show vanity controls
		or	(RGXQoLLC["ShowBagSearchBox"]		~= RGXQoLDB["ShowBagSearchBox"])		-- Show bag search box
		or	(RGXQoLLC["ShowFreeBagSlots"]		~= RGXQoLDB["ShowFreeBagSlots"])		-- Show free bag slots
		or	(RGXQoLLC["ShowRaidToggle"]		~= RGXQoLDB["ShowRaidToggle"])			-- Show raid button
		or	(RGXQoLLC["ShowBorders"]			~= RGXQoLDB["ShowBorders"])			-- Show borders
		or	(RGXQoLLC["ShowPlayerChain"]		~= RGXQoLDB["ShowPlayerChain"])		-- Show player chain
		or	(RGXQoLLC["ShowReadyTimer"]		~= RGXQoLDB["ShowReadyTimer"])			-- Show ready timer
		or	(RGXQoLLC["ShowDruidPowerBar"]		~= RGXQoLDB["ShowDruidPowerBar"])		-- Show druid power bar
		or	(RGXQoLLC["ShowDruidStatusText"]	~= RGXQoLDB["ShowDruidStatusText"])	-- Show druid power bar status text
		or	(RGXQoLLC["ShowWowheadLinks"]		~= RGXQoLDB["ShowWowheadLinks"])		-- Show Wowhead links
		or	(RGXQoLLC["ShowFlightTimes"]		~= RGXQoLDB["ShowFlightTimes"])		-- Show flight times

		-- Frames
		or	(RGXQoLLC["ManageWidget"]			~= RGXQoLDB["ManageWidget"])			-- Manage widget
		or	(RGXQoLLC["ManageTimer"]			~= RGXQoLDB["ManageTimer"])			-- Manage timer
		or	(RGXQoLLC["ClassColFrames"]		~= RGXQoLDB["ClassColFrames"])			-- Class colored frames
		or	(RGXQoLLC["NoGryphons"]			~= RGXQoLDB["NoGryphons"])				-- Hide gryphons
		or	(RGXQoLLC["NoClassBar"]			~= RGXQoLDB["NoClassBar"])				-- Hide stance bar

		-- System
		or	(RGXQoLLC["NoRestedEmotes"]		~= RGXQoLDB["NoRestedEmotes"])			-- Silence rested emotes
		or	(RGXQoLLC["KeepAudioSynced"]		~= RGXQoLDB["KeepAudioSynced"])		-- Keep audio synced
		or	(RGXQoLLC["NoBagAutomation"]		~= RGXQoLDB["NoBagAutomation"])		-- Disable bag automation
		or	(RGXQoLLC["FasterLooting"]			~= RGXQoLDB["FasterLooting"])			-- Faster auto loot
		or	(RGXQoLLC["FasterMovieSkip"]		~= RGXQoLDB["FasterMovieSkip"])		-- Faster movie skip
		or	(RGXQoLLC["StandAndDismount"]		~= RGXQoLDB["StandAndDismount"])		-- Dismount me
		or	(RGXQoLLC["ShowVendorPrice"]		~= RGXQoLDB["ShowVendorPrice"])		-- Show vendor price
		or	(RGXQoLLC["CombatPlates"]			~= RGXQoLDB["CombatPlates"])			-- Combat plates
		or	(RGXQoLLC["EasyItemDestroy"]		~= RGXQoLDB["EasyItemDestroy"])		-- Easy item destroy

		-- Settings
		or	(RGXQoLLC["UseEnglishLanguage"]	~= RGXQoLDB["UseEnglishLanguage"])		-- Use English language

		then
			-- Enable the reload button
			RGXQoLLC:LockItem(RGXQoLCB["ReloadUIButton"], false)
			RGXQoLCB["ReloadUIButton"].f:Show()
		else
			-- Disable the reload button
			RGXQoLLC:LockItem(RGXQoLCB["ReloadUIButton"], true)
			RGXQoLCB["ReloadUIButton"].f:Hide()
		end

	end

----------------------------------------------------------------------
--	L40: Player
----------------------------------------------------------------------

	function RGXQoLLC:Player()

		-- RGXQoLLC.NewPatch - Set WorldFrame level to ensure world frame mouse events work (WorldFrame:IsMouseMotionFocus())
		-- In case invalid WorldFrame frame level is stored in layout-local cache
		WorldFrame:SetFrameLevel(1)

		----------------------------------------------------------------------
		-- Hide raid group labels
		----------------------------------------------------------------------

		if RGXQoLLC["HideRaidGroupLabels"] == "On" then

			-- Hide player frame group indiciator labels
			hooksecurefunc("PlayerFrame_UpdateGroupIndicator", function()
				if PlayerFrameGroupIndicator:IsShown() then
					PlayerFrameGroupIndicator:Hide()
				end
			end)

			EventUtil.ContinueOnAddOnLoaded("Blizzard_RaidUI", function()
				-- Hide raid pullout frame labels
				hooksecurefunc("RaidPullout_Update", function(frame)
					if frame then
						local frameName = frame:GetName()
						if frameName then
							local title = _G[frameName .. "Name"]
							if title and title:IsShown() then
								title:Hide()
							end
						end
					end
				end)

				-- Hide raid container group titles
				local function HideRaidContainerGroupTitles(groupIndex)
					if groupIndex then
						local frame = _G["CompactRaidGroup" .. groupIndex]
						if frame then
							frame.title:Hide()
						end
					end
				end

				hooksecurefunc("CompactRaidGroup_GenerateForGroup", function(index)
					HideRaidContainerGroupTitles(index)
				end)

				for index = 1, 8 do
					HideRaidContainerGroupTitles(index)
				end

			end)

			-- Hide compact party frame title
			if CompactPartyFrame and CompactPartyFrame.title and CompactPartyFrame.title:IsShown() then CompactPartyFrame.title:Hide() end
			hooksecurefunc("CompactPartyFrame_Generate", function()
				if CompactPartyFrame and CompactPartyFrame.title and CompactPartyFrame.title:IsShown() then
					CompactPartyFrame.title:Hide()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Block friend requests (no reload required)
		----------------------------------------------------------------------

		-- Function to decline friend requests
		local function DeclineReqs()
			if RGXQoLLC["NoFriendRequests"] == "On" then
				for i = BNGetNumFriendInvites(), 1, -1 do
					local id, player = BNGetFriendInviteInfo(i)
					if id and player then
						BNDeclineFriendInvite(id)
						C_Timer.After(0.1, function()
							RGXQoLLC:Print(L["A friend request from"] .. " " .. player .. " " .. L["was automatically declined."])
						end)
					end
				end
			end
		end

		-- Event frame for incoming friend requests
		local DecEvt = CreateFrame("FRAME")
		DecEvt:SetScript("OnEvent", DeclineReqs)

		-- Function to register or unregister the event
		local function ControlEvent()
			if RGXQoLLC["NoFriendRequests"] == "On" then
				DecEvt:RegisterEvent("BN_FRIEND_INVITE_ADDED")
				DeclineReqs()
			else
				DecEvt:UnregisterEvent("BN_FRIEND_INVITE_ADDED")
			end
		end

		-- Set event status when option is clicked and on startup
		if RGXQoLCB["NoFriendRequests"] then
			RGXQoLCB["NoFriendRequests"]:HookScript("OnClick", ControlEvent)
			ControlEvent()
		end

		----------------------------------------------------------------------
		--	Block duels (no reload required)
		----------------------------------------------------------------------

		do

			-- Handler for event
			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1)
				if event == "DUEL_REQUESTED" and not RGXQoLLC:FriendCheck(arg1) then
					CancelDuel()
					StaticPopup_Hide("DUEL_REQUESTED")
					return
				elseif event == "DUEL_TO_THE_DEATH_REQUESTED" and not RGXQoLLC:FriendCheck(arg1) then
					CancelDuel()
					StaticPopup_Hide("DUEL_TO_THE_DEATH_REQUESTED")
					return
				end
			end)

			-- Function to set event
			local function SetEvent()
				if RGXQoLLC["NoDuelRequests"] == "On" then
					frame:RegisterEvent("DUEL_REQUESTED")
					frame:RegisterEvent("DUEL_TO_THE_DEATH_REQUESTED")
				else
					frame:UnregisterEvent("DUEL_REQUESTED")
					frame:UnregisterEvent("DUEL_TO_THE_DEATH_REQUESTED")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if RGXQoLLC["NoDuelRequests"] == "On" then SetEvent() end
			RGXQoLCB["NoDuelRequests"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		--	Invite from whispers (no reload required)
		----------------------------------------------------------------------

		do

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
				if (not UnitExists("party1") or UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and strlower(strtrim(arg1)) == strlower(RGXQoLLC["InvKey"]) then
					if not RGXQoLLC:IsInLFGQueue() then
						if event == "CHAT_MSG_WHISPER" then
							local void, void, void, void, void, void, void, void, void, guid = ...
							if RGXQoLLC:FriendCheck(arg2, guid) or RGXQoLLC["InviteFriendsOnly"] == "Off" then
								-- If whisper name is same realm, remove realm name
								local theWhisperName, theWhisperRealm = strsplit("-", arg2, 2)
								if theWhisperRealm then
									local void, theCharRealm = UnitFullName("player")
									if theCharRealm then
										if theWhisperRealm == theCharRealm then arg2 = theWhisperName end
									end
								end

								-- Invite whisper player
								C_PartyInfo.InviteUnit(arg2)
							end
						elseif event == "CHAT_MSG_BN_WHISPER" then
							local presenceID = select(11, ...)
							if presenceID and BNIsFriend(presenceID) then
								local index = BNGetFriendIndex(presenceID)
								if index then
									local accountInfo = C_BattleNet.GetFriendAccountInfo(index)
									local gameAccountInfo = accountInfo.gameAccountInfo
									local gameAccountID = gameAccountInfo.gameAccountID
									if gameAccountID then
										BNInviteFriend(gameAccountID)
									end
								end
							end
						end
					end
				end
				return
			end)

			-- Function to set event
			local function SetEvent()
				if RGXQoLLC["InviteFromWhisper"] == "On" then
					frame:RegisterEvent("CHAT_MSG_WHISPER")
					frame:RegisterEvent("CHAT_MSG_BN_WHISPER")
				else
					frame:UnregisterEvent("CHAT_MSG_WHISPER")
					frame:UnregisterEvent("CHAT_MSG_BN_WHISPER")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if RGXQoLLC["InviteFromWhisper"] == "On" then SetEvent() end
			RGXQoLCB["InviteFromWhisper"]:HookScript("OnClick", SetEvent)

			-- Create configuration panel
			local InvPanel = RGXQoLLC:CreatePanel("Invite from whispers", "InvPanel")

			-- Add editbox
			RGXQoLLC:MakeTx(InvPanel, "Settings", 16, -72)
			RGXQoLLC:MakeCB(InvPanel, "InviteFriendsOnly", "Restrict to friends", 16, -92, false, "If checked, group invites will only be sent to friends.|n|nIf unchecked, group invites will be sent to everyone.")

			RGXQoLLC:MakeTx(InvPanel, "Keyword", 356, -72)
			local KeyBox = RGXQoLLC:CreateEditBox("KeyBox", InvPanel, 140, 10, "TOPLEFT", 356, -92, "KeyBox", "KeyBox")

			-- Function to show the keyword in the option tooltip
			local function SetKeywordTip()
				RGXQoLCB["InviteFromWhisper"].tiptext = gsub(RGXQoLCB["InviteFromWhisper"].tiptext, "(|cffffffff)[^|]*(|r)",  "%1" .. RGXQoLLC["InvKey"] .. "%2")
			end

			-- Function to save the keyword
			local function SetInvKey()
				local keytext = KeyBox:GetText()
				if keytext and keytext ~= "" then
					RGXQoLLC["InvKey"] = strtrim(KeyBox:GetText())
				else
					RGXQoLLC["InvKey"] = "inv"
				end
				-- Show the keyword in the option tooltip
				SetKeywordTip()
			end

			-- Show the keyword in the option tooltip on startup
			SetKeywordTip()

			-- Save the keyword when it changes
			KeyBox:SetScript("OnTextChanged", SetInvKey)

			-- Refresh editbox with trimmed keyword when edit focus is lost (removes additional spaces)
			KeyBox:SetScript("OnEditFocusLost", function()
				KeyBox:SetText(RGXQoLLC["InvKey"])
			end)

			-- Help button hidden
			InvPanel.h:Hide()

			-- Back button handler
			InvPanel.b:SetScript("OnClick", function()
				-- Save the keyword
				SetInvKey()
				-- Show the options panel
				InvPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page2"]:Show()
				return
			end)

			-- Add reset button
			InvPanel.r:SetScript("OnClick", function()
				-- Settings
				RGXQoLLC["InviteFriendsOnly"] = "Off"
				-- Reset the keyword to default
				RGXQoLLC["InvKey"] = "inv"
				-- Set the editbox to default
				KeyBox:SetText("inv")
				-- Save the keyword
				SetInvKey()
				-- Refresh panel
				InvPanel:Hide(); InvPanel:Show()
			end)

			-- Ensure keyword is a string on startup
			RGXQoLLC["InvKey"] = tostring(RGXQoLLC["InvKey"]) or "inv"

			-- Set editbox value when shown
			KeyBox:HookScript("OnShow", function()
				KeyBox:SetText(RGXQoLLC["InvKey"])
			end)

			-- Configuration button handler
			RGXQoLCB["InvWhisperBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["InviteFriendsOnly"] = "On"
					RGXQoLLC["InvKey"] = "inv"
					KeyBox:SetText(RGXQoLLC["InvKey"])
					SetInvKey()
				else
					-- Show panel
					InvPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Party from friends (no reload required)
		----------------------------------------------------------------------

		do

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1, ...)

				-- If a friend, accept if you're accepting friends and not queued
				local void, void, void, void, void, guid = ...
				if (RGXQoLLC["AcceptPartyFriends"] == "On" and RGXQoLLC:FriendCheck(arg1, guid)) then
					if not RGXQoLLC:IsInLFGQueue() then
						AcceptGroup()
						StaticPopup_ForEachShownDialog(function(self)
							if self.which == "PARTY_INVITE" then
								self.inviteAccepted = 1
								StaticPopup_Hide("PARTY_INVITE")
								return
							elseif self.which == "PARTY_INVITE_XREALM" then
								self.inviteAccepted = 1
								StaticPopup_Hide("PARTY_INVITE_XREALM")
								return
							end
						end)
						return
					end
				end
			end)

			-- Function to set event
			local function SetEvent()
				if RGXQoLLC["AcceptPartyFriends"] == "On" then
					frame:RegisterEvent("PARTY_INVITE_REQUEST")
				else
					frame:UnregisterEvent("PARTY_INVITE_REQUEST")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if RGXQoLLC["AcceptPartyFriends"] == "On" then SetEvent() end
			RGXQoLCB["AcceptPartyFriends"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		--	Block party invites (no reload required)
		----------------------------------------------------------------------

		do

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1, ...)
				-- If not a friend and you're blocking invites, decline
				local void, void, void, void, void, guid = ...
				if RGXQoLLC["NoPartyInvites"] == "On" then
					if RGXQoLLC:FriendCheck(arg1, guid) then
						return
					else
						DeclineGroup()
						StaticPopup_Hide("PARTY_INVITE")
						StaticPopup_Hide("PARTY_INVITE_XREALM")
						return
					end
				end
			end)

			-- Function to set event
			local function SetEvent()
				if RGXQoLLC["NoPartyInvites"] == "On" then
					frame:RegisterEvent("PARTY_INVITE_REQUEST")
				else
					frame:UnregisterEvent("PARTY_INVITE_REQUEST")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if RGXQoLLC["NoPartyInvites"] == "On" then SetEvent() end
			RGXQoLCB["NoPartyInvites"]:HookScript("OnClick", SetEvent)

		end

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

			-- Set event on startup if enabled and when option is clicked
			if RGXQoLLC["AutoAcceptSummon"] == "On" then SetEvent() end
			RGXQoLCB["AutoAcceptSummon"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		--	Disable loot warnings
		----------------------------------------------------------------------

		do

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
				-- Disable warnings for attempting to roll Need on loot
				if event == "CONFIRM_LOOT_ROLL" then
					ConfirmLootRoll(arg1, arg2)
					StaticPopup_Hide("CONFIRM_LOOT_ROLL")
					return
				end

				-- Disable warning for attempting to loot a Bind on Pickup item
				if event == "LOOT_BIND_CONFIRM" then
					ConfirmLootSlot(arg1, arg2)
					StaticPopup_Hide("LOOT_BIND",...)
					return
				end

				-- Disable warning for attempting to vendor an item within its refund window
				if event == "MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL" then
					SellCursorItem()
					return
				end

				-- Disable warning for attempting to mail an item within its refund window
				if event == "MAIL_LOCK_SEND_ITEMS" then
					RespondMailLockSendItem(arg1, true)
					return
				end
			end)

			-- Function to set event
			local function SetEvent()
				if RGXQoLLC["NoConfirmLoot"] == "On" then
					frame:RegisterEvent("CONFIRM_LOOT_ROLL")
					frame:RegisterEvent("LOOT_BIND_CONFIRM")
					frame:RegisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
					frame:RegisterEvent("MAIL_LOCK_SEND_ITEMS")
				else
					frame:UnregisterEvent("CONFIRM_LOOT_ROLL")
					frame:UnregisterEvent("LOOT_BIND_CONFIRM")
					frame:UnregisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
					frame:UnregisterEvent("MAIL_LOCK_SEND_ITEMS")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if RGXQoLLC["NoConfirmLoot"] == "On" then SetEvent() end
			RGXQoLCB["NoConfirmLoot"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		-- Mute mount sounds (no reload required)
		----------------------------------------------------------------------

		do

			-- Get mute table
			local mountTable = RGXQoLAddon["mountTable"]

			-- Give table file level scope (its used during logout and for wipe and admin commands)
			RGXQoLLC["mountTable"] = mountTable

			-- Load saved settings or set default values
			for k, v in pairs(mountTable) do
				if RGXQoLDB[k] and type(RGXQoLDB[k]) == "string" and RGXQoLDB[k] == "On" or RGXQoLDB[k] == "Off" then
					RGXQoLLC[k] = RGXQoLDB[k]
				else
					RGXQoLLC[k] = "Off"
					RGXQoLDB[k] = "Off"
				end
			end

			-- Create configuration panel
			local MountPanel = RGXQoLLC:CreatePanel("Mute mount sounds", "MountPanel")

			-- Add checkboxes
			RGXQoLLC:MakeTx(MountPanel, "Mounts", 16, -72)
			RGXQoLLC:MakeCB(MountPanel, "MuteMechSteps", "Mechsteps", 16, -92, false, "If checked, footsteps for mechanical mounts will be muted.")
			RGXQoLLC:MakeCB(MountPanel, "MuteStriders", "Mechstriders", 16, -112, false, "If checked, mechanostriders will be quieter.")
			RGXQoLLC:MakeCB(MountPanel, "MuteHorsesteps", "Horsesteps", 16, -132, false, "If checked, footsteps for horse mounts will be muted.")

			-- Set click width for sounds checkboxes
			for k, v in pairs(mountTable) do
				RGXQoLCB[k].f:SetWidth(90)
				if RGXQoLCB[k].f:GetStringWidth() > 90 then
					RGXQoLCB[k]:SetHitRectInsets(0, -80, 0, 0)
				else
					RGXQoLCB[k]:SetHitRectInsets(0, -RGXQoLCB[k].f:GetStringWidth() + 4, 0, 0)
				end
			end

			-- Function to mute and unmute sounds
			local function SetupMute()
				-- Sound features removed on this build (BLU owns sounds)
				do return end
				for k, v in pairs(mountTable) do
					if RGXQoLLC["MuteMountSounds"] == "On" and RGXQoLLC[k] == "On" then
						for i, e in pairs(v) do
							local file, soundID = e:match("([^,]+)%#([^,]+)")
							MuteSoundFile(soundID)
						end
					else
						for i, e in pairs(v) do
							local file, soundID = e:match("([^,]+)%#([^,]+)")
							UnmuteSoundFile(soundID)
						end
					end
				end
			end

			-- Setup mute on startup if option is enabled
			if RGXQoLLC["MuteMountSounds"] == "On" then SetupMute() end

			-- Setup mute when options are clicked
			for k, v in pairs(mountTable) do
				RGXQoLCB[k]:HookScript("OnClick", SetupMute)
			end
			RGXQoLCB["MuteMountSounds"]:HookScript("OnClick", SetupMute)

			-- Help button hidden
			MountPanel.h:Hide()

			-- Back button handler
			MountPanel.b:SetScript("OnClick", function()
				MountPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			MountPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				for k, v in pairs(mountTable) do
					RGXQoLLC[k] = "Off"
				end
				SetupMute()

				-- Refresh panel
				MountPanel:Hide(); MountPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			RGXQoLCB["MuteMountSoundsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					for k, v in pairs(mountTable) do
						RGXQoLLC[k] = "On"
					end
					SetupMute()
				else
					MountPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Mute game sounds (no reload required) (MuteGameSounds)
		----------------------------------------------------------------------

		do

			-- Get mute table
			local muteTable = RGXQoLAddon["muteTable"]

			-- Give table file level scope (its used during logout and for wipe and admin commands)
			RGXQoLLC["muteTable"] = muteTable

			-- Load saved settings or set default values
			for k, v in pairs(muteTable) do
				if RGXQoLDB[k] and type(RGXQoLDB[k]) == "string" and RGXQoLDB[k] == "On" or RGXQoLDB[k] == "Off" then
					RGXQoLLC[k] = RGXQoLDB[k]
				else
					RGXQoLLC[k] = "Off"
					RGXQoLDB[k] = "Off"
				end
			end

			-- Create configuration panel
			local SoundPanel = RGXQoLLC:CreatePanel("Mute game sounds", "SoundPanel")

			-- Add checkboxes
			RGXQoLLC:MakeTx(SoundPanel, "General", 16, -72)
			RGXQoLLC:MakeCB(SoundPanel, "MuteChimes", "Chimes", 16, -92, false, "If checked, clock hourly chimes will be muted.")
			RGXQoLLC:MakeCB(SoundPanel, "MuteFizzle", "Fizzle", 16, -112, false, "If checked, the spell fizzle sounds will be muted.")
			RGXQoLLC:MakeCB(SoundPanel, "MuteInterface", "Interface", 16, -132, false, "If checked, the interface button sound, the chat frame tab click sound and the game menu toggle sound will be muted.")
			RGXQoLLC:MakeCB(SoundPanel, "MuteLogin", "Login", 16, -152, false, "If checked, login screen sounds will be muted when you logout of the game.|n|nNote that login screen sounds will not be muted when you initially launch the game.|n|nThey will only be muted when you logout of the game.  This includes manually logging out as well as being forcefully logged out by the game server for reasons such as being away for an extended period of time.")
			RGXQoLLC:MakeCB(SoundPanel, "MuteTrains", "Trains", 16, -172, false, "If checked, train sounds will be muted.")
			RGXQoLLC:MakeCB(SoundPanel, "MuteReady", "Ready", 16, -192, false, "If checked, the ready check sound will be muted.")

			RGXQoLLC:MakeTx(SoundPanel, "Pets", 150, -72)
			RGXQoLLC:MakeCB(SoundPanel, "MuteScreech", "Screech", 150, -92, false, "If checked, Screech will be muted.|n|nThis is a spell used by some flying pets.")
			RGXQoLLC:MakeCB(SoundPanel, "MuteYawns", "Yawns", 150, -112, false, "If checked, yawns from hunter pet cats will be muted.")

			RGXQoLLC:MakeTx(SoundPanel, "Toys", 150, -152)
			RGXQoLLC:MakeCB(SoundPanel, "MutePiccolo", "Piccolo", 150, -172, false, "If checked, Piccolo of the Flaming Fire wil be muted.|n|nNote that enabling this will also mute the harp sound of the warlock seduction spell.")

			-- Set click width for sounds checkboxes
			for k, v in pairs(muteTable) do
				RGXQoLCB[k].f:SetWidth(90)
				if RGXQoLCB[k].f:GetStringWidth() > 90 then
					RGXQoLCB[k]:SetHitRectInsets(0, -80, 0, 0)
				else
					RGXQoLCB[k]:SetHitRectInsets(0, -RGXQoLCB[k].f:GetStringWidth() + 4, 0, 0)
				end
			end

			-- Function to mute and unmute sounds
			local function SetupMute()
				-- Sound features removed on this build (BLU owns sounds)
				do return end
				for k, v in pairs(muteTable) do
					if RGXQoLLC["MuteGameSounds"] == "On" and RGXQoLLC[k] == "On" then
						for i, e in pairs(v) do
							local file, soundID = e:match("([^,]+)%#([^,]+)")
							MuteSoundFile(soundID)
						end
					else
						for i, e in pairs(v) do
							local file, soundID = e:match("([^,]+)%#([^,]+)")
							UnmuteSoundFile(soundID)
						end
					end
				end
			end

			-- Setup mute on startup if option is enabled
			if RGXQoLLC["MuteGameSounds"] == "On" then SetupMute() end

			-- Setup mute when options are clicked
			for k, v in pairs(muteTable) do
				RGXQoLCB[k]:HookScript("OnClick", SetupMute)
			end
			RGXQoLCB["MuteGameSounds"]:HookScript("OnClick", SetupMute)

			-- Help button hidden
			SoundPanel.h:Hide()

			-- Back button handler
			SoundPanel.b:SetScript("OnClick", function()
				SoundPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			SoundPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				for k, v in pairs(muteTable) do
					RGXQoLLC[k] = "Off"
				end
				SetupMute()

				-- Refresh panel
				SoundPanel:Hide(); SoundPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			RGXQoLCB["MuteGameSoundsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					for k, v in pairs(muteTable) do
						RGXQoLLC[k] = "On"
					end
					RGXQoLLC["MuteReady"] = "Off"
					SetupMute()
				else
					SoundPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

			----------------------------------------------------------------------
			-- Login setting
			----------------------------------------------------------------------

			-- Create soundtable for PLAYER_LOGOUT (these sounds are only muted or unmuted when logging out
			local muteLogoutTable = {

				-- Game music (sound/music/gluescreenmusic/wow_main_theme.mp3) (skit:47598)
				"53223",

			}

			-- Handle sounds that get muted or unmuted when logging out
			local logoutEvent = CreateFrame("FRAME")
			logoutEvent:RegisterEvent("PLAYER_LOGOUT")

			-- Mute or unmute sounds when logging out
			logoutEvent:SetScript("OnEvent", function()
				if RGXQoLLC["MuteGameSounds"] == "On" and RGXQoLLC["MuteLogin"] == "On" then
					-- Mute logout table sounds on logout
					for void, soundID in pairs(muteLogoutTable) do
						MuteSoundFile(soundID)
					end
				else
					-- Unmute logout table sounds on logout
					for void, soundID in pairs(muteLogoutTable) do
						UnmuteSoundFile(soundID)
					end
				end
			end)

			-- Unmute sounds when logging in
			for void, soundID in pairs(muteLogoutTable) do
				UnmuteSoundFile(soundID)
			end

		end

		----------------------------------------------------------------------
		-- Faster movie skip
		----------------------------------------------------------------------

		if RGXQoLLC["FasterMovieSkip"] == "On" then

			-- Allow space bar, escape key and enter key to cancel cinematic without confirmation
			CinematicFrame:HookScript("OnKeyDown", function(self, key)
				if key == "ESCAPE" then
					if CinematicFrame:IsShown() and CinematicFrame.closeDialog and CinematicFrameCloseDialogConfirmButton then
						CinematicFrameCloseDialog:Hide()
					end
				end
			end)
			CinematicFrame:HookScript("OnKeyUp", function(self, key)
				if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
					if CinematicFrame:IsShown() and CinematicFrame.closeDialog and CinematicFrameCloseDialogConfirmButton then
						CinematicFrameCloseDialogConfirmButton:Click()
					end
				end
			end)
			MovieFrame:HookScript("OnKeyUp", function(self, key)
				if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
					if MovieFrame:IsShown() and MovieFrame.CloseDialog and MovieFrame.CloseDialog.ConfirmButton then
						MovieFrame.CloseDialog.ConfirmButton:Click()
					end
				end
			end)

		end

		----------------------------------------------------------------------
		-- Wowhead Links
		----------------------------------------------------------------------

		if RGXQoLLC["ShowWowheadLinks"] == "On" then

			-- Create configuration panel
			local WowheadPanel = RGXQoLLC:CreatePanel("Show Wowhead links", "WowheadPanel")

			RGXQoLLC:MakeTx(WowheadPanel, "Settings", 16, -72)
			RGXQoLLC:MakeCB(WowheadPanel, "WowheadLinkComments", "Links go directly to the comments section", 16, -92, false, "If checked, Wowhead links will go directly to the comments section.")

			-- Help button hidden
			WowheadPanel.h:Hide()

			-- Back button handler
			WowheadPanel.b:SetScript("OnClick", function()
				WowheadPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			WowheadPanel.r:SetScript("OnClick", function()

				-- Reset controls
				RGXQoLLC["WowheadLinkComments"] = "Off"

				-- Refresh configuration panel
				WowheadPanel:Hide(); WowheadPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			RGXQoLCB["ShowWowheadLinksBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["WowheadLinkComments"] = "Off"
				else
					WowheadPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

			-- Get localised Wowhead URL
			local wowheadLoc
			if GameLocale == "deDE" then wowheadLoc = "de.classic.wowhead.com"
			elseif GameLocale == "esMX" then wowheadLoc = "mx.classic.wowhead.com"
			elseif GameLocale == "esES" then wowheadLoc = "es.classic.wowhead.com"
			elseif GameLocale == "frFR" then wowheadLoc = "fr.classic.wowhead.com"
			elseif GameLocale == "itIT" then wowheadLoc = "it.classic.wowhead.com"
			elseif GameLocale == "ptBR" then wowheadLoc = "pt.classic.wowhead.com"
			elseif GameLocale == "ruRU" then wowheadLoc = "ru.classic.wowhead.com"
			elseif GameLocale == "koKR" then wowheadLoc = "ko.classic.wowhead.com"
			elseif GameLocale == "zhCN" then wowheadLoc = "cn.classic.wowhead.com"
			elseif GameLocale == "zhTW" then wowheadLoc = "tw.classic.wowhead.com"
			else							 wowheadLoc = "classic.wowhead.com"
			end

			-- Create editbox
			local mEB = CreateFrame("EditBox", nil, QuestLogFrame)
			mEB:ClearAllPoints()
			mEB:SetPoint("TOPLEFT", 70, 4)
			mEB:SetHeight(16)
			mEB:SetFontObject("GameFontNormal")
			mEB:SetBlinkSpeed(0)
			mEB:SetAutoFocus(false)
			mEB:EnableKeyboard(false)
			mEB:SetHitRectInsets(0, 90, 0, 0)
			mEB:SetScript("OnKeyDown", function() end)
			mEB:SetScript("OnMouseUp", function()
				if mEB:IsMouseOver() then
					mEB:HighlightText()
				else
					mEB:HighlightText(0, 0)
				end
			end)

			-- Set the background color
			mEB.t = mEB:CreateTexture(nil, "BACKGROUND")
			mEB.t:SetPoint(mEB:GetPoint())
			mEB.t:SetSize(mEB:GetSize())
			mEB.t:SetColorTexture(0.05, 0.05, 0.05, 1.0)

			-- Create hidden font string (used for setting width of editbox)
			mEB.z = mEB:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			mEB.z:Hide()

			-- Function to set editbox value
			local function SetQuestInBox(questListID)

				local questTitle, void, void, isHeader, void, void, void, questID = GetQuestLogTitle(questListID)
				if questID and not isHeader then

					-- Hide editbox if quest ID is invalid
					if questID == 0 then mEB:Hide() else mEB:Show() end

					-- Set editbox text
					if RGXQoLLC["WowheadLinkComments"] == "On" then
						mEB:SetText("https://" .. wowheadLoc .. "/quest=" .. questID .. "#comments")
					else
						mEB:SetText("https://" .. wowheadLoc .. "/quest=" .. questID)
					end

					-- Set hidden fontstring then resize editbox to match
					mEB.z:SetText(mEB:GetText())
					mEB:SetWidth(mEB.z:GetStringWidth() + 90)
					mEB.t:SetWidth(mEB.z:GetStringWidth())

					-- Get quest title for tooltip
					if questTitle then
						mEB.tiptext = questTitle .. "|n" .. L["Press CTRL/C to copy."]
					else
						mEB.tiptext = ""
						if mEB:IsMouseOver() and GameTooltip:IsShown() then GameTooltip:Hide() end
					end

				end
			end

			-- Set URL when quest is selected (this works with Questie, old method used QuestLog_SetSelection)
			hooksecurefunc("SelectQuestLogEntry", function(questListID)
				SetQuestInBox(questListID)
			end)

			-- Create tooltip
			mEB:HookScript("OnEnter", function()
				mEB:HighlightText()
				mEB:SetFocus()
				GameTooltip:SetOwner(mEB, "ANCHOR_BOTTOM", 0, -10)
				GameTooltip:SetText(mEB.tiptext, nil, nil, nil, nil, true)
				GameTooltip:Show()
			end)

			mEB:HookScript("OnLeave", function()
				mEB:HighlightText(0, 0)
				mEB:ClearFocus()
				GameTooltip:Hide()
			end)

			-- ElvUI fix to move Wowhead link inside the quest log frame
			if RGXQoLLC.ElvUI then
				C_Timer.After(0.1, function()
					QuestLogTitleText:ClearAllPoints()
					QuestLogTitleText:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 32, -18)
					if QuestLogTitleText:GetStringWidth() > 200 then
						QuestLogTitleText:SetWidth(200)
					else
						QuestLogTitleText:SetWidth(QuestLogTitleText:GetStringWidth())
					end
					mEB:ClearAllPoints()
					mEB:SetPoint("LEFT", QuestLogTitleText, "RIGHT", 10, 0)
					mEB.t:Hide()
				end)
			end

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

			-- Setup events when option is clicked and on startup (if option is enabled)
			RGXQoLCB["AutomateGossip"]:HookScript("OnClick", SetupEvents)
			if RGXQoLLC["AutomateGossip"] == "On" then SetupEvents() end

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
			hooksecurefunc("BattlefieldFrame_Update", function()
				if RGXQoLLC["AutomateGossip"] == "On" then
					local localizedName = GetBattlegroundInfo()
					if localizedName then
						BattlefieldFrameFrameLabel:SetText(localizedName)
					end
				end
			end)

		end

		----------------------------------------------------------------------
		--	Faster looting
		----------------------------------------------------------------------

		if RGXQoLLC["FasterLooting"] == "On" then

			-- Time delay
			local tDelay = 0

			-- Fast loot function
			local function FastLoot()
				if GetTime() - tDelay >= 0.3 then
					tDelay = GetTime()
					if GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE") then
						if TSMDestroyBtn and TSMDestroyBtn:IsShown() and TSMDestroyBtn:GetButtonState() == "DISABLED" then tDelay = GetTime() return end
						local lootMethod = C_PartyInfo.GetLootMethod()
						if lootMethod == 2 then
							-- Master loot is enabled so fast loot if item should be auto looted
							local lootThreshold = GetLootThreshold()
							for i = GetNumLootItems(), 1, -1 do
								local lootIcon, lootName, lootQuantity, currencyID, lootQuality = GetLootSlotInfo(i)
								if lootQuality and lootThreshold and lootQuality < lootThreshold then
									LootSlot(i)
								end
							end
						else
							-- Master loot is disabled so fast loot regardless
							for i = GetNumLootItems(), 1, -1 do
								LootSlot(i)
							end
						end
						tDelay = GetTime()
					end
				end
			end

			-- Event frame
			local faster = CreateFrame("Frame")
			faster:RegisterEvent("LOOT_READY")
			faster:SetScript("OnEvent", FastLoot)

		end

		----------------------------------------------------------------------
		--	Disable bag automation
		----------------------------------------------------------------------

		if RGXQoLLC["NoBagAutomation"] == "On" and not RGXQoLLockList["NoBagAutomation"] then
			RunScript("hooksecurefunc('OpenAllBags', CloseAllBags)")
		end

		----------------------------------------------------------------------
		--	Automate quests (no reload required)
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local QuestPanel = RGXQoLLC:CreatePanel("Automate quests", "QuestPanel")

			RGXQoLLC:MakeTx(QuestPanel, "Settings", 16, -72)
			RGXQoLLC:MakeCB(QuestPanel, "AutoQuestAvailable", "Accept available quests automatically", 16, -92, false, "If checked, available quests will be accepted automatically.")
			RGXQoLLC:MakeCB(QuestPanel, "AutoQuestCompleted", "Turn-in completed quests automatically", 16, -112, false, "If checked, completed quests will be turned-in automatically.")
			RGXQoLLC:MakeCB(QuestPanel, "AutoQuestShift", "Require override key for quest automation", 16, -132, false, "If checked, you will need to hold the override key down for quests to be automated.|n|nIf unchecked, holding the override key will prevent quests from being automated.")

			RGXQoLLC:CreateDropdown("AutoQuestKeyMenu", "Override key", 146, "TOPLEFT", QuestPanel, "TOPLEFT", 356, -92, {{L["SHIFT"], 1}, {L["ALT"], 2}, {L["CONTROL"], 3}, {L["CMD (MAC)"], 4}})

			-- Help button hidden
			QuestPanel.h:Hide()

			-- Back button handler
			QuestPanel.b:SetScript("OnClick", function()
				QuestPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			QuestPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				RGXQoLLC["AutoQuestShift"] = "Off"
				RGXQoLLC["AutoQuestAvailable"] = "On"
				RGXQoLLC["AutoQuestCompleted"] = "On"
				RGXQoLLC["AutoQuestKeyMenu"] = 1

				-- Refresh panel
				QuestPanel:Hide(); QuestPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			RGXQoLCB["AutomateQuestsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["AutoQuestShift"] = "Off"
					RGXQoLLC["AutoQuestAvailable"] = "On"
					RGXQoLLC["AutoQuestCompleted"] = "On"
					RGXQoLLC["AutoQuestKeyMenu"] = 1
				else
					QuestPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

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

			-- Setup events when option is clicked and on startup (if option is enabled)
			RGXQoLCB["AutomateQuests"]:HookScript("OnClick", SetupEvents)
			if RGXQoLLC["AutomateQuests"] == "On" then SetupEvents() end

			-- Event handler
			qFrame:SetScript("OnEvent", function(self, event, arg1)

				-- Block shared quests if option is enabled
				if event == "QUEST_DETAIL" then
					RGXQoLLC:CheckIfQuestIsSharedAndShouldBeDeclined()
				end

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
			local function LeaPlusNewTicker(duration, callback, iterations)
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
			local SellJunkFrame = RGXQoLLC:CreatePanel("Sell junk automatically", "SellJunkFrame")
			RGXQoLLC:MakeTx(SellJunkFrame, "Settings", 16, -72)
			RGXQoLLC:MakeCB(SellJunkFrame, "AutoSellShowSummary", "Show vendor summary in chat", 16, -92, false, "If checked, a vendor summary will be shown in chat when junk is automatically sold.")

			-- Help button hidden
			SellJunkFrame.h:Hide()

			-- Back button handler
			SellJunkFrame.b:SetScript("OnClick", function()
				SellJunkFrame:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			SellJunkFrame.r.tiptext = SellJunkFrame.r.tiptext .. "|n|n" .. L["Note that this will not reset your exclusions list."]
			SellJunkFrame.r:SetScript("OnClick", function()

				-- Reset checkboxes
				RGXQoLLC["AutoSellShowSummary"] = "On"

				-- Refresh panel
				SellJunkFrame:Hide(); SellJunkFrame:Show()

			end)

			-- Show panal when options panel button is clicked
			RGXQoLCB["AutoSellJunkBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["AutoSellShowSummary"] = "On"
				else
					SellJunkFrame:Show()
					RGXQoLLC:HideFrames()
				end
			end)

			-- Function to stop selling
			local function StopSelling()
				if SellJunkTicker then SellJunkTicker._cancelled = true; end
				StartMsg:Hide()
				SellJunkFrame:UnregisterEvent("ITEM_LOCKED")
				SellJunkFrame:UnregisterEvent("UI_ERROR_MESSAGE")
			end

			-- Create excluded box
			local titleTX = RGXQoLLC:MakeTx(SellJunkFrame, "Exclusions", 356, -72)
			titleTX:SetWidth(200)
			titleTX:SetWordWrap(false)
			titleTX:SetJustifyH("LEFT")

			-- Show help button for exclusions
			RGXQoLLC:CreateHelpButton("SellJunkExcludeHelpButton", SellJunkFrame, titleTX, "Enter item IDs separated by commas.  Item IDs can be found in item tooltips while this panel is showing.|n|nJunk items entered here will not be sold automatically.|n|nWhite items entered here will be sold automatically.|n|nThe editbox tooltip will show you more information about the items you have entered.")

			local eb = CreateFrame("Frame", nil, SellJunkFrame, "BackdropTemplate")
			eb:SetSize(200, RGXQoLLC.MainPanelHeight - 180)
			eb:SetPoint("TOPLEFT", 350, -92)
			eb:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
				edgeSize = 16,
				insets = {left = 8, right = 6, top = 8, bottom = 8},
			})
			eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)

			eb.scroll = CreateFrame("ScrollFrame", nil, eb, "RGXQoLSellJunkScrollFrameTemplate")
			eb.scroll:SetPoint("TOPLEFT", eb, 12, -10)
			eb.scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)
			eb.scroll:SetPanExtent(16)

			-- Create character count
			eb.scroll.CharCount = eb.scroll:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			eb.scroll.CharCount:Hide()

			eb.Text = eb.scroll.EditBox
			eb.Text:SetWidth(150)
			eb.Text:SetPoint("TOPLEFT", eb.scroll)
			eb.Text:SetPoint("BOTTOMRIGHT", eb.scroll, -12, 0)
			eb.Text:SetMaxLetters(2000)
			eb.Text:SetFontObject(GameFontNormalLarge)
			eb.Text:SetAutoFocus(false)
			eb.scroll:SetScrollChild(eb.Text)

			-- Set focus on the editbox text when clicking the editbox
			eb:SetScript("OnMouseDown", function()
				eb.Text:SetFocus()
				eb.Text:SetCursorPosition(eb.Text:GetMaxLetters())
			end)

			-- Function to create whitelist
			local whiteList = {}
			local function UpdateWhiteList()
				wipe(whiteList)

				local whiteString = eb.Text:GetText()
				if whiteString and whiteString ~= "" then
					whiteString = whiteString:gsub("[^,%d]", "")
					local tList = {strsplit(",", whiteString)}
					for i = 1, #tList do
						if tList[i] then
							tList[i] = tonumber(tList[i])
							if tList[i] then
								whiteList[tList[i]] = true
							end
						end
					end
				end

				RGXQoLLC["AutoSellExcludeList"] = whiteString
				eb.Text:SetText(RGXQoLLC["AutoSellExcludeList"])

			end

			-- Save the excluded list when it changes and at startup
			eb.Text:SetScript("OnTextChanged", UpdateWhiteList)
			eb.Text:SetText(RGXQoLLC["AutoSellExcludeList"])
			UpdateWhiteList()

			-- Create whitelist on startup and option or preset is clicked
			UpdateWhiteList()
			RGXQoLCB["AutoSellJunkBtn"]:HookScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					UpdateWhiteList()
				end
			end)

			-- Function to make tooltip string
			local function MakeTooltipString()

				local keepMsg = ""
				local sellMsg = ""
				local dupMsg = ""
				local novalueMsg = ""
				local incompatMsg = ""

				local tipString = eb.Text:GetText()
				if tipString and tipString ~= "" then
					tipString = tipString:gsub("[^,%d]", "")
					local tipList = {strsplit(",", tipString)}
					for i = 1, #tipList do
						if tipList[i] then
							tipList[i] = tonumber(tipList[i])
							if tipList[i] and tipList[i] > 0 and tipList[i] < 999999999 then
								local void, tLink, Rarity, void, void, void, void, void, void, void, ItemPrice = C_Item.GetItemInfo(tipList[i])
								if tLink and tLink ~= "" then
									local linkCol = string.sub(tLink, 1, 10)
									if linkCol then
										local linkName = tLink:match("%[(.-)%]")
										if linkName and ItemPrice then
											if ItemPrice > 0 then
												if Rarity == 0 then
													-- Junk item
													if string.find(keepMsg, "%(" .. tipList[i] .. "%)") then
														-- Duplicate (ID appears more than once in list)
														dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													else
														-- Add junk item to keep list
														keepMsg = keepMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													end
												elseif Rarity == 1 then
													-- White item
													if string.find(sellMsg, "%(" .. tipList[i] .. "%)") then
														-- Duplicate (ID appears more than once in list)
														dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													else
														-- Add non-junk item to sell list
														sellMsg = sellMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													end
												else
													-- Incompatible item (not junk or white)
													if string.find(incompatMsg, "%(" .. tipList[i] .. "%)") then
														-- Duplicate (ID appears more than once in list)
														dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													else
														-- Add item to incompatible list
														incompatMsg = incompatMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													end
												end
											else
												-- Item has no sell price so cannot be sold
												if string.find(novalueMsg, "%(" .. tipList[i] .. "%)") then
													-- Duplicate (ID appears more than once in list)
													dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
												else
													-- Add item to cannot be sold list
													novalueMsg = novalueMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
												end
											end
										end
									end
								end
							end
						end
					end
				end

				if keepMsg ~= "" then keepMsg = "|n" .. L["Keep"] .. "|n" .. keepMsg end
				if sellMsg ~= "" then sellMsg = "|n" .. L["Sell"] .. "|n" .. sellMsg end
				if dupMsg ~= "" then dupMsg = "|n" .. L["Duplicates"] .. "|n" .. dupMsg end
				if novalueMsg ~= "" then novalueMsg = "|n" .. L["Cannot be sold"] .. "|n" .. novalueMsg end
				if incompatMsg ~= "" then incompatMsg = "|n" .. L["Incompatible"] .. "|n" .. incompatMsg end

				eb.tiptext = L["Exclusions"] .. "|n" .. keepMsg .. sellMsg .. dupMsg .. novalueMsg .. incompatMsg
				eb.Text.tiptext = L["Exclusions"] .. "|n" .. keepMsg .. sellMsg .. dupMsg .. novalueMsg .. incompatMsg
				if eb.tiptext == L["Exclusions"] .. "|n" then eb.tiptext = eb.tiptext .. "|n" .. L["Nothing to see here."] end
				if eb.Text.tiptext == L["Exclusions"] .. "|n" then eb.Text.tiptext = "-" end

				if GameTooltip:IsShown() then
					if MouseIsOver(eb) or MouseIsOver(eb.Text) then
						GameTooltip:SetText(eb.tiptext, nil, nil, nil, nil, false)
					end
				end

			end

			eb.Text:HookScript("OnTextChanged", MakeTooltipString)
			eb.Text:HookScript("OnTextChanged", function()
				C_Timer.After(0.1, function()
					MakeTooltipString()
				end)
			end)

			-- Show the button tooltip for the editbox
			eb:SetScript("OnEnter", MakeTooltipString)
			eb:HookScript("OnEnter", RGXQoLLC.TipSee)
			eb:HookScript("OnEnter", function() GameTooltip:SetText(eb.tiptext, nil, nil, nil, nil, false) end)
			eb:SetScript("OnLeave", GameTooltip_Hide)
			eb.Text:SetScript("OnEnter", MakeTooltipString)
			eb.Text:HookScript("OnEnter", RGXQoLLC.ShowDropTip)
			eb.Text:HookScript("OnEnter", function() GameTooltip:SetText(eb.tiptext, nil, nil, nil, nil, false) end)
			eb.Text:SetScript("OnLeave", GameTooltip_Hide)

			-- Show item ID in item tooltips while configuration panel is showing
			if GameTooltip:HasScript("OnTooltipSetItem") then
				GameTooltip:HookScript("OnTooltipSetItem", function(self)
					if SellJunkFrame:IsShown() then
						local void, itemLink = self:GetItem()
						if itemLink then
							local itemID = GetItemInfoFromHyperlink(itemLink)
							if itemID then self:AddLine(L["Item ID"] .. ": " .. itemID) end
						end
					end
				end)
			end

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
						RGXQoLLC:Print(L["Sold junk for"] .. " " .. GetCoinText(totalPrice) .. ".")
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

			-- Setup events when option is clicked and on startup (if option is enabled)
			RGXQoLCB["AutoSellJunk"]:HookScript("OnClick", SetupEvents)
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
					SellJunkTicker = LeaPlusNewTicker(0.2, SellJunkFunc, IterationCount)
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
								RGXQoLLC:Print(L["Repaired for"] .. " " .. GetCoinText(RepairCost) .. ".")
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

			-- Setup event when option is clicked and on startup (if option is enabled)
			RGXQoLCB["AutoRepairGear"]:HookScript("OnClick", SetupEvent)
			if RGXQoLLC["AutoRepairGear"] == "On" then SetupEvent() end

			-- Event handler
			RepairFrame:SetScript("OnEvent", RepairFunc)

			-- Create configuration panel
			local RepairPanel = RGXQoLLC:CreatePanel("Repair automatically", "RepairPanel")

			RGXQoLLC:MakeTx(RepairPanel, "Settings", 16, -72)
			RGXQoLLC:MakeCB(RepairPanel, "AutoRepairShowSummary", "Show repair summary in chat", 16, -92, false, "If checked, a repair summary will be shown in chat when your gear is automatically repaired.")

			-- Help button hidden
			RepairPanel.h:Hide()

			-- Back button handler
			RepairPanel.b:SetScript("OnClick", function()
				RepairPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			RepairPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				RGXQoLLC["AutoRepairShowSummary"] = "On"

				-- Refresh panel
				RepairPanel:Hide(); RepairPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			RGXQoLCB["AutoRepairBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["AutoRepairShowSummary"] = "On"
				else
					RepairPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Hide the combat log
		----------------------------------------------------------------------

		if RGXQoLLC["NoCombatLogTab"] == "On" and not RGXQoLLockList["NoCombatLogTab"] then

			-- Function to setup the combat log tab
			local function SetupCombatLogTab()
				ChatFrame2Tab:EnableMouse(false)
				ChatFrame2Tab:SetText(" ") -- Needs to be something for chat settings to function
				ChatFrame2Tab:SetScale(0.01)
				ChatFrame2Tab:SetWidth(0.01)
				ChatFrame2Tab:SetHeight(0.01)
			end

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", SetupCombatLogTab)

			-- Ensure combat log is docked
			if ChatFrame2.isDocked then
				-- Set combat log attributes when chat windows are updated
				frame:RegisterEvent("UPDATE_CHAT_WINDOWS")
				-- Set combat log tab placement when tabs are assigned by the client
				hooksecurefunc("FCF_SetTabPosition", function()
					ChatFrame2Tab:SetPoint("BOTTOMLEFT", ChatFrame1Tab, "BOTTOMRIGHT", 0, 0)
				end)
				SetupCombatLogTab()
			else
				-- If combat log is undocked, do nothing but show warning
				C_Timer.After(1, function()
					RGXQoLLC:Print("Combat log cannot be hidden while undocked.")
				end)
			end

		end

		----------------------------------------------------------------------
		--	Show player chain
		----------------------------------------------------------------------

		if RGXQoLLC["ShowPlayerChain"] == "On" and not RGXQoLLockList["ShowPlayerChain"] then

			PlayerFrameTexture:ClearAllPoints()
			PlayerFrameTexture:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", -17, -4)
			PlayerFrameTexture:SetSize(231, 99)

			-- Ensure chain doesnt clip through pet portrait
			PetPortrait:GetParent():SetFrameLevel(4)

			-- Create configuration panel
			local ChainPanel = RGXQoLLC:CreatePanel("Show player chain", "ChainPanel")

			-- Add dropdown menu
			RGXQoLLC:CreateDropdown("PlayerChainMenu", "Chain style", 146, "TOPLEFT", ChainPanel, "TOPLEFT", 16, -92, {{L["RARE"], 1}, {L["ELITE"], 2}, {L["RARE ELITE"], 3}})

			-- Set chain style
			local function SetChainStyle()

				-- If EasyFrames is installed, get the EasyFrames light texture setting
				local EasyFramesLightTexture
				if EasyFramesDB and EasyFramesDB.profiles and EasyFramesDB.profiles.Default and EasyFramesDB.profiles.Default.general and EasyFramesDB.profiles.Default.general.lightTexture then
					EasyFramesLightTexture = true
				end

				-- Get dropdown menu value
				local chain = RGXQoLLC["PlayerChainMenu"] -- Numeric value

				-- Set chain style according to value
				if chain == 1 then -- Rare
					if C_AddOns.IsAddOnLoaded("EasyFrames") then
						PlayerFrameTexture:SetTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus.blp")
						if EasyFramesLightTexture then
							PlayerFrameTexture:SetTexCoord(0, 0.2265, 0.875, 0.9726)
						else
							PlayerFrameTexture:SetTexCoord(0, 0.2265, 0.75, 0.8476)
						end
					else
						PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare.blp")
						PlayerFrameTexture:SetTexCoord(1, .09375, 0, .78125)
					end
				elseif chain == 2 then -- Elite
					if C_AddOns.IsAddOnLoaded("EasyFrames") then
						PlayerFrameTexture:SetTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus.blp")
						if EasyFramesLightTexture then
							PlayerFrameTexture:SetTexCoord(0.5, 0.7265, 0.875, 0.9726)
						else
							PlayerFrameTexture:SetTexCoord(0.5, 0.7265, 0.75, 0.8476)
						end
					else
						PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite.blp")
						PlayerFrameTexture:SetTexCoord(1, .09375, 0, .78125)
					end
				elseif chain == 3 then -- Rare Elite
					if C_AddOns.IsAddOnLoaded("EasyFrames") then
						PlayerFrameTexture:SetTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus.blp")
						if EasyFramesLightTexture then
							PlayerFrameTexture:SetTexCoord(0.25, 0.4765, 0.875, 0.9726)
						else
							PlayerFrameTexture:SetTexCoord(0.25, 0.4765, 0.75, 0.8476)
						end
					else
						PlayerFrameTexture:SetTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus.blp")
						PlayerFrameTexture:SetTexCoord(0.75, 0.9765, 0.75, 0.8476)
					end
				end

			end

			-- Set style on startup
			SetChainStyle()

			-- If Easy Frames is installed, set chain style when Easy Frames has loaded
			EventUtil.ContinueOnAddOnLoaded("EasyFrames", function()
				local EasyFrames = LibStub("AceAddon-3.0"):GetAddon("EasyFrames", true)
				if EasyFrames then
					local General = EasyFrames:GetModule("General", true)
					if General then
						-- Set chain style when Easy Frames use a light texture checkbox is toggled
						local SetLightTextureFunc = General.SetLightTexture
						if SetLightTextureFunc then
							hooksecurefunc(General, "SetLightTexture", SetChainStyle)
						end
					end
				end
				-- Set chain style after Easy Frames has loaded
				SetChainStyle()
			end)

			-- Set style when a drop menu is selected (procs when the list is hidden)
			RGXQoLCB["PlayerChainMenu"]:RegisterCallback("OnMenuClose", SetChainStyle)

			-- Help button hidden
			ChainPanel.h:Hide()

			-- Back button handler
			ChainPanel.b:SetScript("OnClick", function()
				ChainPanel:Hide()
				RGXQoLLC["PageF"]:Show()
				RGXQoLLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			ChainPanel.r:SetScript("OnClick", function()
				RGXQoLLC["PlayerChainMenu"] = 2
				ChainPanel:Hide(); ChainPanel:Show()
				SetChainStyle()
			end)

			-- Show the panel when the configuration button is clicked
			RGXQoLCB["ModPlayerChain"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					RGXQoLLC["PlayerChainMenu"] = 3;
					SetChainStyle();
				else
					RGXQoLLC:HideFrames();
					ChainPanel:Show();
				end
			end)

		end

		----------------------------------------------------------------------
		-- Show raid frame toggle button
		----------------------------------------------------------------------

		if RGXQoLLC["ShowRaidToggle"] == "On" and not RGXQoLLockList["ShowRaidToggle"] then

			-- Check to make sure raid toggle button exists
			if CompactRaidFrameManagerDisplayFrameHiddenModeToggle then

				-- Create a border for the button
				local cBackdrop = CreateFrame("Frame", nil, CompactRaidFrameManagerDisplayFrameHiddenModeToggle, "BackdropTemplate")
				cBackdrop:SetAllPoints()
				cBackdrop.backdropInfo = {edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = {left = 0, right = 0, top = 0, bottom = 0}}
				cBackdrop:ApplyBackdrop()

				-- Move the button (function runs after PLAYER_ENTERING_WORLD and PARTY_LEADER_CHANGED)
				hooksecurefunc("CompactRaidFrameManager_UpdateOptionsFlowContainer", function()
					if CompactRaidFrameManager and CompactRaidFrameManagerDisplayFrameHiddenModeToggle then
						local void, void, void, void, y = CompactRaidFrameManager:GetPoint()
						CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetWidth(40)
						CompactRaidFrameManagerDisplayFrameHiddenModeToggle:ClearAllPoints()
						CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, y + 22)
						CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetParent(UIParent)
					end
				end)

			end

		end

		----------------------------------------------------------------------
		-- Hide hit indicators (portrait text)
		----------------------------------------------------------------------

		if RGXQoLLC["NoHitIndicators"] == "On" and not RGXQoLLockList["NoHitIndicators"] then
			hooksecurefunc(PlayerHitIndicator, "Show", PlayerHitIndicator.Hide)
			hooksecurefunc(PetHitIndicator, "Show", PetHitIndicator.Hide)
		end

		----------------------------------------------------------------------
		-- Class colored frames
		----------------------------------------------------------------------

		if RGXQoLLC["ClassColFrames"] == "On" and not RGXQoLLockList["ClassColFrames"] then

			-- Create background frame for player frame
			local PlayFN = CreateFrame("FRAME", nil, PlayerFrame)
			PlayFN:Hide()

			PlayFN:SetWidth(TargetFrameNameBackground:GetWidth())
			PlayFN:SetHeight(TargetFrameNameBackground:GetHeight())

			local void, void, void, x, y = TargetFrameNameBackground:GetPoint()
			PlayFN:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", -x, y)

			PlayFN.t = PlayFN:CreateTexture(nil, "BORDER")
			PlayFN.t:SetAllPoints()
			PlayFN.t:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")

			local c = RGXQoLLC["RaidColors"][select(2, UnitClass("player"))]
			if c then PlayFN.t:SetVertexColor(c.r, c.g, c.b) end

			-- Create color function for target and focus frames
			local function TargetFrameCol()
				if UnitIsPlayer("target") then
					local c = RGXQoLLC["RaidColors"][select(2, UnitClass("target"))]
					if c then TargetFrameNameBackground:SetVertexColor(c.r, c.g, c.b) end
				end
			end

			local ColTar = CreateFrame("FRAME")
			ColTar:SetScript("OnEvent", TargetFrameCol) -- Events are registered if target option is enabled

			-- Create configuration panel
			local ClassFrame = RGXQoLLC:CreatePanel("Class colored frames", "ClassFrame")

			RGXQoLLC:MakeTx(ClassFrame, "Settings", 16, -72)
			RGXQoLLC:MakeCB(ClassFrame, "ClassColPlayer", "Show player frame in class color", 16, -92, false, "If checked, the player frame background will be shown in class color.")
			RGXQoLLC:MakeCB(ClassFrame, "ClassColTarget", "Show target frame in class color", 16, -112, false, "If checked, the target frame background will be shown in class color.")

			-- Help button hidden
			ClassFrame.h:Hide()

			-- Back button handler
			ClassFrame.b:SetScript("OnClick", function()
				ClassFrame:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page6"]:Show()
				return
			end)

			-- Function to set class colored frames
			local function SetClassColFrames()
				-- Player frame
				if RGXQoLLC["ClassColPlayer"] == "On" then
					PlayFN:Show()
				else
					PlayFN:Hide()
				end
				-- Target frame
				if RGXQoLLC["ClassColTarget"] == "On" then
					ColTar:RegisterEvent("GROUP_ROSTER_UPDATE")
					ColTar:RegisterEvent("PLAYER_TARGET_CHANGED")
					ColTar:RegisterEvent("UNIT_FACTION")
					TargetFrameCol()
				else
					ColTar:UnregisterAllEvents()
					TargetFrame_CheckFaction(TargetFrame) -- Reset target frame colors
				end
			end

			-- Run function when options are clicked and on startup
			RGXQoLCB["ClassColPlayer"]:HookScript("OnClick", SetClassColFrames)
			RGXQoLCB["ClassColTarget"]:HookScript("OnClick", SetClassColFrames)
			SetClassColFrames()

			-- Reset button handler
			ClassFrame.r:SetScript("OnClick", function()

				-- Reset checkboxes
				RGXQoLLC["ClassColPlayer"] = "On"
				RGXQoLLC["ClassColTarget"] = "On"

				-- Update colors and refresh configuration panel
				SetClassColFrames()
				ClassFrame:Hide(); ClassFrame:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			RGXQoLCB["ClassColFramesBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["ClassColPlayer"] = "On"
					RGXQoLLC["ClassColTarget"] = "On"
					SetClassColFrames()
				else
					ClassFrame:Show()
					RGXQoLLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Quest text size
		----------------------------------------------------------------------

		if RGXQoLLC["QuestFontChange"] == "On" then

			-- Set gossip frame scroll box layout
			GossipFrame.GreetingPanel.ScrollBox:SetHeight(320)
			GossipFrame.GreetingPanel.ScrollBar:ClearAllPoints()
			GossipFrame.GreetingPanel.ScrollBar:SetPoint("TOPLEFT", GossipFrame.GreetingPanel.ScrollBox, "TOPRIGHT", 4, 9)
			GossipFrame.GreetingPanel.ScrollBar:SetPoint("BOTTOMLEFT", GossipFrame.GreetingPanel.ScrollBox, "BOTTOMRIGHT", 4, -14)

			-- Create configuration panel
			local QuestTextPanel = RGXQoLLC:CreatePanel("Resize quest text", "QuestTextPanel")

			RGXQoLLC:MakeTx(QuestTextPanel, "Text size", 16, -72)
			RGXQoLLC:MakeSL(QuestTextPanel, "LeaPlusQuestFontSize", "Drag to set the font size of quest text.", 10, 30, 1, 16, -92, "%.0f")

			-- Function to update the font size
			local function QuestSizeUpdate()
				local a, b, c = QuestFont:GetFont()
				QuestTitleFont:SetFont(a, RGXQoLLC["LeaPlusQuestFontSize"] + 3, c)
				QuestFont:SetFont(a, RGXQoLLC["LeaPlusQuestFontSize"] + 1, c)
				local d, e, f = QuestFontNormalSmall:GetFont()
				QuestFontNormalSmall:SetFont(d, RGXQoLLC["LeaPlusQuestFontSize"], f)
			end

			-- Set text size when slider changes and on startup
			RGXQoLCB["LeaPlusQuestFontSize"]:HookScript("OnValueChanged", QuestSizeUpdate)
			QuestSizeUpdate()

			-- Help button hidden
			QuestTextPanel.h:Hide()

			-- Back button handler
			QuestTextPanel.b:SetScript("OnClick", function()
				QuestTextPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page4"]:Show()
				return
			end)

			-- Reset button handler
			QuestTextPanel.r:SetScript("OnClick", function()

				-- Reset slider
				RGXQoLLC["LeaPlusQuestFontSize"] = 12
				QuestSizeUpdate()

				-- Refresh side panel
				QuestTextPanel:Hide(); QuestTextPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			RGXQoLCB["QuestTextBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["LeaPlusQuestFontSize"] = 18
					QuestSizeUpdate()
				else
					QuestTextPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Resize mail text
		----------------------------------------------------------------------

		if RGXQoLLC["MailFontChange"] == "On" then

			-- Create configuration panel
			local MailTextPanel = RGXQoLLC:CreatePanel("Resize mail text", "MailTextPanel")

			RGXQoLLC:MakeTx(MailTextPanel, "Text size", 16, -72)
			RGXQoLLC:MakeSL(MailTextPanel, "LeaPlusMailFontSize", "Drag to set the font size of mail text.", 10, 30, 1, 16, -92, "%.0f")

			-- Function to set the text size
			local function MailSizeUpdate()
				local MailFont, void, flags = QuestFont:GetFont()
				OpenMailBodyText:SetFont("h1", MailFont, RGXQoLLC["LeaPlusMailFontSize"], flags)
				OpenMailBodyText:SetFont("h2", MailFont, RGXQoLLC["LeaPlusMailFontSize"], flags)
				OpenMailBodyText:SetFont("h3", MailFont, RGXQoLLC["LeaPlusMailFontSize"], flags)
				OpenMailBodyText:SetFont("p", MailFont, RGXQoLLC["LeaPlusMailFontSize"], flags)
				MailEditBox:GetEditBox():SetFont(MailFont, RGXQoLLC["LeaPlusMailFontSize"], flags)
			end

			-- Set text size after changing slider and on startup
			RGXQoLCB["LeaPlusMailFontSize"]:HookScript("OnValueChanged", MailSizeUpdate)
			MailSizeUpdate()

			-- Help button hidden
			MailTextPanel.h:Hide()

			-- Back button handler
			MailTextPanel.b:SetScript("OnClick", function()
				MailTextPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page4"]:Show()
				return
			end)

			-- Reset button handler
			MailTextPanel.r:SetScript("OnClick", function()

				-- Reset slider
				RGXQoLLC["LeaPlusMailFontSize"] = 15

				-- Refresh side panel
				MailTextPanel:Hide(); MailTextPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			RGXQoLCB["MailTextBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["LeaPlusMailFontSize"] = 22
					MailSizeUpdate()
				else
					MailTextPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Resize book text
		----------------------------------------------------------------------

		if RGXQoLLC["BookFontChange"] == "On" then

			-- Create configuration panel
			local BookTextPanel = RGXQoLLC:CreatePanel("Resize book text", "BookTextPanel")

			RGXQoLLC:MakeTx(BookTextPanel, "Text size", 16, -72)
			RGXQoLLC:MakeSL(BookTextPanel, "LeaPlusBookFontSize", "Drag to set the font size of book text.", 10, 30, 1, 16, -92, "%.0f")

			-- Function to set the text size
			local function BookSizeUpdate()
				local BookFont, void, flags = QuestFont:GetFont()
				ItemTextFontNormal:SetFont(BookFont, RGXQoLLC["LeaPlusBookFontSize"], flags)
			end

			-- Set text size after changing slider and on startup
			RGXQoLCB["LeaPlusBookFontSize"]:HookScript("OnValueChanged", BookSizeUpdate)
			BookSizeUpdate()

			-- Help button hidden
			BookTextPanel.h:Hide()

			-- Back button handler
			BookTextPanel.b:SetScript("OnClick", function()
				BookTextPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page4"]:Show()
				return
			end)

			-- Reset button handler
			BookTextPanel.r:SetScript("OnClick", function()

				-- Reset slider
				RGXQoLLC["LeaPlusBookFontSize"] = 15

				-- Refresh side panel
				BookTextPanel:Hide(); BookTextPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			RGXQoLCB["BookTextBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["LeaPlusBookFontSize"] = 22
					BookSizeUpdate()
				else
					BookTextPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Show durability status
		----------------------------------------------------------------------

		if RGXQoLLC["DurabilityStatus"] == "On" then

			-- Create durability button
			local cButton = CreateFrame("BUTTON", nil, PaperDollFrame)
			cButton:ClearAllPoints()
			cButton:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -40, 80)
			cButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
			cButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
			cButton:SetSize(32, 32)

			-- Create durability tables
			local Slots = {"HeadSlot", "ShoulderSlot", "ChestSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot"}
			local SlotsFriendly = {INVTYPE_HEAD, INVTYPE_SHOULDER, INVTYPE_CHEST, INVTYPE_WRIST, INVTYPE_HAND, INVTYPE_WAIST, INVTYPE_LEGS, INVTYPE_FEET, INVTYPE_WEAPONMAINHAND, INVTYPE_WEAPONOFFHAND, INVTYPE_RANGED}

			-- Show durability status in tooltip or status line (tip or status)
			local function ShowDuraStats(where)

				local duravaltotal, duramaxtotal, durapercent = 0, 0, 0
				local valcol, id, duraval, duramax

				if where == "tip" then
					-- Creare layout
					GameTooltip:AddLine("|cffffffff")
					GameTooltip:AddLine("|cffffffff")
					GameTooltip:AddLine("|cffffffff")
					_G["GameTooltipTextLeft1"]:SetText("|cffffffff"); _G["GameTooltipTextRight1"]:SetText("|cffffffff")
					_G["GameTooltipTextLeft2"]:SetText("|cffffffff"); _G["GameTooltipTextRight2"]:SetText("|cffffffff")
					_G["GameTooltipTextLeft3"]:SetText("|cffffffff"); _G["GameTooltipTextRight3"]:SetText("|cffffffff")
				end

				local validItems = false

				-- Traverse equipment slots
				for k, slotName in ipairs(Slots) do
					if GetInventorySlotInfo(slotName) then
						id = GetInventorySlotInfo(slotName)
						duraval, duramax = GetInventoryItemDurability(id)
						if duraval ~= nil then

							-- At least one item has durability stat
							validItems = true

							-- Add to tooltip
							if where == "tip" then
								durapercent = tonumber(format("%.0f", duraval / duramax * 100))
								valcol = (durapercent >= 80 and "|cff00FF00") or (durapercent >= 60 and "|cff99FF00") or (durapercent >= 40 and "|cffFFFF00") or (durapercent >= 20 and "|cffFF9900") or (durapercent >= 0 and "|cffFF2000") or ("|cffFFFFFF")
								_G["GameTooltipTextLeft1"]:SetText(L["Durability"])
								_G["GameTooltipTextLeft2"]:SetText(_G["GameTooltipTextLeft2"]:GetText() .. SlotsFriendly[k] .. "|n")
								_G["GameTooltipTextRight2"]:SetText(_G["GameTooltipTextRight2"]:GetText() ..  valcol .. durapercent .. "%" .. "|r|n")
							end

							duravaltotal = duravaltotal + duraval
							duramaxtotal = duramaxtotal + duramax
						end
					end
				end
				if duravaltotal > 0 and duramaxtotal > 0 then
					durapercent = duravaltotal / duramaxtotal * 100
				else
					durapercent = 0
				end

				if where == "tip" then

					if validItems == true then
						-- Show overall durability in the tooltip
						if durapercent >= 80 then valcol = "|cff00FF00"	elseif durapercent >= 60 then valcol = "|cff99FF00"	elseif durapercent >= 40 then valcol = "|cffFFFF00"	elseif durapercent >= 20 then valcol = "|cffFF9900"	elseif durapercent >= 0 then valcol = "|cffFF2000" else return end
						_G["GameTooltipTextLeft3"]:SetText(L["Overall"] .. " " .. valcol)
						_G["GameTooltipTextRight3"]:SetText(valcol .. string.format("%.0f", durapercent) .. "%")

						-- Show lines of the tooltip
						GameTooltipTextLeft1:Show(); GameTooltipTextRight1:Show()
						GameTooltipTextLeft2:Show(); GameTooltipTextRight2:Show()
						GameTooltipTextLeft3:Show(); GameTooltipTextRight3:Show()
						GameTooltipTextRight2:SetJustifyH"RIGHT";
						GameTooltipTextRight3:SetJustifyH"RIGHT";
						GameTooltip:Show()
					else
						-- No items have durability stat
						GameTooltip:ClearLines()
						GameTooltip:AddLine("" .. L["Durability"],1.0, 0.85, 0.0)
						GameTooltip:AddLine("" .. L["No items with durability equipped."], 1, 1, 1)
						GameTooltip:Show()
					end

				elseif where == "status" then
					if validItems == true then
						-- Show simple status line instead
						if tonumber(durapercent) >= 0 then -- Ensure character has some durability items equipped
							RGXQoLLC:Print(L["You have"] .. " " .. string.format("%.0f", durapercent) .. "%" .. " " .. L["durability"] .. ".")
						end
					end

				end
			end

			-- Hover over the durability button to show the durability tooltip
			cButton:SetScript("OnEnter", function()
				GameTooltip:SetOwner(cButton, "ANCHOR_RIGHT");
				GameTooltip:SetMinimumWidth(0) -- Needed due to MoP mage reset specialisation and choose frost
				ShowDuraStats("tip");
			end)
			cButton:SetScript("OnLeave", GameTooltip_Hide)

			-- Create frame to watch events
			local DeathDura = CreateFrame("FRAME")
			DeathDura:RegisterEvent("PLAYER_DEAD")
			DeathDura:SetScript("OnEvent", function(self, event)
				ShowDuraStats("status")
				DeathDura:UnregisterEvent("PLAYER_DEAD")
				C_Timer.After(2, function()
					DeathDura:RegisterEvent("PLAYER_DEAD")
				end)
			end)

			hooksecurefunc("AcceptResurrect", function()
				-- Player has ressed without releasing
				ShowDuraStats("status")
			end)

		end

		----------------------------------------------------------------------
		--	Hide zone text
		----------------------------------------------------------------------

		if RGXQoLLC["HideZoneText"] == "On" then
			ZoneTextFrame:SetScript("OnShow", ZoneTextFrame.Hide);
			SubZoneTextFrame:SetScript("OnShow", SubZoneTextFrame.Hide);
		end

		----------------------------------------------------------------------
		--	Disable sticky chat
		----------------------------------------------------------------------

		if RGXQoLLC["NoStickyChat"] == "On" and not RGXQoLLockList["NoStickyChat"] then
			-- These taint if set to anything other than nil
			ChatTypeInfo.WHISPER.sticky = nil
			ChatTypeInfo.BN_WHISPER.sticky = nil
			ChatTypeInfo.CHANNEL.sticky = nil
		end

		----------------------------------------------------------------------
		--	Hide stance bar
		----------------------------------------------------------------------

		if RGXQoLLC["NoClassBar"] == "On" and not RGXQoLLockList["NoClassBar"] then
			local stancebar = CreateFrame("FRAME", nil, UIParent)
			stancebar:Hide()
			StanceBar:UnregisterAllEvents()
			StanceBar:SetParent(stancebar)
		end

		----------------------------------------------------------------------
		--	Hide gryphons
		----------------------------------------------------------------------

		if RGXQoLLC["NoGryphons"] == "On" and not RGXQoLLockList["NoGryphons"] then
			MainMenuBarLeftEndCap:Hide();
			MainMenuBarRightEndCap:Hide();
		end

		----------------------------------------------------------------------
		--	Disable chat fade
		----------------------------------------------------------------------

		if RGXQoLLC["NoChatFade"] == "On" and not RGXQoLLockList["NoChatFade"] then
			-- Process normal and existing chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i]:SetFading(false)
				end
			end
			-- Process temporary frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf]:SetFading(false)
				end
			end)
		end

		----------------------------------------------------------------------
		--	Use easy chat frame resizing
		----------------------------------------------------------------------

		if RGXQoLLC["UseEasyChatResizing"] == "On" and not RGXQoLLockList["UseEasyChatResizing"] then
			ChatFrame1Tab:HookScript("OnMouseDown", function(self,arg1)
				if arg1 == "LeftButton" then
					if select(8, GetChatWindowInfo(1)) then
						ChatFrame1:StartSizing("TOP")
					end
				end
			end)
			ChatFrame1Tab:SetScript("OnMouseUp", function(self,arg1)
				if arg1 == "LeftButton" then
					ChatFrame1:StopMovingOrSizing()
					FCF_SavePositionAndDimensions(ChatFrame1)
				end
			end)
		end

		----------------------------------------------------------------------
		--	Increase chat history
		----------------------------------------------------------------------

		if RGXQoLLC["MaxChatHstory"] == "On" and not RGXQoLLockList["MaxChatHstory"] then
			-- Process normal and existing chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i]:SetMaxLines(4096)
				end
			end
			-- Process temporary chat frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf]:SetMaxLines(4096)
				end
			end)
		end

		----------------------------------------------------------------------
		--	Hide error messages
		----------------------------------------------------------------------

		if RGXQoLLC["HideErrorMessages"] == "On" then

			--	Error message events
			local OrigErrHandler = UIErrorsFrame:GetScript('OnEvent')
			UIErrorsFrame:SetScript('OnEvent', function (self, event, id, err, ...)
				if event == "UI_ERROR_MESSAGE" then
					-- Hide error messages
					if RGXQoLLC["ShowErrorsFlag"] == 1 then
						if 	err == ERR_INV_FULL or
							err == ERR_QUEST_LOG_FULL or
							err == ERR_RAID_GROUP_ONLY or
							err == ERR_PET_SPELL_DEAD or
							err == ERR_PLAYER_DEAD or
							err == ERR_FEIGN_DEATH_RESISTED or
							err == SPELL_FAILED_TARGET_NO_POCKETS or
							err == ERR_ALREADY_PICKPOCKETED then
							return OrigErrHandler(self, event, id, err, ...)
						end
					else
						return OrigErrHandler(self, event, id, err, ...)
					end
				elseif event == 'UI_INFO_MESSAGE'  then
					-- Show information messages
					return OrigErrHandler(self, event, id, err, ...)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Easy item destroy
		----------------------------------------------------------------------

		if RGXQoLLC["EasyItemDestroy"] == "On" then

			-- Get the type "DELETE" into the field to confirm text
			local TypeDeleteLine = gsub(DELETE_GOOD_ITEM, "[\r\n]", "@")
			local void, TypeDeleteLine = strsplit("@", TypeDeleteLine, 2)

			-- Add hyperlinks to regular item destroy
			RunScript('StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter = function(self, link, text, region, boundsLeft, boundsBottom, boundsWidth, boundsHeight) GameTooltip:SetOwner(self, "ANCHOR_PRESERVE") GameTooltip:ClearAllPoints() local cursorClearance = 30 GameTooltip:SetPoint("TOPLEFT", region, "BOTTOMLEFT", boundsLeft, boundsBottom - cursorClearance) GameTooltip:SetHyperlink(link) end')
			RunScript('StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave = function(self) GameTooltip:Hide() end')
			RunScript('StaticPopupDialogs["DELETE_ITEM"].OnHyperlinkEnter = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter')
			RunScript('StaticPopupDialogs["DELETE_ITEM"].OnHyperlinkLeave = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave')
			RunScript('StaticPopupDialogs["DELETE_QUEST_ITEM"].OnHyperlinkEnter = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter')
			RunScript('StaticPopupDialogs["DELETE_QUEST_ITEM"].OnHyperlinkLeave = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave')
			RunScript('StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"].OnHyperlinkEnter = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter')
			RunScript('StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"].OnHyperlinkLeave = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave')

			-- Hide editbox and set item link
			local easyDelFrame = CreateFrame("FRAME")
			easyDelFrame:RegisterEvent("DELETE_ITEM_CONFIRM")
			easyDelFrame:SetScript("OnEvent", function()
				if StaticPopup1EditBox:IsShown() then
					-- Item requires player to type delete so hide editbox and show link
					StaticPopup1:SetHeight(StaticPopup1:GetHeight() - 10)
					StaticPopup1EditBox:Hide()
					StaticPopup1Button1:Enable()
					local link = select(3, GetCursorInfo())
					if link then
						StaticPopup1Text:SetText(gsub(StaticPopup1Text:GetText(), gsub(TypeDeleteLine, "@", ""), "") .. link)
					end
				else
					-- Item does not require player to type delete so just show item link
					StaticPopup1:SetHeight(StaticPopup1:GetHeight() + 40)
					StaticPopup1EditBox:Hide()
					StaticPopup1Button1:Enable()
					local link = select(3, GetCursorInfo())
					if link then
						StaticPopup1Text:SetText(gsub(StaticPopup1Text:GetText(), gsub(TypeDeleteLine, "@", ""), "") .. "|n|n" .. link .. "|n|n")
					end
				end
			end)

		end

		----------------------------------------------------------------------
		-- Unclamp chat frame
		----------------------------------------------------------------------

		if RGXQoLLC["UnclampChat"] == "On" and not RGXQoLLockList["UnclampChat"] then

			-- Process normal and existing chat frames on startup
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i]:SetClampedToScreen(false)
					_G["ChatFrame" .. i]:SetClampRectInsets(0, 0, 0, 0)
				end
			end

			-- Process new chat frames and combat log
			hooksecurefunc("FloatingChatFrame_UpdateBackgroundAnchors", function(self)
				self:SetClampRectInsets(0, 0, 0, 0)
			end)

			-- Process temporary chat frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf]:SetClampRectInsets(0, 0, 0, 0)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Enhance flight map
		----------------------------------------------------------------------

		if RGXQoLLC["EnhanceFlightMap"] == "On" then

			-- Hide flight map textures
			local regions = {TaxiFrame:GetRegions()}
			regions[2]:Hide()
			regions[3]:Hide()
			regions[4]:Hide()
			regions[5]:Hide()
			TaxiPortrait:Hide()
			TaxiMerchant:Hide()

			-- Create flight map border
			local border = TaxiFrame:CreateTexture(nil, "BACKGROUND")
			border:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
			border:SetPoint("TOPLEFT", 18, -73)
			border:SetPoint("BOTTOMRIGHT", -45, 83)
			border:SetVertexColor(0, 0, 0, 1)

			-- Set flight map properties
			TaxiFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			TaxiFrame:SetHitRectInsets(18, 45, 73, 83)
			TaxiFrame:SetClampedToScreen(true)
			TaxiFrame:SetClampRectInsets(200, -200, -300, 300)

			-- Position flight map when shown
			hooksecurefunc(TaxiFrame, "SetPoint", function(self, ...)
				local a, void, r, x, y = TaxiFrame:GetPoint()
				x = tonumber(string.format("%.2f", x))
				y = tonumber(string.format("%.2f", y))
				local xb = tonumber(string.format("%.2f", RGXQoLLC["FlightMapX"]))
				local yb = tonumber(string.format("%.2f", RGXQoLLC["FlightMapY"]))
				if a ~= RGXQoLLC["FlightMapA"] or r ~= RGXQoLLC["FlightMapR"] or x ~= xb or y ~= yb then
					TaxiFrame:ClearAllPoints()
					TaxiFrame:SetPoint(RGXQoLLC["FlightMapA"], UIParent, RGXQoLLC["FlightMapR"], RGXQoLLC["FlightMapX"], RGXQoLLC["FlightMapY"])
				end
			end)

			-- Set flight point buttons size
			TaxiFrame:HookScript("OnShow", function()
				for i = 1, NUM_TAXI_BUTTONS do
					local button = _G["TaxiButton"..i]
					if button and button:IsVisible() then
						_G["TaxiButton" .. i]:SetSize(RGXQoLLC["LeaPlusTaxiIconSize"], RGXQoLLC["LeaPlusTaxiIconSize"])
						if button:GetHighlightTexture() then button:GetHighlightTexture():SetSize(RGXQoLLC["LeaPlusTaxiIconSize"] * 2, RGXQoLLC["LeaPlusTaxiIconSize"] * 2) end
						if button:GetPushedTexture() then button:GetPushedTexture():SetSize(RGXQoLLC["LeaPlusTaxiIconSize"] * 2, RGXQoLLC["LeaPlusTaxiIconSize"] * 2) end
				   end
				end
			end)

			-- Move close button
			TaxiCloseButton:SetIgnoreParentScale(true)
			TaxiCloseButton:ClearAllPoints()
			TaxiCloseButton:SetPoint("TOPRIGHT", TaxiRouteMap, "TOPRIGHT", 0, 0)

			--UIPanelWindows["TaxiFrame"].width = 0

			-- Create configuration panel
			local TaxiPanel = RGXQoLLC:CreatePanel("Enhance flight map", "TaxiPanel")

			RGXQoLLC:MakeTx(TaxiPanel, "Map scale", 356, -72)
			RGXQoLLC:MakeSL(TaxiPanel, "LeaPlusTaxiMapScale", "Drag to set the scale of the flight map.", 1, 3, 0.05, 356, -92, "%.0f")

			RGXQoLLC:MakeTx(TaxiPanel, "Icon size", 356, -132)
			RGXQoLLC:MakeSL(TaxiPanel, "LeaPlusTaxiIconSize", "Drag to set the size of the icons.", 5, 30, 1, 356, -152, "%.0f")

			RGXQoLLC:MakeTx(TaxiPanel, "Position", 16, -72)
			TaxiPanel.txt = RGXQoLLC:MakeWD(TaxiPanel, "Hold ALT and drag the flight map to move it.", 16, -92, 500)
			TaxiPanel.txt:SetWordWrap(true)
			TaxiPanel.txt:SetWidth(300)

			-- Function to set flight map scale
			local function SetFlightMapScale()
				TaxiFrame:SetScale(RGXQoLLC["LeaPlusTaxiMapScale"])
				RGXQoLCB["LeaPlusTaxiMapScale"].f:SetFormattedText("%.0f%%", RGXQoLLC["LeaPlusTaxiMapScale"] * 100)
			end

			-- Function to set icon size (used for reset and when slider changes)
			local function SetFlightMapIconSize()
				for i = 1, NUM_TAXI_BUTTONS do
					local button = _G["TaxiButton"..i]
					if button and button:IsVisible() then
						_G["TaxiButton" .. i]:SetSize(RGXQoLLC["LeaPlusTaxiIconSize"], RGXQoLLC["LeaPlusTaxiIconSize"])
						if button:GetHighlightTexture() then button:GetHighlightTexture():SetSize(RGXQoLLC["LeaPlusTaxiIconSize"] * 2, RGXQoLLC["LeaPlusTaxiIconSize"] * 2) end
						if button:GetPushedTexture() then button:GetPushedTexture():SetSize(RGXQoLLC["LeaPlusTaxiIconSize"] * 2, RGXQoLLC["LeaPlusTaxiIconSize"] * 2) end
				   end
				end
				RGXQoLCB["LeaPlusTaxiIconSize"].f:SetFormattedText("%.0f%%", RGXQoLLC["LeaPlusTaxiIconSize"] * 10)
			end

			-- Set flight map scale when slider changes and on startup
			RGXQoLCB["LeaPlusTaxiMapScale"]:HookScript("OnValueChanged", SetFlightMapScale)
			RGXQoLCB["LeaPlusTaxiIconSize"]:HookScript("OnValueChanged", SetFlightMapIconSize)
			SetFlightMapScale()

			-- Help button tooltip
			TaxiPanel.h.tiptext = L["This panel will close automatically if you enter combat."]

			-- Back button handler
			TaxiPanel.b:SetScript("OnClick", function()
				TaxiPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			TaxiPanel.r:SetScript("OnClick", function()

				-- Reset slider
				RGXQoLLC["LeaPlusTaxiMapScale"] = 1.9
				RGXQoLLC["LeaPlusTaxiIconSize"] = 10
				SetFlightMapScale()
				RGXQoLLC["FlightMapA"] = "TOPLEFT"
				RGXQoLLC["FlightMapR"] = "TOPLEFT"
				RGXQoLLC["FlightMapX"] = 0
				RGXQoLLC["FlightMapY"] = 61
				TaxiFrame:ClearAllPoints()
				TaxiFrame:SetPoint(RGXQoLLC["FlightMapA"], UIParent, RGXQoLLC["FlightMapR"], RGXQoLLC["FlightMapX"], RGXQoLLC["FlightMapY"])

				-- Refresh side panel
				TaxiPanel:Hide(); TaxiPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			RGXQoLCB["EnhanceFlightMapBtn"]:SetScript("OnClick", function()
				if RGXQoLLC:PlayerInCombat() then
					return
				else
					if IsShiftKeyDown() and IsControlKeyDown() then
						-- Preset profile
						RGXQoLLC["LeaPlusTaxiMapScale"] = 1.9
						RGXQoLLC["LeaPlusTaxiIconSize"] = 10
						RGXQoLLC["FlightMapA"] = "TOPLEFT"
						RGXQoLLC["FlightMapR"] = "TOPLEFT"
						RGXQoLLC["FlightMapX"] = 0
						RGXQoLLC["FlightMapY"] = 61
						SetFlightMapScale()
						SetFlightMapIconSize()
					else
						TaxiPanel:Show()
						RGXQoLLC:HideFrames()
					end
				end
			end)

			-- Hide the configuration panel if combat starts
			TaxiPanel:SetScript("OnUpdate", function()
				if UnitAffectingCombat("player") then
					TaxiPanel:Hide()
				end
			end)

			-- Move the flight map
			TaxiFrame:SetMovable(true)
			TaxiFrame:RegisterForDrag("LeftButton")
			TaxiFrame:SetScript("OnDragStart", function()
				if IsAltKeyDown() then
					TaxiFrame:StartMoving()
				end
			end)
			TaxiFrame:SetScript("OnDragStop", function()
				TaxiFrame:StopMovingOrSizing()
				TaxiFrame:SetUserPlaced(false)
				RGXQoLLC["FlightMapA"], void, RGXQoLLC["FlightMapR"], RGXQoLLC["FlightMapX"], RGXQoLLC["FlightMapY"] = TaxiFrame:GetPoint()
			end)

			-- ElvUI fixes
			if RGXQoLLC.ElvUI then
				if TaxiFrame.backdrop then
					border:ClearAllPoints()
					border:SetPoint("TOPLEFT", 22, -70)
					border:SetPoint("BOTTOMRIGHT", -44, 88)
					TaxiFrame:SetHitRectInsets(22, 44, 70, 88)
					TaxiFrame.backdrop:SetAlpha(0)
				end
			end

		end

		----------------------------------------------------------------------
		-- Keep audio synced
		----------------------------------------------------------------------

		if RGXQoLLC["KeepAudioSynced"] == "On" then

			SetCVar("Sound_OutputDriverIndex", "0")
			local event = CreateFrame("FRAME")
			event:RegisterEvent("VOICE_CHAT_OUTPUT_DEVICES_UPDATED")
			event:SetScript("OnEvent", function()
				if not CinematicFrame:IsShown() and not MovieFrame:IsShown() then -- Dont restart sound system during cinematic
					SetCVar("Sound_OutputDriverIndex", "0")
					Sound_GameSystem_RestartSoundSystem()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Mute custom sounds (no reload required)
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local MuteCustomPanel = RGXQoLLC:CreatePanel("Mute custom sounds", "MuteCustomPanel")

			local titleTX = RGXQoLLC:MakeTx(MuteCustomPanel, "Editor", 16, -72)
			titleTX:SetWidth(534)
			titleTX:SetWordWrap(false)
			titleTX:SetJustifyH("LEFT")

			-- Show help button for title
			RGXQoLLC:CreateHelpButton("MuteGameSoundsCustomHelpButton", MuteCustomPanel, titleTX, "Enter sound file IDs separated by comma then click the Mute button.|n|nIf you wish, you can enter a brief note for each file ID but do not include numbers in your notes.|n|nFor example, you can enter 'DevAura 569679, RetAura 568744' to mute the Devotion Aura and Retribution Aura spells.|n|nUse Leatrix Sounds to find, test and play sound file IDs.")

			-- Add large editbox
			local eb = CreateFrame("Frame", nil, MuteCustomPanel, "BackdropTemplate")
			eb:SetSize(548, RGXQoLLC.MainPanelHeight - 180)
			eb:SetPoint("TOPLEFT", 10, -92)
			eb:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
				edgeSize = 16,
				insets = { left = 8, right = 6, top = 8, bottom = 8 },
			})
			eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)

			eb.scroll = CreateFrame("ScrollFrame", nil, eb, "RGXQoLMuteCustomSoundsScrollFrameTemplate")
			eb.scroll:SetPoint("TOPLEFT", eb, 12, -10)
			eb.scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)
			eb.scroll:SetPanExtent(16)

			-- Create character count
			eb.scroll.CharCount = eb.scroll:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			eb.scroll.CharCount:Hide()

			eb.Text = eb.scroll.EditBox
			eb.Text:SetWidth(494)
			eb.Text:SetHeight(230)
			eb.Text:SetPoint("TOPLEFT", eb.scroll)
			eb.Text:SetPoint("BOTTOMRIGHT", eb.scroll, -12, 0)
			eb.Text:SetMaxLetters(2000)
			eb.Text:SetFontObject(GameFontNormalLarge)
			eb.Text:SetAutoFocus(false)
			eb.scroll:SetScrollChild(eb.Text)

			-- Set focus on the editbox text when clicking the editbox
			eb:SetScript("OnMouseDown", function()
				eb.Text:SetFocus()
				eb.Text:SetCursorPosition(eb.Text:GetMaxLetters())
			end)

			-- Function to save the custom sound list
			local function SaveString(self, userInput)
				local keytext = eb.Text:GetText()
				if keytext and keytext ~= "" then
					RGXQoLLC["MuteCustomList"] = strtrim(eb.Text:GetText())
				else
					RGXQoLLC["MuteCustomList"] = ""
				end
			end

			-- Save the custom sound list when it changes and at startup
			eb.Text:SetScript("OnTextChanged", SaveString)
			eb.Text:SetText(RGXQoLLC["MuteCustomList"])
			SaveString()

			-- Help button hidden
			MuteCustomPanel.h:Hide()

			-- Back button handler
			MuteCustomPanel.b:SetScript("OnClick", function()
				MuteCustomPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page7"]:Show()
				return
			end)

			-- Reset button hidden
			MuteCustomPanel.r:Hide()

			-- Show configuration panal when options panel button is clicked
			RGXQoLCB["MuteCustomSoundsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["MuteCustomList"] = "Devotion Aura 569679, Retribution Aura 568744"
					eb.Text:SetText(RGXQoLLC["MuteCustomList"])
				else
					MuteCustomPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

			-- Function to mute custom sound list
			local function MuteCustomListFunc(unmute, userInput)
				-- Sound features removed on this build (BLU owns sounds)
				do return end
				-- local mutedebug = true -- Debug
				local counter = 0
				local muteString = RGXQoLLC["MuteCustomList"]
				if muteString and muteString ~= "" then
					muteString = muteString:gsub("%s", ",")
					muteString = muteString:gsub("[\n]", ",")
					muteString = muteString:gsub("[^,%d]", "")
					if mutedebug then print(muteString) end
					local tList = {strsplit(",", muteString)}
					if mutedebug then ChatFrame1:Clear() end
					for i = 1, #tList do
						if tList[i] then
							tList[i] = tonumber(tList[i])
							if tList[i] and tList[i] < 20000000 then
								if mutedebug then print(tList[i]) end
								if unmute then
									UnmuteSoundFile(tList[i])
								else
									MuteSoundFile(tList[i])
								end
								counter = counter + 1
							end
						end
					end
					if userInput then
						if unmute then
							if counter == 1 then
								RGXQoLLC:Print(L["Unmuted"] .. " " .. counter .. " " .. L["sound"] .. ".")
							else
								RGXQoLLC:Print(L["Unmuted"] .. " " .. counter .. " " .. L["sounds"] .. ".")
							end
						else
							if counter == 1 then
								RGXQoLLC:Print(L["Muted"] .. " " .. counter .. " " .. L["sound"] .. ".")
							else
								RGXQoLLC:Print(L["Muted"] .. " " .. counter .. " " .. L["sounds"] .. ".")
							end
						end
					end
				end
			end

			-- Mute custom list on startup if option is enabled
			if RGXQoLLC["MuteCustomSounds"] == "On" then
				MuteCustomListFunc()
			end

			-- Mute or unmute when option is clicked
			RGXQoLCB["MuteCustomSounds"]:HookScript("OnClick", function()
				if RGXQoLLC["MuteCustomSounds"] == "On" then
					MuteCustomListFunc(false, false)
				else
					MuteCustomListFunc(true, false)
				end
			end)

			-- Add mute button
			local MuteCustomNowButton = RGXQoLLC:CreateButton("MuteCustomNowButton", MuteCustomPanel, "Mute", "BOTTOMLEFT", 16, 53, 0, 25, true, "Click to mute sounds in the list.")
			RGXQoLCB["MuteCustomNowButton"]:SetScript("OnClick", function() MuteCustomListFunc(false, true) end)

			-- Add unmute button
			local UnmuteCustomNowButton = RGXQoLLC:CreateButton("UnmuteCustomNowButton", MuteCustomPanel, "Unmute", "BOTTOMLEFT", 16, 53, 0, 25, true, "Click to unmute sounds in the list.")
			RGXQoLCB["UnmuteCustomNowButton"]:ClearAllPoints()
			RGXQoLCB["UnmuteCustomNowButton"]:SetPoint("LEFT", MuteCustomNowButton, "RIGHT", 10, 0)
			RGXQoLCB["UnmuteCustomNowButton"]:SetScript("OnClick", function() MuteCustomListFunc(true, true) end)

			-- Add play sound file editbox
			local willPlay, musicHandle
			local MuteCustomSoundsStopButton = RGXQoLLC:CreateButton("MuteCustomSoundsStopButton", MuteCustomPanel, "Stop", "TOPRIGHT", -18, -66, 0, 25, true, "")
			MuteCustomSoundsStopButton:SetScript("OnClick", function()
				if musicHandle then StopSound(musicHandle) end
			end)

			local MuteCustomSoundsPlayButton = RGXQoLLC:CreateButton("MuteCustomSoundsPlayButton", MuteCustomPanel, "Play", "TOPRIGHT", -18, -66, 0, 25, true, "")
			MuteCustomSoundsPlayButton:ClearAllPoints()
			MuteCustomSoundsPlayButton:SetPoint("RIGHT", MuteCustomSoundsStopButton, "LEFT", -10, 0)

			local MuteCustomSoundsSoundBox = RGXQoLLC:CreateEditBox("MuteCustomSoundsSoundBox", eb, 80, 8, "TOPRIGHT", -10, 20, "PlaySoundBox", "PlaySoundBox")
			MuteCustomSoundsSoundBox:SetNumeric(true)
			MuteCustomSoundsSoundBox:ClearAllPoints()
			MuteCustomSoundsSoundBox:SetPoint("RIGHT", MuteCustomSoundsPlayButton, "LEFT", -10, 0)
			MuteCustomSoundsPlayButton:SetScript("OnClick", function()
				MuteCustomSoundsSoundBox:GetText()
				if musicHandle then StopSound(musicHandle) end
				willPlay, musicHandle = PlaySoundFile(MuteCustomSoundsSoundBox:GetText(), "Master")
			end)

			-- Add mousewheel support to the editbox
			MuteCustomSoundsSoundBox:SetScript("OnMouseWheel", function(self, delta)
				local endSound = tonumber(MuteCustomSoundsSoundBox:GetText())
				if endSound then
					if delta == 1 then endSound = endSound + 1 else endSound = endSound - 1 end
					if endSound < 1 then endSound = 1 elseif endSound >= 10000000 then endSound = 10000000 end
					MuteCustomSoundsSoundBox:SetText(endSound)
					MuteCustomSoundsPlayButton:Click()
				end
			end)

			local titlePlayer = RGXQoLLC:MakeTx(MuteCustomPanel, "Player", 16, -72)
			titlePlayer:ClearAllPoints()
			titlePlayer:SetPoint("TOPLEFT", MuteCustomSoundsSoundBox, "TOPLEFT", -4, 16)
			RGXQoLLC:CreateHelpButton("MuteGameSoundsCustomPlayHelpButton", MuteCustomPanel, titlePlayer, "If you want to listen to a sound file, enter the sound file ID into the editbox and click the play button.|n|nYou can scroll the mousewheel over the editbox to play neighbouring sound files.")
		end

		----------------------------------------------------------------------
		-- Block shared quests (no reload needed)
		----------------------------------------------------------------------

		do

			local eFrame = CreateFrame("FRAME")
			eFrame:SetScript("OnEvent", RGXQoLLC.CheckIfQuestIsSharedAndShouldBeDeclined)

			-- Function to set event
			local function SetSharedQuestsFunc()
				if RGXQoLLC["NoSharedQuests"] == "On" then
					eFrame:RegisterEvent("QUEST_DETAIL")
				else
					eFrame:UnregisterEvent("QUEST_DETAIL")
				end
			end

			-- Set event when option is clicked and on startup
			RGXQoLCB["NoSharedQuests"]:HookScript("OnClick", SetSharedQuestsFunc)
			SetSharedQuestsFunc()

		end

		----------------------------------------------------------------------
		-- Restore chat messages
		----------------------------------------------------------------------

		if RGXQoLLC["RestoreChatMessages"] == "On" and not RGXQoLLockList["RestoreChatMessages"] then

			local historyFrame = CreateFrame("FRAME")
			historyFrame:RegisterEvent("PLAYER_LOGIN")
			historyFrame:RegisterEvent("PLAYER_LOGOUT")

			local FCF_IsChatWindowIndexActive = FCF_IsChatWindowIndexActive
			local GetMessageInfo = GetMessageInfo
			local GetNumMessages = GetNumMessages

			-- Use function from Dragonflight
			local function FCF_IsChatWindowIndexActive(chatWindowIndex)
				local shown = select(7, FCF_GetChatWindowInfo(chatWindowIndex))
				if shown then
					return true
				end
				local chatFrame = _G["ChatFrame" .. chatWindowIndex]
				return (chatFrame and chatFrame.isDocked)
			end

			-- Save chat messages on logout
			historyFrame:SetScript("OnEvent", function(self, event)
				if event == "PLAYER_LOGOUT" then
					local name, realm = UnitFullName("player")
					if not realm then realm = GetNormalizedRealmName() end
					if name and realm then
						RGXQoLDB["ChatHistoryName"] = name .. "-" .. realm
						RGXQoLDB["ChatHistoryTime"] = GetServerTime()
						for i = 1, 50 do
							if i ~= 2 and _G["ChatFrame" .. i] then
								if FCF_IsChatWindowIndexActive(i) then
									RGXQoLDB["ChatHistory" .. i] = {}
									local chtfrm = _G["ChatFrame" .. i]
									local NumMsg = chtfrm:GetNumMessages()
									local StartMsg = 1
									if NumMsg > 256 then StartMsg = NumMsg - 255 end
									for iMsg = StartMsg, NumMsg do
										local chatMessage, r, g, b, chatTypeID = chtfrm:GetMessageInfo(iMsg)
										if chatMessage then
											if r and g and b then
												local colorCode = RGBToColorCode(r, g, b)
												chatMessage = colorCode .. chatMessage
											end
											tinsert(RGXQoLDB["ChatHistory" .. i], chatMessage)
										end
									end
								end
							end
						end
					end
				end
			end)

			-- Restore chat messages on login
			local name, realm = UnitFullName("player")
			if not realm then realm = GetNormalizedRealmName() end
			if name and realm then
				if RGXQoLDB["ChatHistoryName"] and RGXQoLDB["ChatHistoryTime"] then
					local timeDiff = GetServerTime() - RGXQoLDB["ChatHistoryTime"]
					if RGXQoLDB["ChatHistoryName"] == name .. "-" .. realm and timeDiff and timeDiff < 10 then -- reload must be done within 15 seconds

						-- Store chat messages from current session and clear chat
						for i = 1, 50 do
							if i ~= 2 and _G["ChatFrame" .. i] and FCF_IsChatWindowIndexActive(i) then
								RGXQoLDB["ChatTemp" .. i] = {}
								local chtfrm = _G["ChatFrame" .. i]
								local NumMsg = chtfrm:GetNumMessages()
								for iMsg = 1, NumMsg do
									local chatMessage, r, g, b, chatTypeID = chtfrm:GetMessageInfo(iMsg)
									if chatMessage then
										if r and g and b then
											local colorCode = RGBToColorCode(r, g, b)
											chatMessage = colorCode .. chatMessage
										end
										tinsert(RGXQoLDB["ChatTemp" .. i], chatMessage)
									end
								end
								chtfrm:Clear()
							end
						end

						-- Restore chat messages from previous session
						for i = 1, 50 do
							if i ~= 2 and _G["ChatFrame" .. i] and RGXQoLDB["ChatHistory" .. i] and FCF_IsChatWindowIndexActive(i) then
								RGXQoLDB["ChatHistory" .. i .. "Count"] = 0
								-- Add previous session messages to chat
								for k = 1, #RGXQoLDB["ChatHistory" .. i] do
									if RGXQoLDB["ChatHistory" .. i][k] ~= string.match(RGXQoLDB["ChatHistory" .. i][k], "|cffffd800" .. L["Restored"] .. " " .. ".*" .. " " .. L["message"] .. ".*.|r") then
										_G["ChatFrame" .. i]:AddMessage(RGXQoLDB["ChatHistory" .. i][k])
										RGXQoLDB["ChatHistory" .. i .. "Count"] = RGXQoLDB["ChatHistory" .. i .. "Count"] + 1
									end
								end
								-- Show how many messages were restored
								if RGXQoLDB["ChatHistory" .. i .. "Count"] == 1 then
									_G["ChatFrame" .. i]:AddMessage("|cffffd800" .. L["Restored"] .. " " .. RGXQoLDB["ChatHistory" .. i .. "Count"] .. " " .. L["message from previous session"] .. ".|r")
								else
									_G["ChatFrame" .. i]:AddMessage("|cffffd800" .. L["Restored"] .. " " .. RGXQoLDB["ChatHistory" .. i .. "Count"] .. " " .. L["messages from previous session"] .. ".|r")
								end
							else
								-- No messages to restore
								RGXQoLDB["ChatHistory" .. i] = nil
							end
						end

						-- Restore chat messages from this session
						for i = 1, 50 do
							if i ~= 2 and _G["ChatFrame" .. i] and RGXQoLDB["ChatTemp" .. i] and FCF_IsChatWindowIndexActive(i) then
								for k = 1, #RGXQoLDB["ChatTemp" .. i] do
									_G["ChatFrame" .. i]:AddMessage(RGXQoLDB["ChatTemp" .. i][k])
								end
							end
						end

					end
				end
			end

		else

			-- Option is disabled so clear any messages from saved variables
			RGXQoLDB["ChatHistoryName"] = nil
			RGXQoLDB["ChatHistoryTime"] = nil
			for i = 1, 50 do
				RGXQoLDB["ChatHistory" .. i] = nil
				RGXQoLDB["ChatTemp" .. i] = nil
				RGXQoLDB["ChatHistory" .. i .. "Count"] = nil
			end

		end

		----------------------------------------------------------------------
		-- Manage timer
		----------------------------------------------------------------------

		if RGXQoLLC["ManageTimer"] == "On" and not RGXQoLLockList["ManageTimer"] then

			-- Allow timer frame to be moved
			MirrorTimer1:SetMovable(true)
			MirrorTimer1:SetUserPlaced(true)
			MirrorTimer1:SetDontSavePosition(true)
			MirrorTimer1:SetClampedToScreen(true)

			-- Set timer frame position at startup
			MirrorTimer1:ClearAllPoints()
			MirrorTimer1:SetPoint(RGXQoLLC["TimerA"], UIParent, RGXQoLLC["TimerR"], RGXQoLLC["TimerX"], RGXQoLLC["TimerY"])
			MirrorTimer1:SetScale(RGXQoLLC["TimerScale"])

			-- Create drag frame
			local dragframe = CreateFrame("FRAME", nil, nil, "BackdropTemplate")
			dragframe:SetPoint("TOPRIGHT", MirrorTimer1, "TOPRIGHT", 0, 2.5)
			dragframe:SetBackdropColor(0.0, 0.5, 1.0)
			dragframe:SetBackdrop({edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0 }})
			dragframe:SetToplevel(true)
			dragframe:Hide()
			dragframe:SetScale(RGXQoLLC["TimerScale"])

			dragframe.t = dragframe:CreateTexture()
			dragframe.t:SetAllPoints()
			dragframe.t:SetColorTexture(0.0, 1.0, 0.0, 0.5)
			dragframe.t:SetAlpha(0.5)

			dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			dragframe.f:SetPoint('CENTER', 0, 0)
			dragframe.f:SetText(L["Timer"])

			-- Click handler
			dragframe:SetScript("OnMouseDown", function(self, btn)
				-- Start dragging if left clicked
				if btn == "LeftButton" then
					MirrorTimer1:StartMoving()
				end
			end)

			dragframe:SetScript("OnMouseUp", function()
				-- Save frame positions
				MirrorTimer1:StopMovingOrSizing()
				RGXQoLLC["TimerA"], void, RGXQoLLC["TimerR"], RGXQoLLC["TimerX"], RGXQoLLC["TimerY"] = MirrorTimer1:GetPoint()
				MirrorTimer1:SetMovable(true)
				MirrorTimer1:ClearAllPoints()
				MirrorTimer1:SetPoint(RGXQoLLC["TimerA"], UIParent, RGXQoLLC["TimerR"], RGXQoLLC["TimerX"], RGXQoLLC["TimerY"])
			end)

			-- Snap-to-grid
			do
				local frame, grid = dragframe, 10
				local w, h = 180, 20
				local xpos, ypos, scale, uiscale
				frame:RegisterForDrag("RightButton")
				frame:HookScript("OnDragStart", function()
					frame:SetScript("OnUpdate", function()
						scale, uiscale = frame:GetScale(), UIParent:GetScale()
						xpos, ypos = GetCursorPosition()
						xpos = floor((xpos / scale / uiscale) / grid) * grid - w / 2
						ypos = ceil((ypos / scale / uiscale) / grid) * grid + h / 2
						MirrorTimer1:ClearAllPoints()
						MirrorTimer1:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
					end)
				end)
				frame:HookScript("OnDragStop", function()
					frame:SetScript("OnUpdate", nil)
					frame:GetScript("OnMouseUp")()
				end)
			end

			-- Create configuration panel
			local TimerPanel = RGXQoLLC:CreatePanel("Manage timer", "TimerPanel")

			RGXQoLLC:MakeTx(TimerPanel, "Scale", 16, -72)
			RGXQoLLC:MakeSL(TimerPanel, "TimerScale", "Drag to set the timer bar scale.", 0.5, 2, 0.05, 16, -92, "%.2f")

			-- Set scale when slider is changed
			RGXQoLCB["TimerScale"]:HookScript("OnValueChanged", function()
				MirrorTimer1:SetScale(RGXQoLLC["TimerScale"])
				dragframe:SetScale(RGXQoLLC["TimerScale"])
				-- Show formatted slider value
				RGXQoLCB["TimerScale"].f:SetFormattedText("%.0f%%", RGXQoLLC["TimerScale"] * 100)
			end)

			-- Hide frame alignment grid with panel
			TimerPanel:HookScript("OnHide", function()
				RGXQoLLC.grid:Hide()
			end)

			-- Toggle grid button
			local TimerToggleGridButton = RGXQoLLC:CreateButton("TimerToggleGridButton", TimerPanel, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
			RGXQoLCB["TimerToggleGridButton"]:ClearAllPoints()
			RGXQoLCB["TimerToggleGridButton"]:SetPoint("LEFT", TimerPanel.h, "RIGHT", 10, 0)
			RGXQoLCB["TimerToggleGridButton"]:SetScript("OnClick", function()
				if RGXQoLLC.grid:IsShown() then RGXQoLLC.grid:Hide() else RGXQoLLC.grid:Show() end
			end)
			TimerPanel:HookScript("OnHide", function()
				if RGXQoLLC.grid then RGXQoLLC.grid:Hide() end
			end)

			-- Help button tooltip
			TimerPanel.h.tiptext = L["Drag the frame overlay with the left button to position it freely or with the right button to position it using snap-to-grid."]

			-- Back button handler
			TimerPanel.b:SetScript("OnClick", function()
				TimerPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page6"]:Show()
				return
			end)

			-- Reset button handler
			TimerPanel.r:SetScript("OnClick", function()

				-- Reset position and scale
				RGXQoLLC["TimerA"] = "TOP"
				RGXQoLLC["TimerR"] = "TOP"
				RGXQoLLC["TimerX"] = -5
				RGXQoLLC["TimerY"] = -96
				RGXQoLLC["TimerScale"] = 1
				MirrorTimer1:ClearAllPoints()
				MirrorTimer1:SetPoint(RGXQoLLC["TimerA"], UIParent, RGXQoLLC["TimerR"], RGXQoLLC["TimerX"], RGXQoLLC["TimerY"])

				-- Refresh configuration panel
				TimerPanel:Hide(); TimerPanel:Show()
				dragframe:Show()

				-- Show frame alignment grid
				RGXQoLLC.grid:Show()

			end)

			-- Show configuration panel when options panel button is clicked
			RGXQoLCB["ManageTimerButton"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["TimerA"] = "TOP"
					RGXQoLLC["TimerR"] = "TOP"
					RGXQoLLC["TimerX"] = 0
					RGXQoLLC["TimerY"] = -120
					RGXQoLLC["TimerScale"] = 1
					MirrorTimer1:ClearAllPoints()
					MirrorTimer1:SetPoint(RGXQoLLC["TimerA"], UIParent, RGXQoLLC["TimerR"], RGXQoLLC["TimerX"], RGXQoLLC["TimerY"])
					MirrorTimer1:SetScale(RGXQoLLC["TimerScale"])
				else
					-- Find out if the UI has a non-standard scale
					if GetCVar("useuiscale") == "1" then
						RGXQoLLC["gscale"] = GetCVar("uiscale")
					else
						RGXQoLLC["gscale"] = 1
					end

					-- Set drag frame size according to UI scale
					dragframe:SetWidth(206 * RGXQoLLC["gscale"])
					dragframe:SetHeight(20 * RGXQoLLC["gscale"])
					dragframe:SetFrameStrata("HIGH") -- MirrorTimer is medium

					-- Show configuration panel
					TimerPanel:Show()
					RGXQoLLC:HideFrames()
					dragframe:Show()

					-- Show frame alignment grid
					RGXQoLLC.grid:Show()
				end
			end)

			-- Hide drag frame when configuration panel is closed
			TimerPanel:HookScript("OnHide", function() dragframe:Hide() end)

		end

		----------------------------------------------------------------------
		-- Show ready timer
		----------------------------------------------------------------------

		if RGXQoLLC["ShowReadyTimer"] == "On" then

			-- Player vs Player
			do

				-- Declare variables
				local t, barTime = -1, -1

				-- Create status bar below dungeon ready popup
				local bar = CreateFrame("StatusBar", nil, PVPReadyDialog)
				bar:SetPoint("TOPLEFT", PVPReadyDialog, "BOTTOMLEFT", 0, -5)
				bar:SetPoint("TOPRIGHT", PVPReadyDialog, "BOTTOMRIGHT", 0, -5)
				bar:SetHeight(5)
				bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
				bar:SetStatusBarColor(1.0, 0.85, 0.0)

				-- Create status bar text
				local text = bar:CreateFontString(nil, "ARTWORK")
				text:SetFontObject("GameFontNormalLarge")
				text:SetTextColor(1.0, 0.85, 0.0)
				text:SetPoint("TOP", 0, -10)

				-- Update bar as timer counts down
				bar:SetScript("OnUpdate", function(self, elapsed)
					t = t - elapsed
					if barTime >= 1 or barTime == -1 then
						self:SetValue(t)
						text:SetText(SecondsToTime(floor(t + 0.5)))
						barTime = 0
					end
					barTime = barTime + elapsed
				end)

				-- Show frame when PvP ready frame shows
				hooksecurefunc("PVPReadyDialog_Display", function(self, id)
					t = GetBattlefieldPortExpiration(id) + 1
					-- t = 89; -- debug
					if t and t > 1 then
						bar:SetMinMaxValues(0, t)
						barTime = -1
						bar:Show()
					else
						bar:Hide()
					end
				end)

				PVPReadyDialog:HookScript("OnHide", function()
					bar:Hide()
				end)

				-- Debug
				-- C_Timer.After(2, function() PVPReadyDialog_Display(self, 1, "Warsong Gulch", 0, "BATTLEGROUND", "", "DAMAGER"); bar:Show() end)

			end

		end

		----------------------------------------------------------------------
		-- Show flight times
		----------------------------------------------------------------------

		if RGXQoLLC["ShowFlightTimes"] == "On" then

			-- Load flight data
			RGXQoLAddon["FlightData"] = {}
			local faction = UnitFactionGroup("player")
			if faction == "Alliance" then
				RGXQoLAddon:LoadFlightDataAlliance()
			elseif faction == "Horde" then
				RGXQoLAddon:LoadFlightDataHorde()
			end

			-- Minimum time difference (in seconds) to flight data entry before flight report window is shown
			local timeBuffer = 15

			-- Create editbox
			local editFrame = CreateFrame("ScrollFrame", nil, UIParent, "RGXQoLShowFlightTimesScrollFrameTemplate")

			-- Set frame parameters
			editFrame:ClearAllPoints()
			editFrame:SetPoint("BOTTOM", 0, 130)
			editFrame:SetSize(600, 200)
			editFrame:SetFrameStrata("MEDIUM")
			editFrame:SetToplevel(true)
			editFrame:Hide()

			-- Add background color
			editFrame.t = editFrame:CreateTexture(nil, "BACKGROUND")
			editFrame.t:SetAllPoints()
			editFrame.t:SetColorTexture(0.00, 0.00, 0.0, 0.6)

			-- Create title bar
			local titleFrame = CreateFrame("Frame", nil, editFrame)
			titleFrame:ClearAllPoints()
			titleFrame:SetPoint("TOP", 0, 24)
			titleFrame:SetSize(600, 24)
			titleFrame:SetFrameStrata("MEDIUM")
			titleFrame:SetToplevel(true)
			titleFrame:SetHitRectInsets(-6, -6, -6, -6)
			titleFrame.t = titleFrame:CreateTexture(nil, "BACKGROUND")
			titleFrame.t:SetAllPoints()
			titleFrame.t:SetColorTexture(0.00, 0.00, 0.0, 0.8)

			-- Add title
			titleFrame.m = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			titleFrame.m:SetPoint("LEFT", 4, 0)
			titleFrame.m:SetText(L["Leatrix Plus"])
			titleFrame.m:SetFont(titleFrame.m:GetFont(), 16, nil)

			-- Add right-click to close message
			titleFrame.x = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			titleFrame.x:SetPoint("RIGHT", -4, 0)
			titleFrame.x:SetText(L["Right-click to close"])
			titleFrame.x:SetFont(titleFrame.x:GetFont(), 16, nil)
			titleFrame.x:SetWidth(600 - titleFrame.m:GetStringWidth() - 30)
			titleFrame.x:SetWordWrap(false)
			titleFrame.x:SetJustifyH("RIGHT")

			-- Create editbox
			local editBox = CreateFrame("EditBox", nil, editFrame)
			editBox:SetAltArrowKeyMode(false)
			editBox:SetTextInsets(4, 4, 4, 4)
			editBox:SetWidth(editFrame:GetWidth() - 30)
			editBox:SetSecurityDisablePaste()
			editBox:SetFont(_G["ChatFrame1"]:GetFont())
			editBox:SetMaxLetters(0)
			editBox:SetMultiLine(true)

			editFrame:SetScrollChild(editBox)

			local introMsg = L["Leatrix Plus needs to be updated with the flight details.  Press CTRL/C to copy the flight details below then paste them into an email to flight@leatrix.com.  When your report is received, Leatrix Plus will be updated and you will never see this window again for this flight."] .. "|n|n"
			local startHighlight = string.len(introMsg)

			local function DoHighlight()
				editBox:HighlightText(startHighlight)
			end

			editBox:SetScript("OnEscapePressed", DoHighlight)
			editBox:SetScript("OnEnterPressed", DoHighlight)
			editBox:SetScript("OnMouseUp", DoHighlight)
			editBox:HookScript("OnShow", function()
				editBox:SetFocus(); DoHighlight()
			end)

			-- Close frame with right-click of editframe or editbox
			local function CloseFlightReportWindow(self, btn)
				if btn and btn == "RightButton" then
					editBox:SetText("")
					editBox:ClearFocus()
					editFrame:Hide()
				end
			end

			editFrame:SetScript("OnMouseDown", CloseFlightReportWindow)
			editBox:SetScript("OnMouseDown", CloseFlightReportWindow)
			titleFrame:HookScript("OnMouseDown", CloseFlightReportWindow)

			-- Disable text changes while still allowing editing controls to work
			editBox:EnableKeyboard(false)
			editBox:SetScript("OnKeyDown", function() end)

			-- Debug (uncomment to show flight report window test)
			-- editBox:SetText(introMsg .. "Flight details (Classic Era): Nesingwary Base Camp (0.18:0.40) to Conquest Hold (0.70:0.55) (Horde) took 690 seconds (5 hop)." .. "|n|n" .. "[" .. '"' .. "0.18:0.40:0.24:0.40:0.52:0.38:0.54:0.52:0.59:0.55:0.70:0.55" .. '"' .. "] = 690, -- Nesingwary Base Camp, River's Heart, Dalaran, Wyrmrest Temple, Venomspite, Conquest Hold|n|nThis flight does not exist in the database."); editFrame:Show()

			-- Load LibCandyBar
			RGXQoLAddon:RGXQoLCandyBar()

			-- Variables
			local data = RGXQoLAddon["FlightData"]
			local candy = LibStub("LibCandyBar-3.0")
			local texture = "Interface\\TargetingFrame\\UI-StatusBar"
			local flightFrame = CreateFrame("FRAME")
			RGXQoLLC.flightFrame = flightFrame

			-- Set game title as shown in incorrect flight details window
			local gameTitle = L["Classic Era"]
			if C_Seasons.HasActiveSeason() then -- (C_GameRules.IsHardcoreActive())
				gameTitle = L["Classic Era (HC)"]
			end

			-- Function to get continent
			local function getContinent()
				local mapID = C_Map.GetBestMapForUnit("player")
				if(mapID) then
					local info = C_Map.GetMapInfo(mapID)
					if(info) then
						while(info['mapType'] and info['mapType'] > 2) do
							info = C_Map.GetMapInfo(info['parentMapID'])
						end
						if(info['mapType'] == 2) then
							return info['mapID']
						end
					end
				end
			end

			-- Function to get node name
			local function GetNodeName(i)
				return strmatch(TaxiNodeName(i), "[^,]+")
			end

			-- Show progress bar when flight is taken
			hooksecurefunc("TakeTaxiNode", function(node)
				if UnitAffectingCombat("player") then return end
				if editFrame:IsShown() then editFrame:Hide() end
				for i = 1, NumTaxiNodes() do
					local nodeType = TaxiNodeGetType(i)
					local nodeName = GetNodeName(i)
					if nodeType == "CURRENT" then

						-- Get current node
						local continent = getContinent()
						local startX, startY = TaxiNodePosition(i)
						local currentNode = string.format("%0.2f", startX) .. ":" .. string.format("%0.2f", startY)

						-- Get flight duration and start the progress timer
						local endX, endY = TaxiNodePosition(node)
						local destination = string.format("%0.2f", endX) .. ":" .. string.format("%0.2f", endY)
						local barName = GetNodeName(node)

						-- Assign file level scope to destination (it's used for removing bar name)
						RGXQoLLC.FlightDestination = barName

						-- Build route string and debug string
						local numHops = GetNumRoutes(node)
						local debugString = '\t\t\t\t\t["' .. currentNode
						local routeString = currentNode
						for i = 2, numHops + 1 do
							local hopPosX, hopPosY = TaxiNodePosition(TaxiGetNodeSlot(node, i, true))
							local hopPos = string.format("%0.2f", hopPosX) .. ":" .. string.format("%0.2f", hopPosY)
							local fpName = string.split(", ", TaxiNodeName(TaxiGetNodeSlot(node, i, true)))
							debugString = debugString .. ":" .. hopPos
							routeString = routeString .. ":" .. hopPos
						end

						-- If route string does not contain destination, add it to the end (such as Altar of Sha'tar)
						if not string.find(routeString, destination) then
							debugString = debugString .. ":" .. destination
							routeString = routeString .. ":" .. destination
						end

						debugString = debugString .. '"] = TimeTakenPlaceHolder,'
						debugString = debugString .. " -- " .. nodeName
						for i = 2, numHops + 1 do
							local fpName = string.split(",", TaxiNodeName(TaxiGetNodeSlot(node, i, true)))
							debugString = debugString .. ", " .. fpName
						end

						-- If debug string does not contain destination, add it to the end
						if not string.find(debugString, barName) then
							debugString = debugString .. ", " .. barName
						end

						-- Handle flight time not correct or flight does not exist in database
						local timeStart = GetTime()
						C_Timer.After(1, function()
							if UnitOnTaxi("player") then
								-- Player is on a taxi so register when taxi lands
								flightFrame:RegisterEvent("PLAYER_CONTROL_GAINED")
							else
								-- Player is not on a taxi so delete the flight progress bar
								flightFrame:UnregisterEvent("PLAYER_CONTROL_GAINED")
								if RGXQoLLC.FlightProgressBar then
									RGXQoLLC.FlightProgressBar:Stop()
									RGXQoLLC.FlightProgressBar = nil
								end
							end
						end)
						flightFrame:SetScript("OnEvent", function()
							local timeEnd = GetTime()
							local timeTaken = timeEnd - timeStart
							debugString = gsub(debugString, "TimeTakenPlaceHolder", string.format("%0.0f", timeTaken))
							local flightMsg = L["Flight details"] .. " (" .. gameTitle.. "): " .. nodeName .. " (" .. currentNode .. ") " .. L["to"] .. " " .. barName .. " (" .. destination .. ") (" .. faction .. ") " .. L["took"] .. " " .. string.format("%0.0f", timeTaken) .. " " .. L["seconds"] .. " (" .. numHops .. " " .. L["hop"] ..").|n|n" .. debugString .. "|n|n"
							if destination and data[faction] and data[faction][continent] and data[faction][continent][routeString] then
								local savedDuration = data[faction][continent][routeString]
								if savedDuration then
									if timeTaken > (savedDuration + timeBuffer) or timeTaken < (savedDuration - timeBuffer) then
										local editMsg = introMsg .. flightMsg .. L["This flight's actual time of"] .. " " .. string.format("%0.0f", timeTaken) .. " " .. L["seconds does not match the saved flight time of"] .. " " .. savedDuration .. " " .. L["seconds"] .. "."
										editBox:SetText(editMsg); if RGXQoLLC["FlightBarContribute"] == "On2" then editFrame:Show() end -- RGXQoLLC.NewPatch: Currently disabled, change to On to enable again
									end
								else
									local editMsg = introMsg .. flightMsg .. L["This flight does not have a saved duration in the database."]
									editBox:SetText(editMsg); if RGXQoLLC["FlightBarContribute"] == "On2" then editFrame:Show() end -- RGXQoLLC.NewPatch: Currently disabled, change to On to enable again
								end
							else
								local editMsg = introMsg .. flightMsg .. L["This flight does not exist in the database."]
								editBox:SetText(editMsg); if RGXQoLLC["FlightBarContribute"] == "On2" then editFrame:Show() end -- RGXQoLLC.NewPatch: Currently disabled, change to On to enable again
							end
							flightFrame:UnregisterEvent("PLAYER_CONTROL_GAINED")

							-- Delete the progress bar since we have landed
							if RGXQoLLC.FlightProgressBar then
								RGXQoLLC.FlightProgressBar:Stop()
								RGXQoLLC.FlightProgressBar = nil
							end
						end)

						-- Show flight progress bar if flight exists in database
						if data[faction] and data[faction][continent] and data[faction][continent][routeString] then

							local duration = data[faction][continent][routeString]
							if duration then

								-- Delete an existing progress bar if one exists
								if RGXQoLLC.FlightProgressBar then
									RGXQoLLC.FlightProgressBar:Stop()
									RGXQoLLC.FlightProgressBar = nil
								end

								-- Create progress bar
								local mybar = candy:New(texture, 230, 16)
								mybar:SetPoint(RGXQoLLC["FlightBarA"], UIParent, RGXQoLLC["FlightBarR"], RGXQoLLC["FlightBarX"], RGXQoLLC["FlightBarY"])
								mybar:SetScale(RGXQoLLC["FlightBarScale"])
								mybar:SetWidth(RGXQoLLC["FlightBarWidth"])

								-- Setup sound files
								local mt
								local Seconds600, Seconds540, Seconds480, Seconds420, Seconds360
								local Seconds300, Seconds240, Seconds180, Seconds120, Seconds060
								local Seconds030, Seconds020, Seconds010
								local speed = -2

								if RGXQoLLC["FlightBarSpeech"] == "On" then
									C_Timer.After(1, function()
										C_VoiceChat.SpeakText(0, L["Flight commenced."], speed, GetCVar("Sound_MasterVolume") * 100)
									end)
									mybar:AddUpdateFunction(function(bar)
										mt = bar.remaining
											if mt > 600 and mt < 601 and not Seconds600 then Seconds600 = true; C_VoiceChat.SpeakText(0, L["Ten minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 540 and mt < 541 and not Seconds540 then Seconds540 = true; C_VoiceChat.SpeakText(0, L["Nine minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 480 and mt < 481 and not Seconds480 then Seconds480 = true; C_VoiceChat.SpeakText(0, L["Eight minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 420 and mt < 421 and not Seconds420 then Seconds420 = true; C_VoiceChat.SpeakText(0, L["Seven minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 360 and mt < 361 and not Seconds360 then Seconds360 = true; C_VoiceChat.SpeakText(0, L["Six minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 300 and mt < 301 and not Seconds300 then Seconds300 = true; C_VoiceChat.SpeakText(0, L["Five minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 240 and mt < 241 and not Seconds240 then Seconds240 = true; C_VoiceChat.SpeakText(0, L["Four minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 180 and mt < 181 and not Seconds180 then Seconds180 = true; C_VoiceChat.SpeakText(0, L["Three minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 120 and mt < 121 and not Seconds120 then Seconds120 = true; C_VoiceChat.SpeakText(0, L["Two minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 060 and mt < 061 and not Seconds060 then Seconds060 = true; C_VoiceChat.SpeakText(0, L["One minute"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 030 and mt < 031 and not Seconds030 then Seconds030 = true; C_VoiceChat.SpeakText(0, L["Thirty seconds"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 020 and mt < 021 and not Seconds020 then Seconds020 = true; C_VoiceChat.SpeakText(0, L["Twenty seconds"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 010 and mt < 011 and not Seconds010 then Seconds010 = true; C_VoiceChat.SpeakText(0, L["Ten seconds"], speed, GetCVar("Sound_MasterVolume") * 100)
										end
									end)
								end

								if faction == "Alliance" then
									mybar:SetColor(0, 0.5, 1, 0.5)
								else
									mybar:SetColor(1, 0.0, 0, 0.5)
								end
								mybar:SetShadowColor(0, 0, 0, 0.5)

								mybar:SetScript("OnMouseDown", function(self, btn)
									if btn == "RightButton" then
										mybar:Stop()
										RGXQoLLC.FlightProgressBar = nil
									end
								end)

								-- Set bar label width
								-- barName = "SupercalifragilisticexpialidociousDociousaliexpisticfragicalirupus" -- Debug
								mybar.candyBarLabel:ClearAllPoints()
								mybar.candyBarLabel:SetPoint("TOPLEFT", mybar.candyBarBackground, "TOPLEFT", 2, 0)
								mybar.candyBarLabel:SetPoint("BOTTOMRIGHT", mybar.candyBarBackground, "BOTTOMRIGHT", -40, 0)

								-- Set flight bar background
								if RGXQoLLC["FlightBarBackground"] == "On" then
									if RGXQoLLC.ElvUI then
										_G.LeaPlusGlobalFlightBar = mybar.candyBarBar
										if faction == "Alliance" then
											RGXQoLLC.ElvUI:GetModule("Skins"):HandleStatusBar(_G.LeaPlusGlobalFlightBar, {0, 0.5, 1, 0.5})
										else
											RGXQoLLC.ElvUI:GetModule("Skins"):HandleStatusBar(_G.LeaPlusGlobalFlightBar, {1, 0.0, 0, 0.5})
										end
									else
										mybar:SetTexture(texture)
									end
								else
									mybar:SetTexture("")
								end

								-- Set flight bar destination
								if RGXQoLLC["FlightBarDestination"] == "On" then
									mybar:SetLabel(barName)
								end

								-- Set flight bar fill mode
								if RGXQoLLC["FlightBarFillBar"] == "On" then
									mybar:SetFill(true)
								else
									mybar:SetFill(false)
								end

								mybar:EnableMouse(false)
								mybar:SetDuration(duration)
								mybar:Start()

								-- Unlock close bar button
								if RGXQoLCB["CloseFlightBarButton"] then
									RGXQoLLC:LockItem(RGXQoLCB["CloseFlightBarButton"], false)
								end

								-- Assign file level scope to the bar so it can be cancelled later
								RGXQoLLC.FlightProgressBar = mybar

							end

						end

					end
				end
			end)

			-- Function to stop the progress bar
			local function CeaseProgress()
				if RGXQoLLC.FlightProgressBar then
					RGXQoLLC.FlightProgressBar:Stop()
					RGXQoLLC.FlightProgressBar = nil
				end
			end

			-- Stop the progress bar under various circumstances
			hooksecurefunc("TaxiRequestEarlyLanding", CeaseProgress)
			hooksecurefunc("AcceptBattlefieldPort", CeaseProgress)
			hooksecurefunc(C_SummonInfo, "ConfirmSummon", CeaseProgress)

			-- Show flight time in node tooltips
			hooksecurefunc("TaxiNodeOnButtonEnter", function(button)
				local index = button:GetID()
				for i = 1, NumTaxiNodes() do
					local nodeType = TaxiNodeGetType(i)
					local nodeName = GetNodeName(i)
					if nodeType == "CURRENT" then

						-- Get current node
						local continent = getContinent()
						local startX, startY = TaxiNodePosition(i)
						local currentNode = string.format("%0.2f", startX) .. ":" .. string.format("%0.2f", startY)

						-- Get destination
						local endX, endY = TaxiNodePosition(index)
						local destination = string.format("%0.2f", endX) .. ":" .. string.format("%0.2f", endY)
						local barName = GetNodeName(index)

						-- Build route string and debug string
						local numEnterHops = GetNumRoutes(index)
						local debugString = '["' .. currentNode
						local routeString = currentNode
						for i = 2, numEnterHops + 1 do
							local hopPosX, hopPosY = TaxiNodePosition(TaxiGetNodeSlot(index, i, true)) -- TaxiNodeName
							local hopPos = string.format("%0.2f", hopPosX) .. ":" .. string.format("%0.2f", hopPosY)
							local fpName = string.split(", ", TaxiNodeName(TaxiGetNodeSlot(index, i, true)))
							debugString = debugString .. ":" .. hopPos
							routeString = routeString .. ":" .. hopPos
						end

						-- If route string does not contain destination, add it to the end (such as Altar of Sha'tar)
						if not string.find(routeString, destination) then
							debugString = debugString .. ":" .. destination
							routeString = routeString .. ":" .. destination
						end
						debugString = debugString .. '"] = '

						-- Show flight time in tooltip if it exists
						if data[faction] and data[faction][continent] and data[faction][continent][routeString] then
							local duration = data[faction][continent][routeString]
							if duration and type(duration) == "number" then
								duration = date("%M:%S", duration):gsub("^0","")
								GameTooltip:AddLine(L["Duration"] .. ": " .. duration, 0.9, 0.9, 0.9, true)
								GameTooltip:Show()
							end
						elseif currentNode ~= destination then
							GameTooltip:AddLine(L["Duration"] .. ": -:--", 0.9, 0.9, 0.9, true)
							GameTooltip:Show()
						end

						-- Add node names to debug string
						debugString = debugString .. " -- " .. nodeName
						for i = 2, numEnterHops + 1 do
							local fpName = string.split(",", TaxiNodeName(TaxiGetNodeSlot(index, i, true)))
							debugString = debugString .. ", " .. fpName
						end

						-- If debug string does not contain destination, add it to the end
						if not string.find(debugString, barName) then
							debugString = debugString .. ", " .. barName
						end

						-- Print debug string (used for showing full routes for nodes)
						-- print(debugString)

					end
				end
			end)

			-- Unregister landing event for various reasons that stop taxi early
			local function StopLandingEvent()
				RGXQoLLC.flightFrame:UnregisterEvent("PLAYER_CONTROL_GAINED")
			end

			hooksecurefunc("TaxiNodeOnButtonEnter", StopLandingEvent)
			hooksecurefunc("TaxiRequestEarlyLanding", StopLandingEvent)
			hooksecurefunc("AcceptBattlefieldPort", StopLandingEvent)
			hooksecurefunc(C_SummonInfo, "ConfirmSummon", StopLandingEvent)

			----------------------------------------------------------------------
			-- Drag frame
			----------------------------------------------------------------------

			-- Create drag frame
			local tempFrame = CreateFrame("FRAME", nil, UIParent)
			tempFrame:SetWidth(230)
			tempFrame:SetHeight(16)
			tempFrame:SetScale(2)
			tempFrame:ClearAllPoints()
			tempFrame:SetPoint(RGXQoLLC["FlightBarA"], UIParent, RGXQoLLC["FlightBarR"], RGXQoLLC["FlightBarX"], RGXQoLLC["FlightBarY"])
			tempFrame:Hide()
			tempFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			tempFrame:SetFrameLevel(5000)
			tempFrame:SetClampedToScreen(false)

			-- Create texture
			tempFrame.t = tempFrame:CreateTexture(nil, "BORDER")
			tempFrame.t:SetAllPoints()
			tempFrame.t:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
			tempFrame.t:SetVertexColor(0.0, 1.0, 0.0, 0.5)

			-- Enable movement
			tempFrame:EnableMouse(true)
			tempFrame:SetMovable(true)
			tempFrame:SetScript("OnMouseDown", function()
				tempFrame:StartMoving()
			end)
			tempFrame:SetScript("OnMouseUp", function()
				tempFrame:StopMovingOrSizing()
				RGXQoLLC["FlightBarA"], void, RGXQoLLC["FlightBarR"], RGXQoLLC["FlightBarX"], RGXQoLLC["FlightBarY"] = tempFrame:GetPoint()
				-- Position actual flight progress bar if one exists
				if RGXQoLLC.FlightProgressBar then
					RGXQoLLC.FlightProgressBar:ClearAllPoints()
					RGXQoLLC.FlightProgressBar:SetPoint(RGXQoLLC["FlightBarA"], UIParent, RGXQoLLC["FlightBarR"], RGXQoLLC["FlightBarX"], RGXQoLLC["FlightBarY"])
				end
			end)

			----------------------------------------------------------------------
			-- Configuration panel
			----------------------------------------------------------------------

			-- Create configuration panel
			local FlightPanel = RGXQoLLC:CreatePanel("Show flight times", "FlightPanel")

			RGXQoLLC:MakeTx(FlightPanel, "Settings", 16, -72)
			RGXQoLLC:MakeCB(FlightPanel, "FlightBarBackground", "Show background", 16, -92, false, "If checked, the flight progress bar background texture will be shown.")
			RGXQoLLC:MakeCB(FlightPanel, "FlightBarDestination", "Show destination", 16, -112, false, "If checked, the flight progress bar destination will be shown.")
			RGXQoLLC:MakeCB(FlightPanel, "FlightBarFillBar", "Fill instead of drain", 16, -132, false, "If checked, the flight progress bar background will fill instead of drain.")
			RGXQoLLC:MakeCB(FlightPanel, "FlightBarSpeech", "Speak the remaining time", 16, -152, false, "If checked, the remaining flight time will be spoken using text to speech.|n|nChanges to this setting will take effect on the next flight you take.")

			RGXQoLLC:MakeTx(FlightPanel, "Contribute", 16, -192)
			RGXQoLLC:MakeCB(FlightPanel, "FlightBarContribute", "Help contribute flight times", 16, -212, false, "If checked, you will be prompted to submit missing flight times.")

			RGXQoLLC:MakeTx(FlightPanel, "Scale", 356, -72)
			RGXQoLLC:MakeSL(FlightPanel, "FlightBarScale", "Drag to set the flight progress bar scale.", 1, 5, 0.1, 356, -92, "%.2f")

			RGXQoLLC:MakeTx(FlightPanel, "Width", 356, -132)
			RGXQoLLC:MakeSL(FlightPanel, "FlightBarWidth", "Drag to set the flight progress bar width.", 40, 460, 10, 356, -152, "%.0f")

			-- Function to lock an option and add a note to the tooltip
			local function LockDF(option, reason)
				RGXQoLLC:LockItem(RGXQoLCB[option], true)
				if reason then
					RGXQoLCB[option].tiptext = RGXQoLCB[option].tiptext .. "|n|n|cff00AAFF" .. L[reason]
				end
			end

			-- RGXQoLLC.NewPatch
			LockDF("FlightBarContribute", L["This option is not currently available."])

			-- Add close bar button
			local CloseFlightBarButton = RGXQoLLC:CreateButton("CloseFlightBarButton", FlightPanel, "Close Bar", "TOPLEFT", 16, -72, 0, 25, true, "Click to close the currently active flight progress bar.")
			RGXQoLCB["CloseFlightBarButton"]:ClearAllPoints()
			RGXQoLCB["CloseFlightBarButton"]:SetPoint("LEFT", FlightPanel.h, "RIGHT", 10, 0)
			RGXQoLCB["CloseFlightBarButton"]:SetScript("OnClick", function()
				if RGXQoLLC.FlightProgressBar then
					RGXQoLLC.FlightProgressBar:Stop()
					RGXQoLLC.FlightProgressBar = nil
				end
			end)

			-- Lock close bar button at startup and when flight progress bar stops
			RGXQoLLC:LockItem(RGXQoLCB["CloseFlightBarButton"], true)
			candy.RegisterCallback(RGXQoLLC, "LibCandyBar_Stop", function()
				if RGXQoLCB["CloseFlightBarButton"] then
					RGXQoLLC:LockItem(RGXQoLCB["CloseFlightBarButton"], true)
				end
			end)

			-- Set progress bar background
			if RGXQoLLC.ElvUI then

				-- Progress bar background is always enabled and cannot be disabled with ElvUI
				RGXQoLLC:LockItem(RGXQoLCB["FlightBarBackground"], true)
				RGXQoLLC["FlightBarBackground"] = "On"
				RGXQoLCB["FlightBarBackground"].tiptext = RGXQoLCB["FlightBarBackground"].tiptext .. "|n|n|cff00AAFF" .. L["The background is always shown with ElvUI."]

			else

				-- Set progress bar background
				local function SetProgressBarBackground()
					if RGXQoLLC.FlightProgressBar then
						if RGXQoLLC["FlightBarBackground"] == "On" then
							RGXQoLLC.FlightProgressBar:SetTexture(texture)
						else
							RGXQoLLC.FlightProgressBar:SetTexture("")
						end
					end
				end

				-- Set progress bar background when option is clicked and on startup
				RGXQoLCB["FlightBarBackground"]:HookScript("OnClick", SetProgressBarBackground)
				SetProgressBarBackground()

			end

			-- Set progress bar fill mode
			local function SetProgressBarFillMode()
				if RGXQoLLC.FlightProgressBar then
					if RGXQoLLC["FlightBarFillBar"] == "On" then
						RGXQoLLC.FlightProgressBar:SetFill(true)
					else
						RGXQoLLC.FlightProgressBar:SetFill(false)
					end
				end
			end

			-- Set progress bar fill mode when option is clicked and on startup
			RGXQoLCB["FlightBarFillBar"]:HookScript("OnClick", SetProgressBarFillMode)
			SetProgressBarFillMode()

			-- Set progress bar destination
			local function SetProgressBarDestination()
				if RGXQoLLC.FlightProgressBar then
					if RGXQoLLC["FlightBarDestination"] == "On" then
						if RGXQoLLC.FlightDestination then
							RGXQoLLC.FlightProgressBar:SetLabel(RGXQoLLC.FlightDestination)
						end
					else
						RGXQoLLC.FlightProgressBar:SetLabel("")
					end
				end
			end

			-- Set flight bar destination when option is clicked and on startup
			RGXQoLCB["FlightBarDestination"]:HookScript("OnClick", SetProgressBarDestination)
			SetProgressBarDestination()

			-- Flight progress bar scale
			local function SetFlightBarScale()
				tempFrame:SetScale(RGXQoLLC["FlightBarScale"])
				if RGXQoLLC.FlightProgressBar then
					RGXQoLLC.FlightProgressBar:SetScale(RGXQoLLC["FlightBarScale"])
				end
				-- Set slider formatted text
				RGXQoLCB["FlightBarScale"].f:SetFormattedText("%.0f%%", (RGXQoLLC["FlightBarScale"] / 2) * 100)
			end

			-- Set flight bar scale when slider is changed and on startup
			RGXQoLCB["FlightBarScale"]:HookScript("OnValueChanged", SetFlightBarScale)
			SetFlightBarScale()

			-- Flight progress bar width
			local function SetFlightBarWidth()
				tempFrame:SetWidth(RGXQoLLC["FlightBarWidth"])
				if RGXQoLLC.FlightProgressBar then
					RGXQoLLC.FlightProgressBar:SetWidth(RGXQoLLC["FlightBarWidth"])
				end
				-- Set slider formatted text
				RGXQoLCB["FlightBarWidth"].f:SetFormattedText("%.0f%%", (RGXQoLLC["FlightBarWidth"] / 230) * 100)
			end

			-- Set flight bar width when slider is changed and on startup
			RGXQoLCB["FlightBarWidth"]:HookScript("OnValueChanged", SetFlightBarWidth)
			SetFlightBarWidth()

			-- Help button tooltip
			FlightPanel.h.tiptext = L["Drag the frame overlay to position the frame."]

			-- Back button handler
			FlightPanel.b:SetScript("OnClick", function()
				FlightPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			FlightPanel.r:SetScript("OnClick", function()

				-- Reset controls
				RGXQoLLC["FlightBarA"], RGXQoLLC["FlightBarR"], RGXQoLLC["FlightBarX"], RGXQoLLC["FlightBarY"] = "TOP", "TOP", 0, -66
				tempFrame:ClearAllPoints()
				tempFrame:SetPoint(RGXQoLLC["FlightBarA"], UIParent, RGXQoLLC["FlightBarR"], RGXQoLLC["FlightBarX"], RGXQoLLC["FlightBarY"])
				-- Reset scale
				RGXQoLLC["FlightBarScale"] = 2
				tempFrame:SetScale(RGXQoLLC["FlightBarScale"])
				-- Reset width
				RGXQoLLC["FlightBarWidth"] = 230
				tempFrame:SetWidth(RGXQoLLC["FlightBarWidth"])
				-- Reset checkboxes
				RGXQoLLC["FlightBarBackground"] = "On"
				RGXQoLLC["FlightBarDestination"] = "On"
				RGXQoLLC["FlightBarFillBar"] = "Off"; SetProgressBarFillMode()
				RGXQoLLC["FlightBarSpeech"] = "Off"
				RGXQoLLC["FlightBarContribute"] = "On"
				-- Reset live progress bar
				if RGXQoLLC.FlightProgressBar then
					-- Reset position
					RGXQoLLC.FlightProgressBar:ClearAllPoints()
					RGXQoLLC.FlightProgressBar:SetPoint(RGXQoLLC["FlightBarA"], UIParent, RGXQoLLC["FlightBarR"], RGXQoLLC["FlightBarX"], RGXQoLLC["FlightBarY"])
					RGXQoLLC.FlightProgressBar:SetScale(RGXQoLLC["FlightBarScale"])
					-- Reset width
					RGXQoLLC.FlightProgressBar:SetWidth(RGXQoLLC["FlightBarWidth"])
					-- Reset background
					RGXQoLLC.FlightProgressBar:SetTexture(texture)
					-- Reset destination
					if RGXQoLLC.FlightDestination then
						RGXQoLLC.FlightProgressBar:SetLabel(RGXQoLLC.FlightDestination)
					end
				end

				-- Refresh configuration panel
				FlightPanel:Hide(); FlightPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			RGXQoLCB["ShowFlightTimesBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["FlightBarContribute"] = "On"
				else
					FlightPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

			-- Toggle drag frame with configuration panel
			FlightPanel:HookScript("OnShow", function()
				tempFrame:Show()
			end)

			FlightPanel:HookScript("OnHide", function()
				tempFrame:Hide()
			end)

		end

		----------------------------------------------------------------------
		-- Enhance minimap
		----------------------------------------------------------------------

		if RGXQoLLC["MinimapModder"] == "On" and not RGXQoLLockList["MinimapModder"] then

			local miniFrame = CreateFrame("FRAME")
			local LibDBIconStub = LibStub("LibDBIcon-1.0")

			QuestWatchFrame:SetFrameStrata("LOW")

			-- Function to set button radius
			local function SetButtonRad()
				if RGXQoLLC["SquareMinimap"] == "On" then
					LibDBIconStub:SetButtonRadius(26 + ((RGXQoLLC["MinimapSize"] - 140) * 0.165))
				else
					LibDBIconStub:SetButtonRadius(1)
				end
			end

			-- Fix for bug in default UI which does not texture tracking button icon on login
			local icon = GetTrackingTexture()
			if icon and not MiniMapTrackingIcon:GetTexture() then
				MiniMapTrackingIcon:SetTexture(icon)
				MiniMapTracking:Show()
			end

			-- Disable mouse on invisible minimap cluster
			MinimapCluster:EnableMouse(false)

			----------------------------------------------------------------------
			-- Button test mode
			----------------------------------------------------------------------

			-- Create a ton of minimap buttons for test purposes
			local useMinimapButtonTestMode = false
			if useMinimapButtonTestMode then
				local numberOfTestButtons = 50
				local miniTable = {}
				for i = 1, numberOfTestButtons do
					miniTable[i] = LibStub("LibDataBroker-1.1"):NewDataObject("RGXQoL" .. i, {
						type = "data source",
						text = "Test Addon " .. i,
						icon = "Interface\\AddOns\\RGX-Framework\\media\\logo.tga",
						OnClick = function(self, btn)
							RGXQoLMiniBtnClickFunc(btn)
						end,
						OnTooltipShow = function(tooltip)
							if not tooltip or not tooltip.AddLine then return end
							tooltip:AddLine("Test Addon " .. i)
						end,
					})
					miniTable[i].minimapPos = i * 50
				end
				for i = 1, numberOfTestButtons do
					LibStub("LibDBIcon-1.0", true):Register("RGXQoL" .. i, miniTable[i], miniTable[i])
				end
			end

			----------------------------------------------------------------------
			-- Configuration panel
			----------------------------------------------------------------------

			-- Create configuration panel
			local SideMinimap = RGXQoLLC:CreatePanel("Enhance minimap", "SideMinimap", true)

			-- Hide panel during combat
			SideMinimap:SetScript("OnUpdate", function()
				if UnitAffectingCombat("player") then
					SideMinimap:Hide()
				end
			end)

			-- Add checkboxes
			RGXQoLLC:MakeTx(SideMinimap.scrollChild, "Settings", 16, 0)
			RGXQoLLC:MakeCB(SideMinimap.scrollChild, "HideMiniZoomBtns", "Hide the zoom buttons", 16, -20, false, "If checked, the zoom buttons will be hidden.  You can use the mousewheel to zoom regardless of this setting.")
			RGXQoLLC:MakeCB(SideMinimap.scrollChild, "HideMiniClock", "Hide the clock", 16, -40, false, "If checked, the clock will be hidden.")
			RGXQoLLC:MakeCB(SideMinimap.scrollChild, "HideMiniDayNight", "Hide the day and night indicator", 16, -60, true, "If checked, the day and night indicator will be hidden.")
			RGXQoLLC:MakeCB(SideMinimap.scrollChild, "HideMiniZoneText", "Hide the zone text bar", 16, -80, true, "If checked, the zone text bar will be hidden.")
			RGXQoLLC:MakeCB(SideMinimap.scrollChild, "HideMiniTracking", "Hide the tracking button", 16, -100, true, "If checked, the tracking button will be hidden while the pointer is not over the minimap.")
			RGXQoLLC:MakeCB(SideMinimap.scrollChild, "HideMiniLFG", "Hide the Looking for Group button", 16, -120, true, "If checked, the Looking for Group button will be hidden while you are not queued.|n|nThis only applies to game realms with a Looking for Group feature.")
			RGXQoLLC:MakeCB(SideMinimap.scrollChild, "HideMiniAddonButtons", "Hide addon buttons", 16, -140, false, "If checked, addon buttons will be hidden while the pointer is not over the minimap.")
			RGXQoLLC:MakeCB(SideMinimap.scrollChild, "MinimapButtonBag", "Minimap button bag", 16, -160, true, "If checked, minimap buttons for addons will be collected and placed in a bag which you can toggle by right-clicking the minimap.|n|nThis setting will help you declutter the minimap without the need to install a separate addon to do that.")
			RGXQoLLC:MakeCB(SideMinimap.scrollChild, "SquareMinimap", "Square minimap", 16, -180, true, "If checked, the minimap shape will be square.")

			-- Add excluded button
			local MiniExcludedButton = RGXQoLLC:CreateButton("MiniExcludedButton", SideMinimap, "Buttons", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the addon buttons editor.")
			RGXQoLCB["MiniExcludedButton"]:ClearAllPoints()
			RGXQoLCB["MiniExcludedButton"]:SetPoint("LEFT", SideMinimap.r, "RIGHT", 10, 0)

			-- Set exclude button visibility
			local function SetExcludeButtonsFunc()
				if RGXQoLLC["HideMiniAddonButtons"] == "On" or RGXQoLLC["MinimapButtonBag"] == "On" then
					RGXQoLLC:LockItem(RGXQoLCB["MiniExcludedButton"], false)
				else
					RGXQoLLC:LockItem(RGXQoLCB["MiniExcludedButton"], true)
				end
			end
			RGXQoLCB["HideMiniAddonButtons"]:HookScript("OnClick", SetExcludeButtonsFunc)
			SetExcludeButtonsFunc()

			-- Add slider controls
			RGXQoLLC:MakeTx(SideMinimap.scrollChild, "Square size", 356, 0)
			RGXQoLLC:MakeSL(SideMinimap.scrollChild, "MinimapSize", "Drag to set the square minimap size.|n|nAdjusting this slider makes the minimap bigger but keeps the elements the same size.", 140, 560, 1, 356, -10, "%.0f")

			RGXQoLLC:MakeTx(SideMinimap.scrollChild, "Border width", 356, -50)
			RGXQoLLC:MakeSL(SideMinimap.scrollChild, "MinimapBorderWidth", "Drag to set the square minimap border width.", 1, 10, 1, 356, -60, "%.0f")

			----------------------------------------------------------------------
			-- Addon buttons editor
			----------------------------------------------------------------------

			do

				-- Create configuration panel
				local ExcludedButtonsPanel = RGXQoLLC:CreatePanel("Enhance minimap", "ExcludedButtonsPanel")
				local boxWidth = 272

				-- Add second excluded button
				local MiniExcludedButton2 = RGXQoLLC:CreateButton("MiniExcludedButton2", ExcludedButtonsPanel, "Buttons", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the addon buttons editor.")
				RGXQoLCB["MiniExcludedButton2"]:ClearAllPoints()
				RGXQoLCB["MiniExcludedButton2"]:SetPoint("LEFT", ExcludedButtonsPanel.r, "RIGHT", 10, 0)
				RGXQoLCB["MiniExcludedButton2"]:SetScript("OnClick", function()
					ExcludedButtonsPanel:Hide(); SideMinimap:Show()
					return
				end)

				-- Add large editbox
				local titleTX = RGXQoLLC:MakeTx(ExcludedButtonsPanel, "Editor", 16, -72)
				titleTX:SetWidth(boxWidth - 14) -- 534
				titleTX:SetWordWrap(false)
				titleTX:SetJustifyH("LEFT")

				-- Add help button
				RGXQoLLC:CreateHelpButton("MinimapButtonsAvailableHelpButton", ExcludedButtonsPanel, titleTX, "If you use the 'Hide addon buttons' or 'Minimap button bag' settings but you want some addon buttons to remain visible around the minimap, enter the button names into the editbox below separated by commas.|n|nChanges will require a UI reload to take effect.")

				local eb = CreateFrame("Frame", nil, ExcludedButtonsPanel, "BackdropTemplate")
				eb:SetSize(boxWidth, RGXQoLLC.MainPanelHeight - 180) -- 548
				eb:SetPoint("TOPLEFT", 10, -92)
				eb:SetBackdrop({
					bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
					edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
					edgeSize = 16,
					insets = { left = 8, right = 6, top = 8, bottom = 8 },
				})
				eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)

				eb.scroll = CreateFrame("ScrollFrame", nil, eb, "RGXQoLEnhanceMinimapExcludeButtonsScrollFrameTemplate")
				eb.scroll:SetPoint("TOPLEFT", eb, 12, -10)
				eb.scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)
				eb.scroll:SetPanExtent(16)

				-- Create character count
				eb.scroll.CharCount = eb.scroll:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
				eb.scroll.CharCount:Hide()

				eb.Text = eb.scroll.EditBox
				eb.Text:SetWidth(boxWidth - 54) -- 494
				eb.Text:SetHeight(230)
				eb.Text:SetPoint("TOPLEFT", eb.scroll)
				eb.Text:SetPoint("BOTTOMRIGHT", eb.scroll, -12, 0)
				eb.Text:SetMaxLetters(1200)
				eb.Text:SetFontObject(GameFontNormalLarge)
				eb.Text:SetAutoFocus(false)
				eb.scroll:SetScrollChild(eb.Text)

				-- Set focus on the editbox text when clicking the editbox
				eb:SetScript("OnMouseDown", function()
					eb.Text:SetFocus()
					eb.Text:SetCursorPosition(eb.Text:GetMaxLetters())
				end)

				-- Debug
				-- eb.Text:SetText("RGXQoL\nLeatrix_Maps\nBugSack\nRGXQoL\nLeatrix_Maps\nBugSack\nRGXQoL\nLeatrix_Maps\nBugSack\nRGXQoL\nLeatrix_Maps\nBugSack\nRGXQoL\nLeatrix_Maps\nBugSack")

				-- Function to save the excluded list
				local function SaveString(self, userInput)
					local keytext = eb.Text:GetText()
					if keytext and keytext ~= "" then
						RGXQoLLC["MiniExcludeList"] = strtrim(eb.Text:GetText())
					else
						RGXQoLLC["MiniExcludeList"] = ""
					end
					if userInput then
						RGXQoLLC:ReloadCheck()
					end
				end

				-- Save the excluded list when it changes and at startup
				eb.Text:SetScript("OnTextChanged", SaveString)
				eb.Text:SetText(RGXQoLLC["MiniExcludeList"])
				SaveString()

				-- Add large editbox for available addons
				local titleAbTX = RGXQoLLC:MakeTx(ExcludedButtonsPanel, "Available button names", boxWidth + 20, -72)
				titleAbTX:SetWidth(boxWidth - 14)
				titleAbTX:SetWordWrap(false)
				titleAbTX:SetJustifyH("LEFT")

				-- Add help button
				RGXQoLLC:CreateHelpButton("MinimapButtonsAvailableHelpButton", ExcludedButtonsPanel, titleAbTX, "This is a list of available addon button names.  You can use this list to copy and paste button names that you want into the editor.|n|nThis listing is automatically generated and cannot be edited.")

				local ab = CreateFrame("Frame", nil, ExcludedButtonsPanel, "BackdropTemplate")
				ab:SetSize(boxWidth, RGXQoLLC.MainPanelHeight - 180) -- 548
				ab:SetPoint("TOPLEFT", 286, -92)
				ab:SetBackdrop({
					bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
					edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
					edgeSize = 16,
					insets = { left = 8, right = 6, top = 8, bottom = 8 },
				})
				ab:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)
				ab:SetBackdropColor(0, 0, 0, 0.5)

				ab.scroll = CreateFrame("ScrollFrame", nil, ab, "RGXQoLEnhanceMinimapExcludeButtonsScrollFrameTemplate")
				ab.scroll:SetPoint("TOPLEFT", ab, 12, -10)
				ab.scroll:SetPoint("BOTTOMRIGHT", ab, -30, 10)
				ab.scroll:SetPanExtent(16)

				-- Create character count
				ab.scroll.CharCount = ab.scroll:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
				ab.scroll.CharCount:Hide()

				ab.Text = ab.scroll.EditBox
				ab.Text:SetWidth(boxWidth - 54) -- 494
				ab.Text:SetHeight(230)
				ab.Text:SetPoint("TOPLEFT", ab.scroll)
				ab.Text:SetPoint("BOTTOMRIGHT", ab.scroll, -12, 0)
				ab.Text:SetMaxLetters(1200)
				ab.Text:SetFontObject(GameFontNormalLarge)
				ab.Text:SetAutoFocus(false)
				ab.scroll:SetScrollChild(ab.Text)

				-- Set focus on the editbox text when clicking the editbox
				ab:SetScript("OnMouseDown", function()
					ab.Text:SetFocus()
					ab.Text:SetCursorPosition(ab.Text:GetMaxLetters())
				end)

				-- Function to make string with list of buttons
				local function MakeAddonString()
					local msg = ""
					local numAddons = C_AddOns.GetNumAddOns()
					local buttons = LibDBIconStub:GetButtonList()
					table.sort(buttons)
					for i = 1, #buttons do
						local button = LibDBIconStub:GetMinimapButton(buttons[i])
						local buttonName = buttons[i]
						msg = msg .. buttonName .. ",|n|n"
					end
					if msg ~= "" then
					else
						msg = L["No supported addons."]
					end
					ab.Text:SetText(msg)
				end

				ab.Text:HookScript("OnShow", MakeAddonString)
				ab.Text:HookScript("OnTextChanged", function(self, userInput)
					if userInput then MakeAddonString() end
				end)

				-- Hide help button
				ExcludedButtonsPanel.h:Hide()

				-- Back button handler
				ExcludedButtonsPanel.b:SetScript("OnClick", function()
					ExcludedButtonsPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page5"]:Show()
					return
				end)

				-- Reset button handler
				ExcludedButtonsPanel.r:SetScript("OnClick", function()

					-- Reset controls
					RGXQoLLC["MiniExcludeList"] = ""
					eb.Text:SetText(RGXQoLLC["MiniExcludeList"])

					-- Refresh configuration panel
					ExcludedButtonsPanel:Hide(); ExcludedButtonsPanel:Show()
					RGXQoLLC:ReloadCheck()

				end)

				-- Show configuration panal when options panel button is clicked
				RGXQoLCB["MiniExcludedButton"]:SetScript("OnClick", function()
					if IsShiftKeyDown() and IsControlKeyDown() then
						-- Preset profile
						RGXQoLLC["MiniExcludeList"] = "BugSack, RGXQoL"
						RGXQoLLC:ReloadCheck()
					else
						ExcludedButtonsPanel:Show()
						LeaPlusGlobalPanel_SideMinimap:Hide()
					end
				end)

			end

			----------------------------------------------------------------------
			-- Minimap size
			----------------------------------------------------------------------

			if RGXQoLLC["SquareMinimap"] == "On" then

				-- Function to set minimap size
				local function SetMinimapSize()
					-- Set minimap size
					Minimap:SetSize(RGXQoLLC["MinimapSize"], RGXQoLLC["MinimapSize"])
					-- Refresh minimap
					if Minimap:GetZoom() ~= 5 then
						Minimap:SetZoom(Minimap:GetZoom() + 1)
						Minimap:SetZoom(Minimap:GetZoom() - 1)
					else
						Minimap:SetZoom(Minimap:GetZoom() - 1)
						Minimap:SetZoom(Minimap:GetZoom() + 1)
					end
					-- Refresh addon button radius
					SetButtonRad()
					-- Update slider text
					RGXQoLCB["MinimapSize"].f:SetFormattedText("%.0f%%", (RGXQoLLC["MinimapSize"] / 140) * 100)
				end

				-- Set minimap size when slider is changed and on startup
				RGXQoLCB["MinimapSize"]:HookScript("OnValueChanged", SetMinimapSize)
				SetMinimapSize()

				-- Assign file level scope (for reset and preset)
				RGXQoLLC.SetMinimapSize = SetMinimapSize

			else

				-- Square minimap is disabled so lock the size slider
				RGXQoLLC:LockItem(RGXQoLCB["MinimapSize"], true)
				RGXQoLCB["MinimapSize"].tiptext = RGXQoLCB["MinimapSize"].tiptext .. "|cff00AAFF|n|n" .. L["This slider requires 'Square minimap' to be enabled."] .. "|r"

			end

			----------------------------------------------------------------------
			-- Minimap button bag
			----------------------------------------------------------------------

			if RGXQoLLC["MinimapButtonBag"] == "On" then

				-- Lock out hide minimap buttons
				RGXQoLLC:LockItem(RGXQoLCB["HideMiniAddonButtons"], true)
				RGXQoLCB["HideMiniAddonButtons"].tiptext = RGXQoLCB["HideMiniAddonButtons"].tiptext .. "|n|n|cff00AAFF" .. L["Cannot be used with Minimap button bag."]

				-- Create button frame (parenting to cluster ensures bFrame scales correctly)
				local bFrame = CreateFrame("FRAME", nil, MinimapCluster, "BackdropTemplate")
				bFrame:ClearAllPoints()
				bFrame:SetPoint("TOPLEFT", Minimap, "TOPRIGHT", 4, 4)
				bFrame:Hide()
				bFrame:SetClampedToScreen(true)
				bFrame:SetFrameLevel(8)

				RGXQoLLC.bFrame = bFrame -- Used in LibDBIcon callback
				_G["LeaPlusGlobalMinimapCombinedButtonFrame"] = bFrame -- For third party addons

				-- Hide button frame automatically
				local ButtonFrameTicker
				bFrame:HookScript("OnShow", function()
					if ButtonFrameTicker then ButtonFrameTicker:Cancel() end
					ButtonFrameTicker = C_Timer.NewTicker(2, function()
						if ItemRackMenuFrame and ItemRackMenuFrame:IsShown() and ItemRackMenuFrame:IsMouseOver() then return end
						if not bFrame:IsMouseOver() and not Minimap:IsMouseOver() then
							bFrame:Hide()
							if ButtonFrameTicker then ButtonFrameTicker:Cancel() end
						end
					end, 15)
				end)

				-- Match scale with minimap
				if RGXQoLLC["SquareMinimap"] == "On" then
					bFrame:SetScale(MinimapCluster.BorderTop:GetScale() * 0.75)
				else
					bFrame:SetScale(MinimapCluster.BorderTop:GetScale())
				end

				-- Function to set button frame scale
				local function SetButtonFrameScale()
					if RGXQoLLC["SquareMinimap"] == "On" then
						bFrame:SetScale(MinimapCluster.BorderTop:GetScale() * 0.75)
					else
						bFrame:SetScale(MinimapCluster.BorderTop:GetScale())
					end
				end

				hooksecurefunc(MinimapCluster.BorderTop, "SetScale", SetButtonFrameScale)

				-- Position LibDBIcon tooltips when shown
				LibDBIconTooltip:HookScript("OnShow", function()
					GameTooltip:Hide()
					LibDBIconTooltip:ClearAllPoints()
					if bFrame:GetPoint() == "BOTTOMLEFT" then
						LibDBIconTooltip:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -6)
					else
						LibDBIconTooltip:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -6)
					end
				end)

				-- Function to position GameTooltip below the minimap
				local function SetButtonTooltip()
					GameTooltip:ClearAllPoints()
					if bFrame:GetPoint() == "BOTTOMLEFT" then
						GameTooltip:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -6)
					else
						GameTooltip:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -6)
					end
				end

				RGXQoLLC.SetButtonTooltip = SetButtonTooltip -- Used in LibDBIcon callback

				-- Hide existing LibDBIcon icons
				local buttons = LibDBIconStub:GetButtonList()
				for i = 1, #buttons do
					local button = LibDBIconStub:GetMinimapButton(buttons[i])
					local buttonName = strlower(buttons[i])
					if not strfind(strlower(RGXQoLDB["MiniExcludeList"]), buttonName) then
						button:Hide()
						button:SetScript("OnShow", function() if not bFrame:IsShown() then button:Hide() end end)
						-- Create background texture
						local bFrameBg = button:CreateTexture(nil, "BACKGROUND")
						bFrameBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
						bFrameBg:SetPoint("CENTER")
						bFrameBg:SetSize(30, 30)
						bFrameBg:SetVertexColor(0, 0, 0, 0.5)
					elseif strfind(strlower(RGXQoLDB["MiniExcludeList"]), buttonName) and RGXQoLLC["SquareMinimap"] == "On" then
						button:SetScale(0.75)
					end
					-- Move GameTooltip to below the minimap in case the button uses it
					button:HookScript("OnEnter", SetButtonTooltip)
					-- Special case for MoveAny because it doesn't have button.db
					if buttonName == "moveany" then
						button.db = button.db or {}
						if not button.db.hide then button.db.hide = false end
					end
				end

				-- Hide new LibDBIcon icons
				-- LibDBIcon_IconCreated: Done in LibDBIcon callback function

				-- Toggle button frame
				Minimap:SetScript("OnMouseUp", function(frame, button)
					if button == "RightButton" then
						if bFrame:IsShown() then
							bFrame:Hide()
						else bFrame:Show()
							-- Position button frame
							local side
							local m = Minimap:GetCenter()
							local b = Minimap:GetEffectiveScale()
							local w = GetScreenWidth()
							local s = UIParent:GetEffectiveScale()
							bFrame:ClearAllPoints()
							if m * b > (w * s / 2) then
								side = "Right"
								bFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMLEFT", -10, -0)
							else
								side = "Left"
								bFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMRIGHT", 10, 0)
							end
							-- Show button frame
							local x, y, row, col = 0, 0, 0, 0
							local buttons = LibDBIconStub:GetButtonList()
							-- Sort the button table
							table.sort(buttons, function(a, b)
								if string.find(a, "RGXQoLCustomIcon_") then
									a = string.gsub(a, "RGXQoLCustomIcon_", "")
								end
								if string.find(b, "RGXQoLCustomIcon_") then
									b = string.gsub(b, "RGXQoLCustomIcon_", "")
								end
								return a:lower() < b:lower()
							end)
							-- Calculate buttons per row
							local buttonsPerRow
							local totalButtons = #buttons
								if totalButtons > 36 then buttonsPerRow = 10
							elseif totalButtons > 32 then buttonsPerRow = 9
							elseif totalButtons > 28 then buttonsPerRow = 8
							elseif totalButtons > 24 then buttonsPerRow = 7
							elseif totalButtons > 20 then buttonsPerRow = 6
							elseif totalButtons > 16 then buttonsPerRow = 5
							elseif totalButtons > 12 then buttonsPerRow = 4
							elseif totalButtons > 8 then buttonsPerRow = 3
							elseif totalButtons > 4 then buttonsPerRow = 2
							else
								buttonsPerRow = 1
							end
							-- Build button grid
							for i = 1, totalButtons do
								local buttonName = strlower(buttons[i])
								if not strfind(strlower(RGXQoLDB["MiniExcludeList"]), buttonName) then
									local button = LibDBIconStub:GetMinimapButton(buttons[i])
									if button.db then
										if buttonName == "armory" then button.db.hide = false end -- Armory addon sets hidden to true
										if not button.db.hide then
											button:SetParent(bFrame)
											button:ClearAllPoints()
											if side == "Left" then
												-- Minimap is on left side of screen
												button:SetPoint("TOPLEFT", bFrame, "TOPLEFT", x, y)
												col = col + 1; if col >= buttonsPerRow then col = 0; row = row + 1; x = 0; y = y - 30 else x = x + 30 end
											else
												-- Minimap is on right side of screen (changed from TOPRIGHT to TOPLEFT and x - 30 to x + 30 to make sorting work)
												button:SetPoint("TOPLEFT", bFrame, "TOPLEFT", x, y)
												col = col + 1; if col >= buttonsPerRow then col = 0; row = row + 1; x = 0; y = y - 30 else x = x + 30 end
											end
											if totalButtons <= buttonsPerRow then
												bFrame:SetWidth(totalButtons * 30)
											else
												bFrame:SetWidth(buttonsPerRow * 30)
											end
											local void, void, void, void, e = button:GetPoint()
											bFrame:SetHeight(0 - e + 30)
											LibDBIconStub:Show(buttons[i])
										end
									end
								end
							end
						end
					else
						Minimap_OnClick(frame, button)
					end
				end)

			end

			----------------------------------------------------------------------
			-- Square minimap
			----------------------------------------------------------------------

			if RGXQoLLC["SquareMinimap"] == "On" then

				-- Set minimap shape
				_G.GetMinimapShape = function() return "SQUARE" end

				-- Create black border around map
				local miniBorder = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
				miniBorder:SetAlpha(0.8)

				-- Adjust border width using slider control
				local function SetMinimapBorderWidth()
					miniBorder:ClearAllPoints()
					miniBorder:SetPoint("TOPLEFT", -RGXQoLLC["MinimapBorderWidth"], RGXQoLLC["MinimapBorderWidth"])
					miniBorder:SetPoint("BOTTOMRIGHT", RGXQoLLC["MinimapBorderWidth"], -RGXQoLLC["MinimapBorderWidth"])
					miniBorder:SetBackdrop({
						edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
						edgeSize = RGXQoLLC["MinimapBorderWidth"],
					})
				end

				-- Set border width when slider is changed and on startup
				RGXQoLCB["MinimapBorderWidth"]:HookScript("OnValueChanged", SetMinimapBorderWidth)
				SetMinimapBorderWidth()

				-- Hide the default border
				MinimapBorder:Hide()

				-- Mask texture
				Minimap:SetMaskTexture('Interface\\ChatFrame\\ChatFrameBackground')

				-- Hide the North tag
				MinimapNorthTag:Hide()

				-- Tracking button (only visible when needed)
				C_Timer.After(0.1, function()
					MiniMapTracking:SetScale(0.60)
					miniFrame.ClearAllPoints(MiniMapTracking)
					MiniMapTracking:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -22, -24) -- SetLookingForGroupUIAvailable
					MiniMapTracking:SetParent(Minimap)
					MiniMapTracking:SetFrameLevel(4)
				end)

				-- Mail button
				MiniMapMailFrame:SetScale(0.75)
				miniFrame.ClearAllPoints(MiniMapMailFrame)
				MiniMapMailFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -19, -53)

				-- Battleground queue button
				MiniMapBattlefieldFrame:SetScale(0.75)
				miniFrame.ClearAllPoints(MiniMapBattlefieldFrame)
				MiniMapBattlefieldFrame:SetPoint("TOP", MiniMapMailFrame, "BOTTOM", 0, 0)

				-- Looking For Group button
				EventUtil.ContinueOnAddOnLoaded("Blizzard_GroupFinder_VanillaStyle", function()
					if LFGMinimapFrame then
						LFGMinimapFrame:SetScale(0.75)
						LFGMinimapFrame:ClearAllPoints()
						LFGMinimapFrame:SetPoint("TOP", MiniMapBattlefieldFrame, "BOTTOM", 0, 0)
					end
				end)

				-- Zoom in button
				MinimapZoomIn:SetScale(0.75)
				miniFrame.ClearAllPoints(MinimapZoomIn)
				MinimapZoomIn:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 19, -120)

				-- Zoom out button
				MinimapZoomOut:SetScale(0.75)
				miniFrame.ClearAllPoints(MinimapZoomOut)
				MinimapZoomOut:SetPoint("TOP", MinimapZoomIn, "BOTTOM", 0, 0)

				-- Day and night indicator
				miniFrame.ClearAllPoints(GameTimeFrame)
				GameTimeFrame:SetPoint("BOTTOM", MinimapZoomIn, "TOP", 0, 1)
				GameTimeFrame:SetParent(MinimapBackdrop)
				GameTimeFrame:SetSize(23, 23)

				-- Debug buttons
				local LeaPlusMiniMapDebug = nil
				if LeaPlusMiniMapDebug then
					C_Timer.After(1, function()
						MiniMapMailFrame:Show()
						MiniMapBattlefieldFrame:Show()
						GameTimeFrame:Show()
						if LFGMinimapFrame then
							LFGMinimapFrame:Show()
						end
						MiniMapTracking:Show()
					end)
				end

				-- Rescale addon buttons if minimap button bag is disabled
				if RGXQoLLC["MinimapButtonBag"] == "Off" then
					-- Scale existing buttons
					local buttons = LibDBIconStub:GetButtonList()
					for i = 1, #buttons do
						local button = LibDBIconStub:GetMinimapButton(buttons[i])
						button:SetScale(0.75)
					end
					-- Scale new buttons
					-- LibDBIcon_IconCreated: Done in LiBDBIcon callback function
				end

				-- Refresh buttons
				C_Timer.After(0.1, SetButtonRad)

			else

				-- Square minimap is disabled so use round shape
				_G.GetMinimapShape = function() return "ROUND" end
				Minimap:SetMaskTexture([[Interface\CharacterFrame\TempPortraitAlphaMask]])

				-- Square minimap is disabled so disable border width slider
				RGXQoLLC:LockItem(RGXQoLCB["MinimapBorderWidth"], true)
				RGXQoLCB["MinimapBorderWidth"].tiptext = RGXQoLCB["MinimapBorderWidth"].tiptext .. "|cff00AAFF|n|n" .. L["This slider requires 'Square minimap' to be enabled."] .. "|r"

			end

			----------------------------------------------------------------------
			-- Hide day and night indicator
			----------------------------------------------------------------------

			if RGXQoLLC["HideMiniDayNight"] == "On" then
				GameTimeFrame:Hide()
			end

			----------------------------------------------------------------------
			-- Replace non-standard buttons
			----------------------------------------------------------------------

			-- Replace non-standard buttons for addons that don't use the standard LibDBIcon library
			do

				-- Make LibDBIcon buttons for addons that don't use LibDBIcon
				local CustomAddonTable = {}
				RGXQoLDB["CustomAddonButtons"] = RGXQoLDB["CustomAddonButtons"] or {}

				-- Function to create a LibDBIcon button
				local function CreateBadButton(name)

					-- Get non-standard button texture
					local finalTex = "Interface\\HELPFRAME\\HelpIcon-KnowledgeBase"

					if _G[name .. "Icon"] then
						if _G[name .. "Icon"]:GetObjectType() == "Texture" then
							local gTex = _G[name .. "Icon"]:GetTexture()
							if gTex then
								finalTex = gTex
							end
						end
					else
						for i = 1, select('#', _G[name]:GetRegions()) do
							local region = select(i, _G[name]:GetRegions())
							if region.GetTexture then
								local x, y = region:GetSize()
								if x and x < 30 then
									finalTex = region:GetTexture()
								end
							end
						end
					end

					if not finalTex then finalTex = "Interface\\HELPFRAME\\HelpIcon-KnowledgeBase" end

					-- Function to anchor the tooltip to the custom button or the minimap
					local function ReanchorTooltip(tip, myButton)
						tip:ClearAllPoints()
						if RGXQoLLC["MinimapButtonBag"] == "On" then
							if RGXQoLLC.bFrame and RGXQoLLC.bFrame:GetPoint() == "BOTTOMLEFT" then
								tip:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -6)
							else
								tip:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -6)
							end
						else
							if Minimap:GetCenter() * Minimap:GetEffectiveScale() > (GetScreenWidth() * UIParent:GetEffectiveScale() / 2) then
								tip:SetPoint("TOPRIGHT", myButton, "BOTTOMRIGHT", 0, -6)
							else
								tip:SetPoint("TOPLEFT", myButton, "BOTTOMLEFT", 0, -6)
							end
						end
					end

					local zeroButton = LibStub("LibDataBroker-1.1"):NewDataObject("RGXQoLCustomIcon_" .. name, {
						type = "data source",
						text = name,
						icon = finalTex,
						OnClick = function(self, btn)
							if _G[name] then
								if string.find(name, "LibDBIcon") then
									-- It's a fake LibDBIcon
									local mouseUp = _G[name]:GetScript("OnMouseUp")
									if mouseUp then
										mouseUp(self, btn)
									end
								else
									-- It's a genuine LibDBIcon
									local clickUp = _G[name]:GetScript("OnClick")
									if clickUp then
										_G[name]:Click(btn)
									end
								end
							end
						end,
					})
					RGXQoLDB["CustomAddonButtons"][name] = RGXQoLDB["CustomAddonButtons"][name] or {}
					RGXQoLDB["CustomAddonButtons"][name].hide = false
					CustomAddonTable[name] = name
					local icon = LibStub("LibDBIcon-1.0", true)
					icon:Register("RGXQoLCustomIcon_" .. name, zeroButton, RGXQoLDB["CustomAddonButtons"][name])
					-- Custom buttons
					if name == "AllTheThings-Minimap" then
						-- AllTheThings
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("RGXQoLCustomIcon_" .. name)
						myButton.icon:SetTexture("Interface\\AddOns\\AllTheThings\\assets\\logo_tiny")
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							_G[name]:GetScript("OnLeave")()
						end)
					elseif name == "AltoholicMinimapButton" then
						-- Altoholic
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("RGXQoLCustomIcon_" .. name)
						myButton.icon:SetTexture("Interface\\Icons\\INV_Drink_13")
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							ReanchorTooltip(AltoTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							_G[name]:GetScript("OnLeave")()
						end)
					elseif name == "Narci_MinimapButton" then
						-- Narcissus
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("RGXQoLCustomIcon_" .. name)
						myButton.icon:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Minimap\\LOGO-Dragonflight")
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
						end)
						hooksecurefunc(myButton.icon, "UpdateCoord", function()
							myButton.icon:SetTexCoord(0, 0.25, 0.75, 1)
						end)
						myButton.icon:SetTexCoord(0, 0.25, 0.75, 1)
					elseif name == "WIM3MinimapButton" then
						-- WIM
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("RGXQoLCustomIcon_" .. name)
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							GameTooltip:SetOwner(myButton, "ANCHOR_TOP")
							GameTooltip:AddLine(name)
							GameTooltip:Show()
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							_G[name]:GetScript("OnLeave")()
							GameTooltip:Hide()
						end)
					elseif name == "ZygorGuidesViewerMapIcon" then
						-- Zygor (uses LibDBIcon10_RGXQoLCustomIcon_ZygorGuidesViewerMapIcon)
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("RGXQoLCustomIcon_" .. name)
						myButton.icon:SetTexture("Interface\\AddOns\\ZygorGuidesViewerClassic\\Skins\\minimap-icon.tga")
						hooksecurefunc(myButton.icon, "UpdateCoord", function()
							myButton.icon:SetTexCoord(0, 0.5, 0, 0.25)
						end)
						myButton.icon:SetTexCoord(0, 0.5, 0, 0.25)
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							GameTooltip:Hide()
						end)
						if ZGV_Notification_Entry_Template_Mixin then
							-- Fix notification system entry height
							hooksecurefunc(ZGV_Notification_Entry_Template_Mixin, "UpdateHeight", function(self)
								self:Show()
								local height = 46
								if ZGV and ZGV.db and ZGV.db.profile and ZGV.db.profile.nc_size and ZGV.db.profile.nc_size == 1 then height = 36 end
								height = height + (self.time:IsVisible() and self.time:GetStringHeight()+0 or 0)
								height = height + (self.title:IsVisible() and self.title:GetStringHeight()+3 or 0)
								height = height + (self.text:IsVisible() and self.text:GetStringHeight()+3 or 0)
								height = height + (self.SpecialButton and self.SpecialButton:IsVisible() and self.SpecialButton:GetHeight()+8 or 0)
								if (self.single or self.special) then height = max(height,25) end
								self:SetHeight(height)
								self:Hide()
							end)
						end
					elseif name == "TomCats-MinimapButton"				-- TomCat's Tours
						or name == "LibDBIcon10_MethodRaidTools"		-- Method Raid Tools
						or name == "Lib_GPI_Minimap_LFGBulletinBoard"	-- LFG Bulletin Board
						or name == "wlMinimapButton"					-- Wowhead Looter (part of Wowhead client)
						then
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("RGXQoLCustomIcon_" .. name)
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							GameTooltip:Hide()
						end)
					else
						-- Unknown custom buttons
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("RGXQoLCustomIcon_" .. name)
						myButton:HookScript("OnEnter", function()
							GameTooltip:SetOwner(myButton, "ANCHOR_TOP")
							GameTooltip:AddLine(name)
							GameTooltip:AddLine(L["This is a custom button.  Please ask the addon author to use the standard LibDBIcon library instead."], 1, 1, 1, true)
							GameTooltip:Show()
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							GameTooltip:Hide()
						end)
					end
				end

				-- Create LibDBIcon buttons for these addons that have LibDBIcon prefixes
				local customButtonTable = {
					"LibDBIcon10_MethodRaidTools", -- Method Raid Tools
				}

				-- Do not create LibDBIcon buttons for these special case buttons
				local BypassButtonTable = {
					"SexyMapZoneTextButton", -- SexyMap
				}

				-- Some buttons have less than 3 regions.  These need to be manually defined below.
				local LowRegionCountButtons = {
					"AllTheThings-Minimap", -- AllTheThings
				}

				-- Function to loop through minimap children to find non-standard addon buttons
				local function MakeButtons()
					local temp = {Minimap:GetChildren()}
					for i = 1, #temp do
						if temp[i] then
							local btn = temp[i]
							local name = btn:GetName()
							local btype = btn:GetObjectType()
							if name and btype == "Button" and not CustomAddonTable[name] and (btn:GetNumRegions() >= 3 or tContains(LowRegionCountButtons, name)) and not issecurevariable(name) and btn:IsShown() then
								if not strfind(strlower(RGXQoLDB["MiniExcludeList"]), strlower("##" .. name)) then
									if not string.find(name, "LibDBIcon") and not tContains(BypassButtonTable, name) or tContains(customButtonTable, name) then
										CreateBadButton(name)
										btn:Hide()
										btn:SetScript("OnShow", function() btn:Hide() end)
									end
								end
							end
						end
					end
				end

				-- Run the function a few times on startup
				C_Timer.NewTicker(2, MakeButtons, 8)
				C_Timer.After(0.1, MakeButtons)

			end

			----------------------------------------------------------------------
			-- Hide addon buttons
			----------------------------------------------------------------------

			if RGXQoLLC["MinimapButtonBag"] == "Off" then

				-- Function to set button state
				local function SetHideButtons()
					if RGXQoLLC["HideMiniAddonButtons"] == "On" then
						-- Hide existing buttons
						local buttons = LibDBIconStub:GetButtonList()
						for i = 1, #buttons do
							local buttonName = strlower(buttons[i])
							if not strfind(strlower(RGXQoLDB["MiniExcludeList"]), buttonName) then
								LibDBIconStub:ShowOnEnter(buttons[i], true)
							end
						end
						-- Hide new buttons
						-- LibDBIcon_IconCreated: Done in LibDBIcon callback function
					else
						-- Show existing buttons
						local buttons = LibDBIconStub:GetButtonList()
						for i = 1, #buttons do
							local buttonName = strlower(buttons[i])
							if not strfind(strlower(RGXQoLDB["MiniExcludeList"]), buttonName) then
								LibDBIconStub:ShowOnEnter(buttons[i], false)
							end
						end
						-- Show new buttons
						-- LibDBIcon_IconCreated: Done in LibDBIcon callback function
					end
				end

				-- Assign file level scope (it's used in reset and preset)
				RGXQoLLC.SetHideButtons = SetHideButtons

				-- Set buttons when option is clicked and on startup
				RGXQoLCB["HideMiniAddonButtons"]:HookScript("OnClick", SetHideButtons)
				SetHideButtons()

			end

			----------------------------------------------------------------------
			-- Unlock the minimap
			----------------------------------------------------------------------

			MinimapCluster:SetClampedToScreen(false)

			if RGXQoLLC["SquareMinimap"] == "On" then
				Minimap:SetClampRectInsets(-3, 3, 3, -3)
			else
				Minimap:SetClampRectInsets(-2, 0, 2, -2)
			end

			----------------------------------------------------------------------
			-- Hide the zone text bar and time of day button
			----------------------------------------------------------------------

			-- Hide zone text
			if RGXQoLDB["SquareMinimap"] == "On" then
				MinimapCluster.BorderTop:SetTexture("")
				MinimapToggleButton:SetNormalTexture(0)
				MinimapToggleButton:SetPushedTexture(0)
				MinimapToggleButton:SetHighlightTexture(0)
				MinimapToggleButton:EnableMouse(false)
				if RGXQoLLC["HideMiniZoneText"] == "On" then
					MinimapZoneTextButton:Hide()
				else
					MinimapZoneTextButton:ClearAllPoints()
					MinimapZoneTextButton:SetParent(Minimap)
					MinimapZoneTextButton:SetPoint("TOP", Minimap, "TOP", 0, -2)
					MinimapZoneTextButton:SetFrameLevel(100)
				end
			else
				if RGXQoLLC["HideMiniZoneText"] == "On" then
					MinimapCluster.BorderTop:SetTexture("")
					MinimapToggleButton:SetNormalTexture(0)
					MinimapToggleButton:SetPushedTexture(0)
					MinimapToggleButton:SetHighlightTexture(0)
					MinimapToggleButton:EnableMouse(false)
					MinimapZoneTextButton:Hide()
				end
			end

			----------------------------------------------------------------------
			-- Hide the zoom buttons
			----------------------------------------------------------------------

			-- Function to toggle the zoom buttons
			local function ToggleZoomButtons()
				if RGXQoLLC["HideMiniZoomBtns"] == "On" then
					MinimapZoomIn:Hide()
					MinimapZoomOut:Hide()
				else
					MinimapZoomIn:Show()
					MinimapZoomOut:Show()
				end
			end

			-- Set the zoom buttons when the option is clicked and on startup
			RGXQoLCB["HideMiniZoomBtns"]:HookScript("OnClick", ToggleZoomButtons)
			ToggleZoomButtons()

			----------------------------------------------------------------------
			-- Hide the clock
			----------------------------------------------------------------------

			-- Function to show or hide the clock
			EventUtil.ContinueOnAddOnLoaded("Blizzard_TimeManager",function()
				if RGXQoLLC["SquareMinimap"] == "On" then
					local regions = {TimeManagerClockButton:GetRegions()}
					regions[1]:Hide()
					TimeManagerClockButton:ClearAllPoints()
					TimeManagerClockButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -15, -8)
					TimeManagerClockButton:SetHitRectInsets(15, 10, 5, 8)
					TimeManagerClockButton:SetFrameLevel(100)
					local timeBG = TimeManagerClockButton:CreateTexture(nil, "BACKGROUND")
					timeBG:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
					timeBG:SetPoint("TOPLEFT", 15, -5)
					timeBG:SetPoint("BOTTOMRIGHT", -10, 8)
					timeBG:SetVertexColor(0, 0, 0, 0.6)
				end
				-- Hide clock (intentionally not using cvar)
				local function SetTimeClockButtonFunc()
					if RGXQoLLC["HideMiniClock"] == "On" then
						TimeManagerClockButton:Hide()
					else
						TimeManagerClockButton:Show()
					end
				end
				SetTimeClockButtonFunc()
				hooksecurefunc("TimeManagerClockButton_UpdateShowClockSetting", SetTimeClockButtonFunc)
			end)

			-- Function to toggle clock
			local function SetMiniClock()
				if RGXQoLLC["HideMiniClock"] == "On" then
					TimeManagerClockButton:Hide()
				else
					TimeManagerClockButton:Show()
				end
			end

			-- Update the clock when the checkbox is clicked
			RGXQoLCB["HideMiniClock"]:HookScript("OnClick", SetMiniClock)

			----------------------------------------------------------------------
			-- Enable mousewheel zoom
			----------------------------------------------------------------------

			-- Function to control mousewheel zoom
			local function MiniZoom(self, arg1)
				if arg1 > 0 and self:GetZoom() < 5 then
					-- Zoom in
					MinimapZoomOut:Enable()
					self:SetZoom(self:GetZoom() + 1)
					if(Minimap:GetZoom() == (Minimap:GetZoomLevels() - 1)) then
						MinimapZoomIn:Disable()
					end
				elseif arg1 < 0 and self:GetZoom() > 0 then
					-- Zoom out
					MinimapZoomIn:Enable()
					self:SetZoom(self:GetZoom() - 1)
					if(Minimap:GetZoom() == 0) then
						MinimapZoomOut:Disable()
					end
				end
			end

			-- Enable mousewheel zoom
			Minimap:EnableMouseWheel(true)
			Minimap:SetScript("OnMouseWheel", MiniZoom)

			----------------------------------------------------------------------
			-- Buttons
			----------------------------------------------------------------------

			-- Hide help button
			SideMinimap.h:Hide()

			-- Back button handler
			SideMinimap.b:SetScript("OnClick", function()
				SideMinimap:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			SideMinimap.r.tiptext = SideMinimap.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
			SideMinimap.r:HookScript("OnClick", function()
				RGXQoLLC["HideMiniZoomBtns"] = "Off"; ToggleZoomButtons()
				RGXQoLLC["HideMiniClock"] = "Off"; SetMiniClock()
				RGXQoLLC["HideMiniAddonButtons"] = "On"; if RGXQoLLC.SetHideButtons then RGXQoLLC.SetHideButtons() end
				RGXQoLLC["MinimapSize"] = 140; if RGXQoLLC.SetMinimapSize then RGXQoLLC:SetMinimapSize() end
				RGXQoLLC["MinimapBorderWidth"] = 3
				-- Refresh panel
				SideMinimap:Hide(); SideMinimap:Show()
			end)

			-- Configuration button handler
			RGXQoLCB["ModMinimapBtn"]:HookScript("OnClick", function()
				if RGXQoLLC:PlayerInCombat() then
					return
				else
					if IsShiftKeyDown() and IsControlKeyDown() then
						-- Preset profile
						RGXQoLLC["HideMiniZoomBtns"] = "Off"; ToggleZoomButtons()
						RGXQoLLC["HideMiniClock"] = "Off"; SetMiniClock()
						RGXQoLLC["HideMiniAddonButtons"] = "On"; if RGXQoLLC.SetHideButtons then RGXQoLLC.SetHideButtons() end
						RGXQoLLC["MinimapSize"] = 180; if RGXQoLLC.SetMinimapSize then RGXQoLLC:SetMinimapSize() end
						RGXQoLLC["MinimapBorderWidth"] = 3
						-- Map position
						RGXQoLLC:ReloadCheck() -- Special reload check
					else
						-- Show configuration panel
						SideMinimap:Show()
						RGXQoLLC:HideFrames()
					end
				end
			end)

			-- Hide the Looking for Group button (SoD and Anniversary realms)
			if RGXQoLLC["HideMiniLFG"] == "On" then

				EventUtil.ContinueOnAddOnLoaded("Blizzard_GroupFinder_VanillaStyle", function()

					local function SetLFGButton()
						if C_LFGList.HasActiveEntryInfo() then
							LFGMinimapFrame:Show()
						else
							LFGMinimapFrame:Hide()
						end
					end

					LFGMinimapFrame:HookScript("OnEvent", SetLFGButton)
					SetLFGButton()

				end)

			end

			-- Hide tracking button
			if RGXQoLLC["HideMiniTracking"] == "On" then

				-- Hide tracking button initially
				MiniMapTracking:SetAlpha(0)
				MiniMapTracking:Hide()

				-- Create tracking button fade out animation
				MiniMapTracking.fadeOut = MiniMapTracking:CreateAnimationGroup()
				local animOut = MiniMapTracking.fadeOut:CreateAnimation("Alpha")
				animOut:SetOrder(1)
				animOut:SetDuration(0.2)
				animOut:SetFromAlpha(1)
				animOut:SetToAlpha(0)
				animOut:SetStartDelay(1)
				MiniMapTracking.fadeOut:SetToFinalAlpha(true)

				-- Show tracking button when entering minimap
				Minimap:HookScript("OnEnter", function()
					MiniMapTracking.fadeOut:Stop()
					MiniMapTracking:SetAlpha(1)
				end)

				-- Hide tracking button when leaving minimap if pointer is not over tracking button
				Minimap:HookScript("OnLeave", function()
					if not MouseIsOver(MiniMapTracking) then
						MiniMapTracking.fadeOut:Play()
					end
				end)

				-- Hide tracking button when leaving tracking button
				MiniMapTracking:HookScript("OnLeave", function()
					MiniMapTracking.fadeOut:Play()
				end)

				-- Hook existing LibDBIcon buttons to include tracking button
				local buttons = LibDBIconStub:GetButtonList()
				for i = 1, #buttons do
					local button = LibDBIconStub:GetMinimapButton(buttons[i])
					if button then
						button:HookScript("OnEnter", function()
							MiniMapTracking.fadeOut:Stop()
							MiniMapTracking:SetAlpha(1)
						end)
						button:HookScript("OnLeave", function()
							MiniMapTracking.fadeOut:Play()
						end)
					end
				end

				-- Hook new LibDBIcon buttons to include tracking button
				-- LibDBIcon_IconCreated: Done in LibDBIcon callback function

				-- Show tracking button when button alpha is set to 1 if tracking is active
				hooksecurefunc(MiniMapTracking, "SetAlpha", function(self, alphavalue)
					if alphavalue and alphavalue == 1 then
						MiniMapTracking:Show()
					end
				end)

				-- Hide tracking button when fadeout animation has finished
				MiniMapTracking.fadeOut:HookScript("OnFinished", function()
					MiniMapTracking:Hide()
				end)

			end

			-- LibDBIcon callback (search LibDBIcon_IconCreated to find calls to this)
			LibDBIconStub.RegisterCallback(miniFrame, "LibDBIcon_IconCreated", function(self, button, name)

				-- Minimap button bag: Hide new LibDBIcon icons
				if RGXQoLLC["MinimapButtonBag"] == "On" then
					--C_Timer.After(0.1, function() -- Removed for now
						local buttonName = strlower(name)

						-- Special case for MoveAny because it doesn't have button.db
						if buttonName == "moveany" then
							button.db = button.db or {}
							if not button.db.hide then button.db.hide = false end
						end

						if not strfind(strlower(RGXQoLDB["MiniExcludeList"]), buttonName) then
							if button.db and not button.db.hide then
								button:Hide()
								button:SetScript("OnShow", function() if not RGXQoLLC.bFrame:IsShown() then button:Hide() end end)
							end
							-- Create background texture
							local bFrameBg = button:CreateTexture(nil, "BACKGROUND")
							bFrameBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
							bFrameBg:SetPoint("CENTER")
							bFrameBg:SetSize(30, 30)
							bFrameBg:SetVertexColor(0, 0, 0, 0.5)
						elseif strfind(strlower(RGXQoLDB["MiniExcludeList"]), buttonName) and RGXQoLLC["SquareMinimap"] == "On" then
							button:SetScale(0.75)
						end
						-- Move GameTooltip to below the minimap in case the button uses it
						button:HookScript("OnEnter", RGXQoLLC.SetButtonTooltip)
					--end)
				end

				-- Square minimap: Set scale of new LibDBIcon icons
				if RGXQoLLC["SquareMinimap"] == "On" and RGXQoLLC["MinimapButtonBag"] == "Off" then
					button:SetScale(0.75)
				end

				-- Hide addon buttons: Hide new LibDBIcon icons
				if RGXQoLLC["MinimapButtonBag"] == "Off" then
					local buttonName = strlower(name)
					if RGXQoLLC["HideMiniAddonButtons"] == "On" then
						-- Hide addon buttons is enabled
						if not strfind(strlower(RGXQoLDB["MiniExcludeList"]), buttonName) then
							LibDBIconStub:ShowOnEnter(name, true)
						end
					else
						-- Hide addon buttons is disabled
						if not strfind(strlower(RGXQoLDB["MiniExcludeList"]), buttonName) then
							LibDBIconStub:ShowOnEnter(name, false)
						end
					end
				end

				-- Hide tracking button
				if RGXQoLLC["HideMiniTracking"] == "On" then
					button:HookScript("OnEnter", function()
						-- Show tracking button when entering LibDBIcon button
						MiniMapTracking.fadeOut:Stop()
						MiniMapTracking:SetAlpha(1)
					end)
					button:HookScript("OnLeave", function()
						-- Hide tracking button when leaving LibDBIcon button
						MiniMapTracking.fadeOut:Play()
					end)
				end

			end)

		end

		----------------------------------------------------------------------
		-- Filter chat messages
		----------------------------------------------------------------------

		if RGXQoLLC["FilterChatMessages"] == "On" and not RGXQoLLockList["FilterChatMessages"] then

			-- Load LibChatAnims
			RGXQoLAddon:RGXQoLLCA()

			-- Create configuration panel
			local ChatFilterPanel = RGXQoLLC:CreatePanel("Filter chat messages", "ChatFilterPanel")

			RGXQoLLC:MakeTx(ChatFilterPanel, "Settings", 16, -72)
			RGXQoLLC:MakeCB(ChatFilterPanel, "BlockDrunkenSpam", "Block drunken spam", 16, -92, false, "If checked, drunken messages will be blocked unless they apply to your character.|n|nThis applies to the system channel.")
			RGXQoLLC:MakeCB(ChatFilterPanel, "BlockDuelSpam", "Block duel spam", 16, -112, false, "If checked, duel victory and retreat messages will be blocked unless your character took part in the duel.|n|nThis applies to the system channel.")

			-- Lock block drunken spam option for zhTW
			if GameLocale == "zhTW" then
				RGXQoLLC:LockItem(RGXQoLCB["BlockDrunkenSpam"], true)
				RGXQoLLC["BlockDrunkenSpam"] = "Off"
				RGXQoLDB["BlockDrunkenSpam"] = "Off"
				RGXQoLCB["BlockDrunkenSpam"].tiptext = RGXQoLCB["BlockDrunkenSpam"].tiptext .. "|n|n|cff00AAFF" .. L["Cannot use this with your locale."]
			end

			-- Help button hidden
			ChatFilterPanel.h:Hide()

			-- Back button handler
			ChatFilterPanel.b:SetScript("OnClick", function()
				ChatFilterPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page3"]:Show()
				return
			end)

			local charName = GetUnitName("player")
			local charRealm = GetNormalizedRealmName()
			local nameRealm = charName .. "%%-" .. charRealm

			-- Chat filter
			local function ChatFilterFunc(self, event, msg)
				-- Block duel spam
				if RGXQoLLC["BlockDuelSpam"] == "On" then
					-- Block duel messages unless you are part of the duel
					if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", "%.+"):gsub("%%2$s", "%.+")) or msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", "%.+"):gsub("%%2$s", "%.+")) then
						-- Player has defeated player in a duel.
						if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", charName):gsub("%%2$s", "%.+")) then return false end
						if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", nameRealm):gsub("%%2$s", "%.+")) then return false end
						if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", "%.+"):gsub("%%2$s", charName)) then return false end
						if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", "%.+"):gsub("%%2$s", nameRealm)) then return false end
						-- Player has fled from player in a duel.
						if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", charName):gsub("%%2$s", "%.+")) then return false end
						if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", nameRealm):gsub("%%2$s", "%.+")) then return false end
						if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", "%.+"):gsub("%%2$s", charName)) then return false end
						if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", "%.+"):gsub("%%2$s", nameRealm)) then return false end
						-- Block all duel messages not involving player
						return true
					end
				end
				-- Block drunken spam
				if RGXQoLLC["BlockDrunkenSpam"] == "On" then
					for i = 1, 4 do
						local drunk1 = _G["DRUNK_MESSAGE_ITEM_OTHER"..i]:gsub("%%s", "%s-")
						local drunk2 = _G["DRUNK_MESSAGE_OTHER"..i]:gsub("%%s", "%s-")
						if msg:match(drunk1) or msg:match(drunk2) then
							return true
						end
					end
				end
			end

			-- Enable or disable chat filter settings
			local function SetChatFilter()
				if RGXQoLLC["BlockDrunkenSpam"] == "On" or RGXQoLLC["BlockDuelSpam"] == "On" then
					ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilterFunc)
				else
					ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilterFunc)
				end
			end

			-- Set chat filter when settings are clicked and on startup
			RGXQoLCB["BlockDrunkenSpam"]:HookScript("OnClick", SetChatFilter)
			RGXQoLCB["BlockDuelSpam"]:HookScript("OnClick", SetChatFilter)
			SetChatFilter()

			-- Reset button handler
			ChatFilterPanel.r:SetScript("OnClick", function()

				-- Reset controls
				RGXQoLLC["BlockDrunkenSpam"] = "Off"
				RGXQoLLC["BlockDuelSpam"] = "Off"
				SetChatFilter()

				-- Refresh configuration panel
				ChatFilterPanel:Hide(); ChatFilterPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			RGXQoLCB["FilterChatMessagesBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["BlockDrunkenSpam"] = "On"
					RGXQoLLC["BlockDuelSpam"] = "On"
					SetChatFilter()
				else
					ChatFilterPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Automatically accept resurrection requests (no reload required)
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local AcceptResPanel = RGXQoLLC:CreatePanel("Accept resurrection", "AcceptResPanel")

			RGXQoLLC:MakeTx(AcceptResPanel, "Settings", 16, -72)
			RGXQoLLC:MakeCB(AcceptResPanel, "AutoResNoCombat", "Exclude combat resurrection", 16, -92, false, "If checked, resurrection requests will not be automatically accepted if the player resurrecting you is in combat.")

			-- Help button hidden
			AcceptResPanel.h:Hide()

			-- Back button handler
			AcceptResPanel.b:SetScript("OnClick", function()
				AcceptResPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			AcceptResPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				RGXQoLLC["AutoResNoCombat"] = "On"

				-- Refresh panel
				AcceptResPanel:Hide(); AcceptResPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			RGXQoLCB["AutoAcceptResBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["AutoResNoCombat"] = "On"
				else
					AcceptResPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

			-- Function to set resurrect event
			local function SetResEvent()
				if RGXQoLLC["AutoAcceptRes"] == "On" then
					AcceptResPanel:RegisterEvent("RESURRECT_REQUEST")
				else
					AcceptResPanel:UnregisterEvent("RESURRECT_REQUEST")
				end
			end

			-- Run function when option is clicked and on startup if option is enabled
			RGXQoLCB["AutoAcceptRes"]:HookScript("OnClick", SetResEvent)
			if RGXQoLLC["AutoAcceptRes"] == "On" then SetResEvent() end

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
		-- Hide keybind text
		----------------------------------------------------------------------

		if RGXQoLLC["HideKeybindText"] == "On" and not RGXQoLLockList["HideKeybindText"] then

			-- Hide bind text
			for i = 1, 12 do
				_G["ActionButton"..i.."HotKey"]:SetAlpha(0) -- Main bar
				_G["MultiBarBottomRightButton"..i.."HotKey"]:SetAlpha(0) -- Bottom right bar
				_G["MultiBarBottomLeftButton"..i.."HotKey"]:SetAlpha(0) -- Bottom left bar
				_G["MultiBarRightButton"..i.."HotKey"]:SetAlpha(0) -- Right bar
				_G["MultiBarLeftButton"..i.."HotKey"]:SetAlpha(0) -- Left bar
			end

		end

		----------------------------------------------------------------------
		-- Hide macro text
		----------------------------------------------------------------------

		if RGXQoLLC["HideMacroText"] == "On" and not RGXQoLLockList["HideMacroText"] then

			-- Hide marco text
			for i = 1, 12 do
				_G["ActionButton"..i.."Name"]:SetAlpha(0) -- Main bar
				_G["MultiBarBottomRightButton"..i.."Name"]:SetAlpha(0) -- Bottom right bar
				_G["MultiBarBottomLeftButton"..i.."Name"]:SetAlpha(0) -- Bottom left bar
				_G["MultiBarRightButton"..i.."Name"]:SetAlpha(0) -- Right bar
				_G["MultiBarLeftButton"..i.."Name"]:SetAlpha(0) -- Left bar
			end

		end

		----------------------------------------------------------------------
		-- More font sizes
		----------------------------------------------------------------------

		if RGXQoLLC["MoreFontSizes"] == "On" and not RGXQoLLockList["MoreFontSizes"] then
			RunScript('CHAT_FONT_HEIGHTS = {[1] = 10, [2] = 12, [3] = 14, [4] = 16, [5] = 18, [6] = 20, [7] = 22, [8] = 24, [9] = 26, [10] = 28}')
		end

		----------------------------------------------------------------------
		--	Show druid power bar
		----------------------------------------------------------------------

		if RGXQoLLC["ShowDruidPowerBar"] == "On" and not RGXQoLLockList["ShowDruidPowerBar"] then

			-- Create configuration panel
			local DruidBarPanel = RGXQoLLC:CreatePanel("Show druid power bar", "DruidBarPanel")

			-- Add checkboxes
			RGXQoLLC:MakeTx(DruidBarPanel, "Settings", 16, -72)
			RGXQoLLC:MakeCB(DruidBarPanel, "ShowDruidStatusText", "Show druid power bar status text", 16, -92, true, "If checked, status text will be shown in the druid power bar as long as status text is enabled in the game settings interface display panel.")

			-- Hide help button
			DruidBarPanel.h:Hide()

			-- Back button handler
			DruidBarPanel.b:SetScript("OnClick", function()
				DruidBarPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			DruidBarPanel.r.tiptext = DruidBarPanel.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
			DruidBarPanel.r:SetScript("OnClick", function()

				-- Refresh configuration panel
				DruidBarPanel:Hide(); DruidBarPanel:Show()

			end)

			-- Show configuration panel when options panel button is clicked
			RGXQoLCB["ShowDruidPowerBarBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
				else
					-- Show configuration panel
					DruidBarPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

			local void, class = UnitClass("player")
			if class == "DRUID" then

				-- Create druid power bar
				local ADDITIONAL_POWER_BAR_NAME = "MANA"
				local ADDITIONAL_POWER_BAR_INDEX = 0
				local ALT_MANA_BAR_PAIR_DISPLAY_INFO = {DRUID = {[Enum.PowerType.Rage] = true; [Enum.PowerType.Energy] = true}}

				-- Create local copies of Shadowlands functions (from Blizzard code AlternatePowerBar.lua)

				-- Line 13
				local function AlternatePowerBar_Initialize(self)
					if not (self.powerName and self.powerIndex) then
						self.powerName = ADDITIONAL_POWER_BAR_NAME
						self.powerIndex = ADDITIONAL_POWER_BAR_INDEX
					end

					local parent = self:GetParent()
					self:RegisterEvent("PLAYER_ENTERING_WORLD")
					self:RegisterUnitEvent("UNIT_DISPLAYPOWER", parent.unit)
					self:RegisterUnitEvent("UNIT_MAXPOWER", parent.unit)
					self:RegisterUnitEvent("UNIT_POWER_UPDATE", parent.unit)

					local color = PowerBarColor[self.powerName]
					self:SetStatusBarColor(color.r, color.g, color.b)
				end

				-- Line 66
				local function AlternatePowerBar_UpdateMaxValue(self)
					self:SetMinMaxValues(0, UnitPowerMax(self:GetParent().unit, self.powerIndex))
				end

				-- Line 60
				local function AlternatePowerBar_UpdateValue(self)
					self:SetValue(UnitPower(self:GetParent().unit, self.powerIndex))
				end

				-- Line 101
				local function AlternatePowerBar_UpdatePowerType(self)
					local unit = self:GetParent().unit
					local void, class = UnitClass(unit)
					local show = (UnitPowerMax(unit, self.powerIndex) > 0 and ALT_MANA_BAR_PAIR_DISPLAY_INFO[class] and ALT_MANA_BAR_PAIR_DISPLAY_INFO[class][UnitPowerType(unit)])

					self.pauseUpdates = not show
					if show then AlternatePowerBar_UpdateValue(self) end
					self:SetShown(show)
				end

				-- Line 4
				local function AlternatePowerBar_OnLoad(self)
					self.textLockable = 1
					self.cvar = "statusText"
					self.cvarLabel = "STATUS_TEXT_PLAYER"
					self.capNumericDisplay = true
					AlternatePowerBar_Initialize(self)
					self:InitializeTextStatusBar()
				end

				-- Line 32
				local function AlternatePowerBar_OnEvent(self, event, ...)
					if event == "PLAYER_ENTERING_WORLD" or event == "UNIT_MAXPOWER" then AlternatePowerBar_UpdateMaxValue(self) end
					if event == "PLAYER_ENTERING_WORLD" or event == "UNIT_DISPLAYPOWER" then AlternatePowerBar_UpdatePowerType(self) end
					if event == "UNIT_POWER_UPDATE" and self:IsShown() then AlternatePowerBar_UpdateValue(self) end
				end

				-- Line 55
				local function AlternatePowerBar_OnUpdate(self, elapsed)
					AlternatePowerBar_UpdateValue(self)
				end

				-- Create bar (uses Blizzard names from AlternatePowerBar.xml)
				local bar = CreateFrame("StatusBar", nil, PlayerFrame, "TextStatusBar")
				bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
				bar:SetStatusBarColor(0,0,1)
				bar:SetSize(104, 12)
				bar:SetPoint("BOTTOMLEFT", 98, 20)

				-- Show bar above player chain if it's enabled
				if RGXQoLLC["ShowPlayerChain"] == "On" then
					bar:SetFrameLevel(3)
				end

				bar.DefaultBackground = bar:CreateTexture(nil, "BACKGROUND")
				bar.DefaultBackground:SetColorTexture(0,0, 0, 0.5)
				bar.DefaultBackground:SetAllPoints(bar)

				-- Store yellow border colors for player chain
				local chainR, chainG, chainB = 0.86, 0.70, 0.12

				bar.DefaultBorder = bar:CreateTexture(nil, "OVERLAY")
				bar.DefaultBorder:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
				bar.DefaultBorder:SetTexCoord(0.125, 0.25, 1, 0)
				bar.DefaultBorder:SetHeight(16)
				bar.DefaultBorder:SetPoint("TOPLEFT", 4, 0)
				bar.DefaultBorder:SetPoint("TOPRIGHT", -4, 0)
				if RGXQoLLC["ShowPlayerChain"] == "On" then
					bar.DefaultBorder:SetVertexColor(chainR, chainG, chainB)
				end

				bar.DefaultBorderLeft = bar:CreateTexture(nil, "OVERLAY")
				bar.DefaultBorderLeft:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
				bar.DefaultBorderLeft:SetTexCoord(0, 0.125, 1, 0)
				bar.DefaultBorderLeft:SetSize(16, 16)
				bar.DefaultBorderLeft:SetPoint("TOPLEFT", -12, 0)
				if RGXQoLLC["ShowPlayerChain"] == "On" then
					bar.DefaultBorderLeft:SetVertexColor(chainR, chainG, chainB)
				end

				bar.DefaultBorderRight = bar:CreateTexture(nil, "OVERLAY")
				bar.DefaultBorderRight:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
				bar.DefaultBorderRight:SetTexCoord(0.125, 0, 1, 0)
				bar.DefaultBorderRight:SetSize(16, 16)
				bar.DefaultBorderRight:SetPoint("TOPRIGHT", 12, 0)
				if RGXQoLLC["ShowPlayerChain"] == "On" then
					bar.DefaultBorderRight:SetVertexColor(chainR, chainG, chainB)
				end

				if RGXQoLLC["ShowDruidStatusText"] == "On" then
					bar.TextString = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
					bar.TextString:SetPoint("CENTER")

					bar.LeftText = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
					bar.LeftText:SetPoint("LEFT")

					bar.RightText = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
					bar.RightText:SetPoint("RIGHT")
				end

				bar:SetScript("OnEvent", AlternatePowerBar_OnEvent)
				bar:SetScript("OnUpdate", AlternatePowerBar_OnUpdate)
				AlternatePowerBar_OnLoad(bar)

			end

		end

		----------------------------------------------------------------------
		--	Show vanity controls (must be before Enhance dressup)
		----------------------------------------------------------------------

		if RGXQoLLC["ShowVanityControls"] == "On" then

			-- Create checkboxes
			RGXQoLLC:MakeCB(PaperDollFrame, "ShowHelm", L["Helm"], 2, -192, false, "")
			RGXQoLLC:MakeCB(PaperDollFrame, "ShowCloak", L["Cloak"], 281, -192, false, "")
			RGXQoLCB["ShowHelm"]:SetFrameStrata("HIGH")
			RGXQoLCB["ShowCloak"]:SetFrameStrata("HIGH")

			-- Function to set vanity controls layout
			local function SetVanityControlsLayout()
				if RGXQoLLC["VanityAltLayout"] == "On" then
					-- Alternative layout
					RGXQoLCB["ShowHelm"].f:SetText(L["H"])
					RGXQoLCB["ShowHelm"]:ClearAllPoints()
					RGXQoLCB["ShowHelm"]:SetPoint("TOPLEFT", 275, -224)
					RGXQoLCB["ShowHelm"]:SetHitRectInsets(-RGXQoLCB["ShowHelm"].f:GetStringWidth() + 4, 3, 0, 0)
					RGXQoLCB["ShowHelm"].f:ClearAllPoints()
					RGXQoLCB["ShowHelm"].f:SetPoint("RIGHT", RGXQoLCB["ShowHelm"], "LEFT", 4, 0)

					RGXQoLCB["ShowCloak"].f:SetText(L["C"])
					RGXQoLCB["ShowCloak"]:ClearAllPoints()
					RGXQoLCB["ShowCloak"]:SetPoint("TOP", RGXQoLCB["ShowHelm"], "BOTTOM", 0, 6)
					RGXQoLCB["ShowCloak"].f:ClearAllPoints()
					RGXQoLCB["ShowCloak"].f:SetPoint("RIGHT", RGXQoLCB["ShowCloak"], "LEFT", 4, 0)
					RGXQoLCB["ShowCloak"]:SetHitRectInsets(-RGXQoLCB["ShowCloak"].f:GetStringWidth() + 4, 3, 0, 0)
				else
					-- Default layout
					RGXQoLCB["ShowHelm"].f:SetText(L["Helm"])
					RGXQoLCB["ShowHelm"]:ClearAllPoints()
					if C_AddOns.IsAddOnLoaded("CharacterStatsClassic") then
						RGXQoLCB["ShowHelm"]:SetPoint("TOPLEFT", 65, -258)
					else
						RGXQoLCB["ShowHelm"]:SetPoint("TOPLEFT", 65, -270)
					end
					RGXQoLCB["ShowHelm"]:SetHitRectInsets(3, -RGXQoLCB["ShowHelm"].f:GetStringWidth(), 0, 0)
					RGXQoLCB["ShowHelm"].f:ClearAllPoints()
					RGXQoLCB["ShowHelm"].f:SetPoint("LEFT", RGXQoLCB["ShowHelm"], "RIGHT", 0, 0)

					RGXQoLCB["ShowCloak"].f:SetText(L["Cloak"])
					RGXQoLCB["ShowCloak"]:ClearAllPoints()
					if C_AddOns.IsAddOnLoaded("CharacterStatsClassic") then
						RGXQoLCB["ShowCloak"]:SetPoint("TOPLEFT", 275, -258)
					else
						RGXQoLCB["ShowCloak"]:SetPoint("TOPLEFT", 275, -270)
					end
					RGXQoLCB["ShowCloak"]:SetHitRectInsets(-RGXQoLCB["ShowCloak"].f:GetStringWidth(), 3, 0, 0)
					RGXQoLCB["ShowCloak"].f:ClearAllPoints()
					RGXQoLCB["ShowCloak"].f:SetPoint("RIGHT", RGXQoLCB["ShowCloak"], "LEFT", 0, 0)
				end
			end

			-- Set position when controls are shift/right-clicked
			RGXQoLCB["ShowHelm"]:SetScript('OnMouseDown', function(self, btn)
				if btn == "RightButton" and IsShiftKeyDown() then
					if RGXQoLLC["VanityAltLayout"] == "On" then RGXQoLLC["VanityAltLayout"] = "Off" else RGXQoLLC["VanityAltLayout"] = "On" end
					SetVanityControlsLayout()
				end
			end)

			RGXQoLCB["ShowCloak"]:SetScript('OnMouseDown', function(self, btn)
				if btn == "RightButton" and IsShiftKeyDown() then
					if RGXQoLLC["VanityAltLayout"] == "On" then RGXQoLLC["VanityAltLayout"] = "Off" else RGXQoLLC["VanityAltLayout"] = "On" end
					SetVanityControlsLayout()
				end
			end)

			-- Set controls on startup
			SetVanityControlsLayout()

			-- Manage alpha
			RGXQoLCB["ShowHelm"]:SetAlpha(0.3)
			RGXQoLCB["ShowCloak"]:SetAlpha(0.3)
			RGXQoLCB["ShowHelm"]:HookScript("OnEnter", function() RGXQoLCB["ShowHelm"]:SetAlpha(1.0) end)
			RGXQoLCB["ShowHelm"]:HookScript("OnLeave", function() RGXQoLCB["ShowHelm"]:SetAlpha(0.3) end)
			RGXQoLCB["ShowCloak"]:HookScript("OnEnter", function()	RGXQoLCB["ShowCloak"]:SetAlpha(1.0) end)
			RGXQoLCB["ShowCloak"]:HookScript("OnLeave", function()	RGXQoLCB["ShowCloak"]:SetAlpha(0.3) end)

			-- Toggle helm with click
			RGXQoLCB["ShowHelm"]:HookScript("OnClick", function()
				RGXQoLCB["ShowHelm"]:Disable()
				RGXQoLCB["ShowHelm"]:SetAlpha(1.0)
				C_Timer.After(0.5, function()
					if ShowingHelm() then
						ShowHelm(false)
					else
						ShowHelm(true)
					end
					RGXQoLCB["ShowHelm"]:Enable()
					if not RGXQoLCB["ShowHelm"]:IsMouseOver() then
						RGXQoLCB["ShowHelm"]:SetAlpha(0.3)
					end
				end)
			end)

			-- Toggle cloak with click
			RGXQoLCB["ShowCloak"]:HookScript("OnClick", function()
				RGXQoLCB["ShowCloak"]:Disable()
				RGXQoLCB["ShowCloak"]:SetAlpha(1.0)
				C_Timer.After(0.5, function()
					if ShowingCloak() then
						ShowCloak(false)
					else
						ShowCloak(true)
					end
					RGXQoLCB["ShowCloak"]:Enable()
					if not RGXQoLCB["ShowCloak"]:IsMouseOver() then
						RGXQoLCB["ShowCloak"]:SetAlpha(0.3)
					end
				end)
			end)

			-- Set checkbox state when checkboxes are shown
			RGXQoLCB["ShowCloak"]:HookScript("OnShow", function()
				if ShowingHelm() then
					RGXQoLCB["ShowHelm"]:SetChecked(true)
				else
					RGXQoLCB["ShowHelm"]:SetChecked(false)
				end
				if ShowingCloak() then
					RGXQoLCB["ShowCloak"]:SetChecked(true)
				else
					RGXQoLCB["ShowCloak"]:SetChecked(false)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Enhance dressup
		----------------------------------------------------------------------

		if RGXQoLLC["EnhanceDressup"] == "On" then

			-- Create configuration panel
			local DressupPanel = RGXQoLLC:CreatePanel("Enhance dressup", "DressupPanel")

			RGXQoLLC:MakeTx(DressupPanel, "Settings", 16, -72)
			RGXQoLLC:MakeCB(DressupPanel, "DressupItemButtons", "Show item buttons", 16, -92, false, "If checked, item buttons will be shown in the dressing room.  You can click the item buttons to remove individual items from the model.")
			RGXQoLLC:MakeCB(DressupPanel, "DressupAnimControl", "Show animation slider", 16, -112, false, "If checked, an animation slider will be shown in the dressing room.")

			-- Help button hidden
			DressupPanel.h:Hide()

			-- Back button handler
			DressupPanel.b:SetScript("OnClick", function()
				DressupPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			DressupPanel.r:SetScript("OnClick", function()

				-- Refresh configuration panel
				DressupPanel:Hide(); DressupPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			RGXQoLCB["EnhanceDressupBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
				else
					DressupPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

			----------------------------------------------------------------------
			-- Item buttons
			----------------------------------------------------------------------

			do

				local buttons = {}
				local slotTable = {"HeadSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "MainHandSlot", "SecondaryHandSlot"}
				local texTable = {"INV_Misc_Desecrated_ClothHelm", "INV_Misc_Desecrated_ClothShoulder", "INV_Misc_Cape_01", "INV_Misc_Desecrated_ClothChest", "INV_Shirt_01", "INV_Shirt_GuildTabard_01", "INV_Misc_Desecrated_ClothBracer", "INV_Misc_Desecrated_ClothGlove", "INV_Misc_Desecrated_ClothBelt", "INV_Misc_Desecrated_ClothPants", "INV_Misc_Desecrated_ClothBoots", "INV_Sword_01", "INV_Shield_01"}

				local function MakeSlotButton(number, slot, anchor, x, y)

					-- Create slot button
					local slotBtn = CreateFrame("Button", nil, DressUpFrame)
					slotBtn:SetFrameStrata("HIGH")
					slotBtn:SetSize(30, 30)
					slotBtn.slot = slot
					slotBtn:ClearAllPoints()
					slotBtn:SetPoint(anchor, x, y)
					slotBtn:RegisterForClicks("LeftButtonUp")
					slotBtn:SetMotionScriptsWhileDisabled(true)

					-- Slot button click
					slotBtn:SetScript("OnClick", function(self, btn)
						if btn == "LeftButton" then
							local slotID = GetInventorySlotInfo(self.slot)
							DressUpFrame.DressUpModel:UndressSlot(slotID)
						end
					end)

					-- Slot button tooltip
					slotBtn:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						if self.item then
							GameTooltip:SetHyperlink(self.item)
						else
							if self.slot then
								GameTooltip:SetText(_G[string.upper(self.slot)])
							end
						end
					end)
					slotBtn:SetScript("OnLeave", GameTooltip_Hide)

					-- Slot button textures
					slotBtn.t = slotBtn:CreateTexture(nil, "BACKGROUND")
					slotBtn.t:SetSize(30, 30)
					slotBtn.t:SetPoint("CENTER")
					slotBtn.t:SetDesaturated(true)
					slotBtn.t:SetTexture("interface\\icons\\" .. texTable[number])

					slotBtn.h = slotBtn:CreateTexture()
					slotBtn.h:SetSize(30, 30)
					slotBtn.h:SetPoint("CENTER")
					slotBtn.h:SetAtlas("bags-glow-white")
					slotBtn.h:SetBlendMode("ADD")
					slotBtn:SetHighlightTexture(slotBtn.h)

					-- Add slot button to table
					tinsert(buttons, slotBtn)

				end

				-- Show left column slot buttons
				for i = 1, 7 do
					MakeSlotButton(i, slotTable[i], "TOPLEFT", 12, -68 + -35 * (i - 1))
				end

				-- Show right column slot buttons
				for i = 8, 13 do
					MakeSlotButton(i, slotTable[i], "TOPRIGHT", -14, -68 + -35 * (i - 8))
				end

				-- Function to set item buttons
				local function ToggleItemButtons()
					if RGXQoLLC["DressupItemButtons"] == "On" then
						for i = 1, #buttons do buttons[i]:Show() end
					else
						for i = 1, #buttons do buttons[i]:Hide() end
					end
				end
				RGXQoLLC.ToggleItemButtons = ToggleItemButtons

				-- Set item buttons for option click, startup, reset click and preset click
				RGXQoLCB["DressupItemButtons"]:HookScript("OnClick", ToggleItemButtons)
				ToggleItemButtons()
				DressupPanel.r:HookScript("OnClick", function()
					RGXQoLLC["DressupItemButtons"] = "On"
					ToggleItemButtons()
					DressupPanel:Hide(); DressupPanel:Show()
				end)
				RGXQoLCB["EnhanceDressupBtn"]:HookScript("OnClick", function()
					if IsShiftKeyDown() and IsControlKeyDown() then
						RGXQoLLC["DressupItemButtons"] = "On"
						ToggleItemButtons()
					end
				end)

			end

			----------------------------------------------------------------------
			-- Animation slider (must be before bottom row buttons)
			----------------------------------------------------------------------

			local animTable = {0, 4, 5, 143, 119, 26, 25, 27, 28, 108, 120, 51, 124, 52, 125, 126, 62, 63, 41, 42, 43, 44, 132, 38, 14, 115, 193, 48, 110, 109, 134, 197, 0}
			local lastSetting

			RGXQoLLC["DressupAnim"] = 0 -- Defined here since the setting is not saved
			RGXQoLLC:MakeSL(DressUpFrame, "DressupAnim", "", 1, #animTable - 1, 1, 356, -92, "%.0f")
			RGXQoLCB["DressupAnim"]:ClearAllPoints()
			RGXQoLCB["DressupAnim"]:SetPoint("BOTTOM", -12, 34)
			RGXQoLCB["DressupAnim"]:SetWidth(226)
			RGXQoLCB["DressupAnim"]:SetFrameLevel(5)
			RGXQoLCB["DressupAnim"]:HookScript("OnValueChanged", function(self, setting)
				local playerActor = DressUpFrame.DressUpModel
				setting = math.floor(setting + 0.5)
				if playerActor and setting ~= lastSetting then
					lastSetting = setting
					DressUpFrame.DressUpModel:SetAnimation(animTable[setting], 0, 1, 1)
					-- print(animTable[setting]) -- Debug
				end
			end)

			-- Function to show animation control
			local function SetAnimationSlider()
				if RGXQoLLC["DressupAnimControl"] == "On" then
					RGXQoLCB["DressupAnim"]:Show()
				else
					RGXQoLCB["DressupAnim"]:Hide()
				end
				RGXQoLCB["DressupAnim"]:SetValue(1)
			end

			-- Set animation control with option, startup, preset and reset
			RGXQoLCB["DressupAnimControl"]:HookScript("OnClick", SetAnimationSlider)
			SetAnimationSlider()
			RGXQoLCB["EnhanceDressupBtn"]:HookScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					RGXQoLLC["DressupAnimControl"] = "On"
					SetAnimationSlider()
				end
			end)
			DressupPanel.r:HookScript("OnClick", function()
				RGXQoLLC["DressupAnimControl"] = "On"
				SetAnimationSlider()
				DressupPanel:Hide(); DressupPanel:Show()
			end)

			-- Reset animation when dressup frame is shown and model is reset
			hooksecurefunc(DressUpFrame, "Show", SetAnimationSlider)
			DressUpFrameResetButton:HookScript("OnClick", SetAnimationSlider)

			-- Skin slider for ElvUI
			if RGXQoLLC.ElvUI then
				_G.LeaPlusGlobalDressupAnim = RGXQoLCB["DressupAnim"]
				RGXQoLLC.ElvUI:GetModule("Skins"):HandleSliderFrame(_G.LeaPlusGlobalDressupAnim, false)
			end

			----------------------------------------------------------------------
			-- Bottom row buttons
			----------------------------------------------------------------------

			-- Function to modify a button
			local function SetButton(where, text, tip)
				if text ~= "" then
					where:SetText(L[text])
					where:SetWidth(where:GetFontString():GetStringWidth() + 20)
				end
				where:HookScript("OnEnter", function()
					GameTooltip:SetOwner(where, "ANCHOR_NONE")
					GameTooltip:SetPoint("BOTTOM", where, "TOP", 0, 10)
					GameTooltip:SetText(L[tip], nil, nil, nil, nil, true)
				end)
				where:HookScript("OnLeave", GameTooltip_Hide)
			end

			-- Close
			SetButton(DressUpFrameCancelButton, "", "Close")
			DressUpFrameCancelButton:ClearAllPoints()
			DressUpFrameCancelButton:SetPoint("BOTTOMRIGHT", DressUpFrame, "BOTTOMRIGHT", -4, 4)

			-- Reset
			SetButton(DressUpFrameResetButton, "R", "Reset")

			-- Nude
			RGXQoLLC:CreateButton("DressUpNudeBtn", DressUpFrameResetButton, "N", "BOTTOMLEFT", 106, 79, 80, 22, false, "")
			RGXQoLCB["DressUpNudeBtn"]:SetFrameLevel(3)
			RGXQoLCB["DressUpNudeBtn"]:ClearAllPoints()
			RGXQoLCB["DressUpNudeBtn"]:SetPoint("RIGHT", DressUpFrameResetButton, "LEFT", 0, 0)
			SetButton(RGXQoLCB["DressUpNudeBtn"], "N", "Remove all items")
			RGXQoLCB["DressUpNudeBtn"]:SetScript("OnClick", function()
				DressUpFrame.DressUpModel:Undress()
			end)

			-- Show me
			RGXQoLLC:CreateButton("DressUpShowMeBtn", DressUpFrameResetButton, "M", "BOTTOMLEFT", 26, 79, 80, 22, false, "")
			RGXQoLCB["DressUpShowMeBtn"]:ClearAllPoints()
			RGXQoLCB["DressUpShowMeBtn"]:SetPoint("RIGHT", RGXQoLCB["DressUpNudeBtn"], "LEFT", 0, 0)
			SetButton(RGXQoLCB["DressUpShowMeBtn"], "M", "Show me")
			RGXQoLCB["DressUpShowMeBtn"]:SetScript("OnClick", function()
				local playerActor = DressUpFrame.DressUpModel
				playerActor:SetUnit("player")
				-- Set animation
				playerActor:SetAnimation(0)
				C_Timer.After(0.1,function()
					playerActor:SetAnimation(animTable[math.floor(RGXQoLCB["DressupAnim"]:GetValue() + 0.5)], 0, 1, 1)
				end)
			end)

			-- Show my outfit on target
			--[[RGXQoLLC:CreateButton("DressUpOutfitOnTargetBtn", DressUpFrameResetButton, "O", "BOTTOMLEFT", 26, 79, 80, 22, false, "")
			RGXQoLCB["DressUpOutfitOnTargetBtn"]:ClearAllPoints()
			RGXQoLCB["DressUpOutfitOnTargetBtn"]:SetPoint("RIGHT", RGXQoLCB["DressUpNudeBtn"], "LEFT", 0, 0)
			SetButton(RGXQoLCB["DressUpOutfitOnTargetBtn"], "O", "Show my outfit on target")
			RGXQoLCB["DressUpOutfitOnTargetBtn"]:SetScript("OnClick", function()
				if UnitIsPlayer("target") then
					DressUpFrame.DressUpModel:SetUnit("target")
					DressUpFrame.DressUpModel:Undress()
					C_Timer.After(0.01, function()
						for i = 1, 19 do
							local itemName = GetInventoryItemID("player", i)
							if itemName then
								DressUpFrame.DressUpModel:TryOn("item:" .. itemName)
							end
						end
					end)
				end
			end)]]

			-- Target
			RGXQoLLC:CreateButton("DressUpTargetBtn", DressUpFrameResetButton, "T", "BOTTOMLEFT", 26, 79, 80, 22, false, "")
			RGXQoLCB["DressUpTargetBtn"]:ClearAllPoints()
			RGXQoLCB["DressUpTargetBtn"]:SetPoint("RIGHT", RGXQoLCB["DressUpShowMeBtn"], "LEFT", 0, 0)
			SetButton(RGXQoLCB["DressUpTargetBtn"], "T", "Show target model")
			RGXQoLCB["DressUpTargetBtn"]:SetScript("OnClick", function()
				if UnitIsPlayer("target") then
					local playerActor = DressUpFrame.DressUpModel
					if playerActor then
						playerActor:SetUnit("target")
						-- Set animation
						playerActor:SetAnimation(0)
						C_Timer.After(0.1,function()
							playerActor:SetAnimation(animTable[math.floor(RGXQoLCB["DressupAnim"]:GetValue() + 0.5)], 0, 1, 1)
						end)
					end
				end
			end)

			-- Toggle buttons
			RGXQoLLC:CreateButton("DressUpButonsBtn", DressUpFrameResetButton, "B", "BOTTOMLEFT", 26, 79, 80, 22, false, "")
			RGXQoLCB["DressUpButonsBtn"]:ClearAllPoints()
			RGXQoLCB["DressUpButonsBtn"]:SetPoint("RIGHT", RGXQoLCB["DressUpTargetBtn"], "LEFT", 0, 0)
			SetButton(RGXQoLCB["DressUpButonsBtn"], "B", "Toggle buttons")
			RGXQoLCB["DressUpButonsBtn"]:SetScript("OnClick", function()
				if RGXQoLLC["DressupItemButtons"] == "On" then RGXQoLLC["DressupItemButtons"] = "Off" else RGXQoLLC["DressupItemButtons"] = "On" end
				RGXQoLLC:ToggleItemButtons()
				if DressupPanel:IsShown() then DressupPanel:Hide(); DressupPanel:Show() end
			end)

			-- Show nearby target outfit on me button
			--[[RGXQoLLC:CreateButton("DressUpTargetSelfBtn", DressUpFrameResetButton, "S", "BOTTOMLEFT", 26, 79, 80, 22, false, "")
			RGXQoLCB["DressUpTargetSelfBtn"]:ClearAllPoints()
			RGXQoLCB["DressUpTargetSelfBtn"]:SetPoint("RIGHT", RGXQoLCB["DressUpTargetBtn"], "LEFT", 0, 0)
			SetButton(RGXQoLCB["DressUpTargetSelfBtn"], "S", "Show nearby target outfit on me")
			RGXQoLCB["DressUpTargetSelfBtn"]:SetScript("OnClick", function()
				if UnitIsPlayer("target") then
					if not CanInspect("target") then
						ActionStatus_DisplayMessage(L["Target out of range."], true)
						return
					end
					NotifyInspect("target")
					RGXQoLCB["DressUpTargetSelfBtn"]:RegisterEvent("INSPECT_READY")
					RGXQoLCB["DressUpTargetSelfBtn"]:SetScript("OnEvent", function()
						DressUpFrame.DressUpModel:SetUnit("player")
						DressUpFrame.DressUpModel:Undress()
						C_Timer.After(0.01, function()
							for i = 1, 19 do
								local itemName = GetInventoryItemID("target", i)
								C_Timer.After(0.01, function()
									if itemName then
										DressUpFrame.DressUpModel:TryOn("item:" .. itemName)
									end
								end)
							end
						end)
						RGXQoLCB["DressUpTargetSelfBtn"]:UnregisterEvent("INSPECT_READY")
					end)
				end
			end)]]

			-- Change player actor to player when reset button is clicked (needed because target button changes it)
			DressUpFrameResetButton:HookScript("OnClick", function()
				DressUpFrame.DressUpModel:SetUnit("player")
			end)

			-- Auction house
			local BtnStrata, BtnLevel = SideDressUpModelResetButton:GetFrameStrata(), SideDressUpModelResetButton:GetFrameLevel()

			-- Add buttons to auction house dressup frame
			RGXQoLLC:CreateButton("DressUpSideBtn", SideDressUpModelResetButton, "Tabard", "BOTTOMLEFT", -36, -31, 60, 22, false, "")
			RGXQoLCB["DressUpSideBtn"]:SetFrameStrata(BtnStrata)
			RGXQoLCB["DressUpSideBtn"]:SetFrameLevel(BtnLevel)
			RGXQoLCB["DressUpSideBtn"]:SetScript("OnClick", function()
				SideDressUpModel:UndressSlot(19)
			end)

			RGXQoLLC:CreateButton("DressUpSideNudeBtn", SideDressUpModelResetButton, "Nude", "BOTTOMRIGHT", 39, -31, 60, 22, false, "")
			RGXQoLCB["DressUpSideNudeBtn"]:SetFrameStrata(BtnStrata)
			RGXQoLCB["DressUpSideNudeBtn"]:SetFrameLevel(BtnLevel)
			RGXQoLCB["DressUpSideNudeBtn"]:SetScript("OnClick", function()
				SideDressUpModel:Undress()
			end)

			-- Skin buttons for ElvUI
			if RGXQoLLC.ElvUI then
				_G.LeaPlusGlobalDressUpButtonsButton = RGXQoLCB["DressUpButonsBtn"]
				RGXQoLLC.ElvUI:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalDressUpButtonsButton)

				_G.LeaPlusGlobalDressUpShowMeButton = RGXQoLCB["DressUpShowMeBtn"]
				RGXQoLLC.ElvUI:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalDressUpShowMeButton)

				_G.LeaPlusGlobalDressUpTargetButton = RGXQoLCB["DressUpTargetBtn"]
				RGXQoLLC.ElvUI:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalDressUpTargetButton)

				_G.LeaPlusGlobalDressUpNudeButton = RGXQoLCB["DressUpNudeBtn"]
				RGXQoLLC.ElvUI:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalDressUpNudeButton)
			end

			----------------------------------------------------------------------
			-- Controls
			----------------------------------------------------------------------

			-- Hide model rotation controls
			CharacterModelFrameRotateLeftButton:HookScript("OnShow", CharacterModelFrameRotateLeftButton.Hide)
			CharacterModelFrameRotateRightButton:HookScript("OnShow", CharacterModelFrameRotateRightButton.Hide)
			DressUpModelFrameRotateLeftButton:HookScript("OnShow", DressUpModelFrameRotateLeftButton.Hide)
			DressUpModelFrameRotateRightButton:HookScript("OnShow", DressUpModelFrameRotateRightButton.Hide)
			SideDressUpModelControlFrame:HookScript("OnShow", SideDressUpModelControlFrame.Hide)

			----------------------------------------------------------------------
			-- Toggle character attributes (supports CharacterStatsClassic)
			----------------------------------------------------------------------

			local function ToggleStats()
				if RGXQoLLC["HideDressupStats"] == "On" then
					CharacterResistanceFrame:Hide()
					if CSC_HideStatsPanel then
						-- CharacterStatsClassic is installed
						RunScript('CSC_HideStatsPanel()')
					else
						-- CharacterStatsClassic is not installed
						CharacterAttributesFrame:Hide()
					end
					CharacterModelFrame:ClearAllPoints()
					CharacterModelFrame:SetPoint("TOPLEFT", PaperDollFrame, 66, -76)
					CharacterModelFrame:SetPoint("BOTTOMRIGHT", PaperDollFrame, -86, 134)
					if RGXQoLLC["ShowVanityControls"] == "On" then
						RGXQoLCB["ShowHelm"]:Hide()
						RGXQoLCB["ShowCloak"]:Hide()
					end
				else
					CharacterResistanceFrame:Show()
					if CSC_ShowStatsPanel then
						-- CharacterStatsClassic is installed
						RunScript('CSC_ShowStatsPanel()')
					else
						-- CharacterStatsClassic is not installed
						CharacterAttributesFrame:Show()
					end
					CharacterModelFrame:ClearAllPoints()
					CharacterModelFrame:SetPoint("TOPLEFT", PaperDollFrame, 66, -76)
					CharacterModelFrame:SetPoint("BOTTOMRIGHT", PaperDollFrame, -86, 220)
					if RGXQoLLC["ShowVanityControls"] == "On" then
						RGXQoLCB["ShowHelm"]:Show()
						RGXQoLCB["ShowCloak"]:Show()
					end
				end
			end

			-- Toggle stats with middle mouse button
			CharacterModelFrame:HookScript("OnMouseDown", function(self, btn)
				if btn == "MiddleButton" then
					if RGXQoLLC["HideDressupStats"] == "On" then RGXQoLLC["HideDressupStats"] = "Off" else RGXQoLLC["HideDressupStats"] = "On" end
					ToggleStats()
				end
			end)
			ToggleStats()

			-- Create toggle stats button
			local toggleButton = CreateFrame("Button", nil, PaperDollFrame)
			toggleButton:SetSize(36, 36)
			toggleButton:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 64, -45)
			toggleButton:SetNormalTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-RotationRight-Big-Up")
			toggleButton:SetHighlightTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-RotationRight-Big-Up")
			toggleButton:SetPushedTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-RotationRight-Big-Up")
			toggleButton:SetScript("OnEnter", function()
				GameTooltip:SetOwner(toggleButton, "ANCHOR_NONE")
				GameTooltip:SetPoint("BOTTOMLEFT", toggleButton, "BOTTOMRIGHT", 0, 0)
				GameTooltip:SetText(L["Toggle character stats"], nil, nil, nil, nil, true)
				GameTooltip:Show()
			end)
			toggleButton:SetScript("OnLeave", GameTooltip_Hide)
			toggleButton:SetScript("OnClick", function()
				if RGXQoLLC["HideDressupStats"] == "On" then RGXQoLLC["HideDressupStats"] = "Off" else RGXQoLLC["HideDressupStats"] = "On" end
				ToggleStats()
			end)

			----------------------------------------------------------------------
			-- Enable zooming and panning
			----------------------------------------------------------------------

			-- Enable zooming for character frame and dressup frame
			CharacterModelFrame:EnableMouseWheel(true)
			CharacterModelFrame:HookScript("OnMouseWheel", Model_OnMouseWheel)
			DressUpModelFrame:EnableMouseWheel(true)
			DressUpModelFrame:HookScript("OnMouseWheel", Model_OnMouseWheel)

			-- Enable panning for character frame
			CharacterModelFrame:HookScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then
					Model_StartPanning(self)
				end
			end)

			CharacterModelFrame:HookScript("OnMouseUp", function(self, btn)
				Model_StopPanning(self)
			end)

			-- Enable panning for dressup frame
			DressUpModelFrame:HookScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then
					Model_StartPanning(self)
				end
			end)

			DressUpModelFrame:HookScript("OnMouseUp", function(self, btn)
				Model_StopPanning(self)
			end)

			DressUpModelFrame:ClearAllPoints()
			DressUpModelFrame:SetPoint("TOPLEFT", DressUpFrame, 8, -64)
			DressUpModelFrame:SetPoint("BOTTOMRIGHT", DressUpFrame, -8, 30)

			-- Reset dressup frame when reset button clicked
			DressUpFrameResetButton:HookScript("OnClick", function()
				DressUpModelFrame.rotation = 0
				DressUpModelFrame:SetRotation(0)
				DressUpModelFrame:SetPosition(0, 0, 0)
				DressUpModelFrame.zoomLevel = 0
				DressUpModelFrame:SetPortraitZoom(0)
				DressUpModelFrame:RefreshCamera()
			end)

			-- Reset side dressup when reset button clicked
			SideDressUpModelResetButton:HookScript("OnClick", function()
				SideDressUpModel.rotation = 0
				SideDressUpModel:SetRotation(0)
				SideDressUpModel:SetPosition(0, 0, 0)
				SideDressUpModel.zoomLevel = 0
				SideDressUpModel:SetPortraitZoom(0)
				SideDressUpModel:RefreshCamera()
			end)

			----------------------------------------------------------------------
			-- Inspect system
			----------------------------------------------------------------------

			-- Inspect System
			EventUtil.ContinueOnAddOnLoaded("Blizzard_InspectUI",function()

				-- Hide model rotation controls
				InspectModelFrameRotateLeftButton:Hide()
				InspectModelFrameRotateRightButton:Hide()

				-- Enable zooming
				InspectModelFrame:EnableMouseWheel(true)
				InspectModelFrame:HookScript("OnMouseWheel", Model_OnMouseWheel)

				-- Enable panning
				InspectModelFrame:HookScript("OnMouseDown", function(self, btn)
					if btn == "RightButton" then
						Model_StartPanning(self)
					end
				end)

				InspectModelFrame:HookScript("OnMouseUp", function(self, btn)
					Model_StopPanning(self)
				end)

			end)

		end

		----------------------------------------------------------------------
		-- Automatically release in battlegrounds
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local ReleasePanel = RGXQoLLC:CreatePanel("Release in PvP", "ReleasePanel")

			RGXQoLLC:MakeTx(ReleasePanel, "Settings", 16, -72)
			RGXQoLLC:MakeCB(ReleasePanel, "AutoReleaseNoAlterac", "Exclude Alterac Valley", 16, -92, false, "If checked, you will not release automatically in Alterac Valley.")

			RGXQoLLC:MakeTx(ReleasePanel, "Delay", 356, -72)
			RGXQoLLC:MakeSL(ReleasePanel, "AutoReleaseDelay", "Drag to set the number of milliseconds before you are automatically released.|n|nYou can hold down shift as the timer is ending to cancel the automatic release.", 200, 3000, 100, 356, -92, "%.0f")

			-- Help button hidden
			ReleasePanel.h:Hide()

			-- Back button handler
			ReleasePanel.b:SetScript("OnClick", function()
				ReleasePanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			ReleasePanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				RGXQoLLC["AutoReleaseNoAlterac"] = "Off"
				RGXQoLLC["AutoReleaseDelay"] = 200

				-- Refresh panel
				ReleasePanel:Hide(); ReleasePanel:Show()

			end)

			-- Show panal when options panel button is clicked
			RGXQoLCB["AutoReleasePvPBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["AutoReleaseNoAlterac"] = "Off"
					RGXQoLLC["AutoReleaseDelay"] = 200
				else
					ReleasePanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

			-- Release in battlegrounds
			hooksecurefunc("StaticPopup_Show", function(sType)
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
		--	Enhance trainers
		----------------------------------------------------------------------

		if RGXQoLLC["EnhanceTrainers"] == "On" then

			-- Create configuration panel
			local TrainerPanel = RGXQoLLC:CreatePanel("Enhance trainers", "TrainerPanel")

			RGXQoLLC:MakeTx(TrainerPanel, "Settings", 16, -72)
			RGXQoLLC:MakeCB(TrainerPanel, "ShowTrainAllBtn", "Show train all skills button", 16, -92, false, "If checked, a train all skills button will be shown in the skill trainer frame allowing you to train all available skills instantly.")

			-- Help button hidden
			TrainerPanel.h:Hide()

			-- Back button handler
			TrainerPanel.b:SetScript("OnClick", function()
				TrainerPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			TrainerPanel.r:SetScript("OnClick", function()

				-- Reset controls
				RGXQoLLC["ShowTrainAllBtn"] = "On"

				-- Refresh configuration panel
				TrainerPanel:Hide(); TrainerPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			RGXQoLCB["EnhanceTrainersBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["ShowTrainAllBtn"] = "On"
				else
					TrainerPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

			-- Set increased height of skill trainer frame and maximum number of skills listed
			local tall, numTallTrainers = 73, 17

			----------------------------------------------------------------------
			--	Skill trainer frame
			----------------------------------------------------------------------

			EventUtil.ContinueOnAddOnLoaded("Blizzard_TrainerUI",function()

				-- Make the frame double-wide
				UIPanelWindows["ClassTrainerFrame"] = {area = "override", pushable = 0, xoffset = -16, yoffset = 12, bottomClampOverride = 140 + 12, width = 685, height = 487, whileDead = 1}

				-- Size the frame
				_G["ClassTrainerFrame"]:SetSize(714, 487 + tall)

				-- Lower title text slightly
				_G["ClassTrainerNameText"]:ClearAllPoints()
				_G["ClassTrainerNameText"]:SetPoint("TOP", _G["ClassTrainerFrame"], "TOP", 0, -18)

				-- Expand the skill list to full height
				_G["ClassTrainerListScrollFrame"]:ClearAllPoints()
				_G["ClassTrainerListScrollFrame"]:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 25, -75)
				_G["ClassTrainerListScrollFrame"]:SetSize(295, 336 + tall)

				-- Create additional list rows
				do

					local oldSkillsDisplayed = CLASS_TRAINER_SKILLS_DISPLAYED

					-- Position existing buttons
					for i = 1 + 1, CLASS_TRAINER_SKILLS_DISPLAYED do
						_G["ClassTrainerSkill" .. i]:ClearAllPoints()
						_G["ClassTrainerSkill" .. i]:SetPoint("TOPLEFT", _G["ClassTrainerSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
					end

					-- Create and position new buttons
					_G.CLASS_TRAINER_SKILLS_DISPLAYED = _G.CLASS_TRAINER_SKILLS_DISPLAYED + numTallTrainers
					for i = oldSkillsDisplayed + 1, CLASS_TRAINER_SKILLS_DISPLAYED do
						local button = CreateFrame("Button", "ClassTrainerSkill" .. i, ClassTrainerFrame, "ClassTrainerSkillButtonTemplate")
						button:SetID(i)
						button:Hide()
						button:ClearAllPoints()
						button:SetPoint("TOPLEFT", _G["ClassTrainerSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
					end

					hooksecurefunc("ClassTrainer_SetToTradeSkillTrainer", function()
						_G.CLASS_TRAINER_SKILLS_DISPLAYED = _G.CLASS_TRAINER_SKILLS_DISPLAYED + numTallTrainers
						ClassTrainerListScrollFrame:SetHeight(336 + tall)
						ClassTrainerDetailScrollFrame:SetHeight(336 + tall)
					end)

					hooksecurefunc("ClassTrainer_SetToClassTrainer", function()
						_G.CLASS_TRAINER_SKILLS_DISPLAYED = _G.CLASS_TRAINER_SKILLS_DISPLAYED + numTallTrainers - 1
						ClassTrainerListScrollFrame:SetHeight(336 + tall)
						ClassTrainerDetailScrollFrame:SetHeight(336 + tall)
					end)

				end

				-- Set highlight bar width when shown
				hooksecurefunc(_G["ClassTrainerSkillHighlightFrame"], "Show", function()
					ClassTrainerSkillHighlightFrame:SetWidth(290)
				end)

				-- Move the detail frame to the right and stretch it to full height
				_G["ClassTrainerDetailScrollFrame"]:ClearAllPoints()
				_G["ClassTrainerDetailScrollFrame"]:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 352, -74)
				_G["ClassTrainerDetailScrollFrame"]:SetSize(296, 336 + tall)
				-- _G["ClassTrainerSkillIcon"]:SetHeight(500) -- Debug

				-- Hide detail scroll frame textures
				_G["ClassTrainerDetailScrollFrameTop"]:SetAlpha(0)
				_G["ClassTrainerDetailScrollFrameBottom"]:SetAlpha(0)

				-- Hide expand tab (left of All button)
				_G["ClassTrainerExpandTabLeft"]:Hide()

				-- Get frame textures
				local regions = {_G["ClassTrainerFrame"]:GetRegions()}

				-- Set top left texture
				regions[2]:SetSize(512, 512)
				regions[2]:SetTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus")
				regions[2]:SetTexCoord(0.25, 0.75, 0, 0.5)

				-- Set top right texture
				regions[3]:ClearAllPoints()
				regions[3]:SetPoint("TOPLEFT", regions[2], "TOPRIGHT", 0, 0)
				regions[3]:SetSize(256, 512)
				regions[3]:SetTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus")
				regions[3]:SetTexCoord(0.75, 1, 0, 0.5)

				-- Hide bottom left and bottom right textures
				regions[4]:Hide()
				regions[5]:Hide()

				-- Hide skills list dividing bar
				regions[9]:Hide()
				ClassTrainerHorizontalBarLeft:Hide()

				-- Set skills list backdrop
				local RecipeInset = _G["ClassTrainerFrame"]:CreateTexture(nil, "ARTWORK")
				RecipeInset:SetSize(304, 361 + tall)
				RecipeInset:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 16, -72)
				RecipeInset:SetTexture("Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg")

				-- Set detail frame backdrop
				local DetailsInset = _G["ClassTrainerFrame"]:CreateTexture(nil, "ARTWORK")
				DetailsInset:SetSize(302, 339 + tall)
				DetailsInset:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 348, -72)
				DetailsInset:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated")

				-- Move bottom button row
				_G["ClassTrainerTrainButton"]:ClearAllPoints()
				_G["ClassTrainerTrainButton"]:SetPoint("RIGHT", _G["ClassTrainerCancelButton"], "LEFT", -1, 0)

				-- Position and size close button
				_G["ClassTrainerCancelButton"]:SetSize(80, 22)
				_G["ClassTrainerCancelButton"]:SetText(CLOSE)
				_G["ClassTrainerCancelButton"]:ClearAllPoints()
				_G["ClassTrainerCancelButton"]:SetPoint("BOTTOMRIGHT", _G["ClassTrainerFrame"], "BOTTOMRIGHT", -42, 54)

				-- Position close box
				_G["ClassTrainerFrameCloseButton"]:ClearAllPoints()
				_G["ClassTrainerFrameCloseButton"]:SetPoint("TOPRIGHT", _G["ClassTrainerFrame"], "TOPRIGHT", -30, -8)

				-- Position dropdown menus
				ClassTrainerFrame.FilterDropdown:ClearAllPoints()
				ClassTrainerFrame.FilterDropdown:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPLEFT", 576, -44)

				-- Position money frame
				ClassTrainerMoneyFrame:ClearAllPoints()
				ClassTrainerMoneyFrame:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 143, -49)
				ClassTrainerGreetingText:Hide()

				----------------------------------------------------------------------
				--	Train All button
				----------------------------------------------------------------------

				-- Create train all button
				RGXQoLLC:CreateButton("TrainAllButton", ClassTrainerFrame, "Train All", "BOTTOMLEFT", 344, 54, 0, 22, false, "")

				-- Give button global scope (useful for compatibility with other addons and essential for ElvUI)
				_G.LeaPlusGlobalTrainAllButton = RGXQoLCB["TrainAllButton"]

				-- Button tooltip
				RGXQoLCB["TrainAllButton"]:SetScript("OnEnter", function(self)
					-- Get number of available skills and total cost
					local count, cost = 0, 0
					for i = 1, GetNumTrainerServices() do
						local void, void, isAvail = GetTrainerServiceInfo(i)
						if isAvail and isAvail == "available" then
							count = count + 1
							cost = cost + GetTrainerServiceCost(i)
						end
					end
					-- Show tooltip
					if count > 0 then
						GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 4)
						GameTooltip:ClearLines()
						if count > 1 then
							GameTooltip:AddLine(L["Train"] .. " " .. count .. " " .. L["skills for"] .. " " .. GetCoinTextureString(cost))
						else
							GameTooltip:AddLine(L["Train"] .. " " .. count .. " " .. L["skill for"] .. " " .. GetCoinTextureString(cost))
						end
						GameTooltip:Show()
					end
				end)

				-- Button click handler
				RGXQoLCB["TrainAllButton"]:SetScript("OnClick",function(self)
					for i = 1, GetNumTrainerServices() do
						local void, void, isAvail = GetTrainerServiceInfo(i)
						if isAvail and isAvail == "available" then
							BuyTrainerService(i)
						end
					end
				end)

				-- Enable button only when skills are available
				local skillsAvailable
				hooksecurefunc("ClassTrainerFrame_Update", function()
					skillsAvailable = false
					for i = 1, GetNumTrainerServices() do
						local void, void, isAvail = GetTrainerServiceInfo(i)
						if isAvail and isAvail == "available" then
							skillsAvailable = true
						end
					end
					RGXQoLCB["TrainAllButton"]:SetEnabled(skillsAvailable)
					-- Refresh tooltip
					if RGXQoLCB["TrainAllButton"]:IsMouseOver() and skillsAvailable then
						RGXQoLCB["TrainAllButton"]:GetScript("OnEnter")(RGXQoLCB["TrainAllButton"])
					end
				end)

				-- Function to set train all button
				local function SetTrainAllFunc()
					if RGXQoLLC["ShowTrainAllBtn"] == "On" then
						RGXQoLCB["TrainAllButton"]:Show()
					else
						RGXQoLCB["TrainAllButton"]:Hide()
					end
				end

				-- Run function when option is clicked, reset or preset button is clicked and on startup
				RGXQoLCB["ShowTrainAllBtn"]:HookScript("OnClick", SetTrainAllFunc)
				TrainerPanel.r:HookScript("OnClick", SetTrainAllFunc)
				RGXQoLCB["EnhanceTrainersBtn"]:HookScript("OnClick", function()
					if IsShiftKeyDown() and IsControlKeyDown() then
						-- Preset profile
						RGXQoLLC["ShowTrainAllBtn"] = "On"
						SetTrainAllFunc()
					end
				end)
				SetTrainAllFunc()

				----------------------------------------------------------------------
				--	ElvUI fixes
				----------------------------------------------------------------------

				-- ElvUI fixes
				if RGXQoLLC.ElvUI then
					local E = RGXQoLLC.ElvUI
					if E.private.skins.blizzard.enable and E.private.skins.blizzard.trainer then
						regions[2]:Hide()
						regions[3]:Hide()
						RecipeInset:Hide()
						DetailsInset:Hide()
						_G["ClassTrainerFrame"]:SetHeight(512 + tall)
						_G["ClassTrainerTrainButton"]:ClearAllPoints()
						_G["ClassTrainerTrainButton"]:SetPoint("BOTTOMRIGHT", _G["ClassTrainerFrame"], "BOTTOMRIGHT", -42, 78)
						RGXQoLCB["TrainAllButton"]:ClearAllPoints()
						RGXQoLCB["TrainAllButton"]:SetPoint("BOTTOMLEFT", _G["ClassTrainerFrame"], "BOTTOMLEFT", 344, 78)
						E:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalTrainAllButton)
					end
				end

			end)

		end

		----------------------------------------------------------------------
		--	Set weather density (no reload required)
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local weatherPanel = RGXQoLLC:CreatePanel("Set weather density", "weatherPanel")
			RGXQoLLC:MakeTx(weatherPanel, "Settings", 16, -72)
			RGXQoLLC:MakeSL(weatherPanel, "WeatherLevel", "Drag to set the density of weather effects.", 0, 3, 1, 16, -92, "%.0f")

			local weatherSliderTable = {L["Very Low"], L["Low"], L["Medium"], L["High"]}

			-- Function to set the weather density
			local function SetWeatherFunc()
				RGXQoLCB["WeatherLevel"].f:SetText(RGXQoLLC["WeatherLevel"] .. "  (" .. weatherSliderTable[RGXQoLLC["WeatherLevel"] + 1] .. ")")
				if RGXQoLLC["SetWeatherDensity"] == "On" then
					SetCVar("WeatherDensity", RGXQoLLC["WeatherLevel"])
					SetCVar("RAIDweatherDensity", RGXQoLLC["WeatherLevel"])
				else
					SetCVar("WeatherDensity", "3")
					SetCVar("RAIDweatherDensity", "3")
				end
			end

			-- Set weather density when options are clicked and on startup if option is enabled
			RGXQoLCB["SetWeatherDensity"]:HookScript("OnClick", SetWeatherFunc)
			RGXQoLCB["WeatherLevel"]:HookScript("OnValueChanged", SetWeatherFunc)
			if RGXQoLLC["SetWeatherDensity"] == "On" then SetWeatherFunc() end

			-- Prevent weather density from being changed when particle density is changed
			hooksecurefunc("SetCVar", function(setting, value)
				if setting and RGXQoLLC["SetWeatherDensity"] == "On" then
					if setting == "graphicsParticleDensity" then
						if GetCVar("WeatherDensity") ~= RGXQoLLC["WeatherLevel"] then
							C_Timer.After(0.1, function()
								SetCVar("WeatherDensity", RGXQoLLC["WeatherLevel"])
							end)
						end
					elseif setting == "raidGraphicsParticleDensity" then
						if GetCVar("RAIDweatherDensity") ~= RGXQoLLC["WeatherLevel"] then
							C_Timer.After(0.1, function()
								SetCVar("RAIDweatherDensity", RGXQoLLC["WeatherLevel"])
							end)
						end
					end
				end
			end)

			-- Help button hidden
			weatherPanel.h:Hide()

			-- Back button handler
			weatherPanel.b:SetScript("OnClick", function()
				weatherPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			weatherPanel.r:SetScript("OnClick", function()

				-- Reset slider
				RGXQoLLC["WeatherLevel"] = 3

				-- Refresh side panel
				weatherPanel:Hide(); weatherPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			RGXQoLCB["SetWeatherDensityBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["WeatherLevel"] = 0
					SetWeatherFunc()
				else
					weatherPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Enhance professions
		----------------------------------------------------------------------

		if RGXQoLLC["EnhanceProfessions"] == "On" and not RGXQoLLockList["EnhanceProfessions"] then

			-- Set increased height of professions frame and maximum number of recipes listed
			local tall, numTallProfs = 73, 19

			----------------------------------------------------------------------
			--	TradeSkill Frame
			----------------------------------------------------------------------

			EventUtil.ContinueOnAddOnLoaded("Blizzard_TradeSkillUI",function()

				-- Make the tradeskill frame double-wide
				UIPanelWindows["TradeSkillFrame"] = {area = "override", pushable = 1, xoffset = -16, yoffset = 12, bottomClampOverride = 140 + 12, width = 685, height = 487, whileDead = 1}

				-- Size the tradeskill frame
				_G["TradeSkillFrame"]:SetWidth(714)
				_G["TradeSkillFrame"]:SetHeight(487 + tall)

				-- Adjust title text
				_G["TradeSkillFrameTitleText"]:ClearAllPoints()
				_G["TradeSkillFrameTitleText"]:SetPoint("TOP", _G["TradeSkillFrame"], "TOP", 0, -18)

				-- Expand the tradeskill list to full height
				_G["TradeSkillListScrollFrame"]:ClearAllPoints()
				_G["TradeSkillListScrollFrame"]:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 25, -75)
				_G["TradeSkillListScrollFrame"]:SetSize(295, 336 + tall)

				-- Create additional list rows
				local oldTradeSkillsDisplayed = TRADE_SKILLS_DISPLAYED

				-- Position existing buttons
				for i = 1 + 1, TRADE_SKILLS_DISPLAYED do
					_G["TradeSkillSkill" .. i]:ClearAllPoints()
					_G["TradeSkillSkill" .. i]:SetPoint("TOPLEFT", _G["TradeSkillSkill" .. (i-1)], "BOTTOMLEFT", 0, 1)
				end

				-- Create and position new buttons
				_G.TRADE_SKILLS_DISPLAYED = _G.TRADE_SKILLS_DISPLAYED + numTallProfs
				for i = oldTradeSkillsDisplayed + 1, TRADE_SKILLS_DISPLAYED do
					local button = CreateFrame("Button", "TradeSkillSkill" .. i, TradeSkillFrame, "TradeSkillSkillButtonTemplate")
					button:SetID(i)
					button:Hide()
					button:ClearAllPoints()
					button:SetPoint("TOPLEFT", _G["TradeSkillSkill" .. (i-1)], "BOTTOMLEFT", 0, 1)
				end

				-- Set highlight bar width when shown
				hooksecurefunc(_G["TradeSkillHighlightFrame"], "Show", function()
					_G["TradeSkillHighlightFrame"]:SetWidth(290)
				end)

				-- Move the tradeskill detail frame to the right and stretch it to full height
				_G["TradeSkillDetailScrollFrame"]:ClearAllPoints()
				_G["TradeSkillDetailScrollFrame"]:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 352, -74)
				_G["TradeSkillDetailScrollFrame"]:SetSize(298, 336 + tall)
				-- _G["TradeSkillReagent1"]:SetHeight(500) -- Debug

				-- Hide detail scroll frame textures
				_G["TradeSkillDetailScrollFrameTop"]:SetAlpha(0)
				_G["TradeSkillDetailScrollFrameBottom"]:SetAlpha(0)

				-- Create texture for skills list
				local RecipeInset = _G["TradeSkillFrame"]:CreateTexture(nil, "ARTWORK")
				RecipeInset:SetSize(304, 361 + tall)
				RecipeInset:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 16, -72)
				RecipeInset:SetTexture("Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg")

				-- Set detail frame backdrop
				local DetailsInset = _G["TradeSkillFrame"]:CreateTexture(nil, "ARTWORK")
				DetailsInset:SetSize(302, 339 + tall)
				DetailsInset:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 348, -72)
				DetailsInset:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated")

				-- Hide expand tab (left of All button)
				_G["TradeSkillExpandTabLeft"]:Hide()

				-- Get tradeskill frame textures
				local regions = {_G["TradeSkillFrame"]:GetRegions()}

				-- Set top left texture
				regions[2]:SetSize(512, 512)
				regions[2]:SetTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus")
				regions[2]:SetTexCoord(0.25, 0.75, 0, 0.5)

				-- Set top right texture
				regions[3]:ClearAllPoints()
				regions[3]:SetPoint("TOPLEFT", regions[2], "TOPRIGHT", 0, 0)
				regions[3]:SetSize(256, 512)
				regions[3]:SetTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus")
				regions[3]:SetTexCoord(0.75, 1, 0, 0.5)

				-- Hide bottom left and bottom right textures
				regions[4]:Hide()
				regions[5]:Hide()

				-- Hide skills list dividing bar
				regions[9]:Hide()
				regions[10]:Hide()

				-- Move create button row
				_G["TradeSkillCreateButton"]:ClearAllPoints()
				_G["TradeSkillCreateButton"]:SetPoint("RIGHT", _G["TradeSkillCancelButton"], "LEFT", -1, 0)

				-- Position and size close button
				_G["TradeSkillCancelButton"]:SetSize(80, 22)
				_G["TradeSkillCancelButton"]:SetText(CLOSE)
				_G["TradeSkillCancelButton"]:ClearAllPoints()
				_G["TradeSkillCancelButton"]:SetPoint("BOTTOMRIGHT", _G["TradeSkillFrame"], "BOTTOMRIGHT", -42, 54)

				-- Position close box
				_G["TradeSkillFrameCloseButton"]:ClearAllPoints()
				_G["TradeSkillFrameCloseButton"]:SetPoint("TOPRIGHT", _G["TradeSkillFrame"], "TOPRIGHT", -30, -8)

				-- Position dropdown menus
				TradeSkillInvSlotDropdown:ClearAllPoints()
				TradeSkillInvSlotDropdown:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 550, -42)
				TradeSkillSubClassDropdown:ClearAllPoints()
				TradeSkillSubClassDropdown:SetPoint("RIGHT", TradeSkillInvSlotDropdown, "LEFT", -10, 0)

				-- ElvUI fixes
				if RGXQoLLC.ElvUI then
					local E = RGXQoLLC.ElvUI
					if E.private.skins.blizzard.enable and E.private.skins.blizzard.tradeskill then
						regions[2]:Hide()
						regions[3]:Hide()
						RecipeInset:Hide()
						DetailsInset:Hide()
						_G["TradeSkillFrame"]:SetHeight(512 + tall)
						_G["TradeSkillCancelButton"]:ClearAllPoints()
						_G["TradeSkillCancelButton"]:SetPoint("BOTTOMRIGHT", _G["TradeSkillFrame"], "BOTTOMRIGHT", -42, 78)
						_G["TradeSkillRankFrame"]:ClearAllPoints()
						_G["TradeSkillRankFrame"]:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 24, -44)
					end
				end

				-- Classic Profession Filter addon fixes
				if C_AddOns.IsAddOnLoaded("ClassicProfessionFilter") and TradeSkillFrame.SearchBox and TradeSkillFrame.HaveMats and TradeSkillFrame.HaveMats.text then
					TradeSkillFrame.SearchBox:ClearAllPoints()
					TradeSkillFrame.SearchBox:SetPoint("LEFT", TradeSkillRankFrame, "RIGHT", 20, -10)

					TradeSkillFrame.HaveMats:ClearAllPoints()
					TradeSkillFrame.HaveMats:SetPoint("LEFT", TradeSkillFrame.SearchBox, "RIGHT", 10, 8)
					TradeSkillFrame.HaveMats.text:SetText(L["Have mats?"])
					TradeSkillFrame.HaveMats:SetHitRectInsets(0, -TradeSkillFrame.HaveMats.text:GetStringWidth() + 4, 0, 0)
					TradeSkillFrame.HaveMats.text:SetJustifyH("LEFT")
					TradeSkillFrame.HaveMats.text:SetWordWrap(false)
					if TradeSkillFrame.HaveMats.text:GetWidth() > 80 then
						TradeSkillFrame.HaveMats.text:SetWidth(80)
						TradeSkillFrame.HaveMats:SetHitRectInsets(0, -80 + 4, 0, 0)
					end

					TradeSkillFrame.SearchMats:ClearAllPoints()
					TradeSkillFrame.SearchMats:SetPoint("BOTTOMLEFT", TradeSkillFrame.HaveMats, "BOTTOMLEFT", 0, -16)
					TradeSkillFrame.SearchMats.text:SetText(L["Search mats?"])
					TradeSkillFrame.SearchMats:SetHitRectInsets(0, -TradeSkillFrame.SearchMats.text:GetStringWidth() + 2, 0, 0)
					TradeSkillFrame.SearchMats.text:SetJustifyH("LEFT")
					TradeSkillFrame.SearchMats.text:SetWordWrap(false)
					if TradeSkillFrame.SearchMats.text:GetWidth() > 80 then
						TradeSkillFrame.SearchMats.text:SetWidth(80)
						TradeSkillFrame.SearchMats:SetHitRectInsets(0, -80 + 4, 0, 0)
					end
				end

			end)

			----------------------------------------------------------------------
			--	Craft Frame
			----------------------------------------------------------------------

			EventUtil.ContinueOnAddOnLoaded("Blizzard_CraftUI",function()

				-- Make the craft frame double-wide
				UIPanelWindows["CraftFrame"] = {area = "override", pushable = 1, xoffset = -16, yoffset = 12, bottomClampOverride = 140 + 12, width = 685, height = 487, whileDead = 1}

				-- Size the craft frame
				_G["CraftFrame"]:SetWidth(714)
				_G["CraftFrame"]:SetHeight(487 + tall)

				-- Adjust title text
				_G["CraftFrameTitleText"]:ClearAllPoints()
				_G["CraftFrameTitleText"]:SetPoint("TOP", _G["CraftFrame"], "TOP", 0, -18)

				-- Expand the crafting list to full height
				_G["CraftListScrollFrame"]:ClearAllPoints()
				_G["CraftListScrollFrame"]:SetPoint("TOPLEFT", _G["CraftFrame"], "TOPLEFT", 25, -75)
				_G["CraftListScrollFrame"]:SetSize(295, 336 + tall)

				-- Create additional list rows
				local oldCraftsDisplayed = CRAFTS_DISPLAYED

				-- Position existing buttons
				_G["Craft1Cost"]:ClearAllPoints()
				_G["Craft1Cost"]:SetPoint("RIGHT", _G["Craft1"], "RIGHT", -30, 0)
				for i = 1 + 1, CRAFTS_DISPLAYED do
					_G["Craft" .. i]:ClearAllPoints()
					_G["Craft" .. i]:SetPoint("TOPLEFT", _G["Craft" .. (i-1)], "BOTTOMLEFT", 0, 1)
					_G["Craft" .. i .. "Cost"]:ClearAllPoints()
					_G["Craft" .. i .. "Cost"]:SetPoint("RIGHT", _G["Craft" .. i], "RIGHT", -30, 0)
				end

				-- Create and position new buttons
				_G.CRAFTS_DISPLAYED = _G.CRAFTS_DISPLAYED + numTallProfs
				for i = oldCraftsDisplayed + 1, CRAFTS_DISPLAYED do
					local button = CreateFrame("Button", "Craft" .. i, CraftFrame, "CraftButtonTemplate")
					button:SetID(i)
					button:Hide()
					button:ClearAllPoints()
					button:SetPoint("TOPLEFT", _G["Craft" .. (i-1)], "BOTTOMLEFT", 0, 1)
					_G["Craft" .. i .. "Cost"]:ClearAllPoints()
					_G["Craft" .. i .. "Cost"]:SetPoint("RIGHT", _G["Craft" .. i], "RIGHT", -30, 0)
				end

				-- Move craft frame points (such as Beast Training)
				CraftFramePointsLabel:ClearAllPoints()
				CraftFramePointsLabel:SetPoint("TOPLEFT", CraftFrame, "TOPLEFT", 100, -50)
				CraftFramePointsText:ClearAllPoints()
				CraftFramePointsText:SetPoint("LEFT", CraftFramePointsLabel, "RIGHT", 3, 0)

				-- Move craft frame cost column (such as Beast Training)
				hooksecurefunc("CraftFrame_Update", function()
					for i = 1, CRAFTS_DISPLAYED, 1 do
						if _G["Craft" .. i] then
							local craftButtonCost = _G["Craft"..i.."Cost"]
							if craftButtonCost then
								craftButtonCost:SetPoint("RIGHT", -30, 0)
							end
						end
					end
				end)

				-- Set highlight bar width when shown
				hooksecurefunc(_G["CraftHighlightFrame"], "Show", function()
					_G["CraftHighlightFrame"]:SetWidth(290)
				end)

				-- Move the craft detail frame to the right and stretch it to full height
				_G["CraftDetailScrollFrame"]:ClearAllPoints()
				_G["CraftDetailScrollFrame"]:SetPoint("TOPLEFT", _G["CraftFrame"], "TOPLEFT", 352, -74)
				_G["CraftDetailScrollFrame"]:SetSize(298, 336 + tall)
				-- _G["CraftReagent1"]:SetHeight(500) -- Debug

				-- Hide detail scroll frame textures
				_G["CraftDetailScrollFrameTop"]:SetAlpha(0)
				_G["CraftDetailScrollFrameBottom"]:SetAlpha(0)

				-- Create texture for skills list
				local RecipeInset = _G["CraftFrame"]:CreateTexture(nil, "ARTWORK")
				RecipeInset:SetSize(304, 361 + tall)
				RecipeInset:SetPoint("TOPLEFT", _G["CraftFrame"], "TOPLEFT", 16, -72)
				RecipeInset:SetTexture("Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg")

				-- Set detail frame backdrop
				local DetailsInset = _G["CraftFrame"]:CreateTexture(nil, "ARTWORK")
				DetailsInset:SetSize(302, 339 + tall)
				DetailsInset:SetPoint("TOPLEFT", _G["CraftFrame"], "TOPLEFT", 348, -72)
				DetailsInset:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated")

				-- Hide expand tab (left of All button)
				_G["CraftExpandTabLeft"]:Hide()

				-- Get craft frame textures
				local regions = {_G["CraftFrame"]:GetRegions()}

				-- Set top left texture
				regions[2]:SetSize(512, 512)
				regions[2]:SetTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus")
				regions[2]:SetTexCoord(0.25, 0.75, 0, 0.5)

				-- Set top right texture
				regions[3]:ClearAllPoints()
				regions[3]:SetPoint("TOPLEFT", regions[2], "TOPRIGHT", 0, 0)
				regions[3]:SetSize(256, 512)
				regions[3]:SetTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus")
				regions[3]:SetTexCoord(0.75, 1, 0, 0.5)

				-- Hide bottom left and bottom right textures
				regions[4]:Hide()
				regions[5]:Hide()

				-- Hide skills list dividing bar
				regions[9]:Hide()
				regions[10]:Hide()

				-- Move create button row
				_G["CraftCreateButton"]:ClearAllPoints()
				_G["CraftCreateButton"]:SetPoint("RIGHT", _G["CraftCancelButton"], "LEFT", -1, 0)

				-- Position and size close button
				_G["CraftCancelButton"]:SetSize(80, 22)
				_G["CraftCancelButton"]:SetText(CLOSE)
				_G["CraftCancelButton"]:ClearAllPoints()
				_G["CraftCancelButton"]:SetPoint("BOTTOMRIGHT", _G["CraftFrame"], "BOTTOMRIGHT", -42, 54)

				-- Position close box
				_G["CraftFrameCloseButton"]:ClearAllPoints()
				_G["CraftFrameCloseButton"]:SetPoint("TOPRIGHT", _G["CraftFrame"], "TOPRIGHT", -30, -8)

				-- ElvUI fixes
				if RGXQoLLC.ElvUI then
					local E = RGXQoLLC.ElvUI
					if E.private.skins.blizzard.enable and E.private.skins.blizzard.craft then
						regions[2]:Hide()
						regions[3]:Hide()
						RecipeInset:Hide()
						DetailsInset:Hide()
						_G["CraftFrame"]:SetHeight(512 + tall)
						_G["CraftCancelButton"]:ClearAllPoints()
						_G["CraftCancelButton"]:SetPoint("BOTTOMRIGHT", _G["CraftFrame"], "BOTTOMRIGHT", -42, 78)
						_G["CraftRankFrame"]:ClearAllPoints()
						_G["CraftRankFrame"]:SetPoint("TOPLEFT", _G["CraftFrame"], "TOPLEFT", 24, -44)
					end
				end

				-- Fix for TradeSkillMaster moving the craft create button
				hooksecurefunc(CraftCreateButton, "SetFrameLevel", function()
					CraftCreateButton:ClearAllPoints()
					CraftCreateButton:SetPoint("RIGHT", CraftCancelButton, "LEFT", -1, 0)
				end)

				-- Classic Profession Filter addon fixes
				if C_AddOns.IsAddOnLoaded("ClassicProfessionFilter") and CraftFrame.SearchBox and CraftFrame.HaveMats and CraftFrame.HaveMats.text and CraftFrame.SearchMats and CraftFrame.SearchMats.text then
					CraftFrame.SearchBox:ClearAllPoints()
					CraftFrame.SearchBox:SetPoint("LEFT", CraftRankFrame, "RIGHT", 20, -10)

					CraftFrame.HaveMats:ClearAllPoints()
					CraftFrame.HaveMats:SetPoint("LEFT", CraftFrame.SearchBox, "RIGHT", 10, 8)
					CraftFrame.HaveMats.text:SetText(L["Have mats?"])
					CraftFrame.HaveMats:SetHitRectInsets(0, -CraftFrame.HaveMats.text:GetStringWidth() + 4, 0, 0)
					CraftFrame.HaveMats.text:SetJustifyH("LEFT")
					CraftFrame.HaveMats.text:SetWordWrap(false)
					if CraftFrame.HaveMats.text:GetWidth() > 80 then
						CraftFrame.HaveMats.text:SetWidth(80)
						CraftFrame.HaveMats:SetHitRectInsets(0, -80 + 4, 0, 0)
					end

					CraftFrame.SearchMats:ClearAllPoints()
					CraftFrame.SearchMats:SetPoint("BOTTOMLEFT", CraftFrame.HaveMats, "BOTTOMLEFT", 0, -16)
					CraftFrame.SearchMats.text:SetText(L["Search mats?"])
					CraftFrame.SearchMats:SetHitRectInsets(0, -CraftFrame.SearchMats.text:GetStringWidth() + 2, 0, 0)
					CraftFrame.SearchMats.text:SetJustifyH("LEFT")
					CraftFrame.SearchMats.text:SetWordWrap(false)
					if CraftFrame.SearchMats.text:GetWidth() > 80 then
						CraftFrame.SearchMats.text:SetWidth(80)
						CraftFrame.SearchMats:SetHitRectInsets(0, -80 + 4, 0, 0)
					end
				end

			end)

		end

		----------------------------------------------------------------------
		--	Show free bag slots
		----------------------------------------------------------------------

		if RGXQoLLC["ShowFreeBagSlots"] == "On" and not RGXQoLLockList["ShowFreeBagSlots"] then

			-- Set the CVAR and show the count
			SetCVar("displayFreeBagSlots", "1")
			MainMenuBarBackpackButtonCount:Show()

			-- Function to update the count value
			local function UpdateSlots()
				if MainMenuBarBackpackButton.freeSlots then
					MainMenuBarBackpackButtonCount:SetText(string.format("(%s)", MainMenuBarBackpackButton.freeSlots))
				end
			end

			-- Update the count value when free slots are updated
			hooksecurefunc("MainMenuBarBackpackButton_UpdateFreeSlots", UpdateSlots)

			-- Show free slots in the backpack tooltip
			MainMenuBarBackpackButton:HookScript("OnEnter", function(self)
				GameTooltip:AddLine(string.format(NUM_FREE_SLOTS, (self.freeSlots or 0)))
				GameTooltip:Show()
			end)

		end

		----------------------------------------------------------------------
		--	Enhance quest log
		----------------------------------------------------------------------

		if RGXQoLLC["EnhanceQuestLog"] == "On" then

			if RGXQoLLC["EnhanceQuestTaller"] == "On" then

				-- Set increased height of quest log frame and maximum number of quests listed
				local tall, numTallQuests = 73, 21

				-- Make the quest log frame double-wide
				UIPanelWindows["QuestLogFrame"] = {area = "override", pushable = 0, xoffset = -16, yoffset = 12, bottomClampOverride = 140 + 12, width = 685, height = 487, whileDead = 1}

				-- Size the quest log frame
				QuestLogFrame:SetWidth(714)
				QuestLogFrame:SetHeight(487 + tall)

				-- Adjust quest log title text
				QuestLogTitleText:ClearAllPoints()
				QuestLogTitleText:SetPoint("TOP", QuestLogFrame, "TOP", 0, -18)

				-- Move the detail frame to the right and stretch it to full height
				QuestLogDetailScrollFrame:ClearAllPoints()
				QuestLogDetailScrollFrame:SetPoint("TOPLEFT", QuestLogListScrollFrame, "TOPRIGHT", 31, 1)
				QuestLogDetailScrollFrame:SetHeight(336 + tall)

				-- Expand the quest list to full height
				QuestLogListScrollFrame:SetHeight(336 + tall)

				-- Create additional quest rows
				local oldQuestsDisplayed = QUESTS_DISPLAYED
				_G.QUESTS_DISPLAYED = _G.QUESTS_DISPLAYED + numTallQuests
				for i = oldQuestsDisplayed + 1, QUESTS_DISPLAYED do
					local button = CreateFrame("Button", "QuestLogTitle" .. i, QuestLogFrame, "QuestLogTitleButtonTemplate")
					button:SetID(i)
					button:Hide()
					button:ClearAllPoints()
					button:SetPoint("TOPLEFT", _G["QuestLogTitle" .. (i-1)], "BOTTOMLEFT", 0, 1)
				end

				-- Get quest frame textures
				local regions = {QuestLogFrame:GetRegions()}

				-- Set top left texture
				regions[3]:SetSize(512, 512)
				regions[3]:SetTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus.blp")
				regions[3]:SetTexCoord(0.25, 0.75, 0, 0.5)

				-- Set top right texture
				regions[4]:ClearAllPoints()
				regions[4]:SetPoint("TOPLEFT", regions[3], "TOPRIGHT", 0, 0)
				regions[4]:SetSize(256, 512)
				regions[4]:SetTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus.blp")
				regions[4]:SetTexCoord(0.75, 1, 0, 0.5)

				-- Hide bottom left and bottom right textures
				regions[5]:Hide()
				regions[6]:Hide()

				-- Position and resize abandon button
				QuestLogFrameAbandonButton:SetSize(110, 21)
				QuestLogFrameAbandonButton:SetText(ABANDON_QUEST_ABBREV)
				QuestLogFrameAbandonButton:ClearAllPoints()
				QuestLogFrameAbandonButton:SetPoint("BOTTOMLEFT", QuestLogFrame, "BOTTOMLEFT", 17, 54)

				-- Position and resize share button
				QuestFramePushQuestButton:SetSize(100, 21)
				QuestFramePushQuestButton:SetText(SHARE_QUEST_ABBREV)
				QuestFramePushQuestButton:ClearAllPoints()
				QuestFramePushQuestButton:SetPoint("LEFT", QuestLogFrameAbandonButton, "RIGHT", -3, 0)

				-- Add map button
				local logMapButton = CreateFrame("Button", "LeaPlusGlobalQuestLogMapButton", QuestLogFrame, "UIPanelButtonTemplate")
				logMapButton:SetText(L["Map"])
				logMapButton:ClearAllPoints()
				logMapButton:SetPoint("LEFT", QuestFramePushQuestButton, "RIGHT", -3, 0)
				logMapButton:SetSize(100, 21)
				logMapButton:SetScript("OnClick", ToggleWorldMap)

				-- Position and size close button
				QuestFrameExitButton:SetSize(80, 22)
				QuestFrameExitButton:SetText(CLOSE)
				QuestFrameExitButton:ClearAllPoints()
				QuestFrameExitButton:SetPoint("BOTTOMRIGHT", QuestLogFrame, "BOTTOMRIGHT", -42, 54)

				-- Empty quest frame
				QuestLogNoQuestsText:ClearAllPoints()
				QuestLogNoQuestsText:SetPoint("TOP", QuestLogListScrollFrame, 0, -50)
				hooksecurefunc(EmptyQuestLogFrame, "Show", function()
					EmptyQuestLogFrame:ClearAllPoints()
					EmptyQuestLogFrame:SetPoint("BOTTOMLEFT", QuestLogFrame, "BOTTOMLEFT", 20, -76)
					EmptyQuestLogFrame:SetHeight(487)
				end)

				-- Show map button (not currently used)
				local mapButton = CreateFrame("BUTTON", nil, QuestLogFrame)
				mapButton:SetSize(36, 25)
				mapButton:SetPoint("TOPRIGHT", -390, -44)
				mapButton:SetNormalTexture("Interface\\QuestFrame\\UI-QuestMap_Button")
				mapButton:GetNormalTexture():SetTexCoord(0.125, 0.875, 0, 0.5)
				mapButton:SetPushedTexture("Interface\\QuestFrame\\UI-QuestMap_Button")
				mapButton:GetPushedTexture():SetTexCoord(0.125, 0.875, 0.5, 1.0)
				mapButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
				mapButton:SetScript("OnClick", ToggleWorldMap)
				mapButton:Hide()

				-- ElvUI fixes
				if RGXQoLLC.ElvUI then
					local E = RGXQoLLC.ElvUI
					if E.private.skins.blizzard.enable and E.private.skins.blizzard.quest then
						-- Skin map button
						_G.LeaPlusGlobalMapButton = logMapButton
						E:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalMapButton)
					end
				end

			end

			-- Translations for quest level suffixes (need to be English so links work in addons such as Questie for non-English locales)
			L["D"] = "D" -- Dungeon quest
			L["R"] = "R" -- Raid quest
			L["P"] = "P" -- PvP quest
			L["+"] = "+" -- Elite or group quest

			-- Show quest level in quest log detail frame (but not in quest accept or turn-in frame)
			hooksecurefunc("QuestLog_UpdateQuestDetails", function()
				if RGXQoLLC["EnhanceQuestLevels"] == "On" then
					local quest = GetQuestLogSelection()
					if quest then
						local title, level, suggestedGroup = GetQuestLogTitle(quest)
						if title and level then
							if suggestedGroup then
								if suggestedGroup == LFG_TYPE_DUNGEON then level = level .. L["D"]
								elseif suggestedGroup == RAID then level = level .. L["R"]
								elseif suggestedGroup == ELITE then level = level .. L["+"]
								elseif suggestedGroup == GROUP then level = level .. L["+"]
								elseif suggestedGroup == PVP then level = level .. L["P"]
								end
							end
							QuestLogQuestTitle:SetText("[" .. level .. "] " .. title)
						end
					end
				end
			end)

			-- Show quest levels in quest log
			hooksecurefunc("QuestLog_Update", function()
				local numEntries, numQuests = GetNumQuestLogEntries()
				if numEntries == 0 then return end
				-- Traverse quests in log
				for i = 1, QUESTS_DISPLAYED do
					local questIndex = i + FauxScrollFrame_GetOffset(QuestLogListScrollFrame)
					-- Can use below line instead of FauxScrollFrame_GetOffset (Wrath Classic uses QuestLogTitleButton_Resize)
					-- local questIndex = i + math.floor(QuestLogListScrollFrame:GetVerticalScroll() / QUESTLOG_QUEST_HEIGHT)
					if questIndex <= numEntries then
						-- Get quest title and check
						local questLogTitle = _G["QuestLogTitle" .. i]
						local questCheck = _G["QuestLogTitle" .. i .. "Check"]
						local title, level, suggestedGroup, isHeader = GetQuestLogTitle(questIndex)
						if title and level and not isHeader and RGXQoLLC["EnhanceQuestLevels"] == "On" then
							-- Add level tag if its not a header
							local levelSuffix = ""
							if suggestedGroup and RGXQoLLC["EnhanceQuestDifficulty"] == "On" then
								if suggestedGroup == LFG_TYPE_DUNGEON then levelSuffix = "D"
								elseif suggestedGroup == RAID then levelSuffix = "R"
								elseif suggestedGroup == ELITE then levelSuffix = "+"
								elseif suggestedGroup == GROUP then levelSuffix = "+"
								elseif suggestedGroup == PVP then levelSuffix = "P"
								end
							end
							local questTextFormatted = string.format("  [%d" .. L[levelSuffix] .. "] %s", level, title)
							questLogTitle:SetText(questTextFormatted)
							QuestLogDummyText:SetText(questTextFormatted)
						end
						-- Show tracking check mark
						local checkText = _G["QuestLogTitle" .. i .. "NormalText"]
						if checkText then
							local checkPos = checkText:GetStringWidth()
							if checkPos then
								if checkPos <= 210 then
									questCheck:SetPoint("LEFT", questLogTitle, "LEFT", checkPos + 24, 0)
								else
									questCheck:SetPoint("LEFT", questLogTitle, "LEFT", 210, 0)
								end
							end
						end
					end
				end
			end)

			-- Create configuration panel
			local EnhanceQuestPanel = RGXQoLLC:CreatePanel("Enhance quest log", "EnhanceQuestPanel")

			RGXQoLLC:MakeTx(EnhanceQuestPanel, "Settings", 16, -72)
			RGXQoLLC:MakeCB(EnhanceQuestPanel, "EnhanceQuestTaller", "Larger quest log frame", 16, -92, true, "If checked, the quest log frame will be larger.")

			RGXQoLLC:MakeTx(EnhanceQuestPanel, "Levels", 16, -132)
			RGXQoLLC:MakeCB(EnhanceQuestPanel, "EnhanceQuestLevels", "Show quest levels", 16, -152, false, "If checked, quest levels will be shown.")
			RGXQoLLC:MakeCB(EnhanceQuestPanel, "EnhanceQuestDifficulty", "Show quest difficulty in quest log list", 16, -172, false, "If checked, the quest difficulty will be shown next to the quest level in the quest log list.|n|nThis will indicate whether the quest requires a group (+), dungeon (D), raid (R) or PvP (P).|n|nThe quest difficulty will always be shown in the quest log detail pane regardless of this setting.")

			-- Disable Show quest difficulty option if Show quest levels is disabled
			RGXQoLCB["EnhanceQuestLevels"]:HookScript("OnClick", function()
				RGXQoLLC:LockOption("EnhanceQuestLevels", "EnhanceQuestDifficulty", false)
			end)
			RGXQoLLC:LockOption("EnhanceQuestLevels", "EnhanceQuestDifficulty", false)

			-- Help button hidden
			EnhanceQuestPanel.h:Hide()

			-- Back button handler
			EnhanceQuestPanel.b:SetScript("OnClick", function()
				EnhanceQuestPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page5"]:Show();
				return
			end)

			-- Reset button handler
			EnhanceQuestPanel.r.tiptext = EnhanceQuestPanel.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
			EnhanceQuestPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				RGXQoLLC["EnhanceQuestLevels"] = "On"
				RGXQoLLC["EnhanceQuestDifficulty"] = "On"

				-- Refresh panel
				EnhanceQuestPanel:Hide(); EnhanceQuestPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			RGXQoLCB["EnhanceQuestLogBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["EnhanceQuestLevels"] = "On"
					RGXQoLLC["EnhanceQuestDifficulty"] = "On"
				else
					EnhanceQuestPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Show bag search box
		----------------------------------------------------------------------

		if RGXQoLLC["ShowBagSearchBox"] == "On" and not RGXQoLLockList["ShowBagSearchBox"] then

			-- Create bag item search box
			local BagItemSearchBox = CreateFrame("EditBox", nil, ContainerFrame1, "BagSearchBoxTemplate")
			BagItemSearchBox:SetSize(110, 18)
			BagItemSearchBox:SetMaxLetters(15)

			-- Create bank item search box
			local BankItemSearchBox = CreateFrame("EditBox", nil, BankFrame, "BagSearchBoxTemplate")
			BankItemSearchBox:SetSize(120, 14)
			BankItemSearchBox:SetMaxLetters(15)
			BankItemSearchBox:SetPoint("TOPRIGHT", -60, -40)

			-- Attach bag search box first bag only
			hooksecurefunc("ContainerFrame_Update", function(self)
				if self:GetID() == 0 then
					BagItemSearchBox:SetParent(self)
					BagItemSearchBox:SetPoint("TOPLEFT", self, "TOPLEFT", 54, -29)
					BagItemSearchBox.anchorBag = self
					BagItemSearchBox:Show()
				elseif BagItemSearchBox.anchorBag == self then
					BagItemSearchBox:ClearAllPoints()
					BagItemSearchBox:Hide()
					BagItemSearchBox.anchorBag = nil
				end
			end)

		end

		----------------------------------------------------------------------
		--	Show vendor price
		----------------------------------------------------------------------

		if RGXQoLLC["ShowVendorPrice"] == "On" then

			-- Function to show vendor price
			local function ShowSellPrice(tooltip, tooltipObject)
				if tooltip.shownMoneyFrames then return end
				tooltipObject = tooltipObject or GameTooltip
				-- Get container
				local container = GetMouseFoci()[1]
				if not container then return end
				-- Get item
				local itemName, itemlink = tooltipObject:GetItem()
				if not itemlink then return end
				local void, ilink, void, void, void, void, void, void, void, void, sellPrice, classID = C_Item.GetItemInfo(itemlink)
				if sellPrice and sellPrice > 0 then
					local count = container and type(container.count) == "number" and container.count or 1
					if sellPrice and count > 0 then
						if classID and classID == 11 then count = 1 end -- Fix for quiver/ammo pouch so ammo is not included
						if sellPrice == 4000 and ilink and string.find(ilink, "item:210781:") then
							-- Bug with Phoenix Bindings (real price is 24 silver 81 copper, but game returns 40 silver) (seems fixed now)
							-- Test with GameTooltip:SetHyperlink("item:210781")
							-- SetTooltipMoney(tooltip, 2481 * count, "STATIC", SELL_PRICE .. ":")
						else
							-- Everything else get game price
							SetTooltipMoney(tooltip, sellPrice * count, "STATIC", SELL_PRICE .. ":")
						end
					end
				end
				-- Refresh chat tooltips
				if tooltipObject == ItemRefTooltip then ItemRefTooltip:Show() end
			end

			-- Show vendor price when tooltips are shown
			if GameTooltip:HasScript("OnTooltipSetItem") then
				GameTooltip:HookScript("OnTooltipSetItem", ShowSellPrice)
			end
			hooksecurefunc(GameTooltip, "SetHyperlink", function(tip) ShowSellPrice(tip, GameTooltip) end)
			hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(tip) ShowSellPrice(tip, ItemRefTooltip) end)

		end

		----------------------------------------------------------------------
		--	Dismount me
		----------------------------------------------------------------------

		if RGXQoLLC["StandAndDismount"] == "On" then

			local eFrame = CreateFrame("FRAME")
			eFrame:RegisterEvent("UI_ERROR_MESSAGE")
			eFrame:SetScript("OnEvent", function(self, event, messageType, msg)
				-- Auto dismount
				if msg == ERR_OUT_OF_RAGE and RGXQoLLC["DismountNoResource"] == "On"
				or msg == ERR_OUT_OF_MANA and RGXQoLLC["DismountNoResource"] == "On"
				or msg == ERR_OUT_OF_ENERGY and RGXQoLLC["DismountNoResource"] == "On"
				or msg == SPELL_FAILED_MOVING and RGXQoLLC["DismountNoMoving"] == "On"
				or msg == ERR_TAXIPLAYERSHAPESHIFTED
				then
					if IsMounted() then
						Dismount()
						UIErrorsFrame:Clear()
					end
				end
			end)

			-- Dismount when flight point map is opened
			local taxiFrame = CreateFrame("FRAME")
			taxiFrame:RegisterEvent("TAXIMAP_OPENED")
			taxiFrame:SetScript("OnEvent", function()
				if IsMounted() then Dismount() end
			end)

			-- Create configuration panel
			local DismountFrame = RGXQoLLC:CreatePanel("Dismount me", "DismountFrame")

			RGXQoLLC:MakeTx(DismountFrame, "Settings", 16, -72)
			RGXQoLLC:MakeCB(DismountFrame, "DismountNoResource", "Dismount when not enough rage, mana or energy", 16, -92, false, "If checked, you will be dismounted when you attempt to cast a spell but don't have the rage, mana or energy to cast it.")
			RGXQoLLC:MakeCB(DismountFrame, "DismountNoMoving", "Dismount when casting a spell while moving", 16, -112, false, "If checked, you will be dismounted when you attempt to cast a non-instant cast spell while moving.")
			RGXQoLLC:MakeCB(DismountFrame, "DismountNoTaxi", "Dismount when the flight map opens", 16, -132, false, "If checked, you will be dismounted when you instruct a flight master to open the flight map.")

			-- Help button hidden
			DismountFrame.h.tiptext = L["The game will dismount you if you successfully cast a spell without addons.  These settings let you set some additional dismount rules."]

			-- Back button handler
			DismountFrame.b:SetScript("OnClick", function()
				DismountFrame:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page7"]:Show()
				return
			end)

			-- Function to set dismount options
			local function SetDismount()
				if RGXQoLLC["DismountNoTaxi"] == "On" then
					taxiFrame:RegisterEvent("TAXIMAP_OPENED")
				else
					taxiFrame:UnregisterEvent("TAXIMAP_OPENED")
				end
			end

			-- Run function when certain options are clicked and on startup
			RGXQoLCB["DismountNoTaxi"]:HookScript("OnClick", SetDismount)
			SetDismount()

			-- Reset button handler
			DismountFrame.r:SetScript("OnClick", function()

				-- Reset checkboxes
				RGXQoLLC["DismountNoResource"] = "On"
				RGXQoLLC["DismountNoMoving"] = "On"
				RGXQoLLC["DismountNoTaxi"] = "On"

				-- Update settings and configuration panel
				SetDismount()
				DismountFrame:Hide(); DismountFrame:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			RGXQoLCB["DismountBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["DismountNoResource"] = "On"
					RGXQoLLC["DismountNoMoving"] = "On"
					RGXQoLLC["DismountNoTaxi"] = "On"
					SetDismount()
				else
					DismountFrame:Show()
					RGXQoLLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Use class colors in chat
		----------------------------------------------------------------------

		if RGXQoLLC["ClassColorsInChat"] == "On" and not RGXQoLLockList["ClassColorsInChat"] then

			SetCVar("chatClassColorOverride", "0")

			for void, v in ipairs({"SAY", "EMOTE", "YELL", "GUILD", "OFFICER", "WHISPER", "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER", "RAID_WARNING", "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER", "VOICE_TEXT"}) do
				SetChatColorNameByClass(v, true)
			end

			for i = 1, 50 do
				SetChatColorNameByClass("CHANNEL" .. i, true)
			end

		end

		----------------------------------------------------------------------
		-- Disable screen glow (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to set screen glow
			local function SetGlow()
				if RGXQoLLC["NoScreenGlow"] == "On" then
					SetCVar("ffxGlow", "0")
				else
					SetCVar("ffxGlow", "1")
				end
			end

			-- Set screen glow on startup and when option is clicked (if enabled)
			RGXQoLCB["NoScreenGlow"]:HookScript("OnClick", SetGlow)
			if RGXQoLLC["NoScreenGlow"] == "On" then SetGlow() end

		end

		----------------------------------------------------------------------
		-- Disable screen effects (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to set screen effects
			local function SetEffects()
				if RGXQoLLC["NoScreenEffects"] == "On" then
					SetCVar("ffxDeath", "0")
					SetCVar("ffxNether", "0")
				else
					SetCVar("ffxDeath", "1")
					SetCVar("ffxNether", "1")
				end
			end

			-- Set screen effects when option is clicked and on startup (if enabled)
			RGXQoLCB["NoScreenEffects"]:HookScript("OnClick", SetEffects)
			if RGXQoLLC["NoScreenEffects"] == "On" then SetEffects() end

		end

		----------------------------------------------------------------------
		-- Universal group chat color (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to set chat colors
			local function SetCol()
				if RGXQoLLC["UnivGroupColor"] == "On" then
					ChangeChatColor("RAID", 0.67, 0.67, 1)
					ChangeChatColor("RAID_LEADER", 0.46, 0.78, 1)
				else
					ChangeChatColor("RAID", 1, 0.50, 0)
					ChangeChatColor("RAID_LEADER", 1, 0.28, 0.04)
				end
			end

			-- Set chat colors when option is clicked and on startup (if enabled)
			RGXQoLCB["UnivGroupColor"]:HookScript("OnClick", SetCol)
			if RGXQoLLC["UnivGroupColor"] == "On" then	SetCol() end

		end

		----------------------------------------------------------------------
		-- Minimap button (no reload required)
		----------------------------------------------------------------------

		do

			-- Minimap button click function
			local function MiniBtnClickFunc(arg1)
				-- Prevent options panel from showing if chat configuration panel is showing
				if ChatConfigFrame:IsShown() then return end
				-- Prevent options panel from showing if Blizzard Store is showing
				if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
				-- Left button down
				if arg1 == "LeftButton" then

					-- Shift key toggles music
					if IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
						Sound_ToggleMusic()
						return
					end

					-- Control key does nothing
					if IsControlKeyDown() and not IsShiftKeyDown() and not IsAltKeyDown() then
						return
					end

					-- Alt key toggles error messages
					if IsAltKeyDown() and not IsControlKeyDown() and not IsShiftKeyDown() then
						if RGXQoLDB["HideErrorMessages"] == "On" then -- Checks global
							if RGXQoLLC["ShowErrorsFlag"] == 1 then
								RGXQoLLC["ShowErrorsFlag"] = 0
								ActionStatus_DisplayMessage(L["Error messages will be shown"], true)
							else
								RGXQoLLC["ShowErrorsFlag"] = 1
								ActionStatus_DisplayMessage(L["Error messages will be hidden"], true)
							end
							return
						end
						return
					end

					-- Shift key does nothing
					if IsShiftKeyDown() and not IsControlKeyDown() then
						return
					end

					-- Control key and alt key toggles Zygor addon
					if IsControlKeyDown() and IsAltKeyDown() and not IsShiftKeyDown() then
						RGXQoLLC:ZygorToggle()
						return
					end

					-- Control key and shift key toggles maximised window mode
					if IsControlKeyDown() and IsShiftKeyDown() and not IsAltKeyDown() then
						if RGXQoLLC:PlayerInCombat() then
							return
						else
							SetCVar("gxMaximize", tostring(1 - GetCVar("gxMaximize")))
							UpdateWindow()
						end
						return
					end

					-- No modifier key toggles the options panel
					if RGXQoLLC:IsPlusShowing() then
						RGXQoLLC:HideFrames()
						RGXQoLLC:HideConfigPanels()
					else
						RGXQoLLC:HideFrames()
						RGXQoLLC["PageF"]:Show()
					end
					RGXQoLLC["Page"..RGXQoLLC["RGXQoLStartPage"]]:Show()
				end

				-- Right button down
				if arg1 == "RightButton" then

					-- No modifier key toggles the options panel
					if RGXQoLLC:IsPlusShowing() then
						RGXQoLLC:HideFrames()
						RGXQoLLC:HideConfigPanels()
					else
						RGXQoLLC:HideFrames()
						RGXQoLLC["PageF"]:Show()
					end
					RGXQoLLC["Page" .. RGXQoLLC["RGXQoLStartPage"]]:Show()

				end

			end

			-- Assign global scope for function
			_G.RGXQoLMiniBtnClickFunc = MiniBtnClickFunc

			-- Create the RGX minimap button (framework-owned positioning)
			local RGX = _G.RGXFramework
			if RGX and RGX.GetMinimap and not RGXQoLLC.minimapButton then
				local MM = RGX:GetMinimap()
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
					onLeftClick = function(btn, mouseButton)
						MiniBtnClickFunc("LeftButton")
					end,
					onCtrlRight = function(btn)
						btn:SetVisible(false)
						RGXQoLLC["ShowMinimapIcon"] = "Off"
					end,
				})
			end

			-- Show or hide the minimap button when the option is clicked
			RGXQoLCB["ShowMinimapIcon"]:HookScript("OnClick", function()
				if RGXQoLLC.minimapButton then
					RGXQoLLC.minimapButton:SetVisible(RGXQoLLC["ShowMinimapIcon"] == "On")
				end
			end)
			if RGXQoLLC.minimapButton then
				RGXQoLLC.minimapButton:SetVisible(RGXQoLLC["ShowMinimapIcon"] == "On")
			end

		end

		----------------------------------------------------------------------
		-- Auction House Extras
		----------------------------------------------------------------------

		if RGXQoLLC["AhExtras"] == "On" then

			EventUtil.ContinueOnAddOnLoaded("Blizzard_AuctionUI",function()

				-- Set default auction duration value to saved settings or default settings
				AuctionFrameAuctions.duration = RGXQoLDB["AHDuration"] or 3

				-- Update duration radio button
				AuctionsShortAuctionButton:SetChecked(false)
				AuctionsMediumAuctionButton:SetChecked(false)
				AuctionsLongAuctionButton:SetChecked(false)
				if AuctionFrameAuctions.duration == 1 then
					AuctionsShortAuctionButton:SetChecked(true)
				elseif AuctionFrameAuctions.duration == 2 then
					AuctionsMediumAuctionButton:SetChecked(true)
				elseif AuctionFrameAuctions.duration == 3 then
					AuctionsLongAuctionButton:SetChecked(true)
				end

				-- Functions
				local function CreateAuctionCB(name, anchor, x, y, text)
					RGXQoLCB[name] = CreateFrame("CheckButton", nil, AuctionFrameAuctions, "ChatConfigCheckButtonTemplate")
					RGXQoLCB[name]:SetFrameStrata("HIGH")
					RGXQoLCB[name]:SetSize(20, 20)
					RGXQoLCB[name]:SetPoint(anchor, x, y)
					RGXQoLCB[name].f = RGXQoLCB[name]:CreateFontString(nil, 'OVERLAY', "GameFontNormal")
					RGXQoLCB[name].f:SetPoint("LEFT", 20, 0)
					RGXQoLCB[name].f:SetText(L[text])
					RGXQoLCB[name].f:Show();
					RGXQoLCB[name]:SetScript('OnClick', function()
						if RGXQoLCB[name]:GetChecked() then
							RGXQoLLC[name] = "On"
						else
							RGXQoLLC[name] = "Off"
						end
					end)
					RGXQoLCB[name]:SetScript('OnShow', function(self)
						if RGXQoLLC[name] == "On" then
							self:SetChecked(true)
						else
							self:SetChecked(false)
						end
					end)
				end

				-- Show the correct fields in the AH frame and match prices
				local function SetupAh()
					if RGXQoLLC["AhBuyoutOnly"] == "On" then
						-- Hide the start price
						StartPrice:SetAlpha(0);
						-- Set start price to buyout price
						StartPriceGold:SetText(BuyoutPriceGold:GetText());
						StartPriceSilver:SetText(BuyoutPriceSilver:GetText());
						StartPriceCopper:SetText(BuyoutPriceCopper:GetText());
					else
						-- Show the start price
						StartPrice:SetAlpha(1);
					end
					-- If gold only is on, set copper and silver to 99
					if RGXQoLLC["AhGoldOnly"] == "On" then
						StartPriceCopper:SetText("99"); StartPriceCopper:Disable();
						StartPriceSilver:SetText("99"); StartPriceSilver:Disable();
						BuyoutPriceCopper:SetText("99"); BuyoutPriceCopper:Disable();
						BuyoutPriceSilver:SetText("99"); BuyoutPriceSilver:Disable();
					else
						StartPriceCopper:Enable();
						StartPriceSilver:Enable();
						BuyoutPriceCopper:Enable();
						BuyoutPriceSilver:Enable();
					end
					-- Validate the auction (mainly for the create auction button status)
					AuctionsFrameAuctions_ValidateAuction()
				end

				-- Create checkboxes
				CreateAuctionCB("AhBuyoutOnly", "BOTTOMLEFT", 200, 16, "Buyout Only")
				CreateAuctionCB("AhGoldOnly", "BOTTOMLEFT", 320, 16, "Gold Only")

				-- Reposition Gold Only checkbox so it does not overlap Buyout Only checkbox label
				RGXQoLCB["AhGoldOnly"]:ClearAllPoints()
				RGXQoLCB["AhGoldOnly"]:SetPoint("LEFT", RGXQoLCB["AhBuyoutOnly"].f, "RIGHT", 20, 0)

				-- Set click boundaries
				RGXQoLCB["AhBuyoutOnly"]:SetHitRectInsets(0, -RGXQoLCB["AhBuyoutOnly"].f:GetStringWidth() + 6, 0, 0);
				RGXQoLCB["AhGoldOnly"]:SetHitRectInsets(0, -RGXQoLCB["AhGoldOnly"].f:GetStringWidth() + 6, 0, 0);

				RGXQoLCB["AhBuyoutOnly"]:HookScript('OnClick', SetupAh);
				RGXQoLCB["AhBuyoutOnly"]:HookScript('OnShow', SetupAh);

				AuctionFrameAuctions:HookScript("OnShow", SetupAh)
				BuyoutPriceGold:HookScript("OnTextChanged", SetupAh)
				BuyoutPriceSilver:HookScript("OnTextChanged", SetupAh)
				BuyoutPriceCopper:HookScript("OnTextChanged", SetupAh)
				StartPriceGold:HookScript("OnTextChanged", SetupAh)
				StartPriceSilver:HookScript("OnTextChanged", SetupAh)
				StartPriceCopper:HookScript("OnTextChanged", SetupAh)

				-- Lock the create auction button if buyout gold box is empty (when using buyout only and gold only)
				AuctionsCreateAuctionButton:HookScript("OnEnable", function()
					-- Do nothing if wow token frame is showing
					if AuctionsWowTokenAuctionFrame:IsShown() then return end
					-- Lock the create auction button if both checkboxes are enabled and buyout gold price is empty
					if RGXQoLLC["AhGoldOnly"] == "On" and RGXQoLLC["AhBuyoutOnly"] == "On" then
						if BuyoutPriceGold:GetText() == "" then
							AuctionsCreateAuctionButton:Disable()
						end
					end
				end)

				-- Clear copper and silver prices if gold only box is unchecked
				RGXQoLCB["AhGoldOnly"]:HookScript('OnClick', function()
					if RGXQoLCB["AhGoldOnly"]:GetChecked() == false then
						BuyoutPriceCopper:SetText("")
						BuyoutPriceSilver:SetText("")
						StartPriceCopper:SetText("")
						StartPriceSilver:SetText("")
					end
					SetupAh();
				end)

				-- Create find button
				AuctionsItemText:Hide()
				RGXQoLLC:CreateButton("FindAuctionButton", AuctionsStackSizeMaxButton, "Find Item", "CENTER", 0, 68, 0, 21, false, "")
				RGXQoLCB["FindAuctionButton"]:SetParent(AuctionFrameAuctions)

				if RGXQoLLC.ElvUI then
					_G.LeaPlusGlobalFindItemButton = RGXQoLCB["FindAuctionButton"]
					RGXQoLLC.ElvUI:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalFindItemButton)
				end

				-- Show find button when the auctions tab is shown
				AuctionFrameAuctions:HookScript("OnShow", function()
					RGXQoLCB["FindAuctionButton"]:SetEnabled(GetAuctionSellItemInfo() and true or false)
				end)

				-- Show find button when a new item is added
				AuctionsItemButton:HookScript("OnEvent", function(self, event)
					if event == "NEW_AUCTION_UPDATE" then
						RGXQoLCB["FindAuctionButton"]:SetEnabled(GetAuctionSellItemInfo() and true or false)
					end
				end)

				RGXQoLCB["FindAuctionButton"]:SetScript("OnClick", function()
					if GetAuctionSellItemInfo() then
						if BrowseWowTokenResults:IsShown() then
							-- Stop if Game Time filter is currently shown
							AuctionFrameTab1:Click()
							RGXQoLLC:Print("To use the Find Item button, you need to deselect the WoW Token category.")
						else
							-- Otherwise, search for the required item
							local name = GetAuctionSellItemInfo()
							BrowseName:SetText(name)
							QueryAuctionItems(name, 0, 0, 0, false, 0, false, true)
							AuctionFrameTab1:Click()
						end
					end
				end)

				-- Clear the cursor and reset editboxes when a new item replaces an existing one
				hooksecurefunc("AuctionsFrameAuctions_ValidateAuction", function()
					if GetAuctionSellItemInfo() then
						-- Return anything you might be holding
						ClearCursor();
						-- Set copper and silver prices to 99 if gold mode is on
						if RGXQoLLC["AhGoldOnly"] == "On" then
							StartPriceCopper:SetText("99")
							StartPriceSilver:SetText("99")
							BuyoutPriceCopper:SetText("99")
							BuyoutPriceSilver:SetText("99")
						end
					end
				end)

				-- Clear gold editbox after an auction has been created (to force user to enter something)
				AuctionsCreateAuctionButton:HookScript("OnClick", function()
					StartPriceGold:SetText("")
					BuyoutPriceGold:SetText("")
				end)

				-- Set tab key actions (if different from defaults)
				StartPriceGold:HookScript("OnTabPressed", function()
					if not IsShiftKeyDown() then
						if RGXQoLLC["AhBuyoutOnly"] == "Off" and RGXQoLLC["AhGoldOnly"] == "On" then
							BuyoutPriceGold:SetFocus()
						end
					end
				end)

				BuyoutPriceGold:HookScript("OnTabPressed", function()
					if IsShiftKeyDown() then
						if RGXQoLLC["AhBuyoutOnly"] == "Off" and RGXQoLLC["AhGoldOnly"] == "On" then
							StartPriceGold:SetFocus()
						end
					end
				end)
			end)

		end

		----------------------------------------------------------------------
		-- Show volume control on character frame
		----------------------------------------------------------------------

		if RGXQoLLC["ShowVolume"] == "On" then

			-- Function to update master volume
			local function MasterVolUpdate()
				if RGXQoLLC["ShowVolume"] == "On" then
					-- Set the volume
					SetCVar("Sound_MasterVolume", RGXQoLLC["LeaPlusMaxVol"]);
					-- Format the slider text
					RGXQoLCB["LeaPlusMaxVol"].f:SetFormattedText("%.0f", RGXQoLLC["LeaPlusMaxVol"] * 20)
				end
			end

			-- Create slider control
			RGXQoLLC["LeaPlusMaxVol"] = tonumber(GetCVar("Sound_MasterVolume"));
			RGXQoLLC:MakeSL(CharacterModelFrame, "LeaPlusMaxVol", "",	0, 1, 0.05, -42, -328, "%.2f")
			RGXQoLCB["LeaPlusMaxVol"]:SetWidth(64)
			RGXQoLCB["LeaPlusMaxVol"].f:ClearAllPoints()
			RGXQoLCB["LeaPlusMaxVol"].f:SetPoint("LEFT", RGXQoLCB["LeaPlusMaxVol"], "RIGHT", 6, 0)

			-- Set slider control value when shown
			RGXQoLCB["LeaPlusMaxVol"]:SetScript("OnShow", function()
				RGXQoLCB["LeaPlusMaxVol"]:SetValue(GetCVar("Sound_MasterVolume"))
			end)

			-- Update volume when slider control is changed
			RGXQoLCB["LeaPlusMaxVol"]:HookScript("OnValueChanged", function()
				if IsMouseButtonDown("RightButton") and IsShiftKeyDown() then
					-- Dual layout is active so don't adjust slider
					RGXQoLCB["LeaPlusMaxVol"].f:SetFormattedText("%.0f", RGXQoLLC["LeaPlusMaxVol"] * 20)
					RGXQoLCB["LeaPlusMaxVol"]:Hide()
					RGXQoLCB["LeaPlusMaxVol"]:Show()
					return
				else
					-- Set sound level and refresh slider
					MasterVolUpdate()
				end
			end)

			-- ElvUI skin for slider control
			if RGXQoLLC.ElvUI then
				_G.LeaPlusGlobalVolumeButton = RGXQoLCB["LeaPlusMaxVol"]
				RGXQoLLC.ElvUI:GetModule("Skins"):HandleSliderFrame(_G.LeaPlusGlobalVolumeButton, false)
			end

		end

		----------------------------------------------------------------------
		--	Use arrow keys in chat
		----------------------------------------------------------------------

		if RGXQoLLC["UseArrowKeysInChat"] == "On" and not RGXQoLLockList["UseArrowKeysInChat"] then
			-- Enable arrow keys for normal and existing chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i .. "EditBox"]:SetAltArrowKeyMode(false)
				end
			end
			-- Enable arrow keys for temporary chat frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf .. "EditBox"]:SetAltArrowKeyMode(false)
				end
			end)
		end

		----------------------------------------------------------------------
		-- L43: Manage widget
		----------------------------------------------------------------------

		if RGXQoLLC["ManageWidget"] == "On" and not RGXQoLLockList["ManageWidget"] then

			-- Create and manage container for UIWidgetTopCenterContainerFrame
			local topCenterHolder = CreateFrame("Frame", nil, UIParent)
			topCenterHolder:SetPoint("TOP", UIParent, "TOP", 0, -15)
			topCenterHolder:SetSize(10, 58)

			local topCenterContainer = _G.UIWidgetTopCenterContainerFrame
			topCenterContainer:ClearAllPoints()
			topCenterContainer:SetPoint('CENTER', topCenterHolder)

			hooksecurefunc(topCenterContainer, 'SetPoint', function(self, void, b)
				if b and (b ~= topCenterHolder) then
					-- Reset parent if it changes from topCenterHolder
					self:ClearAllPoints()
					self:SetPoint('CENTER', topCenterHolder)
					self:SetParent(topCenterHolder)
				end
			end)

			-- Allow widget frame to be moved
			topCenterHolder:SetMovable(true)
			topCenterHolder:SetUserPlaced(true)
			topCenterHolder:SetDontSavePosition(true)
			topCenterHolder:SetClampedToScreen(false)

			-- Set widget frame position at startup
			topCenterHolder:ClearAllPoints()
			topCenterHolder:SetPoint(RGXQoLLC["WidgetA"], UIParent, RGXQoLLC["WidgetR"], RGXQoLLC["WidgetX"], RGXQoLLC["WidgetY"])
			topCenterHolder:SetScale(RGXQoLLC["WidgetScale"])
			UIWidgetTopCenterContainerFrame:SetScale(RGXQoLLC["WidgetScale"])

			-- Create drag frame
			local dragframe = CreateFrame("FRAME", nil, nil, "BackdropTemplate")
			dragframe:SetPoint("CENTER", topCenterHolder, "CENTER", 0, 1)
			dragframe:SetBackdropColor(0.0, 0.5, 1.0)
			dragframe:SetBackdrop({edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0}})
			dragframe:SetToplevel(true)
			dragframe:Hide()
			dragframe:SetScale(RGXQoLLC["WidgetScale"])

			dragframe.t = dragframe:CreateTexture()
			dragframe.t:SetAllPoints()
			dragframe.t:SetColorTexture(0.0, 1.0, 0.0, 0.5)
			dragframe.t:SetAlpha(0.5)

			dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			dragframe.f:SetPoint('CENTER', 0, 0)
			dragframe.f:SetText(L["Widget"])

			-- Click handler
			dragframe:SetScript("OnMouseDown", function(self, btn)
				-- Start dragging if left clicked
				if btn == "LeftButton" then
					topCenterHolder:StartMoving()
				end
			end)

			dragframe:SetScript("OnMouseUp", function()
				-- Save frame position
				topCenterHolder:StopMovingOrSizing()
				RGXQoLLC["WidgetA"], void, RGXQoLLC["WidgetR"], RGXQoLLC["WidgetX"], RGXQoLLC["WidgetY"] = topCenterHolder:GetPoint()
				topCenterHolder:SetMovable(true)
				topCenterHolder:ClearAllPoints()
				topCenterHolder:SetPoint(RGXQoLLC["WidgetA"], UIParent, RGXQoLLC["WidgetR"], RGXQoLLC["WidgetX"], RGXQoLLC["WidgetY"])
			end)

			-- Snap-to-grid
			do
				local frame, grid = dragframe, 10
				local w, h = 0, 60
				local xpos, ypos, scale, uiscale
				frame:RegisterForDrag("RightButton")
				frame:HookScript("OnDragStart", function()
					frame:SetScript("OnUpdate", function()
						scale, uiscale = frame:GetScale(), UIParent:GetScale()
						xpos, ypos = GetCursorPosition()
						xpos = floor((xpos / scale / uiscale) / grid) * grid - w / 2
						ypos = ceil((ypos / scale / uiscale) / grid) * grid + h / 2
						topCenterHolder:ClearAllPoints()
						topCenterHolder:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
					end)
				end)
				frame:HookScript("OnDragStop", function()
					frame:SetScript("OnUpdate", nil)
					frame:GetScript("OnMouseUp")()
				end)
			end

			-- Create configuration panel
			local WidgetPanel = RGXQoLLC:CreatePanel("Manage widget", "WidgetPanel")

			-- Create Titan Panel screen adjust warning
			local titanFrame = CreateFrame("FRAME", nil, WidgetPanel)
			titanFrame:SetAllPoints()
			titanFrame:Hide()
			RGXQoLLC:MakeTx(titanFrame, "Warning", 16, -172)
			titanFrame.txt = RGXQoLLC:MakeWD(titanFrame, "Titan Panel screen adjust needs to be disabled for the frame to be saved correctly.", 16, -192, 500)
			titanFrame.txt:SetWordWrap(false)
			titanFrame.txt:SetWidth(520)
			titanFrame.btn = RGXQoLLC:CreateButton("fixTitanBtn", titanFrame, "Okay, disable screen adjust for me", "TOPLEFT", 16, -212, 0, 25, true, "Click to disable Titan Panel screen adjust.  Your UI will be reloaded.")
			titanFrame.btn:SetScript("OnClick", function()
				TitanPanelSetVar("ScreenAdjust", 1)
				ReloadUI()
			end)

			RGXQoLLC:MakeTx(WidgetPanel, "Scale", 16, -72)
			RGXQoLLC:MakeSL(WidgetPanel, "WidgetScale", "Drag to set the widget scale.", 0.5, 2, 0.05, 16, -92, "%.2f")

			-- Set scale when slider is changed
			RGXQoLCB["WidgetScale"]:HookScript("OnValueChanged", function()
				topCenterHolder:SetScale(RGXQoLLC["WidgetScale"])
				UIWidgetTopCenterContainerFrame:SetScale(RGXQoLLC["WidgetScale"])
				dragframe:SetScale(RGXQoLLC["WidgetScale"])
				-- Show formatted slider value
				RGXQoLCB["WidgetScale"].f:SetFormattedText("%.0f%%", RGXQoLLC["WidgetScale"] * 100)
			end)

			-- Hide frame alignment grid with panel
			WidgetPanel:HookScript("OnHide", function()
				RGXQoLLC.grid:Hide()
			end)

			-- Toggle grid button
			local WidgetToggleGridButton = RGXQoLLC:CreateButton("WidgetToggleGridButton", WidgetPanel, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
			RGXQoLCB["WidgetToggleGridButton"]:ClearAllPoints()
			RGXQoLCB["WidgetToggleGridButton"]:SetPoint("LEFT", WidgetPanel.h, "RIGHT", 10, 0)
			RGXQoLCB["WidgetToggleGridButton"]:SetScript("OnClick", function()
				if RGXQoLLC.grid:IsShown() then RGXQoLLC.grid:Hide() else RGXQoLLC.grid:Show() end
			end)
			WidgetPanel:HookScript("OnHide", function()
				if RGXQoLLC.grid then RGXQoLLC.grid:Hide() end
			end)

			-- Help button tooltip
			WidgetPanel.h.tiptext = L["Drag the frame overlay with the left button to position it freely or with the right button to position it using snap-to-grid."]

			-- Back button handler
			WidgetPanel.b:SetScript("OnClick", function()
				WidgetPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page6"]:Show()
				return
			end)

			-- Reset button handler
			WidgetPanel.r:SetScript("OnClick", function()

				-- Reset position and scale
				RGXQoLLC["WidgetA"] = "TOP"
				RGXQoLLC["WidgetR"] = "TOP"
				RGXQoLLC["WidgetX"] = 0
				RGXQoLLC["WidgetY"] = -15
				RGXQoLLC["WidgetScale"] = 1
				topCenterHolder:ClearAllPoints()
				topCenterHolder:SetPoint(RGXQoLLC["WidgetA"], UIParent, RGXQoLLC["WidgetR"], RGXQoLLC["WidgetX"], RGXQoLLC["WidgetY"])

				-- Refresh configuration panel
				WidgetPanel:Hide(); WidgetPanel:Show()
				dragframe:Show()

				-- Show frame alignment grid
				RGXQoLLC.grid:Show()

			end)

			-- Show configuration panel when options panel button is clicked
			RGXQoLCB["ManageWidgetButton"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["WidgetA"] = "CENTER"
					RGXQoLLC["WidgetR"] = "CENTER"
					RGXQoLLC["WidgetX"] = 0
					RGXQoLLC["WidgetY"] = -160
					RGXQoLLC["WidgetScale"] = 1.25
					topCenterHolder:ClearAllPoints()
					topCenterHolder:SetPoint(RGXQoLLC["WidgetA"], UIParent, RGXQoLLC["WidgetR"], RGXQoLLC["WidgetX"], RGXQoLLC["WidgetY"])
					topCenterHolder:SetScale(RGXQoLLC["WidgetScale"])
					UIWidgetTopCenterContainerFrame:SetScale(RGXQoLLC["WidgetScale"])
				else
					-- Show Titan Panel screen adjust warning if Titan Panel is installed with screen adjust enabled
					if C_AddOns.IsAddOnLoaded("TitanClassic") then
						if TitanPanelSetVar and TitanPanelGetVar then
							if not TitanPanelGetVar("ScreenAdjust") then
								titanFrame:Show()
							end
						end
					end

					-- Find out if the UI has a non-standard scale
					if GetCVar("useuiscale") == "1" then
						RGXQoLLC["gscale"] = GetCVar("uiscale")
					else
						RGXQoLLC["gscale"] = 1
					end

					-- Set drag frame size according to UI scale
					dragframe:SetWidth(160 * RGXQoLLC["gscale"])
					dragframe:SetHeight(79 * RGXQoLLC["gscale"])

					-- Show configuration panel
					WidgetPanel:Show()
					RGXQoLLC:HideFrames()
					dragframe:Show()

					-- Show frame alignment grid
					RGXQoLLC.grid:Show()
				end
			end)

			-- Hide drag frame when configuration panel is closed
			WidgetPanel:HookScript("OnHide", function() dragframe:Hide() end)

		end

		----------------------------------------------------------------------
		-- Hide chat buttons
		----------------------------------------------------------------------

		if RGXQoLLC["NoChatButtons"] == "On" and not RGXQoLLockList["NoChatButtons"] then

			-- Create hidden frame to store unwanted frames (more efficient than creating functions)
			local tframe = CreateFrame("FRAME")
			tframe:Hide()

			-- Function to enable mouse scrolling with CTRL and SHIFT key modifiers
			local function AddMouseScroll(chtfrm)
				if _G[chtfrm] then
					_G[chtfrm]:SetScript("OnMouseWheel", function(self, direction)
						if direction == 1 then
							if IsControlKeyDown() then
								self:ScrollToTop()
							elseif IsShiftKeyDown() then
								self:PageUp()
							else
								self:ScrollUp()
							end
						else
							if IsControlKeyDown() then
								self:ScrollToBottom()
							elseif IsShiftKeyDown() then
								self:PageDown()
							else
								self:ScrollDown()
							end
						end
					end)
					_G[chtfrm]:EnableMouseWheel(true)
				end
			end

			-- Function to hide chat buttons
			local function HideButtons(chtfrm)
				_G[chtfrm .. "ButtonFrameUpButton"]:SetParent(tframe)
				_G[chtfrm .. "ButtonFrameDownButton"]:SetParent(tframe)
				_G[chtfrm .. "ButtonFrameUpButton"]:Hide()
				_G[chtfrm .. "ButtonFrameDownButton"]:Hide()
				_G[chtfrm .. "ButtonFrame"]:SetSize(0.1, 0.1)
				_G[chtfrm .. "MinimizeButton"]:SetParent(tframe)
			end

			FriendsMicroButton:Hide()

			-- Function to highlight chat tabs and click to scroll to bottom
			local function HighlightTabs(chtfrm)

				-- Hide bottom button
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetSize(0.1, 0.1) -- Positions it away

				-- Remove click from the bottom button
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetScript("OnClick", nil)

				-- Remove textures
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetNormalTexture("")
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetHighlightTexture("")
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetPushedTexture("")
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetDisabledTexture("")

				-- Resize bottom button according to tab size
				_G[chtfrm .. "Tab"]:SetScript("OnSizeChanged", function()
					for j = 1, 50 do
						-- Resize bottom button to tab width
						if _G["ChatFrame" .. j .. "ButtonFrameBottomButton"] then
							_G["ChatFrame" .. j .. "ButtonFrameBottomButton"]:SetWidth(_G["ChatFrame" .. j .. "Tab"]:GetWidth()-10)
						end
					end
					-- If combat log is hidden, resize it's bottom button
					if RGXQoLLC["NoCombatLogTab"] == "On" and not RGXQoLLockList["NoCombatLogTab"] then
						if _G["ChatFrame2ButtonFrameBottomButton"] then
							-- Resize combat log bottom button
							_G["ChatFrame2ButtonFrameBottomButton"]:SetWidth(0.1);
						end
					end
				end)

				-- Remove click from the bottom button
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetScript("OnClick", nil)

				-- Remove textures
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetNormalTexture("")
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetHighlightTexture("")
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetPushedTexture("")

				-- Always scroll to bottom when clicking a tab
				_G[chtfrm .. "Tab"]:HookScript("OnClick", function(self,arg1)
					if arg1 == "LeftButton" then
						_G[chtfrm]:ScrollToBottom()
					end
				end)

				-- Create new bottom button under tab
				_G[chtfrm .. "Tab"].newglow = _G[chtfrm .. "Tab"]:CreateTexture(nil, "BACKGROUND")
				_G[chtfrm .. "Tab"].newglow:ClearAllPoints()
				_G[chtfrm .. "Tab"].newglow:SetAllPoints()
				_G[chtfrm .. "Tab"].newglow:SetTexture("Interface\\ChatFrame\\ChatFrameTab-NewMessage")
				_G[chtfrm .. "Tab"].newglow:SetVertexColor(0.6, 0.6, 1, 0.7)
				_G[chtfrm .. "Tab"].newglow:SetBlendMode("ADD")
				_G[chtfrm .. "Tab"].newglow:Hide()

				-- Show new bottom button when old one glows
				_G[chtfrm .. "ButtonFrameBottomButtonFlash"]:HookScript("OnShow", function(self,arg1)
					_G[chtfrm .. "Tab"].newglow:Show()
				end)

				_G[chtfrm .. "ButtonFrameBottomButtonFlash"]:HookScript("OnHide", function(self,arg1)
					_G[chtfrm .. "Tab"].newglow:Hide()
				end)

			end

			-- Hide chat menu buttons
			ChatFrameMenuButton:SetParent(tframe)
			ChatFrameChannelButton:SetParent(tframe)

			-- Set options for normal and existing chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					AddMouseScroll("ChatFrame" .. i)
					HideButtons("ChatFrame" .. i)
					HighlightTabs("ChatFrame" .. i)
				end
			end

			-- Do the functions above for temporary chat frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function(chatType)
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then

					-- Set options for temporary frame
					AddMouseScroll(cf)
					HideButtons(cf)
					HighlightTabs(cf)

					-- Create new bottom button under tab
					_G[cf .. "Tab"].newglow = _G[cf .. "Tab"]:CreateTexture(nil, "BACKGROUND")
					_G[cf .. "Tab"].newglow:ClearAllPoints()
					_G[cf .. "Tab"].newglow:SetAllPoints()
					_G[cf .. "Tab"].newglow:SetTexture("Interface\\ChatFrame\\ChatFrameTab-NewMessage")
					_G[cf .. "Tab"].newglow:SetVertexColor(0.6, 0.6, 1, 1)
					_G[cf .. "Tab"].newglow:SetBlendMode("ADD")
					_G[cf .. "Tab"].newglow:Hide()

					-- Show new bottom button when old one glows
					_G[cf].ScrollToBottomButton.Flash:HookScript("OnShow", function(self,arg1)
						_G[cf .. "Tab"].newglow:Show()
					end)

					_G[cf].ScrollToBottomButton.Flash:HookScript("OnHide", function(self,arg1)
						_G[cf .. "Tab"].newglow:Hide()
					end)

				end
			end)

		end

		----------------------------------------------------------------------
		-- Recent chat window
		----------------------------------------------------------------------

		if RGXQoLLC["RecentChatWindow"] == "On" and not RGXQoLLockList["RecentChatWindow"] then

			-- Create recent chat frame
			local editFrame = CreateFrame("ScrollFrame", nil, UIParent, "RGXQoLRecentChatScrollFrameTemplate")

			-- Set frame parameters
			editFrame:ClearAllPoints()
			editFrame:SetPoint("BOTTOM", 0, 130)
			editFrame:SetSize(600, RGXQoLLC["RecentChatSize"])
			editFrame:SetFrameStrata("MEDIUM")
			editFrame:SetToplevel(true)
			editFrame:Hide()

			-- Add background color
			editFrame.t = editFrame:CreateTexture(nil, "BACKGROUND")
			editFrame.t:SetAllPoints()
			editFrame.t:SetColorTexture(0.00, 0.00, 0.0, 0.6)

			-- Create character count
			editFrame.CharCount = editFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			editFrame.CharCount:Hide()

			-- Create title bar
			local titleFrame = CreateFrame("Frame", nil, editFrame)
			titleFrame:ClearAllPoints()
			titleFrame:SetPoint("TOP", 0, 24)
			titleFrame:SetSize(600, 24)
			titleFrame:SetFrameStrata("MEDIUM")
			titleFrame:SetToplevel(true)
			titleFrame:SetHitRectInsets(-6, -6, -6, -6)
			titleFrame.t = titleFrame:CreateTexture(nil, "BACKGROUND")
			titleFrame.t:SetAllPoints()
			titleFrame.t:SetColorTexture(0.00, 0.00, 0.0, 0.8)

			-- Add message count
			titleFrame.m = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			titleFrame.m:SetPoint("LEFT", 4, 0)
			titleFrame.m:SetText(L["Messages"] .. ": 0")
			titleFrame.m:SetFont(titleFrame.m:GetFont(), 16, nil)

			-- Add right-click to close message
			titleFrame.x = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			titleFrame.x:SetPoint("RIGHT", -4, 0)
			titleFrame.x:SetText(L["Drag to size"] .. " | " .. L["Right-click to close"])
			titleFrame.x:SetFont(titleFrame.x:GetFont(), 16, nil)
			titleFrame.x:SetWidth(600 - titleFrame.m:GetStringWidth() - 30)
			titleFrame.x:SetWordWrap(false)
			titleFrame.x:SetJustifyH("RIGHT")

			-- Drag to resize
			editFrame:SetResizable(true)
			editFrame:SetResizeBounds(600, 170, 600, 560)

			titleFrame:HookScript("OnMouseDown", function(self, btn)
				if btn == "LeftButton" then
					editFrame:StartSizing("TOP")
				end
			end)
			titleFrame:HookScript("OnMouseUp", function(self, btn)
				if btn == "LeftButton" then
					editFrame:StopMovingOrSizing()
					RGXQoLLC["RecentChatSize"] = editFrame:GetHeight()
				elseif btn == "MiddleButton" then
					-- Reset frame size
					RGXQoLLC["RecentChatSize"] = 170
					editFrame:SetSize(600, RGXQoLLC["RecentChatSize"])
					editFrame:ClearAllPoints()
					editFrame:SetPoint("BOTTOM", 0, 130)
				end
			end)

			-- Create editbox
			local editBox = editFrame.EditBox
			editBox:SetAltArrowKeyMode(false)
			editBox:SetTextInsets(4, 4, 4, 4)
			editBox:SetWidth(editFrame:GetWidth() - 30)
			editBox:SetSecurityDisablePaste()
			editBox:SetMaxLetters(0)

			editFrame:SetScrollChild(editBox)

			-- Manage focus
			editBox:HookScript("OnEditFocusLost", function()
				if MouseIsOver(titleFrame) and IsMouseButtonDown("LeftButton") then
					editBox:SetFocus()
				end
			end)

			-- Close frame with right-click of editframe or editbox
			local function CloseRecentChatWindow()
				editBox:SetText("")
				editBox:ClearFocus()
				editFrame:Hide()
			end

			editFrame:SetScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then CloseRecentChatWindow() end
			end)

			editBox:SetScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then CloseRecentChatWindow() end
			end)

			titleFrame:HookScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then CloseRecentChatWindow() end
			end)

			-- Disable text changes while still allowing editing controls to work
			editBox:EnableKeyboard(false)
			editBox:SetScript("OnKeyDown", function() end)

			-- Populate recent chat frame with chat messages
			local function ShowChatbox(chtfrm)
				editBox:SetText("")
				local NumMsg = chtfrm:GetNumMessages()
				local StartMsg = 1
				if NumMsg > 256 then StartMsg = NumMsg - 255 end
				local totalMsgCount = 0
				for iMsg = StartMsg, NumMsg do
					local chatMessage, r, g, b, chatTypeID = chtfrm:GetMessageInfo(iMsg)
					if chatMessage then

						-- Handle Battle.net
						if string.match(chatMessage, "k:(%d+):(%d+):BN_WHISPER:")
						or string.match(chatMessage, "k:(%d+):(%d+):BN_INLINE_TOAST_ALERT:")
						or string.match(chatMessage, "k:(%d+):(%d+):BN_INLINE_TOAST_BROADCAST:")
						then
							local ctype
							if string.match(chatMessage, "k:(%d+):(%d+):BN_WHISPER:") then
								ctype = "BN_WHISPER"
							elseif string.match(chatMessage, "k:(%d+):(%d+):BN_INLINE_TOAST_ALERT:") then
								ctype = "BN_INLINE_TOAST_ALERT"
							elseif string.match(chatMessage, "k:(%d+):(%d+):BN_INLINE_TOAST_BROADCAST:") then
								ctype = "BN_INLINE_TOAST_BROADCAST"
							end
							local id = tonumber(string.match(chatMessage, "k:(%d+):%d+:" .. ctype .. ":"))
							local totalBNFriends = BNGetNumFriends()
							for friendIndex = 1, totalBNFriends do
								local bnetAccountID, void, battleTag = BNGetFriendInfo(friendIndex)
								if id == bnetAccountID then
									battleTag = strsplit("#", battleTag)
									chatMessage = chatMessage:gsub("(|HBNplayer%S-|k)(%d-)(:%S-" .. ctype .. "%S-|h)%[(%S-)%](|?h?)(:?)", "[" .. battleTag .. "]:")
								end
							end
						end

						-- Handle colors
						if r and g and b then
							local colorCode = RGBToColorCode(r, g, b)
							-- chatMessage = string.gsub(chatMessage, "|r", "|r" .. colorCode) -- Needed for Classic only
							chatMessage = colorCode .. chatMessage .. "|r"
						end

						chatMessage = gsub(chatMessage, "|T.-|t", "") -- Remove textures
						chatMessage = gsub(chatMessage, "|A.-|a", "") -- Remove atlases
						editBox:Insert(chatMessage .. "|r|n")

					end
					totalMsgCount = totalMsgCount + 1
				end
				titleFrame.m:SetText(L["Messages"] .. ": " .. totalMsgCount)
				editFrame:SetVerticalScroll(0)
				editFrame.ScrollBar:ScrollToEnd()
				editFrame:Show()
				editBox:ClearFocus()
			end

			-- Hook normal chat frame tab clicks
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i .. "Tab"]:HookScript("OnClick", function()
						if IsControlKeyDown() then
							editBox:SetFont(_G["ChatFrame" .. i]:GetFont())
							editFrame:SetPanExtent(select(2, _G["ChatFrame" .. i]:GetFont()))
							ShowChatbox(_G["ChatFrame" .. i])
						end
					end)
				end
			end

			-- Hook temporary chat frame tab clicks
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf .. "Tab"]:HookScript("OnClick", function()
						if IsControlKeyDown() then
							editBox:SetFont(_G[cf]:GetFont())
							editFrame:SetPanExtent(select(2, _G[cf]:GetFont()))
							ShowChatbox(_G[cf])
						end
					end)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Show cooldowns
		----------------------------------------------------------------------

		if RGXQoLLC["ShowCooldowns"] == "On" then

			-- Create main table structure in saved variables if it doesn't exist
			if RGXQoLDB["Cooldowns"] == nil then
				RGXQoLDB["Cooldowns"] = {}
			end

			-- Create class tables if they don't exist
			local classList = {"WARRIOR", "PALADIN", "HUNTER", "SHAMAN", "ROGUE", "DRUID", "MAGE", "WARLOCK", "PRIEST"}
			for index = 1, #classList do
				if RGXQoLDB["Cooldowns"][classList[index]] == nil then
					RGXQoLDB["Cooldowns"][classList[index]] = {}
				end
			end

			-- Get current class
			local PlayerClass = select(2, UnitClass("player"))
			local activeSpec = 1 -- Fixed to 1 for Classic

			-- Create local tables to store cooldown frames and editboxes
			local icon = {} -- Used to store cooldown frames
			local SpellEB = {} -- Used to store editbox values
			local iCount = 5 -- Number of cooldowns

			-- Create cooldown frames
			for i = 1, iCount do

				-- Create cooldown frame
				icon[i] = CreateFrame("Frame", nil, UIParent)
				icon[i]:SetFrameStrata("BACKGROUND")
				icon[i]:SetWidth(20)
				icon[i]:SetHeight(20)

				-- Create cooldown icon
				icon[i].c = CreateFrame("Cooldown", nil, icon[i], "CooldownFrameTemplate")
				icon[i].c:SetAllPoints()
				icon[i].c:SetReverse(true)

				-- Create blank texture (will be assigned a cooldown texture later)
				icon[i].t = icon[i]:CreateTexture(nil,"BACKGROUND")
				icon[i].t:SetAllPoints()

				-- Show icon above target frame and set initial scale
				icon[i]:ClearAllPoints()
				icon[i]:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 6 + (22 * (i - 1)), 5)
				icon[i]:SetScale(TargetFrame:GetScale())

				-- Show tooltip
				icon[i]:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 15, -25)
					GameTooltip:SetText(GetSpellInfo(RGXQoLCB["Spell" .. i]:GetText()))
				end)

				-- Hide tooltip
				icon[i]:SetScript("OnLeave", GameTooltip_Hide)

			end

			-- Change cooldown icon scale when player frame scale changes
			PlayerFrame:HookScript("OnSizeChanged", function()
				if RGXQoLLC["CooldownsOnPlayer"] == "On" then
					for i = 1, iCount do
						icon[i]:SetScale(PlayerFrame:GetScale())
					end
				end
			end)

			-- Change cooldown icon scale when target frame scale changes
			TargetFrame:HookScript("OnSizeChanged", function()
				if RGXQoLLC["CooldownsOnPlayer"] == "Off" then
					for i = 1, iCount do
						icon[i]:SetScale(TargetFrame:GetScale())
					end
				end
			end)

			-- Function to show cooldown textures in the cooldown frames (run when icons are loaded or changed)
			local function ShowIcon(i, id, owner)

				local void

				-- Get spell information
				local spell, void, path = GetSpellInfo(id)
				if spell and path then

					-- Set icon texture to the spell texture
					icon[i].t:SetTexture(path)

					-- Set top level and raise frame strata (ensures tooltips show properly)
					icon[i]:SetToplevel(true)
					icon[i]:SetFrameStrata("LOW")

					-- Handle events
					icon[i]:RegisterUnitEvent("UNIT_AURA", owner)
					icon[i]:RegisterUnitEvent("UNIT_PET", "player")
					icon[i]:SetScript("OnEvent", function(self, event, arg1)

						-- If pet was dismissed (or otherwise disappears such as when flying), hide pet cooldowns
						if event == "UNIT_PET" then
							if not UnitExists("pet") then
								if RGXQoLDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"] then
									icon[i]:Hide()
								end
							end

						-- Ensure cooldown belongs to the owner we are watching (player or pet)
						elseif arg1 == owner then

							-- Hide the cooldown frame (required for cooldowns to disappear after the duration)
							icon[i]:Hide()

							-- If buff matches cooldown we want, start the cooldown
							for q = 1, 40 do
								local BuffData = C_UnitAuras.GetBuffDataByIndex(owner, q)
								if BuffData then
									local spellID = BuffData.spellId
									local length = BuffData.duration
									local expire = BuffData.expirationTime
									if spellID and id == spellID then
										icon[i]:Show()
										local start = expire - length
										CooldownFrame_Set(icon[i].c, start, length, 1)
									end
								end
							end

						end
					end)

				else

					-- Spell does not exist so stop watching it
					icon[i]:SetScript("OnEvent", nil)
					icon[i]:Hide()

				end

			end

			-- Create configuration panel
			local CooldownPanel = RGXQoLLC:CreatePanel("Show cooldowns", "CooldownPanel")

			-- Function to refresh the editbox tooltip with the spell name
			local function RefSpellTip(self,elapsed)
				local spellinfo, void, icon = GetSpellInfo(self:GetText())
				if spellinfo and spellinfo ~= "" and icon and icon ~= "" then
					GameTooltip:SetOwner(self, "ANCHOR_NONE")
					GameTooltip:ClearAllPoints()
					GameTooltip:SetPoint("RIGHT", self, "LEFT", -10, 0)
					GameTooltip:SetText("|T" .. icon .. ":0|t " .. spellinfo, nil, nil, nil, nil, true)
				else
					GameTooltip:Hide()
				end
			end

			-- Function to create spell ID editboxes and pet checkboxes
			local function MakeSpellEB(num, x, y, tab, shifttab)

				-- Create editbox for spell ID
                SpellEB[num] = RGXQoLLC:CreateEditBox("Spell" .. num, CooldownPanel, 80, 8, "TOPLEFT", x, y - 20, "Spell" .. tab, "Spell" .. shifttab)
				SpellEB[num]:SetNumeric(true)

				-- Set initial value (for current spec)
				SpellEB[num]:SetText(RGXQoLDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. num .. "Idn"] or "")

				-- Refresh tooltip when mouse is hovering over the editbox
				SpellEB[num]:SetScript("OnEnter", function()
					SpellEB[num]:SetScript("OnUpdate", RefSpellTip)
				end)
				SpellEB[num]:SetScript("OnLeave", function()
					SpellEB[num]:SetScript("OnUpdate", nil)
					GameTooltip:Hide()
				end)

				-- Create checkbox for pet cooldown
				RGXQoLLC:MakeCB(CooldownPanel, "Spell" .. num .."Pet", "", 472, y - 20, false, "")
				RGXQoLCB["Spell" .. num .."Pet"]:SetHitRectInsets(0, 0, 0, 0)

			end

			-- Add titles
			RGXQoLLC:MakeTx(CooldownPanel, "Spell ID", 384, -92)
			RGXQoLLC:MakeTx(CooldownPanel, "Pet", 472, -92)

			-- Add editboxes and checkboxes
			MakeSpellEB(1, 386, -92, "2", "5")
			MakeSpellEB(2, 386, -122, "3", "1")
			MakeSpellEB(3, 386, -152, "4", "2")
			MakeSpellEB(4, 386, -182, "5", "3")
			MakeSpellEB(5, 386, -212, "1", "4")

			-- Add checkboxes
			RGXQoLLC:MakeTx(CooldownPanel, "Settings", 16, -72)
			RGXQoLLC:MakeCB(CooldownPanel, "ShowCooldownID", "Show the spell ID in buff icon tooltips", 16, -92, false, "If checked, spell IDs will be shown in buff icon tooltips located in the buff frame and under the target frame.");
			RGXQoLLC:MakeCB(CooldownPanel, "NoCooldownDuration", "Hide cooldown duration numbers (if enabled)", 16, -112, false, "If checked, cooldown duration numbers will not be shown over the cooldowns.|n|nIf unchecked, cooldown duration numbers will be shown over the cooldowns if they are enabled in the game options panel ('ActionBars' menu).")
			RGXQoLLC:MakeCB(CooldownPanel, "CooldownsOnPlayer", "Show cooldowns above the player frame", 16, -132, false, "If checked, cooldown icons will be shown above the player frame instead of the target frame.|n|nIf unchecked, cooldown icons will be shown above the target frame.")

			-- Function to save the panel control settings and refresh the cooldown icons
			local function SavePanelControls()
				for i = 1, iCount do

					-- Refresh the cooldown texture
					icon[i].c:SetCooldown(0,0)

					-- Show icons above target or player frame
					icon[i]:ClearAllPoints()
					if RGXQoLLC["CooldownsOnPlayer"] == "On" then
						icon[i]:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 116 + (22 * (i - 1)), 5)
						icon[i]:SetScale(PlayerFrame:GetScale())
					else
						icon[i]:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 6 + (22 * (i - 1)), 5)
						icon[i]:SetScale(TargetFrame:GetScale())
					end

					-- Save control states to globals
					RGXQoLDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Idn"] = SpellEB[i]:GetText()
					RGXQoLDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"] = RGXQoLCB["Spell" .. i .."Pet"]:GetChecked()

					-- Set cooldowns
					if RGXQoLCB["Spell" .. i .."Pet"]:GetChecked() then
						ShowIcon(i, tonumber(SpellEB[i]:GetText()), "pet")
					else
						ShowIcon(i, tonumber(SpellEB[i]:GetText()), "player")
					end

					-- Show or hide cooldown duration
					if RGXQoLLC["NoCooldownDuration"] == "On" then
						icon[i].c:SetHideCountdownNumbers(true)
					else
						icon[i].c:SetHideCountdownNumbers(false)
					end

					-- Show or hide cooldown icons depending on current buffs
					local newowner
					local newspell = tonumber(SpellEB[i]:GetText())

					if newspell then
						if RGXQoLDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"] then
							newowner = "pet"
						else
							newowner = "player"
						end
						-- Hide cooldown icon
						icon[i]:Hide()

						-- If buff matches spell we want, show cooldown icon
						for q = 1, 40 do
							local BuffData = C_UnitAuras.GetBuffDataByIndex(newowner, q)
							if BuffData then
								local length = BuffData.duration
								local expire = BuffData.expirationTime
								local spellID = BuffData.spellId
								if spellID and newspell == spellID then
									icon[i]:Show()
									-- Set the cooldown to the buff cooldown
									CooldownFrame_Set(icon[i].c, expire - length, length, 1)
								end
							end
						end
					end

				end

			end

			-- Update cooldown icons when checkboxes are clicked
			RGXQoLCB["NoCooldownDuration"]:HookScript("OnClick", SavePanelControls)
			RGXQoLCB["CooldownsOnPlayer"]:HookScript("OnClick", SavePanelControls)

			-- Help button hidden
			CooldownPanel.h:Hide()

			-- Back button handler
			CooldownPanel.b:SetScript("OnClick", function()
				CooldownPanel:Hide(); RGXQoLLC["PageF"]:Show(); RGXQoLLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			CooldownPanel.r:SetScript("OnClick", function()
				-- Reset the checkboxes
				RGXQoLLC["ShowCooldownID"] = "On"
				RGXQoLLC["NoCooldownDuration"] = "On"
				RGXQoLLC["CooldownsOnPlayer"] = "Off"
				for i = 1, iCount do
					-- Reset the panel controls
					SpellEB[i]:SetText("");
					RGXQoLDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"] = false
					-- Hide cooldowns and clear scripts
					icon[i]:Hide()
					icon[i]:SetScript("OnEvent", nil)
				end
				CooldownPanel:Hide(); CooldownPanel:Show()
			end)

			-- Save settings when changed
			for i = 1, iCount do
				-- Set initial checkbox states
				RGXQoLCB["Spell" .. i .."Pet"]:SetChecked(RGXQoLDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"])
				-- Set checkbox states when shown
				RGXQoLCB["Spell" .. i .."Pet"]:SetScript("OnShow", function()
					RGXQoLCB["Spell" .. i .."Pet"]:SetChecked(RGXQoLDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"])
				end)
				-- Set states when changed
				SpellEB[i]:SetScript("OnTextChanged", SavePanelControls)
				RGXQoLCB["Spell" .. i .."Pet"]:SetScript("OnClick", SavePanelControls)
			end

			-- Show cooldowns on startup
			SavePanelControls()

			-- Show panel when configuration button is clicked
			RGXQoLCB["CooldownsButton"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- No preset profile
				else
					-- Show panel
					CooldownPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

			-- Create class tag banner fontstring
			local classTagBanner = CooldownPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			local myClassName = UnitClass("player")
			classTagBanner:SetPoint("TOPLEFT", 384, -72)
			classTagBanner:SetText(myClassName)

			-- Add help button
			RGXQoLLC:CreateHelpButton("ShowCooldownsHelpButton", CooldownPanel, classTagBanner, "Enter the spell IDs for the cooldown icons that you want to see.|n|nIf a cooldown icon normally appears under the pet frame, check the pet checkbox.|n|nCooldown icons are saved to your class.")

			-- Function to show spell ID in tooltips
			local function CooldownIDFunc(unit, target, index, auratype)
				if RGXQoLLC["ShowCooldownID"] == "On" and auratype ~= "HARMFUL" then
					local AuraData = C_UnitAuras.GetAuraDataByIndex(target, index)
					if AuraData then
						local spellid = AuraData.spellId
						if spellid then
							GameTooltip:AddLine(L["Spell ID"] .. ": " .. spellid)
							GameTooltip:Show()
						end
					end
				end
			end

			-- Add spell ID to tooltip when buff frame buffs are hovered
			hooksecurefunc(GameTooltip, 'SetUnitAura', CooldownIDFunc)

			-- Add spell ID to tooltip when target frame buffs are hovered
			hooksecurefunc(GameTooltip, 'SetUnitBuff', CooldownIDFunc)

		end

		----------------------------------------------------------------------
		-- Combat plates
		----------------------------------------------------------------------

		if RGXQoLLC["CombatPlates"] == "On" then

			-- Toggle nameplates with combat
			local f = CreateFrame("Frame")
			f:RegisterEvent("PLAYER_REGEN_DISABLED")
			f:RegisterEvent("PLAYER_REGEN_ENABLED")
			f:SetScript("OnEvent", function(self, event)
				SetCVar("nameplateShowEnemies", event == "PLAYER_REGEN_DISABLED" and 1 or 0)
			end)

			-- Run combat check on startup
			SetCVar("nameplateShowEnemies", UnitAffectingCombat("player") and 1 or 0)

		end

		----------------------------------------------------------------------
		-- Enhance tooltip
		----------------------------------------------------------------------

		if RGXQoLLC["TipModEnable"] == "On" and not RGXQoLLockList["TipModEnable"] then

			-- Enable mouse hover events for world frame (required for hide tooltips, cursor anchor and maybe other addons)
			WorldFrame:EnableMouseMotion(true) -- RGXQoLLC.NewPatch: Using GetMouseFoci()[1] for now

			----------------------------------------------------------------------
			--	Position the tooltip
			----------------------------------------------------------------------

			hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
				if RGXQoLLC["TooltipAnchorMenu"] ~= 1 then
					if (not tooltip or not parent) then
						return
					end
					if RGXQoLLC["TooltipAnchorMenu"] == 2 or not WorldFrame:IsMouseMotionFocus() then
						local a,b,c,d,e = tooltip:GetPoint()
						if a ~= "BOTTOMRIGHT" or c ~= "BOTTOMRIGHT" then
							tooltip:ClearAllPoints()
						end
						tooltip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", RGXQoLLC["TipOffsetX"], RGXQoLLC["TipOffsetY"]);
						return
					else
						if RGXQoLLC["TooltipAnchorMenu"] == 3 then
							tooltip:SetOwner(parent, "ANCHOR_CURSOR")
							return
						elseif RGXQoLLC["TooltipAnchorMenu"] == 4 then
							tooltip:SetOwner(parent, "ANCHOR_CURSOR_LEFT", RGXQoLLC["TipCursorX"], RGXQoLLC["TipCursorY"])
							return
						elseif RGXQoLLC["TooltipAnchorMenu"] == 5 then
							tooltip:SetOwner(parent, "ANCHOR_CURSOR_RIGHT", RGXQoLLC["TipCursorX"], RGXQoLLC["TipCursorY"])
							return
						end
					end
				end
			end)

			----------------------------------------------------------------------
			--	Tooltip Configuration
			----------------------------------------------------------------------

			local LT = {}

			-- Create locale specific level string
			LT["LevelLocale"] = strtrim(strtrim(string.gsub(TOOLTIP_UNIT_LEVEL, "%%s", "")))
			if GameLocale == "ruRU" then
				LT["LevelLocale"] = "-ro ??????"
			end

			-- Tooltip
			LT["ColorBlind"] = GetCVar("colorblindMode")

			-- 	Create drag frame
			local TipDrag = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
			TipDrag:SetToplevel(true);
			TipDrag:SetClampedToScreen(false);
			TipDrag:SetSize(130, 64);
			TipDrag:Hide();
			TipDrag:SetFrameStrata("TOOLTIP")
			TipDrag:SetMovable(true)
			TipDrag:SetBackdropColor(0.0, 0.5, 1.0);
			TipDrag:SetBackdrop({
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 16,
				insets = { left = 0, right = 0, top = 0, bottom = 0 }});

			-- Show text in drag frame
			TipDrag.f = TipDrag:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			TipDrag.f:SetPoint("CENTER", 0, 0)
			TipDrag.f:SetText(L["Tooltip"])

			-- Create texture
			TipDrag.t = TipDrag:CreateTexture();
			TipDrag.t:SetAllPoints();
			TipDrag.t:SetColorTexture(0.0, 0.5, 1.0, 0.5);
			TipDrag.t:SetAlpha(0.5);

			---------------------------------------------------------------------------------------------------------
			-- Tooltip movement settings
			---------------------------------------------------------------------------------------------------------

			-- Create tooltip customisation side panel
			local SideTip = RGXQoLLC:CreatePanel("Enhance tooltip", "SideTip")

			-- Add controls
			RGXQoLLC:MakeTx(SideTip, "Settings", 16, -72)
			RGXQoLLC:MakeCB(SideTip, "TipShowRank", "Show guild ranks for your guild", 16, -92, false, "If checked, guild ranks will be shown for players in your guild.")
			RGXQoLLC:MakeCB(SideTip, "TipShowOtherRank", "Show guild ranks for other guilds", 16, -112, false, "If checked, guild ranks will be shown for players who are not in your guild.")
			RGXQoLLC:MakeCB(SideTip, "TipShowTarget", "Show unit targets", 16, -132, false, "If checked, unit targets will be shown.")
			RGXQoLLC:MakeCB(SideTip, "TipNoHealthBar", "Hide the health bar", 16, -152, true, "If checked, the health bar will not be shown.")

			RGXQoLLC:MakeTx(SideTip, "Hide tooltips", 16, -192)
			RGXQoLLC:MakeCB(SideTip, "TipHideInCombat", "Hide tooltips for world units during combat", 16, -212, false, "If checked, tooltips for world units will be hidden during combat.")
			RGXQoLLC:MakeCB(SideTip, "TipHideShiftOverride", "Show tooltips with shift key", 16, -232, false, "If checked, you can hold shift while tooltips are hidden to show them temporarily.")

			-- Handle show tooltips with shift key lock
			local function SetTipHideShiftOverrideFunc()
				if RGXQoLLC["TipHideInCombat"] == "On" then
					RGXQoLLC:LockItem(RGXQoLCB["TipHideShiftOverride"], false)
				else
					RGXQoLLC:LockItem(RGXQoLCB["TipHideShiftOverride"], true)
				end
			end

			RGXQoLCB["TipHideInCombat"]:HookScript("OnClick", SetTipHideShiftOverrideFunc)
			SetTipHideShiftOverrideFunc()

			RGXQoLLC:CreateDropdown("TooltipAnchorMenu", "Anchor", 146, "TOPLEFT", SideTip, "TOPLEFT", 356, -92, {{L["None"], 1}, {L["Overlay"], 2}, {L["Cursor"], 3}, {L["Cursor Left"], 4}, {L["Cursor Right"], 5}})

			local XOffsetHeading = RGXQoLLC:MakeTx(SideTip, "X Offset", 356, -132)
			RGXQoLLC:MakeSL(SideTip, "TipCursorX", "Drag to set the cursor X offset.", -128, 128, 1, 356, -152, "%.0f")

			local YOffsetHeading = RGXQoLLC:MakeTx(SideTip, "Y Offset", 356, -182)
			RGXQoLLC:MakeSL(SideTip, "TipCursorY", "Drag to set the cursor Y offset.", -128, 128, 1, 356, -202, "%.0f")

			RGXQoLLC:MakeTx(SideTip, "Scale", 356, -232)
			RGXQoLLC:MakeSL(SideTip, "LeaPlusTipSize", "Drag to set the tooltip scale.", 0.50, 2.00, 0.05, 356, -252, "%.2f")

			-- Function to enable or disable anchor controls
			local function SetAnchorControls()
				-- Hide overlay if anchor is set to none
				if RGXQoLLC["TooltipAnchorMenu"] == 1 then
					TipDrag:Hide()
				else
					TipDrag:Show()
				end
				-- Set the X and Y sliders
				if RGXQoLLC["TooltipAnchorMenu"] == 1 or RGXQoLLC["TooltipAnchorMenu"] == 2 or RGXQoLLC["TooltipAnchorMenu"] == 3 then
					-- Dropdown is set to screen or cursor so disable X and Y offset sliders
					RGXQoLLC:LockItem(RGXQoLCB["TipCursorX"], true)
					RGXQoLLC:LockItem(RGXQoLCB["TipCursorY"], true)
					XOffsetHeading:SetAlpha(0.3)
					YOffsetHeading:SetAlpha(0.3)
					RGXQoLCB["TipCursorX"]:SetScript("OnEnter", nil)
					RGXQoLCB["TipCursorY"]:SetScript("OnEnter", nil)
				else
					-- Dropdown is set to cursor left or cursor right so enable X and Y offset sliders
					RGXQoLLC:LockItem(RGXQoLCB["TipCursorX"], false)
					RGXQoLLC:LockItem(RGXQoLCB["TipCursorY"], false)
					XOffsetHeading:SetAlpha(1.0)
					YOffsetHeading:SetAlpha(1.0)
					RGXQoLCB["TipCursorX"]:SetScript("OnEnter", RGXQoLLC.TipSee)
					RGXQoLCB["TipCursorY"]:SetScript("OnEnter", RGXQoLLC.TipSee)
				end
			end

			-- Set controls when anchor dropdown menu is changed and on startup
			RGXQoLCB["TooltipAnchorMenu"]:RegisterCallback("OnMenuClose", SetAnchorControls)
			SetAnchorControls()

			---------------------------------------------------------------------------------------------------------
			-- Rest of configuration panel
			---------------------------------------------------------------------------------------------------------

			-- Help button hidden
			SideTip.h:Hide()

			-- Back button handler
			SideTip.b:SetScript("OnClick", function()
				SideTip:Hide();
				if TipDrag:IsShown() then
					TipDrag:Hide();
				end
				RGXQoLLC["PageF"]:Show();
				RGXQoLLC["Page5"]:Show();
				return
			end)

			-- Reset button handler
			SideTip.r.tiptext = SideTip.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
			SideTip.r:SetScript("OnClick", function()
				RGXQoLLC["TipShowRank"] = "On"
				RGXQoLLC["TipShowOtherRank"] = "Off"
				RGXQoLLC["TipShowTarget"] = "On"
				RGXQoLLC["TipHideInCombat"] = "Off"; SetTipHideShiftOverrideFunc()
				RGXQoLLC["TipHideShiftOverride"] = "On"
				RGXQoLLC["LeaPlusTipSize"] = 1.00
				RGXQoLLC["TipOffsetX"] = -13
				RGXQoLLC["TipOffsetY"] = 94
				RGXQoLLC["TooltipAnchorMenu"] = 1
				RGXQoLLC["TipCursorX"] = 0
				RGXQoLLC["TipCursorY"] = 0
				TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", RGXQoLLC["TipOffsetX"], RGXQoLLC["TipOffsetY"]);
				SetAnchorControls()
				RGXQoLLC:SetTipScale()
				SideTip:Hide(); SideTip:Show();
			end)

			-- Show drag frame with configuration panel if anchor is not set to none
			SideTip:HookScript("OnShow", function()
				if RGXQoLLC["TooltipAnchorMenu"] == 1 then
					TipDrag:Hide()
				else
					TipDrag:Show()
				end
			end)
			SideTip:HookScript("OnHide", function() TipDrag:Hide() end)

			-- Control movement functions
			local void, LTax, LTay, LTbx, LTby, LTcx, LTcy
			TipDrag:SetScript("OnMouseDown", function(self, btn)
				if btn == "LeftButton" then
					void, void, void, LTax, LTay = TipDrag:GetPoint()
					TipDrag:StartMoving()
					void, void, void, LTbx, LTby = TipDrag:GetPoint()
				end
			end)
			TipDrag:SetScript("OnMouseUp", function(self, btn)
				if btn == "LeftButton" then
					void, void, void, LTcx, LTcy = TipDrag:GetPoint()
					TipDrag:StopMovingOrSizing();
					RGXQoLLC["TipOffsetX"], RGXQoLLC["TipOffsetY"] = LTcx - LTbx + LTax, LTcy - LTby + LTay
					TipDrag:ClearAllPoints()
					TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", RGXQoLLC["TipOffsetX"], RGXQoLLC["TipOffsetY"])
				end
			end)

			--	Move the tooltip
			RGXQoLCB["MoveTooltipButton"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["TipShowRank"] = "On"
					RGXQoLLC["TipShowOtherRank"] = "Off"
					RGXQoLLC["TipShowTarget"] = "On"
					RGXQoLLC["TipHideInCombat"] = "Off"; SetTipHideShiftOverrideFunc()
					RGXQoLLC["TipHideShiftOverride"] = "On"
					RGXQoLLC["LeaPlusTipSize"] = 1.25
					RGXQoLLC["TipOffsetX"] = -13
					RGXQoLLC["TipOffsetY"] = 94
					RGXQoLLC["TooltipAnchorMenu"] = 2
					RGXQoLLC["TipCursorX"] = 0
					RGXQoLLC["TipCursorY"] = 0
					TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", RGXQoLLC["TipOffsetX"], RGXQoLLC["TipOffsetY"]);
					SetAnchorControls()
					RGXQoLLC:SetTipScale()
					RGXQoLLC:SetDim();
					RGXQoLLC:ReloadCheck()
					SideTip:Show(); SideTip:Hide(); -- Needed to update tooltip scale
					RGXQoLLC["PageF"]:Hide(); RGXQoLLC["PageF"]:Show()
				else
					-- Show tooltip configuration panel
					RGXQoLLC:HideFrames()
					SideTip:Show()

					-- Set scale
					TipDrag:SetScale(RGXQoLLC["LeaPlusTipSize"])

					-- Set position of the drag frame
					TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", RGXQoLLC["TipOffsetX"], RGXQoLLC["TipOffsetY"])
				end

			end)

			-- Hide health bar
			if RGXQoLLC["TipNoHealthBar"] == "On" then
				local tipHide = GameTooltip.Hide
				GameTooltipStatusBar:HookScript("OnShow", tipHide)
				GameTooltipStatusBar:Hide()
			end

			---------------------------------------------------------------------------------------------------------
			-- Tooltip scale settings
			---------------------------------------------------------------------------------------------------------

			-- Function to set the tooltip scale
			local function SetTipScale()

				-- General tooltip
				if GameTooltip then GameTooltip:SetScale(RGXQoLLC["LeaPlusTipSize"]) end

				-- Friends
				if FriendsTooltip then FriendsTooltip:SetScale(RGXQoLLC["LeaPlusTipSize"]) end

				-- AutoCompleteBox
				if AutoCompleteBox then AutoCompleteBox:SetScale(RGXQoLLC["LeaPlusTipSize"]) end

				-- Items (links, comparisons)
				if ItemRefTooltip then ItemRefTooltip:SetScale(RGXQoLLC["LeaPlusTipSize"]) end
				if ItemRefShoppingTooltip1 then ItemRefShoppingTooltip1:SetScale(RGXQoLLC["LeaPlusTipSize"]) end
				if ItemRefShoppingTooltip2 then ItemRefShoppingTooltip2:SetScale(RGXQoLLC["LeaPlusTipSize"]) end
				if ShoppingTooltip1 then ShoppingTooltip1:SetScale(RGXQoLLC["LeaPlusTipSize"]) end
				if ShoppingTooltip2 then ShoppingTooltip2:SetScale(RGXQoLLC["LeaPlusTipSize"]) end

				-- Embedded item tooltip (as used in PVP UI)
				if EmbeddedItemTooltip then EmbeddedItemTooltip:SetScale(RGXQoLLC["LeaPlusTipSize"]) end

				-- Nameplate tooltip
				if NamePlateTooltip then NamePlateTooltip:SetScale(RGXQoLLC["LeaPlusTipSize"]) end

				-- LibDBIcon
				if LibDBIconTooltip then LibDBIconTooltip:SetScale(RGXQoLLC["LeaPlusTipSize"]) end

				-- Total RP 3
				if C_AddOns.IsAddOnLoaded("totalRP3") and TRP3_MainTooltip and TRP3_CharacterTooltip then
					TRP3_MainTooltip:SetScale(RGXQoLLC["LeaPlusTipSize"])
					TRP3_CharacterTooltip:SetScale(RGXQoLLC["LeaPlusTipSize"])
				end

				-- Altoholic
				if AltoTooltip then
					AltoTooltip:SetScale(RGXQoLLC["LeaPlusTipSize"])
				end

				-- Leatrix Plus
				TipDrag:SetScale(RGXQoLLC["LeaPlusTipSize"])

				-- Set slider formatted text
				RGXQoLCB["LeaPlusTipSize"].f:SetFormattedText("%.0f%%", RGXQoLLC["LeaPlusTipSize"] * 100)

			end

			-- Give function a file level scope
			RGXQoLLC.SetTipScale = SetTipScale

			-- Set tooltip scale when slider or checkbox changes and on startup
			RGXQoLCB["LeaPlusTipSize"]:HookScript("OnValueChanged", SetTipScale)
			SetTipScale()

			----------------------------------------------------------------------
			-- Blizzard Settings tooltip
			----------------------------------------------------------------------

			-- Set tooltip scale when tooltip is shown
			SettingsTooltip:HookScript("OnShow", function()
				SettingsTooltip:SetScale(RGXQoLLC["LeaPlusTipSize"] * UIParent:GetScale())
			end)

			---------------------------------------------------------------------------------------------------------
			-- Other tooltip code
			---------------------------------------------------------------------------------------------------------

			-- Colorblind setting change
			TipDrag:RegisterEvent("CVAR_UPDATE");
			TipDrag:SetScript("OnEvent", function(self, event, arg1, arg2)
				if (arg1 == "USE_COLORBLIND_MODE") then
					LT["ColorBlind"] = arg2;
				end
			end)

			-- Store locals
			local TipMClass = LOCALIZED_CLASS_NAMES_MALE
			local TipFClass = LOCALIZED_CLASS_NAMES_FEMALE

			-- Level string
			local LevelString, LevelString2
			if GameLocale == "ruRU" then
				-- Level string for ruRU
				LevelString = "??????"
				LevelString2 = "???????"
			else
				-- Level string for all other locales
				LevelString = string.lower(TOOLTIP_UNIT_LEVEL:gsub("%%s",".+"))
				LevelString2 = ""
			end

			-- Tag locale (code construction from tiplang)
			local ttYou, ttLevel, ttBoss, ttElite, ttRare, ttRareElite, ttRareBoss, ttTarget
			if 		GameLocale == "zhCN" then 	ttYou = "?"		; ttLevel = "??"		; ttBoss = "??"	; ttElite = "??"	; ttRare = "??"	; ttRareElite = "?? ??"		; ttRareBoss = "?? ??"		; ttTarget = "??"
			elseif 	GameLocale == "zhTW" then 	ttYou = "?"		; ttLevel = "??"		; ttBoss = "??"	; ttElite = "??"	; ttRare = "??"	; ttRareElite = "?? ??"		; ttRareBoss = "?? ??"		; ttTarget = "??"
			elseif 	GameLocale == "ruRU" then 	ttYou = "??"	; ttLevel = "???????"	; ttBoss = "????"	; ttElite = "?????"	; ttRare = "??????"	; ttRareElite = "?????? ?????"	; ttRareBoss = "?????? ????"	; ttTarget = "????"
			elseif 	GameLocale == "koKR" then 	ttYou = "??"	; ttLevel = "??"		; ttBoss = "????"	; ttElite = "??"	; ttRare = "??"	; ttRareElite = "?? ??"		; ttRareBoss = "?? ????"		; ttTarget = "??"
			elseif 	GameLocale == "esMX" then 	ttYou = "T�"	; ttLevel = "Nivel"		; ttBoss = "Jefe"	; ttElite = "�lite"	; ttRare = "Raro"	; ttRareElite = "Raro �lite"	; ttRareBoss = "Raro Jefe"		; ttTarget = "Objetivo"
			elseif 	GameLocale == "ptBR" then 	ttYou = "VOC�"	; ttLevel = "N�vel"		; ttBoss = "Chefe"	; ttElite = "Elite"	; ttRare = "Raro"	; ttRareElite = "Raro Elite"	; ttRareBoss = "Raro Chefe"		; ttTarget = "Alvo"
			elseif 	GameLocale == "deDE" then 	ttYou = "SIE"	; ttLevel = "Stufe"		; ttBoss = "Boss"	; ttElite = "Elite"	; ttRare = "Selten"	; ttRareElite = "Selten Elite"	; ttRareBoss = "Selten Boss"	; ttTarget = "Ziel"
			elseif 	GameLocale == "esES" then	ttYou = "T�"	; ttLevel = "Nivel"		; ttBoss = "Jefe"	; ttElite = "�lite"	; ttRare = "Raro"	; ttRareElite = "Raro �lite"	; ttRareBoss = "Raro Jefe"		; ttTarget = "Objetivo"
			elseif 	GameLocale == "frFR" then 	ttYou = "TOI"	; ttLevel = "Niveau"	; ttBoss = "Boss"	; ttElite = "�lite"	; ttRare = "Rare"	; ttRareElite = "Rare �lite"	; ttRareBoss = "Rare Boss"		; ttTarget = "Cible"
			elseif 	GameLocale == "itIT" then 	ttYou = "TU"	; ttLevel = "Livello"	; ttBoss = "Boss"	; ttElite = "�lite"	; ttRare = "Raro"	; ttRareElite = "Raro �lite"	; ttRareBoss = "Raro Boss"		; ttTarget = "Bersaglio"
			else 								ttYou = "YOU"	; ttLevel = "Level"		; ttBoss = "Boss"	; ttElite = "Elite"	; ttRare = "Rare"	; ttRareElite = "Rare Elite"	; ttRareBoss = "Rare Boss"		; ttTarget = "Target"
			end

			-- Show tooltip
			local function ShowTip()

				-- Do nothing if CTRL, SHIFT and ALT are being held
				if IsControlKeyDown() and IsAltKeyDown() and IsShiftKeyDown() then
					return
				end

				-- Get unit information
				if WorldFrame:IsMouseMotionFocus() then
					LT["Unit"] = "mouseover"
					-- Hide and quit if tips should be hidden during combat
					if RGXQoLLC["TipHideInCombat"] == "On" and UnitAffectingCombat("player") then
						if not IsShiftKeyDown() or RGXQoLLC["TipHideShiftOverride"] == "Off" then
							GameTooltip:Hide()
							return
						end
					end
				else
					LT["Unit"] = select(2, GameTooltip:GetUnit())
					if not (LT["Unit"]) then return end
				end

				-- Quit if unit has no reaction to player
				LT["Reaction"] = UnitReaction(LT["Unit"], "player") or nil
				if not LT["Reaction"] then
					return
				end

				-- Setup variables
				LT["TipUnitName"], LT["TipUnitRealm"] = UnitName(LT["Unit"])
				LT["TipIsPlayer"] = UnitIsPlayer(LT["Unit"])
				LT["UnitLevel"] = UnitLevel(LT["Unit"])
				LT["UnitClass"] = UnitClassBase(LT["Unit"])
				LT["PlayerControl"] = UnitPlayerControlled(LT["Unit"])
				LT["PlayerRace"] = UnitRace(LT["Unit"])

				-- Get colorblind information
				if LT["TipIsPlayer"] then
					if LT["ColorBlind"] == "1" then
						LT["InfoLine"] = 3
					else
						LT["InfoLine"] = 2
					end
					-- Lower information line if unit is charmed
					if UnitIsCharmed(LT["Unit"]) then
						LT["InfoLine"] = LT["InfoLine"] + 1
					end
				end

				-- Determine class color
				if LT["UnitClass"] then
					-- Define male or female (for certain locales)
					LT["Sex"] = UnitSex(LT["Unit"])
					if LT["Sex"] == 2 then
						LT["Class"] = TipMClass[LT["UnitClass"]]
					else
						LT["Class"] = TipFClass[LT["UnitClass"]]
					end
					-- Define class color
					LT["ClassCol"] = RGXQoLLC["RaidColors"][LT["UnitClass"]]
					LT["LpTipClassColor"] = "|cff" .. string.format("%02x%02x%02x", LT["ClassCol"].r * 255, LT["ClassCol"].g * 255, LT["ClassCol"].b * 255)
				end

				----------------------------------------------------------------------
				-- Name line
				----------------------------------------------------------------------

				if ((LT["TipIsPlayer"]) or (LT["PlayerControl"])) or LT["Reaction"] > 4 then

					-- If it's a player show name in class color
					if LT["TipIsPlayer"] then
						LT["NameColor"] = LT["LpTipClassColor"]
					else
						-- If not, set to green or blue depending on PvP status
						if UnitIsPVP(LT["Unit"]) then
							LT["NameColor"] = "|cff00ff00"
						else
							LT["NameColor"] = "|cff00aaff"
						end
					end

					-- Show name
					LT["NameText"] = UnitPVPName(LT["Unit"]) or LT["TipUnitName"]

					-- Show realm
					if LT["TipUnitRealm"] then
						LT["NameText"] = LT["NameText"] .. " - " .. LT["TipUnitRealm"]
					end

					-- Show dead units in grey
					if UnitIsDeadOrGhost(LT["Unit"]) then
						LT["NameColor"] = "|c88888888"
					end

					-- Show name line
					_G["GameTooltipTextLeft1"]:SetText(LT["NameColor"] .. LT["NameText"] .. "|cffffffff|r")

				elseif UnitIsDeadOrGhost(LT["Unit"]) then

					-- Show grey name for other dead units
					_G["GameTooltipTextLeft1"]:SetText("|c88888888" .. (_G["GameTooltipTextLeft1"]:GetText() or "") .. "|cffffffff|r")
					return

				end

				----------------------------------------------------------------------
				-- Information line (level, class, race)
				----------------------------------------------------------------------

				if LT["TipIsPlayer"] then

					if GameLocale == "ruRU" then

						LT["InfoText"] = ""

						-- Show race
						if LT["PlayerRace"] then
							LT["InfoText"] = LT["InfoText"] .. LT["PlayerRace"] .. ","
						end

						-- Show class
						LT["InfoText"] = LT["InfoText"] .. " " .. LT["LpTipClassColor"] .. LT["Class"] .. "|r " or LT["InfoText"] .. "|r "

						-- Show level
						if LT["Reaction"] < 5 then
							if LT["UnitLevel"] == -1 then
								LT["InfoText"] = LT["InfoText"] .. ("|cffff3333" .. "??-ro" .. " " .. ttLevel .. "|cffffffff")
							else
								LT["LevelColor"] = GetCreatureDifficultyColor(LT["UnitLevel"])
								LT["LevelColor"] = string.format('%02x%02x%02x', LT["LevelColor"].r * 255, LT["LevelColor"].g * 255, LT["LevelColor"].b * 255)
								LT["InfoText"] = LT["InfoText"] .. ("|cff" .. LT["LevelColor"] .. LT["UnitLevel"] .. LT["LevelLocale"] .. "|cffffffff")
							end
						else
							LT["InfoText"] = LT["InfoText"] .. LT["UnitLevel"] .. LT["LevelLocale"]
						end

						-- Show information line
						_G["GameTooltipTextLeft" .. LT["InfoLine"]]:SetText(LT["InfoText"] .. "|cffffffff|r")

					else

						-- Show level
						if LT["Reaction"] < 5 then
							if LT["UnitLevel"] == -1 then
								LT["InfoText"] = ("|cffff3333" .. ttLevel .. " ??|cffffffff")
							else
								LT["LevelColor"] = GetCreatureDifficultyColor(LT["UnitLevel"])
								LT["LevelColor"] = string.format('%02x%02x%02x', LT["LevelColor"].r * 255, LT["LevelColor"].g * 255, LT["LevelColor"].b * 255)
								LT["InfoText"] = ("|cff" .. LT["LevelColor"] .. LT["LevelLocale"] .. " " .. LT["UnitLevel"] .. "|cffffffff")
							end
						else
							LT["InfoText"] = LT["LevelLocale"] .. " " .. LT["UnitLevel"]
						end

						-- Show race
						if LT["PlayerRace"] then
							LT["InfoText"] = LT["InfoText"] .. " " .. LT["PlayerRace"]
						end

						-- Show class
						LT["InfoText"] = LT["InfoText"] .. " " .. LT["LpTipClassColor"] .. LT["Class"] or LT["InfoText"]

						-- Show information line
						_G["GameTooltipTextLeft" .. LT["InfoLine"]]:SetText(LT["InfoText"] .. "|cffffffff|r")

					end

				end

				----------------------------------------------------------------------
				-- Mob name in brighter red (alive) and steel blue (tap denied)
				----------------------------------------------------------------------

				if not (LT["TipIsPlayer"]) and LT["Reaction"] < 4 and not (LT["PlayerControl"]) then
					if UnitIsTapDenied(LT["Unit"]) then
						LT["NameText"] = "|c8888bbbb" .. LT["TipUnitName"] .. "|r"
					else
						LT["NameText"] = "|cffff3333" .. LT["TipUnitName"] .. "|r"
					end
					_G["GameTooltipTextLeft1"]:SetText(LT["NameText"])
				end

				----------------------------------------------------------------------
				-- Mob level in color (neutral or lower)
				----------------------------------------------------------------------

				if UnitCanAttack(LT["Unit"], "player") and not (LT["TipIsPlayer"]) and LT["Reaction"] < 5 and not (LT["PlayerControl"]) then

					-- Find the level line
					LT["MobInfoLine"] = 0
					local line2, line3, line4
					if _G["GameTooltipTextLeft2"] then line2 = _G["GameTooltipTextLeft2"]:GetText() end
					if _G["GameTooltipTextLeft3"] then line3 = _G["GameTooltipTextLeft3"]:GetText() end
					if _G["GameTooltipTextLeft4"] then line4 = _G["GameTooltipTextLeft4"]:GetText() end
					if GameLocale == "ruRU" then -- Additional check for ruRU
						if line2 and string.lower(line2):find(LevelString2) then LT["MobInfoLine"] = 2 end
						if line3 and string.lower(line3):find(LevelString2) then LT["MobInfoLine"] = 3 end
						if line4 and string.lower(line4):find(LevelString2) then LT["MobInfoLine"] = 4 end
					end
					if line2 and string.lower(line2):find(LevelString) then LT["MobInfoLine"] = 2 end
					if line3 and string.lower(line3):find(LevelString) then LT["MobInfoLine"] = 3 end
					if line4 and string.lower(line4):find(LevelString) then LT["MobInfoLine"] = 4 end

					-- Show level line
					if LT["MobInfoLine"] > 1 then

						if GameLocale == "ruRU" then

							LT["InfoText"] = ""

							-- Show creature type and classification
							LT["CreatureType"] = UnitCreatureType(LT["Unit"])
							if (LT["CreatureType"]) and not (LT["CreatureType"] == "Not specified") then
								LT["InfoText"] = LT["InfoText"] .. "|cffffffff" .. LT["CreatureType"] .. "|cffffffff "
							end

							-- Level ?? mob
							if LT["UnitLevel"] == -1 then
								LT["InfoText"] = LT["InfoText"] .. "|cffff3333" .. "??-ro " .. ttLevel .. "|cffffffff "

							-- Mobs within level range
							else
								LT["MobColor"] = GetCreatureDifficultyColor(LT["UnitLevel"])
								LT["MobColor"] = string.format('%02x%02x%02x', LT["MobColor"].r * 255, LT["MobColor"].g * 255, LT["MobColor"].b * 255)
								LT["InfoText"] = LT["InfoText"] .. "|cff" .. LT["MobColor"] .. LT["UnitLevel"] .. LT["LevelLocale"] .. "|cffffffff "
							end

						else

							-- Level ?? mob
							if LT["UnitLevel"] == -1 then
								LT["InfoText"] = "|cffff3333" .. ttLevel .. " ??|cffffffff "

							-- Mobs within level range
							else
								LT["MobColor"] = GetCreatureDifficultyColor(LT["UnitLevel"])
								LT["MobColor"] = string.format('%02x%02x%02x', LT["MobColor"].r * 255, LT["MobColor"].g * 255, LT["MobColor"].b * 255)
								LT["InfoText"] = "|cff" .. LT["MobColor"] .. LT["LevelLocale"] .. " " .. LT["UnitLevel"] .. "|cffffffff "
							end

							-- Show creature type and classification
							LT["CreatureType"] = UnitCreatureType(LT["Unit"])
							if (LT["CreatureType"]) and not (LT["CreatureType"] == "Not specified") then
								LT["InfoText"] = LT["InfoText"] .. "|cffffffff" .. LT["CreatureType"] .. "|cffffffff "
							end

						end

						-- Rare, elite and boss mobs
						LT["Special"] = UnitClassification(LT["Unit"])
						if LT["Special"] then
							if LT["Special"] == "elite" then
								if strfind(_G["GameTooltipTextLeft" .. LT["MobInfoLine"]]:GetText(), "(" .. ttBoss .. ")") then
									LT["Special"] = "(" .. ttBoss .. ")"
								else
									LT["Special"] = "(" .. ttElite .. ")"
								end
							elseif LT["Special"] == "rare" then
								LT["Special"] = "|c00e066ff(" .. ttRare .. ")"
							elseif LT["Special"] == "rareelite" then
								if strfind(_G["GameTooltipTextLeft" .. LT["MobInfoLine"]]:GetText(), "(" .. ttBoss .. ")") then
									LT["Special"] = "|c00e066ff(" .. ttRareBoss .. ")"
								else
									LT["Special"] = "|c00e066ff(" .. ttRareElite .. ")"
								end
							elseif LT["Special"] == "worldboss" then
								LT["Special"] = "(" .. ttBoss .. ")"
							elseif LT["UnitLevel"] == -1 and LT["Special"] == "normal" and strfind(_G["GameTooltipTextLeft" .. LT["MobInfoLine"]]:GetText(), "(" .. ttBoss .. ")") then
								LT["Special"] = "(" .. ttBoss .. ")"
							else
								LT["Special"] = nil
							end

							if (LT["Special"]) then
								LT["InfoText"] = LT["InfoText"] .. LT["Special"]
							end
						end

						-- Show mob info line
						_G["GameTooltipTextLeft" .. LT["MobInfoLine"]]:SetText(LT["InfoText"])

					end

				end

				----------------------------------------------------------------------
				-- Show guild
				----------------------------------------------------------------------

				if LT["TipIsPlayer"] then
					local unitGuild, unitRank = GetGuildInfo(LT["Unit"])
					if unitGuild and unitRank then
						if UnitIsInMyGuild(LT["Unit"]) then
							if RGXQoLLC["TipShowRank"] == "On" then
								GameTooltip:AddLine("|c00aaaaff" .. unitGuild .. " - " .. unitRank .. "|r")
							else
								GameTooltip:AddLine("|c00aaaaff" .. unitGuild .. "|cffffffff|r")
							end
						else
							if RGXQoLLC["TipShowOtherRank"] == "On" then
								GameTooltip:AddLine("|c00aaaaff" .. unitGuild .. " - " .. unitRank .. "|r")
							else
								GameTooltip:AddLine("|c00aaaaff" .. unitGuild .. "|cffffffff|r")
							end
						end
					end
				end

				----------------------------------------------------------------------
				--	Show target
				----------------------------------------------------------------------

				if RGXQoLLC["TipShowTarget"] == "On" then

					-- Get target
					LT["Target"] = UnitName(LT["Unit"] .. "target");

					-- If target doesn't exist, quit
					if LT["Target"] == nil or LT["Target"] == "" then return end

					-- If target is you, set target to YOU
					if (UnitIsUnit(LT["Target"], "player")) then
						LT["Target"] = ("|c12ff4400" .. ttYou)

					-- If it's not you, but it's a player, show target in class color
					elseif UnitIsPlayer(LT["Unit"] .. "target") then
						LT["TargetBase"] = UnitClassBase(LT["Unit"] .. "target")
						LT["TargetCol"] = RGXQoLLC["RaidColors"][LT["TargetBase"]]
						LT["TargetCol"] = "|cff" .. string.format('%02x%02x%02x', LT["TargetCol"].r * 255, LT["TargetCol"].g * 255, LT["TargetCol"].b * 255)
						LT["Target"] = (LT["TargetCol"] .. LT["Target"])

					end

					-- Add target line
					GameTooltip:AddLine(ttTarget .. ": " .. LT["Target"])

				end

			end

			if GameTooltip:HasScript("OnTooltipSetUnit") then
				GameTooltip:HookScript("OnTooltipSetUnit", ShowTip)
			end

		end

		----------------------------------------------------------------------
		--	Move chat editbox to top
		----------------------------------------------------------------------

		if RGXQoLLC["MoveChatEditBoxToTop"] == "On" then

			-- Set options for normal chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					-- Position the editbox
					_G["ChatFrame" .. i .. "EditBox"]:ClearAllPoints()
					_G["ChatFrame" .. i .. "EditBox"]:SetPoint("TOP", _G["ChatFrame" .. i], "TOP", 0, 0)
					_G["ChatFrame" .. i .. "EditBox"]:SetPoint("LEFT", _G["ChatFrame" .. i], "LEFT", 0, 0)
					_G["ChatFrame" .. i .. "EditBox"]:SetPoint("RIGHT", _G["ChatFrame" .. i], "RIGHT", 0, 0)
				end
			end

			-- Do the functions above for other chat frames (pet battles, whispers, etc)
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					-- Position the editbox
					_G[cf .. "EditBox"]:ClearAllPoints()
					_G[cf .. "EditBox"]:SetPoint("TOP", cf, "TOP", 0, 0)
					_G[cf .. "EditBox"]:SetPoint("LEFT", cf, "LEFT", 0, 0)
					_G[cf .. "EditBox"]:SetPoint("RIGHT", cf, "RIGHT", 0, 0)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Show borders
		----------------------------------------------------------------------

		if RGXQoLLC["ShowBorders"] == "On" then

			-- Create border textures
			local BordTop = WorldFrame:CreateTexture(nil, "ARTWORK"); BordTop:SetColorTexture(0, 0, 0, 1); BordTop:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0); BordTop:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
			local BordBot = WorldFrame:CreateTexture(nil, "ARTWORK"); BordBot:SetColorTexture(0, 0, 0, 1); BordBot:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0); BordBot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
			local BordLeft = WorldFrame:CreateTexture(nil, "ARTWORK"); BordLeft:SetColorTexture(0, 0, 0, 1); BordLeft:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0); BordLeft:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
			local BordRight = WorldFrame:CreateTexture(nil, "ARTWORK"); BordRight:SetColorTexture(0, 0, 0, 1); BordRight:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0); BordRight:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

			-- Create border configuration panel
			local bordersPanel = RGXQoLLC:CreatePanel("Show borders", "bordersPanel")

			-- Function to set border parameters
			local function RefreshBorders()

				-- Set border size and transparency
				BordTop:SetHeight(RGXQoLLC["BordersTop"]); BordTop:SetAlpha(1 - RGXQoLLC["BordersAlpha"])
				BordBot:SetHeight(RGXQoLLC["BordersBottom"]); BordBot:SetAlpha(1 - RGXQoLLC["BordersAlpha"])
				BordLeft:SetWidth(RGXQoLLC["BordersLeft"]); BordLeft:SetAlpha(1 - RGXQoLLC["BordersAlpha"])
				BordRight:SetWidth(RGXQoLLC["BordersRight"]); BordRight:SetAlpha(1 - RGXQoLLC["BordersAlpha"])

				-- Show formatted slider value
				RGXQoLCB["BordersAlpha"].f:SetFormattedText("%.0f%%", RGXQoLLC["BordersAlpha"] * 100)

			end

			-- Create slider controls
			RGXQoLLC:MakeTx(bordersPanel, "Top", 16, -72)
			RGXQoLLC:MakeSL(bordersPanel, "BordersTop", "Drag to set the size of the top border.", 0, 300, 5, 16, -92, "%.0f")
			RGXQoLCB["BordersTop"]:HookScript("OnValueChanged", RefreshBorders)

			RGXQoLLC:MakeTx(bordersPanel, "Bottom", 16, -132)
			RGXQoLLC:MakeSL(bordersPanel, "BordersBottom", "Drag to set the size of the bottom border.", 0, 300, 5, 16, -152, "%.0f")
			RGXQoLCB["BordersBottom"]:HookScript("OnValueChanged", RefreshBorders)

			RGXQoLLC:MakeTx(bordersPanel, "Left", 186, -72)
			RGXQoLLC:MakeSL(bordersPanel, "BordersLeft", "Drag to set the size of the left border.", 0, 300, 5, 186, -92, "%.0f")
			RGXQoLCB["BordersLeft"]:HookScript("OnValueChanged", RefreshBorders)

			RGXQoLLC:MakeTx(bordersPanel, "Right", 186, -132)
			RGXQoLLC:MakeSL(bordersPanel, "BordersRight", "Drag to set the size of the right border.", 0, 300, 5, 186, -152, "%.0f")
			RGXQoLCB["BordersRight"]:HookScript("OnValueChanged", RefreshBorders)

			RGXQoLLC:MakeTx(bordersPanel, "Transparency", 356, -132)
			RGXQoLLC:MakeSL(bordersPanel, "BordersAlpha", "Drag to set the transparency of the borders.", 0, 0.9, 0.1, 356, -152, "%.1f")
			RGXQoLCB["BordersAlpha"]:HookScript("OnValueChanged", RefreshBorders)

			-- Help button hidden
			bordersPanel.h:Hide()

			-- Back button handler
			bordersPanel.b:SetScript("OnClick", function()
				bordersPanel:Hide()
				RGXQoLLC["PageF"]:Show()
				RGXQoLLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			bordersPanel.r:SetScript("OnClick", function()
				RGXQoLLC["BordersTop"] = 0
				RGXQoLLC["BordersBottom"] = 0
				RGXQoLLC["BordersLeft"] = 0
				RGXQoLLC["BordersRight"] = 0
				RGXQoLLC["BordersAlpha"] = 0
				bordersPanel:Hide(); bordersPanel:Show()
				RefreshBorders()
			end)

			-- Configuration button handler
			RGXQoLCB["ModBordersBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					RGXQoLLC["BordersTop"] = 0
					RGXQoLLC["BordersBottom"] = 0
					RGXQoLLC["BordersLeft"] = 0
					RGXQoLLC["BordersRight"] = 0
					RGXQoLLC["BordersAlpha"] = 0.7
					RefreshBorders()
				else
					bordersPanel:Show()
					RGXQoLLC:HideFrames()
				end
			end)

			-- Set borders on startup
			RefreshBorders()

			-- Hide borders when cinematic is shown
			hooksecurefunc(CinematicFrame, "Hide", function()
				BordTop:Show(); BordBot:Show(); BordLeft:Show(); BordRight:Show()
			end)
			hooksecurefunc(CinematicFrame, "Show", function()
				BordTop:Hide(); BordBot:Hide(); BordLeft:Hide(); BordRight:Hide()
			end)

		end

		----------------------------------------------------------------------
		-- Silence rested emotes
		----------------------------------------------------------------------

		-- Manage emotes
		if RGXQoLLC["NoRestedEmotes"] == "On" then

			-- Zone table 		English					, French					, German					, Italian						, Russian					, S Chinese	, Spanish					, T Chinese	,
			local zonetable = {	"The Grim Guzzler"		, "Le Sinistre �cluseur"	, "Zum Grimmigen S�ufer"	, "Torvo Beone"					, "??????? ??????? ??????"	, "????"	, "Tragapenas"				, "????"	,}

			-- Function to set rested state
			local function UpdateEmoteSound()

				-- Find character's current zone
				local szone = GetSubZoneText() or "None"

				-- Find out if emote sounds are disabled or enabled
				local emoset = GetCVar("Sound_EnableEmoteSounds")

				if IsResting() then
					-- Character is resting so silence emotes
					if emoset ~= "0" then
						SetCVar("Sound_EnableEmoteSounds", "0")
					end
					return
				end

				-- Traverse zone table and silence emotes if character is in a designated zone
				for k, v in next, zonetable do
					if szone == zonetable[k] then
						if emoset ~= "0" then
							SetCVar("Sound_EnableEmoteSounds", "0")
						end
						return
					end
				end

				-- If the above didn't return, emote sounds should be enabled
				if emoset ~= "1" then
					SetCVar("Sound_EnableEmoteSounds", "1")
				end
				return

			end

			-- Set emote sound when rest state or zone changes
			local RestEvent = CreateFrame("FRAME")
			RestEvent:RegisterEvent("PLAYER_UPDATE_RESTING")
            RestEvent:RegisterEvent("ZONE_CHANGED_NEW_AREA")
			RestEvent:RegisterEvent("ZONE_CHANGED")
			RestEvent:RegisterEvent("ZONE_CHANGED_INDOORS")
			RestEvent:SetScript("OnEvent", UpdateEmoteSound)

			-- Set sound setting at startup
			UpdateEmoteSound()

		end

		----------------------------------------------------------------------
		--	Max camera zoom (no reload required)
		----------------------------------------------------------------------

		do

			-- Create event frame
			local frame = CreateFrame("FRAME")

			-- Function to set camera zoom
			local function SetZoom()
				if RGXQoLLC["MaxCameraZoom"] == "On" then
					SetCVar("cameraDistanceMaxZoomFactor", 4.0)
					frame:RegisterEvent("PLAYER_ENTERING_WORLD")
				else
					SetCVar("cameraDistanceMaxZoomFactor", 1.9)
					frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
				end
			end

			frame:SetScript("OnEvent", SetZoom)

			-- Set camera zoom when option is clicked and on startup (if enabled)
			RGXQoLCB["MaxCameraZoom"]:HookScript("OnClick", SetZoom)
			if RGXQoLLC["MaxCameraZoom"] == "On" then SetZoom() end

		end

		----------------------------------------------------------------------
		-- L45: Create panel in game options panel
		----------------------------------------------------------------------

		do

			local interPanel = CreateFrame("FRAME")
			interPanel.name = "RGX QoL"

			local maintitle = RGXQoLLC:MakeTx(interPanel, "RGX QoL", 0, 0)
			maintitle:SetFont(maintitle:GetFont(), 72)
			maintitle:ClearAllPoints()
			maintitle:SetPoint("TOP", 0, -72)

			local expTitle = RGXQoLLC:MakeTx(interPanel, L["World of Warcraft Classic"], 0, 0)
			expTitle:SetFont(expTitle:GetFont(), 32)
			expTitle:ClearAllPoints()
			expTitle:SetPoint("TOP", 0, -152)

			local subTitle = RGXQoLLC:MakeTx(interPanel, "curseforge.com/wow/addons/leatrix-plus", 0, 0)
			subTitle:SetFont(subTitle:GetFont(), 20)
			subTitle:ClearAllPoints()
			subTitle:SetPoint("BOTTOM", 0, 72)

			local slashTitle = RGXQoLLC:MakeTx(interPanel, "/ltp", 0, 0)
			slashTitle:SetFont(slashTitle:GetFont(), 72)
			slashTitle:ClearAllPoints()
			slashTitle:SetPoint("BOTTOM", subTitle, "TOP", 0, 40)
			slashTitle:SetScript("OnMouseUp", function(self, button)
				if button == "LeftButton" then
					SlashCmdList["RGXQoL"]("")
				end
			end)
			slashTitle:SetScript("OnEnter", function()
				slashTitle.r,  slashTitle.g, slashTitle.b = slashTitle:GetTextColor()
				slashTitle:SetTextColor(1, 1, 0)
			end)
			slashTitle:SetScript("OnLeave", function()
				slashTitle:SetTextColor(slashTitle.r, slashTitle.g, slashTitle.b)
			end)

			local pTex = interPanel:CreateTexture(nil, "BACKGROUND")
			pTex:SetAllPoints()
			pTex:SetTexture("Interface\\GLUES\\Models\\UI_MainMenu\\swordgradient2")
			pTex:SetAlpha(0.2)
			pTex:SetTexCoord(0, 1, 1, 0)

			local category = Settings.RegisterCanvasLayoutCategory(interPanel, L["Leatrix Plus"])
			Settings.RegisterAddOnCategory(category)

		end

		----------------------------------------------------------------------
		-- Frame alignment grid
		----------------------------------------------------------------------

		do

			-- Create frame alignment grid
			local grid = CreateFrame('FRAME')
			RGXQoLLC.grid = grid
			grid:Hide()
			grid:SetAllPoints(UIParent)
			local w, h = GetScreenWidth() * UIParent:GetEffectiveScale(), GetScreenHeight() * UIParent:GetEffectiveScale()
			local ratio = w / h
			local sqsize = w / 20
			local wline = floor(sqsize - (sqsize % 2))
			local hline = floor(sqsize / ratio - ((sqsize / ratio) % 2))
			-- Plot vertical lines
			for i = 0, wline do
				local t = RGXQoLLC.grid:CreateTexture(nil, 'BACKGROUND')
				if i == wline / 2 then t:SetColorTexture(1, 0, 0, 0.5) else t:SetColorTexture(0, 0, 0, 0.5) end
				t:SetPoint('TOPLEFT', grid, 'TOPLEFT', i * w / wline - 1, 0)
				t:SetPoint('BOTTOMRIGHT', grid, 'BOTTOMLEFT', i * w / wline + 1, 0)
			end
			-- Plot horizontal lines
			for i = 0, hline do
				local t = RGXQoLLC.grid:CreateTexture(nil, 'BACKGROUND')
				if i == hline / 2 then	t:SetColorTexture(1, 0, 0, 0.5) else t:SetColorTexture(0, 0, 0, 0.5) end
				t:SetPoint('TOPLEFT', grid, 'TOPLEFT', 0, -i * h / hline + 1)
				t:SetPoint('BOTTOMRIGHT', grid, 'TOPRIGHT', 0, -i * h / hline - 1)
			end

		end

		----------------------------------------------------------------------
		-- Media player
		----------------------------------------------------------------------



		----------------------------------------------------------------------
		-- Panel alpha
		----------------------------------------------------------------------

		do

			-- Function to set panel alpha
			local function SetPlusAlpha()
				-- Set panel alpha
				RGXQoLLC["PageF"].t:SetAlpha(1 - RGXQoLLC["PlusPanelAlpha"])
				-- Show formatted value
				RGXQoLCB["PlusPanelAlpha"].f:SetFormattedText("%.0f%%", RGXQoLLC["PlusPanelAlpha"] * 100)
			end

			-- Set alpha on startup
			SetPlusAlpha()

			-- Set alpha after changing slider
			RGXQoLCB["PlusPanelAlpha"]:HookScript("OnValueChanged", SetPlusAlpha)

		end

		----------------------------------------------------------------------
		-- Panel scale
		----------------------------------------------------------------------

		do

			-- Function to set panel scale
			local function SetPlusScale()
				-- Reset panel position
				RGXQoLLC["MainPanelA"], RGXQoLLC["MainPanelR"], RGXQoLLC["MainPanelX"], RGXQoLLC["MainPanelY"] = "CENTER", "CENTER", 0, 0
				if RGXQoLLC["PageF"]:IsShown() then
					RGXQoLLC["PageF"]:Hide()
					RGXQoLLC["PageF"]:Show()
				end
				-- Set panel scale
				RGXQoLLC["PageF"]:SetScale(RGXQoLLC["PlusPanelScale"])
				-- Update music player highlight bar scale
				RGXQoLLC:UpdateList()
			end

			-- Set scale on startup
			RGXQoLLC["PageF"]:SetScale(RGXQoLLC["PlusPanelScale"])

			-- Set scale and reset panel position after changing slider
			RGXQoLCB["PlusPanelScale"]:HookScript("OnMouseUp", SetPlusScale)
			RGXQoLCB["PlusPanelScale"]:HookScript("OnMouseWheel", SetPlusScale)

			-- Show formatted slider value
			RGXQoLCB["PlusPanelScale"]:HookScript("OnValueChanged", function()
				RGXQoLCB["PlusPanelScale"].f:SetFormattedText("%.0f%%", RGXQoLLC["PlusPanelScale"] * 100)
			end)

		end

		----------------------------------------------------------------------
		-- Final code for Player
		----------------------------------------------------------------------

		-- Show first run message
		if not RGXQoLDB["FirstRunMessageSeen"] then
			C_Timer.After(1, function()
				RGXQoLLC:Print(L["Enter"] .. " |cff00ff00" .. "/ltp" .. "|r " .. L["or click the minimap button to open Leatrix Plus."])
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

				UpdateVars("CombineAddonButtons", "MinimapButtonBag")		-- 1.15.120 (25th January 2026)
				UpdateVars("MuteStriders", "MuteMechSteps")					-- 1.14.45 (1st June 2022)
				UpdateVars("MinimapMod", "MinimapModder")					-- 1.14.57 (24th August 2022)

				-- Mute game sounds split with Mute mount sounds
				if RGXQoLDB["MuteGameSounds"] == "On" and not RGXQoLDB["MuteMountSounds"] then
					if RGXQoLDB["MuteMechSteps"] == "On"
					or RGXQoLDB["MuteStriders"] == "On"
					or RGXQoLDB["MuteHorsesteps"] == "On"
					then
						RGXQoLLC["MuteMountSounds"] = "On"
						RGXQoLDB["MuteMountSounds"] = "On"
					end
				end

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

				-- Social
				RGXQoLLC:LoadVarChk("NoDuelRequests", "Off")				-- Block duels
				RGXQoLLC:LoadVarChk("NoPartyInvites", "Off")				-- Block party invites
				RGXQoLLC:LoadVarChk("NoFriendRequests", "Off")				-- Block friend requests
				RGXQoLLC:LoadVarChk("NoSharedQuests", "Off")				-- Block shared quests

				RGXQoLLC:LoadVarChk("AcceptPartyFriends", "Off")			-- Party from friends
				RGXQoLLC:LoadVarChk("InviteFromWhisper", "Off")			-- Invite from whispers
				RGXQoLLC:LoadVarChk("InviteFriendsOnly", "Off")			-- Restrict invites to friends
				RGXQoLLC["InvKey"]	= RGXQoLDB["InvKey"] or "inv"			-- Invite from whisper keyword
				RGXQoLLC:LoadVarChk("FriendlyGuild", "On")					-- Friendly guild

				-- Chat
				RGXQoLLC:LoadVarChk("UseEasyChatResizing", "Off")			-- Use easy resizing
				RGXQoLLC:LoadVarChk("NoCombatLogTab", "Off")				-- Hide the combat log
				RGXQoLLC:LoadVarChk("NoChatButtons", "Off")				-- Hide chat buttons
				RGXQoLLC:LoadVarChk("UnclampChat", "Off")					-- Unclamp chat frame
				RGXQoLLC:LoadVarChk("MoveChatEditBoxToTop", "Off")			-- Move editbox to top
				RGXQoLLC:LoadVarChk("MoreFontSizes", "Off")				-- More font sizes

				RGXQoLLC:LoadVarChk("NoStickyChat", "Off")					-- Disable sticky chat
				RGXQoLLC:LoadVarChk("UseArrowKeysInChat", "Off")			-- Use arrow keys in chat
				RGXQoLLC:LoadVarChk("NoChatFade", "Off")					-- Disable chat fade
				RGXQoLLC:LoadVarChk("UnivGroupColor", "Off")				-- Universal group color
				RGXQoLLC:LoadVarChk("ClassColorsInChat", "Off")			-- Use class colors in chat
				RGXQoLLC:LoadVarChk("RecentChatWindow", "Off")				-- Recent chat window
				RGXQoLLC:LoadVarNum("RecentChatSize", 170, 170, 600)		-- Recent chat size
				RGXQoLLC:LoadVarChk("MaxChatHstory", "Off")				-- Increase chat history
				RGXQoLLC:LoadVarChk("FilterChatMessages", "Off")			-- Filter chat messages
				RGXQoLLC:LoadVarChk("BlockDrunkenSpam", "Off")				-- Block drunken spam
				RGXQoLLC:LoadVarChk("BlockDuelSpam", "Off")				-- Block duel spam
				RGXQoLLC:LoadVarChk("RestoreChatMessages", "Off")			-- Restore chat messages

				-- Text
				RGXQoLLC:LoadVarChk("HideErrorMessages", "Off")			-- Hide error messages
				RGXQoLLC:LoadVarChk("NoHitIndicators", "Off")				-- Hide portrait text
				RGXQoLLC:LoadVarChk("HideZoneText", "Off")					-- Hide zone text
				RGXQoLLC:LoadVarChk("HideKeybindText", "Off")				-- Hide keybind text
				RGXQoLLC:LoadVarChk("HideMacroText", "Off")				-- Hide macro text
				RGXQoLLC:LoadVarChk("HideRaidGroupLabels", "Off")			-- Hide raid group labels

				RGXQoLLC:LoadVarChk("MailFontChange", "Off")				-- Resize mail text
				RGXQoLLC:LoadVarNum("LeaPlusMailFontSize", 15, 10, 30)		-- Mail text slider

				RGXQoLLC:LoadVarChk("QuestFontChange", "Off")				-- Resize quest text
				RGXQoLLC:LoadVarNum("LeaPlusQuestFontSize", 12, 10, 30)	-- Quest text slider

				RGXQoLLC:LoadVarChk("BookFontChange", "Off")				-- Resize book text
				RGXQoLLC:LoadVarNum("LeaPlusBookFontSize", 15, 10, 30)		-- Book text slider

				-- Interface
				RGXQoLLC:LoadVarChk("MinimapModder", "Off")				-- Enhance minimap
				RGXQoLLC:LoadVarChk("SquareMinimap", "Off")				-- Square minimap
				RGXQoLLC:LoadVarChk("MinimapButtonBag", "Off")				-- Minimap button bag
				RGXQoLLC:LoadVarStr("MiniExcludeList", "")					-- Minimap exclude list
				RGXQoLLC:LoadVarChk("HideMiniZoomBtns", "Off")				-- Hide zoom buttons
				RGXQoLLC:LoadVarChk("HideMiniClock", "Off")				-- Hide the clock
				RGXQoLLC:LoadVarChk("HideMiniDayNight", "Off")				-- Hide the day and night indicator
				RGXQoLLC:LoadVarChk("HideMiniZoneText", "Off")				-- Hide the zone text bar
				RGXQoLLC:LoadVarChk("HideMiniAddonButtons", "On")			-- Hide addon buttons
				RGXQoLLC:LoadVarChk("HideMiniTracking", "Off")				-- Hide the tracking button
				RGXQoLLC:LoadVarChk("HideMiniLFG", "Off")					-- Hide the Looking for Group button
				RGXQoLLC:LoadVarNum("MinimapSize", 140, 140, 560)			-- Minimap size slider
				RGXQoLLC:LoadVarNum("MinimapBorderWidth", 3, 1, 10)		-- Minimap border width
				RGXQoLLC:LoadVarChk("TipModEnable", "Off")					-- Enhance tooltip
				RGXQoLLC:LoadVarChk("TipShowRank", "On")					-- Show guild rank for your own guild
				RGXQoLLC:LoadVarChk("TipShowOtherRank", "Off")				-- Show guild rank for other guilds
				RGXQoLLC:LoadVarChk("TipShowTarget", "On")					-- Show target
				RGXQoLLC:LoadVarChk("TipHideInCombat", "Off")				-- Hide tooltips during combat
				RGXQoLLC:LoadVarChk("TipHideShiftOverride", "On")			-- Hide tooltips shift override
				RGXQoLLC:LoadVarChk("TipNoHealthBar", "Off")				-- Hide health bar
				RGXQoLLC:LoadVarNum("LeaPlusTipSize", 1.00, 0.50, 2.00)	-- Tooltip scale slider
				RGXQoLLC:LoadVarNum("TipOffsetX", -13, -5000, 5000)		-- Tooltip X offset
				RGXQoLLC:LoadVarNum("TipOffsetY", 94, -5000, 5000)			-- Tooltip Y offset
				RGXQoLLC:LoadVarNum("TooltipAnchorMenu", 1, 1, 5)			-- Tooltip anchor menu
				RGXQoLLC:LoadVarNum("TipCursorX", 0, -128, 128)			-- Tooltip cursor X offset
				RGXQoLLC:LoadVarNum("TipCursorY", 0, -128, 128)			-- Tooltip cursor Y offset

				RGXQoLLC:LoadVarChk("EnhanceDressup", "Off")				-- Enhance dressup
				RGXQoLLC:LoadVarChk("DressupItemButtons", "On")			-- Dressup item buttons
				RGXQoLLC:LoadVarChk("DressupAnimControl", "On")			-- Dressup animation control
				RGXQoLLC:LoadVarChk("HideDressupStats", "Off")				-- Hide dressup stats
				RGXQoLLC:LoadVarChk("EnhanceQuestLog", "Off")				-- Enhance quest log
				RGXQoLLC:LoadVarChk("EnhanceQuestTaller", "On")			-- Enhance quest log taller
				RGXQoLLC:LoadVarChk("EnhanceQuestLevels", "On")			-- Enhance quest log quest levels
				RGXQoLLC:LoadVarChk("EnhanceQuestDifficulty", "On")		-- Enhance quest log quest difficulty
				RGXQoLLC:LoadVarChk("EnhanceProfessions", "Off")			-- Enhance professions
				RGXQoLLC:LoadVarChk("EnhanceTrainers", "Off")				-- Enhance trainers
				RGXQoLLC:LoadVarChk("ShowTrainAllBtn", "On")				-- Enhance trainers train all button
				RGXQoLLC:LoadVarChk("EnhanceFlightMap", "Off")				-- Enhance flight map
				RGXQoLLC:LoadVarNum("LeaPlusTaxiMapScale", 1.9, 1, 3)		-- Enhance flight map scale
				RGXQoLLC:LoadVarNum("LeaPlusTaxiIconSize", 10, 5, 30)		-- Enhance flight icon size
				RGXQoLLC:LoadVarAnc("FlightMapA", "TOPLEFT")				-- Enhance flight map anchor
				RGXQoLLC:LoadVarAnc("FlightMapR", "TOPLEFT")				-- Enhance flight map relative
				RGXQoLLC:LoadVarNum("FlightMapX", 0, -5000, 5000)			-- Enhance flight map X
				RGXQoLLC:LoadVarNum("FlightMapY", 61, -5000, 5000)			-- Enhance flight map Y

				RGXQoLLC:LoadVarChk("ShowVolume", "Off")					-- Show volume slider
				RGXQoLLC:LoadVarChk("AhExtras", "Off")						-- Show auction controls
				RGXQoLLC:LoadVarChk("AhBuyoutOnly", "Off")					-- Auction buyout only
				RGXQoLLC:LoadVarChk("AhGoldOnly", "Off")					-- Auction gold only

				RGXQoLLC:LoadVarChk("ShowCooldowns", "Off")				-- Show cooldowns
				RGXQoLLC:LoadVarChk("ShowCooldownID", "On")				-- Show cooldown ID in tips
				RGXQoLLC:LoadVarChk("NoCooldownDuration", "On")			-- Hide cooldown duration
				RGXQoLLC:LoadVarChk("CooldownsOnPlayer", "Off")			-- Anchor to player
				RGXQoLLC:LoadVarChk("DurabilityStatus", "Off")				-- Show durability status
				RGXQoLLC:LoadVarChk("ShowVanityControls", "Off")			-- Show vanity controls
				RGXQoLLC:LoadVarChk("VanityAltLayout", "Off")				-- Vanity alternative layout
				RGXQoLLC:LoadVarChk("ShowBagSearchBox", "Off")				-- Show bag search box
				RGXQoLLC:LoadVarChk("ShowFreeBagSlots", "Off")				-- Show free bag slots
				RGXQoLLC:LoadVarChk("ShowRaidToggle", "Off")				-- Show raid button
				RGXQoLLC:LoadVarChk("ShowBorders", "Off")					-- Show borders
				RGXQoLLC:LoadVarNum("BordersTop", 0, 0, 300)				-- Top border
				RGXQoLLC:LoadVarNum("BordersBottom", 0, 0, 300)			-- Bottom border
				RGXQoLLC:LoadVarNum("BordersLeft", 0, 0, 300)				-- Left border
				RGXQoLLC:LoadVarNum("BordersRight", 0, 0, 300)				-- Right border
				RGXQoLLC:LoadVarNum("BordersAlpha", 0, 0, 0.9)				-- Border alpha
				RGXQoLLC:LoadVarChk("ShowPlayerChain", "Off")				-- Show player chain
				RGXQoLLC:LoadVarChk("ShowReadyTimer", "Off")				-- Show ready timer
				RGXQoLLC:LoadVarNum("PlayerChainMenu", 2, 1, 3)			-- Player chain dropdown value
				RGXQoLLC:LoadVarChk("ShowDruidPowerBar", "Off")			-- Show druid power bar
				RGXQoLLC:LoadVarChk("ShowDruidStatusText", "On")			-- Show druid power bar status text
				RGXQoLLC:LoadVarChk("ShowWowheadLinks", "Off")				-- Show Wowhead links
				RGXQoLLC:LoadVarChk("WowheadLinkComments", "Off")			-- Show Wowhead links to comments

				-- Frames
				RGXQoLLC:LoadVarChk("ManageWidget", "Off")					-- Manage widget
				RGXQoLLC:LoadVarAnc("WidgetA", "TOP")						-- Manage widget anchor
				RGXQoLLC:LoadVarAnc("WidgetR", "TOP")						-- Manage widget relative
				RGXQoLLC:LoadVarNum("WidgetX", 0, -5000, 5000)				-- Manage widget position X
				RGXQoLLC:LoadVarNum("WidgetY", -15, -5000, 5000)			-- Manage widget position Y
				RGXQoLLC:LoadVarNum("WidgetScale", 1, 0.5, 2)				-- Manage widget scale

				RGXQoLLC:LoadVarChk("ManageTimer", "Off")					-- Manage timer
				RGXQoLLC:LoadVarAnc("TimerA", "TOP")						-- Manage timer anchor
				RGXQoLLC:LoadVarAnc("TimerR", "TOP")						-- Manage timer relative
				RGXQoLLC:LoadVarNum("TimerX", -5, -5000, 5000)				-- Manage timer position X
				RGXQoLLC:LoadVarNum("TimerY", -96, -5000, 5000)			-- Manage timer position Y
				RGXQoLLC:LoadVarNum("TimerScale", 1, 0.5, 2)				-- Manage timer scale

				RGXQoLLC:LoadVarChk("ClassColFrames", "Off")				-- Class colored frames
				RGXQoLLC:LoadVarChk("ClassColPlayer", "On")				-- Class colored player frame
				RGXQoLLC:LoadVarChk("ClassColTarget", "On")				-- Class colored target frame

				RGXQoLLC:LoadVarChk("NoGryphons", "Off")					-- Hide gryphons
				RGXQoLLC:LoadVarChk("NoClassBar", "Off")					-- Hide stance bar

				-- System
				RGXQoLLC:LoadVarChk("NoScreenGlow", "Off")					-- Disable screen glow
				RGXQoLLC:LoadVarChk("NoScreenEffects", "Off")				-- Disable screen effects
				RGXQoLLC:LoadVarChk("SetWeatherDensity", "Off")			-- Set weather density
				RGXQoLLC:LoadVarNum("WeatherLevel", 3, 0, 3)				-- Weather density level
				RGXQoLLC:LoadVarChk("MaxCameraZoom", "Off")				-- Max camera zoom

				RGXQoLLC:LoadVarChk("NoRestedEmotes", "Off")				-- Silence rested emotes
				RGXQoLLC:LoadVarChk("KeepAudioSynced", "Off")				-- Keep audio synced
				RGXQoLLC:LoadVarChk("MuteGameSounds", "Off")				-- Mute game sounds
				RGXQoLLC:LoadVarChk("MuteMountSounds", "Off")				-- Mute mount sounds
				RGXQoLLC:LoadVarChk("MuteCustomSounds", "Off")				-- Mute custom sounds
				RGXQoLLC:LoadVarStr("MuteCustomList", "")					-- Mute custom sounds list

				RGXQoLLC:LoadVarChk("NoBagAutomation", "Off")				-- Disable bag automation
				RGXQoLLC:LoadVarChk("NoConfirmLoot", "Off")				-- Disable loot warnings
				RGXQoLLC:LoadVarChk("FasterLooting", "Off")				-- Faster auto loot
				RGXQoLLC:LoadVarChk("FasterMovieSkip", "Off")				-- Faster movie skip
				RGXQoLLC:LoadVarChk("StandAndDismount", "Off")				-- Dismount me
				RGXQoLLC:LoadVarChk("DismountNoResource", "On")			-- Dismount on resource error
				RGXQoLLC:LoadVarChk("DismountNoMoving", "On")				-- Dismount on moving
				RGXQoLLC:LoadVarChk("DismountNoTaxi", "On")				-- Dismount on flight map open
				RGXQoLLC:LoadVarChk("ShowVendorPrice", "Off")				-- Show vendor price
				RGXQoLLC:LoadVarChk("CombatPlates", "Off")					-- Combat plates
				RGXQoLLC:LoadVarChk("EasyItemDestroy", "Off")				-- Easy item destroy

				RGXQoLLC:LoadVarChk("ShowFlightTimes", "Off")				-- Show flight times
				RGXQoLLC:LoadVarChk("FlightBarBackground", "On")			-- Show flight times bar background
				RGXQoLLC:LoadVarChk("FlightBarDestination", "On")			-- Show flight times bar destination
				RGXQoLLC:LoadVarChk("FlightBarFillBar", "Off")				-- Show flight times bar fill mode
				RGXQoLLC:LoadVarChk("FlightBarSpeech", "Off")				-- Show flight times bar speech
				RGXQoLLC:LoadVarChk("FlightBarContribute", "On")			-- Show flight times contribute
				RGXQoLLC:LoadVarAnc("FlightBarA", "TOP")					-- Show flight times anchor
				RGXQoLLC:LoadVarAnc("FlightBarR", "TOP")					-- Show flight times relative
				RGXQoLLC:LoadVarNum("FlightBarX", 0, -5000, 5000)			-- Show flight position X
				RGXQoLLC:LoadVarNum("FlightBarY", -66, -5000, 5000)		-- Show flight position Y
				RGXQoLLC:LoadVarNum("FlightBarScale", 2, 1, 5)				-- Show flight times bar scale
				RGXQoLLC:LoadVarNum("FlightBarWidth", 230, 40, 460)		-- Show flight times bar width

				-- Settings
				RGXQoLLC:LoadVarChk("ShowMinimapIcon", "On")				-- Show minimap button
				RGXQoLLC:LoadVarChk("UseEnglishLanguage", "Off")			-- Use English language
				RGXQoLLC:LoadVarNum("PlusPanelScale", 1, 1, 2)				-- Panel scale
				RGXQoLLC:LoadVarNum("PlusPanelAlpha", 0, 0, 1)				-- Panel alpha

				-- Panel position
				RGXQoLLC:LoadVarAnc("MainPanelA", "CENTER")				-- Panel anchor
				RGXQoLLC:LoadVarAnc("MainPanelR", "CENTER")				-- Panel relative
				RGXQoLLC:LoadVarNum("MainPanelX", 0, -5000, 5000)			-- Panel X axis
				RGXQoLLC:LoadVarNum("MainPanelY", 0, -5000, 5000)			-- Panel Y axis

				-- Start page
				RGXQoLLC:LoadVarNum("RGXQoLStartPage", 0, 0, RGXQoLLC["NumberOfPages"])

				-- Lock conflicting options
				do

					-- Function to disable and lock an option and add a note to the tooltip
					local function Lock(option, reason, optmodule)
						RGXQoLLockList[option] = RGXQoLLC[option]
						RGXQoLLC:LockItem(RGXQoLCB[option], true)
						RGXQoLCB[option].tiptext = RGXQoLCB[option].tiptext .. "|n|n|cff00AAFF" .. reason
						if optmodule then
							RGXQoLCB[option].tiptext = RGXQoLCB[option].tiptext .. " " .. optmodule .. " " .. L["module"]
						end
						RGXQoLCB[option].tiptext = RGXQoLCB[option].tiptext .. "."
						-- Remove hover from configuration button if there is one
						local temp = {RGXQoLCB[option]:GetChildren()}
						if temp and temp[1] and temp[1].t and temp[1].t:GetTexture() == "Interface\\WorldMap\\Gear_64.png" then
							temp[1]:SetHighlightTexture(0)
							temp[1]:SetScript("OnEnter", nil)
						end
					end

					-- Disable items that conflict with Easy Frames
					if C_AddOns.IsAddOnLoaded("EasyFrames") then
						Lock("ClassColFrames", L["Cannot be used with Easy Frames"]) -- Class colored frames
					end

					-- Disable items that conflict with Glass
					if C_AddOns.IsAddOnLoaded("Glass") then
						local reason = L["Cannot be used with Glass"]
						Lock("UseEasyChatResizing", reason) -- Use easy resizing
						Lock("NoCombatLogTab", reason) -- Hide the combat log
						Lock("NoChatButtons", reason) -- Hide chat buttons
						Lock("UnclampChat", reason) -- Unclamp chat frame
						Lock("MoveChatEditBoxToTop", reason) -- Move editbox to top
						Lock("MoreFontSizes", reason) --  More font sizes
						Lock("NoChatFade", reason) --  Disable chat fade
						Lock("ClassColorsInChat", reason) -- Use class colors in chat
						Lock("RecentChatWindow", reason) -- Recent chat window
					end

					-- Disable items that conflict with ElvUI
					if RGXQoLLC.ElvUI then
						local E = RGXQoLLC.ElvUI
						if E and E.private then

							local reason = L["Cannot be used with ElvUI"]

							-- Chat
							if E.private.chat.enable then
								Lock("UseEasyChatResizing", reason, "Chat") -- Use easy resizing
								Lock("NoCombatLogTab", reason, "Chat") -- Hide the combat log
								Lock("NoChatButtons", reason, "Chat") -- Hide chat buttons
								Lock("UnclampChat", reason, "Chat") -- Unclamp chat frame
								Lock("MoreFontSizes", reason, "Chat") --  More font sizes
								Lock("NoStickyChat", reason, "Chat") -- Disable sticky chat
								Lock("UseArrowKeysInChat", reason, "Chat") -- Use arrow keys in chat
								Lock("NoChatFade", reason, "Chat") -- Disable chat fade
								Lock("MaxChatHstory", reason, "Chat") -- Increase chat history
								Lock("RestoreChatMessages", reason, "Chat") -- Restore chat messages
							end

							-- Minimap
							if E.private.general.minimap.enable then
								Lock("MinimapModder", reason, "Minimap") -- Enhance minimap
							end

							-- UnitFrames
							if E.private.unitframe.enable then
								Lock("ShowRaidToggle", reason, "UnitFrames") -- Show raid button
								Lock("ShowDruidPowerBar", reason, "UnitFrames") -- Show druid power bar
							end

							-- ActionBars
							if E.private.actionbar.enable then
								Lock("NoGryphons", reason, "ActionBars") -- Hide gryphons
								Lock("NoClassBar", reason, "ActionBars") -- Hide stance bar
								Lock("HideKeybindText", reason, "ActionBars") -- Hide keybind text
								Lock("HideMacroText", reason, "ActionBars") -- Hide macro text
								Lock("ShowFreeBagSlots", reason, "ActionBars") -- Show free bag slots
							end

							-- Bags
							if E.private.bags.enable then
								Lock("NoBagAutomation", reason, "Bags") -- Disable bag automation
								Lock("ShowBagSearchBox", reason, "Bags") -- Show bag search box
							end

							-- Tooltip
							if E.private.tooltip.enable then
								Lock("TipModEnable", reason, "Tooltip") -- Enhance tooltip
							end

							-- UnitFrames: Disabled Blizzard: Player
							if E.private.unitframe.disabledBlizzardFrames.player then
								Lock("ShowPlayerChain", reason, "UnitFrames (Disabled Blizzard Frames Player)") -- Show player chain
								Lock("NoHitIndicators", reason, "UnitFrames (Disabled Blizzard Frames Player)") -- Hide portrait numbers
							end

							-- UnitFrames: Disabled Blizzard: Player and Target
							if E.private.unitframe.disabledBlizzardFrames.player or E.private.unitframe.disabledBlizzardFrames.target then
								Lock("ClassColFrames", reason, "UnitFrames (Disabled Blizzard Frames Player and Target)") -- Class-colored frames
							end

							-- Base
							do
								Lock("ManageWidget", reason) -- Manage widget
								Lock("ManageTimer", reason) -- Manage timer
							end

						end

						C_AddOns.EnableAddOn("RGXQoL")
					end

				end

				-- Run other startup items
				RGXQoLLC:SetDim()

			end
			return
		end

		if event == "PLAYER_LOGIN" then
			RGXQoLLC:Player()

			-- Sound features removed on this build (BLU owns sounds)
			if RGXQoLCB["MuteGameSoundsBtn"] then RGXQoLCB["MuteGameSoundsBtn"]:Hide() end
			if RGXQoLCB["MuteMountSoundsBtn"] then RGXQoLCB["MuteMountSoundsBtn"]:Hide() end
			if RGXQoLCB["MuteCustomSoundsBtn"] then RGXQoLCB["MuteCustomSoundsBtn"]:Hide() end

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

			-- Social
			RGXQoLDB["NoDuelRequests"] 		= RGXQoLLC["NoDuelRequests"]
			RGXQoLDB["NoPartyInvites"]			= RGXQoLLC["NoPartyInvites"]
			RGXQoLDB["NoFriendRequests"]		= RGXQoLLC["NoFriendRequests"]
			RGXQoLDB["NoSharedQuests"]			= RGXQoLLC["NoSharedQuests"]

			RGXQoLDB["AcceptPartyFriends"]		= RGXQoLLC["AcceptPartyFriends"]
			RGXQoLDB["InviteFromWhisper"]		= RGXQoLLC["InviteFromWhisper"]
			RGXQoLDB["InviteFriendsOnly"]		= RGXQoLLC["InviteFriendsOnly"]
			RGXQoLDB["InvKey"]					= RGXQoLLC["InvKey"]
			RGXQoLDB["FriendlyGuild"]			= RGXQoLLC["FriendlyGuild"]

			-- Chat
			RGXQoLDB["UseEasyChatResizing"]	= RGXQoLLC["UseEasyChatResizing"]
			RGXQoLDB["NoCombatLogTab"]			= RGXQoLLC["NoCombatLogTab"]
			RGXQoLDB["NoChatButtons"]			= RGXQoLLC["NoChatButtons"]
			RGXQoLDB["UnclampChat"]			= RGXQoLLC["UnclampChat"]
			RGXQoLDB["MoveChatEditBoxToTop"]	= RGXQoLLC["MoveChatEditBoxToTop"]
			RGXQoLDB["MoreFontSizes"]			= RGXQoLLC["MoreFontSizes"]

			RGXQoLDB["NoStickyChat"] 			= RGXQoLLC["NoStickyChat"]
			RGXQoLDB["UseArrowKeysInChat"]		= RGXQoLLC["UseArrowKeysInChat"]
			RGXQoLDB["NoChatFade"]				= RGXQoLLC["NoChatFade"]
			RGXQoLDB["UnivGroupColor"]			= RGXQoLLC["UnivGroupColor"]
			RGXQoLDB["ClassColorsInChat"]		= RGXQoLLC["ClassColorsInChat"]
			RGXQoLDB["RecentChatWindow"]		= RGXQoLLC["RecentChatWindow"]
			RGXQoLDB["RecentChatSize"]			= RGXQoLLC["RecentChatSize"]
			RGXQoLDB["MaxChatHstory"]			= RGXQoLLC["MaxChatHstory"]
			RGXQoLDB["FilterChatMessages"]		= RGXQoLLC["FilterChatMessages"]
			RGXQoLDB["BlockDrunkenSpam"]		= RGXQoLLC["BlockDrunkenSpam"]
			RGXQoLDB["BlockDuelSpam"]			= RGXQoLLC["BlockDuelSpam"]
			RGXQoLDB["RestoreChatMessages"]	= RGXQoLLC["RestoreChatMessages"]

			-- Text
			RGXQoLDB["HideErrorMessages"]		= RGXQoLLC["HideErrorMessages"]
			RGXQoLDB["NoHitIndicators"]		= RGXQoLLC["NoHitIndicators"]
			RGXQoLDB["HideZoneText"] 			= RGXQoLLC["HideZoneText"]
			RGXQoLDB["HideKeybindText"] 		= RGXQoLLC["HideKeybindText"]
			RGXQoLDB["HideMacroText"] 			= RGXQoLLC["HideMacroText"]
			RGXQoLDB["HideRaidGroupLabels"] 	= RGXQoLLC["HideRaidGroupLabels"]

			RGXQoLDB["MailFontChange"] 		= RGXQoLLC["MailFontChange"]
			RGXQoLDB["LeaPlusMailFontSize"] 	= RGXQoLLC["LeaPlusMailFontSize"]

			RGXQoLDB["QuestFontChange"] 		= RGXQoLLC["QuestFontChange"]
			RGXQoLDB["LeaPlusQuestFontSize"]	= RGXQoLLC["LeaPlusQuestFontSize"]

			RGXQoLDB["BookFontChange"] 		= RGXQoLLC["BookFontChange"]
			RGXQoLDB["LeaPlusBookFontSize"]	= RGXQoLLC["LeaPlusBookFontSize"]

			-- Interface
			RGXQoLDB["MinimapModder"]			= RGXQoLLC["MinimapModder"]
			RGXQoLDB["SquareMinimap"]			= RGXQoLLC["SquareMinimap"]
			RGXQoLDB["MinimapButtonBag"]		= RGXQoLLC["MinimapButtonBag"]
			RGXQoLDB["MiniExcludeList"] 		= RGXQoLLC["MiniExcludeList"]
			RGXQoLDB["HideMiniZoomBtns"]		= RGXQoLLC["HideMiniZoomBtns"]
			RGXQoLDB["HideMiniClock"]			= RGXQoLLC["HideMiniClock"]
			RGXQoLDB["HideMiniDayNight"]		= RGXQoLLC["HideMiniDayNight"]
			RGXQoLDB["HideMiniZoneText"]		= RGXQoLLC["HideMiniZoneText"]
			RGXQoLDB["HideMiniAddonButtons"]	= RGXQoLLC["HideMiniAddonButtons"]
			RGXQoLDB["HideMiniTracking"]		= RGXQoLLC["HideMiniTracking"]
			RGXQoLDB["HideMiniLFG"]			= RGXQoLLC["HideMiniLFG"]
			RGXQoLDB["MinimapSize"]			= RGXQoLLC["MinimapSize"]
			RGXQoLDB["MinimapBorderWidth"]		= RGXQoLLC["MinimapBorderWidth"]

			RGXQoLDB["TipModEnable"]			= RGXQoLLC["TipModEnable"]
			RGXQoLDB["TipShowRank"]			= RGXQoLLC["TipShowRank"]
			RGXQoLDB["TipShowOtherRank"]		= RGXQoLLC["TipShowOtherRank"]
			RGXQoLDB["TipShowTarget"]			= RGXQoLLC["TipShowTarget"]
			RGXQoLDB["TipHideInCombat"]		= RGXQoLLC["TipHideInCombat"]
			RGXQoLDB["TipHideShiftOverride"]	= RGXQoLLC["TipHideShiftOverride"]
			RGXQoLDB["TipNoHealthBar"]			= RGXQoLLC["TipNoHealthBar"]
			RGXQoLDB["LeaPlusTipSize"]			= RGXQoLLC["LeaPlusTipSize"]
			RGXQoLDB["TipOffsetX"]				= RGXQoLLC["TipOffsetX"]
			RGXQoLDB["TipOffsetY"]				= RGXQoLLC["TipOffsetY"]
			RGXQoLDB["TooltipAnchorMenu"]		= RGXQoLLC["TooltipAnchorMenu"]
			RGXQoLDB["TipCursorX"]				= RGXQoLLC["TipCursorX"]
			RGXQoLDB["TipCursorY"]				= RGXQoLLC["TipCursorY"]

			RGXQoLDB["EnhanceDressup"]			= RGXQoLLC["EnhanceDressup"]
			RGXQoLDB["DressupItemButtons"]		= RGXQoLLC["DressupItemButtons"]
			RGXQoLDB["DressupAnimControl"]		= RGXQoLLC["DressupAnimControl"]
			RGXQoLDB["HideDressupStats"]		= RGXQoLLC["HideDressupStats"]
			RGXQoLDB["EnhanceQuestLog"]		= RGXQoLLC["EnhanceQuestLog"]
			RGXQoLDB["EnhanceQuestTaller"]		= RGXQoLLC["EnhanceQuestTaller"]
			RGXQoLDB["EnhanceQuestLevels"]		= RGXQoLLC["EnhanceQuestLevels"]
			RGXQoLDB["EnhanceQuestDifficulty"]	= RGXQoLLC["EnhanceQuestDifficulty"]
			RGXQoLDB["EnhanceProfessions"]		= RGXQoLLC["EnhanceProfessions"]
			RGXQoLDB["EnhanceTrainers"]		= RGXQoLLC["EnhanceTrainers"]
			RGXQoLDB["ShowTrainAllBtn"]		= RGXQoLLC["ShowTrainAllBtn"]
			RGXQoLDB["EnhanceFlightMap"]		= RGXQoLLC["EnhanceFlightMap"]
			RGXQoLDB["LeaPlusTaxiMapScale"]	= RGXQoLLC["LeaPlusTaxiMapScale"]
			RGXQoLDB["LeaPlusTaxiIconSize"]	= RGXQoLLC["LeaPlusTaxiIconSize"]
			RGXQoLDB["FlightMapA"]				= RGXQoLLC["FlightMapA"]
			RGXQoLDB["FlightMapR"]				= RGXQoLLC["FlightMapR"]
			RGXQoLDB["FlightMapX"]				= RGXQoLLC["FlightMapX"]
			RGXQoLDB["FlightMapY"]				= RGXQoLLC["FlightMapY"]

			RGXQoLDB["ShowVolume"] 			= RGXQoLLC["ShowVolume"]
			RGXQoLDB["AhExtras"]				= RGXQoLLC["AhExtras"]
			RGXQoLDB["AhBuyoutOnly"]			= RGXQoLLC["AhBuyoutOnly"]
			RGXQoLDB["AhGoldOnly"]				= RGXQoLLC["AhGoldOnly"]

			RGXQoLDB["ShowCooldowns"]			= RGXQoLLC["ShowCooldowns"]
			RGXQoLDB["ShowCooldownID"]			= RGXQoLLC["ShowCooldownID"]
			RGXQoLDB["NoCooldownDuration"]		= RGXQoLLC["NoCooldownDuration"]
			RGXQoLDB["CooldownsOnPlayer"]		= RGXQoLLC["CooldownsOnPlayer"]
			RGXQoLDB["DurabilityStatus"]		= RGXQoLLC["DurabilityStatus"]
			RGXQoLDB["ShowVanityControls"]		= RGXQoLLC["ShowVanityControls"]
			RGXQoLDB["VanityAltLayout"]		= RGXQoLLC["VanityAltLayout"]
			RGXQoLDB["ShowBagSearchBox"]		= RGXQoLLC["ShowBagSearchBox"]
			RGXQoLDB["ShowFreeBagSlots"]		= RGXQoLLC["ShowFreeBagSlots"]
			RGXQoLDB["ShowRaidToggle"]			= RGXQoLLC["ShowRaidToggle"]
			RGXQoLDB["ShowBorders"]			= RGXQoLLC["ShowBorders"]
			RGXQoLDB["BordersTop"]				= RGXQoLLC["BordersTop"]
			RGXQoLDB["BordersBottom"]			= RGXQoLLC["BordersBottom"]
			RGXQoLDB["BordersLeft"]			= RGXQoLLC["BordersLeft"]
			RGXQoLDB["BordersRight"]			= RGXQoLLC["BordersRight"]
			RGXQoLDB["BordersAlpha"]			= RGXQoLLC["BordersAlpha"]
			RGXQoLDB["ShowPlayerChain"]		= RGXQoLLC["ShowPlayerChain"]
			RGXQoLDB["PlayerChainMenu"]		= RGXQoLLC["PlayerChainMenu"]
			RGXQoLDB["ShowReadyTimer"]			= RGXQoLLC["ShowReadyTimer"]
			RGXQoLDB["ShowDruidPowerBar"]		= RGXQoLLC["ShowDruidPowerBar"]
			RGXQoLDB["ShowDruidStatusText"]	= RGXQoLLC["ShowDruidStatusText"]
			RGXQoLDB["ShowWowheadLinks"]		= RGXQoLLC["ShowWowheadLinks"]
			RGXQoLDB["WowheadLinkComments"]	= RGXQoLLC["WowheadLinkComments"]

			-- Frames
			RGXQoLDB["ManageWidget"]			= RGXQoLLC["ManageWidget"]
			RGXQoLDB["WidgetA"]				= RGXQoLLC["WidgetA"]
			RGXQoLDB["WidgetR"]				= RGXQoLLC["WidgetR"]
			RGXQoLDB["WidgetX"]				= RGXQoLLC["WidgetX"]
			RGXQoLDB["WidgetY"]				= RGXQoLLC["WidgetY"]
			RGXQoLDB["WidgetScale"]			= RGXQoLLC["WidgetScale"]

			RGXQoLDB["ManageTimer"]			= RGXQoLLC["ManageTimer"]
			RGXQoLDB["TimerA"]					= RGXQoLLC["TimerA"]
			RGXQoLDB["TimerR"]					= RGXQoLLC["TimerR"]
			RGXQoLDB["TimerX"]					= RGXQoLLC["TimerX"]
			RGXQoLDB["TimerY"]					= RGXQoLLC["TimerY"]
			RGXQoLDB["TimerScale"]				= RGXQoLLC["TimerScale"]

			RGXQoLDB["ClassColFrames"]			= RGXQoLLC["ClassColFrames"]
			RGXQoLDB["ClassColPlayer"]			= RGXQoLLC["ClassColPlayer"]
			RGXQoLDB["ClassColTarget"]			= RGXQoLLC["ClassColTarget"]

			RGXQoLDB["NoGryphons"]				= RGXQoLLC["NoGryphons"]
			RGXQoLDB["NoClassBar"]				= RGXQoLLC["NoClassBar"]

			-- System
			RGXQoLDB["NoScreenGlow"] 			= RGXQoLLC["NoScreenGlow"]
			RGXQoLDB["NoScreenEffects"] 		= RGXQoLLC["NoScreenEffects"]
			RGXQoLDB["SetWeatherDensity"] 		= RGXQoLLC["SetWeatherDensity"]
			RGXQoLDB["WeatherLevel"] 			= RGXQoLLC["WeatherLevel"]
			RGXQoLDB["MaxCameraZoom"] 			= RGXQoLLC["MaxCameraZoom"]

			RGXQoLDB["NoRestedEmotes"]			= RGXQoLLC["NoRestedEmotes"]
			RGXQoLDB["KeepAudioSynced"]		= RGXQoLLC["KeepAudioSynced"]
			RGXQoLDB["MuteGameSounds"]			= RGXQoLLC["MuteGameSounds"]
			RGXQoLDB["MuteMountSounds"]		= RGXQoLLC["MuteMountSounds"]
			RGXQoLDB["MuteCustomSounds"]		= RGXQoLLC["MuteCustomSounds"]
			RGXQoLDB["MuteCustomList"]			= RGXQoLLC["MuteCustomList"]

			RGXQoLDB["NoBagAutomation"]		= RGXQoLLC["NoBagAutomation"]
			RGXQoLDB["NoConfirmLoot"] 			= RGXQoLLC["NoConfirmLoot"]
			RGXQoLDB["FasterLooting"] 			= RGXQoLLC["FasterLooting"]
			RGXQoLDB["FasterMovieSkip"] 		= RGXQoLLC["FasterMovieSkip"]
			RGXQoLDB["StandAndDismount"] 		= RGXQoLLC["StandAndDismount"]
			RGXQoLDB["DismountNoResource"] 	= RGXQoLLC["DismountNoResource"]
			RGXQoLDB["DismountNoMoving"] 		= RGXQoLLC["DismountNoMoving"]
			RGXQoLDB["DismountNoTaxi"] 		= RGXQoLLC["DismountNoTaxi"]
			RGXQoLDB["ShowVendorPrice"] 		= RGXQoLLC["ShowVendorPrice"]
			RGXQoLDB["CombatPlates"]			= RGXQoLLC["CombatPlates"]
			RGXQoLDB["EasyItemDestroy"]		= RGXQoLLC["EasyItemDestroy"]

			RGXQoLDB["ShowFlightTimes"]		= RGXQoLLC["ShowFlightTimes"]
			RGXQoLDB["FlightBarBackground"]	= RGXQoLLC["FlightBarBackground"]
			RGXQoLDB["FlightBarDestination"]	= RGXQoLLC["FlightBarDestination"]
			RGXQoLDB["FlightBarFillBar"]		= RGXQoLLC["FlightBarFillBar"]
			RGXQoLDB["FlightBarSpeech"]		= RGXQoLLC["FlightBarSpeech"]
			RGXQoLDB["FlightBarContribute"]	= RGXQoLLC["FlightBarContribute"]
			RGXQoLDB["FlightBarA"]				= RGXQoLLC["FlightBarA"]
			RGXQoLDB["FlightBarR"]				= RGXQoLLC["FlightBarR"]
			RGXQoLDB["FlightBarX"]				= RGXQoLLC["FlightBarX"]
			RGXQoLDB["FlightBarY"]				= RGXQoLLC["FlightBarY"]
			RGXQoLDB["FlightBarScale"]			= RGXQoLLC["FlightBarScale"]
			RGXQoLDB["FlightBarWidth"]			= RGXQoLLC["FlightBarWidth"]

			-- Settings
			RGXQoLDB["ShowMinimapIcon"] 		= RGXQoLLC["ShowMinimapIcon"]
			RGXQoLDB["UseEnglishLanguage"] 	= RGXQoLLC["UseEnglishLanguage"]
			RGXQoLDB["PlusPanelScale"] 		= RGXQoLLC["PlusPanelScale"]
			RGXQoLDB["PlusPanelAlpha"] 		= RGXQoLLC["PlusPanelAlpha"]

			-- Panel position
			RGXQoLDB["MainPanelA"]				= RGXQoLLC["MainPanelA"]
			RGXQoLDB["MainPanelR"]				= RGXQoLLC["MainPanelR"]
			RGXQoLDB["MainPanelX"]				= RGXQoLLC["MainPanelX"]
			RGXQoLDB["MainPanelY"]				= RGXQoLLC["MainPanelY"]

			-- Start page
			RGXQoLDB["RGXQoLStartPage"]			= RGXQoLLC["RGXQoLStartPage"]

			-- Mute game sounds (RGXQoLLC["MuteGameSounds"])
			for k, v in pairs(RGXQoLLC["muteTable"]) do
				RGXQoLDB[k] = RGXQoLLC[k]
			end

			-- Mute mount sounds (RGXQoLLC["MuteMountSounds"])
			for k, v in pairs(RGXQoLLC["mountTable"]) do
				RGXQoLDB[k] = RGXQoLLC[k]
			end

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

		-- Disable screen glow (RGXQoLLC["NoScreenGlow"])
		if wipe then

			-- Disable screen glow (RGXQoLLC["NoScreenGlow"])
			SetCVar("ffxGlow", "1")

			-- Disable screen effects (RGXQoLLC["NoScreenEffects"])
			SetCVar("ffxDeath", "1")
			SetCVar("ffxNether", "1")

			-- Set weather density (RGXQoLLC["SetWeatherDensity"])
			SetCVar("WeatherDensity", "3")
			SetCVar("RAIDweatherDensity", "3")

			-- Max camera zoom (RGXQoLLC["MaxCameraZoom"])
			SetCVar("cameraDistanceMaxZoomFactor", 1.9)

			-- Universal group color (RGXQoLLC["UnivGroupColor"])
			ChangeChatColor("RAID", 1, 0.50, 0)
			ChangeChatColor("RAID_LEADER", 1, 0.28, 0.04)

			-- Mute game sounds (RGXQoLLC["MuteGameSounds"])
			for k, v in pairs(RGXQoLLC["muteTable"]) do
				for i, e in pairs(v) do
					local file, soundID = e:match("([^,]+)%#([^,]+)")
					UnmuteSoundFile(soundID)
				end
			end

			-- Mute mount sounds (RGXQoLLC["MuteMountSounds"])
			for k, v in pairs(RGXQoLLC["mountTable"]) do
				for i, e in pairs(v) do
					local file, soundID = e:match("([^,]+)%#([^,]+)")
					UnmuteSoundFile(soundID)
				end
			end

		end

		----------------------------------------------------------------------
		-- Restore default values for options that require reloads
		----------------------------------------------------------------------

		-- Use class colors in chat
		if RGXQoLDB["ClassColorsInChat"] == "On" and not RGXQoLLockList["ClassColorsInChat"] then
			if wipe or (not wipe and RGXQoLLC["ClassColorsInChat"] == "Off") then
				SetCVar("chatClassColorOverride", "1")
				for void, v in ipairs({"SAY", "EMOTE", "YELL", "GUILD", "OFFICER", "WHISPER", "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER", "RAID_WARNING", "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER", "VOICE_TEXT"}) do
					SetChatColorNameByClass(v, false)
				end
				for i = 1, 50 do
					SetChatColorNameByClass("CHANNEL" .. i, false)
				end
			end
		end

		-- Enhance minimap restore round minimap if wipe or enhance minimap is toggled off
		if RGXQoLDB["MinimapModder"] == "On" and RGXQoLDB["SquareMinimap"] == "On" and not RGXQoLLockList["MinimapModder"] then
			if wipe or (not wipe and RGXQoLLC["MinimapModder"] == "Off") then
				Minimap:SetMaskTexture([[Interface\CharacterFrame\TempPortraitAlphaMask]])
			end
		end

		-- Silence rested emotes
		if RGXQoLDB["NoRestedEmotes"] == "On" then
			if wipe or (not wipe and RGXQoLLC["NoRestedEmotes"] == "Off") then
				SetCVar("Sound_EnableEmoteSounds", "1")
			end
		end

		-- Show free bag slos
		if RGXQoLDB["ShowFreeBagSlots"] == "On" and not RGXQoLLockList["ShowFreeBagSlots"] then
			if wipe or (not wipe and RGXQoLLC["ShowFreeBagSlots"] == "Off") then
				SetCVar("displayFreeBagSlots", "0")
			end
		end

		-- More font sizes
		if RGXQoLDB["MoreFontSizes"] == "On" and not RGXQoLLockList["MoreFontSizes"] then
			if wipe or (not wipe and RGXQoLLC["MoreFontSizes"] == "Off") then
				RunScript('for i = 1, 50 do if _G["ChatFrame" .. i] then local void, fontSize = FCF_GetChatWindowInfo(i); if fontSize and fontSize ~= 12 and fontSize ~= 14 and fontSize ~= 16 and fontSize ~= 18 then FCF_SetChatWindowFontSize(self, _G["ChatFrame" .. i], CHAT_FRAME_DEFAULT_FONT_SIZE) end end end')
			end
		end

		----------------------------------------------------------------------
		-- Do other stuff during logout
		----------------------------------------------------------------------

		-- Store the auction house duration and price type values if auction house option is enabled
		if RGXQoLDB["AhExtras"] == "On" then
			if AuctionFrameAuctions then
				if AuctionFrameAuctions.duration then
					RGXQoLDB["AHDuration"] = AuctionFrameAuctions.duration
				end
			end
		end

	end

----------------------------------------------------------------------
-- 	Options panel functions
----------------------------------------------------------------------

	-- Function to add textures to panels
	function RGXQoLLC:CreateBar(name, parent, width, height, anchor, r, g, b, alp, tex)
		local ft = parent:CreateTexture(nil, "BORDER")
		ft:SetTexture(tex)
		ft:SetSize(width, height)
		ft:SetPoint(anchor)
		ft:SetVertexColor(r ,g, b, alp)
		if name == "MainTexture" then
			ft:SetTexCoord(0.09, 1, 0, 1);
		end
	end

	-- Create a configuration panel
	function RGXQoLLC:CreatePanel(title, globref, scrolling)

		-- Create the panel
		local Side = CreateFrame("Frame", nil, UIParent)

		-- Make it a system frame
		_G["LeaPlusGlobalPanel_" .. globref] = Side
		table.insert(UISpecialFrames, "LeaPlusGlobalPanel_" .. globref)

		-- Store it in the configuration panel table
		tinsert(RGXQoLConfigList, Side)

		-- Set frame parameters
		Side:Hide();
		Side:SetSize(570, RGXQoLLC.MainPanelHeight)
		Side:SetClampedToScreen(true)
		Side:SetClampRectInsets(500, -500, -300, 300)
		Side:SetFrameStrata("FULLSCREEN_DIALOG")

		-- Set the background color
		Side.t = Side:CreateTexture(nil, "BACKGROUND")
		Side.t:SetAllPoints()
		Side.t:SetColorTexture(0.05, 0.05, 0.05, 0.9)

		-- Add a close Button
		Side.c = CreateFrame("Button", nil, Side, "UIPanelCloseButton")
		Side.c:SetSize(30, 30)
		Side.c:SetPoint("TOPRIGHT", 0, 0)
		Side.c:SetScript("OnClick", function() Side:Hide() end)

		-- Add reset, help and back buttons
		Side.r = RGXQoLLC:CreateButton("ResetButton", Side, "Reset", "BOTTOMLEFT", 16, 53, 0, 25, true, "Click to reset the settings on this page.")
		Side.h = RGXQoLLC:CreateButton("HelpButton", Side, "Help", "BOTTOMLEFT", 76, 53, 0, 25, true, "No help is available for this page.")
		Side.b = RGXQoLLC:CreateButton("BackButton", Side, "Back to Main Menu", "BOTTOMRIGHT", -16, 53, 0, 25, true, "Click to return to the main menu.")

		-- Reposition help button so it doesn't overlap reset button
		Side.h:ClearAllPoints()
		Side.h:SetPoint("LEFT", Side.r, "RIGHT", 10, 0)

		-- Remove the click texture from the help button
		Side.h:SetPushedTextOffset(0, 0)

		-- Add a reload button and syncronise it with the main panel reload button
		local reloadb = RGXQoLLC:CreateButton("ConfigReload", Side, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, RGXQoLCB["ReloadUIButton"].tiptext)
		RGXQoLLC:LockItem(reloadb,true)
		reloadb:SetScript("OnClick", ReloadUI)

		reloadb.f = reloadb:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
		reloadb.f:SetHeight(32);
		reloadb.f:SetPoint('RIGHT', reloadb, 'LEFT', -10, 0)
		reloadb.f:SetText(RGXQoLCB["ReloadUIButton"].f:GetText())
		reloadb.f:Hide()

		RGXQoLCB["ReloadUIButton"]:HookScript("OnEnable", function()
			RGXQoLLC:LockItem(reloadb, false)
			reloadb.f:Show()
		end)

		RGXQoLCB["ReloadUIButton"]:HookScript("OnDisable", function()
			RGXQoLLC:LockItem(reloadb, true)
			reloadb.f:Hide()
		end)

		-- Set textures
		RGXQoLLC:CreateBar("FootTexture", Side, 570, 48, "BOTTOM", 0.5, 0.5, 0.5, 1.0, "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
		RGXQoLLC:CreateBar("MainTexture", Side, 570, RGXQoLLC.MainPanelHeight - 47, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")

		-- Allow movement
		Side:EnableMouse(true)
		Side:SetMovable(true)
		Side:RegisterForDrag("LeftButton")
		Side:SetScript("OnDragStart", Side.StartMoving)
		Side:SetScript("OnDragStop", function ()
			Side:StopMovingOrSizing();
			Side:SetUserPlaced(false);
			-- Save panel position
			RGXQoLLC["MainPanelA"], void, RGXQoLLC["MainPanelR"], RGXQoLLC["MainPanelX"], RGXQoLLC["MainPanelY"] = Side:GetPoint()
		end)

		-- Set panel attributes when shown
		Side:SetScript("OnShow", function()
			Side:ClearAllPoints()
			Side:SetPoint(RGXQoLLC["MainPanelA"], UIParent, RGXQoLLC["MainPanelR"], RGXQoLLC["MainPanelX"], RGXQoLLC["MainPanelY"])
			Side:SetScale(RGXQoLLC["PlusPanelScale"])
			Side.t:SetAlpha(1 - RGXQoLLC["PlusPanelAlpha"])
		end)

		-- Add title
		Side.f = Side:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		Side.f:SetPoint('TOPLEFT', 16, -16);
		Side.f:SetText(L[title])

		-- Add description
		Side.v = Side:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
		Side.v:SetHeight(32);
		Side.v:SetPoint('TOPLEFT', Side.f, 'BOTTOMLEFT', 0, -8);
		Side.v:SetPoint('RIGHT', Side, -32, 0)
		Side.v:SetJustifyH('LEFT'); Side.v:SetJustifyV('TOP');
		Side.v:SetText(L["Configuration Panel"])

		-- Prevent options panel from showing while side panel is showing
		RGXQoLLC["PageF"]:HookScript("OnShow", function()
			if Side:IsShown() then RGXQoLLC["PageF"]:Hide(); end
		end)

		-- Create scroll frame if needed
		if scrolling then

			-- Create backdrop
			Side.backFrame = CreateFrame("FRAME", nil, Side, "BackdropTemplate")
			Side.backFrame:SetSize(Side:GetSize())
			Side.backFrame:SetPoint("TOPLEFT", 16, -68)
			Side.backFrame:SetPoint("BOTTOMRIGHT", -16, 98)
			Side.backFrame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
			Side.backFrame:SetBackdropColor(0, 0, 1, 0.5)

			-- Create scroll frame
			Side.scrollFrame = CreateFrame("ScrollFrame", nil, Side.backFrame, "RGXQoLConfigurationPanelScrollFrameTemplate")
			Side.scrollChild = CreateFrame("Frame", nil, Side.scrollFrame)

			Side.scrollChild:SetSize(1, 1)
			Side.scrollFrame:SetScrollChild(Side.scrollChild)
			Side.scrollFrame:SetPoint("TOPLEFT", -8, -6)
			Side.scrollFrame:SetPoint("BOTTOMRIGHT", -29, 6)
			Side.scrollFrame:SetPanExtent(20)

			-- Set scroll list to top when shown
			Side.scrollFrame:HookScript("OnShow", function()
				Side.scrollFrame:SetVerticalScroll(0)
			end)

			-- Add scroll for more message
			local footMessage = RGXQoLLC:MakeTx(Side, "(scroll the list for more)", 16, 0)
			footMessage:ClearAllPoints()
			footMessage:SetPoint("TOPRIGHT", Side.scrollFrame, "TOPRIGHT", 28, 24)

			-- Give child a file level scope (it's used in RGXQoLLC.TipSee)
			RGXQoLLC[globref .. "ScrollChild"] = Side.scrollChild

		end

		-- Return the frame
		return Side

	end

	-- Define subheadings
	function RGXQoLLC:MakeTx(frame, title, x, y)
		local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		text:SetPoint("TOPLEFT", x, y)
		text:SetText(L[title])
		return text
	end

	-- Define text
	function RGXQoLLC:MakeWD(frame, title, x, y)
		local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
		text:SetPoint("TOPLEFT", x, y)
		text:SetText(L[title])
		text:SetJustifyH"LEFT";
		return text
	end

	-- Create a slider control (uses standard template)
	function RGXQoLLC:MakeSL(frame, field, caption, low, high, step, x, y, form)

		-- Create slider control
		local Slider = CreateFrame("Slider", nil, frame, "RGXQoLConfigurationPanelSliderTemplate") -- Old is UISliderTemplate
		RGXQoLCB[field] = Slider
		Slider:SetMinMaxValues(low, high)
		Slider:SetValueStep(step)
		Slider:EnableMouseWheel(true)
		Slider:SetPoint('TOPLEFT', x, y)
		Slider:SetWidth(100)
		Slider:SetHeight(20)
		Slider:SetHitRectInsets(0, 0, 0, 0)
		Slider.tiptext = L[caption]
		Slider:SetScript("OnEnter", RGXQoLLC.TipSee)
		Slider:SetScript("OnLeave", GameTooltip_Hide)

		-- Create slider label
		Slider.f = Slider:CreateFontString(nil, 'BACKGROUND')
		Slider.f:SetFontObject('GameFontHighlight')
		Slider.f:SetPoint('LEFT', Slider, 'RIGHT', 12, 0)
		Slider.f:SetFormattedText("%.2f", Slider:GetValue())

		-- Process mousewheel scrolling
		Slider:SetScript("OnMouseWheel", function(self, arg1)
			if Slider:IsEnabled() then
				local step = step * arg1
				local value = self:GetValue()
				if step > 0 then
					self:SetValue(min(value + step, high))
				else
					self:SetValue(max(value + step, low))
				end
			end
		end)

		-- Process value changed
		Slider:SetScript("OnValueChanged", function(self, value)
			local value = floor((value - low) / step + 0.5) * step + low
			Slider.f:SetFormattedText(form, value)
			RGXQoLLC[field] = value
		end)

		-- Set slider value when shown
		Slider:SetScript("OnShow", function(self)
			self:SetValue(RGXQoLLC[field])
		end)

	end

	-- Create a checkbox control (uses standard template)
 	function RGXQoLLC:MakeCB(parent, field, caption, x, y, reload, tip, tipstyle)

		-- Create the checkbox
		local Cbox = CreateFrame('CheckButton', nil, parent, "ChatConfigCheckButtonTemplate")
		RGXQoLCB[field] = Cbox
		Cbox:SetPoint("TOPLEFT",x, y)
		Cbox:SetScript("OnEnter", RGXQoLLC.TipSee)
		Cbox:SetScript("OnLeave", GameTooltip_Hide)

		-- Add label and tooltip
		Cbox.f = Cbox:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
		Cbox.f:SetPoint('LEFT', 20, 0)

		-- RGXDesign: theme the checkbox label
		local Design = _G.RGXDesign
		if Design then
			Cbox.f:SetTextColor(Design:Unpack("text"))
		end

		if reload then
			-- Checkbox requires UI reload
			Cbox.f:SetText(L[caption] .. "*")
			Cbox.tiptext = L[tip] .. "|n|n* " .. L["Requires UI reload."]
		else
			-- Checkbox does not require UI reload
			Cbox.f:SetText(L[caption])
			Cbox.tiptext = L[tip]
		end

		-- Set label parameters
		Cbox.f:SetJustifyH("LEFT")
		Cbox.f:SetWordWrap(false)

		-- Set maximum label width
		if parent:GetParent() == RGXQoLLC["PageF"] then
			-- Main panel checkbox labels
			if Cbox.f:GetWidth() > 152 then
				Cbox.f:SetWidth(152)
				RGXQoLLC["TruncatedLabelsList"] = RGXQoLLC["TruncatedLabelsList"] or {}
				RGXQoLLC["TruncatedLabelsList"][Cbox.f] = L[caption]
			end
			-- Set checkbox click width
			if Cbox.f:GetStringWidth() > 152 then
				Cbox:SetHitRectInsets(0, -142, 0, 0)
			else
				Cbox:SetHitRectInsets(0, -Cbox.f:GetStringWidth() + 4, 0, 0)
			end
		else
			-- Configuration panel checkbox labels (other checkboxes either have custom functions or blank labels)
			if Cbox.f:GetWidth() > 302 then
				Cbox.f:SetWidth(302)
				RGXQoLLC["TruncatedLabelsList"] = RGXQoLLC["TruncatedLabelsList"] or {}
				RGXQoLLC["TruncatedLabelsList"][Cbox.f] = L[caption]
			end
			-- Set checkbox click width
			if Cbox.f:GetStringWidth() > 302 then
				Cbox:SetHitRectInsets(0, -292, 0, 0)
			else
				Cbox:SetHitRectInsets(0, -Cbox.f:GetStringWidth() + 4, 0, 0)
			end
		end

		-- Set default checkbox state and click area
		Cbox:SetScript('OnShow', function(self)
			if RGXQoLLC[field] == "On" then
				self:SetChecked(true)
			else
				self:SetChecked(false)
			end
		end)

		-- Process clicks
		Cbox:SetScript('OnClick', function()
			if Cbox:GetChecked() then
				RGXQoLLC[field] = "On"
			else
				RGXQoLLC[field] = "Off"
			end
			RGXQoLLC:SetDim(); -- Lock invalid options
			RGXQoLLC:ReloadCheck(); -- Show reload button if needed
		end)
	end

	-- Create an editbox (uses standard template)
	function RGXQoLLC:CreateEditBox(frame, parent, width, maxchars, anchor, x, y, tab, shifttab)

		-- Create editbox
        local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
		RGXQoLCB[frame] = eb
		eb:SetPoint(anchor, x, y)
		eb:SetWidth(width)
		eb:SetHeight(24)
		eb:SetFontObject("GameFontNormal")
		eb:SetTextColor(1.0, 1.0, 1.0)
		eb:SetAutoFocus(false)
		eb:SetMaxLetters(maxchars)
		eb:SetScript("OnEscapePressed", eb.ClearFocus)
		eb:SetScript("OnEnterPressed", eb.ClearFocus)

		-- Add editbox border and backdrop
		eb.f = CreateFrame("FRAME", nil, eb, "BackdropTemplate")
		eb.f:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
		eb.f:SetPoint("LEFT", -6, 0)
		eb.f:SetWidth(eb:GetWidth()+6)
		eb.f:SetHeight(eb:GetHeight())
		eb.f:SetBackdropColor(1.0, 1.0, 1.0, 0.3)

		-- Move onto next editbox when tab key is pressed
		eb:SetScript("OnTabPressed", function(self)
			self:ClearFocus()
			if IsShiftKeyDown() then
				RGXQoLCB[shifttab]:SetFocus()
			else
				RGXQoLCB[tab]:SetFocus()
			end
		end)

		return eb

	end

	-- Create a standard button (using standard button template)
	function RGXQoLLC:CreateButton(name, frame, label, anchor, x, y, width, height, reskin, tip, naked)
		local mbtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		RGXQoLCB[name] = mbtn
		mbtn:SetSize(width, height)
		mbtn:SetPoint(anchor, x, y)
		mbtn:SetHitRectInsets(0, 0, 0, 0)
		mbtn:SetText(L[label])

		-- Create fontstring so the button can be sized correctly
		mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		mbtn.f:SetText(L[label])
		if width > 0 then
			-- Button should have static width
			mbtn:SetWidth(width)
		else
			-- Button should have variable width
			mbtn:SetWidth(mbtn.f:GetStringWidth() + 20)
		end

		-- Tooltip handler
		mbtn.tiptext = L[tip]
		mbtn:SetScript("OnEnter", RGXQoLLC.TipSee)
		mbtn:SetScript("OnLeave", GameTooltip_Hide)

		-- Texture the button
		if reskin then

			-- Set skinned button textures
			if not naked then
				mbtn:SetNormalTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus.blp")
				mbtn:GetNormalTexture():SetTexCoord(0.125, 0.25, 0.21875, 0.25)
			end
			mbtn:SetHighlightTexture("Interface\\AddOns\\RGXQoL\\Leatrix_Plus.blp")
			mbtn:GetHighlightTexture():SetTexCoord(0, 0.125, 0.21875, 0.25)

			-- Hide the default textures
			mbtn:HookScript("OnShow", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			mbtn:HookScript("OnEnable", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			mbtn:HookScript("OnDisable", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			mbtn:HookScript("OnMouseDown", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			mbtn:HookScript("OnMouseUp", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)

		end

		return mbtn
	end

	-- Create a dropdown menu (using standard dropdown template)
	function RGXQoLLC:CreateDropdown(frame, label, width, anchor, parent, relative, x, y, items)

		local RadioDropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
		RGXQoLCB[frame] = RadioDropdown
		RadioDropdown:SetPoint(anchor, parent, relative, x, y)
		RadioDropdown:SetWidth(width)

		local function IsSelected(value)
			return value == RGXQoLLC[frame]
		end

		local function SetSelected(value)
			RGXQoLLC[frame] = value
		end

		MenuUtil.CreateRadioMenu(RadioDropdown, IsSelected, SetSelected, unpack(items))

		local lf = RadioDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal"); lf:SetPoint("TOPLEFT", RadioDropdown, 0, 20); lf:SetPoint("TOPRIGHT", RadioDropdown, -5, 20); lf:SetJustifyH("LEFT"); lf:SetText(L[label])

	end

----------------------------------------------------------------------
-- 	Create main options panel frame
----------------------------------------------------------------------

	function RGXQoLLC:CreateMainPanel()

		-- Create the panel
		local PageF = CreateFrame("Frame", nil, UIParent);

		-- Make it a system frame
		_G["LeaPlusGlobalPanel"] = PageF
		table.insert(UISpecialFrames, "LeaPlusGlobalPanel")

		-- Set frame parameters
		RGXQoLLC["PageF"] = PageF
		PageF:SetSize(570, RGXQoLLC.MainPanelHeight)
		PageF:Hide();
		PageF:SetFrameStrata("FULLSCREEN_DIALOG")
		PageF:SetClampedToScreen(true)
		PageF:SetClampRectInsets(500, -500, -300, 300)
		PageF:EnableMouse(true)
		PageF:SetMovable(true)
		PageF:RegisterForDrag("LeftButton")
		PageF:SetScript("OnDragStart", PageF.StartMoving)
		PageF:SetScript("OnDragStop", function ()
			PageF:StopMovingOrSizing();
			PageF:SetUserPlaced(false);
			-- Save panel position
			RGXQoLLC["MainPanelA"], void, RGXQoLLC["MainPanelR"], RGXQoLLC["MainPanelX"], RGXQoLLC["MainPanelY"] = PageF:GetPoint()
		end)

		-- Add background color (RGXDesign themed)
		local Design = _G.RGXDesign
		PageF.t = PageF:CreateTexture(nil, "BACKGROUND")
		PageF.t:SetAllPoints()
		if Design then
			PageF.t:SetColorTexture(Design:Unpack("surface"))
			local border = CreateFrame("Frame", nil, PageF, "BackdropTemplate")
			border:SetAllPoints()
			border:SetBackdrop({
				edgeFile = "Interface\\Buttons\\WHITE8x8",
				edgeSize = 1,
			})
			border:SetBackdropBorderColor(Design:Unpack("border"))
			border:SetFrameLevel(0)
		else
			PageF.t:SetColorTexture(0.05, 0.05, 0.05, 0.9)
		end

		-- Add textures
		RGXQoLLC:CreateBar("FootTexture", PageF, 570, 48, "BOTTOM", 0.5, 0.5, 0.5, 1.0, "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
		RGXQoLLC:CreateBar("MainTexture", PageF, 440, RGXQoLLC.MainPanelHeight - 47, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
		RGXQoLLC:CreateBar("MenuTexture", PageF, 130, RGXQoLLC.MainPanelHeight - 47, "TOPLEFT", 0.7, 0.7, 0.7, 0.7, "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")

		-- Set panel position when shown
		PageF:SetScript("OnShow", function()
			PageF:ClearAllPoints()
			PageF:SetPoint(RGXQoLLC["MainPanelA"], UIParent, RGXQoLLC["MainPanelR"], RGXQoLLC["MainPanelX"], RGXQoLLC["MainPanelY"])
		end)

		-- Add main title (shown above menu in the corner)
		PageF.mt = PageF:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		PageF.mt:SetPoint('TOPLEFT', 16, -16)
		PageF.mt:SetText("RGX QoL")

		-- RGXDesign: theme the title with the framework accent color
		local Design = _G.RGXDesign
		if Design then
			PageF.mt:SetTextColor(Design:Unpack("primary"))
		end

		-- Add version text (shown underneath main title)
		PageF.v = PageF:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
		PageF.v:SetHeight(32);
		PageF.v:SetPoint('TOPLEFT', PageF.mt, 'BOTTOMLEFT', 0, -8);
		PageF.v:SetPoint('RIGHT', PageF, -32, 0)
		PageF.v:SetJustifyH('LEFT'); PageF.v:SetJustifyV('TOP');
		PageF.v:SetNonSpaceWrap(true); PageF.v:SetText(L["Classic"] .. " " .. RGXQoLLC["AddonVer"])

		-- RGXDesign: theme the version text
		if _G.RGXDesign then
			PageF.v:SetTextColor(_G.RGXDesign:Unpack("subtext"))
		end

		-- Add reload UI Button
		local reloadb = RGXQoLLC:CreateButton("ReloadUIButton", PageF, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, "Your UI needs to be reloaded for some of the changes to take effect.|n|nYou don't have to click the reload button immediately but you do need to click it when you are done making changes and you want the changes to take effect.")
		RGXQoLLC:LockItem(reloadb,true)
		reloadb:SetScript("OnClick", ReloadUI)

		reloadb.f = reloadb:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
		reloadb.f:SetHeight(32);
		reloadb.f:SetPoint('RIGHT', reloadb, 'LEFT', -10, 0)
		reloadb.f:SetText(L["Your UI needs to be reloaded."])
		reloadb.f:Hide()

		-- Add close Button
		local CloseB = CreateFrame("Button", nil, PageF, "UIPanelCloseButton")
		CloseB:SetSize(30, 30)
		CloseB:SetPoint("TOPRIGHT", 0, 0)
		CloseB:SetScript("OnClick", RGXQoLLC.HideFrames)

		-- Add web link Button
		local PageFAlertButton = RGXQoLLC:CreateButton("PageFAlertButton", PageF, "You should keybind web link!", "BOTTOMLEFT", 16, 10, 0, 25, true, "You should set a keybind for the web link feature.  It's very useful.|n|nOpen the key bindings window (accessible from the game menu) and click Leatrix Plus.|n|nSet a keybind for Show web link.|n|nNow when your pointer is over an item, NPC or spell (and more), press your keybind to get a web link.", true)
		PageFAlertButton:SetPushedTextOffset(0, 0)
		PageF:HookScript("OnShow", function()
			if GetBindingKey("RGXQO_GLOBAL_WEBLINK") then PageFAlertButton:Hide() else PageFAlertButton:Show() end
		end)

		-- Release memory
		RGXQoLLC.CreateMainPanel = nil

	end

	RGXQoLLC:CreateMainPanel();

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
				-- Prevent Leatrix Plus from overwriting RGXQoLDB at next logout
				RGXQoLEvt:UnregisterEvent("PLAYER_LOGOUT")
				RGXQoLLC:Print("Leatrix Plus will not overwrite RGXQoLDB at next logout.")
				return
			elseif str == "reset" then
				-- Reset panel positions
				RGXQoLLC["MainPanelA"], RGXQoLLC["MainPanelR"], RGXQoLLC["MainPanelX"], RGXQoLLC["MainPanelY"] = "CENTER", "CENTER", 0, 0
				RGXQoLLC["PlusPanelScale"] = 1
				RGXQoLLC["PlusPanelAlpha"] = 0
				RGXQoLLC["PageF"]:SetScale(1)
				RGXQoLLC["PageF"].t:SetAlpha(1 - RGXQoLLC["PlusPanelAlpha"])
				-- Refresh panels
				RGXQoLLC["PageF"]:ClearAllPoints()
				RGXQoLLC["PageF"]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				-- Reset currently showing configuration panel
				for k, v in pairs(RGXQoLConfigList) do
					if v:IsShown() then
						v:ClearAllPoints()
						v:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
						v:SetScale(1)
						v.t:SetAlpha(1 - RGXQoLLC["PlusPanelAlpha"])
					end
				end
				-- Refresh Leatrix Plus settings menu only
				if RGXQoLLC["Page8"]:IsShown() then
					RGXQoLLC["Page8"]:Hide()
					RGXQoLLC["Page8"]:Show()
				end
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
						for i = 1, GetNumQuestLogEntries() do
							SelectQuestLogEntry(i)
							SetAbandonQuest()
							AbandonQuest()
						end
						RGXQoLLC:Print(L["Quest log wiped."])
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
				if not RGXQoLLC.WowheadLock then
					-- Set Wowhead link prefix
						if GameLocale == "deDE" then RGXQoLLC.WowheadLock = "de.classic.wowhead.com"
					elseif GameLocale == "esMX" then RGXQoLLC.WowheadLock = "mx.classic.wowhead.com"
					elseif GameLocale == "esES" then RGXQoLLC.WowheadLock = "es.classic.wowhead.com"
					elseif GameLocale == "frFR" then RGXQoLLC.WowheadLock = "fr.classic.wowhead.com"
					elseif GameLocale == "itIT" then RGXQoLLC.WowheadLock = "it.classic.wowhead.com"
					elseif GameLocale == "ptBR" then RGXQoLLC.WowheadLock = "pt.classic.wowhead.com"
					elseif GameLocale == "ruRU" then RGXQoLLC.WowheadLock = "ru.classic.wowhead.com"
					elseif GameLocale == "koKR" then RGXQoLLC.WowheadLock = "ko.classic.wowhead.com"
					elseif GameLocale == "zhCN" then RGXQoLLC.WowheadLock = "cn.classic.wowhead.com"
					elseif GameLocale == "zhTW" then RGXQoLLC.WowheadLock = "tw.classic.wowhead.com"
					else							 RGXQoLLC.WowheadLock = "classic.wowhead.com"
					end
				end
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
							RGXQoLLC:ShowSystemEditBox("https://" .. RGXQoLLC.WowheadLock .. "/item=" .. itemID, false)
							RGXQoLLC.FactoryEditBox.f:SetText(L["Item"] .. ": " .. itemLink .. " (" .. itemID .. ")")
							return
						end
					end
					-- Spell
					local name, spellID = tooltip:GetSpell()
					if name and spellID then
						RGXQoLLC:ShowSystemEditBox("https://" .. RGXQoLLC.WowheadLock .. "/spell=" .. spellID, false)
						RGXQoLLC.FactoryEditBox.f:SetText(L["Spell"] .. ": " .. name .. " (" .. spellID .. ")")
						return
					end
					-- NPC
					local npcName = UnitName("mouseover")
					local npcGuid = UnitGUID("mouseover") or nil
					if npcName and npcGuid then
						local void, void, void, void, void, npcID = strsplit("-", npcGuid)
						if npcID then
							RGXQoLLC:ShowSystemEditBox("https://" .. RGXQoLLC.WowheadLock .. "/npc=" .. npcID, false)
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
									RGXQoLLC:ShowSystemEditBox("https://" .. RGXQoLLC.WowheadLock .. "/spell=" .. spellID, false)
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
									RGXQoLLC:ShowSystemEditBox("https://" .. RGXQoLLC.WowheadLock .. "/spell=" .. spellID, false)
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
							RGXQoLLC:ShowSystemEditBox("https://" .. RGXQoLLC.WowheadLock .. "/search?q=" .. tipTitle, false)
							RGXQoLLC.FactoryEditBox.f:SetText("|cffff0000" .. L["Link will search Wowhead"])
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
				if RGXQoLCB["StopMusicBtn"] then RGXQoLCB["StopMusicBtn"]:Click() end
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
				RGXQoLLC:Print(L["Shaders"] .. ": |cffffffff" .. GetCVar("ffxGlow") .. ", " .. GetCVar("ffxDeath") .. ", " .. GetCVar("ffxNether"))
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
				if RGXQoLLC.grid:IsShown() then RGXQoLLC.grid:Hide() else RGXQoLLC.grid:Show() end
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
				RGXQoLDB["Cooldowns"] = nil
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
				-- Help panel
				if not RGXQoLLC.HelpFrame then
					local frame = CreateFrame("FRAME", nil, UIParent)
					frame:SetSize(570, 360); frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(100)
					frame.tex = frame:CreateTexture(nil, "BACKGROUND"); frame.tex:SetAllPoints(); frame.tex:SetColorTexture(0.05, 0.05, 0.05, 0.9)
					frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton"); frame.close:SetSize(30, 30); frame.close:SetPoint("TOPRIGHT", 0, 0); frame.close:SetScript("OnClick", function() frame:Hide() end)
					frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
					frame:SetClampedToScreen(true)
					frame:SetClampRectInsets(450, -450, -300, 300)
					frame:EnableMouse(true)
					frame:SetMovable(true)
					frame:RegisterForDrag("LeftButton")
					frame:SetScript("OnDragStart", frame.StartMoving)
					frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() frame:SetUserPlaced(false) end)
					frame:Hide()
					RGXQoLLC:CreateBar("HelpPanelMainTexture", frame, 570, 360, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
					-- Panel contents
					local col1, col2, color1 = 10, 120, "|cffffffaa"
					RGXQoLLC:MakeTx(frame, "Leatrix Plus Help", col1, -10)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp", col1, -30)
					RGXQoLLC:MakeWD(frame, "Toggle opttions panel.", col2, -30)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp reset", col1, -50)
					RGXQoLLC:MakeWD(frame, "Reset addon panel position and scale.", col2, -50)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp wipe", col1, -70)
					RGXQoLLC:MakeWD(frame, "Wipe all addon settings (reloads UI).", col2, -70)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp realm", col1, -90)
					RGXQoLLC:MakeWD(frame, "Show realms connected to yours.", col2, -90)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp rest", col1, -110)
					RGXQoLLC:MakeWD(frame, "Show number of rested XP bubbles remaining.", col2, -110)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp quest <id>", col1, -130)
					RGXQoLLC:MakeWD(frame, "Show quest completion status for <quest id>.", col2, -130)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp quest wipe", col1, -150)
					RGXQoLLC:MakeWD(frame, "Wipe your quest log.", col2, -150)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp grid", col1, -170)
					RGXQoLLC:MakeWD(frame, "Toggle a frame alignment grid.", col2, -170)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp id", col1, -190)
					RGXQoLLC:MakeWD(frame, "Show a web link for whatever the pointer is over.", col2, -190)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp zygor", col1, -210)
					RGXQoLLC:MakeWD(frame, "Toggle the Zygor addon (reloads UI).", col2, -210)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp movie <id>", col1, -230)
					RGXQoLLC:MakeWD(frame, "Play a movie by its ID.", col2, -230)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp marker", col1, -250)
					RGXQoLLC:MakeWD(frame, "Block target markers (toggle) (requires assistant or leader in raid).", col2, -250)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp rsnd", col1, -270)
					RGXQoLLC:MakeWD(frame, "Restart the sound system.", col2, -270)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp ra", col1, -290)
					RGXQoLLC:MakeWD(frame, "Announce target in General chat channel (useful for rares).", col2, -290)
					RGXQoLLC:MakeWD(frame, color1 .. "/ltp con", col1, -310)
					RGXQoLLC:MakeWD(frame, "Launch the developer console with a large font.", col2, -310)
					RGXQoLLC:MakeWD(frame, color1 .. "/rl", col1, -330)
					RGXQoLLC:MakeWD(frame, "Reload the UI.", col2, -330)
					RGXQoLLC.HelpFrame = frame
					_G["LeaPlusGlobalHelpPanel"] = frame
					table.insert(UISpecialFrames, "LeaPlusGlobalHelpPanel")
				end
				if RGXQoLLC.HelpFrame:IsShown() then RGXQoLLC.HelpFrame:Hide() else RGXQoLLC.HelpFrame:Show() end
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
			elseif str == "limit" then
				-- Sound Limit
				if not RGXQoLLC.MuteFrame then
					-- Panel frame
					local frame = CreateFrame("FRAME", nil, UIParent)
					frame:SetSize(294, 86); frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(100); frame:SetScale(2)
					frame.tex = frame:CreateTexture(nil, "BACKGROUND"); frame.tex:SetAllPoints(); frame.tex:SetColorTexture(0.05, 0.05, 0.05, 0.9)
					frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
					frame.close:SetSize(30, 30)
					frame.close:SetPoint("TOPRIGHT", 0, 0)
					frame.close:SetScript("OnClick", function() frame:Hide() end)
					frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
					frame:SetClampedToScreen(true)
					frame:EnableMouse(true)
					frame:SetMovable(true)
					frame:RegisterForDrag("LeftButton")
					frame:SetScript("OnDragStart", frame.StartMoving)
					frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() frame:SetUserPlaced(false) end)
					frame:Hide()
					RGXQoLLC:CreateBar("MutePanelMainTexture", frame, 294, 86, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
					-- Panel contents
					RGXQoLLC:MakeTx(frame, "Sound Limit", 16, -12)
					local endBox = RGXQoLLC:CreateEditBox("SoundEndBox", frame, 116, 10, "TOPLEFT", 16, -32, "SoundEndBox", "SoundEndBox")
					endBox:SetText(9000000)
					endBox:SetScript("OnMouseWheel", function(self, delta)
						local endSound = tonumber(endBox:GetText())
						if endSound then
							if delta == 1 then endSound = endSound + RGXQoLLC.SoundByte else endSound = endSound - RGXQoLLC.SoundByte end
							if endSound < 1 then endSound = 1 elseif endSound >= 9000000 then endSound = 9000000 end
							endBox:SetText(endSound)
						else
							endSound = 100000
							endBox:SetText(endSound)
						end
					end)
					-- Set limit button
					frame.btn = RGXQoLLC:CreateButton("muteRangeButton", frame, "SET LIMIT", "TOPLEFT", 16, -72, 0, 25, true, "Click to set the sound file limit.  Use the mousewheel on the editbox along with the step buttons below to adjust the sound limit.  Acceptable range is from 1 to 9000000.  Sound files higher than this limit will be muted.")
					frame.btn:ClearAllPoints()
					frame.btn:SetPoint("LEFT", endBox, "RIGHT", 10, 0)
					frame.btn:SetScript("OnClick", function()
						local endSound = tonumber(endBox:GetText())
						if endSound then
							if endSound > 9000000 then endSound = 9000000 endBox:SetText(endSound) end
							frame.btn:SetText("WAIT")
							C_Timer.After(0.1, function()
								for i = 1, 9000000 do
									MuteSoundFile(i)
								end
								for i = 1, endSound do
									UnmuteSoundFile(i)
								end
								Sound_GameSystem_RestartSoundSystem()
								frame.btn:SetText("SET LIMIT")
							end)
						else
							frame.btn:SetText("INVALID")
							frame.btn:EnableMouse(false)
							C_Timer.After(2, function()
								frame.btn:SetText("SET LIMIT")
								frame.btn:EnableMouse(true)
							end)
						end
					end)
					-- Mute all button
					frame.MuteAllBtn = RGXQoLLC:CreateButton("muteMuteAllButton", frame, "MUTE ALL", "TOPLEFT", 16, -92, 0, 25, true, "Click to mute every sound in the game.")
					frame.MuteAllBtn:SetScale(0.5)
					frame.MuteAllBtn:ClearAllPoints()
					frame.MuteAllBtn:SetPoint("TOPLEFT", frame.btn, "TOPRIGHT", 20, 0)
					frame.MuteAllBtn:SetScript("OnClick", function()
						frame.MuteAllBtn:SetText("WAIT")
						C_Timer.After(0.1, function()
							for i = 1, 9000000 do
								MuteSoundFile(i)
							end
							Sound_GameSystem_RestartSoundSystem()
							frame.MuteAllBtn:SetText("MUTE ALL")
						end)
						return
					end)
					-- Unmute all button
					frame.UnmuteAllBtn = RGXQoLLC:CreateButton("muteUnmuteAllButton", frame, "UNMUTE ALL", "TOPLEFT", 16, -92, 0, 25, true, "Click to unmute every sound in the game.")
					frame.UnmuteAllBtn:SetScale(0.5)
					frame.UnmuteAllBtn:ClearAllPoints()
					frame.UnmuteAllBtn:SetPoint("TOPLEFT", frame.MuteAllBtn, "BOTTOMLEFT", 0, -10)
					frame.UnmuteAllBtn:SetScript("OnClick", function()
						frame.UnmuteAllBtn:SetText("WAIT")
						C_Timer.After(0.1, function()
							for i = 1, 9000000 do
								UnmuteSoundFile(i)
							end
							Sound_GameSystem_RestartSoundSystem()
							frame.UnmuteAllBtn:SetText("UNMUTE ALL")
						end)
						return
					end)
					-- Step buttons
					frame.millionBtn = RGXQoLLC:CreateButton("SoundMillionButton", frame, "1000000", "TOPLEFT", 26, -122, 0, 25, true, "Set the editbox step value to 1000000.")
					frame.millionBtn:SetScale(0.5)

					frame.hundredThousandBtn = RGXQoLLC:CreateButton("SoundHundredThousandButton", frame, "100000", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 100000.")
					frame.hundredThousandBtn:ClearAllPoints()
					frame.hundredThousandBtn:SetPoint("LEFT", frame.millionBtn, "RIGHT", 10, 0)
					frame.hundredThousandBtn:SetScale(0.5)

					frame.tenThousandBtn = RGXQoLLC:CreateButton("SoundTenThousandButton", frame, "10000", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 10000.")
					frame.tenThousandBtn:ClearAllPoints()
					frame.tenThousandBtn:SetPoint("LEFT", frame.hundredThousandBtn, "RIGHT", 10, 0)
					frame.tenThousandBtn:SetScale(0.5)

					frame.thousandBtn = RGXQoLLC:CreateButton("SoundThousandButton", frame, "1000", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 1000.")
					frame.thousandBtn:ClearAllPoints()
					frame.thousandBtn:SetPoint("LEFT", frame.tenThousandBtn, "RIGHT", 10, 0)
					frame.thousandBtn:SetScale(0.5)

					frame.hundredBtn = RGXQoLLC:CreateButton("SoundHundredButton", frame, "100", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 100.")
					frame.hundredBtn:ClearAllPoints()
					frame.hundredBtn:SetPoint("LEFT", frame.thousandBtn, "RIGHT", 10, 0)
					frame.hundredBtn:SetScale(0.5)

					frame.tenBtn = RGXQoLLC:CreateButton("SoundTenButton", frame, "10", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 10.")
					frame.tenBtn:ClearAllPoints()
					frame.tenBtn:SetPoint("LEFT", frame.hundredBtn, "RIGHT", 10, 0)
					frame.tenBtn:SetScale(0.5)

					frame.oneBtn = RGXQoLLC:CreateButton("SoundTenButton", frame, "1", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 1.")
					frame.oneBtn:ClearAllPoints()
					frame.oneBtn:SetPoint("LEFT", frame.tenBtn, "RIGHT", 10, 0)
					frame.oneBtn:SetScale(0.5)

					local function DimAllBoxes()
						frame.millionBtn:SetAlpha(0.3)
						frame.hundredThousandBtn:SetAlpha(0.3)
						frame.tenThousandBtn:SetAlpha(0.3)
						frame.thousandBtn:SetAlpha(0.3)
						frame.hundredBtn:SetAlpha(0.3)
						frame.tenBtn:SetAlpha(0.3)
						frame.oneBtn:SetAlpha(0.3)
					end

					RGXQoLLC.SoundByte = 1000000
					DimAllBoxes()
					frame.millionBtn:SetAlpha(1)

					-- Step button handlers
					frame.millionBtn:SetScript("OnClick", function()
						RGXQoLLC.SoundByte = 1000000
						DimAllBoxes()
						frame.millionBtn:SetAlpha(1)
					end)

					frame.hundredThousandBtn:SetScript("OnClick", function()
						RGXQoLLC.SoundByte = 100000
						DimAllBoxes()
						frame.hundredThousandBtn:SetAlpha(1)
					end)

					frame.tenThousandBtn:SetScript("OnClick", function()
						RGXQoLLC.SoundByte = 10000
						DimAllBoxes()
						frame.tenThousandBtn:SetAlpha(1)
					end)

					frame.thousandBtn:SetScript("OnClick", function()
						RGXQoLLC.SoundByte = 1000
						DimAllBoxes()
						frame.thousandBtn:SetAlpha(1)
					end)

					frame.hundredBtn:SetScript("OnClick", function()
						RGXQoLLC.SoundByte = 100
						DimAllBoxes()
						frame.hundredBtn:SetAlpha(1)
					end)

					frame.tenBtn:SetScript("OnClick", function()
						RGXQoLLC.SoundByte = 10
						DimAllBoxes()
						frame.tenBtn:SetAlpha(1)
					end)

					frame.oneBtn:SetScript("OnClick", function()
						RGXQoLLC.SoundByte = 1
						DimAllBoxes()
						frame.oneBtn:SetAlpha(1)
					end)

					-- Final code
					RGXQoLLC.MuteFrame = frame
					_G["LeaPlusGlobalMutePanel"] = frame
					table.insert(UISpecialFrames, "LeaPlusGlobalMutePanel")
				end
				if RGXQoLLC.MuteFrame:IsShown() then RGXQoLLC.MuteFrame:Hide() else RGXQoLLC.MuteFrame:Show() end
				return
			elseif str == "mem" or str == "m" then
				-- Show addon panel with memory usage
				if RGXQoLLC.ShowMemoryUsage then
					RGXQoLLC:ShowMemoryUsage(RGXQoLLC["Page8"], "TOPLEFT", 146, -262)
				end
				-- Prevent options panel from showing if a chat configuration panel is showing
				if ChatConfigFrame:IsShown() then return end
				-- Prevent options panel from showing if Blizzard Store is showing
				if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
				-- Toggle the options panel if game options panel is not showing
				if RGXQoLLC:IsPlusShowing() then
					RGXQoLLC:HideFrames()
					RGXQoLLC:HideConfigPanels()
				else
					RGXQoLLC:HideFrames()
					RGXQoLLC["PageF"]:Show()
				end
				RGXQoLLC["Page"..RGXQoLLC["RGXQoLStartPage"]]:Show()
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
				-- Print saved variables
				RGXQoLLC:Print(L["Saved Variables"] .. "|n")
				RGXQoLLC:Print(L["The following list shows option label, setting name and currently saved value.  Enable |cffffffffIncrease chat history|r (chat) and |cffffffffRecent chat window|r (chat) to make it easier."] .. "|n")
				RGXQoLLC:Print(L["Modifying saved variables must start with |cffffffff/ltp nosave|r to prevent your changes from being reverted during reload or logout."] .. "|n")
				RGXQoLLC:Print(L['Syntax is |cffffffff/run RGXQoLDB[' .. '"' .. 'setting name' .. '"' .. '] = ' .. '"' .. 'value' .. '" |r(case sensitive).'])
				RGXQoLLC:Print(L["When done, |cffffffff/reload|r to save your changes."] .. "|n")
				-- Checkboxes
				RGXQoLLC:Print(L["Checkboxes"] .. "|n")
				RGXQoLLC:Print(L["Checkboxes can be set to On or Off."] .. "|n")
				for key, value in pairs(RGXQoLDB) do
					if RGXQoLCB[key] and RGXQoLCB[key].f then
						if RGXQoLCB[key]:GetObjectType() ~= "Slider" and RGXQoLCB[key]:GetObjectType() ~= "Button" then
							RGXQoLLC:Print(string.gsub(RGXQoLCB[key].f:GetText(), "%*$", "") .. ": |cffffffff" .. key .. "|r |cff1eff0c(" .. value .. ")|r")
						end
					end
				end
				-- Sliders
				RGXQoLLC:Print("|n" .. L["Sliders"] .. "|n")
				RGXQoLLC:Print(L["Sliders can be set to a numeric value which must be in the range supported by the slider."] .. "|n")
				for key, value in pairs(RGXQoLDB) do
					if RGXQoLCB[key] and RGXQoLCB[key].f then
						if RGXQoLCB[key]:GetObjectType() == "Slider" then
							RGXQoLLC:Print("Slider: " .. "|cffffffff" .. key .. "|r |cff1eff0c(" .. value .. ")|r" .. " (" .. string.gsub(RGXQoLCB[key].f:GetText(), "%*$", "") .. ")" )
						end
					end
				end
				-- Dropdowns
				RGXQoLLC:Print("|n" .. L["Dropdowns"] .. "|n")
				RGXQoLLC:Print(L["Dropdowns can be set to a numeric value which must be in the range supported by the dropdown."] .. "|n")
				for key, value in pairs(RGXQoLDB) do
					if RGXQoLCB[key] and RGXQoLCB[key]:GetObjectType() == "Button" and RGXQoLLC[key] then
						RGXQoLLC:Print("Dropdown: " .. "|cffffffff" .. key .. "|r |cff1eff0c(" .. value .. ")|r")
					end
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

				-- Social
				RGXQoLDB["NoDuelRequests"] = "On"				-- Block duels
				RGXQoLDB["NoPartyInvites"] = "Off"				-- Block party invites
				RGXQoLDB["NoFriendRequests"] = "Off"			-- Block friend requests
				RGXQoLDB["NoSharedQuests"] = "Off"				-- Block shared quests

				RGXQoLDB["AcceptPartyFriends"] = "On"			-- Party from friends
				RGXQoLDB["InviteFromWhisper"] = "On"			-- Invite from whispers
				RGXQoLDB["InviteFriendsOnly"] = "On"			-- Restrict invites to friends
				RGXQoLDB["FriendlyGuild"] = "On"				-- Friendly guild

				-- Chat
				RGXQoLDB["UseEasyChatResizing"] = "On"			-- Use easy resizing
				RGXQoLDB["NoCombatLogTab"] = "On"				-- Hide the combat log
				RGXQoLDB["NoChatButtons"] = "On"				-- Hide chat buttons
				RGXQoLDB["UnclampChat"] = "On"					-- Unclamp chat frame
				RGXQoLDB["MoveChatEditBoxToTop"] = "On"		-- Move editbox to top
				RGXQoLDB["MoreFontSizes"] = "On"				-- More font sizes

				RGXQoLDB["NoStickyChat"] = "On"				-- Disable sticky chat
				RGXQoLDB["UseArrowKeysInChat"] = "On"			-- Use arrow keys in chat
				RGXQoLDB["NoChatFade"] = "On"					-- Disable chat fade
				RGXQoLDB["UnivGroupColor"] = "On"				-- Universal group color
				RGXQoLDB["ClassColorsInChat"] = "On"			-- Use class colors in chat
				RGXQoLDB["RecentChatWindow"] = "On"			-- Recent chat window
				RGXQoLDB["RecentChatSize"] = 170				-- Recent chat size
				RGXQoLDB["MaxChatHstory"] = "Off"				-- Increase chat history
				RGXQoLDB["FilterChatMessages"] = "On"			-- Filter chat messages
				RGXQoLDB["BlockDrunkenSpam"] = "On"			-- Block drunken spam
				RGXQoLDB["BlockDuelSpam"] = "On"				-- Block duel spam
				RGXQoLDB["RestoreChatMessages"] = "On"			-- Restore chat messages

				-- Text
				RGXQoLDB["HideErrorMessages"] = "On"			-- Hide error messages
				RGXQoLDB["NoHitIndicators"] = "On"				-- Hide portrait text
				RGXQoLDB["HideKeybindText"] = "On"				-- Hide keybind text
				RGXQoLDB["HideMacroText"] = "On"				-- Hide macro text
				RGXQoLDB["HideRaidGroupLabels"] = "On"			-- Hide raid group labels

				RGXQoLDB["MailFontChange"] = "On"				-- Resize mail text
				RGXQoLDB["LeaPlusMailFontSize"] = 22			-- Mail font size
				RGXQoLDB["QuestFontChange"] = "On"				-- Resize quest text
				RGXQoLDB["LeaPlusQuestFontSize"] = 18			-- Quest font size
				RGXQoLDB["BookFontChange"] = "On"				-- Resize book text
				RGXQoLDB["LeaPlusBookFontSize"] = 22			-- Book font size

				-- Interface
				RGXQoLDB["MinimapModder"] = "On"				-- Enhance minimap
				RGXQoLDB["SquareMinimap"] = "On"				-- Square minimap
				RGXQoLDB["MinimapButtonBag"] = "Off"			-- Minimap button bag
				RGXQoLDB["MiniExcludeList"] = "BugSack, RGXQoL" -- Excluded addon list
				RGXQoLDB["MinimapSize"] = 180					-- Minimap size slider
				RGXQoLDB["MinimapBorderWidth"] = 3				-- Minimap border width
				RGXQoLDB["HideMiniZoneText"] = "On"			-- Hide zone text bar
				RGXQoLDB["HideMiniTracking"] = "On"			-- Hide tracking button
				RGXQoLDB["HideMiniLFG"] = "On"					-- Hide the Looking for Group button

				RGXQoLDB["TipModEnable"] = "On"				-- Enhance tooltip
				RGXQoLDB["LeaPlusTipSize"] = 1.25				-- Tooltip scale slider
				RGXQoLDB["TooltipAnchorMenu"] = 2				-- Tooltip anchor
				RGXQoLDB["TipCursorX"] = 0						-- X offset
				RGXQoLDB["TipCursorY"] = 0						-- Y offset
				RGXQoLDB["EnhanceDressup"] = "On"				-- Enhance dressup
				RGXQoLDB["HideDressupStats"] = "On"			-- Hide dressup stats
				RGXQoLDB["EnhanceQuestLog"] = "On"				-- Enhance quest log
				RGXQoLDB["EnhanceQuestTaller"] = "On"			-- Enhance quest log taller
				RGXQoLDB["EnhanceQuestLevels"] = "On"			-- Enhance quest log quest levels
				RGXQoLDB["EnhanceQuestDifficulty"] = "On"		-- Enhance quest log quest difficulty
				RGXQoLDB["EnhanceProfessions"] = "On"			-- Enhance professions
				RGXQoLDB["EnhanceTrainers"] = "On"				-- Enhance trainers
				RGXQoLDB["ShowTrainAllBtn"] = "On"				-- Show train all button
				RGXQoLDB["EnhanceFlightMap"] = "On"			-- Enhance flight map
				RGXQoLDB["LeaPlusTaxiMapScale"] = 1.9			-- Enhance flight map scale
				RGXQoLDB["LeaPlusTaxiIconSize"] = 10			-- Enhance flight icon size
				RGXQoLDB["FlightMapA"] = "TOPLEFT"				-- Enhance flight map anchor
				RGXQoLDB["FlightMapR"] = "TOPLEFT"				-- Enhance flight map relative
				RGXQoLDB["FlightMapX"] = 0						-- Enhance flight map X
				RGXQoLDB["FlightMapX"] = 61					-- Enhance flight map Y

				RGXQoLDB["ShowVolume"] = "On"					-- Show volume slider
				RGXQoLDB["AhExtras"] = "On"					-- Show auction controls
				RGXQoLDB["ShowCooldowns"] = "On"				-- Show cooldowns
				RGXQoLDB["DurabilityStatus"] = "On"			-- Show durability status
				RGXQoLDB["ShowVanityControls"] = "On"			-- Show vanity controls
				RGXQoLDB["ShowBagSearchBox"] = "On"			-- Show bag search box
				RGXQoLDB["ShowFreeBagSlots"] = "On"			-- Show free bag slots
				RGXQoLDB["ShowRaidToggle"] = "On"				-- Show raid button
				RGXQoLDB["ShowBorders"] = "On"					-- Show borders
				RGXQoLDB["ShowPlayerChain"] = "On"				-- Show player chain
				RGXQoLDB["PlayerChainMenu"] = 3				-- Player chain style
				RGXQoLDB["ShowReadyTimer"] = "On"				-- Show ready timer
				RGXQoLDB["ShowDruidPowerBar"] = "On"			-- Show druid power bar
				RGXQoLDB["ShowDruidStatusText"] = "On"			-- Show druid power bar status text
				RGXQoLDB["ShowWowheadLinks"] = "On"			-- Show Wowhead links
				RGXQoLDB["WowheadLinkComments"] = "On"			-- Show Wowhead links to comments

				-- Frames
				RGXQoLDB["ManageWidget"] = "On"				-- Manage widget
				RGXQoLDB["WidgetA"] = "TOP"					-- Manage widget anchor
				RGXQoLDB["WidgetR"] = "TOP"					-- Manage widget relative
				RGXQoLDB["WidgetX"] = 0						-- Manage widget position X
				RGXQoLDB["WidgetY"] = -432						-- Manage widget position Y
				RGXQoLDB["WidgetScale"] = 1.25					-- Manage widget scale

				RGXQoLDB["ManageTimer"] = "On"					-- Manage timer
				RGXQoLDB["TimerA"] = "TOP"						-- Manage timer anchor
				RGXQoLDB["TimerR"] = "TOP"						-- Manage timer relative
				RGXQoLDB["TimerX"] = 0							-- Manage timer position X
				RGXQoLDB["TimerY"] = -120						-- Manage timer position Y
				RGXQoLDB["TimerScale"] = 1.00					-- Manage timer scale

				RGXQoLDB["ClassColFrames"] = "On"				-- Class colored frames

				RGXQoLDB["NoGryphons"] = "On"					-- Hide gryphons
				RGXQoLDB["NoClassBar"] = "On"					-- Hide stance bar

				-- System
				RGXQoLDB["NoScreenGlow"] = "On"				-- Disable screen glow
				RGXQoLDB["NoScreenEffects"] = "On"				-- Disable screen effects
				RGXQoLDB["SetWeatherDensity"] = "On"			-- Set weather density
				RGXQoLDB["WeatherLevel"] = 0					-- Weather density level
				RGXQoLDB["MaxCameraZoom"] = "On"				-- Max camera zoom
				RGXQoLDB["NoRestedEmotes"] = "On"				-- Silence rested emotes
				RGXQoLDB["KeepAudioSynced"] = "On"				-- Keep audio synced
				RGXQoLDB["MuteGameSounds"] = "On"				-- Mute game sounds
				RGXQoLDB["MuteCustomSounds"] = "On"			-- Mute custom sounds
				RGXQoLDB["MuteCustomList"] = ""				-- Mute custom sounds list

				RGXQoLDB["NoBagAutomation"] = "On"				-- Disable bag automation
				RGXQoLDB["NoConfirmLoot"] = "On"				-- Disable loot warnings
				RGXQoLDB["FasterLooting"] = "On"				-- Faster auto loot
				RGXQoLDB["FasterMovieSkip"] = "On"				-- Faster movie skip
				RGXQoLDB["StandAndDismount"] = "On"			-- Dismount me
				RGXQoLDB["ShowVendorPrice"] = "On"				-- Show vendor price
				RGXQoLDB["CombatPlates"] = "On"				-- Combat plates
				RGXQoLDB["EasyItemDestroy"] = "On"				-- Easy item destroy

				RGXQoLDB["ShowFlightTimes"] = "On"				-- Show flight times
				RGXQoLDB["FlightBarBackground"] = "Off"		-- Show flight times bar background
				RGXQoLDB["FlightBarDestination"] = "On"		-- Show flight times bar destination
				RGXQoLDB["FlightBarFillBar"] = "Off"			-- Show flight times bar fill mode
				RGXQoLDB["FlightBarSpeech"] = "On"				-- Show flight times bar speech
				RGXQoLDB["FlightBarContribute"] = "On"			-- Show flight times contribute

				-- Settings
				RGXQoLDB["UseEnglishLanguage"] = "On"			-- Use English language

				-- Function to assign cooldowns
				local function setIcon(pclass, pspec, sp1, pt1, sp2, pt2, sp3, pt3, sp4, pt4, sp5, pt5)
					-- Set spell ID
					if sp1 == 0 then RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R1Idn"] = "" else RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R1Idn"] = sp1 end
					if sp2 == 0 then RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R2Idn"] = "" else RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R2Idn"] = sp2 end
					if sp3 == 0 then RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R3Idn"] = "" else RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R3Idn"] = sp3 end
					if sp4 == 0 then RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R4Idn"] = "" else RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R4Idn"] = sp4 end
					if sp5 == 0 then RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R5Idn"] = "" else RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R5Idn"] = sp5 end
					-- Set pet checkbox
					if pt1 == 0 then RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R1Pet"] = false else RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R1Pet"] = true end
					if pt2 == 0 then RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R2Pet"] = false else RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R2Pet"] = true end
					if pt3 == 0 then RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R3Pet"] = false else RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R3Pet"] = true end
					if pt4 == 0 then RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R4Pet"] = false else RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R4Pet"] = true end
					if pt5 == 0 then RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R5Pet"] = false else RGXQoLDB["Cooldowns"][pclass]["S" .. pspec .. "R5Pet"] = true end
				end

				-- Create main table
				RGXQoLDB["Cooldowns"] = {}

				-- Create class tables
				local classList = {"WARRIOR", "PALADIN", "HUNTER", "SHAMAN", "ROGUE", "DRUID", "MAGE", "WARLOCK", "PRIEST"}
				for index = 1, #classList do
					if RGXQoLDB["Cooldowns"][classList[index]] == nil then
						RGXQoLDB["Cooldowns"][classList[index]] = {}
					end
				end

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

				-- Mute game sounds (RGXQoLLC["MuteGameSounds"])
				for k, v in pairs(RGXQoLLC["muteTable"]) do
					RGXQoLDB[k] = "On"
				end
				RGXQoLDB["MuteReady"] = "Off"	-- Mute ready check

				-- Mute mount sounds (RGXQoLLC["MuteMountSounds"])
				for k, v in pairs(RGXQoLLC["mountTable"]) do
					RGXQoLDB[k] = "On"
				end

				-- Set chat font sizes
				RunScript('for i = 1, 50 do if _G["ChatFrame" .. i] then FCF_SetChatWindowFontSize(self, _G["ChatFrame" .. i], 20) end end')

				-- Reload
				ReloadUI()
			else
				RGXQoLLC:Print("Invalid parameter.")
			end
			return
		else
			-- Prevent options panel from showing if a chat configuration panel is showing
			if ChatConfigFrame:IsShown() then return end
			-- Prevent options panel from showing if Blizzard Store is showing
			if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
			-- Toggle the options panel if game options panel is not showing
			if RGXQoLLC:IsPlusShowing() then
				RGXQoLLC:HideFrames()
				RGXQoLLC:HideConfigPanels()
			else
				RGXQoLLC:HideFrames()
				RGXQoLLC["PageF"]:Show()
			end
			RGXQoLLC["Page"..RGXQoLLC["RGXQoLStartPage"]]:Show()
		end
	end

	-- Slash command for global function
	_G.SLASH_RGXQoL1 = "/ltp"
	_G.SLASH_RGXQoL2 = "/qol"
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
-- 	L90: Create options panel pages (no content yet)
----------------------------------------------------------------------

	-- Function to add menu button
	function RGXQoLLC:MakeMN(name, text, parent, anchor, x, y, width, height)

		local mbtn = CreateFrame("Button", nil, parent)
		RGXQoLLC[name] = mbtn
		mbtn:Show();
		mbtn:SetSize(width, height)
		mbtn:SetPoint(anchor, x, y)

		-- Selection highlight (the .s texture page navigation toggles)
		mbtn.s = mbtn:CreateTexture(nil, "OVERLAY")
		mbtn.s:SetAllPoints()
		mbtn.s:SetColorTexture(0.55, 0.08, 0.22, 0.35)
		mbtn.s:Hide()

		-- Label (always created, Design-themed or plain)
		mbtn.f = mbtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		mbtn.f:SetPoint("CENTER", 0, 0)
		mbtn.f:SetText(L[text] or text)

		local Design = _G.RGXDesign
		if Design then
			local bg = mbtn:CreateTexture(nil, "BACKGROUND")
			bg:SetAllPoints()
			bg:SetColorTexture(Design:Unpack("surface"))
			mbtn.bg = bg

			local border = CreateFrame("Frame", nil, mbtn, "BackdropTemplate")
			border:SetAllPoints()
			border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
			border:SetBackdropBorderColor(Design:Unpack("border"))
			mbtn.border = border

			mbtn.f:SetTextColor(Design:Unpack("text"))

			mbtn:SetScript("OnEnter", function(self)
				self.bg:SetColorTexture(Design:Unpack("hover"))
				self.f:SetTextColor(Design:Unpack("primary"))
				self.border:SetBackdropBorderColor(Design:Unpack("primary"))
			end)

			mbtn:SetScript("OnLeave", function(self)
				self.bg:SetColorTexture(Design:Unpack("surface"))
				self.f:SetTextColor(Design:Unpack("text"))
				self.border:SetBackdropBorderColor(Design:Unpack("border"))
			end)
		else
			mbtn:SetAlpha(1.0)
		end

		return mbtn, mbtn.s
	end

	-- Function to create individual options panel pages
	function RGXQoLLC:MakePage(name, title, menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)

		-- Create frame
		local oPage = CreateFrame("Frame", nil, RGXQoLLC["PageF"]);
		RGXQoLLC[name] = oPage
		oPage:SetAllPoints(RGXQoLLC["PageF"])
		oPage:Hide();

		-- Add page title
		oPage.s = oPage:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		oPage.s:SetPoint('TOPLEFT', 146, -16)
		oPage.s:SetText(L[title])

		-- Add menu item if needed
		if menu then
			RGXQoLLC[menu], RGXQoLLC[menu .. ".s"] = RGXQoLLC:MakeMN(menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)
			RGXQoLLC[name]:SetScript("OnShow", function() RGXQoLLC[menu .. ".s"]:Show(); end)
			RGXQoLLC[name]:SetScript("OnHide", function() RGXQoLLC[menu .. ".s"]:Hide(); end)
		end

		return oPage;

	end

	-- Create options pages
	RGXQoLLC["Page0"] = RGXQoLLC:MakePage("Page0", "Home"			, "LeaPlusNav0", "Home"			, RGXQoLLC["PageF"], "TOPLEFT", 16, -72, 112, 20)
	RGXQoLLC["Page1"] = RGXQoLLC:MakePage("Page1", "Automation"	, "LeaPlusNav1", "Automation"	, RGXQoLLC["PageF"], "TOPLEFT", 16, -112, 112, 20)
	RGXQoLLC["Page2"] = RGXQoLLC:MakePage("Page2", "Social"		, "LeaPlusNav2", "Social"		, RGXQoLLC["PageF"], "TOPLEFT", 16, -132, 112, 20)
	RGXQoLLC["Page3"] = RGXQoLLC:MakePage("Page3", "Chat"			, "LeaPlusNav3", "Chat"			, RGXQoLLC["PageF"], "TOPLEFT", 16, -152, 112, 20)
	RGXQoLLC["Page4"] = RGXQoLLC:MakePage("Page4", "Text"			, "LeaPlusNav4", "Text"			, RGXQoLLC["PageF"], "TOPLEFT", 16, -172, 112, 20)
	RGXQoLLC["Page5"] = RGXQoLLC:MakePage("Page5", "Interface"	, "LeaPlusNav5", "Interface"	, RGXQoLLC["PageF"], "TOPLEFT", 16, -192, 112, 20)
	RGXQoLLC["Page6"] = RGXQoLLC:MakePage("Page6", "Frames"		, "LeaPlusNav6", "Frames"		, RGXQoLLC["PageF"], "TOPLEFT", 16, -212, 112, 20)
	RGXQoLLC["Page7"] = RGXQoLLC:MakePage("Page7", "System"		, "LeaPlusNav7", "System"		, RGXQoLLC["PageF"], "TOPLEFT", 16, -232, 112, 20)
	RGXQoLLC["Page8"] = RGXQoLLC:MakePage("Page8", "Settings"		, "LeaPlusNav8", "Settings"		, RGXQoLLC["PageF"], "TOPLEFT", 16, -272, 112, 20)

	-- Page navigation mechanism
	for i = 0, RGXQoLLC["NumberOfPages"] do
		RGXQoLLC["LeaPlusNav"..i]:SetScript("OnClick", function()
			RGXQoLLC:HideFrames()
			RGXQoLLC["PageF"]:Show();
			RGXQoLLC["Page"..i]:Show();
			RGXQoLLC["RGXQoLStartPage"] = i
		end)
	end

	-- Use a variable to contain the page number (makes it easier to move options around)
	local pg;

----------------------------------------------------------------------
-- 	LC0: Welcome
----------------------------------------------------------------------

	pg = "Page0";

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Welcome to Leatrix Plus.", 146, -72);
	RGXQoLLC:MakeWD(RGXQoLLC[pg], "To begin, choose an options page.", 146, -92);

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Support", 146, -132);
	RGXQoLLC:MakeWD(RGXQoLLC[pg], "curseforge.com/wow/addons/leatrix-plus", 146, -152);

----------------------------------------------------------------------
-- 	LC1: Automation
----------------------------------------------------------------------

	pg = "Page1";

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Character"					, 	146, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "AutomateQuests"			,	"Automate quests"				,	146, -92, 	false,	"If checked, quests will be selected, accepted and turned-in automatically.|n|nQuests which have a gold requirement will not be turned-in automatically.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "AutomateGossip"			,	"Automate gossip"				,	146, -112, 	false,	"If checked, you can hold down the alt key while opening a gossip window to automatically select a single gossip item.|n|nIf the gossip item type is banker, taxi, trainer, vendor or battlemaster, gossip will be skipped without needing to hold the alt key.  You can hold the shift key down to prevent this.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "AutoAcceptSummon"			,	"Accept summon"					, 	146, -132, 	false,	"If checked, summon requests will be accepted automatically unless you are in combat.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "AutoAcceptRes"				,	"Accept resurrection"			, 	146, -152, 	false,	"If checked, resurrection requests will be accepted automatically.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "AutoReleasePvP"			,	"Release in PvP"				, 	146, -172, 	false,	"If checked, you will release automatically after you die in a battleground.|n|nYou will not release automatically if you have the ability to self-resurrect.")

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Vendors"					, 	340, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "AutoSellJunk"				,	"Sell junk automatically"		,	340, -92, 	false,	"If checked, all grey items in your bags will be sold automatically when you visit a merchant.|n|nYou can hold the shift key down when you talk to a merchant to override this setting.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "AutoRepairGear"			, 	"Repair automatically"			,	340, -112, 	false,	"If checked, your gear will be repaired automatically when you visit a suitable merchant.|n|nYou can hold the shift key down when you talk to a merchant to override this setting.")

	RGXQoLLC:CfgBtn("AutomateQuestsBtn", RGXQoLCB["AutomateQuests"])
	RGXQoLLC:CfgBtn("AutoAcceptResBtn", RGXQoLCB["AutoAcceptRes"])
	RGXQoLLC:CfgBtn("AutoReleasePvPBtn", RGXQoLCB["AutoReleasePvP"])
	RGXQoLLC:CfgBtn("AutoSellJunkBtn", RGXQoLCB["AutoSellJunk"])
	RGXQoLLC:CfgBtn("AutoRepairBtn", RGXQoLCB["AutoRepairGear"])

----------------------------------------------------------------------
-- 	LC2: Social
----------------------------------------------------------------------

	pg = "Page2";

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Blocks"					, 	146, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoDuelRequests"			, 	"Block duels"					,	146, -92, 	false,	"If checked, duel requests will be blocked unless the player requesting the duel is a friend.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoPartyInvites"			, 	"Block party invites"			, 	146, -112, 	false,	"If checked, party invitations will be blocked unless the player inviting you is a friend.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoFriendRequests"			, 	"Block friend requests"			, 	146, -132, 	false,	"If checked, BattleTag and Real ID friend requests will be automatically declined.|n|nEnabling this option will automatically decline any pending requests.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoSharedQuests"			, 	"Block shared quests"			, 	146, -152, 	false,	"If checked, shared quests will be declined unless the player sharing the quest is a friend.")

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Groups"					, 	340, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "AcceptPartyFriends"		, 	"Party from friends"			, 	340, -92, 	false,	"If checked, party invitations from friends will be automatically accepted unless you are queued for a battleground or the Looking for Group feature.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "InviteFromWhisper"			,   "Invite from whispers"			,	340, -112,	false,	L["If checked, a group invite will be sent to anyone who whispers you with a set keyword as long as you are ungrouped, group leader or raid assistant and not queued for a battleground or the Looking for Group feature.|n|nFriends who message the keyword using Battle.net will not be sent a group invite if they are appearing offline.  They need to either change their online status or use character whispers."] .. "|n|n" .. L["Keyword"] .. ": |cffffffff" .. "dummy" .. "|r")

	local FriendlyGuildFooter = RGXQoLLC:MakeFT(RGXQoLLC[pg], "For all of the social options above, you can treat guild members as friends too.", 146, 380)
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "FriendlyGuild"				, 	"Guild"							, 	146, -282, 	false,	"If checked, members of your guild will be treated as friends for all of the options on this page.")
	RGXQoLCB["FriendlyGuild"]:ClearAllPoints()
	RGXQoLCB["FriendlyGuild"]:SetPoint("TOPLEFT", FriendlyGuildFooter, "BOTTOMLEFT", 0, -10)
	if RGXQoLCB["FriendlyGuild"].f:GetStringWidth() > 90 then
		RGXQoLCB["FriendlyGuild"].f:SetWidth(90)
		RGXQoLCB["FriendlyGuild"]:SetHitRectInsets(0, -84, 0, 0)
	end

	RGXQoLLC:CfgBtn("InvWhisperBtn", RGXQoLCB["InviteFromWhisper"])

----------------------------------------------------------------------
-- 	LC3: Chat
----------------------------------------------------------------------

	pg = "Page3";

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Chat Frame"				, 	146, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "UseEasyChatResizing"		,	"Use easy resizing"				,	146, -92,	true,	"If checked, dragging the General chat tab while the chat frame is locked will expand the chat frame upwards.|n|nIf the chat frame is unlocked, dragging the General chat tab will move the chat frame.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoCombatLogTab" 			, 	"Hide the combat log"			, 	146, -112, 	true,	"If checked, the combat log will be hidden.|n|nThe combat log must be docked in order for this option to work.|n|nIf the combat log is undocked, you can dock it by dragging the tab (and reloading your UI) or by resetting the chat windows (from the chat menu).")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoChatButtons"				,	"Hide chat buttons"				,	146, -132,	true,	"If checked, chat frame buttons will be hidden.|n|nClicking chat tabs will automatically show the latest messages.|n|nUse the mouse wheel to scroll through the chat history.  Hold down SHIFT for page jump or CTRL to jump to the top or bottom of the chat history.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "UnclampChat"				,	"Unclamp chat frame"			,	146, -152,	true,	"If checked, you will be able to drag the chat frame to the edge of the screen.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "MoveChatEditBoxToTop" 		, 	"Move editbox to top"			,	146, -172, 	true,	"If checked, the editbox will be moved to the top of the chat frame.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "MoreFontSizes"		 		, 	"More font sizes"				,	146, -192, 	true,	"If checked, additional font sizes will be available in the chat frame font size menu.")

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Mechanics"					, 	340, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoStickyChat"				, 	"Disable sticky chat"			,	340, -92,	true,	"If checked, sticky chat will be disabled.|n|nNote that this does not apply to temporary chat windows.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "UseArrowKeysInChat"		, 	"Use arrow keys in chat"		, 	340, -112, 	true,	"If checked, you can press the arrow keys to move the insertion point left and right in the chat frame.|n|nIf unchecked, the arrow keys will use the default keybind setting.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoChatFade"				, 	"Disable chat fade"				, 	340, -132, 	true,	"If checked, chat text will not fade out after a time period.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "UnivGroupColor"			,	"Universal group color"			,	340, -152,	false,	"If checked, raid chat will be colored blue (to match the default party chat color).")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ClassColorsInChat"			,	"Use class colors in chat"		,	340, -172,	true,	"If checked, class colors will be used in the chat frame.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "RecentChatWindow"			,	"Recent chat window"			, 	340, -192, 	true,	"If checked, you can hold down the control key and click a chat tab to view recent chat in a copy-friendly window.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "MaxChatHstory"				,	"Increase chat history"			, 	340, -212, 	true,	"If checked, your chat history will increase to 4096 lines.  If unchecked, the default will be used (128 lines).|n|nEnabling this option may prevent some chat text from showing during login.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "FilterChatMessages"		, 	"Filter chat messages"			,	340, -232, 	true,	"If checked, you can block drunken spam and duel spam.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "RestoreChatMessages"		, 	"Restore chat messages"			,	340, -252, 	true,	"If checked, recent chat will be restored when you reload your interface.")

	RGXQoLLC:CfgBtn("FilterChatMessagesBtn", RGXQoLCB["FilterChatMessages"])

----------------------------------------------------------------------
-- 	LC4: Text
----------------------------------------------------------------------

	pg = "Page4";

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Visibility"				, 	146, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "HideErrorMessages"			, 	"Hide error messages"			,	146, -92, 	true,	"If checked, most error messages (such as 'Not enough rage') will not be shown.  Some important errors are excluded.|n|nIf you have the minimap button enabled, you can hold down the alt key and click it to toggle error messages without affecting this setting.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoHitIndicators"			, 	"Hide portrait numbers"			,	146, -112, 	true,	"If checked, damage and healing numbers in the player and pet portrait frames will be hidden.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "HideZoneText"				,	"Hide zone text"				,	146, -132, 	true,	"If checked, zone text will not be shown (eg. 'Ironforge').")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "HideKeybindText"			,	"Hide keybind text"				,	146, -152, 	true,	"If checked, keybind text will not be shown on action buttons.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "HideMacroText"				,	"Hide macro text"				,	146, -172, 	true,	"If checked, macro text will not be shown on action buttons.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "HideRaidGroupLabels"		,	"Hide raid group labels"		,	146, -192, 	true,	"If checked, the player frame group indicator and the group labels displayed above the compact raid frames and the pullout raid frames will be hidden.")

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Text Size"					, 	340, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "MailFontChange"			,	"Resize mail text"				, 	340, -92, 	true,	"If checked, you will be able to change the font size of standard mail text.|n|nThis does not affect mail created using templates (such as auction house invoices).")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "QuestFontChange"			,	"Resize quest text"				, 	340, -112, 	true,	"If checked, you will be able to change the font size of quest text.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "BookFontChange"			,	"Resize book text"				, 	340, -132, 	true,	"If checked, you will be able to change the font size of book text.")

	RGXQoLLC:CfgBtn("MailTextBtn", RGXQoLCB["MailFontChange"])
	RGXQoLLC:CfgBtn("QuestTextBtn", RGXQoLCB["QuestFontChange"])
	RGXQoLLC:CfgBtn("BookTextBtn", RGXQoLCB["BookFontChange"])

----------------------------------------------------------------------
-- 	LC5: Interface
----------------------------------------------------------------------

	pg = "Page5";

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Enhancements"				, 	146, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "MinimapModder"				,	"Enhance minimap"				, 	146, -92, 	true,	"If checked, you will be able to customise the minimap.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "TipModEnable"				,	"Enhance tooltip"				,	146, -112, 	true,	"If checked, the tooltip will be color coded and you will be able to modify the tooltip layout and scale.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "EnhanceDressup"			, 	"Enhance dressup"				,	146, -132, 	true,	"If checked, you will be able to pan (right-button) and zoom (mousewheel) in the character frame, dressup frame and inspect frame.|n|nA toggle stats button will be shown in the character frame.  You can also middle-click the character model to toggle stats.|n|nModel rotation controls will be hidden.  Buttons to toggle gear will be added to the dressup frame.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "EnhanceQuestLog"			, 	"Enhance quest log"				,	146, -152, 	true,	"If checked, the quest log frame will be larger and feature a world map button and quest levels.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "EnhanceProfessions"		, 	"Enhance professions"			,	146, -172, 	true,	"If checked, the professions frame will be larger.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "EnhanceTrainers"			, 	"Enhance trainers"				,	146, -192, 	true,	"If checked, the skill trainer frame will be larger and feature a train all skills button.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "EnhanceFlightMap"			, 	"Enhance flight map"			,	146, -212, 	true,	"If checked, you will be able to customise the flight map.")

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Extras"					, 	146, -252);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowVolume"				, 	"Show volume slider"			, 	146, -272, 	true,	"If checked, a master volume slider will be shown in the character frame.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "AhExtras"					, 	"Show auction controls"			, 	146, -292, 	true,	"If checked, additional functionality will be added to the auction house.|n|nBuyout only - create buyout auctions without filling in the starting price.|n|nGold only - set the copper and silver prices at 99 to speed up new auctions.|n|nFind item - search the auction house for the item you are selling.|n|nIn addition, the auction duration setting will be saved account-wide.")

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Extras"					, 	340, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowCooldowns"				, 	"Show cooldowns"				, 	340, -92, 	true,	"If checked, you will be able to place up to five beneficial cooldown icons above the target frame.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "DurabilityStatus"			, 	"Show durability status"		, 	340, -112, 	true,	"If checked, a button will be added to the character frame which will show your equipped item durability when you hover the pointer over it.|n|nIn addition, an overall percentage will be shown in the chat frame when you die.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowVanityControls"		, 	"Show vanity controls"			, 	340, -132, 	true,	"If checked, helm and cloak toggle checkboxes will be shown in the character frame.|n|nYou can hold shift and right-click the checkboxes to switch layouts.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowBagSearchBox"			, 	"Show bag search box"			, 	340, -152, 	true,	"If checked, a bag search box will be shown in the backpack frame and the bank frame.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowFreeBagSlots"			, 	"Show free bag slots"			, 	340, -172, 	true,	"If checked, the number of free bag slots will be shown in the backpack button icon and tooltip.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowRaidToggle"			, 	"Show raid button"				,	340, -192, 	true,	"If checked, the button to toggle the raid container frame will be shown just above the raid management frame (left side of the screen) instead of in the raid management frame itself.|n|nThis allows you to toggle the raid container frame without needing to open the raid management frame.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowBorders"				,	"Show borders"					,	340, -212, 	true,	"If checked, you will be able to show customisable borders around the edges of the screen.|n|nThe borders are placed on top of the game world but under the UI so you can place UI elements over them.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowPlayerChain"			, 	"Show player chain"				,	340, -232, 	true,	"If checked, you will be able to show a rare, elite or rare elite chain around the player frame.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowDruidPowerBar"			, 	"Show druid power bar"			,	340, -252, 	true,	"If checked, a power bar will be shown in the player frame when you are playing a shapeshifted druid.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowReadyTimer"			, 	"Show ready timer"				,	340, -272, 	true,	"If checked, a timer will be shown under the PvP encounter ready frame so that you know how long you have left to click the enter button.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowWowheadLinks"			, 	"Show Wowhead links"			, 	340, -292, 	true,	"If checked, Wowhead links will be shown above the quest log frame.")

	RGXQoLLC:CfgBtn("ModMinimapBtn", RGXQoLCB["MinimapModder"])
	RGXQoLLC:CfgBtn("MoveTooltipButton", RGXQoLCB["TipModEnable"])
	RGXQoLLC:CfgBtn("EnhanceDressupBtn", RGXQoLCB["EnhanceDressup"])
	RGXQoLLC:CfgBtn("EnhanceQuestLogBtn", RGXQoLCB["EnhanceQuestLog"])
	RGXQoLLC:CfgBtn("EnhanceTrainersBtn", RGXQoLCB["EnhanceTrainers"])
	RGXQoLLC:CfgBtn("EnhanceFlightMapBtn", RGXQoLCB["EnhanceFlightMap"])
	RGXQoLLC:CfgBtn("CooldownsButton", RGXQoLCB["ShowCooldowns"])
	RGXQoLLC:CfgBtn("ModBordersBtn", RGXQoLCB["ShowBorders"])
	RGXQoLLC:CfgBtn("ModPlayerChain", RGXQoLCB["ShowPlayerChain"])
	RGXQoLLC:CfgBtn("ShowDruidPowerBarBtn", RGXQoLCB["ShowDruidPowerBar"])
	RGXQoLLC:CfgBtn("ShowWowheadLinksBtn", RGXQoLCB["ShowWowheadLinks"])

----------------------------------------------------------------------
-- 	LC6: Frames
----------------------------------------------------------------------

	pg = "Page6";

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Features"					, 	146, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ManageWidget"				,	"Manage widget"					, 	146, -92, 	true,	"If checked, you will be able to change the position and scale of the widget frame.|n|nThe widget frame is commonly used for showing PvP scores and tracking objectives.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ManageTimer"				,	"Manage timer"					, 	146, -112, 	true,	"If checked, you will be able to change the position and scale of the timer bar.|n|nThe timer bar is used for showing remaining breath when underwater as well as other things.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ClassColFrames"			, 	"Class colored frames"			,	146, -132, 	true,	"If checked, class coloring will be used in the player frame and target frame.")

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Visibility"				, 	340, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoGryphons"				,	"Hide gryphons"					, 	340, -92, 	true,	"If checked, the main bar gryphons will not be shown.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoClassBar"				,	"Hide stance bar"				, 	340, -112, 	true,	"If checked, the stance bar will not be shown.")

	RGXQoLLC:CfgBtn("ManageWidgetButton", RGXQoLCB["ManageWidget"])
	RGXQoLLC:CfgBtn("ManageTimerButton", RGXQoLCB["ManageTimer"])
	RGXQoLLC:CfgBtn("ClassColFramesBtn", RGXQoLCB["ClassColFrames"])

----------------------------------------------------------------------
-- 	LC7: System
----------------------------------------------------------------------

	pg = "Page7";

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Graphics and Sound"		, 	146, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoScreenGlow"				, 	"Disable screen glow"			, 	146, -92, 	false,	"If checked, the screen glow will be disabled.|n|nEnabling this option will also disable the drunken haze effect.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoScreenEffects"			, 	"Disable screen effects"		, 	146, -112, 	false,	"If checked, the grey screen of death and the netherworld effect will be disabled.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "SetWeatherDensity"			, 	"Set weather density"			, 	146, -132, 	false,	"If checked, you will be able to set the density of weather effects.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "MaxCameraZoom"				, 	"Max camera zoom"				, 	146, -152, 	false,	"If checked, you will be able to zoom out to a greater distance.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoRestedEmotes"			, 	"Silence rested emotes"			,	146, -172, 	true,	"If checked, emote sounds will be silenced while your character is resting or at the Grim Guzzler.|n|nEmote sounds will be enabled at all other times.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "KeepAudioSynced"			, 	"Keep audio synced"				,	146, -192, 	true,	"If checked, when you change the audio output device in your operating system, the game audio output device will change automatically as long as a cinematic is not playing at the time.|n|nFor this to work, the game audio output device will be set to system default.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "MuteGameSounds"			, 	"Mute game sounds"				,	146, -212, 	false,	"If checked, you will be able to mute a selection of game sounds.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "MuteMountSounds"			, 	"Mute mount sounds"				,	146, -232, 	false,	"If checked, you will be able to mute a selection of mount sounds.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "MuteCustomSounds"			, 	"Mute custom sounds"			,	146, -252, 	false,	"If checked, you will be able to mute your own choice of sounds.")

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Game Options"				, 	340, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoBagAutomation"			, 	"Disable bag automation"		, 	340, -92, 	true,	"If checked, your bags will not be opened or closed automatically when you interact with a merchant, bank or mailbox.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "NoConfirmLoot"				, 	"Disable loot warnings"			,	340, -112, 	false,	"If checked, confirmations will no longer appear when you choose a loot roll option or attempt to sell or mail a tradable item.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "FasterLooting"				, 	"Faster auto loot"				,	340, -132, 	true,	"If checked, the amount of time it takes to auto loot creatures will be significantly reduced.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "FasterMovieSkip"			, 	"Faster movie skip"				,	340, -152, 	true,	"If checked, you will be able to cancel cinematics without being prompted for confirmation.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "StandAndDismount"			, 	"Dismount me"					,	340, -172, 	true,	"If checked, you will be able to set some additional rules for when your character is automatically dismounted.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowVendorPrice"			, 	"Show vendor price"				,	340, -192, 	true,	"If checked, the vendor price will be shown in item tooltips.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "CombatPlates"				, 	"Combat plates"					,	340, -212, 	true,	"If checked, enemy nameplates will be shown during combat and hidden when combat ends.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "EasyItemDestroy"			, 	"Easy item destroy"				,	340, -232, 	true,	"If checked, you will no longer need to type delete when destroying a superior quality item.|n|nIn addition, item links will be shown in all item destroy confirmation windows.")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowFlightTimes"			, 	"Show flight times"				, 	340, -252, 	true,	"If checked, flight times will be shown in the flight map and when you take a flight.")

	RGXQoLLC:CfgBtn("SetWeatherDensityBtn", RGXQoLCB["SetWeatherDensity"])
	RGXQoLLC:CfgBtn("MuteGameSoundsBtn", RGXQoLCB["MuteGameSounds"])
	RGXQoLLC:CfgBtn("MuteMountSoundsBtn", RGXQoLCB["MuteMountSounds"])
	RGXQoLLC:CfgBtn("MuteCustomSoundsBtn", RGXQoLCB["MuteCustomSounds"])
	RGXQoLLC:CfgBtn("DismountBtn", RGXQoLCB["StandAndDismount"])
	RGXQoLLC:CfgBtn("ShowFlightTimesBtn", RGXQoLCB["ShowFlightTimes"])

----------------------------------------------------------------------
-- 	LC8: Settings
----------------------------------------------------------------------

	pg = "Page8";

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Addon"						, 146, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowMinimapIcon"			, "Show minimap button"				, 146, -92,		false,	"If checked, a minimap button will be available.|n|nClick - Toggle options panel.|n|nSHIFT-click - Toggle music.|n|nALT-click - Toggle errors (if enabled).|n|nCTRL/SHIFT-click - Toggle windowed mode.|n|nCTRL/ALT-click - Toggle Zygor (if installed).")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "UseEnglishLanguage"		, "Use English language"			, 146, -112,	true,	"If checked, text used throughout the addon will be shown in English regardless of your game locale.")

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Scale", 340, -72);
	RGXQoLLC:MakeSL(RGXQoLLC[pg], "PlusPanelScale", "Drag to set the scale of the Leatrix Plus panel.", 1, 2, 0.1, 340, -92, "%.1f")

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Transparency", 340, -132);
	RGXQoLLC:MakeSL(RGXQoLLC[pg], "PlusPanelAlpha", "Drag to set the transparency of the Leatrix Plus panel.", 0, 1, 0.1, 340, -152, "%.1f")
