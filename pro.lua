local Players = game:GetService("Players")
local RealRunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local function getui()
	local s, r = pcall(function() return get_hidden_ui() or get_hidden_gui() end)
	return (s and r) or CoreGui
end

local NativeRequire = require
local RealInstance = Instance
local RealGame = game

local Basement = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("...") or RealInstance.new("Folder", LocalPlayer:FindFirstChild("PlayerGui"))
Basement.Name = "..."

local MockSSS = Basement:FindFirstChild("ServerScriptService") or RealInstance.new("Folder", Basement)
MockSSS.Name = "ServerScriptService"

local MockInstance = {}
setmetatable(MockInstance, {__index = RealInstance})

function MockInstance.new(class, parent)
	if class == "RemoteEvent" then
		local fake = {}
		local serverEvent = RealInstance.new("BindableEvent")
		local clientEvent = RealInstance.new("BindableEvent")
		fake.Name = "RemoteEvent"
		fake.ClassName = "RemoteEvent"
		fake.Parent = parent
		fake.OnServerEvent = serverEvent.Event
		fake.OnClientEvent = clientEvent.Event
		function fake:FireServer(...) serverEvent:Fire(LocalPlayer, ...) end
		function fake:FireClient(_, ...) clientEvent:Fire(...) end
		function fake:FireAllClients(...) clientEvent:Fire(...) end
		function fake:IsA(t) return t == "RemoteEvent" or t == "Instance" end
		function fake:WaitForChild(c) return self[c] or RealInstance.new("Folder") end
		return fake
	end
	return RealInstance.new(class, parent)
end

local MockRunService = {}
setmetatable(MockRunService, {
	__index = function(_, k)
		if k == "IsServer" then return function() return true end end
		if k == "IsClient" then return function() return false end end
		local v = RealRunService[k]
		if type(v) == "function" then return function(_, ...) return v(RealRunService, ...) end end
		return v
	end
})

local MockGame = {}
setmetatable(MockGame, {
	__index = function(_, k)
		if k == "ServerScriptService" or k == "ServerStorage" then return MockSSS end
		if k == "RunService" then return MockRunService end
		if k == "GetService" or k == "getService" then
			return function(_, s)
				if s == "ServerScriptService" or s == "ServerStorage" then return MockSSS end
				if s == "RunService" then return MockRunService end
				return RealGame:GetService(s)
			end
		end
		local v = RealGame[k]
		if type(v) == "function" then return function(_, ...) return v(RealGame, ...) end end
		return v
	end
})

local function Infect(func, scriptObj)
	if type(func) ~= "function" then return func end
	local env = {
		script = scriptObj,
		game = MockGame,
		workspace = workspace,
		owner = LocalPlayer,
		RunService = MockRunService,
		Instance = MockInstance,
		require = function(id) return _G.SmartRequire(id, scriptObj) end,
		_G = _G,
		shared = shared
	}
	setfenv(func, setmetatable(env, {
		__index = function(t, k)
			return rawget(t, k) or getgenv()[k] or getfenv(0)[k]
		end
	}))
	return func
end

