--[[
=========================================================
  CP EXPLOIT - FULL EDITION
  Merge: CP Teleport 1-25 + Movement + Manual + Bubble
  Author: Kyriel (for ADIEL)
=========================================================
]]

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
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

-- ============================================================
-- HELPER
-- ============================================================
local function getChar()
    return LP.Character or LP.Character:WaitForChild("Humanoid")
end

local function getHRP()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    return LP.Character and LP.Character:FindFirstChild("Humanoid")
end

-- ============================================================
-- CARI CP (multi-lokasi, multi-nama)
-- ============================================================
local function findCP(num)
    local names = {"CP" .. num, "CP_" .. num, "CP0" .. num}
    local folders = {
        Workspace:FindFirstChild("Checkpoints"),
        Workspace,
    }
    
    for _, folder in ipairs(folders) do
        if folder then
            for _, name in ipairs(names) do
                local obj = folder:FindFirstChild(name)
                if obj then
                    local part = obj:FindFirstChild("Part") 
                        or obj:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        return {
                            name = name,
                            model = obj,
                            part = part,
                            fullName = obj:GetFullName(),
                        }
                    end
                end
            end
        end
    end
    return nil
end

-- ============================================================
-- TELEPORT + TRIGGER TOUCH
-- ============================================================
local function tpToCP(cp, trigger)
    local char = LP.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not cp.part then return false end
    
    hrp.CFrame = CFrame.new(cp.part.Position + Vector3.new(0, 5, 0))
    hrp.Velocity = Vector3.zero
    
    if trigger ~= false then
        task.wait(0.2)
        pcall(function()
            firetouchinterest(hrp, cp.part, 0)
            task.wait(0.1)
            firetouchinterest(hrp, cp.part, 1)
        end)
    end
    
    print("[TP] " .. cp.name)
    return true
end

-- ============================================================
-- NOCLIP
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

-- ============================================================
-- FLY
-- ============================================================
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
    LoadingSubtitle = "by ADIEL",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ============================================================
-- RESIZE WINDOW (KECILIN)
-- ============================================================
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
-- TAB 1: TELEPORT CP 1-25
-- ============================================================
local TabTP = Window:CreateTab("Teleport", 4483362458)
TabTP:CreateSection("Checkpoint 1 - 25")

local totalFound = 0
local totalMissing = 0
local missingList = {}

for i = 1, 25 do
    local cp = findCP(i)
    
    if cp then
        totalFound = totalFound + 1
        TabTP:CreateButton({
            Name = "-> " .. cp.name,
            Callback = function()
                if tpToCP(cp) then
                    Rayfield:Notify({
                        Title = "Teleport",
                        Content = cp.name .. " triggered",
                        Duration = 2,
                    })
                else
                    Rayfield:Notify({
                        Title = "Error",
                        Content = "Gagal TP ke " .. cp.name,
                        Duration = 2,
                    })
                end
            end,
        })
    else
        totalMissing = totalMissing + 1
        table.insert(missingList, "CP" .. i)
        TabTP:CreateButton({
            Name = "-> CP" .. i .. " [NOT FOUND]",
            Callback = function()
                Rayfield:Notify({
                    Title = "Not Found",
                    Content = "CP" .. i .. " gak ada",
                    Duration = 2,
                })
            end,
        })
    end
end

-- ============================================================
-- TAB 2: MOVEMENT
-- ============================================================
local TabMove = Window:CreateTab("Movement", 4483362458)

TabMove:CreateSection("Speed")
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

TabMove:CreateSection("Exploits")

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
    Callback = function(v)
        setNoclip(v)
    end,
})

TabMove:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(v)
        setFly(v)
    end,
})

TabMove:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 1,
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(v)
        flySpeed = v
    end,
})

-- ============================================================
-- TAB 3: MANUAL
-- ============================================================
local TabManual = Window:CreateTab("Manual", 4483362458)
TabManual:CreateSection("Koordinat Manual")

local xInput = TabManual:CreateInput({
    Name = "X",
    PlaceholderText = "0",
    RemoveTextAfterFocusLost = false,
    Flag = "InputX",
    Callback = function() end,
})

local yInput = TabManual:CreateInput({
    Name = "Y",
    PlaceholderText = "100",
    RemoveTextAfterFocusLost = false,
    Flag = "InputY",
    Callback = function() end,
})

local zInput = TabManual:CreateInput({
    Name = "Z",
    PlaceholderText = "0",
    RemoveTextAfterFocusLost = false,
    Flag = "InputZ",
    Callback = function() end,
})

TabManual:CreateButton({
    Name = "Teleport ke X, Y, Z",
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

TabManual:CreateButton({
    Name = "Simpan Posisi Sekarang",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        local p = hrp.Position
        Rayfield:Notify({
            Title = "Posisi Disimpan",
            Content = string.format("X: %.0f, Y: %.0f, Z: %.0f", p.X, p.Y, p.Z),
            Duration = 3,
        })
    end,
})

TabManual:CreateSection("Trigger CP by Name")

local cpNameInput = TabManual:CreateInput({
    Name = "Nama CP",
    PlaceholderText = "CP10",
    RemoveTextAfterFocusLost = false,
    Flag = "InputCPName",
    Callback = function() end,
})

TabManual:CreateButton({
    Name = "Trigger CP by Name",
    Callback = function()
        local num = tonumber(cpNameInput:match("(%d+)"))
        if not num then
            Rayfield:Notify({
                Title = "Error",
                Content = "Format salah. Contoh: CP10",
                Duration = 2,
            })
            return
        end
        local cp = findCP(num)
        if cp then
            if tpToCP(cp) then
                Rayfield:Notify({
                    Title = "Success",
                    Content = cp.name .. " triggered",
                    Duration = 2,
                })
            end
        else
            Rayfield:Notify({
                Title = "Not Found",
                Content = "CP" .. num .. " gak ada",
                Duration = 2,
            })
        end
    end,
})

-- ============================================================
-- TAB 4: INFO
-- ============================================================
local TabInfo = Window:CreateTab("Info", 4483362458)
TabInfo:CreateSection("Player")

TabInfo:CreateLabel("Place ID: " .. tostring(game.PlaceId))
TabInfo:CreateLabel("Character: " .. (LP.Character and LP.Character.Name or "Not loaded"))

TabInfo:CreateButton({
    Name = "Tampilkan Posisi",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            local p = hrp.Position
            Rayfield:Notify({
                Title = "Posisi",
                Content = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z),
                Duration = 5,
            })
        end
    end,
})

TabInfo:CreateSection("Checkpoint Status")
TabInfo:CreateLabel("Ditemukan: " .. totalFound .. " CP")
TabInfo:CreateLabel("Missing: " .. totalMissing .. " CP")

if #missingList > 0 then
    TabInfo:CreateLabel("Missing: " .. table.concat(missingList, ", "))
end

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

-- Draggable bubble
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

-- Toggle window
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

-- Auto-detect close Rayfield
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
            
            if anyVisible then
                Bubble.Visible = false
                rayfieldVisible = true
            else
                Bubble.Visible = true
                rayfieldVisible = false
            end
        end
    end
end)

-- ============================================================
-- NOTIF
-- ============================================================
Rayfield:Notify({
    Title = "CP Exploit",
    Content = totalFound .. " CP ditemukan, " .. totalMissing .. " missing",
    Duration = 4,
})
