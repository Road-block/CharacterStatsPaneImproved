local addonName, addon = ...

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