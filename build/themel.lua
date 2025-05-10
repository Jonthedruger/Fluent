local run = function(f) f() end local cloneref = cloneref or function(o) return o end

local playersService = cloneref(game:GetService('Players')) local inputService = cloneref(game:GetService('UserInputService')) local replicatedStorage = cloneref(game:GetService('ReplicatedStorage')) local runService = cloneref(game:GetService('RunService'))

local gameCamera = workspace.CurrentCamera local lplr = playersService.LocalPlayer local vape = shared.vape

local bd = {} local store = {blocks = {}, serverBlocks = {}}

local function parsePositions(v, func) if v:IsA('Part') then local start = -(v.Size / 2) + Vector3.new(1.5, 1.5, 1.5) for x = 0, v.Size.X - 1, 3 do for y = 0, v.Size.Y - 1, 3 do for z = 0, v.Size.Z - 1, 3 do local vec = start + Vector3.new(x, y, z) vec = v.CFrame:PointToWorldSpace(vec) vec = Vector3.new(math.round(vec.X), math.round(vec.Y), math.round(vec.Z)) func(vec) end end end end end

local Knit = require(replicatedStorage.Modules.Knit.Client) if not debug.getupvalue(Knit.Start, 1) then repeat task.wait() until debug.getupvalue(Knit.Start, 1) end

bd = setmetatable({ Blink = require(replicatedStorage.Blink.Client), CombatService = Knit.GetService('CombatService'), CombatConstants = require(replicatedStorage.Constants.Melee), Knit = Knit, Entity = require(replicatedStorage.Modules.Entity), ServerData = require(replicatedStorage.Modules.ServerData) }, { __index = function(self, i) rawset(self, i, i:find('Service') and Knit.GetService(i) or Knit.GetController(i)) return rawget(self, i) end })

task.spawn(function() local map = workspace:WaitForChild('Map', 99999) if map and vape.Loaded ~= nil then vape:Clean(map.DescendantAdded:Connect(function(v) parsePositions(v, function(pos) store.blocks[pos] = v end) end)) vape:Clean(map.DescendantRemoving:Connect(function(v) parsePositions(v, function(pos) if store.blocks[pos] == v then store.blocks[pos] = nil store.serverBlocks[pos] = nil end end) end)) for _, v in map:GetDescendants() do parsePositions(v, function(pos) store.blocks[pos] = v store.serverBlocks[pos] = v end) end end end)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({ Title = "Literally Not Skibidi", Footer = "v1.0.0", ToggleKeybind = Enum.KeyCode.RightControl, Center = true, AutoShow = true, Resizable = true })

local Combat = Window:AddTab("Main", "skull") local CB = Combat:AddLeftTabbox("Combat") local CT = CB:AddTab("Combat")

local function GetTool() return lplr.Character and lplr.Character:FindFirstChildWhichIsA('Tool', true) or nil end

local function IsInFOV(targetPos, angle) local camDir = gameCamera.CFrame.LookVector local toTarget = (targetPos - gameCamera.CFrame.Position).Unit local deg = math.deg(math.acos(camDir:Dot(toTarget))) return deg <= angle end

local function GetClosestTarget(range, fov) local closest, closestDist = nil, range for _, v in pairs(playersService:GetPlayers()) do if v ~= lplr and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then local pos = v.Character.HumanoidRootPart.Position local dist = (pos - lplr.Character.HumanoidRootPart.Position).Magnitude if dist <= closestDist and IsInFOV(pos, fov) then closest = v closestDist = dist end end end return closest end

local RangeKa = 14 local KaAngle = 90 local KillAuraRunning = false local SwingDelay = 0 local infJump, infJumpDebounce

local Lel = CT:AddSlider("ReachSlider", { Text = "Range", Default = 14, Min = 1, Max = 30, Rounding = 1, Callback = function(v) RangeKa = v end })

