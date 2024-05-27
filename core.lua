local addonName,addon = ...
local L = addon.L
local f=CreateFrame("Frame")
f.OnEvent = function(_,event,...)
  return addon[event] and addon[event](addon,...)
end
f:SetScript("OnEvent",f.OnEvent)
f:RegisterEvent("ADDON_LOADED")

local function loadPaneStatus()
  local showStatus = not not CharacterStatsPaneImprovedDB.showPane
  if PaperDollFrame:IsVisible() or PetPaperDollFrame:IsVisible() then
    if CharacterStatsPane:IsShown() ~= showStatus then
      CharacterFrameExpandButton:Click()
    end
  end
end

function InitVars()
  CharacterStatsPaneImprovedDB = CharacterStatsPaneImprovedDB or {{},{}} -- primary, secondary specs
  CharacterStatsPaneImprovedDB[1].collapsed = CharacterStatsPaneImprovedDB[1].collapsed or {}
  CharacterStatsPaneImprovedDB[1].order = CharacterStatsPaneImprovedDB[1].order or {}
  CharacterStatsPaneImprovedDB[2].collapsed = CharacterStatsPaneImprovedDB[2].collapsed or {}
  CharacterStatsPaneImprovedDB[2].order = CharacterStatsPaneImprovedDB[2].order or {}
  CharacterStatsPaneImprovedDBG = CharacterStatsPaneImprovedDBG or {showLuck = true}
end

function addon:SetupPaneHooks()
  EventRegistry:RegisterCallback("CharacterFrame.Show", loadPaneStatus, addon)
  hooksecurefunc(CharacterFrame, "ShowSubFrame", loadPaneStatus)
  hooksecurefunc(CharacterFrame,"Expand",function()
    CharacterStatsPaneImprovedDB.showPane = true
  end)
  CharacterFrameExpandButton:HookScript("PreClick",function(self,button,down)
    CharacterStatsPaneImprovedDB.showPane = not CharacterFrame.Expanded
  end)
  hooksecurefunc("PaperDoll_InitStatCategories",addon.InitStatCategories)
  hooksecurefunc("PaperDoll_MoveCategoryUp",addon.MoveCategoryUp)
  hooksecurefunc("PaperDoll_MoveCategoryDown",addon.MoveCategoryDown)
  --hooksecurefunc("PaperDollStatCategory_OnDragStart",addon.StatCategory_OnDragStart)
  --hooksecurefunc("PaperDollStatCategory_OnDragStop",addon.StatCategory_OnDragStop)
  hooksecurefunc("PaperDollFrame_UpdateStatCategory",addon.CleanStatCategory)
end

local PAPERDOLL_STATINFO_CSPM = addon.NEW_STATINFO
function addon:SetupInjections()
  PAPERDOLL_STATINFO = setmetatable(PAPERDOLL_STATINFO,{__index = PAPERDOLL_STATINFO_CSPM})
end

function addon:ADDON_LOADED(...)
  if ... == addonName then
    InitVars()
    self:SetupPaneHooks()
    self:SetupInjections()
    addon.spec = GetActiveTalentGroup() or 1
    f:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    self:AddStat("DEFENSE","CTC","BLOCK")
    self:AddStat("GENERAL","GEARCHECK")
    self:AddStat("ATTRIBUTES","LUCK")
  end
end

function addon:ACTIVE_TALENT_GROUP_CHANGED(...)
  local changedTo, changedFrom = ...
  local prevSpec = addon.spec or 1
  addon.spec = changedTo or 1
  if addon.spec ~= prevSpec then
    local cvarOrder,cvarCollapse
    if addon.spec == 1 then
      cvarOrder,cvarCollapse = "statCategoryOrder","statCategoriesCollapsed"
    else
      cvarOrder,cvarCollapse = "statCategoryOrder_2","statCategoriesCollapsed_2"
    end
    self.InitStatCategories(PAPERDOLL_STATCATEGORY_DEFAULTORDER,cvarOrder,cvarCollapse,"player")
  end
end

_G[addonName]=addon
