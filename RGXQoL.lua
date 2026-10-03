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
	local RGXQoLLC, RGXQoLCB, RGXQoLDropList, RGXQoLConfigList, RGXQoLLockList = {}, {}, {}, {}, {}

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

		-- Hide options panel (skip when embedded in the game options canvas;
		-- hiding it would leave the category page blank)
		if not RGXQoLLC.OptionsEmbedded and RGXQoLLC["PageF"] then
			RGXQoLLC["PageF"]:Hide();
		end
	end

	-- Find out if RGX QoL is showing (main panel or config panel)
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
		RGXQoLLC:LockOption("FilterChatMessages", "FilterChatMessagesBtn", true)	-- Filter chat messages
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


		-- Interface

		or	(RGXQoLLC["ShowDruidStatusText"]	~= RGXQoLDB["ShowDruidStatusText"])	-- Show druid power bar status text

		-- Frames
		or	(RGXQoLLC["NoGryphons"]			~= RGXQoLDB["NoGryphons"])				-- Hide gryphons
		or	(RGXQoLLC["NoClassBar"]			~= RGXQoLDB["NoClassBar"])				-- Hide stance bar

		-- System

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


		----------------------------------------------------------------------
		--	Block duels (no reload required)
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Invite from whispers (no reload required)
		----------------------------------------------------------------------


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


		----------------------------------------------------------------------
		-- Mute mount sounds (no reload required)
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Mute game sounds (no reload required) (MuteGameSounds)
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Faster movie skip
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Wowhead Links
		----------------------------------------------------------------------


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
		--	Faster looting
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Disable bag automation
		----------------------------------------------------------------------


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
				SafeHookSecure("FCF_SetTabPosition", function()
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


		----------------------------------------------------------------------
		-- Show raid frame toggle button
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Hide hit indicators (portrait text)
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Class colored frames
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Quest text size
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Resize mail text
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Resize book text
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Show durability status
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Hide zone text
		----------------------------------------------------------------------


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
			SafeHookSecure("FCF_OpenTemporaryWindow", function()
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
			SafeHookSecure("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf]:SetMaxLines(4096)
				end
			end)
		end

		----------------------------------------------------------------------
		--	Hide error messages
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Easy item destroy
		----------------------------------------------------------------------


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
			SafeHookSecure("FloatingChatFrame_UpdateBackgroundAnchors", function(self)
				self:SetClampRectInsets(0, 0, 0, 0)
			end)

			-- Process temporary chat frames
			SafeHookSecure("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf]:SetClampRectInsets(0, 0, 0, 0)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Enhance flight map
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Keep audio synced
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Mute custom sounds (no reload required)
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Block shared quests (no reload needed)
		----------------------------------------------------------------------


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


		----------------------------------------------------------------------
		-- Show ready timer
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Show flight times
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Enhance minimap
		----------------------------------------------------------------------


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


		----------------------------------------------------------------------
		-- Hide macro text
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- More font sizes
		----------------------------------------------------------------------

		if RGXQoLLC["MoreFontSizes"] == "On" and not RGXQoLLockList["MoreFontSizes"] then
			RunScript('CHAT_FONT_HEIGHTS = {[1] = 10, [2] = 12, [3] = 14, [4] = 16, [5] = 18, [6] = 20, [7] = 22, [8] = 24, [9] = 26, [10] = 28}')
		end

		----------------------------------------------------------------------
		--	Show druid power bar
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Show vanity controls (must be before Enhance dressup)
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Enhance dressup
		----------------------------------------------------------------------


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
		--	Enhance trainers
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Set weather density (no reload required)
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Enhance professions
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Show free bag slots
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Enhance quest log
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Show bag search box
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Show vendor price
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		--	Dismount me
		----------------------------------------------------------------------


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


		----------------------------------------------------------------------
		-- Disable screen effects (no reload required)
		----------------------------------------------------------------------


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


		----------------------------------------------------------------------
		-- Show volume control on character frame
		----------------------------------------------------------------------


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
			SafeHookSecure("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf .. "EditBox"]:SetAltArrowKeyMode(false)
				end
			end)
		end

		----------------------------------------------------------------------
		-- L43: Manage widget
		----------------------------------------------------------------------


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
			SafeHookSecure("FCF_OpenTemporaryWindow", function(chatType)
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
			SafeHookSecure("FCF_OpenTemporaryWindow", function()
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


		----------------------------------------------------------------------
		-- Combat plates
		----------------------------------------------------------------------


		----------------------------------------------------------------------
		-- Enhance tooltip
		----------------------------------------------------------------------


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
			SafeHookSecure("FCF_OpenTemporaryWindow", function()
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


		----------------------------------------------------------------------
		-- Silence rested emotes
		----------------------------------------------------------------------

		-- Manage emotes

		----------------------------------------------------------------------
		--	Max camera zoom (no reload required)
		----------------------------------------------------------------------


	----------------------------------------------------------------------
	-- L45: Create panel in game options panel
	----------------------------------------------------------------------

	do

		local interPanel = CreateFrame("FRAME")
		interPanel.name = "RGX QoL"

		-- Settings-integrated: the options panel always lives inside the
		-- game options category and is never an independent window.
		local mainFrame = RGXQoLLC["PageF"]
		if mainFrame then
			mainFrame:SetParent(interPanel)
			mainFrame:ClearAllPoints()
			mainFrame:SetAllPoints(interPanel)
			mainFrame:SetMovable(false)
			mainFrame:SetScript("OnDragStart", nil)
			mainFrame:SetScript("OnDragStop", nil)
			mainFrame:SetScript("OnShow", nil)
			mainFrame:Show()
			RGXQoLLC.OptionsEmbedded = true

			-- Show the start page inside the settings canvas
			local startPage = RGXQoLLC["Page" .. (RGXQoLLC["RGXQoLStartPage"] or 0)]
			if startPage then startPage:Show() end
		end

		-- Register the category when the Blizzard Settings API exists
		if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
			local category = Settings.RegisterCanvasLayoutCategory(interPanel, "RGX QoL")
			RGXQoLLC.OptionsCategory = category
			Settings.RegisterAddOnCategory(category)
		end

	end

		----------------------------------------------------------------------
		-- Frame alignment grid
		----------------------------------------------------------------------


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
				-- Show formatted value
			end

			-- Set alpha on startup
			SetPlusAlpha()

			-- Set alpha after changing slider

		end

		----------------------------------------------------------------------
		-- Panel scale
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

				-- Social

				RGXQoLLC:LoadVarChk("AcceptPartyFriends", "Off")			-- Party from friends
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
				RGXQoLLC:LoadVarChk("RestoreChatMessages", "Off")			-- Restore chat messages

				-- Text




				-- Interface




				-- Frames




				-- System




				-- Settings
				RGXQoLLC:LoadVarChk("ShowMinimapIcon", "On")				-- Show minimap button
				RGXQoLLC:LoadVarChk("UseEnglishLanguage", "Off")			-- Use English language

				-- Panel position
				RGXQoLLC:LoadVarAnc("MainPanelA", "CENTER")				-- Panel anchor
				RGXQoLLC:LoadVarAnc("MainPanelR", "CENTER")				-- Panel relative
				RGXQoLLC:LoadVarNum("MainPanelX", 0, -5000, 5000)			-- Panel X axis
				RGXQoLLC:LoadVarNum("MainPanelY", 0, -5000, 5000)			-- Panel Y axis

				-- Start page
				RGXQoLLC:LoadVarNum("RGXQoLStartPage", 0, 0, RGXQoLLC["NumberOfPages"])

				-- Removed pages: clamp a stale start page to a live page
				do
					local sp = RGXQoLLC["RGXQoLStartPage"]
					if sp and (sp < 0 or (sp > 3 and sp ~= 8)) then
						RGXQoLLC["RGXQoLStartPage"] = 0
					end
				end

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
							end

							-- UnitFrames
							if E.private.unitframe.enable then
							end

						-- ActionBars
						if E.private.actionbar.enable then
						end

							-- Bags
							if E.private.bags.enable then
							end

							-- Tooltip
							if E.private.tooltip.enable then
							end

							-- UnitFrames: Disabled Blizzard: Player
							if E.private.unitframe.disabledBlizzardFrames.player then
							end

							-- UnitFrames: Disabled Blizzard: Player and Target
							if E.private.unitframe.disabledBlizzardFrames.player or E.private.unitframe.disabledBlizzardFrames.target then
							end

							-- Base
							do
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

			RGXQoLDB["AcceptPartyFriends"]		= RGXQoLLC["AcceptPartyFriends"]
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




			-- Interface





			-- Frames




			-- System



			RGXQoLDB["FlightBarA"]				= RGXQoLLC["FlightBarA"]
			RGXQoLDB["FlightBarR"]				= RGXQoLLC["FlightBarR"]
			RGXQoLDB["FlightBarScale"]			= RGXQoLLC["FlightBarScale"]
			RGXQoLDB["FlightBarWidth"]			= RGXQoLLC["FlightBarWidth"]

			-- Settings
			RGXQoLDB["ShowMinimapIcon"] 		= RGXQoLLC["ShowMinimapIcon"]
			RGXQoLDB["UseEnglishLanguage"] 	= RGXQoLLC["UseEnglishLanguage"]

			-- Panel position
			RGXQoLDB["MainPanelA"]				= RGXQoLLC["MainPanelA"]
			RGXQoLDB["MainPanelR"]				= RGXQoLLC["MainPanelR"]
			RGXQoLDB["MainPanelX"]				= RGXQoLLC["MainPanelX"]
			RGXQoLDB["MainPanelY"]				= RGXQoLLC["MainPanelY"]

			-- Start page
			RGXQoLDB["RGXQoLStartPage"]			= RGXQoLLC["RGXQoLStartPage"]



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

		-- Silence rested emotes

		-- Show free bag slos

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

	end

----------------------------------------------------------------------
-- 	Options panel functions
----------------------------------------------------------------------

	-- Function to add textures to panels
	function RGXQoLLC:BuildHeaderBand(parent, height)
		local Design = _G.RGXDesign
		local header = CreateFrame("Frame", nil, parent, "BackdropTemplate")
		header:SetHeight(height or 52)
		header:SetPoint("TOPLEFT", 0, 0)
		header:SetPoint("TOPRIGHT", 0, 0)
		header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		local br, bgc, bb = 0.055, 0.055, 0.071
		local er, eg, eb = 0.137, 0.137, 0.173
		local pr, pg, pb = 0.545, 0.082, 0.220
		if Design then
			br, bgc, bb = Design:Unpack("background")
			er, eg, eb = Design:Unpack("border")
			pr, pg, pb = Design:Unpack("primary")
		end
		header:SetBackdropColor(br, bgc, bb, 0.95)
		header:SetBackdropBorderColor(er, eg, eb, 1)
		local accent = header:CreateTexture(nil, "ARTWORK")
		accent:SetHeight(2)
		accent:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
		accent:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
		accent:SetColorTexture(pr, pg, pb, 1)
		return header
	end

	function RGXQoLLC:GetAddonVersion()
		if C_AddOns and C_AddOns.GetAddOnMetadata then
			local ok, v = pcall(C_AddOns.GetAddOnMetadata, "RGXQoL", "Version")
			if ok and v and v ~= "" then return v end
		end
		return RGXQoLLC["AddonVer"]
	end

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
		_G["RGXQoLGlobalPanel_" .. globref] = Side
		table.insert(UISpecialFrames, "RGXQoLGlobalPanel_" .. globref)

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
		local Design = _G.RGXDesign
		if Design then
			Side.t:SetColorTexture(Design:Unpack("surface"))
		else
			Side.t:SetColorTexture(0.05, 0.05, 0.05, 0.9)
		end
		local sBorder = CreateFrame("Frame", nil, Side, "BackdropTemplate")
		sBorder:SetAllPoints()
		sBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		if Design then
			sBorder:SetBackdropBorderColor(Design:Unpack("border"))
		else
			sBorder:SetBackdropBorderColor(0.137, 0.137, 0.173)
		end
		sBorder:SetFrameLevel(0)

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
			Side:SetScale(1)
			Side.t:SetAlpha(1)
		end)

		-- RGXMods header band
		local header = RGXQoLLC:BuildHeaderBand(Side)

		-- Add title
		Side.f = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		Side.f:SetPoint("TOPLEFT", 16, -10)
		Side.f:SetText(L[title])

		-- Add description
		Side.v = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		Side.v:SetPoint("TOPLEFT", Side.f, "BOTTOMLEFT", 0, -2)
		Side.v:SetText(L["Configuration Panel"])

		local sver = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		sver:SetPoint("TOPRIGHT", header, "TOPRIGHT", -46, -12)
		sver:SetJustifyH("RIGHT")
		sver:SetText("v" .. tostring(RGXQoLLC:GetAddonVersion()))

		if _G.RGXDesign then
			Side.f:SetTextColor(_G.RGXDesign:Unpack("text"))
			Side.v:SetTextColor(_G.RGXDesign:Unpack("subtext"))
			sver:SetTextColor(_G.RGXDesign:Unpack("primary"))
		end

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
			Side.backFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
			if _G.RGXDesign then
				local br, bgc, bb = _G.RGXDesign:Unpack("background")
				Side.backFrame:SetBackdropColor(br, bgc, bb, 0.4)
			else
				Side.backFrame:SetBackdropColor(0.055, 0.055, 0.071, 0.4)
			end

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
		if _G.RGXDesign then
			text:SetTextColor(_G.RGXDesign:Unpack("primary"))
		end
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
		if _G.RGXDesign then
			Slider.f:SetTextColor(_G.RGXDesign:Unpack("text"))
		end

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
				mbtn:SetNormalTexture("Interface\\AddOns\\RGXQoL\\RGXQoL.blp")
				mbtn:GetNormalTexture():SetTexCoord(0.125, 0.25, 0.21875, 0.25)
			end
			mbtn:SetHighlightTexture("Interface\\AddOns\\RGXQoL\\RGXQoL.blp")
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

		-- Settings-integrated panel: registered as an options-page canvas,
		-- never an independent floating window (see L45).
		_G["RGXQoLGlobalPanel"] = PageF

		-- Set frame parameters
		RGXQoLLC["PageF"] = PageF
		PageF:SetSize(570, RGXQoLLC.MainPanelHeight)
		PageF:Hide();
		PageF:SetClampedToScreen(true)
		PageF:EnableMouse(true)

		-- Add background color (RGXDesign themed)
		local Design = _G.RGXDesign
		PageF.t = PageF:CreateTexture(nil, "BACKGROUND")
		PageF.t:SetAllPoints()
		if Design then
			PageF.t:SetColorTexture(Design:Unpack("surface"))
		else
			PageF.t:SetColorTexture(0.05, 0.05, 0.05, 0.9)
		end
		local border = CreateFrame("Frame", nil, PageF, "BackdropTemplate")
		border:SetAllPoints()
		border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		if Design then
			border:SetBackdropBorderColor(Design:Unpack("border"))
		else
			border:SetBackdropBorderColor(0.137, 0.137, 0.173)
		end
		border:SetFrameLevel(0)

		-- Settings-integrated: PageF fills its options-pane parent; no float positioning.

		-- RGXMods header band: dark strip, accent line, identity column
		local header = RGXQoLLC:BuildHeaderBand(PageF)
		PageF.header = header

		local icon = header:CreateTexture(nil, "ARTWORK")
		icon:SetSize(30, 30)
		icon:SetPoint("LEFT", 12, 0)
		icon:SetTexture("Interface\\AddOns\\RGX-Framework\\media\\logo.tga")

		PageF.mt = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		PageF.mt:SetPoint("LEFT", header, "TOPLEFT", 52, -14)
		PageF.mt:SetText("|cff8B1538RGX|r |cffffffffQoL|r")

		PageF.v = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		PageF.v:SetPoint("LEFT", header, "TOPLEFT", 52, -27)
		PageF.v:SetText("Quality of life enhancements for WoW Forever")

		local discord = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		discord:SetPoint("LEFT", header, "TOPLEFT", 52, -39)
		local dInvite = "discord.gg/N7kdKAHVVF"
		if C_AddOns and C_AddOns.GetAddOnMetadata then
			local ok, v = pcall(C_AddOns.GetAddOnMetadata, "RGXQoL", "X-Discord")
			if ok and v and v ~= "" then dInvite = v end
		end
		discord:SetText("|cff7289daDiscord:|r |cffffd700" .. dInvite .. "|r")
		discord:SetTextColor(0.85, 0.85, 0.85)

		local ver = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ver:SetPoint("TOPRIGHT", header, "TOPRIGHT", -14, -12)
		ver:SetJustifyH("RIGHT")
		ver:SetText("v" .. tostring(RGXQoLLC.GetAddonVersion and RGXQoLLC:GetAddonVersion() or RGXQoLLC["AddonVer"]))

		local auth = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		auth:SetPoint("TOPRIGHT", header, "TOPRIGHT", -14, -25)
		auth:SetJustifyH("RIGHT")
		auth:SetText("by donniedice")

		local brand = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		brand:SetPoint("TOPRIGHT", header, "TOPRIGHT", -14, -38)
		brand:SetJustifyH("RIGHT")
		brand:SetText("|cff8B1538RGX|r |cffffd700Mods|r")

		if Design then
			PageF.mt:SetTextColor(Design:Unpack("text"))
			PageF.v:SetTextColor(Design:Unpack("subtext"))
			ver:SetTextColor(Design:Unpack("primary"))
			auth:SetTextColor(Design:Unpack("subtext"))
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
				-- Prevent RGX QoL from overwriting RGXQoLDB at next logout
				RGXQoLEvt:UnregisterEvent("PLAYER_LOGOUT")
				RGXQoLLC:Print("RGX QoL will not overwrite RGXQoLDB at next logout.")
				return
			elseif str == "reset" then
				-- Reset panel positions
				RGXQoLLC["PageF"]:SetScale(1)
				-- Refresh panels
				RGXQoLLC["PageF"]:ClearAllPoints()
				RGXQoLLC["PageF"]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				-- Reset currently showing configuration panel
				for k, v in pairs(RGXQoLConfigList) do
					if v:IsShown() then
						v:ClearAllPoints()
						v:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
						v:SetScale(1)
					end
				end
				-- Refresh RGX QoL Plus settings menu only
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
					RGXQoLLC:CreateBar("HelpPanelMainTexture", frame, 570, 360, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "")
					-- Panel contents
					local col1, col2, color1 = 10, 120, "|cffffffaa"
					RGXQoLLC:MakeTx(frame, "RGX QoL Plus Help", col1, -10)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol", col1, -30)
					RGXQoLLC:MakeWD(frame, "Toggle opttions panel.", col2, -30)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol reset", col1, -50)
					RGXQoLLC:MakeWD(frame, "Reset addon panel position and scale.", col2, -50)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol wipe", col1, -70)
					RGXQoLLC:MakeWD(frame, "Wipe all addon settings (reloads UI).", col2, -70)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol realm", col1, -90)
					RGXQoLLC:MakeWD(frame, "Show realms connected to yours.", col2, -90)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol rest", col1, -110)
					RGXQoLLC:MakeWD(frame, "Show number of rested XP bubbles remaining.", col2, -110)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol quest <id>", col1, -130)
					RGXQoLLC:MakeWD(frame, "Show quest completion status for <quest id>.", col2, -130)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol quest wipe", col1, -150)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol grid", col1, -170)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol id", col1, -190)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol zygor", col1, -210)
					RGXQoLLC:MakeWD(frame, "Toggle the Zygor addon (reloads UI).", col2, -210)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol movie <id>", col1, -230)
					RGXQoLLC:MakeWD(frame, "Play a movie by its ID.", col2, -230)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol marker", col1, -250)
					RGXQoLLC:MakeWD(frame, "Block target markers (toggle) (requires assistant or leader in raid).", col2, -250)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol rsnd", col1, -270)
					RGXQoLLC:MakeWD(frame, "Restart the sound system.", col2, -270)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol ra", col1, -290)
					RGXQoLLC:MakeWD(frame, "Announce target in General chat channel (useful for rares).", col2, -290)
					RGXQoLLC:MakeWD(frame, color1 .. "/qol con", col1, -310)
					RGXQoLLC:MakeWD(frame, "Launch the developer console with a large font.", col2, -310)
					RGXQoLLC:MakeWD(frame, color1 .. "/rl", col1, -330)
					RGXQoLLC:MakeWD(frame, "Reload the UI.", col2, -330)
					RGXQoLLC.HelpFrame = frame
					_G["RGXQoLGlobalHelpPanel"] = frame
					table.insert(UISpecialFrames, "RGXQoLGlobalHelpPanel")
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
					RGXQoLLC:CreateBar("MutePanelMainTexture", frame, 294, 86, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "")
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
					_G["RGXQoLGlobalMutePanel"] = frame
					table.insert(UISpecialFrames, "RGXQoLGlobalMutePanel")
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
				RGXQoLLC:Print(L["Modifying saved variables must start with |cffffffff/qol nosave|r to prevent your changes from being reverted during reload or logout."] .. "|n")
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

				RGXQoLDB["AcceptPartyFriends"] = "On"			-- Party from friends
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
				RGXQoLDB["RestoreChatMessages"] = "On"			-- Restore chat messages

				-- Text


				-- Interface



				-- Frames




				-- System



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
			-- Open the Blizzard settings panel for RGX QoL
			local function TryOpenQoLOptions()
				if not (Settings and Settings.OpenToCategory) then return end

				-- Forever/modern clients demand the numeric category ID; names and
				-- table references crash OpenSettingsPanel. Try ID first, then the
				-- category object, then legacy name — all pcall'd so no crash.
				local target = RGXQoLLC.OptionsCategory
				local id
				if type(target) == "table" then
					if type(target.GetID) == "function" then
						local ok, v = pcall(target.GetID, target)
						if ok and type(v) == "number" then id = v end
					end
					if id == nil and type(target.ID) == "number" then
						id = target.ID
					end
				end
				if id == nil and type(Settings.GetCategory) == "function" then
					local ok, cat = pcall(Settings.GetCategory, "RGX QoL")
					if ok and type(cat) == "table" then
						if type(cat.GetID) == "function" then
							local ok2, v = pcall(cat.GetID, cat)
							if ok2 and type(v) == "number" then id = v end
						end
						if id == nil and type(cat.ID) == "number" then id = cat.ID end
					end
				end

				if id then
					Settings.OpenToCategory(id)
					return
				end
				-- No numeric ID resolved: never pass a name (the client turns it
				-- into an async OpenSettingsPanel call that pcall cannot contain).
				RGXQoLLC:Print("Open |cff00ff00Options > AddOns > RGX QoL|r from the game menu.")
			end
			TryOpenQoLOptions()
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
		do
			local pr, pg, pb = 0.55, 0.08, 0.22
			if _G.RGXDesign then
				pr, pg, pb = _G.RGXDesign:Unpack("primary")
			end
			mbtn.s:SetColorTexture(pr, pg, pb, 0.35)
		end
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
		oPage.s:SetPoint('TOPLEFT', 146, -58)
		oPage.s:SetText(L[title])
		if _G.RGXDesign then
			oPage.s:SetTextColor(_G.RGXDesign:Unpack("primary"))
		end

		-- Add menu item if needed
		if menu then
			RGXQoLLC[menu], RGXQoLLC[menu .. ".s"] = RGXQoLLC:MakeMN(menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)
			RGXQoLLC[name]:SetScript("OnShow", function() RGXQoLLC[menu .. ".s"]:Show(); end)
			RGXQoLLC[name]:SetScript("OnHide", function() RGXQoLLC[menu .. ".s"]:Hide(); end)
		end

		return oPage;

	end

	-- Create options pages
	RGXQoLLC["Page0"] = RGXQoLLC:MakePage("Page0", "Home"			, "RGXQoLNav0", "Home"			, RGXQoLLC["PageF"], "TOPLEFT", 16, -72, 112, 20)
	RGXQoLLC["Page1"] = RGXQoLLC:MakePage("Page1", "Automation"	, "RGXQoLNav1", "Automation"	, RGXQoLLC["PageF"], "TOPLEFT", 16, -112, 112, 20)
	RGXQoLLC["Page2"] = RGXQoLLC:MakePage("Page2", "Social"		, "RGXQoLNav2", "Social"		, RGXQoLLC["PageF"], "TOPLEFT", 16, -132, 112, 20)
	RGXQoLLC["Page3"] = RGXQoLLC:MakePage("Page3", "Chat"			, "RGXQoLNav3", "Chat"			, RGXQoLLC["PageF"], "TOPLEFT", 16, -152, 112, 20)
	RGXQoLLC["Page8"] = RGXQoLLC:MakePage("Page8", "Settings"		, "RGXQoLNav8", "Settings"		, RGXQoLLC["PageF"], "TOPLEFT", 16, -272, 112, 20)

	-- Page navigation mechanism
	for i = 0, RGXQoLLC["NumberOfPages"] do
		if RGXQoLLC["RGXQoLNav"..i] then
		RGXQoLLC["RGXQoLNav"..i]:SetScript("OnClick", function()
			RGXQoLLC:HideFrames()
			RGXQoLLC["PageF"]:Show();
			RGXQoLLC["Page"..i]:Show();
			RGXQoLLC["RGXQoLStartPage"] = i
		end)
		end
	end

	-- Use a variable to contain the page number (makes it easier to move options around)
	local pg;

----------------------------------------------------------------------
-- 	LC0: Welcome
----------------------------------------------------------------------

	pg = "Page0";

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Welcome to RGX QoL Plus.", 146, -72);
	RGXQoLLC:MakeWD(RGXQoLLC[pg], "To begin, choose an options page.", 146, -92);

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Support", 146, -132);
	RGXQoLLC:MakeWD(RGXQoLLC[pg], "curseforge.com/wow/addons/RGX QoL-plus", 146, -152);

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

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Groups"					, 	340, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "AcceptPartyFriends"		, 	"Party from friends"			, 	340, -92, 	false,	"If checked, party invitations from friends will be automatically accepted unless you are queued for a battleground or the Looking for Group feature.")

	local FriendlyGuildFooter = RGXQoLLC:MakeFT(RGXQoLLC[pg], "For all of the social options above, you can treat guild members as friends too.", 146, 380)
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "FriendlyGuild"				, 	"Guild"							, 	146, -282, 	false,	"If checked, members of your guild will be treated as friends for all of the options on this page.")
	RGXQoLCB["FriendlyGuild"]:ClearAllPoints()
	RGXQoLCB["FriendlyGuild"]:SetPoint("TOPLEFT", FriendlyGuildFooter, "BOTTOMLEFT", 0, -10)
	if RGXQoLCB["FriendlyGuild"].f:GetStringWidth() > 90 then
		RGXQoLCB["FriendlyGuild"].f:SetWidth(90)
		RGXQoLCB["FriendlyGuild"]:SetHitRectInsets(0, -84, 0, 0)
	end


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


	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Visibility"				, 	146, -72);

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Text Size"					, 	340, -72);


----------------------------------------------------------------------
-- 	LC5: Interface
----------------------------------------------------------------------


	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Enhancements"				, 	146, -72);

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Extras"					, 	146, -252);

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Extras"					, 	340, -72);


----------------------------------------------------------------------
-- 	LC6: Frames
----------------------------------------------------------------------


	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Features"					, 	146, -72);

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Visibility"				, 	340, -72);


----------------------------------------------------------------------
-- 	LC7: System
----------------------------------------------------------------------


	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Graphics and Sound"		, 	146, -72);

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Game Options"				, 	340, -72);


----------------------------------------------------------------------
-- 	LC8: Settings
----------------------------------------------------------------------

	pg = "Page8";

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Addon"						, 146, -72);
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "ShowMinimapIcon"			, "Show minimap button"				, 146, -92,		false,	"If checked, a minimap button will be available.|n|nClick - Toggle options panel.|n|nSHIFT-click - Toggle music.|n|nALT-click - Toggle errors (if enabled).|n|nCTRL/SHIFT-click - Toggle windowed mode.|n|nCTRL/ALT-click - Toggle Zygor (if installed).")
	RGXQoLLC:MakeCB(RGXQoLLC[pg], "UseEnglishLanguage"		, "Use English language"			, 146, -112,	true,	"If checked, text used throughout the addon will be shown in English regardless of your game locale.")

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Scale", 340, -72);

	RGXQoLLC:MakeTx(RGXQoLLC[pg], "Transparency", 340, -132);
