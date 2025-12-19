local addonName, addon = ...
local L = setmetatable({}, { __index = function(t, k)
  local v = tostring(k)
  rawset(t, k, v)
  return v
end })
addon.L = L

local LOCALE = (GAME_LOCALE or GetLocale())

L.STAT_CTC = "CTC"
L.STAT_LUCK = "Luck"
L.STAT_GEARCHECK = "Gear Checks"
L.STAT_CTC_DETAIL = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|tBoss CTC %s (%.2F%%)"
L.STAT_CTC_VERBOSE = "Combat Table Coverage"
L.STAT_CTC_DELTA = "CTC Delta"
L.STAT_CTC_CRITBLOCK = "|cff00ff00+%.2F%%|r |T236307:0|t"
L.STAT_AVOIDRATIO_LABEL = "Avoidance DR Penalty"
L.STAT_CRITCAP = "Crit Cap"
L.STAT_CRITCAP_VERBOSE = "Crit Chance Cap"
L.STAT_CRITCAP_REALCRIT = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|tReal Crit Chance %.2F%%"
L.STAT_CRITCAP_CRITDELTA = "Can add %.1F%% (|TInterface\\GROUPFRAME\\UI-GROUP-MAINTANKICON:0|t%.1F%%) Crit Chance"
L.STAT_CRITCAP_RAISEBY = "Hit/Exp can raise Crit Cap by %.2F%% (|TInterface\\GROUPFRAME\\UI-GROUP-MAINTANKICON:0|t%.1F%%)"
L.STAT_CRITCAP_RAISEBY_RB = "Raid Buffed Crit %.2F%% (|TInterface\\GROUPFRAME\\UI-GROUP-MAINTANKICON:0|t%.1F%%)"
L.STAT_AVOIDRATIO = "Ideal ".._G.PARRY
L.STAT_AVOIDRATIO_VERBOSE = _G.PARRY.." Goal: "
L.STAT_AVOIDRATIO_DETAIL = L.STAT_AVOIDRATIO_VERBOSE.."%.2F (%.2F%%)"
L.TAG_ELITE = "Elite"
L.TAG_CELESTIAL = "Celestial"
L.TAG_THUNDERFORGED = "Thunderforged"

if LOCALE == "deDE" then
  L.TAG_CELESTIAL = "Erhaben"
  L.TAG_THUNDERFORGED = "Donnergeschmiedet"
elseif LOCALE == "ruRU" then
  L.STAT_CTC = "CTC"
  L.STAT_LUCK = "Удача"
  L.STAT_GEARCHECK = "Проверки экипировки"
  L.STAT_CTC_DETAIL = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|tCTC босса %s (%.2F%%)"
  L.STAT_CTC_VERBOSE = "Покрытие таблицы боя"
  L.STAT_CTC_DELTA = "Дельта CTC"
  L.STAT_CTC_CRITBLOCK = "|cff00ff00+%.2F%%|r |T236307:0|t"
  L.STAT_AVOIDRATIO_LABEL = "Штраф DR уклонения"
  L.STAT_CRITCAP = "Капа крита"
  L.STAT_CRITCAP_VERBOSE = "Капа шанса крита"
  L.STAT_CRITCAP_REALCRIT = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|tРеальный шанс крита %.2F%%"
  L.STAT_CRITCAP_CRITDELTA = "Можно добавить %.1F%% (|TInterface\\GROUPFRAME\\UI-GROUP-MAINTANKICON:0|t%.1F%%) шанса крита"
  L.STAT_CRITCAP_RAISEBY = "Точн./Эксп. может поднять капу крита на %.2F%% (|TInterface\\GROUPFRAME\\UI-GROUP-MAINTANKICON:0|t%.1F%%)"
  L.STAT_CRITCAP_RAISEBY_RB = "Крит с рейд-баффами %.2F%% (|TInterface\\GROUPFRAME\\UI-GROUP-MAINTANKICON:0|t%.1F%%)"
  L.STAT_AVOIDRATIO = "Идеальное ".._G.PARRY
  L.STAT_AVOIDRATIO_VERBOSE = _G.PARRY.." Цель: "
  L.STAT_AVOIDRATIO_DETAIL = L.STAT_AVOIDRATIO_VERBOSE.."%.2F (%.2F%%)"
  L.TAG_ELITE = "Элита"
  L.TAG_CELESTIAL = "Небожители"
  L.TAG_THUNDERFORGED = "Создано в Кузне Грома"
elseif LOCALE == "frFR" then
  L.TAG_CELESTIAL = "Astral"
  L.TAG_THUNDERFORGED = "Forgé par le tonnerre"
elseif LOCALE == "koKR" then
  L.TAG_CELESTIAL = "천신"
  L.TAG_THUNDERFORGED = "천둥벼림"
elseif LOCALE == "zhTW" then
  L.TAG_CELESTIAL = "天尊"
  L.TAG_THUNDERFORGED = "雷霆鑄造"
elseif LOCALE == "zhCN" then
  L.TAG_CELESTIAL = "天神"
  L.TAG_THUNDERFORGED = "雷霆"
end
