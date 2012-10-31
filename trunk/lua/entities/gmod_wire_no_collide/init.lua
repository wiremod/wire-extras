
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

ENT.WireDebugName = "No Collide"

include('shared.lua')

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ENT:Initialize()
	self:SetModel( MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self, { "Activate" } )	
	
	self:SetOverlayText( "Collide Toggle - Deactivated" )
	
	self.PreviousValue = 0
	
end

function ENT:SendVars( EntInfo )
	
	self.EntInfo = EntInfo
	
end

function ENT:TriggerInput(iname, value)

	if (iname == "Activate") then
		
		if (!self.EntInfo) then return end
	
		if ( value == 0 ) then
		
			local entInfo, i
			for i in pairs(self.EntInfo) do
				entInfo = self.EntInfo[i]
			
				// Only save the colour and material if previous state was on
				if (self.PreviousValue > 0) then
					entInfo.OnMaterial = entInfo.Ent:GetMaterial()
					entInfo.OnColor = entInfo.Ent:GetColor()
				end
				
	            entInfo.Ent:SetMaterial(entInfo.OffMaterial)
	            entInfo.Ent:SetColor( entInfo.OffColor )
				
				entInfo.Ent:SetCollisionGroup(entInfo.CollisionGroup)
				entInfo.Ent.CollisionGroup = entInfo.CollisionGroup
			end
			
			self:SetOverlayText( "No Collide - Deactivated" )
			
		end
		
		if ( value > 0 ) then
		
			local entInfo, i
			for i in pairs(self.EntInfo) do
				entInfo = self.EntInfo[i]
				
				// Only save the colour, material and CollisionGroup if previous state was off
				if (self.PreviousValue == 0) then
					entInfo.OffMaterial = entInfo.Ent:GetMaterial()
					entInfo.OffColor = entInfo.Ent:GetColor()
					
					entInfo.CollisionGroup = entInfo.Ent:GetCollisionGroup()
				end
				
	            entInfo.Ent:SetMaterial(entInfo.OnMaterial)
	            entInfo.Ent:SetColor( entInfo.OnColor )
				
	            
				entInfo.Ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
				entInfo.Ent.CollisionGroup = COLLISION_GROUP_WORLD
			end
			
			self:SetOverlayText( "No Collide - Activated" )
			
		end
		
		self.PreviousValue = value
		
	end
	
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	
	local curEnt
	local CollisionGroup
	local OffMaterial
	local OffColor
	local OnMaterial
	local OnColor
	
	// Toggle on and off so that any changes in material are saved
	local oldValue = self.Inputs.Activate.Value
	if (self.Inputs.Activate.Value == 0) then
		self:TriggerInput("Activate", 1)
	else
		self:TriggerInput("Activate", 0)
	end
	self:TriggerInput("Activate", oldValue)
	
	info.EntInfo = {}
	local entInfo, i
	for i in pairs(self.EntInfo) do
		entInfo = self.EntInfo[i]
		if (entInfo.Ent) and (entInfo.Ent:IsValid()) then
			table.insert(info.EntInfo,{Ent = entInfo.Ent:EntIndex(),
									CollisionGroup = entInfo.CollisionGroup,
									OffMaterial = entInfo.OffMaterial,
									OffColor = entInfo.OffColor,
									OnMaterial = entInfo.OnMaterial,
									OnColor = entInfo.OnColor})
		end
	end
	
	return info
end 

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	
	self.PreviousValue = self.Inputs.Activate.Value
	
	//format : { Ent, CollisionGroup, OffMaterial, OffColor, OnMaterial, OnColor }
	self.EntInfo = {}
	local tempEnt
	local entInfo, i
	for i in pairs(info.EntInfo) do
		entInfo = info.EntInfo[i]
		if (entInfo.Ent) then
			tempEnt = GetEntByID(entInfo.Ent)
			if (!tempEnt) then
				tempEnt = ents.GetByIndex(entInfo.Ent)
			end
			table.insert(self.EntInfo,{Ent = tempEnt,
									CollisionGroup = entInfo.CollisionGroup,
									OffMaterial = entInfo.OffMaterial,
									OffColor = entInfo.OffColor,
									OnMaterial = entInfo.OnMaterial,
									OnColor = entInfo.OnColor})
		end
	end
	
	self:TriggerInput("Activate", self.Inputs.Activate.Value)
end
 