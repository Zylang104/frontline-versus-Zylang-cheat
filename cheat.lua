local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local markedModels = {} -- Table to store models currently being tracked (for pulsing)

-- Configuration
local TARGET_MODEL_NAME = "SoldierModels" 

local MARKER_SIZE = UDim2.new(0, 15, 0, 15) -- Size of the dot in pixels (15x15 for a visible circle)
local MARKER_COLOR = Color3.fromRGB(0, 255, 0)   -- Constant Bright Green
local PULSE_SPEED = 2.5 -- Controls the speed of the pulse. Lower = Slower

-- 2. Part Highlight Configuration (The actual glow effect)
local GLOW_COLOR = Color3.fromRGB(255, 255, 0)       -- Bright Yellow glow
local GLOW_FILL_TRANSPARENCY = 0.6                  -- How transparent the interior fill is
local GLOW_OUTLINE_TRANSPARENCY = 0.0               -- How transparent the outline is

-- Function to remove the effects (Glow and Marker) from a model
local function cleanupModelEffects(targetModel)
    -- Remove the Highlight (Glow) from all descendants
    for _, descendant in ipairs(targetModel:GetDescendants()) do
        local highlight = descendant:FindFirstChildOfClass("Highlight")
        if highlight then
            highlight:Destroy()
        end
    end

    -- Remove the Marker (BillboardGui) from the PrimaryPart
    local primaryPart = targetModel.PrimaryPart
    if primaryPart then
        local attachment = primaryPart:FindFirstChild("VisibilityMarkerAttachment")
        if attachment then
            attachment:Destroy()
        end
    end
end

-- Function to create and attach the Highlight glow
local function applyPartGlow(basePart)
    if not (basePart:IsA("BasePart")) or basePart:FindFirstChildOfClass("Highlight") then return end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = GLOW_COLOR
    highlight.OutlineColor = GLOW_COLOR
    highlight.FillTransparency = GLOW_FILL_TRANSPARENCY
    highlight.OutlineTransparency = GLOW_OUTLINE_TRANSPARENCY
    highlight.Parent = basePart
end


-- Function to create and attach the single see-through dot marker
local function createModelMarker(targetModel)
    local primaryPart = targetModel.PrimaryPart 
    
    if not primaryPart then
        warn("Model '" .. targetModel.Name .. "' is missing a PrimaryPart to attach the marker to.")
        return nil
    end
    
    if primaryPart:FindFirstChild("VisibilityMarkerAttachment") then return nil end

    -- 1. Create an Attachment to hold the marker (anchors the GUI to the 3D space)
    local attachment = Instance.new("Attachment")
    attachment.Name = "VisibilityMarkerAttachment"
    attachment.Position = Vector3.new(0, 1.5, 0) -- 1.5 studs above the center of the PrimaryPart
    attachment.Parent = primaryPart 

    -- 2. Create the BillboardGui (the container for the 2D dot marker)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "VisibilityMarker"
    billboardGui.Size = MARKER_SIZE
    billboardGui.AlwaysOnTop = true -- Makes it visible through walls!
    billboardGui.LightInfluence = 0 
    billboardGui.MaxDistance = 200 -- Renders the dot up to 200 studs away!

    -- 3. Create the actual visual element (the dot Frame)
    local markerFrame = Instance.new("Frame")
    markerFrame.Size = UDim2.new(1, 0, 1, 0)
    markerFrame.BackgroundColor3 = MARKER_COLOR -- Constant Green color
    markerFrame.BorderSizePixel = 0
    markerFrame.BackgroundTransparency = 0.1 -- Initial transparency
    
    -- Add UICorner to make it a rounded dot
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0) -- Full radius for a perfect circle/dot
    corner.Parent = markerFrame
    
    markerFrame.Parent = billboardGui
    billboardGui.Parent = attachment
    
    return markerFrame, billboardGui -- Return both the frame and the gui for tracking
end

-- Function to mark a new model
local function markModel(model)
    if not model:IsA("Model") or model.PrimaryPart == nil then return end

    -- Apply the single THROUGH-WALL DOT MARKER and get the frame and gui references
    local markerFrame, billboardGui = createModelMarker(model) 
    
    -- Apply the GLOW to all parts
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            applyPartGlow(descendant)
        end
    end
    
    -- Only track if we successfully created a marker (needs PrimaryPart)
    if markerFrame and billboardGui then
        -- Store the markerFrame for pulsing and the model itself
        markedModels[model] = {frame = markerFrame} 
        print("Marked new model: " .. model.Name)
    end
end

-- Function to unmark a model
local function unmarkModel(model)
    if markedModels[model] then
        cleanupModelEffects(model)
        markedModels[model] = nil -- Remove from tracking table
        print("Unmarked model: " .. model.Name)
    end
end

-- Event handling for new models appearing
local function onChildAdded(child)
    if child:IsA("Model") then
        markModel(child)
    end
end

-- Event handling for models disappearing
local function onChildRemoved(child)
    if child:IsA("Model") then
        unmarkModel(child)
    end
end


----------------------------------------------------------------------------------------------------
--                                         MAIN SCRIPT
----------------------------------------------------------------------------------------------------

-- Wait for the main container model to load in the Workspace
local MainContainer = Workspace:WaitForChild(TARGET_MODEL_NAME, 10)

if MainContainer and MainContainer:IsA("Model") then
    print("--- Found Target Model: " .. TARGET_MODEL_NAME .. ". Starting dynamic highlighting. ---")
    
    -- Connect listeners for dynamic updating
    MainContainer.ChildAdded:Connect(onChildAdded)
    MainContainer.ChildRemoved:Connect(onChildRemoved)
    
    -- Process existing models immediately when the script starts
    for _, child in ipairs(MainContainer:GetChildren()) do
        onChildAdded(child)
    end
    
    -- Start the continuous update loop for slow GUI pulse
    RunService.Heartbeat:Connect(function()
        local currentTime = os.clock()
        
        -- Loop through the table of currently tracked models
        for model, markerData in pairs(markedModels) do
            local primaryPart = model.PrimaryPart
            
            -- Re-check if the model is still valid
            if primaryPart and primaryPart.Parent == model then
                -- Implement slow pulsing effect on the marker's transparency
                -- Using math.sin to create a smooth, repeating value between 0 and 1
                local pulse = math.abs(math.sin(currentTime * PULSE_SPEED))
                
                -- Map the pulse (0 to 1) to a transparency range (faint 0.6 to bright 0.1)
                local minTrans = 0.1
                local maxTrans = 0.6
                -- Interpolate the transparency: when pulse is low (0), trans is max (0.6); when pulse is high (1), trans is min (0.1)
                local newTransparency = maxTrans - (maxTrans - minTrans) * pulse
                
                -- Update the marker's transparency for the pulsing effect
                markerData.frame.BackgroundTransparency = newTransparency
                
            else
                -- If the model is somehow invalid or its primary part is gone, unmark it
                unmarkModel(model)
            end
        end
    end)
    
else
    warn("ERROR: Could not find Model named '" .. TARGET_MODEL_NAME .. "' in the Workspace after 10 seconds. Marker script terminated.")
end
