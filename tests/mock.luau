-- Mini-simulateur Roblox pour tester les scripts hors de Studio.
-- Valide les propriétés / méthodes / enums avec le dump officiel de l'API.

local API = require("./api_data")

local M = {}
M.errors = {}
M.warnings = {}
M.now = 0
M.context = "server"

local function report(kind, msg)
	table.insert(M.errors, "[" .. kind .. "] " .. tostring(msg))
end

------------------------------------------------------------------
-- SCHEDULER
------------------------------------------------------------------
local queue = {}
local threadContext = setmetatable({}, {__mode = "k"})

local function resume(thread, ...)
	local previous = M.context
	M.context = threadContext[thread] or previous
	local ok, err = coroutine.resume(thread, ...)
	M.context = previous
	if not ok then
		report(threadContext[thread] or "?", debug.traceback(thread, tostring(err)))
	end
end

local function spawnFn(fn, ...)
	local thread = coroutine.create(fn)
	threadContext[thread] = M.context
	resume(thread, ...)
	return thread
end
M.spawn = spawnFn

local function schedule(thread, delay, ...)
	table.insert(queue, {thread = thread, wake = M.now + (delay or 0), args = table.pack(...)})
end

function M.runFor(seconds, onFrame)
	local target = M.now + seconds
	local frame = 1 / 30
	while M.now < target do
		local stepEnd = math.min(M.now + frame, target)
		-- réveille les threads dont l'heure est passée
		local progressed = true
		while progressed do
			progressed = false
			table.sort(queue, function(a, b) return a.wake < b.wake end)
			local entry = queue[1]
			if entry and entry.wake <= stepEnd then
				table.remove(queue, 1)
				if entry.wake > M.now then M.now = entry.wake end
				if coroutine.status(entry.thread) == "suspended" then
					resume(entry.thread, table.unpack(entry.args, 1, entry.args.n))
				end
				progressed = true
			end
		end
		M.now = stepEnd
		if onFrame then onFrame(frame) end
	end
end

M.task = {
	spawn = function(fn, ...)
		if type(fn) == "thread" then
			resume(fn, ...)
			return fn
		end
		return spawnFn(fn, ...)
	end,
	defer = function(fn, ...)
		local thread = coroutine.create(fn)
		threadContext[thread] = M.context
		schedule(thread, 0, ...)
		return thread
	end,
	delay = function(delay, fn, ...)
		local thread = coroutine.create(fn)
		threadContext[thread] = M.context
		schedule(thread, delay or 0, ...)
		return thread
	end,
	wait = function(delay)
		local thread = coroutine.running()
		schedule(thread, math.max(delay or 0, 1 / 60))
		coroutine.yield()
		return delay or 0
	end,
	cancel = function(thread) end,
}

------------------------------------------------------------------
-- SIGNALS
------------------------------------------------------------------
local Signal = {}
Signal.__index = Signal
function Signal.new(name)
	return setmetatable({handlers = {}, waiting = {}, name = name}, Signal)
end
function Signal:Connect(fn)
	assert(type(fn) == "function", "Attempt to connect failed: Passed value is not a function")
	local connection = {Connected = true, fn = fn, context = M.context}
	function connection.Disconnect() connection.Connected = false end
	table.insert(self.handlers, connection)
	return connection
end
function Signal:Once(fn)
	local c
	c = self:Connect(function(...)
		c.Disconnect()
		fn(...)
	end)
	return c
end
function Signal:Wait()
	local thread = coroutine.running()
	table.insert(self.waiting, thread)
	return coroutine.yield()
end
function Signal:Fire(...)
	for _, c in ipairs(table.clone(self.handlers)) do
		if c.Connected then
			local previous = M.context
			M.context = c.context
			spawnFn(c.fn, ...)
			M.context = previous
		end
	end
	local waiting = self.waiting
	self.waiting = {}
	for _, thread in ipairs(waiting) do
		resume(thread, ...)
	end
end
M.Signal = Signal

------------------------------------------------------------------
-- DATA TYPES
------------------------------------------------------------------
local typeNames = setmetatable({}, {__mode = "k"})
local function makeType(name)
	local mt = {}
	mt.__index = mt
	typeNames[mt] = name
	return mt
end

function M.typeof(value)
	local mt = getmetatable(value)
	if mt and typeNames[mt] then return typeNames[mt] end
	if mt and mt.__isInstance then return "Instance" end
	return type(value)
end

-- Vector3
local V3 = makeType("Vector3")
local function v3(x, y, z)
	return setmetatable({X = x or 0, Y = y or 0, Z = z or 0}, V3)
