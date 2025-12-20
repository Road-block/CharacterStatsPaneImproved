local addonName, addon = ...
local L = addon.L
local _
local private = {}
local GetItemSpell = function(...)
  if _G.GetItemSpell then
    return _G.GetItemSpell(...)
  elseif C_Item and C_Item.GetItemSpell then
    return C_Item.GetItemSpell(...)
  end
end
local GetItemInfoInstant = function(...)
  if _G.GetItemInfoInstant then
    return _G.GetItemInfoInstant(...)
  elseif C_Item and C_Item.GetItemInfoInstant then
    return _G.GetItemInfoInstant(...)
  end
end
_,addon.RACE,addon.RACEID = UnitRace("player")
_,addon.CLASS,addon.CLASSID = UnitClass("player")
addon.TANKTREE = {
  WARRIOR     = 3,
  PALADIN     = 2,
  DRUID       = 2,
  DEATHKNIGHT = 1,
  MONK        = 1,
}
addon.DUALWIELD = {
  WARRIOR     = 2,
  SHAMAN      = 2,
  MONK        = {[1]=true,[3]=true},
  ROGUE       = {[1]=true,[2]=true,[3]=true},
  DEATHKNIGHT = {[1]=true,[2]=true,[3]=true},
}
addon.MELEE = {
  WARRIOR     = {[1]=true,[2]=true,[3]=true},
  PALADIN     = {[2]=true,[3]=true},
  DEATHKNIGHT = {[1]=true,[2]=true,[3]=true},
  SHAMAN      = 2,
  ROGUE       = {[1]=true,[2]=true,[3]=true},
  DRUID       = {[2]=true,[3]=true},
  MONK        = {[1]=true,[3]=true},
}
if addon.IsCata then
  addon.TANKTREE.DRUID = nil
  addon.TANKTREE.DEATHKNIGHT = nil
  addon.TANKTREE.MONK = nil
  addon.DUALWIELD.MONK = nil
  addon.MELEE.MONK = nil
end
if addon.IsMoP then -- can't parry
  addon.TANKTREE.DRUID = nil
end
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

if addon.IsMoP then
  addon.SLOTMAP[INVSLOT_RANGED] = nil
end

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

