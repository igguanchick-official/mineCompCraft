-- Request tunnel length from the user
print("How many blocks to dig?")
write("Enter number: ")
local input = read()
local length = tonumber(input)

-- Check for correct input
if not length or length <= 0 then
    print("Error: Please enter a valid number greater than 0!")
    return
end

-- Minimum fuel level before refuel triggers
local MIN_FUEL = 100 

print("\nStarting tunnel digging, length: " .. length .. "...")

-- Automatic refuel function
local function checkAndRefuel()
    if turtle.getFuelLevel() >= MIN_FUEL then
        return true
    end

    print("Low fuel. Searching for coal...")
    
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then -- Check if item is fuel
            turtle.refuel()     -- Consume the whole stack
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

-- Check if inventory is full function
local function isInventoryFull()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            return false
        end
    end
    return true
end

-- Main movement and digging loop
for i = 1, length do
    -- 1. Check and replenish fuel
    if not checkAndRefuel() then
        print("CRITICAL ERROR: Out of fuel!")
        break
    end

    -- 2. Check inventory space
    if isInventoryFull() then
        print("Error: Inventory is full!")
        break
    end

    -- 3. Clear path in front and step forward (Middle layer)
    while turtle.detect() do
        turtle.dig()
        sleep(0.5) -- Wait for gravel/sand to fall
    end
    
    if not turtle.forward() then
        print("Error: Path blocked. Cannot move forward.")
        break
    end

    -- 4. Dig the upper block (Ceiling)
    while turtle.detectUp() do
        turtle.digUp()
        sleep(0.5) -- Wait if gravel falls from above
    end

    -- 5. Dig the lower block (Floor)
    if turtle.detectDown() then
        turtle.digDown()
    end

    print("Blocks mined: " .. i .. "/" .. length)
end

print("Job completed!")
