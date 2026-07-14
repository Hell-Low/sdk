--- DIY интеграция системы ракет для меню Panzer War
--- DIY Missile System Integration for Panzer War Menu

local MissileIntegration = class("MissileIntegration")

--- Параметры ракеты для DIY меню
MissileIntegration.MISSILE_CONFIG = {
    -- Идентификаторы
    id = "missile_three_stage",
    name = "Трёхстадийная ракета",
    displayName = "3-Stage Missile",
    description = "Улучшенная ракета с тремя стадиями полёта",
    
    -- Категория
    category = "weapon",
    type = "missile",
    
    -- Характеристики
    damage = 500,
    explosionRadius = 100,
    weight = 45,
    
    -- Статистика
    fireRate = 3.5,        -- выстрелов в секунду
    accuracy = 0.95,       -- точность 95%
    reload = 6.0,          -- сек
    
    -- Косметика
    icon = "missile_icon",
    color = {r = 1, g = 0.5, b = 0},  -- оранжевый
}

--- Инициализация интеграции
function MissileIntegration:ctor()
    print("[MissileIntegration] Инициализация системы ракет DIY...")
    self:registerMissileInDIY()
    self:registerMissileEvents()
end

--- Регистрация ракеты в DIY системе
function MissileIntegration:registerMissileInDIY()
    local config = MissileIntegration.MISSILE_CONFIG
    
    print("[MissileIntegration] Регистрация ракеты: " .. config.name)
    
    -- Попытка добавить в DIY менеджер если доступен
    if UserDIYDataManager then
        print("[MissileIntegration] UserDIYDataManager найден")
    end
    
    if DIYDataManager then
        print("[MissileIntegration] DIYDataManager найден")
        -- Здесь будет код регистрации в игровой системе
    end
    
    -- Создаём объект конфигурации
    self.diyConfig = {
        guid = CSharpAPI.GetGUID(),
        name = config.name,
        type = config.type,
        category = config.category,
        damage = config.damage,
        explosionRadius = config.explosionRadius,
    }
    
    print(string.format("[MissileIntegration] Ракета зарегистрирована с GUID: %s", self.diyConfig.guid))
end

--- Регистрация обработчиков событий
function MissileIntegration:registerMissileEvents()
    print("[MissileIntegration] Регистрация обработчиков событий...")
    
    -- Событие установки ракеты на载具
    if CSharpAPI.OnEquipInstallClicked then
        CSharpAPI.OnEquipInstallClicked:AddListener(function()
            self:onMissileInstalled()
        end)
        print("[MissileIntegration] Обработчик установки зарегистрирован")
    end
    
    -- Событие снятия ракеты с載具
    if CSharpAPI.OnEquipUninstallClicked then
        CSharpAPI.OnEquipUninstallClicked:AddListener(function()
            self:onMissileUninstalled()
        end)
        print("[MissileIntegration] Обработчик снятия зарегистрирован")
    end
end

--- Вызывается при установке ракеты на载具
function MissileIntegration:onMissileInstalled()
    print("[MissileIntegration] Ракета установлена на载具")
    print(string.format("  - Урон: %d", MissileIntegration.MISSILE_CONFIG.damage))
    print(string.format("  - Радиус взрыва: %d м", MissileIntegration.MISSILE_CONFIG.explosionRadius))
    print(string.format("  - Вес: %d кг", MissileIntegration.MISSILE_CONFIG.weight))
end

--- Вызывается при снятии ракеты с載具
function MissileIntegration:onMissileUninstalled()
    print("[MissileIntegration] Ракета снята с載具")
end

--- Получить конфиг ракеты
function MissileIntegration:getConfig()
    return MissileIntegration.MISSILE_CONFIG
end

--- Получить информацию о ракете
function MissileIntegration:getInfo()
    local config = MissileIntegration.MISSILE_CONFIG
    return {
        id = config.id,
        name = config.displayName,
        description = config.description,
        damage = config.damage,
        explosionRadius = config.explosionRadius,
        fireRate = config.fireRate,
        accuracy = config.accuracy,
        reload = config.reload,
        weight = config.weight,
    }
end

--- Инициализировать ракету для载具
function MissileIntegration:initializeMissileForVehicle(vehicle)
    if not vehicle then
        print("[MissileIntegration] ОШИБКА:載具 не найден")
        return false
    end
    
    print("[MissileIntegration] Инициализация ракеты для載具: " .. vehicle:GetVehicleName())
    
    -- Получить систему огня载具
    local tankFireList = TankAPI.GetTankFireList(vehicle)
    if tankFireList and tankFireList.Count > 0 then
        print(string.format("[MissileIntegration] Найдено %d систем огня", tankFireList.Count))
        return true
    else
        print("[MissileIntegration] ОШИБКА: Системы огня не найдены")
        return false
    end
end

--- Запустить ракету
function MissileIntegration:fireMissile(vehicle, targetPos)
    if not vehicle then
        print("[MissileIntegration] ОШИБКА:载具 не определён")
        return false
    end
    
    if not targetPos then
        print("[MissileIntegration] ОШИБКА: Позиция цели не указана")
        return false
    end
    
    local launchPos = vehicle:GetComponent("Transform").position
    
    print("[MissileIntegration] Запуск ракеты!")
    print(string.format("  - Позиция запуска: (%.2f, %.2f, %.2f)", launchPos.x, launchPos.y, launchPos.z))
    print(string.format("  - Позиция цели: (%.2f, %.2f, %.2f)", targetPos.x, targetPos.y, targetPos.z))
    
    -- Создаём объект ракеты
    local Missile = require("scripts.missile")
    local missile = Missile.new(launchPos, targetPos, 45)
    
    -- Регистрируем обновление ракеты
    TimeAPI.RegisterLateFrameTick(function()
        local deltaTime = TimeAPI.GetDeltaTime()
        missile:update(deltaTime)
    end)
    
    print("[MissileIntegration] Ракета запущена успешно!")
    return true
end

--- Получить статистику ракеты
function MissileIntegration:getStats()
    local config = MissileIntegration.MISSILE_CONFIG
    return {
        name = config.name,
        damage = config.damage,
        explosionRadius = config.explosionRadius,
        fireRate = config.fireRate,
        accuracy = config.accuracy,
        reload = config.reload,
        weight = config.weight,
        class = "weapon",
    }
end

print("[MissileIntegration] Модуль интеграции ракет загружен успешно!")

-- Создаём глобальный экземпляр для доступа из игры
_G.MissileIntegration = MissileIntegration

return MissileIntegration
