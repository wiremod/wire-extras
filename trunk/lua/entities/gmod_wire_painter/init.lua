
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Painter"

local function PlaceDecal( Ent, Pos1, Pos2, decal )

	util.Decal( decal, Pos1, Pos2 )
	
	if ( Ent == NULL ) then return end
	if ( Ent:IsWorld() ) then return end
	if ( Ent:GetClass() != "prop_ragdoll" ) then return end

	local decal = 
		{ 
			decal, 
			Ent:WorldToLocal(Pos1), 
			Ent:WorldToLocal(Pos2) 
		}

	if not	Ent:GetTable().decals then Ent:GetTable().decals = {} end

	table.insert( Ent:GetTable().decals, 1, decal )

	//Trim decal table so only 50 decals are saved
	if #Ent:GetTable().decals > 50 then
		Ent:GetTable().decals[51] = nil
	end

end

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = WireLib.CreateSpecialInputs(self.Entity, { "Paint", "Decal" }, { "NORMAL", "STRING" })
	self.Decal = "Blood"
	self.PlaySound = true
	self.PaintRate = 0
	self:SetBeamLength(2048)
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup(Range, decal, playsound, paintrate)
    self.PlaySound = playsound
	self.PaintRate = paintrate
	self.Decal = decal
    self:SetBeamLength(Range)
	self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
	if iname == "Paint" then
		if self.PaintRate <= 0.01 and value ~= 0 then
			if self.PlaySound then self:EmitSound("SprayCan.Paint") end
		
			local vStart = self.Entity:GetPos()
			local vForward = self.Entity:GetUp()
			 
			local trace = {}
				trace.start = vStart
				trace.endpos = vStart + (vForward * self:GetBeamLength())
				trace.filter = { self.Entity }
			local trace = util.TraceLine( trace ) 
			
			local Pos1 = trace.HitPos + trace.HitNormal
			local Pos2 = trace.HitPos - trace.HitNormal

			PlaceDecal( trace.Entity, Pos1, Pos2, self.Decal )
		elseif self.PaintRate > 0.01 then
			self.Painting = (value ~= 0)
		end
	elseif iname == "Decal" then
		if value ~= "" then self.Decal = value end
		self:ShowOutput()
	end
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	if self.PaintRate > 0.01 and self.Painting then
		if self.PlaySound then self:EmitSound("SprayCan.Paint") end
	
		local vStart = self.Entity:GetPos()
		local vForward = self.Entity:GetUp()
			 
		local trace = {}
			trace.start = vStart
			trace.endpos = vStart + (vForward * self:GetBeamLength())
			trace.filter = { self.Entity }
		local trace = util.TraceLine( trace ) 
			
		local Pos1 = trace.HitPos + trace.HitNormal
		local Pos2 = trace.HitPos - trace.HitNormal

		PlaceDecal( trace.Entity, Pos1, Pos2, self.Decal )
		
		self.Entity:NextThink(CurTime()+self.PaintRate)
		return true
	end
end

function ENT:ShowOutput()
	self:SetOverlayText( "Decal: "..self.Decal )
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

