local MogIt,mog = ...;
_G["MogIt"] = mog;
local L = mog.L;

mog.modules = {
	base = {},
	extra = {},
	lookup = {},
};
mog.sub = {};
mog.list = {};
mog.models = {};
mog.bin = {};
mog.posX = 0;
mog.posY = 0;
mog.posZ = 0;
mog.face = 0;

-- dropdown()
-- setlist()
-- update()
-- mouseover()
-- onclick()

-- UnsetList?
-- :Gets?
-- Sort/Filter/URL

function mog:RegisterModule(name,data,base)
	if mog.modules.lookup[name] then return end;
	mog.modules.lookup[name] = data;
	table.insert(base and mog.modules.base or mog.modules.extras,data);
	if UIDropDownMenu_GetCurrentDropDown() == mog.dropdown and DropDownList1 and DropDownList1:IsShown() then
		HideDropDownMenu(1);
		ToggleDropDownMenu(1,data,mog.dropdown);
	end
	return data;
end

function mog:GetModule(name)
	return mog.modules.lookup[name];
end

function mog:SetList(module,list,top)
	if mog.selected and mog.selected.Unlist then
		mog.selected:Unlist(module,list);
	end
	mog.selected = module;
	mog.list = list;
	--sorting
	--showfilter
	mog.scroll:update(top and 1);
	mog:FilterUpdate(); -- dont update if list isnt updated
end

function mog.toggleFrame()
	if mog.frame:IsShown() then
		HideUIPanel(mog.frame);
	else
		ShowUIPanel(mog.frame);
	end
end

function mog.togglePreview()
	if mog.preview:IsShown() then
		HideUIPanel(mog.preview);
	else
		ShowUIPanel(mog.preview);
	end
end

SLASH_MOGIT1 = "/mog";
SLASH_MOGIT2 = "/mogit";
SlashCmdList["MOGIT"] = toggleFrame;
--[[function(msg)
	if msg and msg > "" then
		if msg:match("item:(%d+)") then
			local id = msg:match("item:(%d+)");
			mog:ShowURL(id);
			return;
		elseif msg:match("spell:(%d+)") then
			local id = msg:match("spell:(%d+)");
			mog:ShowURL(id,"spell");
			return;
		end
	end
	mog.toggleFrame();
end--]]

BINDING_HEADER_MogIt = "MogIt";
BINDING_NAME_MogIt = L["Toggle Mogit"];

local LDB = LibStub("LibDataBroker-1.1");
mog.LDBI = LibStub("LibDBIcon-1.0");
mog.mmb = LDB:NewDataObject("MogIt",{
	type = "launcher",
	icon = "Interface\\Icons\\INV_Enchant_EssenceCosmicGreater",
	OnClick = function(self,btn)
		if btn == "RightButton" then
			mog.togglePreview();
		else
			mog.toggleFrame();
		end
	end,
	OnTooltipShow = function(self)
		if not self or not self.AddLine then return end
		self:AddLine("MogIt");
		self:AddLine(mog.frame:IsShown() and L["Left click to close MogIt"] or L["Left click to open MogIt"],1,1,1);
		--self:AddLine(mog.preview:IsShown() and L["Right click to close the MogIt preview"] or L["Right click to close the MogIt preview"],1,1,1);
	end,
});

local defaults = {
	profile = {
		tooltip = true,
		tooltipMouse = false,
		tooltipDress = false,
		tooltipRotate = true,
		tooltipMog = true,
		gridDress = true,
		noAnim = false,
		minimap = {},
		url = "Battle.net",
		--tooltipWidth = 300,
		--tooltipHeight = 300,
		width = 200,
		height = 200,
		rows = 2;
		columns = 3,
	}
}

