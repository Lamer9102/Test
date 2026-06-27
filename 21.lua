if game:GetService("CoreGui"):FindFirstChild("UddachoJust_CustomMenu") or shared.UddachoExecuted then 
    return 
end
shared.UddachoExecuted = true

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
if not Players.LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

task.wait(3)

if game:GetService("CoreGui"):FindFirstChild("UddachoJust_CustomMenu") then
    return
end

local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")

local camera = Workspace.CurrentCamera

local Settings = {
    Mouse = false,
    Hide = false,
    Range = 9e9,
    Sword = false,
    RandomTP = false,
    TPDelay = 0.5,
    SignalID = "192557913",
    Platform = false,
    PlatformY = -3.76,
    AutoBuy = true,
    Aimbot = false,
    TargetFolder = "Folder", -- Дефолтное имя папки
    LoopDelay = 0.5,         -- Дефолтная задержка
    LoopTP = false           -- Статус On/Off для телепорта по объектам
}
getgenv().Settings = Settings

task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xxqLgnd/Utilities/main/BuyItemChecker.lua", true))()
    end)
end)

local platformPart = nil
local platformConnection = nil
local AIM_DISTANCE = 1000

local function CreateGUID()
    return tostring(HttpService:GenerateGUID(false))
end

local Cache = CreateGUID()

MarketplaceService.PromptPurchaseRequestedV2:Connect(function(...)
    if not Settings.AutoBuy then return end

    local PurchaseTable = {...}
    local Type = Enum.InfoType.Asset
    local AssetId = PurchaseTable[2]
    local ItemData = MarketplaceService:GetProductInfo(AssetId, Enum.InfoType.Asset)
    local Price = ItemData.PriceInRobux
    
    if Price ~= 0 then
        StarterGui:SetCore("SendNotification", {
            Title = "Пропуск",
            Text = "Предмет платный (" .. tostring(Price) .. " Robux), покупка отменена.",
            Duration = 3
        })
        return
    end

    local RequestId = Cache
    local ProductId = ItemData.ProductId or AssetId

    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    
    local Used = false
    local success = false
    
    mt.__namecall = function(self, ...)
        if Used == false and not checkcaller() then
            Used = true
            local sus, eror = pcall(function()
                if setthreadidentity then setthreadidentity(7) end
                MarketplaceService:PerformPurchase(Type, ProductId, Price, RequestId, true, tostring(ItemData.CollectibleItemId), tostring(ItemData.CollectibleProductId), tostring(PurchaseTable[5]), tostring(PurchaseTable[6]), 0)
            end)
            success = sus
            Cache = CreateGUID()
        end
        if Used then
            setreadonly(mt, false)
            mt.__namecall = old
            setreadonly(mt, true)
        end
        return old(self, ...)
    end
    setreadonly(mt, true)

    task.spawn(function()
        task.wait(1)
        if success then
            StarterGui:SetCore("SendNotification", {
                Title = "Успешно",
                Text = "Бесплатный предмет успешно куплен!",
                Duration = 5
            })
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Ошибка",
                Text = "Не удалось купить бесплатный предмет.",
                Duration = 5
            })
        end
    end)
end)

MarketplaceService.PromptBulkPurchaseRequested:Connect(function(...)
    if not Settings.AutoBuy then return end

    local BulkPurchaseTable = {...}
    local OrderQuest = BulkPurchaseTable[3] or {}
    local Options = BulkPurchaseTable[6] or {}

    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)

    local isPaidFound = false
    local totalPrice = 0
    local checkedItems = 0
    local totalItems = #OrderQuest

    if totalItems == 0 then 
        setreadonly(mt, true)
        return 
    end

    for _, item in ipairs(OrderQuest) do
        local assetId = item.AssetId or item.assetId or item.ProductInfoId or item.ItemInfoId
        if assetId then
            task.spawn(function()
                local success, itemData = pcall(function()
                    return MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
                end)
                
                if success and itemData and itemData.PriceInRobux then
                    if itemData.PriceInRobux > 0 then
                        isPaidFound = true
                        totalPrice = totalPrice + itemData.PriceInRobux
                    end
                end
                
                checkedItems = checkedItems + 1
            end)
        else
            checkedItems = checkedItems + 1
        end
    end

    repeat task.wait() until checkedItems >= totalItems

    if isPaidFound then
        mt.__namecall = old
        setreadonly(mt, true)

        StarterGui:SetCore("SendNotification", {
            Title = "Пропуск Bulk",
            Text = "Обнаружены платные предметы на сумму " .. tostring(totalPrice) .. " Robux. Покупка отменена!",
            Duration = 5
        })
    else
        local Used = false
        mt.__namecall = function(self, ...)
            if Used == false and not checkcaller() then
                Used = true
                pcall(function()
                    if setthreadidentity then setthreadidentity(7) end
                    MarketplaceService:PerformBulkPurchase(OrderQuest, Options)
                end)
            end
            setreadonly(mt, false)
            mt.__namecall = old
            setreadonly(mt, true)
            return old(self, ...)
        end
        setreadonly(mt, true)

        StarterGui:SetCore("SendNotification", {
            Title = "Успешно",
            Text = "Бесплатный Bulk пакет успешно куплен!",
            Duration = 5
        })
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UddachoJust_CustomMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 99999999
ScreenGui.Parent = CoreGui

