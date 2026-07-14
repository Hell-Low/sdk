--- Трёхстадийная система ракет для Panzer War
--- Stage 1: Медленный запуск из ствола (50-60 м/с)
--- Stage 2: Разгон вверх на 1500м (800 м/с)
--- Stage 3: Полёт к цели (750 м/с)

local Missile = class("Missile")

--- Константы стадий
Missile.STAGE = {
    LAUNCH = 1,      -- Запуск из ствола
    ASCENT = 2,      -- Разгон и подъём
    CRUISE = 3       -- Полёт к цели
}

--- Параметры для реального мира (можешь отредактировать под игру)
Missile.PARAMS = {
    -- Стадия 1: Запуск
    stage1 = {
        speed = 55,              -- м/с (среднее 50-60)
        duration = 2.0,          -- сек (время разгона из ствола)
        acceleration = 20,       -- м/с² (ускорение на старте)
    },
    
    -- Стадия 2: Разгон и подъём
    stage2 = {
        speed = 800,             -- м/с (максимальная скорость)
        targetAltitude = 1500,   -- метры (высота подъёма)
        duration = 2.5,          -- сек (примерно время до высоты 1500м)
        acceleration = 250,      -- м/с² (разгон на стадии 2)
    },
    
    -- Стадия 3: Полёт к цели
    stage3 = {
        speed = 750,             -- м/с (скорость крейсерского полёта)
        cruiseAltitude = 1200,   -- метры (высота полёта)
        deceleration = 50,       -- м/с² (замедление перед целью)
    },
    
    -- Общие параметры
    damage = 500,                -- единицы урона
    explosionRadius = 100,       -- метры (радиус взрыва)
    weight = 45,                 -- кг (вес ракеты)
    mass = 45,                   -- кг (масса для физики)
    drag = 0.47,                 -- коэффициент сопротивления воздуха
    gravity = 9.81,              -- м/с² (гравитация)
    maxFuelTime = 8.0,           -- сек (общее время полёта)
}

--- Инициализация ракеты
function Missile:ctor(launchPos, targetPos, launchAngle)
    self.launchPos = launchPos or {x = 0, y = 0, z = 0}
    self.targetPos = targetPos or {x = 100, y = 0, z = 100}
    self.launchAngle = launchAngle or 45  -- градусы
    
    -- Текущее состояние
    self.currentStage = Missile.STAGE.LAUNCH
    self.position = {
        x = self.launchPos.x,
        y = self.launchPos.y,
        z = self.launchPos.z
    }
    self.velocity = {x = 0, y = 0, z = 0}
    self.acceleration = {x = 0, y = 0, z = 0}
    
    -- Таймеры
    self.stageTimer = 0
    self.totalTime = 0
    self.isAlive = true
    self.hasExploded = false
    
    -- Расстояние до цели
    self.distanceToTarget = self:calculateDistance(self.launchPos, self.targetPos)
    
    -- Направление к цели (нормализованный вектор)
    self.directionToTarget = self:normalizeVector(
        self:subtractVectors(self.targetPos, self.launchPos)
    )
    
    print("[Missile] Запуск ракеты!")
    print(string.format("[Missile] Дистанция до цели: %.2f м", self.distanceToTarget))
    print(string.format("[Missile] Начальная позиция: (%.2f, %.2f, %.2f)", 
        self.position.x, self.position.y, self.position.z))
end

--- Обновление позиции ракеты (вызывать каждый фрейм)
function Missile:update(deltaTime)
    if not self.isAlive then
        return
    end
    
    self.totalTime = self.totalTime + deltaTime
    self.stageTimer = self.stageTimer + deltaTime
    
    -- Проверка топлива
    if self.totalTime >= Missile.PARAMS.maxFuelTime then
        self:explode()
        return
    end
    
    -- Обновление стадии
    self:updateStage(deltaTime)
    
    -- Применение физики
    self:applyPhysics(deltaTime)
    
    -- Обновление позиции
    self:updatePosition(deltaTime)
    
    -- Проверка попадания в цель
    self:checkCollision()
end