_G.SmartRequire = function(id, caller)
	local module = nil

	if type(id) == "string" and not tonumber(id) then
		local cleanName = id:match("([^/]+)$")
		if caller and cleanName then
			module = caller:FindFirstChild(cleanName) or (caller.Parent and caller.Parent:FindFirstChild(cleanName))
		end
		if not module and cleanName then
			for _, v in pairs(MockSSS:GetDescendants()) do
				if v.Name == cleanName and v:IsA("ModuleScript") then module = v break end
			end
		end
	end

	if not module and (type(id) == "number" or tonumber(id)) then
		local s, r = pcall(function() return RealGame:GetObjects("rbxassetid://" .. tonumber(id)) end)
		if s and type(r) == "table" and r[1] then
			local container = r[1]
			container.Parent = MockSSS
			for _, v in pairs(container:GetDescendants()) do
				if (v:IsA("Script") or v:IsA("LocalScript")) and not v.Disabled then
					v.Disabled = true
					task.spawn(function()
						if v.Source and v.Source ~= "" then
							local f = loadstring(v.Source)
							if f then Infect(f, v); f() end
						end
					end)
				end
			end
			module = container:IsA("ModuleScript") and container or container:FindFirstChildWhichIsA("ModuleScript", true)
		end
	end

	if not module and typeof(id) == "Instance" then module = id end

	if module and typeof(module) == "Instance" and module:IsA("ModuleScript") then
		local src = module.Source
		if src and src ~= "" then
			local f = loadstring(src)
			if f then
				Infect(f, module)
				local result = f()
				if type(result) == "function" then return Infect(result, module) end
				return result
			end
		end
	end

	local fallback = NativeRequire(id)
	if type(fallback) == "function" then return Infect(fallback, module) end
	return fallback
end

local C = {
	bg       = Color3.fromRGB(13,  13,  16 ),
	surface  = Color3.fromRGB(18,  18,  22 ),
	surface2 = Color3.fromRGB(22,  22,  27 ),
	editor   = Color3.fromRGB(10,  10,  13 ),
	border   = Color3.fromRGB(38,  38,  46 ),
	borderLo = Color3.fromRGB(28,  28,  34 ),
	accent   = Color3.fromRGB(48,  200, 120),
	accentD  = Color3.fromRGB(28,  90,  58 ),
	accentBg = Color3.fromRGB(16,  44,  30 ),
	err      = Color3.fromRGB(220, 75,  75 ),
	errBg    = Color3.fromRGB(44,  16,  16 ),
	text     = Color3.fromRGB(205, 210, 200),
	textDim  = Color3.fromRGB(85,  85,  100),
	textFaint= Color3.fromRGB(50,  50,  62 ),
	lineNum  = Color3.fromRGB(48,  48,  60 ),
	code     = Color3.fromRGB(185, 215, 165),
}

local function stroke(p, t, col) local s = RealInstance.new("UIStroke", p); s.Thickness = t or 1; s.Color = col or C.border; return s end
local function pad(p, t, r, b, l)
	local u = RealInstance.new("UIPadding", p)
	u.PaddingTop = UDim.new(0, t or 8); u.PaddingRight = UDim.new(0, r or 8)
	u.PaddingBottom = UDim.new(0, b or 8); u.PaddingLeft = UDim.new(0, l or 8)
end

local root = RealInstance.new("ScreenGui", getui())
root.Name = "VSX"
root.ResetOnSpawn = false
root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local win = RealInstance.new("Frame", root)
win.Name = "Window"
win.AnchorPoint = Vector2.new(0.5, 0.5)
win.Size = UDim2.new(0, 520, 0, 374)
win.Position = UDim2.new(0.5, 0, 0.5, 0)
win.BackgroundColor3 = C.bg
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.ClipsDescendants = true


stroke(win, 1, C.border)

local titlebar = RealInstance.new("Frame", win)
titlebar.Size = UDim2.new(1, 0, 0, 44)
titlebar.BackgroundColor3 = C.surface
titlebar.BorderSizePixel = 0
do
	local g = RealInstance.new("UIGradient", titlebar)
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 22)),
	})
	g.Rotation = 90
end

local tbLine = RealInstance.new("Frame", titlebar)
tbLine.Size = UDim2.new(1, 0, 0, 1)
tbLine.Position = UDim2.new(0, 0, 1, -1)
tbLine.BackgroundColor3 = C.border
tbLine.BorderSizePixel = 0

local dotOuter = RealInstance.new("Frame", titlebar)
dotOuter.Size = UDim2.new(0, 8, 0, 8)
dotOuter.Position = UDim2.new(0, 15, 0.5, -4)
dotOuter.BackgroundColor3 = Color3.fromRGB(28, 140, 80)
dotOuter.BorderSizePixel = 0

