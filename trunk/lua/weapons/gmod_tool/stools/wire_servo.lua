TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Servo"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "torque" ] 		= "3000"
TOOL.ClientConVar[ "friction" ] 	= "1"
TOOL.ClientConVar[ "nocollide" ] 	= "1"
TOOL.ClientConVar[ "initweld" ] 	= "1"
TOOL.ClientConVar[ "forcelimit" ] 	= "0"
TOOL.ClientConVar[ "weldmode" ]		= "0"

// Add Default Language translation (saves adding it to the txt files)
if ( CLIENT ) then
	language.Add( "Tool.wire_servo.name", "Servo Tool (wire)" )
    language.Add( "Tool.wire_servo.desc", "Attaches a servo to something." )
    language.Add( "Tool.wire_servo.0", "Click on a prop to attach a servo." )
	
	language.Add( "WireServoTool_initweld", "Create initial weld:" )
	language.Add( "WireServoTool_weldmode", "Enable weld-stop mode:" )
	
	language.Add( "undone_WireServo", "Undone Wire Servo" )
	language.Add( "Cleanup_wire_servos", "Wired Servos" )
	language.Add( "Cleaned_wire_servos", "Cleaned up all Wired Servos" )
	language.Add( "SBoxLimit_wire_servos", "You've reached the wired servo limit!" )
end

if (SERVER) then
    CreateConVar('sbox_maxwire_servos', 30)
end 

cleanup.Register( "wire_servos" )

/*---------------------------------------------------------
   Places a servo
---------------------------------------------------------*/
function TOOL:LeftClick( trace )
	if ( trace.Entity && trace.Entity:IsPlayer() ) then return false end
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	if (CLIENT) then return true end
	
	local ply = self:GetOwner()

	if ( !self:GetSWEP():CheckLimit( "wire_servos" ) ) then return false end

	local targetPhys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	
	// Get client's CVars
	local torque		= self:GetClientNumber( "torque" )
	local friction 		= self:GetClientNumber( "friction" )
	local nocollide		= self:GetClientNumber( "nocollide" )
	local limit			= self:GetClientNumber( "forcelimit" )
	local model			= ply:GetInfo( "wheel_model" )
	
	local initweld		= self:GetClientNumber( "initweld" )
	local weldmode		= self:GetClientNumber( "weldmode" )
	
	if ( !util.IsValidModel( model ) ) then return false end
	if ( !util.IsValidProp( model ) ) then return false end
		
	// Create the servo
	local servoEnt = MakeWireServo( ply, trace.HitPos, Angle(0,0,0), model, nil, nil, nil, torque )
	
	// Make sure we have our servo angle
	self.servoAngle = Angle( tonumber(ply:GetInfo( "wheel_rx" )), tonumber(ply:GetInfo( "wheel_ry" )), tonumber(ply:GetInfo( "wheel_rz" )) )
	
	local TargetAngle = trace.HitNormal:Angle() + self.servoAngle	
	servoEnt:SetAngles( TargetAngle )
	
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
	
	local constraint, axis = constraint.Motor( servoEnt, trace.Entity, 0, trace.PhysicsBone, LPos1,	LPos2, friction, torque, 0, nocollide, false, ply, limit )
	
	undo.Create("WireServo")
	undo.AddEntity( axis )
	undo.AddEntity( constraint )
	undo.AddEntity( servoEnt )
	undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_servos", axis )
	ply:AddCleanup( "wire_servos", constraint )
	ply:AddCleanup( "wire_servos", servoEnt )
	
	servoEnt:SetMotor( constraint )
	//servoEnt:SetDirection( constraint.direction )	
	servoEnt:SetAxis( trace.HitNormal )
	servoEnt:SetToggle( toggle )
	servoEnt:SetBaseTorque( torque )
	servoEnt:AcceptVars( trace.Entity, trace.PhysicsBone, weldmode ) // My code
	servoEnt:DoVectorChoice()
	if ( initweld == 1 )then servoEnt:InitWeld() end

	return true

end


/*---------------------------------------------------------
   Apply new values to the servo
---------------------------------------------------------*/
function TOOL:RightClick( trace )

	if ( trace.Entity && trace.Entity:GetClass() != "gmod_wire_servo" ) then return false end
	if (CLIENT) then return true end
	
	local servoEnt = trace.Entity
	
	// Only change your own servos..
	if ( servoEnt:GetTable():GetPlayer():IsValid() && 
	     servoEnt:GetTable():GetPlayer() != self:GetOwner() ) then 
		 
		 return false 
		 
	end

	// Get client's CVars
	local torque		= self:GetClientNumber( "torque" )
	local toggle		= self:GetClientNumber( "toggle" ) != 0
		
	servoEnt:SetTorque( torque )
	servoEnt:UpdateOverlayText()

	return true

end

