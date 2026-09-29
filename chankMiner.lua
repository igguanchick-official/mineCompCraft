-- Request quarry dimensions from the user
print("Enter Width (X - lanes to the right):")
local inputX = read()
local width = tonumber(inputX)

print("Enter Length (Y - blocks forward):")
local inputY = read()
local length = tonumber(inputY)

print("Enter Total Depth (Z - total blocks down):")
local inputZ = read()
local totalDepth = tonumber(inputZ)

if not width or width <= 0 or not length or length <= 0 or not totalDepth or totalDepth <= 0 then
    print("Error: Please enter valid numbers greater than 0!")
    return
end

local MIN_FUEL = 400 
local LAYER_HEIGHT = 3
local totalLayers = math.ceil(totalDepth / LAYER_HEIGHT)

local trashItems = {
    ["minecraft:cobblestone"] = true, ["minecraft:stone"] = true,
    ["minecraft:dirt"] = true, ["minecraft:gravel"] = true,
    ["minecraft:andesite"] = true, ["minecraft:diorite"] = true,
    ["minecraft:granite"] = true, ["minecraft:deepslate"] = true,
    ["minecraft:cobbled_deepslate"] = true, ["minecraft:tuff"] = true,
    ["minecraft:netherrack"] = true, ["minecraft:blackstone"] = true,
    ["minecraft:basalt"] = true
}

term.clear()
term.setCursorPos(1, 1)
print("=== FRONT QUARRY SYSTEM ===")
print("Area: " .. width .. "x" .. length .. " | Depth: " .. totalDepth)
print("Chest location: Under start block")
print("-----------------------------------")
local statusLine = 5

-- Глобальные координаты относительно стартовой ячейки на поверхности
local curX, curY, curZ = 0, 0, 0
local curDir = 0 -- 0: Вперед, 1: Вправо, 2: Назад, 3: Влево

local function turnLeftTrack() turtle.turnLeft() curDir = (curDir - 1) % 4 end
local function turnRightTrack() turtle.turnRight() curDir = (curDir + 1) % 4 end

local function checkAndRefuel()
    if turtle.getFuelLevel() >= MIN_FUEL then return true end
    term.setCursorPos(1, statusLine + 1)
    term.clearLine()
    write("Status: Low fuel! Searching...")
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then
            turtle.refuel(5) -- Экономная заправка по 5 шт
            if turtle.getFuelLevel() >= MIN_FUEL then
                turtle.select(1)
                return true
            end
        end
    end
    turtle.select(1)
    return turtle.getFuelLevel() > 0
end

local function clearTrash()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and trashItems[item.name] then
            turtle.select(slot)
            turtle.dropDown()
        end
    end
    turtle.select(1)
end

local function isInventoryFull()
    for i = 1, 16 do if turtle.getItemCount(i) == 0 then return false end end
    return true
end

local function stepForward()
    while turtle.detect() do turtle.dig() sleep(0.5) end
    if not turtle.forward() then return false end
    
    if curDir == 0 then curY = curY + 1
    elseif curDir == 1 then curX = curX + 1
    elseif curDir == 2 then curY = curY - 1
    elseif curDir == 3 then curX = curX - 1
    end
    return true
end

local function digStep()
    if not stepForward() then return false end
    while turtle.detectUp() do turtle.digUp() sleep(0.5) end
    if turtle.detectDown() then turtle.digDown() end
    return true
end

-- Спуск на Z блоков вниз
local function goDownBlocks(blocks)
    for b = 1, blocks do
        while turtle.detectDown() do turtle.digDown() sleep(0.5) end
        if turtle.down() then
            curZ = curZ - 1
        else
            return false
        end
    end
    return true
end

-- --- MAIN QUARRY LOOP ---

for layer = 1, totalLayers do
    -- 1. Спускаемся по базовой оси шахты
    local downDistance = (layer == 1) and 1 or LAYER_HEIGHT
    term.setCursorPos(1, statusLine)
    term.clearLine()
    print("Status: Descending to layer " .. layer .. "/" .. totalLayers)
    
    if not goDownBlocks(downDistance) then
        print("CRITICAL ERROR: Bedrock blocked descent!")
        break
    end

    -- 2. Делаем первый шаг ВПЕРЕД, чтобы войти в зону 16х16 (область перед роботом)
    if not digStep() then
        print("Error entering mining zone.")
        break
    end

    -- 3. Копаем змейкой (длина уменьшена на 1, так как первый шаг уже сделан)
    for lane = 1, width do
        -- В первой линии копаем на (length - 1) шагов, в остальных — на полную длину
        local stepsInLane = (lane == 1) and (length - 1) or (length - 1)
        -- Из-за смещения координат, цикл идет одинаково:
        for step = 1, length - 1 do
            if not checkAndRefuel() then return end
            if step % 5 == 0 or isInventoryFull() then clearTrash() end
            if isInventoryFull() then term.setCursorPos(1, statusLine + 1) print("Error: Inv full!") return end
            if not digStep() then term.setCursorPos(1, statusLine + 1) print("Error: Blocked!") return end
            
            term.setCursorPos(1, statusLine)
            term.clearLine()
            write("Layer: " .. layer .. "/" .. totalLayers .. " | Lane: " .. lane .. "/" .. width)
        end

        if lane < width then
            if lane % 2 == 1 then
                turnRightTrack()
                if not digStep() then print("Error lane shift.") return end
                turnRightTrack()
            else
                turnLeftTrack()
                if not digStep() then print("Error lane shift.") return end
                turnLeftTrack()
            end
            clearTrash()
        end
    end

    clearTrash()

    -- 4. Возврат к вертикальной оси спуска по воздуху
    term.setCursorPos(1, statusLine)
    term.clearLine()
    print("Status: Returning to axle...")

    while curDir ~= 2 do turnRightTrack() end
    -- Летим назад до координаты Y = 0 (точка прямо под стартом)
    while curY > 0 do
        if not checkAndRefuel() then break end
        if stepForward() then curY = curY - 1 else break end
    end

    while curDir ~= 3 do turnRightTrack() end
    -- Летим влево до координаты X = 0
    while curX > 0 do
        if not checkAndRefuel() then break end
        if stepForward() then curX = curX - 1 else break end
    end

    while curDir ~= 0 do turnRightTrack() end
end

-- --- 5. RETURN TO SURFACE & UNLOAD ---
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Mining done! Climbing to surface...")

-- Поднимаемся обратно до уровня curZ = 0
while curZ < 0 do
    if not checkAndRefuel() then break end
    while turtle.detectUp() do turtle.digUp() sleep(0.5) end
    if turtle.up() then
        curZ = curZ + 1
        term.setCursorPos(1, statusLine + 1)
        term.clearLine()
        write("Climbing... Blocks left: " .. math.abs(curZ))
    else
        print("\nError: Way up blocked!")
        break
    end
end

-- Финальная разгрузка в сундук под ногами
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Unloading valuables to chest...")

for slot = 1, 16 do
    if turtle.getItemCount(slot) > 0 then
        turtle.select(slot)
        -- Выгружаем строго вниз (в сундук)
        while not turtle.dropDown() do
            term.setCursorPos(1, statusLine + 1)
            term.clearLine()
            print("Warning: Storage chest is full!")
            sleep(5)
        end
    end
end
turtle.select(1)

term.clear()
term.setCursorPos(1, 1)
print("=== MISSION COMPLETED ===")
print("Quarry area cleared successfully!")
print("All resources saved to the chest underneath.")
