-- Request parameters from user
print("How many blocks down to go?")
write("Enter depth: ")
local depthInput = read()
local depth = tonumber(depthInput)

print("How many blocks to dig forward?")
write("Enter length: ")
local lengthInput = read()
local length = tonumber(lengthInput)

if not depth or depth <= 0 or not length or length <= 0 then
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
print("=== DEEP MINING SYSTEM ===")
print("Target depth: " .. depth .. " blocks down")
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

-- --- 1. GOING DOWN ---
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

-- --- 2. DIGGING THE TUNNEL ---
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Digging tunnel (" .. length .. " blocks)")

local actualLength = 0
for i = 1, length do
    if not checkAndRefuel() then break end
    if i % 5 == 0 then clearTrash() end

    while turtle.detect() do turtle.dig() sleep(0.5) end
    if not turtle.forward() then 
        print("\nTunnel blocked! Stopping here.") 
        break 
    end
    actualLength = actualLength + 1

    while turtle.detectUp() do turtle.digUp() sleep(0.5) end
    if turtle.detectDown() then turtle.digDown() end

    term.setCursorPos(1, statusLine + 1)
    term.clearLine()
    write("Progress: " .. i .. "/" .. length .. " | Fuel: " .. turtle.getFuelLevel())
end

clearTrash()

-- --- 3. RETURNING BACK TO SHAFT ---
term.setCursorPos(1, statusLine)
term.clearLine()
print("Status: Returning to shaft...")

turtle.turnRight()
turtle.turnRight()

for i = 1, actualLength do
    if not checkAndRefuel() then break end
    while turtle.detect() do turtle.dig() sleep(0.5) end
    if not turtle.forward() then break end
end

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

-- Разворачиваемся в исходное направление, в котором черепашку ставили изначально
turtle.turnRight()
turtle.turnRight()

term.clear()
term.setCursorPos(1, 1)
print("=== MISSION COMPLETED ===")
print("Returned safely to the top.")
print("Fuel left: " .. turtle.getFuelLevel())