end
V3.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then return v3(a * b.X, a * b.Y, a * b.Z) end
	if type(b) == "number" then return v3(a.X * b, a.Y * b, a.Z * b) end
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then return v3(a.X / b, a.Y / b, a.Z / b) end
	return v3(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__unm = function(a) return v3(-a.X, -a.Y, -a.Z) end
V3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
V3.__tostring = function(a) return string.format("%g, %g, %g", a.X, a.Y, a.Z) end
V3.__index = function(self, key)
	if key == "Magnitude" then return math.sqrt(self.X ^ 2 + self.Y ^ 2 + self.Z ^ 2) end
	if key == "Unit" then
		local m = math.sqrt(self.X ^ 2 + self.Y ^ 2 + self.Z ^ 2)
		if m == 0 then return v3(0 / 0, 0 / 0, 0 / 0) end
		return v3(self.X / m, self.Y / m, self.Z / m)
	end
	if key == "Dot" then return function(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end end
	if key == "Cross" then return function(a, b) return v3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X) end end
	if key == "Lerp" then return function(a, b, t) return a + (b - a) * t end end
	if key == "Abs" then return function(a) return v3(math.abs(a.X), math.abs(a.Y), math.abs(a.Z)) end end
	error(tostring(key) .. " is not a valid member of Vector3", 2)
end
M.Vector3 = {
	new = v3,
	zero = v3(0, 0, 0),
	one = v3(1, 1, 1),
	xAxis = v3(1, 0, 0), yAxis = v3(0, 1, 0), zAxis = v3(0, 0, 1),
}

-- Vector2
local V2 = makeType("Vector2")
local function v2(x, y) return setmetatable({X = x or 0, Y = y or 0}, V2) end
V2.__add = function(a, b) return v2(a.X + b.X, a.Y + b.Y) end
V2.__sub = function(a, b) return v2(a.X - b.X, a.Y - b.Y) end
V2.__mul = function(a, b)
	if type(b) == "number" then return v2(a.X * b, a.Y * b) end
	if type(a) == "number" then return v2(b.X * a, b.Y * a) end
	return v2(a.X * b.X, a.Y * b.Y)
end
V2.__div = function(a, b) return v2(a.X / b, a.Y / b) end
V2.__index = function(self, key)
	if key == "Magnitude" then return math.sqrt(self.X ^ 2 + self.Y ^ 2) end
	error(tostring(key) .. " is not a valid member of Vector2", 2)
end
M.Vector2 = {new = v2, zero = v2(0, 0), one = v2(1, 1)}

-- CFrame (position + matrice 3x3 : colonnes = axes X, Y, Z)
local CF = makeType("CFrame")
local function cf(p, r)
	return setmetatable({p = p, r = r or {1, 0, 0, 0, 1, 0, 0, 0, 1}}, CF)
end
-- r = {r00, r01, r02, r10, r11, r12, r20, r21, r22}
local function mulR(a, b)
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			local s = 0
			for k = 0, 2 do
				s += a[i * 3 + k + 1] * b[k * 3 + j + 1]
			end
			r[i * 3 + j + 1] = s
		end
	end
	return r
end
local function rotVec(r, v)
	return v3(
		r[1] * v.X + r[2] * v.Y + r[3] * v.Z,
		r[4] * v.X + r[5] * v.Y + r[6] * v.Z,
		r[7] * v.X + r[8] * v.Y + r[9] * v.Z
	)
end
local function transpose(r)
	return {r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9]}
end
CF.__mul = function(a, b)
	if M.typeof(b) == "Vector3" then
		return a.p + rotVec(a.r, b)
	end
	return cf(a.p + rotVec(a.r, b.p), mulR(a.r, b.r))
end
CF.__add = function(a, b) return cf(a.p + b, a.r) end
CF.__sub = function(a, b) return cf(a.p - b, a.r) end
CF.__index = function(self, key)
	if key == "Position" or key == "p" then return self.p end
	if key == "X" then return self.p.X end
	if key == "Y" then return self.p.Y end
	if key == "Z" then return self.p.Z end
	if key == "LookVector" then return -v3(self.r[3], self.r[6], self.r[9]) end
	if key == "RightVector" then return v3(self.r[1], self.r[4], self.r[7]) end
	if key == "UpVector" then return v3(self.r[2], self.r[5], self.r[8]) end
	if key == "Rotation" then return cf(v3(), self.r) end
	if key == "Inverse" then
		return function(s)
			local rt = transpose(s.r)
			return cf(-rotVec(rt, s.p), rt)
		end
	end
	if key == "VectorToWorldSpace" then return function(s, v) return rotVec(s.r, v) end end
	if key == "VectorToObjectSpace" then return function(s, v) return rotVec(transpose(s.r), v) end end
	if key == "PointToWorldSpace" then return function(s, v) return s * v end end
	if key == "PointToObjectSpace" then return function(s, v) return rotVec(transpose(s.r), v - s.p) end end
	if key == "ToWorldSpace" then return function(s, c) return s * c end end
	if key == "ToObjectSpace" then return function(s, c) return s:Inverse() * c end end
	if key == "Lerp" then return function(s, c, t) return cf(s.p + (c.p - s.p) * t, t < 0.5 and s.r or c.r) end end
	error(tostring(key) .. " is not a valid member of CFrame", 2)
end
local function angles(rx, ry, rz)
	local cx, sx = math.cos(rx), math.sin(rx)
	local cy, sy = math.cos(ry), math.sin(ry)
	local cz, sz = math.cos(rz), math.sin(rz)
	local RX = {1, 0, 0, 0, cx, -sx, 0, sx, cx}
	local RY = {cy, 0, sy, 0, 1, 0, -sy, 0, cy}
	local RZ = {cz, -sz, 0, sz, cz, 0, 0, 0, 1}
	return mulR(mulR(RX, RY), RZ)
end
local function lookAt(pos, target)
	local look = (target - pos)
	if look.Magnitude < 1e-6 then return cf(pos) end
	look = look.Unit
	local up = v3(0, 1, 0)
	if math.abs(look:Dot(up)) > 0.999 then up = v3(0, 0, 1) end
	local right = look:Cross(up).Unit
	local realUp = right:Cross(look).Unit
	local back = -look
	return cf(pos, {right.X, realUp.X, back.X, right.Y, realUp.Y, back.Y, right.Z, realUp.Z, back.Z})
end
M.CFrame = {
	new = function(a, b, c, ...)
		if a == nil then return cf(v3()) end
		if type(a) == "number" then
			local extra = {...}
			if #extra == 9 then
				return cf(v3(a, b, c), extra)
			end
			return cf(v3(a, b, c))
		end
		if b ~= nil then return lookAt(a, b) end
		return cf(a)
	end,
	Angles = function(x, y, z) return cf(v3(), angles(x or 0, y or 0, z or 0)) end,
	fromEulerAnglesXYZ = function(x, y, z) return cf(v3(), angles(x or 0, y or 0, z or 0)) end,
	lookAt = lookAt,
	fromMatrix = function(pos, vx, vy, vz)
		vz = vz or vx:Cross(vy)
		return cf(pos, {vx.X, vy.X, vz.X, vx.Y, vy.Y, vz.Y, vx.Z, vy.Z, vz.Z})
	end,
	identity = cf(v3()),
}

