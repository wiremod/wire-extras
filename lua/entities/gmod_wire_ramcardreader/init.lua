
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "RAM-Card Reader"

local NEW_CARD_WAIT_TIME = 2
local CARD_IN_SOCKET_CONSTRAINT_POWER = 2000
local CARD_IN_ATTACH_RANGE = 3

function ENT:Initialize()
	self.Entity:SetModel( "models/keycardspawner/keycardspawner.mdl" )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	--self.Inputs = Wire_CreateInputs(self.Entity, { "ReadLocation", "WriteEnabled", "WriteLocation", "WriteValue" })
	self.Outputs = Wire_CreateOutputs(self.Entity, {"Card Connected"})
	
	self.PluggedCard = nil
	self.CardWeld = nil
	self.CardNoCollide = nil
	
	self.Entity:SetOverlayText("Wire RAM-Card\nReader/Writer\nNo Card plugged in")
	Wire_TriggerOutput(self.Entity,"Card Connected",0)
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	if (self.CardWeld && !self.CardWeld:IsValid()) then
		if (self.PluggedCard && self.PluggedCard:IsValid()) then
			self.PluggedCard:ResetSocket()
		end
		self.CardWeld = nil
		self.CardNoCollide = nil
		self.PluggedCard = nil
		
		self.Entity:SetOverlayText("Wire RAM-Card\nReader/Writer\nNo Card plugged in")
		
		Wire_TriggerOutput(self.Entity,"Card Connected",0)
		
		self.Entity:NextThink( CurTime() + NEW_CARD_WAIT_TIME )
		return true
	end
	
	if (!self.PluggedCard || !self.PluggedCard:IsValid()) then
		self:SearchCards()
	end
	
	if (self.PluggedCard && self.PluggedCard:IsValid()) then
		self.Entity:NextThink( CurTime() + 1 )
	else
		self.Entity:NextThink( CurTime() + 0.2 )
	end
	return true
end

function ENT:SearchCards()
	local sockCenter = self.Entity:GetPos() + self.Entity:GetUp() * 5
	local local_ents = ents.FindInSphere( sockCenter, CARD_IN_ATTACH_RANGE )
	for key, card in pairs(local_ents) do
		// If we find a plug, try to attach it to us
		if ( card && card:IsValid() && card:GetTable().IsRamCard ) then
			// If no other sockets are using it
			if (card:GetSocket() == nil || !card:GetSocket():IsValid()) then
				self:PlugCard(card)
			end
		end
		if (self.PluggedCard && self.PluggedCard:IsValid()) then
			break
		end
	end
end

function ENT:PlugCard( card )
	self.PluggedCard = card
	local newpos = self.Entity:GetPos() + self.Entity:GetUp() * 5
	local socketAng = self.Entity:GetAngles() + Vector(90,0,0)
	card:SetPos( newpos )
	card:SetAngles( socketAng )
	
	self.CardNoCollide = constraint.NoCollide(self.Entity, card, 0, 0)
	if (!self.CardNoCollide) then
	    return
	end
	
	self.CardWeld = constraint.Weld( self.Entity, card, 0, 0, CARD_IN_SOCKET_CONSTRAINT_POWER, true )
	if (!self.CardWeld && !self.CardWeld:IsValid()) then
	    self.CardNoCollide:Remove()
	    self.CardNoCollide = nil
	    return
	end
	
	card:DeleteOnRemove( self.CardWeld )
	self.Entity:DeleteOnRemove( self.CardWeld )
	self.CardWeld:DeleteOnRemove( self.CardNoCollide )
	
	self.PluggedCard = card
	card:SetSocket( self )
	
	self.Entity:SetOverlayText("Wire RAM-Card\nReader/Writer\nA Card is plugged in")
	Wire_TriggerOutput(self.Entity,"Card Connected",1)
end

--Address 0 is handled by the Reader/Writer, and says, if a card is connected.  If you write a 0 to cell 0, the card will be thrown out
--Address 1 gives the size of the current card (only readable, will cause memory fault if you write)

function ENT:WriteCell( Address, value )
	if (Address == 0) then
		if (self.PluggedCard && self.PluggedCard:IsValid()) then
			if (value <= 0) then
				self.CardWeld:Remove()
				self.CardNoCollide:Remove()
				self.PluggedCard:ResetSocket()
				
				self.CardWeld = nil
				self.CardNoCollide = nil
				self.PluggedCard = nil
				
				self.Entity:SetOverlayText("Wire RAM-Card\nReader/Writer\nNo Card plugged in")
				Wire_TriggerOutput(self.Entity,"Card Connected",0)
				self.Entity:NextThink( CurTime() + NEW_CARD_WAIT_TIME )
			end
		end
		return true
	elseif (Address >= 2) then
		if (self.PluggedCard && self.PluggedCard:IsValid()) then
			if (self.PluggedCard:CanWrite()) then
				return self.PluggedCard:WriteCell( Address - 1, value )
			end
		end
	end
	return false
end

function ENT:ReadCell( Address )
	if (Address == 0) then
		if (self.PluggedCard && self.PluggedCard:IsValid()) then
			return 1
		else
			return 0
		end
	elseif (Address == 1) then
		if (self.PluggedCard && self.PluggedCard:IsValid()) then
			return self.PluggedCard:GetSize()
		end
	else
		if (self.PluggedCard && self.PluggedCard:IsValid()) then
			if (self.PluggedCard:CanRead()) then
				return self.PluggedCard:ReadCell( Address - 1 )
			end
		end
	end
	return nil
end

