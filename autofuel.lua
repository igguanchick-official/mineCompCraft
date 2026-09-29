-- Request parameters from user
print("How many blocks down to the lava?")
write("Enter depth: ")
local depthInput = read()
local depth = tonumber(depthInput)

print("How many buckets of lava to drink?")
write("Enter number of buckets: ")
local bucketsInput = read()
local targetBuckets = tonumber(bucketsInput)

if not depth or depth <= 0 or not targetBuckets or targetBuckets <= 0 then
    print("Error: Please enter valid numbers greater than 0!")
    return
end

local MAX_FUEL = 20000 
local BUCKET_SLOT = 1

term.clear()
term.setCursorPos(1, 1)
print("=== NETHER N-BUCKET REFUEL ===")
print("Depth: " .. depth .. " | Target buckets: " .. targetBuckets)
print("Please put ONE empty bucket in slot 1!")
print("---------------------------------")
local statusLine = 5

-- Счетчик выпитых ведер
local bucketsDrunk = 0

-- Функция сбора лавы под собой и мгновенной заправки
local function pumpAndRefuel()
    -- Защита от переполнения бака или выполнения нормы
    if turtle.getFuelLevel() >= MAX_FUEL or bucketsDrunk >= targetBuckets then
        return true
    end

    local hasBlock, data = turtle.inspectDown()
    if hasBlock and (data.name == "minecraft:lava" or data.name == "minecraft:flowing_lava") then
        turtle.select(BUCKET_SLOT)
        
        local item = turtle.getItemDetail(BUCKET_SLOT)
        if item and item.name == "minecraft:bucket" then
            if turtle.placeDown() then -- Набрали лаву
                turtle.refuel(1)      -- Выпили (+1000 топлива)
                bucketsDrunk = bucketsDrunk + 1 -- Увеличиваем счетчик
                return true
            end
        end
    end
    return false
end

local function checkEmergencyFuel()
    if turtle.getFuelLevel() > 0 then return true end
    return pumpAndRefuel()
end

-- --- 1. GOING DOWN TO THE LAVA ---
local blocksDown = 0
while blocksDown < depth do
    if turtle.getFuelLevel() == 0 then
        pumpAndRefuel()
    end
    if turtle.getFuelLevel() == 0 then
        print("\nCRITICAL ERROR: Out of fuel during descent!")
        return
    end

    while turtle.detectDown() do turtle.digDown() sleep(0.5) end
    if turtle.down() then
        blocksDown = blocksDown + 1
        term.setCursorPos(1, statusLine)
        term.clearLine()
        write("Status: Going down... " .. blocksDown .. "/" .. depth)
    else
        print("\nError: Blocked underneath.")
        break
    end
end

-- --- 2. PUMPING EXACT N BUCKETS ---
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Collecting lava...")

local actualLength = 0

-- Пытаемся заправиться на начальной точке
pumpAndRefuel()

-- Летим вперед, пока не наберем нужное число ведер
while bucketsDrunk < targetBuckets do
    -- Если бак забился под завязку физически, дальше пить нельзя
    if turtle.getFuelLevel() >= MAX_FUEL then
        term.setCursorPos(1, statusLine + 1)
        print("Status: Max fuel capacity reached!")
        break
    end

    -- Шаг вперед над лавой
    while turtle.detect() do turtle.dig() sleep(0.5) end
    if not turtle.forward() then 
        term.setCursorPos(1, statusLine + 1)
        print("Warning: Hit a wall before reaching N buckets.")
        break 
    end
    actualLength = actualLength + 1

    -- Пьем лаву в новой точке
    pumpAndRefuel()

    -- Обновляем статус
    term.setCursorPos(1, statusLine)
    term.clearLine()
    write("Buckets: " .. bucketsDrunk .. "/" .. targetBuckets .. " | Fuel: " .. turtle.getFuelLevel())
end

-- --- 3. RETURNING TO VERTICAL SHAFT ---
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Returning to shaft...")

turtle.turnRight()
turtle.turnRight()

for i = 1, actualLength do
    checkEmergencyFuel()
    while turtle.detect() do turtle.dig() sleep(0.5) end
    turtle.forward()
end

-- --- 4. GOING UP TO SURFACE ---
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Going up to surface...")

while blocksDown > 0 do
    checkEmergencyFuel()
    while turtle.detectUp() do turtle.digUp() sleep(0.5) end
    if turtle.up() then
        blocksDown = blocksDown - 1
        term.setCursorPos(1, statusLine + 1)
        term.clearLine()
        write("Blocks left to climb: " .. blocksDown)
    else
        print("\nError: Path blocked on way up!")
        break
    end
end

turtle.turnRight()
turtle.turnRight()

term.clear()
term.setCursorPos(1, 1)
print("=== REFUEL MISSION COMPLETED ===")
print("Buckets consumed: " .. bucketsDrunk .. "/" .. targetBuckets)
print("Final Fuel Level: " .. turtle.getFuelLevel() .. "/" .. MAX_FUEL)