local function ScanSlotTooltip(slot, lookFor, plain)
  addon.scanTip = addon.scanTip or CreateFrame("GameTooltip",addonName.."TooltipScanner",nil,"GameTooltipTemplate")
  addon.scanTip:ClearLines()
  addon.scanTip:Hide()
  if not addon.scanTip:IsOwned(WorldFrame) then
    addon.scanTip:SetOwner(WorldFrame,"ANCHOR_NONE")
  end
  local lookForCapture = plain and format("(%s)",lookFor) or lookFor
  local hasItem, hasCD, repairCost = addon.scanTip:SetInventoryItem("player",slot)
  local ttName = addon.scanTip:GetName()
  if (hasItem) then
    for i=2,8 do
      local line = _G[ttName.."TextLeft"..i]
      if line then
        local linetext = line:GetText() or ""
        local matches = addon.wrapTuple(linetext:match(lookForCapture))
        if matches and #matches > 0 then
          return matches, linetext
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
  [[A pound of pluck is worth a ton of luck]],
  [[Learn to notice good luck when it's waving at you, trying to get your attention]]
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
  local specID
  if GetPrimaryTalentTree then
    specID = GetPrimaryTalentTree() or 0 -- can be nil for unspecced characters
  elseif C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
    specID = C_SpecializationInfo.GetSpecialization() or 0
  end
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

addon.AVRTCONST = { -- various class constants
  base = {
    parry = {
      WARRIOR = 3.01,
      PALADIN = 3.01,
      DEATHKNIGHT = 3.01,
      MONK = 3,
    },
    dodge = {
      WARRIOR = 5.01,
      PALADIN = 3.01,
      DEATHKNIGHT = 5.01,
      MONK = 0,
    },
  },
  cap = {
    parry = {
      WARRIOR = 237.1859,
      PALADIN = 237.1859,
      DEATHKNIGHT = 235.5,
      MONK = 50.276243,
    },
    dodge = {
      WARRIOR = 90.6425,
      PALADIN = 66.56745,
      DEATHKNIGHT = 90.6425,
      MONK = 501.25,
    },
  },
  dr = {
    WARRIOR = 0.956,
    PALADIN = 0.886,
    DEATHKNIGHT = 0.956,
    MONK = 1.422,
  },
}
addon.avrt_data = {}
local function getAVRT()
  local preDodge = GetDodgeChance()
  local preParry = GetParryChance()
  local const = addon.AVRTCONST
  local CLASS = addon.CLASS
  local baseDodge = const.base.dodge[CLASS]
  local baseParry = const.base.parry[CLASS]
  local capDodge = const.cap.dodge[CLASS]
  local capParry = const.cap.parry[CLASS]
  if addon.RACEID == 4 then -- nightelf
    baseDodge = baseDodge + 2
  end
  if addon.RACEID == 7 then -- gnome
    baseParry = baseParry - 0.01
  end
  -- rune of swordshattering 3365
  -- base_parry + cap_parry/cap_dodge*(dodge-base_dodge)
  local idealPreParry = baseParry + capParry/capDodge*(preDodge-baseDodge)
  local parryDelta = idealPreParry - preParry
  local ratioCap = capParry/capDodge
  -- parryDelta > 0 = get more parry, parryDelta < 0 = lose parry / gain dodge
  local idealRatio = idealPreParry/preDodge
  addon.avrt_data = {ideal=idealPreParry,goal=parryDelta,drcap=ratioCap}

  return addon.avrt_data
end

local function AVRT_OnEnter(statFrame)
  if (MOVING_STAT_CATEGORY) then return end
  GameTooltip:SetOwner(statFrame, "ANCHOR_RIGHT")
  GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, L.STAT_AVOIDRATIO)..format(" %.1F%%",addon.avrt_data.ideal)..FONT_COLOR_CODE_CLOSE)
  GameTooltip:AddLine(format(L.STAT_AVOIDRATIO_DETAIL, addon.avrt_data.ideal, addon.avrt_data.goal))
  GameTooltip:Show()
end

local function PaperDollFrame_SetAVRT(statFrame, unit)
  if (unit ~= "player") then
    statFrame:Hide()
    return
  end
  local specID
  if GetPrimaryTalentTree then
    specID = GetPrimaryTalentTree() or 0 -- can be nil for unspecced characters
  elseif C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
    specID = C_SpecializationInfo.GetSpecialization() or 0
  end
  local tankSpec = addon.TANKTREE[addon.CLASS]
  if not (tankSpec and tankSpec == specID) then
    statFrame:Hide()
    return
  end
  addon.avrt_data = getAVRT()

  PaperDollFrame_SetLabelAndText(statFrame, L.STAT_AVOIDRATIO_LABEL, abs(addon.avrt_data.goal), true, abs(addon.avrt_data.goal))
  statFrame:SetScript("OnEnter", AVRT_OnEnter)
  statFrame:Show()
end

--[[local function isDualWielding()
  local mainhand = GetInventoryItemID("player",INVSLOT_MAINHAND)
  local offhand = GetInventoryItemID("player",INVSLOT_OFFHAND)
  if mainhand and offhand then
    local _, _, _, _, _, MHclassID, MHsubclassID = GetItemInfoInstant(mainhand)
    local _, _, _, _, _, OHclassID, OHsubclassID = GetItemInfoInstant(offhand)
    if MHclassID == Enum.ItemClass.Weapon and OHclassID == Enum.ItemClass.Weapon then
      return true
    end
  end
  return false
end]]
local function canDualWield()
  local specID
  if GetPrimaryTalentTree then
    specID = GetPrimaryTalentTree() or 0 -- can be nil for unspecced characters
  elseif C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
    specID = C_SpecializationInfo.GetSpecialization() or 0
  end
  local dualwield = addon.DUALWIELD[addon.CLASS]
  if type(dualwield)=="table" then
    return dualwield[specID] and true or false
  elseif type(dualwield)=="number" then
    return dualwield == specID and true or false
  else
    return false
  end
  return false
