
TOOL.Category		= "Wire Extras/Physics"
TOOL.Name			= "Buoyancy"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language.Add( "Tool.rt_buoyancy_wire.name", "Buoyancy (Wire)" )
	language.Add( "Tool.rt_buoyancy_wire.desc", "Make things float." )
	language.Add( "Tool.rt_buoyancy_wire.0", "Left click to choose a prop." )
	language.Add( "Tool.rt_buoyancy_wire.1", "Left click to place/choose the controller." )
	language.Add( "Undone_WireBuoyancy", "Undone Wire Buoyancy" )
end

local function MakeBuoyancyController( pl, pos, ang, collide )
	// Create the controller.
	local control = ents.Create( "gmod_wire_buoyancy" )
		control:SetModel( "models/jaanus/wiretool/wiretool_siren.mdl" )
		control:SetPos( pos )
		control:SetAngles( ang )
		control.Collide = collide
	control:Spawn()
	
	if ( !collide ) then
		// Disable collisions.
		local phys = control:GetPhysicsObject()
		if ( phys:IsValid() ) then
			phys:EnableCollisions( false )
		end
	end
	
	return control
end
duplicator.RegisterEntityClass( "gmod_wire_buoyancy", MakeBuoyancyController, "Pos", "Ang", "Collide" )

function TOOL:LeftClick( trace )
	local ent = trace.Entity
	if ( CLIENT ) then return true end
	
	if ( self:GetStage() == 0 ) then
		if ( !ent || !ent:IsValid() ) then return false end

		self.Target = ent
		
		self:SetStage( 1 )
	else
		local targ = self.Target
		
		// Remove the entity from the current controller.
		if ( ent.BuoyancyController && IsValid( ent.BuoyancyController ) ) then
			ent.BuoyancyController:RemoveEntity( ent )
		end
		
		// If we clicked on a controller, use it.
		if ( ent:IsValid() && ent:GetClass() == "gmod_wire_buoyancy" ) then
			ent:AddEntity( targ )
			targ.BuoyancyController = ent
		else
			local control = MakeBuoyancyController( nil, trace.HitPos, trace.HitNormal:Angle() + Angle( 90, 0, 0 ), ent:IsValid() )
			control:AddEntity( targ )
			
			local weld
			if ( ent:IsValid() ) then
				// Weld it to the target.
				weld = constraint.Weld( control, ent, 0, 0, 0, false )
			end
			
			// Create the undo.
			undo.Create( "WireBuoyancy" )
				undo.AddEntity( control )
				if ( weld ) then undo.AddEntity( weld ) end
				undo.SetPlayer( self:GetOwner() )
			undo.Finish()
			
			targ.BuoyancyController = control
		end
		
		self:SetStage( 0 )
	end
	
	return true
end
function TOOL:RightClick( trace )
end
function TOOL.BuildCPanel( panel )
end

// Stops the buoyancy resetting when the entity is physgunned.
if ( SERVER ) then
	local function OnDrop( ply, ent )
		if ( ent.BuoyancyController && IsValid( ent.BuoyancyController ) ) then
			timer.Simple( 0, function() ent.BuoyancyController.SetPercent(ent.BuoyancyController) end ) // Refresh.
		end
	end
	hook.Add( "PhysgunDrop", "rt_buoyancy_wire", OnDrop )
	hook.Add( "GravGunOnDropped", "rt_buoyancy_wire", OnDrop )
end
