--[[
=========================================================
  CP EXPLOIT - Rayfield UI
  Rewritten from ZhonyaLib version
=========================================================
]]

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- State
local noclipConn, autoJumpConn = nil, nil

-- ============ HELPERS ============
local function getHRP()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    return LP.Character and LP.Character:FindFirstChild("Humanoid")
end

-- ============ SCAN CHECKPOINTS ============
local function scanCPs()
    local list = {}
    local seen = {}
    
    local function add(name, obj)
        if not obj or seen[obj] then return end
        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
        if part then
            seen[obj] = true
            table.insert(list, {name = name, part = part})
        end
    end
    
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:match("^CP%d+$") then
            add(obj.Name, obj)
        end
    end
    
    local folder = Workspace:FindFirstChild("Checkpoints")
    if folder then
        for _, obj in ipairs(folder:GetChildren()) do
            add("Checkpoints." .. obj.Name, obj)
        end
    end
    
    table.sort(list, function(a, b)
        local an = tonumber(a.name:match("(%d+)")) or 0
        local bn = tonumber(b.name:match("(%d+)")) or 0
        return an < bn
    end)
    
    return list
end

-- ============ TELEPORT ============
local function tpTo(part)
    local hrp = getHRP()
    if not hrp or not part then return false end
    pcall(function()
        hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0))
    end)
    return true
end

-- ============ CREATE WINDOW ============
local Window = Rayfield:CreateWindow({
    Name = "CP Exploit",
    LoadingTitle = "Loading CP Exploit",
    LoadingSubtitle = "by Conqueror",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ============ TAB 1: TELEPORT ============
local TabTP = Window:CreateTab("Teleport", 4483362458)
TabTP:CreateSection("Checkpoints Terdeteksi")
TabTP:CreateLabel("Klik CP untuk teleport")

local cps = scanCPs()

if #cps == 0 then
    TabTP:CreateLabel("Tidak ada CP ditemukan")
    TabTP:CreateLabel("Pastikan CP ada di Workspace atau Workspace.Checkpoints")
else
    for _, cp in ipairs(cps) do
        TabTP:CreateButton({
            Name = "-> " .. cp.name,
            Callback = function()
                if tpTo(cp.part) then
                    Rayfield:Notify({
                        Title = "Teleport",
                        Content = "TP: " .. cp.name,
                        Duration = 3,
                    })
                end
            end,
        })
    end
end

-- ============ TAB 2: MOVEMENT ============
local TabMove = Window:CreateTab("Movement", 4483362458)

TabMove:CreateSection("Kecepatan")
TabMove:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 500},
    Increment = 1,
    Suffix = "",
    CurrentValue = 50,
    Flag = "WalkSpeed",
    Callback = function(v)
        local h = getHumanoid()
        if h then h.WalkSpeed = v end
    end,
})

TabMove:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 1,
    Suffix = "",
    CurrentValue = 100,
    Flag = "JumpPower",
    Callback = function(v)
        local h = getHumanoid()
        if h then h.JumpPower = v end
    end,
})

TabMove:CreateSection("Exploits")

TabMove:CreateToggle({
    Name = "Auto Jump",
    CurrentValue = false,
    Flag = "AutoJump",
    Callback = function(v)
        if v then
            if autoJumpConn then autoJumpConn:Disconnect() end
            autoJumpConn = RunService.Heartbeat:Connect(function()
                local h = getHumanoid()
                if h and h:GetState() ~= Enum.HumanoidStateType.Jumping then
                    h.Jump = true
                end
            end)
        else
            if autoJumpConn then autoJumpConn:Disconnect(); autoJumpConn = nil end
        end
    end,
})

TabMove:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v)
        if v then
            if noclipConn then noclipConn:Disconnect() end
            noclipConn = RunService.Stepped:Connect(function()
                local char = LP.Character
                if char then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
        else
            if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        end
    end,
})

-- ============ TAB 3: MANUAL ============
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
            Content = string.format("TP ke (%.0f, %.0f, %.0f)", x, y, z),
            Duration = 3,
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

-- ============ TAB 4: INFO ============
local TabInfo = Window:CreateTab("Info", 4483362458)
TabInfo:CreateSection("Player")

TabInfo:CreateLabel("Place ID: " .. tostring(game.PlaceId))
TabInfo:CreateLabel("Total CP terdeteksi: " .. #cps)
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

-- ============ NOTIF ============
Rayfield:Notify({
    Title = "CP Exploit",
    Content = "Loaded! " .. #cps .. " CP ditemukan",
    Duration = 4,
})
