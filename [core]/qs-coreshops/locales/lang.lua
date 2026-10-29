Locales = Locales or {}

function T(key, ...)
    local t = Locales[GetConvar('qs:locale', 'en')] or Locales.en or {}
    local s = t[key] or key
    if select('#', ...) > 0 then return s:format(...) end
    return s
end