-- Color3
local C3 = makeType("Color3")
local function c3(r, g, b) return setmetatable({R = r or 0, G = g or 0, B = b or 0}, C3) end
C3.__index = function(self, key)
	if key == "Lerp" then
		return function(a, b, t) return c3(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t) end
	end
	if key == "ToHSV" then return function() return 0, 0, 0 end end
	error(tostring(key) .. " is not a valid member of Color3", 2)
end
C3.__eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end
M.Color3 = {
	new = c3,
	fromRGB = function(r, g, b)
		assert(type(r) == "number" and type(g) == "number" and type(b) == "number", "Color3.fromRGB expects numbers")
		return c3(r / 255, g / 255, b / 255)
	end,
	fromHSV = function(h, s, v) return c3(v, v, v) end,
}

-- UDim / UDim2
local UD = makeType("UDim")
local function udim(s, o) return setmetatable({Scale = s or 0, Offset = o or 0}, UD) end
UD.__add = function(a, b) return udim(a.Scale + b.Scale, a.Offset + b.Offset) end
local UD2 = makeType("UDim2")
local function udim2(xs, xo, ys, yo) return setmetatable({X = udim(xs, xo), Y = udim(ys, yo), Width = udim(xs, xo), Height = udim(ys, yo)}, UD2) end
UD2.__add = function(a, b) return udim2(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset) end
UD2.__sub = function(a, b) return udim2(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset) end
M.UDim = {new = udim}
M.UDim2 = {
	new = function(xs, xo, ys, yo)
		for _, v in ipairs({xs or 0, xo or 0, ys or 0, yo or 0}) do
			assert(type(v) == "number", "UDim2.new expects numbers")
		end
		return udim2(xs, xo, ys, yo)
	end,
	fromScale = function(x, y) return udim2(x, 0, y, 0) end,
	fromOffset = function(x, y) return udim2(0, x, 0, y) end,
}

-- Séquences, plages, etc.
local CSK = makeType("ColorSequenceKeypoint")
local CS = makeType("ColorSequence")
M.ColorSequenceKeypoint = {new = function(t, c)
	assert(M.typeof(c) == "Color3", "ColorSequenceKeypoint expects Color3")
	return setmetatable({Time = t, Value = c}, CSK)
end}
M.ColorSequence = {new = function(a, b)
	if M.typeof(a) == "Color3" then
		assert(b == nil or M.typeof(b) == "Color3", "ColorSequence.new : Color3 attendu")
		return setmetatable({Keypoints = {}}, CS)
	end
	assert(type(a) == "table", "ColorSequence.new : table attendue")
	return setmetatable({Keypoints = a}, CS)
end}
local NSK = makeType("NumberSequenceKeypoint")
local NS = makeType("NumberSequence")
M.NumberSequenceKeypoint = {new = function(t, v) return setmetatable({Time = t, Value = v}, NSK) end}
M.NumberSequence = {new = function(a, b)
	if type(a) == "number" then return setmetatable({Keypoints = {}}, NS) end
	assert(type(a) == "table", "NumberSequence.new : table attendue")
	return setmetatable({Keypoints = a}, NS)
end}
local NR = makeType("NumberRange")
M.NumberRange = {new = function(a, b) return setmetatable({Min = a, Max = b or a}, NR) end}
local TI = makeType("TweenInfo")
M.TweenInfo = {new = function(time, style, dir)
	if style ~= nil then assert(M.typeof(style) == "EnumItem", "TweenInfo : EasingStyle attendu") end
	return setmetatable({Time = time or 1}, TI)
end}
local RP = makeType("RaycastParams")
M.RaycastParams = {new = function()
	return setmetatable({FilterType = nil, FilterDescendantsInstances = {}}, {__index = function() return nil end, __newindex = rawset})
end}
local RND = makeType("Random")
M.Random = {new = function(seed)
	return setmetatable({}, {__index = {
		NextNumber = function(_, a, b)
			a = a or 0
			b = b or 1
			return a + math.random() * (b - a)
		end,
		NextInteger = function(_, a, b) return math.random(a, b) end,
	}})
end}

------------------------------------------------------------------
-- ENUMS
------------------------------------------------------------------
local EI = makeType("EnumItem")
EI.__tostring = function(self) return "Enum." .. self.EnumType.Name .. "." .. self.Name end
EI.__index = function(self, key)
	error(tostring(key) .. " is not a valid member of EnumItem", 2)
end
local enumCache = {}
local EnumType = {}
EnumType.__index = function(self, key)
	if key == "GetEnumItems" then
		return function(s)
			local list = {}
			for name in pairs(API.enums[rawget(s, "Name")]) do
				table.insert(list, s[name])
			end
			return list
		end
	end
	local items = API.enums[rawget(self, "Name")]
	if items[key] == nil then
		error(tostring(key) .. " is not a valid member of \"Enum." .. rawget(self, "Name") .. "\"", 2)
	end
	local item = setmetatable({Name = key, Value = items[key], EnumType = self}, EI)
	rawset(self, key, item)
	return item
end
M.Enum = setmetatable({}, {__index = function(_, name)
	if not API.enums[name] then
		error(tostring(name) .. " is not a valid member of \"Enums\"", 2)
	end
	if not enumCache[name] then
		enumCache[name] = setmetatable({Name = name}, EnumType)
	end
	return enumCache[name]
end})

------------------------------------------------------------------
-- INSTANCES
------------------------------------------------------------------
local data = setmetatable({}, {__mode = "k"})
local InstanceMT = {__isInstance = true}
M.data = data

