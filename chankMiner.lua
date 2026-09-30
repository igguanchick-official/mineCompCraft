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
print("=== AUTO-UNLOAD QUARRY ===")
print("Area: " .. width .. "x" .. length .. " | Depth: " .. totalDepth)
print("-----------------------------------")
local statusLine = 5

-- Глобальные координаты. Точка (0,0,0) — это стартовая ячейка над сундуком.
local curX, curY, curZ, curDir = 0, 0, 0, 0

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
            turtle.refuel(5)
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

-- Безопасный шаг вперед
local function safeMove()
    while turtle.detect() do turtle.dig() sleep(0.5) end
    if not turtle.forward() then return false end
    if curDir == 0 then curY = curY + 1
    elseif curDir == 1 then curX = curX + 1
    elseif curDir == 2 then curY = curY - 1
    elseif curDir == 3 then curX = curX - 1
    end
    return true
end

-- Шаг полноценного копания (вперед, вверх, вниз)
local function digForwardStep()
    if not safeMove() then return false end
    while turtle.detectUp() do turtle.digUp() sleep(0.5) end
    turtle.digDown()
    return true
end

-- Спуск под себя
local function goDownBlocks(blocks)
    for b = 1, blocks do
        turtle.digDown()
        if turtle.down() then
            curZ = curZ - 1
            while turtle.detectUp() do turtle.digUp() sleep(0.5) end
            while turtle.detect() do turtle.dig() sleep(0.5) end
        else
            return false
        end
    end
    return true
end

-- Функция выгрузки ресурсов в сундук на поверхности
local function unloadToChest()
    term.setCursorPos(1, statusLine)
    term.clearLine()
    print("Status: Unloading to chest...")
    
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            while not turtle.dropDown() do
                term.setCursorPos(1, statusLine + 1)
                term.clearLine()
                print("Warning: Storage chest full!")
                sleep(5)
            end
        end
    end
    turtle.select(1)
end

-- Функция экстренного возврата на базу и возвращения обратно к точке копания
local function emergencyUnload()
    -- Запоминаем текущую рабочую позицию
    local savedX, savedY, savedZ, savedDir = curX, curY, curZ, curDir
    
    term.setCursorPos(1, statusLine + 1)
    term.clearLine()
    print("Status: Inv full! Going to unload...")

    -- 1. Летим назад к безопасной вертикали (X=0, Y=1)
    while curDir ~= 2 do turnRightTrack() end
    while curY > 1 do if safeMove() == false then break end end
    
    while curDir ~= 3 do turnRightTrack() end
    while curX > 0 do if safeMove() == false then break end end

    -- 2. Поднимаемся на поверхность (curZ = 0)
    while curZ < 0 do
        while turtle.detectUp() do turtle.digUp() sleep(0.5) end
        if turtle.up() then curZ = curZ + 1 else break end
    end

    -- 3. Шаг назад (Y=0) строго НАД сундук и выгрузка
    while curDir ~= 2 do turnRightTrack() end
    if safeMove() then curY = 0 end
    unloadToChest()

    -- 4. ВОЗВРАЩАЕМСЯ ОБРАТНО НА РАБОЧУЮ ТОЧКУ
    term.setCursorPos(1, statusLine + 1)
    term.clearLine()
    print("Status: Returning to work site...")
    
    -- Выходим обратно на Y=1
    while curDir ~= 0 do turnRightTrack() end
    if safeMove() then curY = 1 end

    -- Спускаемся обратно на нужный этаж
    while curZ > savedZ do
        turtle.digDown()
        if turtle.down() then curZ = curZ - 1 else break end
    end

    -- Летим вперед на нужную координату X
    while curDir ~= 1 do turnRightTrack() end
    while curX < savedX do if safeMove() == false then break end end

    -- Летим вперед на нужную координату Y
    while curDir ~= 0 do turnRightTrack() end
    while curY < savedY do if safeMove() == false then break end end

    -- Восстанавливаем оригинальное направление взгляда черепашки
    while curDir ~= savedDir do turnRightTrack() end
    
    term.setCursorPos(1, statusLine + 1)
    term.clearLine()
end

-- --- MAIN QUARRY LOOP ---
for layer = 1, totalLayers do
    if layer == 1 then
        while turtle.detect() do turtle.dig() sleep(0.5) end
        if turtle.forward() then
            curY = 1
            while turtle.detectUp() do turtle.digUp() sleep(0.5) end
            turtle.digDown()
        else
            print("Error exiting start shaft.")
            break
        end
    else
        term.setCursorPos(1, statusLine)
        term.clearLine()
        print("Status: Going to layer " .. layer)
        if not goDownBlocks(LAYER_HEIGHT) then
            print("CRITICAL ERROR: Descent blocked!")
            break
        end
    end

    for lane = 1, width do
        for step = 1, length - 1 do
            if not checkAndRefuel() then return end
            if step % 5 == 0 or isInventoryFull() then clearTrash() end
            
            -- ПРОВЕРКА: Если даже после очистки мусора инвентарь забит ценными рудами
            if isInventoryFull() then
                emergencyUnload()
            end
            
            if not digForwardStep() then term.setCursorPos(1, statusLine + 1) print("Error: Blocked!") return end
            
            term.setCursorPos(1, statusLine)
            term.clearLine()
            write("L:" .. layer .. "/" .. totalLayers .. " | X:" .. lane .. "/" .. width .. " | F:" .. turtle.getFuelLevel())
        end

        if lane < width then
            if lane % 2 == 1 then
                turnRightTrack()
                if isInventoryFull() then emergencyUnload() end
                if not digForwardStep() then print("Error lane shift.") return end
                turnRightTrack()
            else
                turnLeftTrack()
                if isInventoryFull() then emergencyUnload() end
                if not digForwardStep() then print("Error lane shift.") return end
                turnLeftTrack()
            end
            clearTrash()
        end
    end

    clearTrash()

    -- Плановый возврат в конце слоя
    term.setCursorPos(1, statusLine)
    term.clearLine()
    print("Status: Layer done. Returning...")

    while curDir ~= 2 do turnRightTrack() end
    while curY > 1 do
        if not checkAndRefuel() then break end
        if not safeMove() then break end
    end

    while curDir ~= 3 do turnRightTrack() end
    while curX > 0 do
        if not checkAndRefuel() then break end
        if not safeMove() then break end
    end

    while curDir ~= 0 do turnRightTrack() end
end

-- --- FINAL RETURN TO SURFACE ---
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Done! Climbing up...")

while curZ < 0 do
    if not checkAndRefuel() then break end
    while turtle.detectUp() do turtle.digUp() sleep(0.5) end
    if turtle.up() then
        curZ = curZ + 1
        term.setCursorPos(1, statusLine + 1)
        term.clearLine()
        write("Climbing... Left: " .. math.abs(curZ))
    else
        print("\nError: Way up blocked!")
        break
    end
end

-- Шаг назад на ось шахты над сундуком
while curDir ~= 2 do turnRightTrack() end
if safeMove() then curY = 0 end

-- Финальная сдача всей добычи
unloadToChest()
while curDir ~= 0 do turnRightTrack() end

term.clear()
term.setCursorPos(1, 1)
print("=== MISSION COMPLETED ===")
print("Quarry cleared. Fuel left: " .. turtle.getFuelLevel())
