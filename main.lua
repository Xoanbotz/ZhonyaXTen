--[[
=========================================================
  CP EXPLOIT - AUTO REFRESH
  CP baru muncul otomatis pas lo unlock
=========================================================
]]

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- ============================================================
-- STATE
-- ============================================================
local noclipConn = nil
local autoJumpConn = nil
local flyConn = nil
local bodyVel = nil
local flySpeed = 50

local knownCPs = {}     -- CP yang udah ke-scan: [num] = {name, part}
local cpButtons = {}    -- Tombol yang udah dibuat: [num] = button

-- ============================================================
-- HELPER
-- ============================================================
local function getHRP()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    return LP.Character and LP.Character:FindFirstChild("Humanoid")
end

-- ============================================================
-- SCAN CP (REKURSIF, MULTI FORMAT)
-- ============================================================
local function scanAllCPs()
    local found = {}
    
    local function scanContainer(container)
        if not container then return end
        for _, obj in ipairs(container:GetChildren()) do
            -- Match CP1, CP_1, CP01, CP 1
            local nameUpper = string.upper(obj.Name)
            local numMatch = nameUpper:match("CP[%s_]*0*(%d+)")
            
            if numMatch then
                local num = tonumber(numMatch)
                local part = obj:FindFirstChildWhichIsA("BasePart", true)
                
                if part then
                    found[num] = {
                        name = obj.Name,
                        model = obj,
                        part = part,
                    }
                end
            end
        end
    end
    
    -- Cek folder Checkpoints
    local cpFolder = Workspace:FindFirstChild("Checkpoints")
    if cpFolder then
        scanContainer(cpFolder)
    end
    
    -- Cek juga di Workspace langsung (kalo ada CP yang di root)
    scanContainer(Workspace)
    
    return found
end

-- ============================================================
-- TELEPORT
-- ============================================================
local function tpToCP(cp)
    local char = LP.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not cp.part or not cp.part.Parent then return false end
    
    hrp.CFrame = CFrame.new(cp.part.Position + Vector3.new(0, 5, 0))
    hrp.Velocity = Vector3.zero
    
    task.wait(0.2)
    pcall(function()
        firetouchinterest(hrp, cp.part, 0)
        task.wait(0.1)
        firetouchinterest(hrp, cp.part, 1)
    end)
    
    print("[TP] " .. cp.name)
    return true
end

-- ============================================================
-- NOCLIP / FLY
-- ============================================================
local function setNoclip(state)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            local c = LP.Character
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    else
        local c = LP.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

local function setFly(state)
    if flyConn then
        flyConn:Disconnect()
        if flyConn.InputBegan then flyConn.InputBegan:Disconnect() end
        if flyConn.InputEnded then flyConn.InputEnded:Disconnect() end
        flyConn = nil
    end
    if bodyVel then bodyVel:Destroy(); bodyVel = nil end
    if not state then return end
    
    local hrp = getHRP()
    if not hrp then return end
    
    bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyVel.Velocity = Vector3.zero
    bodyVel.Parent = hrp
    
    local pressed = {}
    
    local inputBegan = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        pressed[input.KeyCode] = true
    end)
    
    local inputEnded = UserInputService.InputEnded:Connect(function(input)
        pressed[input.KeyCode] = false
    end)
    
    flyConn = RunService.Heartbeat:Connect(function()
        local h = getHRP()
        if not h or not bodyVel then return end
        
        local cam = Workspace.CurrentCamera
        local dir = Vector3.zero
        
        if pressed[Enum.KeyCode.W] then dir += cam.CFrame.LookVector end
        if pressed[Enum.KeyCode.S] then dir -= cam.CFrame.LookVector end
        if pressed[Enum.KeyCode.A] then dir -= cam.CFrame.RightVector end
        if pressed[Enum.KeyCode.D] then dir += cam.CFrame.RightVector end
        if pressed[Enum.KeyCode.Space] then dir += Vector3.new(0, 1, 0) end
        if pressed[Enum.KeyCode.LeftShift] then dir -= Vector3.new(0, 1, 0) end
        
        if dir.Magnitude > 0 then dir = dir.Unit end
        bodyVel.Velocity = dir * flySpeed
    end)
    
    flyConn.InputBegan = inputBegan
    flyConn.InputEnded = inputEnded
end

