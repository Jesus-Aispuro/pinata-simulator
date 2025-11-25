-- 🔁 RebirthHandler.lua
-- Conecta el cliente con el RebirthModule

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RebirthEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RebirthEvent")

local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService:WaitForChild("Modules")
local RebirthModule = require(Modules:WaitForChild("RebirthModule"))
local Economy = require(Modules:WaitForChild("EconomyModule"))


RebirthEvent.OnServerEvent:Connect(function(player, action)
    if action == "RequestData" then
        local profile = Economy._profiles[player.UserId]
        if not profile then return end
        local rebirth = profile.Rebirths or 0
        local def = RebirthModule.Defs[rebirth + 1]

        if def then
            RebirthEvent:FireClient(player, "UpdateUI", {
                currentRebirth = rebirth,
                cost = def.cost,
                requiredLevel = def.requiredLevel,
                bonusMult = def.bonusMult,
                speedBonus = def.speedBonus,
                shieldBonus = def.shieldBonus,
            })
        end
    elseif action == "DoRebirth" then
        local success, msg = RebirthModule.TryRebirth(player)
        RebirthEvent:FireClient(player, "Message", msg)
        if success then
            RebirthEvent:FireClient(player, "RequestData")
        end
    end
end)
