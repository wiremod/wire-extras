ENT.Type           = "anim"
ENT.Base           = "base_wire_entity"

ENT.PrintName      = "Wire EGP"
ENT.Author         = "Goluch"
ENT.Contact        = "Goluch on wiremod.com"
ENT.Purpose        = "Bring Graphic Processing to E2"
ENT.Instructions   = "WireLink To E2"

ENT.Spawnable      = false
ENT.AdminSpawnable = false

local umsg_defaults = {
	Char = 0,
	Byte = 0,
	Short = 0,
	Long = 0,
	Float = 0,
	Bool = false,
	String = "",
	
	Entity = NULL,
	Vector = Vector(0,0,0),
	VectorNormal = Vector(0,0,0),
	Angle = Angle(0,0,0),
}
local umsg_layout = {
	Default = {
		{ "Short", "posX" },
		{ "Short", "posY" },
		{ "Short", "sizeX" },
		{ "Short", "sizeY" },
		{ "Byte", "colR" },
		{ "Byte", "colG" },
		{ "Byte", "colB" },
		{ "Byte", "colA" },
		{ "Short", "angle" },
		{ "String", "material" },
		{ "Short", "extra" },
		{ "Short", "sides" },
	},
	text = {
		{ "Short", "posX" },
		{ "Short", "posY" },
		{ "Byte", "colR" },
		{ "Byte", "colG" },
		{ "Byte", "colB" },
		{ "Byte", "colA" },
		{ "String", "text" },
		{ "Char", "falign" },
		{ "Short", "fsize" },
		{ "Char", "fid" },
	},
	textl = {
		{ "Short", "posX" },
		{ "Short", "posY" },
		{ "Short", "sizeX" },
		{ "Short", "sizeY" },
		{ "Byte", "colR" },
		{ "Byte", "colG" },
		{ "Byte", "colB" },
		{ "Byte", "colA" },
		{ "String", "text" },
		{ "Char", "falign" },
		{ "Short", "fsize" },
		{ "Char", "fid" },
	},
	poly = {
		{ "Byte", "colR" },
		{ "Byte", "colG" },
		{ "Byte", "colB" },
		{ "Byte", "colA" },
		{ "String", "material" },
		{ "VertexList", "vertices" },
	},
}

setmetatable(umsg_layout, { __index = function(self) return rawget(self, "Default") end })

local _umsg = setmetatable({}, { __index = umsg })
local _bf_read = setmetatable({}, { __index = _R.bf_read })

function _umsg.Byte(value)
	return umsg.Char(value-128)
end

function _bf_read:ReadByte()
	return self:ReadChar()+128
end

function _umsg.VertexList(value)
	umsg.Char( #value )
	for _,vertex in ipairs(value) do
		umsg.Float(vertex[1])
		umsg.Float(vertex[2])
		umsg.Float(vertex[3])
		umsg.Float(vertex[4])
	end
end

function _bf_read:ReadVertexList()
	local vertices = {}
	local nvertices = self:ReadChar()
	for i = 1,nvertices do
		vertices[i] = {
			x = self:ReadFloat(),
			y = self:ReadFloat(),
			u = self:ReadFloat(),
			v = self:ReadFloat(),
		}
	end
	return vertices
end

function ENT:InitializeShared()
	WireLib.umsgRegister(self)
end

function ENT:SendEntry(idx, entry, ply)
	self:umsg(ply)
	if entry then
			umsg.Char(2) -- set entry
			umsg.Long(idx)
			umsg.String(entry.image)
			
			for _,tp,element in ipairs_map(umsg_layout[entry.image], unpack) do
				local value = entry[element] or umsg_defaults[tp]
				_umsg[tp](value)
			end
	else
			umsg.Char(3) -- clear entry
			umsg.Long(idx)
	end
	umsg.End()
end

function ENT:ReceiveEntry(um)
	local idx = um:ReadLong()
	local image = um:ReadString()
	local entry = { image = image }
	
	for _,tp,element in ipairs_map(umsg_layout[image], unpack) do
		entry[element] = _bf_read["Read"..tp](um)
	end
	if entry.material == "" then entry.material = nil end
	
	self.Render[idx] = entry
end

function ENT:Retransmit(ply)
	for k,v in pairs(self.Render) do
		self:SendEntry(k, v, ply) --> shared.lua
	end
end
