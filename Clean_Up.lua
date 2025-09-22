local self = CreateFrame'Frame'
self:Hide()
self:SetScript('OnUpdate', function() this:UPDATE() end)
self:SetScript('OnEvent', function() this[event](this) end)
for _, event in {'ADDON_LOADED', 'PLAYER_LOGIN', 'MERCHANT_SHOW', 'MERCHANT_CLOSED'} do
	self:RegisterEvent(event)
end
local maxMovesPerClick = 5
local moveCounter = 0
local lastTime
local lastSlotAndLink = {}

self.bags = { containers = {0, 1, 2, 3, 4}, tooltip = 'Clean Up Bags' }
self.bank = { containers = {-1, 5, 6, 7, 8, 9, 10}, tooltip = 'Clean Up Bank' }

self.ITEM_TYPES = {GetAuctionItemClasses()}
function self:Present(...)
	local called
	return function()
		if not called then
			called = true
			return unpack(arg)
		end
	end
end
function self:ItemTypeKey(itemClass)
	return self:Key(self.ITEM_TYPES, itemClass) or 0
end
function self:ItemSubTypeKey(itemClass, itemSubClass)
	return self:Key({GetAuctionItemSubClasses(self:ItemTypeKey(itemClass))}, itemClass) or 0
end
function self:ItemInvTypeKey(itemClass, itemSubClass, itemSlot)
	return self:Key({GetAuctionInvTypes(self:ItemTypeKey(itemClass), self:ItemSubTypeKey(itemSubClass))}, itemSlot) or 0
end
function self.ADDON_LOADED()
	if not Clean_Up_Settings then Clean_Up_Settings = { reversed = false, assignments = {}, bags = { parent = "ContainerFrame1", position = {-24, -5}, }, bank = { parent = "BankFrame", position = {-57, -11}, }, } end
	if arg1 ~= "Clean_Up" then
		if arg1 == "Bagnon" then Clean_Up_Settings["bags"].parent = "BagnonTitle" Clean_Up_Settings["bags"].position = {0, -1} self:CreateButton'bags' Clean_Up_Settings["bank"].parent = "BanknonTitle" Clean_Up_Settings["bank"].position = {0, -1} self:CreateButton'bank' end
		if not Bagnon and arg1 == "pfUI" and pfBag then Clean_Up_Settings["bags"].parent = "pfBag" Clean_Up_Settings["bags"].position = {-103, 4} self:CreateButton'bags' Clean_Up_Settings["bank"].parent = "pfBank" Clean_Up_Settings["bank"].position = {-40, 4} self:CreateButton'bank' end
		return
	end
	if Bagnon then Clean_Up_Settings["bags"].parent = "BagnonTitle" Clean_Up_Settings["bags"].position = {0, -1} self:CreateButton'bags' Clean_Up_Settings["bank"].parent = "BanknonTitle" Clean_Up_Settings["bank"].position = {0, -1} self:CreateButton'bank' end
	self.CLASSES = {
		{ -- arrow
			containers = {2101, 5439, 7278, 11362, 3573, 3605, 7371, 8217, 2662, 19319, 18714},
			items = self:Set(2512, 2515, 3030, 3464, 9399, 11285, 12654, 18042, 19316),
		},
		{ -- bullet
			containers = {2102, 5441, 7279, 11363, 3574, 3604, 7372, 8218, 2663, 19320},
			items = self:Set(2516, 2519, 3033, 3465, 4960, 5568, 8067, 8068, 8069, 10512, 10513, 11284, 11630, 13377, 15997, 19317),
		},
		{ -- soul
			containers = {22243, 22244, 21340, 21341, 21342},
			items = self:Set(6265),
		},
		{ -- enchanting
			containers = {22246, 22248, 22249},
			items = self:Set(
				10940, 11083, 11137, 11176, 16204, -- dust
				10938, 10939, 10998, 11082, 11134, 11135, 11174, 11175, 16202, 16203, -- essence
				10978, 11084, 11138, 11139, 11177, 11178, 14343, 14344, --shard
				20725, -- crystal
				6218, 6339, 11130, 11145, 16207 --rod
			),
		},
		{ -- herb
			containers = {22250, 22251, 22252},
			items = self:Set(765, 785, 2447, 2449, 2450, 2452, 2453, 3355, 3356, 3357, 3358, 3369, 3818, 3819, 3820, 3821, 4625, 8831, 8836, 8838, 8839, 8845, 8846, 13463, 13464, 13465, 13466, 13467, 13468),
		},
	}
	self.MOUNT = self:Set(
		5864, 5872, 5873, 18785, 18786, 18787, 18244, 19030, 13328, 13329, -- rams
		2411, 2414, 5655, 5656, 18778, 18776, 18777, 18241, 12353, 12354, -- horses
		8629, 8631, 8632, 18766, 18767, 18902, 18242, 13086, 19902, 12302, 12303, 8628, 12326, -- sabers
		8563, 8595, 13321, 13322, 18772, 18773, 18774, 18243, 13326, 13327, -- mechanostriders
		15277, 15290, 18793, 18794, 18795, 18247, 15292, 15293, -- kodos
		1132, 5665, 5668, 18796, 18797, 18798, 18245, 12330, 12351, -- wolves
		8588, 8591, 8592, 18788, 18789, 18790, 18246, 19872, 8586, 13317, -- raptors
		13331, 13332, 13333, 13334, 18791, 18248, 13335, -- undead horses
		21218, 21321, 21323, 21324, 21176 -- qiraji battle tanks
	)
	self.SPECIAL = self:Set(5462, 17696, 17117, 13347, 13289, 11511)
	self.KEY = self:Set(9240, 17191, 13544, 12324, 16309, 12384, 20402)
	self.TOOL = self:Set(7005, 12709, 19727, 5956, 2901, 6219, 10498, 6218, 6339, 11130, 11145, 16207, 9149, 15846, 6256, 6365, 6367)
	self:SetupSlash()

	CreateFrame('GameTooltip', 'Clean_Up_Tooltip', nil, 'GameTooltipTemplate')
	self:CreateButtonPlacer()
	self:CreateButton'bags'
	self:CreateButton'bank'
