print("How many blocks to dig?")
write("Enter number: ")
local input = read()
local length = tonumber(input)

if not length or length <= 0 then
    print("Error: Please enter a valid number greater than 0!")
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
print("=== 2-WAY TUNNEL SYSTEM ===")
print("Target length per lane: " .. length)
print("----------------------------")

local statusLine = 4

local function checkAndRefuel()
    if turtle.getFuelLevel() >= MIN_FUEL then return true end
    term.setCursorPos(1, statusLine + 1)
    term.clearLine()
    write("Status: Searching for coal...")
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then
            turtle.refuel(5) -- Берёт строго по 5 штук из стака
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
    write("Status: Clearing trash items...")
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
    for i = 1, 16 do if turtle.getItemCount(i) == 0 then return false end end
    return true
end

local function digStep()
    while turtle.detect() do turtle.dig() sleep(0.5) end
    if not turtle.forward() then return false end
    while turtle.detectUp() do turtle.digUp() sleep(0.5) end
    if turtle.detectDown() then turtle.digDown() end
    return true
end

-- Way there
for i = 1, length do
    if not checkAndRefuel() then return end
    if i % 5 == 0 or isInventoryFull() then clearTrash() end
    if isInventoryFull() then term.setCursorPos(1, statusLine + 1) print("Error: Inv full!") return end
    if not digStep() then term.setCursorPos(1, statusLine + 1) print("Error forward path!") return end
    
    term.setCursorPos(1, statusLine)
    term.clearLine()
    write("Lane 1/2: " .. i .. "/" .. length .. " | Fuel: " .. turtle.getFuelLevel())
end

-- Turning around
term.setCursorPos(1, statusLine + 1)
term.clearLine()
write("Status: Switching lanes...")
turtle.turnRight()
while turtle.detect() do turtle.dig() sleep(0.5) end
if not turtle.forward() then return end
while turtle.detectUp() do turtle.digUp() sleep(0.5) end
if turtle.detectDown() then turtle.digDown() end
turtle.turnRight()
term.setCursorPos(1, statusLine + 1)
term.clearLine()

-- Way back
for i = 1, length do
    if not checkAndRefuel() then return end
    if i % 5 == 0 or isInventoryFull() then clearTrash() end
    if isInventoryFull() then term.setCursorPos(1, statusLine + 1) print("Error: Inv full!") return end
    if not digStep() then term.setCursorPos(1, statusLine + 1) print("Error return path!") return end
    
    term.setCursorPos(1, statusLine)
    term.clearLine()
    write("Lane 2/2: " .. i .. "/" .. length .. " | Fuel: " .. turtle.getFuelLevel())
end

clearTrash()
term.setCursorPos(1, statusLine + 2)
print("Job completed! Returned to base line.")
