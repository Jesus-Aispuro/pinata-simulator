-- Config/PinataLevels.lua
-- Definición de 10 niveles de piñata + helpers

local PinataLevels = {}

-- Cada nivel: costo para subir a ese nivel, capacidad (slots) y multiplicador de dinero
-- Nota: level 1 es el inicial.
PinataLevels.Levels = {
    [1]  = { name = "Cartón", cost = 0, capacity = 10, moneyMult = 1.00, visual = { Material = Enum.Material.Wood, Color = Color3.fromRGB(209, 173, 123) } },
    [2]  = { name = "Madera", cost = 500, capacity = 20, moneyMult = 1.10, visual = { Material = Enum.Material.Wood, Color = Color3.fromRGB(160, 110, 70) } },
    [3]  = { name = "Cobre", cost = 1_500, capacity = 30, moneyMult = 1.25, visual = { Material = Enum.Material.Metal, Color = Color3.fromRGB(170, 110, 60) } },
    [4]  = { name = "Bronce", cost = 4_000, capacity = 45, moneyMult = 1.40, visual = { Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 90, 50) } },
    [5]  = { name = "Plata", cost = 10_000, capacity = 60, moneyMult = 1.60, visual = { Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 200, 210) } },
    [6]  = { name = "Oro", cost = 30_000, capacity = 80, moneyMult = 1.85, visual = { Material = Enum.Material.Metal, Color = Color3.fromRGB(240, 210, 80) } },
    [7]  = { name = "Cristal", cost = 90_000, capacity = 105, moneyMult = 2.15, visual = { Material = Enum.Material.Glass, Color = Color3.fromRGB(170, 230, 255) } },
    [8]  = { name = "Diamante", cost = 270_000, capacity = 135, moneyMult = 2.50, visual = { Material = Enum.Material.Neon, Color = Color3.fromRGB(130, 220, 255) } },
    [9]  = { name = "Mítica", cost = 800_000, capacity = 170, moneyMult = 2.95, visual = { Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 120, 220) } },
    [10] = { name = "Épica", cost = 2_000_000, capacity = 210, moneyMult = 3.50, visual = { Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 255, 255) } },
}

function PinataLevels.GetMaxLevel()
    return 10
end

function PinataLevels.GetDef(level)
    return PinataLevels.Levels[level]
end

return PinataLevels
