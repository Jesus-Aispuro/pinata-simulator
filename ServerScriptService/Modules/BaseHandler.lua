-- 📦 BaseHandler.lua
-- Este módulo se encarga de ASIGNAR una base al jugador cuando entra al juego.
-- Clona la plantilla "BasePinata" y la coloca donde estaba una base vacía en el mapa.

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))

local BaseHandler = {}

-- 📁 Carpeta que contiene las bases del mapa (Base1, Base2, ..., Base8)
local BasesFolder = Workspace:WaitForChild("Bases")
local BasesDisponibles = BasesFolder:GetChildren()

-- 🛠 CORRECCIÓN: en Roblox, las propiedades son **Name**, no **name**
-- Ordenamos por nombre para que se asignen en orden (Base1 → Base2 → Base3)
table.sort(BasesDisponibles, function(a, b)
    return a.Name < b.Name
end)

-- 🧠 Tabla para llevar el control de las bases ocupadas
local BasesOcupadas = {}

-- =======================================================
-- 🔹 FUNCIÓN PRINCIPAL: Asignar una base libre al jugador
-- =======================================================
function BaseHandler.AsignarBase(player)
    -- 1️⃣ Buscar una base del mapa que no esté ocupada
    local baseLibre
    for _, base in ipairs(BasesDisponibles) do
        if not BasesOcupadas[base] then
            baseLibre = base
            break
        end
    end

    if not baseLibre then
        warn("⚠️ No hay bases libres para " .. player.Name)
        return
    end

    -- 2️⃣ Marcar la base como ocupada
    BasesOcupadas[baseLibre] = player

    -- 3️⃣ Clonar la plantilla BasePinata desde el ServerStorage
    local plantilla = ServerStorage:WaitForChild("BasePinata")
    local nuevaBase = plantilla:Clone()
    nuevaBase.Name = player.Name .. "_Base"
    nuevaBase.Parent = Workspace

    -- 🧠 Asignar el dueño a la base
    local duenoTag = Instance.new("ObjectValue")
    duenoTag.Name = "Dueno"
    duenoTag.Value = player
    duenoTag.Parent = nuevaBase



    -- 4️⃣ Alinear la base clonada a la posición de la base original
    if baseLibre.PrimaryPart then
        nuevaBase:SetPrimaryPartCFrame(baseLibre.PrimaryPart.CFrame)
    else
        warn("⚠️ La base " .. baseLibre.Name .. " no tiene PrimaryPart.")
    end

    -- 5️⃣ Eliminar la base del mapa
    baseLibre:Destroy()

    -- 6️⃣ Registrar esta base en el BaseManager
    BaseManager.RegisterBase(player, nuevaBase)

    print("✅ Base asignada a " .. player.Name .. " en posición de " .. baseLibre.Name)

    -- =======================================================
    -- 📍 TELETRANSPORTAR AL JUGADOR AL SPAWN DE SU BASE
    -- =======================================================
    local function teleportar(player, base)
        local spawnPart = base:WaitForChild("PlayerSpawn") -- Puede ser Part o SpawnLocation

        local function doTeleport(char)
            local hrp = char:WaitForChild("HumanoidRootPart")

            -- Si es un SpawnLocation, también lo asignamos como RespawnLocation
            if spawnPart:IsA("SpawnLocation") then
                player.RespawnLocation = spawnPart
            end

            -- Posiciona y orienta al jugador mirando hacia la base
            local lookAtPos = base.PrimaryPart and base.PrimaryPart.Position or base:GetModelCFrame().Position
            local spawnPos = spawnPart.Position + Vector3.new(0, 3, 0)
            hrp.CFrame = CFrame.lookAt(spawnPos, lookAtPos)
        end

        -- Si ya está cargado, teletransporta ahora
        if player.Character then
            doTeleport(player.Character)
        end

        -- Si respawnea, volver a moverlo
        player.CharacterAdded:Connect(doTeleport)
    end

    teleportar(player, nuevaBase)
end

-- =======================================================
-- 🔹 FUNCIÓN: Liberar la base cuando el jugador sale
-- =======================================================
function BaseHandler.RemoverBase(player)
    local base = BaseManager.GetBase(player)
    if base then
        base:Destroy()
        BaseManager.UnregisterBase(player)
    end

    -- Quitar la marca de ocupada
    for spawn, owner in pairs(BasesOcupadas) do
        if owner == player then
            BasesOcupadas[spawn] = nil
        end
    end

    print("🧹 Base liberada de " .. player.Name)
end

return BaseHandler
