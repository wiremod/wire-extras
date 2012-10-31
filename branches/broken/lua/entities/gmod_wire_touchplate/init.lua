AddCSLuaFile("cl_init.lua")

include("cl_init.lua")

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	
	self.Inputs  = WireLib.CreateInputs (self, { "OnlyPlayers" })
	self.Outputs = WireLib.CreateOutputs(self, { "Touched", "Toucher [ENTITY]", "Touchers [ARRAY]" })
	
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end
	
	self.touchers = {}
	self.only_players = false
	
	self:UpdateOutputs()
end

function ENT:TriggerInput(name, value)
	if name == "OnlyPlayers" then
		self.only_players = value ~= 0
	end
end

function ENT:UpdateOutputs()
	local NumTouchers = #self.touchers
	WireLib.TriggerOutput(self, "Touched", NumTouchers>0 and 1 or 0)
	WireLib.TriggerOutput(self, "Toucher", self.touchers[NumTouchers] or NULL)
	WireLib.TriggerOutput(self, "Touchers", self.touchers)
end

function ENT:StartTouch(ent)
	if not self:MyPassesTriggerFilters(ent) then return end
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

function ENT:MyPassesTriggerFilters(ent)
	return ent:IsPlayer() or not self.only_players
end

function MakeWireTouchplate(pl, Pos, Ang, model, only_players)
	-- Create the entity
	local ent = ents.Create("gmod_wire_touchplate")
	
	ent:SetModel(Model(model))
	ent:SetAngles( Ang )
	ent:SetPos( Pos )
	
	ent:SetPlayer( pl )
	ent:Spawn()
	
	ent.only_players = only_players
	
	return ent
end

duplicator.RegisterEntityClass("gmod_wire_touchplate", MakeWireTouchplate, "Pos", "Ang", "model", "only_players")
