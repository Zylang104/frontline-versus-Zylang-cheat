-- Field of View (FOV) angle in degrees
local fovAngle = 25

-- Offset to move the mouse in a different direction
local offsetX = -20  -- Adjust this value as needed
local offsetY = 5  -- Adjust this value as needed

-- Function to move the mouse to the part's position with offset
local function moveMouseToPart(part)
    -- Get the screen position of the part
    local screenPosition = game.Workspace.CurrentCamera:WorldToScreenPoint(part.Position)

    -- Get the current mouse position
    local mouse = game.Players.LocalPlayer:GetMouse()
    local currentMousePosition = Vector2.new(mouse.X, mouse.Y)

    -- Calculate the target position with offset
    local targetPosition = Vector2.new(
        screenPosition.X + offsetX,
        screenPosition.Y + offsetY
    )

    -- Print debug information
    print("Screen Position:", screenPosition)
    print("Current Mouse Position:", currentMousePosition)
    print("Target Position:", targetPosition)

    -- Calculate the relative movement needed
    local relativeMovement = Vector2.new(targetPosition.X - currentMousePosition.X, targetPosition.Y - currentMousePosition.Y)

    -- Print debug information
    print("Relative Movement:", relativeMovement)

    -- Move the mouse relative to its current position
    mousemoverel(relativeMovement.X, relativeMovement.Y)
end

-- Function to calculate the distance between two points
local function calculateDistance(point1, point2)
    return (point1 - point2).magnitude
end

-- Function to check if a part is within the FOV
local function isWithinFOV(part, camera)
    local direction = (part.Position - camera.CFrame.Position).unit
    local dotProduct = direction:Dot(camera.CFrame.LookVector)
    local angle = math.acos(dotProduct) * (180 / math.pi)
    return angle <= fovAngle
end

-- Function to highlight a part
local function highlightPart(part, color)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = color
    highlight.OutlineTransparency = 0
    highlight.Adornee = part
    highlight.Parent = game:GetService("Lighting")
end

-- Recursive function to find the closest part to track, excluding models named "1"
local function findClosestPartToTrack(model, camera)
    local closestPart = nil
    local closestDistance = math.huge

    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("Part") and isWithinFOV(child, camera) then
            local distance = calculateDistance(camera.CFrame.Position, child.Position)
            if distance < closestDistance then
                closestDistance = distance
                closestPart = child
            end
        elseif child:IsA("Model") and child.Name ~= "1" then
            local part = findClosestPartToTrack(child, camera)
            if part then
                local distance = calculateDistance(camera.CFrame.Position, part.Position)
                if distance < closestDistance then
                    closestDistance = distance
                    closestPart = part
                end
            end
        end
    end

    return closestPart
end

-- Create a test model called "10" and add a part to it
local testModel = Instance.new("Model")
testModel.Name = "10"
local testPart = Instance.new("Part")
testPart.Size = Vector3.new(4, 1, 2)
testPart.Position = Vector3.new(0, 5, 0)
testPart.Parent = testModel
testModel.Parent = game.Workspace

-- Main loop to continuously update the mouse position
while true do
    -- Check if the left ALT key is held down
    if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftAlt) then
        local camera = game.Workspace.CurrentCamera
        local partToTrack = findClosestPartToTrack(game.Workspace.SoldierModelsFollowers, camera)
        if partToTrack then
            -- Check for "friendly_marker" in the same child
            local isFriendly = false
            for _, child in ipairs(partToTrack.Parent:GetChildren()) do
                if child.Name == "friendly_marker" then
                    isFriendly = true
                    break
                end
            end

            -- Set transparency and highlight color based on the presence of "friendly_marker"
            partToTrack.Transparency = 1
            if isFriendly then
                highlightPart(partToTrack, Color3.new(0, 0, 1)) -- Blue highlight
            else
                highlightPart(partToTrack, Color3.new(1, 0, 0)) -- Red highlight
            end

            moveMouseToPart(partToTrack)
        end
    end
    wait(0.001) -- Adjust the wait time for smoother tracking
end
