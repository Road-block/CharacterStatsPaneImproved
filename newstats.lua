local addonName, addon = ...
local L = addon.L
local _
local private = {}
_,addon.RACE,addon.RACEID = UnitRace("player")
_,addon.CLASS,addon.CLASSID = UnitClass("player")
addon.TANKTREE = {
  WARRIOR = 3,
  PALADIN = 2,
  DRUID = 2,
  DEATHKNIGHT = 1,
}
addon.SLOTMAP = {
  [INVSLOT_HEAD] = _G.HEADSLOT,
  [INVSLOT_NECK] = _G.NECKSLOT,
  [INVSLOT_SHOULDER] = _G.SHOULDERSLOT,
  [INVSLOT_CHEST] = _G.CHESTSLOT,
  [INVSLOT_WAIST] = _G.WAISTSLOT,
  [INVSLOT_LEGS] = _G.LEGSSLOT,
  [INVSLOT_FEET] = _G.FEETSLOT,
  [INVSLOT_WRIST] = _G.WRISTSLOT,
  [INVSLOT_HAND] = _G.HANDSSLOT,
  [INVSLOT_FINGER1] = _G.FINGER0SLOT.."1",
  [INVSLOT_FINGER2] = _G.FINGER1SLOT.."2",
  [INVSLOT_TRINKET1] = _G.TRINKET0SLOT.."1",
  [INVSLOT_TRINKET2] = _G.TRINKET1SLOT.."2",
  [INVSLOT_BACK] = _G.BACKSLOT,
  [INVSLOT_MAINHAND] = _G.MAINHANDSLOT,
  [INVSLOT_OFFHAND] = _G.SECONDARYHANDSLOT,
  [INVSLOT_RANGED] = _G.RANGEDSLOT,
}

local function FindPlayerAuraByID(spellId)
  local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellId)
  if aura and aura.spellId == spellId then
    return aura.name
  end
  return false
end

local professions = {
  ENG = 202,
  BS = 164,
  ENCH = 333,
}
local function HasProfession(prof)
  local profID = professions[prof]
  if not profID then return false end
  local prof1, prof2, arch, fish, cook, firstAid = GetProfessions()
  local prof1Name, prof1ID, prof2Name, prof2ID
  if prof1 then
    prof1Name, _, _, _, _, _, prof1ID = GetProfessionInfo(prof1)
  end
  if prof1ID and prof1ID == profID then
    return prof1Name
  end
  if prof2 then
    prof2Name, _, _, _, _, _, prof2ID = GetProfessionInfo(prof2)
  end
  if prof2ID and prof2ID == profID then
    return prof2Name
  end
  return false
end

