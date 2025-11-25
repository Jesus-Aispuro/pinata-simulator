-- 📦 EconomyModule.lua
-- Maneja economía, guardado y restauración de dulces, nivel de piñata y dinero acumulado.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local playerStore = DataStoreService:GetDataStore("PlayerEconomy_v3")

local Economy = {}
_G.PlayerEconomy = _G.PlayerEconomy or {}
Economy._profiles = _G.PlayerEconomy

---------------------------------------------------------------------
-- 🧱 Crea o asegura leaderstats visibles
---------------------------------------------------------------------
local function ensureLeaderstats(player)
    local ls = player:FindFirstChild("leaderstats")
    if not ls then
        ls = Instance.new("Folder")
        ls.Name = "leaderstats"
        ls.Parent = player
    end

    local dinero = ls:FindFirstChild("Dinero")
    if not dinero then
        dinero = Instance.new("IntValue")
        dinero.Name = "Dinero"
        dinero.Value = 0
        dinero.Parent = ls
    end

    return dinero
end

---------------------------------------------------------------------
-- 🟢 Inicializar jugador (cargar datos)
---------------------------------------------------------------------
function Economy.InitializePlayer(player)
    local key = "user_" .. player.UserId
    local data
    local isNew = false

    local success, err = pcall(function()
        data = playerStore:GetAsync(key)
    end)

    if not success then
        warn("❌ Error cargando datos de " .. player.Name .. ": " .. err)
    end

    if not data then
        -- Jugador nuevo
        data = {
            Balance = 0,
            Candies = {},
            Accumulated = 0,
            PinataLevel = 0
        }
        isNew = true
    end

    -- Guardar en memoria
    Economy._profiles[player.UserId] = {
        Balance = tonumber(data.Balance) or 0,
        Candies = data.Candies or {},
        Accumulated = tonumber(data.Accumulated) or 0,
        PinataLevel = tonumber(data.PinataLevel) or 0
    }

    -- Actualizar leaderstats
    local dineroValue = ensureLeaderstats(player)
    dineroValue.Value = Economy._profiles[player.UserId].Balance

    print("💾 Datos cargados para:", player.Name)
    return isNew
end

---------------------------------------------------------------------
-- 🔴 Guardar datos al salir
---------------------------------------------------------------------
function Economy.RemovePlayer(player)
    local profile = Economy._profiles[player.UserId]
    if not profile then return end

    local key = "user_" .. player.UserId
    local success, err = pcall(function()
        playerStore:SetAsync(key, {
            Balance = profile.Balance,
            Candies = profile.Candies,
            Accumulated = profile.Accumulated or 0,
            PinataLevel = profile.PinataLevel or 0
        })
    end)

    if success then
        print("✅ Datos guardados correctamente para", player.Name)
    else
        warn("❌ Error al guardar datos de " .. player.Name .. ": " .. err)
    end

    Economy._profiles[player.UserId] = nil
end

---------------------------------------------------------------------
-- 💵 Funciones de economía
---------------------------------------------------------------------
function Economy.GetBalance(player)
    local p = Economy._profiles[player.UserId]
    return p and p.Balance or 0
end

function Economy.SetBalance(player, amount)
    amount = math.max(0, math.floor(amount))
    local p = Economy._profiles[player.UserId]
    if not p then return end

    p.Balance = amount
    local ls = player:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("Dinero") then
        ls.Dinero.Value = amount
    end
end

function Economy.AddMoney(player, amount)
    if not amount or amount == 0 then return end
    Economy.SetBalance(player, Economy.GetBalance(player) + amount)
end

function Economy.CanAfford(player, cost)
    return Economy.GetBalance(player) >= (tonumber(cost) or 0)
end

function Economy.Charge(player, cost)
    cost = math.floor(tonumber(cost) or 0)
    if cost <= 0 then return true end
    if not Economy.CanAfford(player, cost) then return false end
    Economy.SetBalance(player, Economy.GetBalance(player) - cost)
    return true
end

---------------------------------------------------------------------
-- 🍬 Guardar y restaurar dulces (con cantidad)
---------------------------------------------------------------------
function Economy.SaveCandy(player, candyInfo)
    local profile = Economy._profiles[player.UserId]
    if not profile then return end

    profile.Candies = profile.Candies or {}

    -- Buscar dulce existente
    local found = false
    for _, candy in ipairs(profile.Candies) do
        if candy.Nombre == candyInfo.Nombre then
            candy.Cantidad = (candy.Cantidad or 1) + 1
            found = true
            break
        end
    end

    -- Si no existe, agregar nuevo
    if not found then
        table.insert(profile.Candies, {
            Nombre = candyInfo.Nombre,
            Valor = candyInfo.Valor or 1,
            Costo = candyInfo.Costo or 0,
            Cantidad = candyInfo.Cantidad or 1
        })
    end
end

function Economy.GetCandies(player)
    local profile = Economy._profiles[player.UserId]
    return profile and profile.Candies or {}
end

---------------------------------------------------------------------
-- 💾 Guardar dinero acumulado y nivel de piñata
---------------------------------------------------------------------
function Economy.SaveAccumulated(player, value)
    local profile = Economy._profiles[player.UserId]
    if not profile then return end
    profile.Accumulated = value or 0
end

function Economy.GetAccumulated(player)
    local profile = Economy._profiles[player.UserId]
    return profile and profile.Accumulated or 0
end

function Economy.SavePinataLevel(player, level)
    local profile = Economy._profiles[player.UserId]
    if not profile then return end
    profile.PinataLevel = level or 1
end

function Economy.GetPinataLevel(player)
    local profile = Economy._profiles[player.UserId]
    return profile and profile.PinataLevel or 1
end

---------------------------------------------------------------------
-- 🔄 Auto-guardado periódico
---------------------------------------------------------------------
task.spawn(function()
    while true do
        for _, player in ipairs(Players:GetPlayers()) do
            local profile = Economy._profiles[player.UserId]
            if profile then
                local key = "user_" .. player.UserId
                pcall(function()
                    playerStore:SetAsync(key, {
                        Balance = profile.Balance,
                        Candies = profile.Candies,
                        Accumulated = profile.Accumulated or 0,
                        PinataLevel = profile.PinataLevel or 0
                    })
                end)
            end
        end
        task.wait(60)
    end
end)

---------------------------------------------------------------------
return Economy