local memberCache = {}
local function findMember(className, key)
	memberCache[className] = memberCache[className] or {}
	local cached = memberCache[className][key]
	if cached ~= nil then return cached or nil end
	local cls = API.classes[className]
	while cls do
		local m = cls.members[key]
		if m then
			memberCache[className][key] = m
			return m
		end
		cls = API.classes[cls.super]
	end
	memberCache[className][key] = false
	return nil
end

local function isA(className, target)
	local name = className
	while name and name ~= "<<<ROOT>>>" do
		if name == target then return true end
		local cls = API.classes[name]
		name = cls and cls.super
	end
	return false
end
M.isA = isA

local function fullName(inst)
	local parts = {}
	local cur = inst
	while cur do
		table.insert(parts, 1, data[cur].Name)
		cur = data[cur].Parent
	end
	return table.concat(parts, ".")
end

local DEFAULT_TRUE = {
	Visible = true, Enabled = true, CanCollide = true, CanQuery = true, CanTouch = true, Archivable = true,
	AutoButtonColor = true, RequiresHandle = true, CanBeDropped = true, Active = false,
}

local function defaultValue(inst, key, member)
	local d = data[inst]
	local className = d.ClassName
	if member.c == "Primitive" then
		if member.t == "bool" then return DEFAULT_TRUE[key] or false end
		if member.t == "string" then return "" end
		if key == "Scale" then return 1 end
		if key == "Thickness" then return 1 end
		if key == "Volume" then return 0.5 end
		if key == "PlaybackSpeed" then return 1 end
		if key == "FieldOfView" then return 70 end
		if key == "Health" or key == "MaxHealth" then return 100 end
		if key == "WalkSpeed" then return 16 end
		if key == "UserId" then return d.userId or 0 end
		return 0
	end
	if member.c == "DataType" then
		local t = member.t
		if t == "Vector3" then
			if key == "Size" and isA(className, "BasePart") then return v3(4, 1, 2) end
			return v3()
		end
		if t == "Vector2" then
			if key == "ViewportSize" then return v2(1280, 720) end
			return v2()
		end
		if t == "CFrame" then return cf(v3()) end
		if t == "Color3" then return c3(0.64, 0.64, 0.64) end
		if t == "UDim2" then return udim2(0, 0, 0, 0) end
		if t == "UDim" then return udim(0, 0) end
		if t == "Content" or t == "ContentId" then return "" end
		if t == "ColorSequence" then return M.ColorSequence.new(c3(1, 1, 1)) end
		if t == "NumberSequence" then return M.NumberSequence.new(0) end
		if t == "NumberRange" then return M.NumberRange.new(0, 0) end
		return nil
	end
	if member.c == "Enum" then
		local items = API.enums[member.t]
		local first
		for name, value in pairs(items) do
			if not first or value < items[first] then first = name end
		end
		return first and M.Enum[member.t][first] or nil
	end
	return nil
end

local function checkType(inst, key, member, value)
	local className = data[inst].ClassName
	local function fail(expected)
		error(string.format("Unable to assign property %s. %s expected, got %s (%s)", key, expected, M.typeof(value), className), 3)
	end
	if member.c == "Primitive" then
		local t = member.t
		if t == "bool" then
			if type(value) ~= "boolean" then fail("bool") end
		elseif t == "string" then
			if type(value) ~= "string" and type(value) ~= "number" then fail("string") end
		elseif type(value) ~= "number" then
			fail("number")
		elseif value ~= value then
			fail("number (NaN)")
		end
	elseif member.c == "DataType" then
		local t = member.t
		if t == "Content" or t == "ContentId" then
			if type(value) ~= "string" then fail("Content") end
		elseif ({Vector3 = 1, Vector2 = 1, CFrame = 1, Color3 = 1, UDim2 = 1, UDim = 1, ColorSequence = 1, NumberSequence = 1, NumberRange = 1})[t] then
			if M.typeof(value) ~= t then fail(t) end
			if t == "Vector3" and (value.X ~= value.X or value.Y ~= value.Y or value.Z ~= value.Z) then fail("Vector3 (NaN)") end
		end
	elseif member.c == "Enum" then
		if M.typeof(value) == "EnumItem" then
			if value.EnumType.Name ~= member.t then fail("Enum." .. member.t) end
		elseif type(value) ~= "number" and type(value) ~= "string" then
			fail("Enum." .. member.t)
		end
	elseif member.c == "Class" then
		if value ~= nil and M.typeof(value) ~= "Instance" then fail(member.t) end
	end
end

local function getSignal(inst, key)
	local d = data[inst]
	d.signals[key] = d.signals[key] or Signal.new(key)
	return d.signals[key]
end
M.getSignal = getSignal

local function firePropChanged(inst, key, value)
	local d = data[inst]
	if d.propSignals[key] then d.propSignals[key]:Fire() end
	if d.signals.Changed then
		if isA(d.ClassName, "ValueBase") then
			if key == "Value" then d.signals.Changed:Fire(value) end
		else
			d.signals.Changed:Fire(key)
		end
	end
end

local tagged = {} -- tag -> set
local tagAdded = {}
local tagRemoved = {}
local function tagSignal(list, tag)
	list[tag] = list[tag] or Signal.new(tag)
	return list[tag]
end

local function isInGame(inst)
	local cur = inst
	while cur do
		if cur == M.game then return true end
		cur = data[cur].Parent
	end
	return false
end