end
local count = 0
function self:PLAYER_LOGIN()
	self.PickupContainerItem = PickupContainerItem
	function PickupContainerItem(...)
		if IsAltKeyDown() and not SpellIsTargeting() then
			local container, position = unpack(arg)
			for item in self:Present(self:Item(container, position)) do
				local slotKey = self:SlotKey(container, position)
				Clean_Up_Settings.assignments[slotKey] = item
				self:Log(slotKey..' assigned to '..item)
			end
		else
			self.PickupContainerItem(unpack(arg))
		end
	end

	self.UseContainerItem = UseContainerItem
	function UseContainerItem(...)
		local container, position = unpack(arg)
		local slot = self:SlotKey(container, position)
		if not slot then return end
		if IsAltKeyDown() then
			if Clean_Up_Settings.assignments[slot] then
				Clean_Up_Settings.assignments[slot] = nil
				self:Log(slot..' freed')
			end
		else
			local link = GetContainerItemLink(container, position)
			if not link then link = lastSlotAndLink[2] end
			if lastTime and GetTime() - lastTime < .5 and slot == lastSlotAndLink[1] then
				containers = self:Set(unpack(self.bags.containers))[container] and self.bags.containers or self.bank.containers
				for _, container in containers do
					for position=1,GetContainerNumSlots(container) do
						if self:SlotKey(container, position) ~= slot and GetContainerItemLink(container, position) == link then
							arg[1], arg[2] = container, position
							self.UseContainerItem(unpack(arg))
							count = count + 1
							if self.atMerchant and count == 5 then break end
						end
					end
					if self.atMerchant and count == 5 then break end
				end
			end
			if count == 5 then lastTime = GetTime() - .5 else lastTime = GetTime() end
			count = 0
			lastSlotAndLink[1] = slot
			lastSlotAndLink[2] = link
			self.UseContainerItem(unpack(arg))
		end
	end
	if not Bagnon and not pfUI then Clean_Up_Settings["bags"].parent = "ContainerFrame1" Clean_Up_Settings["bags"].position = {-24, -5} Clean_Up_Settings["bank"].parent = "BankFrame" Clean_Up_Settings["bank"].position = {-57, -11} self:CreateButton'bags' self:CreateButton'bank' end
