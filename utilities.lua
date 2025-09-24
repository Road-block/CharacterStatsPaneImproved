local addonName, addon = ...
local wowver,wowbuild,wowbuilddate,wowtoc = GetBuildInfo()

addon.IsMoP = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
addon.IsCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
addon.IsMoPre = addon.IsMoP and (GetMaxPlayerLevel() < 90)
addon.IsMoP51 = addon.IsMoP and tonumber(wowtoc) >= 50501

function addon.tCount(tbl)
  local count = 0
  for k,v in pairs(tbl) do
    count = count + 1
  end
  return count
end

function addon.wrapTuple(...)
  return {...}
end
