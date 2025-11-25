-- ⚙️ UpgradeModule.lua
-- Lógica de compra, aplicación y persistencia de mejoras del jugador.

local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ServerScriptService.Modules.Config:WaitForChild("Upgrades"))
local Economy = require(ServerScriptService.Modules:WaitForChild("EconomyModule"))

local UpgradeModule = {}

---------------------------------------------------------------------
-- 🧠 asegurar estructura en el perfil
---------------------------------------------------------------------
local function ensureProfile(player)
    local profile = Economy._profiles[player.UserId]
    if not profile then
        Economy.InitializePlayer(player)
        profile = Economy._profiles[player.UserId]
    end

    profile.Upgrades = profile.Upgrades or {}
    profile.Rebirths = profile.Rebirths or 0
    return profile
end

---------------------------------------------------------------------
-- 💰 intenta comprar una mejora
---------------------------------------------------------------------
function UpgradeModule.TryUpgrade(player, upgradeId)
    local profile = ensureProfile(player)
    local def = Config.Defs[upgradeId]

    if not def then
        return false, "Mejora inexistente."
    end

    if not Config.IsUnlockedFor(profile, upgradeId) then
        return false, "Bloqueada. Requiere más rebirths."
    end

    local currentLevel = Config.GetLevel(profile, upgradeId)
    if currentLevel >= def.maxLevel then
        return false, "Ya alcanzaste el nivel máximo."
    end

    local nextLevel = currentLevel + 1
    local cost = Config.CalcCost(upgradeId, nextLevel)

    if not Economy.CanAfford(player, cost) then
        return false, "Fondos insuficientes."
    end

    -- 💸 Cobra y aplica mejora
    Economy.Charge(player, cost)
    profile.Upgrades[upgradeId] = nextLevel

    print(string.format("⚙️ %s subió %s a nivel %d (costo $%d)", player.Name, def.displayName, nextLevel, cost))

    -- aplicar efectos inmediatos si corresponde
    task.defer(function()
        UpgradeModule.ApplyEffects(player)
    end)

    return true, string.format("%s mejorado a nivel %d.", def.displayName, nextLevel)
end

---------------------------------------------------------------------
-- 🔢 obtener información visible de mejoras (para UI)
---------------------------------------------------------------------
function UpgradeModule.GetPlayerUpgradeData(player)
    local profile = ensureProfile(player)
    local upgrades = {}

    for id, def in pairs(Config.Defs) do
        local lvl = Config.GetLevel(profile, id)
        local nextCost = Config.CalcCost(id, lvl + 1)
        local unlocked = Config.IsUnlockedFor(profile, id)

        table.insert(upgrades, {
            id = id,
            name = def.displayName,
            desc = def.desc or "",
            level = lvl,
            max = def.maxLevel,
            cost = nextCost,
            unlocked = unlocked,
            category = def.category or "General",
        })
    end

    return upgrades
end

---------------------------------------------------------------------
-- 🧮 obtener el multiplicador o bonus actual de una stat
---------------------------------------------------------------------
function UpgradeModule.GetStat(player, key)
    local profile = Economy._profiles[player.UserId]
    if not (profile and profile.Upgrades) then return 0 end

    local total = 0
    local mult = 1

    for id, lvl in pairs(profile.Upgrades) do
        local def = Config.Defs[id]
        if def and def.effect and def.effect.key == key then
            local eff = def.effect
            if eff.type == "add" then
                total += lvl * (eff.perLevel or 0)
            elseif eff.type == "mult" then
                mult = 1 + lvl * (eff.perLevel or 0)
            elseif eff.type == "percent_add" then
                total += (eff.perLevel or 0) * lvl
            end
        end
    end

    return total, mult
end

---------------------------------------------------------------------
-- 💾 guardado y carga (integración con Economy)
---------------------------------------------------------------------
function UpgradeModule.LoadFromProfile(player)
    local profile = ensureProfile(player)
    return profile.Upgrades or {}
end

function UpgradeModule.SaveToProfile(player, upgradesTable)
    local profile = ensureProfile(player)
    profile.Upgrades = upgradesTable or {}
end

---------------------------------------------------------------------
-- 🧩 aplicar efectos inmediatos
---------------------------------------------------------------------
function UpgradeModule.ApplyEffects(player)
    local speedBonus = UpgradeModule.GetStat(player, "WalkSpeedBonus")
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local baseSpeed = 16
        local finalSpeed = baseSpeed * (1 + speedBonus)
        humanoid.WalkSpeed = math.clamp(finalSpeed, 16, 30)
    end
end

---------------------------------------------------------------------
-- 🧾 solicitud de datos (para el cliente HUD)
---------------------------------------------------------------------
function UpgradeModule.HandleRequest(player)
    local data = UpgradeModule.GetPlayerUpgradeData(player)
    return data
end

return UpgradeModule
