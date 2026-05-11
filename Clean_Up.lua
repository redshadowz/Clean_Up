local Clean_Up = CreateFrame'Frame'
Clean_Up:Hide()
Clean_Up:RegisterEvent("PLAYER_ENTERING_WORLD")
Clean_Up:SetScript('OnEvent', function() this[event](this) end)
local maxMovesPerClick = 5
local moveCounter = 0
local lastTime
local lastSlotAndLink = {}
local buttonIDs = {}

Clean_Up.bags = { containers = {0,1,2,3,4},tooltip = 'Clean Up Bags' }
Clean_Up.bank = { containers = {-1,5,6,7,8,9,10},tooltip = 'Clean Up Bank' }
Clean_Up.ITEM_TYPES = {GetAuctionItemClasses()}

Clean_Up.CLASSES = {
	{ -- arrow
containers = {2101,5439,7278,11362,3573,3605,7371,8217,2662,19319,18714},
items = {[2512]=true,[2515]=true,[3030]=true,[3464]=true,[9399]=true,[11285]=true,[12654]=true,[18042]=true,[19316]=true},
	},
	{ -- bullet
containers = {2102,5441,7279,11363,3574,3604,7372,8218,2663,19320},
items = {[2516]=true,[2519]=true,[3033]=true,[3465]=true,[4960]=true,[5568]=true,[8067]=true,[8068]=true,[8069]=true,[10512]=true,[10513]=true,[11284]=true,[11630]=true,[13377]=true,[15997]=true,[19317]=true},
	},
	{ -- soul
containers = {22243,22244,21340,21341,21342},
items = {[6265]=true},
	},
	{ -- enchanting
containers = {22246,22248,22249},
items = {
	[10940]=true,[11083]=true,[11137]=true,[11176]=true,[16204]=true,-- dust
	[10938]=true,[10939]=true,[10998]=true,[11082]=true,[11134]=true,[11135]=true,[11174]=true,[11175]=true,[16202]=true,[16203]=true,-- essence
	[10978]=true,[11084]=true,[11138]=true,[11139]=true,[11177]=true,[11178]=true,[14343]=true,[14344]=true,--shard
	[20725]=true,-- crystal
	[6218]=true,[6339]=true,[11130]=true,[11145]=true,[16207]=true --rod
		},
	},
	{ -- herb
containers = {22250,22251,22252},
items = {
	[765]=true,[785]=true,[2447]=true,[2449]=true,[2450]=true,[2452]=true,[2453]=true,[3355]=true,[3356]=true,[3357]=true,[3358]=true,[3369]=true,[3818]=true,[3819]=true,[3820]=true,[3821]=true,
	[4625]=true,[8831]=true,[8836]=true,[8838]=true,[8839]=true,[8845]=true,[8846]=true,[13463]=true,[13464]=true,[13465]=true,[13466]=true,[13467]=true,[13468]=true
		},
	},
}
Clean_Up.MOUNT = {
	[5864]=true,[5872]=true,[5873]=true,[18785]=true,[18786]=true,[18787]=true,[18244]=true,[19030]=true,[13328]=true,[13329]=true,-- rams
	[2411]=true,[2414]=true,[5655]=true,[5656]=true,[18778]=true,[18776]=true,[18777]=true,[18241]=true,[12353]=true,[12354]=true,-- horses
	[8629]=true,[8631]=true,[8632]=true,[18766]=true,[18767]=true,[18902]=true,[18242]=true,[13086]=true,[19902]=true,[12302]=true,[12303]=true,[8628]=true,[12326]=true,-- sabers
	[8563]=true,[8595]=true,[13321]=true,[13322]=true,[18772]=true,[18773]=true,[18774]=true,[18243]=true,[13326]=true,[13327]=true,-- mechanostriders
	[15277]=true,[15290]=true,[18793]=true,[18794]=true,[18795]=true,[18247]=true,[15292]=true,[15293]=true,-- kodos
	[1132]=true,[5665]=true,[5668]=true,[18796]=true,[18797]=true,[18798]=true,[18245]=true,[12330]=true,[12351]=true,-- wolves
	[8588]=true,[8591]=true,[8592]=true,[18788]=true,[18789]=true,[18790]=true,[18246]=true,[19872]=true,[8586]=true,[13317]=true,-- raptors
	[13331]=true,[13332]=true,[13333]=true,[13334]=true,[18791]=true,[18248]=true,[13335]=true,-- undead horses
	[21218]=true,[21321]=true,[21323]=true,[21324]=true,[21176]=true, -- qiraji battle tanks
}
Clean_Up.SPECIAL = {[5462]=true,[17696]=true,[17117]=true,[13347]=true,[13289]=true,[11511]=true}
Clean_Up.KEY = {[9240]=true,[17191]=true,[13544]=true,[12324]=true,[16309]=true,[12384]=true,[20402]=true}
Clean_Up.TOOL = {[7005]=true,[12709]=true,[19727]=true,[5956]=true,[2901]=true,[6219]=true,[10498]=true,[6218]=true,[6339]=true,[11130]=true,[11145]=true,[16207]=true,[9149]=true,[15846]=true,[6256]=true,[6365]=true,[6367]=true}