end
addon.CRITCONST = {
  glance = 24,
  miss = 3,
  levelmiss = 1.5,
  block = 5,
  levelblock = 0.5,
  dodge = 3,
  parry = 3,
  leveldodge = 1.5,
  levelparry = 1.5,
  dualmisstax = 19,
  critsup = 1,
  raidbuff = 5,
  fullcombatable = 100,
}
addon.critcap_data = { }
local function getCRITCAP()
  local const = addon.CRITCONST
  local CLASS = addon.CLASS
  local critchance = GetCritChance()
  local hitchance = GetCombatRatingBonus(CR_HIT_MELEE) + GetHitModifier()
  local glancing = const.glance
  for i=0,3 do
    local dodgecombatable,oh_enemydodge = GetEnemyDodgeChance(i)
    local parrycombatable,oh_enemyparry = GetEnemyParryChance(i)
    local missenemycap = const.miss + (i*const.levelmiss)
    local missenemybase,oh_missenemy = missenemycap + (IsDualWielding() and const.dualmisstax or 0)
    local blockcombatable = const.block + (i*const.levelblock)
    oh_missenemy = missenemybase
    local misscombatable = math.max(0,missenemybase-hitchance)
    local critcap_back = const.fullcombatable - ((i==3 and glancing or 0) + misscombatable + dodgecombatable)
    local critcap_front = const.fullcombatable - ((i==3 and glancing or 0) + misscombatable + dodgecombatable + parrycombatable + blockcombatable)
    local realcritchance = math.max(0,critchance - (i*const.critsup))
    local canraiseby_back = misscombatable + dodgecombatable
    local canraiseby_front = canraiseby_back + parrycombatable
    addon.critcap_data[i] = {
      melee_critcap = critcap_back,
      tank_critcap = critcap_front,
      real_crit = realcritchance,
      melee_critcap_raise = canraiseby_back,
      tank_critcap_raise = canraiseby_front,
      melee_crit_delta = critcap_back-realcritchance,
      tank_crit_delta = critcap_front-realcritchance,
      melee_crit_delta_critbuffed = critcap_back-realcritchance-const.raidbuff,
      tank_crit_delta_critbuffed = critcap_front-realcritchance-const.raidbuff,
    }
    --local combatcritchance_front = realcritchance * (critcap_front/100)
    --local combatcritchance_back = realcritchance * (critcap_back/100)
  end

  return addon.critcap_data
end

