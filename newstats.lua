local addonName, addon = ...
local L = addon.L
local _
_,addon.RACE,addon.RACEID = UnitRace("player")
_,addon.CLASS,addon.CLASSID = UnitClass("player")
addon.TANKTREE = {
  WARRIOR = 3,
  PALADIN = 2,
  DRUID = 2,
  DEATHKNIGHT = 1,
}
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

local function CTC_OnEnter(statFrame)
  if (MOVING_STAT_CATEGORY) then return end
  GameTooltip:SetOwner(statFrame, "ANCHOR_RIGHT")
  if not addon.ctc_data[3] then return end
  local playerLevel = UnitLevel("player")
  local coverage, delta = addon.ctc_data[3].ctc, addon.ctc_data[3].delta
  coverage = format("%.2F%%",coverage>=100 and 100 or coverage)
  if delta > 0 then
    coverage = RED_FONT_COLOR_CODE .. coverage .. FONT_COLOR_CODE_CLOSE
  end
  GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, L.STAT_CTC_VERBOSE).." "..coverage..FONT_COLOR_CODE_CLOSE)
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
      if addon.CLASSID == 1 and IsPlayerSpell(76857) then -- warrior with crit block mastery
        delta = format(L.STAT_CTC_CRITBLOCK, -delta)
      else
        if delta > -1 then
          delta = GRAY_FONT_COLOR_CODE..format()
        else
          delta = GRAY_FONT_COLOR_CODE..format("%.2F%%",-delta)
        end
      end
    else
      delta = RED_FONT_COLOR_CODE..format("%.2F%%",-delta)
    end
    GameTooltip:AddDoubleLine("      "..level, delta.."    ", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
  end
  GameTooltip:Show()
end

local function PaperDollFrame_SetCTC(statFrame, unit)
  if (unit ~= "player") then
    statFrame:Hide()
    return
  end
  local talentIdx = GetPrimaryTalentTree()
  if not addon.TANKTREE[addon.CLASS] then
    statFrame:Hide()
    return
  end
  addon.ctc_data = getCTC()

  PaperDollFrame_SetLabelAndText(statFrame, L.STAT_CTC, addon.ctc_data[3].ctc, true, addon.ctc_data[3].ctc)
  statFrame:SetScript("OnEnter", CTC_OnEnter)
  statFrame:Show()
end

local function PaperDollFrame_SetLUCK(statFrame, unit)
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
-- 76857 -- warrior critical block
-- 76671 -- paladin divine bullwark