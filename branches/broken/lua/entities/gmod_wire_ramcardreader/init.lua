
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "RAM-Card Reader"

local NEW_CARD_WAIT_TIME = 2
local CARD_IN_SOCKET_CONSTRAINT_POWER = 2000
local CARD_IN_ATTACH_RANGE = 3

function ENT:Initialize()
	self:SetModel( "models/keycardspawner/keycardspawner.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, { "Clk", "AddrRead", "AddrWrite", "Data" })
	self.Outputs = Wire_CreateOutputs(self, {"Card Connected","Data","Cells"})
	
	self.PluggedCard = nil
	self.CardWeld = nil
	self.CardNoCollide = nil
	
	self:SetOverlayText("Wire RAM-Card\nReader/Writer\nNo Card plugged in")
	Wire_TriggerOutput(self,"Card Connected",0)
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
		
		self:SetOverlayText("Wire RAM-Card\nReader/Writer\nNo Card plugged in")
		
		Wire_TriggerOutput(self,"Card Connected",0)
		Wire_TriggerOutput(self,"Cells",0)
		Wire_TriggerOutput(self,"Data",0)
		
		self:NextThink( CurTime() + NEW_CARD_WAIT_TIME )
		return true
	end
	
	if (!self.PluggedCard || !self.PluggedCard:IsValid()) then
		self:SearchCards()
	end
	
	if (self.PluggedCard && self.PluggedCard:IsValid()) then
		self:NextThink( CurTime() + 1 )
	else
		self:NextThink( CurTime() + 0.2 )
	end
	return true
end

function ENT:SearchCards()
	local sockCenter = self:GetPos() + self:GetUp() * 5
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
	local newpos = self:GetPos() + self:GetUp() * 5
	local socketAng = self:GetAngles() + Vector(90,0,0)
	card:SetPos( newpos )
	card:SetAngles( socketAng )
	
	self.CardNoCollide = constraint.NoCollide(self, card, 0, 0)
	if (!self.CardNoCollide) then
	    return
	end
	
	self.CardWeld = constraint.Weld( self, card, 0, 0, CARD_IN_SOCKET_CONSTRAINT_POWER, true )
	if (!self.CardWeld && !self.CardWeld:IsValid()) then
	    self.CardNoCollide:Remove()
	    self.CardNoCollide = nil
	    return
	end
	
	card:DeleteOnRemove( self.CardWeld )
	self:DeleteOnRemove( self.CardWeld )
	self.CardWeld:DeleteOnRemove( self.CardNoCollide )
	
	self.PluggedCard = card
	card:SetSocket( self )
	
	self:SetOverlayText("Wire RAM-Card\nReader/Writer\nA Card is plugged in")
	Wire_TriggerOutput(self,"Card Connected",1)
	Wire_TriggerOutput(self,"Cells",self.PluggedCard:GetSize())
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
				
				self:SetOverlayText("Wire RAM-Card\nReader/Writer\nNo Card plugged in")
				Wire_TriggerOutput(self,"Card Connected",0)
				self:NextThink( CurTime() + NEW_CARD_WAIT_TIME )
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

function ENT:TriggerInput( iname, value )
	if (iname == "AddrWrite") then
		if (self.PluggedCard && self.PluggedCard:IsValid()) then
			if (self.Inputs["Clk"].Value > 0) then
				if (value >= 0 && value < self.PluggedCard:GetSize()) then
					self:WriteCell(value + 2, self.Inputs["Data"].Value)
				end
			end
		end
	elseif (iname == "AddrRead") then
		if (self.PluggedCard && self.PluggedCard:IsValid()) then
			if (value >= 0 && value < self.PluggedCard:GetSize()) then
				Wire_TriggerOutput(self,"Data",self:ReadCell(value+2))
			else
				Wire_TriggerOutput(self,"Data",0)
			end
		else
			Wire_TriggerOutput(self,"Data",0)
		end
	elseif (iname == "Clk") then
		if (self.PluggedCard && self.PluggedCard:IsValid()) then
			if (self.Inputs["Clk"].Value > 0) then
				if (self.Inputs["AddrWrite"].Value >= 0 && self.Inputs["AddrWrite"].Value < self.PluggedCard:GetSize()) then
					self:WriteCell(self.Inputs["AddrWrite"].Value + 2, self.Inputs["Data"].Value)
				end
			end
		end
	end
end

