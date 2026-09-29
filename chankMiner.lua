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
print("=== FIXED SHAFT QUARRY ===")
print("Area: " .. width .. "x" .. length .. " | Depth: " .. totalDepth)
print("Safe descent active (Chest protected)")
print("-----------------------------------")
local statusLine = 5

-- Глобальные координаты. Точка (0,0,0) — это стартовая ячейка над сундуком.
local curX = 0   
local curY = 0   
local curZ = 0   
local curDir = 0 -- 0: Вперед, 1: Вправо, 2: Назад, 3: Влево

local function turnLeftTrack() 
    turtle.turnLeft() 
    curDir = (curDir - 1) % 4
end

local function turnRightTrack() 
    turtle.turnRight() 
    curDir = (curDir + 1) % 4
end

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

-- Шаг вперед с обновлением виртуального компаса
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

-- Шаг копания (вперед, вверх, вниз)
local function digForwardStep()
    if not stepForward() then return false end
    while turtle.detectUp() do turtle.digUp() sleep(0.5) end
    if turtle.detectDown() then turtle.digDown() end
    return true
end

-- Спуск под себя
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
    -- 1. Навигация перед началом слоя
    if layer == 1 then
        -- Первый слой: просто выходим из стартовой шахты на Y = 1 (сундук остается сзади на Y = 0)
        if not digForwardStep() then
            print("Error exiting start shaft.")
            break
        end
    else
        -- Последующие слои: мы УЖЕ стоим на X=0, Y=1. Спускаемся строго вниз.
        term.setCursorPos(1, statusLine)
        term.clearLine()
        print("Status: Descending to layer " .. layer .. "/" .. totalLayers)
        
        if not goDownBlocks(LAYER_HEIGHT) then
            print("CRITICAL ERROR: Path blocked during descent!")
            break
        end
    end

    -- 2. Выкапываем плоскость текущего слоя змейкой width x length
    for lane = 1, width do
        for step = 1, length - 1 do
            if not checkAndRefuel() then return end
            if step % 5 == 0 or isInventoryFull() then clearTrash() end
            if isInventoryFull() then term.setCursorPos(1, statusLine + 1) print("Error: Inv full!") return end
            if not digForwardStep() then term.setCursorPos(1, statusLine + 1) print("Error: Blocked!") return end
            
            term.setCursorPos(1, statusLine)
            term.clearLine()
            write("Layer: " .. layer .. "/" .. totalLayers .. " | Lane: " .. lane .. "/" .. width)
        end

        if lane < width then
            if lane % 2 == 1 then
                turnRightTrack()
                if not digForwardStep() then print("Error lane shift.") return end
                turnRightTrack()
            else
                turnLeftTrack()
                if not digForwardStep() then print("Error lane shift.") return end
                turnLeftTrack()
            end
            clearTrash()
        end
    end

    clearTrash()

    -- 3. ВОЗВРАТ К ДИСТАНЦИОННОЙ ОСИ (X = 0, Y = 1) ПО ВОЗДУХУ
    term.setCursorPos(1, statusLine)
    term.clearLine()
    print("Status: Layer done. Returning to safe line...")

    -- Разворачиваемся назад (лицом к Y=1)
    while curDir ~= 2 do turnRightTrack() end
    while curY > 1 do
        if not checkAndRefuel() then break end
        if stepForward() then curY = curY - 1 else break end
    end

    -- Разворачиваемся влево (лицом к X=0)
    while curDir ~= 3 do turnRightTrack() end
    while curX > 0 do
        if not checkAndRefuel() then break end
        if stepForward() then curX = curX - 1 else break end
    end

    -- ЖЕСТКИЙ СБРОС НАПРАВЛЕНИЯ: разворачиваемся строго вперед (0) пред следующим слоем
    while curDir ~= 0 do turnRightTrack() end
end

-- --- FINAL RETURN TO SURFACE & UNLOAD ---
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Mining done! Climbing up safe line...")

-- Поднимаемся до уровня поверхности (curZ = 0) на безопасной точке Y = 1
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

-- Делаем шаг НАЗАД, возвращаясь на исходную точку Y = 0 строго НАД сундуком
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Moving back over the chest...")

while curDir ~= 2 do turnRightTrack() end
if turtle.forward() then
    curY = 0
else
    print("Error returning to original shaft node.")
end

-- Разгрузка в двойной сундук под ногами
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Unloading valuables to chest...")

for slot = 1, 16 do
    if turtle.getItemCount(slot) > 0 then
        turtle.select(slot)
        while not turtle.dropDown() do
            term.setCursorPos(1, statusLine + 1)
            term.clearLine()
            print("Warning: Storage chest is full!")
            sleep(5)
        end
    end
end
turtle.select(1)

-- Разворачиваемся в начальное положение (лицом к карьеру)
while curDir ~= 0 do turnRightTrack() end

term.clear()
term.setCursorPos(1, 1)
print("=== FIXED MISSION COMPLETED ===")
print("Quarry cleared. Layer shift issue fixed!")
print("Fuel left: " .. turtle.getFuelLevel())

