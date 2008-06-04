TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Servo"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.ClientConVar[ "model" ] = "models/props_vehicles/carparts_wheel01a.mdl"

if ( CLIENT ) then
    language.Add( "Tool_wire_servo_name", "Servo Tool (Wire)" )
    language.Add( "Tool_wire_servo_desc", "Spawns a servo." )
    language.Add( "Tool_wire_servo_0", "Primary: Create servo. Secondary: Get Model" )
    language.Add( "WireDataServoTool_servo", "Servo:" )
	language.Add( "sboxlimit_wire_servos", "You've hit servos limit!" )
	language.Add( "undone_Wire Servo", "Undone Wire servo" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_servos', 20)
end

cleanup.Register( "wire_servos" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_servo4" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_servos" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local Model	= self:GetClientInfo( "model" )

	local wire_servo = MakeWireServo( ply, Model, trace.HitPos, Ang )

	local min = wire_servo:OBBMins()
	wire_servo:SetPos( trace.HitPos - trace.HitNormal * min.z )

	
	local const = constraint.Weld(wire_servo, trace.Entity, 0, trace.PhysicsBone, 0, 1, 0)

	
	//######################
	local constball = constraint.AdvBallsocket( wire_servo, trace.Entity, 0, trace.PhysicsBone, Vector(0,0,0), Vector(0,0,0), 0, 0, -720, -720, -720, 720, 720, 720, 0, 0, 0, 0, 1 )
//	local constball = constraint.Axis( wire_servo, trace.Entity, 0, trace.PhysicsBone, Vector(0,0,0), Vector(0,0,0), 0, 0, 0, 1, wire_servo:GetRight() )
//	local constball = constraint.Ballsocket(wire_servo, trace.Entity, 0, trace.PhysicsBone, Vector(0,0,0), 0, 0, 0) //This needs to be an advanced ball
//	const:SetName( "temp_weld" )
//	wire_weight:SetVar( "attached", trace.Entity )
//	wire_weight:SetVar( "attbone", trace.PhysicsBone )
//	wire_weight:SetVar( "constraint", const )
	//######################
	
	wire_servo:SendObjects( const, trace.Entity ) //This function works, the entity is received by the... entity. Yeah.

	undo.Create("Wire Servo")
		undo.AddEntity( wire_servo )
		undo.AddEntity( const )
		undo.AddEntity( constball )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_servos", wire_servo )

	return true
end

function TOOL:RightClick( trace )
	if CLIENT and trace.Entity:IsValid() then return true end
	if not trace.Entity:IsValid() then return end
	local model = trace.Entity:GetModel()
	self:GetOwner():ConCommand("wire_servo_model "..model);
	self.Model = model
	return true;
end

if (SERVER) then

	function MakeWireServo( pl, Model, Pos, Ang )
		if ( !pl:CheckLimit( "wire_servos" ) ) then return false end
	
		local wire_servo = ents.Create( "gmod_wire_servo4" )
		if (!wire_servo:IsValid()) then return false end

		wire_servo:SetAngles(Ang)
		wire_servo:SetPos(Pos)
		wire_servo:SetModel(Model)
		wire_servo:Spawn()

		wire_servo:GetTable():SetPlayer( pl )

		local ttable = {
			pl = pl
		}

		table.Merge(wire_servo:GetTable(), ttable )
		
		pl:AddCount( "wire_servos", wire_servo )

		return wire_servo
	end
	
	duplicator.RegisterEntityClass("gmod_wire_servo4", MakeWireServo, "Model", "Pos", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireServo( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_servo4" ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )
end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.Model ) then
		self:MakeGhostEntity( self:GetClientInfo("model"), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireServo( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)

	panel:AddControl("Header", { Text = "#Tool_wire_servo_name", Description = "#Tool_wire_servo_desc" })
	
end
