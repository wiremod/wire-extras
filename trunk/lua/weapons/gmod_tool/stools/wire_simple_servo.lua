
TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Simple Servo"
TOOL.Command		= nil
TOOL.ConfigName		= nil

TOOL.ClientConVar[ "model" ] 		= "models/props_vehicles/carparts_wheel01a.mdl"
TOOL.ClientConVar[ "rotate" ]       = 1

// Add Default Language translation (saves adding it to the txt files)
if ( CLIENT ) then
	language.Add( "Tool_wire_simple_servo_name", "Simple Servo Tool (wire)" )
    language.Add( "Tool_wire_simple_servo_desc", "Attaches a servo to something." )
    language.Add( "Tool_wire_simple_servo_0", "Primary: Attach a servo. Secondary: Change the model" )
	
	language.Add( "undone_WireSimpleServo", "Undone Wire Servo" )
	language.Add( "Cleanup_wire_simple_servos", "Wired Servos" )
	language.Add( "Cleaned_wire_simple_servos", "Cleaned up all Wired Simple Servos" )
	language.Add( "sbox_maxwire_simple_servos", "You've reached the wired servos limit!" )

end

if (SERVER) then
    CreateConVar('sbox_maxwire_simple_servos', 30)
end 

cleanup.Register( "wire_simple_servos" )

/*---------------------------------------------------------
   Places a wheel
---------------------------------------------------------*/
function TOOL:LeftClick( trace )

	if ( trace.Entity && trace.Entity:IsPlayer() ) then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	
	if (CLIENT) then return true end
	
	local ply = self:GetOwner()

	if ( !self:GetSWEP():CheckLimit( "wire_simple_servos" ) ) then return false end

	local targetPhys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	
	// Get client's CVars
	local model			= self:GetClientInfo( "model" )
	
	if ( !util.IsValidModel( model ) ) then return false end
	if ( !util.IsValidProp( model ) ) then return false end	
	
	local Ang = trace.HitNormal:Angle()
	if(self:GetClientInfo("rotate")) then
		Ang.pitch = Ang.pitch+90
		//Ang.r = Ang.r+90
	end
	
	// Create the wheel
	local servoEnt = MakeWireSimpleServo( ply, trace.HitPos, Ang, model )
			
	local CurPos = servoEnt:GetPos()
	local NearestPoint = servoEnt:NearestPoint( CurPos - (trace.HitNormal * 512) )
	local servoOffset = CurPos - NearestPoint
		
	servoEnt:SetPos( trace.HitPos + servoOffset + trace.HitNormal )
	
	// Wake up the physics object so that the entity updates
	servoEnt:GetPhysicsObject():Wake()
	
	local TargetPos = servoEnt:GetPos()
			
	// Set the hinge Axis perpendicular to the trace hit surface
	local LPos1 = servoEnt:GetPhysicsObject():WorldToLocal( TargetPos + trace.HitNormal )
	local LPos2 = targetPhys:WorldToLocal( trace.HitPos )
	
	local constraint, axis = constraint.Axis( servoEnt, trace.Entity, 0, trace.PhysicsBone, LPos1,	LPos2, friction, 0, nocollide, false )
	
	undo.Create("WireSimpleServo")
	undo.AddEntity( axis )
	undo.AddEntity( constraint )
	undo.AddEntity( servoEnt )
	undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_servos", axis )
	ply:AddCleanup( "wire_servos", constraint )
	ply:AddCleanup( "wire_servos", servoEnt )

	return true

end


/*---------------------------------------------------------
   Apply new values to the wheel
---------------------------------------------------------*/
function TOOL:RightClick( trace )
	if CLIENT and trace.Entity:IsValid() then return true end
	if not trace.Entity:IsValid() then return end
	local model = trace.Entity:GetModel()
	self:GetOwner():ConCommand("wire_simple_servo_model "..model);
	self.Model = model
	return true;
end

function TOOL:Reload(trace)
	local rotate = self:GetClientInfo("rotate");
	rotate = rotate + 1
	rotate = rotate % 2
	Msg("Rotate: "..rotate);
	self:GetOwner():ConCommand("wire_simple_servo_rotate "..rotate);
	return true;
end

if ( SERVER ) then

	/*---------------------------------------------------------
	   For duplicator, creates the wheel.
	---------------------------------------------------------*/
	function MakeWireSimpleServo( pl, Pos, Ang, Model )
		
		if ( !pl:CheckLimit( "wire_servos" ) ) then return false end
		
		local servo = ents.Create( "gmod_wire_simple_servo" )
		if ( !servo:IsValid() ) then return end
		
		servo:SetModel( Model )
		servo:SetPos( Pos )
		servo:SetAngles( Ang )
		servo:Spawn()
		
		servo:SetPlayer( pl )	
	
		servo.model = model

		pl:AddCount( "wire_simple_servos", servo )
		
		return servo
		
	end

	duplicator.RegisterEntityClass( "gmod_wire_simple_servo", MakeWireSimpleServo, "Pos", "Ang", "model", "Vel", "aVel", "frozen" )
	
	
end

function TOOL:UpdateGhostWireServo( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end
	
	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	if ( trace.Entity:IsPlayer() ) then
	
		ent:SetNoDraw( true )
		return
		
	end
	
	local Ang = trace.HitNormal:Angle()
	if(self:GetClientInfo("rotate")) then
		Ang.pitch = Ang.pitch+90
		//Ang.r = Ang.r+90
	end
	local CurPos = ent:GetPos()
	local NearestPoint = ent:NearestPoint( CurPos - (trace.HitNormal * 512) )
	local servoOffset = CurPos - NearestPoint
	
	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos + trace.HitNormal + servoOffset )
	ent:SetAngles( Ang )
	
	ent:SetNoDraw( false )
	
end

/*---------------------------------------------------------
   Maintains the ghost wheel
---------------------------------------------------------*/
function TOOL:Think()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireServo( self.GhostEntity, self:GetOwner() )
	
end
