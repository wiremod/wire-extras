/*******************************
	Dynamic Memory Gate
	  for Wiremod
	  
	(C) Sebastian J.
********************************/

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.WireDebugName = "DynamicMemoryGate"

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	
	self.Inputs = Wire_CreateInputs( self, { "Reset" } )
	self.Outputs = Wire_CreateOutputs( self, { "Memory" } ) 

	self.Size = 1
	self.Memory = {}
	self.Memory[0] = 0
	self.Persistant = false
	
	self:SetNWString( "size", "1 Byte" )
	self:SetOverlayText( "size", "1 Byte" )
end

function ENT:Setup( size )
	local size = math.Clamp(math.floor( size or self.Size ), 1, 2097152)
	local overheap = size - self.Size
	
	if ( overheap < 0 ) then
		for i= size, self.Size -1 do
			self.Memory[i] = nil
		end
	elseif ( overheap > 0 ) then
		for i = self.Size, size - 1 do
			self.Memory[i] = 0
		end
	end
	self.Size = size
	
	local sstr = self.Size
	local sunit = " Byte"
	if ( sstr > 10000000 ) then
		sunit = " MByte"
		sstr = math.floor( sstr / 1048.576 ) / 1000
	elseif ( sstr > 10000 ) then
		sunit = " KByte"
		sstr = math.floor( sstr / 1.024 ) / 1000
	end
	self:SetNWString( "size", tostring( sstr ) .. sunit )
end

function ENT:Think()
end

function ENT:SetPersistant( val )
	self.Persistant = val or self.Persistant
end

function ENT:TriggerInput( iname, Value )
	if (iname == "Reset") then
		if (Value == 1) then
			for i=0, self.Size -1 do
				self.Memory[i] = 0
			end
		end
	end
end

function ENT:ReadCell( Address )
	if ( Address >= 0 && Address < self.Size ) then
		return self.Memory[Address]
	end
end

function ENT:WriteCell( Address, Value )
	if ( Address >= 0 && Address < self.Size ) then
		self.Memory[Address] = Value or 0
		return true
	end
	return false
end

// Adv duplicator stuff
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo( self ) or {}

	info.MemSize = self.Size
	info.Persistant = self.Persistant
	if ( self.Persistant ) then
		info.Memory = {}		
		for i=0,self.Size - 1 do
			if ( self.Memory[i] ) then
				info.Memory[i] = self.Memory[i]
			end
		end
	end
	
	return info
end

function ENT:ApplyDupeInfo( ply, ent, info, GetEntByID )
	self.BaseClass.ApplyDupeInfo( self, ply, ent, info, GetEntByID )

	self:Setup( info.MemSize or 1 )
	self.Persistant = info.Persistant
	if ( info.Persistant ) then
		info.Memory = info.Memory or {}	
		for i=0,self.Size - 1 do
			if ( info.Memory[i] ) then
				self.Memory[i] = info.Memory[i]
			end
		end
	end
end