local function setParent(inst, newParent)
	local d = data[inst]
	if d.destroyed then
		error("The Parent property of " .. d.Name .. " is locked, current parent: NULL, new parent " .. tostring(newParent and data[newParent].Name), 3)
	end
	if newParent ~= nil and M.typeof(newParent) ~= "Instance" then
		error("Unable to assign property Parent. Instance expected", 3)
	end
	local old = d.Parent
	if old == newParent then return end
	-- empêche les boucles
	local cur = newParent
	while cur do
		if cur == inst then error("Attempt to set parent of " .. d.Name .. " to itself or a descendant", 3) end
		cur = data[cur].Parent
	end
	if old then
		local od = data[old]
		local idx = table.find(od.children, inst)
		if idx then table.remove(od.children, idx) end
		if od.signals.ChildRemoved then od.signals.ChildRemoved:Fire(inst) end
		local anc = old
		while anc do
			if data[anc].signals.DescendantRemoving then data[anc].signals.DescendantRemoving:Fire(inst) end
			anc = data[anc].Parent
		end
	end
	d.Parent = newParent
	if newParent then
		table.insert(data[newParent].children, inst)
		local nd = data[newParent]
		if nd.signals.ChildAdded then nd.signals.ChildAdded:Fire(inst) end
		local function fireDesc(obj)
			local anc = newParent
			while anc do
				if data[anc].signals.DescendantAdded then data[anc].signals.DescendantAdded:Fire(obj) end
				anc = data[anc].Parent
			end
		end
		fireDesc(inst)
		for _, desc in ipairs(inst:GetDescendants()) do
			fireDesc(desc)
		end
	end
	firePropChanged(inst, "Parent", newParent)
	if d.signals.AncestryChanged then d.signals.AncestryChanged:Fire(inst, newParent) end
end

local Methods = {}

InstanceMT.__index = function(inst, key)
	local d = data[inst]
	if key == "Name" then return d.Name end
	if key == "ClassName" then return d.ClassName end
	if key == "Parent" then return d.Parent end
	if d.special and d.special[key] ~= nil then
		local v = d.special[key]
		if type(v) == "function" and key:sub(1, 1) == "_" then return v end
	end
	local member = findMember(d.ClassName, key)
	if member then
		if member.k == "P" then
			if d.getters and d.getters[key] then return d.getters[key](inst) end
			local v = d.props[key]
			if v == nil then
				v = defaultValue(inst, key, member)
			end
			return v
		elseif member.k == "F" then
			local impl = (d.methods and d.methods[key]) or Methods[key]
			if impl then return impl end
			return function() table.insert(M.warnings, "méthode non simulée : " .. d.ClassName .. ":" .. key) return nil end
		elseif member.k == "E" then
			return getSignal(inst, key)
		elseif member.k == "C" then
			return d.props[key]
		end
	end
	for _, child in ipairs(d.children) do
		if data[child].Name == key then return child end
	end
	error(tostring(key) .. " is not a valid member of " .. d.ClassName .. " \"" .. fullName(inst) .. "\"", 2)
end

InstanceMT.__newindex = function(inst, key, value)
	local d = data[inst]
	if key == "Parent" then
		setParent(inst, value)
		return
	end
	if key == "Name" then
		if type(value) ~= "string" and type(value) ~= "number" then error("Name doit être un string", 2) end
		d.Name = tostring(value)
		firePropChanged(inst, "Name", value)
		return
	end
	local member = findMember(d.ClassName, key)
	if not member then
		error(tostring(key) .. " is not a valid member of " .. d.ClassName .. " \"" .. fullName(inst) .. "\"", 2)
	end
	if member.k == "C" then
		d.props[key] = value
		return
	end
	if member.k ~= "P" then
		error(tostring(key) .. " is not a valid member of " .. d.ClassName .. " (on ne peut pas assigner une méthode/événement)", 2)
	end
	if member.ro and not d.allowWrite then
		error("Unable to assign property " .. key .. ". Property is read only", 2)
	end
	checkType(inst, key, member, value)
	if d.setters and d.setters[key] then
		d.setters[key](inst, value)
	else
		d.props[key] = value
	end
	firePropChanged(inst, key, value)
end

InstanceMT.__tostring = function(inst) return data[inst].Name end

local function rawNew(className, internal)
	local cls = API.classes[className]
	if not cls then error("Unable to create an Instance of type \"" .. tostring(className) .. "\"", 3) end
	if not cls.creatable and not internal then
		error("Unable to create an Instance of type \"" .. className .. "\"", 3)
	end
	local inst = setmetatable({}, InstanceMT)
	data[inst] = {
		ClassName = className, Name = className, Parent = nil, children = {}, props = {}, attrs = {},
		signals = {}, propSignals = {}, attrSignals = {}, tags = {},
	}
	-- BasePart : Position <-> CFrame
	if isA(className, "BasePart") then
		local dd = data[inst]
		dd.props.CFrame = cf(v3())
		dd.getters = {
			Position = function(i) return data[i].props.CFrame.p end,
			Orientation = function() return v3() end,
		}
		dd.setters = {
			Position = function(i, v) data[i].props.CFrame = cf(v, data[i].props.CFrame.r) end,
			CFrame = function(i, v) data[i].props.CFrame = v end,
		}
	end
	return inst
end
M.rawNew = rawNew

M.Instance = {
	new = function(className, parent)
		local inst = rawNew(className, false)
		if parent then inst.Parent = parent end
		return inst
	end,
}

-- ===== Méthodes communes =====
function Methods.FindFirstChild(self, name, recursive)
	for _, child in ipairs(data[self].children) do
		if data[child].Name == name then return child end
	end
	if recursive then
		for _, child in ipairs(data[self].children) do
			local found = Methods.FindFirstChild(child, name, true)
			if found then return found end
		end
	end
	return nil
end
function Methods.FindFirstChildOfClass(self, className)
	for _, child in ipairs(data[self].children) do
		if data[child].ClassName == className then return child end
	end
	return nil
end
function Methods.FindFirstChildWhichIsA(self, className)
	for _, child in ipairs(data[self].children) do
		if isA(data[child].ClassName, className) then return child end
	end
	return nil
end
function Methods.FindFirstAncestorOfClass(self, className)
	local cur = data[self].Parent
	while cur do
		if data[cur].ClassName == className then return cur end
		cur = data[cur].Parent
	end
	return nil
