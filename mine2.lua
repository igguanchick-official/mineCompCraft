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

-- Automatic refuel function
local function checkAndRefuel()
    if turtle.getFuelLevel() >= MIN_FUEL then return true end
    print("Low fuel. Searching for coal...")
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then
            turtle.refuel()
            print("Refueled! Current fuel: " .. turtle.getFuelLevel())
            if turtle.getFuelLevel() >= MIN_FUEL then
                turtle.select(1)
                return true
            end
        end
    end
    turtle.select(1)
    return turtle.getFuelLevel() > 0
end

-- Check inventory space
local function isInventoryFull()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then return false end
    end
    return true
end

-- Digging single step function (forward, up, down)
local function digStep()
    while turtle.detect() do
        turtle.dig()
        sleep(0.5)
    end
    if not turtle.forward() then
        return false
    end
    while turtle.detectUp() do
        turtle.digUp()
        sleep(0.5)
    end
    if turtle.detectDown() then
        turtle.digDown()
    end
    return true
end

-- --- MAIN LOGIC ---

-- Way there (First tunnel line)
print("\n[1/2] Digging forward...")
for i = 1, length do
    if not checkAndRefuel() then print("CRITICAL ERROR: Out of fuel!") return end
    if isInventoryFull() then print("Error: Inventory is full!") return end
    
    if not digStep() then
        print("Error: Path blocked on forward way.")
        break
    end
    print("Forward path: " .. i .. "/" .. length)
end

-- Turn right, move 1 block, turn right
print("\nTurning around to the right...")
turtle.turnRight()

-- Clear the block to the side and step into the next lane
while turtle.detect() do
    turtle.dig()
    sleep(0.5)
end
if not turtle.forward() then
    print("Error: Cannot switch lanes. Blocked.")
    return
end

-- Clear top/bottom at the pivot point
while turtle.detectUp() do turtle.digUp() sleep(0.5) end
if turtle.detectDown() then turtle.digDown() end

turtle.turnRight()

-- Way back (Second tunnel line)
print("\n[2/2] Digging back to base...")
for i = 1, length do
    if not checkAndRefuel() then print("CRITICAL ERROR: Out of fuel!") return end
    if isInventoryFull() then print("Error: Inventory is full!") return end
    
    if not digStep() then
        print("Error: Path blocked on way back.")
        break
    end
    print("Return path: " .. i .. "/" .. length)
end

print("\nJob completed! Returned to base line.")
