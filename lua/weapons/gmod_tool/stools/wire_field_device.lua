TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Field Generator"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "type" ] = ""

if ( CLIENT ) then
    language.Add( "Tool_wire_field_device_name", "Field Generator Tool (Wire)" )
    language.Add( "Tool_wire_field_device_desc", "Spawns a Field Generator." )
    language.Add( "Tool_wire_field_device_0", "Primary: Create Field Generator" )
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
	
	local wire_field_device_obj = Makewire_field_device( ply, trace.HitPos, Ang , self:GetClientInfo("Model") , lType )
	
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

	function Makewire_field_device( pl, Pos, Ang, Model , Type )
		if ( !pl:CheckLimit( "wire_field_device" ) ) then return false end
	
		local wire_field_device_obj = ents.Create( "gmod_wire_field_device" )
		if (!wire_field_device_obj:IsValid()) then return false end

		wire_field_device_obj.Type=Type;
		wire_field_device_obj:SetAngles( Ang )
		wire_field_device_obj:SetPos( Pos )
		wire_field_device_obj:SetModel( Model )
		wire_field_device_obj:Spawn()
		
		wire_field_device_obj:SetPlayer( pl )
		wire_field_device_obj.pl = pl

		pl:AddCount( "wire_field_device", wire_field_device_obj )

		return wire_field_device_obj
	end
	
	duplicator.RegisterEntityClass("gmod_wire_field_device", Makewire_field_device, "Pos", "Ang", "Model", "Type" , "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostgmod_wire_field_device( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
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

	panel:AddControl("Header", { Text = "#Tool_wire_field_device_name", Description = "#Tool_wire_field_device_desc" })
	
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
			Static = {
				wire_field_device_type="Hold"
			}
		}
		
	} )
	
	
end
