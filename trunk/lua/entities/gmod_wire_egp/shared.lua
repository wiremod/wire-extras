ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire EGP"
ENT.Author          = "Goluch"
ENT.Contact         = "Goluch on wiremod.com"
ENT.Purpose         = "Bring Graphic Processing to E2"
ENT.Instructions    = "WireLink To E2"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

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
		{ "Short", "fsize" },
		{ "Short", "fid" },
		{ "Byte", "colR" },
		{ "Byte", "colG" },
		{ "Byte", "colB" },
		{ "Byte", "colA" },
		{ "Short", "angle" },
		{ "String", "material" },
		{ "Short", "falign" },
		{ "Short", "sides" },
	},
}

setmetatable(umsg_layout, { __index = function(self) return rawget(self, "Default") end })

function ENT:SendEntry(idx, entry)
	umsg.Start("EGPU")
		umsg.Entity(self)
		umsg.Char(2) -- id
		umsg.Long(idx)
		umsg.String(entry.image)
		
		for _,tp,element in ipairs_map(umsg_layout[entry.image], unpack) do
			local value = entry[element] or umsg_defaults[tp]
			if tp == "Byte" then
				umsg.Char(value-128)
			else
				umsg[tp](value)
			end
		end
	umsg.End()
end

function ENT:ReceiveEntry(um)
	local idx = um:ReadLong()
	local image = um:ReadString()
	local entry = { image = image }
	
	for _,tp,element in ipairs_map(umsg_layout[image], unpack) do
		if tp == "Byte" then
			entry[element] = um:ReadChar()+128
		else
			entry[element] = um["Read"..tp](um)
		end
	end
	if entry.material == "" then entry.material = nil end
	
	self.Render[idx] = entry
end