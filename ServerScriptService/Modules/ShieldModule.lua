-- 🛡️ ShieldModule.lua - Sistema unificado y sincronizado
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local Economy = require(script.Parent:WaitForChild("EconomyModule"))
local RebirthModule = require(script.Parent:WaitForChild("RebirthModule"))

-- CONFIGURACIÓN
local BASE_DURATION = 30    -- duración base del escudo (s)
local EXTEND_DURATION = 60  -- segundos extra por extensión
local BASE_COST = 1000      -- costo inicial de extensión
local COST_MULTIPLIER = 1.5 -- aumento de costo por compra
local COOLDOWN = 60         -- segundos de espera tras terminar

local activeShields = {}    -- [UserId] = { model, endTime, state, extCost, cdEnd }
local ShieldModule = {}


-----------------------------------------------------------
-- 🧱 COLISIONES
-----------------------------------------------------------
local function setupGroups()
    if not pcall(function() PhysicsService:RegisterCollisionGroup("Shield") end) then end
    if not pcall(function() PhysicsService:RegisterCollisionGroup("Owner") end) then end
    PhysicsService:CollisionGroupSetCollidable("Shield", "Owner", false)
    PhysicsService:CollisionGroupSetCollidable("Shield", "Default", true)
    PhysicsService:CollisionGroupSetCollidable("Shield", "Shield", true)
end
setupGroups()

local function setCollisionGroup(obj, group)
    for _, p in ipairs(obj:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CollisionGroup = group
        end
    end
end

-----------------------------------------------------------
-- 🟢 ACTIVAR ESCUDO
-----------------------------------------------------------
function ShieldModule.ActivateShield(player, baseModel)
    local uid = player.UserId
    local now = os.clock()

    local current = activeShields[uid]
    if current and current.state == "active" then
        return false, "Escudo ya activo."
    elseif current and current.state == "cooldown" then
        return false, "Espera cooldown."
    end

    -- Duración total = base + bonus por rebirth
    local rebirthBonus = RebirthModule.GetShieldBonus(player) or 0
    local duration = BASE_DURATION + rebirthBonus

    local template = ReplicatedStorage:WaitForChild("DomoEscudoPlantilla")
    local shield = template:Clone()
    shield.Name = player.Name .. "_Shield"
    shield.Parent = Workspace
    setCollisionGroup(shield, "Shield")

    -- Posición del domo centrado sobre la base
    if baseModel and baseModel.PrimaryPart then
        local offsetY = -19 -- ajusta según tu modelo
        shield:PivotTo(baseModel.PrimaryPart.CFrame * CFrame.new(0, offsetY, 0))
    end

    -- Asignar colisión "Owner" al personaje
    if player.Character then
        setCollisionGroup(player.Character, "Owner")
    end

    activeShields[uid] = {
        model = shield,
        endTime = now + duration,
        state = "active",
        extCost = BASE_COST
    }

    -- Hilo de control: duración + cooldown
    task.spawn(function()
        while activeShields[uid] and activeShields[uid].state == "active" do
            if os.clock() >= activeShields[uid].endTime then
                break
            end
            task.wait(0.2)
        end

        -- 🔴 Desactivar escudo
        if activeShields[uid] then
            if activeShields[uid].model then
                activeShields[uid].model:Destroy()
            end
            activeShields[uid].state = "cooldown"
            activeShields[uid].cdEnd = os.clock() + COOLDOWN
        end

        -- 🕒 Esperar cooldown
        while activeShields[uid] and activeShields[uid].state == "cooldown" do
            if os.clock() >= activeShields[uid].cdEnd then
                break
            end
            task.wait(0.2)
        end

        -- 🧹 Limpiar al final
        activeShields[uid] = nil
    end)

    return true, ("Escudo activado (%ds)"):format(duration)
end

-----------------------------------------------------------
-- 🔵 EXTENDER ESCUDO
-----------------------------------------------------------
function ShieldModule.ExtendShield(player)
    local uid = player.UserId
    local data = activeShields[uid]
    if not data or data.state ~= "active" then
        return false, "No hay escudo activo."
    end

    local cost = data.extCost or BASE_COST
    if not Economy.CanAfford(player, cost) then
        return false, "Fondos insuficientes ($" .. cost .. ")"
    end

    Economy.Charge(player, cost)
    data.endTime += EXTEND_DURATION
    data.extCost = math.floor(cost * COST_MULTIPLIER)
    return true, ("Tiempo +%ds (nuevo costo $%d)"):format(EXTEND_DURATION, data.extCost)
end

-----------------------------------------------------------
-- 🧠 GETTERS (estado, tiempo, costo)
-----------------------------------------------------------
function ShieldModule.GetState(player)
    local s = activeShields[player.UserId]
    return s and s.state or "none"
end

function ShieldModule.GetTimeLeft(player)
    local s = activeShields[player.UserId]
    if not s then return 0 end
    if s.state == "active" then
        return math.max(0, s.endTime - os.clock())
    elseif s.state == "cooldown" then
        return math.max(0, s.cdEnd - os.clock())
    end
    return 0
end

function ShieldModule.GetExtendInfo(player)
    local s = activeShields[player.UserId]
    local cost = s and s.extCost or BASE_COST
    return EXTEND_DURATION, cost
end

return ShieldModule