local AngleSlider = CT:AddSlider("FOVSlider", { Text = "Attack Angle (FOV)", Default = 90, Min = 1, Max = 360, Rounding = 1, Callback = function(v) KaAngle = v end })

local KA = CT:AddToggle("KillauraToggle", { Text = "Killaura", Default = false, Tooltip = "Auto attack closest target", Callback = function(v) KillAuraRunning = v if v then task.spawn(function() while KillAuraRunning do local tool = GetTool() if tool and tool:HasTag("Sword") and lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart") then local target = GetClosestTarget(RangeKa, KaAngle) if target then local ent = bd.Entity.FindByCharacter(target.Character) if ent then bd.Blink.item_action.attack_entity.fire({ target_entity_id = ent.Id, is_crit = true, weapon_name = tool.Name }) if SwingDelay < tick() then SwingDelay = tick() + 0.25 lplr.Character.Humanoid.Animator:LoadAnimation(tool.Animations.Swing):Play() bd.ViewmodelController:PlayAnimation(tool.Name) end end end end task.wait() end end) end end })

local ReachRange local oldReach

local Rc = CT:AddSlider("Reach", { Text = "Reach", Default = 1, Min = 0, Max = 16, Rounding = 1, Callback = function(v) ReachRange = v oldReach = rawget(bd.CombatConstants, 'REACH_IN_STUDS') rawset(bd.CombatConstants, 'REACH_IN_STUDS', ReachRange) rawset(bd.Entity.LocalEntity, 'Reach', ReachRange) end })

local RH = CT:AddToggle("ReachToggle", { Text = "Reach", Default = false, Tooltip = "Extend hit reach", Callback = function(v) if not v and oldReach then rawset(bd.CombatConstants, 'REACH_IN_STUDS', oldReach) rawset(bd.Entity.LocalEntity, 'Reach', oldReach) oldReach = nil end end })

local critHook local Crit = CT:AddToggle("AutoCrit", { Text = "Auto Critical", Default = false, Tooltip = "Forces critical attacks", Callback = function(v) if v then critHook = hookfunction(bd.Blink.item_action.attack_entity.fire, function(...) local data = ... if type(data) == 'table' then rawset(data, 'is_crit', true) end return critHook(...) end) else if critHook then hookfunction(bd.Blink.item_action.attack_entity.fire, critHook) critHook = nil end end end })

local AntiSlowOld = {} local AntiSlow = CT:AddToggle("AntiSlow", { Text = "Anti Slow", Default = false, Tooltip = "Bypasses movement slowing", Callback = function(callback) local func = debug.getproto(bd.MovementController.KnitStart, 5) if callback then AntiSlowOld = debug.getconstants(func) for i, v in ipairs(AntiSlowOld) do debug.setconstant(func, i, v == 'IsSneaking' and v or 'IsSpectating') end else for i, v in ipairs(AntiSlowOld) do debug.setconstant(func, i, v) end table.clear(AntiSlowOld) end end })

local InfJump = CT:AddToggle("InfJump", { Text = "Infinite Jump", Default = false, Tooltip = "Jump infinitely without touching ground", Callback = function(v) if infJump then infJump:Disconnect() end infJumpDebounce = false if v then infJump = inputService.JumpRequest:Connect(function() if not infJumpDebounce then infJumpDebounce = true lplr.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping) task.wait() infJumpDebounce = false end end) end end })

local VirtualInputManager = game:GetService("VirtualInputManager")

VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
task.wait()
VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place") -- if the game has multiple places inside of it (for example: DOORS)
-- you can use this to save configs for those places separately
-- The path in this script would be: MyScriptHub/specific-game/settings/specific-place
-- [ This is optional ]

-- Builds our config menu on the right side of our tab
SaveManager:BuildConfigSection(Tabs.Combat)

-- Builds our theme menu (with plenty of built in themes) on the left side
-- NOTE: you can also call ThemeManager:ApplyToGroupbox to add it to a specific groupbox
ThemeManager:ApplyToTab(Tabs.Combat)

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()
