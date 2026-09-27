-- Request dimensions from the user
print("Enter Width (X - lanes to the right):")
local inputX = read()
local width = tonumber(inputX)

print("Enter Length (Y - blocks forward):")
local inputY = read()
local length = tonumber(inputY)

if not width or width <= 0 or not length or length <= 0 then
    print("Error: Please enter valid numbers greater than 0!")
    return
end

local MIN_FUEL = 100 

-- Trash list for auto-drop
local trashItems = {
    ["minecraft:cobblestone"] = true,
    ["minecraft:stone"] = true,
    ["minecraft:dirt"] = true,
    ["minecraft:gravel"] = true,
    ["minecraft:andesite"] = true,
    ["minecraft:diorite"] = true,
    ["minecraft:granite"] = true,
    ["minecraft:deepslate"] = true,
    ["minecraft:cobbled_deepslate"] = true,
    ["minecraft:tuff"] = true
}

term.clear()
term.setCursorPos(1, 1)
print("=== AREA MINING SYSTEM ===")
print("Area: " .. width .. "x" .. length .. " (Height: 3)")
print("----------------------------")

local statusLine = 4

-- Виртуальные координаты для возврата домой
local curX = 0  -- Смещение вправо
local curY = 0  -- Смещение вперед
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
    write("Status: Searching for coal...")
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then
            turtle.refuel()
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
    term.setCursorPos(1, statusLine + 1)
    term.clearLine()
    write("Status: Clearing trash...")
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and trashItems[item.name] then
            turtle.select(slot)
            turtle.dropDown()
        end
    end
    turtle.select(1)
    term.setCursorPos(1, statusLine + 1)
    term.clearLine()
end

local function isInventoryFull()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then return false end
    end
    return true
end

-- Dig one block forward and update tracking positions
local function digStep()
    while turtle.detect() do turtle.dig() sleep(0.5) end
    if not turtle.forward() then return false end
    
    -- Обновляем координаты на основе текущего взгляда
    if curDir == 0 then curY = curY + 1
    elseif curDir == 1 then curX = curX + 1
    elseif curDir == 2 then curY = curY - 1
    elseif curDir == 3 then curX = curX - 1
    end

    while turtle.detectUp() do turtle.digUp() sleep(0.5) end
    if turtle.detectDown() then turtle.digDown() end
    return true
end

-- --- MAIN MINING LOGIC ---

for lane = 1, width do
    for step = 1, length - 1 do
        if not checkAndRefuel() then return end
        if step % 5 == 0 or isInventoryFull() then clearTrash() end
        
        if isInventoryFull() then
            term.setCursorPos(1, statusLine + 1)
            print("Error: Inventory full after trash clear!")
            return
        end
        
        if not digStep() then
            term.setCursorPos(1, statusLine + 1)
            print("Error: Path blocked!")
            return
        end
        
        term.setCursorPos(1, statusLine)
        term.clearLine()
        write("Lane: " .. lane .. "/" .. width .. " | Step: " .. step + 1 .. "/" .. length .. " | Fuel: " .. turtle.getFuelLevel())
    end

    if lane < width then
        if lane % 2 == 1 then
            turnRightTrack()
            if not digStep() then print("Error changing lane.") return end
            turnRightTrack()
        else
            turnLeftTrack()
            if not digStep() then print("Error changing lane.") return end
            turnLeftTrack()
        end
        clearTrash()
    end
end

clearTrash()

-- --- HOMECOMING LOGIC (Возврат домой) ---
term.setCursorPos(1, statusLine + 1)
term.clearLine()
print("Status: Returning to start position...")

-- Поворачиваемся лицом назад (к нулевому Y)
while curDir ~= 2 do
    turnRightTrack()
end

-- Летим назад по оси Y до упора
while curY > 0 do
    if not checkAndRefuel() then break end
    -- Если на пути домой упал гравий/песок — расчищаем его
    while turtle.detect() do turtle.dig() sleep(0.5) end
    if turtle.forward() then curY = curY - 1 else break end
end

-- Поворачиваемся налево (к нулевому X)
while curDir ~= 3 do
    turnRightTrack()
end

-- Летим влево по оси X до упора
while curX > 0 do
    if not checkAndRefuel() then break end
    while turtle.detect() do turtle.dig() sleep(0.5) end
    if turtle.forward() then curX = curX - 1 else break end
end

-- Разворачиваем черепашку в начальное положение (лицом вперед, Dir = 0)
while curDir ~= 0 do
    turnRightTrack()
end

term.setCursorPos(1, statusLine + 2)
print("Job completed! Back at start position.")
