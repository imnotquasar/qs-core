-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from QBCore (https://github.com/qbcore-framework/qb-core)
-- Copyright (C) QBCore Framework and contributors
-- Modified for qscore in 2026: adapted to run on top of qs-core. See NOTICE.

local function interpolate(str, subs)
    if not subs then return str end
    return (str:gsub('%%{(.-)}', function(key)
        local sub = subs[key]
        return sub ~= nil and tostring(sub) or ('%%{' .. key .. '}')
    end))
end

Locale = {}
Locale.__index = Locale

function Locale.new(_, opts)
    local self = setmetatable({}, Locale)
    opts = opts or {}
    self.fallback = opts.fallbackLang
    self.warnOnMissing = opts.warnOnMissing ~= false
    self.phrases = {}
    self:extend(opts.phrases or {})
    return self
end

setmetatable(Locale, { __call = Locale.new })

function Locale:extend(phrases, prefix)
    for key, phrase in pairs(phrases) do
        local prefixedKey = prefix and (prefix .. '.' .. key) or key
        if type(phrase) == 'table' then
            self:extend(phrase, prefixedKey)
        else
            self.phrases[prefixedKey] = phrase
        end
    end
end

function Locale:t(key, subs)
    local phrase = self.phrases[key]
    if not phrase then
        if self.fallback and self.fallback ~= self then
            return self.fallback:t(key, subs)
        end
        if self.warnOnMissing then
            print(('^3[qb-core bridge]^7 missing translation: %s'):format(key))
        end
        return key
    end
    return interpolate(phrase, subs)
end

function Locale:has(key)
    return self.phrases[key] ~= nil
end

function Locale:delete(phraseTarget)
    if type(phraseTarget) == 'string' then
        self.phrases[phraseTarget] = nil
    else
        for key in pairs(phraseTarget or {}) do
            self.phrases[key] = nil
        end
    end
end

function Locale:clear()
    self.phrases = {}
end

function Locale:replace(phrases)
    self:clear()
    self:extend(phrases or {})
end

function Locale:locale(newLocale)
    if newLocale then self.currentLocale = newLocale end
    return self.currentLocale
end