local function CRITCAP_OnEnter(statFrame)
  if (MOVING_STAT_CATEGORY) then return end
  local boss_data = addon.critcap_data[3]
  GameTooltip:SetOwner(statFrame, "ANCHOR_RIGHT")
  GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, L.STAT_CRITCAP)..format(" %.1F%%",boss_data.melee_critcap)..format(" (|TInterface\\GROUPFRAME\\UI-GROUP-MAINTANKICON:0|t%.1F%%)",boss_data.tank_critcap)..FONT_COLOR_CODE_CLOSE)
  GameTooltip:AddLine(format(L.STAT_CRITCAP_REALCRIT,boss_data.real_crit))
  GameTooltip:AddLine(format(L.STAT_CRITCAP_CRITDELTA,boss_data.melee_crit_delta,boss_data.tank_crit_delta))
  GameTooltip:AddLine(format(L.STAT_CRITCAP_RAISEBY,boss_data.melee_critcap_raise,boss_data.tank_critcap_raise))
  GameTooltip:AddLine(" ")
  GameTooltip:AddDoubleLine(STAT_TARGET_LEVEL, L.STAT_CRITCAP_VERBOSE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
  local playerLevel = UnitLevel("player");
  for i=0,3 do
    local level = playerLevel + i;
      if (i == 3) then
        level = level.." / |TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|t";
      end
    GameTooltip:AddDoubleLine("      "..level, format("%d%% (|TInterface\\GROUPFRAME\\UI-GROUP-MAINTANKICON:0|t%d%%)",addon.critcap_data[i].melee_critcap+0.5,addon.critcap_data[i].tank_critcap+0.5).."    ", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
  end
  GameTooltip:Show()
end

local function PaperDollFrame_SetCRITCAP(statFrame, unit)
  if (unit ~= "player") then
    statFrame:Hide()
    return
  end
  local specID
  if GetPrimaryTalentTree then
    specID = GetPrimaryTalentTree() or 0 -- can be nil for unspecced characters
  elseif C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
    specID = C_SpecializationInfo.GetSpecialization() or 0
  end
  local meleespec = addon.MELEE[addon.CLASS]
  if type(meleespec) == "table" then
    if not meleespec[specID] then
      statFrame:Hide()
      return
    end
  elseif type(meleespec) == "number" then
    if meleespec~=specID then
      statFrame:Hide()
      return
    end
  else
    statFrame:Hide()
    return
  end
  local dualwield = addon.DUALWIELD[addon.CLASS]

  addon.critcap_data = getCRITCAP()
  local boss_data = addon.critcap_data[3]

  if ( statFrame.Label ) then
    statFrame.Label:SetText(format(STAT_FORMAT, L.STAT_CRITCAP))
  end
  statFrame.Value:SetText(format("%d%%",boss_data.melee_critcap+0.5))
  statFrame.numericValue = boss_data.melee_critcap
  statFrame:SetScript("OnEnter", CRITCAP_OnEnter)
  statFrame:Show()
end

local thunder_armaments = { }
local crafted_reborn = {
  [94579] = true,
  [94580] = true,
  [94585] = true,
  [94586] = true,
  [94591] = true,
  [94592] = true,
}
function private.isThunderArmament(itemlink,slot)
  if not addon.IsMoP52 then return end
  if not (slot == INVSLOT_MAINHAND or slot == INVSLOT_OFFHAND) then return end
  local _, itemLevel, itemID
  itemID = itemlink:match("Hitem:(%d+):")
  itemID = tonumber(itemID)
  if itemID then
    _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemID)
    if classID ~= Enum.ItemClass.Weapon then return end
    if thunder_armaments[itemID] then return 1 end
    _,_,_,itemLevel = C_Item.GetItemInfo(itemID)
    if itemLevel == 541 or itemLevel == 535 then
      thunder_armaments[itemID] = true
      return 1
    elseif itemLevel == 528 then
      local matches, linetext = ScanSlotTooltip(slot,L.TAG_THUNDERFORGED,true)
      if matches then
        thunder_armaments[itemID] = true
        return 1
      end
    elseif itemLevel == 522 then
      local stats = GetItemStats(itemlink)
      for statKey,v in pairs(stats) do
        if statKey:match("PVP_POWER") then
          return
        end
      end
      thunder_armaments[itemID] = true
      return 1
    elseif itemLevel == 502 then
      local matches, linetext = ScanSlotTooltip(slot,L.TAG_CELESTIAL,true)
      if matches or crafted_reborn[itemID] then
        thunder_armaments[itemID] = true
        return 1
      end
    end
  end
  return
end

local stats_temp_sockets = {}
local weapon_sha_sockets = {}
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
        if (slot == INVSLOT_MAINHAND or slot == INVSLOT_OFFHAND) then
          if statKey:match("_HYDRAULIC") then -- sha-touched
            if addon.IsMoP51 then
              extraSocket = 1
            end
            weapon_sha_sockets[slot] = tonumber(v) -- temp store
            if CharacterStatsPaneImprovedDB.dualShaTouched or (Accumulate(weapon_sha_sockets) < 2) then -- count it, max 1 unless user option to count all
              socketCount = socketCount + 1
            end
          else
            socketCount = socketCount + tonumber(v)
          end
        else
          socketCount = socketCount + tonumber(v)
        end
      end
    end
    if private.isThunderArmament(itemlink,slot) then
      extraSocket = 1
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
  if CharacterStatsPaneImprovedDBG.skipMeleeRange and (addon.CLASS == "WARRIOR" or addon.CLASS == "ROGUE") then
    return false
  end
  if (item) then
    local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID = GetItemInfoInstant(item)
    if classID == Enum.ItemClass.Weapon and (subclassID ~= Enum.ItemWeaponSubclass.Wand and subclassID ~= Enum.ItemWeaponSubclass.Thrown) then
      return true
    end
  end
  return false
end
local stats_upgrades_cache = {}
local UPGRADE_CAPTURE = _G.ITEM_UPGRADE_TOOLTIP_FORMAT and _G.ITEM_UPGRADE_TOOLTIP_FORMAT:gsub("%%d","(%%d+)") or ": (%d+)/(%d+)"
function private.countUpgrades(slot)
  local upgradeCount = 0
  stats_upgrades_cache[slot] = nil
  local item = GetInventoryItemID("player",slot)
  if item then
    -- this is necessary until they put C_Item.GetItemUpgradeInfo in Classic
    local matches, linetext = ScanSlotTooltip(slot,UPGRADE_CAPTURE)
    if matches then
      local current, total = unpack(matches)
      stats_upgrades_cache[slot] = tonumber(current)
      upgradeCount = upgradeCount + tonumber(total)
    end
  end
  return upgradeCount
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
if addon.IsMoP then
  enchantable[INVSLOT_HEAD] = nil
  enchantable[INVSLOT_RANGED] = nil
end
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
  [INVSLOT_MAINHAND] = "countSockets", -- prismatic (5.1+ legendary Q on sha-touched)
  [INVSLOT_OFFHAND] = "countSockets", -- prismatic (5.1+ legendary Q on sha-touched)
  [INVSLOT_RANGED] = "countSockets",
  [INVSLOT_WAIST] = "countSockets", -- belt buckle (everyone)
}
if addon.IsMoP then
  socketable[INVSLOT_RANGED] = nil