end
function Methods.FindFirstAncestorWhichIsA(self, className)
	local cur = data[self].Parent
	while cur do
		if isA(data[cur].ClassName, className) then return cur end
		cur = data[cur].Parent
	end
	return nil
end
function Methods.WaitForChild(self, name, timeout)
	local found = Methods.FindFirstChild(self, name)
	local waited = 0
	while not found do
		if coroutine.isyieldable() then
			M.task.wait(0.05)
			waited += 0.05
		else
			error("WaitForChild appelé hors coroutine pour " .. name)
		end
		found = Methods.FindFirstChild(self, name)
		if not found and waited > (timeout or 10) then
			if timeout then return nil end
			report("WaitForChild", "Infinite yield possible on '" .. fullName(self) .. ":WaitForChild(\"" .. name .. "\")'")
			return nil
		end
	end
	return found
end
function Methods.GetChildren(self)
	return table.clone(data[self].children)
end
function Methods.GetDescendants(self)
	local list = {}
	local function walk(obj)
		for _, child in ipairs(data[obj].children) do
			table.insert(list, child)
			walk(child)
		end
	end
	walk(self)
	return list
end
function Methods.IsA(self, className)
	return isA(data[self].ClassName, className)
end
function Methods.IsDescendantOf(self, other)
	local cur = data[self].Parent
	while cur do
		if cur == other then return true end
		cur = data[cur].Parent
	end
	return false
end
function Methods.IsAncestorOf(self, other)
	return Methods.IsDescendantOf(other, self)
end
function Methods.GetFullName(self) return fullName(self) end
function Methods.Destroy(self)
	local d = data[self]
	if d.destroyed then return end
	for _, child in ipairs(table.clone(d.children)) do
		Methods.Destroy(child)
	end
	if d.Parent then setParent(self, nil) end
	for tag in pairs(d.tags) do
		if tagged[tag] then tagged[tag][self] = nil end
		if tagRemoved[tag] then tagRemoved[tag]:Fire(self) end
	end
	d.destroyed = true
	if d.signals.Destroying then d.signals.Destroying:Fire() end
end
function Methods.ClearAllChildren(self)
	for _, child in ipairs(table.clone(data[self].children)) do
		Methods.Destroy(child)
	end
end
function Methods.Clone(self)
	local d = data[self]
	local copy = rawNew(d.ClassName, true)
	local cd = data[copy]
	cd.Name = d.Name
	for k, v in pairs(d.props) do cd.props[k] = v end
	for k, v in pairs(d.attrs) do cd.attrs[k] = v end
	for _, child in ipairs(d.children) do
		Methods.Clone(child).Parent = copy
	end
	return copy
end
function Methods.SetAttribute(self, name, value)
	local t = M.typeof(value)
	local allowed = {["nil"] = 1, boolean = 1, number = 1, string = 1, Vector3 = 1, Vector2 = 1, CFrame = 1, Color3 = 1, UDim2 = 1, UDim = 1, EnumItem = 1, ColorSequence = 1, NumberSequence = 1, NumberRange = 1}
	if not allowed[t] then
		error("SetAttribute : type non supporté (" .. t .. ") pour " .. name, 2)
	end
	local d = data[self]
	local old = d.attrs[name]
	d.attrs[name] = value
	if old ~= value then
		if d.attrSignals[name] then d.attrSignals[name]:Fire() end
		if d.signals.AttributeChanged then d.signals.AttributeChanged:Fire(name) end
	end
end
function Methods.GetAttribute(self, name) return data[self].attrs[name] end
function Methods.GetAttributes(self) return table.clone(data[self].attrs) end
function Methods.GetAttributeChangedSignal(self, name)
	local d = data[self]
	d.attrSignals[name] = d.attrSignals[name] or Signal.new("attr:" .. name)
	return d.attrSignals[name]
end
function Methods.GetPropertyChangedSignal(self, name)
	local d = data[self]
	if not findMember(d.ClassName, name) and name ~= "Name" and name ~= "Parent" then
		error(name .. " is not a valid property name.", 2)
	end
	d.propSignals[name] = d.propSignals[name] or Signal.new("prop:" .. name)
	return d.propSignals[name]
end
function Methods.AddTag(self, tag) M.addTag(self, tag) end
function Methods.RemoveTag(self, tag) M.removeTag(self, tag) end
function Methods.HasTag(self, tag) return data[self].tags[tag] == true end
function Methods.PivotTo(self, target)
	assert(M.typeof(target) == "CFrame", "PivotTo attend un CFrame")
	local d = data[self]
	if isA(d.ClassName, "BasePart") then
		d.props.CFrame = target
		return
	end
	local pivot = Methods.GetPivot(self)
	local delta = target * pivot:Inverse()
	for _, desc in ipairs(Methods.GetDescendants(self)) do
		if isA(data[desc].ClassName, "BasePart") then
			data[desc].props.CFrame = delta * data[desc].props.CFrame
		end
	end
	d.props.WorldPivot = target
end
function Methods.GetPivot(self)
	local d = data[self]
	if isA(d.ClassName, "BasePart") then return d.props.CFrame end
	local primary = d.props.PrimaryPart
	if primary then return data[primary].props.CFrame end
	if d.props.WorldPivot then return d.props.WorldPivot end
	for _, desc in ipairs(Methods.GetDescendants(self)) do
		if isA(data[desc].ClassName, "BasePart") then return data[desc].props.CFrame end
	end
	return cf(v3())
