-- 🪅 PinataManager.lua
-- Generación pasiva con delta-time, guardado y restauración completa.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local Economy = require(script.Parent:WaitForChild("EconomyModule"))
local PinataLevel = require(script.Parent:WaitForChild("PinataLevelModule"))
local RebirthModule = require(script.Parent:WaitForChild("RebirthModule"))

local PinataManager = {}

-- Registro de tiempos por jugador
local lastTickPerUser = {}

---------------------------------------------------------------------
-- 🧩 Asegurar estructura básica de la piñata
---------------------------------------------------------------------
local function ensurePinata(player)
    local base = BaseManager.GetBase(player)
    if not base then return nil end

    local boveda = base:FindFirstChild("PinataBoveda")
    if not boveda then return nil end

    local pinata = boveda:FindFirstChild("Pinata")
    if not pinata then return nil end

    -- 🔹 Dinero acumulado
    local acumulado = pinata:FindFirstChild("DineroAcumulado")
    if not acumulado then
        acumulado = Instance.new("NumberValue")
        acumulado.Name = "DineroAcumulado"
        acumulado.Value = 0
        acumulado.Parent = pinata
    end

    -- 🔹 Carpeta de dulces
    local candies = pinata:FindFirstChild("Candies")
    if not candies then
        candies = Instance.new("Folder")
        candies.Name = "Candies"
        candies.Parent = pinata
    end

    return pinata, acumulado, candies
end

---------------------------------------------------------------------
-- 🧠 Inicializar piñata al entrar el jugador
---------------------------------------------------------------------
function PinataManager.InicializarPinata(player)
    lastTickPerUser[player.UserId] = os.clock()
    local pinata, acumulado, candies = ensurePinata(player)
    if not pinata then
        warn("❌ No se pudo inicializar la piñata de " .. player.Name)
        return
    end

    -----------------------------------------------------------------
    -- 🍭 Restaurar dulces y acumulado desde Economy
    -----------------------------------------------------------------
    local savedCandies = Economy.GetCandies(player)
    local savedAccum = Economy.GetAccumulated(player)
    local savedLevel = Economy.GetPinataLevel(player)

    -- 🧮 Restaurar dulces con cantidad real
    if savedCandies and #savedCandies > 0 then
        for _, candyInfo in ipairs(savedCandies) do
            local dulce = candies:FindFirstChild(candyInfo.Nombre)
            if not dulce then
                dulce = Instance.new("Folder")
                dulce.Name = candyInfo.Nombre
                dulce:SetAttribute("Valor", candyInfo.Valor or 1)
                dulce:SetAttribute("Costo", candyInfo.Costo or 0)
                dulce:SetAttribute("Cantidad", candyInfo.Cantidad or 1)
                dulce.Parent = candies
            else
                -- si ya existía, actualiza la cantidad guardada
                dulce:SetAttribute("Cantidad", candyInfo.Cantidad or 1)
            end
        end
        print(("🍭 Dulces restaurados para %s: %d"):format(player.Name, #savedCandies))
    else
        print(("🍭 Ningún dulce previo para %s (nuevo jugador o sin compras)"):format(player.Name))
    end

    -- 💰 Restaurar dinero acumulado
    acumulado.Value = savedAccum or 0

    -- 🎨 Restaurar nivel de piñata
    if savedLevel and savedLevel > 0 then
        PinataLevel.SetLevel(player, savedLevel)
    end

    -- 🎨 Aplicar apariencia según nivel actual
    PinataLevel.SafeApply(player)
end

---------------------------------------------------------------------
-- 💰 Generación pasiva de dinero (loop continuo)
---------------------------------------------------------------------
task.spawn(function()
    while true do
        local now = os.clock()

        for _, plr in ipairs(Players:GetPlayers()) do
            local pinata, acumulado, candies = ensurePinata(plr)
            if pinata and acumulado and candies then
                local last = lastTickPerUser[plr.UserId] or now
                local dt = now - last
                lastTickPerUser[plr.UserId] = now

                if dt > 0 then
                    -- 🧮 Ganancia base
                    local perSec = 0
                    for _, dulce in ipairs(candies:GetChildren()) do
                        local cantidad = dulce:GetAttribute("Cantidad") or 1
                        local valor = dulce:GetAttribute("Valor") or 0
                        perSec += valor * cantidad
                    end

                    -- 🔹 Multiplicadores combinados (nivel + rebirth)
                    local multLevel = PinataLevel.GetMoneyMultiplier(plr)
                    local multRebirth = RebirthModule and RebirthModule.GetBonusMultiplier(plr) or 1
                    local totalMult = multLevel * multRebirth

                    if perSec > 0 then
                        local deltaGain = (perSec * totalMult) * dt
                        acumulado.Value += deltaGain
                        Economy.SaveAccumulated(plr, acumulado.Value)
                    end
                end
            end
        end

        task.wait(0.25)
    end
end)

---------------------------------------------------------------------
-- 🟢 Obtener dinero acumulado actual
---------------------------------------------------------------------
function PinataManager.GetAccumulated(player)
    local base = BaseManager.GetBase(player)
    if not base then return 0 end

    local pinata = base:FindFirstChild("PinataBoveda") and base.PinataBoveda:FindFirstChild("Pinata")
    if not pinata then return 0 end

    local acumulado = pinata:FindFirstChild("DineroAcumulado")
    return acumulado and acumulado.Value or 0
end

---------------------------------------------------------------------
-- 🔴 Guardar acumulado o nivel manualmente
---------------------------------------------------------------------
function PinataManager.SetAccumulated(player, value)
    local base = BaseManager.GetBase(player)
    if not base then return end

    local pinata = base:FindFirstChild("PinataBoveda") and base.PinataBoveda:FindFirstChild("Pinata")
    if not pinata then return end

    local acumulado = pinata:FindFirstChild("DineroAcumulado")
    if not acumulado then
        acumulado = Instance.new("NumberValue")
        acumulado.Name = "DineroAcumulado"
        acumulado.Value = 0
        acumulado.Parent = pinata
    end

    acumulado.Value = value or 0
    Economy.SaveAccumulated(player, acumulado.Value)
end

function PinataManager.SavePinataLevel(player, level)
    Economy.SavePinataLevel(player, level)
end

return PinataManager