if ( SERVER ) then

	/*---------------------------------------------------------
	   For duplicator, creates the servo.
	---------------------------------------------------------*/
	function MakeWireServo( pl, Pos, Ang, Model, Vel, aVel, frozen, BaseTorque, axis, Data )
		
		if ( !pl:CheckLimit( "wire_servos" ) ) then return false end
		
		local servo = ents.Create( "gmod_wire_servo" )
		if ( !servo:IsValid() ) then return end
		
		servo:SetModel( Model )
		servo:SetPos( Pos )
		servo:SetAngles( Ang )
		servo:Spawn()
		
		servo:SetPlayer( pl )
		
		duplicator.DoGenericPhysics( servo, pl, Data )
		
		if ( axis ) then
			servo.Axis = axis
		end
		
		servo:SetBaseTorque( BaseTorque )
		servo:UpdateOverlayText()
		
		pl:AddCount( "wire_servos", servo )
		
		return servo
		
	end

	duplicator.RegisterEntityClass( "gmod_wire_servo", MakeWireServo, "Pos", "Ang", "model", "Vel", "aVel", "frozen", "BaseTorque", "Axis", "Data" )
	
	
end

function TOOL:UpdateGhostWireServo( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end
	
	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	if ( trace.Entity:IsPlayer() ) then
	
		ent:SetNoDraw( true )
		return
		
	end
	
	local Ang = trace.HitNormal:Angle() + self.servoAngle
	local CurPos = ent:GetPos()
	local NearestPoint = ent:NearestPoint( CurPos - (trace.HitNormal * 512) )
	local ServoOffset = CurPos - NearestPoint
	
	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos + trace.HitNormal + ServoOffset )
	ent:SetAngles( Ang )
	
	ent:SetNoDraw( false )
	
end

/*---------------------------------------------------------
   Maintains the ghost servo
---------------------------------------------------------*/
function TOOL:Think()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetOwner():GetInfo( "wheel_model" )) then
		self.servoAngle = Angle( tonumber(self:GetOwner():GetInfo( "wheel_rx" )), tonumber(self:GetOwner():GetInfo( "wheel_ry" )), tonumber(self:GetOwner():GetInfo( "wheel_rz" )) )
		self:MakeGhostEntity( self:GetOwner():GetInfo( "wheel_model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireServo( self.GhostEntity, self:GetOwner() )
	
end


function TOOL.BuildCPanel( CPanel )

	// HEADER
	CPanel:AddControl( "Header", { Text = "#Tool.wire_servo.name", Description	= "#Tool.wire_servo.desc" }  )
	
	local Options = { Default = {	wire_servo_torque		= "3000",
									wire_servo_friction		= "0",
									wire_servo_nocollide	= "1",
									wire_servo_forcelimit	= "0",} }
									
	local CVars = { "wire_servo_torque", "wire_servo_friction", "wire_servo_nocollide", "wire_servo_forcelimit", "wire_servo_initweld", "wire_servo_weldmode" }
	
	CPanel:AddControl( "ComboBox", { Label = "#Presets",
									 MenuButton = 1,
									 Folder = "wire_servo",
									 Options = Options,
									 CVars = CVars } )								
									 
	CPanel:AddControl( "PropSelect", { Label = "#tool.wheel.model",
									 ConVar = "wheel_model",
									 Category = "Servos",
									 Models = list.Get( "WheelModels" ) } )
									 
	CPanel:AddControl( "Slider", { Label = "#tool.wheel.torque",
									 Description = "#ServoTool_torque_desc",
									 Type = "Float",
									 Min = 10,
									 Max = 10000,
									 Command = "wire_servo_torque" } )
									 
									 
	CPanel:AddControl( "Slider", { Label = "#tool.wheel.forcelimit",
									 Description = "#ServoTool_forcelimit_desc",
									 Type = "Float",
									 Min = 0,
									 Max = 50000,
									 Command = "wire_servo_forcelimit" } )
									 
	CPanel:AddControl( "Slider", { Label = "#tool.wheel.friction",
									 Description = "#ServoTool_friction_desc",
									 Type = "Float",
									 Min = 0,
									 Max = 100,
									 Command = "wire_servo_friction" } )
									 
	CPanel:AddControl( "CheckBox", { Label = "#tool.wheel.nocollide",
									 Description = "#ServoTool_nocollide_desc",
									 Command = "wire_servo_nocollide" } )
									 
	CPanel:AddControl( "CheckBox", { Label = "#WireServoTool_initweld",
									 Description = "#ServoTool_initweld_desc",
									 Command = "wire_servo_initweld" } )
	
	CPanel:AddControl( "CheckBox", { Label = "#WireServoTool_weldmode",
									 Description = "#ServoTool_weldmode_desc",
									 Command = "wire_servo_weldmode" } )
end
