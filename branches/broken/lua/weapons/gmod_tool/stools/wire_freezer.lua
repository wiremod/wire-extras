
TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Freezer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
	
    language.Add( "Tool.wire_freezer.name", "Freezer Tool (Wire)" )
    language.Add( "Tool.wire_freezer.desc", "Makes a controllable freezer" )
    language.Add( "Tool.wire_freezer.0", "Primary: Click on the entity to be frozen" )
    language.Add( "Tool.wire_freezer.1", "Left click to place the controller" )
	language.Add( "undone_wirefreezer", "Undone Wire Freezer" )
	
end

function TOOL:LeftClick( trace )
	
	if ( trace.Entity:IsValid() && trace.Entity:IsPlayer() ) then return end
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	local iNum = self:NumObjects()
		self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
	
	if ( iNum == 1 ) then
			
		if ( CLIENT ) then
			self:ClearObjects()
			self:SetStage(0)
			return true
		end
		
		local ply = self:GetOwner()
		local Ent1 = self:GetEnt(1)
				
		// Attach our Controller to the weld constraint
		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90
		local controller = MakeWireFreezerController( ply, trace.HitPos, Ang )
		
		// Send Entity and Constraint info over to the controller
		controller:SendVars(Ent1)
		
		local min = controller:OBBMins()
		controller:SetPos( trace.HitPos - trace.HitNormal * min.z )
		
		local const = WireLib.Weld(controller, trace.Entity, trace.PhysicsBone, true)
		
		undo.Create("WireFreezer")
			undo.AddEntity( controller )
			undo.AddEntity( const )
			undo.SetPlayer( ply )
		undo.Finish()
		
		self:ClearObjects()
		self:SetStage(0)

		elseif ( iNum == 1 ) then
		
		if ( CLIENT ) then
			return true
		end
		
		// Get information we're about to use
		self.Ent1 = self:GetEnt(1)
							
		self:SetStage(0)
		
	else
		
		self:SetStage( self:GetStage() + 1 )
		
	end
	
	return true
	
end

if SERVER then
	
	function MakeWireFreezerController( pl, Pos, Ang )
		local controller = ents.Create("gmod_wire_freezer")
		
		controller:SetPos( Pos )
		controller:SetAngles( Ang )
		controller:SetPlayer(pl)
		
		controller:Spawn()
		
		return controller
	end
	duplicator.RegisterEntityClass("gmod_wire_freezer", MakeWireFreezerController, "Pos", "Ang")
		
end

function TOOL.BuildCPanel( panel )
	panel:AddControl( "Header", { Text = "#Tool.wire_freezer.name", Description = "#Tool.wire_freezer.desc" } )
end
