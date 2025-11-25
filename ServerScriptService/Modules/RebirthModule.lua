-- 🔁 RebirthModule.lua
-- Controla los reinicios (rebirths) y sus recompensas permanentes

local ServerScriptService = game:GetService("ServerScriptService")
local Economy = require(ServerScriptService.Modules:WaitForChild("EconomyModule"))
local PinataLevel = require(ServerScriptService.Modules:WaitForChild("PinataLevelModule"))

local RebirthModule = {}
RebirthModule.Defs = {
    -- Definición de los 10 rebirths
    [1] = { cost = 10000, requiredLevel = 10, bonusMult = 1.2, speedBonus = 0.05, shieldBonus = 5 },
    [2] = { cost = 25000, requiredLevel = 10, bonusMult = 1.4, speedBonus = 0.07, shieldBonus = 7 },
    [3] = { cost = 60000, requiredLevel = 10, bonusMult = 1.6, speedBonus = 0.09, shieldBonus = 10 },
    [4] = { cost = 150000, requiredLevel = 10, bonusMult = 1.9, speedBonus = 0.1, shieldBonus = 12 },
    [5] = { cost = 350000, requiredLevel = 10, bonusMult = 2.3, speedBonus = 0.12, shieldBonus = 15 },
    [6] = { cost = 750000, requiredLevel = 10, bonusMult = 2.7, speedBonus = 0.13, shieldBonus = 18 },
    [7] = { cost = 1500000, requiredLevel = 10, bonusMult = 3.2, speedBonus = 0.15, shieldBonus = 22 },
    [8] = { cost = 3500000, requiredLevel = 10, bonusMult = 3.8, speedBonus = 0.17, shieldBonus = 25 },
    [9] = { cost = 8000000, requiredLevel = 10, bonusMult = 4.5, speedBonus = 0.18, shieldBonus = 30 },
    [10] = { cost = 20000000, requiredLevel = 10, bonusMult = 5.0, speedBonus = 0.2, shieldBonus = 35 },
}

-- 🧠 Asegura perfil en memoria
local function ensureProfile(player)
    local profile = Economy._profiles[player.UserId]
    if not profile then
        Economy.InitializePlayer(player)
        profile = Economy._profiles[player.UserId]
    end
    profile.Rebirths = profile.Rebirths or 0
    return profile
end

---------------------------------------------------------------------
-- 🔹 Obtener información del próximo rebirth
---------------------------------------------------------------------
function RebirthModule.GetNextCost(player)
    local profile = ensureProfile(player)
    local nextRebirth = (profile.Rebirths or 0) + 1
    local def = RebirthModule.Defs[nextRebirth]
    return def and def.cost or math.huge
end

function RebirthModule.GetNextRequirement(player)
    local profile = ensureProfile(player)
    local nextRebirth = (profile.Rebirths or 0) + 1
    local def = RebirthModule.Defs[nextRebirth]
    return def and def.requiredLevel or math.huge
end

---------------------------------------------------------------------
-- 🔁 Intentar hacer Rebirth
---------------------------------------------------------------------
function RebirthModule.TryRebirth(player)
    local profile = ensureProfile(player)
    local rebirth = (profile.Rebirths or 0) + 1
    local def = RebirthModule.Defs[rebirth]

    if not def then
        return false, "Has alcanzado el máximo Rebirth disponible."
    end

    local currentMoney = Economy.GetBalance(player)
    local currentLevel = PinataLevel.GetLevel(player)

    if currentLevel < def.requiredLevel then
        return false, "Tu piñata necesita ser nivel " .. def.requiredLevel .. "."
    end
    if currentMoney < def.cost then
        return false, "Necesitas $" .. def.cost .. " para hacer Rebirth."
    end

    -- Cobrar y reiniciar
    Economy.Charge(player, def.cost)
    Economy.SetBalance(player, 0)
    profile.Rebirths = rebirth
    profile.Candies = {}
    profile.Accumulated = 0
    PinataLevel.SetLevel(player, 1)

    print(("🔥 %s hizo Rebirth #%d"):format(player.Name, rebirth))
    return true, "¡Rebirth #" .. rebirth .. " completado!"
end

---------------------------------------------------------------------
-- 📊 Obtener multiplicadores
---------------------------------------------------------------------
function RebirthModule.GetBonusMultiplier(player)
    local profile = ensureProfile(player)
    local rebirth = profile.Rebirths or 0
    local mult = 1
    for i = 1, rebirth do
        local def = RebirthModule.Defs[i]
        if def then
            mult *= def.bonusMult
        end
    end
    return mult
end

function RebirthModule.GetSpeedBonus(player)
    local profile = ensureProfile(player)
    local rebirth = profile.Rebirths or 0
    local total = 0
    for i = 1, rebirth do
        local def = RebirthModule.Defs[i]
        if def then
            total += def.speedBonus or 0
        end
    end
    return total
end

function RebirthModule.GetShieldBonus(player)
    local profile = ensureProfile(player)
    local rebirth = profile.Rebirths or 0
    local total = 0
    for i = 1, rebirth do
        local def = RebirthModule.Defs[i]
        if def then
            total += def.shieldBonus or 0
        end
    end
    return total
end

return RebirthModule
