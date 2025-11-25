-- 🧩 UpgradeHandler.lua
-- Conecta el sistema de mejoras (UpgradeModule) con los clientes mediante RemoteEvents.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = script.Parent:WaitForChild("Modules")
local UpgradeModule = require(Modules:WaitForChild("UpgradeModule"))
local Economy = require(Modules:WaitForChild("EconomyModule"))

-- Evento remoto
local eventsFolder = ReplicatedStorage:FindFirstChild("Events") or Instance.new("Folder", ReplicatedStorage)
eventsFolder.Name = "Events"
local UpgradeEvent = eventsFolder:FindFirstChild("UpgradeEvent") or Instance.new("RemoteEvent", eventsFolder)
UpgradeEvent.Name = "UpgradeEvent"

---------------------------------------------------------------------
-- 🧍 Inicializar mejoras al entrar
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    task.wait(2)
    UpgradeModule.LoadFromProfile(player)
end)

---------------------------------------------------------------------
-- 🚪 Guardar al salir
---------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    local data = UpgradeModule.LoadFromProfile(player)
    UpgradeModule.SaveToProfile(player, data)
end)

---------------------------------------------------------------------
-- ⚙️ Manejar solicitudes del cliente
---------------------------------------------------------------------
UpgradeEvent.OnServerEvent:Connect(function(player, action)
    -- El cliente puede mandar dos tipos de acción:
    -- "RequestData" → pide lista de mejoras
    -- o un ID de mejora → intenta mejorar

    if action == "RequestData" then
        local data = UpgradeModule.GetPlayerUpgradeData(player)
        UpgradeEvent:FireClient(player, true, "Datos de mejoras cargados.", data)
        return
    end

    -- Si no es RequestData, asumimos que es un intento de mejora
    local success, msg = UpgradeModule.TryUpgrade(player, action)
    local data = UpgradeModule.GetPlayerUpgradeData(player)
    UpgradeEvent:FireClient(player, success, msg, data)
end)

print("✅ UpgradeHandler cargado correctamente.")
