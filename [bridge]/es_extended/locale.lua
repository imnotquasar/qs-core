Locales = Locales or {}

function Translate(str, ...)
    local locale = (Config and Config.Locale) or 'en'
    if Locales[locale] and Locales[locale][str] then
        local ok, result = pcall(string.format, Locales[locale][str], ...)
        return ok and result or Locales[locale][str]
    elseif Locales['en'] and Locales['en'][str] then
        local ok, result = pcall(string.format, Locales['en'][str], ...)
        return ok and result or Locales['en'][str]
    end
    return ('Translation [%s][%s] does not exist'):format(locale, str)
end

function TranslateCap(str, ...)
    local s = Translate(str, ...)
    return (s:gsub('^%l', string.upper))
end

_ = Translate
_U = TranslateCap
