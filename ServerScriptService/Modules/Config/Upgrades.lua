-- ServerScriptService/Modules/Config/Upgrades.lua
-- Tabla de definición de mejoras (solo datos + helpers de costo/desbloqueo)
-- No hace cobros, no toca UI: eso se maneja en UpgradeModule

local Upgrades = {}

-- 🎛️ Definiciones de cada mejora
Upgrades.Defs = {
    -- Núcleo de progresión
    capacity = {
        id = "capacity",
        displayName = "Capacidad de Piñata",
        desc = "Permite sostener más dulces a la vez.",
        baseCost = 300,
        costMul = 1.25,
        maxLevel = 20,
        unlockRebirth = 0,
        category = "Core",
        effect = {
            key = "PinataCapacity",
            perLevel = 1,
            type = "add",
        },
    },

    candy_value = {
        id = "candy_value",
        displayName = "Valor de Dulces",
        desc = "Aumenta el dinero por segundo que generan tus dulces.",
        baseCost = 500,
        costMul = 1.30,
        maxLevel = 15,
        unlockRebirth = 0,
        category = "Core",
        effect = {
            key = "CandyValueMultiplier",
            perLevel = 0.10,
            type = "mult",
            maxMultiplier = 5.0,
        },
    },

    speed = {
        id = "speed",
        displayName = "Velocidad de Movimiento",
        desc = "Camina más rápido para explorar y robar mejor.",
        baseCost = 800,
        costMul = 1.35,
        maxLevel = 10,
        unlockRebirth = 1,
        category = "Player",
        effect = {
            key = "WalkSpeedBonus",
            perLevel = 0.05,
            type = "percent_add",
            clamp = { min = 16, max = 30 },
        },
    },

    shield_duration = {
        id = "shield_duration",
        displayName = "Duración del Escudo",
        desc = "Aumenta los segundos de tu escudo gratuito.",
        baseCost = 1000,
        costMul = 1.40,
        maxLevel = 10,
        unlockRebirth = 1,
        category = "Defense",
        effect = {
            key = "ShieldDurationBonus",
            perLevel = 5,
            type = "add_seconds",
            maxSeconds = 300,
        },
    },

    discount = {
        id = "discount",
        displayName = "Descuento en Tienda",
        desc = "Reduce el precio de los dulces al comprar.",
        baseCost = 1500,
        costMul = 1.40,
        maxLevel = 8,
        unlockRebirth = 2,
        category = "Economy",
        effect = {
            key = "ShopDiscount",
            perLevel = 0.05,
            type = "discount",
            maxDiscount = 0.50,
        },
    },

    aesthetics = {
        id = "aesthetics",
        displayName = "Decoración de Base",
        desc = "Desbloquea estilos y props para tu base.",
        baseCost = 2000,
        costMul = 1.50,
        maxLevel = 5,
        unlockRebirth = 0,
        category = "Cosmetic",
        effect = {
            key = "DecorTier",
            perLevel = 1,
            type = "tier",
        },
    },
}

---------------------------------------------------------------------
-- 🧮 Helper: costo del siguiente nivel
---------------------------------------------------------------------
function Upgrades.CalcCost(upgradeId, nextLevel)
    local def = Upgrades.Defs[upgradeId]
    if not def then return math.huge end
    nextLevel = math.max(1, nextLevel)
    local cost = def.baseCost * (def.costMul ^ (nextLevel - 1))
    return math.floor(cost + 0.5)
end

---------------------------------------------------------------------
-- 🔓 Helper: ¿desbloqueada para este perfil?
---------------------------------------------------------------------
function Upgrades.IsUnlockedFor(profile, upgradeId)
    local def = Upgrades.Defs[upgradeId]
    if not def then return false end
    local req = def.unlockRebirth or 0
    local rb = (profile and profile.Rebirths) or 0
    return rb >= req
end

---------------------------------------------------------------------
-- 🔢 Helper: nivel actual / si llegó al tope
---------------------------------------------------------------------
function Upgrades.GetLevel(profile, upgradeId)
    if not (profile and profile.Upgrades) then return 0 end
    return profile.Upgrades[upgradeId] or 0
end

function Upgrades.IsMaxed(profile, upgradeId)
    local def = Upgrades.Defs[upgradeId]
    if not def then return true end
    return Upgrades.GetLevel(profile, upgradeId) >= def.maxLevel
end

return Upgrades