end
function Methods.GetBoundingBox(self)
	local minV, maxV
	for _, desc in ipairs(Methods.GetDescendants(self)) do
		if isA(data[desc].ClassName, "BasePart") then
			local p = data[desc].props.CFrame.p
			local s = data[desc].props.Size or v3(4, 1, 2)
			local lo, hi = p - s / 2, p + s / 2
			minV = minV and v3(math.min(minV.X, lo.X), math.min(minV.Y, lo.Y), math.min(minV.Z, lo.Z)) or lo
			maxV = maxV and v3(math.max(maxV.X, hi.X), math.max(maxV.Y, hi.Y), math.max(maxV.Z, hi.Z)) or hi
		end
	end
	if not minV then return cf(v3()), v3() end
	return cf((minV + maxV) / 2), maxV - minV
end
function Methods.GetMass() return 1 end
function Methods.EquipTool(self, tool)
	local character = data[self].Parent
	for _, child in ipairs(Methods.GetChildren(character)) do
		if data[child].ClassName == "Tool" and child ~= tool then
			local player = M.players and M.getPlayerFromCharacter(character)
			child.Parent = player and Methods.FindFirstChild(player, "Backpack") or nil
		end
	end
	tool.Parent = character
end
function Methods.UnequipTools() end
function Methods.GetPlayers(self)
	local list = {}
	for _, child in ipairs(data[self].children) do
		if data[child].ClassName == "Player" then table.insert(list, child) end
	end
	return list
end
function Methods.GetPlayerFromCharacter(_, character)
	return M.getPlayerFromCharacter(character)
end
function Methods.GetPlayerByUserId(self, userId)
	for _, p in ipairs(Methods.GetPlayers(self)) do
		if data[p].userId == userId then return p end
	end
	return nil
end
function Methods.GetService(self, name)
	return M.getService(name)
end
function Methods.FindService(self, name)
	return M.getService(name)
end
function Methods.BindToClose(_, fn) M.closeHandlers = M.closeHandlers or {} table.insert(M.closeHandlers, fn) end
function Methods.IsStudio() return true end
function Methods.IsServer() return M.context == "server" end
function Methods.IsClient() return M.context == "client" end
function Methods.GetServerTimeNow() return M.now end
function Methods.Raycast(_, origin, direction, params)
	assert(M.typeof(origin) == "Vector3" and M.typeof(direction) == "Vector3", "Raycast attend des Vector3")
	if M.raycastHook then return M.raycastHook(origin, direction, params) end
	return nil
end
function Methods.ViewportPointToRay(_, x, y)
	return {Origin = v3(0, 10, 0), Direction = v3(0, -1, 0)}
end
function Methods.ScreenPointToRay(_, x, y) return {Origin = v3(0, 10, 0), Direction = v3(0, -1, 0)} end
function Methods.GetMouseLocation() return v2(640, 360) end
function Methods.PlayLocalSound() end
function Methods.Play(self)
	local d = data[self]
	if d.ClassName == "Tween" then
		local goals = d.goals
		local target = d.target
		for k, v in pairs(goals) do
			target[k] = v
		end
		local sig = getSignal(self, "Completed")
		M.task.delay(d.info.Time or 0, function() sig:Fire(M.Enum.PlaybackState.Completed) end)
	end
end
function Methods.Cancel() end
function Methods.Pause() end
function Methods.Stop() end
function Methods.Create(self, target, info, goals)
	local d = data[self]
	if d.ClassName ~= "TweenService" then return nil end
	assert(M.typeof(target) == "Instance", "TweenService:Create : Instance attendue")
	assert(M.typeof(info) == "TweenInfo", "TweenService:Create : TweenInfo attendu")
	assert(type(goals) == "table", "TweenService:Create : table attendue")
	for k, v in pairs(goals) do
		local member = findMember(data[target].ClassName, k)
		if not member or member.k ~= "P" then
			error("TweenService:Create property named '" .. k .. "' cannot be tweened due to type mismatch (property is a 'nil', but given type is '" .. M.typeof(v) .. "')", 2)
		end
		checkType(target, k, member, v)
	end
	local tween = rawNew("Tween", true)
	data[tween].goals = goals
	data[tween].target = target
	data[tween].info = info
	return tween
end
function Methods.AddItem(_, item, time)
	M.task.delay(time or 10, function()
		if not data[item].destroyed then Methods.Destroy(item) end
	end)
end
function Methods.SetCoreGuiEnabled() end
function Methods.SetCore() end
function Methods.GenerateGUID()
	M.guid = (M.guid or 0) + 1
	return string.format("%08X-AAAA-BBBB-CCCC-%012d", M.guid, M.guid)
end
function Methods.JSONEncode(_, v) return "{}" end
function Methods.PromptProductPurchase() end
function Methods.GetTagged(_, tag)
	local list = {}
	for inst in pairs(tagged[tag] or {}) do table.insert(list, inst) end
	return list
end
function Methods.GetInstanceAddedSignal(_, tag) return tagSignal(tagAdded, tag) end
function Methods.GetInstanceRemovedSignal(_, tag) return tagSignal(tagRemoved, tag) end
function Methods.GetDataStore(_, name)
	M.stores = M.stores or {}
	M.stores[name] = M.stores[name] or {}
	local store = M.stores[name]
	return {
		GetAsync = function(_, key) return store[key] end,
		SetAsync = function(_, key, value) store[key] = value end,
		UpdateAsync = function(_, key, fn) store[key] = fn(store[key]); return store[key] end,
	}
end
function Methods.FireServer(self, ...)
	assert(M.context == "client", "FireServer appelé côté serveur")
	local player = M.localPlayer
	local args = table.pack(...)
	local previous = M.context
	M.context = "server"
	getSignal(self, "OnServerEvent"):Fire(player, table.unpack(args, 1, args.n))
	M.context = previous
end
function Methods.FireClient(self, player, ...)
	assert(M.context == "server", "FireClient appelé côté client")
	assert(M.typeof(player) == "Instance" and data[player].ClassName == "Player", "FireClient : Player attendu")
	if player ~= M.localPlayer then return end
	local args = table.pack(...)
	local previous = M.context
	M.context = "client"
	getSignal(self, "OnClientEvent"):Fire(table.unpack(args, 1, args.n))
	M.context = previous
