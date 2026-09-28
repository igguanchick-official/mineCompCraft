-- Request parameters from user
print("How many blocks down to go?")
write("Enter depth: ")
local depthInput = read()
local depth = tonumber(depthInput)

print("Enter Width (X - lanes to the right):")
local inputX = read()
local width = tonumber(inputX)

print("Enter Length (Y - blocks forward):")
local inputY = read()
local length = tonumber(inputY)

if not depth or depth <= 0 or not width or width <= 0 or not length or length <= 0 then
    print("Error: Please enter valid numbers greater than 0!")
    return
end

local MIN_FUEL = 100 
local trashItems = {
    ["minecraft:cobblestone"] = true, ["minecraft:stone"] = true,
    ["minecraft:dirt"] = true, ["minecraft:gravel"] = true,
    ["minecraft:andesite"] = true, ["minecraft:diorite"] = true,
    ["minecraft:granite"] = true, ["minecraft:deepslate"] = true,
    ["minecraft:cobbled_deepslate"] = true, ["minecraft:tuff"] = true
}

term.clear()
term.setCursorPos(1, 1)
print("=== DEEP AREA MINING SYSTEM ===")
print("Depth: " .. depth .. " | Area: " .. width .. "x" .. length)
print("-----------------------------------")
local statusLine = 4

-- Виртуальные координаты ВНУТРИ нижней площадки для возврата к шахте
local curX = 0   -- Смещение вправо от шахты
local curY = 0   -- Смещение вперед от шахты
local curDir = 0 -- 0: Вперед, 1: Вправо, 2: Назад, 3: Влево

local function turnLeftTrack() turtle.turnLeft() curDir = (curDir - 1) % 4 end
local function turnRightTrack() turtle.turnRight() curDir = (curDir + 1) % 4 end

local function checkAndRefuel()
    if turtle.getFuelLevel() >= MIN_FUEL then return true end
    term.setCursorPos(1, statusLine + 1)
    term.clearLine()
    write("Status: Searching for coal...")
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then
            turtle.refuel(5) -- Экономная заправка по 5 штук
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

-- Шаг копания вперед с обновлением координат на плоскости
local function digStep()
    while turtle.detect() do turtle.dig() sleep(0.5) end
    if not turtle.forward() then return false end
    
    if curDir == 0 then curY = curY + 1
    elseif curDir == 1 then curX = curX + 1
    elseif curDir == 2 then curY = curY - 1
    elseif curDir == 3 then curX = curX - 1
    end

    while turtle.detectUp() do turtle.digUp() sleep(0.5) end
    if turtle.detectDown() then turtle.digDown() end
    return true
end

-- --- 1. GOING DOWN TO THE LEVEL ---
local blocksDown = 0
while blocksDown < depth do
    if not checkAndRefuel() then print("Out of fuel!") return end
    while turtle.detectDown() do turtle.digDown() sleep(0.5) end
    if turtle.down() then
        blocksDown = blocksDown + 1
        term.setCursorPos(1, statusLine)
        term.clearLine()
        write("Status: Going down... " .. blocksDown .. "/" .. depth)
    else
        print("\nError: Blocked underneath. Bedrock?")
        break
    end
end

-- --- 2. MINING THE AREA X BY Y (HEIGHT 3) ---
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Mining area at the bottom...")

for lane = 1, width do
    for step = 1, length - 1 do
        if not checkAndRefuel() then return end
        if step % 5 == 0 or isInventoryFull() then clearTrash() end
        if isInventoryFull() then term.setCursorPos(1, statusLine + 1) print("Error: Inv full!") return end
        if not digStep() then term.setCursorPos(1, statusLine + 1) print("Error: Blocked!") return end
        
        term.setCursorPos(1, statusLine)
        term.clearLine()
        write("Lane: " .. lane .. "/" .. width .. " | Step: " .. step + 1 .. "/" .. length)
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

-- --- 3. RETURNING TO THE VERTICAL SHAFT ---
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Returning to shaft...")

while curDir ~= 2 do turnRightTrack() end
while curY > 0 do
    if not checkAndRefuel() then break end
    while turtle.detect() do turtle.dig() sleep(0.5) end
    if turtle.forward() then curY = curY - 1 else break end
end

while curDir ~= 3 do turnRightTrack() end
while curX > 0 do
    if not checkAndRefuel() then break end
    while turtle.detect() do turtle.dig() sleep(0.5) end
    if turtle.forward() then curX = curX - 1 else break end
end

while curDir ~= 0 do turnRightTrack() end

-- --- 4. GOING UP TO SURFACE ---
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Going up to surface...")

while blocksDown > 0 do
    if not checkAndRefuel() then break end
    while turtle.detectUp() do turtle.digUp() sleep(0.5) end
    if turtle.up() then
        blocksDown = blocksDown - 1
        term.setCursorPos(1, statusLine + 1)
        term.clearLine()
        write("Blocks left to climb: " .. blocksDown)
    else
        print("\nError: Cannot move up. Path blocked!")
        break
    end
end

-- Финальный разворот в сторону первоначального взгляда
turtle.turnRight()
turtle.turnRight()

term.clear()
term.setCursorPos(1, 1)
print("=== MISSION COMPLETED ===")
print("Area cleared at depth successfully!")
print("Fuel left: " .. turtle.getFuelLevel())