function Clean_Up:Present(...)
	local called
	return function()
		if not called then
			called = true
			return unpack(arg)
		end
	end
end
function Clean_Up:ItemTypeKey(itemClass)
	return Clean_Up:Key(Clean_Up.ITEM_TYPES,itemClass) or 0
end
function Clean_Up:ItemSubTypeKey(itemClass,itemSubClass)
	return Clean_Up:Key({GetAuctionItemSubClasses(Clean_Up:ItemTypeKey(itemClass))},itemClass) or 0
end
function Clean_Up:ItemInvTypeKey(itemClass,itemSubClass,itemSlot)
	return Clean_Up:Key({GetAuctionInvTypes(Clean_Up:ItemTypeKey(itemClass),Clean_Up:ItemSubTypeKey(itemSubClass))},itemSlot) or 0
end
function Clean_Up_Hooks()
	Clean_Up.PickupContainerItem = PickupContainerItem
	function PickupContainerItem(...)
		if IsAltKeyDown() and not SpellIsTargeting() then
			local container,position = unpack(arg)
			for item in Clean_Up:Present(Clean_Up:Item(container,position)) do
				local slotKey = container..":"..position
				Clean_Up_Settings.assignments[slotKey] = item
				Clean_Up:Log(slotKey..' assigned to '..GetItemInfo("item:"..item) or item)
			end
			Clean_Up:SetBagIcons()
		else
			Clean_Up.PickupContainerItem(unpack(arg))
		end
	end

	Clean_Up.UseContainerItem = UseContainerItem
	function UseContainerItem(...)
		local container,position = unpack(arg)
		local slot = container..":"..position
		local sellCounter = 0
		if not slot then return end
		if IsAltKeyDown() then
			if Clean_Up_Settings.assignments[slot] then
				Clean_Up_Settings.assignments[slot] = nil
				Clean_Up:Log(slot..' freed')
				Clean_Up:SetBagIcons()
			end
		else
			local link = GetContainerItemLink(container,position)
			if not link then link = lastSlotAndLink[2] end
			if lastTime and GetTime() - lastTime < .5 and slot == lastSlotAndLink[1] then
				containers = Clean_Up:Set(unpack(Clean_Up.bags.containers))[container] and Clean_Up.bags.containers or Clean_Up.bank.containers
				for _,container in containers do
					for position=1,GetContainerNumSlots(container) do
						if container..":"..position ~= slot and GetContainerItemLink(container,position) == link then
							arg[1],arg[2] = container,position
							Clean_Up.UseContainerItem(unpack(arg))
							sellCounter = sellCounter + 1
							if Clean_Up.atMerchant and sellCounter == 5 then break end
						end
					end
					if Clean_Up.atMerchant and sellCounter == 5 then break end
				end
			end
			if sellCounter == 5 then lastTime = GetTime() - .5 else lastTime = GetTime() end
			lastSlotAndLink[1] = slot
			lastSlotAndLink[2] = link
			Clean_Up.UseContainerItem(unpack(arg))
		end
	end
