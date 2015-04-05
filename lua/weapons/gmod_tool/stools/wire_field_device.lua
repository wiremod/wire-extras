TOOL.Category		= "Wire Extras/Physics"
TOOL.Name			= "Field Generator"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "type" ] = ""
TOOL.ClientConVar[ "workonplayers" ] 	= "1"
TOOL.ClientConVar[ "ignoreself" ] 	= "1"
TOOL.ClientConVar[ "arc" ] 	= "360"
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool.wire_field_device.name", "Field Generator Tool (Wire)" )
    language.Add( "Tool.wire_field_device.desc", "Spawns a Field Generator." )
    language.Add( "Tool.wire_field_device.0", "Primary: Create Field Generator" )
	language.Add( "sboxlimit_wire_field_device", "You've hit Field Generator limit!" )
	language.Add( "Undone_wire_field_device", "Undone Wire Field Generator" )
	language.Add( "hint_field_type" , "You Must Select Field Type" )
	language.Add( "hint_field_type" , "You Must Select Field Type" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_field_device', 5)
end

TOOL.ClientConVar["Model"] = "models/jaanus/wiretool/wiretool_grabber_forcer.mdl"

TOOL.FirstSelected = nil

cleanup.Register( "wire_field_device" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_field_device" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_field_device" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local lType=self:GetClientInfo( "type" );
	
	if string.len( lType ) < 2 then ply:SendHint( "field_type" , 0 ) return false end
	
	local wire_field_device_obj = Makewire_field_device( ply, trace.HitPos, Ang , self:GetClientInfo("Model") , lType , self:GetClientNumber("ignoreself") , self:GetClientNumber("workonplayers"), self:GetClientNumber("arc") )
	
	local min = wire_field_device_obj:OBBMins()
	wire_field_device_obj:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_field_device_obj, trace.Entity, trace.PhysicsBone, true)

	undo.Create("wire_field_device")
		undo.AddEntity( wire_field_device_obj )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_field_device", wire_field_device_obj )
	ply:AddCleanup( "wire_field_device", const )

	return true
end

function TOOL:RightClick( trace )
	return false
end

function TOOL:Reload( trace )
	return false
end


if (SERVER) then

	function Makewire_field_device( pl, Pos, Ang, Model , Type , ignoreself , workonplayers , arc )
		if ( !pl:CheckLimit( "wire_field_device" ) ) then return false end
	
		local wire_field_device_obj = ents.Create( "gmod_wire_field_device" )
		if (!wire_field_device_obj:IsValid()) then return false end
		
		wire_field_device_obj:Setworkonplayers(workonplayers);
		wire_field_device_obj:Setignoreself(ignoreself);
		wire_field_device_obj:SetType(Type);
		wire_field_device_obj:Setarc(arc);
		
		wire_field_device_obj:SetAngles( Ang )
		wire_field_device_obj:SetPos( Pos )
		wire_field_device_obj:SetModel( Model )
		wire_field_device_obj:Spawn()
		
		wire_field_device_obj:SetPlayer( pl )
		wire_field_device_obj.pl = pl

		pl:AddCount( "wire_field_device", wire_field_device_obj )

		return wire_field_device_obj
	end
	
	duplicator.RegisterEntityClass("gmod_wire_field_device", Makewire_field_device, "Pos", "Ang", "Model", "FieldType" , "ignoreself" , "workonplayers" , "arc" , "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostgmod_wire_field_device( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_field_device" ) then
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
		self:MakeGhostEntity( self:GetClientInfo("Model"), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostgmod_wire_field_device( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)

	panel:AddControl("Header", { Text = "#Tool.wire_field_device.name", Description = "#Tool.wire_field_device.desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#Type",
		
		Options = {
			Gravity = {
				wire_field_device_type="Gravity"
			},
			Attraction = {
				wire_field_device_type="Pull"
			},
			Repulsion = {
				wire_field_device_type="Push"
			},
			Stasis = {
				wire_field_device_type="Hold"
			},
			Wind = {
				wire_field_device_type="Wind"
			},
			Vortex = {
				wire_field_device_type="Vortex"
			},
			Flame = {
				wire_field_device_type="Flame"
			},
			Pressure = {
				wire_field_device_type="Crush"
			},
			Electromagnetic = {
				wire_field_device_type="EMP"
			},
			Radiation = {
				wire_field_device_type="Death"
			},
			Recovery = {
				wire_field_device_type="Heal"
			},
			Acceleration = {
				wire_field_device_type="Speed"
			},
			Battery = {
				wire_field_device_type="Battery"
			},
			Phase = {
				wire_field_device_type="NoCollide"
			}
		}
		
	} )
	
	panel:AddControl( "Checkbox", { Label = "Ignore Self & Connected Props:", Description = "Makes the Generator, and its contraption, Immune it its own effects.", Command = "wire_field_device_ignoreself" } )
	panel:AddControl( "Checkbox", { Label = "Affect players:", Description = "Removes Player Immunity to fields.", Command = "wire_field_device_workonplayers" } )
	
	panel:AddControl( "Slider" , { 
		Type = "Float",
		Min = "0.1",
		Max = "360.0",
		Label = "Arc Size:" , 
		Description = "The Arc( in Degrees ) taht the field is emitted, ( 0 or 360 for circle )" , 
		Command ="wire_field_device_arc" 
	} );
		
end
