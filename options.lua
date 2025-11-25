local addonName, addon = ...
local L = addon.L
local options = { }
local children = { }

local OptionsFrame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
OptionsFrame:Hide()
OptionsFrame:SetAllPoints()
OptionsFrame.name = addonName
OptionsFrame.OnCommit = function() end
OptionsFrame.OnDefault = function() end
OptionsFrame.OnRefresh = function() end

function options.CheckBoxSetChecked(self)
  self:SetChecked(self:GetValue())
end

function options.CheckBoxOnClick(self)
  local checked = self:GetChecked()
  PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
  self:SetValue(checked)
end

function options.CheckBoxOnEnter(self)
  if self.tooltipText and self.tooltipRequirement then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, self.tooltipText)
    GameTooltip_AddNormalLine(GameTooltip, self.tooltipRequirement, true)
    GameTooltip:Show()
  end
end

function options.CheckBoxOnLeave(self)
  if GameTooltip:IsOwned(self) then
    GameTooltip_Hide()
  end
end

function options.CheckBoxGetOption(self)
  return CharacterStatsPaneImprovedDBG[self.option]
end

function options.CheckBoxSetOption(self, checked)
  CharacterStatsPaneImprovedDBG[self.option] = checked
end

function options.CheckBoxGetPCOption(self)
  return CharacterStatsPaneImprovedDB[self.option]
end

function options.CheckBoxSetPCOption(self, checked)
  CharacterStatsPaneImprovedDB[self.option] = checked
end

function options:CreateCheck(parent, option, get, set, label, description)
  local checkbox = CreateFrame("CheckButton", format("%sCheck%s",addonName,label), parent, "InterfaceOptionsCheckButtonTemplate")

  checkbox.option = option
  checkbox.GetValue = get or options.CheckBoxGetOption
  checkbox.SetValue = set or options.CheckBoxSetOption
  checkbox:SetScript("OnShow", options.CheckBoxSetChecked)
  checkbox:SetScript("OnClick", options.CheckBoxOnClick)
  checkbox:SetScript("OnEnter", options.CheckBoxOnEnter)
  checkbox:SetScript("OnLeave", options.CheckBoxOnLeave)
  checkbox:SetScript("OnHide", options.CheckBoxOnLeave)
  checkbox.label = _G[checkbox:GetName() .. "Text"]
  checkbox.label:SetText(label)
  checkbox.tooltipText = label
  checkbox.tooltipRequirement = description
  children[checkbox] = option

  return checkbox
end

local title = OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText(OptionsFrame.name)
local showLuck = options:CreateCheck(OptionsFrame, "showLuck", nil, nil, L["Show Luck"], L["Uncheck to hide the humorous 'Luck' Attribute\n(Account-wide option)"])
showLuck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)

local skipMeleeRange
if addon.IsCata then
  skipMeleeRange = options:CreateCheck(OptionsFrame, "skipMeleeRange", nil, nil, L["Skip Ranged Enchant"], L["Check to skp checking Enchants on Ranged for Melee\n(Account-wide option)"])
  skipMeleeRange:SetPoint("LEFT", showLuck, "RIGHT", 200, 0)
end

local dualShaTouched
if addon.IsMoP51 then
  -- maybe an option for the upgrade checks
  dualShaTouched = options:CreateCheck(OptionsFrame, "dualShaTouched", options.CheckBoxGetPCOption, options.CheckBoxSetPCOption, L["Dual Sha-Touched"], L["Count all Sha-Touched sockets when Dual Wielding"])
  dualShaTouched:SetPoint("TOPLEFT", showLuck, "BOTTOMLEFT", 0, -16)
end

-- Add to BlizzOptions
local category, layout = Settings.RegisterCanvasLayoutCategory(OptionsFrame, OptionsFrame.name, OptionsFrame.name);
category.ID = OptionsFrame.name;
Settings.RegisterAddOnCategory(category)
