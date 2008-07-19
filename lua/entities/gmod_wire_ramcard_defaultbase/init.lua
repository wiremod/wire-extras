AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "RAM-card"

function ENT:SetupBase()
	self.Entity:SetModel( "models/keycard/keycard.mdl" )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )
	
	self.CardOwner = nil
	self.CardOwnerName = nil
	
	self.IsRamCard = true
	self.Entity.IsRamCard = true
	
	self.Socket = nil
	self.Memory = {}
	
	self.Entity:SetOverlayText("Wire RAM-Card\nDefault ("..self.SizePrint..")")
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
end

function ENT:Think() --//think function of the card. any actions can be done in here. main one: check if the socket is still there
	sock = self:GetSocket()
	if (sock && !sock:IsValid()) then
		self:ResetSocket()
	end
	
	self.Entity:NextThink( CurTime() + 1 )
	return true
end

function ENT:SetSocket( sock ) --//lets the socket itself tell the card, that it is the card's socket
	self.Socket = sock
end

function ENT:GetSocket() --//gives the socket obj
	return self.Socket
end

function ENT:GetSize()
	return self.Size
end

function ENT:ResetSocket() --//Set's the socket from this card to nil
	self.Socket = nil
end

function ENT:CanWrite() --//asks, if reader/writer can write on card
	return true
end

function ENT:CanRead() --//asks, if reader/writer can read from card
	return true
end

function ENT:WriteCell( Address, value ) --//Writes a Cell on the Card
	if (Address >= 0 && Address <= (self.Size - 1)) then
		if (value != 0) then
			self.Memory[Address] = value
		else
			self.Memory[Address] = nil
		end
		return true
	end
	return false
end

function ENT:ReadCell( Address ) --//Reads a Cell from the Card
	if (Address >= 0 && Address <= (self.Size - 1)) then
		if (self.Memory[Address]) then
			return self.Memory[Address]
		else
			return 0
		end
	end
	return nil
end