end
function Clean_Up:PLAYER_ENTERING_WORLD()
	Clean_Up:SetupSlash()
	if not Clean_Up_Settings then Clean_Up_Settings = { reversed = false, assignments = {}, bags = { parent = "ContainerFrame1", position = {-24, -5}, }, bank = { parent = "BankFrame", position = {-57, -11}, }, } end
	if not Clean_Up_Settings["bags"] or Clean_Up_Settings["bags"].parent or (string.find(getglobal(Clean_Up_Settings["bags"].parent):GetName(), "ContainerFrame") and (IsAddOnLoaded("Bagnon") or IsAddOnLoaded("pfUI"))) or (Clean_Up_Settings["bags"].parent == "BagnonTitle" and not IsAddOnLoaded("Bagnon")) or (Clean_Up_Settings["bags"].parent == "pfBag" and not IsAddOnLoaded("Bagnon")) or (Clean_Up_Settings["bags"].parent == "ContainerFrame1" and (IsAddOnLoaded("Bagnon") or IsAddOnLoaded("pfUI"))) then
		if IsAddOnLoaded("Bagnon") then Clean_Up_Settings["bags"].parent = "BagnonTitle" Clean_Up_Settings["bags"].position = {0,-1} Clean_Up_Settings["bank"].parent = "BanknonTitle" Clean_Up_Settings["bank"].position = {0,-1}
		elseif IsAddOnLoaded("pfUI") then Clean_Up_Settings["bags"].parent = "pfBag" Clean_Up_Settings["bags"].position = {-103,4} Clean_Up_Settings["bank"].parent = "pfBank" Clean_Up_Settings["bank"].position = {-40,4}
		else Clean_Up_Settings = { reversed = false, assignments = {}, bags = { parent = "ContainerFrame1", position = {-24,-5}, }, bank = { parent = "BankFrame", position = {-57,-11}, }, } end
	end
	CreateFrame('GameTooltip', 'Clean_Up_Tooltip', nil, 'GameTooltipTemplate')
	Clean_Up:CreateButtonPlacer()
	Clean_Up:CreateButton'bags'
	Clean_Up:CreateButton'bank'
	for _,event in {'MERCHANT_SHOW','MERCHANT_CLOSED'} do
		Clean_Up:RegisterEvent(event)
	end
	Clean_Up_Hooks()
	Clean_Up:SetBagIcons()
	Clean_Up:SetScript('OnUpdate', function() this:UPDATE() end)
	Clean_Up:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function Clean_Up:SetBagIcons()
	for savedButton,_ in pairs(buttonIDs) do getglobal(savedButton):Hide() end
	buttonIDs = {}
	local BagSizes = {}
	local total = 0
	for _,container in pairs(Clean_Up.bags.containers) do BagSizes[container] = total total = total + GetContainerNumSlots(container) end
	for slotKey,_ in pairs(Clean_Up_Settings.assignments) do
		local _,_,bag,slot = string.find(slotKey,"(%d+):(%d+)")
		if bag then
			bag = tonumber(bag)
			slot = tonumber(slot)
			if getglobal("BagnonItem"..(BagSizes[bag] + slot)) and getglobal("BagnonItem"..(BagSizes[bag] + slot)):GetID() == slot then
				local square = getglobal("CleanUpIcon"..(BagSizes[bag] + slot)) or Clean_Up:CreateIcon("CleanUpIcon"..(BagSizes[bag] + slot),getglobal("BagnonItem"..(BagSizes[bag] + slot)))
				square:SetPoint("TOPLEFT", getglobal("BagnonItem"..(BagSizes[bag] + slot)), "TOPLEFT",0,0)
				square:Show()
				buttonIDs["CleanUpIcon"..(BagSizes[bag] + slot)] = true
			elseif getglobal("ContainerFrame"..(bag+1).."Item"..GetContainerNumSlots(bag)-slot+1) then -- 1 = 16, 16 = 1... so if position 16, then 16 - 16 = 0 + 1... position 1, then 16-1+1
				local square = getglobal("CleanUpIcon"..(BagSizes[bag] + slot)) or Clean_Up:CreateIcon("CleanUpIcon"..(BagSizes[bag] + slot),getglobal("ContainerFrame"..(bag+1).."Item"..GetContainerNumSlots(bag)-slot+1))
				square:SetPoint("TOPLEFT", getglobal("ContainerFrame"..(bag+1).."Item"..GetContainerNumSlots(bag)-slot+1), "TOPLEFT",0,0)
				square:Show()
				buttonIDs["CleanUpIcon"..(BagSizes[bag] + slot)] = true
			end
		end
	end