local function getClosestPlayer()
    local closest = nil
    local shortest = AIM_DISTANCE

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local distance = (hrp.Position - camera.CFrame.Position).Magnitude

            if distance < shortest then
                shortest = distance
                closest = hrp
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not Settings.Aimbot then return end

    local target = getClosestPlayer()
    if target then
        camera.CFrame = CFrame.new(
            camera.CFrame.Position,
            target.Position
        )
    end
end)

LocalPlayer:GetMouse().Button1Down:Connect(function()
    if Settings.Mouse and LocalPlayer:GetMouse().Hit then
        LocalPlayer.Character:PivotTo(CFrame.new(LocalPlayer:GetMouse().Hit.Position + Vector3.new(0, 3, 0)))
    end
end)

local function FireTouchTransmitter(part)
    local PartClass = part:FindFirstAncestorWhichIsA("Part")
    if firetouchinterest and LocalPlayer.Character then
        local Character = LocalPlayer.Character:FindFirstChildOfClass("Part")
        if Character and part and PartClass then
            firetouchinterest(PartClass, Character, 0)
            firetouchinterest(PartClass, Character, 1)
            PartClass:PivotTo(Character:GetPivot())
        end
    elseif PartClass then
        LocalPlayer.Character:PivotTo(PartClass:GetPivot())
    end
end

task.spawn(function()
    while true do
        if Settings.RandomTP and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local allPlayers = Players:GetPlayers()
            if #allPlayers > 1 then
                local targetPlayer = allPlayers[math.random(1, #allPlayers)]
                if targetPlayer ~= LocalPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPlayer.Character.HumanoidRootPart.Position)
                end
            end
        end
        task.wait(Settings.TPDelay)
    end
end)

local function TogglePlatform(state)
    if state then
        if not platformPart then
            platformPart = Instance.new("Part")
            platformPart.Size = Vector3.new(10, 2, 10)
            platformPart.Anchored = true
            platformPart.CanCollide = true
            platformPart.Material = Enum.Material.SmoothPlastic
            platformPart.Color = Color3.fromRGB(50, 50, 50)
            platformPart.Transparency = 0.2
            platformPart.Name = "SafetyPlatform"
            platformPart.Parent = Workspace
        end
        if not platformConnection then
            platformConnection = RunService.RenderStepped:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and platformPart then
                    local hrp = LocalPlayer.Character.HumanoidRootPart
                    platformPart.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + Settings.PlatformY, hrp.Position.Z)
                end
            end)
        end
    else
        if platformConnection then
            platformConnection:Disconnect()
            platformConnection = nil
        end
        if platformPart then
            platformPart:Destroy()
            platformPart = nil
        end
    end
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 150, 0, 40)
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.BackgroundTransparency = 1
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 10
MainFrame.Parent = ScreenGui

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 11
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 30, 0, 0)
Title.Text = "UddachoJust 1.2"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.BackgroundTransparency = 1
Title.ZIndex = 12
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Position = UDim2.new(0, 0, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.SourceSans
CloseBtn.TextSize = 16
CloseBtn.BackgroundTransparency = 1
CloseBtn.ZIndex = 13
CloseBtn.Parent = TopBar
CloseBtn.MouseButton1Up:Connect(function()
    TogglePlatform(false)
    Settings.LoopTP = false
    shared.UddachoExecuted = nil
    ScreenGui:Destroy()
end)

local MenuBody = Instance.new("Frame")
MenuBody.Size = UDim2.new(1, 0, 0, 260)
MenuBody.Position = UDim2.new(0, 0, 0, 40)
MenuBody.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MenuBody.BorderSizePixel = 0
MenuBody.ClipsDescendants = true
MenuBody.Visible = false
MenuBody.ZIndex = 10
MenuBody.Parent = MainFrame

local BodyCorner = Instance.new("UICorner")
BodyCorner.CornerRadius = UDim.new(0, 8)
BodyCorner.Parent = MenuBody

local SidePanel = Instance.new("Frame")
SidePanel.Size = UDim2.new(0, 120, 1, 0)
SidePanel.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
SidePanel.BorderSizePixel = 0
SidePanel.ZIndex = 11
SidePanel.Parent = MenuBody

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -130, 1, -10)
ContentContainer.Position = UDim2.new(0, 125, 0, 5)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ZIndex = 11
ContentContainer.Parent = MenuBody

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 30, 1, 0)
ToggleBtn.Position = UDim2.new(1, -30, 0, 0)
ToggleBtn.Text = "v"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSans
ToggleBtn.TextSize = 16
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.ZIndex = 13
ToggleBtn.Parent = TopBar