mog.frame = CreateFrame("Frame","MogItFrame",UIParent,"ButtonFrameTemplate");
mog.frame:SetScript("OnEvent",function(self,event,arg1,...)
	if event == "PLAYER_LOGIN" then
		--mog.view.model.model:SetUnit("PLAYER");
		mog.updateGUI();
		--mog.updateModels();
		
		--[[mog.tooltip.model:SetUnit("PLAYER");
		mog.tooltip:SetSize(mog.db.profile.tooltipWidth,mog.db.profile.tooltipHeight);
		if mog.db.profile.tooltipRotate then
			mog.tooltip.rotate:Show();
		end--]]
	elseif event == "GET_ITEM_INFO_RECEIVED" then
		local owner = GameTooltip:IsShown() and GameTooltip:GetOwner();
		if owner and owner.MogItModel and mog.selected and mog.selected.OnEnter then
			mog.selected:OnEnter(owner);
		end
		if UIDropDownMenu_GetCurrentDropDown() == mog.sub.LeftClick and DropDownList1 and DropDownList1:IsShown() then
			HideDropDownMenu(1);
			ToggleDropDownMenu(nil,nil,mog.sub.LeftClick,"cursor",0,0,mog.sub.LeftClick.menuList);
		end
	elseif event == "ADDON_LOADED" then
		if arg1 == MogIt then
			print(MogIt_Character)
			local AceDB = LibStub("AceDB-3.0")
			
			local db = AceDB:New("MogItDB", defaults, true)
			mog.db = db
			
			-- deal with old saved variables
			if MogIt_Global then
				MogIt_Global.wishlist = nil
				for k, v in pairs (MogIt_Global) do
					db.profile[k] = v
				end
				-- MogIt_Global = nil
			end
			
			-- db.RegisterCallback(self, "OnProfileChanged", "LoadSettings")
			-- db.RegisterCallback(self, "OnProfileCopied", "LoadSettings")
			-- db.RegisterCallback(self, "OnProfileReset", "LoadSettings")
			
			if not mog.db.global.version then
				DEFAULT_CHAT_FRAME:AddMessage(L["MogIt has loaded! Type \"/mog\" to open it."]);
			end
			mog.db.global.version = GetAddOnMetadata(MogIt,"Version");
			
			mog.LDBI:Register(MogIt,mog.mmb,mog.db.profile.minimap);
			
			-- fire every module's "init" method (if they have one)
			for i, module in ipairs(mog.modules.base) do
				if module.AddonLoaded then
					module:AddonLoaded()
				end
			end
		end
		
		if mog.sub and mog.sub.modules[arg1] then
			mog.sub.modules[arg1].loaded = true;
			if UIDropDownMenu_GetCurrentDropDown() == mog.dropdown and DropDownList1 and DropDownList1:IsShown() then
				HideDropDownMenu(1);
				ToggleDropDownMenu(1,mog.sub.modules[arg1],mog.dropdown);
			end
		end
	end
end);
mog.frame:RegisterEvent("PLAYER_LOGIN");
mog.frame:RegisterEvent("GET_ITEM_INFO_RECEIVED");
mog.frame:RegisterEvent("ADDON_LOADED");


local LBB = LibStub("LibBabble-Boss-3.0"):GetUnstrictLookupTable();
local mobs = {};

--[[local tooltip = CreateFrame("GameTooltip","MogItMobsTooltip");
local text = tooltip:CreateFontString();
tooltip:AddFontStrings(text,tooltip:CreateFontString());

local function CachedMob(id)
	if not id then return end;
	tooltip:SetOwner(WorldFrame,"ANCHOR_NONE");
	tooltip:SetHyperlink(("unit:0xF53%05X00000000"):format(id));
	if (tooltip:IsShown()) then
		return text:GetText();
	end
end--]]

function mog.AddMob(id,name)
	--if not (mobs[id] or CachedMob(id)) then
	if not mobs[id] then
		mobs[id] = LBB[name] or name;
	end
end

function mog.GetMob(id)
	--return mobs[id] or CachedMob(id);
	return mobs[id];
end