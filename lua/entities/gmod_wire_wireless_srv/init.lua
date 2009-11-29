
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "BT_Hub"

local MODEL = Model( "models/props_lab/binderblue.mdl" )
local Servs = {}

function GetWirelessSrv()
	return Servs;
end

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )																			
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Key=0;
	self.clientNum=1;
	self.clientMax=1;
	self.clients={};

	table.insert( Servs , self );
	
	self:SetOverlayText("Wireless Hub - 0 connected")
			
	self.Inputs = Wire_CreateInputs(self, { "Next", "Pop" , "Message" , "Send" , "Reset" , "Key" })
	self.Outputs = Wire_CreateOutputs(self, { "ID", "Connected", "Count" , "Message" , "Clients" })
end

function BTClientUpdateMessage( self )

	if ( self.Connected != 0 ) then
		Wire_TriggerOutput(self.Entity, "Connected", 1 )
	else
		Wire_TriggerOutput(self.Entity, "Connected", 0 )
	end

	Wire_TriggerOutput(self.Entity, "ID", self.clientID )
	Wire_TriggerOutput(self.Entity, "Count", #self.Buff )
	
	Wire_TriggerOutput(self.Entity, "Message", self.Buff[1] or 0 )
	
end

function ENT:GetClient( C )
	if C == nil then
		if self.clients[ self.clientNum ] == nil then
			return 0;
		else
			return self.clients[ self.clientNum ];
		end
	else
		for _,Clis in pairs( self.clients ) do
			if Clis.Connected == C then
				return Clis
			end
		end
	end
	return 0
end

function CreateClient( srv , C , id )

	local obj={}
	
	obj.clientID=id;
	obj.Entity = srv.Entity;
	obj.SendMsg=0;
	obj.Buff={};
	obj.Byte=0;
	obj.Connected=C;
	obj.UpdateMessage = BTClientUpdateMessage;
	
	return obj;
	
end

function ENT:TriggerInput(iname, value)
	
	if ( value != nil && iname == "Key" ) then
		self.Key=value;
		iname="Reset";
		value=1;
	end
	
	if ( iname == "Reset" ) then
		if ( value != nil && math.floor( value ) != 0 ) then

			for Key,Clis in pairs( self.clients ) do
				if Clis.Connected != 0 then
					Clis.Connected.Connected=0;
					Clis.Connected:UpdateRMessage();
				end
			end
			
			self.clientNum=1;
			self.clientMax=1;
			self.clients={};

			self:UpdateMsg();
			
		end
	end
	
	if ( iname == "Next" ) then
		
		self.clientNum = self.clientNum + 1;
		
		if self.clientNum >= self.clientMax then
			self.clientNum = 0;
		end
		self:FindNextClient();
		
	end

	local Cli = self:GetClient();
	if ( Cli != 0 ) then
		if ( iname == "Pop" ) then
			if ( value != nil && math.floor( value ) != 0 ) then
				table.remove( Cli.Buff , 1 )
			end
		end
		
		if ( value != nil && iname == "Message" ) then
			Cli.SendMsg=value;
		end

		if ( iname == "Send" ) then
			if ( value != nil && value != nil && math.floor( value ) != 0 ) then
				if ( Cli.Connected != 0 ) then
					if ( Cli.Connected:IsValid() ) then 
						Cli.Connected:Push( Cli.SendMsg )
					else
						Cli.Connected=0
					end
				end
			end
		end
		
		Cli:UpdateMessage();
	end
			
end

function ENT:FindNextClient()
	
	while ( self.clientNum < self.clientMax ) do
		
		if ( self.clients[ self.clientNum ] != nil ) then
			if ( self.clients[ self.clientNum ].Connected != 0 ) then
				return;
			end
		end
		
		self.clientNum=self.clientNum+1;
	end
	
end

function ENT:Push( who , data )

	local Cli = self:GetClient( who );
	if ( Cli != 0 ) then
		table.insert( Cli.Buff , data );
	end
	self:UpdateMsg();
	
end

function ENT:Connect( c )
	self.clients[ self.clientMax ]=CreateClient( self , c , self.clientMax );
	self.clientMax=self.clientMax+1;
	self:FindNextClient();
	self:UpdateMsg();
end

function ENT:Dissconnect( C )
	for Key,Clis in pairs( self.clients ) do
		if Clis.Connected == C then
			Clis.Connected=0;
			self:FindNextClient();
			self:UpdateMsg();
			return;
		end
	end
end

function ENT:CountActiveClients()
	local lk=0;
	for Key,Clis in pairs( self.clients ) do
		if Clis.Connected != 0 then
			lk = lk + 1;
		end
	end
	return lk;
end

function ENT:UpdateMsg()
	local Cli = self:GetClient();
	if ( Cli != 0 ) then
		Cli:UpdateMessage();
		local CliCount=self:CountActiveClients();
		Wire_TriggerOutput(self.Entity, "Clients", CliCount )
		
		if self.Key != 0 then
			self:SetOverlayText("Wireless Hub (" .. self.Key .. ") - " .. CliCount .. " connected")
		else
			self:SetOverlayText("Wireless Hub - " .. CliCount .. " connected")
		end
		
	else
		
		if self.Key != 0 then
			self:SetOverlayText("Wireless Hub (" .. self.Key .. ") - 0 connected")
		else
			self:SetOverlayText("Wireless Hub - 0 connected")
		end
		
		Wire_TriggerOutput(self.Entity, "Clients", 0 )
		Wire_TriggerOutput(self.Entity, "Connected", 0 )
		Wire_TriggerOutput(self.Entity, "ID", 0 )
		Wire_TriggerOutput(self.Entity, "Count", 0 )
	end
end

if SERVER then

	function ENT:OnRemove()

		for Key,Clis in pairs( self.clients ) do
			if Clis.Connected != 0 then
				Clis.Connected.Connected=0;
				Clis.Connected:UpdateRMessage();
			end
		end
			
		for Key,BT in pairs( GetWirelessSrv() ) do
			if BT == self then
				table.remove( Servs , Key )
			end
		end
		
	end
	
end