local isOpened = false
ToggleBtn.MouseButton1Up:Connect(function()
    isOpened = not isOpened
    if isOpened then
        ToggleBtn.Text = "^"
        MainFrame.Size = UDim2.new(0, 450, 0, 300)
        MenuBody.Visible = true
    else
        ToggleBtn.Text = "v"
        MenuBody.Visible = false
        MainFrame.Size = UDim2.new(0, 150, 0, 40)
    end
end)

local Pages = {}
local ScrollStates = {}

local function CreatePage(name)
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, 0)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 4
    Scroll.Visible = false
    Scroll.ZIndex = 12
    Scroll.Parent = ContentContainer

    local List = Instance.new("UIListLayout")
    List.Padding = UDim.new(0, 6)
    List.SortOrder = Enum.SortOrder.LayoutOrder
    List.Parent = Scroll

    ScrollStates[Scroll] = false

    Scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        ScrollStates[Scroll] = true
        task.delay(0.3, function()
            ScrollStates[Scroll] = false
        end)
    end)

    Pages[name] = Scroll
    return Scroll
end

local function FindParentScroll(element)
    local current = element.Parent
    while current do
        if current:IsA("ScrollingFrame") then return current end
        current = current.Parent
    end
    return nil
end

local function IsScrolling(element)
    local scroll = FindParentScroll(element)
    if not scroll then return false end
    return ScrollStates[scroll] == true
end

local MainScroll      = CreatePage("Main")
local TeleportScroll  = CreatePage("Teleport") -- Название изменено с Moving на Teleport
local ToolsScroll     = CreatePage("Tools")
local ImportantScroll = CreatePage("Other")

local function SelectTab(name)
    getgenv().Settings = Settings
    for k, v in pairs(Pages) do v.Visible = (k == name) end
end

local tabCount = 0
local function AddTabButton(name)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -10, 0, 30)
    Btn.Position = UDim2.new(0, 5, 0, 10 + (tabCount * 35))
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Btn.Font = Enum.Font.SourceSans
    Btn.TextSize = 13
    Btn.BorderSizePixel = 0
    Btn.ZIndex = 13
    Btn.Parent = SidePanel

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 4)
    BtnCorner.Parent = Btn

    Btn.MouseButton1Up:Connect(function() SelectTab(name) end)
    tabCount = tabCount + 1
end

AddTabButton("Main")
AddTabButton("Teleport") -- Изменено название кнопки вкладки
AddTabButton("Tools")
AddTabButton("Other")
SelectTab("Main")

local NickLabel = Instance.new("TextLabel")
NickLabel.Size = UDim2.new(1, -10, 0, 30)
NickLabel.Position = UDim2.new(0, 5, 1, -35)
NickLabel.Text = LocalPlayer.Name
NickLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
NickLabel.BackgroundTransparency = 1
NickLabel.Font = Enum.Font.SourceSans
NickLabel.TextSize = 12
NickLabel.TextWrapped = true
NickLabel.ZIndex = 13
NickLabel.Parent = SidePanel