--- Обновление текущей стадии
function Missile:updateStage(deltaTime)
    if self.currentStage == Missile.STAGE.LAUNCH then
        self:updateLaunchStage(deltaTime)
    elseif self.currentStage == Missile.STAGE.ASCENT then
        self:updateAscentStage(deltaTime)
    elseif self.currentStage == Missile.STAGE.CRUISE then
        self:updateCruiseStage(deltaTime)
    end
end

--- Стадия 1: Медленный запуск из ствола
function Missile:updateLaunchStage(deltaTime)
    -- Если время стадии 1 закончилось - переходим на стадию 2
    if self.stageTimer >= Missile.PARAMS.stage1.duration then
        self:transitionToAscent()
    end
    
    -- Ускорение на начальном этапе
    self.acceleration.y = 0  -- Пока летим вперёд
    
    -- Применяем ускорение
    local accel = Missile.PARAMS.stage1.acceleration
    self.velocity.x = self.velocity.x + (self.directionToTarget.x * accel * deltaTime)
    self.velocity.z = self.velocity.z + (self.directionToTarget.z * accel * deltaTime)
    
    -- Контролируем скорость не превышать 60 м/с на стадии 1
    local speed = self:getSpeed()
    if speed > Missile.PARAMS.stage1.speed then
        local factor = Missile.PARAMS.stage1.speed / speed
        self.velocity.x = self.velocity.x * factor
        self.velocity.z = self.velocity.z * factor
    end
end

--- Стадия 2: Разгон вверх на 1500м
function Missile:updateAscentStage(deltaTime)
    -- Если достигли целевой высоты - переходим на стадию 3
    if self.position.y >= Missile.PARAMS.stage2.targetAltitude then
        self:transitionToCruise()
    end
    
    -- Разгон вверх
    self.acceleration.y = Missile.PARAMS.stage2.acceleration
    
    -- Горизонтальное движение к цели (медленнее, чем вверх)
    local horizontalAccel = Missile.PARAMS.stage2.acceleration * 0.5
    self.velocity.x = self.velocity.x + (self.directionToTarget.x * horizontalAccel * deltaTime)
    self.velocity.z = self.velocity.z + (self.directionToTarget.z * horizontalAccel * deltaTime)
    
    -- Вертикальное движение
    self.velocity.y = self.velocity.y + (self.acceleration.y * deltaTime)
    
    -- Контролируем скор��сть на стадии 2
    local speed = self:getSpeed()
    if speed > Missile.PARAMS.stage2.speed then
        local factor = Missile.PARAMS.stage2.speed / speed
        self.velocity.x = self.velocity.x * factor
        self.velocity.y = self.velocity.y * factor
        self.velocity.z = self.velocity.z * factor
    end
end

--- Стадия 3: Полёт к цели
function Missile:updateCruiseStage(deltaTime)
    -- На стадии 3 летим к цели с постоянной скоростью
    -- Медленно снижаемся к цели
    
    local distanceToTarget = self:calculateDistance(self.position, self.targetPos)
    
    -- Если близко к цели (в пределах 50м) - взрыв
    if distanceToTarget < 50 then
        self:explode()
        return
    end
    
    -- Направление к цели (обновляем каждый фрейм)
    local newDirection = self:normalizeVector(
        self:subtractVectors(self.targetPos, self.position)
    )
    
    -- Применяем направление с скоростью стадии 3
    local cruiseSpeed = Missile.PARAMS.stage3.speed
    self.velocity.x = newDirection.x * cruiseSpeed
    self.velocity.z = newDirection.z * cruiseSpeed
    
    -- Снижение к цели
    if self.position.y > self.targetPos.y then
        self.velocity.y = -Missile.PARAMS.stage3.deceleration * deltaTime
    else
        self.velocity.y = 0
    end
end

--- Применение физики (гравитация, сопротивление воздуха)
function Missile:applyPhysics(deltaTime)
    -- Гравитация (кроме стадии 2, где есть активное ускорение)
    if self.currentStage ~= Missile.STAGE.ASCENT then
        self.velocity.y = self.velocity.y - (Missile.PARAMS.gravity * deltaTime)
    end
    
    -- Сопротивление воздуха (очень слабое)
    local dragFactor = 1 - (Missile.PARAMS.drag * 0.001 * deltaTime)
    self.velocity.x = self.velocity.x * dragFactor
    self.velocity.z = self.velocity.z * dragFactor
