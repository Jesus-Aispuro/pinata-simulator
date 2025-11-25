-- 📜 MainServer.lua
-- Coordina la entrada y salida de los jugadores, asigna bases,
-- inicializa economía y prepara la piñata correctamente en orden.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService:WaitForChild("Modules")

-- Requerimos los módulos principales
local BaseHandler = require(Modules:WaitForChild("BaseHandler"))
local Economy = require(Modules:WaitForChild("EconomyModule"))
local PinataManager = require(Modules:WaitForChild("PinataManager"))

---------------------------------------------------------------------
-- 🧍‍♂️ CUANDO UN JUGADOR ENTRA AL JUEGO
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    -- 1️⃣ Inicializa su economía y detecta si es nuevo
    local isNew = Economy.InitializePlayer(player)

    -- 2️⃣ Asigna su base
    BaseHandler.AsignarBase(player)

    -- 3️⃣ Espera breve para que la base termine de clonarse
    task.wait(1)

    PinataManager.InicializarPinata(player)
    PinataManager.SetAccumulated(player, Economy._profiles[player.UserId].Accumulated or 0)
    print("✅ Piñata restaurada con $" .. (Economy._profiles[player.UserId].Accumulated or 0))


    -- 4️⃣ Inicializa la piñata dentro de su base (antes que botones o dulces)
    local success, err = pcall(function()
        PinataManager.InicializarPinata(player)
    end)
    if not success then
        warn("❌ Error al inicializar piñata para " .. player.Name .. ": " .. tostring(err))
    else
        print("✅ Piñata lista para " .. player.Name)
    end

    -- 5️⃣ Solo dar dinero inicial si es un jugador nuevo
    if isNew then
        Economy.AddMoney(player, 500)
        print("💰 Dinero inicial otorgado a nuevo jugador: " .. player.Name)
    end
end)

---------------------------------------------------------------------
-- 🚪 CUANDO UN JUGADOR SE VA
---------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    local acumulado = PinataManager.GetAccumulated(player)
    local profile = Economy._profiles[player.UserId]
    if profile then
        profile.Accumulated = acumulado
    end

    Economy.RemovePlayer(player)
    BaseHandler.RemoverBase(player)
end)