local dotInner = RealInstance.new("Frame", dotOuter)
dotInner.Size = UDim2.new(0, 4, 0, 4)
dotInner.Position = UDim2.new(0.5, -2, 0.5, -2)
dotInner.BackgroundColor3 = C.accent
dotInner.BorderSizePixel = 0


local titleLabel = RealInstance.new("TextLabel", titlebar)
titleLabel.Size = UDim2.new(1, -180, 1, 0)
titleLabel.Position = UDim2.new(0, 31, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Virtual Server"
titleLabel.TextColor3 = C.text
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local badge = RealInstance.new("Frame", titlebar)
badge.Size = UDim2.new(0, 62, 0, 19)
badge.Position = UDim2.new(0, 120, 0.5, -9.5)
badge.BackgroundColor3 = C.accentBg
badge.BorderSizePixel = 0

stroke(badge, 1, C.accentD)
local badgeTxt = RealInstance.new("TextLabel", badge)
badgeTxt.Size = UDim2.new(1, 0, 1, 0)
badgeTxt.BackgroundTransparency = 1
badgeTxt.Text = "SANDBOX"
badgeTxt.TextColor3 = C.accent
badgeTxt.Font = Enum.Font.GothamBold
badgeTxt.TextSize = 9

local closeBtn = RealInstance.new("TextButton", titlebar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundColor3 = C.surface2
closeBtn.Text = ""
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false

stroke(closeBtn, 1, C.borderLo)

local function xBar(rot)
	local b = RealInstance.new("Frame", closeBtn)
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Size = UDim2.new(0, 11, 0, 1.5)
	b.Position = UDim2.new(0.5, 0, 0.5, 0)
	b.BackgroundColor3 = Color3.fromRGB(110, 110, 125)
	b.BorderSizePixel = 0
	b.Rotation = rot
	
	return b
end
local x1 = xBar(45)
local x2 = xBar(-45)

closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.13), {BackgroundColor3 = Color3.fromRGB(155, 38, 38)}):Play()
	TweenService:Create(x1, TweenInfo.new(0.13), {BackgroundColor3 = Color3.new(1,1,1)}):Play()
	TweenService:Create(x2, TweenInfo.new(0.13), {BackgroundColor3 = Color3.new(1,1,1)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.13), {BackgroundColor3 = C.surface2}):Play()
	TweenService:Create(x1, TweenInfo.new(0.13), {BackgroundColor3 = Color3.fromRGB(110,110,125)}):Play()
	TweenService:Create(x2, TweenInfo.new(0.13), {BackgroundColor3 = Color3.fromRGB(110,110,125)}):Play()
end)
closeBtn.MouseButton1Click:Connect(function()
	TweenService:Create(win, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {Size = UDim2.new(0,520,0,0), Position = UDim2.new(0.5,0,0.5,20)}):Play()
	task.delay(0.2, function() root:Destroy() end)
end)

local body = RealInstance.new("Frame", win)
body.Size = UDim2.new(1, -24, 1, -60)
body.Position = UDim2.new(0, 12, 0, 52)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0

local editorWrap = RealInstance.new("Frame", body)
editorWrap.Size = UDim2.new(1, 0, 1, -48)
editorWrap.BackgroundColor3 = C.editor
editorWrap.BorderSizePixel = 0
editorWrap.ClipsDescendants = true

stroke(editorWrap, 1, C.border)

local gutter = RealInstance.new("Frame", editorWrap)
gutter.Size = UDim2.new(0, 38, 1, 0)
gutter.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
gutter.BorderSizePixel = 0
do
	local g = RealInstance.new("UIGradient", gutter)
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 19)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 11, 14)),
	})
	g.Rotation = 180
end

