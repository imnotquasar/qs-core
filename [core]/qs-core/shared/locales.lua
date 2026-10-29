function T(key, ...)
    local table = Locales[GetConvar('qs:locale', Config.Locale or 'en')] or Locales.en or {}
    local str = table[key] or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end
