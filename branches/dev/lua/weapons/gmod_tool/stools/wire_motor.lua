TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Motor"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "torque" ] = "500"
TOOL.ClientConVar[ "friction" ] = "1"
TOOL.ClientConVar[ "nocollide" ] = "1"
TOOL.ClientConVar[ "forcelimit" ] 	= "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

local controlmodels = {
    ["models/jaanus/wiretool/wiretool_siren.mdl"] = {},
    ["models/jaanus/wiretool/wiretool_controlchip.mdl"] = {}};

if CLIENT then
    language.Add( "Tool.wire_motor.name", "Motor Tool (Wire)" )
    language.Add( "Tool.wire_motor.desc", "Makes a controllable motor" )
    language.Add( "Tool.wire_motor.0", "Primary: Place motor" )
    language.Add( "Tool.wire_motor.1", "Left click on the second point" )
    language.Add( "Tool.wire_motor.2", "Left click to place the controller" )
    language.Add( "WireMotorTool_torque", "Torque:" )
    language.Add( "WireMotorTool_friction", "Friction:" )
	language.Add( "WireMotorTool_nocollide", "No Collide" )
	language.Add( "WireMotorTool_forcelimit", "Force Limit:" )
	language.Add( "WireMotorTool_model", "Choose a Model:" )
	language.Add( "undone_wiremotor", "Undone Wire Motor" )
end

function TOOL:LeftClick( trace )

	if ( trace.Entity:IsValid() && trace.Entity:IsPlayer() ) then return end

	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	
	local iNum = self:NumObjects()

	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	
	// Don't allow us to choose the world as the first object
	if (iNum == 0 && !trace.Entity:IsValid()) then return end
	
	// Don't allow us to choose the same object
	if (iNum == 1 && trace.Entity == self:GetEnt(1) ) then return end
	
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
	
	if ( iNum > 1 ) then
		
		if ( CLIENT ) then
			self:ClearObjects()
			return true
		end
	
		local ply = self:GetOwner()
		local Ent1, Ent2, Ent3  = self:GetEnt(1),	 self:GetEnt(2), trace.Entity
		local const, axis = self.constraint, self.axis
		
		if ( !const ) or ( !const:IsValid() ) then
			self:GetOwner():SendLua( "GAMEMODE:AddNotify('Wire Motor Invalid!', NOTIFY_GENERIC, 7);" )
			self:ClearObjects()
			self:SetStage(0)
			return
		end
		
		local model = self:GetClientInfo( "model" )
		
		// Attach our Controller to the Motor constraint
		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90
		local controller = MakeWireMotorController(ply, trace.HitPos, Ang, nil, model, const, axis)
		
		local min = controller:OBBMins()
		controller:SetPos( trace.HitPos - trace.HitNormal * min.z )
		
		local const2 = WireLib.Weld(controller, trace.Entity, trace.PhysicsBone, true)
		
		undo.Create("WireMotor")
			undo.AddEntity( controller )
			undo.AddEntity( const )
			undo.AddEntity( axis )
			undo.AddEntity( const2 )
			undo.SetPlayer( ply )
		undo.Finish()
		
		ply:AddCleanup( "constraints", controller )
		ply:AddCleanup( "constraints", const2 )
		
		if const then controller:DeleteOnRemove( const ) end
		if axis then controller:DeleteOnRemove( axis ) end
		
		self:ClearObjects()
		self:SetStage(0)
		
	elseif ( iNum == 1 ) then
	
		if ( CLIENT ) then
		
			self:ClearObjects()
			self:ReleaseGhostEntity()
			
			return true
			
		end
		
		// Get client's CVars
		local torque		= self:GetClientNumber( "torque" )
		local friction 		= self:GetClientNumber( "friction" )
		local nocollide		= self:GetClientNumber( "nocollide" )
		local forcelimit	= self:GetClientNumber( "forcelimit" )
		
		local Ent1,  Ent2  = self:GetEnt(1),	 self:GetEnt(2)
		local Bone1, Bone2 = self:GetBone(1),	 self:GetBone(2)
		local WPos1, WPos2 = self:GetPos(1),	 self:GetPos(2)
		local LPos1, LPos2 = self:GetLocalPos(1),self:GetLocalPos(2)
		local Norm1, Norm2 = self:GetNormal(1),	 self:GetNormal(2)
		local Phys1, Phys2 = self:GetPhys(1), self:GetPhys(2)
		
		// Note: To keep stuff ragdoll friendly try to treat things as physics objects rather than entities
		local Ang1, Ang2 = Norm1:Angle(), (Norm2 * -1):Angle()
		local TargetAngle = Phys1:AlignAngles( Ang1, Ang2 )
		
		Phys1:SetAngles( TargetAngle )
		
		// Move the object so that the hitpos on our object is at the second hitpos
		local TargetPos = WPos2 + (Phys1:GetPos() - self:GetPos(1))

		// Offset slightly so it can rotate
		TargetPos = TargetPos + (2*Norm2)

		// Set the position
		Phys1:SetPos( TargetPos )

		// Wake up the physics object so that the entity updates
		Phys1:Wake()

		// Set the hinge Axis perpendicular to the trace hit surface
		LPos1 = Phys1:WorldToLocal( WPos2 + Norm2 * 64 )

		--local constraint, axis = constraint.Motor( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, friction, torque, 0, nocollide, 0, self:GetOwner(), 0)
		local constraint, axis = MakeWireMotor( self:GetOwner(), Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, friction, torque, nocollide, forcelimit )
		
		self.constraint, self.axis = constraint, axis
		
		undo.Create("WireMotor")
		if axis then undo.AddEntity( axis ) end
		if constraint then undo.AddEntity( constraint ) end
		undo.SetPlayer( self:GetOwner() )
		undo.Finish()
		
		if axis then self:GetOwner():AddCleanup( "constraints", axis ) end
		if constraint then self:GetOwner():AddCleanup( "constraints", constraint ) end

		self:ReleaseGhostEntity()
		
		self:SetStage(2)

	else
	
		self:StartGhostEntity( trace.Entity )
		self:SetStage( iNum+1 )
		
	end
	
	return true
	
