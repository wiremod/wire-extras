include('shared.lua')

function ENT:SpawnFunction( ply, trace )
	-- Create the entity
	local ent = ents.Create("gmod_wire_touchplate")
	
	-- Use a plate as the model
	ent:SetModel( "models/props_phx/construct/metal_plate1.mdl" )
	
	-- Align the plate with the surface below it
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	ent:SetAngles( Ang )
	
	-- Move it into the right spot
	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	-- Spawn the plate and set its player
	ent:SetPlayer( ply )
	ent:Spawn()
	
	return ent
end

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Inputs  = WireLib.CreateInputs (self, { "OnlyPlayers" })
	self.Outputs = WireLib.CreateOutputs(self, { "Touched", "Toucher [ENTITY]", "Touchers [ARRAY]" })
	
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end
	
	self.touchers = {}
	self.OnlyPlayers = false
	
	self:UpdateOutputs()
end

function ENT:TriggerInput(name, value)
	if name == "OnlyPlayers" then
		self.OnlyPlayers = value ~= 0
	end
end

function ENT:UpdateOutputs()
	local NumTouchers = #self.touchers
	WireLib.TriggerOutput(self, "Touched", NumTouchers>0 and 1 or 0)
	WireLib.TriggerOutput(self, "Toucher", self.touchers[NumTouchers] or NULL)
	WireLib.TriggerOutput(self, "Touchers", self.touchers)
end

function ENT:StartTouch(ent)
	if not self:MehPassesTriggerFilters(ent) then return end
	table.insert(self.touchers, ent)
	self:UpdateOutputs()
end

function ENT:EndTouch(ent)
	for i,v in ipairs(self.touchers) do
		if v == ent then
			table.remove(self.touchers, i)
			self:UpdateOutputs()
			break
		end
	end
end

function ENT:MehPassesTriggerFilters(ent)
	return ent:IsPlayer() or not self.OnlyPlayers
end