end
local slowdowntheupdateimer = 0
local Sort1ThenStack2 = 1
function self:UPDATE()
	if slowdowntheupdateimer < GetTime() and not IsAltKeyDown() then
		slowdowntheupdateimer = GetTime() + .5
		count = 0
		if moveCounter == 0 and keyToRepeatIfNotFinished then self:Go(keyToRepeatIfNotFinished) else keyToRepeatIfNotFinished = nil end
		if not self.model then
			self:CreateModel()
		end
		if Sort1ThenStack2 == 1 then 
			if self:Sort() then	self:Hide()	end
			Sort1ThenStack2 = 2
			moveCounter = moveCounter - 1
		else
			self:Stack()
			Sort1ThenStack2 = 1
			moveCounter = moveCounter - 1
		end
	elseif IsAltKeyDown() then
		keyToRepeatIfNotFinished = nil
	end
end
function self:MERCHANT_SHOW()
	self.atMerchant = true
end
function self:MERCHANT_CLOSED()
	self.atMerchant = false
end
function self:Log(msg)
	DEFAULT_CHAT_FRAME:AddMessage(LIGHTYELLOW_FONT_COLOR_CODE..'[Clean Up] '..msg)
end
function self:Set(...)
	local t = {}
	for i=1,arg.n do t[arg[i]] = true end
	return t
end
function self:LT(a, b)
	local i = 1
	while true do
		if a[i] and b[i] and a[i] ~= b[i] then
			return a[i] < b[i]
		elseif not a[i] and b[i] then
			return true
		elseif not b[i] then
			return false
		end
		i = i + 1
	end
end
function self:Key(table, value)
	for k, v in table do
		if v == value then return k end
	end
end
function self:SlotKey(container, position)
	return container..':'..position
end
function self:SetupSlash()
  	SLASH_CLEANUPBAGS1 = '/cleanupbags'
	function SlashCmdList.CLEANUPBAGS(arg)
		self.buttonPlacer.key = 'bags'
		self.buttonPlacer:Show()
	end
	SLASH_CLEANUPBANK1 = '/cleanupbank'
	function SlashCmdList.CLEANUPBANK(arg)
		self.buttonPlacer.key = 'bank'
		self.buttonPlacer:Show()
	end
    SLASH_CLEANUPREVERSE1 = '/cleanupreverse'
    function SlashCmdList.CLEANUPREVERSE(arg)
        Clean_Up_Settings.reversed = not Clean_Up_Settings.reversed
        self:Log('Sort order: '..(Clean_Up_Settings.reversed and 'Reversed' or 'Standard'))
	end
end
function self:CreateBrushButton(parent)
	local button = CreateFrame('Button', nil, parent)
	button:SetWidth(28)
	button:SetHeight(26)
	button:SetNormalTexture[[Interface\AddOns\Clean_Up\Bags]]
	button:GetNormalTexture():SetTexCoord(.12109375, .23046875, .7265625, .9296875)
	button:SetPushedTexture[[Interface\AddOns\Clean_Up\Bags]]
	button:GetPushedTexture():SetTexCoord(.00390625, .11328125, .7265625, .9296875)
	button:SetHighlightTexture[[Interface\Buttons\ButtonHilight-Square]]
	button:GetHighlightTexture():ClearAllPoints()
	button:GetHighlightTexture():SetPoint('CENTER', 0, 0)
	button:GetHighlightTexture():SetWidth(24)
	button:GetHighlightTexture():SetHeight(23)
	return button