end
function Clean_Up:CreateIcon(name,parent)
	local f = CreateFrame("Frame", name, parent)
	f:SetWidth(5)
	f:SetHeight(5)
	f.tex = f:CreateTexture(nil, "BACKGROUND")
	f.tex:SetAllPoints(true)
	f.tex:SetTexture(1,0,0,1)
	return f
end

local slowdowntheupdateimer = 0
local Sort1ThenStack2 = 1
local stopSorting = nil
function Clean_Up:UPDATE()
	if slowdowntheupdateimer < GetTime() and not IsAltKeyDown() then
		slowdowntheupdateimer = GetTime() + .25
		if moveCounter == 0 and keyToRepeatIfNotFinished then Clean_Up:Go(keyToRepeatIfNotFinished) else keyToRepeatIfNotFinished = nil end
		if not Clean_Up.model then
			Clean_Up:CreateModel()
		end
		if Sort1ThenStack2 == 1 then 
			if Clean_Up:Sort() then Clean_Up:Hide() end
			Sort1ThenStack2 = 2
			moveCounter = moveCounter - 1
		else
			Clean_Up:Stack()
			Sort1ThenStack2 = 1
			moveCounter = moveCounter - 1
		end
	elseif IsAltKeyDown() then
		keyToRepeatIfNotFinished = nil
	end
end
function Clean_Up:MERCHANT_SHOW()
	Clean_Up.atMerchant = true
end
function Clean_Up:MERCHANT_CLOSED()
	Clean_Up.atMerchant = false
end
function Clean_Up:Log(msg)
	DEFAULT_CHAT_FRAME:AddMessage(LIGHTYELLOW_FONT_COLOR_CODE..'[Clean Up] '..msg)
end
function Clean_Up:Set(...)
	local t = {}
	for i=1,arg.n do t[arg[i]] = true end
	return t
end
function Clean_Up:LT(a,b)
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
function Clean_Up:Key(table,value)
	for k,v in table do
		if v == value then return k end
	end
end
function Clean_Up:SetupSlash()
  	SLASH_CLEANUPBAGS1 = '/cleanupbags'
	function SlashCmdList.CLEANUPBAGS(arg)
		Clean_Up.buttonPlacer.key = 'bags'
		Clean_Up.buttonPlacer:Show()
	end
	SLASH_CLEANUPBANK1 = '/cleanupbank'
	function SlashCmdList.CLEANUPBANK(arg)
		Clean_Up.buttonPlacer.key = 'bank'
		Clean_Up.buttonPlacer:Show()
	end
    SLASH_CLEANUPREVERSE1 = '/cleanupreverse'
    function SlashCmdList.CLEANUPREVERSE(arg)
        Clean_Up_Settings.reversed = not Clean_Up_Settings.reversed
        Clean_Up:Log('Sort order: '..(Clean_Up_Settings.reversed and 'Reversed' or 'Standard'))
	end