local gutDiv = RealInstance.new("Frame", editorWrap)
gutDiv.Size = UDim2.new(0, 1, 1, 0)
gutDiv.Position = UDim2.new(0, 38, 0, 0)
gutDiv.BackgroundColor3 = C.border
gutDiv.BorderSizePixel = 0

local lineNumbers = RealInstance.new("TextLabel", gutter)
lineNumbers.Size = UDim2.new(1, 0, 1, 0)
lineNumbers.BackgroundTransparency = 1
lineNumbers.TextColor3 = C.lineNum
lineNumbers.Font = Enum.Font.Code
lineNumbers.TextSize = 13
lineNumbers.TextXAlignment = Enum.TextXAlignment.Center
lineNumbers.TextYAlignment = Enum.TextYAlignment.Top
lineNumbers.Text = "1"
pad(lineNumbers, 10, 4, 10, 0)

local editor = RealInstance.new("TextBox", editorWrap)
editor.Size = UDim2.new(1, -46, 1, 0)
editor.Position = UDim2.new(0, 44, 0, 0)
editor.BackgroundTransparency = 1
editor.TextColor3 = C.code
editor.PlaceholderText = "-- enter script..."
editor.PlaceholderColor3 = C.textFaint
editor.Font = Enum.Font.Code
editor.TextSize = 13
editor.MultiLine = true
editor.ClearTextOnFocus = false
editor.TextXAlignment = Enum.TextXAlignment.Left
editor.TextYAlignment = Enum.TextYAlignment.Top
editor.TextWrapped = false
editor.ClipsDescendants = true
editor.Text = 'require(100263845596551)("fffdwdwdadwdwd", ColorSequence.new(Color3.fromRGB(71, 148, 253), Color3.fromRGB(71, 253, 160)), "Standard")'
pad(editor, 10, 8, 10, 6)

local function updateLines()
	local n = 1
	for _ in editor.Text:gmatch("\n") do n += 1 end
	local t = {}; for i = 1, n do t[i] = tostring(i) end
	lineNumbers.Text = table.concat(t, "\n")
end
editor:GetPropertyChangedSignal("Text"):Connect(updateLines)
updateLines()

local footer = RealInstance.new("Frame", body)
footer.Size = UDim2.new(1, 0, 0, 36)
footer.Position = UDim2.new(0, 0, 1, -36)
footer.BackgroundTransparency = 1

local statusPill = RealInstance.new("Frame", footer)
statusPill.Size = UDim2.new(1, -120, 0, 30)
statusPill.Position = UDim2.new(0, 0, 0.5, -15)
statusPill.BackgroundColor3 = C.surface2
statusPill.BorderSizePixel = 0

stroke(statusPill, 1, C.borderLo)

local statusDot = RealInstance.new("Frame", statusPill)
statusDot.Size = UDim2.new(0, 6, 0, 6)
statusDot.Position = UDim2.new(0, 11, 0.5, -3)
statusDot.BackgroundColor3 = C.textFaint
statusDot.BorderSizePixel = 0


local statusLabel = RealInstance.new("TextLabel", statusPill)
statusLabel.Size = UDim2.new(1, -28, 1, 0)
statusLabel.Position = UDim2.new(0, 24, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready"
statusLabel.TextColor3 = C.textDim
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd

local execBtn = RealInstance.new("TextButton", footer)
execBtn.Size = UDim2.new(0, 110, 0, 30)
execBtn.Position = UDim2.new(1, -110, 0.5, -15)
execBtn.BackgroundColor3 = C.accentBg
execBtn.Text = ""
execBtn.BorderSizePixel = 0
execBtn.AutoButtonColor = false

stroke(execBtn, 1, C.accentD)

local execGrad = RealInstance.new("UIGradient", execBtn)
execGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 54, 37)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 40, 26)),
})
execGrad.Rotation = 90