end
function self:CreateButtonPlacer()
	local frame = CreateFrame('Button', nil, UIParent)
	self.buttonPlacer = frame
	frame:SetFrameStrata'FULLSCREEN_DIALOG'
	frame:SetAllPoints()
	frame:Hide()

	local escapeInterceptor = CreateFrame('EditBox', nil, frame)
	escapeInterceptor:SetScript('OnEscapePressed', function() frame:Hide() end)

	local buttonPreview = self:CreateBrushButton(frame)
	buttonPreview:EnableMouse(false)
	buttonPreview:SetAlpha(.5)

	frame:SetScript('OnShow', function() escapeInterceptor:SetFocus() end)
	frame:SetScript('OnClick', function() this:EnableMouse(false) end)
	frame:SetScript('OnUpdate', function()
		local scale, x, y = buttonPreview:GetEffectiveScale(), GetCursorPosition()
		buttonPreview:SetPoint('CENTER', UIParent, 'BOTTOMLEFT', x/scale, y/scale)
		if not this:IsMouseEnabled() and GetMouseFocus() then
			local parent = GetMouseFocus()
			local parentScale, parentX, parentY = parent:GetEffectiveScale(), parent:GetCenter()
			Clean_Up_Settings[this.key] = {parent=parent:GetName(), position={x/parentScale-parentX, y/parentScale-parentY}}
			self:UpdateButton(this.key)
			this:EnableMouse(true)
			this:Hide()
		end
	end)
end
function self:UpdateButton(key)
	local button, settings = self[key].button, Clean_Up_Settings[key]
	button:SetParent(settings.parent)
	button:SetPoint('TOPRIGHT', unpack(settings.position))
end
function self:CreateButton(key)
	local settings = Clean_Up_Settings[key]
	local button = self:CreateBrushButton()
	self[key].button = button
	button:SetScript('OnUpdate', function()
		if settings.parent and getglobal(settings.parent) then
			self:UpdateButton(key)
			this:SetScript('OnUpdate', nil)
		end
	end)
	button:SetScript('OnClick', function()
		PlaySoundFile[[Interface\AddOns\Clean_Up\UI_BagSorting_01.ogg]]
		self:Go(key)
		slowdowntheupdateimer = 0
	end)
	button:SetScript('OnEnter', function()
		GameTooltip:SetOwner(this)
		GameTooltip:AddLine(self[key].tooltip)
		GameTooltip:Show()
	end)
	button:SetScript('OnLeave', function()
		GameTooltip:Hide()
	end)
	button:SetScript('OnShow', function()
		if pfBagSearch then
			pfBagSearch:ClearAllPoints()
			pfBagSearch:SetPoint("TOPLEFT", pfBag, "TOPLEFT", 6, 0)
			pfBagSearch:SetPoint("BOTTOMRIGHT", pfBagSlotShow, "BOTTOMRIGHT", -103, 0)
		end
	end)
end
function self:Move(src, dst)
    local _,_,srcLocked = GetContainerItemInfo(src.container, src.position)
    local _,_,dstLocked = GetContainerItemInfo(dst.container, dst.position)
	if not srcLocked and not dstLocked then
		ClearCursor()
       	PickupContainerItem(src.container, src.position)
		PickupContainerItem(dst.container, dst.position)

	    local _, _, srcLocked = GetContainerItemInfo(src.container, src.position)
	    local _, _, dstLocked = GetContainerItemInfo(dst.container, dst.position)
    	if srcLocked or dstLocked then
			if src.state.item == dst.state.item then
				local count = min(src.state.count, self:Info(dst.state.item).stack - dst.state.count)
				src.state.count = src.state.count - count
				dst.state.count = dst.state.count + count
				if src.count == 0 then src.state.item = nil end
			else
				src.state, dst.state = dst.state, src.state
			end
		end
		return true
    end