end
local upgradeable = addon.IsMoP51 and {
  [INVSLOT_HEAD] = "countUpgrades",
  [INVSLOT_NECK] = "countUpgrades",
  [INVSLOT_SHOULDER] = "countUpgrades",
  [INVSLOT_CHEST] = "countUpgrades",
  [INVSLOT_WAIST] = "countUpgrades",
  [INVSLOT_LEGS] = "countUpgrades",
  [INVSLOT_FEET] = "countUpgrades",
  [INVSLOT_WRIST] = "countUpgrades",
  [INVSLOT_HAND] = "countUpgrades",
  [INVSLOT_FINGER1] = "countUpgrades",
  [INVSLOT_FINGER2] = "countUpgrades",
  [INVSLOT_TRINKET1] = "countUpgrades",
  [INVSLOT_TRINKET2] = "countUpgrades",
  [INVSLOT_BACK] = "countUpgrades",
  [INVSLOT_MAINHAND] = "countUpgrades",
  [INVSLOT_OFFHAND] = "countUpgrades",
} or {}
local tinkers = {
  [INVSLOT_BACK] = "checkEngi", -- only engineers
  [INVSLOT_HAND] = "checkEngi", -- only engineers
  [INVSLOT_WAIST] = "checkEngi", -- only engineers
}
local tinker_spells = {
  [54735] = (GetSpellInfo(54735)),
  [54757] = (GetSpellInfo(54757)),
  [54758] = (GetSpellInfo(54758)),
  [55001] = (GetSpellInfo(55001)),
  [55004] = (GetSpellInfo(55004)),
  [67810] = (GetSpellInfo(67810)),
  [67890] = (GetSpellInfo(67890)),
  [82174] = (GetSpellInfo(82174)),
  [82176] = (GetSpellInfo(82176)),
  [82179] = (GetSpellInfo(82179)),
  [82184] = (GetSpellInfo(82184)),
  [82186] = (GetSpellInfo(82186)),
  [82387] = (GetSpellInfo(82387)),
  [82626] = (GetSpellInfo(82626)),
  [82820] = (GetSpellInfo(82820)),
  [94548] = (GetSpellInfo(94548)),
}
if addon.IsMoP then
  tinker_spells[67799] = (GetSpellInfo(67799))
  tinker_spells[84348] = (GetSpellInfo(84348))
  tinker_spells[108788] = (GetSpellInfo(108788))
  tinker_spells[109076] = (GetSpellInfo(109076))
  tinker_spells[126389] = (GetSpellInfo(126389))
  tinker_spells[126734] = (GetSpellInfo(126734))
  tinker_spells[131459] = (GetSpellInfo(131459))
  --tinker_spells[54735] = (GetSpellInfo(54735))
  --tinker_spells[54757] = (GetSpellInfo(54757))
  --tinker_spells[54758] = (GetSpellInfo(54758))
  --tinker_spells[55001] = (GetSpellInfo(55001))
  --tinker_spells[55004] = (GetSpellInfo(55004))
  --tinker_spells[67890] = (GetSpellInfo(67890))
  --tinker_spells[82387] = (GetSpellInfo(82387))
