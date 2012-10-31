TOOL.Category		= "Wire - Physics"
TOOL.Name			= "No Collide"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
    language.Add( "Tool_wire_no_collide_name", "No Collide Tool (Wire)" )
    language.Add( "Tool_wire_no_collide_desc", "Makes a controller to no collide entities (with all others)" )
    language.Add( "Tool_wire_no_collide_0", "Primary: Select entity to be no collided" )
    language.Add( "Tool_wire_no_collide_1", "Primary: Select any additional entities to be no collided   Secondary: Place the controller" )
	language.Add( "undone_wirenocollide", "Undone No Collide" )
end

function TOOL:LeftClick( trace )
	if ( !trace.Entity:IsValid() ) then return end
	if ( trace.Entity:IsPlayer() ) then return end
	
	local iNum = self:NumObjects()
	
	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )

	// Check if the entity has already been no collided by this controller
	local i
	for i = 1, iNum, 1 do
		if (self:GetEnt(i) == trace.Entity) then
			return
		end
	end
	
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
		
	if ( CLIENT ) then
		return true
	end
	
	// Save information on the selected ent
	local CollisionGroup = trace.Entity:GetCollisionGroup()
	local Material = trace.Entity:GetMaterial()
	local color = trace.Entity:GetColor()
	
	if (iNum == 0) then
		self.EntInfo = {}
	end
	
	table.insert(self.EntInfo,{CollisionGroup, Material, color})
	
	self:SetStage(1)
	
	return true
	
end

function TOOL:RightClick( trace )
	if ( trace.Entity:IsValid() && trace.Entity:IsPlayer() ) then return end
	
	local iNum = self:NumObjects()
	
	if ( iNum > 0 ) then
			
		if ( CLIENT ) then
			self:ClearObjects()
			return true
		end
		
		local ply = self:GetOwner()
		
		// Attach Controller with a weld constraint
		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90
		local controller = MakeNoCollideController( ply, trace.HitPos, Ang )
		local min = controller:OBBMins()
		controller:SetPos( trace.HitPos - trace.HitNormal * min.z )
		if (trace.Entity:IsValid()) then
			local weld = WireLib.Weld(controller, trace.Entity, trace.PhysicsBone, true)
		end
		
		// Send info over to the controller
		local controllerInfo = {}
		local i
		for i = 1, iNum, 1 do
			table.insert(controllerInfo,{Ent = self:GetEnt(i),
										CollisionGroup = self.EntInfo[i][1],
										OffMaterial = self.EntInfo[i][2],
										OffColor = self.EntInfo[i][3],
										OnMaterial = self.EntInfo[i][2],
										OnColor = self.EntInfo[i][3]})
		end
		
		// format : { Ent, CollisionGroup, OffMaterial, OffColor, OnMaterial, OnColor }
		controller:SendVars( controllerInfo )
		
		undo.Create("WireNoCollide")
			undo.AddEntity( controller )
			if (trace.Entity:IsValid()) then
				undo.AddEntity( weld )
			end
			undo.SetPlayer( ply )
		undo.Finish()
		
		self:ClearObjects()
		self:SetStage(0)
		
	else
	
		return
		
	end
	
	return true
	
end

if SERVER then
	
	function MakeNoCollideController( pl, Pos, Ang )
		local controller = ents.Create("gmod_wire_no_collide")
		
		controller:SetPos( Pos )
		controller:SetAngles( Ang )
		controller:SetPlayer(pl)
		
		controller:Spawn()
		
		return controller
	end
	duplicator.RegisterEntityClass("gmod_wire_no_collide", MakeNoCollideController, "Pos", "Ang")
	
end

function TOOL.BuildCPanel( panel )
	panel:AddControl( "Header", { Text = "#Tool_wire_no_collide_name", Description = "#Tool_wire_no_collide_desc" } )
end
