AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

local dam = 0
local takedam = 0
local ison = 0
local ref = 0.2
local attid = 0

ENT.WireDebugName = "Damage Scale"

function ENT:Initialize() 
	self.Entity:PhysicsInit( SOLID_VPHYSICS )     
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )   
	self.Entity:SetSolid( SOLID_VPHYSICS )               
	local phys = self.Entity:GetPhysicsObject()  
	    	if  WireAddon then 
			self.Inputs = Wire_CreateInputs(self.Entity, { "On", "Refresh" })	
	    		self.Outputs = Wire_CreateOutputs(self.Entity, { "Damage", "Steamid"})
		end
	if (phys:IsValid()) then  		
		phys:Wake()  	
	end 
end

function ENT:TriggerInput(iname, value)
	if (iname == "On") then
		ison = value
	elseif (iname == "Refresh") then
		ref = value
	end
end

function ENT:OnTakeDamage(dmginfo)
	if (ison == 1) then
		dam = dmginfo:GetDamage()
		attid = dmginfo:GetAttacker:SteamID()
	else
		dam = 0
	end
end

function ENT:Think()
	if ( ison == 1 ) then
		self:SetOverlayText( "The damage is "..dam )
			if ( dam > 0 ) then
				Wire_TriggerOutput(self.Entity, "Damage", dam)
				Wire_TriggerOutput(self.Entity, "Steamid", attid)//Registers the steam id
				attid = 0//Resets it
				dam = 0 		
					if ( ref >= 0 )	then	 //It's not going back in time btw
						self.Entity:NextThink( CurTime() + ref )
						return true
					end
			else
				Wire_TriggerOutput(self.Entity, "Damage", 0)
				self.Entity:NextThink( CurTime() + 0 )
			end 
	else
		self:SetOverlayText( " We are off and ergo nothing is happnin " )
	end
end


