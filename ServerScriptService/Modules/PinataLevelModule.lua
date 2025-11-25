-- PinataLevelModule.lua
-- Lleva el nivel actual del jugador, valida mejoras, aplica visuales y expone stats

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ServerScriptService.Modules:WaitForChild("EconomyModule"))
local BaseManager = require(ServerScriptService.Modules:WaitForChild("BaseManager"))
local PinataLevels = require(ServerScriptService.Modules.Config:WaitForChild("PinataLevels"))

local PinataLevel = {}
PinataLevel.__index = PinataLevel

-- 🔐 obtiene/crea los campos en el perfil del Economy
local function ensureProfile(player)
    local profile = Economy._profiles[player.UserId]
    if not profile then
        Economy.InitializePlayer(player)
        profile = Economy._profiles[player.UserId]
    end
    profile.PinataLevel = profile.PinataLevel or 1
    return profile
end

-- 🎨 aplica material y color a la piñata visual con efecto glow + partículas
local TweenService = game:GetService("TweenService")

local function applyVisual(baseModel, def)
    if not baseModel then return end

    local pinataModel = baseModel:FindFirstChild("PinataBoveda")
    pinataModel = pinataModel and pinataModel:FindFirstChild("Pinata") or nil
    if not pinataModel then
        warn("⚠️ No se encontró la parte 'Pinata' en la base del jugador.")
        return
    end

    local parts = {}
    if pinataModel:IsA("BasePart") then
        table.insert(parts, pinataModel)
    else
        for _, p in ipairs(pinataModel:GetDescendants()) do
            if p:IsA("BasePart") then
                table.insert(parts, p)
            end
        end
    end

    for _, part in ipairs(parts) do
        -- 🔹 aplicar color y material
        part.Material = def.visual.Material
        part.Color = def.visual.Color

        -- 💫 efecto glow (emisión simulada con SurfaceAppearance)
        local glow = Instance.new("PointLight")
        glow.Color = def.visual.Color
        glow.Brightness = 2
        glow.Range = 10
        glow.Shadows = false
        glow.Parent = part

        -- ✨ partículas de brillo
        local emitter = Instance.new("ParticleEmitter")
        emitter.Texture = "rbxassetid://2418766425" -- Partícula circular brillante
        emitter.Color = ColorSequence.new(def.visual.Color)
        emitter.LightEmission = 1
        emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
        emitter.Lifetime = NumberRange.new(0.4)
        emitter.Rate = 100
        emitter.Speed = NumberRange.new(2, 5)
        emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
        emitter.Parent = part

        -- 🌀 efecto de pulso en transparencia
        local tweenIn = TweenService:Create(part, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Transparency = 0.4 })
        local tweenOut = TweenService:Create(part, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Transparency = 0 })
        tweenIn:Play()
        tweenIn.Completed:Connect(function()
            tweenOut:Play()
        end)

        -- ⏳ eliminar el glow y partículas tras 1.5s
        task.delay(1.5, function()
            if glow then glow:Destroy() end
            if emitter then emitter:Destroy() end
        end)
    end

    print(("🎆 Piñata visual mejorada: %s (nivel %s)")
        :format(def.name, tostring(def.id)))
end



-- 📈 intenta subir de nivel (comprar)
function PinataLevel.TryUpgrade(player)
    local profile = ensureProfile(player)
    local current = profile.PinataLevel
    local maxLevel = PinataLevels.GetMaxLevel()
    if current >= maxLevel then
        return false, "Nivel máximo alcanzado."
    end

    local nextLevel = current + 1
    local def = PinataLevels.GetDef(nextLevel)
    if not def then
        return false, "Definición de nivel no encontrada."
    end

    if not Economy.CanAfford(player, def.cost) then
        return false, "Fondos insuficientes."
    end

    -- Pagar y subir
    Economy.Charge(player, def.cost)
    profile.PinataLevel = nextLevel

    -- Cambiar visuals
    local base = BaseManager.GetBase(player)
    applyVisual(base, def)

    return true, ("Piñata mejorada a %s (nivel %d)."):format(def.name, nextLevel)
end

-- 🔎 lectura de stats
function PinataLevel.GetLevel(player)
    local p = ensureProfile(player)
    return p.PinataLevel
end

function PinataLevel.GetCapacity(player)
    local lvl = PinataLevel.GetLevel(player)
    local def = PinataLevels.GetDef(lvl)
    return def and def.capacity or 10
end

function PinataLevel.GetMoneyMultiplier(player)
    local lvl = PinataLevel.GetLevel(player)
    local def = PinataLevels.GetDef(lvl)
    return def and def.moneyMult or 1.0
end

-- 🎨 aplicar visuals al entrar / respawnear
function PinataLevel.ApplyVisualsNow(player)
    local lvl = PinataLevel.GetLevel(player)
    local def = PinataLevels.GetDef(lvl)
    local base = BaseManager.GetBase(player)
    if def and base then
        applyVisual(base, def)
        return true
    end
    return false
end

-- 🧱 establece directamente el nivel de la piñata (usado al cargar datos)
function PinataLevel.SetLevel(player, level)
    local profile = Economy._profiles[player.UserId]
    if not profile then
        Economy.InitializePlayer(player)
        profile = Economy._profiles[player.UserId]
    end
    profile.PinataLevel = math.max(1, tonumber(level) or 1)
end

-- 🧩 Fallback visual seguro (previene nil cuando el def.visual no existe)
function PinataLevel.SafeApply(player)
    local success, err = pcall(function()
        PinataLevel.ApplyVisualsNow(player)
    end)
    if not success then
        warn("⚠️ Error visual en piñata de " .. player.Name .. ": " .. tostring(err))
    end
end

return PinataLevel
