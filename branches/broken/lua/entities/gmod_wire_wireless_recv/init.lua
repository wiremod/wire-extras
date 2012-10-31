
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "BT_Recv"

local MODEL = Model( "models/props_lab/binderblue.mdl" )
local Recvs = {}

function GetWirelessRecv()
	return Recvs;
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	
	self.Key=0;
	self.SendMsg=0;
	self.Buff={};
	self.Byte=0;
	self.Connected=0;
	
	self:SetOverlayText("Wireless Receiver - Scanning")
			
	table.insert( Recvs , self );
	
	self.Inputs = Wire_CreateInputs(self, { "Pop" , "Message" , "Send" , "Reset" , "Key" })
	self.Outputs = Wire_CreateOutputs(self, { "Connected" , "Count" , "Message"  })
end

function ENT:TriggerInput(iname, value)

	if ( value != nil && iname == "Key" ) then
		self.Key=value;
		iname="Reset";
		value=1;
	end
	
	if ( iname == "Reset" ) then
		if ( value != nil && math.floor( value ) != 0 ) then

			if self.Connected != 0 then				
				self.Connected:Dissconnect( self );
			end
			
			self.SendMsg=0;
			self.Buff={};
			self.Byte=0;
			self.Connected=0;
			
		end
	end
	
	if ( iname == "Pop" ) then
		if ( value != nil && math.floor( value ) != 0 ) then
			table.remove( self.Buff , 1 )
		end
	end
	
	
	if ( value != nil && iname == "Message" ) then
		self.SendMsg=value;
	end

	if ( iname == "Send" ) then
		if ( value != nil && value != nil && math.floor( value ) != 0 ) then
			if ( self.Connected != 0 ) then
				if ( self.Connected:IsValid() ) then 
					self.Connected:Push( self , self.SendMsg )
				else
					self.Connected=0
				end
			end
		end
	end
	
	self:UpdateRMessage();
		
end

function ENT:UpdateRMessage()
	
	if ( self.Connected != 0 ) then
	
		if self.Key != 0 then
			self:SetOverlayText("Wireless Receiver (" .. self.Key .. ") - Connected")
		else
			self:SetOverlayText("Wireless Receiver - Connected")
		end
		
		Wire_TriggerOutput(self, "Connected", 1 )
	
	else
	
		if self.Key != 0 then
			self:SetOverlayText("Wireless Receiver (" .. self.Key .. ") - Scanning")
		else
			self:SetOverlayText("Wireless Receiver - Scanning")
		end
		
		Wire_TriggerOutput(self, "Connected", 0 )
		
	end
	
	Wire_TriggerOutput(self, "Count", #self.Buff )
	
	Wire_TriggerOutput(self, "Message", self.Buff[1] or 0 )
	
end

function ENT:Push( data )

	table.insert( self.Buff, data );
	self:UpdateRMessage();
	
end

function ENT:Think()
	
	if self.Connected != 0 then
		if ( not self.Connected:IsValid() ) then self.Connected=0 end
	else
		
		local Closest=0;
		local CDistance=0;
		
		if self then
			local myPos = self:GetPos();
			for _,Server in pairs( GetWirelessSrv() ) do
				if Server then
					if Server.Key == self.Key then
						local TheirPos=Server:GetPos();
						local ldist=TheirPos:Distance( myPos )
						if ( Closest == 0 || ldist < CDistance ) then
							CDistance=ldist
							Closest=Server
						end
					end
				end
			end
		end
		
		if ( Closest != 0 ) then
			self.Connected=Closest;
			Closest:Connect( self );
			self:UpdateRMessage();
		end
		
	end
	
	self.BaseClass.Think(self)
end

function ENT:OnRemove()

	
	if self.Connected != 0 then					
		self.Connected:Dissconnect( self );
	end
	
	for Key,BT in pairs( GetWirelessRecv() ) do
		if BT == self then
			table.remove( Recvs , Key )
		end
	end
	
end
