-- Request tunnel length from the user
print("How many blocks to dig?")
write("Enter number: ")
local input = read()
local length = tonumber(input)

if not length or length <= 0 then
    print("Error: Please enter a valid number greater than 0!")
    return
end

local MIN_FUEL = 100 

-- Очищаем экран перед началом работы для идеальной чистоты
term.clear()
term.setCursorPos(1, 1)
print("=== TUNNEL MINING SYSTEM ===")
print("Target length: " .. length)
print("----------------------------")

-- Запоминаем строчку, на которой будем обновлять статус
local statusLine = 4

local function checkAndRefuel()
    if turtle.getFuelLevel() >= MIN_FUEL then return true end
    
    -- Выводим предупреждение на отдельной строке ниже
    term.setCursorPos(1, statusLine + 1)
    term.clearLine()
    write("Status: Low fuel. Searching for coal...")
    
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then
            turtle.refuel()
            term.setCursorPos(1, statusLine + 1)
            term.clearLine()
            write("Status: Refueled! Fuel: " .. turtle.getFuelLevel())
            sleep(1) -- даем секунду прочесть сообщение
            if turtle.getFuelLevel() >= MIN_FUEL then
                turtle.select(1)
                return true
            end
        end
    end
    turtle.select(1)
    return turtle.getFuelLevel() > 0
end

local function isInventoryFull()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then return false end
    end
    return true
end

for i = 1, length do
    if not checkAndRefuel() then 
        term.setCursorPos(1, statusLine + 1)
        print("CRITICAL ERROR: Out of fuel!") 
        break 
    end
    
    if isInventoryFull() then 
        term.setCursorPos(1, statusLine + 1)
        print("Error: Inventory is full!") 
        break 
    end

    while turtle.detect() do turtle.dig() sleep(0.5) end
    if not turtle.forward() then 
        term.setCursorPos(1, statusLine + 1)
        print("Error: Path blocked!") 
        break 
    end
    
    while turtle.detectUp() do turtle.digUp() sleep(0.5) end
    if turtle.detectDown() then turtle.digDown() end

    -- ЭТА ЧАСТЬ ОБНОВЛЯЕТ СТРОКУ НА ОДНОМ МЕСТЕ
    term.setCursorPos(1, statusLine)
    term.clearLine() -- Стирает старый текст в этой строке
    write("Progress: " .. i .. "/" .. length .. " | Fuel: " .. turtle.getFuelLevel())
end

term.setCursorPos(1, statusLine + 2)
print("Job completed!")
