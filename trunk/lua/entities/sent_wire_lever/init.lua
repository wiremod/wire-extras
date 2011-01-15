AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )
--[[resource.AddFile("materials/VGUI/entities/lever.vmt")
resource.AddFile("materials/VGUI/entities/lever.vtf")]]

function ENT:Initialize() 
	lastswitch=CurTime()
	self:SetModel( "models/props_mining/control_lever01.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )     
	self:SetMoveType( MOVETYPE_VPHYSICS )   
	self:SetSolid( SOLID_VPHYSICS )               
	local phys = self:GetPhysicsObject()  
	if not (WireAddon == nil) then self.Inputs = Wire_CreateInputs(self, { "Lock"}) end	
	if not (WireAddon == nil) then self.Outputs = Wire_CreateOutputs(self, { "A"}) end
	if (phys:IsValid()) then  		
		phys:Wake()
	end
	self.locked = 0
	self.on = 0
end   

function ENT:TriggerInput(iname, value) --wire inputs
	if (iname == "Lock") then
		if (value ~= nil) then
			self.locked = value
		end
	end
end

function ENT:SpawnFunction( ply, tr)

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16
	
	local ent = ents.Create( "sent_wire_lever" )
		ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Activate()
	
	return ent

end

function ENT:Think()
	
	if not (WireAddon == nil) then Wire_TriggerOutput(self, "A", self.on) end
end

function ENT:Use()
	if ((lastswitch*4)+3<(CurTime()*4) && self.locked==0) then

		if (self.on == 1) then
			self.on=0
			local sequence = self:LookupSequence("close")
			self:ResetSequence( sequence ) 
		else
			local sequence = self:LookupSequence("open")
			self:ResetSequence( sequence ) 
			self.on=1
		end
		
		lastswitch=CurTime()
		local phys = self:GetPhysicsObject()  
		if (phys:IsValid()) then  		
			phys:Wake()  	
			phys:EnableMotion(True)
			phys:EnableMotion(False)
		end
	
    return true
	
	end
end	