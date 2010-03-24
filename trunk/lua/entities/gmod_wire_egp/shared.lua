ENT.Type           = "anim"
ENT.Base           = "base_wire_entity"

ENT.PrintName      = "Wire EGP"
ENT.Author         = "Goluch / Doridian"
ENT.Contact        = "Goluch on wiremod.com"
ENT.Purpose        = "Bring Graphic Processing to E2"
ENT.Instructions   = "WireLink To E2"

ENT.Spawnable      = false
ENT.AdminSpawnable = false


--This realy advanced user message system is by TOMYLOBO!
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
local umsg_layout = EGP.USM

setmetatable(umsg_layout, { __index = function(self) return rawget(self, "Default") end })

local _umsg = setmetatable({}, { __index = WireLib.wire_umsg })
local _bf_read = setmetatable({}, { __index = _R.bf_read })

function _umsg.Byte(value)
	return _umsg.Char(value-128)
end

function _bf_read:ReadByte()
	return self:ReadChar()+128
end

function _umsg.VertexList(value)
	_umsg.Char( #value )
	for _,vertex in ipairs(value) do
		_umsg.Float(vertex[1])
		_umsg.Float(vertex[2])
		_umsg.Float(vertex[3])
		_umsg.Float(vertex[4])
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
	self.IsEGP = true
	WireLib.umsgRegister(self)
end

function ENT:SendEntry(idx, entry, ply)
	self:umsg(ply)
		if entry then
			self.umsg.Long(idx)
			self.umsg.String(entry.image)
			
			for _,tp,element in ipairs_map(umsg_layout[entry.image], unpack) do
				local value = entry[element] or umsg_defaults[tp]
				_umsg[tp](value)
			end
		end
	self.umsg.End()
end

function ENT:ReceiveEntry(um)
	local idx = um:ReadLong()
	local image = um:ReadString()
	local entry = { image = image }
	
	for _,tp,element in ipairs_map(umsg_layout[image], unpack) do
		entry[element] = _bf_read["Read"..tp](um)
	end
	if entry.material then
		local gpuid = tonumber(entry.material:match("^<gpu(%d+)>$"))
		if gpuid then
			entry.material = Entity(gpuid)
		end
		if entry.material == "" then entry.material = nil end
	end
	EGP.ProcessCache(self,idx,entry)
	self.Render[idx] = entry
end

function ENT:Retransmit(ply)
	for k,v in pairs(self.RenderDrawn) do
		self:SendEntry(k, v ,ply)
	end
end
--Thank you Tomy!