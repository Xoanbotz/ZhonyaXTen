-- ============================================
-- CHECKPOINT EXPLOIT - ZhonyaLib UI
-- By: Conqueror
-- ============================================

if not ZhonyaLib then
    warn("[!] ZhonyaLib not loaded! Load library first.")
    return
end

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
    
    -- Direct Workspace.CP1, CP2, dst
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:match("^CP%d+$") then
            add(obj.Name, obj)
        end
    end
    
    -- Folder Workspace.Checkpoints.CP0, CP1, dst
    local folder = Workspace:FindFirstChild("Checkpoints")
    if folder then
        for _, obj in ipairs(folder:GetChildren()) do
            add("Checkpoints." .. obj.Name, obj)
        end
    end
    
    -- Sort by nomor
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

-- ============ CREATE UI ============
local Win = ZhonyaLib:CreateWindow({
    Title = "CP Exploit",
    OnUnload = function()
        if noclipConn then pcall(function() noclipConn:Disconnect() end) end
        if autoJumpConn then pcall(function() autoJumpConn:Disconnect() end) end
    end
})

-- ============ TAB 1: TELEPORT ============
local TabTP = Win:CreateTab("Teleport")
TabTP:CreateSection("Checkpoints Terdeteksi")
TabTP:CreateLabel("Klik CP untuk teleport ke titik itu")

local cps = scanCPs()

if #cps == 0 then
    TabTP:CreateLabel("⚠ Tidak ada CP ditemukan.")
    TabTP:CreateLabel("Pastikan CP ada di Workspace atau Workspace.Checkpoints")
else
    for _, cp in ipairs(cps) do
        TabTP:CreateButton({
            Name = "→ " .. cp.name,
            Callback = function()
                if tpTo(cp.part) then
                    ZhonyaLib:Notify({Content = "TP: " .. cp.name})
                end
            end
        })
    end
end

-- ============ TAB 2: MOVEMENT ============
local TabMove = Win:CreateTab("Movement")

TabMove:CreateSection("Kecepatan")
TabMove:CreateSlider({
    Name = "Walk Speed",
    Min = 16, Max = 500, Default = 50, Increment = 1,
    Callback = function(v)
        local h = getHumanoid()
        if h then h.WalkSpeed = v end
    end
})

TabMove:CreateSlider({
    Name = "Jump Power",
    Min = 50, Max = 500, Default = 100, Increment = 1,
    Callback = function(v)
        local h = getHumanoid()
        if h then h.JumpPower = v end
    end
})

TabMove:CreateSection("Exploits")

TabMove:CreateToggle({
    Name = "Auto Jump",
    CurrentValue = false,
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
    end
})

TabMove:CreateToggle({
    Name = "Noclip (Tembus Tembok)",
    CurrentValue = false,
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
    end
})

-- ============ TAB 3: MANUAL TP ============
local TabManual = Win:CreateTab("Manual")
TabManual:CreateSection("Koordinat Manual")

local xI = TabManual:CreateInput({Name = "X", Placeholder = "0"})
local yI = TabManual:CreateInput({Name = "Y", Placeholder = "100"})
local zI = TabManual:CreateInput({Name = "Z", Placeholder = "0"})

TabManual:CreateButton({
    Name = "Teleport ke X, Y, Z",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        local x = tonumber(xI:Get()) or 0
        local y = tonumber(yI:Get()) or 100
        local z = tonumber(zI:Get()) or 0
        hrp.CFrame = CFrame.new(x, y, z)
        ZhonyaLib:Notify({Content = string.format("TP ke (%.0f, %.0f, %.0f)", x, y, z)})
    end
})

TabManual:CreateButtonSecondary({
    Name = "Simpan Posisi Sekarang",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        xI:Set(tostring(math.floor(hrp.Position.X)))
        yI:Set(tostring(math.floor(hrp.Position.Y)))
        zI:Set(tostring(math.floor(hrp.Position.Z)))
        ZhonyaLib:Notify({Content = "Posisi disimpan!"})
    end
})

-- ============ TAB 4: INFO ============
local TabInfo = Win:CreateTab("Info")
TabInfo:CreateSection("Player")

TabInfo:CreateLabel("Place ID: " .. tostring(game.PlaceId))
TabInfo:CreateLabel("Total CP terdeteksi: " .. #cps)
TabInfo:CreateLabel("Character: " .. (LP.Character and LP.Character.Name or "Not loaded"))

TabInfo:CreateButtonSecondary({
    Name = "Tampilkan Posisi",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            local p = hrp.Position
            ZhonyaLib:Notify({
                Content = string.format("Pos: %.1f, %.1f, %.1f", p.X, p.Y, p.Z),
                Duration = 5
            })
        end
    end
})

-- ============ NOTIF ============
ZhonyaLib:Notify({
    Content = "✅ CP Exploit loaded! " .. #cps .. " CP ditemukan",
    Duration = 4
})
