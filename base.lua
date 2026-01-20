--[[
    Sierra UI Library
    A modern dark-themed GUI library for Roblox
    
    Usage:
    local Sierra = loadstring(game:HttpGet("your-url-here"))()
    local Window = Sierra:CreateWindow("My Window")
    local Tab = Window:CreateTab("Main")
    local Section = Tab:CreateSection("Section Name")
    Section:CreateToggle("Toggle Name", false, function(value) print(value) end)
]]

local Sierra = {}
Sierra.__index = Sierra

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Theme Configuration
local Theme = {
    Background = Color3.fromRGB(30, 30, 35),
    DarkBackground = Color3.fromRGB(20, 20, 25),
    LightBackground = Color3.fromRGB(40, 40, 45),
    Border = Color3.fromRGB(50, 50, 55),
    Text = Color3.fromRGB(200, 200, 200),
    DimText = Color3.fromRGB(140, 140, 140),
    Accent = Color3.fromRGB(70, 100, 160),
    AccentDark = Color3.fromRGB(50, 70, 120),
    Toggle = Color3.fromRGB(60, 90, 150),
    ToggleOff = Color3.fromRGB(50, 50, 55),
    Slider = Color3.fromRGB(70, 100, 160),
    SliderBackground = Color3.fromRGB(35, 35, 40),
}

-- Utility Functions
local function Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function Tween(instance, properties, duration)
    local tween = TweenService:Create(instance, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad), properties)
    tween:Play()
    return tween
end

local function AddCorner(instance, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 4),
        Parent = instance
    })
end

local function AddStroke(instance, color, thickness)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Parent = instance
    })
end

local function AddPadding(instance, padding)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, padding),
        PaddingBottom = UDim.new(0, padding),
        PaddingLeft = UDim.new(0, padding),
        PaddingRight = UDim.new(0, padding),
        Parent = instance
    })
end