end
function Methods.FireAllClients(self, ...)
	local args = table.pack(...)
	local previous = M.context
	M.context = "client"
	getSignal(self, "OnClientEvent"):Fire(table.unpack(args, 1, args.n))
	M.context = previous
end
function Methods.GetAsync() return nil end
function Methods.Kick() end
function Methods.LoadCharacter() end

M.Methods = Methods

function M.addTag(inst, tag)
	local d = data[inst]
	if d.tags[tag] then return end
	d.tags[tag] = true
	tagged[tag] = tagged[tag] or {}
	tagged[tag][inst] = true
	if tagAdded[tag] then tagAdded[tag]:Fire(inst) end
end
function M.removeTag(inst, tag)
	local d = data[inst]
	if not d.tags[tag] then return end
	d.tags[tag] = nil
	if tagged[tag] then tagged[tag][inst] = nil end
	if tagRemoved[tag] then tagRemoved[tag]:Fire(inst) end
end
Methods.AddTagCS = nil

-- CollectionService:AddTag(inst, tag) (méthode du service, pas de l'instance)
local serviceAddTag = function(self, a, b)
	if data[self].ClassName == "CollectionService" then
		M.addTag(a, b)
	else
		M.addTag(self, a)
	end
end
local serviceRemoveTag = function(self, a, b)
	if data[self].ClassName == "CollectionService" then
		M.removeTag(a, b)
	else
		M.removeTag(self, a)
	end
end
Methods.AddTag = serviceAddTag
Methods.RemoveTag = serviceRemoveTag
Methods.HasTag = function(self, a, b)
	if data[self].ClassName == "CollectionService" then return data[a].tags[b] == true end
	return data[self].tags[a] == true
end

------------------------------------------------------------------
-- DATAMODEL
------------------------------------------------------------------
M.game = rawNew("DataModel", true)
data[M.game].Name = "Game"
local services = {}
function M.getService(name)
	if services[name] then return services[name] end
	local cls = API.classes[name]
	if not cls then error("'" .. tostring(name) .. "' is not a valid Service name", 3) end
	local svc = rawNew(name, true)
	data[svc].Name = name
	services[name] = svc
	svc.Parent = M.game
	return svc
end
M.workspace = M.getService("Workspace")
local terrain = rawNew("Terrain", true)
data[terrain].Name = "Terrain"
terrain.Parent = M.workspace
local camera = rawNew("Camera", true)
data[camera].Name = "Camera"
camera.Parent = M.workspace
data[M.workspace].props.CurrentCamera = camera

-- Players.LocalPlayer dépend du contexte
local players = M.getService("Players")
M.players = players
data[players].getters = {
	LocalPlayer = function()
		if M.context == "client" then return M.localPlayer end
		return nil
	end,
}
function M.getPlayerFromCharacter(character)
	for _, p in ipairs(Methods.GetPlayers(players)) do
		if data[p].props.Character == character and character ~= nil then return p end
	end
	return nil
end

local tcs = M.getService("TextChatService")
data[tcs].props.ChatVersion = M.Enum.ChatVersion.TextChatService
local commands = rawNew("Folder", true)
data[commands].Name = "TextChatCommands"
commands.Parent = tcs

------------------------------------------------------------------
-- ENVIRONNEMENT DES SCRIPTS
------------------------------------------------------------------
M.moduleFiles = {} -- ModuleScript -> chemin
M.moduleCache = {server = {}, client = {}}

local function readFile(path)
	local f = io and io.open and io.open(path, "r")
	if f then
		local s = f:read("*a")
		f:close()
		return s
	end
	return M.readFile(path)
end

function M.makeEnv(scriptInstance)
	local env = {
		game = M.game,
		workspace = M.workspace,
		script = scriptInstance,
		Instance = M.Instance,
		Vector3 = M.Vector3,
		Vector2 = M.Vector2,
		CFrame = M.CFrame,
		Color3 = M.Color3,
		UDim = M.UDim,
		UDim2 = M.UDim2,
		ColorSequence = M.ColorSequence,
		ColorSequenceKeypoint = M.ColorSequenceKeypoint,
		NumberSequence = M.NumberSequence,
		NumberSequenceKeypoint = M.NumberSequenceKeypoint,
		NumberRange = M.NumberRange,
		TweenInfo = M.TweenInfo,
		RaycastParams = M.RaycastParams,
		Random = M.Random,
		Enum = M.Enum,
		task = M.task,
		typeof = M.typeof,
		warn = function(...) table.insert(M.warnings, table.concat({...}, " ")) end,
		print = function(...) end,
		tick = function() return M.now end,
		time = function() return M.now end,
		os = {clock = function() return M.now end, time = os.time, date = os.date},
		wait = M.task.wait,
		require = function(target)
			assert(M.typeof(target) == "Instance", "require attend un ModuleScript")
			local path = M.moduleFiles[target]
			assert(path, "ModuleScript sans source : " .. fullName(target))
			local cache = M.moduleCache[M.context]
			if cache[target] ~= nil then return cache[target].value end
			local chunk, err = loadstring(M.readFile(path), "=" .. path)
			assert(chunk, err)
			setfenv(chunk, M.makeEnv(target))
			local result = chunk()
			cache[target] = {value = result}
			return result
		end,
	}
	return setmetatable(env, {__index = _G})
end

function M.runScript(scriptInstance, path, context)
	local previous = M.context
	M.context = context
	local chunk, err = loadstring(M.readFile(path), "=" .. path)
	if not chunk then
		report("compile", err)
		M.context = previous
		return
	end
	setfenv(chunk, M.makeEnv(scriptInstance))
	spawnFn(chunk)
	M.context = previous
end

return M
