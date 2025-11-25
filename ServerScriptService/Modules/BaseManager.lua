-- 📦 BaseManager.lua
-- Módulo encargado de administrar las bases asignadas a cada jugador.
-- No maneja partes físicas, solo guarda y gestiona la información de quién posee qué base.

local BaseManager = {}

-- 🧠 Tabla principal donde guardaremos las bases asignadas
-- Estructura: BaseManager.Bases[player.UserId] = referencia a la base
BaseManager.Bases = {}

-- =======================================================
-- 🔹 Registrar base
-- =======================================================
function BaseManager.RegisterBase(player, base)
    -- Guardamos la referencia en la tabla
    BaseManager.Bases[player.UserId] = base

    -- También puedes añadir aquí atributos si lo necesitas
    -- base:SetAttribute("Dueno", player.Name)

    print("📍 Base registrada para:", player.Name)
end

-- =======================================================
-- 🔹 Obtener base de un jugador
-- =======================================================
function BaseManager.GetBase(player)
    -- Retorna la base asignada al jugador (o nil si no tiene)
    return BaseManager.Bases[player.UserId]
end

-- =======================================================
-- 🔹 Eliminar base (cuando el jugador sale o se reinicia)
-- =======================================================
function BaseManager.UnregisterBase(player)
    -- Quita la referencia de la tabla
    BaseManager.Bases[player.UserId] = nil
    print("🧹 Base eliminada de:", player.Name)
end

-- =======================================================
-- 🔹 Obtener el dueño de una base (por ejemplo, si alguien entra a una base)
-- =======================================================
function BaseManager.GetOwner(base)
    for userId, playerBase in pairs(BaseManager.Bases) do
        if playerBase == base then
            -- Buscar jugador usando su UserId (por seguridad)
            local player = game.Players:GetPlayerByUserId(userId)
            return player
        end
    end
    return nil
end

-- =======================================================
-- 🔹 Comprobar si una base pertenece a un jugador
-- =======================================================
function BaseManager.IsOwner(player, base)
    return BaseManager.Bases[player.UserId] == base
end

return BaseManager