-- ============================================================
-- CREATE WINDOW
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "CP Exploit",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Auto Refresh",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- Resize window
task.delay(0.2, function()
    local gui = PlayerGui:FindFirstChild("Rayfield")
        or game:GetService("CoreGui"):FindFirstChild("Rayfield")
    if gui then
        for _, obj in ipairs(gui:GetDescendants()) do
            if obj:IsA("Frame") and (obj.Name == "Main" or obj.Name == "Root") then
                pcall(function()
                    obj.Size = UDim2.new(0, 340, 0, 280)
                end)
            end
        end
    end
end)

-- ============================================================
-- TAB TELEPORT (AUTO REFRESH)
-- ============================================================
local TabTP = Window:CreateTab("Teleport", 4483362458)

-- Label status
local statusLabel = TabTP:CreateLabel("Scanning...")

-- Container buat tombol CP (biar bisa update)
local cpSection = TabTP:CreateSection("Checkpoints")

-- ============================================================
-- FUNGSI UPDATE BUTTONS
-- ============================================================
local function updateCPButtons()
    local currentCPs = scanAllCPs()
    
    -- Hapus tombol yang CP-nya udah gak ada (kalo ada)
    for num, btn in pairs(cpButtons) do
        if not currentCPs[num] then
            -- Skip, jarang CP ilang
        end
    end
    
    -- Tambah tombol baru buat CP yang belum ada tombolnya
    for num, cp in pairs(currentCPs) do
        if not knownCPs[num] then
            knownCPs[num] = cp
            print("[NEW] CP" .. num .. " muncul: " .. cp.name)
            
            local newBtn = TabTP:CreateButton({
                Name = "-> " .. cp.name,
                Callback = function()
                    local latest = knownCPs[num]
                    if latest and tpToCP(latest) then
                        Rayfield:Notify({
                            Title = "Teleport",
                            Content = latest.name .. " triggered",
                            Duration = 2,
                        })
                    else
                        Rayfield:Notify({
                            Title = "Error",
                            Content = "CP" .. num .. " udah gak ada",
                            Duration = 2,
                        })
                    end
                end,
            })
            cpButtons[num] = newBtn
        end
    end
    
    -- Update status
    local count = 0
    for _ in pairs(knownCPs) do count = count + 1 end
    pcall(function()
        statusLabel:Set("Detected: " .. count .. " CP")
    end)
    
    return count
end

-- Initial scan
updateCPButtons()

-- ============================================================
-- AUTO REFRESH LOOP
-- ============================================================
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local before = 0
            for _ in pairs(knownCPs) do before = before + 1 end
            
            updateCPButtons()
            
            local after = 0
            for _ in pairs(knownCPs) do after = after + 1 end
            
            if after > before then
                Rayfield:Notify({
                    Title = "CP Baru Terdeteksi",
                    Content = "Total: " .. after .. " CP",
                    Duration = 3,
                })
            end
        end)
    end
end)

-- ============================================================
-- TAB MOVEMENT
-- ============================================================
local TabMove = Window:CreateTab("Movement", 4483362458)

TabMove:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 500},
    Increment = 1,
    CurrentValue = 50,
    Flag = "WalkSpeed",
    Callback = function(v)
        local h = getHum()
        if h then h.WalkSpeed = v end
    end,
})

TabMove:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 1,
    CurrentValue = 100,
    Flag = "JumpPower",
    Callback = function(v)
        local h = getHum()
        if h then
            h.JumpPower = v
            h.UseJumpPower = true
        end
    end,
})

TabMove:CreateToggle({
    Name = "Auto Jump",
    CurrentValue = false,
    Flag = "AutoJump",
    Callback = function(v)
        if autoJumpConn then autoJumpConn:Disconnect(); autoJumpConn = nil end
        if v then
            autoJumpConn = RunService.Heartbeat:Connect(function()
                local h = getHum()
                if h and h:GetState() ~= Enum.HumanoidStateType.Jumping then
                    h.Jump = true
                end
            end)
        end
    end,
})

TabMove:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v) setNoclip(v) end,
})

TabMove:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(v) setFly(v) end,
})

TabMove:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 1,
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(v) flySpeed = v end,
})

-- ============================================================
-- TAB MANUAL
-- ============================================================
local TabManual = Window:CreateTab("Manual", 4483362458)

local xInput = TabManual:CreateInput({
    Name = "X",
    PlaceholderText = "0",
    RemoveTextAfterFocusLost = false,
    Callback = function() end,
})

local yInput = TabManual:CreateInput({
    Name = "Y",
    PlaceholderText = "100",
    RemoveTextAfterFocusLost = false,
    Callback = function() end,
})

