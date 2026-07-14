--- Основной скрипт запуска мода Three-Stage Missile System
--- Main startup script for Three-Stage Missile System mod

print("=" .. string.rep("=", 58) .. "=")
print("=" .. string.rep(" ", 58) .. "=")
print("=          THREE-STAGE MISSILE SYSTEM MOD v1.0.0           =")
print("=                       Hell-Low                            =")
print("=" .. string.rep(" ", 58) .. "=")
print("=" .. string.rep("=", 58) .. "=")

-- Загружаем ядро мода
local MissileSystem = require("scripts.missile")
local MissileIntegration = require("scripts.diy_missile_integration")

print("\n[MainMod] Инициализация модуля ракет...")

-- Создаём глобальный экземпляр системы ракет
local missileSystem = nil

-- Инициализируем мод при загрузке сцены боя
if ModeAPI then
    print("[MainMod] Регистрация обработчиков событий ModeAPI...")
    
    -- Вызывается когда мод полностью загружен
    local modeInstance = ModeAPI.GetModeInstance()
    if modeInstance then
        print("[MainMod] Экземпляр мода найден")
    end
end

-- Инициализируем мод при загрузке载具
if GameAPI then
    print("[MainMod] Регистрация обработчиков событий GameAPI...")
    
    GameAPI.RegisterVehicleLoadedEvent(function(vehicle)
        print("[MainMod]载具загружен: " .. vehicle:GetVehicleName())
        
        -- Инициализируем ракету для載具
        local integration = MissileIntegration.new()
        if integration:initializeMissileForVehicle(vehicle) then
            print("[MainMod] Ракета инициализирована для載具")
        end
    end)
end

-- Функция для запуска ракеты (вызывается из игры)
function LaunchMissile(vehicle, targetPos)
    print("[MainMod] Запрос на запуск ракеты")
    
    if not missileSystem then
        missileSystem = MissileSystem.new({x=0, y=0, z=0}, targetPos, 45)
    end
    
    if missileSystem then
        return missileSystem:update(TimeAPI.GetDeltaTime())
    end
    
    return false
end

-- Функция для получения статистики ракеты
function GetMissileStats()
    local integration = MissileIntegration.new()
    return integration:getStats()
end

-- Функция для получения информации о ракете
function GetMissileInfo()
    local integration = MissileIntegration.new()
    return integration:getInfo()
end

-- Делаем функции доступными глобально
_G.LaunchMissile = LaunchMissile
_G.GetMissileStats = GetMissileStats
_G.GetMissileInfo = GetMissileInfo

print("\n[MainMod] ✅ Three-Stage Missile System успешно загружен!")
print("[MainMod] Команды доступны:")
print("  - LaunchMissile(vehicle, targetPos)")
print("  - GetMissileStats()")
print("  - GetMissileInfo()")
print("\n[MainMod] Мод готов к использованию в DIY меню!\n")

return {
    name = "Three-Stage Missile System",
    version = "1.0.0",
    author = "Hell-Low",
    launchMissile = LaunchMissile,
    getMissileStats = GetMissileStats,
    getMissileInfo = GetMissileInfo,
}
