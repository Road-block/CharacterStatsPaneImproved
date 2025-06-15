local addonName, addon = ...
local L = setmetatable({}, { __index = function(t, k)
  local v = tostring(k)
  rawset(t, k, v)
  return v
end })
addon.L = L

local LOCALE = GetLocale()

L.STAT_CTC = "CTC"
L.STAT_LUCK = "Luck"
L.STAT_GEARCHECK = "Gear Checks"
L.STAT_CTC_DETAIL = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|tBoss CTC %s (%.2F%%)"
L.STAT_CTC_VERBOSE = "Combat Table Coverage"
L.STAT_CTC_DELTA = "CTC Delta"
L.STAT_CTC_CRITBLOCK = "|cff00ff00+%.2F%%|r |T236307:0|t"
L.STAT_AVOIDRATIO_LABEL = "Avoidance DR Penalty"
L.STAT_AVOIDRATIO = "Ideal ".._G.PARRY
L.STAT_AVOIDRATIO_VERBOSE = _G.PARRY.." Goal: "
L.STAT_AVOIDRATIO_DETAIL = L.STAT_AVOIDRATIO_VERBOSE.."%.2F (%.2F%%)"