end
function self:TooltipInfo(container, position)
	local chargesPattern = '^'..gsub(gsub(ITEM_SPELL_CHARGES_P1, '%%d', '(%%d+)'), '%%%d+%$d', '(%%d+)')..'$'
	Clean_Up_Tooltip:SetOwner(self, ANCHOR_NONE)
	Clean_Up_Tooltip:ClearLines()
	if container == BANK_CONTAINER then Clean_Up_Tooltip:SetInventoryItem('player', BankButtonIDToInvSlotID(position)) else Clean_Up_Tooltip:SetBagItem(container, position) end

	local charges, usable, soulbound, quest, conjured
	for i=1,Clean_Up_Tooltip:NumLines() do
		local text = getglobal('Clean_Up_TooltipTextLeft'..i):GetText()
		local _, _, chargeString = strfind(text, chargesPattern)
		if chargeString then
			charges = tonumber(chargeString)
		elseif strfind(text, '^'..ITEM_SPELL_TRIGGER_ONUSE) then
			usable = true
		elseif text == ITEM_SOULBOUND then
			soulbound = true
		elseif text == ITEM_BIND_QUEST then
			quest = true
		elseif text == ITEM_CONJURED then
			conjured = true
		end
	end
	return charges or 1, usable, soulbound, quest, conjured
end
function self:Sort()
	local complete = true
	local counter = 0
	for _, dst in self.model do
		if dst.item and (dst.state.item ~= dst.item or dst.state.count < dst.count) then
			complete = false
			if counter == 10 then return false end

			local sources, rank = {}, {}
			for _, src in self.model do
				if src.state.item == dst.item
					and src ~= dst
					and not (dst.state.item and src.class and src.class ~= self:Info(dst.state.item).class)
					and not (src.item and src.state.item == src.item and src.state.count <= src.count)
				then
					rank[src] = abs(src.state.count - dst.count + (dst.state.item == dst.item and dst.state.count or 0))
					tinsert(sources, src)
				end
			end
			sort(sources, function(a, b) return rank[a] < rank[b] end)
			for _,src in sources do
				if self:Move(src,dst) then
					counter=counter+1
					break
				end
			end
		end
	end
	return complete
end
function self:Stack()
	local counter = 0
	for _, src in self.model do
		if counter == 10 then return false end
		if src.state.item and src.state.count < self:Info(src.state.item).stack then
			for _, dst in self.model do
				if dst ~= src and dst.state.item and dst.state.item == src.state.item and dst.state.count < self:Info(dst.state.item).stack then
					counter=counter+1
					self:Move(src, dst)
				end
			end
		end
	end
end
function self:ClickSell(container,position)
	local link = GetContainerItemLink(container, position)
	for _, container in containers do
		for position=1,GetContainerNumSlots(container) do
			if self:SlotKey(container, position) ~= slot and GetContainerItemLink(container, position) == link then
				arg[1], arg[2] = container, position
				self.UseContainerItem(unpack(arg))
				return true
			end
		end
	end
end
local keyToRepeatIfNotFinished = "bags"
function self:Go(key)
	self.containers = self[key].containers
	self.model = nil
	moveCounter = maxMovesPerClick
	keyToRepeatIfNotFinished = key
	self:Show()
end
do
	local items, counts
	local function insert(t, v)
		if Clean_Up_Settings.reversed then tinsert(t, v) else tinsert(t, 1, v) end
	end
	local function assign(slot, item)
		if counts[item] > 0 then
			local count = min(counts[item], self:Info(item).stack)
			slot.item = item
			slot.count = count
			counts[item] = counts[item] - count
			return true
		end
	end
	local function assignCustom()
		for _, slot in self.model do
			for item in self:Present(Clean_Up_Settings.assignments[self:SlotKey(slot.container, slot.position)]) do
				if counts[item] then assign(slot, item) end
			end
		end
	end
	local function assignSpecial()
		for key, class in self.CLASSES do
			for _, slot in self.model do
				if slot.class == key and not slot.item then
					for _, item in items do
						if self:Info(item).class == key and assign(slot, item) then break end
				    end
			    end
			end
		end
	end
	local function assignRemaining()
		for _, slot in self.model do
			if not slot.class and not slot.item then
				for _, item in items do
					if assign(slot, item) then break end
			    end
		    end
		end
	end
	function self:CreateModel()
		self.model = {}
		counts = {}
		for _, container in self.containers do
			local class = self:Class(container)
			for position=1,GetContainerNumSlots(container) do
				local slot = {container=container, position=position, class=class}
				local item = self:Item(container, position)
				if item then
					local _, count = GetContainerItemInfo(container, position)
					slot.state = {item=item, count=count}
					counts[item] = (counts[item] or 0) + count
				else
					slot.state = {}
				end
				insert(self.model, slot)
			end
		end
		items = {}
		for item, _ in counts do tinsert(items, item) end
		sort(items, function(a, b) return self:LT(self:Info(a).sortKey, self:Info(b).sortKey) end)
		assignCustom()
		assignSpecial()
		assignRemaining()
	end