end

function TOOL:RightClick( trace )
	return false
end

if SERVER then

	//need for the const to find the controller after being duplicator pasted
	WireMotorTracking = {}
	
	function MakeWireMotorController( pl, Pos, Ang, MyEntId, model, const, axis )
		local controller = ents.Create("gmod_wire_motor")
		
		controller:SetPos( Pos )
		controller:SetAngles( Ang )
		controller:SetModel( model )
		controller:SetPlayer(pl)
		
		if (!const) then
			WireMotorTracking[ MyEntId ] = controller
		else
			controller.MyId = controller:EntIndex()
			const.MyCrtl = controller:EntIndex()
			controller:SetConstraint( const ) 
			controller:DeleteOnRemove( const )
		end
		if (axis) then
			controller:SetAxis( axis )
			controller:DeleteOnRemove( axis )
		end
		
		controller:Spawn()
		
		return controller
	end
	
	duplicator.RegisterEntityClass("gmod_wire_motor", MakeWireMotorController, "Pos", "Ang", "MyId", "model")
	
	function MakeWireMotor( pl, Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, friction, torque, nocollide, forcelimit, MyCrtl )
		if ( !constraint.CanConstrain( Ent1, Bone1 ) ) then return false end
		if ( !constraint.CanConstrain( Ent2, Bone2 ) ) then return false end
		
		local Phys1 = Ent1:GetPhysicsObjectNum( Bone1 )
		local Phys2 = Ent2:GetPhysicsObjectNum( Bone2)
		local WPos1 = Phys1:LocalToWorld( LPos1 )
		local WPos2 = Phys2:LocalToWorld( LPos2 )
		
		if ( Phys1 == Phys2 ) then return false end

		local const, axis = constraint.Motor( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, friction, torque, 0, nocollide, 0, pl, forcelimit)
		
		if ( !const ) then return nil, axis end
		
		local ctable = 
		{
			Type 		= "WireMotor",
			pl			= pl,
			Ent1		= Ent1,
			Ent2		= Ent2,
			Bone1		= Bone1,
			Bone2		= Bone2,
			LPos1		= LPos1,
			LPos2		= LPos2,
			friction	= friction,
			torque  	= torque,
			nocollide	= nocollide,
			forcelimit  = forcelimit
		}
		const:SetTable( ctable )
		
		if (MyCrtl) then
			Msg("finding crtl for this wired mot const\n")
			local controller = WireMotorTracking[ MyCrtl ]
			
			const.MyCrtl = controller:EntIndex()
			controller.MyId = controller:EntIndex()
			
			controller:SetConstraint( const )
			controller:DeleteOnRemove( const )
			if (axis) then
				controller:SetAxis( axis )
				controller:DeleteOnRemove( axis )
			end
			
			Ent1:DeleteOnRemove( controller )
			Ent2:DeleteOnRemove( controller )
			const:DeleteOnRemove( controller )
		end
		
		return const, axis
	end

	duplicator.RegisterConstraint( "WireMotor", MakeWireMotor, "pl", "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "friction", "torque", "nocollide", "forcelimit", "MyCrtl" )
	
end

function TOOL:Reload( trace )

	if (!trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then return false end
	if ( CLIENT ) then return true end
	
	local  bool = constraint.RemoveConstraints( trace.Entity, "WireMotor" )
	return bool
	
end

function TOOL:Think()

	if (self:NumObjects() != 1) then return end
	
	self:UpdateGhostEntity()

end

function TOOL.BuildCPanel(panel)
	panel:AddControl( "PropSelect", { Label = "#WireMotorTool_model",
									 ConVar = "wire_motor_model",
									 Category = "Wire Motor",
									 Models = controlmodels } )

	panel:AddControl("Slider", {
		Label = "#WireMotorTool_torque",
		Type = "Float",
		Min = "0",
		Max = "10000",
		Command = "wire_motor_torque"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireMotorTool_forcelimit",
		Type = "Float",
		Min = "0",
		Max = "50000",
		Command = "wire_motor_forcelimit"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireMotorTool_friction",
		Type = "Float",
		Min = "0",
		Max = "100",
		Command = "wire_motor_friction"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireMotorTool_nocollide",
		Command = "wire_motor_nocollide"
	})
end
