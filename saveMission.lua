local MAX_FUEL = 20000
local TARGET_SLOT = 1  -- Сюда упадет спасенная черепашка
local BUCKET_SLOT = 2  -- Здесь лежит пустое ведро

term.clear()
term.setCursorPos(1,1)
print("=== BLIND RESCUE RADAR ===")
print("Ensure Slot 1 is EMPTY!")
print("Ensure Slot 2 has 1 BUCKET!")
print("--------------------------")

local function pumpAndRefuel()
    if turtle.getFuelLevel() >= 1000 then return true end
    local hasBlock, data = turtle.inspectDown()
    if hasBlock and (data.name == "minecraft:lava" or data.name == "minecraft:flowing_lava") then
        turtle.select(BUCKET_SLOT)
        if turtle.placeDown() then
            turtle.refuel(1) -- Выпиваем ведро лавы
            return true
        end
    end
    return false
end

-- --- 1. СУМАСШЕДШИЙ СПУСК ДО УПОРА ---
print("Descending to the floor...")
local blocksDown = 0

while not turtle.detectDown() do
    if turtle.getFuelLevel() == 0 then
        -- Если кончилось стартовое топливо, проверяем лаву под ногами
        pumpAndRefuel()
    end
    if turtle.getFuelLevel() == 0 then
        print("CRITICAL: Out of fuel during descent!")
        return
    end
    
    if turtle.down() then
        blocksDown = blocksDown + 1
    else
        break
    end
end

print("Floor reached at " .. blocksDown .. " blocks down.")

-- --- 2. ПОДЪЕМ НА 1 БЛОК ВВЕРХ ---
if blocksDown > 0 then
    print("Rising 1 block up to mining layer...")
    if turtle.up() then
        blocksDown = blocksDown - 1
    else
        print("Error: Cannot rise up from the floor!")
        return
    end
end

-- --- 3. ПОЛЕТ ВПЕРЕД В РЕЖИМЕ РАДАРА ---
print("Searching for target...")
local stepsForward = 0

while true do
    pumpAndRefuel()
    
    -- Проверяем, что перед нами
    local hasBlock, data = turtle.inspect()
    
    if hasBlock then
        -- Если уперлись в блок (черепашку), ломаем её кирочкой
        print("Target detected! Extracting...")
        turtle.select(TARGET_SLOT)
        turtle.dig() -- Застрявшая черепашка падает предметом в слот 1
        break
    end
    
    -- Если впереди пусто, летим дальше
    if turtle.forward() then
        stepsForward = stepsForward + 1
    else
        print("Warning: Hit unexpected wall.")
        break
    end
    
    sleep(0.1)
end

-- --- 4. ВОЗВРАЩЕНИЕ НА БАЗУ ---
print("Mission complete! Flying home...")
turtle.turnRight()
turtle.turnRight()

-- Летим назад по линии
for i = 1, stepsForward do
    turtle.forward()
end

-- Поднимаемся обратно на поверхность
for i = 1, blocksDown do
    turtle.up()
end

-- Разворачиваемся в начальное положение
turtle.turnRight()
turtle.turnRight()
print("Success! Check your Slot 1.")