local zInput = TabManual:CreateInput({
    Name = "Z",
    PlaceholderText = "0",
    RemoveTextAfterFocusLost = false,
    Callback = function() end,
})

TabManual:CreateButton({
    Name = "TP ke X, Y, Z",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        local x = tonumber(xInput) or 0
        local y = tonumber(yInput) or 100
        local z = tonumber(zInput) or 0
        hrp.CFrame = CFrame.new(x, y, z)
        Rayfield:Notify({
            Title = "Teleport",
            Content = string.format("(%.0f, %.0f, %.0f)", x, y, z),
            Duration = 2,
        })
    end,
})

-- ============================================================
-- TAB INFO
-- ============================================================
local TabInfo = Window:CreateTab("Info", 4483362458)

TabInfo:CreateLabel("Place ID: " .. tostring(game.PlaceId))
TabInfo:CreateLabel("Character: " .. (LP.Character and LP.Character.Name or "Not loaded"))
TabInfo:CreateLabel("Scanner: Auto-refresh 2s")

TabInfo:CreateButton({
    Name = "Refresh Scan Sekarang",
    Callback = function()
        local count = updateCPButtons()
        Rayfield:Notify({
            Title = "Refresh",
            Content = count .. " CP terdeteksi",
            Duration = 2,
        })
    end,
})

-- ============================================================
-- FLOATING BUBBLE
-- ============================================================
local oldBubble = PlayerGui:FindFirstChild("CPBubble")
if oldBubble then oldBubble:Destroy() end

local BubbleGui = Instance.new("ScreenGui")
BubbleGui.Name = "CPBubble"
BubbleGui.ResetOnSpawn = false
BubbleGui.DisplayOrder = 999
BubbleGui.Parent = PlayerGui

local Bubble = Instance.new("TextButton")
Bubble.Size = UDim2.new(0, 50, 0, 50)
Bubble.Position = UDim2.new(0, 20, 0.5, -25)
Bubble.BackgroundColor3 = Color3.fromRGB(180, 30, 255)
Bubble.Text = "CP"
Bubble.TextColor3 = Color3.new(1, 1, 1)
Bubble.Font = Enum.Font.GothamBold
Bubble.TextSize = 16
Bubble.BorderSizePixel = 0
Bubble.AutoButtonColor = false
Bubble.Visible = false
Bubble.Parent = BubbleGui

local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(1, 0)
bc.Parent = Bubble

local bs = Instance.new("UIStroke")
bs.Color = Color3.fromRGB(220, 100, 255)
bs.Thickness = 2
bs.Parent = Bubble

local dragging, dragStart, startPos = false, nil, nil
Bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Bubble.Position
        Bubble:SetAttribute("Dragged", false)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 3 then
            Bubble:SetAttribute("Dragged", true)
        end
        Bubble.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

local rayfieldVisible = true

local function setRayfieldVisible(visible)
    local gui = PlayerGui:FindFirstChild("Rayfield")
        or game:GetService("CoreGui"):FindFirstChild("Rayfield")
    if gui then
        if gui:IsA("ScreenGui") then
            gui.Enabled = visible
        else
            for _, obj in ipairs(gui:GetChildren()) do
                if obj:IsA("Frame") then
                    obj.Visible = visible
                end
            end
        end
    end
end

Bubble.MouseButton1Click:Connect(function()
    if Bubble:GetAttribute("Dragged") then return end
    rayfieldVisible = not rayfieldVisible
    setRayfieldVisible(rayfieldVisible)
    Bubble.Visible = not rayfieldVisible
end)

task.spawn(function()
    while task.wait(0.5) do
        local gui = PlayerGui:FindFirstChild("Rayfield")
            or game:GetService("CoreGui"):FindFirstChild("Rayfield")
        if gui then
            local anyVisible = false
            if gui:IsA("ScreenGui") then
                anyVisible = gui.Enabled
            else
                for _, obj in ipairs(gui:GetChildren()) do
                    if obj:IsA("Frame") and obj.Visible then
                        anyVisible = true
                        break
                    end
                end
            end
            Bubble.Visible = not anyVisible
            rayfieldVisible = anyVisible
        end
    end
end)

-- ============================================================
-- NOTIF
-- ============================================================
local initCount = 0
for _ in pairs(knownCPs) do initCount = initCount + 1 end

Rayfield:Notify({
    Title = "CP Exploit",
    Content = initCount .. " CP terdeteksi. Auto-refresh aktif.",
    Duration = 4,
})
