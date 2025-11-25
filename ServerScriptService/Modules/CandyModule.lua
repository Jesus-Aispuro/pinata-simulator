-- 🍬 CandyModule.lua
-- Administra la compra, registro y guardado de dulces con cantidad.

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Economy = require(ServerScriptService.Modules:WaitForChild("EconomyModule"))
local BaseManager = require(ServerScriptService.Modules:WaitForChild("BaseManager"))

local CandyModule = {}

---------------------------------------------------------------------
-- 🧩 Obtiene o crea los contenedores necesarios dentro de la piñata
---------------------------------------------------------------------
local function ensurePinataStructure(player)
    local base = BaseManager.GetBase(player)
    if not base then
        warn("⚠️ No se encontró base para " .. player.Name)
        return nil
    end

    local pinataBoveda = base:FindFirstChild("PinataBoveda")
    if not pinataBoveda then
        warn("⚠️ No se encontró PinataBoveda para " .. player.Name)
        return nil
    end

    local pinata = pinataBoveda:FindFirstChild("Pinata")
    if not pinata then
        warn("⚠️ No se encontró Pinata en la bóveda de " .. player.Name)
        return nil
    end

    -- 🔹 Crear DineroAcumulado si falta
    if not pinata:FindFirstChild("DineroAcumulado") then
        local dinero = Instance.new("NumberValue")
        dinero.Name = "DineroAcumulado"
        dinero.Value = 0
        dinero.Parent = pinata
    end

    -- 🔹 Crear carpeta Candies si falta
    if not pinata:FindFirstChild("Candies") then
        local candies = Instance.new("Folder")
        candies.Name = "Candies"
        candies.Parent = pinata
    end

    return pinata
end

---------------------------------------------------------------------
-- 🍭 Añade o actualiza un dulce en la piñata (con cantidad)
---------------------------------------------------------------------
function CandyModule.AddCandy(player, candyInfo)
    if not candyInfo or not candyInfo.Nombre then
        warn("⚠️ Información de dulce inválida.")
        return false, "Datos inválidos."
    end

    local pinata = ensurePinataStructure(player)
    if not pinata then
        return false, "No se pudo acceder a la piñata."
    end

    local candiesFolder = pinata:FindFirstChild("Candies")
    local costo = candyInfo.Costo or 0

    -- Validar dinero
    if not Economy.CanAfford(player, costo) then
        return false, "Fondos insuficientes."
    end

    -- Cobrar al jugador
    if not Economy.Charge(player, costo) then
        return false, "Error al realizar el pago."
    end

    -- Buscar si ya tiene ese dulce
    local existing = candiesFolder:FindFirstChild(candyInfo.Nombre)
    if existing then
        -- Si ya existe, sumar cantidad
        local currentQty = existing:GetAttribute("Cantidad") or 1
        existing:SetAttribute("Cantidad", currentQty + 1)
    else
        -- Crear nuevo dulce con cantidad inicial 1
        local dulce = Instance.new("Folder")
        dulce.Name = candyInfo.Nombre
        dulce:SetAttribute("Valor", candyInfo.Valor or 1)
        dulce:SetAttribute("Costo", candyInfo.Costo or 0)
        dulce:SetAttribute("Cantidad", 1)
        dulce.Parent = candiesFolder
    end

    -- Guardar en perfil
    Economy.SaveCandy(player, {
        Nombre = candyInfo.Nombre,
        Valor = candyInfo.Valor or 1,
        Costo = candyInfo.Costo or 0,
        Cantidad = (existing and (existing:GetAttribute("Cantidad") or 1)) or 1
    })

    print(("💸 %s compró un '%s' por $%d"):format(player.Name, candyInfo.Nombre, costo))
    return true, "Dulce agregado o actualizado correctamente."
end

---------------------------------------------------------------------
-- 🔍 Obtener lista actual de dulces del jugador
---------------------------------------------------------------------
function CandyModule.GetPlayerCandies(player)
    local pinata = ensurePinataStructure(player)
    if not pinata then return {} end

    local candies = {}
    local folder = pinata:FindFirstChild("Candies")
    if folder then
        for _, dulce in pairs(folder:GetChildren()) do
            table.insert(candies, {
                Nombre = dulce.Name,
                Valor = dulce:GetAttribute("Valor") or 0,
                Costo = dulce:GetAttribute("Costo") or 0,
                Cantidad = dulce:GetAttribute("Cantidad") or 1
            })
        end
    end

    return candies
end

---------------------------------------------------------------------
-- 🔻 Eliminar cantidad de un dulce (para drops o robo)
---------------------------------------------------------------------
function CandyModule.RemoveCandy(player, nombre, cantidad)
    local pinata = ensurePinataStructure(player)
    if not pinata then return false end

    local candiesFolder = pinata:FindFirstChild("Candies")
    local dulce = candiesFolder and candiesFolder:FindFirstChild(nombre)
    if not dulce then return false end

    local current = dulce:GetAttribute("Cantidad") or 1
    if current <= cantidad then
        dulce:Destroy()
    else
        dulce:SetAttribute("Cantidad", current - cantidad)
    end

    return true
end

return CandyModule
