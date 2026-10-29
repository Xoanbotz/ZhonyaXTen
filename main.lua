local Workspace = game:GetService("Workspace")
local RepStorage = game:GetService("ReplicatedStorage")

print("=== SEMUA CHECKPOINT YANG ADA ===")

-- Scan semua yang namanya CP*
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj.Name:match("^CP%d+$") then
        local pos = "?"
        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
        if part then pos = tostring(part.Position) end
        print("[WS] " .. obj:GetFullName() .. " | " .. obj.ClassName .. " | Pos: " .. pos)
    end
end

-- Scan folder Checkpoints
local cpFolder = Workspace:FindFirstChild("Checkpoints")
if cpFolder then
    print("\n=== FOLDER CHECKPOINTS ===")
    for _, obj in ipairs(cpFolder:GetChildren()) do
        print("  " .. obj.Name .. " (" .. obj.ClassName .. ")")
    end
end

-- Scan ReplicatedStorage (kadang template CP disimpen di sini)
print("\n=== DI REPLICATEDSTORAGE ===")
for _, obj in ipairs(RepStorage:GetDescendants()) do
    if obj.Name:match("^CP%d+$") or string.lower(obj.Name):find("checkpoint") then
        print("[RepStorage] " .. obj:GetFullName() .. " (" .. obj.ClassName .. ")")
    end
end

-- Scan ServerStorage (kalo bisa diakses)
pcall(function()
    local ServerStorage = game:GetService("ServerStorage")
    print("\n=== DI SERVERSTORAGE ===")
    for _, obj in ipairs(ServerStorage:GetDescendants()) do
        if obj.Name:match("^CP%d+$") or string.lower(obj.Name):find("checkpoint") then
            print("[ServerStorage] " .. obj:GetFullName() .. " (" .. obj.ClassName .. ")")
        end
    end
end)

print("\n=== SCAN COMPLETE ===")
