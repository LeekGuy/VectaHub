-- Press Start 2P everywhere. Roblox has no built-in enum for it, so the TTF is
-- downloaded once into Vecta/cache and registered as a custom font family through
-- getcustomasset. If the executor can't do that (or the download fails) the
-- built-in pixel font Arcade is used instead.
local PIXEL_URL = "https://raw.githubusercontent.com/google/fonts/main/ofl/pressstart2p/PressStart2P-Regular.ttf"
local PIXEL_CUSTOM = false

local function loadpixelface()
	if
		type(getcustomasset) ~= "function"
		or type(writefile) ~= "function"
		or type(isfile) ~= "function"
	then
		return nil
	end
	local ok, face = pcall(function()
		pcall(function()
			if not isfolder("Vecta") then
				makefolder("Vecta")
			end
			if not isfolder("Vecta/cache") then
				makefolder("Vecta/cache")
			end
		end)
		local ttf = "Vecta/cache/PressStart2P-Regular.ttf"
		local json = "Vecta/cache/PressStart2P.json"
		local valid = false
		if isfile(ttf) and type(readfile) == "function" then
			local head = readfile(ttf):sub(1, 4)
			valid = head == "\0\1\0\0" or head == "true" or head == "OTTO"
		end
		if not valid then
			local body = game:HttpGet(PIXEL_URL, true)
			local head = type(body) == "string" and body:sub(1, 4) or ""
			if not (head == "\0\1\0\0" or head == "true" or head == "OTTO") then
				return nil
			end
			writefile(ttf, body)
		end
		local family = {
			name = "Press Start 2P",
			faces = {
				{ name = "Regular", weight = 400, style = "normal", assetId = getcustomasset(ttf) },
			},
		}
		writefile(json, game:GetService("HttpService"):JSONEncode(family))
		return Font.new(getcustomasset(json), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	end)
	return ok and face or nil
end

local FONT_BOLD = loadpixelface()
if FONT_BOLD then
	PIXEL_CUSTOM = true
else
	FONT_BOLD = Font.fromEnum(Enum.Font.Arcade)
end
local FONT_MEDIUM = FONT_BOLD

-- Press Start 2P is about twice as wide as the old font at the same size, so every
-- text size is scaled down (8 is its native pixel size, the smallest that stays readable).
local PIXEL_SCALE = 0.65
-- Press Start 2P has a line height of exactly 1 em, so wrapped lines touch each
-- other; a taller LineHeight gives them room to breathe.
local PIXEL_LINEHEIGHT = 1.6
local function ts(n)
	n = tonumber(n) or 12
	if not PIXEL_CUSTOM then
		return n
	end
	return math.max(8, math.floor(n * PIXEL_SCALE + 0.5))
end

local sv = {
	http = game:GetService("HttpService"),
	uis = game:GetService("UserInputService"),
	ts = game:GetService("TweenService"),
	plrs = game:GetService("Players"),
	coregui = game:GetService("CoreGui"),
	sg = game:GetService("StarterGui"),
	textservice = game:GetService("TextService"),
}

-- Text measuring that understands the pixel font. Press Start 2P is monospaced
-- (1 em per glyph), so it is measured by hand; GetTextSize only takes Enum.Font.
local function measure(text, size, font, bound)
	text = tostring(text or "")
	if PIXEL_CUSTOM and typeof(font) == "Font" then
		size = ts(size)
		local maxchars = math.max(1, math.floor(bound.X / size))
		local lines, widest = 0, 0
		for paragraph in (text .. "\n"):gmatch("(.-)\n") do
			local used = 0
			local rowcount = 1
			for word in paragraph:gmatch("%S+") do
				local len = utf8.len(word) or #word
				while len > maxchars do
					if used > 0 then
						widest = math.max(widest, used)
						rowcount = rowcount + 1
						used = 0
					end
					widest = math.max(widest, maxchars)
					rowcount = rowcount + 1
					len = len - maxchars
				end
				if used == 0 then
					used = len
				elseif used + 1 + len <= maxchars then
					used = used + 1 + len
				else
					widest = math.max(widest, used)
					rowcount = rowcount + 1
					used = len
				end
			end
			widest = math.max(widest, used)
			lines = lines + rowcount
		end
		return Vector2.new(widest * size, math.max(1, lines) * size * PIXEL_LINEHEIGHT)
	end
	if typeof(font) ~= "EnumItem" then
		font = Enum.Font.Arcade
	end
	return sv.textservice:GetTextSize(text, size, font, bound)
end

local theme = {
	Accent = Color3.fromRGB(232, 232, 238),
	AccentText = Color3.fromRGB(14, 14, 17),
	Backdrop = Color3.fromRGB(9, 9, 11),
	Sidebar = Color3.fromRGB(13, 13, 16),
	Card = Color3.fromRGB(19, 19, 23),
	Element = Color3.fromRGB(27, 27, 32),
	ElementHover = Color3.fromRGB(36, 36, 43),
	Track = Color3.fromRGB(46, 46, 54),
	Stroke = Color3.fromRGB(42, 42, 50),
	StrokeSoft = Color3.fromRGB(31, 31, 37),
	Text = Color3.fromRGB(238, 238, 243),
	SubText = Color3.fromRGB(162, 162, 174),
	Dim = Color3.fromRGB(116, 116, 128),
	Good = Color3.fromRGB(74, 222, 128),
	Bad = Color3.fromRGB(248, 113, 113),
	Gold = Color3.fromRGB(245, 196, 81),
	Blue = Color3.fromRGB(96, 165, 250),
	Row = Color3.fromRGB(25, 25, 27),
	Inner = Color3.fromRGB(40, 40, 43),
	InnerHover = Color3.fromRGB(52, 52, 56),
	Field = Color3.fromRGB(43, 43, 46),
	Bar = Color3.fromRGB(66, 66, 70),
	Pill = Color3.fromRGB(20, 20, 23),
	TabActive = Color3.fromRGB(29, 29, 32),
	Option = Color3.fromRGB(34, 34, 37),
	ChatBg = Color3.fromRGB(15, 15, 17),
	Mine = Color3.fromRGB(29, 29, 32),
	Mention = Color3.fromRGB(38, 33, 22),
	Box = Color3.fromRGB(16, 16, 18),
}

local function elevate()
	local setfn = (type(setthreadidentity) == "function" and setthreadidentity)
		or (type(set_thread_identity) == "function" and set_thread_identity)
		or (type(setidentity) == "function" and setidentity)
		or (type(setthreadcontext) == "function" and setthreadcontext)
		or (type(set_thread_context) == "function" and set_thread_context)
		or (type(syn) == "table" and type(syn.set_thread_identity) == "function" and syn.set_thread_identity)
	if setfn then
		pcall(setfn, 8)
	end
end

local function hexcolor(color)
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function textheight(text, size, font, width, maxheight)
	local ok, bounds = pcall(function()
		return measure(tostring(text or ""), size, font, Vector2.new(math.max(20, width), 100000))
	end)
	if ok and bounds and bounds.Y > 0 then
		return math.min(maxheight or 100000, math.ceil(bounds.Y) + 2)
	end
	return size
end

-- One-line width of plain text, for controls that must size to their label.
local function textwidth(text, size, font)
	local ok, bounds = pcall(function()
		return measure(tostring(text or ""), size, font, Vector2.new(100000, 100000))
	end)
	if ok and bounds and bounds.X > 0 then
		return math.ceil(bounds.X)
	end
	return math.ceil(#tostring(text or "") * size * 0.6)
end

local function escaperich(text)
	return (tostring(text or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function clipboardread()
	local fn = getclipboard or getclipboardtext or readclipboard
	if type(fn) ~= "function" then
		return nil
	end
	local ok, value = pcall(fn)
	if ok and type(value) == "string" and value ~= "" then
		return value
	end
	return nil
end

local function clipboardwrite(text)
	local fn = setclipboard or toclipboard or writeclipboard
	if type(fn) ~= "function" then
		return false
	end
	return (pcall(fn, tostring(text)))
end

local lucideurl = "https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"

-- Official Lucide library (same loader as Bolong): Lucide.GetAsset(name, size)
local Lucide
do
	local ok, result = pcall(function()
		return loadstring(game:HttpGet(lucideurl))()
	end)
	if ok and result then
		Lucide = result
	else
		warn("[Vecta] Failed to load official Lucide icons: " .. tostring(result))
	end
end

local LucideAssetCache = {}

local function getlucideasset(name, size)
	if not Lucide then
		return nil
	end
	local key = name .. ":" .. tostring(size or 256)
	local cached = LucideAssetCache[key]
	if cached ~= nil then
		return cached or nil
	end
	local ok, asset = pcall(function()
		return Lucide.GetAsset(name, size)
	end)
	if ok and asset then
		LucideAssetCache[key] = asset
		return asset
	end
	LucideAssetCache[key] = false
	return nil
end


local iconaliases = {
	player = "user",
	players = "users",
	next = "chevron-right",
	main = "home",
	home = "home",
	config = "settings",
	setting = "settings",
	settings = "settings",
	farm = "sprout",
	auto = "repeat",
	shop = "shopping-cart",
	store = "store",
	pet = "paw-print",
	pets = "paw-print",
	misc = "layout-grid",
	visual = "eye",
	teleport = "map-pin",
	quest = "scroll",
	fishing = "fish",
	event = "calendar",
	egg = "egg",
	chat = "message-circle",
	donator = "crown",
	key = "key",
	discord = "message-square",
	info = "info",
	forum = "messages-square",
}

local fallbackicons = {
	["home"] = "rbxassetid://6340513838",
	["menu"] = "rbxassetid://6340513838",
	["settings"] = "rbxassetid://70386228443175",
	["cog"] = "rbxassetid://70386228443175",
	["eye"] = "rbxassetid://14321059114",
	["user"] = "rbxassetid://108483430622128",
	["users"] = "rbxassetid://12120698352",
	["shopping-cart"] = "rbxassetid://128874923961846",
	["store"] = "rbxassetid://4985385964",
	["backpack"] = "rbxassetid://8601111810",
	["sword"] = "rbxassetid://82472368671405",
	["swords"] = "rbxassetid://82472368671405",
	["repeat"] = "rbxassetid://122032243989747",
	["refresh-cw"] = "rbxassetid://122032243989747",
	["map-pin"] = "rbxassetid://17824309485",
	["compass"] = "rbxassetid://125300760963399",
	["gamepad-2"] = "rbxassetid://84173963561612",
	["scroll"] = "rbxassetid://114127804740858",
	["crosshair"] = "rbxassetid://12614416478",
	["bar-chart"] = "rbxassetid://12094445329",
	["activity"] = "rbxassetid://12094445329",
	["star"] = "rbxassetid://107005941750079",
	["skull"] = "rbxassetid://17313330026",
	["credit-card"] = "rbxassetid://18747025078",
	["scan"] = "rbxassetid://109869955247116",
	["search"] = "rbxassetid://8447654914",
	["alert-triangle"] = "rbxassetid://73186275216515",
	["help-circle"] = "rbxassetid://17510196486",
	["lightbulb"] = "rbxassetid://16833255748",
	["info"] = "rbxassetid://16833255748",
	["messages-square"] = "rbxassetid://12120698352",
	["zap"] = "rbxassetid://13321880293",
	["droplet"] = "rbxassetid://100076212630732",
	["play"] = "rbxassetid://108886429866687",
	["chevron-right"] = "rbxassetid://12662718374",
	["fish"] = "rbxassetid://97167558235554",
	["globe"] = "rbxassetid://137601480983962",
	["mouse-pointer-click"] = "rbxassetid://7734010488",
	["egg"] = "rbxassetid://8601111810",
	["gift"] = "rbxassetid://18747025078",
}

local function applyicon(image, name, size)
	if not image then
		return false
	end
	name = tostring(name or "")
	if name == "" then
		image.Image = ""
		image.ImageRectOffset = Vector2.new(0, 0)
		image.ImageRectSize = Vector2.new(0, 0)
		return false
	end
	if tonumber(name) then
		name = "rbxassetid://" .. name
	end
	if name:match("^rbxassetid://") or name:match("^rbxasset://") or name:match("^http") or name:match("^rbxthumb://") then
		image.Image = name
		image.ImageRectOffset = Vector2.new(0, 0)
		image.ImageRectSize = Vector2.new(0, 0)
		return true
	end

	name = iconaliases[name:lower()] or name:lower()

	local asset = getlucideasset(name, size or 48)
	if asset then
		image.Image = asset.Url
		image.ImageRectOffset = asset.ImageRectOffset
		image.ImageRectSize = asset.ImageRectSize
		return true
	end

	-- only used when the official library failed to load
	local fallback = fallbackicons[name] or fallbackicons[(name:gsub("_", "-"))]
	image.Image = fallback or ""
	image.ImageRectOffset = Vector2.new(0, 0)
	image.ImageRectSize = Vector2.new(0, 0)
	return fallback ~= nil
end

-- Roblox can't show an https:// image directly: download it once into
-- Vecta/cache (kept even after the link expires) and load it with getcustomasset.
local function urlimage(url, cacheonly)
	if type(getcustomasset) ~= "function" or type(writefile) ~= "function" then
		return nil
	end
	local name = tostring(url):gsub("[?#].*$", ""):match("([^/]+)$") or "image.png"
	name = name:gsub("[^%w%._%-]", "")
	if not name:match("%.%w+$") then
		name = name .. ".png"
	end
	local path = "Vecta/cache/" .. name
	pcall(function()
		if not isfolder("Vecta") then
			makefolder("Vecta")
		end
		if not isfolder("Vecta/cache") then
			makefolder("Vecta/cache")
		end
	end)
	local cached = false
	pcall(function()
		cached = isfile(path)
	end)
	if not cached and cacheonly then
		return nil
	end
	if not cached then
		local ok, body = pcall(function()
			return game:HttpGet(url, true)
		end)
		if not ok or type(body) ~= "string" or #body < 64 then
			return nil
		end
		if not pcall(writefile, path, body) then
			return nil
		end
	end
	local ok, asset = pcall(getcustomasset, path)
	return ok and asset or nil
end


local function executorname()
	local ok, name = pcall(function()
		if type(identifyexecutor) == "function" then
			return (identifyexecutor())
		end
		if type(getexecutorname) == "function" then
			return getexecutorname()
		end
		return nil
	end)
	name = ok and name and tostring(name) or ""
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		return game:GetService("RunService"):IsStudio() and "Studio" or "Unknown"
	end
	return name
end

if getgenv().ChloeX_Running then
	if getgenv().ChloeX_ReopenPrompt then
		return
	end

	getgenv().ChloeX_ReopenPrompt = true

	local bind = Instance.new("BindableFunction")
	local result = nil

	bind.OnInvoke = function(answer)
		result = answer == "Re-Open"
	end

	pcall(function()
		sv.sg:SetCore("SendNotification", {
			Title = "Vecta Already Opened",
			Text = "Destroy and Re-Open Vecta?",
			Icon = "rbxassetid://100997912316573",
			Duration = 10,
			Button1 = "Re-Open",
			Button2 = "Cancel",
			Callback = bind,
		})
	end)

	task.delay(10, function()
		if result == nil then
			result = false
		end
	end)

	repeat
		task.wait()
	until result ~= nil

	bind:Destroy()
	getgenv().ChloeX_ReopenPrompt = nil

	if not result then
		return
	end

	if getgenv().ChloeX_Instance then
		pcall(function()
			getgenv().ChloeX_Instance:DestroyGui()
		end)
	else
		for _, name in ipairs({
			"Chloeex",
			"ToggleUIButton",
			"OverlayGui",
			"NotifyGui",
			"AnnounceGui",
			"FloatingGui",
		}) do
			local old = sv.coregui:FindFirstChild(name)
			if old then
				old:Destroy()
			end
		end

		getgenv().ChloeX_Running = nil
		getgenv().ChloeX_ReopenPrompt = nil
		getgenv().ChloeX_Instance = nil
	end
end

getgenv().ChloeX_Running = true

local allConnections = {}
local resizeDebounceTable = {}
local heartbeatCallbacks = {}
local heartbeatConnection = nil

local function trackConnection(conn, name)
	if not conn then
		return nil
	end
	table.insert(allConnections, { conn = conn, name = name or "unnamed" })
	return conn
end

local function disconnectAll()
	for _, entry in ipairs(allConnections) do
		if entry.conn then
			pcall(function()
				entry.conn:Disconnect()
			end)
		end
	end
	allConnections = {}
end

local function registerHeartbeat(name, callback)
	if not name or not callback then
		return
	end
	heartbeatCallbacks[name] = callback
	if not heartbeatConnection then
		heartbeatConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
			for _, cb in pairs(heartbeatCallbacks) do
				if cb then
					pcall(function()
						cb(dt)
					end)
				end
			end
		end)
	end
end

local function unregisterHeartbeat(name)
	heartbeatCallbacks[name] = nil
	if next(heartbeatCallbacks) == nil and heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
end

local function debounceResize(key, callback, delay)
	delay = delay or 0.1
	if resizeDebounceTable[key] then
		task.cancel(resizeDebounceTable[key])
	end
	resizeDebounceTable[key] = task.delay(delay, function()
		pcall(function()
			callback()
		end)
		resizeDebounceTable[key] = nil
	end)
end

local config = { gamefolder = nil, autoloadfile = nil, data = {}, elements = {}, version = nil, current = nil, loaded = false }

local metakeys = {
	["Input_Config Name"] = true,
	["Input_External Config"] = true,
	["Input_Import JSON"] = true,
	["Dropdown_Saved Configs"] = true,
	["Dropdown_Account Config"] = true,
	["Toggle_Auto Save"] = true,
	["Toggle_Auto Load"] = true,
	["Toggle_Per-Account Autoload"] = true,
}

local function packconfig(data)
	local out = {}
	for key, value in pairs(data or {}) do
		local keep = not metakeys[key]
		if value == false or value == nil then
			keep = false
		elseif type(value) == "string" and value:gsub("%s+", "") == "" then
			keep = false
		elseif type(value) == "table" and next(value) == nil then
			keep = false
		end
		if keep then
			out[key] = value
		end
	end
	return out
end

local function missingdefault(key, element)
	if key:match("^Toggle_") then
		return false
	elseif key:match("^Input_") then
		return ""
	elseif key:match("^Dropdown_") then
		if type(element.Value) == "table" then
			return {}
		end
		return nil
	end
	return nil
end
local instance = {}
local classes = {
	"ScreenGui",
	"BillboardGui",
	"SurfaceGui",
	"ViewportFrame",
	"CanvasGroup",
	"Frame",
	"ScrollingFrame",
	"VideoFrame",
	"TextLabel",
	"TextButton",
	"TextBox",
	"ImageLabel",
	"ImageButton",
	"UIListLayout",
	"UIGridLayout",
	"UITableLayout",
	"UIPageLayout",
	"UIFlexItem",
	"UIAspectRatioConstraint",
	"UISizeConstraint",
	"UITextSizeConstraint",
	"UIPadding",
	"UICorner",
	"UIStroke",
	"UIGradient",
	"Folder",
	"Configuration",
	"BoolValue",
	"IntValue",
	"NumberValue",
	"StringValue",
	"Color3Value",
	"Vector3Value",
	"CFrameValue",
	"ObjectValue",
	"UIScale",
	"UITextSizeConstraint",
	"LocalizationTable",
}
local draggable = {
	dragging = false,
	resizing = false,
	draginput = nil,
	resizeinput = nil,
	dragstart = nil,
	resizestart = nil,
	startpos = nil,
	startsize = nil,
	minx = 420,
	miny = 260,
	defx = 720,
	defy = 460,
}

local sliderDrag = { active = nil, lastUpdateTime = 0 }
local sliderUpdateThrottle = 0.005

trackConnection(
	sv.uis.InputChanged:Connect(function(input)
		if
			sliderDrag.active
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local now = tick()
			if (now - sliderDrag.lastUpdateTime) > sliderUpdateThrottle then
				sliderDrag.active.setfromx(input.Position.X)
				sliderDrag.lastUpdateTime = now
			end
		end
	end),
	"global.sliderDrag.InputChanged"
)

trackConnection(
	sv.uis.InputEnded:Connect(function(input)
		if
			sliderDrag.active
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			sliderDrag.active.hidebubble()
			sliderDrag.active = nil
		end
	end),
	"global.sliderDrag.InputEnded"
)

for _, class in ipairs(classes) do
	instance[class:lower()] = function(parent)
		local obj = Instance.new(class)
		if class == "TextLabel" or class == "TextButton" or class == "TextBox" then
			obj.FontFace = FONT_MEDIUM
			if PIXEL_CUSTOM then
				obj.LineHeight = PIXEL_LINEHEIGHT
			end
		end
		obj.Parent = parent
		return obj
	end
end

local sliceimage = "rbxassetid://3570695787"
local rowalpha = 0

-- Rounded row background. Normally a sliced ImageLabel child named "Bg", but
-- that child draws OVER its parent (ZIndexBehavior Sibling), which hid every
-- TextButton's own text, and inside a UIListLayout it became the first list
-- item and pushed the real content out of view. Those parents (TextButtons,
-- and frames that pass native = true) get their own BackgroundColor3 + a
-- UICorner instead; the returned proxy keeps .ImageColor3 / .ImageTransparency
-- working for hoverbg and friends.
local function roundbg(parent, radius, color, native)
	if native or parent:IsA("TextButton") then
		parent.BackgroundColor3 = color
		parent.BackgroundTransparency = rowalpha
		parent.BorderSizePixel = 0
		local corner = parent:FindFirstChildOfClass("UICorner") or instance.uicorner(parent)
		corner.CornerRadius = UDim.new(0, radius)
		return setmetatable({}, {
			__index = function(_, key)
				if key == "ImageColor3" then
					return parent.BackgroundColor3
				elseif key == "ImageTransparency" then
					return parent.BackgroundTransparency
				end
				return nil
			end,
			__newindex = function(_, key, value)
				if key == "ImageColor3" then
					parent.BackgroundColor3 = value
				elseif key == "ImageTransparency" then
					parent.BackgroundTransparency = value
				end
			end,
		})
	end
	parent.BackgroundTransparency = 1
	local bg = instance.imagelabel(parent)
	bg.Name = "Bg"
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.ImageTransparency = rowalpha
	bg.Image = sliceimage
	bg.ScaleType = Enum.ScaleType.Slice
	bg.SliceCenter = Rect.new(100, 100, 100, 100)
	bg.SliceScale = radius / 100
	bg.ImageColor3 = color
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.ZIndex = 0
	return bg
end

local function hoverbg(button, bg, normal, hover)
	button.MouseEnter:Connect(function()
		bg.ImageColor3 = hover
	end)
	button.MouseLeave:Connect(function()
		bg.ImageColor3 = normal
	end)
	button.MouseButton1Down:Connect(function()
		bg.ImageColor3 = normal
	end)
	button.MouseButton1Up:Connect(function()
		bg.ImageColor3 = hover
	end)
end

-- Short press dip on buttons (was called everywhere but never defined).
local function pesseffect(button)
	local scale = button:FindFirstChild("PressScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "PressScale"
		scale.Parent = button
	end
	sv.ts:Create(scale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.96 }):Play()
	task.delay(0.08, function()
		if scale.Parent then
			sv.ts:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end)
end

local hasfs = type(isfolder) == "function" and type(makefolder) == "function"
if hasfs and not isfolder("Vecta") then
	pcall(makefolder, "Vecta")
end

-- ===== Config system (Bolong-style) =====
-- Vecta/<GameName>/{_meta,_base,_autosave,_autoload,_account_autoload,Default,<name>}.json
local VECTA_ROOT = "Vecta"
local DEFAULT_CONFIG_NAME = "Default"
local ACCOUNT_AUTOLOAD_FILE = "_account_autoload.json"
local internalfiles = { _meta = true, _base = true, _autoload = true, _autosave = true, _account_autoload = true, presets = true }

config.autosave = false
config.applying = false
config.savequeued = false
config.activepath = nil
config.accountpending = false

local function safeencode(value)
	local ok, encoded = pcall(function()
		return sv.http:JSONEncode(value)
	end)
	return ok and encoded or nil
end

local function sanitizename(name)
	name = tostring(name or ""):gsub("[^%w_ ]", ""):gsub("%s+", "_")
	return name
end

local function ensurefolderfor(path)
	if not (isfolder and makefolder) then
		return
	end
	local parts = {}
	for part in string.gmatch(path, "[^/\\]+") do
		table.insert(parts, part)
	end
	table.remove(parts)
	local current = ""
	for _, part in ipairs(parts) do
		current = current == "" and part or (current .. "/" .. part)
		if not isfolder(current) then
			pcall(makefolder, current)
		end
	end
end

local function tryread(path, retries)
	if not (readfile and isfile) then
		return nil
	end
	retries = retries or 3
	for attempt = 1, retries do
		local okfile, raw = pcall(function()
			if isfile(path) then
				return readfile(path)
			end
			return nil
		end)
		if okfile and type(raw) == "string" and raw ~= "" then
			local okdec, dec = pcall(function()
				return sv.http:JSONDecode(raw)
			end)
			if okdec and type(dec) == "table" then
				return dec
			end
		end
		if attempt < retries then
			task.wait(0.25 * attempt)
		end
	end
	return nil
end

local function safewrite(path, encoded)
	if not writefile or not encoded then
		return false
	end
	ensurefolderfor(path)
	for attempt = 1, 3 do
		if pcall(writefile, path, encoded) then
			return true
		end
		if attempt < 3 then
			task.wait(0.2 * attempt)
		end
	end
	return false
end

local function readmeta(folder)
	return tryread(VECTA_ROOT .. "/" .. folder .. "/_meta.json", 1)
end

local function writemeta(folder, data)
	safewrite(VECTA_ROOT .. "/" .. folder .. "/_meta.json", safeencode(data))
end

local function copyvalue(value, seen)
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] then
		return seen[value]
	end
	local copy = {}
	seen[value] = copy
	for k, v in pairs(value) do
		copy[copyvalue(k, seen)] = copyvalue(v, seen)
	end
	return copy
end

-- Game folder: reuse the folder whose _meta.json has this PlaceId, else name it
-- after the game (GetProductInfo).
local function resolvegamename()
	local placeid = game.PlaceId
	if listfolders then
		local ok, dirs = pcall(listfolders, VECTA_ROOT)
		if ok and type(dirs) == "table" then
			for _, folder in ipairs(dirs) do
				local name = tostring(folder):match("([^/\\]+)$")
				local meta = name and readmeta(name)
				if meta and tonumber(meta.PlaceId) == tonumber(placeid) then
					return name
				end
			end
		end
	end
	local fetched
	for attempt = 1, 3 do
		local ok, info = pcall(function()
			return game:GetService("MarketplaceService"):GetProductInfo(placeid)
		end)
		if ok and info and info.Name then
			fetched = tostring(info.Name)
			break
		end
		if attempt < 3 then
			task.wait(1 + attempt)
		end
	end
	local name = sanitizename(fetched or "")
	if name == "" then
		return "Unknown_Game"
	end
	writemeta(name, { PlaceId = placeid, Name = fetched, SavedAt = os.time() })
	return name
end

local function currentaccountid()
	if config.accountoverride then
		return tostring(config.accountoverride)
	end
	local ok, id = pcall(function()
		local lp = game:GetService("Players").LocalPlayer
		return lp and lp.UserId or 0
	end)
	return tostring(ok and id or 0)
end

function config:basefile()
	if self.accountpending then
		return self.gamefolder .. "/_base." .. currentaccountid() .. ".json"
	end
	return self.gamefolder .. "/_base.json"
end

function config:snapshot()
	local snap = packconfig(self.data)
	for key, value in pairs(snap) do
		snap[key] = copyvalue(value)
	end
	snap._version = self.version
	return snap
end

local function isemptysnapshot(snap)
	for key in pairs(snap or {}) do
		if key ~= "_version" then
			return false
		end
	end
	return true
end

function config:setactive(name, path)
	self.current = name
	self.activepath = path
end

function config:persist(force)
	if not writefile or not self.gamefolder then
		return false
	end
	if self.applying and not force then
		return false
	end
	if not force and not self.autosave then
		return false
	end
	local target = self.activepath or self:basefile()
	local snap = self:snapshot()
	local encoded = safeencode(snap)
	if not encoded then
		return false
	end
	if isemptysnapshot(snap) and tryread(target, 1) ~= nil then
		return false -- never overwrite a saved config with an empty one
	end
	return safewrite(target, encoded)
end

-- Debounced autosave, called after every element change.
function config:queuesave()
	if self.applying or not self.autosave or self.savequeued then
		return
	end
	self.savequeued = true
	task.delay(0.35, function()
		self.savequeued = false
		self:persist(false)
	end)
end

function config:readautosave()
	local data = tryread((self.gamefolder or "") .. "/_autosave.json", 2)
	if data and type(data.Enabled) == "boolean" then
		return data.Enabled
	end
	return nil
end

function config:writeautosave(value)
	return safewrite(self.gamefolder .. "/_autosave.json", safeencode({ Enabled = value == true }))
end

function config:getaccountinfo()
	local info = { Enabled = false, Accounts = {} }
	local data = tryread(self.gamefolder .. "/" .. ACCOUNT_AUTOLOAD_FILE, 2)
	if data then
		info.Enabled = data.Enabled == true
		if type(data.Accounts) == "table" then
			for id, name in pairs(data.Accounts) do
				info.Accounts[tostring(id)] = tostring(name or "")
			end
		end
	end
	return info
end

function config:writeaccountinfo(info)
	local clean = { Enabled = info.Enabled == true, Accounts = {} }
	for id, name in pairs(info.Accounts or {}) do
		if tostring(name or "") ~= "" then
			clean.Accounts[tostring(id)] = tostring(name)
		end
	end
	return safewrite(self.gamefolder .. "/" .. ACCOUNT_AUTOLOAD_FILE, safeencode(clean))
end

function config:getlist()
	local configs = {}
	if isfolder and listfiles and self.gamefolder and isfolder(self.gamefolder) then
		for _, filepath in pairs(listfiles(self.gamefolder)) do
			local filename = filepath:match("([^/\\]+)%.json$")
			if filename and filename:sub(1, 1) ~= "_" and not internalfiles[filename] then
				table.insert(configs, filename)
			end
		end
	end
	table.sort(configs)
	return configs
end

function config:getautoload()
	local data = tryread((self.gamefolder or "") .. "/_autoload.json", 1)
	if data and tostring(data.Name or "") ~= "" then
		return tostring(data.Name)
	end
	return nil
end

function config:setautoload(name)
	name = tostring(name or "")
	if name == "" then
		return self:clearautoload()
	end
	if not safewrite(self.gamefolder .. "/_autoload.json", safeencode({ Name = name })) then
		return false
	end
	local info = self:getaccountinfo()
	if info.Enabled then
		info.Enabled = false
		self:writeaccountinfo(info)
		self.accountpending = false
	end
	return true
end

function config:clearautoload()
	return safewrite(self.gamefolder .. "/_autoload.json", safeencode({ Name = "" }))
end

function config:setaccountautoload(accountid, name)
	accountid = tostring(accountid or currentaccountid())
	local info = self:getaccountinfo()
	info.Accounts[accountid] = (name and name ~= "") and tostring(name) or nil
	return self:writeaccountinfo(info)
end

function config:setaccountenabled(value)
	local info = self:getaccountinfo()
	info.Enabled = value == true
	if not self:writeaccountinfo(info) then
		return false
	end
	self.accountpending = info.Enabled
	if info.Enabled then
		self:clearautoload()
	end
	return true
end

-- Strip wrapper/meta fields from a config file or exported payload.
local function extractpayload(payload)
	if type(payload) ~= "table" then
		return nil
	end
	local data = payload
	if type(payload.Data) == "table" then
		data = payload.Data
	elseif type(payload.Config) == "table" then
		data = payload.Config
	elseif type(payload.Settings) == "table" then
		data = payload.Settings
	end
	local cleaned = {}
	for key, value in pairs(data) do
		if
			key ~= "_version"
			and key ~= "Game"
			and key ~= "Version"
			and key ~= "PlaceId"
			and key ~= "Hub"
			and key ~= "SavedAt"
			and key ~= "ActiveConfig"
			and key ~= "AutoLoad"
			and not metakeys[key]
		then
			cleaned[key] = value
		end
	end
	return cleaned
end

function config:loadelements()
	self.applying = true
	for key, element in pairs(self.elements) do
		if element.Set and not metakeys[key] then
			local value = self.data[key]
			local apply = value ~= nil
			if value == nil then
				value = missingdefault(key, element)
				apply = value ~= nil or key:match("^Dropdown_") ~= nil
			end
			if apply then
				local ok, err = pcall(function()
					if element.LoadValue then
						element:LoadValue(value)
					else
						element:Set(value, true)
					end
				end)
				if not ok then
					warn("[VECTA] Config load failed for " .. tostring(key) .. ":", err)
				end
			end
		end
	end
	self.applying = false
end

function config:applydata(data)
	if isemptysnapshot(data) then
		warn("[VECTA] Config data is empty, skipped")
		return false
	end
	local fresh = { _version = self.version }
	for key, value in pairs(data) do
		fresh[key] = value
	end
	-- keep panel-only inputs out of the loaded data
	self.data = fresh
	self.loaded = true
	self:loadelements()
	return true
end

function config:ensuredefault()
	if not (writefile and self.version and self.gamefolder) then
		return
	end
	local meta = readmeta(self.gamemeta or "") or {}
	if meta.DefaultConfigSaved and isfile and isfile(self.gamefolder .. "/" .. DEFAULT_CONFIG_NAME .. ".json") then
		return
	end
	local encoded = safeencode(self:snapshot())
	if encoded and safewrite(self.gamefolder .. "/" .. DEFAULT_CONFIG_NAME .. ".json", encoded) then
		meta.DefaultConfigSaved = true
		meta.PlaceId = meta.PlaceId or game.PlaceId
		writemeta(self.gamemeta, meta)
	end
end

function config:save(name)
	name = sanitizename(name)
	if name == "" then
		warn("[VECTA] Config name cannot be empty")
		return false
	end
	if not writefile or not self.gamefolder then
		return false
	end
	local path = self.gamefolder .. "/" .. name .. ".json"
	if not safewrite(path, safeencode(self:snapshot())) then
		return false
	end
	self:setactive(name, path)
	return true
end

function config:load(name)
	if not name or name == "" then
		warn("[VECTA] Config name cannot be empty")
		return false
	end
	local path = self.gamefolder .. "/" .. name .. ".json"
	if not (isfile and isfile(path)) then
		warn("[VECTA] Config file not found: " .. name)
		return false
	end
	local data = extractpayload(tryread(path, 3))
	if not data or not self:applydata(data) then
		return false
	end
	self:setactive(name, path)
	return true
end

function config:delete(name)
	if not name or name == "" then
		return false
	end
	local path = self.gamefolder .. "/" .. name .. ".json"
	if not (delfile and isfile and isfile(path)) then
		warn("[VECTA] Config file not found: " .. name)
		return false
	end
	delfile(path)
	if self:getautoload() == name then
		self:clearautoload()
	end
	local info = self:getaccountinfo()
	local changed = false
	for id, cfgname in pairs(info.Accounts) do
		if cfgname == name then
			info.Accounts[id] = nil
			changed = true
		end
	end
	if changed then
		self:writeaccountinfo(info)
	end
	if self.current == name then
		self:setactive(nil, nil)
	end
	return true
end

function config:reset()
	self.data = { _version = self.version }
	self.loaded = false
	self.applying = true
	for key, element in pairs(self.elements) do
		if element.Set and not metakeys[key] then
			pcall(function()
				if element.ResetValue then
					element:ResetValue()
				elseif key:match("^Toggle_") then
					element:Set(false)
				elseif key:match("^Input_") then
					element:Set("")
				elseif key:match("^Dropdown_") then
					if type(element.Value) == "table" then
						element:Set({})
					else
						element:Set(nil)
					end
				end
			end)
		end
	end
	self.applying = false
end

function config:export()
	local payload = safeencode({
		Hub = "Vecta",
		Game = self.gamemeta,
		PlaceId = game.PlaceId,
		Version = self.version,
		ActiveConfig = self.current or "",
		AutoLoad = self:getautoload() or "",
		Data = self:snapshot(),
	})
	if payload and setclipboard then
		setclipboard(payload)
	end
	return payload
end

function config:loadexternal(json)
	if not json or json == "" then
		warn("[VECTA] External config JSON kosong")
		return false
	end
	local ok, dec = pcall(function()
		return sv.http:JSONDecode(json)
	end)
	if not ok or type(dec) ~= "table" then
		warn("[VECTA] External config JSON invalid")
		return false
	end
	local data = extractpayload(dec)
	if not data or not self:applydata(data) then
		return false
	end
	self:queuesave()
	return true
end

-- Startup: pick the autoload config (per-account or global) or the base file.
function config:init(scope)
	if hasfs and not isfolder(VECTA_ROOT) then
		pcall(makefolder, VECTA_ROOT)
	end
	local gamename = resolvegamename()
	self.gamemeta = gamename
	scope = sanitizename(scope or "")
	self.gamefolder = VECTA_ROOT .. "/" .. gamename .. (scope ~= "" and ("/" .. scope) or "")
	if hasfs then
		ensurefolderfor(self.gamefolder .. "/_base.json")
	end

	self.data = { _version = self.version }
	self:setactive(nil, nil)

	local saved = self:readautosave()
	if saved ~= nil then
		self.autosave = saved
	end

	local info = self:getaccountinfo()
	self.accountpending = info.Enabled == true

	local autoname = ""
	if self.accountpending then
		autoname = tostring(info.Accounts[currentaccountid()] or "")
	else
		autoname = self:getautoload() or ""
	end

	if autoname ~= "" then
		local result = tryread(self.gamefolder .. "/" .. autoname .. ".json", 3)
		if result then
			local data = extractpayload(result)
			for key, value in pairs(data or {}) do
				self.data[key] = value
			end
			self.loaded = true
			self:setactive(autoname, self.gamefolder .. "/" .. autoname .. ".json")
			return
		end
		warn("[VECTA] Config '" .. autoname .. "' could not be read, using base config")
	end

	local base = tryread(self:basefile(), 3)
	if base then
		for key, value in pairs(extractpayload(base) or {}) do
			self.data[key] = value
		end
		self.loaded = true
	end
end

function isMobileDevice()
	return sv.uis.TouchEnabled and not sv.uis.KeyboardEnabled and not sv.uis.MouseEnabled
end

local isMobile = isMobileDevice()

function safesize(width, height)
	local viewport = workspace.CurrentCamera.ViewportSize

	local x = width / viewport.X
	local y = height / viewport.Y

	if isMobile then
		x = math.min(x, 0.5)
		y = math.min(y, 0.3)
	end

	return UDim2.new(x, 0, y, 0)
end

-- The one place the window size is decided: the viewer's last size (saved when
-- they finish resizing), else the default, always clamped to the screen.
local WINDOW_SIZE_FILE = "Vecta/window_size.txt"

local function savedwindowsize()
	if isMobile or type(isfile) ~= "function" or type(readfile) ~= "function" then
		return nil
	end
	local ok, raw = pcall(function()
		return isfile(WINDOW_SIZE_FILE) and readfile(WINDOW_SIZE_FILE) or nil
	end)
	local w, h = tostring(ok and raw or ""):match("^(%d+)x(%d+)")
	if w and h then
		return tonumber(w), tonumber(h)
	end
	return nil
end

local function clampwindowsize(width, height)
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local maxw = math.max(draggable.minx, math.floor(viewport.X * 0.94))
	local maxh = math.max(draggable.miny, math.floor(viewport.Y * 0.9))
	return math.clamp(width, draggable.minx, maxw), math.clamp(height, draggable.miny, maxh)
end

function makedraggable(topbar, object)
	if isMobile then
		draggable.defx, draggable.defy = 470, 270
	end

	local startw, starth = savedwindowsize()
	startw, starth = clampwindowsize(startw or draggable.defx, starth or draggable.defy)
	object.Size = UDim2.new(0, startw, 0, starth)

	local resize = instance.frame(object)
	resize.Name = "resize"
	resize.AnchorPoint = Vector2.new(1, 1)
	resize.BackgroundTransparency = 1
	resize.Size = UDim2.new(0, 40, 0, 40)
	resize.Position = UDim2.new(1, 20, 1, 20)
	resize.Active = true
	local dragConnection = nil
	local resizeConnection = nil

	trackConnection(
		topbar.InputBegan:Connect(function(input)
			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			draggable.dragging = true
			draggable.dragstart = input.Position
			draggable.startpos = object.Position

			if dragConnection then
				dragConnection:Disconnect()
			end
			dragConnection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					draggable.dragging = false
					dragConnection:Disconnect()
					dragConnection = nil
				end
			end)
		end),
		"makedraggable.drag.InputBegan"
	)

	trackConnection(
		topbar.InputChanged:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			then
				draggable.draginput = input
			end
		end),
		"makedraggable.drag.InputChanged"
	)

	trackConnection(
		resize.InputBegan:Connect(function(input)
			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			draggable.resizing = true
			draggable.resizestart = input.Position
			draggable.startsize = object.Size

			if resizeConnection then
				resizeConnection:Disconnect()
			end
			resizeConnection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					draggable.resizing = false
					resizeConnection:Disconnect()
					resizeConnection = nil
					if not isMobile and type(writefile) == "function" then
						pcall(writefile, WINDOW_SIZE_FILE, string.format("%dx%d", object.Size.X.Offset, object.Size.Y.Offset))
					end
				end
			end)
		end),
		"makedraggable.resize.InputBegan"
	)

	trackConnection(
		resize.InputChanged:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			then
				draggable.resizeinput = input
			end
		end),
		"makedraggable.resize.InputChanged"
	)

	trackConnection(
		sv.uis.InputChanged:Connect(function(input)
			if draggable.dragging and input == draggable.draginput then
				draggable.pendingdrag = input.Position
			end
			if draggable.resizing and input == draggable.resizeinput then
				draggable.pendingresize = input.Position
			end
		end),
		"makedraggable.global.InputChanged"
	)

	trackConnection(
		game:GetService("RunService").RenderStepped:Connect(function()
			local drag = draggable.pendingdrag
			if drag then
				draggable.pendingdrag = nil
				local delta = drag - draggable.dragstart
				object.Position = UDim2.new(
					draggable.startpos.X.Scale,
					draggable.startpos.X.Offset + delta.X,
					draggable.startpos.Y.Scale,
					draggable.startpos.Y.Offset + delta.Y
				)
			end

			local resize = draggable.pendingresize
			if resize then
				draggable.pendingresize = nil
				local delta = resize - draggable.resizestart
				local width = math.max(draggable.startsize.X.Offset + delta.X, draggable.minx)
				local height = math.max(draggable.startsize.Y.Offset + delta.Y, draggable.miny)
				object.Size = UDim2.new(0, width, 0, height)
			end
		end),
		"makedraggable.render"
	)
end

local Chloex = {}

local function notifyholder(top)
	local gui = sv.coregui:FindFirstChild("NotifyGui")
	if not gui then
		gui = instance.screengui(sv.coregui)
		gui.Name = "NotifyGui"
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 9999
	end

	local name = top and "AnnounceLayout" or "NotifyLayout"
	local holder = gui:FindFirstChild(name)
	if not holder then
		holder = instance.frame(gui)
		holder.Name = name
		holder.AnchorPoint = top and Vector2.new(0.5, 0) or Vector2.new(1, 1)
		holder.Position = top and UDim2.new(0.5, 0, 0, 30) or UDim2.new(1, -30, 1, -30)
		holder.Size = UDim2.new(0, top and 400 or 320, 1, 0)
		holder.BackgroundTransparency = 1
		holder.BorderSizePixel = 0

		holder.ChildRemoved:Connect(function()
			local offset = 0
			for _, v in ipairs(holder:GetChildren()) do
				local target = top and UDim2.new(0, 0, 0, offset) or UDim2.new(0, 0, 1, -offset)
				sv.ts
					:Create(v, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Position = target })
					:Play()
				offset = offset + v.Size.Y.Offset + 12
			end
		end)
	end

	return holder
end

local function stackoffset(holder, top)
	local offset = 0
	for _, v in ipairs(holder:GetChildren()) do
		if top then
			offset = v.Position.Y.Offset + v.Size.Y.Offset + 12
		else
			offset = -v.Position.Y.Offset + v.Size.Y.Offset + 12
		end
	end
	return offset
end

local function buildnotify(cfg, top)
	elevate()
	local holder = notifyholder(top)
	local offset = stackoffset(holder, top)
	local width = holder.Size.X.Offset
	local textsize = tonumber(cfg.TextSize) or 13
	local headersize = tonumber(cfg.HeaderSize) or 14

	local bodyheight = math.max(textsize, textheight(cfg.Content, textsize, FONT_MEDIUM, width - 28, textsize * 8))
	local height = math.max(65, bodyheight + 40)

	local notifyframe = instance.frame(holder)
	notifyframe.Name = "NotifyFrame"
	notifyframe.BackgroundTransparency = 1
	notifyframe.BorderSizePixel = 0
	notifyframe.Size = UDim2.new(1, 0, 0, height)
	notifyframe.AnchorPoint = top and Vector2.new(0, 0) or Vector2.new(0, 1)
	notifyframe.Position = top and UDim2.new(0, 0, 0, offset) or UDim2.new(0, 0, 1, -offset)

	local notifyframereal = instance.frame(notifyframe)
	notifyframereal.Name = "NotifyFrameReal"
	notifyframereal.BackgroundColor3 = theme.Card
	notifyframereal.BorderSizePixel = 0
	notifyframereal.Position = UDim2.new(0, 400, 0, 0)
	notifyframereal.Size = UDim2.new(1, 0, 1, 0)
	instance.uicorner(notifyframereal).CornerRadius = UDim.new(0, 8)

	local notifystroke = instance.uistroke(notifyframereal)
	notifystroke.Color = theme.Stroke
	notifystroke.Thickness = 1

	local topbar = instance.frame(notifyframereal)
	topbar.Name = "Top"
	topbar.Size = UDim2.new(1, 0, 0, 36)
	topbar.BackgroundTransparency = 1
	topbar.BorderSizePixel = 0

	local titlewidth = 0
	pcall(function()
		titlewidth = measure(cfg.Title, headersize, FONT_BOLD, Vector2.new(1000, 100)).X
	end)
	titlewidth = math.ceil(titlewidth)

	local title = instance.textlabel(topbar)
	title.FontFace = FONT_BOLD
	title.Text = cfg.Title
	title.TextSize = ts(headersize)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Size = UDim2.new(0, titlewidth + 2, 1, 0)
	title.Position = UDim2.new(0, 14, 0, 0)

	local descx = 14 + titlewidth + 8
	local desc = instance.textlabel(topbar)
	desc.FontFace = FONT_BOLD
	desc.Text = cfg.Description
	desc.TextSize = ts(headersize)
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	desc.BackgroundTransparency = 1
	desc.TextColor3 = cfg.Color
	desc.Size = UDim2.new(1, -(descx + 34), 1, 0)
	desc.Position = UDim2.new(0, descx, 0, 0)

	local close = instance.textbutton(topbar)
	close.Text = ""
	close.Size = UDim2.new(0, 25, 0, 25)
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, -5, 0.5, 0)
	close.BackgroundTransparency = 1
	close.BorderSizePixel = 0

	local closeicon = instance.imagelabel(close)
	closeicon.BackgroundTransparency = 1
	closeicon.ImageColor3 = theme.SubText
	closeicon.Size = UDim2.new(0, 14, 0, 14)
	applyicon(closeicon, "x", 48)
	closeicon.Position = UDim2.new(0.5, 0, 0.5, 0)
	closeicon.AnchorPoint = Vector2.new(0.5, 0.5)

	-- Body is regular weight and ends in "..." past 8 lines instead of spilling
	-- out of the card (the card clips as a second guard).
	notifyframereal.ClipsDescendants = true
	local content = instance.textlabel(notifyframereal)
	content.FontFace = FONT_MEDIUM
	content.Text = cfg.Content
	content.TextWrapped = true
	content.TextTruncate = Enum.TextTruncate.AtEnd
	content.TextXAlignment = Enum.TextXAlignment.Left
	content.TextYAlignment = Enum.TextYAlignment.Top
	content.TextSize = ts(textsize)
	content.BackgroundTransparency = 1
	content.TextColor3 = theme.SubText
	content.Position = UDim2.new(0, 14, 0, 27)
	content.Size = UDim2.new(1, -28, 0, bodyheight)

	local handle = {}
	local closed = false

	function handle:Close()
		if closed then
			return
		end
		closed = true
		elevate()
		sv.ts
			:Create(
				notifyframereal,
				TweenInfo.new(cfg.Time, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
				{ Position = UDim2.new(0, 400, 0, 0) }
			)
			:Play()
		task.delay(cfg.Time / 1.2, function()
			pcall(function()
				notifyframe:Destroy()
			end)
		end)
	end

	function handle:SetContent(text)
		content.Text = tostring(text or "")
	end

	close.Activated:Connect(function()
		handle:Close()
	end)

	sv.ts
		:Create(
			notifyframereal,
			TweenInfo.new(cfg.Time, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
			{ Position = UDim2.new(0, 0, 0, 0) }
		)
		:Play()

	return handle
end

function Chloex:MakeNotify(notifyconfig)
	notifyconfig = notifyconfig or {}
	notifyconfig.Title = tostring(notifyconfig.Title or "Vecta")
	notifyconfig.Description = tostring(notifyconfig.Description or "Notification")
	notifyconfig.Content = tostring(notifyconfig.Content or "Content")
	notifyconfig.Color = notifyconfig.Color or theme.Accent
	notifyconfig.Time = tonumber(notifyconfig.Time) or 0.5
	notifyconfig.Delay = tonumber(notifyconfig.Delay) or 5

	local handle = buildnotify(notifyconfig, false)
	task.delay(notifyconfig.Delay, function()
		handle:Close()
	end)
	return handle
end

function chloex(msg, delay, color, title, desc)
	return Chloex:MakeNotify({
		Title = title or "Vecta",
		Description = desc or "Notification",
		Content = msg or "Content",
		Color = color or theme.Accent,
		Delay = delay or 4,
	})
end

function Chloex:Notify(notifyconfig)
	notifyconfig = notifyconfig or {}
	return Chloex:MakeNotify({
		Title = notifyconfig.Title or notifyconfig[1] or "Vecta",
		Description = notifyconfig.Description or notifyconfig.Desc or "Notification",
		Content = notifyconfig.Content or notifyconfig.Text or notifyconfig[2] or "",
		Color = notifyconfig.Color or theme.Accent,
		Delay = tonumber(notifyconfig.Duration or notifyconfig.Delay or notifyconfig.Time or notifyconfig[3]) or 4,
	})
end

function Chloex:Prompt(promptconfig)
	promptconfig = promptconfig or {}
	local title = tostring(promptconfig.Title or "Vecta")
	local content = tostring(promptconfig.Content or "")
	local duration = math.max(5, tonumber(promptconfig.Duration) or 60)
	local avatar = promptconfig.Avatar
	local callback = promptconfig.Callback
	local acceptlabel = tostring(promptconfig.Accept or "Accept")
	local declinelabel = tostring(promptconfig.Decline or "Decline")

	local promptfunc = {}
	local answered = false
	local closed = false

	task.spawn(function()
		elevate()
		local notifylayout = notifyholder(false)

		local notifyposheigh = 0
		for _, v in ipairs(notifylayout:GetChildren()) do
			notifyposheigh = -v.Position.Y.Offset + v.Size.Y.Offset + 12
		end

		local notifyframe = instance.frame(notifylayout)
		notifyframe.Name = "NotifyFrame"
		notifyframe.BackgroundTransparency = 1
		notifyframe.BorderSizePixel = 0
		notifyframe.Size = UDim2.new(1, 0, 0, 98)
		notifyframe.AnchorPoint = Vector2.new(0, 1)
		notifyframe.Position = UDim2.new(0, 0, 1, -notifyposheigh)

		local notifyframereal = instance.frame(notifyframe)
		notifyframereal.Name = "NotifyFrameReal"
		notifyframereal.BackgroundColor3 = theme.Card
		notifyframereal.BorderSizePixel = 0
		notifyframereal.Position = UDim2.new(0, 400, 0, 0)
		notifyframereal.Size = UDim2.new(1, 0, 1, 0)
		instance.uicorner(notifyframereal).CornerRadius = UDim.new(0, 8)

		local stroke = instance.uistroke(notifyframereal)
		stroke.Color = theme.Stroke
		stroke.Thickness = 1

		local avatarframe = instance.frame(notifyframereal)
		avatarframe.Name = "Avatar"
		avatarframe.BackgroundColor3 = theme.Element
		avatarframe.BorderSizePixel = 0
		avatarframe.Position = UDim2.new(0, 12, 0, 12)
		avatarframe.Size = UDim2.new(0, 34, 0, 34)
		instance.uicorner(avatarframe).CornerRadius = UDim.new(1, 0)

		if avatar then
			local pic = instance.imagelabel(avatarframe)
			pic.BackgroundTransparency = 1
			pic.Size = UDim2.new(1, 0, 1, 0)
			pic.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(avatar) .. "&w=60&h=60"
			instance.uicorner(pic).CornerRadius = UDim.new(1, 0)
		else
			local mark = instance.textlabel(avatarframe)
			mark.BackgroundTransparency = 1
			mark.Size = UDim2.new(1, 0, 1, 0)
			mark.FontFace = FONT_BOLD
			mark.Text = "?"
			mark.TextColor3 = theme.Text
			mark.TextSize = ts(14)
		end

		local titlelabel = instance.textlabel(notifyframereal)
		titlelabel.FontFace = FONT_BOLD
		titlelabel.Text = title
		titlelabel.RichText = true
		titlelabel.TextSize = ts(14)
		titlelabel.TextColor3 = theme.Text
		titlelabel.TextXAlignment = Enum.TextXAlignment.Left
		titlelabel.TextTruncate = Enum.TextTruncate.AtEnd
		titlelabel.BackgroundTransparency = 1
		titlelabel.Position = UDim2.new(0, 56, 0, 11)
		titlelabel.Size = UDim2.new(1, -68, 0, 16)

		local contentlabel = instance.textlabel(notifyframereal)
		contentlabel.FontFace = FONT_MEDIUM
		contentlabel.Text = content
		contentlabel.TextSize = ts(12)
		contentlabel.TextColor3 = theme.SubText
		contentlabel.TextWrapped = true
		contentlabel.TextTruncate = Enum.TextTruncate.AtEnd
		contentlabel.TextXAlignment = Enum.TextXAlignment.Left
		contentlabel.TextYAlignment = Enum.TextYAlignment.Top
		contentlabel.BackgroundTransparency = 1
		local promptbody = math.max(14, textheight(content, 12, FONT_MEDIUM, 320 - 68, 14 * 4))
		contentlabel.Position = UDim2.new(0, 56, 0, 29)
		contentlabel.Size = UDim2.new(1, -68, 0, promptbody)
		notifyframe.Size = UDim2.new(1, 0, 0, 29 + promptbody + 8 + 26 + 10)

		local function makebutton(text, x, w, accent)
			local btn = instance.textbutton(notifyframereal)
			btn.Position = UDim2.new(0, x, 1, -36)
			btn.Size = UDim2.new(0, w, 0, 26)
			btn.BackgroundColor3 = accent and theme.Accent or Color3.fromRGB(255, 255, 255)
			btn.BackgroundTransparency = accent and 0 or 0.92
			btn.BorderSizePixel = 0
			btn.FontFace = FONT_BOLD
			btn.Text = text
			btn.TextColor3 = accent and theme.AccentText or theme.Text
			btn.TextSize = ts(12)
			btn.TextTruncate = Enum.TextTruncate.AtEnd
			btn.AutoButtonColor = true
			instance.uicorner(btn).CornerRadius = UDim.new(0, 6)
			return btn
		end

		local half = math.floor((320 - 56 - 12 - 6) / 2)
		local acceptbtn = makebutton(acceptlabel, 56, half, true)
		local declinebtn = makebutton(declinelabel, 56 + half + 6, half, false)

		local bar = instance.frame(notifyframereal)
		bar.Name = "Bar"
		bar.BackgroundColor3 = theme.Accent
		bar.BackgroundTransparency = 0.35
		bar.BorderSizePixel = 0
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.Position = UDim2.new(0, 0, 1, 0)
		bar.Size = UDim2.new(1, 0, 0, 2)
		instance.uicorner(bar).CornerRadius = UDim.new(0, 2)

		function promptfunc:Close()
			if closed then
				return
			end
			closed = true
			elevate()
			sv.ts
				:Create(
					notifyframereal,
					TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
					{ Position = UDim2.new(0, 400, 0, 0) }
				)
				:Play()
			task.delay(0.42, function()
				pcall(function()
					notifyframe:Destroy()
				end)
			end)
		end

		local function answer(accepted)
			if answered then
				return
			end
			answered = true
			promptfunc:Close()
			if type(callback) == "function" then
				task.spawn(function()
					elevate()
					local ok, err = pcall(callback, accepted)
					if not ok then
						warn("[VECTA] Prompt callback error:", err)
					end
				end)
			end
		end

		function promptfunc:Answer(accepted)
			answer(accepted)
		end

		acceptbtn.Activated:Connect(function()
			answer(true)
		end)
		declinebtn.Activated:Connect(function()
			answer(false)
		end)

		sv.ts
			:Create(
				notifyframereal,
				TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
				{ Position = UDim2.new(0, 0, 0, 0) }
			)
			:Play()
		sv.ts:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()

		task.wait(duration)
		if not answered then
			answer(nil)
		end
	end)

	return promptfunc
end

function Chloex:MakeOverlay(overlayconfig)
	overlayconfig = overlayconfig or {}
	overlayconfig.Content = overlayconfig.Content or "Status"
	overlayconfig.Position = typeof(overlayconfig.Position) == "UDim2" and overlayconfig.Position or UDim2.new(0, 20, 0, 20)

	local overlayfunc = {}

	local overlaygui = instance.screengui(sv.coregui)
	overlaygui.Name = "OverlayGui"
	overlaygui.ResetOnSpawn = false
	overlaygui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local overlayframe = instance.frame(overlaygui)
	overlayframe.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlayframe.BackgroundTransparency = 0.4
	overlayframe.BorderSizePixel = 0
	overlayframe.Position = overlayconfig.Position
	overlayframe.Size = UDim2.new(0, 150, 0, 30)
	overlayframe.AutomaticSize = Enum.AutomaticSize.Y

	local uicorner = instance.uicorner(overlayframe)
	uicorner.CornerRadius = UDim.new(0, 6)

	local contentlabel = instance.textlabel(overlayframe)
	contentlabel.FontFace = FONT_BOLD
	contentlabel.Text = overlayconfig.Content
	contentlabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	contentlabel.TextSize = ts(13)
	contentlabel.BackgroundTransparency = 1
	contentlabel.TextWrapped = true
	contentlabel.AutomaticSize = Enum.AutomaticSize.Y
	contentlabel.Size = UDim2.new(1, -10, 0, 0)
	contentlabel.Position = UDim2.new(0, 10, 0, 5)
	contentlabel.TextXAlignment = Enum.TextXAlignment.Left

	local dragging, dragstart, startpos
	overlayframe.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragstart = input.Position
			startpos = overlayframe.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	trackConnection(
		sv.uis.InputChanged:Connect(function(input)
			if
				dragging
				and (
					input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
				)
			then
				local delta = input.Position - dragstart
				overlayframe.Position =
					UDim2.new(startpos.X.Scale, startpos.X.Offset + delta.X, startpos.Y.Scale, startpos.Y.Offset + delta.Y)
			end
		end),
		"overlay.drag"
	)

	function overlayfunc:SetContent(text)
		contentlabel.Text = text or ""
	end

	function overlayfunc:SetVisible(bool)
		overlayframe.Visible = bool
	end

	function overlayfunc:Destroy()
		overlaygui:Destroy()
	end

	return overlayfunc
end

Chloex.Unloaded = false
Chloex.DonatorInfo = nil
Chloex.LockRegistry = {}
Chloex.DonatorListeners = {}
Chloex._isDonator = false
Chloex._isTrial = false

-- A donator claim (from the loader or an earlier run in this Roblox session) is
-- only trusted while its key is still inside its paid time. Paused keys have no
-- running clock, so they never expire locally; the backend decides for them.
local EXPIRY_GRACE = 120

local function donatorinfo()
	local info = Chloex.DonatorInfo
	if type(info) ~= "table" then
		local ok, g = pcall(function()
			return getgenv and getgenv().SenaDonatorInfo
		end)
		info = ok and type(g) == "table" and g or nil
	end
	return info
end

local function claimexpired()
	local info = donatorinfo()
	if type(info) ~= "table" or info.paused == true then
		return false
	end
	local exp = tonumber(info.expires)
	return exp ~= nil and exp > 0 and exp + EXPIRY_GRACE <= os.time()
end

local function writetierglobals()
	if getgenv then
		getgenv().SenaIsDonator = Chloex._isDonator or Chloex._isTrial
		getgenv().SenaIsTrial = Chloex._isTrial
	end
	if _G then
		_G.SenaIsDonator = Chloex._isDonator or Chloex._isTrial
		_G.SenaIsTrial = Chloex._isTrial
	end
end

-- Adopt the tier the loader / VectaGuard wrote into the globals. Runs when the
-- lib loads and again when a Window is built; after that only SetDonator (key
-- redeem, backend tier reports, local expiry) changes the tier.
local function adoptclaim()
	if Chloex._isDonator or Chloex._isTrial then
		return
	end
	local okT, valT = pcall(function()
		return (getgenv and getgenv().SenaIsTrial == true) or (_G and _G.SenaIsTrial == true)
	end)
	local ok, val = pcall(function()
		return (getgenv and getgenv().SenaIsDonator == true) or (_G and _G.SenaIsDonator == true)
	end)
	if not ((okT and valT) or (ok and val)) then
		return
	end
	if claimexpired() then
		-- stale claim: the key ran out since it was set. Clear it before any
		-- element is built, so saved donator settings never get applied.
		pcall(function()
			getgenv().SenaDonatorInfo = nil
		end)
		writetierglobals()
		return
	end
	if okT and valT then
		Chloex._isTrial = true
	else
		Chloex._isDonator = true
	end
end

adoptclaim()

-- Lock or unlock every donator element to match the current tier. Each lock
-- controller is idempotent, so calling this on every tier report is cheap.
local function applydonatorlocks()
	local donator = Chloex._isDonator == true
	local trial = Chloex._isTrial == true
	for i = #Chloex.LockRegistry, 1, -1 do
		local lock = Chloex.LockRegistry[i]
		if lock.Dead and lock.Dead() then
			table.remove(Chloex.LockRegistry, i)
		else
			-- Locked2/DonatorOnly elements open only for a donator; a trial key
			-- leaves them locked. Ordinary elements open for donator OR trial.
			-- tiers are gone: every element is always unlocked
			local unlocked = true
			if unlocked then
				pcall(lock.Unlock, lock)
			else
				pcall(lock.Lock, lock)
			end
		end
	end
end

function Chloex:SetDonator(state, istrial)
	local before = tostring(Chloex._isDonator) .. tostring(Chloex._isTrial)
	if istrial then
		Chloex._isTrial = true
		Chloex._isDonator = false
	else
		Chloex._isTrial = false
		Chloex._isDonator = (state == true)
	end
	writetierglobals()
	if not (Chloex._isDonator or Chloex._isTrial) then
		Chloex.DonatorInfo = nil
		pcall(function()
			getgenv().SenaDonatorInfo = nil
		end)
	end
	applydonatorlocks()
	if before == tostring(Chloex._isDonator) .. tostring(Chloex._isTrial) then
		return
	end
	for _, fn in ipairs(Chloex.DonatorListeners) do
		task.spawn(function()
			elevate()
			pcall(fn)
		end)
	end
end

-- The lib's own state is the only source of truth; globals are an output
-- (writetierglobals) plus one-time input (adoptclaim).
local function isdonator()
	return Chloex._isDonator == true or Chloex._isTrial == true
end

local function istrial()
	return Chloex._isTrial == true
end

-- Whether the current tier may open an element of the given lock class.
-- Ordinary Locked/Donator elements open for donator OR trial; Locked2/
-- DonatorOnly elements open only for a real donator (trial stays locked).
local function tierallows(donatoronly)
	return true
end

function Chloex:IsDonator()
	return isdonator()
end

function Chloex:IsTrial()
	return istrial()
end

function Chloex:UnlockAllDonatorFeatures()
	Chloex:SetDonator(true)
end

-- Locks every donator element again (their saved values stay in the config
-- and come back on the next unlock). SetDonator(false) does the same.
function Chloex:RelockDonatorFeatures()
	Chloex:SetDonator(false)
end

-- Local expiry check: when the backend has not confirmed the key recently
-- (offline, or an older server that sends no lic_state), the paid time from
-- /key/check decides. The backend's word wins while it is reachable.
task.spawn(function()
	while not Chloex.Unloaded do
		task.wait(15)
		if isdonator() and claimexpired() then
			local b = Chloex:GetBackend()
			local confirmed = b and (os.time() - (b.LastValid or 0)) < 30
			if not confirmed then
				warn("[VECTA] Donator key time is up, locking donator features")
				Chloex:SetDonator(false)
				pcall(function()
					Chloex:Notify({ Title = "Vecta", Description = "Donator", Content = "Your donator key has expired. Donator features are locked again.", Duration = 6, Color = theme.Bad })
				end)
			end
		end
	end
end)

local backend = nil

local defaultbackend = {
	Api = "http://56.10.112.179:8080",
	Key = "",
}

local function httpgetjson(url)
	local ok, body = pcall(function()
		return game:HttpGet(url, true)
	end)
	if not ok or type(body) ~= "string" or body == "" then
		return nil
	end
	local okjson, data = pcall(function()
		return sv.http:JSONDecode(body)
	end)
	if not okjson or type(data) ~= "table" then
		return nil
	end
	return data
end

local function backendurl(path, params)
	local parts = {}
	for key, value in pairs(params or {}) do
		parts[#parts + 1] = tostring(key) .. "=" .. sv.http:UrlEncode(tostring(value))
	end
	parts[#parts + 1] = "t=" .. tostring(os.time()) .. tostring(math.random(1000, 9999))
	return backend.Api .. path .. "?" .. table.concat(parts, "&")
end

local function localplayer()
	local lp = sv.plrs.LocalPlayer
	if lp then
		return lp
	end
	local t0 = os.clock()
	while not lp and os.clock() - t0 < 5 do
		lp = sv.plrs.LocalPlayer
		if lp then
			break
		end
		task.wait(0.1)
	end
	return lp
end

local function localuserid()
	local lp = sv.plrs.LocalPlayer
	local ok, id = pcall(function()
		return lp and lp.UserId
	end)
	if ok and id and id ~= 0 then
		return tostring(id)
	end
	return tostring((lp and lp.UserId) or 0)
end

local function localusername()
	local lp = sv.plrs.LocalPlayer
	local ok, name = pcall(function()
		return lp and lp.Name
	end)
	return tostring(ok and name or (lp and lp.Name) or "")
end

local function localdisplayname()
	local lp = sv.plrs.LocalPlayer
	local ok, name = pcall(function()
		return lp and lp.DisplayName
	end)
	return tostring(ok and name or "")
end

local function detectgamename()
	local ok, info = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
	end)
	if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
		return info.Name
	end
	return "PlaceId " .. tostring(game.PlaceId)
end

local keyfiles = {
	"VectaHUB/vecta_key.txt",
	"VectaHUB/Vecta_AutoSave.json",
	"vecta_key.txt",
	"Vecta/vecta_key.txt",
	"VectaKey.txt",
	"vectahub_key.txt",
	"Vecta_AutoSave.json",
	"Vecta/Vecta_AutoSave.json",
}

local function readsavedkey()
	local found = nil
	if not (isfile and readfile) then
		return nil
	end
	for _, f in ipairs(keyfiles) do
		pcall(function()
			if isfile(f) then
				local c = readfile(f)
				if f:find("%.json$") then
					local okj, d = pcall(sv.http.JSONDecode, sv.http, c)
					if okj and type(d) == "table" and d.donatorKey and #tostring(d.donatorKey) > 0 then
						found = tostring(d.donatorKey)
					end
				elseif c and c:gsub("%s+", "") ~= "" then
					found = c
				end
			end
		end)
		if found and found:gsub("%s+", "") ~= "" then
			return found
		end
	end
	return nil
end

local function savekey(key)
	pcall(function()
		if writefile then
			writefile("vecta_key.txt", key)
			if makefolder and isfolder then
				if not isfolder("VectaHUB") then
					pcall(makefolder, "VectaHUB")
				end
				pcall(writefile, "VectaHUB/vecta_key.txt", key)
			end
		end
	end)
end

local function publishkey(key, info)
	if getgenv then
		getgenv().SenaKey = key
		getgenv().SenaDonatorKey = key
		getgenv().SenaDonatorInfo = info
	end
	if _G then
		_G.SenaKey = key
		_G.SenaDonatorKey = key
		_G.SenaDonatorInfo = info
	end
	writetierglobals()
end


-- Key names shown on keybind buttons (the full name is still what is saved).
Chloex.KeyShortNames = {
	LeftControl = "LCtrl", RightControl = "RCtrl",
	LeftShift = "LShift", RightShift = "RShift",
	LeftAlt = "LAlt", RightAlt = "RAlt",
	LeftMeta = "LMeta", RightMeta = "RMeta",
	Return = "Enter", Backspace = "Bksp", Escape = "Esc", CapsLock = "Caps",
	Delete = "Del", Insert = "Ins", PageUp = "PgUp", PageDown = "PgDn",
	Zero = "0", One = "1", Two = "2", Three = "3", Four = "4",
	Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
	KeypadZero = "Num0", KeypadOne = "Num1", KeypadTwo = "Num2", KeypadThree = "Num3",
	KeypadFour = "Num4", KeypadFive = "Num5", KeypadSix = "Num6", KeypadSeven = "Num7",
	KeypadEight = "Num8", KeypadNine = "Num9", KeypadPeriod = "Num.", KeypadDivide = "Num/",
	KeypadMultiply = "Num*", KeypadMinus = "Num-", KeypadPlus = "Num+",
	KeypadEnter = "NumEnter", KeypadEquals = "Num=",
	Backquote = "`", Minus = "-", Equals = "=", LeftBracket = "[", RightBracket = "]",
	BackSlash = "\\", Semicolon = ";", Quote = "'", Comma = ",", Period = ".", Slash = "/",
}

-- Anything a script or a saved config may hold for a key (Enum.KeyCode item,
-- "F3", "f3", "None", nil) becomes an Enum.KeyCode; unknown input = Unknown.
function Chloex:ParseKeyCode(value)
	if typeof(value) == "EnumItem" then
		if value.EnumType == Enum.KeyCode then
			return value
		end
		return Enum.KeyCode.Unknown
	end
	if type(value) == "string" then
		local name = value:gsub("%s+", "")
		if name == "" or name:lower() == "none" then
			return Enum.KeyCode.Unknown
		end
		local ok, found = pcall(function()
			return Enum.KeyCode[name]
		end)
		if ok and found then
			return found
		end
		for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
			if item.Name:lower() == name:lower() then
				return item
			end
		end
	end
	return Enum.KeyCode.Unknown
end

function Chloex:KeyCodeLabel(keycode)
	if not keycode or keycode == Enum.KeyCode.Unknown then
		return "None"
	end
	return Chloex.KeyShortNames[keycode.Name] or keycode.Name
end

function Chloex:GetSavedKey()
	local rawkey = (getgenv and (getgenv().SenaKey or getgenv().SenaDonatorKey or (getgenv().SenaDonator and getgenv().SenaDonator.Key)))
		or (_G and (_G.SenaKey or _G.SenaDonatorKey))
	if (not rawkey or rawkey == "") then
		rawkey = readsavedkey()
	end
	if type(rawkey) ~= "string" or rawkey:gsub("%s+", "") == "" then
		return nil
	end
	return rawkey:gsub("%s+", ""):upper()
end

function Chloex:CheckDonatorKey(customkey)
	local activekey = Chloex:GetSavedKey()
	local key = customkey and tostring(customkey):gsub("%s+", ""):upper() or activekey
	if not key or key == "" then
		Chloex:SetDonator(false)
		Chloex.DonatorInfo = nil
		if getgenv then
			getgenv().SenaDonatorInfo = nil
		end
		return false, "no_key"
	end

	local cfg = (getgenv and getgenv().SenaBackend) or backend or defaultbackend
	local api = tostring(cfg.Api or defaultbackend.Api):gsub("/+$", "")
	local apikey = tostring(cfg.Key or defaultbackend.Key)

	-- Same order as loader.lua (gethwid, then ClientId). A different order makes
	-- one device register two HWID slots. getexecutorname() is not an HWID:
	-- everyone on the same executor would share it.
	local hwid = ""
	pcall(function()
		if type(gethwid) == "function" then
			hwid = tostring(gethwid() or "")
		end
	end)
	if hwid == "" then
		pcall(function()
			hwid = tostring(game:GetService("RbxAnalyticsService"):GetClientId() or "")
		end)
	end
	if hwid == "" then
		hwid = "unknown"
	end

	local uid = localuserid()
	if uid == "0" or uid == "" then
		local lp = localplayer()
		if lp and lp.UserId and lp.UserId ~= 0 then
			uid = tostring(lp.UserId)
		end
	end

	local url = string.format(
		"%s/key/check?key=%s&license=%s&hwid=%s&uid=%s&place=%s&t=%s",
		api,
		sv.http:UrlEncode(apikey),
		sv.http:UrlEncode(key),
		sv.http:UrlEncode(hwid),
		sv.http:UrlEncode(uid),
		sv.http:UrlEncode(tostring(game.PlaceId or "")),
		tostring(os.time())
	)

	local okh, raw
	for attempt = 1, 3 do
		okh, raw = pcall(function()
			return game:HttpGet(url, true)
		end)
		if okh and raw and #raw > 0 then
			break
		end
		if attempt < 3 then
			task.wait(1)
		end
	end

	if okh and raw then
		local okj, res = pcall(sv.http.JSONDecode, sv.http, raw)
		if okj and type(res) == "table" and res.ok and res.valid then
			Chloex.DonatorInfo = res
			if res.is_trial == true or res.tier == "trial" then
				Chloex:SetDonator(false, true)
			else
				Chloex:UnlockAllDonatorFeatures()
			end
			publishkey(key, res)
			savekey(key)
			print(string.format("[VECTA] Donator key verified: %s (%d days left)", tostring(res.name or key), tonumber(res.days_left or 0)))
			return true, res
		end

		local reason = tostring(okj and type(res) == "table" and res.reason or "invalid"):lower()
		if not (okj and type(res) == "table" and res.ok and res.valid == false) then
			-- garbled answer or server error: not a verdict on the key
			warn("[VECTA] Bad response verifying key")
			if isdonator() and not claimexpired() then
				return true, donatorinfo() or { valid = true }
			end
			return false, "network_error"
		end
		if isdonator() and key ~= activekey then
			-- a wrong key typed into Redeem must not lock a donator whose own
			-- key is still active
			return false, reason
		end

		Chloex:SetDonator(false)
		local msg = "Invalid Key. Running in Free Mode."
		if reason:find("hwid limit") then
			msg = "HWID limit reached (3/3). Running Free Version. Reset in Discord."
		elseif reason:find("expired") then
			msg = "Donator Key expired. Running Free Version."
		end
		warn("[VECTA] " .. msg)
		pcall(function()
			Chloex:Notify({ Title = "Vecta", Description = "Free Mode", Content = msg, Duration = 6, Color = theme.Bad })
		end)
		return false, reason
	end

	-- Offline: keep the current tier only while its paid time has not run out.
	warn("[VECTA] Network error verifying key")
	if isdonator() and not claimexpired() then
		return true, donatorinfo() or { valid = true }
	end
	return false, "network_error"
end

local function handlejoinupdate(this, req)
	local id = tostring(req.id or "")
	if id == "" then
		return
	end
	this.JoinSeen = this.JoinSeen or {}
	local status = tostring(req.status or "")
	local seenkey = id .. ":" .. status
	if this.JoinSeen[seenkey] then
		return
	end
	this.JoinSeen[seenkey] = true

	for _, fn in ipairs(this.JoinListeners) do
		task.spawn(function()
			elevate()
			pcall(fn, req)
		end)
	end

	if req.incoming then
		if status ~= "pending" then
			return
		end
		if (os.time() - (tonumber(req.ts) or 0)) > 110 then
			return
		end
		Chloex:Prompt({
			Title = tostring(req.name or "Someone"),
			Content = "wants to join your server (" .. tostring(req.game or "?") .. ")",
			Avatar = tostring(req.av or ""):match("^%d+$") and req.av or nil,
			Accept = "Accept",
			Decline = "Decline",
			Duration = 60,
			Callback = function(accepted)
				if accepted == nil then
					return
				end
				local ok, err = Chloex:AnswerJoin(id, accepted == true)
				if not ok then
					Chloex:Notify({ Title = "Vecta", Description = "Request join", Content = "Could not answer: " .. tostring(err), Duration = 4 })
				elseif accepted then
					Chloex:Notify({ Title = "Vecta", Description = "Request join", Content = tostring(req.name or "They") .. " is on the way to your server.", Duration = 4 })
				end
			end,
		})
	else
		if status == "accepted" then
			local place = tonumber(req.place)
			local job = tostring(req.job or "")
			if job == tostring(game.JobId) then
				Chloex:Notify({ Title = "Vecta", Description = "Request join", Content = "You are already in " .. tostring(req.to_name or "their") .. "'s server.", Duration = 4 })
			elseif place and job ~= "" then
				Chloex:Notify({ Title = "Vecta", Description = "Request join", Content = tostring(req.to_name or "They") .. " accepted. Joining their server...", Duration = 5 })
				task.delay(1.2, function()
					pcall(function()
						local lp = localplayer()
						if lp then
							game:GetService("TeleportService"):TeleportToPlaceInstance(place, job, lp)
						end
					end)
				end)
			end
		elseif status == "declined" then
			Chloex:Notify({ Title = "Vecta", Description = "Request join", Content = tostring(req.to_name or "They") .. " declined.", Duration = 4 })
		elseif status == "expired" then
			Chloex:Notify({ Title = "Vecta", Description = "Request join", Content = tostring(req.to_name or "They") .. " did not answer.", Duration = 4 })
		end
	end
end

local function startbackendloop(this)
	if this.LoopAlive then
		return
	end
	this.LoopAlive = true

	task.spawn(function()
		elevate()
		local uid = localuserid()
		local failures = 0
		local function chatwatched()
			for _, fn in ipairs(this.Watchers or {}) do
				local ok, on = pcall(fn)
				if ok and on then
					return true
				end
			end
			return false
		end
		if not this.Game or this.Game == "" then
			this.Game = detectgamename()
		end

		while this.Running and not Chloex.Unloaded do
			if uid == "0" or uid == "" then
				uid = localuserid()
			end
			local trial = istrial()
			local don = not trial and isdonator()
			local lic = (getgenv and getgenv().SenaKey) or (_G and _G.SenaKey) or ""
			local watching = chatwatched()
			local busy = watching or next(this.Extra) ~= nil
			local params = {
				uid = uid,
				key = this.Key,
				name = localusername(),
				display = localdisplayname(),
				donator = don and "1" or "0",
				trial = trial and "1" or "0",
				lic = tostring(lic or ""),
				chat_since = watching and this.ChatSince or 2147483647,
				ann_since = this.AnnSince,
				dm_since = this.DmSince,
				join_since = this.JoinSince,
				game = this.Game or "",
				place = game.PlaceId,
			}
			for k, v in pairs(this.Extra) do
				params[k] = v
			end

			local data = httpgetjson(backendurl("/sync", params))
			this.PollCount = (this.PollCount or 0) + 1
			this.LastPollAt = os.clock()
			this.Watching = watching

			if data and ((type(data.kick) == "string" and data.kick ~= "") or data.blacklisted) then
				this.Running = false
				local kickmsg = (type(data.kick) == "string" and data.kick ~= "") and data.kick
					or "You've been blacklisted from VECTA.\nAppeal at discord.gg/NNYG29yXDv"
				pcall(function()
					local p = localplayer()
					if p then
						p:Kick(kickmsg)
					end
				end)
				return
			end

			if data and data.ok then
				failures = 0
				this.Connected = true
				this.Online = tonumber(data.online) or this.Online

				-- Tier report. Upgrades apply at once; a downgrade needs the
				-- server to have actually judged the license (lic_state from a
				-- current bot; older bots send none and never downgrade) twice
				-- in a row, so one odd answer cannot flip features off.
				if data.tier == "trial" or data.is_trial == true then
					this.FreeStreak = 0
					this.LastValid = os.time()
					if not istrial() then
						Chloex:SetDonator(false, true)
					end
				elseif data.tier == "donator" or data.is_donator == true then
					this.FreeStreak = 0
					this.LastValid = os.time()
					if not Chloex._isDonator then
						Chloex:UnlockAllDonatorFeatures()
					end
				elseif data.tier == "free" and (data.lic_state == "invalid" or data.lic_state == "none") then
					this.FreeStreak = (this.FreeStreak or 0) + 1
					if this.FreeStreak >= 2 and isdonator() then
						warn("[VECTA] Backend reports this key is no longer active, locking donator features")
						Chloex:SetDonator(false)
						pcall(function()
							Chloex:Notify({ Title = "Vecta", Description = "Donator", Content = "Your donator key is no longer active. Donator features are locked again.", Duration = 6, Color = theme.Bad })
						end)
					end
				else
					this.FreeStreak = 0
				end

				this.ChatTtl = tonumber(data.chat_ttl) or this.ChatTtl
				this.ChatMax = tonumber(data.chat_max) or this.ChatMax
				local poll = tonumber(data.poll)
				if poll then
					this.Interval = math.max(2, poll)
				end

				-- Maintenance switches (/pauseglobalchat, /pauseforum). Older bots send none = all off.
				local pausenow = {
					chat = data.chat_paused == true,
					dm = data.chat_pause_dm == true,
					chatmsg = tostring(data.chat_pause_msg or ""),
					forum = data.forum_paused == true,
					forummsg = tostring(data.forum_pause_msg or ""),
				}
				local prevpause = this.Paused or {}
				if prevpause.chat ~= pausenow.chat or prevpause.dm ~= pausenow.dm or prevpause.chatmsg ~= pausenow.chatmsg
					or prevpause.forum ~= pausenow.forum or prevpause.forummsg ~= pausenow.forummsg then
					this.Paused = pausenow
					for _, fn in ipairs(this.PauseListeners or {}) do
						task.spawn(function()
							elevate()
							local ok, err = pcall(fn, pausenow)
							if not ok then
								warn("[VECTA] pause listener error:", err)
							end
						end)
					end
				end

				local cutoff = os.time() - this.ChatTtl
				while #this.History > 0 and (tonumber(this.History[1].ts) or 0) < cutoff do
					table.remove(this.History, 1)
				end

				if type(data.chat) == "table" then
					for _, msg in ipairs(data.chat) do
						local id = tonumber(msg.id) or 0
						if id > this.ChatSince then
							this.ChatSince = id
						end
						this.History[#this.History + 1] = msg
						if #this.History > 60 then
							table.remove(this.History, 1)
						end
						for _, fn in ipairs(this.Listeners) do
							task.spawn(function()
								elevate()
								local ok, err = pcall(fn, msg)
								if not ok then
									warn("[VECTA] chat listener error:", err)
								end
							end)
						end
					end
				end

				if type(data.dm) == "table" then
					for _, msg in ipairs(data.dm) do
						local id = tonumber(msg.id) or 0
						if id > this.DmSince then
							this.DmSince = id
						end
						msg.pm = true
						this.DmHistory[#this.DmHistory + 1] = msg
						if #this.DmHistory > 60 then
							table.remove(this.DmHistory, 1)
						end
						for _, fn in ipairs(this.DmListeners) do
							task.spawn(function()
								elevate()
								local ok, err = pcall(fn, msg)
								if not ok then
									warn("[VECTA] dm listener error:", err)
								end
							end)
						end
					end
				elseif tonumber(data.dm_seq) and this.DmSince == 0 then
					this.DmSince = tonumber(data.dm_seq)
				end

				local firstjoinsync = this.JoinSince == 0
				if tonumber(data.join_seq) and firstjoinsync then
					this.JoinSince = math.max(this.JoinSince, tonumber(data.join_seq))
				end
				if type(data.joins) == "table" then
					for _, req in ipairs(data.joins) do
						local ver = tonumber(req.ver) or 0
						if ver > this.JoinSince then
							this.JoinSince = ver
						end
						if not firstjoinsync or (req.incoming and tostring(req.status) == "pending") then
							task.spawn(function()
								elevate()
								local ok, err = pcall(handlejoinupdate, this, req)
								if not ok then
									warn("[VECTA] join handler error:", err)
								end
							end)
						else
							this.JoinSeen = this.JoinSeen or {}
							this.JoinSeen[tostring(req.id or "") .. ":" .. tostring(req.status or "")] = true
						end
					end
				end

				if data.fuse ~= nil then
					for _, fn in ipairs(this.FuseListeners) do
						task.spawn(function()
							elevate()
							local ok, err = pcall(fn, data.fuse)
							if not ok then
								warn("[VECTA] fuse listener error:", err)
							end
						end)
					end
				end

				local annseq = tonumber(data.ann_seq)
				if annseq then
					if this.AnnSince < 0 then
						this.AnnSince = annseq
					elseif type(data.ann) == "table" then
						for _, ann in ipairs(data.ann) do
							local id = tonumber(ann.id) or 0
							if id > this.AnnSince then
								this.AnnSince = id
							end
						end
					end
				end
			else
				failures = failures + 1
				this.Connected = false
			end

			local wait = busy and this.Interval or math.max(this.Interval, this.IdleInterval or 60)
			if failures > 0 then
				wait = math.max(wait, math.min(30, this.Interval * (1 + failures)))
			end
			local wakeat = os.clock() + wait + (math.random(0, 1500) / 1000)
			while this.Running and not Chloex.Unloaded and os.clock() < wakeat do
				if not watching and chatwatched() then
					break
				end
				task.wait(0.5)
			end
		end

		this.LoopAlive = false
		this.Connected = false
	end)
end

function Chloex:ConnectBackend(backendconfig)
	backendconfig = backendconfig or {}
	if backendconfig.Disabled then
		return nil
	end

	if not backend then
		local api = tostring(backendconfig.Api or defaultbackend.Api or ""):gsub("/+$", "")
		if api == "" then
			warn("[VECTA] ConnectBackend: Api kosong")
			return nil
		end
		backend = {
			Api = api,
			Key = tostring(backendconfig.Key or defaultbackend.Key or ""),
			Game = backendconfig.Game and tostring(backendconfig.Game) or nil,
			Interval = math.max(2, tonumber(backendconfig.Interval) or 3),
			Announcements = backendconfig.Announcements ~= false,
			ChatSince = 0,
			AnnSince = -1,
			ChatTtl = 600,
			ChatMax = 120,
			Online = 0,
			Running = true,
			Connected = false,
			LoopAlive = false,
			Listeners = {},
			FuseListeners = {},
			DmListeners = {},
			JoinListeners = {},
			PauseListeners = {},
			Paused = {},
			DmSince = 0,
			JoinSince = 0,
			DmHistory = {},
			Extra = {},
			Watchers = {},
			IdleInterval = 60,
			History = {},
		}
	else
		if backendconfig.Api then
			backend.Api = tostring(backendconfig.Api):gsub("/+$", "")
		end
		if backendconfig.Key then
			backend.Key = tostring(backendconfig.Key)
		end
		if backendconfig.Game then
			backend.Game = tostring(backendconfig.Game)
		end
		if backendconfig.Interval then
			backend.Interval = math.max(2, tonumber(backendconfig.Interval) or backend.Interval)
		end
		if backendconfig.Announcements ~= nil then
			backend.Announcements = backendconfig.Announcements ~= false
		end
		backend.Running = true
	end

	startbackendloop(backend)
	return backend
end

function Chloex:GetBackend()
	return backend
end

function Chloex:DisconnectBackend()
	if backend then
		backend.Running = false
	end
end

function Chloex:OnChat(fn)
	if not backend or type(fn) ~= "function" then
		return false
	end
	backend.Listeners[#backend.Listeners + 1] = fn
	return true
end

function Chloex:OnDM(fn)
	if not backend or type(fn) ~= "function" then
		return false
	end
	backend.DmListeners[#backend.DmListeners + 1] = fn
	return true
end

function Chloex:OnJoin(fn)
	if not backend or type(fn) ~= "function" then
		return false
	end
	backend.JoinListeners[#backend.JoinListeners + 1] = fn
	return true
end

function Chloex:OnPause(fn)
	if not backend or type(fn) ~= "function" then
		return false
	end
	backend.PauseListeners = backend.PauseListeners or {}
	backend.PauseListeners[#backend.PauseListeners + 1] = fn
	if backend.Paused then
		task.spawn(pcall, fn, backend.Paused)
	end
	return true
end

function Chloex:GetPaused()
	return backend and backend.Paused or {}
end

function Chloex:OnFuse(fn)
	if not backend or type(fn) ~= "function" then
		return false
	end
	backend.FuseListeners[#backend.FuseListeners + 1] = fn
	return true
end

function Chloex:SetSyncExtra(key, value)
	if not backend then
		return false
	end
	backend.Extra[tostring(key)] = value
	return true
end

function Chloex:BackendCall(path, params)
	if not backend then
		return nil, "not connected"
	end
	local trial = istrial()
	local don = not trial and isdonator()
	local lic = (getgenv and getgenv().SenaKey) or (_G and _G.SenaKey) or ""
	local merged = {
		uid = localuserid(),
		key = backend.Key,
		name = localusername(),
		display = localdisplayname(),
		game = backend.Game or "",
		place = game.PlaceId,
		donator = don and "1" or "0",
		trial = trial and "1" or "0",
		lic = tostring(lic or ""),
	}
	for k, v in pairs(params or {}) do
		merged[k] = v
	end
	local data = httpgetjson(backendurl(path, merged))
	if not data then
		return nil, "no response"
	end
	if data.ok == false then
		return data, tostring(data.error or "error")
	end
	return data, nil
end

local roomtagmap = {
	id = "indonesian",
	indo = "indonesian",
	indonesia = "indonesian",
	indonesian = "indonesian",
	ph = "philippines",
	philippines = "philippines",
	filipino = "philippines",
	pinoy = "philippines",
	vn = "vietnam",
	vietnam = "vietnam",
	vietnamese = "vietnam",
	br = "brazilian",
	brazil = "brazilian",
	brazilian = "brazilian",
	brasil = "brazilian",
	gen = "general",
	general = "general",
	all = "general",
}

local roomtags = {
	indonesian = "[ID]",
	philippines = "[PH]",
	vietnam = "[VN]",
	brazilian = "[BR]",
	general = "[GEN]",
}

local function parsemessageroom(msg)
	if type(msg) ~= "table" then
		return "general", ""
	end
	local text = tostring(msg.text or "")
	local tag, body = text:match("^%[([%w_]+)%]%s*(.*)$")
	local detected = nil
	if tag then
		local r = roomtagmap[tag:lower()]
		if r then
			detected = r
			text = body
		end
	end
	if msg.room and type(msg.room) == "string" and msg.room ~= "" then
		local r = roomtagmap[msg.room:lower()]
		if r then
			detected = r
		end
	end
	return detected or "general", text
end

local function keysharenotice()
	pcall(function()
		Chloex:Notify({
			Title = "Vecta",
			Description = "Chat",
			Content = "Message blocked: sharing license keys in chat is not allowed.",
			Duration = 6,
			Color = theme.Bad,
		})
	end)
end

local function badwordkick(err, where)
	local minutes = err:match("^badword:(%d+)") or "?"
	local reason = "Vecta: offensive language detected in " .. where .. ". Banned for " .. minutes .. " minutes."
	task.delay(1.5, function()
		pcall(function()
			local p = localplayer()
			if p then
				p:Kick(reason)
			end
		end)
	end)
end

function Chloex:SendChat(text, room, hide)
	if not backend then
		return false, "not connected"
	end
	text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if text == "" then
		return false, "empty"
	end

	local upper = text:upper()
	if upper:match("TRIAL%-[%w]+%-[%w]+%-[%w]+") or text:match("%w%w%w%w%-%w%w%w%w%-%w%w%w%w") then
		keysharenotice()
		return false, "Sharing key is prohibited"
	end

	room = tostring(room or "general"):lower()
	local tag = roomtags[room]
	local sendtext = text
	if tag and not sendtext:find("^%[") and room ~= "general" then
		sendtext = tag .. " " .. text
	end

	local trial = istrial()
	local don = not trial and isdonator()
	local lic = (getgenv and getgenv().SenaKey) or (_G and _G.SenaKey) or ""

	local ishide = false
	do
		if hide ~= nil then
			ishide = (hide == true or hide == "1" or hide == 1)
		elseif getgenv and getgenv().SenaHideName ~= nil then
			ishide = (getgenv().SenaHideName == true)
		elseif _G and _G.SenaHideName ~= nil then
			ishide = (_G.SenaHideName == true)
		elseif Chloex.HideName ~= nil then
			ishide = (Chloex.HideName == true)
		else
			ishide = true
		end
	end

	local data = httpgetjson(backendurl("/chat/send", {
		uid = localuserid(),
		key = backend.Key,
		name = localusername(),
		game = backend.Game,
		text = sendtext,
		room = room,
		donator = don and "1" or "0",
		trial = trial and "1" or "0",
		lic = tostring(lic or ""),
		hide = ishide and "1" or "0",
	}))
	if not data then
		return false, "no response"
	end
	if data.ok then
		return true
	end
	local err = tostring(data.error or "error")
	if err:match("key_share") then
		keysharenotice()
	elseif err:match("^badword") then
		badwordkick(err, "global chat")
	end
	return false, err
end

function Chloex:SendDM(toname, text)
	if not backend then
		return false, "not connected"
	end
	toname = tostring(toname or ""):gsub("^@", "")
	text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if toname == "" then
		return false, "who?"
	end
	if text == "" then
		return false, "empty"
	end
	local data, err = Chloex:BackendCall("/dm/send", { to = toname, text = text })
	if not data then
		return false, err
	end
	if data.ok then
		return true, data.to_name
	end
	err = tostring(data.error or "error")
	if err:match("^badword") then
		badwordkick(err, "chat")
	end
	return false, err
end

function Chloex:RequestJoin(toname)
	if not backend then
		return false, "not connected"
	end
	toname = tostring(toname or ""):gsub("^@", "")
	if toname == "" then
		return false, "who?"
	end
	local data, err = Chloex:BackendCall("/join/request", { to = toname })
	if not data then
		return false, err
	end
	if data.ok then
		return true, data.to_name
	end
	return false, tostring(data.error or "error")
end

function Chloex:AnswerJoin(id, accept)
	if not backend then
		return false, "not connected"
	end
	local data, err = Chloex:BackendCall("/join/answer", {
		id = tostring(id),
		accept = accept and "1" or "0",
		place = tostring(game.PlaceId),
		job = tostring(game.JobId),
	})
	if not data then
		return false, err
	end
	if data.ok then
		return true
	end
	return false, tostring(data.error or "error")
end

function Chloex:Window(guiconfig)
	guiconfig = guiconfig or {}
	Chloex.Unloaded = false
	-- the loader may have verified the key after this lib was loaded
	adoptclaim()
	if backend and not backend.Running then
		Chloex:ConnectBackend({})
	end
	guiconfig.Title = guiconfig.Title or "Vecta"
	guiconfig.Footer = guiconfig.Footer or "Vecta"
	guiconfig.Color = guiconfig.Color or theme.Accent
	guiconfig["Tab Width"] = guiconfig["Tab Width"] or 120
	-- On phones the sidebar is icon-only (44 px) so the page gets that width back.
	local compactsidebar = isMobile and guiconfig.CompactSidebar ~= false
	local tabwidth = compactsidebar and 44 or guiconfig["Tab Width"]
	guiconfig.Version = guiconfig.Version or 1
	local userPassedImage = guiconfig.Image
	local userPassedToggle = guiconfig.ToggleImage or guiconfig.ToggleIcon or guiconfig.ButtonImage
	guiconfig.Image = guiconfig.Image or "100997912316573"
	-- floating logo size in pixels: LogoSize, ToggleSize or ImageSize (first one set)
	guiconfig.ImageSize = math.clamp(
		math.floor(tonumber(guiconfig.LogoSize) or tonumber(guiconfig.ToggleSize) or tonumber(guiconfig.ImageSize) or 48),
		16,
		256
	)
	guiconfig.AutoConfigTab = guiconfig.AutoConfigTab ~= false
	guiconfig.LazyConfigTab = guiconfig.LazyConfigTab ~= false
	guiconfig.LoadUserThumbnail = guiconfig.LoadUserThumbnail ~= false
	guiconfig.ThumbnailDelay = tonumber(guiconfig.ThumbnailDelay) or 8

	config.version = guiconfig.Version
	config:init(guiconfig.Folder)

	local guifunc = {}
	getgenv().ChloeX_Instance = guifunc
	local chloeex = instance.screengui(sv.coregui)
	chloeex.Name = "Chloeex"
	chloeex.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	chloeex.ResetOnSpawn = false

	local dropshadowholder = instance.frame(chloeex)
	dropshadowholder.Name = "DropShadowHolder"
	dropshadowholder.BackgroundTransparency = 1
	dropshadowholder.BorderSizePixel = 0
	dropshadowholder.AnchorPoint = Vector2.new(0.5, 0.5)
	dropshadowholder.Position = UDim2.new(0.5, 0, 0.5, 0)
	dropshadowholder.ZIndex = 0
	-- size comes from makedraggable (saved size or default, clamped to the screen)
	dropshadowholder.Size = UDim2.new(0, draggable.defx, 0, draggable.defy)

	dropshadowholder.Position = UDim2.new(0.5, 0, 0.5, 0)

	local dropshadow = instance.imagelabel(dropshadowholder)
	dropshadow.Name = "DropShadow"
	dropshadow.Image = "rbxassetid://6015897843"
	dropshadow.ImageColor3 = Color3.fromRGB(15, 15, 15)
	dropshadow.ImageTransparency = 1
	dropshadow.ScaleType = Enum.ScaleType.Slice
	dropshadow.SliceCenter = Rect.new(49, 49, 450, 450)
	dropshadow.AnchorPoint = Vector2.new(0.5, 0.5)
	dropshadow.BackgroundTransparency = 1
	dropshadow.BorderSizePixel = 0
	dropshadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	dropshadow.Size = UDim2.new(1, 47, 1, 47)
	dropshadow.ZIndex = 0

	-- Any Image other than the default Vecta logo is the window background; the
	-- floating button logo comes from ToggleImage / ToggleIcon / ButtonImage.
	local bgRaw = guiconfig.Theme
		or guiconfig.Background
		or guiconfig.BackgroundImage
		or (
			userPassedImage
			and (tostring(userPassedImage):gsub("%s+", ""):gsub("^rbxassetid://", "")) ~= "100997912316573"
			and userPassedImage
		)

	local bgAsset = nil
	if bgRaw then
		local s = tostring(bgRaw):gsub("^%s+", ""):gsub("%s+$", "")
		if s ~= "" and s:lower() ~= "none" and s:lower() ~= "false" then
			if s:match("^%d+$") then
				bgAsset = "rbxassetid://" .. s
			elseif not s:match("^%a+://") then
				bgAsset = "rbxassetid://" .. s:gsub("^rbxassetid://", "")
			else
				bgAsset = s
			end
		end
	end

	local main
	if bgAsset then
		main = instance.imagelabel(dropshadow)
		if bgAsset:match("^https?://") then
			local url = bgAsset
			-- already in Vecta/cache: show it right away, only the first run downloads
			main.Image = urlimage(url, true) or ""
			task.spawn(function()
				if main.Image ~= "" then
					return
				end
				local asset = urlimage(url)
				if asset and main.Parent then
					elevate()
					main.Image = asset
				end
			end)
		else
			main.Image = bgAsset
		end
		main.ScaleType = Enum.ScaleType.Crop
		main.BackgroundTransparency = 0
		main.BackgroundColor3 = theme.Backdrop
		local dim = math.clamp(tonumber(guiconfig.ThemeDim or guiconfig.BackgroundDim) or 0.6, 0, 1)
		local gray = math.floor((1 - dim) * 255 + 0.5)
		main.ImageColor3 = Color3.fromRGB(gray, gray, gray)
		rowalpha = math.clamp(tonumber(guiconfig.RowTransparency or guiconfig.RowAlpha) or 0.15, 0, 0.9)
	else
		rowalpha = 0
		main = instance.frame(dropshadow)
		main.BackgroundColor3 = theme.Backdrop
		main.BackgroundTransparency = 0
	end

	local mainstroke = instance.uistroke(main)
	mainstroke.Color = theme.Stroke
	mainstroke.Thickness = 1
	main.Name = "Main"
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.BorderColor3 = Color3.fromRGB(0, 0, 0)
	main.BorderSizePixel = 0
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.Size = UDim2.new(1, -47, 1, -47)

	local uicorner = instance.uicorner(main)

	local top = instance.frame(main)
	top.Name = "Top"
	top.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	top.BackgroundTransparency = 1
	top.BorderColor3 = Color3.fromRGB(0, 0, 0)
	top.BorderSizePixel = 0
	top.Size = UDim2.new(1, 0, 0, 38)

	local textlabel = instance.textlabel(top)
	textlabel.FontFace = FONT_BOLD
	textlabel.Text = guiconfig.Title
	textlabel.TextColor3 = theme.Text
	textlabel.TextSize = ts(14)
	textlabel.TextTruncate = Enum.TextTruncate.AtEnd
	textlabel.TextXAlignment = Enum.TextXAlignment.Left
	textlabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	textlabel.BackgroundTransparency = 1
	textlabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	textlabel.BorderSizePixel = 0
	textlabel.Size = UDim2.new(1, -100, 1, 0)
	textlabel.Position = UDim2.new(0, 10, 0, 0)

	local uicorner1 = instance.uicorner(top)

	-- Footer text is the subtitle: lighter weight, dimmer, placed right after the
	-- title. Laid out from measured widths every time the bar resizes, so it never
	-- runs under the search box (it was positioned once, from TextBounds at 0).
	local textlabel1 = instance.textlabel(top)
	textlabel1.FontFace = FONT_MEDIUM
	textlabel1.Text = guiconfig.Footer
	textlabel1.TextColor3 = theme.SubText
	textlabel1.TextSize = ts(13)
	textlabel1.TextTruncate = Enum.TextTruncate.AtEnd
	textlabel1.TextXAlignment = Enum.TextXAlignment.Left
	textlabel1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	textlabel1.BackgroundTransparency = 1
	textlabel1.BorderColor3 = Color3.fromRGB(0, 0, 0)
	textlabel1.BorderSizePixel = 0
	textlabel1.Size = UDim2.new(0, 0, 1, 0)
	textlabel1.Position = UDim2.new(0, 10, 0, 0)

	local headerreserve = (isMobile and 110 or 150) + 94 + 12
	local headerchips = { rows = {} }
	headerchips.holder = instance.frame(top)
	headerchips.holder.Name = "HeaderChips"
	headerchips.holder.AnchorPoint = Vector2.new(1, 0.5)
	headerchips.holder.Position = UDim2.new(1, -(headerreserve - 4), 0.5, 0)
	headerchips.holder.Size = UDim2.new(0, 0, 0, 22)
	headerchips.holder.AutomaticSize = Enum.AutomaticSize.X
	headerchips.holder.BackgroundTransparency = 1
	headerchips.holder.BorderSizePixel = 0
	local headerchiplayout = instance.uilistlayout(headerchips.holder)
	headerchiplayout.FillDirection = Enum.FillDirection.Horizontal
	headerchiplayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	headerchiplayout.VerticalAlignment = Enum.VerticalAlignment.Center
	headerchiplayout.SortOrder = Enum.SortOrder.LayoutOrder
	headerchiplayout.Padding = UDim.new(0, 4)
	local function layoutheader()
		local reserve = headerreserve + math.floor(headerchips.holder.AbsoluteSize.X) + (headerchips.holder.AbsoluteSize.X > 0 and 6 or 0)
		local avail = math.max(60, top.AbsoluteSize.X - 10 - reserve)
		if top.AbsoluteSize.X <= 1 then
			avail = draggable.defx - 10 - reserve
		end
		local titlew = math.min(textwidth(textlabel.Text, 14, FONT_BOLD) + 2, math.floor(avail * 0.65))
		textlabel.Size = UDim2.new(0, titlew, 1, 0)
		local footerx = 10 + titlew + 6
		textlabel1.Position = UDim2.new(0, footerx, 0, 0)
		textlabel1.Size = UDim2.new(0, math.max(0, avail - titlew - 6), 1, 0)
	end
	layoutheader()
	top:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutheader)
	textlabel:GetPropertyChangedSignal("Text"):Connect(layoutheader)
	headerchips.holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutheader)
	function headerchips.row(i)
		local row = headerchips.rows[i]
		if row then return row end
		local chip = instance.frame(headerchips.holder)
		chip.Name = "Chip" .. i
		chip.LayoutOrder = i
		chip.Size = UDim2.new(0, 0, 0, 22)
		chip.AutomaticSize = Enum.AutomaticSize.X
		chip.BackgroundColor3 = theme.Pill
		chip.BorderSizePixel = 0
		instance.uicorner(chip).CornerRadius = UDim.new(0, 5)
		local chipstroke = instance.uistroke(chip)
		chipstroke.Color = theme.Stroke
		chipstroke.Transparency = 0.3
		local pad = instance.uipadding(chip)
		pad.PaddingLeft = UDim.new(0, 5)
		pad.PaddingRight = UDim.new(0, 8)
		local lay = instance.uilistlayout(chip)
		lay.FillDirection = Enum.FillDirection.Horizontal
		lay.VerticalAlignment = Enum.VerticalAlignment.Center
		lay.SortOrder = Enum.SortOrder.LayoutOrder
		lay.Padding = UDim.new(0, 4)
		local img = instance.imagelabel(chip)
		img.BackgroundTransparency = 1
		img.ScaleType = Enum.ScaleType.Fit
		img.Size = UDim2.new(0, 14, 0, 14)
		img.LayoutOrder = 1
		local label = instance.textlabel(chip)
		label.BackgroundTransparency = 1
		label.FontFace = FONT_MEDIUM
		label.TextSize = ts(12)
		label.TextColor3 = theme.Text
		label.Size = UDim2.new(0, 0, 1, 0)
		label.AutomaticSize = Enum.AutomaticSize.X
		label.LayoutOrder = 2
		row = { frame = chip, img = img, label = label }
		headerchips.rows[i] = row
		return row
	end

	local close = instance.textbutton(top)
	close.Name = "Close"
	close.FontFace = FONT_MEDIUM
	close.Text = ""
	close.TextColor3 = Color3.fromRGB(0, 0, 0)
	close.TextSize = ts(14)
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	close.BackgroundTransparency = 1
	close.BorderColor3 = Color3.fromRGB(0, 0, 0)
	close.BorderSizePixel = 0
	close.Position = UDim2.new(1, -8, 0.5, 0)
	close.Size = UDim2.new(0, 25, 0, 25)
	-- above any header sibling that might be drawn over it
	close.ZIndex = 5

	-- The X is drawn from two bars, not an icon image: it went missing in the header on
	-- some clients even though the button still worked.
	local closebars = {}
	for _, angle in ipairs({ 45, -45 }) do
		local bar = instance.frame(close)
		bar.Name = "CloseBar"
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.BackgroundColor3 = theme.SubText
		bar.BackgroundTransparency = 0
		bar.BorderSizePixel = 0
		bar.Position = UDim2.new(0.5, 0, 0.5, 0)
		bar.Rotation = angle
		bar.ZIndex = 5
		bar.Size = UDim2.new(0, 13, 0, 2)
		instance.uicorner(bar).CornerRadius = UDim.new(1, 0)
		closebars[#closebars + 1] = bar
	end
	local function paintclose(color)
		for _, bar in ipairs(closebars) do
			bar.BackgroundColor3 = color
		end
	end
	close.MouseEnter:Connect(function()
		paintclose(theme.Bad)
	end)
	close.MouseLeave:Connect(function()
		paintclose(theme.SubText)
	end)

	local min = instance.textbutton(top)
	min.Name = "Min"
	min.FontFace = FONT_MEDIUM
	min.Text = ""
	min.TextColor3 = Color3.fromRGB(0, 0, 0)
	min.TextSize = ts(14)
	min.AnchorPoint = Vector2.new(1, 0.5)
	min.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	min.BackgroundTransparency = 1
	min.BorderColor3 = Color3.fromRGB(0, 0, 0)
	min.BorderSizePixel = 0
	min.Position = UDim2.new(1, -38, 0.5, 0)
	min.Size = UDim2.new(0, 25, 0, 25)

	local imagelabel2 = instance.imagelabel(min)
	imagelabel2.AnchorPoint = Vector2.new(0.5, 0.5)
	imagelabel2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	imagelabel2.BackgroundTransparency = 1
	imagelabel2.ImageColor3 = theme.SubText
	imagelabel2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	imagelabel2.BorderSizePixel = 0
	imagelabel2.Position = UDim2.new(0.5, 0, 0.5, 0)
	imagelabel2.Size = UDim2.new(0, 15, 0, 15)
	applyicon(imagelabel2, "minus", 48)
	min.MouseEnter:Connect(function()
		imagelabel2.ImageColor3 = theme.Text
	end)
	min.MouseLeave:Connect(function()
		imagelabel2.ImageColor3 = theme.SubText
	end)

	-- Dot button (left of minimize): on = the floating logo can be dragged,
	-- off = the logo is locked in place. Icons come from the Lucide API.
	local logodrag = { enabled = true }
	local dotbtn = instance.textbutton(top)
	dotbtn.Name = "LogoDragToggle"
	dotbtn.FontFace = FONT_BOLD
	dotbtn.Text = ""
	dotbtn.TextSize = ts(18)
	dotbtn.TextColor3 = theme.SubText
	dotbtn.AnchorPoint = Vector2.new(1, 0.5)
	dotbtn.BackgroundTransparency = 1
	dotbtn.BorderSizePixel = 0
	dotbtn.Position = UDim2.new(1, -66, 0.5, 0)
	dotbtn.Size = UDim2.new(0, 25, 0, 25)
	dotbtn.ZIndex = 5

	local dotimage = instance.imagelabel(dotbtn)
	dotimage.AnchorPoint = Vector2.new(0.5, 0.5)
	dotimage.BackgroundTransparency = 1
	dotimage.ImageColor3 = theme.SubText
	dotimage.BorderSizePixel = 0
	dotimage.Position = UDim2.new(0.5, 0, 0.5, 0)
	dotimage.Size = UDim2.new(0, 13, 0, 13)
	dotimage.ZIndex = 5

	local function paintdot(color)
		dotimage.ImageColor3 = color
		dotbtn.TextColor3 = color
	end
	local function refreshdot()
		-- draggable = circle-dashed, locked = circle-dot-dashed
		local ok = applyicon(dotimage, logodrag.enabled and "circle-dashed" or "circle-dot-dashed", 48)
		dotimage.Visible = ok
		-- plain-text fallback if the Lucide pack could not load
		dotbtn.Text = ok and "" or (logodrag.enabled and "\194\176" or "\226\128\162")
	end
	refreshdot()
	dotbtn.MouseEnter:Connect(function()
		paintdot(theme.Text)
	end)
	dotbtn.MouseLeave:Connect(function()
		paintdot(theme.SubText)
	end)
	dotbtn.Activated:Connect(function()
		logodrag.enabled = not logodrag.enabled
		refreshdot()
	end)

	local searchbox = instance.textbox(top)
	searchbox.Name = "SearchBox"
	searchbox.AnchorPoint = Vector2.new(1, 0.5)
	searchbox.Position = UDim2.new(1, -94, 0.5, 0)
	searchbox.Size = UDim2.new(0, isMobile and 110 or 150, 0, 24)
	searchbox.BackgroundColor3 = theme.Pill
	searchbox.BackgroundTransparency = 0
	searchbox.BorderSizePixel = 0
	searchbox.FontFace = FONT_MEDIUM
	searchbox.PlaceholderText = "Search"
	searchbox.PlaceholderColor3 = theme.Dim
	searchbox.Text = ""
	searchbox.TextColor3 = theme.Text
	searchbox.TextSize = ts(12)
	searchbox.TextXAlignment = Enum.TextXAlignment.Left
	searchbox.ClearTextOnFocus = false
	searchbox.ClipsDescendants = true
	searchbox.TextTruncate = Enum.TextTruncate.AtEnd
	instance.uicorner(searchbox).CornerRadius = UDim.new(0, 5)

	local searchstroke = instance.uistroke(searchbox)
	searchstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	searchstroke.Color = theme.Stroke
	searchstroke.Thickness = 1
	searchstroke.Transparency = 0.15

	local searchpad = instance.uipadding(searchbox)
	searchpad.PaddingLeft = UDim.new(0, 26)
	searchpad.PaddingRight = UDim.new(0, 10)

	local searchicon = instance.imagelabel(searchbox)
	searchicon.AnchorPoint = Vector2.new(0, 0.5)
	searchicon.Position = UDim2.new(0, -17, 0.5, 0)
	searchicon.Size = UDim2.new(0, 12, 0, 12)
	searchicon.BackgroundTransparency = 1
	searchicon.ImageColor3 = theme.Dim
	applyicon(searchicon, "search", 48)

	local layerstab = instance.frame(main)
	layerstab.Name = "LayersTab"
	layerstab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	layerstab.BackgroundTransparency = 1
	layerstab.BorderColor3 = Color3.fromRGB(0, 0, 0)
	layerstab.BorderSizePixel = 0
	layerstab.Position = UDim2.new(0, 3, 0, 50)
	layerstab.Size = UDim2.new(0, tabwidth, 1, -93)

	local uicorner2 = instance.uicorner(layerstab)
	uicorner2.CornerRadius = UDim.new(0, 2)

	local decideframe = instance.frame(main)
	decideframe.Name = "DecideFrame"
	decideframe.AnchorPoint = Vector2.new(0.5, 0)
	decideframe.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	decideframe.BackgroundTransparency = 0.85
	decideframe.BorderColor3 = Color3.fromRGB(0, 0, 0)
	decideframe.BorderSizePixel = 0
	decideframe.Position = UDim2.new(0.5, 0, 0, 38)
	decideframe.Size = UDim2.new(1, 0, 0, 1)

	local decidesaparator = instance.frame(layerstab)
	decidesaparator.Name = "DecideSaparator"
	decidesaparator.AnchorPoint = Vector2.new(1, 0)
	decidesaparator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	decidesaparator.BackgroundTransparency = 0.85
	decidesaparator.BorderColor3 = Color3.fromRGB(0, 0, 0)
	decidesaparator.BorderSizePixel = 0
	decidesaparator.Position = UDim2.new(1, 3, 0, -11)
	decidesaparator.Size = UDim2.new(0, 1, 1, 17)
	decidesaparator.Rotation = 0

	-- With a photo background, a soft dark scrim sits behind the page so rows and
	-- text keep their contrast on bright images.
	if bgAsset then
		local pagescrim = instance.frame(main)
		pagescrim.Name = "PageScrim"
		pagescrim.BackgroundColor3 = theme.Backdrop
		pagescrim.BackgroundTransparency = 0.4
		pagescrim.BorderSizePixel = 0
		pagescrim.Position = UDim2.new(0, tabwidth + 9, 0, 44)
		pagescrim.Size = UDim2.new(1, -(tabwidth + 12), 1, -84)
		instance.uicorner(pagescrim).CornerRadius = UDim.new(0, 6)
	end

	local layers = instance.frame(main)
	layers.Name = "Layers"
	layers.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	layers.BackgroundTransparency = 1
	layers.BorderColor3 = Color3.fromRGB(0, 0, 0)
	layers.BorderSizePixel = 0
	layers.Position = UDim2.new(0, tabwidth + 13, 0, 40)
	layers.Size = UDim2.new(1, -(tabwidth + 20), 1, -83)

	local uicorner6 = instance.uicorner(layers)
	uicorner6.CornerRadius = UDim.new(0, 2)

	local layersreal = instance.frame(layers)
	layersreal.Name = "LayersReal"
	layersreal.AnchorPoint = Vector2.new(0, 1)
	layersreal.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	layersreal.BackgroundTransparency = 1
	layersreal.BorderColor3 = Color3.fromRGB(0, 0, 0)
	layersreal.BorderSizePixel = 0
	layersreal.ClipsDescendants = true
	layersreal.Position = UDim2.new(0, 0, 1, 0)
	layersreal.Size = UDim2.new(1, 0, 1, 0)

	local layersfolder = instance.folder(layersreal)
	layersfolder.Name = "LayersFolder"

	local layerspagelayout = instance.uipagelayout(layersfolder)
	layerspagelayout.Name = "LayersPageLayout"
	layerspagelayout.SortOrder = Enum.SortOrder.LayoutOrder
	layerspagelayout.TweenTime = 0
	layerspagelayout.EasingDirection = Enum.EasingDirection.InOut
	layerspagelayout.EasingStyle = Enum.EasingStyle.Quad
	layerspagelayout.GamepadInputEnabled = false
	layerspagelayout.ScrollWheelInputEnabled = false
	layerspagelayout.TouchInputEnabled = false

	local scrolltab = instance.scrollingframe(layerstab)
	scrolltab.Name = "ScrollTab"
	scrolltab.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrolltab.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
	scrolltab.ScrollBarThickness = 0
	scrolltab.Active = true
	scrolltab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	scrolltab.BackgroundTransparency = 1
	scrolltab.BorderColor3 = Color3.fromRGB(0, 0, 0)
	scrolltab.BorderSizePixel = 0
	scrolltab.Size = UDim2.new(1, 0, 0.89, 30)

	local uilistlayout = instance.uilistlayout(scrolltab)
	uilistlayout.Padding = UDim.new(0, 3)
	uilistlayout.SortOrder = Enum.SortOrder.LayoutOrder
	uilistlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

	local scrolltabpad = instance.uipadding(scrolltab)
	scrolltabpad.PaddingTop = UDim.new(0, 4)
	scrolltabpad.PaddingLeft = UDim.new(0, 6)
	scrolltabpad.PaddingRight = UDim.new(0, 6)

	local function updatesize1()
		scrolltab.CanvasSize = UDim2.new(0, 0, 0, uilistlayout.AbsoluteContentSize.Y)
	end

	trackConnection(
		uilistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			debounceResize("tabscroll_resize", updatesize1, 0.05)
		end),
		"tabscroll.propertychanged"
	)
	updatesize1()

	local userfooter = instance.frame(main)
	userfooter.Name = "UserFooter"
	userfooter.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	userfooter.BackgroundTransparency = 1
	userfooter.BorderSizePixel = 0
	userfooter.AnchorPoint = Vector2.new(0, 1)
	userfooter.Position = UDim2.new(0, 0, 1, 0)
	userfooter.Size = UDim2.new(1, 0, 0, 36)

	local uic = instance.uicorner(userfooter)
	uic.CornerRadius = UDim.new(0, 4)

	local headshot = instance.imagelabel(userfooter)
	headshot.Name = "Headshot"
	headshot.BackgroundColor3 = theme.Element
	headshot.BackgroundTransparency = 0.3
	headshot.Size = UDim2.new(0, 25, 0, 25)
	headshot.Position = UDim2.new(0, 10, 0.2, -3)

	local hscorner = instance.uicorner(headshot)
	hscorner.Name = "HS_Corner"
	hscorner.CornerRadius = UDim.new(1, 0)

	local username = instance.textlabel(userfooter)
	username.Name = "Username"
	username.BackgroundTransparency = 1
	username.FontFace = FONT_MEDIUM
	username.TextColor3 = Color3.fromRGB(255, 255, 255)
	username.TextSize = 7
	username.TextXAlignment = Enum.TextXAlignment.Left
	username.Position = UDim2.new(0, 42, 0, 0)
	username.Size = UDim2.new(0, 140, 1, 0)
	username.TextTruncate = Enum.TextTruncate.AtEnd

	local localplayer = sv.plrs.LocalPlayer
	local rawname = localplayer and localplayer.Name or "User"
	local shortname

	if #rawname > 3 then
		shortname = string.sub(rawname, 1, 3) .. "..."
	else
		shortname = rawname
	end

	username.Text = "Welcome, " .. shortname

	local showident = false

	local function updateIdent()
		username.Text = "Welcome, " .. (showident and rawname or shortname)
	end

	local footerclick = instance.textbutton(userfooter)
	footerclick.Name = "UserFooterClick"
	footerclick.BackgroundTransparency = 1
	footerclick.Text = ""
	footerclick.Size = UDim2.new(0, 150, 1, 0)
	footerclick.ZIndex = 20
	footerclick.Activated:Connect(function()
		showident = not showident
		updateIdent()
	end)

	-- Footer status chips (Executor, FPS) are read-only, so they carry no fill and
	-- no border. A pressable chip (Button = true, e.g. Join Discord) also has no fill:
	-- it gets a fully transparent border and wider padding so it stays apart from the
	-- chips next to it, and only its text brightens on hover.
	local function makepill(parent, pillconfig)
		local pill = pillconfig.Button and instance.textbutton(parent) or instance.frame(parent)
		if pillconfig.Button then
			pill.Text = ""
			pill.AutoButtonColor = false
		end
		pill.Name = pillconfig.Name or "Pill"
		pill.LayoutOrder = pillconfig.LayoutOrder or 1
		pill.BackgroundColor3 = theme.Pill
		pill.BackgroundTransparency = 1
		pill.BorderSizePixel = 0
		pill.AutomaticSize = Enum.AutomaticSize.X
		pill.Size = UDim2.new(0, 0, 0, 22)
		instance.uicorner(pill).CornerRadius = UDim.new(0, 5)

		if pillconfig.Button then
			local pillstroke = instance.uistroke(pill)
			pillstroke.Name = "PillStroke"
			pillstroke.Color = theme.Stroke
			pillstroke.Thickness = 1
			-- fully transparent: the border only reserves the edge, it draws nothing
			pillstroke.Transparency = 1
			pillstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		end

		local pad = instance.uipadding(pill)
		pad.PaddingLeft = UDim.new(0, pillconfig.Button and 8 or 4)
		pad.PaddingRight = UDim.new(0, pillconfig.Button and 8 or 4)

		local layout = instance.uilistlayout(pill)
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 6)
		layout.SortOrder = Enum.SortOrder.LayoutOrder

		local icon
		if pillconfig.Icon then
			icon = instance.imagelabel(pill)
			icon.LayoutOrder = 1
			icon.BackgroundTransparency = 1
			local iconpx = pillconfig.IconSize or 15
			icon.Size = UDim2.new(0, iconpx, 0, iconpx)
			icon.ImageColor3 = pillconfig.Color or theme.SubText
			applyicon(icon, pillconfig.Icon, 48)
		end

		local label = instance.textlabel(pill)
		label.LayoutOrder = 2
		label.BackgroundTransparency = 1
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.new(0, 0, 1, 0)
		label.FontFace = FONT_BOLD
		label.Text = pillconfig.Text or ""
		label.TextColor3 = pillconfig.Color or theme.SubText
		label.TextSize = 7

		return pill, label, icon
	end

	local statusstrip = instance.frame(userfooter)
	statusstrip.Name = "Status"
	statusstrip.AnchorPoint = Vector2.new(1, 0.5)
	statusstrip.Position = UDim2.new(1, -10, 0.5, 0)
	statusstrip.Size = UDim2.new(0, 0, 0, 22)
	statusstrip.AutomaticSize = Enum.AutomaticSize.X
	statusstrip.BackgroundTransparency = 1

	local striplayout = instance.uilistlayout(statusstrip)
	striplayout.FillDirection = Enum.FillDirection.Horizontal
	striplayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	striplayout.VerticalAlignment = Enum.VerticalAlignment.Center
	striplayout.Padding = UDim.new(0, 10)
	striplayout.SortOrder = Enum.SortOrder.LayoutOrder

	if not isMobile then
		makepill(statusstrip, { Name = "Executor", LayoutOrder = 1, Icon = "terminal", Text = executorname() })
	end

	do
		local discordlink = "https://discord.gg/NNYG29yXDv"
		local discordpill, discordlabel, discordicon = makepill(statusstrip, {
			Name = "JoinDiscord",
			LayoutOrder = 2,
			Icon = "77061761388242",
			Text = "Join Discord",
			Button = true,
		})
		-- keep the logo's own colours instead of the grey chip tint
		discordicon.ImageColor3 = Color3.new(1, 1, 1)
		discordicon.Size = UDim2.new(0, 18, 0, 18)
		discordpill.MouseEnter:Connect(function()
			discordlabel.TextColor3 = theme.Text
		end)
		discordpill.MouseLeave:Connect(function()
			discordlabel.TextColor3 = theme.SubText
		end)
		discordpill.Activated:Connect(function()
			elevate()
			if clipboardwrite(discordlink) then
				Chloex:Notify({
					Title = "Vecta",
					Description = "Discord",
					Content = "Discord link copied to clipboard",
					Duration = 3,
					Color = theme.Good,
				})
			else
				Chloex:Notify({
					Title = "Vecta",
					Description = "Discord",
					Content = "Clipboard not supported: " .. discordlink,
					Duration = 6,
					Color = theme.Bad,
				})
			end
		end)
	end

	local _, fpslabel = makepill(statusstrip, { Name = "Fps", LayoutOrder = 3, Icon = "activity", Text = "-- FPS" })

	do
		local frames, elapsed = 0, 0
		trackConnection(
			game:GetService("RunService").RenderStepped:Connect(function(dt)
				frames = frames + 1
				elapsed = elapsed + dt
				if elapsed >= 1 then
					fpslabel.Text = tostring(math.floor(frames / elapsed + 0.5)) .. " FPS"
					frames, elapsed = 0, 0
				end
			end),
			"footer.fps"
		)
	end

	if guiconfig.LoadUserThumbnail then
		task.delay(math.max(0, guiconfig.ThumbnailDelay), function()
			local uid = localplayer and localplayer.UserId
			if not uid or not headshot or not headshot.Parent then
				return
			end

			local ok, content = pcall(function()
				return sv.plrs:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			end)

			if ok and content and headshot and headshot.Parent then
				headshot.Image = content
			end
		end)
	end

	local decideframe2 = instance.frame(main)
	decideframe2.Name = "DecideFrame2"
	decideframe2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	decideframe2.BackgroundTransparency = 0.85
	decideframe2.BorderSizePixel = 0
	decideframe2.AnchorPoint = Vector2.new(0, 1)
	decideframe2.Size = UDim2.new(1, 0, 0, 1)

	local function updateseparator()
		decideframe2.Position = UDim2.new(0, 0, 1, -userfooter.AbsoluteSize.Y)
	end

	updateseparator()
	trackConnection(
		userfooter:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			debounceResize("footer_separator", updateseparator, 0.05)
		end),
		"footer.propertychanged"
	)

	decideframe2.Position = UDim2.new(0, 0, 1, -userfooter.Size.Y.Offset)

	function guifunc:DestroyGui()
		disconnectAll()
		for key, timer in pairs(resizeDebounceTable) do
			if timer then
				task.cancel(timer)
			end
		end
		resizeDebounceTable = {}
		for name in pairs(heartbeatCallbacks) do
			unregisterHeartbeat(name)
		end

		if sv.coregui:FindFirstChild("Chloeex") then
			chloeex:Destroy()
		end

		if sv.coregui:FindFirstChild("ToggleUIButton") then
			sv.coregui.ToggleUIButton:Destroy()
		end

		-- overlays and notifications belong to this instance too, so they go with it
		for _, child in ipairs(sv.coregui:GetChildren()) do
			if child.Name == "OverlayGui" or child.Name == "NotifyGui" or child.Name == "FloatingGui" then
				pcall(function()
					child:Destroy()
				end)
			end
		end

		Chloex.Unloaded = true
		Chloex.LockRegistry = {}
		Chloex:DisconnectBackend()

		getgenv().ChloeX_Instance = nil
		getgenv().ChloeX_Running = nil
		getgenv().ChloeX_ReopenPrompt = nil
	end

	min.Activated:Connect(function()
		dropshadowholder.Visible = false
	end)

	close.Activated:Connect(function()
		local overlay = instance.frame(dropshadowholder)
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 0.3
		overlay.ZIndex = 50

		local dialog = instance.frame(overlay)
		dialog.Size = UDim2.new(0, 300, 0, 150)
		dialog.Position = UDim2.new(0.5, -150, 0.5, -75)
		dialog.BackgroundColor3 = theme.Card
		dialog.BackgroundTransparency = 0
		dialog.BorderSizePixel = 0
		dialog.ZIndex = 51
		local uicorner3 = instance.uicorner(dialog)
		uicorner3.CornerRadius = UDim.new(0, 8)
		local dialogstroke = instance.uistroke(dialog)
		dialogstroke.Color = theme.Stroke
		dialogstroke.Thickness = 1

		local title = instance.textlabel(dialog)
		title.Name = "Title"
		title.Size = UDim2.new(1, 0, 0, 40)
		title.Position = UDim2.new(0, 0, 0, 4)
		title.BackgroundTransparency = 1
		title.FontFace = FONT_BOLD
		title.Text = "Vecta Window"
		title.TextSize = ts(22)
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.ZIndex = 52

		local message = instance.textlabel(dialog)
		message.Name = "Message"
		message.Size = UDim2.new(1, -20, 0, 60)
		message.Position = UDim2.new(0, 10, 0, 30)
		message.BackgroundTransparency = 1
		message.FontFace = FONT_MEDIUM
		message.Text = "Do you want to close this window?\nYou will not be able to open it again"
		message.TextSize = ts(14)
		message.TextColor3 = theme.SubText
		message.TextWrapped = true
		message.ZIndex = 52

		local yes = instance.textbutton(dialog)
		yes.Name = "Yes"
		yes.Size = UDim2.new(0.45, -10, 0, 35)
		yes.Position = UDim2.new(0.05, 0, 1, -55)
		yes.BackgroundColor3 = theme.Element
		yes.BackgroundTransparency = 0
		yes.AutoButtonColor = true
		yes.Text = "Yes"
		yes.FontFace = FONT_BOLD
		yes.TextSize = ts(15)
		yes.TextColor3 = Color3.fromRGB(255, 255, 255)
		yes.TextTransparency = 0.3
		yes.ZIndex = 52
		local yescorner = instance.uicorner(yes)
		yescorner.CornerRadius = UDim.new(0, 6)

		local cancel = instance.textbutton(dialog)
		cancel.Name = "Cancel"
		cancel.Size = UDim2.new(0.45, -10, 0, 35)
		cancel.Position = UDim2.new(0.5, 10, 1, -55)
		cancel.BackgroundColor3 = theme.Element
		cancel.BackgroundTransparency = 0
		cancel.AutoButtonColor = true
		cancel.Text = "Cancel"
		cancel.FontFace = FONT_BOLD
		cancel.TextSize = ts(15)
		cancel.TextColor3 = Color3.fromRGB(255, 255, 255)
		cancel.TextTransparency = 0.3
		cancel.ZIndex = 52
		local cancelcorner = instance.uicorner(cancel)
		cancelcorner.CornerRadius = UDim.new(0, 6)

		yes.MouseButton1Click:Connect(function()
			guifunc:DestroyGui()
		end)

		cancel.MouseButton1Click:Connect(function()
			overlay:Destroy()
		end)
	end)


	-- Window show/hide key. Set it with WindowKeybind (alias ToggleKey) in :Window, or at
	-- runtime with Window:SetWindowKeybind(Enum.KeyCode.RightShift). "None" or
	-- Enum.KeyCode.Unknown turns the shortcut off. The default stays F3.
	local togglekey = Enum.KeyCode.F3
	do
		local configured = guiconfig.WindowKeybind
		if configured == nil then
			configured = guiconfig.ToggleKey
		end
		if configured ~= nil then
			togglekey = Chloex:ParseKeyCode(configured)
		end
	end
	trackConnection(
		sv.uis.InputBegan:Connect(function(input, gpe)
			if gpe or togglekey == Enum.KeyCode.Unknown then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= togglekey then
				return
			end
			-- the key that is being (re)bound on a keybind row must not also hide the window
			local kb = guifunc.Keybinds
			if kb and (kb.cancel or os.clock() < kb.blockuntil) then
				return
			end
			if dropshadowholder then
				dropshadowholder.Visible = not dropshadowholder.Visible
			end
		end),
		"window.togglekey"
	)

	function guifunc:SetWindowKeybind(value)
		if type(self) ~= "table" then
			value = self
		end
		togglekey = Chloex:ParseKeyCode(value)
		return togglekey
	end

	function guifunc:GetWindowKeybind()
		return togglekey
	end


	-- Resize the floating logo after the window exists. Works as
	-- Window:SetLogoSize(64) and Window.SetLogoSize(64); returns the applied size.
	function guifunc:SetLogoSize(size)
		if type(self) ~= "table" then
			size = self
		end
		size = tonumber(size)
		if not size then
			return guiconfig.ImageSize
		end
		size = math.clamp(math.floor(size), 16, 256)
		guiconfig.ImageSize = size
		local logo = guifunc.LogoButton
		if logo and logo.Parent then
			logo.Size = UDim2.new(0, size, 0, size)
		end
		return size
	end

	function guifunc:ToggleUI()
		local screengui = instance.screengui(sv.coregui)
		screengui.Name = "ToggleUIButton"
		screengui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		local mainbutton = instance.imagelabel(screengui)
		mainbutton.Size = UDim2.new(0, guiconfig.ImageSize, 0, guiconfig.ImageSize)
		mainbutton.Position = UDim2.new(0, 20, 0, 100)
		mainbutton.BackgroundTransparency = 1
		guifunc.LogoButton = mainbutton
		local toggleIcon = userPassedToggle or (not bgAsset and userPassedImage) or "100997912316573"
		local toggleStr = tostring(toggleIcon):gsub("^%s+", ""):gsub("%s+$", "")
		if toggleStr:match("^%d+$") then
			toggleStr = "rbxassetid://" .. toggleStr
		elseif not toggleStr:match("^%a+://") then
			toggleStr = "rbxassetid://" .. toggleStr:gsub("^rbxassetid://", "")
		end
		if toggleStr:match("^https?://") then
			local url = toggleStr
			mainbutton.Image = urlimage(url, true) or "rbxassetid://100997912316573"
			task.spawn(function()
				if not mainbutton.Image:match("^rbxassetid://100997912316573") then
					return
				end
				local asset = urlimage(url)
				if asset and mainbutton.Parent then
					elevate()
					mainbutton.Image = asset
				end
			end)
		else
			mainbutton.Image = toggleStr
		end
		mainbutton.ScaleType = Enum.ScaleType.Crop

		local uicorner = instance.uicorner(mainbutton)
		uicorner.CornerRadius = UDim.new(0, 6)

		-- If the logo asset never loads (private / moderated / blocked id, or the
		-- download failed) the button used to stay completely invisible. Show a
		-- visible placeholder icon instead, and drop it again if the image arrives.
		local logofallback = instance.imagelabel(mainbutton)
		logofallback.Name = "LogoFallback"
		logofallback.AnchorPoint = Vector2.new(0.5, 0.5)
		logofallback.Position = UDim2.new(0.5, 0, 0.5, 0)
		logofallback.Size = UDim2.new(0.5, 0, 0.5, 0)
		logofallback.BackgroundTransparency = 1
		logofallback.ImageColor3 = theme.Text
		logofallback.Visible = false
		applyicon(logofallback, "menu", 48)
		local function logoplaceholder(on)
			logofallback.Visible = on
			mainbutton.BackgroundTransparency = on and 0 or 1
			mainbutton.BackgroundColor3 = theme.Element
		end
		task.spawn(function()
			local t0 = os.clock()
			while mainbutton.Parent and not mainbutton.IsLoaded and os.clock() - t0 < 8 do
				task.wait(0.25)
			end
			if mainbutton.Parent and not mainbutton.IsLoaded then
				logoplaceholder(true)
			end
		end)
		mainbutton:GetPropertyChangedSignal("IsLoaded"):Connect(function()
			if mainbutton.IsLoaded then
				logoplaceholder(false)
			end
		end)

		local button = instance.textbutton(mainbutton)
		button.Size = UDim2.new(1, 0, 1, 0)
		button.BackgroundTransparency = 1
		button.Text = ""

		button.MouseButton1Click:Connect(function()
			if dropshadowholder then
				dropshadowholder.Visible = not dropshadowholder.Visible
			end
		end)

		local dragging = false
		local dragstart, startpos

		local function update(input)
			local delta = input.Position - dragstart
			mainbutton.Position =
				UDim2.new(startpos.X.Scale, startpos.X.Offset + delta.X, startpos.Y.Scale, startpos.Y.Offset + delta.Y)
		end

		button.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				if not logodrag.enabled then
					return
				end
				dragging = true
				dragstart = input.Position
				startpos = mainbutton.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		trackConnection(
			sv.uis.InputChanged:Connect(function(input)
				if
					dragging
					and (
						input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch
					)
				then
					update(input)
				end
			end),
			"togglebutton.drag"
		)
	end

	guifunc:ToggleUI()

	local tabs = {}
	function tabs:SetLogoSize(size)
		if type(self) ~= "table" or self ~= tabs then
			size = self
		end
		return guifunc:SetLogoSize(size)
	end

	function tabs:SetWindowKeybind(value)
		if type(self) ~= "table" or self ~= tabs then
			value = self
		end
		return guifunc:SetWindowKeybind(value)
	end

	function tabs:GetWindowKeybind()
		return guifunc:GetWindowKeybind()
	end
	function tabs:SetHeaderChips(list)
		list = type(list) == "table" and list or {}
		for i, item in ipairs(list) do
			local row = headerchips.row(i)
			row.frame.Visible = true
			local icon = tostring(item.Icon or "")
			if row.icon ~= icon then
				row.icon = icon
				row.img.Visible = icon ~= ""
				applyicon(row.img, icon, 48)
			end
			local tint = item.IconColor or Color3.new(1, 1, 1)
			if row.img.ImageColor3 ~= tint then row.img.ImageColor3 = tint end
			local text = tostring(item.Text or "")
			if row.label.Text ~= text then row.label.Text = text end
			local color = item.TextColor or theme.Text
			if row.label.TextColor3 ~= color then row.label.TextColor3 = color end
		end
		for i = #list + 1, #headerchips.rows do
			headerchips.rows[i].frame.Visible = false
		end
	end
	local searchItems = {}
	local counttab = 0
	local countdropdown = 0
	local templates = {}

	do
		local t = instance.frame(nil)
		t.Name = "Toggle"
		t.BorderSizePixel = 0
		t.Size = UDim2.new(1, 0, 0, 46)
		roundbg(t, 4, theme.Row)

		local ttitle = instance.textlabel(t)
		ttitle.Name = "ToggleTitle"
		ttitle.FontFace = FONT_BOLD
		ttitle.TextSize = ts(13)
		ttitle.TextColor3 = theme.Text
		ttitle.TextXAlignment = Enum.TextXAlignment.Left
		ttitle.TextYAlignment = Enum.TextYAlignment.Top
		ttitle.TextTruncate = Enum.TextTruncate.AtEnd
		ttitle.BackgroundTransparency = 1
		ttitle.Position = UDim2.new(0, 10, 0, 15)
		ttitle.Size = UDim2.new(1, -72, 0, 14)

		local tbutton = instance.textbutton(t)
		tbutton.Name = "ToggleButton"
		tbutton.FontFace = FONT_MEDIUM
		tbutton.Text = ""
		tbutton.BackgroundTransparency = 1
		tbutton.Size = UDim2.new(1, 0, 1, 0)

		local tfeature = instance.frame(t)
		tfeature.Name = "FeatureFrame"
		tfeature.AnchorPoint = Vector2.new(1, 0.5)
		tfeature.BackgroundColor3 = theme.Field
		tfeature.BackgroundTransparency = 0
		tfeature.BorderSizePixel = 0
		tfeature.Position = UDim2.new(1, -15, 0.5, 0)
		tfeature.Size = UDim2.new(0, 38, 0, 19)
		instance.uicorner(tfeature)

		local tstroke = instance.uistroke(tfeature)
		tstroke.Color = Color3.fromRGB(255, 255, 255)
		tstroke.Thickness = 2
		tstroke.Transparency = 0.9

		local tcircle = instance.frame(tfeature)
		tcircle.Name = "ToggleCircle"
		tcircle.BackgroundColor3 = theme.Text
		tcircle.BorderSizePixel = 0
		tcircle.Position = UDim2.new(0, 2, 0, 2)
		tcircle.Size = UDim2.new(0, 15, 0, 15)
		instance.uicorner(tcircle).CornerRadius = UDim.new(0, 15)

		templates.Toggle = t
	end

	do
		local s = instance.frame(nil)
		s.Name = "Slider"
		s.BorderSizePixel = 0
		s.Size = UDim2.new(1, 0, 0, 58)
		roundbg(s, 4, theme.Row)

		local stitle = instance.textlabel(s)
		stitle.Name = "SliderTitle"
		stitle.FontFace = FONT_BOLD
		stitle.TextColor3 = theme.Text
		stitle.TextSize = ts(13)
		stitle.TextXAlignment = Enum.TextXAlignment.Left
		stitle.TextYAlignment = Enum.TextYAlignment.Center
		stitle.TextTruncate = Enum.TextTruncate.AtEnd
		stitle.BackgroundTransparency = 1
		stitle.Position = UDim2.new(0, 10, 0, 7)
		stitle.Size = UDim2.new(1, -62, 0, 20)

		local sholder = instance.frame(s)
		sholder.Name = "SliderInputHolder"
		sholder.AnchorPoint = Vector2.new(1, 0)
		sholder.Position = UDim2.new(1, -10, 0, 6)
		sholder.Size = UDim2.new(0, 34, 0, 23)
		roundbg(sholder, 4, theme.Field)

		local sinput = instance.textbox(sholder)
		sinput.Name = "SliderInput"
		sinput.FontFace = FONT_BOLD
		sinput.Text = ""
		sinput.TextColor3 = Color3.fromRGB(255, 255, 255)
		sinput.TextSize = ts(12)
		sinput.TextScaled = true
		sinput.TextXAlignment = Enum.TextXAlignment.Center
		sinput.TextYAlignment = Enum.TextYAlignment.Center
		sinput.BackgroundTransparency = 1
		sinput.ClearTextOnFocus = false
		sinput.Size = UDim2.new(1, -6, 1, 0)
		sinput.Position = UDim2.new(0, 3, 0, 0)

		local sinputconstraint = instance.uitextsizeconstraint(sinput)
		sinputconstraint.MinTextSize = ts(10)
		sinputconstraint.MaxTextSize = ts(12)

		local sbar = instance.frame(s)
		sbar.Name = "SliderBar"
		sbar.BackgroundColor3 = theme.Bar
		sbar.BackgroundTransparency = 0
		sbar.Position = UDim2.new(0, 10, 0, 39)
		sbar.Size = UDim2.new(1, -20, 0, 5)
		sbar.Active = true
		instance.uicorner(sbar).CornerRadius = UDim.new(1, 0)

		local sfill = instance.frame(sbar)
		sfill.Name = "SliderFill"
		sfill.BackgroundColor3 = guiconfig.Color
		sfill.BorderSizePixel = 0
		sfill.Size = UDim2.new(0, 0, 1, 0)
		instance.uicorner(sfill).CornerRadius = UDim.new(1, 0)

		local scircle = instance.frame(sbar)
		scircle.Name = "SliderCircle"
		scircle.AnchorPoint = Vector2.new(0.5, 0.5)
		scircle.BackgroundColor3 = guiconfig.Color
		scircle.Position = UDim2.new(0, 0, 0.5, 0)
		scircle.Size = UDim2.new(0, 12, 0, 12)
		scircle.Active = true
		scircle.ZIndex = 4
		instance.uicorner(scircle).CornerRadius = UDim.new(1, 0)

		local scirclestroke = instance.uistroke(scircle)
		scirclestroke.Color = Color3.fromRGB(255, 255, 255)
		scirclestroke.Transparency = 0.45
		scirclestroke.Thickness = 1

		local sbubble = instance.frame(sbar)
		sbubble.Name = "ValueBubble"
		sbubble.AnchorPoint = Vector2.new(0.5, 1)
		sbubble.BackgroundColor3 = theme.Element
		sbubble.BackgroundTransparency = 0
		sbubble.Position = UDim2.new(0, 0, 0, -10)
		sbubble.Size = UDim2.new(0, 48, 0, 22)
		sbubble.Visible = false
		sbubble.ZIndex = 20
		instance.uicorner(sbubble).CornerRadius = UDim.new(0, 5)

		local sbubbletext = instance.textlabel(sbubble)
		sbubbletext.Name = "BubbleText"
		sbubbletext.BackgroundTransparency = 1
		sbubbletext.Size = UDim2.new(1, -6, 1, 0)
		sbubbletext.Position = UDim2.new(0, 3, 0, 0)
		sbubbletext.FontFace = FONT_BOLD
		sbubbletext.TextColor3 = Color3.fromRGB(255, 255, 255)
		sbubbletext.TextSize = ts(11)
		sbubbletext.TextScaled = true
		sbubbletext.TextXAlignment = Enum.TextXAlignment.Center
		sbubbletext.TextYAlignment = Enum.TextYAlignment.Center
		sbubbletext.ZIndex = 21

		local sbubbleconstraint = instance.uitextsizeconstraint(sbubbletext)
		sbubbleconstraint.MinTextSize = ts(9)
		sbubbleconstraint.MaxTextSize = ts(11)

		templates.Slider = s
	end

	do
		local o = instance.frame(nil)
		o.Name = "Option"
		o.Size = UDim2.new(1, 0, 0, 30)
		roundbg(o, 3, theme.Option).ImageTransparency = 1

		local obutton = instance.textbutton(o)
		obutton.Name = "OptionButton"
		obutton.BackgroundTransparency = 1
		obutton.Size = UDim2.new(1, 0, 1, 0)
		obutton.Text = ""

		local otext = instance.textlabel(o)
		otext.Name = "OptionText"
		otext.FontFace = FONT_BOLD
		otext.TextSize = ts(12)
		otext.TextColor3 = theme.Text
		otext.BackgroundTransparency = 1
		otext.TextXAlignment = Enum.TextXAlignment.Left
		otext.TextTruncate = Enum.TextTruncate.AtEnd

		local ochoose = instance.frame(o)
		ochoose.Name = "ChooseFrame"
		ochoose.AnchorPoint = Vector2.new(0, 0.5)
		ochoose.BackgroundColor3 = guiconfig.Color
		ochoose.Position = UDim2.new(0, 2, 0.5, 0)
		ochoose.Size = UDim2.new(0, 0, 0, 0)

		local ochoosestroke = instance.uistroke(ochoose)
		ochoosestroke.Color = guiconfig.Color
		ochoosestroke.Thickness = 1.6
		ochoosestroke.Transparency = 1
		instance.uicorner(ochoose)

		templates.DropdownOption = o
	end

	makedraggable(top, dropshadowholder)

	-- Window edge glow. While the mouse button / a finger is held on the window, the
	-- window border lights up on the side facing the touch point and follows it
	-- every frame. Nothing moves, scales or tilts. Hovering without pressing does
	-- nothing. Window options:
	--   EdgeGlow         = false  turns the effect off (default on)
	--   EdgeGlowStrength = 0..1   how bright the border gets, default 0.85
	--   EdgeGlowColor    = Color3 glow color, default the window Color
	--   EdgeGlowWidth    = 1..3   border thickness in pixels, default 1.5
	--   EdgeGlowDelay    = seconds the window must be held before the border shows, default 3
	if guiconfig.EdgeGlow ~= false then
		local glowdelay = math.max(0, tonumber(guiconfig.EdgeGlowDelay) or 3)
		local glowstrength = math.clamp(tonumber(guiconfig.EdgeGlowStrength) or 0.85, 0, 1)
		local glowwidth = math.clamp(tonumber(guiconfig.EdgeGlowWidth) or 1.5, 1, 3)
		local glowcolor = typeof(guiconfig.EdgeGlowColor) == "Color3" and guiconfig.EdgeGlowColor
			or guiconfig.Color
			or Color3.new(1, 1, 1)
		local runservice = game:GetService("RunService")
		local maincorner = main:FindFirstChildOfClass("UICorner")

		local glow = instance.frame(main)
		glow.Name = "EdgeGlow"
		glow.Active = false
		pcall(function()
			glow.Interactable = false
		end)
		glow.BackgroundTransparency = 1
		glow.BorderSizePixel = 0
		glow.Size = UDim2.new(1, 0, 1, 0)
		glow.ZIndex = 10
		glow.Visible = false
		local glowcorner = instance.uicorner(glow)
		if maincorner then
			glowcorner.CornerRadius = maincorner.CornerRadius
		end
		local glowstroke = instance.uistroke(glow)
		glowstroke.Color = glowcolor
		glowstroke.Thickness = glowwidth
		glowstroke.Transparency = 0
		local glowgradient = instance.uigradient(glowstroke)
		glowgradient.Transparency = NumberSequence.new(1)

		local pressing = false
		local pressat = 0
		local active = nil
		local pointer = Vector2.new(0, 0)
		-- tx, ty: last touched point (-1..1 from the window centre), ti: 1 while pressed
		local tx, ty, ti = 0, 0, 0
		local cx, cy, ci = 0, 0, 0
		local settled = true

		local function isclick(input)
			return input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
		end

		local function rect()
			local size = dropshadowholder.AbsoluteSize
			local center = dropshadowholder.AbsolutePosition + size / 2
			return center, size / 2
		end

		trackConnection(
			sv.uis.InputBegan:Connect(function(input)
				if pressing or not isclick(input) or not dropshadowholder.Visible then
					return
				end
				local center, half = rect()
				if half.X < 1 or half.Y < 1 then
					return
				end
				local pos = input.Position
				if math.abs(pos.X - center.X) > half.X or math.abs(pos.Y - center.Y) > half.Y then
					return
				end
				pressing = true
				active = input
				pressat = os.clock()
				pointer = Vector2.new(pos.X, pos.Y)
			end),
			"edgeglow.InputBegan"
		)
		trackConnection(
			sv.uis.InputChanged:Connect(function(input)
				if not pressing then
					return
				end
				if active.UserInputType == Enum.UserInputType.Touch then
					if input == active then
						pointer = Vector2.new(input.Position.X, input.Position.Y)
					end
				elseif input.UserInputType == Enum.UserInputType.MouseMovement then
					pointer = Vector2.new(input.Position.X, input.Position.Y)
				end
			end),
			"edgeglow.InputChanged"
		)
		trackConnection(
			sv.uis.InputEnded:Connect(function(input)
				if not pressing then
					return
				end
				if
					input == active
					or (
						active.UserInputType == Enum.UserInputType.MouseButton1
						and input.UserInputType == Enum.UserInputType.MouseButton1
					)
				then
					pressing = false
					active = nil
				end
			end),
			"edgeglow.InputEnded"
		)

		trackConnection(
			runservice.RenderStepped:Connect(function(dt)
				if not dropshadowholder.Visible then
					return
				end

				if pressing then
					local center, half = rect()
					tx = math.clamp((pointer.X - center.X) / math.max(1, half.X), -1, 1)
					ty = math.clamp((pointer.Y - center.Y) / math.max(1, half.Y), -1, 1)
					-- the border only starts to show once the press has lasted EdgeGlowDelay seconds
					ti = (os.clock() - pressat >= glowdelay) and 1 or 0
				else
					-- let go: fade out where the touch was
					ti = 0
				end

				if settled and ti == 0 then
					-- keep the direction ready, so the border fades in right at the touch point
					cx, cy = tx, ty
					return
				end

				-- direction follows the touch softly, brightness fades in ~0.4s / out ~0.5s
				local follow = 1 - math.exp(-dt * 14)
				cx = cx + (tx - cx) * follow
				cy = cy + (ty - cy) * follow
				local fade = 1 - math.exp(-dt * (ti > ci and 7.5 or 6))
				ci = ci + (ti - ci) * fade

				if ti == 0 and ci < 0.01 then
					ci = 0
					settled = true
					glow.Visible = false
					return
				end
				settled = false

				-- t = 1 of the gradient points toward the touch; the closer the touch
				-- is to an edge, the brighter that edge gets. Smoothstep gives an ease in/out.
				local mag = math.min(1, math.sqrt(cx * cx + cy * cy))
				local eased = ci * ci * (3 - 2 * ci)
				local level = glowstrength * eased * (0.3 + 0.7 * mag)
				glow.Visible = true
				glowgradient.Rotation = math.deg(math.atan2(cy, cx))
				glowgradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.55, 1),
					NumberSequenceKeypoint.new(0.85, 1 - 0.55 * level),
					NumberSequenceKeypoint.new(1, 1 - level),
				})
			end),
			"edgeglow.RenderStepped"
		)
	end

	local moreblur = instance.frame(layers)
	moreblur.Name = "MoreBlur"
	moreblur.AnchorPoint = Vector2.new(1, 1)
	moreblur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	moreblur.BackgroundTransparency = 1
	moreblur.BorderColor3 = Color3.fromRGB(0, 0, 0)
	moreblur.BorderSizePixel = 0
	moreblur.ClipsDescendants = true
	moreblur.Position = UDim2.new(1, 8, 1, 8)
	moreblur.Size = UDim2.new(1, 154, 1, 54)
	moreblur.Visible = false

	local dropshadowholder1 = instance.frame(moreblur)
	dropshadowholder1.Name = "DropShadowHolder"
	dropshadowholder1.BackgroundTransparency = 1
	dropshadowholder1.BorderSizePixel = 0
	dropshadowholder1.Size = UDim2.new(1, 0, 1, 0)
	dropshadowholder1.ZIndex = 0

	local dropshadow1 = instance.imagelabel(dropshadowholder1)
	dropshadow1.Name = "DropShadow"
	dropshadow1.Image = "rbxassetid://6015897843"
	dropshadow1.ImageColor3 = Color3.fromRGB(0, 0, 0)
	dropshadow1.ImageTransparency = 1
	dropshadow1.ScaleType = Enum.ScaleType.Slice
	dropshadow1.SliceCenter = Rect.new(49, 49, 450, 450)
	dropshadow1.AnchorPoint = Vector2.new(0.5, 0.5)
	dropshadow1.BackgroundTransparency = 1
	dropshadow1.BorderSizePixel = 0
	dropshadow1.Position = UDim2.new(0.5, 0, 0.5, 0)
	dropshadow1.Size = UDim2.new(1, 35, 1, 35)
	dropshadow1.ZIndex = 0

	local uicorner28 = instance.uicorner(moreblur)

	local connectbutton = instance.textbutton(moreblur)
	connectbutton.Name = "ConnectButton"
	connectbutton.FontFace = FONT_MEDIUM
	connectbutton.Text = ""
	connectbutton.TextColor3 = Color3.fromRGB(0, 0, 0)
	connectbutton.TextSize = ts(14)
	connectbutton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	connectbutton.BackgroundTransparency = 1
	connectbutton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	connectbutton.BorderSizePixel = 0
	connectbutton.Size = UDim2.new(1, 0, 1, 0)

	local dropdownselect = instance.frame(moreblur)
	dropdownselect.Name = "DropdownSelect"
	dropdownselect.AnchorPoint = Vector2.new(1, 0.5)
	dropdownselect.BackgroundColor3 = theme.Element
	dropdownselect.BackgroundTransparency = 0
	dropdownselect.BorderColor3 = Color3.fromRGB(0, 0, 0)
	dropdownselect.BorderSizePixel = 0
	dropdownselect.LayoutOrder = 1
	dropdownselect.Position = UDim2.new(1, 212, 0.5, 0)
	dropdownselect.Size = UDim2.new(0, 200, 1, -16)
	dropdownselect.ClipsDescendants = true

	local uicorner36 = instance.uicorner(dropdownselect)
	uicorner36.CornerRadius = UDim.new(0, 3)

	local uistroke14 = instance.uistroke(dropdownselect)
	uistroke14.Color = theme.Stroke
	uistroke14.Thickness = 2.5
	uistroke14.Transparency = 0.8

	local dropdownselectreal = instance.frame(dropdownselect)
	dropdownselectreal.Name = "DropdownSelectReal"
	dropdownselectreal.AnchorPoint = Vector2.new(0.5, 0.5)
	dropdownselectreal.BackgroundColor3 = theme.Card
	dropdownselectreal.BackgroundTransparency = 0
	dropdownselectreal.BorderColor3 = Color3.fromRGB(0, 0, 0)
	dropdownselectreal.BorderSizePixel = 0
	dropdownselectreal.LayoutOrder = 1
	dropdownselectreal.Position = UDim2.new(0.5, 0, 0.5, 0)
	dropdownselectreal.Size = UDim2.new(1, 1, 1, 1)

	local dropdownfolder = instance.folder(dropdownselectreal)
	dropdownfolder.Name = "DropdownFolder"

	local droppagelayout = instance.uipagelayout(dropdownfolder)
	droppagelayout.Name = "DropPageLayout"
	droppagelayout.EasingDirection = Enum.EasingDirection.InOut
	droppagelayout.EasingStyle = Enum.EasingStyle.Quad
	droppagelayout.TweenTime = 0.01
	droppagelayout.SortOrder = Enum.SortOrder.LayoutOrder
	droppagelayout.FillDirection = Enum.FillDirection.Vertical
	droppagelayout.Archivable = false

	-- popuptoken: a close that is still sliding out must not hide a list that
	-- was opened again in the meantime. Defined after droppagelayout: a function
	-- written above a local sees a nil global instead.
	local popuptoken = 0

	local function opendropdownpopup(index)
		popuptoken = popuptoken + 1
		moreblur.Visible = true
		droppagelayout:JumpToIndex(index)
		sv.ts:Create(moreblur, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		sv.ts:Create(dropdownselect, TweenInfo.new(0.3), { Position = UDim2.new(1, -11, 0.5, 0) }):Play()
	end

	local function closedropdownpopup()
		if not moreblur.Visible then
			return
		end
		popuptoken = popuptoken + 1
		local token = popuptoken
		sv.ts:Create(moreblur, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		sv.ts:Create(dropdownselect, TweenInfo.new(0.3), { Position = UDim2.new(1, 212, 0.5, 0) }):Play()
		task.delay(0.3, function()
			if popuptoken == token then
				moreblur.Visible = false
			end
		end)
	end

	connectbutton.Activated:Connect(closedropdownpopup)

	local searchopened = {}

	local function runsearch()
		local query = string.lower(searchbox.Text or "")
		local current = layerspagelayout.CurrentPage
		local seen = {}

		if query == "" then
			for section, closefn in pairs(searchopened) do
				pcall(closefn)
			end
			searchopened = {}
		end

		for _, data in ipairs(searchItems) do
			if query == "" or data.Page == current then
				local match = query == ""
					or string.find(string.lower(data.Name), query, 1, true) ~= nil
					or string.find(string.lower(data.Path), query, 1, true) ~= nil
				if data.Object then
					data.Object.Visible = match
				end
				if data.Section then
					local state = seen[data.Section]
					if not state then
						state = { any = false, open = data.OpenSection, close = data.CloseSection, isopen = data.IsOpen }
						seen[data.Section] = state
					end
					if match then
						state.any = true
					end
				end
			end
		end

		for section, state in pairs(seen) do
			section.Visible = query == "" or state.any
			if query ~= "" and state.any and state.open then
				local wasopen = state.isopen and state.isopen()
				if not wasopen then
					searchopened[section] = state.close
					pcall(state.open)
				end
			end
		end
	end

	searchbox:GetPropertyChangedSignal("Text"):Connect(function()
		debounceResize("search", runsearch, 0.05)
	end)

	local lockextra = 22
	local usedkeys = {}

	-- Config key of an element: Flag when given, else Title. Two elements with
	-- the same key share one saved value, so say so.
	local function keyfor(prefix, elementconfig)
		local key = prefix .. tostring(elementconfig.Flag or elementconfig.Title)
		if usedkeys[key] then
			warn(string.format("[VECTA] Duplicate config key %q: these elements share one saved value. Give one of them a unique Flag.", key))
		end
		usedkeys[key] = true
		return key
	end

	local function isdonatorelement(elementconfig)
		return elementconfig.Donator == true or elementconfig.Locked == true or elementconfig.Locked2 == true or elementconfig.DonatorOnly == true
	end

	-- Locked2 (alias DonatorOnly) is a stricter tier: a trial key unlocks the
	-- ordinary Locked/Donator elements but never these; only a real donator does.
	local function isdonatoronly(elementconfig)
		return elementconfig.Locked2 == true or elementconfig.DonatorOnly == true
	end

	local CONTENT_FONT = FONT_MEDIUM
	local CONTENT_SIZE = 12

	-- Description text of an element: Content, Desc or Description; nil when empty.
	local function contenttext(elementconfig)
		local text = elementconfig.Content or elementconfig.Desc or elementconfig.Description
		if text == nil then
			return nil
		end
		text = tostring(text)
		if text:gsub("%s+", "") == "" then
			return nil
		end
		return text
	end

	-- Grey description line under an element title. measure() wraps the text to
	-- the row's current width and returns its height; the element turns that
	-- into its row height (see watchwidth for window resizes). rightinset may be
	-- a function when the control beside the text has a width of its own.
	-- Rich-text tags are stripped before measuring: they take no room on screen.
	local function attachcontent(row, text, x, y, rightinset)
		local label = instance.textlabel(row)
		label.Name = "Content"
		label.BackgroundTransparency = 1
		label.FontFace = CONTENT_FONT
		label.RichText = true
		label.Text = text
		label.TextColor3 = theme.SubText
		label.TextSize = math.max(7, ts(CONTENT_SIZE) - 1)
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.Position = UDim2.new(0, x, 0, y)
		local function inset()
			if type(rightinset) == "function" then
				local ok, value = pcall(rightinset)
				return ok and tonumber(value) or 10
			end
			return rightinset
		end
		label.Size = UDim2.new(1, -(x + inset()), 0, CONTENT_SIZE)
		local plain = tostring(text):gsub("<[^>]+>", "")
		local function measure()
			local width = row.AbsoluteSize.X
			if width <= 1 then
				width = layers.AbsoluteSize.X
			end
			if width <= 1 then
				width = 440
			end
			local right = inset()
			local height = textheight(plain, CONTENT_SIZE, CONTENT_FONT, width - x - right, 400)
			label.Size = UDim2.new(1, -(x + right), 0, height)
			return height
		end
		return label, measure
	end

	-- Re-run a layout when the row gets wider or narrower (window resize, first
	-- real layout pass). Height changes are ignored, the layout causes those.
	local function watchwidth(row, relayout)
		local lastwidth = -1
		local queued = false
		row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local width = math.floor(row.AbsoluteSize.X + 0.5)
			if width == lastwidth or width <= 1 or queued then
				return
			end
			lastwidth = width
			queued = true
			task.defer(function()
				queued = false
				relayout()
			end)
		end)
	end

	-- Donator lock of one element. Lock() and Unlock() can run any number of
	-- times, because the tier can change mid-session (key redeemed, key expired,
	-- backend verdict). lockopts.OnLock(silent) drops the element back to its
	-- non-donator value (silent = during the build, the hub has not seen a value
	-- yet, so no callback); lockopts.OnUnlock re-applies the saved value. The
	-- saved value itself stays in the config while locked.
	local function makelock(container, controls, lockopts, startlocked)
		lockopts = lockopts or {}
		controls = controls or {}
		local donatoronly = lockopts.DonatorOnly == true
		local locked = false
		local baseheight, basetransparency = container.Size.Y.Offset, container.BackgroundTransparency
		local dimmed, overlay = {}, {}

		local function dim(obj)
			if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
				dimmed[#dimmed + 1] = { obj, "TextTransparency", obj.TextTransparency }
				obj.TextTransparency = obj.TextTransparency + (1 - obj.TextTransparency) * 0.6
			elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
				dimmed[#dimmed + 1] = { obj, "ImageTransparency", obj.ImageTransparency }
				obj.ImageTransparency = obj.ImageTransparency + (1 - obj.ImageTransparency) * 0.6
			elseif obj:IsA("UIStroke") then
				dimmed[#dimmed + 1] = { obj, "Transparency", obj.Transparency }
				obj.Transparency = obj.Transparency + (1 - obj.Transparency) * 0.6
			end
			if obj:IsA("GuiObject") then
				dimmed[#dimmed + 1] = { obj, "BackgroundTransparency", obj.BackgroundTransparency }
				obj.BackgroundTransparency = obj.BackgroundTransparency + (1 - obj.BackgroundTransparency) * 0.6
			end
		end

		local function buildoverlay()
			local lockborder = instance.frame(container)
			lockborder.Name = "LockBorder"
			lockborder.BackgroundTransparency = 1
			lockborder.AnchorPoint = Vector2.new(0.5, 0.5)
			lockborder.Position = UDim2.new(0.5, 0, 0.5, 0)
			lockborder.Size = UDim2.new(1, -2, 1, -2)
			lockborder.ZIndex = 1
			instance.uicorner(lockborder).CornerRadius = UDim.new(0, 3)

			local lockstroke = instance.uistroke(lockborder)
			lockstroke.Name = "LockStroke"
			lockstroke.Color = Color3.fromRGB(255, 255, 255)
			lockstroke.Thickness = 1
			lockstroke.Transparency = 0.85

			local notice = instance.textlabel(container)
			notice.Name = "LockNotice"
			notice.BackgroundTransparency = 1
			notice.FontFace = FONT_BOLD
			notice.RichText = true
			local tierlabel = donatoronly and "Donator only" or "Donator / Trial"
			notice.Text = '<font color="' .. hexcolor(theme.Text) .. '">' .. tierlabel .. '</font>'
			notice.TextColor3 = theme.SubText
			notice.TextSize = ts(11)
			notice.TextXAlignment = Enum.TextXAlignment.Left
			notice.TextTruncate = Enum.TextTruncate.AtEnd
			notice.Position = UDim2.new(0, 10, 0, baseheight - 4)
			notice.Size = UDim2.new(1, -96, 0, 16)
			notice.ZIndex = 12

			local pill = instance.frame(container)
			pill.Name = "LockPill"
			pill.AnchorPoint = Vector2.new(1, 0)
			pill.Position = UDim2.new(1, -10, 0, baseheight - 4)
			pill.Size = UDim2.new(0, 0, 0, 16)
			pill.AutomaticSize = Enum.AutomaticSize.X
			pill.BackgroundColor3 = theme.Field
			pill.BackgroundTransparency = 0
			pill.BorderSizePixel = 0
			pill.ZIndex = 12
			instance.uicorner(pill).CornerRadius = UDim.new(0, 4)

			local pillstroke = instance.uistroke(pill)
			pillstroke.Color = Color3.fromRGB(255, 255, 255)
			pillstroke.Thickness = 1
			pillstroke.Transparency = 0.85

			local pillpad = instance.uipadding(pill)
			pillpad.PaddingLeft = UDim.new(0, 7)
			pillpad.PaddingRight = UDim.new(0, 8)

			local pilllayout = instance.uilistlayout(pill)
			pilllayout.FillDirection = Enum.FillDirection.Horizontal
			pilllayout.VerticalAlignment = Enum.VerticalAlignment.Center
			pilllayout.Padding = UDim.new(0, 4)
			pilllayout.SortOrder = Enum.SortOrder.LayoutOrder

			local pillicon = instance.imagelabel(pill)
			pillicon.LayoutOrder = 1
			pillicon.BackgroundTransparency = 1
			pillicon.Size = UDim2.new(0, 10, 0, 10)
			pillicon.ImageColor3 = theme.Text
			pillicon.ZIndex = 13
			applyicon(pillicon, "lock", 48)

			local pilltext = instance.textlabel(pill)
			pilltext.LayoutOrder = 2
			pilltext.BackgroundTransparency = 1
			pilltext.AutomaticSize = Enum.AutomaticSize.X
			pilltext.Size = UDim2.new(0, 0, 1, 0)
			pilltext.FontFace = FONT_BOLD
			pilltext.Text = "LOCKED"
			pilltext.TextColor3 = theme.Text
			pilltext.TextSize = ts(10)
			pilltext.ZIndex = 13

			local shield = instance.textbutton(container)
			shield.Name = "LockShield"
			shield.BackgroundTransparency = 1
			shield.Text = ""
			shield.Size = UDim2.new(1, 0, 1, 0)
			shield.ZIndex = 15
			shield.Active = true
			shield.AutoButtonColor = false

			shield.Activated:Connect(function()
				elevate()
				sv.ts:Create(lockstroke, TweenInfo.new(0.12), { Transparency = 0.4 }):Play()
				task.delay(0.18, function()
					elevate()
					if lockstroke and lockstroke.Parent then
						sv.ts:Create(lockstroke, TweenInfo.new(0.3), { Transparency = 0.85 }):Play()
					end
				end)
			end)

			overlay = { shield, notice, pill, lockborder }
		end

		local lockfunc = {}

		function lockfunc:IsLocked()
			return locked
		end

		function lockfunc:Lock(silent)
			if locked or not container.Parent then
				return
			end
			locked = true
			elevate()
			if lockopts.OnLock then
				local ok, err = pcall(lockopts.OnLock, silent == true)
				if not ok then
					warn("[VECTA] lock error:", err)
				end
			end
			baseheight = lockopts.GetBaseHeight and lockopts.GetBaseHeight() or container.Size.Y.Offset
			basetransparency = container.BackgroundTransparency
			dimmed = {}
			for _, control in ipairs(controls) do
				if control then
					dim(control)
					for _, child in ipairs(control:GetDescendants()) do
						dim(child)
					end
				end
			end
			container.Size = UDim2.new(1, 0, 0, baseheight + lockextra)
			buildoverlay()
			if lockopts.Pin then
				pcall(lockopts.Pin, true)
			end
		end

		function lockfunc:Unlock()
			if not locked then
				return
			end
			locked = false
			elevate()
			for _, obj in ipairs(overlay) do
				pcall(function()
					obj:Destroy()
				end)
			end
			overlay = {}
			for _, d in ipairs(dimmed) do
				pcall(function()
					d[1][d[2]] = d[3]
				end)
			end
			dimmed = {}
			container.BackgroundTransparency = basetransparency
			if lockopts.GetBaseHeight then
				baseheight = lockopts.GetBaseHeight()
			end
			container.Size = UDim2.new(1, 0, 0, baseheight)
			if lockopts.Pin then
				pcall(lockopts.Pin, false)
			end
			if lockopts.OnUnlock then
				local ok, err = pcall(lockopts.OnUnlock)
				if not ok then
					warn("[VECTA] unlock error:", err)
				end
			end
		end

		-- The element's own height changed while locked (its description wrapped
		-- differently): move the notice/pill and keep the extra lock strip.
		function lockfunc:Relayout()
			if not locked then
				return
			end
			if lockopts.GetBaseHeight then
				baseheight = lockopts.GetBaseHeight()
			end
			container.Size = UDim2.new(1, 0, 0, baseheight + lockextra)
			local notice, pill = overlay[2], overlay[3]
			if notice and notice.Parent then
				notice.Position = UDim2.new(0, 10, 0, baseheight - 4)
			end
			if pill and pill.Parent then
				pill.Position = UDim2.new(1, -10, 0, baseheight - 4)
			end
			if lockopts.Pin then
				pcall(lockopts.Pin, true)
			end
		end

		lockfunc.Dead = function()
			return container.Parent == nil
		end

		lockfunc.DonatorOnly = donatoronly
		table.insert(Chloex.LockRegistry, lockfunc)
		if startlocked then
			lockfunc:Lock(true)
		end
		return lockfunc
	end

	-- ===== Floating Toggle / Floating Button =====
	-- Small pills that float over the game, outside the window:
	--   local t = Window:CreateFloatingToggle({ Title = "Auto Farm", Icon = "sprout", Default = false,
	--       Flag = "FloatFarm", Callback = function(on) end })
	--   local b = Window:CreateFloatingButton({ Title = "Rejoin", Icon = "refresh-cw", Callback = function() end })
	-- Each one has a lock icon: locked = cannot be dragged, unlocked = drag it anywhere.
	-- Item API (works with : or .):
	--   :SetLocked(bool) / :SetDraggable(bool) / :IsLocked()   lock or free the drag
	--   :SetVisible(bool) / :Show() / :Hide() / :IsVisible()   hide or show this one
	--   :Set(bool) :GetValue() :SetTitle(text) :SetIcon(name) :SetPosition(x, y) :Destroy()
	-- Window level: :SetFloatingVisible(bool) :ShowFloating() :HideFloating()
	--               :SetFloatingLocked(bool) :SetFloatingDraggable(bool)
	-- Position and lock state are remembered in Vecta/floating_positions.json.
	local floating = { list = {}, count = 0, visible = true, gui = nil }
	local FLOAT_POS_FILE = "Vecta/floating_positions.json"
	local floatpos = {}
	pcall(function()
		if type(isfile) == "function" and type(readfile) == "function" and isfile(FLOAT_POS_FILE) then
			local data = sv.http:JSONDecode(readfile(FLOAT_POS_FILE))
			if type(data) == "table" then
				floatpos = data
			end
		end
	end)

	local function savefloatpos()
		debounceResize("floating_pos_save", function()
			if type(writefile) ~= "function" then
				return
			end
			local encoded = safeencode(floatpos)
			if encoded then
				pcall(writefile, FLOAT_POS_FILE, encoded)
			end
		end, 0.5)
	end

	local function floatgui()
		if floating.gui and floating.gui.Parent then
			return floating.gui
		end
		elevate()
		local gui = instance.screengui(sv.coregui)
		gui.Name = "FloatingGui"
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 10
		floating.gui = gui
		return gui
	end

	local function paintlockicon(img, locked)
		local ok = applyicon(img, locked and "lock" or "lock-open", 48)
		if not ok and not locked then
			applyicon(img, "unlock", 48)
		end
		img.ImageColor3 = locked and theme.Gold or theme.SubText
	end

	local function buildfloating(kind, fcfg)
		elevate()
		fcfg = type(fcfg) == "table" and fcfg or {}
		local istoggle = kind == "toggle"
		local title = tostring(fcfg.Title or fcfg.Name or fcfg.Text or (istoggle and "Toggle" or "Button"))
		local callback = fcfg.Callback or function() end
		floating.count = floating.count + 1
		local index = floating.count
		local flag = tostring(fcfg.Flag or title)
		local posname = kind .. ":" .. flag
		local H = 34
		local item = { Kind = kind, Value = false }

		-- toggles join the config like every other toggle (saved / loaded / reset)
		local configkey = nil
		local hubdefault = fcfg.Default and true or false
		if istoggle then
			configkey = keyfor("Toggle_", { Flag = fcfg.Flag or ("Float " .. title) })
			item.DefaultValue = hubdefault
			local saved = config.data[configkey]
			if saved ~= nil then
				item.Value = saved == true
			elseif config.loaded then
				item.Value = false
			else
				item.Value = hubdefault
			end
		end

		local saved = type(floatpos[posname]) == "table" and floatpos[posname] or nil
		local locked = fcfg.Locked == true or fcfg.Draggable == false
		if saved and type(saved.locked) == "boolean" then
			locked = saved.locked
		end
		local shown = fcfg.Visible ~= false
		local connections = {}

		local root = instance.frame(floatgui())
		root.Name = istoggle and "FloatingToggle" or "FloatingButton"
		root.BackgroundColor3 = theme.Card
		root.BorderSizePixel = 0
		root.Size = UDim2.new(0, 120, 0, H)
		root.Visible = shown and floating.visible
		local startpos = UDim2.new(0, 20, 0, 150 + (index - 1) * (H + 8))
		if typeof(fcfg.Position) == "UDim2" then
			startpos = fcfg.Position
		end
		if saved and tonumber(saved.x) and tonumber(saved.y) then
			startpos = UDim2.new(0, saved.x, 0, saved.y)
		end
		root.Position = startpos
		-- same corner radius as the window itself
		local windowcorner = main:FindFirstChildOfClass("UICorner")
		instance.uicorner(root).CornerRadius = windowcorner and windowcorner.CornerRadius or UDim.new(0, 8)
		local rootstroke = instance.uistroke(root)
		rootstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rootstroke.Color = theme.Stroke
		rootstroke.Thickness = 1

		local icon = instance.imagelabel(root)
		icon.Name = "Icon"
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.BackgroundTransparency = 1
		icon.ImageColor3 = theme.SubText
		icon.Size = UDim2.new(0, 14, 0, 14)
		icon.ZIndex = 2

		local label = instance.textlabel(root)
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.FontFace = FONT_BOLD
		label.Text = title
		label.TextColor3 = theme.Text
		label.TextSize = ts(12)
		label.TextTruncate = Enum.TextTruncate.None
		label.TextWrapped = false
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 2

		local track, knob
		if istoggle then
			track = instance.frame(root)
			track.Name = "Switch"
			track.AnchorPoint = Vector2.new(0, 0.5)
			track.BackgroundColor3 = theme.Field
			track.BorderSizePixel = 0
			track.Size = UDim2.new(0, 28, 0, 14)
			track.ZIndex = 2
			instance.uicorner(track).CornerRadius = UDim.new(1, 0)
			local trackstroke = instance.uistroke(track)
			trackstroke.Color = Color3.fromRGB(255, 255, 255)
			trackstroke.Thickness = 1
			trackstroke.Transparency = 0.9
			knob = instance.frame(track)
			knob.Name = "Knob"
			knob.BackgroundColor3 = theme.Text
			knob.BorderSizePixel = 0
			knob.Position = UDim2.new(0, 2, 0, 2)
			knob.Size = UDim2.new(0, 10, 0, 10)
			knob.ZIndex = 3
			instance.uicorner(knob).CornerRadius = UDim.new(1, 0)
		end

		local divider = instance.frame(root)
		divider.Name = "Divider"
		divider.AnchorPoint = Vector2.new(0, 0.5)
		divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		divider.BackgroundTransparency = 0.88
		divider.BorderSizePixel = 0
		divider.Size = UDim2.new(0, 1, 0, 16)
		divider.ZIndex = 2

		local hit = instance.textbutton(root)
		hit.Name = "Hit"
		hit.AutoButtonColor = false
		hit.BackgroundTransparency = 1
		hit.Text = ""
		hit.ZIndex = 4

		local lockbtn = instance.textbutton(root)
		lockbtn.Name = "Lock"
		lockbtn.AutoButtonColor = false
		lockbtn.AnchorPoint = Vector2.new(0, 0.5)
		lockbtn.BackgroundTransparency = 1
		lockbtn.Size = UDim2.new(0, 26, 0, 26)
		lockbtn.Text = ""
		lockbtn.ZIndex = 5
		local lockimg = instance.imagelabel(lockbtn)
		lockimg.AnchorPoint = Vector2.new(0.5, 0.5)
		lockimg.BackgroundTransparency = 1
		lockimg.Position = UDim2.new(0.5, 0, 0.5, 0)
		lockimg.Size = UDim2.new(0, 13, 0, 13)
		lockimg.ZIndex = 5
		paintlockicon(lockimg, locked)

		local function relayout()
			local x = 10
			local hasicon = icon.Image ~= ""
			icon.Visible = hasicon
			if hasicon then
				icon.Position = UDim2.new(0, x, 0.5, 0)
				x = x + 14 + 6
			end
			-- fit the real rendered text (TextBounds), the estimate is only the fallback
			local w = math.max(textwidth(label.Text, 12, FONT_BOLD), math.ceil(label.TextBounds.X)) + 4
			label.Position = UDim2.new(0, x, 0, 0)
			label.Size = UDim2.new(0, w, 1, 0)
			x = x + w + 8
			if track then
				track.Position = UDim2.new(0, x, 0.5, 0)
				x = x + 28 + 8
			end
			divider.Position = UDim2.new(0, x, 0.5, 0)
			hit.Size = UDim2.new(0, x, 1, 0)
			x = x + 1 + 2
			lockbtn.Position = UDim2.new(0, x, 0.5, 0)
			x = x + 26 + 3
			root.Size = UDim2.new(0, x, 0, H)
		end

		local function seticonname(name)
			name = tostring(name or "")
			if name == "" then
				icon.Image = ""
				icon.ImageRectOffset = Vector2.new(0, 0)
				icon.ImageRectSize = Vector2.new(0, 0)
			else
				applyicon(icon, name, 48)
			end
			relayout()
		end
		seticonname(fcfg.Icon)
		label:GetPropertyChangedSignal("TextBounds"):Connect(relayout)

		-- default spot: the right edge of the screen, each new one lands further down
		if not saved and typeof(fcfg.Position) ~= "UDim2" then
			local area = floatgui().AbsoluteSize
			if area.X <= 1 then
				area = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			end
			root.Position = UDim2.new(0, math.max(0, area.X - root.Size.X.Offset - 12), 0, 60 + (index - 1) * (H + 8))
		end

		local function clamp(x, y)
			local gui = floatgui()
			local area = gui.AbsoluteSize
			if area.X <= 1 or area.Y <= 1 then
				area = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			end
			local size = root.AbsoluteSize
			return math.clamp(x, 0, math.max(0, area.X - size.X)), math.clamp(y, 0, math.max(0, area.Y - size.Y))
		end

		local function remember()
			floatpos[posname] = {
				x = math.floor(root.Position.X.Offset + 0.5),
				y = math.floor(root.Position.Y.Offset + 0.5),
				locked = locked,
			}
			savefloatpos()
		end

		local function tween(obj, props, instant)
			if instant then
				for k, v in pairs(props) do
					obj[k] = v
				end
			else
				sv.ts:Create(obj, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
			end
		end

		local hovering = false
		local function render(instant)
			if istoggle then
				local on = item.Value
				tween(track, { BackgroundColor3 = on and guiconfig.Color or theme.Field }, instant)
				tween(knob, {
					Position = on and UDim2.new(0, 16, 0, 2) or UDim2.new(0, 2, 0, 2),
					BackgroundColor3 = on and theme.AccentText or theme.Text,
				}, instant)
				tween(rootstroke, {
					Color = on and guiconfig.Color or theme.Stroke,
					Transparency = on and 0.35 or 0,
				}, instant)
				tween(label, { TextColor3 = on and theme.Text or theme.SubText }, instant)
				tween(icon, { ImageColor3 = on and theme.Text or theme.SubText }, instant)
			end
			tween(root, { BackgroundColor3 = hovering and theme.Element or theme.Card }, instant)
		end

		hit.MouseEnter:Connect(function()
			hovering = true
			render(false)
		end)
		hit.MouseLeave:Connect(function()
			hovering = false
			render(false)
		end)
		lockbtn.MouseEnter:Connect(function()
			lockimg.ImageColor3 = theme.Text
		end)
		lockbtn.MouseLeave:Connect(function()
			lockimg.ImageColor3 = locked and theme.Gold or theme.SubText
		end)

		local function arg(a, b)
			if a == item then
				return b
			end
			return a
		end

		-- the value a toggle holds; also fires the callback
		function item.Set(a, b, c)
			if not istoggle then
				return
			end
			local value = arg(a, b)
			local instant = b
			if a == item then
				instant = c
			end
			item.Value = value and true or false
			if configkey then
				config.data[configkey] = item.Value
				config:queuesave()
			end
			render(instant == true)
			elevate()
			local ok, err = pcall(callback, item.Value)
			if not ok then
				warn("FloatingToggle Callback error (" .. title .. "):", err)
			end
		end
		item.SetValue = item.Set
		function item.LoadValue(a, b)
			item.Set(arg(a, b), true)
		end
		function item.ResetValue()
			item.Set(hubdefault)
		end
		function item.GetValue()
			return item.Value
		end

		function item.SetLocked(a, b)
			locked = arg(a, b) == true
			paintlockicon(lockimg, locked)
			remember()
			return locked
		end
		function item.SetDraggable(a, b)
			return item.SetLocked(not (arg(a, b) == true))
		end
		function item.IsLocked()
			return locked
		end
		function item.IsDraggable()
			return not locked
		end

		local function applyvisible()
			root.Visible = shown and floating.visible
		end
		item.Refresh = applyvisible
		function item.SetVisible(a, b)
			shown = arg(a, b) ~= false
			applyvisible()
		end
		function item.Show()
			shown = true
			applyvisible()
		end
		function item.Hide()
			shown = false
			applyvisible()
		end
		function item.IsVisible()
			return shown and floating.visible
		end

		function item.SetTitle(a, b)
			label.Text = tostring(arg(a, b) or "")
			title = label.Text
			relayout()
		end
		function item.SetIcon(a, b)
			seticonname(arg(a, b))
		end
		function item.SetPosition(a, b, c)
			local x, y = b, c
			if a ~= item then
				x, y = a, b
			end
			if typeof(x) == "UDim2" then
				root.Position = x
			else
				local cx, cy = clamp(tonumber(x) or 0, tonumber(y) or 0)
				root.Position = UDim2.new(0, cx, 0, cy)
			end
			remember()
		end
		function item.Destroy()
			for _, c in ipairs(connections) do
				pcall(function()
					c:Disconnect()
				end)
			end
			connections = {}
			local at = table.find(floating.list, item)
			if at then
				table.remove(floating.list, at)
			end
			if configkey and config.elements[configkey] == item then
				config.elements[configkey] = nil
			end
			pcall(function()
				root:Destroy()
			end)
		end
		item.Instance = root

		local function fire()
			elevate()
			if istoggle then
				item.Set(not item.Value)
			else
				local ok, err = pcall(callback)
				if not ok then
					warn("FloatingButton Callback error (" .. title .. "):", err)
				end
			end
		end

		-- drag: a press that moves further than 6 px drags (when unlocked), a short press is a click
		local dragging, moved = false, false
		local dragstart, dragorigin = nil, nil
		hit.InputBegan:Connect(function(input)
			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end
			dragging, moved = true, false
			dragstart = input.Position
			dragorigin = root.Position
			input.Changed:Connect(function()
				if input.UserInputState ~= Enum.UserInputState.End or not dragging then
					return
				end
				dragging = false
				if moved then
					remember()
				else
					fire()
				end
			end)
		end)
		connections[#connections + 1] = trackConnection(
			sv.uis.InputChanged:Connect(function(input)
				if
					not dragging
					or locked
					or (
						input.UserInputType ~= Enum.UserInputType.MouseMovement
						and input.UserInputType ~= Enum.UserInputType.Touch
					)
				then
					return
				end
				local delta = input.Position - dragstart
				if not moved and delta.Magnitude < 6 then
					return
				end
				moved = true
				local cx, cy = clamp(dragorigin.X.Offset + delta.X, dragorigin.Y.Offset + delta.Y)
				root.Position = UDim2.new(0, cx, 0, cy)
			end),
			"floating.drag." .. posname
		)

		lockbtn.Activated:Connect(function()
			elevate()
			item.SetLocked(not locked)
		end)

		if configkey then
			config.elements[configkey] = item
		end
		floating.list[#floating.list + 1] = item
		render(true)
		task.defer(function()
			if root.Parent then
				local cx, cy = clamp(root.Position.X.Offset, root.Position.Y.Offset)
				root.Position = UDim2.new(0, cx, 0, cy)
			end
		end)
		if istoggle then
			elevate()
			local ok, err = pcall(callback, item.Value)
			if not ok then
				warn("FloatingToggle Callback error (" .. title .. "):", err)
			end
		end
		return item
	end

	function tabs:CreateFloatingToggle(fcfg)
		return buildfloating("toggle", fcfg)
	end
	tabs.CreateFloatingToogle = tabs.CreateFloatingToggle -- common misspelling, kept as an alias

	function tabs:CreateFloatingButton(fcfg)
		return buildfloating("button", fcfg)
	end

	local function floatingarg(a, b)
		if a == tabs then
			return b
		end
		return a
	end

	function tabs:SetFloatingVisible(a, b)
		floating.visible = floatingarg(a, b) ~= false
		for _, item in ipairs(floating.list) do
			item.Refresh()
		end
		return floating.visible
	end

	function tabs:ShowFloating()
		return tabs:SetFloatingVisible(true)
	end

	function tabs:HideFloating()
		return tabs:SetFloatingVisible(false)
	end

	function tabs:SetFloatingLocked(a, b)
		local state = floatingarg(a, b) == true
		for _, item in ipairs(floating.list) do
			item.SetLocked(state)
		end
		return state
	end

	function tabs:SetFloatingDraggable(a, b)
		return not tabs:SetFloatingLocked(not (floatingarg(a, b) == true))
	end

	local hasActiveTab = false

	-- KeyGate: until a trial or donator key is active, every tab except the ones made
	-- with Gate = false (the Donate tab, where the key is redeemed) is hidden, and its
	-- elements are locked like Donator elements, so saved settings are held back
	-- instead of running. A key redeemed mid-session opens everything at once.
	local keygate = guiconfig.KeyGate == true
	-- KeyGateDonatorOnly: only a real donator key opens the gate; a trial key does not
	-- (the gated elements become Locked2 / DonatorOnly).
	local keygatedonator = keygate and guiconfig.KeyGateDonatorOnly == true
	local tabentries = {}
	local gatewasopen = nil
	local gatenotified = false
	local trialnotified = false
	local function applykeygate()
		if not keygate then
			return
		end
		local open
		if keygatedonator then
			open = Chloex._isDonator == true
		else
			open = isdonator()
		end
		local current = layerspagelayout.CurrentPage
		local currententry, first, firstvisible
		for _, entry in ipairs(tabentries) do
			entry.tab.Visible = open or not entry.gated
			if entry.page == current then
				currententry = entry
			end
			if entry.first then
				first = entry
			end
			if entry.tab.Visible and (not firstvisible or entry.order < firstvisible.order) then
				firstvisible = entry
			end
		end
		if open and gatewasopen == false and first then
			-- just unlocked: land on the hub's start tab
			first.select()
		elseif currententry and not currententry.tab.Visible and firstvisible then
			firstvisible.select()
		end
		if not open and firstvisible then
			local where = tostring(firstvisible.name)
			if keygatedonator and istrial() and not trialnotified then
				trialnotified = true
				gatenotified = true
				Chloex:Notify({
					Title = "Vecta",
					Description = "Donator key required",
					Content = "Trial keys do not unlock this hub. Redeem a donator key in " .. where .. ".",
					Duration = 8,
				})
			elseif not gatenotified then
				gatenotified = true
				Chloex:Notify({
					Title = "Vecta",
					Description = keygatedonator and "Donator key required" or "Key required",
					Content = "Redeem a " .. (keygatedonator and "donator" or "trial or donator") .. " key in " .. where .. " to unlock every tab.",
					Duration = 8,
				})
			end
		end
		gatewasopen = open
	end
	if keygate then
		table.insert(Chloex.DonatorListeners, applykeygate)
		-- a key saved from an earlier session is checked again in the background
		if not isdonator() and Chloex:GetSavedKey() then
			task.spawn(function()
				pcall(Chloex.CheckDonatorKey, Chloex)
			end)
		end
	end

	function tabs:AddTab(tabconfig)
		tabconfig = tabconfig or {}
		tabconfig.Name = tabconfig.Name or "Tab"

		local tabIndex = counttab
		local layoutOrder = tonumber(tabconfig.LayoutOrder) or tabIndex
		local isFirstTab = not hasActiveTab and tabconfig.StartActive ~= false
		if isFirstTab then
			hasActiveTab = true
		end
		local tabgated = keygate and tabconfig.Gate ~= false

		-- Thin visible scrollbar: a hidden one let content (the chat input) sit below
		-- the fold with nothing telling the player there was more.
		local scrollayers = instance.scrollingframe(layersfolder)
		scrollayers.Name = "ScrolLayers"
		scrollayers.ScrollBarImageColor3 = theme.Bar
		scrollayers.ScrollBarImageTransparency = 0.35
		scrollayers.ScrollBarThickness = 3
		scrollayers.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		scrollayers.ScrollingDirection = Enum.ScrollingDirection.Y
		scrollayers.Active = true
		scrollayers.LayoutOrder = layoutOrder
		scrollayers.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		scrollayers.BackgroundTransparency = 1
		scrollayers.BorderColor3 = Color3.fromRGB(0, 0, 0)
		scrollayers.BorderSizePixel = 0
		scrollayers.Size = UDim2.new(1, 0, 1, 0)

		local uilistlayout1 = instance.uilistlayout(scrollayers)
		uilistlayout1.Padding = UDim.new(0, 3)
		uilistlayout1.SortOrder = Enum.SortOrder.LayoutOrder

		local function updatesizescroll()
			scrollayers.CanvasSize = UDim2.new(0, 0, 0, uilistlayout1.AbsoluteContentSize.Y)
		end

		uilistlayout1:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatesizescroll)

		local tab = instance.frame(scrolltab)
		tab.Name = "Tab"
		tab.BorderSizePixel = 0
		tab.LayoutOrder = layoutOrder
		tab.Size = UDim2.new(1, -6, 0, 28)
		local tabbg = roundbg(tab, 4, theme.TabActive)
		tabbg.ImageTransparency = isFirstTab and 0 or 1

		local tabbutton = instance.textbutton(tab)
		tabbutton.Name = "TabButton"
		tabbutton.FontFace = FONT_BOLD
		tabbutton.Text = ""
		tabbutton.TextColor3 = Color3.fromRGB(255, 255, 255)
		tabbutton.TextSize = ts(13)
		tabbutton.TextXAlignment = Enum.TextXAlignment.Left
		tabbutton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		tabbutton.BackgroundTransparency = 1
		tabbutton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		tabbutton.BorderSizePixel = 0
		tabbutton.Size = UDim2.new(1, 0, 1, 0)

		local onOpenCallback
		local onOpenRan = false

		local function runOnOpen()
			if onOpenRan or not onOpenCallback then
				return
			end

			onOpenRan = true
			local ok, err = pcall(onOpenCallback)
			if not ok then
				warn("Tab OnOpen error:", err)
			end
		end

		local tabname = instance.textlabel(tab)
		tabname.Name = "TabName"
		tabname.FontFace = FONT_BOLD
		tabname.Text = tostring(tabconfig.Name)
		tabname.TextColor3 = Color3.fromRGB(255, 255, 255)
		tabname.TextSize = ts(13)
		tabname.TextTruncate = Enum.TextTruncate.AtEnd
		tabname.TextXAlignment = Enum.TextXAlignment.Left
		tabname.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		tabname.BackgroundTransparency = 1
		tabname.BorderColor3 = Color3.fromRGB(0, 0, 0)
		tabname.BorderSizePixel = 0

		local hasicon = tabconfig.Icon ~= nil and tabconfig.Icon ~= ""
		local tabicon
		if hasicon then
			tabicon = instance.imagelabel(tab)
			tabicon.Name = "TabIcon"
			tabicon.AnchorPoint = Vector2.new(0, 0.5)
			tabicon.Position = UDim2.new(0, 10, 0.5, 0)
			tabicon.Size = UDim2.new(0, 14, 0, 14)
			tabicon.BackgroundTransparency = 1
			tabicon.ImageColor3 = isFirstTab and theme.Text or theme.SubText
			applyicon(tabicon, tabconfig.Icon, 48)
		end

		tabname.TextColor3 = isFirstTab and theme.Text or theme.SubText
		tabname.Size = UDim2.new(1, -(hasicon and 36 or 16), 1, 0)
		tabname.Position = UDim2.new(0, hasicon and 30 or 10, 0, 0)

		-- Icon-only sidebar: centre the icon; a tab without an icon shows its
		-- first letters instead.
		if compactsidebar then
			if tabicon then
				tabicon.AnchorPoint = Vector2.new(0.5, 0.5)
				tabicon.Position = UDim2.new(0.5, 1, 0.5, 0)
				tabicon.Size = UDim2.new(0, 16, 0, 16)
				tabname.Visible = false
			else
				tabname.Text = string.upper(string.sub(tostring(tabconfig.Name), 1, 2))
				tabname.TextXAlignment = Enum.TextXAlignment.Center
				tabname.Position = UDim2.new(0, 0, 0, 0)
				tabname.Size = UDim2.new(1, 0, 1, 0)
			end
		end

		-- Unread / count badge, set by the hub or a component (tab:SetBadge).
		local badge = instance.frame(tab)
		badge.Name = "TabBadge"
		badge.AnchorPoint = compactsidebar and Vector2.new(1, 0) or Vector2.new(1, 0.5)
		badge.Position = compactsidebar and UDim2.new(1, -2, 0, 2) or UDim2.new(1, -6, 0.5, 0)
		badge.Size = UDim2.new(0, 0, 0, compactsidebar and 12 or 16)
		badge.AutomaticSize = Enum.AutomaticSize.X
		badge.BackgroundColor3 = theme.Bad
		badge.BorderSizePixel = 0
		badge.Visible = false
		badge.ZIndex = 3
		instance.uicorner(badge).CornerRadius = UDim.new(0, 5)
		local badgepad = instance.uipadding(badge)
		badgepad.PaddingLeft = UDim.new(0, compactsidebar and 3 or 5)
		badgepad.PaddingRight = UDim.new(0, compactsidebar and 3 or 5)
		local badgetext = instance.textlabel(badge)
		badgetext.AutomaticSize = Enum.AutomaticSize.X
		badgetext.BackgroundTransparency = 1
		badgetext.FontFace = FONT_BOLD
		badgetext.Size = UDim2.new(0, 0, 1, 0)
		badgetext.Text = ""
		badgetext.TextColor3 = Color3.fromRGB(255, 255, 255)
		badgetext.TextSize = ts(compactsidebar and 9 or 10)
		badgetext.ZIndex = 3

		local function isactive()
			return layerspagelayout.CurrentPage == scrollayers
		end

		-- Hover: a faint fill on inactive tabs only.
		tabbutton.MouseEnter:Connect(function()
			if not isactive() then
				tabbg.ImageTransparency = 0.6
			end
		end)
		tabbutton.MouseLeave:Connect(function()
			if not isactive() then
				tabbg.ImageTransparency = 1
			end
		end)

		-- Active marker: a 3 px accent bar that moves between tabs.
		if isFirstTab then
			layerspagelayout:JumpTo(scrollayers)
			local chooseframe = instance.frame(tab)
			chooseframe.Name = "ChooseFrame"
			chooseframe.BackgroundColor3 = guiconfig.Color
			chooseframe.BorderColor3 = Color3.fromRGB(0, 0, 0)
			chooseframe.BorderSizePixel = 0
			chooseframe.Position = UDim2.new(0, 1, 0, 7)
			chooseframe.Size = UDim2.new(0, 3, 0, 14)

			instance.uicorner(chooseframe).CornerRadius = UDim.new(1, 0)
		end

		local function selecttab()
			if layerspagelayout.CurrentPage == scrollayers then
				runOnOpen()
				return
			end

			local framechoose
			for _, tabframe in ipairs(scrolltab:GetChildren()) do
				if tabframe.Name == "Tab" then
					local cf = tabframe:FindFirstChild("ChooseFrame")
					if cf then
						framechoose = cf
					end
					local tb = tabframe:FindFirstChild("Bg")
					if tb then
						tb.ImageTransparency = 1
					end
					local tn = tabframe:FindFirstChild("TabName")
					if tn then
						tn.TextColor3 = theme.SubText
					end
					local ti = tabframe:FindFirstChild("TabIcon")
					if ti then
						ti.ImageColor3 = theme.SubText
					end
				end
			end

			if not framechoose then
				return
			end

			tabbg.ImageTransparency = 0
			tabname.TextColor3 = theme.Text
			if tabicon then
				tabicon.ImageColor3 = theme.Text
			end

			framechoose.Parent = tab
			framechoose.Position = UDim2.new(0, 1, 0, 7)
			framechoose.Size = UDim2.new(0, 3, 0, 14)

			layerspagelayout:JumpTo(scrollayers)
			runOnOpen()

			if searchbox.Text ~= "" then
				runsearch()
			end
		end
		tabbutton.Activated:Connect(selecttab)

		local sections = {}
		local countsection = 0

		-- tab:SetBadge(n | text | nil): small red count on the sidebar row;
		-- nil, 0, false or "" hides it.
		function sections:SetBadge(value)
			elevate()
			local show = value ~= nil and value ~= false and value ~= 0 and value ~= ""
			if show then
				local n = tonumber(value)
				badgetext.Text = n and (n > 99 and "99+" or tostring(math.floor(n))) or tostring(value)
			end
			badge.Visible = show and true or false
		end

		function sections:OnOpen(callback)
			onOpenCallback = callback
			if isFirstTab then
				runOnOpen()
			end
			return self
		end

		-- AddSection(title, alwaysOpen) or AddSection({ Title, AlwaysOpen, Header }).
		--   AlwaysOpen  pinned open, the header no longer collapses it
		--   Header=false  no header row at all (a component that fills its tab,
		--                 e.g. Live Chat or Forum, and carries its own title)
		function sections:AddSection(sectiontitletext, alwaysopen)
			local noheader = false
			local sectionicon = nil
			if type(sectiontitletext) == "table" then
				local sectioncfg = sectiontitletext
				sectionicon = sectioncfg.Icon
				sectiontitletext = sectioncfg.Title
				alwaysopen = sectioncfg.AlwaysOpen == true or sectioncfg.Open == true or alwaysopen
				noheader = sectioncfg.Header == false
			end
			sectiontitletext = tostring(sectiontitletext or (noheader and "" or "Title"))
			if noheader then
				alwaysopen = true
			end
			local headerheight = noheader and 0 or 30

			local section = instance.frame(scrollayers)
			section.Name = "Section"
			section.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			section.BackgroundTransparency = 1
			section.BorderSizePixel = 0
			section.LayoutOrder = countsection
			section.ClipsDescendants = true
			section.Size = UDim2.new(1, 0, 0, headerheight)

			local sectionreal = instance.frame(section)
			sectionreal.AnchorPoint = Vector2.new(0.5, 0)
			sectionreal.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			sectionreal.BackgroundTransparency = 1
			sectionreal.BorderSizePixel = 0
			sectionreal.Position = UDim2.new(0.5, 0, 0, 0)
			sectionreal.Size = UDim2.new(1, 1, 0, 30)
			sectionreal.Visible = not noheader

			local uicorner = instance.uicorner(sectionreal)
			uicorner.CornerRadius = UDim.new(0, 4)

			local sectionbutton = instance.textbutton(sectionreal)
			sectionbutton.FontFace = FONT_MEDIUM
			sectionbutton.Text = ""
			sectionbutton.BackgroundTransparency = 1
			sectionbutton.Size = UDim2.new(1, 0, 1, 0)

			local featureframe = instance.frame(sectionreal)
			featureframe.AnchorPoint = Vector2.new(1, 0.5)
			featureframe.BackgroundTransparency = 1
			featureframe.Position = UDim2.new(1, -8, 0.5, 0)
			featureframe.Size = UDim2.new(0, 16, 0, 16)
			featureframe.Visible = not alwaysopen

			-- Lucide chevron-right; the frame turns it to point down when open.
			local featureimg = instance.imagelabel(featureframe)
			featureimg.AnchorPoint = Vector2.new(0.5, 0.5)
			featureimg.BackgroundTransparency = 1
			featureimg.ImageColor3 = theme.SubText
			featureimg.Position = UDim2.new(0.5, 0, 0.5, 0)
			featureimg.Size = UDim2.new(0, 14, 0, 14)
			applyicon(featureimg, "chevron-right", 48)

			local sectiontitle = instance.textlabel(sectionreal)
			sectiontitle.FontFace = FONT_BOLD
			sectiontitle.Text = sectiontitletext
			sectiontitle.TextColor3 = theme.Text
			sectiontitle.TextSize = ts(13)
			sectiontitle.TextTruncate = Enum.TextTruncate.AtEnd
			sectiontitle.TextXAlignment = Enum.TextXAlignment.Left
			sectiontitle.AnchorPoint = Vector2.new(0, 0.5)
			sectiontitle.BackgroundTransparency = 1
			sectiontitle.Position = UDim2.new(0, 10, 0.5, 0)
			sectiontitle.Size = UDim2.new(1, -40, 0, 14)

			if sectionicon and tostring(sectionicon) ~= "" then
				local sectioniconimg = instance.imagelabel(sectionreal)
				sectioniconimg.Name = "SectionIcon"
				sectioniconimg.AnchorPoint = Vector2.new(0, 0.5)
				sectioniconimg.BackgroundTransparency = 1
				sectioniconimg.ScaleType = Enum.ScaleType.Fit
				sectioniconimg.Position = UDim2.new(0, 8, 0.5, 0)
				sectioniconimg.Size = UDim2.new(0, 20, 0, 20)
				applyicon(sectioniconimg, sectionicon, 48)
				sectiontitle.Position = UDim2.new(0, 34, 0.5, 0)
				sectiontitle.Size = UDim2.new(1, -64, 0, 14)
			end

			local sectionadd = instance.frame(section)
			sectionadd.AnchorPoint = Vector2.new(0.5, 0)
			sectionadd.BackgroundTransparency = 1
			sectionadd.BorderSizePixel = 0
			sectionadd.ClipsDescendants = true
			sectionadd.Position = UDim2.new(0.5, 0, 0, headerheight)
			sectionadd.Size = UDim2.new(1, 0, 0, 0)

			local uicorner8 = instance.uicorner(sectionadd)
			uicorner8.CornerRadius = UDim.new(0, 2)

			local uilistlayout2 = instance.uilistlayout(sectionadd)
			uilistlayout2.Padding = UDim.new(0, 3)
			uilistlayout2.SortOrder = Enum.SortOrder.LayoutOrder

			local color_normal = theme.Text
			local color_open = theme.Text

			local opensection = false
			local sectionResizeQueued = false

			local function updatesizesection(animate)
				if not opensection then
					return
				end

				local contentHeight = math.max(0, uilistlayout2.AbsoluteContentSize.Y)
				local sectionsizey = headerheight + contentHeight
				sectiontitle.TextColor3 = color_open

				if animate and featureframe.Parent then
					sv.ts:Create(featureframe, TweenInfo.new(0.3), { Rotation = 90 }):Play()
					sv.ts:Create(section, TweenInfo.new(0.3), { Size = UDim2.new(1, 0, 0, sectionsizey) }):Play()
					sv.ts:Create(sectionadd, TweenInfo.new(0.3), { Size = UDim2.new(1, 0, 0, contentHeight) }):Play()
				else
					if featureframe.Parent then
						featureframe.Rotation = 90
					end
					section.Size = UDim2.new(1, 0, 0, sectionsizey)
					sectionadd.Size = UDim2.new(1, 0, 0, contentHeight)
				end

				updatesizescroll()
			end

			local function queueSectionResize()
				if sectionResizeQueued then
					return
				end

				sectionResizeQueued = true
				task.defer(function()
					sectionResizeQueued = false
					updatesizesection(false)
				end)
			end

			local function closesection(animate)
				if not opensection or alwaysopen then
					return
				end
				opensection = false
				sectiontitle.TextColor3 = color_normal
				if animate then
					sv.ts:Create(featureframe, TweenInfo.new(0.3), { Rotation = 0 }):Play()
					sv.ts:Create(section, TweenInfo.new(0.3), { Size = UDim2.new(1, 0, 0, headerheight) }):Play()
					sv.ts:Create(sectionadd, TweenInfo.new(0.3), { Size = UDim2.new(1, 0, 0, 0) }):Play()
				else
					featureframe.Rotation = 0
					section.Size = UDim2.new(1, 0, 0, headerheight)
					sectionadd.Size = UDim2.new(1, 0, 0, 0)
				end
			end

			sectionbutton.Activated:Connect(function()
				if alwaysopen then
					return
				end
				if opensection then
					closesection(true)
				else
					opensection = true
					updatesizesection(true)
				end
			end)

			if alwaysopen then
				opensection = true
				updatesizesection(false)
			end

			uilistlayout2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(queueSectionResize)

			local items = {}
			local countitem = 0
			local currentSubSection = nil
			local buildStartTime = 0
			local frameThreshold = 0.012
			local function yieldbuild()
				if buildStartTime == 0 then
					buildStartTime = tick()
				end
				if (tick() - buildStartTime) > frameThreshold then
					task.wait()
					buildStartTime = tick()
				end
			end

			local function registerSearchItem(title, object)
				title = tostring(title or "Item")

				local path = tabconfig.Name .. "/" .. sectiontitletext
				if currentSubSection then
					path = path .. "/" .. currentSubSection
				end
				path = path .. "/" .. title

				table.insert(searchItems, {
					Name = title,
					Path = path,
					TabIndex = scrollayers.LayoutOrder,
					Page = scrollayers,
					Section = section,
					Object = object,
					IsOpen = function()
						return opensection
					end,
					OpenSection = function()
						if not opensection then
							opensection = true
							updatesizesection()
						end
					end,
					CloseSection = function()
						closesection(false)
					end,
				})
			end

			function items:AddParagraph(paragraphconfig)
				paragraphconfig = paragraphconfig or {}
				paragraphconfig.Title = paragraphconfig.Title or "Title"
				paragraphconfig.Content = paragraphconfig.Content or "Content"
				local paragraphfunc = {}

				local paragraph = instance.frame(sectionadd)
				paragraph.Name = "Paragraph"
				paragraph.BorderSizePixel = 0
				paragraph.LayoutOrder = countitem
				paragraph.Size = UDim2.new(1, 0, 0, 46)
				roundbg(paragraph, 4, theme.Row)

				local iconoffset = 10
				if paragraphconfig.Icon then
					local iconimg = instance.imagelabel(paragraph)
					iconimg.Name = "ParagraphIcon"
					iconimg.Size = UDim2.new(0, 20, 0, 20)
					iconimg.Position = UDim2.new(0, 8, 0, 12)
					iconimg.BackgroundTransparency = 1

					-- Lucide name ("info", "crown") or an asset id, same as tab icons
					applyicon(iconimg, paragraphconfig.Icon, 48)

					iconoffset = 30
				end

				local paragraphtitle = instance.textlabel(paragraph)
				paragraphtitle.Name = "ParagraphTitle"
				paragraphtitle.FontFace = FONT_BOLD
				paragraphtitle.Text = paragraphconfig.Title
				paragraphtitle.TextColor3 = theme.Text
				paragraphtitle.TextSize = ts(13)
				paragraphtitle.TextXAlignment = Enum.TextXAlignment.Left
				paragraphtitle.TextYAlignment = Enum.TextYAlignment.Top
				paragraphtitle.TextTruncate = Enum.TextTruncate.AtEnd
				paragraphtitle.BackgroundTransparency = 1
				paragraphtitle.Position = UDim2.new(0, iconoffset, 0, 10)
				paragraphtitle.Size = UDim2.new(1, -(iconoffset + 10), 0, 14)

				-- Body is regular weight: the title carries the emphasis.
				local paragraphcontent = instance.textlabel(paragraph)
				paragraphcontent.Name = "ParagraphContent"
				paragraphcontent.FontFace = FONT_MEDIUM
				paragraphcontent.Text = paragraphconfig.Content
				paragraphcontent.TextColor3 = theme.Text
				paragraphcontent.TextTransparency = 0.12
				paragraphcontent.TextSize = math.max(7, ts(12) - 1)
				paragraphcontent.TextXAlignment = Enum.TextXAlignment.Left
				paragraphcontent.TextYAlignment = Enum.TextYAlignment.Top
				paragraphcontent.BackgroundTransparency = 1
				paragraphcontent.Position = UDim2.new(0, iconoffset, 0, 27)
				paragraphcontent.TextWrapped = true
				paragraphcontent.RichText = true
				paragraphcontent.Size = UDim2.new(1, -(iconoffset + 10), 0, 0)

				local paragraphbutton
				if paragraphconfig.ButtonText then
					paragraphbutton = instance.textbutton(paragraph)
					paragraphbutton.Position = UDim2.new(0, 10, 0, 42)
					paragraphbutton.Size = UDim2.new(1, -20, 0, 28)
					paragraphbutton.FontFace = FONT_BOLD
					paragraphbutton.TextSize = ts(12)
					paragraphbutton.TextColor3 = theme.Text
					paragraphbutton.TextTruncate = Enum.TextTruncate.AtEnd
					paragraphbutton.Text = paragraphconfig.ButtonText

					hoverbg(paragraphbutton, roundbg(paragraphbutton, 6, theme.Inner), theme.Inner, theme.InnerHover)

					if paragraphconfig.ButtonCallback then
						paragraphbutton.MouseButton1Click:Connect(function()
							pcall(pesseffect, paragraphbutton)
							paragraphconfig.ButtonCallback()
						end)
					end
				end

				-- The button follows the body, so a multi-line body never sits under it.
				local function updatesize()
					local bodyheight = paragraphcontent.TextBounds.Y
					paragraphcontent.Size = UDim2.new(1, -(iconoffset + 10), 0, bodyheight)
					local totalheight = 27 + bodyheight + 10
					if paragraphbutton then
						paragraphbutton.Position = UDim2.new(0, 10, 0, 27 + bodyheight + 8)
						totalheight = totalheight + paragraphbutton.Size.Y.Offset + 6
					end
					paragraph.Size = UDim2.new(1, 0, 0, math.max(46, totalheight))
				end

				task.defer(updatesize)
				paragraphcontent:GetPropertyChangedSignal("TextBounds"):Connect(updatesize)

				function paragraphfunc:SetContent(content)
					content = content or "Content"
					paragraphcontent.Text = content
					updatesize()
				end

				registerSearchItem(paragraphconfig.Title, paragraph)
				countitem = countitem + 1
				yieldbuild()
				return paragraphfunc
			end

			function items:AddPanel(panelconfig)
				panelconfig = panelconfig or {}

				local panels = {
					Chloe = {
						Image = "rbxassetid://139546726059566",
						AspectRatio = 3.56,
					},
					UgPhone = {
						Image = "rbxassetid://95132907847500",
						AspectRatio = 3.56,
					},
					ChloeStore = {
						Image = "rbxassetid://78353987171005",
						AspectRatio = 3.56,
					},
				}

				local paneldata = panels[panelconfig.Type] or panels.Chloe
				local aspectRatio = tonumber(panelconfig.AspectRatio) or paneldata.AspectRatio

				local panel = instance.imagelabel(sectionadd)
				panel.Name = "Panel"
				panel.BackgroundTransparency = 1
				panel.BorderSizePixel = 0
				panel.Image = panelconfig.Image or paneldata.Image
				panel.ScaleType = Enum.ScaleType.Fit
				panel.Size = UDim2.new(1, 0, 0, 160)
				panel.LayoutOrder = countitem
				panel.ClipsDescendants = true
				panel.ZIndex = 1

				instance.uicorner(panel).CornerRadius = UDim.new(0, tonumber(panelconfig.CornerRadius) or 10)

				local lastWidth = -1
				local resizeQueued = false

				local function updatePanelSize()
					resizeQueued = false

					if not panel or not panel.Parent then
						return
					end

					local width = math.floor(panel.AbsoluteSize.X + 0.5)

					if width <= 1 then
						width = math.floor(sectionadd.AbsoluteSize.X + 0.5)
					end

					if width <= 1 or width == lastWidth then
						return
					end

					lastWidth = width

					local height = math.max(1, math.floor((width / aspectRatio) + 0.5))

					panel.Size = UDim2.new(1, 0, 0, height)
				end

				local function queuePanelResize()
					if resizeQueued then
						return
					end

					resizeQueued = true
					task.defer(updatePanelSize)
				end

				trackConnection(
					sectionadd:GetPropertyChangedSignal("AbsoluteSize"):Connect(queuePanelResize),
					"panel.adaptive.resize"
				)

				task.defer(queuePanelResize)

				countitem = countitem + 1
				yieldbuild()

				return panel
			end

			-- Value model shared by Toggle / Slider / Input / Dropdown:
			--   .Value        what the hub sees (callbacks get exactly this)
			--   config.data   what the player saved; kept while the element is
			--                 donator-locked, so a renewed key brings it back
			--   DefaultValue  the hub's own Default; a locked element sits on it
			-- A locked element never applies a saved value and never fires its
			-- callback with one.

			function items:AddIconGrid(gridconfig)
				gridconfig = gridconfig or {}
				local gridfunc = {}
				local columns = math.max(1, tonumber(gridconfig.Columns) or 4)
				local cardheight = tonumber(gridconfig.CardHeight) or 104
				local gap = 6

				local holder = instance.frame(sectionadd)
				holder.Name = "IconGrid"
				holder.BorderSizePixel = 0
				holder.LayoutOrder = countitem
				holder.Size = UDim2.new(1, 0, 0, 40 + cardheight)
				roundbg(holder, 4, theme.Row)

				local title = instance.textlabel(holder)
				title.Name = "GridTitle"
				title.FontFace = FONT_BOLD
				title.Text = tostring(gridconfig.Title or "Collection")
				title.TextColor3 = theme.Text
				title.TextSize = ts(13)
				title.TextXAlignment = Enum.TextXAlignment.Left
				title.TextTruncate = Enum.TextTruncate.AtEnd
				title.BackgroundTransparency = 1
				title.Position = UDim2.new(0, 10, 0, 8)
				title.Size = UDim2.new(0.6, -10, 0, 16)

				local note = instance.textlabel(holder)
				note.Name = "GridNote"
				note.FontFace = FONT_MEDIUM
				note.Text = tostring(gridconfig.Note or "")
				note.TextColor3 = theme.SubText
				note.TextSize = ts(12)
				note.TextXAlignment = Enum.TextXAlignment.Right
				note.TextTruncate = Enum.TextTruncate.AtEnd
				note.BackgroundTransparency = 1
				note.Position = UDim2.new(0.4, 0, 0, 8)
				note.Size = UDim2.new(0.6, -10, 0, 16)

				local body = instance.frame(holder)
				body.Name = "GridBody"
				body.BackgroundTransparency = 1
				body.BorderSizePixel = 0
				body.Position = UDim2.new(0, 8, 0, 32)
				body.Size = UDim2.new(1, -16, 0, cardheight)

				local layout = instance.uigridlayout(body)
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.CellPadding = UDim2.new(0, gap, 0, gap)
				layout.CellSize = UDim2.new(0, 80, 0, cardheight)

				local cards, data, dirty = {}, {}, false

				local function newcard(i)
					local card = instance.frame(body)
					card.Name = "Card" .. i
					card.BorderSizePixel = 0
					card.LayoutOrder = i
					card.ClipsDescendants = true
					local bg = roundbg(card, 6, theme.Inner)
					local stroke = instance.uistroke(card)
					stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					stroke.Thickness = 1
					stroke.Transparency = 0.55
					stroke.Color = theme.Stroke
					instance.uicorner(card).CornerRadius = UDim.new(0, 6)

					local glow = instance.frame(card)
					glow.Name = "Glow"
					glow.BorderSizePixel = 0
					glow.BackgroundTransparency = 0.82
					glow.Size = UDim2.new(1, 0, 0, 3)
					glow.ZIndex = 2

					local icon = instance.imagelabel(card)
					icon.Name = "Icon"
					icon.BackgroundTransparency = 1
					icon.ScaleType = Enum.ScaleType.Fit
					icon.AnchorPoint = Vector2.new(0.5, 0)
					icon.Position = UDim2.new(0.5, 0, 0, 8)
					icon.Size = UDim2.new(0, 40, 0, 40)
					icon.ZIndex = 2

					local function line(name, font, size, y, color)
						local l = instance.textlabel(card)
						l.Name = name
						l.FontFace = font
						l.TextSize = ts(size)
						l.TextColor3 = color
						l.BackgroundTransparency = 1
						l.TextXAlignment = Enum.TextXAlignment.Center
						l.TextTruncate = Enum.TextTruncate.AtEnd
						l.Position = UDim2.new(0, 4, 0, y)
						l.Size = UDim2.new(1, -8, 0, size + 2)
						l.ZIndex = 2
						return l
					end

					local c = {
						frame = card,
						bg = bg,
						stroke = stroke,
						glow = glow,
						icon = icon,
						name = line("Name", FONT_MEDIUM, 12, 50, theme.SubText),
						value = line("Value", FONT_BOLD, 16, 64, theme.Text),
						sub = line("Sub", FONT_MEDIUM, 11, 84, theme.Dim),
					}
					cards[i] = c
					return c
				end

				local function relayout()
					local width = body.AbsoluteSize.X
					if width <= 1 then return end
					local cols = columns
					while cols > 1 and (width - gap * (cols - 1)) / cols < 70 do
						cols = cols - 1
					end
					local cell = math.floor((width - gap * (cols - 1)) / cols)
					layout.CellSize = UDim2.new(0, cell, 0, cardheight)
					local rows = math.max(1, math.ceil(#data / cols))
					local h = rows * cardheight + (rows - 1) * gap
					body.Size = UDim2.new(1, -16, 0, h)
					holder.Size = UDim2.new(1, 0, 0, 40 + h)
				end

				local function paint()
					dirty = false
					for i, item in ipairs(data) do
						local c = cards[i] or newcard(i)
						c.frame.Visible = true
						local accent = typeof(item.Color) == "Color3" and item.Color or theme.Stroke
						c.stroke.Color = accent
						c.glow.BackgroundColor3 = accent
						if c.iconId ~= item.Icon then
							c.iconId = item.Icon
							applyicon(c.icon, item.Icon, 48)
						end
						c.name.Text = tostring(item.Name or "")
						c.value.Text = tostring(item.Value or "")
						c.sub.Text = tostring(item.Sub or "")
						c.sub.TextColor3 = item.SubColor or theme.Dim
					end
					for i = #data + 1, #cards do
						cards[i].frame.Visible = false
					end
					relayout()
				end

				local function queue()
					if dirty then return end
					dirty = true
					task.defer(paint)
				end

				trackConnection(body:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout), "icongrid.resize")

				function gridfunc:SetItems(list)
					data = type(list) == "table" and list or {}
					queue()
				end

				function gridfunc:SetNote(text)
					note.Text = tostring(text or "")
				end

				function gridfunc:SetTitle(text)
					title.Text = tostring(text or "")
				end

				if type(gridconfig.Items) == "table" then
					gridfunc:SetItems(gridconfig.Items)
				end

				registerSearchItem(gridconfig.Title or "Collection", holder)
				countitem = countitem + 1
				yieldbuild()
				return gridfunc
			end

			function items:AddActionList(listconfig)
				listconfig = listconfig or {}
				listconfig.Title = listconfig.Title or "List"
				local emptytext = tostring(listconfig.EmptyText or "Nothing here yet.")
				local visiblerows = math.max(1, tonumber(listconfig.VisibleRows) or 5)
				local buttonwidth = math.max(44, tonumber(listconfig.ButtonWidth) or 74)
				local rowheight = math.max(34, tonumber(listconfig.RowHeight) or 46)
				local rowgap = 4
				local listfunc = {}
				local rows = {}
				local alive = true
				
				local container = instance.frame(sectionadd)
				container.Name = "ActionList"
				container.BorderSizePixel = 0
				container.LayoutOrder = countitem
				container.Size = UDim2.new(1, 0, 0, 62)
				roundbg(container, 4, theme.Row)
				
				local header = instance.textlabel(container)
				header.Name = "ActionListTitle"
				header.FontFace = FONT_BOLD
				header.TextTruncate = Enum.TextTruncate.AtEnd
				header.Text = tostring(listconfig.Title)
				header.TextColor3 = theme.Text
				header.TextSize = ts(13)
				header.TextXAlignment = Enum.TextXAlignment.Left
				header.BackgroundTransparency = 1
				header.Position = UDim2.new(0, 10, 0, 9)
				header.Size = UDim2.new(1, -80, 0, 14)
				
				local counter = instance.textlabel(container)
				counter.Name = "ActionListCount"
				counter.FontFace = FONT_BOLD
				counter.Text = "0"
				counter.TextColor3 = theme.SubText
				counter.TextSize = ts(12)
				counter.TextXAlignment = Enum.TextXAlignment.Right
				counter.BackgroundTransparency = 1
				counter.AnchorPoint = Vector2.new(1, 0)
				counter.Position = UDim2.new(1, -10, 0, 9)
				counter.Size = UDim2.new(0, 60, 0, 14)
				
				local scroll = instance.scrollingframe(container)
				scroll.Name = "ActionListRows"
				scroll.BackgroundTransparency = 1
				scroll.BorderSizePixel = 0
				scroll.Position = UDim2.new(0, 6, 0, 29)
				scroll.Size = UDim2.new(1, -12, 1, -35)
				scroll.ScrollBarThickness = 3
				scroll.ScrollBarImageColor3 = theme.Bar
				scroll.ScrollingDirection = Enum.ScrollingDirection.Y
				scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
				scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
				
				local layout = instance.uilistlayout(scroll)
				layout.FillDirection = Enum.FillDirection.Vertical
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.Padding = UDim.new(0, rowgap)
				
				local empty = instance.textlabel(scroll)
				empty.Name = "ActionListEmpty"
				empty.FontFace = FONT_MEDIUM
				empty.Text = emptytext
				empty.TextColor3 = theme.Dim
				empty.TextSize = ts(12)
				empty.TextXAlignment = Enum.TextXAlignment.Left
				empty.BackgroundTransparency = 1
				empty.LayoutOrder = 0
				empty.Size = UDim2.new(1, -6, 0, 24)
				
				local function resize(count)
					local shown = math.min(math.max(count, 1), visiblerows)
					local body = shown * rowheight + math.max(shown - 1, 0) * rowgap
					container.Size = UDim2.new(1, 0, 0, 35 + body + 6)
				end
				
				local function tintof(name)
					if name == "green" then return theme.Good end
					if name == "red" then return theme.Bad end
					if name == "gold" then return theme.Gold end
					if name == "dim" then return theme.Inner end
					return theme.Accent
				end
				
				local function textof(name)
					if name == "dim" then return Color3.fromRGB(255, 255, 255) end
					if name == "green" or name == "red" or name == "gold" then return theme.AccentText end
					return theme.AccentText
				end
				
				local function buildrow(index)
					elevate()
					local row = instance.frame(scroll)
					row.Name = "ActionRow"
					row.BorderSizePixel = 0
					row.LayoutOrder = index
					row.Size = UDim2.new(1, -6, 0, rowheight)
					roundbg(row, 4, theme.Element)
					
					local name = instance.textlabel(row)
					name.Name = "RowName"
					name.FontFace = FONT_BOLD
					name.TextColor3 = theme.Text
					name.TextSize = ts(12)
					name.RichText = true
					name.TextTruncate = Enum.TextTruncate.AtEnd
					name.TextXAlignment = Enum.TextXAlignment.Left
					name.BackgroundTransparency = 1
					name.Position = UDim2.new(0, 9, 0, 6)
					name.Size = UDim2.new(0.42, -12, 0, 14)
					
					local sub = instance.textlabel(row)
					sub.Name = "RowSub"
					sub.FontFace = FONT_MEDIUM
					sub.TextColor3 = theme.SubText
					sub.TextSize = ts(11)
					sub.RichText = true
					sub.TextTruncate = Enum.TextTruncate.AtEnd
					sub.TextXAlignment = Enum.TextXAlignment.Left
					sub.BackgroundTransparency = 1
					sub.Position = UDim2.new(0, 9, 0, 23)
					sub.Size = UDim2.new(0.42, -12, 0, 14)
					
					local status = instance.textlabel(row)
					status.Name = "RowStatus"
					status.FontFace = FONT_BOLD
					status.TextColor3 = theme.Text
					status.TextSize = ts(12)
					status.RichText = true
					status.TextTruncate = Enum.TextTruncate.AtEnd
					status.TextXAlignment = Enum.TextXAlignment.Left
					status.BackgroundTransparency = 1
					status.Position = UDim2.new(0.44, 0, 0, 6)
					status.Size = UDim2.new(0.56, -buttonwidth - 14, 0, 14)
					
					local statussub = instance.textlabel(row)
					statussub.Name = "RowStatusSub"
					statussub.FontFace = FONT_MEDIUM
					statussub.TextColor3 = theme.Dim
					statussub.TextSize = ts(11)
					statussub.RichText = true
					statussub.TextTruncate = Enum.TextTruncate.AtEnd
					statussub.TextXAlignment = Enum.TextXAlignment.Left
					statussub.BackgroundTransparency = 1
					statussub.Position = UDim2.new(0.44, 0, 0, 23)
					statussub.Size = UDim2.new(0.56, -buttonwidth - 14, 0, 14)
					
					local action = instance.textbutton(row)
					action.Name = "RowAction"
					action.FontFace = FONT_BOLD
					action.TextSize = ts(12)
					action.AutoButtonColor = false
					action.Text = "Go"
					action.TextColor3 = theme.AccentText
					action.AnchorPoint = Vector2.new(1, 0.5)
					action.Position = UDim2.new(1, -8, 0.5, 0)
					action.Size = UDim2.new(0, buttonwidth, 0, 26)
					local actionbg = roundbg(action, 6, theme.Accent)
					
					local record = {
						frame = row,
						name = name,
						sub = sub,
						status = status,
						statussub = statussub,
						action = action,
						bg = actionbg,
						entry = nil,
					}
					
					-- The action button grows to its label (never below ButtonWidth), and
					-- the status column gives up the same width.
					function record.setlabel(text, tint)
						elevate()
						text = tostring(text or "Go")
						action.Text = text
						actionbg.ImageColor3 = tintof(tint)
						action.TextColor3 = textof(tint)
						local width = math.max(buttonwidth, textwidth(text, 12, FONT_BOLD) + 20)
						if record.width ~= width then
							record.width = width
							action.Size = UDim2.new(0, width, 0, 26)
							status.Size = UDim2.new(0.56, -width - 14, 0, 14)
							statussub.Size = UDim2.new(0.56, -width - 14, 0, 14)
						end
					end
					
					action.MouseButton1Down:Connect(function()
						pcall(pesseffect, action)
					end)
					action.MouseButton1Click:Connect(function()
						elevate()
						local entry = record.entry
						if not entry or type(entry.onClick) ~= "function" then return end
						local ok, err = pcall(entry.onClick, entry, record.setlabel)
						if not ok then
							warn("ActionList Callback error (" .. tostring(listconfig.Title) .. "):", err)
						end
					end)
					
					return record
				end
				
				function listfunc:Update(entries)
					elevate()
					if not alive then return end
					entries = type(entries) == "table" and entries or {}
					for index, entry in ipairs(entries) do
						local row = rows[index]
						if not row then
							row = buildrow(index)
							rows[index] = row
						end
						row.entry = entry
						row.name.Text = tostring(entry.name or "")
						row.sub.Text = tostring(entry.sub or "")
						row.status.Text = tostring(entry.status or "")
						row.statussub.Text = tostring(entry.statusSub or "")
						row.setlabel(entry.button or "Go", entry.buttonColor)
						row.action.Visible = entry.button ~= false
						row.frame.Visible = true
					end
					for index = #entries + 1, #rows do
						rows[index].entry = nil
						rows[index].frame.Visible = false
					end
					empty.Visible = #entries == 0
					counter.Text = tostring(#entries)
					resize(#entries)
				end
				
				function listfunc:Clear()
					elevate()
					self:Update({})
				end
				
				function listfunc:Alive()
					elevate()
					return alive and container.Parent ~= nil
				end
				
				function listfunc:Destroy()
					elevate()
					alive = false
					pcall(function() container:Destroy() end)
				end
				
				resize(0)
				registerSearchItem(tostring(listconfig.Title), container)
				countitem = countitem + 1
				yieldbuild()
				return listfunc
			end

			-- Ordered list the player re-ranks with up/down buttons (the hub's Task Order).
			--   Items   { { Id, Title, Sub?, Icon?, Pinned? }, ... }
			--   Default { ids... }  the hub's order; Pinned items always sit at the bottom
			--   Value   array of ids, first runs first; Callback(order) gets a copy
			--   SetStatus(id, text, tone)  live line under a row, tone "run" | "wait" | "off"
			function items:AddPriorityList(listconfig)
				listconfig = listconfig or {}
				listconfig.Title = listconfig.Title or "Priority"
				listconfig.Callback = listconfig.Callback or function() end

				local configkey = keyfor("Priority_", listconfig)
				local rowheight, rowgap, headerheight = 40, 4, 36
				local itemsbyid, itemorder = {}, {}
				for _, item in ipairs(type(listconfig.Items) == "table" and listconfig.Items or {}) do
					local id = type(item) == "table" and tostring(item.Id or item.Title or "") or ""
					if id ~= "" and not itemsbyid[id] then
						itemsbyid[id] = item
						itemorder[#itemorder + 1] = id
					end
				end

				-- Unknown ids are dropped and missing ones appended in default order, so an
				-- order saved before a task existed still loads. Pinned items go last.
				local function sanitize(order)
					local out, seen = {}, {}
					local function push(id)
						id = tostring(id)
						if itemsbyid[id] and not seen[id] and not itemsbyid[id].Pinned then
							seen[id] = true
							out[#out + 1] = id
						end
					end
					for _, id in ipairs(type(order) == "table" and order or {}) do
						push(id)
					end
					for _, id in ipairs(type(listconfig.Default) == "table" and listconfig.Default or {}) do
						push(id)
					end
					for _, id in ipairs(itemorder) do
						push(id)
					end
					for _, id in ipairs(itemorder) do
						if itemsbyid[id].Pinned and not seen[id] then
							seen[id] = true
							out[#out + 1] = id
						end
					end
					return out
				end

				local function copyorder(order)
					local out = {}
					for index, id in ipairs(order) do
						out[index] = id
					end
					return out
				end

				local hubdefault = sanitize(listconfig.Default)
				local function savedpref()
					local saved = config.data[configkey]
					if type(saved) == "table" then
						return sanitize(saved)
					end
					return copyorder(hubdefault)
				end

				local listfunc = { Value = copyorder(hubdefault), DefaultValue = copyorder(hubdefault) }
				local rows, statuses = {}, {}
				-- rows the hub hid (their task is switched off); they keep their place in Value
				local hiddenrows = {}

				local container = instance.frame(sectionadd)
				container.Name = "PriorityList"
				container.BorderSizePixel = 0
				container.LayoutOrder = countitem
				container.ClipsDescendants = true
				container.Size = UDim2.new(1, 0, 0, headerheight)
				roundbg(container, 4, theme.Row)

				local title = instance.textlabel(container)
				title.Name = "PriorityTitle"
				title.BackgroundTransparency = 1
				title.FontFace = FONT_BOLD
				title.Text = tostring(listconfig.Title)
				title.TextColor3 = theme.Text
				title.TextSize = ts(13)
				title.TextTruncate = Enum.TextTruncate.AtEnd
				title.TextXAlignment = Enum.TextXAlignment.Left
				title.TextYAlignment = Enum.TextYAlignment.Top
				title.Position = UDim2.new(0, 10, 0, 11)
				title.Size = UDim2.new(1, -110, 0, 14)

				-- Reset is an auto-width pill: the label sizes the button, never the other way.
				local reset = instance.textbutton(container)
				reset.Name = "PriorityReset"
				reset.AutoButtonColor = false
				reset.Text = ""
				reset.AnchorPoint = Vector2.new(1, 0)
				reset.Position = UDim2.new(1, -8, 0, 8)
				reset.Size = UDim2.new(0, 0, 0, 22)
				reset.AutomaticSize = Enum.AutomaticSize.X
				local resetbg = roundbg(reset, 6, theme.Inner)
				local resetpad = instance.uipadding(reset)
				resetpad.PaddingLeft = UDim.new(0, 8)
				resetpad.PaddingRight = UDim.new(0, 10)
				local resetlayout = instance.uilistlayout(reset)
				resetlayout.FillDirection = Enum.FillDirection.Horizontal
				resetlayout.VerticalAlignment = Enum.VerticalAlignment.Center
				resetlayout.SortOrder = Enum.SortOrder.LayoutOrder
				resetlayout.Padding = UDim.new(0, 5)
				local reseticon = instance.imagelabel(reset)
				reseticon.Name = "Icon"
				reseticon.BackgroundTransparency = 1
				reseticon.ImageColor3 = theme.SubText
				reseticon.LayoutOrder = 1
				reseticon.Size = UDim2.new(0, 12, 0, 12)
				applyicon(reseticon, "rotate-ccw", 48)
				local resettext = instance.textlabel(reset)
				resettext.Name = "Label"
				resettext.AutomaticSize = Enum.AutomaticSize.X
				resettext.BackgroundTransparency = 1
				resettext.FontFace = FONT_BOLD
				resettext.LayoutOrder = 2
				resettext.Size = UDim2.new(0, 0, 1, 0)
				resettext.Text = tostring(listconfig.ResetText or "Reset")
				resettext.TextColor3 = theme.SubText
				resettext.TextSize = ts(12)
				hoverbg(reset, resetbg, theme.Inner, theme.InnerHover)

				local bodytop = headerheight
				local measure = nil
				local description = contenttext(listconfig)
				if description then
					title.Position = UDim2.new(0, 10, 0, 10)
					local _, m = attachcontent(container, description, 10, 30, 10)
					measure = m
				end

				local holder = instance.frame(container)
				holder.Name = "PriorityRows"
				holder.BackgroundTransparency = 1
				holder.BorderSizePixel = 0
				holder.Position = UDim2.new(0, 6, 0, bodytop)
				holder.Size = UDim2.new(1, -12, 0, 0)

				local tones = {
					run = { color = theme.Good, icon = "circle-play" },
					wait = { color = theme.Gold, icon = "hourglass" },
					off = { color = theme.Dim, icon = "circle-off" },
				}
				local tweenfast = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

				local move

				local function buildrow(id)
					elevate()
					local item = itemsbyid[id]
					local pinned = item.Pinned == true

					local row = instance.frame(holder)
					row.Name = "PriorityRow"
					row.BorderSizePixel = 0
					row.Size = UDim2.new(1, 0, 0, rowheight)
					roundbg(row, 6, theme.Element, true)
					local stroke = instance.uistroke(row)
					stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					stroke.Color = guiconfig.Color
					stroke.Thickness = 1
					stroke.Transparency = 1

					local badge = instance.frame(row)
					badge.Name = "Rank"
					badge.AnchorPoint = Vector2.new(0, 0.5)
					badge.BackgroundColor3 = theme.Inner
					badge.BorderSizePixel = 0
					badge.Position = UDim2.new(0, 8, 0.5, 0)
					badge.Size = UDim2.new(0, 22, 0, 22)
					instance.uicorner(badge).CornerRadius = UDim.new(0, 5)
					local ranktext = instance.textlabel(badge)
					ranktext.BackgroundTransparency = 1
					ranktext.FontFace = FONT_BOLD
					ranktext.Size = UDim2.new(1, 0, 1, 0)
					ranktext.Text = ""
					ranktext.TextColor3 = theme.Text
					ranktext.TextSize = ts(11)
					local lockicon = instance.imagelabel(badge)
					lockicon.AnchorPoint = Vector2.new(0.5, 0.5)
					lockicon.BackgroundTransparency = 1
					lockicon.ImageColor3 = theme.SubText
					lockicon.Position = UDim2.new(0.5, 0, 0.5, 0)
					lockicon.Size = UDim2.new(0, 11, 0, 11)
					lockicon.Visible = pinned
					ranktext.Visible = not pinned
					if pinned then
						applyicon(lockicon, "lock", 48)
					end

					local textx = 38
					if item.Icon then
						local icon = instance.imagelabel(row)
						icon.Name = "TaskIcon"
						icon.AnchorPoint = Vector2.new(0, 0.5)
						icon.BackgroundTransparency = 1
						icon.ImageColor3 = theme.SubText
						icon.Position = UDim2.new(0, 38, 0.5, 0)
						icon.Size = UDim2.new(0, 16, 0, 16)
						applyicon(icon, item.Icon, 48)
						textx = 62
					end
					local rightinset = pinned and 12 or 70

					local name = instance.textlabel(row)
					name.Name = "TaskName"
					name.BackgroundTransparency = 1
					name.FontFace = FONT_BOLD
					name.Position = UDim2.new(0, textx, 0, 6)
					name.Size = UDim2.new(1, -(textx + rightinset), 0, 15)
					name.Text = tostring(item.Title or id)
					name.TextColor3 = theme.Text
					name.TextSize = ts(12)
					name.TextTruncate = Enum.TextTruncate.AtEnd
					name.TextXAlignment = Enum.TextXAlignment.Left

					local statusicon = instance.imagelabel(row)
					statusicon.Name = "StatusIcon"
					statusicon.BackgroundTransparency = 1
					statusicon.Position = UDim2.new(0, textx, 0, 23)
					statusicon.Size = UDim2.new(0, 11, 0, 11)
					statusicon.Visible = false

					local status = instance.textlabel(row)
					status.Name = "TaskStatus"
					status.BackgroundTransparency = 1
					status.FontFace = FONT_MEDIUM
					status.Position = UDim2.new(0, textx, 0, 22)
					status.Size = UDim2.new(1, -(textx + rightinset), 0, 13)
					status.Text = tostring(item.Sub or "")
					status.TextColor3 = theme.Dim
					status.TextSize = ts(11)
					status.TextTruncate = Enum.TextTruncate.AtEnd
					status.TextXAlignment = Enum.TextXAlignment.Left

					local function arrow(iconname, x)
						local button = instance.textbutton(row)
						button.Name = "Move"
						button.AnchorPoint = Vector2.new(1, 0.5)
						button.AutoButtonColor = false
						button.Position = UDim2.new(1, x, 0.5, 0)
						button.Size = UDim2.new(0, 26, 0, 26)
						button.Text = ""
						local bg = roundbg(button, 6, theme.Inner)
						local img = instance.imagelabel(button)
						img.AnchorPoint = Vector2.new(0.5, 0.5)
						img.BackgroundTransparency = 1
						img.ImageColor3 = theme.Text
						img.Position = UDim2.new(0.5, 0, 0.5, 0)
						img.Size = UDim2.new(0, 14, 0, 14)
						applyicon(img, iconname, 48)
						local state = { enabled = true }
						button.MouseEnter:Connect(function()
							if state.enabled then
								bg.ImageColor3 = theme.InnerHover
							end
						end)
						button.MouseLeave:Connect(function()
							bg.ImageColor3 = theme.Inner
						end)
						function state.set(on)
							state.enabled = on
							button.Active = on
							bg.ImageColor3 = theme.Inner
							bg.ImageTransparency = on and rowalpha or 0.6
							img.ImageTransparency = on and 0 or 0.7
						end
						return button, state
					end

					local up, upstate, down, downstate
					if not pinned then
						up, upstate = arrow("chevron-up", -38)
						down, downstate = arrow("chevron-down", -8)
						up.MouseButton1Click:Connect(function()
							if upstate.enabled then
								pcall(pesseffect, up)
								move(id, -1)
							end
						end)
						down.MouseButton1Click:Connect(function()
							if downstate.enabled then
								pcall(pesseffect, down)
								move(id, 1)
							end
						end)
					end

					local record = { id = id, frame = row, tone = "off" }

					-- index among the visible rows; prev / nxt are the visible neighbours
					function record.setrank(index, prev, nxt)
						ranktext.Text = tostring(index)
						if upstate then
							upstate.set(prev ~= nil and not itemsbyid[prev].Pinned)
							downstate.set(nxt ~= nil and not itemsbyid[nxt].Pinned)
						end
					end

					function record.setstatus(text, tone)
						local look = tones[tone] or tones.off
						record.tone = tone
						if text == "" then
							text = tostring(item.Sub or "")
						end
						status.Text = text
						status.TextColor3 = look.color
						statusicon.Visible = text ~= ""
						statusicon.ImageColor3 = look.color
						applyicon(statusicon, look.icon, 48)
						local shift = statusicon.Visible and 15 or 0
						status.Position = UDim2.new(0, textx + shift, 0, 22)
						status.Size = UDim2.new(1, -(textx + shift + rightinset), 0, 13)
						stroke.Transparency = tone == "run" and 0.35 or 1
						name.TextColor3 = tone == "off" and theme.SubText or theme.Text
					end

					function record.flash()
						if record.tone == "run" then
							return
						end
						stroke.Transparency = 0.1
						sv.ts:Create(stroke, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }):Play()
					end

					return record
				end

				local function slotpos(index)
					return UDim2.new(0, 0, 0, (index - 1) * (rowheight + rowgap))
				end

				local emptyrow = instance.textlabel(holder)
				emptyrow.Name = "Empty"
				emptyrow.BackgroundTransparency = 1
				emptyrow.FontFace = FONT_MEDIUM
				emptyrow.Size = UDim2.new(1, 0, 0, rowheight)
				emptyrow.Text = tostring(listconfig.EmptyText or "Nothing here yet.")
				emptyrow.TextColor3 = theme.Dim
				emptyrow.TextSize = ts(12)
				emptyrow.TextWrapped = true
				emptyrow.Visible = false

				local function visibleorder()
					local out = {}
					for _, id in ipairs(listfunc.Value) do
						if rows[id] and not hiddenrows[id] then
							out[#out + 1] = id
						end
					end
					return out
				end

				local function layout(instant)
					elevate()
					local shown = visibleorder()
					for _, id in ipairs(listfunc.Value) do
						local record = rows[id]
						if record and hiddenrows[id] then
							record.frame.Visible = false
						end
					end
					for index, id in ipairs(shown) do
						local record = rows[id]
						local goal = slotpos(index)
						local wasvisible = record.frame.Visible
						record.frame.Visible = true
						if instant or not wasvisible then
							record.frame.Position = goal
						else
							sv.ts:Create(record.frame, tweenfast, { Position = goal }):Play()
						end
						record.setrank(index, shown[index - 1], shown[index + 1])
					end
					local count = #shown
					emptyrow.Visible = count == 0
					local body = count > 0 and (count * rowheight + (count - 1) * rowgap) or rowheight
					holder.Position = UDim2.new(0, 6, 0, bodytop)
					holder.Size = UDim2.new(1, -12, 0, body)
					container.Size = UDim2.new(1, 0, 0, bodytop + body + 8)
				end

				local function apply(order, instant, save, fire)
					elevate()
					listfunc.Value = sanitize(order)
					if save then
						config.data[configkey] = copyorder(listfunc.Value)
						config:queuesave()
					end
					layout(instant)
					if fire then
						local ok, err = pcall(listconfig.Callback, copyorder(listfunc.Value))
						if not ok then
							warn("PriorityList Callback error (" .. tostring(listconfig.Title) .. "):", err)
						end
					end
				end

				-- swaps with the nearest visible neighbour, so hidden rows keep their spot
				move = function(id, delta)
					local order = listfunc.Value
					local shown = visibleorder()
					local at = table.find(shown, id)
					local other = at and shown[at + delta]
					if not other or itemsbyid[other].Pinned or itemsbyid[id].Pinned then
						return
					end
					local index, target = table.find(order, id), table.find(order, other)
					if not index or not target then
						return
					end
					local neworder = copyorder(order)
					neworder[index], neworder[target] = neworder[target], neworder[index]
					apply(neworder, false, true, true)
					if rows[id] then
						rows[id].flash()
					end
				end

				for _, id in ipairs(itemorder) do
					rows[id] = buildrow(id)
				end

				local function relayout()
					if measure then
						bodytop = 30 + measure() + 8
					end
					layout(true)
				end
				if measure then
					watchwidth(container, relayout)
				end

				reset.MouseButton1Click:Connect(function()
					pcall(pesseffect, reset)
					listfunc:ResetValue()
				end)

				function listfunc:Set(order, instant)
					apply(order, instant, true, true)
				end

				function listfunc:LoadValue(order)
					self:Set(order, true)
				end

				function listfunc:ResetValue()
					self:Set(copyorder(hubdefault))
				end

				function listfunc:GetValue()
					return copyorder(self.Value)
				end

				-- Hide a row (its task is off) without losing its place in the order.
				function listfunc:SetVisible(id, visible)
					id = tostring(id)
					if not rows[id] then
						return
					end
					local hide = visible == false
					if (hiddenrows[id] == true) == hide then
						return
					end
					hiddenrows[id] = hide or nil
					layout(false)
				end

				-- Writes only when the text or tone changed, so a hub can call it every tick.
				function listfunc:SetStatus(id, text, tone)
					local record = rows[tostring(id)]
					if not record then
						return
					end
					text = tostring(text or "")
					tone = tones[tone] and tone or "off"
					local last = statuses[record.id]
					if last and last.text == text and last.tone == tone then
						return
					end
					statuses[record.id] = { text = text, tone = tone }
					elevate()
					record.setstatus(text, tone)
				end

				relayout()
				apply(savedpref(), true, true, true)

				countitem = countitem + 1
				yieldbuild()
				config.elements[configkey] = listfunc
				registerSearchItem(listconfig.Title, container)
				return listfunc
			end

			function items:AddFuseList(itemCfg)
				itemCfg = itemCfg or {}
				local list = items:AddActionList({
					Title = itemCfg.Title or "Players looking for a partner",
					EmptyText = itemCfg.EmptyText or "Nobody is broadcasting right now.",
					VisibleRows = itemCfg.VisibleRows or 5,
					ButtonWidth = itemCfg.ButtonWidth or 70,
					RowHeight = itemCfg.RowHeight or 46,
				})
				return list
			end

			function items:AddButton(buttonconfig)
				buttonconfig = buttonconfig or {}
				buttonconfig.Title = buttonconfig.Title or "Confirm"
				buttonconfig.Callback = buttonconfig.Callback or function() end
				buttonconfig.SubTitle = buttonconfig.SubTitle or nil
				buttonconfig.SubCallback = buttonconfig.SubCallback or function() end
				local lockable = tabgated or isdonatorelement(buttonconfig)
				local donatoronly = (tabgated and keygatedonator) or isdonatoronly(buttonconfig)
				local islocked = lockable and not tierallows(donatoronly)

				local function runcallback(fn, label)
					if islocked then
						return
					end
					elevate()
					if typeof(fn) == "function" then
						local ok, err = pcall(fn)
						if not ok then
							warn("Button Callback error (" .. tostring(label) .. "):", err)
						end
					end
				end

				local button = instance.frame(sectionadd)
				button.BorderSizePixel = 0
				button.Size = UDim2.new(1, 0, 0, 40)
				button.LayoutOrder = countitem
				roundbg(button, 4, theme.Row)

				local padding = 3
				local gap = 4
				local buttonfunc = {}
				local lock = nil
				local basey = 40
				local description = contenttext(buttonconfig)

				-- Variant: "secondary" (default), "primary" (accent fill) or "danger".
				local variant = tostring(buttonconfig.Variant or "secondary"):lower()
				local facecolor, facehover, facetext = theme.Inner, theme.InnerHover, theme.Text
				if variant == "primary" then
					facecolor = guiconfig.Color
					facehover = guiconfig.Color:Lerp(Color3.new(1, 1, 1), 0.12)
					facetext = theme.AccentText
				elseif variant == "danger" then
					facecolor = Color3.fromRGB(64, 30, 32)
					facehover = Color3.fromRGB(84, 36, 38)
					facetext = theme.Bad
				end

				local function setbase(height)
					basey = height
					if lock and lock:IsLocked() then
						lock:Relayout()
					else
						button.Size = UDim2.new(1, 0, 0, basey)
					end
				end

				-- A face's label is padded and truncated, so a long title ends in "..."
				-- inside the button instead of running into its neighbour.
				local function face(text)
					local b = instance.textbutton(button)
					b.FontFace = FONT_BOLD
					b.Text = tostring(text)
					b.TextSize = ts(12)
					b.TextColor3 = facetext
					b.TextTruncate = Enum.TextTruncate.AtEnd
					b.AutoButtonColor = false
					b.ZIndex = 10
					local pad = instance.uipadding(b)
					pad.PaddingLeft = UDim.new(0, 10)
					pad.PaddingRight = UDim.new(0, 10)
					hoverbg(b, roundbg(b, 4, facecolor), facecolor, facehover)
					b.MouseButton1Down:Connect(function()
						pcall(pesseffect, b)
					end)
					return b
				end

				local buttons = {}
				local mainbutton, subbutton

				if description and not buttonconfig.SubTitle then
					-- Row action: title + description on the left, chevron on the right,
					-- the whole row is the button.
					local title = instance.textlabel(button)
					title.Name = "ButtonTitle"
					title.BackgroundTransparency = 1
					title.FontFace = FONT_BOLD
					title.Text = tostring(buttonconfig.Title)
					title.TextColor3 = theme.Text
					title.TextSize = ts(13)
					title.TextTruncate = Enum.TextTruncate.AtEnd
					title.TextXAlignment = Enum.TextXAlignment.Left
					title.TextYAlignment = Enum.TextYAlignment.Top
					title.Position = UDim2.new(0, 10, 0, 9)
					title.Size = UDim2.new(1, -44, 0, 14)
					local _, measure = attachcontent(button, description, 10, 26, 44)

					local chevron = instance.imagelabel(button)
					chevron.Name = "ButtonIcon"
					chevron.AnchorPoint = Vector2.new(1, 0.5)
					chevron.BackgroundTransparency = 1
					chevron.ImageColor3 = theme.SubText
					chevron.Position = UDim2.new(1, -12, 0.5, 0)
					chevron.Size = UDim2.new(0, 16, 0, 16)
					applyicon(chevron, buttonconfig.Icon or "chevron-right", 48)

					mainbutton = instance.textbutton(button)
					mainbutton.Name = "RowButton"
					mainbutton.AutoButtonColor = false
					mainbutton.BackgroundTransparency = 1
					mainbutton.Size = UDim2.new(1, 0, 1, 0)
					mainbutton.Text = ""
					mainbutton.ZIndex = 10
					local rowbg = button:FindFirstChild("Bg")
					mainbutton.MouseEnter:Connect(function()
						if rowbg then
							rowbg.ImageColor3 = theme.ElementHover
						end
						chevron.ImageColor3 = theme.Text
					end)
					mainbutton.MouseLeave:Connect(function()
						if rowbg then
							rowbg.ImageColor3 = theme.Row
						end
						chevron.ImageColor3 = theme.SubText
					end)
					mainbutton.MouseButton1Down:Connect(function()
						pcall(pesseffect, chevron)
					end)
					buttons = { title, chevron }

					local function relayout()
						setbase(math.max(46, 26 + measure() + 10))
					end
					relayout()
					watchwidth(button, relayout)

					function buttonfunc:SetTitle(text)
						title.Text = tostring(text)
					end
				else
					-- Classic face buttons; a description, when given, sits above them.
					local measure = nil
					if description then
						local _, m = attachcontent(button, description, 10, 9, 10)
						measure = m
					end
					mainbutton = face(buttonconfig.Title)
					buttons[1] = mainbutton
					if buttonconfig.SubTitle then
						subbutton = face(buttonconfig.SubTitle)
						buttons[2] = subbutton
					end

					local function place()
						local top = measure and (9 + measure() + 6) or 5
						local height = 30
						if subbutton then
							mainbutton.Size = UDim2.new(0.5, -padding - gap, 0, height)
							mainbutton.Position = UDim2.new(0, padding, 0, top)
							subbutton.Size = UDim2.new(0.5, -padding - gap, 0, height)
							subbutton.Position = UDim2.new(0.5, gap, 0, top)
						else
							mainbutton.Size = UDim2.new(1, -padding * 2, 0, height)
							mainbutton.Position = UDim2.new(0, padding, 0, top)
						end
						setbase(top + height + 5)
					end
					place()
					if measure then
						watchwidth(button, place)
					end

					function buttonfunc:SetTitle(text)
						mainbutton.Text = tostring(text)
					end
					function buttonfunc:SetSubTitle(text)
						if subbutton then
							subbutton.Text = tostring(text)
						end
					end

					if subbutton then
						subbutton.MouseButton1Click:Connect(function()
							runcallback(buttonconfig.SubCallback, buttonconfig.SubTitle)
						end)
					end
				end

				mainbutton.MouseButton1Click:Connect(function()
					runcallback(buttonconfig.Callback, buttonconfig.Title)
				end)

				if lockable then
					lock = makelock(button, buttons, {
						DonatorOnly = donatoronly,
						GetBaseHeight = function()
							return basey
						end,
						OnLock = function()
							islocked = true
						end,
						OnUnlock = function()
							islocked = false
						end,
					}, islocked)
				end

				-- one search entry per row: two entries for the same row fought over
				-- its Visible and searching the SubTitle hid the whole row
				local searchname = tostring(buttonconfig.Title)
				if buttonconfig.SubTitle then
					searchname = searchname .. " / " .. tostring(buttonconfig.SubTitle)
				end
				registerSearchItem(searchname, button)
				countitem = countitem + 1
				yieldbuild()
				buttonfunc.Instance = button
				return buttonfunc
			end

			function items:AddToggle(toggleconfig)
				toggleconfig = toggleconfig or {}
				toggleconfig.Title = toggleconfig.Title or "Title"
				toggleconfig.Callback = toggleconfig.Callback or function() end

				local configkey = keyfor("Toggle_", toggleconfig)
				local hubdefault = toggleconfig.Default and true or false
				local function savedpref()
					local v = config.data[configkey]
					if v ~= nil then
						return v == true
					end
					if config.loaded then
						return false
					end
					return hubdefault
				end

				local lockable = tabgated or isdonatorelement(toggleconfig)
				local donatoronly = (tabgated and keygatedonator) or isdonatoronly(toggleconfig)
				local islocked = lockable and not tierallows(donatoronly)
				local togglefunc = { Value = false, DefaultValue = hubdefault }

				local toggle = templates.Toggle:Clone()
				toggle.LayoutOrder = countitem
				toggle.Parent = sectionadd

				local toggletitle = toggle.ToggleTitle
				toggletitle.Text = toggleconfig.Title

				local togglebutton = toggle.ToggleButton
				local featureframe2 = toggle.FeatureFrame
				local uistroke8 = featureframe2.UIStroke
				local togglecircle = featureframe2.ToggleCircle

				local togglerowbg = toggle:FindFirstChild("Bg")
				togglebutton.MouseEnter:Connect(function()
					if togglerowbg and not islocked then
						togglerowbg.ImageColor3 = theme.ElementHover
					end
				end)
				togglebutton.MouseLeave:Connect(function()
					if togglerowbg then
						togglerowbg.ImageColor3 = theme.Row
					end
				end)


				-- Keybind button left of the switch: press the bound key to flip this toggle.
				-- Turn it off for one toggle with Keybind = false (or KeybindEnabled = false),
				-- for the whole window with ToggleKeybinds = false in :Window. Keybind = Enum.KeyCode.X
				-- (or "X") sets the default key. Click the button, press a key; Esc cancels,
				-- Backspace clears. Touch devices have no keyboard, so no button there.
				local keyenabled = not isMobile
					and toggleconfig.Keybind ~= false
					and toggleconfig.KeybindEnabled ~= false
					and guiconfig.ToggleKeybinds ~= false
				local keybtn = nil
				local keystroke = nil
				local kbdefault = Chloex:ParseKeyCode(toggleconfig.Keybind)
				local kbvalue = kbdefault
				local kbkey = "ToggleKeybind_" .. configkey:sub(8)
				local kblistening = false
				local kbfunc = { Value = kbvalue, DefaultValue = kbdefault }
				local relayoutdesc = nil

				local function kbinset()
					if keybtn then
						return math.max(40, keybtn.AbsoluteSize.X) + 8
					end
					return 0
				end

				-- the title (and the description under it) leave room for the key button
				local function fittoggletitle()
					toggletitle.Size = UDim2.new(1, -(72 + kbinset()), 0, 14)
					if relayoutdesc then
						relayoutdesc()
					end
				end

				local setkblistening = function() end
				local applykb = function() end

				if keyenabled then
					guifunc.Keybinds = guifunc.Keybinds or { cancel = nil, blockuntil = 0 }
					local shared = guifunc.Keybinds

					keybtn = instance.textbutton(toggle)
					keybtn.Name = "KeyBtn"
					keybtn.FontFace = FONT_BOLD
					keybtn.AutoButtonColor = false
					keybtn.AnchorPoint = Vector2.new(1, 0.5)
					keybtn.Position = UDim2.new(1, -61, 0.5, 0)
					keybtn.Size = UDim2.new(0, 40, 0, 20)
					keybtn.AutomaticSize = Enum.AutomaticSize.X
					keybtn.BackgroundColor3 = theme.Field
					keybtn.BackgroundTransparency = 0
					keybtn.BorderSizePixel = 0
					keybtn.TextSize = ts(11)
					keybtn.TextColor3 = theme.Dim
					keybtn.TextTruncate = Enum.TextTruncate.AtEnd
					keybtn.Text = "None"
					instance.uicorner(keybtn).CornerRadius = UDim.new(0, 4)
					local keypadding = instance.uipadding(keybtn)
					keypadding.PaddingLeft = UDim.new(0, 6)
					keypadding.PaddingRight = UDim.new(0, 6)
					instance.uisizeconstraint(keybtn).MaxSize = Vector2.new(90, 20)
					keystroke = instance.uistroke(keybtn)
					keystroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					keystroke.Color = Color3.fromRGB(255, 255, 255)
					keystroke.Thickness = 1
					keystroke.Transparency = 0.9

					keybtn:GetPropertyChangedSignal("AbsoluteSize"):Connect(fittoggletitle)

					local function renderkb(instant)
						elevate()
						local textcolor, strokecolor, stroketransparency
						if kblistening then
							keybtn.Text = "..."
							textcolor = guiconfig.Color
							strokecolor = guiconfig.Color
							stroketransparency = 0
						else
							keybtn.Text = Chloex:KeyCodeLabel(kbvalue)
							textcolor = kbvalue ~= Enum.KeyCode.Unknown and theme.Text or theme.Dim
							strokecolor = Color3.fromRGB(255, 255, 255)
							stroketransparency = 0.9
						end
						if instant then
							keybtn.TextColor3 = textcolor
							keystroke.Color = strokecolor
							keystroke.Transparency = stroketransparency
						else
							sv.ts:Create(keybtn, TweenInfo.new(0.15), { TextColor3 = textcolor }):Play()
							sv.ts:Create(keystroke, TweenInfo.new(0.15), { Color = strokecolor, Transparency = stroketransparency }):Play()
						end
					end

					local function stopkb()
						setkblistening(false)
					end
					setkblistening = function(state)
						if state == kblistening then
							return
						end
						kblistening = state
						if state then
							if shared.cancel and shared.cancel ~= stopkb then
								shared.cancel()
							end
							shared.cancel = stopkb
						else
							if shared.cancel == stopkb then
								shared.cancel = nil
							end
							shared.blockuntil = os.clock() + 0.25
						end
						renderkb()
					end

					applykb = function(value, save)
						elevate()
						kbvalue = Chloex:ParseKeyCode(value)
						kbfunc.Value = kbvalue
						if save then
							config.data[kbkey] = kbvalue == Enum.KeyCode.Unknown and "None" or kbvalue.Name
							config:queuesave()
						end
						renderkb(true)
					end

					keybtn.Activated:Connect(function()
						if islocked then
							return
						end
						setkblistening(not kblistening)
					end)

					trackConnection(
						sv.uis.InputBegan:Connect(function(input, gpe)
							if kblistening then
								if input.UserInputType ~= Enum.UserInputType.Keyboard then
									return
								end
								if input.KeyCode == Enum.KeyCode.Escape then
									setkblistening(false)
									return
								end
								setkblistening(false)
								if input.KeyCode == Enum.KeyCode.Backspace then
									applykb(Enum.KeyCode.Unknown, true)
								else
									applykb(input.KeyCode, true)
								end
								return
							end
							if gpe or islocked or kbvalue == Enum.KeyCode.Unknown then
								return
							end
							if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= kbvalue then
								return
							end
							if shared.cancel or os.clock() < shared.blockuntil then
								return
							end
							togglefunc:Set(not togglefunc.Value)
						end),
						"togglekeybind." .. kbkey
					)

					-- registered as its own config element so the key is saved, loaded and reset
					-- together with the toggle (config:loadelements / config:reset walk this table)
					function kbfunc:Set(value)
						if islocked then
							return
						end
						setkblistening(false)
						applykb(value, true)
					end
					function kbfunc:LoadValue(value)
						self:Set(value)
					end
					function kbfunc:ResetValue()
						setkblistening(false)
						applykb(kbdefault, false)
					end
					function kbfunc:GetValue()
						return kbvalue
					end
					function kbfunc:IsLocked()
						return islocked
					end

					local savedkey = config.data[kbkey]
					applykb(savedkey ~= nil and savedkey or kbdefault, false)
					config.elements[kbkey] = kbfunc
				end

				function togglefunc:SetKeybind(value)
					if kbfunc.Set then
						kbfunc:Set(value)
					end
				end

				function togglefunc:GetKeybind()
					return kbvalue
				end

				fittoggletitle()

				local lock = nil
				local basey = 46
				local description = contenttext(toggleconfig)
				if description then
					toggletitle.Position = UDim2.new(0, 10, 0, 9)
					local _, measure = attachcontent(toggle, description, 10, 26, function()
						return 72 + kbinset()
					end)
					local function relayout()
						basey = math.max(46, 26 + measure() + 10)
						if lock and lock:IsLocked() then
							lock:Relayout()
						else
							toggle.Size = UDim2.new(1, 0, 0, basey)
						end
					end
					relayout()
					watchwidth(toggle, relayout)
					relayoutdesc = relayout
				end


				local function render(value, instant)
					elevate()
					local titleColor = theme.Text
					local circleColor = value and theme.AccentText or theme.Text
					local circlePosition = value and UDim2.new(0, 21, 0, 2) or UDim2.new(0, 2, 0, 2)
					local strokeColor = value and guiconfig.Color or Color3.fromRGB(255, 255, 255)
					local strokeTransparency = value and 0 or 0.9
					local backgroundColor = value and guiconfig.Color or theme.Field
					local backgroundTransparency = 0

					if instant then
						toggletitle.TextColor3 = titleColor
						togglecircle.Position = circlePosition
						togglecircle.BackgroundColor3 = circleColor
						uistroke8.Color = strokeColor
						uistroke8.Transparency = strokeTransparency
						featureframe2.BackgroundColor3 = backgroundColor
						featureframe2.BackgroundTransparency = backgroundTransparency
					else
						sv.ts:Create(toggletitle, TweenInfo.new(0.2), { TextColor3 = titleColor }):Play()
						sv.ts
							:Create(togglecircle, TweenInfo.new(0.2), {
								Position = circlePosition,
								BackgroundColor3 = circleColor,
							})
							:Play()
						sv.ts
							:Create(uistroke8, TweenInfo.new(0.2), {
								Color = strokeColor,
								Transparency = strokeTransparency,
							})
							:Play()
						sv.ts
							:Create(featureframe2, TweenInfo.new(0.2), {
								BackgroundColor3 = backgroundColor,
								BackgroundTransparency = backgroundTransparency,
							})
							:Play()
					end
				end

				local function apply(value, instant, save, fire)
					elevate()
					togglefunc.Value = value
					if save then
						config.data[configkey] = value
						config:queuesave()
					end
					if fire and typeof(toggleconfig.Callback) == "function" then
						elevate()
						local ok, err = pcall(toggleconfig.Callback, value)
						if not ok then
							warn("Toggle Callback error:", err)
						end
					end
					render(value, instant)
				end

				togglebutton.Activated:Connect(function()
					if islocked then
						return
					end
					togglefunc:Set(not togglefunc.Value)
				end)

				function togglefunc:Set(value, instant)
					if islocked then
						return
					end
					apply(value and true or false, instant, true, true)
				end

				function togglefunc:LoadValue(value)
					self:Set(value, true)
				end

				function togglefunc:ResetValue()
					self:Set(hubdefault)
				end

				function togglefunc:IsLocked()
					return islocked
				end

				if islocked then
					render(false, true)
				else
					apply(savedpref(), true, true, true)
				end

				if lockable then
					lock = makelock(toggle, keybtn and { featureframe2, keybtn } or { featureframe2 }, {
						DonatorOnly = donatoronly,
						GetBaseHeight = function()
							return basey
						end,
						Pin = function(state)
							featureframe2.Position = state and UDim2.new(1, -15, 0, basey / 2) or UDim2.new(1, -15, 0.5, 0)
							if keybtn then
								keybtn.Position = state and UDim2.new(1, -61, 0, basey / 2) or UDim2.new(1, -61, 0.5, 0)
							end
						end,
						OnLock = function(silent)
							islocked = true
							setkblistening(false)
							if togglefunc.Value then
								apply(false, true, false, not silent)
							end
						end,
						OnUnlock = function()
							islocked = false
							apply(savedpref(), true, true, true)
						end,
					}, islocked)
				end

				countitem = countitem + 1
				yieldbuild()
				config.elements[configkey] = togglefunc
				registerSearchItem(toggleconfig.Title, toggle)
				return togglefunc
			end

			function items:AddSlider(sliderconfig)
				sliderconfig = sliderconfig or {}
				sliderconfig.Title = sliderconfig.Title or sliderconfig.Name or "Slider"
				sliderconfig.Increment = tonumber(sliderconfig.Increment) or 1
				sliderconfig.Min = tonumber(sliderconfig.Min) or 0
				sliderconfig.Max = tonumber(sliderconfig.Max) or 100
				sliderconfig.Default = tonumber(sliderconfig.Default) or sliderconfig.Min
				sliderconfig.Callback = sliderconfig.Callback or function() end

				local configkey = keyfor("Slider_", sliderconfig)

				local function getprecision(step)
					local s = tostring(step)
					if s:find("e") or s:find("E") then
						s = string.format("%.12f", step):gsub("0+$", ""):gsub("%.$", "")
					end

					local dot = s:find("%.")
					return dot and (#s - dot) or 0
				end

				local precision = tonumber(sliderconfig.Precision) or getprecision(sliderconfig.Increment)

				local function roundtoincrement(value)
					local step = sliderconfig.Increment
					return math.floor((value / step) + 0.5) * step
				end

				local function formatnumber(value)
					value = tonumber(string.format("%." .. precision .. "f", value)) or 0

					if precision > 0 then
						return string.format("%." .. precision .. "f", value):gsub("0+$", ""):gsub("%.$", "")
					end

					return tostring(math.floor(value + 0.5))
				end

				local function clampvalue(value)
					value = tonumber(value) or sliderconfig.Min
					value = math.clamp(value, sliderconfig.Min, sliderconfig.Max)
					value = roundtoincrement(value)
					value = math.clamp(value, sliderconfig.Min, sliderconfig.Max)
					value = tonumber(string.format("%." .. precision .. "f", value)) or sliderconfig.Min
					return value
				end

				local hubdefault = clampvalue(sliderconfig.Default)
				local haspref = config.data[configkey] ~= nil
				local function savedpref()
					local v = tonumber(config.data[configkey])
					return v and clampvalue(v) or hubdefault
				end

				local lockable = tabgated or isdonatorelement(sliderconfig)
				local donatoronly = (tabgated and keygatedonator) or isdonatoronly(sliderconfig)
				local islocked = lockable and not tierallows(donatoronly)
				local sliderfunc = {
					Value = islocked and hubdefault or savedpref(),
					DefaultValue = hubdefault,
				}

				local slider = templates.Slider:Clone()
				slider.LayoutOrder = countitem
				slider.Parent = sectionadd

				local slidertitle = slider.SliderTitle
				slidertitle.Text = sliderconfig.Title

				local inputholder = slider.SliderInputHolder
				local textbox = inputholder.SliderInput

				local sliderframe = slider.SliderBar
				local sliderfill = sliderframe.SliderFill
				local slidercircle = sliderframe.SliderCircle
				local circlestroke = slidercircle.UIStroke
				local bubble = sliderframe.ValueBubble
				local bubbletext = bubble.BubbleText

				local lock = nil
				local basey = 58
				local description = contenttext(sliderconfig)
				if description then
					local _, measure = attachcontent(slider, description, 10, 31, 20)
					local function relayout()
						local bary = 31 + measure() + 8
						sliderframe.Position = UDim2.new(0, 10, 0, bary)
						basey = bary + 19
						if lock and lock:IsLocked() then
							lock:Relayout()
						else
							slider.Size = UDim2.new(1, 0, 0, basey)
						end
					end
					relayout()
					watchwidth(slider, relayout)
				end

				local dragging = false
				local setting = false

				local function getpercent(value)
					if sliderconfig.Max == sliderconfig.Min then
						return 0
					end

					return math.clamp((value - sliderconfig.Min) / (sliderconfig.Max - sliderconfig.Min), 0, 1)
				end

				local function updatebubble(percent, value)
					bubble.Position = UDim2.new(percent, 0, 0, -10)
					bubbletext.Text = tostring(value)
				end

				local function showbubble()
					bubble.Visible = true

					sv.ts
						:Create(slidercircle, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = UDim2.new(0, 14, 0, 14),
						})
						:Play()

					sv.ts
						:Create(bubble, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							BackgroundTransparency = 0.15,
							Size = UDim2.new(0, 48, 0, 22),
						})
						:Play()
				end

				local function hidebubble()
					sv.ts
						:Create(slidercircle, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = UDim2.new(0, 12, 0, 12),
						})
						:Play()

					sv.ts
						:Create(bubble, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = UDim2.new(0, 48, 0, 22),
						})
						:Play()

					task.delay(0.15, function()
						if not dragging then
							bubble.Visible = false
						end
					end)
				end

				local function apply(value, fire, save)
					elevate()
					value = clampvalue(value)

					sliderfunc.Value = value
					if save then
						config.data[configkey] = value
						config:queuesave()
					end

					local percent = getpercent(value)
					local formatted = formatnumber(value)

					setting = true
					textbox.Text = formatted
					setting = false

					updatebubble(percent, formatted)

					sv.ts
						:Create(sliderfill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = UDim2.new(percent, 0, 1, 0),
						})
						:Play()

					sv.ts
						:Create(slidercircle, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Position = UDim2.new(percent, 0, 0.5, 0),
						})
						:Play()

					if fire and typeof(sliderconfig.Callback) == "function" then
						elevate()
						local ok, err = pcall(sliderconfig.Callback, value)
						if not ok then
							warn("Slider Callback error:", err)
						end
					end
				end

				local function setfromx(x)
					local percent = math.clamp((x - sliderframe.AbsolutePosition.X) / sliderframe.AbsoluteSize.X, 0, 1)
					local value = sliderconfig.Min + ((sliderconfig.Max - sliderconfig.Min) * percent)

					sliderfunc:Set(value)
				end

				function sliderfunc:Set(value, nocallback, force)
					if islocked and not force then
						return
					end
					apply(value, not nocallback, not islocked)
				end

				-- config load: unlike Set(v, true) this does fire the callback,
				-- otherwise a loaded config moves the knob but not the hub
				function sliderfunc:LoadValue(value)
					self:Set(value, false)
				end

				function sliderfunc:ResetValue()
					self:Set(hubdefault)
				end

				local function startdrag(input)
					if islocked then
						return
					end
					if
						input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch
					then
						dragging = true
						showbubble()
						setfromx(input.Position.X)
						sliderDrag.active = {
							setfromx = setfromx,
							hidebubble = function()
								dragging = false
								hidebubble()
							end,
						}
					end
				end

				sliderframe.InputBegan:Connect(startdrag)
				slidercircle.InputBegan:Connect(startdrag)

				textbox.Focused:Connect(function()
					showbubble()
				end)

				textbox.FocusLost:Connect(function()
					if setting then
						return
					end

					local text = textbox.Text:gsub(",", ".")
					local value = tonumber(text)

					if value and not islocked then
						sliderfunc:Set(value)
					else
						textbox.Text = formatnumber(sliderfunc.Value)
					end

					hidebubble()
				end)

				-- a value that came from a saved config reaches the hub at build too
				apply(sliderfunc.Value, (not islocked) and haspref, not islocked)

				if lockable then
					lock = makelock(slider, { sliderframe, inputholder }, {
						DonatorOnly = donatoronly,
						GetBaseHeight = function()
							return basey
						end,
						OnLock = function(silent)
							islocked = true
							if sliderfunc.Value ~= hubdefault then
								apply(hubdefault, not silent, false)
							end
						end,
						OnUnlock = function()
							islocked = false
							apply(savedpref(), true, true)
						end,
					}, islocked)
				end

				function sliderfunc:IsLocked()
					return islocked
				end

				countitem = countitem + 1
				yieldbuild()
				config.elements[configkey] = sliderfunc
				registerSearchItem(sliderconfig.Title, slider)
				return sliderfunc
			end

			function items:AddInput(inputconfig)
				inputconfig = inputconfig or {}
				inputconfig.Title = inputconfig.Title or "Title"
				inputconfig.Placeholder = inputconfig.Placeholder or "Write your input here"
				inputconfig.Callback = inputconfig.Callback or function() end

				local configkey = keyfor("Input_", inputconfig)
				local hubdefault = tostring(inputconfig.Default or "")
				local function savedpref()
					local v = config.data[configkey]
					if v ~= nil then
						return tostring(v)
					end
					if config.loaded and not metakeys[configkey] then
						return ""
					end
					return hubdefault
				end

				local lockable = tabgated or isdonatorelement(inputconfig)
				local donatoronly = (tabgated and keygatedonator) or isdonatoronly(inputconfig)
				local islocked = lockable and not tierallows(donatoronly)
				local inputfunc = { Value = islocked and hubdefault or savedpref(), DefaultValue = hubdefault }

				local inputcontainer = instance.frame(sectionadd)
				inputcontainer.BorderSizePixel = 0
				inputcontainer.LayoutOrder = countitem
				inputcontainer.Size = UDim2.new(1, 0, 0, 58)
				roundbg(inputcontainer, 4, theme.Row)

				local inputtitle = instance.textlabel(inputcontainer)
				inputtitle.FontFace = FONT_BOLD
				inputtitle.Text = inputconfig.Title
				inputtitle.TextSize = ts(13)
				inputtitle.TextColor3 = theme.Text
				inputtitle.TextTruncate = Enum.TextTruncate.AtEnd
				inputtitle.TextXAlignment = Enum.TextXAlignment.Left
				inputtitle.BackgroundTransparency = 1
				inputtitle.Position = UDim2.new(0, 10, 0, 6)
				inputtitle.Size = UDim2.new(1, -20, 0, 14)

				local inputtextbox = instance.textbox(inputcontainer)
				inputtextbox.FontFace = FONT_MEDIUM
				inputtextbox.PlaceholderText = inputconfig.Placeholder
				inputtextbox.PlaceholderColor3 = theme.Dim
				inputtextbox.Text = inputfunc.Value
				inputtextbox.TextSize = ts(12)
				inputtextbox.TextColor3 = theme.Text
				inputtextbox.BackgroundColor3 = theme.Field
				inputtextbox.BackgroundTransparency = 0
				inputtextbox.TextXAlignment = Enum.TextXAlignment.Left
				inputtextbox.ClearTextOnFocus = false
				inputtextbox.Position = UDim2.new(0, 10, 0, 26)
				inputtextbox.Size = UDim2.new(1, -20, 0, 24)
				inputtextbox.ClipsDescendants = true
				inputtextbox.TextTruncate = Enum.TextTruncate.AtEnd
				instance.uicorner(inputtextbox).CornerRadius = UDim.new(0, 4)

				-- Focus ring: the field the keyboard is typing into is obvious.
				local inputfocus = instance.uistroke(inputtextbox)
				inputfocus.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				inputfocus.Color = guiconfig.Color
				inputfocus.Thickness = 1
				inputfocus.Transparency = 1
				inputtextbox.Focused:Connect(function()
					sv.ts:Create(inputfocus, TweenInfo.new(0.12), { Transparency = 0.3 }):Play()
				end)
				inputtextbox.FocusLost:Connect(function()
					sv.ts:Create(inputfocus, TweenInfo.new(0.12), { Transparency = 1 }):Play()
				end)

				local padding = instance.uipadding(inputtextbox)
				padding.PaddingLeft = UDim.new(0, 8)
				padding.PaddingRight = UDim.new(0, 8)

				local lock = nil
				local basey = 58
				local description = contenttext(inputconfig)
				if description then
					local _, measure = attachcontent(inputcontainer, description, 10, 23, 10)
					local function relayout()
						local boxy = 23 + measure() + 5
						inputtextbox.Position = UDim2.new(0, 10, 0, boxy)
						basey = boxy + 32
						if lock and lock:IsLocked() then
							lock:Relayout()
						else
							inputcontainer.Size = UDim2.new(1, 0, 0, basey)
						end
					end
					relayout()
					watchwidth(inputcontainer, relayout)
				end

				inputtextbox.Focused:Connect(function()
					inputtextbox.CursorPosition = #inputtextbox.Text + 1
				end)

				-- suppress: a programmatic Text change (lock, load) must not be
				-- recorded as the player's own typing
				local suppress = false
				local function applyinput(value, fire, save)
					elevate()
					value = tostring(value == nil and "" or value)
					inputfunc.Value = value
					suppress = true
					inputtextbox.Text = value
					suppress = false
					if save then
						config.data[configkey] = value
						config:queuesave()
					end
					if fire and typeof(inputconfig.Callback) == "function" then
						elevate()
						local ok, err = pcall(inputconfig.Callback, value)
						if not ok then
							warn("Input Callback error:", err)
						end
					end
				end

				function inputfunc:Set(value)
					if islocked then
						return
					end
					applyinput(value, true, true)
				end

				function inputfunc:LoadValue(value)
					self:Set(value)
				end

				function inputfunc:ResetValue()
					self:Set(hubdefault)
				end

				local typedseq = 0
				inputtextbox:GetPropertyChangedSignal("Text"):Connect(function()
					if suppress or islocked then
						return
					end
					inputfunc.Value = inputtextbox.Text
					config.data[configkey] = inputtextbox.Text
					config:queuesave()
					typedseq = typedseq + 1
					local seq = typedseq
					task.delay(0.35, function()
						if seq == typedseq and not islocked and inputtextbox.Text == inputfunc.Value then
							applyinput(inputfunc.Value, true, true)
						end
					end)
				end)

				inputtextbox.FocusLost:Connect(function()
					inputfunc:Set(inputtextbox.Text)
				end)

				if islocked then
					applyinput(hubdefault, false, false)
				else
					applyinput(inputfunc.Value, true, true)
				end

				if lockable then
					lock = makelock(inputcontainer, { inputtextbox }, {
						DonatorOnly = donatoronly,
						GetBaseHeight = function()
							return basey
						end,
						OnLock = function(silent)
							islocked = true
							if inputfunc.Value ~= hubdefault then
								applyinput(hubdefault, not silent, false)
							end
						end,
						OnUnlock = function()
							islocked = false
							applyinput(savedpref(), true, true)
						end,
					}, islocked)
				end

				function inputfunc:IsLocked()
					return islocked
				end

				countitem = countitem + 1
				yieldbuild()
				config.elements[configkey] = inputfunc
				registerSearchItem(inputconfig.Title, inputcontainer)
				return inputfunc
			end


			-- Color picker row: swatch button opens a modal (SV box + hue slider +
			-- hex / RGB fields, Apply / Cancel). Value is a Color3, saved as {R,G,B}.
			-- Ported from BolongUI. Callback(color) runs on Apply, on Set and at build.
			function items:AddColorPicker(colorconfig)
				colorconfig = colorconfig or {}
				colorconfig.Title = colorconfig.Title or colorconfig.Name or "Color"
				colorconfig.Callback = colorconfig.Callback or function() end

				local function tocolor(v, fallback)
					if typeof(v) == "Color3" then
						return v
					elseif type(v) == "table" then
						return Color3.fromRGB(
							math.clamp(tonumber(v.R or v.r or v[1]) or 255, 0, 255),
							math.clamp(tonumber(v.G or v.g or v[2]) or 255, 0, 255),
							math.clamp(tonumber(v.B or v.b or v[3]) or 255, 0, 255)
						)
					elseif type(v) == "string" then
						local hex = v:gsub("#", ""):gsub("%s", "")
						if #hex == 6 and hex:match("^%x+$") then
							return Color3.fromRGB(
								tonumber(hex:sub(1, 2), 16),
								tonumber(hex:sub(3, 4), 16),
								tonumber(hex:sub(5, 6), 16)
							)
						end
					end
					return fallback
				end
				local function pack(c)
					return {
						R = math.floor(c.R * 255 + 0.5),
						G = math.floor(c.G * 255 + 0.5),
						B = math.floor(c.B * 255 + 0.5),
					}
				end

				local configkey = keyfor("ColorPicker_", colorconfig)
				local hubdefault = tocolor(colorconfig.Default, Color3.fromRGB(255, 255, 255))
				local function savedpref()
					local v = config.data[configkey]
					if v ~= nil then
						return tocolor(v, hubdefault)
					end
					return hubdefault
				end

				local lockable = tabgated or isdonatorelement(colorconfig)
				local donatoronly = (tabgated and keygatedonator) or isdonatoronly(colorconfig)
				local islocked = lockable and not tierallows(donatoronly)
				local colorfunc = { Value = islocked and hubdefault or savedpref(), DefaultValue = hubdefault }

				local colorcontainer = instance.frame(sectionadd)
				colorcontainer.BorderSizePixel = 0
				colorcontainer.LayoutOrder = countitem
				colorcontainer.Size = UDim2.new(1, 0, 0, 46)
				roundbg(colorcontainer, 4, theme.Row)

				local colortitle = instance.textlabel(colorcontainer)
				colortitle.FontFace = FONT_BOLD
				colortitle.Text = colorconfig.Title
				colortitle.TextSize = ts(13)
				colortitle.TextColor3 = theme.Text
				colortitle.TextTruncate = Enum.TextTruncate.AtEnd
				colortitle.TextXAlignment = Enum.TextXAlignment.Left
				colortitle.BackgroundTransparency = 1
				colortitle.Position = UDim2.new(0, 10, 0, 16)
				colortitle.Size = UDim2.new(1, -60, 0, 14)

				local swatch = instance.textbutton(colorcontainer)
				swatch.Text = ""
				swatch.AutoButtonColor = false
				swatch.AnchorPoint = Vector2.new(1, 0)
				swatch.Position = UDim2.new(1, -10, 0, 14)
				swatch.Size = UDim2.new(0, 30, 0, 18)
				swatch.BackgroundTransparency = 0
				swatch.BackgroundColor3 = colorfunc.Value
				swatch.BorderSizePixel = 0
				instance.uicorner(swatch).CornerRadius = UDim.new(0, 4)
				local swatchstroke = instance.uistroke(swatch)
				swatchstroke.Color = theme.Stroke
				swatchstroke.Thickness = 1
				swatchstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

				local lock = nil
				local basey = 46
				local description = contenttext(colorconfig)
				if description then
					local _, measure = attachcontent(colorcontainer, description, 10, 24, 50)
					local function relayout()
						colortitle.Position = UDim2.new(0, 10, 0, 8)
						swatch.Position = UDim2.new(1, -10, 0, 8)
						basey = math.max(46, 24 + measure() + 8)
						if lock and lock:IsLocked() then
							lock:Relayout()
						else
							colorcontainer.Size = UDim2.new(1, 0, 0, basey)
						end
					end
					relayout()
					watchwidth(colorcontainer, relayout)
				end

				local function applycolor(color, fire, save)
					elevate()
					colorfunc.Value = color
					swatch.BackgroundColor3 = color
					if save then
						config.data[configkey] = pack(color)
						config:queuesave()
					end
					if fire and typeof(colorconfig.Callback) == "function" then
						local ok, err = pcall(colorconfig.Callback, color)
						if not ok then
							warn("ColorPicker Callback error:", err)
						end
					end
				end

				function colorfunc:Set(color)
					if islocked then
						return
					end
					applycolor(tocolor(color, colorfunc.Value), true, true)
				end

				function colorfunc:LoadValue(value)
					self:Set(value)
				end

				function colorfunc:ResetValue()
					self:Set(hubdefault)
				end

				function colorfunc:GetValue()
					return colorfunc.Value
				end

				local function openpalette()
					if islocked or dropshadowholder:FindFirstChild("ColorOverlay") then
						return
					end
					local edith, edits, editv = colorfunc.Value:ToHSV()
					local editcolor = colorfunc.Value
					local svdragging, huedragging = false, false
					local conns = {}

					local overlay = instance.frame(dropshadowholder)
					overlay.Name = "ColorOverlay"
					overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
					overlay.BackgroundTransparency = 0.45
					overlay.BorderSizePixel = 0
					overlay.Size = UDim2.new(1, 0, 1, 0)
					overlay.ZIndex = 60
					pcall(function()
						instance.uicorner(overlay).CornerRadius = UDim.new(0, 8)
					end)

					local overlayclose = instance.textbutton(overlay)
					overlayclose.Text = ""
					overlayclose.BackgroundTransparency = 1
					overlayclose.Size = UDim2.new(1, 0, 1, 0)
					overlayclose.ZIndex = 60

					local dw, dh = 262, 236
					local dialog = instance.frame(overlay)
					dialog.AnchorPoint = Vector2.new(0.5, 0.5)
					dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
					dialog.Size = UDim2.new(0, dw, 0, dh)
					dialog.BackgroundColor3 = theme.Card
					dialog.BackgroundTransparency = 0
					dialog.BorderSizePixel = 0
					dialog.ZIndex = 61
					instance.uicorner(dialog).CornerRadius = UDim.new(0, 8)
					local dstroke = instance.uistroke(dialog)
					dstroke.Color = theme.Stroke
					dstroke.Thickness = 1

					-- shrink the dialog when the window is smaller than it
					local dscale = Instance.new("UIScale")
					dscale.Parent = dialog
					local function fit()
						local h = overlay.AbsoluteSize.Y
						local w = overlay.AbsoluteSize.X
						if h > 1 and w > 1 then
							dscale.Scale = math.clamp(math.min((h - 12) / dh, (w - 12) / dw), 0.5, 1)
						end
					end
					fit()
					table.insert(conns, overlay:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit))

					local dtitle = instance.textlabel(dialog)
					dtitle.FontFace = FONT_BOLD
					dtitle.Text = colorconfig.Title
					dtitle.TextSize = ts(13)
					dtitle.TextColor3 = theme.Text
					dtitle.TextTruncate = Enum.TextTruncate.AtEnd
					dtitle.TextXAlignment = Enum.TextXAlignment.Left
					dtitle.BackgroundTransparency = 1
					dtitle.Position = UDim2.new(0, 12, 0, 8)
					dtitle.Size = UDim2.new(1, -24, 0, 16)
					dtitle.ZIndex = 62

					local svbox = instance.frame(dialog)
					svbox.BackgroundTransparency = 0
					svbox.BackgroundColor3 = Color3.fromHSV(edith, 1, 1)
					svbox.BorderSizePixel = 0
					svbox.Position = UDim2.new(0, 12, 0, 30)
					svbox.Size = UDim2.new(0, 196, 0, 100)
					svbox.ZIndex = 62
					instance.uicorner(svbox).CornerRadius = UDim.new(0, 6)

					local white = instance.frame(svbox)
					white.BackgroundTransparency = 0
					white.BackgroundColor3 = Color3.new(1, 1, 1)
					white.BorderSizePixel = 0
					white.Size = UDim2.new(1, 0, 1, 0)
					white.ZIndex = 62
					instance.uicorner(white).CornerRadius = UDim.new(0, 6)
					local wg = instance.uigradient(white)
					wg.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1),
					})

					local black = instance.frame(svbox)
					black.BackgroundTransparency = 0
					black.BackgroundColor3 = Color3.new(0, 0, 0)
					black.BorderSizePixel = 0
					black.Size = UDim2.new(1, 0, 1, 0)
					black.ZIndex = 62
					instance.uicorner(black).CornerRadius = UDim.new(0, 6)
					local bg = instance.uigradient(black)
					bg.Rotation = 90
					bg.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(1, 0),
					})

					local svcursor = instance.frame(svbox)
					svcursor.AnchorPoint = Vector2.new(0.5, 0.5)
					svcursor.BackgroundTransparency = 0
					svcursor.BackgroundColor3 = Color3.new(1, 1, 1)
					svcursor.BorderSizePixel = 0
					svcursor.Size = UDim2.new(0, 12, 0, 12)
					svcursor.ZIndex = 63
					instance.uicorner(svcursor).CornerRadius = UDim.new(1, 0)
					local svcs = instance.uistroke(svcursor)
					svcs.Color = guiconfig.Color
					svcs.Thickness = 2

					local svhit = instance.textbutton(svbox)
					svhit.Text = ""
					svhit.BackgroundTransparency = 1
					svhit.Size = UDim2.new(1, 0, 1, 0)
					svhit.ZIndex = 64

					local hueslider = instance.frame(dialog)
					hueslider.BackgroundTransparency = 0
					hueslider.BackgroundColor3 = Color3.new(1, 1, 1)
					hueslider.BorderSizePixel = 0
					hueslider.Position = UDim2.new(0, 220, 0, 30)
					hueslider.Size = UDim2.new(0, 18, 0, 100)
					hueslider.ZIndex = 62
					instance.uicorner(hueslider).CornerRadius = UDim.new(0, 9)
					local hg = instance.uigradient(hueslider)
					hg.Rotation = 90
					hg.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
						ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
						ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
						ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
						ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
						ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
					})

					local huecursor = instance.frame(hueslider)
					huecursor.AnchorPoint = Vector2.new(0.5, 0.5)
					huecursor.BackgroundTransparency = 0
					huecursor.BackgroundColor3 = Color3.new(1, 1, 1)
					huecursor.BorderSizePixel = 0
					huecursor.Size = UDim2.new(0, 24, 0, 8)
					huecursor.ZIndex = 63
					instance.uicorner(huecursor).CornerRadius = UDim.new(1, 0)
					local hcs = instance.uistroke(huecursor)
					hcs.Color = Color3.fromRGB(20, 20, 20)
					hcs.Thickness = 2

					local huehit = instance.textbutton(hueslider)
					huehit.Text = ""
					huehit.BackgroundTransparency = 1
					huehit.Size = UDim2.new(1, 0, 1, 0)
					huehit.ZIndex = 64

					local function makefield(x, y, w, label)
						local field = instance.frame(dialog)
						field.BackgroundTransparency = 0
						field.BackgroundColor3 = theme.Field
						field.BorderSizePixel = 0
						field.Position = UDim2.new(0, x, 0, y)
						field.Size = UDim2.new(0, w, 0, 24)
						field.ZIndex = 62
						instance.uicorner(field).CornerRadius = UDim.new(0, 4)

						local box = instance.textbox(field)
						box.FontFace = FONT_MEDIUM
						box.Text = ""
						box.TextSize = ts(12)
						box.TextColor3 = theme.Text
						box.TextXAlignment = Enum.TextXAlignment.Left
						box.ClearTextOnFocus = false
						box.BackgroundTransparency = 1
						box.Position = UDim2.new(0, 8, 0, 0)
						box.Size = UDim2.new(0.62, -8, 1, 0)
						box.ZIndex = 63

						local lab = instance.textlabel(field)
						lab.FontFace = FONT_MEDIUM
						lab.Text = label
						lab.TextSize = ts(11)
						lab.TextColor3 = theme.Dim
						lab.TextXAlignment = Enum.TextXAlignment.Right
						lab.BackgroundTransparency = 1
						lab.Position = UDim2.new(0.62, 0, 0, 0)
						lab.Size = UDim2.new(0.38, -8, 1, 0)
						lab.ZIndex = 63
						return box
					end

					local preview = instance.frame(dialog)
					preview.BackgroundTransparency = 0
					preview.BackgroundColor3 = editcolor
					preview.BorderSizePixel = 0
					preview.Position = UDim2.new(0, 12, 0, 138)
					preview.Size = UDim2.new(0, 24, 0, 24)
					preview.ZIndex = 62
					instance.uicorner(preview).CornerRadius = UDim.new(0, 4)
					local pstroke = instance.uistroke(preview)
					pstroke.Color = theme.Stroke
					pstroke.Thickness = 1

					local hexbox = makefield(42, 138, 196, "Hex")
					local rbox = makefield(12, 168, 74, "R")
					local gbox = makefield(94, 168, 74, "G")
					local bbox = makefield(176, 168, 62, "B")

					local function makebutton(x, text, primary)
						local btn = instance.textbutton(dialog)
						btn.FontFace = FONT_BOLD
						btn.Text = text
						btn.TextSize = ts(12)
						btn.AutoButtonColor = false
						btn.TextColor3 = primary and theme.AccentText or theme.SubText
						btn.Position = UDim2.new(0, x, 0, 200)
						btn.Size = UDim2.new(0, 118, 0, 28)
						btn.ZIndex = 62
						local normal = primary and guiconfig.Color or theme.Inner
						local hover = primary and guiconfig.Color:Lerp(Color3.new(1, 1, 1), 0.12) or theme.InnerHover
						btn.BackgroundTransparency = 0
						btn.BackgroundColor3 = normal
						btn.BorderSizePixel = 0
						instance.uicorner(btn).CornerRadius = UDim.new(0, 4)
						btn.MouseEnter:Connect(function()
							btn.BackgroundColor3 = hover
						end)
						btn.MouseLeave:Connect(function()
							btn.BackgroundColor3 = normal
						end)
						return btn
					end
					local cancelbtn = makebutton(12, "Cancel", false)
					local applybtn = makebutton(132, "Apply", true)

					local updating = false
					local function refresh()
						editcolor = Color3.fromHSV(edith, edits, editv)
						svbox.BackgroundColor3 = Color3.fromHSV(edith, 1, 1)
						svcursor.Position = UDim2.new(edits, 0, 1 - editv, 0)
						huecursor.Position = UDim2.new(0.5, 0, edith, 0)
						preview.BackgroundColor3 = editcolor
						local r = math.floor(editcolor.R * 255 + 0.5)
						local g = math.floor(editcolor.G * 255 + 0.5)
						local b = math.floor(editcolor.B * 255 + 0.5)
						updating = true
						hexbox.Text = string.format("#%02X%02X%02X", r, g, b)
						rbox.Text = tostring(r)
						gbox.Text = tostring(g)
						bbox.Text = tostring(b)
						updating = false
					end

					local function svfrom(pos)
						edits = math.clamp((pos.X - svbox.AbsolutePosition.X) / math.max(svbox.AbsoluteSize.X, 1), 0, 1)
						editv = 1 - math.clamp((pos.Y - svbox.AbsolutePosition.Y) / math.max(svbox.AbsoluteSize.Y, 1), 0, 1)
						refresh()
					end
					local function huefrom(pos)
						edith = math.clamp((pos.Y - hueslider.AbsolutePosition.Y) / math.max(hueslider.AbsoluteSize.Y, 1), 0, 1)
						refresh()
					end
					local function ispointer(input)
						return input.UserInputType == Enum.UserInputType.MouseButton1
							or input.UserInputType == Enum.UserInputType.Touch
					end

					table.insert(conns, svhit.InputBegan:Connect(function(input)
						if ispointer(input) then
							svdragging = true
							svfrom(input.Position)
						end
					end))
					table.insert(conns, huehit.InputBegan:Connect(function(input)
						if ispointer(input) then
							huedragging = true
							huefrom(input.Position)
						end
					end))
					table.insert(conns, sv.uis.InputChanged:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement
							or input.UserInputType == Enum.UserInputType.Touch then
							if svdragging then
								svfrom(input.Position)
							end
							if huedragging then
								huefrom(input.Position)
							end
						end
					end))
					table.insert(conns, sv.uis.InputEnded:Connect(function(input)
						if ispointer(input) then
							svdragging = false
							huedragging = false
						end
					end))

					hexbox.FocusLost:Connect(function()
						if updating then
							return
						end
						local c = tocolor(hexbox.Text, nil)
						if c then
							edith, edits, editv = c:ToHSV()
						end
						refresh()
					end)
					local function rgbedit()
						if updating then
							return
						end
						local function ch(box, cur)
							return math.clamp(math.floor(tonumber(box.Text) or cur), 0, 255)
						end
						local r = ch(rbox, math.floor(editcolor.R * 255 + 0.5))
						local g = ch(gbox, math.floor(editcolor.G * 255 + 0.5))
						local b = ch(bbox, math.floor(editcolor.B * 255 + 0.5))
						edith, edits, editv = Color3.fromRGB(r, g, b):ToHSV()
						refresh()
					end
					rbox.FocusLost:Connect(rgbedit)
					gbox.FocusLost:Connect(rgbedit)
					bbox.FocusLost:Connect(rgbedit)

					local function close()
						for _, c in ipairs(conns) do
							pcall(function()
								c:Disconnect()
							end)
						end
						overlay:Destroy()
					end
					cancelbtn.MouseButton1Click:Connect(close)
					overlayclose.MouseButton1Click:Connect(close)
					applybtn.MouseButton1Click:Connect(function()
						if not islocked then
							applycolor(editcolor, true, true)
						end
						close()
					end)

					for _, c in ipairs(conns) do
						trackConnection(c, "ColorPicker")
					end
					refresh()
				end

				swatch.MouseButton1Click:Connect(openpalette)

				if islocked then
					applycolor(hubdefault, false, false)
				else
					applycolor(colorfunc.Value, true, true)
				end

				if lockable then
					lock = makelock(colorcontainer, { swatch }, {
						DonatorOnly = donatoronly,
						GetBaseHeight = function()
							return basey
						end,
						OnLock = function(silent)
							islocked = true
							if colorfunc.Value ~= hubdefault then
								applycolor(hubdefault, not silent, false)
							end
						end,
						OnUnlock = function()
							islocked = false
							applycolor(savedpref(), true, true)
						end,
					}, islocked)
				end

				function colorfunc:IsLocked()
					return islocked
				end

				countitem = countitem + 1
				yieldbuild()
				config.elements[configkey] = colorfunc
				registerSearchItem(colorconfig.Title, colorcontainer)
				return colorfunc
			end

			-- Keybind row: click the button, press a key to bind it (Esc cancels, Backspace
			-- clears). Callback(keycode) runs when the bound key is pressed; Changed(keycode)
			-- runs when the binding changes (also once at build and on config load).
			function items:AddKeybind(keybindconfig)
				keybindconfig = keybindconfig or {}
				keybindconfig.Title = keybindconfig.Title or keybindconfig.Name or "Keybind"
				keybindconfig.Callback = keybindconfig.Callback or function() end
				local changedcallback = keybindconfig.Changed or keybindconfig.ChangedCallback or keybindconfig.OnChanged

				local hubdefault = Chloex:ParseKeyCode(keybindconfig.Default)

				-- A touch device has no keyboard: hand back an inert element so scripts that
				-- call :Set / :GetValue keep working, and draw nothing.
				if isMobile then
					local inert = { Value = hubdefault, DefaultValue = hubdefault }
					function inert:Set() end
					function inert:LoadValue() end
					function inert:ResetValue() end
					function inert:IsLocked()
						return false
					end
					function inert:GetValue()
						return hubdefault
					end
					return inert
				end

				local configkey = keyfor("Keybind_", keybindconfig)
				local function savedpref()
					local v = config.data[configkey]
					if v ~= nil then
						return Chloex:ParseKeyCode(v)
					end
					return hubdefault
				end

				local lockable = tabgated or isdonatorelement(keybindconfig)
				local donatoronly = (tabgated and keygatedonator) or isdonatoronly(keybindconfig)
				local islocked = lockable and not tierallows(donatoronly)
				local keybindfunc = { Value = hubdefault, DefaultValue = hubdefault }

				-- One record per window: which row is waiting for a key, and a short
				-- cooldown so the key that finishes a rebind never also fires an action.
				guifunc.Keybinds = guifunc.Keybinds or { cancel = nil, blockuntil = 0 }
				local shared = guifunc.Keybinds

				local keyrow = instance.frame(sectionadd)
				keyrow.Name = "Keybind"
				keyrow.BorderSizePixel = 0
				keyrow.LayoutOrder = countitem
				keyrow.Size = UDim2.new(1, 0, 0, 46)
				local rowbg = roundbg(keyrow, 4, theme.Row)

				local keybtn = instance.textbutton(keyrow)
				keybtn.Name = "KeyBtn"
				keybtn.FontFace = FONT_BOLD
				keybtn.AutoButtonColor = false
				keybtn.AnchorPoint = Vector2.new(1, 0.5)
				keybtn.Position = UDim2.new(1, -10, 0.5, 0)
				keybtn.Size = UDim2.new(0, 56, 0, 26)
				keybtn.AutomaticSize = Enum.AutomaticSize.X
				keybtn.BackgroundColor3 = theme.Field
				keybtn.BackgroundTransparency = 0
				keybtn.BorderSizePixel = 0
				keybtn.TextSize = ts(12)
				keybtn.TextColor3 = theme.Dim
				keybtn.TextTruncate = Enum.TextTruncate.AtEnd
				keybtn.Text = "None"
				instance.uicorner(keybtn).CornerRadius = UDim.new(0, 4)
				local keypadding = instance.uipadding(keybtn)
				keypadding.PaddingLeft = UDim.new(0, 8)
				keypadding.PaddingRight = UDim.new(0, 8)
				local keymax = instance.uisizeconstraint(keybtn)
				keymax.MaxSize = Vector2.new(110, 26)
				local keystroke = instance.uistroke(keybtn)
				keystroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				keystroke.Color = Color3.fromRGB(255, 255, 255)
				keystroke.Thickness = 1
				keystroke.Transparency = 0.9

				local keytitle = instance.textlabel(keyrow)
				keytitle.FontFace = FONT_BOLD
				keytitle.Text = keybindconfig.Title
				keytitle.TextSize = ts(13)
				keytitle.TextColor3 = theme.Text
				keytitle.TextTruncate = Enum.TextTruncate.AtEnd
				keytitle.TextXAlignment = Enum.TextXAlignment.Left
				keytitle.BackgroundTransparency = 1
				keytitle.AnchorPoint = Vector2.new(0, 0.5)
				keytitle.Position = UDim2.new(0, 10, 0.5, 0)

				-- the title leaves room for the button, which grows with long key names
				local function fittitle()
					keytitle.Size = UDim2.new(1, -(math.max(56, keybtn.AbsoluteSize.X) + 22), 0, 16)
				end
				fittitle()
				keybtn:GetPropertyChangedSignal("AbsoluteSize"):Connect(fittitle)

				keyrow.MouseEnter:Connect(function()
					if not islocked then
						rowbg.ImageColor3 = theme.ElementHover
					end
				end)
				keyrow.MouseLeave:Connect(function()
					rowbg.ImageColor3 = theme.Row
				end)

				local lock = nil
				local basey = 46
				local description = contenttext(keybindconfig)
				if description then
					keytitle.AnchorPoint = Vector2.new(0, 0)
					keytitle.Position = UDim2.new(0, 10, 0, 9)
					local _, measure = attachcontent(keyrow, description, 10, 26, function()
						return math.max(56, keybtn.AbsoluteSize.X) + 22
					end)
					local function relayout()
						basey = math.max(46, 26 + measure() + 10)
						if lock and lock:IsLocked() then
							lock:Relayout()
						else
							keyrow.Size = UDim2.new(1, 0, 0, basey)
						end
					end
					relayout()
					watchwidth(keyrow, relayout)
				end

				local listening = false

				local function renderkey(instant)
					elevate()
					local textcolor, strokecolor, stroketransparency
					if listening then
						keybtn.Text = "..."
						textcolor = guiconfig.Color
						strokecolor = guiconfig.Color
						stroketransparency = 0
					else
						keybtn.Text = Chloex:KeyCodeLabel(keybindfunc.Value)
						textcolor = keybindfunc.Value ~= Enum.KeyCode.Unknown and theme.Text or theme.Dim
						strokecolor = Color3.fromRGB(255, 255, 255)
						stroketransparency = 0.9
					end
					if instant then
						keybtn.TextColor3 = textcolor
						keystroke.Color = strokecolor
						keystroke.Transparency = stroketransparency
					else
						sv.ts:Create(keybtn, TweenInfo.new(0.15), { TextColor3 = textcolor }):Play()
						sv.ts:Create(keystroke, TweenInfo.new(0.15), { Color = strokecolor, Transparency = stroketransparency }):Play()
					end
				end

				local setlistening
				local function stoplistening()
					setlistening(false)
				end
				function setlistening(state)
					if state == listening then
						return
					end
					listening = state
					if state then
						if shared.cancel and shared.cancel ~= stoplistening then
							shared.cancel()
						end
						shared.cancel = stoplistening
					else
						if shared.cancel == stoplistening then
							shared.cancel = nil
						end
						shared.blockuntil = os.clock() + 0.25
					end
					renderkey()
				end

				local function apply(value, save, fire)
					elevate()
					value = Chloex:ParseKeyCode(value)
					keybindfunc.Value = value
					if save then
						config.data[configkey] = value == Enum.KeyCode.Unknown and "None" or value.Name
						config:queuesave()
					end
					renderkey(true)
					if fire and typeof(changedcallback) == "function" then
						elevate()
						local ok, err = pcall(changedcallback, value)
						if not ok then
							warn("Keybind Changed callback error:", err)
						end
					end
				end

				function keybindfunc:Set(value)
					if islocked then
						return
					end
					setlistening(false)
					apply(value, true, true)
				end

				function keybindfunc:LoadValue(value)
					self:Set(value)
				end

				function keybindfunc:ResetValue()
					self:Set(hubdefault)
				end

				function keybindfunc:GetValue()
					return keybindfunc.Value
				end

				function keybindfunc:IsLocked()
					return islocked
				end

				keybtn.Activated:Connect(function()
					if islocked then
						return
					end
					setlistening(not listening)
				end)

				trackConnection(
					sv.uis.InputBegan:Connect(function(input, gpe)
						if listening then
							if input.UserInputType ~= Enum.UserInputType.Keyboard then
								return
							end
							if input.KeyCode == Enum.KeyCode.Escape then
								setlistening(false)
								return
							end
							setlistening(false)
							if input.KeyCode == Enum.KeyCode.Backspace then
								apply(Enum.KeyCode.Unknown, true, true)
							else
								apply(input.KeyCode, true, true)
							end
							return
						end
						if gpe or islocked or keybindfunc.Value == Enum.KeyCode.Unknown then
							return
						end
						if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= keybindfunc.Value then
							return
						end
						if shared.cancel or os.clock() < shared.blockuntil then
							return
						end
						elevate()
						local ok, err = pcall(keybindconfig.Callback, keybindfunc.Value)
						if not ok then
							warn("Keybind Callback error:", err)
						end
					end),
					"keybind." .. configkey
				)

				if islocked then
					apply(hubdefault, false, false)
				else
					apply(savedpref(), true, true)
				end

				if lockable then
					lock = makelock(keyrow, { keybtn }, {
						DonatorOnly = donatoronly,
						GetBaseHeight = function()
							return basey
						end,
						Pin = function(state)
							keybtn.Position = state and UDim2.new(1, -10, 0, basey / 2) or UDim2.new(1, -10, 0.5, 0)
							if not description then
								keytitle.Position = state and UDim2.new(0, 10, 0, basey / 2) or UDim2.new(0, 10, 0.5, 0)
							end
						end,
						OnLock = function()
							islocked = true
							setlistening(false)
						end,
						OnUnlock = function()
							islocked = false
						end,
					}, islocked)
				end

				countitem = countitem + 1
				yieldbuild()
				config.elements[configkey] = keybindfunc
				registerSearchItem(keybindconfig.Title, keyrow)
				return keybindfunc
			end

			function items:AddDropdown(dropdownconfig)
				dropdownconfig = dropdownconfig or {}
				dropdownconfig.Title = dropdownconfig.Title or "Title"
				dropdownconfig.Multi = dropdownconfig.Multi or false
				dropdownconfig.Advanced = dropdownconfig.Advanced or false
				dropdownconfig.Options = dropdownconfig.Options or {}
				dropdownconfig.Callback = dropdownconfig.Callback or function() end
				local multi = dropdownconfig.Multi

				-- a selection in this dropdown's shape: Multi -> a fresh array,
				-- single -> one value or nil. Always a copy, so the hub can keep or
				-- change what it was given without touching the dropdown.
				local function normalize(value)
					if multi then
						local out = {}
						if type(value) == "table" then
							for _, v in ipairs(value) do
								out[#out + 1] = v
							end
						end
						return out
					end
					if type(value) == "table" then
						return value[1]
					end
					if value == "" then
						return nil
					end
					return value
				end

				local function sameselection(a, b)
					if multi then
						if #a ~= #b then
							return false
						end
						for i = 1, #a do
							if a[i] ~= b[i] then
								return false
							end
						end
						return true
					end
					return a == b
				end

				local configkey = keyfor("Dropdown_", dropdownconfig)
				local hubdefault = normalize(dropdownconfig.Default)
				local function savedpref()
					local v = config.data[configkey]
					if v ~= nil then
						return normalize(v)
					end
					if config.loaded then
						return normalize(nil)
					end
					return normalize(hubdefault)
				end

				local lockable = tabgated or isdonatorelement(dropdownconfig)
				local donatoronly = (tabgated and keygatedonator) or isdonatoronly(dropdownconfig)
				local islocked = lockable and not tierallows(donatoronly)
				local dropdownfunc = {
					Value = islocked and normalize(hubdefault) or savedpref(),
					Options = dropdownconfig.Options,
					DefaultValue = normalize(hubdefault),
				}

				local function parseOption(option)
					local label, desc, img, value

					if typeof(option) == "table" then
						if option.Label and option.Value ~= nil then
							label = tostring(option.Label)
							value = option.Value
							desc = option.Description or option.Desc or option[2]
							img = option.Image or option.Icon or option[3]
						else
							label = tostring(option[1] or option.Title or option.Name or "Option")
							desc = option[2] or option.Description or option.Desc
							img = option[3] or option.Image or option.Icon
							value = option.Value ~= nil and option.Value or label
						end
					else
						label = tostring(option)
						value = option
					end

					if img and type(img) == "number" then
						img = "rbxassetid://" .. tostring(img)
					elseif img and type(img) == "string" and img ~= "" and not img:find("rbxassetid://") then
						img = "rbxassetid://" .. img
					end

					return label, desc, img, value
				end

				local dropdown = instance.frame(sectionadd)
				dropdown.Name = "Dropdown"
				dropdown.BorderSizePixel = 0
				dropdown.LayoutOrder = countitem
				dropdown.Size = UDim2.new(1, 0, 0, 46)
				roundbg(dropdown, 4, theme.Row)

				local dropdownbutton = instance.textbutton(dropdown)
				dropdownbutton.Name = "ToggleButton"
				dropdownbutton.Text = ""
				dropdownbutton.BackgroundTransparency = 1
				dropdownbutton.Size = UDim2.new(1, 0, 1, 0)

				local dropdownrowbg = dropdown:FindFirstChild("Bg")
				dropdownbutton.MouseEnter:Connect(function()
					if dropdownrowbg then
						dropdownrowbg.ImageColor3 = theme.ElementHover
					end
				end)
				dropdownbutton.MouseLeave:Connect(function()
					if dropdownrowbg then
						dropdownrowbg.ImageColor3 = theme.Row
					end
				end)

				local dropdowntitle = instance.textlabel(dropdown)
				dropdowntitle.Name = "DropdownTitle"
				dropdowntitle.FontFace = FONT_BOLD
				dropdowntitle.Text = dropdownconfig.Title
				dropdowntitle.TextColor3 = theme.Text
				dropdowntitle.TextSize = ts(13)
				dropdowntitle.TextTruncate = Enum.TextTruncate.AtEnd
				dropdowntitle.TextXAlignment = Enum.TextXAlignment.Left
				dropdowntitle.BackgroundTransparency = 1
				dropdowntitle.Position = UDim2.new(0, 10, 0, 0)
				dropdowntitle.Size = UDim2.new(0.55, -24, 1, 0)

				-- The value pill takes 45% of the row (120-260 px) instead of a fixed
				-- 148 px, and its text is truncated; the full pick list is in the popup.
				local selectoptionsframe = instance.frame(dropdown)
				selectoptionsframe.Name = "SelectOptionsFrame"
				selectoptionsframe.AnchorPoint = Vector2.new(1, 0.5)
				selectoptionsframe.Position = UDim2.new(1, -7, 0.5, 0)
				selectoptionsframe.Size = UDim2.new(0.45, 0, 0, 30)
				selectoptionsframe.LayoutOrder = countdropdown
				roundbg(selectoptionsframe, 4, theme.Inner)
				local pillconstraint = instance.uisizeconstraint(selectoptionsframe)
				pillconstraint.MinSize = Vector2.new(120, 0)
				pillconstraint.MaxSize = Vector2.new(260, 30)

				local optionselecting = instance.textlabel(selectoptionsframe)
				optionselecting.Name = "OptionSelecting"
				optionselecting.FontFace = FONT_BOLD
				optionselecting.Text = dropdownconfig.Multi and "Select Options" or "Select Option"
				optionselecting.TextColor3 = theme.Text
				optionselecting.TextSize = ts(12)
				optionselecting.TextTransparency = 0.55
				optionselecting.TextTruncate = Enum.TextTruncate.AtEnd
				optionselecting.TextXAlignment = Enum.TextXAlignment.Left
				optionselecting.AnchorPoint = Vector2.new(0, 0.5)
				optionselecting.BackgroundTransparency = 1
				optionselecting.Position = UDim2.new(0, 9, 0.5, 0)
				optionselecting.Size = UDim2.new(1, -34, 1, -8)

				local optionimg = instance.imagelabel(selectoptionsframe)
				optionimg.Name = "OptionImg"
				optionimg.ImageColor3 = theme.SubText
				optionimg.AnchorPoint = Vector2.new(1, 0.5)
				optionimg.BackgroundTransparency = 1
				optionimg.Position = UDim2.new(1, -8, 0.5, 0)
				optionimg.Size = UDim2.new(0, 14, 0, 14)
				applyicon(optionimg, "chevron-down", 48)

				local lock = nil
				local basey = 46
				local description = contenttext(dropdownconfig)
				if description then
					dropdowntitle.Position = UDim2.new(0, 10, 0, 9)
					dropdowntitle.Size = UDim2.new(0.55, -24, 0, 14)
					dropdowntitle.TextYAlignment = Enum.TextYAlignment.Top
					local _, measure = attachcontent(dropdown, description, 10, 26, function()
						local width = selectoptionsframe.AbsoluteSize.X
						return (width > 1 and width or 160) + 20
					end)
					local function relayout()
						basey = math.max(46, 26 + measure() + 10)
						if lock and lock:IsLocked() then
							lock:Relayout()
						else
							dropdown.Size = UDim2.new(1, 0, 0, basey)
						end
					end
					relayout()
					watchwidth(dropdown, relayout)
				end

				local dropdowncontainer = instance.frame(dropdownfolder)
				dropdowncontainer.Size = UDim2.new(1, 0, 1, 0)
				dropdowncontainer.BackgroundTransparency = 1

				local searchbox = instance.textbox(dropdowncontainer)
				searchbox.Name = "SearchBox"
				searchbox.PlaceholderText = "Search"
				searchbox.PlaceholderColor3 = theme.Dim
				searchbox.FontFace = FONT_MEDIUM
				searchbox.Text = ""
				searchbox.TextSize = ts(12)
				searchbox.TextColor3 = theme.Text
				searchbox.TextXAlignment = Enum.TextXAlignment.Left
				searchbox.TextTruncate = Enum.TextTruncate.AtEnd
				searchbox.BackgroundColor3 = theme.Element
				searchbox.BackgroundTransparency = 0
				searchbox.BorderSizePixel = 0
				searchbox.ClipsDescendants = true
				searchbox.Size = UDim2.new(1, 0, 0, 26)
				searchbox.Position = UDim2.new(0, 0, 0, 0)
				searchbox.ClearTextOnFocus = false
				instance.uicorner(searchbox).CornerRadius = UDim.new(0, 4)
				local searchpad = instance.uipadding(searchbox)
				searchpad.PaddingLeft = UDim.new(0, 8)
				searchpad.PaddingRight = UDim.new(0, 8)

				local scrollselect = instance.scrollingframe(dropdowncontainer)
				scrollselect.Name = "ScrollSelect"
				scrollselect.Size = UDim2.new(1, 0, 1, -30)
				scrollselect.Position = UDim2.new(0, 0, 0, 30)
				scrollselect.ScrollBarImageColor3 = theme.Track
				scrollselect.ScrollBarImageTransparency = 0.2
				scrollselect.BorderSizePixel = 0
				scrollselect.BackgroundTransparency = 1
				scrollselect.ScrollBarThickness = 3
				scrollselect.CanvasSize = UDim2.new(0, 0, 0, 0)

				local uilistlayout = instance.uilistlayout(scrollselect)
				uilistlayout.Padding = UDim.new(0, 3)
				uilistlayout.SortOrder = Enum.SortOrder.LayoutOrder

				uilistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					scrollselect.CanvasSize = UDim2.new(0, 0, 0, uilistlayout.AbsoluteContentSize.Y)
				end)

				-- Options live in optionlist; their rows are only built the first
				-- time the list is opened (a dropdown nobody opens costs no rows,
				-- and Refresh on a closed dropdown is just a table swap).
				local optionlist = {}
				local built = false

				local function isselected(value)
					if multi then
						return table.find(dropdownfunc.Value, value) ~= nil
					end
					return dropdownfunc.Value ~= nil and dropdownfunc.Value == value
				end

				local function paint(entry, instant)
					local drop = entry.frame
					if not drop or not drop.Parent then
						return
					end
					local selected = isselected(entry.value)
					local targetSize = selected and UDim2.new(0, 1, 0, 12) or UDim2.new(0, 0, 0, 0)
					local targetStroke = selected and 0 or 1
					local targetBackground = selected and 0 or 1
					local stroke = drop.ChooseFrame:FindFirstChild("UIStroke")

					if instant then
						drop.ChooseFrame.Size = targetSize
						if stroke then
							stroke.Transparency = targetStroke
						end
						drop.Bg.ImageTransparency = targetBackground
					else
						local info = TweenInfo.new(selected and 0.2 or 0.1)
						sv.ts:Create(drop.ChooseFrame, info, { Size = targetSize }):Play()
						if stroke then
							sv.ts:Create(stroke, info, { Transparency = targetStroke }):Play()
						end
						sv.ts:Create(drop.Bg, info, { ImageTransparency = targetBackground }):Play()
					end
				end

				local function updatetext()
					local texts, matched = {}, {}
					for _, entry in ipairs(optionlist) do
						if isselected(entry.value) then
							texts[#texts + 1] = entry.label
							matched[entry.value] = true
						end
					end
					-- a pick whose option is not in the list (saved before the list
					-- loaded, a player who left) is still active, so still shown
					local picks = multi and dropdownfunc.Value or { dropdownfunc.Value }
					for _, v in ipairs(picks) do
						if v ~= nil and not matched[v] then
							texts[#texts + 1] = tostring(v)
						end
					end
					-- One pick shows its name; several show "first +N" so the pill never
					-- has to fit a comma list. Placeholder text stays dim.
					if #texts == 0 then
						optionselecting.Text = multi and "Select Options" or "Select Option"
						optionselecting.TextTransparency = 0.55
					elseif #texts == 1 then
						optionselecting.Text = texts[1]
						optionselecting.TextTransparency = 0
					else
						optionselecting.Text = texts[1] .. "  +" .. tostring(#texts - 1)
						optionselecting.TextTransparency = 0
					end
				end

				local function fire()
					if typeof(dropdownconfig.Callback) ~= "function" then
						return
					end
					elevate()
					local ok, err
					if multi then
						ok, err = pcall(dropdownconfig.Callback, normalize(dropdownfunc.Value))
					else
						ok, err = pcall(dropdownconfig.Callback, dropdownfunc.Value ~= nil and tostring(dropdownfunc.Value) or "")
					end
					if not ok then
						warn("Dropdown Callback error:", err)
					end
				end

				local function apply(value, instant, save, dofire)
					elevate()
					dropdownfunc.Value = normalize(value)
					if save then
						config.data[configkey] = multi and normalize(dropdownfunc.Value) or dropdownfunc.Value
						config:queuesave()
					end
					for _, entry in ipairs(optionlist) do
						paint(entry, instant)
					end
					updatetext()
					if dofire then
						fire()
					end
				end

				local function applyfilter()
					if not built then
						return
					end
					local query = string.lower(searchbox.Text)
					for _, entry in ipairs(optionlist) do
						if entry.frame then
							entry.frame.Visible = query == ""
								or string.find(string.lower(entry.label), query, 1, true) ~= nil
								or (entry.desc ~= nil and string.find(string.lower(tostring(entry.desc)), query, 1, true) ~= nil)
						end
					end
					scrollselect.CanvasSize = UDim2.new(0, 0, 0, uilistlayout.AbsoluteContentSize.Y)
				end

				searchbox:GetPropertyChangedSignal("Text"):Connect(applyfilter)

				local function buildoption(entry)
					local useAdvanced = dropdownconfig.Advanced and (entry.desc or entry.img)
					local height = 30
					local leftPadding = entry.img and 42 or 8
					local textX = useAdvanced and math.max(8, leftPadding - 10) or leftPadding

					local optionframe = templates.DropdownOption:Clone()
					optionframe.Size = UDim2.new(1, 0, 0, height)
					optionframe.Parent = scrollselect

					local optionbutton = optionframe.OptionButton
					local optiontext = optionframe.OptionText
					optiontext.Text = entry.label
					optiontext.Position = UDim2.new(0, textX, 0, useAdvanced and 1 or 8)
					optiontext.Size = UDim2.new(1, -(textX + 20), 0, 13)

					if entry.img then
						local icon = instance.imagelabel(optionframe)
						icon.Name = "OptionIcon"
						icon.Image = entry.img
						icon.BackgroundTransparency = 1
						icon.Position = UDim2.new(0, 8, 0.5, -14)
						icon.Size = UDim2.new(0, 28, 0, 28)
						icon.ScaleType = Enum.ScaleType.Fit
						instance.uicorner(icon).CornerRadius = UDim.new(0, 5)
					end

					if useAdvanced and entry.desc then
						local optiondesc = instance.textlabel(optionframe)
						optiondesc.Name = "OptionDesc"
						optiondesc.FontFace = FONT_BOLD
						optiondesc.Text = tostring(entry.desc)
						optiondesc.TextSize = ts(10)
						optiondesc.TextTransparency = 0.3
						optiondesc.TextColor3 = Color3.fromRGB(255, 255, 255)
						optiondesc.Position = UDim2.new(0, textX, 0, 11)
						optiondesc.Size = UDim2.new(1, -(textX + 20), 0, 10)
						optiondesc.BackgroundTransparency = 1
						optiondesc.TextXAlignment = Enum.TextXAlignment.Left
						optiondesc.TextTruncate = Enum.TextTruncate.AtEnd
					end

					optionbutton.Activated:Connect(function()
						if islocked then
							return
						end
						if multi then
							local sel = normalize(dropdownfunc.Value)
							local idx = table.find(sel, entry.value)
							if idx then
								table.remove(sel, idx)
							else
								table.insert(sel, entry.value)
							end
							apply(sel, false, true, true)
						else
							apply(entry.value, false, true, true)
							closedropdownpopup()
						end
					end)

					entry.frame = optionframe
				end

				local function buildall()
					if built then
						return
					end
					built = true
					for _, entry in ipairs(optionlist) do
						buildoption(entry)
						paint(entry, true)
					end
				end

				local function setoptions(list)
					for _, entry in ipairs(optionlist) do
						if entry.frame then
							entry.frame:Destroy()
						end
					end
					optionlist = {}
					for _, option in ipairs(list or {}) do
						local label, desc, img, value = parseOption(option)
						local entry = { label = label, desc = desc, img = img, value = value }
						optionlist[#optionlist + 1] = entry
						if built then
							buildoption(entry)
						end
					end
					dropdownfunc.Options = list or {}
				end

				dropdownbutton.Activated:Connect(function()
					if islocked then
						return
					end
					buildall()
					applyfilter()
					opendropdownpopup(selectoptionsframe.LayoutOrder)
				end)

				function dropdownfunc:Clear()
					setoptions({})
					dropdownfunc.Value = normalize(nil)
					updatetext()
				end

				function dropdownfunc:AddOption(option)
					local label, desc, img, value = parseOption(option)
					local entry = { label = label, desc = desc, img = img, value = value }
					optionlist[#optionlist + 1] = entry
					if built then
						buildoption(entry)
						paint(entry, true)
						applyfilter()
					end
					updatetext()
				end

				function dropdownfunc:Set(value, instant, force)
					if islocked and not force then
						return
					end
					apply(value, instant, not islocked, true)
				end

				function dropdownfunc:SetValue(val)
					self:Set(val)
				end

				function dropdownfunc:GetValue()
					return self.Value
				end

				function dropdownfunc:SetValues(newlist, selecting, instant)
					setoptions(newlist or {})
					if islocked then
						apply(dropdownfunc.Value, true, false, false)
					else
						apply(selecting, instant, true, true)
					end
					applyfilter()
				end

				-- Refresh swaps the option list and keeps the selection, like
				-- VectaLib (nothing fires). Refresh(list, false) clears it and fires
				-- the callback if something was selected.
				function dropdownfunc:Refresh(newlist, keep)
					setoptions(newlist or {})
					if keep == false and not islocked then
						local cleared = normalize(nil)
						apply(cleared, true, true, not sameselection(normalize(dropdownfunc.Value), cleared))
					else
						apply(dropdownfunc.Value, true, false, false)
					end
					applyfilter()
				end

				function dropdownfunc:LoadValue(value)
					self:Set(value, true)
				end

				function dropdownfunc:ResetValue()
					self:Set(normalize(hubdefault))
				end

				setoptions(dropdownconfig.Options)
				if islocked then
					apply(dropdownfunc.Value, true, false, false)
				else
					apply(dropdownfunc.Value, true, true, true)
				end

				if lockable then
					lock = makelock(dropdown, { selectoptionsframe }, {
						DonatorOnly = donatoronly,
						GetBaseHeight = function()
							return basey
						end,
						Pin = function(state)
							selectoptionsframe.Position = state and UDim2.new(1, -7, 0, basey / 2) or UDim2.new(1, -7, 0.5, 0)
							if not description then
								dropdowntitle.Size = state and UDim2.new(1, -180, 0, basey) or UDim2.new(1, -180, 1, 0)
							end
						end,
						OnLock = function(silent)
							islocked = true
							local base = normalize(hubdefault)
							if not sameselection(normalize(dropdownfunc.Value), base) then
								apply(base, true, false, not silent)
							end
						end,
						OnUnlock = function()
							islocked = false
							apply(savedpref(), true, true, true)
						end,
					}, islocked)
				end

				function dropdownfunc:IsLocked()
					return islocked
				end

				countitem = countitem + 1
				countdropdown = countdropdown + 1
				yieldbuild()
				config.elements[configkey] = dropdownfunc
				registerSearchItem(dropdownconfig.Title, dropdown)
				return dropdownfunc
			end

			function items:AddDivider()
				local divider = instance.frame(sectionadd)
				divider.Name = "Divider"
				divider.Size = UDim2.new(1, 0, 0, 2)
				divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				divider.BackgroundTransparency = 0
				divider.BorderSizePixel = 0
				divider.LayoutOrder = countitem

				local gradient = instance.uigradient(divider)
				gradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 22)),
					ColorSequenceKeypoint.new(0.5, guiconfig.Color),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 22, 22)),
				})

				instance.uicorner(divider).CornerRadius = UDim.new(0, 2)

				countitem = countitem + 1
				return divider
			end

			function items:AddSubSection(sectiontext)
				sectiontext = sectiontext or "Sub Section"

				local subsection = instance.frame(sectionadd)
				subsection.Name = "SubSection"
				subsection.BackgroundTransparency = 1
				subsection.Size = UDim2.new(1, 0, 0, 22)
				subsection.LayoutOrder = countitem

				local background = instance.frame(subsection)
				background.Size = UDim2.new(1, 0, 1, 0)
				background.BackgroundColor3 = theme.Row
				background.BackgroundTransparency = 0.45
				background.BorderSizePixel = 0
				instance.uicorner(background).CornerRadius = UDim.new(0, 6)

				local label = instance.textlabel(subsection)
				label.AnchorPoint = Vector2.new(0, 0.5)
				label.Position = UDim2.new(0, 10, 0.5, 0)
				label.Size = UDim2.new(1, -20, 1, 0)
				label.BackgroundTransparency = 1
				label.FontFace = FONT_BOLD
				label.Text = string.upper(tostring(sectiontext))
				label.TextColor3 = theme.Dim
				label.TextSize = ts(11)
				label.TextTransparency = 0.35
				label.TextTruncate = Enum.TextTruncate.AtEnd
				label.TextXAlignment = Enum.TextXAlignment.Left

				countitem = countitem + 1
				currentSubSection = tostring(sectiontext)
				return subsection
			end

			function items:AddConfigPanel()
				config:ensuredefault()

				local autoname = config:getautoload() or ""
				local currentname = ""
				local importjson = ""
				local selected = autoname ~= "" and autoname or DEFAULT_CONFIG_NAME

				local nameinput = items:AddInput({
					Title = "Config Name",
					Content = "Name for saving",
					Placeholder = "MyConfig",
					Callback = function(text)
						currentname = text
					end,
				})

				local configlist
				local acclist
				local function refreshlist()
					local list = config:getlist()
					if configlist and configlist.SetValues then
						configlist:SetValues(list, selected, true)
					end
					if acclist and acclist.SetValues then
						acclist:SetValues(list, acclist.Value or "", true)
					end
				end

				configlist = items:AddDropdown({
					Title = "Saved Configs",
					Content = "Select a config",
					Multi = false,
					Options = config:getlist(),
					Default = selected,
					Callback = function(choice)
						selected = (choice and choice ~= "") and choice or nil
						if selected then
							currentname = selected
							nameinput:Set(selected)
						end
					end,
				})

				items:AddButton({
					Title = "Save",
					SubTitle = "Load",
					Callback = function()
						local name = sanitizename(currentname)
						if name == "" then
							chloex("Enter a config name first", 3, theme.Bad)
							return
						end
						if config:save(name) then
							selected = name
							refreshlist()
							chloex("Saved '" .. name .. "'", 3, theme.Good)
						else
							chloex("Failed to save config", 3, theme.Bad)
						end
					end,
					SubCallback = function()
						if not selected then
							chloex("Select a config first", 3, theme.Bad)
							return
						end
						if config:load(selected) then
							chloex("Loaded '" .. selected .. "'", 3, theme.Good)
						else
							chloex("Failed to load '" .. selected .. "'", 3, theme.Bad)
						end
					end,
				})

				items:AddButton({
					Title = "Delete",
					SubTitle = "Refresh List",
					Callback = function()
						if not selected then
							chloex("Select a config first", 3, theme.Bad)
							return
						end
						if config:delete(selected) then
							chloex("Deleted '" .. selected .. "'", 3, theme.Good)
							selected = nil
							refreshlist()
						end
					end,
					SubCallback = function()
						refreshlist()
					end,
				})

				local initautosave = true
				items:AddToggle({
					Title = "Auto Save",
					Content = "Save changes automatically",
					Default = config.autosave,
					Callback = function(value)
						config.autosave = value == true
						config:writeautosave(config.autosave)
						if initautosave then
							return
						end
						if config.autosave then
							config:persist(true)
						end
						chloex(config.autosave and "Auto Save enabled" or "Auto Save disabled", 3, theme.Good)
					end,
				})
				initautosave = false

				local acctoggle, autotoggle
				local initauto = true
				autotoggle = items:AddToggle({
					Title = "Auto Load",
					Content = autoname ~= "" and ("Auto: " .. autoname) or "Load selected on startup",
					Default = autoname ~= "",
					Callback = function(value)
						if initauto then
							return
						end
						if value and selected then
							config:setautoload(selected)
							if acctoggle then
								initauto = true
								acctoggle:Set(false, true)
								initauto = false
							end
							chloex("Auto load set to '" .. selected .. "'", 3, theme.Good)
						elseif value then
							config:clearautoload()
							initauto = true
							autotoggle:Set(false, true)
							initauto = false
							chloex("Select a config first", 3, theme.Bad)
						else
							config:clearautoload()
						end
					end,
				})
				initauto = false

				items:AddSubSection("Auto Load Per Account")

				local accid = currentaccountid()
				local accinfo = config:getaccountinfo()
				local accstatus = items:AddParagraph({
					Title = "Auto Load Per Account",
					Content = "Account ID: " .. accid,
				})

				local function updateaccstatus()
					local info = config:getaccountinfo()
					local bound = tostring(info.Accounts[accid] or "")
					local text = "Account ID: " .. accid
					text = text .. (bound ~= "" and ("\nBound to: " .. bound) or "\nNot set, no autoload for this account")
					text = text .. "\nStatus: " .. (info.Enabled and "ON" or "OFF")
					accstatus:SetContent(text)
				end
				updateaccstatus()

				local initacc = true
				acctoggle = items:AddToggle({
					Title = "Per-Account Autoload",
					Content = "Different config per Roblox account (multi-instance)",
					Default = accinfo.Enabled == true,
					Callback = function(value)
						if initacc or initauto then
							return
						end
						if not config:setaccountenabled(value) then
							initacc = true
							acctoggle:Set(not value, true)
							initacc = false
							return
						end
						if value and autotoggle then
							initauto = true
							autotoggle:Set(false, true)
							initauto = false
							chloex("Per-Account Autoload enabled", 3, theme.Good)
						end
						updateaccstatus()
					end,
				})
				initacc = false

				local selectedacc = tostring(accinfo.Accounts[accid] or "") ~= "" and tostring(accinfo.Accounts[accid]) or nil
				acclist = items:AddDropdown({
					Title = "Account Config",
					Content = "Config loaded for account " .. accid,
					Multi = false,
					Options = config:getlist(),
					Default = selectedacc or "",
					Callback = function(choice)
						selectedacc = (choice and choice ~= "") and choice or nil
					end,
				})

				items:AddButton({
					Title = "Set For This Account",
					SubTitle = "Clear Binding",
					Callback = function()
						if not selectedacc then
							chloex("Select a config first", 3, theme.Bad)
							return
						end
						if config:setaccountautoload(accid, selectedacc) then
							chloex("Account " .. accid .. " -> '" .. selectedacc .. "'", 3, theme.Good)
							updateaccstatus()
						end
					end,
					SubCallback = function()
						if config:setaccountautoload(accid, nil) then
							selectedacc = nil
							if acclist and acclist.Set then
								acclist:Set("", true)
							end
							chloex("Binding cleared", 3, theme.Good)
							updateaccstatus()
						end
					end,
				})

				items:AddSubSection("Import / Export")

				items:AddInput({
					Title = "Import JSON",
					Content = "Paste exported config",
					Placeholder = "{...}",
					Callback = function(text)
						importjson = text
					end,
				})

				local function doimport(json)
					if not json or json == "" then
						chloex("Paste a config string first", 3, theme.Bad)
						return
					end
					if config:loadexternal(json) then
						refreshlist()
						chloex("Config imported", 3, theme.Good)
					else
						chloex("Invalid config format", 3, theme.Bad)
					end
				end

				items:AddButton({
					Title = "Import JSON",
					SubTitle = "Import from Clipboard",
					Callback = function()
						doimport(importjson)
					end,
					SubCallback = function()
						doimport((getclipboard and getclipboard()) or "")
					end,
				})

				items:AddButton({
					Title = "Export to Clipboard",
					SubTitle = "Reset To Default",
					Callback = function()
						config:export()
						chloex("Config copied to clipboard", 3, theme.Good)
					end,
					SubCallback = function()
						config:reset()
						chloex("All elements reset to default", 3, theme.Good)
					end,
				})

				task.spawn(function()
					for _ = 1, 5 do
						task.wait(1)
						if #config:getlist() > 0 then
							refreshlist()
							break
						end
					end
				end)

				return {
					Refresh = refreshlist,
					RefreshList = refreshlist,
					UpdateStatus = updateaccstatus,
				}
			end

			items.AddConfig = items.AddConfigPanel

			-- Config Forum. Browse first: the share form lives in its own sheet, and
			-- applying a setup always goes through a preview with Undo.
			function items:AddForum(forumconfig)
				forumconfig = forumconfig or {}
				local fixedheight = tonumber(forumconfig.Height)
				local function fitheight()
					if fixedheight then
						return math.max(320, fixedheight)
					end
					local h = scrollayers.AbsoluteWindowSize.Y
					if h <= 1 then
						h = layers.AbsoluteSize.Y
					end
					return math.max(320, math.floor(h) - 2)
				end
				local pad = 8
				local forum = {
					Sort = "top",
					Posts = {},
					Mine = nil,
					Game = nil,
					Busy = false,
					Loading = false,
					Search = "",
					DeviceFilter = "Any",
					Device = { ram = "Any", ping = "Any", platform = "Any" },
					Options = {
						ram = { "Any", "2GB", "3GB", "4GB", "6GB", "8GB+" },
						ping = { "Any", "Under 50ms", "Under 100ms", "Under 150ms", "Under 250ms" },
						platform = { "Any", "PC", "Mobile" },
					},
				}

				local texthex = hexcolor(theme.Text)
				local dimhex = hexcolor(theme.Dim)
				local goldhex = hexcolor(theme.Gold)

				local function httprequest()
					return (type(request) == "function" and request)
						or (type(http_request) == "function" and http_request)
						or (type(syn) == "table" and type(syn.request) == "function" and syn.request)
						or (type(http) == "table" and type(http.request) == "function" and http.request)
						or nil
				end

				local function deviceid()
					local ok, id = pcall(function()
						if type(gethwid) == "function" then
							return gethwid()
						end
						return game:GetService("RbxAnalyticsService"):GetClientId()
					end)
					id = ok and id and tostring(id) or ""
					if id == "" then
						id = localuserid() .. ":" .. executorname()
					end
					return id
				end

				local function currentping()
					local ok, ms = pcall(function()
						return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
					end)
					if not ok or not tonumber(ms) or ms <= 0 then
						ok, ms = pcall(function()
							return sv.plrs.LocalPlayer:GetNetworkPing() * 2000
						end)
					end
					return ok and tonumber(ms) or nil
				end

				local myplatform = isMobile and "Mobile" or "PC"
				local function defaultdevice()
					local ms = currentping()
					local ping = "Any"
					if ms then
						for _, cap in ipairs({ 50, 100, 150, 250 }) do
							if ms < cap then
								ping = "Under " .. cap .. "ms"
								break
							end
						end
					end
					forum.Device.ping = ping
					forum.Device.platform = myplatform
				end
				defaultdevice()

				-- name on posts: the forum's own setting (it used to follow the chat pill)
				local namefile = "Vecta/forum_showname.txt"
				local showname = false
				pcall(function()
					if isfile and isfile(namefile) then
						showname = readfile(namefile) == "1"
					elseif getgenv and getgenv().SenaHideName ~= nil then
						showname = getgenv().SenaHideName ~= true
					end
				end)

				local function basepayload(extra)
					local trial = istrial()
					local payload = {
						uid = localuserid(),
						key = backend and backend.Key or "",
						name = localusername(),
						display = localdisplayname(),
						place = tostring(game.PlaceId),
						game = backend and backend.Game or "",
						lic = tostring((getgenv and getgenv().SenaKey) or ""),
						trial = trial and "1" or "0",
					}
					for k, v in pairs(extra or {}) do
						payload[k] = v
					end
					return payload
				end

				local function forumpost(path, extra)
					if not backend then
						return nil, "not connected"
					end
					local payload = basepayload(extra)
					local fn = httprequest()
					if fn then
						local ok, res = pcall(fn, {
							Url = backend.Api .. path,
							Method = "POST",
							Headers = { ["Content-Type"] = "application/json" },
							Body = sv.http:JSONEncode(payload),
						})
						if ok and type(res) == "table" and type(res.Body) == "string" then
							local okjson, data = pcall(function()
								return sv.http:JSONDecode(res.Body)
							end)
							if okjson and type(data) == "table" then
								if data.ok == false then
									return data, tostring(data.error or "error")
								end
								return data, nil
							end
						end
						return nil, "no response"
					end
					return Chloex:BackendCall(path, extra)
				end

				-- the server's words never reach the player as-is; "what" names the
				-- action so a cooldown says what is cooling down
				local function cleanwhy(why)
					return (tostring(why or ""):gsub("^%s+", ""):gsub("^[Mm]aintenance[%s,:%.%-]*", ""))
				end
				local function friendlyerror(err, what)
					err = tostring(err or "error")
					if err:match("^maintenance") then
						local why = cleanwhy(err:match("^maintenance:(.*)") or "")
						return "The forum is under maintenance" .. (why ~= "" and ("  ·  " .. why) or "")
					end
					local secs = err:match("^cooldown:(%d+)")
					if secs then
						return "Wait " .. secs .. "s before " .. (what or "trying again")
					end
					if err:match("^badword:") then
						return "The title has blocked words"
					end
					if err:match("^key_share") then
						return "The title can't contain a license key"
					end
					if err == "not connected" or err == "bad key" or err == "missing uid" then
						return "Not connected to Vecta yet, try again in a moment"
					end
					if err == "no response" then
						return "Vecta didn't answer, try again in a moment"
					end
					if err == "blacklisted" then
						return "Your account can't use the forum"
					end
					return "Something went wrong, try again"
				end

				local function timeago(ts)
					local s = math.max(0, os.time() - (tonumber(ts) or os.time()))
					if s < 60 then
						return "just now"
					elseif s < 3600 then
						return math.floor(s / 60) .. "m ago"
					elseif s < 86400 then
						return math.floor(s / 3600) .. "h ago"
					end
					return math.floor(s / 86400) .. "d ago"
				end

				local function shownname(key)
					return (tostring(key):gsub("^%a+_", ""))
				end

				local function joinlist(list, limit)
					local out = {}
					for i, v in ipairs(list) do
						if i > limit then
							out[#out + 1] = "+" .. (#list - limit) .. " more"
							break
						end
						out[#out + 1] = escaperich(v)
					end
					return table.concat(out, ", ")
				end

				-- full description of a shared config, plus counts for the short line
				local function describe(cfgtable)
					local enabled, filters, values, unknown = {}, {}, {}, 0
					for key, value in pairs(cfgtable or {}) do
						if config.elements[key] == nil then
							unknown = unknown + 1
						else
							local kind = tostring(key):match("^(%a+)_")
							if kind == "Toggle" and value == true then
								enabled[#enabled + 1] = shownname(key)
							elseif kind == "Dropdown" then
								local list = type(value) == "table" and value or { value }
								local picked = {}
								for _, v in ipairs(list) do
									picked[#picked + 1] = tostring(v)
								end
								if #picked > 0 then
									filters[#filters + 1] = { shownname(key), picked }
								end
							elseif kind == "Slider" and tonumber(value) then
								values[#values + 1] = { shownname(key), tonumber(value) }
							end
						end
					end
					table.sort(enabled)
					table.sort(filters, function(a, b)
						return a[1] < b[1]
					end)
					table.sort(values, function(a, b)
						return a[1] < b[1]
					end)

					local lines = {}
					local function head(text)
						return '<font color="' .. texthex .. '"><b>' .. escaperich(text) .. "</b></font>  "
					end
					if #enabled > 0 then
						lines[#lines + 1] = head("Enabled") .. joinlist(enabled, 14)
					end
					for i, f in ipairs(filters) do
						if i > 6 then
							lines[#lines + 1] = '<font color="' .. dimhex .. '">+' .. (#filters - 6) .. " more filters</font>"
							break
						end
						lines[#lines + 1] = head(f[1]) .. joinlist(f[2], 8)
					end
					for i, v in ipairs(values) do
						if i > 4 then
							break
						end
						local n = v[2]
						lines[#lines + 1] = head(v[1]) .. (n == math.floor(n) and tostring(n) or string.format("%.2f", n))
					end
					if unknown > 0 then
						lines[#lines + 1] = '<font color="' .. dimhex .. '"><i>' .. unknown .. " setting(s) from another hub version will be skipped</i></font>"
					end
					if #lines == 0 then
						lines[1] = '<font color="' .. dimhex .. '">Nothing from this hub version</font>'
					end
					local short = #enabled > 0 and joinlist(enabled, 3) or "No features"
					if #filters > 0 then
						short = short .. '  <font color="' .. dimhex .. '">·  ' .. #filters .. " filter" .. (#filters == 1 and "" or "s") .. "</font>"
					end
					return table.concat(lines, "\n"), #enabled, #filters, #values, short
				end

				local function collectconfig()
					local out = {}
					for key, element in pairs(config.elements) do
						if not metakeys[key] and (key:match("^Toggle_") or key:match("^Dropdown_") or key:match("^Slider_")) then
							local value = element.Value
							if key:match("^Toggle_") then
								if value == true then
									out[key] = true
								end
							elseif key:match("^Slider_") then
								if tonumber(value) then
									out[key] = tonumber(value)
								end
							elseif type(value) == "table" then
								local list = {}
								for _, v in ipairs(value) do
									list[#list + 1] = tostring(v)
								end
								if #list > 0 then
									out[key] = list
								end
							elseif value ~= nil and tostring(value) ~= "" then
								out[key] = tostring(value)
							end
						end
					end
					return out
				end

				local function copyvalue(v)
					if type(v) ~= "table" then
						return v
					end
					local out = {}
					for k, x in pairs(v) do
						out[k] = copyvalue(x)
					end
					return out
				end

				-- apply a shared setup: features / filters / sliders from the post,
				-- everything else off; the player's own text inputs (webhooks, names) stay
				local function injectconfig(cfgtable)
					local data = { _version = config.version }
					for key, value in pairs(config.data or {}) do
						if tostring(key):match("^Input_") or metakeys[key] then
							data[key] = value
						end
					end
					for key, value in pairs(cfgtable or {}) do
						if config.elements[key] ~= nil and not tostring(key):match("^Input_") then
							data[key] = value
						end
					end
					config.data = data
					config.loaded = true
					config:loadelements()
				end

				-- what applying cfgtable would do to the player's current settings
				local function diffconfig(cfgtable)
					local turnon, turnoff, changes = {}, {}, {}
					local function same(a, b)
						if type(a) == "table" or type(b) == "table" then
							local x = type(a) == "table" and a or (a ~= nil and { a } or {})
							local y = type(b) == "table" and b or (b ~= nil and { b } or {})
							if #x ~= #y then
								return false
							end
							local seen = {}
							for _, v in ipairs(x) do
								seen[tostring(v)] = true
							end
							for _, v in ipairs(y) do
								if not seen[tostring(v)] then
									return false
								end
							end
							return true
						end
						return tostring(a) == tostring(b)
					end
					for key, element in pairs(config.elements) do
						if not metakeys[key] then
							local now = element.Value
							local want = cfgtable[key]
							if key:match("^Toggle_") then
								local on = want == true
								if on and now ~= true then
									turnon[#turnon + 1] = shownname(key)
								elseif not on and now == true then
									turnoff[#turnoff + 1] = shownname(key)
								end
							elseif key:match("^Dropdown_") then
								local nowempty = now == nil or now == "" or (type(now) == "table" and #now == 0)
								if want == nil then
									if not nowempty then
										changes[#changes + 1] = shownname(key) .. " → cleared"
									end
								elseif not same(now, want) then
									local shown = type(want) == "table" and table.concat(want, ", ") or tostring(want)
									changes[#changes + 1] = shownname(key) .. " → " .. shown
								end
							elseif key:match("^Slider_") and tonumber(want) and not same(now, want) then
								changes[#changes + 1] = shownname(key) .. " → " .. tostring(want)
							end
						end
					end
					table.sort(turnon)
					table.sort(turnoff)
					table.sort(changes)
					return turnon, turnoff, changes
				end

				-- what a post asks of the device, compared with this one
				local function devicefit(dev)
					dev = type(dev) == "table" and dev or {}
					local platform = tostring(dev.platform or "Any")
					if platform ~= "Any" and platform ~= myplatform then
						return false, "Made for " .. platform
					end
					local cap = tonumber(tostring(dev.ping or ""):match("(%d+)"))
					local ms = currentping()
					if cap and ms and ms >= cap then
						return false, "Needs ping under " .. cap .. "ms"
					end
					return true, "Fits your device"
				end

				-- small building blocks ------------------------------------------------
				local function icon(parent, name, size, color)
					local img = instance.imagelabel(parent)
					img.BackgroundTransparency = 1
					img.ImageColor3 = color or theme.SubText
					img.Size = UDim2.new(0, size, 0, size)
					applyicon(img, name, 48)
					return img
				end

				local function hlist(parent, spacing, align)
					local layout = instance.uilistlayout(parent)
					layout.FillDirection = Enum.FillDirection.Horizontal
					layout.HorizontalAlignment = align or Enum.HorizontalAlignment.Left
					layout.VerticalAlignment = Enum.VerticalAlignment.Center
					layout.Padding = UDim.new(0, spacing or 6)
					layout.SortOrder = Enum.SortOrder.LayoutOrder
					return layout
				end

				-- read-only chip: no fill, dim text (in this window a fill means "pressable")
				local function tag(parent, text, color, iconname)
					local frame = instance.frame(parent)
					frame.AutomaticSize = Enum.AutomaticSize.X
					frame.BackgroundTransparency = 1
					frame.Size = UDim2.new(0, 0, 0, 18)
					hlist(frame, 4)
					if iconname then
						local img = icon(frame, iconname, 11, color or theme.Dim)
						img.LayoutOrder = 0
					end
					local label = instance.textlabel(frame)
					label.AutomaticSize = Enum.AutomaticSize.X
					label.BackgroundTransparency = 1
					label.FontFace = FONT_BOLD
					label.LayoutOrder = 1
					label.RichText = true
					label.Size = UDim2.new(0, 0, 1, 0)
					label.Text = text
					label.TextColor3 = color or theme.Dim
					label.TextSize = ts(11)
					return frame, label
				end

				-- pressable button that sizes to its label
				local function button(parent, text, kind, iconname)
					local b = instance.textbutton(parent)
					b.AutoButtonColor = false
					b.AutomaticSize = Enum.AutomaticSize.X
					b.BorderSizePixel = 0
					b.Size = UDim2.new(0, 0, 0, 26)
					b.Text = ""
					local face, hover, ink = theme.Inner, theme.InnerHover, theme.Text
					if kind == "primary" then
						face, hover, ink = guiconfig.Color, guiconfig.Color:Lerp(Color3.new(1, 1, 1), 0.12), theme.AccentText
					elseif kind == "danger" then
						face, hover, ink = Color3.fromRGB(64, 30, 32), Color3.fromRGB(84, 36, 38), theme.Bad
					elseif kind == "ghost" then
						face, hover, ink = theme.Element, theme.ElementHover, theme.SubText
					end
					b.BackgroundColor3 = face
					instance.uicorner(b).CornerRadius = UDim.new(0, 5)
					local bpad = instance.uipadding(b)
					bpad.PaddingLeft = UDim.new(0, iconname and 10 or 12)
					bpad.PaddingRight = UDim.new(0, 12)
					hlist(b, 5)
					local img
					if iconname then
						img = icon(b, iconname, 13, ink)
						img.LayoutOrder = 0
					end
					local label = instance.textlabel(b)
					label.AutomaticSize = Enum.AutomaticSize.X
					label.BackgroundTransparency = 1
					label.FontFace = FONT_BOLD
					label.LayoutOrder = 1
					label.RichText = true
					label.Size = UDim2.new(0, 0, 1, 0)
					label.Text = text
					label.TextColor3 = ink
					label.TextSize = ts(12)
					local enabled = true
					b.MouseEnter:Connect(function()
						if enabled then
							b.BackgroundColor3 = hover
						end
					end)
					b.MouseLeave:Connect(function()
						b.BackgroundColor3 = face
					end)
					b.MouseButton1Down:Connect(function()
						if enabled then
							pcall(pesseffect, b)
						end
					end)
					local api = { frame = b, label = label, icon = img }
					function api.setenabled(on)
						enabled = on
						b.Active = on
						b.BackgroundTransparency = on and 0 or 0.5
						label.TextTransparency = on and 0 or 0.5
						if img then
							img.ImageTransparency = on and 0 or 0.5
						end
					end
					function api.enabled()
						return enabled
					end
					return api
				end

				-- layout -------------------------------------------------------------------
				local root = instance.frame(sectionadd)
				root.Name = "ConfigForum"
				root.BorderSizePixel = 0
				root.ClipsDescendants = true
				root.LayoutOrder = countitem
				root.Size = UDim2.new(1, 0, 0, fitheight())
				roundbg(root, 6, theme.Row)
				countitem = countitem + 1
				if not fixedheight then
					scrollayers:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
						root.Size = UDim2.new(1, 0, 0, fitheight())
					end)
				end

				local headerh = 40
				local title = instance.textlabel(root)
				title.BackgroundTransparency = 1
				title.FontFace = FONT_BOLD
				title.Position = UDim2.new(0, 12, 0, 6)
				title.Size = UDim2.new(1, -250, 0, 16)
				title.Text = tostring(forumconfig.Title or "Community Setups")
				title.TextColor3 = theme.Text
				title.TextSize = ts(13)
				title.TextTruncate = Enum.TextTruncate.AtEnd
				title.TextXAlignment = Enum.TextXAlignment.Left

				local subtitle = instance.textlabel(root)
				subtitle.BackgroundTransparency = 1
				subtitle.FontFace = FONT_MEDIUM
				subtitle.Position = UDim2.new(0, 12, 0, 22)
				subtitle.RichText = true
				subtitle.Size = UDim2.new(1, -250, 0, 14)
				subtitle.Text = "Loading..."
				subtitle.TextColor3 = theme.Dim
				subtitle.TextSize = ts(11)
				subtitle.TextTruncate = Enum.TextTruncate.AtEnd
				subtitle.TextXAlignment = Enum.TextXAlignment.Left

				local actionsbar = instance.frame(root)
				actionsbar.AnchorPoint = Vector2.new(1, 0.5)
				actionsbar.BackgroundTransparency = 1
				actionsbar.Position = UDim2.new(1, -pad, 0, headerh / 2)
				actionsbar.Size = UDim2.new(0, 240, 0, 26)
				hlist(actionsbar, 6, Enum.HorizontalAlignment.Right)

				local refreshbtn = instance.textbutton(actionsbar)
				refreshbtn.AutoButtonColor = false
				refreshbtn.LayoutOrder = 1
				refreshbtn.Size = UDim2.new(0, 26, 0, 26)
				refreshbtn.Text = ""
				hoverbg(refreshbtn, roundbg(refreshbtn, 6, theme.Inner), theme.Inner, theme.InnerHover)
				local refreshicon = icon(refreshbtn, "refresh-cw", 13, theme.Text)
				refreshicon.AnchorPoint = Vector2.new(0.5, 0.5)
				refreshicon.Position = UDim2.new(0.5, 0, 0.5, 0)

				local sharebtn = button(actionsbar, "Share my setup", "primary", "share-2")
				sharebtn.frame.LayoutOrder = 2

				-- toolbar: sort, search, device filter
				local toolh = 28
				local toolbar = instance.frame(root)
				toolbar.BackgroundTransparency = 1
				toolbar.Position = UDim2.new(0, pad, 0, headerh)
				toolbar.Size = UDim2.new(1, -pad * 2, 0, toolh)

				local sortframe = instance.frame(toolbar)
				sortframe.AutomaticSize = Enum.AutomaticSize.X
				sortframe.BackgroundColor3 = theme.Element
				sortframe.BorderSizePixel = 0
				sortframe.Size = UDim2.new(0, 0, 0, 26)
				instance.uicorner(sortframe).CornerRadius = UDim.new(0, 5)
				local sortpad = instance.uipadding(sortframe)
				sortpad.PaddingLeft = UDim.new(0, 2)
				sortpad.PaddingRight = UDim.new(0, 2)
				hlist(sortframe, 2)
				local sortchips = {}
				local function sortchip(key, text, order)
					local b = instance.textbutton(sortframe)
					b.AutoButtonColor = false
					b.AutomaticSize = Enum.AutomaticSize.X
					b.BackgroundColor3 = guiconfig.Color
					b.BackgroundTransparency = 1
					b.BorderSizePixel = 0
					b.LayoutOrder = order
					b.Size = UDim2.new(0, 0, 0, 22)
					b.Text = ""
					instance.uicorner(b).CornerRadius = UDim.new(0, 5)
					local bpad = instance.uipadding(b)
					bpad.PaddingLeft = UDim.new(0, 10)
					bpad.PaddingRight = UDim.new(0, 10)
					local label = instance.textlabel(b)
					label.AutomaticSize = Enum.AutomaticSize.X
					label.BackgroundTransparency = 1
					label.FontFace = FONT_BOLD
					label.Size = UDim2.new(0, 0, 1, 0)
					label.Text = text
					label.TextColor3 = theme.SubText
					label.TextSize = ts(11)
					sortchips[key] = { frame = b, label = label }
					return b
				end
				local topchip = sortchip("top", "Top liked", 1)
				local newchip = sortchip("new", "Newest", 2)

				local search = instance.textbox(toolbar)
				search.AnchorPoint = Vector2.new(1, 0.5)
				search.BackgroundColor3 = theme.Element
				search.BorderSizePixel = 0
				search.ClearTextOnFocus = false
				search.ClipsDescendants = true
				search.FontFace = FONT_MEDIUM
				search.PlaceholderColor3 = theme.Dim
				search.PlaceholderText = "Search setups"
				search.Position = UDim2.new(1, -112, 0.5, 0)
				search.Size = UDim2.new(0.4, -40, 0, 26)
				search.Text = ""
				search.TextColor3 = theme.Text
				search.TextSize = ts(12)
				search.TextTruncate = Enum.TextTruncate.AtEnd
				search.TextXAlignment = Enum.TextXAlignment.Left
				instance.uicorner(search).CornerRadius = UDim.new(0, 5)
				local searchpad = instance.uipadding(search)
				searchpad.PaddingLeft = UDim.new(0, 28)
				searchpad.PaddingRight = UDim.new(0, 10)
				local searchicon = icon(search, "search", 12, theme.Dim)
				searchicon.AnchorPoint = Vector2.new(0, 0.5)
				searchicon.Position = UDim2.new(0, -19, 0.5, 0)

				local devicebtn = button(toolbar, "Any device", "ghost", "chevron-down")
				devicebtn.frame.AnchorPoint = Vector2.new(1, 0.5)
				devicebtn.frame.Position = UDim2.new(1, 0, 0.5, 0)

				-- banner for errors, maintenance and the post-apply Undo
				local bannerh = 30
				local banner = instance.frame(root)
				banner.BackgroundColor3 = theme.Box
				banner.BorderSizePixel = 0
				banner.Position = UDim2.new(0, pad, 0, headerh + toolh + 4)
				banner.Size = UDim2.new(1, -pad * 2, 0, bannerh)
				banner.Visible = false
				banner.ZIndex = 3
				instance.uicorner(banner).CornerRadius = UDim.new(0, 6)
				local bannerstroke = instance.uistroke(banner)
				bannerstroke.Color = theme.Stroke
				bannerstroke.Transparency = 0.4
				local bannericon = icon(banner, "info", 13, theme.SubText)
				bannericon.AnchorPoint = Vector2.new(0, 0.5)
				bannericon.Position = UDim2.new(0, 10, 0.5, 0)
				bannericon.ZIndex = 4
				local bannertext = instance.textlabel(banner)
				bannertext.BackgroundTransparency = 1
				bannertext.FontFace = FONT_BOLD
				bannertext.Position = UDim2.new(0, 30, 0, 0)
				bannertext.Size = UDim2.new(1, -120, 1, 0)
				bannertext.Text = ""
				bannertext.TextColor3 = theme.SubText
				bannertext.TextSize = ts(12)
				bannertext.TextTruncate = Enum.TextTruncate.AtEnd
				bannertext.TextXAlignment = Enum.TextXAlignment.Left
				bannertext.ZIndex = 4
				local banneraction = button(banner, "Retry", "ghost")
				banneraction.frame.AnchorPoint = Vector2.new(1, 0.5)
				banneraction.frame.Position = UDim2.new(1, -4, 0.5, 0)
				banneraction.frame.Size = UDim2.new(0, 0, 0, 22)
				banneraction.frame.ZIndex = 4
				banneraction.label.ZIndex = 5
				local bannerfn = nil
				banneraction.frame.Activated:Connect(function()
					elevate()
					if bannerfn then
						local fn = bannerfn
						fn()
					end
				end)

				local scroll = instance.scrollingframe(root)
				scroll.Name = "Posts"
				scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
				scroll.BackgroundColor3 = theme.ChatBg
				scroll.BorderSizePixel = 0
				scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
				scroll.ScrollBarImageColor3 = theme.Bar
				scroll.ScrollBarThickness = 3
				scroll.ScrollingDirection = Enum.ScrollingDirection.Y
				instance.uicorner(scroll).CornerRadius = UDim.new(0, 6)
				local scrollpad = instance.uipadding(scroll)
				scrollpad.PaddingBottom = UDim.new(0, 6)
				scrollpad.PaddingLeft = UDim.new(0, 6)
				scrollpad.PaddingRight = UDim.new(0, 8)
				scrollpad.PaddingTop = UDim.new(0, 6)
				local scrolllayout = instance.uilistlayout(scroll)
				scrolllayout.Padding = UDim.new(0, 6)
				scrolllayout.SortOrder = Enum.SortOrder.LayoutOrder

				local function layoutlist()
					local top = headerh + toolh + 4 + (banner.Visible and (bannerh + 6) or 0)
					scroll.Position = UDim2.new(0, pad, 0, top)
					scroll.Size = UDim2.new(1, -pad * 2, 1, -(top + pad))
				end
				layoutlist()

				local bannertoken = 0
				local function showbanner(text, tone, actiontext, fn, seconds)
					elevate()
					bannertoken = bannertoken + 1
					local token = bannertoken
					if not text then
						banner.Visible = false
						bannerfn = nil
						layoutlist()
						return
					end
					local color = tone == "bad" and theme.Bad or (tone == "warn" and theme.Gold or (tone == "good" and theme.Good or theme.SubText))
					local iconname = tone == "bad" and "triangle-alert" or (tone == "warn" and "hourglass" or (tone == "good" and "circle-check" or "info"))
					bannertext.Text = text
					bannertext.TextColor3 = color
					bannericon.ImageColor3 = color
					applyicon(bannericon, iconname, 48)
					bannerstroke.Color = color
					banneraction.frame.Visible = actiontext ~= nil
					if actiontext then
						banneraction.label.Text = actiontext
					end
					bannerfn = fn
					banner.Visible = true
					layoutlist()
					if seconds then
						task.delay(seconds, function()
							if bannertoken == token then
								elevate()
								banner.Visible = false
								bannerfn = nil
								layoutlist()
							end
						end)
					end
				end

				local emptybox = instance.frame(scroll)
				emptybox.Name = "Empty"
				emptybox.BackgroundTransparency = 1
				emptybox.LayoutOrder = 0
				emptybox.Size = UDim2.new(1, 0, 0, 110)
				local emptyicon = icon(emptybox, "messages-square", 22, theme.Dim)
				emptyicon.AnchorPoint = Vector2.new(0.5, 0)
				emptyicon.Position = UDim2.new(0.5, 0, 0, 14)
				local emptytext = instance.textlabel(emptybox)
				emptytext.BackgroundTransparency = 1
				emptytext.FontFace = FONT_MEDIUM
				emptytext.Position = UDim2.new(0, 10, 0, 44)
				emptytext.Size = UDim2.new(1, -20, 0, 30)
				emptytext.Text = "Loading setups..."
				emptytext.TextColor3 = theme.Dim
				emptytext.TextSize = ts(12)
				emptytext.TextWrapped = true
				local emptyshare = button(emptybox, "Share my setup", "primary", "share-2")
				emptyshare.frame.AnchorPoint = Vector2.new(0.5, 0)
				emptyshare.frame.Position = UDim2.new(0.5, 0, 0, 78)
				emptyshare.frame.Visible = false

				-- sheets and popovers sit over everything, with one click-outside layer
				local scrim = instance.textbutton(root)
				scrim.AutoButtonColor = false
				scrim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				scrim.BackgroundTransparency = 1
				scrim.Size = UDim2.new(1, 0, 1, 0)
				scrim.Text = ""
				scrim.Visible = false
				scrim.ZIndex = 20
				local openlayer = nil
				local closepickerref = nil
				local function closelayer()
					if closepickerref then
						closepickerref()
					end
					if openlayer then
						openlayer.Visible = false
					end
					openlayer = nil
					scrim.Visible = false
				end
				local function showlayer(frame, dim)
					closelayer()
					openlayer = frame
					frame.Visible = true
					scrim.BackgroundTransparency = dim and 0.45 or 1
					scrim.Visible = true
				end
				scrim.Activated:Connect(closelayer)

				local function sheet(name)
					local frame = instance.frame(root)
					frame.Name = name
					frame.AnchorPoint = Vector2.new(0.5, 0.5)
					frame.AutomaticSize = Enum.AutomaticSize.Y
					frame.BackgroundColor3 = theme.Card
					frame.BorderSizePixel = 0
					frame.Position = UDim2.new(0.5, 0, 0.5, 0)
					frame.Size = UDim2.new(1, -40, 0, 0)
					frame.Visible = false
					frame.ZIndex = 30
					instance.uicorner(frame).CornerRadius = UDim.new(0, 8)
					local stroke = instance.uistroke(frame)
					stroke.Color = theme.Stroke
					local spad = instance.uipadding(frame)
					spad.PaddingBottom = UDim.new(0, 12)
					spad.PaddingLeft = UDim.new(0, 14)
					spad.PaddingRight = UDim.new(0, 14)
					spad.PaddingTop = UDim.new(0, 12)
					local layout = instance.uilistlayout(frame)
					layout.Padding = UDim.new(0, 8)
					layout.SortOrder = Enum.SortOrder.LayoutOrder
					local constraint = instance.uisizeconstraint(frame)
					constraint.MaxSize = Vector2.new(460, 2000)
					return frame
				end

				local function sheethead(frame, text)
					local head = instance.frame(frame)
					head.BackgroundTransparency = 1
					head.LayoutOrder = 0
					head.Size = UDim2.new(1, 0, 0, 22)
					head.ZIndex = 31
					local label = instance.textlabel(head)
					label.BackgroundTransparency = 1
					label.FontFace = FONT_BOLD
					label.Size = UDim2.new(1, -30, 1, 0)
					label.Text = text
					label.TextColor3 = theme.Text
					label.TextSize = ts(14)
					label.TextTruncate = Enum.TextTruncate.AtEnd
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.ZIndex = 31
					local close = instance.imagebutton(head)
					close.AnchorPoint = Vector2.new(1, 0.5)
					close.BackgroundTransparency = 1
					close.ImageColor3 = theme.SubText
					close.Position = UDim2.new(1, 0, 0.5, 0)
					close.Size = UDim2.new(0, 16, 0, 16)
					close.ZIndex = 32
					applyicon(close, "x", 48)
					close.Activated:Connect(closelayer)
					return head, label
				end

				local function sheettext(frame, order, text, color, size)
					local label = instance.textlabel(frame)
					label.AutomaticSize = Enum.AutomaticSize.Y
					label.BackgroundTransparency = 1
					label.FontFace = FONT_MEDIUM
					label.LayoutOrder = order
					label.RichText = true
					label.Size = UDim2.new(1, 0, 0, 0)
					label.Text = text
					label.TextColor3 = color or theme.SubText
					label.TextSize = ts(size or 12)
					label.TextWrapped = true
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.ZIndex = 31
					return label
				end

				local function sheetrow(frame, order, height)
					local row = instance.frame(frame)
					row.BackgroundTransparency = 1
					row.LayoutOrder = order
					row.Size = UDim2.new(1, 0, 0, height or 28)
					row.ZIndex = 31
					return row
				end

				local function lift(gui, z)
					gui.ZIndex = z
					for _, d in ipairs(gui:GetDescendants()) do
						if d:IsA("GuiObject") then
							d.ZIndex = z + 1
						end
					end
				end

				-- option list popover used by the device filter and the requirement pickers
				local picker = instance.frame(root)
				picker.Name = "Picker"
				picker.AutomaticSize = Enum.AutomaticSize.Y
				picker.BackgroundColor3 = theme.Card
				picker.BorderSizePixel = 0
				picker.Size = UDim2.new(0, 170, 0, 0)
				picker.Visible = false
				picker.ZIndex = 40
				instance.uicorner(picker).CornerRadius = UDim.new(0, 8)
				local pickerstroke = instance.uistroke(picker)
				pickerstroke.Color = theme.Stroke
				local pickerpad = instance.uipadding(picker)
				pickerpad.PaddingBottom = UDim.new(0, 4)
				pickerpad.PaddingLeft = UDim.new(0, 4)
				pickerpad.PaddingRight = UDim.new(0, 4)
				pickerpad.PaddingTop = UDim.new(0, 4)
				local pickerlayout = instance.uilistlayout(picker)
				pickerlayout.Padding = UDim.new(0, 2)
				pickerlayout.SortOrder = Enum.SortOrder.LayoutOrder
				local pickerowner = nil

				local function closepicker()
					picker.Visible = false
					pickerowner = nil
					if not openlayer then
						scrim.Visible = false
					end
				end
				closepickerref = closepicker

				local function openpicker(anchor, options, current, onpick)
					elevate()
					if pickerowner == anchor then
						closepicker()
						return
					end
					for _, child in ipairs(picker:GetChildren()) do
						if child:IsA("GuiObject") then
							child:Destroy()
						end
					end
					for index, option in ipairs(options) do
						local row = instance.textbutton(picker)
						row.AutoButtonColor = false
						row.BackgroundColor3 = theme.Element
						row.BackgroundTransparency = option == current and 0 or 1
						row.BorderSizePixel = 0
						row.LayoutOrder = index
						row.Size = UDim2.new(1, 0, 0, 26)
						row.Text = ""
						row.ZIndex = 41
						instance.uicorner(row).CornerRadius = UDim.new(0, 6)
						local label = instance.textlabel(row)
						label.BackgroundTransparency = 1
						label.FontFace = FONT_BOLD
						label.Position = UDim2.new(0, 10, 0, 0)
						label.Size = UDim2.new(1, -34, 1, 0)
						label.Text = option
						label.TextColor3 = option == current and theme.Text or theme.SubText
						label.TextSize = ts(12)
						label.TextTruncate = Enum.TextTruncate.AtEnd
						label.TextXAlignment = Enum.TextXAlignment.Left
						label.ZIndex = 42
						if option == current then
							local mark = icon(row, "check", 12, guiconfig.Color)
							mark.AnchorPoint = Vector2.new(1, 0.5)
							mark.Position = UDim2.new(1, -8, 0.5, 0)
							mark.ZIndex = 42
						end
						row.MouseEnter:Connect(function()
							row.BackgroundTransparency = 0
						end)
						row.MouseLeave:Connect(function()
							row.BackgroundTransparency = option == current and 0 or 1
						end)
						row.Activated:Connect(function()
							elevate()
							closepicker()
							onpick(option)
						end)
					end
					local ax = anchor.AbsolutePosition.X - root.AbsolutePosition.X + anchor.AbsoluteSize.X
					local ay = anchor.AbsolutePosition.Y - root.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 4
					picker.AnchorPoint = Vector2.new(1, 0)
					picker.Position = UDim2.new(0, math.max(170, ax), 0, ay)
					picker.Visible = true
					pickerowner = anchor
					-- outside a sheet, a transparent scrim closes the list on any outside tap
					if not openlayer then
						scrim.BackgroundTransparency = 1
						scrim.Visible = true
					end
				end

				-- share sheet ---------------------------------------------------------------
				local sharesheet = sheet("ShareSheet")
				local _, sharetitle = sheethead(sharesheet, "Share your setup")

				local namerow = sheetrow(sharesheet, 1, 32)
				local titlebox = instance.textbox(namerow)
				titlebox.BackgroundColor3 = theme.Element
				titlebox.BorderSizePixel = 0
				titlebox.ClearTextOnFocus = false
				titlebox.ClipsDescendants = true
				titlebox.FontFace = FONT_MEDIUM
				titlebox.PlaceholderColor3 = theme.Dim
				titlebox.PlaceholderText = "Name your setup, e.g. Divine egg farm"
				titlebox.Size = UDim2.new(1, 0, 1, 0)
				titlebox.Text = ""
				titlebox.TextColor3 = theme.Text
				titlebox.TextSize = ts(12)
				titlebox.TextXAlignment = Enum.TextXAlignment.Left
				titlebox.ZIndex = 32
				instance.uicorner(titlebox).CornerRadius = UDim.new(0, 6)
				local titlepad = instance.uipadding(titlebox)
				titlepad.PaddingLeft = UDim.new(0, 10)
				titlepad.PaddingRight = UDim.new(0, 48)
				local titlecount = instance.textlabel(namerow)
				titlecount.AnchorPoint = Vector2.new(1, 0.5)
				titlecount.BackgroundTransparency = 1
				titlecount.FontFace = FONT_BOLD
				titlecount.Position = UDim2.new(1, -10, 0.5, 0)
				titlecount.Size = UDim2.new(0, 40, 0, 14)
				titlecount.Text = "0/48"
				titlecount.TextColor3 = theme.Dim
				titlecount.TextSize = ts(10)
				titlecount.TextXAlignment = Enum.TextXAlignment.Right
				titlecount.ZIndex = 33
				titlebox:GetPropertyChangedSignal("Text"):Connect(function()
					if #titlebox.Text > 48 then
						titlebox.Text = titlebox.Text:sub(1, 48)
						return
					end
					titlecount.Text = tostring(#titlebox.Text) .. "/48"
				end)

				sheettext(sharesheet, 2, "REQUIREMENTS", theme.Dim, 10).FontFace = FONT_BOLD
				local reqrow = sheetrow(sharesheet, 3, 28)
				hlist(reqrow, 6)
				local deviceprefix = { ram = "RAM", ping = "Ping", platform = "Device" }
				local reqbuttons = {}
				for order, field in ipairs({ "ram", "ping", "platform" }) do
					local b = button(reqrow, "", "ghost", "chevron-down")
					b.frame.LayoutOrder = order
					lift(b.frame, 32)
					local function render()
						b.label.Text = '<font color="' .. dimhex .. '">' .. deviceprefix[field] .. "</font>  " .. escaperich(forum.Device[field])
					end
					render()
					reqbuttons[field] = render
					b.frame.Activated:Connect(function()
						openpicker(b.frame, forum.Options[field], forum.Device[field], function(option)
							forum.Device[field] = option
							render()
						end)
					end)
				end

				local summary = sheettext(sharesheet, 4, "", theme.SubText, 12)

				local namerow2 = sheetrow(sharesheet, 5, 34)
				local nametoggle = instance.textbutton(namerow2)
				nametoggle.AutoButtonColor = false
				nametoggle.BackgroundTransparency = 1
				nametoggle.Size = UDim2.new(1, 0, 1, 0)
				nametoggle.Text = ""
				nametoggle.ZIndex = 32
				local namelabel = instance.textlabel(namerow2)
				namelabel.BackgroundTransparency = 1
				namelabel.FontFace = FONT_BOLD
				namelabel.Position = UDim2.new(0, 0, 0, 1)
				namelabel.Size = UDim2.new(1, -50, 0, 16)
				namelabel.Text = "Show my name on the post"
				namelabel.TextColor3 = theme.Text
				namelabel.TextSize = ts(12)
				namelabel.TextXAlignment = Enum.TextXAlignment.Left
				namelabel.ZIndex = 33
				local namesub = instance.textlabel(namerow2)
				namesub.BackgroundTransparency = 1
				namesub.FontFace = FONT_MEDIUM
				namesub.Position = UDim2.new(0, 0, 0, 18)
				namesub.Size = UDim2.new(1, -50, 0, 14)
				namesub.Text = "Off: the post shows a masked name"
				namesub.TextColor3 = theme.Dim
				namesub.TextSize = ts(11)
				namesub.TextXAlignment = Enum.TextXAlignment.Left
				namesub.ZIndex = 33
				local track = instance.frame(namerow2)
				track.AnchorPoint = Vector2.new(1, 0.5)
				track.BackgroundColor3 = theme.Field
				track.BorderSizePixel = 0
				track.Position = UDim2.new(1, 0, 0.5, 0)
				track.Size = UDim2.new(0, 34, 0, 18)
				track.ZIndex = 33
				instance.uicorner(track).CornerRadius = UDim.new(1, 0)
				local knob = instance.frame(track)
				knob.BackgroundColor3 = theme.Text
				knob.BorderSizePixel = 0
				knob.Position = UDim2.new(0, 2, 0, 2)
				knob.Size = UDim2.new(0, 14, 0, 14)
				knob.ZIndex = 34
				instance.uicorner(knob).CornerRadius = UDim.new(1, 0)
				local function rendername()
					track.BackgroundColor3 = showname and guiconfig.Color or theme.Field
					knob.BackgroundColor3 = showname and theme.AccentText or theme.Text
					sv.ts:Create(knob, TweenInfo.new(0.15), { Position = showname and UDim2.new(0, 18, 0, 2) or UDim2.new(0, 2, 0, 2) }):Play()
				end
				rendername()
				nametoggle.Activated:Connect(function()
					elevate()
					showname = not showname
					rendername()
					pcall(function()
						if writefile then
							writefile(namefile, showname and "1" or "0")
						end
					end)
				end)

				local sharewarn = sheettext(sharesheet, 6, "", theme.Gold, 11)
				sharewarn.Visible = false

				local sharebuttons = sheetrow(sharesheet, 7, 30)
				local deletebtn = button(sharebuttons, "Delete my post", "danger", "trash-2")
				lift(deletebtn.frame, 32)
				deletebtn.frame.Visible = false
				local rightbtns = instance.frame(sharebuttons)
				rightbtns.AnchorPoint = Vector2.new(1, 0)
				rightbtns.BackgroundTransparency = 1
				rightbtns.Position = UDim2.new(1, 0, 0, 0)
				rightbtns.Size = UDim2.new(0, 260, 1, 0)
				rightbtns.ZIndex = 31
				hlist(rightbtns, 6, Enum.HorizontalAlignment.Right)
				local cancelbtn = button(rightbtns, "Cancel", "ghost")
				cancelbtn.frame.LayoutOrder = 1
				lift(cancelbtn.frame, 32)
				local confirmshare = button(rightbtns, "Share", "primary", "share-2")
				confirmshare.frame.LayoutOrder = 2
				lift(confirmshare.frame, 32)
				cancelbtn.frame.Activated:Connect(closelayer)

				local function updateshare()
					local _, ons, filters, sliders = describe(collectconfig())
					summary.Text = string.format(
						'Will share <font color="%s"><b>%d</b></font> feature%s  ·  <font color="%s"><b>%d</b></font> filter%s  ·  <font color="%s"><b>%d</b></font> slider%s',
						texthex, ons, ons == 1 and "" or "s",
						texthex, filters, filters == 1 and "" or "s",
						texthex, sliders, sliders == 1 and "" or "s"
					)
					local mine = forum.Mine
					if mine and forum.MineHidden then
						sharewarn.Text = "Your post is hidden after reports. Ask an admin on Discord."
						sharewarn.TextColor3 = theme.Bad
						sharewarn.Visible = true
					elseif mine then
						local likes = tonumber(mine.likes) or 0
						sharewarn.Text = likes > 0 and ("Updating resets your " .. likes .. " like" .. (likes == 1 and "" or "s") .. ".")
							or "Updating replaces your current post."
						sharewarn.TextColor3 = theme.Gold
						sharewarn.Visible = true
					else
						sharewarn.Visible = false
					end
					sharetitle.Text = mine and "Update your setup" or "Share your setup"
					confirmshare.label.Text = mine and "Update" or "Share"
					deletebtn.frame.Visible = mine ~= nil
					sharebtn.label.Text = mine and "My setup" or "Share my setup"
					confirmshare.setenabled(not forum.Paused and ons > 0)
				end

				local function openshare()
					elevate()
					if forum.Paused then
						showbanner("The forum is under maintenance, sharing is closed", "warn", nil, nil, 4)
						return
					end
					closepicker()
					updateshare()
					showlayer(sharesheet, true)
				end
				sharebtn.frame.Activated:Connect(openshare)
				emptyshare.frame.Activated:Connect(openshare)

				-- preview & apply sheet ------------------------------------------------
				local applysheet = sheet("ApplySheet")
				local _, applytitle = sheethead(applysheet, "Apply setup")
				local applybody = sheettext(applysheet, 1, "", theme.SubText, 12)
				local applywarn = sheettext(applysheet, 2, "", theme.Gold, 11)
				local applybuttons = sheetrow(applysheet, 3, 30)
				local applyright = instance.frame(applybuttons)
				applyright.BackgroundTransparency = 1
				applyright.Size = UDim2.new(1, 0, 1, 0)
				applyright.ZIndex = 31
				hlist(applyright, 6, Enum.HorizontalAlignment.Right)
				local applycancel = button(applyright, "Cancel", "ghost")
				applycancel.frame.LayoutOrder = 1
				lift(applycancel.frame, 32)
				local applyconfirm = button(applyright, "Apply", "primary", "check")
				applyconfirm.frame.LayoutOrder = 2
				lift(applyconfirm.frame, 32)
				applycancel.frame.Activated:Connect(closelayer)
				local applypost = nil

				local function bulletlist(head, list, color, limit)
					if #list == 0 then
						return nil
					end
					local shown = {}
					for i, v in ipairs(list) do
						if i > limit then
							shown[#shown + 1] = "+" .. (#list - limit) .. " more"
							break
						end
						shown[#shown + 1] = escaperich(v)
					end
					return '<font color="' .. hexcolor(color) .. '"><b>' .. head .. "</b></font>\n" .. table.concat(shown, ", ")
				end

				local function openapply(post)
					elevate()
					if forum.Paused then
						showbanner("The forum is under maintenance", "warn", nil, nil, 4)
						return
					end
					applypost = post
					applytitle.Text = tostring(post.title or "Untitled setup")
					local on, off, changes = diffconfig(post.config or {})
					local parts = {}
					parts[#parts + 1] = bulletlist("Turns on", on, theme.Good, 12)
					parts[#parts + 1] = bulletlist("Turns off", off, theme.Bad, 12)
					parts[#parts + 1] = bulletlist("Changes", changes, theme.Gold, 8)
					local text = table.concat(parts, "\n\n")
					if text == "" then
						text = "Your settings already match this setup."
					end
					applybody.Text = text .. '\n\n<font color="' .. dimhex .. '">Your own text fields (webhooks, names) are kept.</font>'
					local fits, why = devicefit(post.device)
					applywarn.Visible = not fits
					applywarn.Text = fits and "" or ("Heads up: " .. why .. ".")
					showlayer(applysheet, true)
				end

				local function snapshot()
					local copy = {}
					for k, v in pairs(config.data or {}) do
						copy[k] = copyvalue(v)
					end
					return copy
				end

				applyconfirm.frame.Activated:Connect(function()
					elevate()
					local post = applypost
					if not post then
						return
					end
					closelayer()
					local before = snapshot()
					local ok, errmsg = pcall(injectconfig, post.config)
					if not ok then
						warn("[VECTA] forum apply failed:", errmsg)
						showbanner("Couldn't apply this setup", "bad", nil, nil, 5)
						return
					end
					showbanner("Applied: " .. tostring(post.title or "setup"), "good", "Undo", function()
						config.data = before
						config.loaded = true
						config:loadelements()
						showbanner("Your previous settings are back", "info", nil, nil, 3)
					end, 12)
				end)

				-- cards ----------------------------------------------------------------------
				local rankcolors = {
					Color3.fromRGB(245, 196, 81),
					Color3.fromRGB(196, 200, 210),
					Color3.fromRGB(214, 144, 92),
				}

				local cardmenu = instance.frame(root)
				cardmenu.AutomaticSize = Enum.AutomaticSize.Y
				cardmenu.BackgroundColor3 = theme.Card
				cardmenu.BorderSizePixel = 0
				cardmenu.Size = UDim2.new(0, 180, 0, 0)
				cardmenu.Visible = false
				cardmenu.ZIndex = 30
				instance.uicorner(cardmenu).CornerRadius = UDim.new(0, 8)
				local cardmenustroke = instance.uistroke(cardmenu)
				cardmenustroke.Color = theme.Stroke
				local cardmenupad = instance.uipadding(cardmenu)
				cardmenupad.PaddingBottom = UDim.new(0, 4)
				cardmenupad.PaddingLeft = UDim.new(0, 4)
				cardmenupad.PaddingRight = UDim.new(0, 4)
				cardmenupad.PaddingTop = UDim.new(0, 4)
				local cardmenulayout = instance.uilistlayout(cardmenu)
				cardmenulayout.SortOrder = Enum.SortOrder.LayoutOrder

				local function report(post, card)
					task.spawn(function()
						local data, errmsg = forumpost("/forum/report", { id = post.id })
						elevate()
						if errmsg then
							showbanner(friendlyerror(errmsg, "reporting again"), "bad", nil, nil, 5)
							return
						end
						post.reported = true
						showbanner("Thanks, the post was reported", "good", nil, nil, 3)
						if data and data.hidden and card.Parent then
							card:Destroy()
						end
					end)
				end

				local function opencardmenu(anchor, post, card)
					elevate()
					for _, child in ipairs(cardmenu:GetChildren()) do
						if child:IsA("GuiObject") then
							child:Destroy()
						end
					end
					local confirm = false
					local row = instance.textbutton(cardmenu)
					row.AutoButtonColor = false
					row.BackgroundColor3 = theme.Element
					row.BackgroundTransparency = 1
					row.BorderSizePixel = 0
					row.Size = UDim2.new(1, 0, 0, 30)
					row.Text = ""
					row.ZIndex = 31
					instance.uicorner(row).CornerRadius = UDim.new(0, 6)
					local img = icon(row, "flag", 13, post.reported and theme.Dim or theme.Bad)
					img.AnchorPoint = Vector2.new(0, 0.5)
					img.Position = UDim2.new(0, 8, 0.5, 0)
					img.ZIndex = 32
					local label = instance.textlabel(row)
					label.BackgroundTransparency = 1
					label.FontFace = FONT_BOLD
					label.Position = UDim2.new(0, 28, 0, 0)
					label.Size = UDim2.new(1, -34, 1, 0)
					label.Text = post.reported and "Reported" or "Report this post"
					label.TextColor3 = post.reported and theme.Dim or theme.Text
					label.TextSize = ts(12)
					label.TextTruncate = Enum.TextTruncate.AtEnd
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.ZIndex = 32
					if not post.reported then
						row.MouseEnter:Connect(function()
							row.BackgroundTransparency = 0
						end)
						row.MouseLeave:Connect(function()
							row.BackgroundTransparency = 1
						end)
						row.Activated:Connect(function()
							elevate()
							if not confirm then
								confirm = true
								label.Text = "Tap again to confirm"
								label.TextColor3 = theme.Bad
								return
							end
							closelayer()
							report(post, card)
						end)
					end
					local ax = anchor.AbsolutePosition.X - root.AbsolutePosition.X + anchor.AbsoluteSize.X
					local ay = anchor.AbsolutePosition.Y - root.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 4
					cardmenu.AnchorPoint = Vector2.new(1, 0)
					cardmenu.Position = UDim2.new(0, ax, 0, math.min(ay, root.AbsoluteSize.Y - 50))
					showlayer(cardmenu, false)
				end

				local function buildcard(post, order)
					local card = instance.frame(scroll)
					card.Name = "Post"
					card.AutomaticSize = Enum.AutomaticSize.Y
					card.BackgroundColor3 = post.mine and theme.Mine or theme.Card
					card.BorderSizePixel = 0
					card.LayoutOrder = order
					card.Size = UDim2.new(1, 0, 0, 0)
					instance.uicorner(card).CornerRadius = UDim.new(0, 8)
					local first = post.rank == 1 and forum.Sort == "top"
					local cardstroke = instance.uistroke(card)
					cardstroke.Color = first and theme.Gold or theme.Stroke
					cardstroke.Transparency = first and 0.4 or 0.55
					local cardpad = instance.uipadding(card)
					cardpad.PaddingBottom = UDim.new(0, 10)
					cardpad.PaddingLeft = UDim.new(0, 12)
					cardpad.PaddingRight = UDim.new(0, 12)
					cardpad.PaddingTop = UDim.new(0, 10)
					local cardlayout = instance.uilistlayout(card)
					cardlayout.Padding = UDim.new(0, 6)
					cardlayout.SortOrder = Enum.SortOrder.LayoutOrder

					-- title line: rank, title, likes
					local top = instance.frame(card)
					top.BackgroundTransparency = 1
					top.LayoutOrder = 1
					top.Size = UDim2.new(1, 0, 0, 22)
					local rank = tonumber(post.rank) or 0
					local badge = instance.textlabel(top)
					badge.AnchorPoint = Vector2.new(0, 0.5)
					badge.BackgroundColor3 = rankcolors[rank] or theme.Inner
					badge.BorderSizePixel = 0
					badge.FontFace = FONT_BOLD
					badge.Position = UDim2.new(0, 0, 0.5, 0)
					badge.Size = UDim2.new(0, 30, 0, 20)
					badge.Text = rank > 0 and ("#" .. rank) or "-"
					badge.TextColor3 = rankcolors[rank] and theme.AccentText or theme.SubText
					badge.TextSize = ts(11)
					instance.uicorner(badge).CornerRadius = UDim.new(1, 0)

					local like = button(top, "", "ghost", "heart")
					like.frame.AnchorPoint = Vector2.new(1, 0.5)
					like.frame.Position = UDim2.new(1, 0, 0.5, 0)
					like.frame.Size = UDim2.new(0, 0, 0, 24)
					local function renderlike()
						like.label.Text = tostring(post.likes or 0)
						like.icon.ImageColor3 = post.liked and theme.Bad or theme.SubText
						like.label.TextColor3 = post.liked and theme.Bad or theme.SubText
					end
					renderlike()

					local posttitle = instance.textlabel(top)
					posttitle.BackgroundTransparency = 1
					posttitle.FontFace = FONT_BOLD
					posttitle.Position = UDim2.new(0, 38, 0, 0)
					posttitle.Size = UDim2.new(1, -110, 1, 0)
					posttitle.Text = tostring(post.title or "Untitled setup")
					posttitle.TextColor3 = theme.Text
					posttitle.TextSize = ts(13)
					posttitle.TextTruncate = Enum.TextTruncate.AtEnd
					posttitle.TextXAlignment = Enum.TextXAlignment.Left

					local meta = instance.textlabel(card)
					meta.BackgroundTransparency = 1
					meta.FontFace = FONT_MEDIUM
					meta.LayoutOrder = 2
					meta.RichText = true
					meta.Size = UDim2.new(1, 0, 0, 14)
					local who = escaperich(post.name or "??****")
					local metatext = "by " .. who .. "  ·  " .. timeago(post.updated or post.ts)
					if post.cfg_version and post.cfg_version ~= "" then
						metatext = metatext .. "  ·  v" .. escaperich(post.cfg_version)
					end
					meta.Text = metatext
					meta.TextColor3 = theme.Dim
					meta.TextSize = ts(11)
					meta.TextTruncate = Enum.TextTruncate.AtEnd
					meta.TextXAlignment = Enum.TextXAlignment.Left

					-- device needs, and whether this device meets them
					local chips = instance.frame(card)
					chips.BackgroundTransparency = 1
					chips.LayoutOrder = 3
					chips.Size = UDim2.new(1, 0, 0, 18)
					hlist(chips, 10)
					local dev = type(post.device) == "table" and post.device or {}
					local fits, fittext = devicefit(dev)
					local fitchip = tag(chips, fittext, fits and theme.Good or theme.Gold, fits and "circle-check" or "triangle-alert")
					fitchip.LayoutOrder = 0
					for i, field in ipairs({ "ram", "ping", "platform" }) do
						local v = tostring(dev[field] or "Any")
						if v ~= "Any" then
							local chip = tag(chips, deviceprefix[field] .. "  " .. escaperich(v), theme.Dim)
							chip.LayoutOrder = i
						end
					end

					-- short summary, full details on demand
					local _, _, _, _, short = describe(post.config)
					local summaryline = instance.textlabel(card)
					summaryline.BackgroundTransparency = 1
					summaryline.FontFace = FONT_MEDIUM
					summaryline.LayoutOrder = 4
					summaryline.RichText = true
					summaryline.Size = UDim2.new(1, 0, 0, 16)
					summaryline.Text = short
					summaryline.TextColor3 = theme.SubText
					summaryline.TextSize = ts(12)
					summaryline.TextTruncate = Enum.TextTruncate.AtEnd
					summaryline.TextXAlignment = Enum.TextXAlignment.Left

					local details = instance.textlabel(card)
					details.AutomaticSize = Enum.AutomaticSize.Y
					details.BackgroundTransparency = 1
					details.FontFace = FONT_MEDIUM
					details.LayoutOrder = 5
					details.LineHeight = 1.1
					details.RichText = true
					details.Size = UDim2.new(1, 0, 0, 0)
					details.Text = ""
					details.TextColor3 = theme.SubText
					details.TextSize = ts(12)
					details.TextWrapped = true
					details.TextXAlignment = Enum.TextXAlignment.Left
					details.TextYAlignment = Enum.TextYAlignment.Top
					details.Visible = false

					local actions = instance.frame(card)
					actions.BackgroundTransparency = 1
					actions.LayoutOrder = 6
					actions.Size = UDim2.new(1, 0, 0, 26)
					hlist(actions, 6)
					local applyb = button(actions, "Preview & apply", "primary", "eye")
					applyb.frame.LayoutOrder = 1
					local detailsb = button(actions, "Details", "ghost", "chevron-down")
					detailsb.frame.LayoutOrder = 2

					local more
					if post.mine then
						local mytag = tag(card, "Your post", theme.Gold, "star")
						mytag.Parent = actions
						mytag.LayoutOrder = 3
					else
						more = instance.textbutton(top)
						more.AnchorPoint = Vector2.new(1, 0.5)
						more.AutoButtonColor = false
						more.BackgroundTransparency = 1
						more.Position = UDim2.new(1, -like.frame.AbsoluteSize.X - 64, 0.5, 0)
						more.Size = UDim2.new(0, 24, 0, 24)
						more.Text = ""
						local moreicon = icon(more, "ellipsis", 14, theme.SubText)
						moreicon.AnchorPoint = Vector2.new(0.5, 0.5)
						moreicon.Position = UDim2.new(0.5, 0, 0.5, 0)
						-- keep the menu dots just left of the like button
						like.frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
							more.Position = UDim2.new(1, -like.frame.AbsoluteSize.X - 6, 0.5, 0)
						end)
						task.defer(function()
							if more.Parent then
								more.Position = UDim2.new(1, -like.frame.AbsoluteSize.X - 6, 0.5, 0)
							end
						end)
						posttitle.Size = UDim2.new(1, -140, 1, 0)
						more.Activated:Connect(function()
							opencardmenu(more, post, card)
						end)
					end

					applyb.frame.Activated:Connect(function()
						openapply(post)
					end)
					detailsb.frame.Activated:Connect(function()
						elevate()
						details.Visible = not details.Visible
						if details.Visible and details.Text == "" then
							details.Text = (describe(post.config))
						end
						detailsb.label.Text = details.Visible and "Hide details" or "Details"
						summaryline.Visible = not details.Visible
					end)

					local likebusy = false
					like.frame.Activated:Connect(function()
						elevate()
						if post.mine then
							showbanner("You can't like your own post", "info", nil, nil, 3)
							return
						end
						if likebusy then
							return
						end
						likebusy = true
						task.spawn(function()
							local want = not post.liked
							local data, errmsg = forumpost("/forum/like", { id = post.id, on = want and "1" or "0" })
							elevate()
							likebusy = false
							if errmsg then
								showbanner(friendlyerror(errmsg, "liking again"), "bad", nil, nil, 4)
								return
							end
							post.liked = data and data.liked == true
							post.likes = tonumber(data and data.likes) or post.likes
							renderlike()
						end)
					end)

					return card
				end

				local function visibleposts()
					local out = {}
					local q = forum.Search:lower()
					for _, post in ipairs(forum.Posts) do
						local keep = true
						if q ~= "" then
							local hay = (tostring(post.title or "") .. " " .. tostring(post.name or "")):lower()
							keep = hay:find(q, 1, true) ~= nil
						end
						if keep and forum.DeviceFilter ~= "Any" then
							local platform = type(post.device) == "table" and tostring(post.device.platform or "Any") or "Any"
							keep = platform == "Any" or platform == forum.DeviceFilter
						end
						if keep then
							out[#out + 1] = post
						end
					end
					return out
				end

				local morebtn = nil
				local renderedcount = 0

				local function setsubtitle()
					local gamename = forum.Game and forum.Game ~= "" and escaperich(forum.Game) or "This game"
					local total = tonumber(forum.Total) or 0
					local text = gamename .. '  <font color="' .. dimhex .. '">·  ' .. total .. " setup" .. (total == 1 and "" or "s") .. "</font>"
					if forum.Paused then
						text = gamename .. '  <font color="' .. goldhex .. '">·  Maintenance</font>'
					end
					subtitle.Text = text
				end

				local function rendermore()
					if morebtn then
						morebtn:Destroy()
						morebtn = nil
					end
					local filtering = forum.Search ~= "" or forum.DeviceFilter ~= "Any"
					if not filtering and forum.Total and #forum.Posts < forum.Total then
						local b = button(scroll, "Show more  (" .. (forum.Total - #forum.Posts) .. ")", "ghost", "chevron-down")
						b.frame.LayoutOrder = 100000
						morebtn = b.frame
						b.frame.Activated:Connect(function()
							elevate()
							forum.refresh(true)
						end)
					end
				end

				-- full redraw for refresh/sort/filter; "Show more" only adds the new cards
				local function render(appendonly)
					elevate()
					if not appendonly then
						for _, child in ipairs(scroll:GetChildren()) do
							if child.Name == "Post" then
								child:Destroy()
							end
						end
						renderedcount = 0
					end
					local list = visibleposts()
					for i = renderedcount + 1, #list do
						buildcard(list[i], i)
					end
					renderedcount = #list
					emptybox.Visible = #list == 0
					emptyshare.frame.Visible = false
					if #list == 0 then
						if forum.Paused then
							emptytext.Text = "The forum is under maintenance. Check back soon."
						elseif #forum.Posts > 0 then
							emptytext.Text = "No setups match your search."
						else
							emptytext.Text = "No setups shared for this game yet. Be the first!"
							emptyshare.frame.Visible = true
						end
					end
					rendermore()
					setsubtitle()
					updateshare()
				end

				local function updatesort()
					for key, chip in pairs(sortchips) do
						local selected = forum.Sort == key
						chip.frame.BackgroundTransparency = selected and 0 or 1
						chip.label.TextColor3 = selected and theme.AccentText or theme.SubText
					end
				end
				updatesort()

				local spinning = false
				local function setloading(on)
					forum.Loading = on
					scroll.ScrollBarImageTransparency = on and 0.8 or 0
					for _, child in ipairs(scroll:GetChildren()) do
						if child.Name == "Post" then
							child.BackgroundTransparency = on and 0.4 or 0
						end
					end
					if on and not spinning then
						spinning = true
						task.spawn(function()
							while forum.Loading and refreshicon.Parent do
								refreshicon.Rotation = (refreshicon.Rotation + 12) % 360
								task.wait(0.03)
							end
							refreshicon.Rotation = 0
							spinning = false
						end)
					end
				end

				local function showmaintenance(why)
					forum.Paused = true
					forum.Posts = {}
					forum.Total = 0
					forum.Mine = nil
					closelayer()
					render()
					why = cleanwhy(why)
					showbanner("The forum is under maintenance" .. (why ~= "" and ("  ·  " .. why) or ""), "warn")
					sharebtn.setenabled(false)
				end

				forum.refresh = function(append)
					if forum.Busy then
						return
					end
					forum.Busy = true
					setloading(true)
					task.spawn(function()
						local offset = append and #forum.Posts or 0
						local data, errmsg = forumpost("/forum/list", {
							sort = forum.Sort,
							offset = tostring(offset),
							game_name = forum.Game or "",
						})
						elevate()
						forum.Busy = false
						setloading(false)
						if errmsg and tostring(errmsg):match("^maintenance") then
							showmaintenance(tostring(errmsg):match("^maintenance:(.*)"))
							return
						end
						if errmsg or type(data) ~= "table" then
							-- the old list is dropped rather than left under an error
							forum.Posts = {}
							forum.Total = 0
							render()
							emptytext.Text = "Setups couldn't load."
							showbanner(friendlyerror(errmsg or "no response", "refreshing"), "bad", "Retry", function()
								showbanner(nil)
								forum.refresh(false)
							end)
							return
						end
						if forum.Paused then
							forum.Paused = false
							sharebtn.setenabled(true)
						end
						if banner.Visible and banneraction.label.Text == "Retry" then
							showbanner(nil)
						end
						forum.Game = tostring(data.game or forum.Game or "")
						forum.Total = tonumber(data.total) or 0
						forum.Mine = type(data.mine) == "table" and data.mine or nil
						if forum.Mine and not append then
							local d = forum.Mine.device
							if type(d) == "table" then
								for field, renderfield in pairs(reqbuttons) do
									if d[field] then
										forum.Device[field] = tostring(d[field])
										renderfield()
									end
								end
							end
							if titlebox.Text == "" then
								titlebox.Text = tostring(forum.Mine.title or "")
							end
						end
						local posts = type(data.posts) == "table" and data.posts or {}
						forum.MineHidden = data.mine_hidden == true
						if append then
							for _, p in ipairs(posts) do
								forum.Posts[#forum.Posts + 1] = p
							end
							render(true)
						else
							forum.Posts = posts
							scroll.CanvasPosition = Vector2.new(0, 0)
							render()
						end
					end)
				end

				-- live: an open forum closes / reopens as soon as /sync reports the switch
				Chloex:OnPause(function(p)
					elevate()
					if p.forum == true and not forum.Paused then
						showmaintenance(p.forummsg)
					elseif p.forum ~= true and forum.Paused then
						forum.Paused = false
						sharebtn.setenabled(true)
						showbanner(nil)
						forum.refresh(false)
					end
				end)

				local function doshare()
					if forum.Busy then
						return
					end
					if forum.Paused then
						showbanner("The forum is under maintenance, sharing is closed", "warn", nil, nil, 4)
						return
					end
					local cfgtable = collectconfig()
					local _, ons = describe(cfgtable)
					if ons < 1 then
						showbanner("Turn on at least one feature before sharing", "info", nil, nil, 4)
						return
					end
					forum.Busy = true
					confirmshare.label.Text = forum.Mine and "Updating..." or "Sharing..."
					confirmshare.setenabled(false)
					task.spawn(function()
						local data, errmsg = forumpost("/forum/post", {
							title = titlebox.Text,
							config = sv.http:JSONEncode(cfgtable),
							cfg_version = tostring(config.version or ""),
							dev = deviceid(),
							hide = showname and "0" or "1",
							ram = forum.Device.ram,
							ping = forum.Device.ping,
							platform = forum.Device.platform,
							game_name = forum.Game or "",
						})
						elevate()
						forum.Busy = false
						updateshare()
						if errmsg then
							showbanner(friendlyerror(errmsg, "sharing again"), "bad", nil, nil, 5)
							return
						end
						closelayer()
						showbanner(data and data.updated and "Your setup was updated" or "Your setup is live on the forum", "good", nil, nil, 4)
						if not (data and data.updated) then
							forum.Sort = "new"
							updatesort()
						end
						forum.refresh(false)
					end)
				end
				confirmshare.frame.Activated:Connect(function()
					elevate()
					if confirmshare.enabled() then
						doshare()
					end
				end)

				local deleteconfirm = false
				deletebtn.frame.Activated:Connect(function()
					elevate()
					if not forum.Mine or forum.Busy then
						return
					end
					if not deleteconfirm then
						deleteconfirm = true
						deletebtn.label.Text = "Tap again to delete"
						task.delay(3, function()
							deleteconfirm = false
							if deletebtn.label.Parent then
								deletebtn.label.Text = "Delete my post"
							end
						end)
						return
					end
					deleteconfirm = false
					deletebtn.label.Text = "Delete my post"
					task.spawn(function()
						local _, errmsg = forumpost("/forum/delete", { id = forum.Mine.id, dev = deviceid() })
						elevate()
						if errmsg then
							showbanner(friendlyerror(errmsg, "deleting again"), "bad", nil, nil, 5)
							return
						end
						forum.Mine = nil
						closelayer()
						showbanner("Your post was deleted", "info", nil, nil, 3)
						forum.refresh(false)
					end)
				end)

				refreshbtn.Activated:Connect(function()
					elevate()
					pcall(pesseffect, refreshbtn)
					forum.refresh(false)
				end)
				topchip.Activated:Connect(function()
					elevate()
					if forum.Sort ~= "top" and not forum.Busy then
						forum.Sort = "top"
						updatesort()
						forum.refresh(false)
					end
				end)
				newchip.Activated:Connect(function()
					elevate()
					if forum.Sort ~= "new" and not forum.Busy then
						forum.Sort = "new"
						updatesort()
						forum.refresh(false)
					end
				end)

				local searchqueued = false
				search:GetPropertyChangedSignal("Text"):Connect(function()
					forum.Search = search.Text
					if searchqueued then
						return
					end
					searchqueued = true
					task.delay(0.2, function()
						searchqueued = false
						elevate()
						render()
					end)
				end)

				devicebtn.frame.Activated:Connect(function()
					openpicker(devicebtn.frame, { "Any", "PC", "Mobile" }, forum.DeviceFilter, function(option)
						forum.DeviceFilter = option
						devicebtn.label.Text = option == "Any" and "Any device" or option
						render()
					end)
				end)

				-- the share summary only matters while the sheet is open
				task.spawn(function()
					while root.Parent do
						task.wait(1.5)
						if sharesheet.Visible and not forum.Busy then
							elevate()
							pcall(updateshare)
						end
					end
				end)

				task.spawn(function()
					local ok, info = pcall(function()
						return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
					end)
					if ok and type(info) == "table" and info.Name and not forum.Game then
						forum.Game = tostring(info.Name)
						elevate()
						setsubtitle()
					end
					local t0 = os.clock()
					while not backend and os.clock() - t0 < 15 do
						task.wait(0.5)
					end
					-- the server only accepts players it has seen on /sync; give the first one a moment
					local t1 = os.clock()
					while backend and not backend.Connected and os.clock() - t1 < 10 do
						task.wait(0.5)
					end
					elevate()
					forum.refresh(false)
				end)

				local api = {}
				api.Refresh = function()
					forum.refresh(false)
				end
				api.Share = function()
					openshare()
				end
				-- works as api.Inject(cfg) and api:Inject(cfg)
				api.Inject = function(a, b)
					local cfgtable = a
					if a == api then
						cfgtable = b
					end
					return injectconfig(cfgtable)
				end
				api.Describe = function(a, b)
					local cfgtable = b
					if a ~= api and b == nil then
						cfgtable = a
					end
					return (describe(cfgtable))
				end
				return api
			end

			countsection = countsection + 1
			return items
		end

		tabentries[#tabentries + 1] = {
			tab = tab,
			page = scrollayers,
			select = selecttab,
			order = layoutOrder,
			gated = tabgated,
			first = isFirstTab,
			name = tabconfig.Name,
		}
		applykeygate()

		counttab = counttab + 1
		-- kept for Chloe X scripts that reach tabs through _G, but never over an
		-- existing global (a tab named "Config" or "Settings" used to clobber it)
		local safename = tabconfig.Name:gsub("%s+", "_")
		if _G[safename] == nil then
			_G[safename] = sections
		end
		return sections
	end

	if guiconfig.AutoConfigTab then
		local ConfigTab = tabs:AddTab({
			Name = "Config",
			Icon = "settings",
			LayoutOrder = 1000000,
			StartActive = false,
		})

		local function buildConfigTab()
			local ConfigSection = ConfigTab:AddSection("Config Configuration", true)
			ConfigSection:AddConfigPanel()
		end

		if guiconfig.LazyConfigTab then
			ConfigTab:OnOpen(buildConfigTab)
		else
			buildConfigTab()
		end
	end

	function tabs:AddForum(forumconfig)
		forumconfig = forumconfig or {}
		local forumtab = tabs:AddTab({
			Name = forumconfig.Name or "Forum",
			Icon = forumconfig.Icon or "forum",
			LayoutOrder = forumconfig.LayoutOrder,
			StartActive = false,
		})
		local holder = { Tab = forumtab }
		forumtab:OnOpen(function()
			-- headerless: the forum carries its own title, no second heading above it
			local section = forumtab:AddSection({ Header = false })
			holder.Forum = section:AddForum(forumconfig)
		end)
		return holder
	end

	if guiconfig.ForumTab then
		local forumtabconfig = type(guiconfig.ForumTab) == "table" and guiconfig.ForumTab or {}
		forumtabconfig.LayoutOrder = forumtabconfig.LayoutOrder or 999999
		tabs:AddForum(forumtabconfig)
	end

	tabs.Notify = function(self, ...)
		return Chloex:Notify(...)
	end

	return tabs
end

task.defer(function()
	elevate()
	local ok, cfg = pcall(function()
		return getgenv and getgenv().SenaBackend
	end)
	Chloex:ConnectBackend((ok and type(cfg) == "table") and cfg or {})
end)

Chloex.Elevate = elevate
function Chloex:Elevate()
	elevate()
end

-- Lucide icon (or asset id) on any ImageLabel / ImageButton, same pack the window
-- uses. Works as Chloex.ApplyIcon(image, name) and Chloex:ApplyIcon(image, name).
function Chloex.ApplyIcon(a, b, c, d)
	if a == Chloex then
		a, b, c = b, c, d
	end
	return applyicon(a, b, c)
end

getgenv().ChloeX = Chloex

return Chloex