end
addon.enchant_list = { }
addon.socket_list = { }
addon.tinker_list = { }
addon.upgrade_list = { }
local function getGearCheckList()
  wipe(addon.enchant_list)
  wipe(addon.socket_list)
  wipe(addon.tinker_list)
  wipe(addon.upgrade_list)
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
  wipe(weapon_sha_sockets)
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
  for slot, check in pairs(upgradeable) do
    if (GetInventoryItemID("player", slot)) then
      if check == true then
        addon.upgrade_list[slot] = 1
      else
        if private[check](slot) then
          addon.upgrade_list[slot] = private[check](slot)
        end
      end
    end
  end
  return addon.enchant_list, addon.socket_list, addon.tinker_list, addon.upgrade_list
end

addon.gearcheck_data = { }
local function getGearCheck()
  wipe(addon.gearcheck_data)
  addon.enchant_list, addon.socket_list, addon.tinker_list, addon.upgrade_list = getGearCheckList()
  local availableEnchants = Accumulate(addon.enchant_list)
  local availableSockets = Accumulate(addon.socket_list)
  local availableTinkers = Accumulate(addon.tinker_list)
  local availableUpgrades = Accumulate(addon.upgrade_list)
  addon.gearcheck_data.total = availableEnchants + availableSockets + availableTinkers + availableUpgrades
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
  for slot, maxUpgrades in pairs(addon.upgrade_list) do
    local upgraded = stats_upgrades_cache[slot] or 0
    have = have + upgraded
    if upgraded < maxUpgrades then
      addon.gearcheck_data.missing = addon.gearcheck_data.missing or {}
      addon.gearcheck_data.missing[L["Upgrades"]] = addon.gearcheck_data.missing[L["Upgrades"]] or {}
      addon.gearcheck_data.missing[L["Upgrades"]][slot] = maxUpgrades-upgraded
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
    if addon.gearcheck_data.missing and addon.tCount(addon.gearcheck_data.missing)>0 then
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
if addon.IsCata then
  if addon.TANKTREE[addon.CLASS] then -- warrior/paladin
    addon.NEW_STATINFO["CTC"] = {
      updateFunc = function(statFrame, unit) PaperDollFrame_SetCTC(statFrame, unit) end
    }
  end
end
addon.NEW_STATINFO["GEARCHECK"] = {
  updateFunc = function(statFrame, unit) PaperDollFrame_SetGearCheck(statFrame, unit) end
}
addon.NEW_STATINFO["LUCK"] = {
  updateFunc = function(statFrame, unit) PaperDollFrame_SetLUCK(statFrame, unit) end
}
if addon.IsMoP then
  if addon.TANKTREE[addon.CLASS] then -- can parry and dodge
    addon.NEW_STATINFO["AVRT"] = {
      updateFunc = function(statFrame, unit) PaperDollFrame_SetAVRT(statFrame, unit) end
    }
  end
  if addon.MELEE[addon.CLASS] then
    addon.NEW_STATINFO["CRITCAP"] = {
      updateFunc = function(statFrame, unit) PaperDollFrame_SetCRITCAP(statFrame, unit) end
    }
  end
end

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

_G.CSPI_DEV = private -- debug help