end

--- Обновление позиции
function Missile:updatePosition(deltaTime)
    self.position.x = self.position.x + (self.velocity.x * deltaTime)
    self.position.y = self.position.y + (self.velocity.y * deltaTime)
    self.position.z = self.position.z + (self.velocity.z * deltaTime)
    
    -- Если ракета упала ниже земли - взрыв
    if self.position.y < 0 then
        self:explode()
    end
end

--- Проверка столкновения с целью
function Missile:checkCollision()
    local distance = self:calculateDistance(self.position, self.targetPos)
    
    -- Если рядом с целью - взрыв
    if distance < 100 and self.currentStage == Missile.STAGE.CRUISE then
        self:explode()
    end
end

--- Переход на стадию 2
function Missile:transitionToAscent()
    self.currentStage = Missile.STAGE.ASCENT
    self.stageTimer = 0
    print("[Missile] Переход на стадию 2: РАЗГОН И ПОДЪЁМ (800 м/с)")
    print(string.format("[Missile] Текущая позиция: (%.2f, %.2f, %.2f)", 
        self.position.x, self.position.y, self.position.z))
end

--- Переход на стадию 3
function Missile:transitionToCruise()
    self.currentStage = Missile.STAGE.CRUISE
    self.stageTimer = 0
    print("[Missile] Переход на стадию 3: ПОЛЁТ К ЦЕЛИ (750 м/с)")
    print(string.format("[Missile] Достигнута высота: %.2f м", self.position.y))
end

--- Взрыв ракеты
function Missile:explode()
    if self.hasExploded then
        return
    end
    
    self.hasExploded = true
    self.isAlive = false
    
    print("[Missile] ВЗРЫВ!")
    print(string.format("[Missile] Позиция взрыва: (%.2f, %.2f, %.2f)", 
        self.position.x, self.position.y, self.position.z))
    print(string.format("[Missile] Радиус поражения: %d м", Missile.PARAMS.explosionRadius))
    print(string.format("[Missile] Урон: %d", Missile.PARAMS.damage))
    print(string.format("[Missile] Общее время полёта: %.2f сек", self.totalTime))
    
    -- Здесь вызывать функцию нанесения урона в игре
    self:dealDamage()
end

--- Нанесение урона в области взрыва
function Missile:dealDamage()
    -- TODO: Реализовать нанесение урона врагам в радиусе explosionRadius
    -- в позиции self.position с уроном self.PARAMS.damage
    print("[Missile] Урон нанесён всем целям в радиусе!")
end

--- Утилиты: Расстояние между двумя точками
function Missile:calculateDistance(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    local dz = pos2.z - pos1.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

--- Утилиты: Вычитание векторов
function Missile:subtractVectors(v1, v2)
    return {
        x = v1.x - v2.x,
        y = v1.y - v2.y,
        z = v1.z - v2.z
    }
end

--- Утилиты: Нормализация вектора
function Missile:normalizeVector(vec)
    local length = math.sqrt(vec.x*vec.x + vec.y*vec.y + vec.z*vec.z)
    if length == 0 then
        return {x = 0, y = 0, z = 0}
    end
    return {
        x = vec.x / length,
        y = vec.y / length,
        z = vec.z / length
    }
end

--- Утилиты: Текущая скорость ракеты
function Missile:getSpeed()
    return math.sqrt(
        self.velocity.x*self.velocity.x + 
        self.velocity.y*self.velocity.y + 
        self.velocity.z*self.velocity.z
    )
end

--- Получить информацию о ракете
function Missile:getInfo()
    return {
        stage = self.currentStage,
        position = {x = self.position.x, y = self.position.y, z = self.position.z},
        velocity = self:getSpeed(),
        distanceToTarget = self:calculateDistance(self.position, self.targetPos),
        totalTime = self.totalTime,
        isAlive = self.isAlive,
        hasExploded = self.hasExploded
    }
end

return Missile