end
function Clean_Up:CreateBrushButton(parent)
	local button = CreateFrame('Button',nil,parent)
	button:SetWidth(28)
	button:SetHeight(26)
	button:SetNormalTexture[[Interface\AddOns\Clean_Up\Bags]]
	button:GetNormalTexture():SetTexCoord(.12109375,.23046875,.7265625,.9296875)
	button:SetPushedTexture[[Interface\AddOns\Clean_Up\Bags]]
	button:GetPushedTexture():SetTexCoord(.00390625,.11328125,.7265625,.9296875)
	button:SetHighlightTexture[[Interface\Buttons\ButtonHilight-Square]]
	button:GetHighlightTexture():ClearAllPoints()
	button:GetHighlightTexture():SetPoint('CENTER',0,0)
	button:GetHighlightTexture():SetWidth(24)
	button:GetHighlightTexture():SetHeight(23)
	return button
end
function Clean_Up:CreateButtonPlacer()
	local frame = CreateFrame('Button', nil, UIParent)
	Clean_Up.buttonPlacer = frame
	frame:SetFrameStrata'FULLSCREEN_DIALOG'
	frame:SetAllPoints()
	frame:Hide()

	local escapeInterceptor = CreateFrame('EditBox', nil, frame)
	escapeInterceptor:SetScript('OnEscapePressed', function() frame:Hide() end)

	local buttonPreview = Clean_Up:CreateBrushButton(frame)
	buttonPreview:EnableMouse(false)
	buttonPreview:SetAlpha(.5)

	frame:SetScript('OnShow', function() escapeInterceptor:SetFocus() end)
	frame:SetScript('OnClick', function() this:EnableMouse(false) end)
	frame:SetScript('OnUpdate', function()
		local scale,x,y = buttonPreview:GetEffectiveScale(),GetCursorPosition()
		buttonPreview:SetPoint('CENTER', UIParent, 'BOTTOMLEFT', x/scale, y/scale)
		if not this:IsMouseEnabled() and GetMouseFocus() then
			local parent = GetMouseFocus()
			local parentScale,parentX,parentY = parent:GetEffectiveScale(),parent:GetCenter()
			Clean_Up_Settings[this.key] = {parent=parent:GetName(), position={x/parentScale-parentX, y/parentScale-parentY}}
			Clean_Up:UpdateButton(this.key)
			this:EnableMouse(true)
			this:Hide()
		end
	end)
end
function Clean_Up:UpdateButton(key)
	local button,settings = Clean_Up[key].button,Clean_Up_Settings[key]
	button:SetParent(settings.parent)
	button:SetPoint('TOPRIGHT', unpack(settings.position))