local function CreateGroupFrame(page, color)
    local Group = Instance.new("Frame")
    Group.Size = UDim2.new(1, -10, 0, 84)
    Group.BackgroundColor3 = color
    Group.BorderSizePixel = 0
    Group.Active = false
    Group.ZIndex = 13
    Group.Parent = page

    local GCorn = Instance.new("UICorner")
    GCorn.CornerRadius = UDim.new(0, 6)
    GCorn.Parent = Group

    local GList = Instance.new("UIListLayout")
    GList.Padding = UDim.new(0, 4)
    GList.SortOrder = Enum.SortOrder.LayoutOrder
    GList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    GList.VerticalAlignment = Enum.VerticalAlignment.Center
    GList.Parent = Group

    return Group
end

local function AddButton(page, text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -10, 0, 35)
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Btn.Font = Enum.Font.SourceSansSemibold
    Btn.TextSize = 14
    Btn.BorderSizePixel = 0
    Btn.Active = true
    Btn.ZIndex = 14
    Btn.Parent = page

    local BCorn = Instance.new("UICorner")
    BCorn.CornerRadius = UDim.new(0, 5)
    BCorn.Parent = Btn

    local pressX, pressY = 0, 0
    local pressed = false

    Btn.MouseButton1Down:Connect(function()
        local mouse = LocalPlayer:GetMouse()
        pressX = mouse.X
        pressY = mouse.Y
        pressed = true
    end)

    Btn.MouseButton1Up:Connect(function()
        if not pressed then return end
        pressed = false
        local mouse = LocalPlayer:GetMouse()
        local dx = math.abs(mouse.X - pressX)
        local dy = math.abs(mouse.Y - pressY)
        if dx > 10 or dy > 10 then return end
        if IsScrolling(Btn) then return end
        getgenv().Settings = Settings
        pcall(callback)
    end)
    return Btn
end

local function AddToggle(page, text, varName, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -10, 0, 35)
    
    if Settings[varName] then
        Btn.Text = text .. ": ON"
        Btn.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        Btn.Text = text .. ": OFF"
        Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    
    Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Btn.Font = Enum.Font.SourceSansSemibold
    Btn.TextSize = 14
    Btn.BorderSizePixel = 0
    Btn.Active = true
    Btn.ZIndex = 15
    Btn.Parent = page

    local BCorn = Instance.new("UICorner")
    BCorn.CornerRadius = UDim.new(0, 5)
    BCorn.Parent = Btn

    local pressX, pressY = 0, 0
    local pressed = false

    Btn.MouseButton1Down:Connect(function()
        local mouse = LocalPlayer:GetMouse()
        pressX = mouse.X
        pressY = mouse.Y
        pressed = true
    end)

    Btn.MouseButton1Up:Connect(function()
        if not pressed then return end
        pressed = false
        local mouse = LocalPlayer:GetMouse()
        local dx = math.abs(mouse.X - pressX)
        local dy = math.abs(mouse.Y - pressY)
        if dx > 10 or dy > 10 then return end
        if IsScrolling(Btn) then return end
        getgenv().Settings = Settings
        
        Settings[varName] = not Settings[varName]
        if Settings[varName] then
            Btn.Text = text .. ": ON"
            Btn.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            Btn.Text = text .. ": OFF"
            Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end

        task.spawn(function()
            pcall(callback, Settings[varName])
        end)
    end)
    return Btn
end

local function AddTextBox(page, placeholder, callback)
    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(1, -10, 0, 35)
    Box.PlaceholderText = placeholder
    Box.Text = ""
    Box.TextColor3 = Color3.fromRGB(255, 255, 255)
    Box.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    Box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Box.Font = Enum.Font.SourceSans
    Box.TextSize = 13
    Box.BorderSizePixel = 0
    Box.Active = true
    Box.ZIndex = 14
    Box.Parent = page

    local BCorn = Instance.new("UICorner")
    BCorn.CornerRadius = UDim.new(0, 5)
    BCorn.Parent = Box

    Box.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            getgenv().Settings = Settings
            pcall(callback, Box.Text)
        end
    end)
    return Box