local item_info = { }
local function LinkBreakDown(itemLink)
  wipe(item_info)
  local linkType, itemString, displayName = LinkUtil.ExtractLink(itemLink)
  if itemString and itemString:find(":") then
    for info in (itemString..":"):gmatch("([^:]*):") do
      item_info[#item_info+1] = tonumber(info) or "nil"
    end
  end
  return item_info
end

local function ScanSlotTooltip(slot, lookFor)
  addon.scanTip = addon.scanTip or CreateFrame("GameTooltip",addonName.."TooltipScanner",nil,"GameTooltipTemplate")
  --addon.scanTip:Hide()
  addon.scanTip:ClearLines()
  if not addon.scanTip:IsOwned(WorldFrame) then
    addon.scanTip:SetOwner(WorldFrame,"ANCHOR_NONE")
  end
  local lookForCapture = format("(%s)",lookFor)
  local hasItem, hasCD, repairCost = addon.scanTip:SetInventoryItem("player",slot)
  local ttName = addon.scanTip:GetName()
  if (hasItem) then
    for i=2,8 do
      local line = _G[ttName.."TextLeft"..i]
      if line then
        local linetext = line:GetText() or ""
        if linetext:match(lookForCapture) then
          return lookFor,linetext
        end
      end
    end
  else
    return false
  end
  return false
end

local luck_data = {}
local luck_quotes = {
  [[I broke a mirror and got seven years bad luck but my lawyer thinks he can get me down to five]],
  [[I think we consider too much the good luck of the early bird and not enough the bad luck of the early worm]],
  [[You gotta try your luck at least once a day, because you could be going around lucky all day and not even know it]],
  [[The way my luck is running, if I was a politician I would be honest]],
  [[A pound of pluck is worth a ton of luck]],
  [[Every day a piano doesn't fall on my head is good luck]],
  [[I'm lucky to have survived so much bad luck]],
  [[A man forgets his good luck the next day, but remembers his bad luck until next year]],
  [[Probability said that some day we would run out of luck]],
  [[Good luck is coming your way. Be ready.]],
  [[Depend on the rabbit’s foot if you will, but remember it didn’t work for the rabbit]],
  [[Luck affects everything; let your hook always be cast; in the stream where you least expect it, there will be a fish]],
  [[Maybe I’m lucky to be going so slowly, because I may be going in the wrong direction]],
  [[Luck has a peculiar habit of favoring those who don’t depend on it]],
  [[The only sure thing about luck is that it will change]],
  [[Throw a lucky man in the sea, and he will come up with a fish in his mouth]],
  [[If you are looking for bad luck, you will soon find it ^_^]],
  [[I asked luck for a penny, and she gave me a dime. That’s what I call inflation.]],
  [[I don’t need luck, I just need a good sense of humor and a lot of caffeine.]],
  [[I get enough exercise just pushing my luck!]],
  [[Luck is like a boomerang – sometimes it comes back to hit you in the face]],
  [[There Goes Your Life Savings...]],
  [[I have one-of-a-kind items]],
  [[Your gold is welcome here]],
}
local function getLUCK()
  local now = GetTime()
  if addon.old_luck and (now - addon.old_luck) > 600 then
    wipe(luck_data)
    addon.old_luck = now
  end
  if #luck_data < 2 then
    table.insert(luck_data,fastrandom(1,100))
    table.insert(luck_data,fastrandom(1,100))
  end
  if #luck_data > 9 then
    table.remove(luck_data,1)
    table.insert(luck_data,fastrandom(1,100))
  end
  local luck = Accumulate(luck_data)/#luck_data
  local quote = luck_quotes[math.random(1,#luck_quotes)]
  return luck, quote
end

addon.ctc_data = {}
local function getCTC()
  wipe(addon.ctc_data)
  local baseMissed = addon.RACEID == 4 and 7 or 5
  local baseDodge = GetDodgeChance()
  local baseParry = GetParryChance()
  local baseBlock = addon.CLASSID > 2 and 0 or GetBlockChance()
  for enemyLevel = 0, 3, 1 do
    local missed = math.max(0,baseMissed-(enemyLevel*0.2))
    local dodge = math.max(0,baseDodge-(enemyLevel*0.2))
    local parry = math.max(0,baseParry-(enemyLevel*0.2))
    local block = math.max(0,baseBlock-(enemyLevel*0.2))
    local coverage = missed+dodge+parry+block
    local ctc_delta = 100 - (missed+dodge+parry+block)
    addon.ctc_data[enemyLevel] = {ctc=coverage,delta=ctc_delta}
  end
  return addon.ctc_data
end

local function CTC_OnEnter(statFrame)
  if (MOVING_STAT_CATEGORY) then return end
  GameTooltip:SetOwner(statFrame, "ANCHOR_RIGHT")
  if not addon.ctc_data[3] then return end
  local playerLevel = UnitLevel("player")
  local is_warrior = addon.CLASSID and (addon.CLASSID == 1)
  local coverage, delta = addon.ctc_data[3].ctc, addon.ctc_data[3].delta
  coverage = format("%.2F%%",coverage>=100 and 100 or coverage)
  local can_shieldblock = is_warrior and not FindPlayerAuraByID(2565)
  if delta > 0 then
    if can_shieldblock and (delta <= 25) then
      coverage = YELLOW_FONT_COLOR_CODE .. coverage .. FONT_COLOR_CODE_CLOSE
    else
      coverage = RED_FONT_COLOR_CODE .. coverage .. FONT_COLOR_CODE_CLOSE
    end
  end
  GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, L.STAT_CTC_VERBOSE)..format(" %.1F%%",addon.ctc_data[3].ctc)..FONT_COLOR_CODE_CLOSE)
  GameTooltip:AddLine(format(L.STAT_CTC_DETAIL, coverage, -delta))
  GameTooltip:AddLine(" ")
  GameTooltip:AddDoubleLine(STAT_TARGET_LEVEL, L.STAT_CTC_DELTA, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
  for i=0,3,1 do
    coverage, delta = addon.ctc_data[i].ctc, addon.ctc_data[i].delta
    local level = playerLevel + i
    if i == 3 then
      level = level.." / |TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|t"
    end
    if delta < 0 then
      if is_warrior and IsPlayerSpell(76857) then -- warrior with crit block mastery
        delta = format(L.STAT_CTC_CRITBLOCK, -delta)
      else
        if delta > -1 then
          delta = GREEN_FONT_COLOR_CODE..format("%.2F%%    ",-delta)..FONT_COLOR_CODE_CLOSE
        else
          delta = GRAY_FONT_COLOR_CODE..format("%.2F%%    ",-delta)..FONT_COLOR_CODE_CLOSE
        end
      end
    else
      if can_shieldblock and (delta <= 25) then -- softcap, can ctc with shield block
        delta = YELLOW_FONT_COLOR_CODE..format("%.2F%%    ",-delta)..FONT_COLOR_CODE_CLOSE
      else
        delta = RED_FONT_COLOR_CODE..format("%.2F%%    ",-delta)..FONT_COLOR_CODE_CLOSE
      end
    end
    GameTooltip:AddDoubleLine("      "..level, delta, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
  end
  GameTooltip:Show()
end

local function PaperDollFrame_SetCTC(statFrame, unit)
  if (unit ~= "player") then
    statFrame:Hide()
    return
  end
  local specID = GetPrimaryTalentTree() or 0 -- can be nil for unspecced characters
  local tankSpec = addon.TANKTREE[addon.CLASS]
  if not (tankSpec and tankSpec == specID) then
    statFrame:Hide()
    return
  end
  addon.ctc_data = getCTC()

  PaperDollFrame_SetLabelAndText(statFrame, L.STAT_CTC, addon.ctc_data[3].ctc, true, addon.ctc_data[3].ctc)
  statFrame:SetScript("OnEnter", CTC_OnEnter)
  statFrame:Show()
end

local stats_temp_sockets = {}
function private.countSockets(slot)
  wipe(stats_temp_sockets)
  local itemlink = GetInventoryItemLink("player",slot)
  local socketCount = 0
  local extraSocket = 0
  if itemlink then
    if (slot == INVSLOT_WAIST) then
      extraSocket = 1
    end
    if (slot == INVSLOT_WRIST) or (slot == INVSLOT_HAND) then
      if HasProfession("BS") then
        extraSocket = 1
      end
    end
    stats_temp_sockets = GetItemStats(itemlink) or {}
    for statKey,v in pairs(stats_temp_sockets) do
      if statKey:match("_SOCKET_") then
        socketCount = socketCount + tonumber(v)
      end
    end
  end
  return socketCount+extraSocket, extraSocket -- total possible, extra
end
function private.checkEnch(slot)
  if HasProfession("ENCH") and GetInventoryItemID("player",slot) then
    return true
  end
  return false
end
function private.checkEngi(slot)
  if HasProfession("ENG") and GetInventoryItemID("player",slot) then
    return true
  end
  return false
end
function private.checkOffhand()
  local item = GetInventoryItemID("player",INVSLOT_OFFHAND)
  if item then
    local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID = GetItemInfoInstant(item)
    if classID == Enum.ItemClass.Armor and subclassID == Enum.ItemArmorSubclass.Shield then
      return true
    end
    if classID == Enum.ItemClass.Weapon then
      return true
    end
  end
  return false
end
function private.checkRanged()
  local item = GetInventoryItemID("player",INVSLOT_RANGED)
  if (item) then
    local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID = GetItemInfoInstant(item)
    if classID == Enum.ItemClass.Weapon and subclassID ~= Enum.ItemWeaponSubclass.Wand then
      return true -- could give non-Hunters a pass
    end
  end
  return false
end

local enchantable = {
  [INVSLOT_HEAD] = true,
  [INVSLOT_SHOULDER] = true,
  [INVSLOT_BACK] = true,
  [INVSLOT_CHEST] = true,
  [INVSLOT_WRIST] = true,
  [INVSLOT_HAND] = true,
  [INVSLOT_LEGS] = true,
  [INVSLOT_FEET] = true,
  [INVSLOT_MAINHAND] = true,
  [INVSLOT_OFFHAND] = true, --"checkOffhand", -- only weapon + shield edit: frills can also be enchanted in cata
  [INVSLOT_RANGED] = "checkRanged", -- weapons except wands
  [INVSLOT_FINGER1] = "checkEnch", -- only enchanters
  [INVSLOT_FINGER2] = "checkEnch", -- only enchanters
}
local socketable = {
  [INVSLOT_HEAD] = "countSockets",
  [INVSLOT_NECK] = "countSockets",
  [INVSLOT_SHOULDER] = "countSockets",
  [INVSLOT_CHEST] = "countSockets",
  [INVSLOT_LEGS] = "countSockets",
  [INVSLOT_FEET] = "countSockets",
  [INVSLOT_WRIST] = "countSockets", -- blacksmithing (prof)
  [INVSLOT_HAND] = "countSockets", -- blacksmithing (prof)
  [INVSLOT_FINGER1] = "countSockets",
  [INVSLOT_FINGER2] = "countSockets",
  [INVSLOT_TRINKET1] = "countSockets",
  [INVSLOT_TRINKET2] = "countSockets",
  [INVSLOT_BACK] = "countSockets",
  [INVSLOT_MAINHAND] = "countSockets",
  [INVSLOT_OFFHAND] = "countSockets",
  [INVSLOT_RANGED] = "countSockets",
  [INVSLOT_WAIST] = "countSockets", -- belt buckle (everyone)
}
local tinkers = {
  [INVSLOT_BACK] = "checkEngi", -- only engineers
  [INVSLOT_HAND] = "checkEngi", -- only engineers
  [INVSLOT_WAIST] = "checkEngi", -- only engineers
}
local tinker_spells = {
  [54735] = (GetSpellInfo(54735)),
  [67890] = (GetSpellInfo(67890)),
  [54757] = (GetSpellInfo(54757)),
  [54758] = (GetSpellInfo(54758)),
  [55001] = (GetSpellInfo(55001)),
  [55004] = (GetSpellInfo(55004)),
  [82387] = (GetSpellInfo(82387)),
  [67810] = (GetSpellInfo(67810)),
  [82174] = (GetSpellInfo(82174)),
  [82176] = (GetSpellInfo(82176)),
  [82179] = (GetSpellInfo(82179)),
  [82184] = (GetSpellInfo(82184)),
  [82186] = (GetSpellInfo(82186)),
  [82820] = (GetSpellInfo(82820)),
  [94548] = (GetSpellInfo(94548)),
  [82626] = (GetSpellInfo(82626)),
}
addon.enchant_list = { }
addon.socket_list = { }
addon.tinker_list = { }
local function getGearCheckList()
  wipe(addon.enchant_list)
  wipe(addon.socket_list)
  wipe(addon.tinker_list)
  for slot, check in pairs(enchantable) do
    if (GetInventoryItemID("player", slot)) then
      if check == true then
        addon.enchant_list[slot] = 1
      else
        if private[check](slot) then
          addon.enchant_list[slot] = 1
        end
      end
    end
  end
  for slot, check in pairs(socketable) do
    if (GetInventoryItemID("player", slot)) then
      if check == true then
        addon.socket_list[slot] = 1
      else
        if private[check](slot) then
          addon.socket_list[slot] = private[check](slot)
        end
      end
    end
  end
  for slot,check in pairs(tinkers) do
    if (GetInventoryItemID("player", slot)) then
      if (check == true) or private[check](slot) then
        addon.tinker_list[slot] = 1
      end
    end
  end
  return addon.enchant_list, addon.socket_list, addon.tinker_list
end

addon.gearcheck_data = { }
local function getGearCheck()
  wipe(addon.gearcheck_data)
  addon.enchant_list, addon.socket_list, addon.tinker_list = getGearCheckList()
  local availableEnchants = Accumulate(addon.enchant_list)
  local availableSockets = Accumulate(addon.socket_list)
  local availableTinkers = Accumulate(addon.tinker_list)
  addon.gearcheck_data.total = availableEnchants + availableSockets + availableTinkers
  local have = 0
  for slot, _ in pairs(addon.enchant_list) do
    local itemdata = LinkBreakDown(GetInventoryItemLink("player",slot))
    if type(itemdata[2]) == "number" then
      have = have + 1
    else
      addon.gearcheck_data.missing = addon.gearcheck_data.missing or {}
      addon.gearcheck_data.missing[L["Enchants"]] = addon.gearcheck_data.missing[L["Enchants"]] or {}
      addon.gearcheck_data.missing[L["Enchants"]][slot] = 1
    end
  end
  for slot, maxGems in pairs(addon.socket_list) do
    local gems = addon.wrapTuple(GetInventoryItemGems(slot))
    local gemCount = addon.tCount(gems)
    have = have + gemCount
    if gemCount < maxGems then
      addon.gearcheck_data.missing = addon.gearcheck_data.missing or {}
      addon.gearcheck_data.missing[L["Gems"]] = addon.gearcheck_data.missing[L["Gems"]] or {}
      addon.gearcheck_data.missing[L["Gems"]][slot] = maxGems-gemCount
    end
  end
  for slot, _ in pairs(addon.tinker_list) do
    local spellName, spellId = GetItemSpell(GetInventoryItemLink("player",slot))
    if tinker_spells[spellId] then
      have = have + 1
    else
      addon.gearcheck_data.missing = addon.gearcheck_data.missing or {}
      addon.gearcheck_data.missing[L["Tinkers"]] = addon.gearcheck_data.missing[L["Tinkers"]] or {}
      addon.gearcheck_data.missing[L["Tinkers"]][slot] = 1
    end
  end
  addon.gearcheck_data.have = have -- we'll compute this here
  return addon.gearcheck_data
end

local function GEARCHECK_OnEnter(statFrame)
  if (MOVING_STAT_CATEGORY) then return end
  GameTooltip:SetOwner(statFrame, "ANCHOR_RIGHT")
  if addon.gearcheck_data.total then
    GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, L.STAT_GEARCHECK)..format(" %d/%d",addon.gearcheck_data.have,addon.gearcheck_data.total)..FONT_COLOR_CODE_CLOSE)
    if addon.tCount(addon.gearcheck_data.missing)>0 then
      GameTooltip:AddLine(" ")
      for cat,slots in pairs(addon.gearcheck_data.missing) do
        GameTooltip:AddLine(format(ITEM_MISSING,cat), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
        for slot,count in pairs(slots) do
          GameTooltip:AddDoubleLine("    "..addon.SLOTMAP[slot],format("%2d  ",count))
        end
      end
    end
    GameTooltip:Show()
  end
end

local function PaperDollFrame_SetGearCheck(statFrame, unit)
  if (unit ~= "player") then
    statFrame:Hide()
    return
  end
  if UnitLevel("player") < GetMaxPlayerLevel() then
    statFrame:Hide()
    return
  end
  addon.gearcheck_data = getGearCheck()
  PaperDollFrame_SetLabelAndText(statFrame, L.STAT_GEARCHECK, format("%d/%d",addon.gearcheck_data.have,addon.gearcheck_data.total), false)
  statFrame:SetScript("OnEnter", GEARCHECK_OnEnter)
  statFrame:Show()
end

local function PaperDollFrame_SetLUCK(statFrame, unit)
  if not CharacterStatsPaneImprovedDBG.showLuck then
    statFrame:Hide()
    return
  end
  if (unit ~= "player") then
    statFrame:Hide()
    return
  end
  if not addon.old_luck then addon.old_luck = GetTime() end
  local luck, quote = getLUCK() -- o_O
  local lucktext
  if luck > 99 then
    lucktext = format("|cffe5cc80%d%%|r",luck)
  elseif luck > 98 then
    lucktext = format("|cffe268a8%d%%|r",luck)
  elseif luck > 94 then
    lucktext = format("|cffff8000%d%%|r",luck)
  elseif luck > 74 then
    lucktext = format("|cffa335ee%d%%|r",luck)
  elseif luck > 49 then
    lucktext = format("|cff0070ff%d%%|r",luck)
  elseif luck > 24 then
    lucktext = format("|cff1eff00%d%%|r",luck)
  else
    lucktext = format("|cff666666%d%%|r",luck)
  end
  --PaperDollFrame_SetLabelAndText(statFrame, L.STAT_LUCK, lucktext, true, luck)
  if ( statFrame.Label ) then
    statFrame.Label:SetText(format(STAT_FORMAT, L.STAT_LUCK))
  end
  statFrame.Value:SetText(lucktext)
  statFrame.numericValue = luck
  statFrame.tooltip = format("%s: %.1F%%",L.STAT_LUCK,luck)
  statFrame.tooltip2 = GRAY_FONT_COLOR_CODE..quote..FONT_COLOR_CODE_CLOSE
  statFrame:Show()
end

addon.NEW_STATINFO = { }
if addon.TANKTREE[addon.CLASS] then -- warrior/paladin
  addon.NEW_STATINFO["CTC"] = {
    updateFunc = function(statFrame, unit) PaperDollFrame_SetCTC(statFrame, unit) end
  }
end
addon.NEW_STATINFO["GEARCHECK"] = {
  updateFunc = function(statFrame, unit) PaperDollFrame_SetGearCheck(statFrame, unit) end
}
addon.NEW_STATINFO["LUCK"] = {
  updateFunc = function(statFrame, unit) PaperDollFrame_SetLUCK(statFrame, unit) end
}

function addon:AddStat(categoryName_or_Id, newStat, after)
  if not addon.NEW_STATINFO[newStat] then return end
  local needUpdate = false
  local categoryName = categoryName_or_Id
  if type(categoryName_or_Id) == "number" then
    categoryName = PaperDoll_FindCategoryById(categoryName_or_Id)
  end
  if categoryName then
    local Stats = PAPERDOLL_STATCATEGORIES[categoryName].stats
    if not tContains(Stats, newStat) then
      local insertIdx
      if after then
        local test_idx = tIndexOf(Stats,after)
        if test_idx then
          insertIdx = test_idx+1
        end
      end
      if insertIdx then
        table.insert(Stats,insertIdx,newStat)
      else
        table.insert(Stats,newStat)
      end
      needUpdate = true
    end
  end
  if needUpdate then
    PaperDollFrame_UpdateStats()
  end
end
