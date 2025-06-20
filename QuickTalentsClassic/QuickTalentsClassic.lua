----------------------------------------------------------------------------------------------------------------------------------
-- QuickTalentsClassic
----------------------------------------------------------------------------------------------------------------------------------
CreateFrame("Frame", "QTC", UIParent):RegisterEvent("ADDON_LOADED")
local GetSpecialization = C_SpecializationInfo.GetActiveSpecGroup

-- Helper function to get talent info
local function GetTalentInfo(tier, column)
	return C_SpecializationInfo.GetTalentInfo({
		tier = tier,
		column = column,
		groupIndex = C_SpecializationInfo.GetActiveSpecGroup(false),
		isInspect = false,
	})
end

-- Helper function to convert talent number (1-18) to tier and column
local function GetTalentPosition(talentNum)
	local tier = ceil(talentNum / 3)
	local column = talentNum % 3
	if column == 0 then
		column = 3
	end
	return tier, column
end

QTC:SetScript("OnEvent", function(self)
	self:UnregisterEvent("ADDON_LOADED")
	C_Timer.After(0.1, function()
		C_AddOns.LoadAddOn("Blizzard_TalentUI")
	end)

	local isBeta = string.find(string.lower(select(1, GetRealmName())), "beta") ~= nil
	if isBeta then
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cff00ff00[QuickTalentsClassic]|r Click |Hqtad:1|h|cff00ccff[ >>here<< ]|r|h to advertise the addon! <3",
			1,
			1,
			0
		)
	end

	-- Load/Validate Settings
	local settings = {
		Scale = 100,
		ShowTooltips = false,
		BackgroundAlpha = 50,
		ShowGlyphs = true,
		GlyphHistorySize = 3,
		Position = { "TOP" },
		Bindings = {},
		GlyphHistory = {},
		Collapsed = false,
		CollapseInCombat = false,
	}
	QT_Saved = QT_Saved or settings
	local cfg = QT_Saved
	for k, v in pairs(settings) do
		if type(cfg[k]) ~= type(v) then
			cfg[k] = v
		end
	end

	-- Main Frame
	local anchor = CreateFrame("FRAME", nil, UIParent)
	anchor:SetPoint(unpack(cfg.Position))
	anchor:SetSize(1, 1)
	anchor:SetMovable(true)
	self:SetPoint("TOPLEFT", anchor)
	self:SetSize(86, 20)
	self:EnableMouse(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", function()
		anchor:StartMoving()
	end)
	self:SetScript("OnDragStop", function()
		anchor:StopMovingOrSizing()
		cfg.Position = { anchor:GetPoint() }
	end)

	self:CreateTexture("QuickTalentsBackground"):SetAllPoints()
	self:CreateFontString("QuickTalentsReagents"):SetFont("Fonts\\ARIALN.TTF", 13, "OUTLINE")
	QuickTalentsReagents:SetPoint("TOPLEFT", 4, -2)

	local toggler =
		CreateFrame("BUTTON", "QuickTalentsToggle", self, "SecureHandlerClickTemplate,SecureHandlerStateTemplate")
	toggler:SetAttribute(
		"UpdateDisplay",
		[[
			local btns = newtable(self:GetParent():GetChildren());
			local state = self:GetAttribute("Collapsed") or (PlayerInCombat() and self:GetAttribute("OnCombat"));
			local y = 18;
			for _,f in pairs(btns) do
				if strmatch(f:GetName(),"QuickTalentsButton%d") then
					if state or not f:GetAttribute("used") then
						f:Hide()
					else
						f:Show()
						y = max(y,-select(5,f:GetPoint())+28);
					end
				end
			end
			self:GetParent():SetHeight(y);
		]]
	)
	toggler:SetAttribute(
		"_onclick",
		[[
			self:SetAttribute("Collapsed", not self:GetAttribute("Collapsed") );
			self:RunAttribute("UpdateDisplay");
		]]
	)
	toggler:SetAttribute("Collapsed", cfg.Collapsed)

	---@param isCollapsed boolean
	local function SetTogglerDirections(isCollapsed)
		if isCollapsed then
			toggler.texture:SetTexCoord(0, 1, 0, 0.5)
			toggler.texture2:SetTexCoord(0, 1, 0.5, 1)
		else
			toggler.texture:SetTexCoord(0, 1, 0.5, 1)
			toggler.texture2:SetTexCoord(0, 1, 0, 0.5)
		end
	end

	toggler:HookScript("OnClick", function()
		cfg.Collapsed = not not toggler:GetAttribute("Collapsed")
		SetTogglerDirections(cfg.Collapsed)
	end)

	local togglerSize = 14
	toggler:SetSize(togglerSize, togglerSize)
	toggler:SetPoint("TOPRIGHT", -2, -2)
	toggler:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
	end)
	toggler:SetScript("OnLeave", function(self)
		self:SetAlpha(0.75)
	end)
	toggler:SetAlpha(0.75)
	toggler.texture = toggler:CreateTexture()
	toggler.texture:SetTexture("Interface/PaperDollInfoFrame/StatSortArrows")
	toggler.texture:SetVertexColor(0, 1, 0, 1)
	toggler.texture:SetPoint("TOPLEFT", 0, 0)
	toggler.texture:SetSize(togglerSize, togglerSize / 2)

	toggler.texture2 = toggler:CreateTexture()
	toggler.texture2:SetTexture("Interface/PaperDollInfoFrame/StatSortArrows")
	toggler.texture2:SetVertexColor(0, 1, 0, 1)
	toggler.texture2:SetPoint("BOTTOMLEFT", 0, 0)
	toggler.texture2:SetSize(togglerSize, togglerSize / 2)

	SetTogglerDirections(cfg.Collapsed)

	RegisterStateDriver(toggler, "combat", "[combat]1;2;")
	toggler:SetAttribute("OnCombat", cfg.CollapseInCombat)
	toggler:SetAttribute("_onstate-combat", [[self:RunAttribute("UpdateDisplay")]])

	-- Obsoleted
	-- Learn Queue
	local Queue = {}

	-- Learn talent (x = 1...18)
	function L(t)
		local tier, column = GetTalentPosition(t)
		local talentInfo = GetTalentInfo(tier, column) or {}
		Queue[tier] = nil
		for i = tier * 3 - 2, tier * 3 do
			local talentInfo = GetTalentInfo(tier, column) or {}
			if talentInfo.selected then
				Queue[tier] = t
				return
			end
		end
		LearnTalents(talentInfo.talentID)
	end

	-- Obsoleted (seem not working clicking this button from macro)
	-- Handles the safe loading & opening of the Blizzard Talent UI
	CreateFrame("BUTTON", "QuickTalentsOpener", self, "SecureActionButtonTemplate"):SetAttribute("type", "macro")
	QuickTalentsOpener:SetAttribute(
		"macrotext",
		"/run PlayerTalentFrame:Show()\n"
			.. "/click [spec:1]PlayerSpecTab1;[spec:2]PlayerSpecTab2\n"
			.. "/click PlayerTalentFrameTab3\n"
			.. "/click PlayerTalentFrameTab2\n"
			.. "/run PlayerTalentFrame:Hide()"
	)

	-- PlayerTalentFrame:Show()
	function S()
		PlayerTalentFrame:Show()
	end

	-- PlayerTalentFrame:Hide()
	function H()
		PlayerTalentFrame:Hide()
	end

	-- PlayerTalentFrame_Close()
	function C()
		PlayerTalentFrame_Close()
	end

	-- PlayerTalentFrame_ClearTalentSelections()
	function R()
		PlayerTalentFrame_ClearTalentSelections()
	end

	-- Set up Glyph filter
	function self:G(name)
		SetGlyphNameFilter(name)
		if IsGlyphFlagSet(1) then
			ToggleGlyphFilter(1)
		end
	end

	-- Glyphs
	local GlyphHistory, PlayerSpec, PlayerGlyphs
	function self:UpdateGlyphs()
		if PlayerSpec ~= GetSpecialization(false) then
			PlayerSpec = GetSpecialization(false)
			-- get players current glyphs
			PlayerGlyphs = wipe(PlayerGlyphs or {})
			for i = 1, 3 do
				local id, icon = select(4, GetGlyphSocketInfo(i * 2))
				PlayerGlyphs[i] = id and { id, GetSpellInfo(id):sub(10), icon } or {}
			end
			-- load glyph history
			local class = select(2, UnitClass("Player"))
			cfg.GlyphHistory[class] = cfg.GlyphHistory[class] or {}
			if PlayerSpec then
				cfg.GlyphHistory[class][PlayerSpec] = cfg.GlyphHistory[class][PlayerSpec] or {}
			end
			GlyphHistory = cfg.GlyphHistory[class][PlayerSpec]
		end
		if not (PlayerGlyphs and GetGlyphSocketInfo(1) and GlyphHistory) then
			return
		end
		local h = GlyphHistory
		for i = 1, 3 do
			local id, icon = select(4, GetGlyphSocketInfo(i * 2))
			if PlayerGlyphs[i][1] ~= id then -- glyph slot has changed
				if id then -- remove new glyph from history
					local found = 0
					for j = 1, #h do
						if h[j][1] == id then
							found = 1
						end
						h[j] = h[j + found]
					end
				end
				if PlayerGlyphs[i][1] then -- add previous glyph to history
					for j = #h, 0, -1 do
						h[j + 1] = h[j] or PlayerGlyphs[i]
					end
				end
				PlayerGlyphs[i] = id and { id, GetSpellInfo(id):sub(10), icon } or {} -- update PlayerGlyphs
			end
		end
	end

	-- Create Buttons
	local buttons = {}
	function self:CreateButtons()
		if InCombatLockdown() then
			return
		end
		for i = 1, 21 + cfg.GlyphHistorySize do
			if not buttons[i] then
				local btn = CreateFrame("BUTTON", "QuickTalentsButton" .. i, self, "SecureActionButtonTemplate")
				btn:SetAttribute("type1", "macro")
				btn:SetSize(26, 26)
				btn:SetPoint("TOPLEFT", ((i - 1) % 3) * 28 + 2, -(ceil(i / 3) * 28) + 8)

				btn.texture = btn:CreateTexture(nil, "BACKGROUND")
				btn.texture:SetAllPoints()
				btn.texture:SetTexCoord(0.075, 0.925, 0.075, 0.925)

				btn:SetScript("OnLeave", function(btn)
					GameTooltip:Hide()
					btn:SetAlpha(btn.selected and 1 or 0.25)
				end)
				btn:SetScript("OnEnter", function(btn)
					if cfg.ShowTooltips then
						GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
						if btn.glyphID then
							GameTooltip:SetSpellByID(btn.glyphID)
						elseif btn.telantID then
							GameTooltip:SetTalent(btn.telantID)
						end
						GameTooltip:Show()
					end
					btn:SetAlpha(btn.selected and 1 or 0.5)
				end)

				if i <= 18 then -- talents
					local tier, column = GetTalentPosition(i)
					local talentInfo = GetTalentInfo(tier, column) or {}
					btn.telantID = talentInfo.talentID or {}
					btn:SetAttribute(
						"macrotext",
						"/stopmacro [combat]\n"
							--.. "/click QuickTalentsOpener\n" -- ensures the talent frame is ready for interactionType
							.. "/run C()S()R()\n"
							.. "/click [spec:1]PlayerSpecTab1;[spec:2]PlayerSpecTab2\n"
							.. "/click PlayerTalentFrameTab2\n"
							.. format("/click PlayerTalentFrameTalentsTalentRow%dTalent%d\n", tier, column)
							.. "/click StaticPopup1Button1\n" -- confirm unlearn (TODO: what if popup1 is not the talent prompt)
							.. "/click PlayerTalentFrameTalentsLearnButton\n"
							.. "/run H()\n"
							.. format("/run L(%d)", i) -- queue new talents for learn
					)
					btn:RegisterForDrag("LeftButton")
					btn:SetScript("OnDragStart", function()
						if not InCombatLockdown() then
							--PickupTalent(btn.telantID)
							local tier, column = GetTalentPosition(i)
							local talentInfo = GetTalentInfo(tier, column)
							PickupSpell(talentInfo.spellID)
							if CursorHasSpell() then
								QuickTalentsBinder.spell = select(4, GetCursorInfo())
								QuickTalentsBinder:SetScript("OnUpdate", QuickTalentsBinder.OnEvent)
							end
						end
					end)
				elseif i <= 21 then -- glyphs slots
					btn:SetAttribute(
						"macrotext",
						format("/click GlyphFrameGlyph%d\n/click StaticPopup1Button1\n", (i - 18) * 2) .. "/run H()"
					)
					btn.ring = btn:CreateTexture(nil, "ARTWORK")
					btn.ring:SetTexture("Interface/TalentFrame/talent-main")
					btn.ring:SetPoint("CENTER")
					btn.ring:SetSize(38, 38)
					btn.ring:SetTexCoord(0.50000000, 0.91796875, 0.00195313, 0.21093750)
					btn.texture:SetTexCoord(0, 1, 0, 1)
					btn.selected = true
				else -- glyph history
					btn:SetAlpha(0.25)
					btn:RegisterForClicks("RightButtonUp", "LeftButtonDown")
					-- TODO: remove from history
					btn:SetAttribute("type2", "script") -- TODO: maybe use a modified click instead
					btn:SetAttribute("_script", function(btn) -- remove from history
						for j = i - 21, #GlyphHistory do
							GlyphHistory[j] = GlyphHistory[j + 1]
						end
						self:Update()
					end)
				end
				buttons[i] = btn
			end
		end
	end

	-- Update/Style Frames
	function self:Update()
		if InCombatLockdown() then
			return
		end
		self:CreateButtons()

		toggler:SetAttribute("OnCombat", cfg.CollapseInCombat)

		QuickTalentsBackground:SetColorTexture(0, 0, 0, cfg.BackgroundAlpha / 100)
		QuickTalentsReagents:SetText(select(2, GetTalentClearInfo()) or 0)

		self:SetScale(cfg.Scale / 100)

		local y = 18
		-- Update Textures & Glyphs
		for i, btn in pairs(buttons) do
			if
				i > (cfg.ShowGlyphs and 21 + cfg.GlyphHistorySize or 18)
				or (i > 21 and not (GlyphHistory and GlyphHistory[i - 21]))
			then
				btn:Hide()
				btn:SetAttribute("used", false)
			else
				btn:Show()
				btn:SetAttribute("used", true)
				y = max(y, -select(5, btn:GetPoint()) + 28)

				if i <= 18 then -- talents
					local tier, column = GetTalentPosition(i)
					local talentInfo = GetTalentInfo(tier, column)
					if not talentInfo then
						return
					end

					btn.selected = talentInfo.selected
					btn:SetAlpha(btn.selected and 1 or 0.25)
					btn.texture:SetTexture(talentInfo.icon)
				else -- glyph buttons
					local icon, id, name
					if i <= 21 then -- sockets
						id, icon = select(4, GetGlyphSocketInfo((i - 18) * 2))
						SetPortraitToTexture(btn.texture, icon or "Interface/Buttons/GreyscaleRamp64")
					else -- history
						id, name, icon = unpack(GlyphHistory[i - 21])
						btn:SetAttribute(
							"macrotext", -- TODO: It's possible to cast glyph spells directly, but requires placement into an action slot
							"/stopmacro [combat]\n"
								.. "/run C()S()\n"
								.. "/click [spec:1]PlayerSpecTab1;[spec:2]PlayerSpecTab2\n"
								.. "/click PlayerTalentFrameTab3\n"
								.. format('/run QTC:G("%s")\n', name) -- set name filter and prep header
								.. "/click GlyphFrameHeader1\n" -- trigger scrollframe update
								.. "/click GlyphFrameScrollFrameButton2" -- click glyph button, TODO: are there glyphs that return multiple results?
						)
						btn.texture:SetTexture(icon)
					end
					btn.glyphID = id
				end
			end
		end
		if cfg.Collapsed then
			y = 18
			for i, btn in pairs(buttons) do
				btn:Hide()
			end
		end
		self:SetHeight(y)
	end

	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("BAG_UPDATE_DELAYED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")

	-- Event Handler
	self:SetScript("OnEvent", function(self, e, ...)
		-- Obsoleted
		for i, t in pairs(Queue) do
			L(t)
		end

		if e:sub(1, 12) == "PLAYER_REGEN" then
			local state = e == "PLAYER_REGEN_DISABLED"
			for i, btn in pairs(buttons) do
				SetDesaturation(btn.texture, state)
			end
			SetDesaturation(QuickTalentsConfigButton.texture, state)
			if state and QuickTalentsConfig then
				QuickTalentsConfig:Hide()
			end
		else
			self:UpdateGlyphs()
			self:Update()
		end
	end)

	-- Config Manager
	local function ToggleConfig()
		if QuickTalentsConfig then
			QuickTalentsConfig:SetShown(not QuickTalentsConfig:IsShown())
		else
			local window = CreateFrame("FRAME", "QuickTalentsConfig", UIParent)
			window:SetSize(300, 180)
			window:SetPoint("CENTER")
			window:EnableMouse(true)
			window:SetMovable(true)
			window:RegisterForDrag("LeftButton")
			window:SetScript("OnDragStart", window.StartMoving)
			window:SetScript("OnDragStop", window.StopMovingOrSizing)

			local background = window:CreateTexture()
			background:SetAllPoints()
			background:SetColorTexture(0, 0, 0, 0.75)

			local close = CreateFrame("BUTTON", nil, window)
			close:SetPoint("TOPRIGHT", 5, 5)
			close:SetSize(30, 30)
			close:SetScript("OnClick", function()
				window:Hide()
			end)

			local cross = close:CreateFontString()
			cross:SetFont("Fonts\\ARIALN.TTF", 13, "OUTLINE")
			cross:SetPoint("CENTER")
			cross:SetText("X")

			for i, name in pairs({ "ShowTooltips", "ShowGlyphs", "CollapseInCombat" }) do
				local cb = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
				cb:SetPoint("TOPLEFT", 10, 10 - (i * 20))
				--cb:SetHitRectInsets(0,-60,0,0);
				cb:SetChecked(cfg[name])
				select(6, cb:GetRegions()):SetText(name:gsub("%u", " %1"))
				cb:SetScript("OnClick", function(cb)
					cfg[name] = not not cb:GetChecked()
					self:Update()
				end)
			end

			local y = -100
			for name, v in pairs({
				Scale = { 20, 300 },
				BackgroundAlpha = { 0, 100 },
				GlyphHistorySize = { 1, 18 },
			}) do
				local label = window:CreateFontString()
				label:SetFont("Fonts\\ARIALN.TTF", 13, "OUTLINE")
				label:SetPoint("TOPLEFT", 6, y)
				label:SetText(name:gsub("[A-Z]", " %1") .. ":")

				local slider = CreateFrame("Slider", nil, window, "OptionsSliderTemplate")
				slider:SetPoint("TOPRIGHT", -10, y)
				slider:SetSize(150, 14)
				slider:SetMinMaxValues(unpack(v))
				slider:EnableMouseWheel(true)
				slider:SetValue(cfg[name])
				slider:SetScript("OnMouseWheel", function(self, dir)
					self:SetValue(self:GetValue() + dir)
				end)
				slider:SetScript("OnValueChanged", function(slider, val)
					cfg[name] = floor(val)
					self:Update()
				end)
				if select(11, slider:GetRegions()) then
					select(11, slider:GetRegions()):Hide() -- low
				end
				if select(12, slider:GetRegions()) then
					select(12, slider:GetRegions()):Hide() -- high
				end
				y = y - 26
			end
		end
		if InCombatLockdown() then
			QuickTalentsConfig:Hide()
		end
	end

	local ConfigButton = CreateFrame("BUTTON", "QuickTalentsConfigButton", self)
	ConfigButton:SetSize(14, 14)
	ConfigButton:SetPoint("TOPRIGHT", -20, -2)
	ConfigButton:SetScript("OnClick", ToggleConfig)
	ConfigButton:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
	end)
	ConfigButton:SetScript("OnLeave", function(self)
		self:SetAlpha(0.75)
	end)
	ConfigButton:SetAlpha(0.75)
	ConfigButton.texture = ConfigButton:CreateTexture()
	ConfigButton.texture:SetTexture("Interface/GossipFrame/HealerGossipIcon")
	ConfigButton.texture:SetAllPoints()

	SLASH_QUICKTALENTS1, SLASH_QUICKTALENTS2 = "/quicktalents", "/qts"
	SlashCmdList.QUICKTALENTS = function(args)
		local arg1, arg2 = strsplit(" ", args, 2)
		if strlower(arg1) == "unbind" then
			if not arg2 then
				print("Usage: /qts unbind [SpellName|SpellID]")
			else
				local found
				for id, slot in pairs(cfg.Bindings) do
					if strlower(GetSpellInfo(id)) == strlower(arg2) then
						cfg.Bindings[id] = nil
						found = true
						print(format("%s (%d) Unbound.", arg2, id))
					end
				end
				if not found then
					print("Bind not found:")
					for id, slot in pairs(cfg.Bindings) do
						print(format("%s (%d) - %d", GetSpellLink(id), id, slot))
					end
				end
			end
			return
		elseif strlower(arg1) == "reset" then
			anchor:ClearAllPoints()
			anchor:SetPoint("CENTER")
			cfg.Position = { "CENTER" }
			print("Position Reset.")
			return
		elseif arg1 ~= "" then
			print("Options:")
			print("/qts unbind [SpellName|SpellID]")
			print("/qts reset")
			return
		end
		ToggleConfig()
	end

	-- Binder
	StaticPopupDialogs["QUICKTALENTS_CONFIRM_BIND"] = {
		text = "Do you want to bind %s to Action Slot %d",
		button1 = YES,
		button2 = NO,
		OnAccept = function(popup)
			cfg.Bindings[popup.data[1]] = tonumber(popup.data[2])
			print(
				format(
					"%s will now automatically be placed in action slot %d when it is learnt.",
					GetSpellLink(popup.data[1]),
					popup.data[2]
				)
			)
		end,
	}
	CreateFrame("Frame", "QuickTalentsBinder", self)
	function QuickTalentsBinder:OnEvent(e, arg1)
		if e == "LEARNED_SPELL_IN_TAB" then
			if cfg.Bindings[arg1] then
				PickupSpell(arg1)
				PlaceAction(cfg.Bindings[arg1])
				ClearCursor()
			end
		elseif self.spell and select(4, GetCursorInfo()) ~= self.spell then
			if e == "ACTIONBAR_SLOT_CHANGED" and cfg.Bindings[tonumber(self.spell)] ~= tonumber(arg1) then
				StaticPopup_Show("QUICKTALENTS_CONFIRM_BIND", GetSpellLink(self.spell), arg1, { self.spell, arg1 })
			end
			self.spell = nil
			self:SetScript("OnUpdate", nil)
		end
	end
	QuickTalentsBinder:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	QuickTalentsBinder:RegisterEvent("LEARNED_SPELL_IN_TAB")
	QuickTalentsBinder:SetScript("OnEvent", QuickTalentsBinder.OnEvent)

	if isBeta then
		-- Only register once!
		if not QuickTalentsClassic_SetItemRef_Hooked then
			local orig_SetItemRef = SetItemRef

			function SetItemRef(link, text, button, chatFrame)
				if link:sub(1, 5) == "qtad:" then
					-- You can show a popup, or do something else here
					-- You CANNOT send a chat message directly from here (protected)
					StaticPopup_Show("QT_ADVERTISE_CONFIRM")
					return
				end
				orig_SetItemRef(link, text, button, chatFrame)
			end
			QuickTalentsClassic_SetItemRef_Hooked = true
		end

		-- Register a popup for confirmation
		StaticPopupDialogs["QT_ADVERTISE_CONFIRM"] = {
			text = "Do you want to advertise Quick Talents Classic in channel 1?",
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
				SendChatMessage(
					"Try Quick Talents Classic addon! Instantly swap talents with one click! =)",
					"CHANNEL",
					nil,
					1
				)
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
	end
end)