end

AddButton(MainScroll, "Infinite Yield", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", true))() end)
AddButton(MainScroll, "Dark Dex", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua", true))() end)
AddButton(MainScroll, "Buy Item Checker", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/xxqLgnd/Utilities/main/BuyItemChecker.lua", true))() end)
AddButton(MainScroll, "WyConnect", function() loadstring(game:HttpGet("https://pastefy.app/16kxxJlL/raw", true))() end)
AddButton(MainScroll, "Remote Spy", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua", true))() end)
AddButton(MainScroll, "Turtle Spy", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Spy/main/source.lua", true))() end)
AddButton(MainScroll, "Remote Browser", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Games1799/Scripts/refs/heads/main/RemoteBrowser", true))() end)
AddButton(MainScroll, "Dev Purchase's", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ckw69/Wyborn/refs/heads/main/Dev%20Product%20Purchase", true))() end)

-- ВКЛАДКА TELEPORT (Бывшая Moving)
AddToggle(TeleportScroll, "Mouse Teleport", "Mouse", function() end)
AddButton(TeleportScroll, "Copy Position", function()
    local pos = LocalPlayer.Character.HumanoidRootPart:GetPivot()
    setclipboard(string.format("%d, %d, %d", pos.X, pos.Y, pos.Z))
end)
AddButton(TeleportScroll, "Copy Teleport", function()
    local pos = LocalPlayer.Character.HumanoidRootPart:GetPivot()
    setclipboard(string.format("game:GetService('Players').LocalPlayer.Character:PivotTo(CFrame.new(Vector3.new(%d, %d, %d)))", pos.X+.5, pos.Y+.5, pos.Z+.5))
end)
AddButton(TeleportScroll, "Copy TweenService", function()
    local pos = LocalPlayer.Character.HumanoidRootPart:GetPivot()
    setclipboard(string.format("game:GetService('TweenService'):Create(game:GetService('Players').LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(2), {CFrame = CFrame.new(%d, %d, %d)}):Play()", pos.X, pos.Y, pos.Z))
end)

-- Новая группа функций: Телепорт по объектам папки
local folderGroup = CreateGroupFrame(TeleportScroll, Color3.fromRGB(30, 80, 150))
local f1 = AddTextBox(folderGroup, "Имя папки в Workspace", function(text)
    if text and text ~= "" then Settings.TargetFolder = text end
end)
local f2 = AddTextBox(folderGroup, "Задержка цикла (Тек: 0.5)", function(text)
    local n = tonumber(text)
    if n then Settings.LoopDelay = n end
end)
local f3 = AddToggle(folderGroup, "Folder TP Loop", "LoopTP", function(state)
    if state then
        while Settings.LoopTP do
            local folder = Workspace:FindFirstChild(Settings.TargetFolder)
            if folder then
                for _, v in ipairs(folder:GetChildren()) do
                    if not Settings.LoopTP then break end
                    if v:IsA("BasePart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = v.CFrame
                    end
                    task.wait(Settings.LoopDelay)
                end
            else
                StarterGui:SetCore("SendNotification", {
                    Title = "Ошибка",
                    Text = "Папка '" .. Settings.TargetFolder .. "' не найдена в Workspace!",
                    Duration = 3
                })
                Settings.LoopTP = false
                break
            end
            task.wait(0.1)
        end
    end
end)

f1.Size = UDim2.new(1, -6, 0, 35)
f2.Size = UDim2.new(1, -6, 0, 35)
f3.Size = UDim2.new(1, -6, 0, 35)
-- Корректировка размера фрейма группы, так как теперь там 3 элемента вместо 2
folderGroup.Size = UDim2.new(1, -10, 0, 125)


AddToggle(ToolsScroll, "Auto Hide Players", "Hide", function(state)
    while Settings.Hide do
        for _, v in pairs(Players:GetPlayers()) do
            if v.Name ~= LocalPlayer.Name and v.Character then v.Character:Destroy() end
        end
        task.wait(.2)
    end
end)
AddButton(ToolsScroll, "Fire All ProximityPrompt", function()
    for _, v in ipairs(Workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then fireproximityprompt(v) end end
end)
AddButton(ToolsScroll, "HoldDuration 0", function()
    for _, v in pairs(Workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then v.HoldDuration = 0 end end
end)
AddButton(ToolsScroll, "Fire All ClickDetectors", function()
    for _, v in ipairs(Workspace:GetDescendants()) do if v:IsA("ClickDetector") then fireclickdetector(v) end end
end)
AddButton(ToolsScroll, "Fire All Firetouchinterests", function()
    for _, v in ipairs(Workspace:GetDescendants()) do if v:IsA("TouchTransmitter") then FireTouchTransmitter(v) end end
end)

local toolGroup = CreateGroupFrame(ToolsScroll, Color3.fromRGB(0, 120, 120))
local b1 = AddToggle(toolGroup, "Sword Killaura", "Sword", function()
    while Settings.Sword do
        for _, v in pairs(Players:GetPlayers()) do
            local Dist = LocalPlayer:DistanceFromCharacter(v.Character:GetPivot().Position)
            if v.Character and v.Character.Name ~= LocalPlayer.Name and v.Character:FindFirstChild("HumanoidRootPart") and Dist <= Settings.Range then
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("Handle") then
                    tool:Activate()
                    firetouchinterest(tool.Handle, v.Character.HumanoidRootPart, 0)
                    firetouchinterest(tool.Handle, v.Character.HumanoidRootPart, 1)
                end
            end
        end
        task.wait(.3)
    end
end)
local b2 = AddTextBox(toolGroup, "Sword Killaura Range (жми Enter)", function(text)
    local n = tonumber(text)
    if n then Settings.Range = n end
end)
b1.Size = UDim2.new(1, -6, 0, 35)
b2.Size = UDim2.new(1, -6, 0, 35)

AddToggle(ImportantScroll, "AutoBuy (Free items)", "AutoBuy", function(state) end)
AddToggle(ImportantScroll, "Aimbot", "Aimbot", function(state) end)

AddButton(ImportantScroll, "Fly V3", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
end)

local redGroup = CreateGroupFrame(ImportantScroll, Color3.fromRGB(150, 30, 30))
local r1 = AddToggle(redGroup, "Random TP", "RandomTP", function() end)
local r2 = AddTextBox(redGroup, "TP Delay (Текущий: 0.5)", function(text)
    local n = tonumber(text)
    if n then Settings.TPDelay = n end
end)
r1.Size = UDim2.new(1, -6, 0, 35)
r2.Size = UDim2.new(1, -6, 0, 35)

AddButton(ImportantScroll, "Auto Save (Refund)", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xxqLgnd/Utilities/main/AutoRefund.lua", true))()
end)

local orangeGroup = CreateGroupFrame(ImportantScroll, Color3.fromRGB(160, 80, 20))
local o1 = AddTextBox(orangeGroup, "Введите ID для Signal", function(text)
    if text and text ~= "" then Settings.SignalID = text end
end)
local o2 = AddButton(orangeGroup, "Send Signal", function()
    pcall(function()
        MarketplaceService:SignalPromptPurchaseFinished(LocalPlayer, tonumber(Settings.SignalID), true)
        MarketplaceService:SignalPromptPurchaseFinished(LocalPlayer, tonumber(Settings.SignalID), false)
    end)
end)
o1.Size = UDim2.new(1, -6, 0, 35)
o2.Size = UDim2.new(1, -6, 0, 35)

AddButton(ImportantScroll, "UtopiaSpy", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Klinac/scripts/main/utopia_spy.lua", true))()
end)

AddButton(ImportantScroll, "Keyboard", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Xxtan31/Ata/main/deltakeyboardcrack.txt"))()
end)

local purpleGroup = CreateGroupFrame(ImportantScroll, Color3.fromRGB(100, 30, 150))
local p1 = AddToggle(purpleGroup, "Safety Platform", "Platform", function(state)
    TogglePlatform(state)
end)
local p2 = AddTextBox(purpleGroup, "Platform Y offset (Тек: -3.76)", function(text)
    local n = tonumber(text)
    if n then
        Settings.PlatformY = n
        if Settings.Platform and platformPart then
            TogglePlatform(false)
            TogglePlatform(true)
        end
    end
end)
p1.Size = UDim2.new(1, -6, 0, 35)
p2.Size = UDim2.new(1, -6, 0, 35)