-- Main Library
function Sierra:CreateWindow(title)
    local Window = {}
    Window.Tabs = {}
    Window.CurrentTab = nil
    
    -- Main ScreenGui
    local ScreenGui = Create("ScreenGui", {
        Name = "SierraUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = Player:WaitForChild("PlayerGui")
    })
    
    -- Main Frame
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 550, 0, 450),
        Position = UDim2.new(0.5, -275, 0.5, -225),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = ScreenGui
    })
    AddCorner(MainFrame, 6)
    AddStroke(MainFrame, Theme.Border)
    
    -- Title Bar
    local TitleBar = Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundColor3 = Theme.DarkBackground,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    AddCorner(TitleBar, 6)
    
    -- Fix corner overlap
    local TitleBarFix = Create("Frame", {
        Name = "TitleBarFix",
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Theme.DarkBackground,
        BorderSizePixel = 0,
        Parent = TitleBar
    })
    
    local TitleLabel = Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "Sierra",
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TitleBar
    })
    
    -- Tab Container (Top tabs)
    local TabContainer = Create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, -20, 0, 28),
        Position = UDim2.new(0, 10, 0, 30),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    
    local TabLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = TabContainer
    })
    
    -- Content Container
    local ContentContainer = Create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -20, 1, -68),
        Position = UDim2.new(0, 10, 0, 62),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = MainFrame
    })
    
    -- Dragging functionality
    local dragging, dragInput, dragStart, startPos
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Tab Creation
    function Window:CreateTab(name)
        local Tab = {}
        Tab.Sections = {}
        Tab.Name = name
        
        -- Tab Button
        local TabButton = Create("TextButton", {
            Name = name .. "Tab",
            Size = UDim2.new(0, 70, 1, 0),
            BackgroundColor3 = Theme.LightBackground,
            BorderSizePixel = 0,
            Text = name,
            TextColor3 = Theme.DimText,
            TextSize = 12,
            Font = Enum.Font.Code,
            AutoButtonColor = false,
            Parent = TabContainer
        })
        AddCorner(TabButton, 4)
        AddStroke(TabButton, Theme.Border)
        
        -- Tab Content Frame
        local TabContent = Create("ScrollingFrame", {
            Name = name .. "Content",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            Visible = false,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Parent = ContentContainer
        })
        
        local ContentLayout = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            Parent = TabContent
        })
        
        -- Update canvas size
        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, ContentLayout.AbsoluteContentSize.X, 0, 0)
        end)
        
        -- Tab Selection
        TabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(Window.Tabs) do
                tab.Button.BackgroundColor3 = Theme.LightBackground
                tab.Button.TextColor3 = Theme.DimText
                tab.Content.Visible = false
            end
            TabButton.BackgroundColor3 = Theme.DarkBackground
            TabButton.TextColor3 = Theme.Text
            TabContent.Visible = true
            Window.CurrentTab = Tab
        end)
        
        Tab.Button = TabButton
        Tab.Content = TabContent
        
        -- Section Creation
        function Tab:CreateSection(name, width)
            local Section = {}
            Section.Elements = {}
            
            local SectionFrame = Create("Frame", {
                Name = name .. "Section",
                Size = UDim2.new(0, width or 255, 1, 0),
                BackgroundColor3 = Theme.DarkBackground,
                BorderSizePixel = 0,
                Parent = TabContent
            })
            AddCorner(SectionFrame, 4)
            AddStroke(SectionFrame, Theme.Border)
            
            -- Section Header with sub-tabs
            local SectionHeader = Create("Frame", {
                Name = "Header",
                Size = UDim2.new(1, 0, 0, 25),
                BackgroundTransparency = 1,
                Parent = SectionFrame
            })
            
            local HeaderLayout = Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2),
                Parent = SectionHeader
            })
            AddPadding(SectionHeader, 3)
            
            -- Section Content
            local SectionContent = Create("ScrollingFrame", {
                Name = "Content",
                Size = UDim2.new(1, -6, 1, -30),
                Position = UDim2.new(0, 3, 0, 28),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Theme.Accent,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                Parent = SectionFrame
            })
            
            local ElementLayout = Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2),
                Parent = SectionContent
            })
            
            ElementLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SectionContent.CanvasSize = UDim2.new(0, 0, 0, ElementLayout.AbsoluteContentSize.Y + 5)
            end)
            
            Section.Frame = SectionFrame
            Section.Content = SectionContent
            Section.SubTabs = {}
            Section.CurrentSubTab = nil
            
            -- Sub-tab creation for sections
            function Section:CreateSubTab(subName)
                local SubTab = {}
                
                local SubTabButton = Create("TextButton", {
                    Name = subName,
                    Size = UDim2.new(0, 55, 0, 18),
                    BackgroundColor3 = #Section.SubTabs == 0 and Theme.DarkBackground or Theme.LightBackground,
                    BorderSizePixel = 0,
                    Text = subName,
                    TextColor3 = #Section.SubTabs == 0 and Theme.Text or Theme.DimText,
                    TextSize = 11,
                    Font = Enum.Font.Code,
                    AutoButtonColor = false,
                    Parent = SectionHeader
                })
                AddCorner(SubTabButton, 3)
                AddStroke(SubTabButton, Theme.Border)
                
                SubTab.Button = SubTabButton
                SubTab.Elements = {}
                
                SubTabButton.MouseButton1Click:Connect(function()
                    for _, st in pairs(Section.SubTabs) do
                        st.Button.BackgroundColor3 = Theme.LightBackground
                        st.Button.TextColor3 = Theme.DimText
                        for _, elem in pairs(st.Elements) do
                            if elem.Frame then elem.Frame.Visible = false end
                        end
                    end
                    SubTabButton.BackgroundColor3 = Theme.DarkBackground
                    SubTabButton.TextColor3 = Theme.Text
                    for _, elem in pairs(SubTab.Elements) do
                        if elem.Frame then elem.Frame.Visible = true end
                    end
                    Section.CurrentSubTab = SubTab
                end)
                
                table.insert(Section.SubTabs, SubTab)
                if #Section.SubTabs == 1 then
                    Section.CurrentSubTab = SubTab
                end
                
                return SubTab
            end
            
            -- Toggle Element
            function Section:CreateToggle(name, default, callback, subTab)
                local Toggle = {}
                Toggle.Value = default or false
                
                local ToggleFrame = Create("Frame", {
                    Name = name .. "Toggle",
                    Size = UDim2.new(1, -6, 0, 22),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    Visible = not subTab or (Section.CurrentSubTab == subTab),
                    Parent = SectionContent
                })
                AddCorner(ToggleFrame, 3)
                
                local ToggleIndicator = Create("Frame", {
                    Name = "Indicator",
                    Size = UDim2.new(0, 3, 0, 14),
                    Position = UDim2.new(0, 4, 0.5, -7),
                    BackgroundColor3 = default and Theme.Toggle or Theme.ToggleOff,
                    BorderSizePixel = 0,
                    Parent = ToggleFrame
                })
                AddCorner(ToggleIndicator, 1)
                
                local ToggleLabel = Create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -15, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    Text = name,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.Code,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ToggleFrame
                })
                
                local ToggleButton = Create("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = ToggleFrame
                })
                
                ToggleButton.MouseButton1Click:Connect(function()
                    Toggle.Value = not Toggle.Value
                    Tween(ToggleIndicator, {BackgroundColor3 = Toggle.Value and Theme.Toggle or Theme.ToggleOff}, 0.15)
                    if callback then callback(Toggle.Value) end
                end)
                
                Toggle.Frame = ToggleFrame
                Toggle.Set = function(self, value)
                    self.Value = value
                    Tween(ToggleIndicator, {BackgroundColor3 = value and Theme.Toggle or Theme.ToggleOff}, 0.15)
                    if callback then callback(value) end
                end
                
                if subTab then
                    table.insert(subTab.Elements, Toggle)
                end
                table.insert(Section.Elements, Toggle)
                
                return Toggle
            end
            
            -- Button Element
            function Section:CreateButton(name, callback, subTab)
                local Button = {}
                
                local ButtonFrame = Create("Frame", {
                    Name = name .. "Button",
                    Size = UDim2.new(1, -6, 0, 22),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    Visible = not subTab or (Section.CurrentSubTab == subTab),
                    Parent = SectionContent
                })
                AddCorner(ButtonFrame, 3)
                
                local ButtonLabel = Create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -50, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    Text = name,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.Code,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ButtonFrame
                })
                
                local ActionButton = Create("TextButton", {
                    Name = "Action",
                    Size = UDim2.new(0, 25, 0, 16),
                    Position = UDim2.new(1, -30, 0.5, -8),
                    BackgroundColor3 = Theme.LightBackground,
                    BorderSizePixel = 0,
                    Text = "...",
                    TextColor3 = Theme.Text,
                    TextSize = 10,
                    Font = Enum.Font.Code,
                    Parent = ButtonFrame
                })
                AddCorner(ActionButton, 3)
                AddStroke(ActionButton, Theme.Border)
                
                ActionButton.MouseButton1Click:Connect(function()
                    if callback then callback() end
                end)
                
                Button.Frame = ButtonFrame
                
                if subTab then
                    table.insert(subTab.Elements, Button)
                end
                table.insert(Section.Elements, Button)
                
                return Button
            end
            
            -- Dropdown Element
            function Section:CreateDropdown(name, options, default, callback, subTab)
                local Dropdown = {}
                Dropdown.Value = default or options[1]
                Dropdown.Open = false
                
                local DropdownFrame = Create("Frame", {
                    Name = name .. "Dropdown",
                    Size = UDim2.new(1, -6, 0, 22),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    ClipsDescendants = false,
                    Visible = not subTab or (Section.CurrentSubTab == subTab),
                    Parent = SectionContent
                })
                AddCorner(DropdownFrame, 3)
                
                local DropdownLabel = Create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(0, 80, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    Text = name,
                    TextColor3 = Theme.DimText,
                    TextSize = 11,
                    Font = Enum.Font.Code,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = DropdownFrame
                })
                
                local DropdownButton = Create("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(0, 140, 0, 18),
                    Position = UDim2.new(1, -145, 0.5, -9),
                    BackgroundColor3 = Theme.DarkBackground,
                    BorderSizePixel = 0,
                    Text = Dropdown.Value,
                    TextColor3 = Theme.Text,
                    TextSize = 11,
                    Font = Enum.Font.Code,
                    Parent = DropdownFrame
                })
                AddCorner(DropdownButton, 3)
                AddStroke(DropdownButton, Theme.Border)
                
                local DropdownArrow = Create("TextLabel", {
                    Name = "Arrow",
                    Size = UDim2.new(0, 15, 1, 0),
                    Position = UDim2.new(1, -18, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "v",
                    TextColor3 = Theme.DimText,
                    TextSize = 10,
                    Font = Enum.Font.Code,
                    Parent = DropdownButton
                })
                
                local DropdownList = Create("Frame", {
                    Name = "List",
                    Size = UDim2.new(1, 0, 0, #options * 20),
                    Position = UDim2.new(0, 0, 1, 2),
                    BackgroundColor3 = Theme.DarkBackground,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 10,
                    Parent = DropdownButton
                })
                AddCorner(DropdownList, 3)
                AddStroke(DropdownList, Theme.Border)
                
                local ListLayout = Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = DropdownList
                })
                
                for i, option in ipairs(options) do
                    local OptionButton = Create("TextButton", {
                        Name = option,
                        Size = UDim2.new(1, 0, 0, 20),
                        BackgroundTransparency = 1,
                        Text = option,
                        TextColor3 = Theme.Text,
                        TextSize = 11,
                        Font = Enum.Font.Code,
                        ZIndex = 11,
                        Parent = DropdownList
                    })
                    
                    OptionButton.MouseEnter:Connect(function()
                        OptionButton.BackgroundTransparency = 0.8
                        OptionButton.BackgroundColor3 = Theme.Accent
                    end)
                    
                    OptionButton.MouseLeave:Connect(function()
                        OptionButton.BackgroundTransparency = 1
                    end)
                    
                    OptionButton.MouseButton1Click:Connect(function()
                        Dropdown.Value = option
                        DropdownButton.Text = option
                        DropdownList.Visible = false
                        Dropdown.Open = false
                        if callback then callback(option) end
                    end)
                end
                
                DropdownButton.MouseButton1Click:Connect(function()
                    Dropdown.Open = not Dropdown.Open
                    DropdownList.Visible = Dropdown.Open
                end)
                
                Dropdown.Frame = DropdownFrame
                Dropdown.Set = function(self, value)
                    self.Value = value
                    DropdownButton.Text = value
                    if callback then callback(value) end
                end
                
                if subTab then
                    table.insert(subTab.Elements, Dropdown)
                end
                table.insert(Section.Elements, Dropdown)
                
                return Dropdown
            end
            
            -- Slider Element
            function Section:CreateSlider(name, min, max, default, suffix, callback, subTab)
                local Slider = {}
                Slider.Value = default or min
                
                local SliderFrame = Create("Frame", {
                    Name = name .. "Slider",
                    Size = UDim2.new(1, -6, 0, 22),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    Visible = not subTab or (Section.CurrentSubTab == subTab),
                    Parent = SectionContent
                })
                AddCorner(SliderFrame, 3)
                
                local SliderLabel = Create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(0, 60, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    Text = name,
                    TextColor3 = Theme.DimText,
                    TextSize = 11,
                    Font = Enum.Font.Code,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = SliderFrame
                })
                
                local SliderContainer = Create("Frame", {
                    Name = "Container",
                    Size = UDim2.new(0, 120, 0, 10),
                    Position = UDim2.new(1, -180, 0.5, -5),
                    BackgroundColor3 = Theme.SliderBackground,
                    BorderSizePixel = 0,
                    Parent = SliderFrame
                })
                AddCorner(SliderContainer, 2)
                
                local SliderFill = Create("Frame", {
                    Name = "Fill",
                    Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = Theme.Slider,
                    BorderSizePixel = 0,
                    Parent = SliderContainer
                })
                AddCorner(SliderFill, 2)
                
                local SliderValue = Create("TextLabel", {
                    Name = "Value",
                    Size = UDim2.new(0, 50, 1, 0),
                    Position = UDim2.new(1, -55, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(default) .. (suffix or ""),
                    TextColor3 = Theme.Text,
                    TextSize = 11,
                    Font = Enum.Font.Code,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = SliderFrame
                })
                
                local SliderButton = Create("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = SliderContainer
                })
                
                local dragging = false
                
                local function updateSlider(input)
                    local pos = math.clamp((input.Position.X - SliderContainer.AbsolutePosition.X) / SliderContainer.AbsoluteSize.X, 0, 1)
                    local value = math.floor(min + (max - min) * pos)
                    Slider.Value = value
                    SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                    SliderValue.Text = tostring(value) .. (suffix or "")
                    if callback then callback(value) end
                end
                
                SliderButton.MouseButton1Down:Connect(function()
                    dragging = true
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSlider(input)
                    end
                end)
                
                SliderButton.MouseButton1Click:Connect(function()
                    updateSlider({Position = Vector2.new(Mouse.X, Mouse.Y)})
                end)
                
                Slider.Frame = SliderFrame
                Slider.Set = function(self, value)
                    self.Value = value
                    local pos = (value - min) / (max - min)
                    SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                    SliderValue.Text = tostring(value) .. (suffix or "")
                    if callback then callback(value) end
                end
                
                if subTab then
                    table.insert(subTab.Elements, Slider)
                end
                table.insert(Section.Elements, Slider)
                
                return Slider
            end
            
            -- Label Element
            function Section:CreateLabel(text, subTab)
                local Label = {}
                
                local LabelFrame = Create("Frame", {
                    Name = "Label",
                    Size = UDim2.new(1, -6, 0, 22),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    Visible = not subTab or (Section.CurrentSubTab == subTab),
                    Parent = SectionContent
                })
                AddCorner(LabelFrame, 3)
                AddStroke(LabelFrame, Theme.Border)
                
                local LabelText = Create("TextLabel", {
                    Name = "Text",
                    Size = UDim2.new(1, -10, 1, 0),
                    Position = UDim2.new(0, 5, 0, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.DimText,
                    TextSize = 11,
                    Font = Enum.Font.Code,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = LabelFrame
                })
                
                Label.Frame = LabelFrame
                Label.Set = function(self, newText)
                    LabelText.Text = newText
                end
                
                if subTab then
                    table.insert(subTab.Elements, Label)
                end
                table.insert(Section.Elements, Label)
                
                return Label
            end
            
            -- Keybind Element
            function Section:CreateKeybind(name, default, callback, subTab)
                local Keybind = {}
                Keybind.Value = default
                Keybind.Listening = false
                
                local KeybindFrame = Create("Frame", {
                    Name = name .. "Keybind",
                    Size = UDim2.new(1, -6, 0, 22),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    Visible = not subTab or (Section.CurrentSubTab == subTab),
                    Parent = SectionContent
                })
                AddCorner(KeybindFrame, 3)
                
                local KeybindLabel = Create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -60, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    Text = name,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.Code,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = KeybindFrame
                })
                
                local KeybindButton = Create("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(0, 50, 0, 16),
                    Position = UDim2.new(1, -55, 0.5, -8),
                    BackgroundColor3 = Theme.DarkBackground,
                    BorderSizePixel = 0,
                    Text = default and default.Name or "None",
                    TextColor3 = Theme.Text,
                    TextSize = 10,
                    Font = Enum.Font.Code,
                    Parent = KeybindFrame
                })
                AddCorner(KeybindButton, 3)
                AddStroke(KeybindButton, Theme.Border)
                
                KeybindButton.MouseButton1Click:Connect(function()
                    Keybind.Listening = true
                    KeybindButton.Text = "..."
                end)
                
                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if Keybind.Listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            Keybind.Value = input.KeyCode
                            KeybindButton.Text = input.KeyCode.Name
                            Keybind.Listening = false
                        end
                    elseif input.KeyCode == Keybind.Value and not gameProcessed then
                        if callback then callback() end
                    end
                end)
                
                Keybind.Frame = KeybindFrame
                
                if subTab then
                    table.insert(subTab.Elements, Keybind)
                end
                table.insert(Section.Elements, Keybind)
                
                return Keybind
            end
            
            table.insert(Tab.Sections, Section)
            return Section
        end
        
        table.insert(Window.Tabs, Tab)
        
        -- Select first tab by default
        if #Window.Tabs == 1 then
            TabButton.BackgroundColor3 = Theme.DarkBackground
            TabButton.TextColor3 = Theme.Text
            TabContent.Visible = true
            Window.CurrentTab = Tab
        end
        
        return Tab
    end
    
    -- Destroy window
    function Window:Destroy()
        ScreenGui:Destroy()
    end
    
    -- Toggle visibility
    function Window:Toggle()
        MainFrame.Visible = not MainFrame.Visible
    end
    
    return Window
end

return Sierra