end
do
	local cache = {}
	function self:Class(container)
		if not cache[container] and container ~= 0 and container ~= BANK_CONTAINER then
			for name in self:Present(GetBagName(container)) do		
				for class, info in self.CLASSES do
					for _, itemID in info.containers do
						if name == GetItemInfo(itemID) then cache[container] = class end
					end	
				end
			end
		end
		return cache[container]
	end
end
do
	local cache = {}
	function self:Info(item) return setmetatable({}, {__index=cache[item]}) end
	function self:Item(container, position)
		for link in self:Present(GetContainerItemLink(container, position)) do
			local _, _, itemID, enchantID, suffixID, uniqueID = strfind(link, 'item:(%d+):(%d*):(%d*):(%d*)')
			itemID = tonumber(itemID)
			local _, _, quality, _, type, subType, stack, invType = GetItemInfo(itemID)
			local charges, usable, soulbound, quest, conjured = self:TooltipInfo(container, position)
			local key = format('%s:%s:%s:%s:%s:%s', itemID, enchantID, suffixID, uniqueID, charges, (soulbound and 1 or 0))
			if not cache[key] then
				local sortKey = {}
				if itemID == 6948 then -- hearthstone
					tinsert(sortKey, 1)
				elseif self.MOUNT[itemID] then -- mounts
					tinsert(sortKey, 2)
				elseif self.SPECIAL[itemID] then -- special items
					tinsert(sortKey, 3)
				elseif self.KEY[itemID] then -- key items
					tinsert(sortKey, 4)
				elseif self.TOOL[itemID] then -- tools
					tinsert(sortKey, 5)
				elseif soulbound then -- soulbound items
					tinsert(sortKey, 6)
				elseif type == self.ITEM_TYPES[9] then -- reagents
					tinsert(sortKey, 7)
				elseif usable and type ~= self.ITEM_TYPES[1] and type ~= self.ITEM_TYPES[2] and type ~= self.ITEM_TYPES[8] or type == self.ITEM_TYPES[4] then -- consumables
					tinsert(sortKey, 8)
				elseif quest then -- quest items
					tinsert(sortKey, 9)
				elseif quality > 1 then -- higher quality
					tinsert(sortKey, 10)
				elseif quality == 1 then -- common quality
					tinsert(sortKey, 11)
				elseif conjured then -- conjured items
					tinsert(sortKey, 13)
				elseif quality == 0 then -- junk
					tinsert(sortKey, 12)
				end
				tinsert(sortKey, self:ItemTypeKey(type))
				tinsert(sortKey, self:ItemInvTypeKey(type, subType, invType))
				tinsert(sortKey, self:ItemSubTypeKey(type, subType))
				tinsert(sortKey, itemID)
				tinsert(sortKey, 1/charges)
				tinsert(sortKey, suffixID)
				tinsert(sortKey, enchantID)
				tinsert(sortKey, uniqueID)
				cache[key] = { stack = stack, sortKey = sortKey, }
				for class, info in self.CLASSES do
					if info.items[itemID] then cache[key].class = class end
				end
			end
			return key
		end
	end
end
