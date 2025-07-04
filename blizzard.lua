local addonName, addon = ...

local STATCATEGORY_PADDING = 4
local STATCATEGORY_MOVING_INDENT = 4
local toolbarsHooked = { }

--[[ UTILITY ]]--
local function FindCategoryFrameFromCategoryName(categoryName)
  for index,name in ipairs(CharacterStatsPaneImprovedDB[addon.spec].order) do
    local frame = _G["CharacterStatsPaneCategory"..index]
    if frame and frame.Category == categoryName then
      return frame
    end
  end
  return nil
end

local function EqualArrays(arr1, arr2)
  if #arr1 ~= #arr2 then return false end
  local arr1str = table.concat(arr1,nil,1, addon.tCount(arr1))
  local arr2str = table.concat(arr2,nil,1, addon.tCount(arr2))
  if arr1str ~= arr2str then return false end
  return true
end

local function HookToolbars()
  for index,categoryName in ipairs(PAPERDOLL_STATCATEGORY_DEFAULTORDER) do
    local toolbarName = "CharacterStatsPaneCategory"..index.."Toolbar"
    local categoryFrameToolbar = _G[toolbarName]
    if not toolbarsHooked[toolbarName] then
      if categoryFrameToolbar then
        categoryFrameToolbar:HookScript("OnClick",addon.ToggleStatCategory)
        toolbarsHooked[toolbarName] = true
      end
    end
  end
end

--[[ STORE ]]--
-- category collapse/expand status
function addon.ToggleStatCategory(toolbar)
  if PetPaperDollFrame:IsVisible() then return end
  CharacterStatsPaneImprovedDB[addon.spec].collapsed = CharacterStatsPaneImprovedDB[addon.spec].collapsed or {}
  local categoryFrame = toolbar:GetParent()
  local category = categoryFrame.Category
  if (category) then
    if categoryFrame.collapsed then
      CharacterStatsPaneImprovedDB[addon.spec].collapsed[category] = true
    else
      CharacterStatsPaneImprovedDB[addon.spec].collapsed[category] = false
    end
  end
end

-- category order
function addon.MoveCategoryUp(self)
  if PetPaperDollFrame:IsVisible() then return end
  local category = self.Category
  for index = 2, #CharacterStatsPaneImprovedDB[addon.spec].order do
    if (CharacterStatsPaneImprovedDB[addon.spec].order[index] == category) then
      tremove(CharacterStatsPaneImprovedDB[addon.spec].order, index)
      tinsert(CharacterStatsPaneImprovedDB[addon.spec].order, index-1, category)
      break
    end
  end
  addon.UpdateCategoryPositions()
end

function addon.MoveCategoryDown(self)
  if PetPaperDollFrame:IsVisible() then return end
  local category = self.Category
  for index = 1, #CharacterStatsPaneImprovedDB[addon.spec].order-1 do
    if (CharacterStatsPaneImprovedDB[addon.spec].order[index] == category) then
      tremove(CharacterStatsPaneImprovedDB[addon.spec].order, index)
      tinsert(CharacterStatsPaneImprovedDB[addon.spec].order, index+1, category)
      break
    end
  end
  addon.UpdateCategoryPositions()
end

addon._dragInfo = {}
function addon.StatCategory_OnDragStart(self)

end
function addon.StatCategory_OnDragStop(self)

end

--[[RESTORE]]--
function addon.InitStatCategories(defaultOrder, orderCVarName, collapsedCVarName, unit)
  if unit and not (unit == "player") then return end

  HookToolbars()

  local numOrder = #CharacterStatsPaneImprovedDB[addon.spec].order
  if (numOrder == 0) or (numOrder ~= #PAPERDOLL_STATCATEGORY_DEFAULTORDER) then
    CharacterStatsPaneImprovedDB[addon.spec].order = table.wipe(CharacterStatsPaneImprovedDB[addon.spec].order)
    for index,categoryName in ipairs(PAPERDOLL_STATCATEGORY_DEFAULTORDER) do
      local categoryFrame = _G["CharacterStatsPaneCategory"..index]
      local toolbarName = "CharacterStatsPaneCategory"..index.."Toolbar"
      local categoryFrameToolbar = _G[toolbarName]
      if not toolbarsHooked[toolbarName] then
        categoryFrameToolbar:HookScript("OnClick",addon.ToggleStatCategory)
        toolbarsHooked[toolbarName] = true
      end
      if (categoryFrame) then
        table.insert(CharacterStatsPaneImprovedDB[addon.spec].order,categoryName)
      end
    end
  end

  if not EqualArrays(CharacterStatsPaneImprovedDB[addon.spec].order, PAPERDOLL_STATCATEGORY_DEFAULTORDER) then
    addon.UpdateCategoryPositions()
  end

  addon.UpdateCategoryCollapse()
end

function addon.UpdateCategoryCollapse()
  local numOrder = #CharacterStatsPaneImprovedDB[addon.spec].order
  for index=numOrder,1,-1 do
    local categoryName = CharacterStatsPaneImprovedDB[addon.spec].order[index]
    if CharacterStatsPaneImprovedDB[addon.spec].collapsed[categoryName] == true then
      local categoryFrame = FindCategoryFrameFromCategoryName(categoryName)
      if (categoryFrame) then
        PaperDollFrame_CollapseStatCategory(categoryFrame)
      end
    end
  end
end

function addon.UpdateCategoryPositions()
  local prevFrame = nil

  for index = 1, #CharacterStatsPaneImprovedDB[addon.spec].order do
    local frame = FindCategoryFrameFromCategoryName(CharacterStatsPaneImprovedDB[addon.spec].order[index])
    if frame then
      frame:ClearAllPoints()
      -- Indent the one we are currently dragging
      local xOffset = 0
      if (frame == MOVING_STAT_CATEGORY) then
        xOffset = STATCATEGORY_MOVING_INDENT
      elseif (prevFrame and prevFrame == MOVING_STAT_CATEGORY) then
        xOffset = -STATCATEGORY_MOVING_INDENT
      end

      if (prevFrame) then
        frame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0+xOffset, -STATCATEGORY_PADDING)
      else
        frame:SetPoint("TOPLEFT", 1+xOffset, -STATCATEGORY_PADDING+(CharacterStatsPane.initialOffsetY or 0))
      end
      prevFrame = frame
    end
  end
end

function addon.CleanStatCategory(categoryFrame)
  if PetPaperDollFrame:IsVisible() then return end
  if categoryFrame:IsShown() and not categoryFrame.collapsed then
    local totalHeight = categoryFrame:GetHeight()
    local needUpdate = false
    local categoryFrameName = categoryFrame:GetName()
    local categoryInfo = categoryFrame.Category and PAPERDOLL_STATCATEGORIES[categoryFrame.Category]
    if (categoryInfo) then
      local numStats = #categoryInfo.stats
      for i = 1, numStats, 1 do
        local statFrame = _G[categoryFrameName.."Stat"..i]
        if statFrame and statFrame:IsShown() then
          local text = statFrame.Value and statFrame.Value:GetText()
          if text == NOT_APPLICABLE then
            local statHeight = statFrame:GetHeight()
            totalHeight = totalHeight - statHeight
            local nextStatFrame = _G[categoryFrameName.."Stat"..(i+1)]
            if nextStatFrame and nextStatFrame:IsShown() then
              nextStatFrame:SetAllPoints(statFrame)
            end
            statFrame:Hide()
            needUpdate = true
          end
        end
      end
    end
    if needUpdate then
      categoryFrame:SetHeight(totalHeight)
      PaperDollFrame_UpdateStatScrollChildHeight()
    end
  end
end
