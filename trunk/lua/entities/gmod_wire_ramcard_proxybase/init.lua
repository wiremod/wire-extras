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
	
	self.OwnerObj = nil
	self.OwnerID = nil
	
	self.IsRamCard = true
	self.Entity.IsRamCard = true
	
	self.OwnerIDPart1 = 0
	self.OwnerIDPart2 = 0
	self.OwnerIDPart3 = 0
	
	self.Socket = nil
	self.Memory = {}
	self.CurrentDist = 0
	
	self.Entity:SetOverlayText("Wire RAM-Card\nProximity ("..self.SizePrint..")\nMax Owner Distance: "..self.MaxDist.."\nUser Disconnected!")
	Msg(self.Entity:EntIndex())
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
end

function ENT:SetCardOwner( ply )
	self.OwnerObj = ply
	self.OwnerID = ply:SteamID()
	if (!SinglePlayer()) then
		local pos1 = string.find(self.OwnerID,":")
		self.OwnerIDPart1 = tonumber(string.sub(self.OwnerID,7,pos1-1))
		local pos2 = string.find(self.OwnerID,":",pos1+1)
		self.OwnerIDPart2 = tonumber(string.sub(self.OwnerID,pos1+1,pos2-1))
		self.OwnerIDPart3 = tonumber(string.sub(self.OwnerID,pos2+1,string.len(self.OwnerID)))
	else
		self.OwnerIDPart1 = 0
		self.OwnerIDPart2 = 0
		self.OwnerIDPart3 = 0
	end
end

function ENT:GetCardOwner( ply )
	return self.OwnerObj
end

function ENT:Think() --//think function of the card. any actions can be done in here. main one: check if the socket is still there
	self.BaseClass.BaseClass.Think(self)
	sock = self:GetSocket()
	if (sock && !sock:IsValid()) then
		self:ResetSocket()
	end
	if (!self.OwnerObj) then Msg("No OwnerObj\n") end
	if (!self.Entity.OwnerObj) then Msg("No OwnerObj in Entity\n") end
	
	if (self.OwnerObj && self.OwnerObj:IsValid()) then
		self.CurrentDist = self.Entity:GetPos():Distance(self.OwnerObj:GetPos())
		self.Entity:SetOverlayText("Wire RAM-Card\nProximity ("..self.SizePrint..")\nMax Owner Distance: "..self.MaxDist.."\nDistance Now: "..self.CurrentDist)
	elseif (self.OwnerID && !self.OwnerObj:IsValid()) then
		for _,ply in pairs( player.GetAll() ) do
			if (ply:SteamID() == self.OwnerID) then
				self.OwnerObj = ply
				break
			end
		end
		self.OwnerObj = nil
		self.CurrentDist = -1
	end
	if (!self.OwnerObj || !self.OwnerObj:IsValid()) then
		self.Entity:SetOverlayText("Wire RAM-Card\nProximity ("..self.SizePrint..")\nMax Owner Distance: "..self.MaxDist.."\nUser Disconnected!")
	end
	
	self.Entity:NextThink( CurTime() + 0.25 )
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
	if (self.CurrentDist <= self.MaxDist) then
		return true
	else
		return false
	end
end

function ENT:CanRead() --//asks, if reader/writer can read from card
	if (self.CurrentDist <= self.MaxDist) then
		return true
	else
		return false
	end
end

/*
	Some Addresses are used to give more information over the card:
	
	0		Gives Max User Distance
	1		Gives Current User Distance
	2		Gives 1 if you can read or write or 0 if not		//end end
	3		Gives the first number of the owners SteamID
	4		Gives the second number of the owners SteamID
	5		Gives the third number of the owners SteamID
	
	Those values are after the memory area, to make it more compatible. So if you have a 24 value card, the "Max User
	Distance" cell would be address 24 (counted from 0, memory is 0-23)
*/

function ENT:WriteCell( Address, value ) --//Writes a Cell on the Card
	if (self:CanWrite()) then
		if (Address >= 0 && Address <= (self.Size - 1)) then
			if (value != 0) then
				self.Memory[Address] = value
			else
				self.Memory[Address] = nil
			end
			return true
		end
	end
	return false
end

function ENT:ReadCell( Address ) --//Reads a Cell from the Card
	if (self:CanRead()) then
		if (Address >= 0 && Address <= (self.Size - 1)) then
			if (self.Memory[Address]) then
				return self.Memory[Address]
			else
				return 0
			end
		elseif (Address == self.Size) then
			return self.MaxDist
		elseif (Address == (self.Size + 1)) then
			return self.CurrentDist
		elseif (Address == (self.Size + 2)) then
			if (self:CanRead()) then
				return 0
			end
			return 0
		elseif (Address == (self.Size + 3)) then
			return self.OwnerIDPart1
		elseif (Address == (self.Size + 4)) then
			return self.OwnerIDPart2
		elseif (Address == (self.Size + 5)) then
			return self.OwnerIDPart3
		end
	end
	return nil
end