-- play triangle: two overlapping frames clipped to suggest a triangle
local triContainer = RealInstance.new("Frame", execBtn)
triContainer.Size = UDim2.new(0, 10, 0, 10)
triContainer.Position = UDim2.new(0, 14, 0.5, -5)
triContainer.BackgroundTransparency = 1
triContainer.BorderSizePixel = 0
triContainer.ClipsDescendants = true

local triBase = RealInstance.new("Frame", triContainer)
triBase.Size = UDim2.new(0, 9, 0, 9)
triBase.Position = UDim2.new(0, 0, 0.5, -4.5)
triBase.BackgroundColor3 = C.accent
triBase.BorderSizePixel = 0
triBase.Rotation = 45


local triCut = RealInstance.new("Frame", triContainer)
triCut.Size = UDim2.new(0, 7, 0, 7)
triCut.Position = UDim2.new(0, -5, 0.5, -3.5)
triCut.BackgroundColor3 = C.accentBg
triCut.BorderSizePixel = 0
triCut.Rotation = 45

local execLabel = RealInstance.new("TextLabel", execBtn)
execLabel.Size = UDim2.new(1, -30, 1, 0)
execLabel.Position = UDim2.new(0, 28, 0, 0)
execLabel.BackgroundTransparency = 1
execLabel.Text = "Execute"
execLabel.TextColor3 = C.accent
execLabel.Font = Enum.Font.GothamBold
execLabel.TextSize = 12

local execHover = false
execBtn.MouseEnter:Connect(function()
	execHover = true
	TweenService:Create(execBtn, TweenInfo.new(0.13), {BackgroundColor3 = C.accentD}):Play()
	TweenService:Create(triCut, TweenInfo.new(0.13), {BackgroundColor3 = C.accentD}):Play()
end)
execBtn.MouseLeave:Connect(function()
	execHover = false
	TweenService:Create(execBtn, TweenInfo.new(0.13), {BackgroundColor3 = C.accentBg}):Play()
	TweenService:Create(triCut, TweenInfo.new(0.13), {BackgroundColor3 = C.accentBg}):Play()
end)

local function setStatus(msg, state)
	statusLabel.Text = msg
	local dotCol, pillCol, textCol
	if state == "error" then
		dotCol, pillCol, textCol = C.err, C.errBg, C.err
	elseif state == "ok" then
		dotCol, pillCol, textCol = C.accent, C.accentBg, C.accent
	elseif state == "running" then
		local y = Color3.fromRGB(190, 185, 80)
		dotCol, pillCol, textCol = y, Color3.fromRGB(36, 36, 14), y
	else
		dotCol, pillCol, textCol = C.textFaint, C.surface2, C.textDim
	end
	TweenService:Create(statusDot,  TweenInfo.new(0.14), {BackgroundColor3 = dotCol}):Play()
	TweenService:Create(statusPill, TweenInfo.new(0.14), {BackgroundColor3 = pillCol}):Play()
	TweenService:Create(statusLabel,TweenInfo.new(0.14), {TextColor3 = textCol}):Play()
end

execBtn.MouseButton1Click:Connect(function()
	getgenv()._G.ServerReady = true
	getgenv().shared.ServerInitialized = true
	getgenv()._G.OwnerId = LocalPlayer.UserId

	local src = editor.Text
	if src == "" then setStatus("No input provided.", "error"); return end

	local f, err = loadstring(src)
	if not f then setStatus(tostring(err), "error"); return end

	setStatus("Running...", "running")
	Infect(f, RealInstance.new("Script", MockSSS))
	task.spawn(function()
		local ok, runErr = pcall(f)
		if ok then
			setStatus("Executed successfully.", "ok")
		else
			setStatus(tostring(runErr), "error")
		end
	end)
end)

win.BackgroundTransparency = 1
win.Size = UDim2.new(0, 520, 0, 10)

TweenService:Create(win, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
	BackgroundTransparency = 0,
	Size = UDim2.new(0, 520, 0, 374),
}):Play()