end
function Clean_Up:CreateButton(key)
	local settings = Clean_Up_Settings[key]
	local button = Clean_Up:CreateBrushButton()
	Clean_Up[key].button = button
	button:SetScript('OnUpdate', function()
		if settings.parent and getglobal(settings.parent) then
			Clean_Up:UpdateButton(key)
			this:SetScript('OnUpdate', nil)
		end
	end)
	button:SetScript('OnClick', function()
		PlaySoundFile[[Interface\AddOns\Clean_Up\UI_BagSorting_01.ogg]]
		Clean_Up:Go(key)
		slowdowntheupdateimer = 0
	end)
	button:SetScript('OnEnter', function()
		GameTooltip:SetOwner(this)
		GameTooltip:AddLine(Clean_Up[key].tooltip)
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
function Clean_Up:Move(src,dst)
    local _,_,srcLocked = GetContainerItemInfo(src.container,src.position)
    local _,_,dstLocked = GetContainerItemInfo(dst.container,dst.position)
	if not srcLocked and not dstLocked then
		ClearCursor()
       	PickupContainerItem(src.container,src.position)
		PickupContainerItem(dst.container,dst.position)

	    local _,_,srcLocked = GetContainerItemInfo(src.container,src.position)
	    local _,_,dstLocked = GetContainerItemInfo(dst.container,dst.position)
    	if srcLocked or dstLocked then
			if src.state.item == dst.state.item then
				local count = min(src.state.count, Clean_Up:Info(dst.state.item).stack - dst.state.count)
				src.state.count = src.state.count - count
				dst.state.count = dst.state.count + count
				if src.count == 0 then src.state.item = nil end
			else
				src.state,dst.state = dst.state,src.state
			end
		end
		return true
    end
end
function Clean_Up:TooltipInfo(container,position)
	local chargesPattern = '^'..gsub(gsub(ITEM_SPELL_CHARGES_P1, '%%d', '(%%d+)'), '%%%d+%$d', '(%%d+)')..'$'
	Clean_Up_Tooltip:SetOwner(Clean_Up, ANCHOR_NONE)
	Clean_Up_Tooltip:ClearLines()
	if container == BANK_CONTAINER then Clean_Up_Tooltip:SetInventoryItem('player', BankButtonIDToInvSlotID(position)) else Clean_Up_Tooltip:SetBagItem(container,position) end

	local charges,usable,soulbound,quest,conjured
	for i=1,Clean_Up_Tooltip:NumLines() do
		local text = getglobal('Clean_Up_TooltipTextLeft'..i):GetText()
		local _,_,chargeString = strfind(text,chargesPattern)
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
function Clean_Up:Sort()
	local complete = true
	local counter = 0
	for _,dst in Clean_Up.model do
		if dst.item and (dst.state.item ~= dst.item or dst.state.count < dst.count) then
			complete = false
			if counter == 10 then return false end

			local sources,rank = {},{}
			for _,src in Clean_Up.model do
				if src.state.item == dst.item
					and src ~= dst
					and not (dst.state.item and src.class and src.class ~= Clean_Up:Info(dst.state.item).class)
					and not (src.item and src.state.item == src.item and src.state.count <= src.count)
				then
					rank[src] = abs(src.state.count - dst.count + (dst.state.item == dst.item and dst.state.count or 0))
					tinsert(sources, src)
				end
			end
			sort(sources, function(a, b) return rank[a] < rank[b] end)
			for _,src in sources do
				if Clean_Up:Move(src,dst) then
					counter=counter+1
					break
				end
			end
		end
	end
	return stopSorting or complete
end
function Clean_Up:Stack()
	local counter = 0
	for _,src in Clean_Up.model do
		if counter == 10 then return false end
		if src.state.item and src.state.count < Clean_Up:Info(src.state.item).stack then
			for _,dst in Clean_Up.model do
				if dst ~= src and dst.state.item and dst.state.item == src.state.item and dst.state.count < Clean_Up:Info(dst.state.item).stack then
					counter=counter+1
					Clean_Up:Move(src,dst)
				end
			end
		end
	end
end
local keyToRepeatIfNotFinished = "bags"
function Clean_Up:Go(key)
	if Clean_Up:IsVisible() then stopSorting = true else stopSorting = nil end
	Clean_Up.containers = Clean_Up[key].containers
	Clean_Up.model = nil
	moveCounter = maxMovesPerClick
	keyToRepeatIfNotFinished = key
	Clean_Up:Show()
end
do
	local items,counts
	local function insert(t, v)
		if Clean_Up_Settings.reversed then tinsert(t, v) else tinsert(t, 1, v) end
	end
	local function assign(slot,item)
		if counts[item] > 0 then
			local count = min(counts[item], Clean_Up:Info(item).stack)
			slot.item = item
			slot.count = count
			counts[item] = counts[item] - count
			return true
		end
	end
	local function assignCustom()
		for _,slot in Clean_Up.model do
			for item in Clean_Up:Present(Clean_Up_Settings.assignments[slot.container..":"..slot.position]) do
				if counts[item] then assign(slot,item) end
			end
		end
	end
	local function assignSpecial()
		for key,class in Clean_Up.CLASSES do
			for _,slot in Clean_Up.model do
				if slot.class == key and not slot.item then
					for _,item in items do
						if Clean_Up:Info(item).class == key and assign(slot,item) then break end
				    end
			    end
			end
		end
	end
	local function assignRemaining()
		for _,slot in Clean_Up.model do
			if not slot.class and not slot.item then
				for _,item in items do
					if assign(slot,item) then break end
			    end
		    end
		end
	end
	function Clean_Up:CreateModel()
		Clean_Up.model = {}
		counts = {}
		for _,container in Clean_Up.containers do
			local class = Clean_Up:Class(container)
			for position=1,GetContainerNumSlots(container) do
				local slot = {container=container,position=position,class=class}
				local item = Clean_Up:Item(container,position)
				if item then
					local _,count = GetContainerItemInfo(container,position)
					slot.state = {item=item,count=count}
					counts[item] = (counts[item] or 0) + count
				else
					slot.state = {}
				end
				insert(Clean_Up.model, slot)
			end
		end
		items = {}
		for item,_ in counts do tinsert(items,item) end
		sort(items, function(a, b) return Clean_Up:LT(Clean_Up:Info(a).sortKey, Clean_Up:Info(b).sortKey) end)
		assignCustom()
		assignSpecial()
		assignRemaining()
	end
end
do
	local cache = {}
	function Clean_Up:Class(container)
		if not cache[container] and container ~= 0 and container ~= BANK_CONTAINER then
			for name in Clean_Up:Present(GetBagName(container)) do		
				for class,info in Clean_Up.CLASSES do
					for _,itemID in info.containers do
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
	function Clean_Up:Info(item) return setmetatable({}, {__index=cache[item]}) end
	function Clean_Up:Item(container,position)
		for link in Clean_Up:Present(GetContainerItemLink(container,position)) do
			local _,_,itemID,enchantID,suffixID,uniqueID = strfind(link, 'item:(%d+):(%d*):(%d*):(%d*)')
			itemID = tonumber(itemID)
			local _,_,quality,_,type,subType,stack,invType = GetItemInfo(itemID)
			local charges,usable,soulbound,quest,conjured = Clean_Up:TooltipInfo(container,position)
			local key = format('%s:%s:%s:%s:%s:%s', itemID, enchantID, suffixID, uniqueID, charges, (soulbound and 1 or 0))
			if not cache[key] then
				local sortKey = {}
				if itemID == 6948 then -- hearthstone
					tinsert(sortKey, 1)
				elseif Clean_Up.MOUNT[itemID] then -- mounts
					tinsert(sortKey, 2)
				elseif Clean_Up.SPECIAL[itemID] then -- special items
					tinsert(sortKey, 3)
				elseif Clean_Up.KEY[itemID] then -- key items
					tinsert(sortKey, 4)
				elseif Clean_Up.TOOL[itemID] then -- tools
					tinsert(sortKey, 5)
				elseif soulbound then -- soulbound items
					tinsert(sortKey, 6)
				elseif type == Clean_Up.ITEM_TYPES[9] then -- reagents
					tinsert(sortKey, 7)
				elseif usable and type ~= Clean_Up.ITEM_TYPES[1] and type ~= Clean_Up.ITEM_TYPES[2] and type ~= Clean_Up.ITEM_TYPES[8] or type == Clean_Up.ITEM_TYPES[4] then -- consumables
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
				tinsert(sortKey, Clean_Up:ItemTypeKey(type))
				tinsert(sortKey, Clean_Up:ItemInvTypeKey(type, subType, invType))
				tinsert(sortKey, Clean_Up:ItemSubTypeKey(type, subType))
				tinsert(sortKey, itemID)
				tinsert(sortKey, 1/charges)
				tinsert(sortKey, suffixID)
				tinsert(sortKey, enchantID)
				tinsert(sortKey, uniqueID)
				cache[key] = { stack = stack, sortKey = sortKey, }
				for class,info in Clean_Up.CLASSES do
					if info.items[itemID] then cache[key].class = class end
				end
			end
			return key
		end
	end
end
