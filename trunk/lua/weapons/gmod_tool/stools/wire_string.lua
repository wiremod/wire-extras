
TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Constant String"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_string_name", "String Tool (Wire)" )
    language.Add( "Tool_wire_string_desc", "Spawns a constant string prop for use with the wire system." )
    language.Add( "Tool_wire_string_0", "Primary: Create/Update Value   Secondary: Copy Settings" )
	language.Add( "WireStringTool_string", "String:" )
	language.Add( "sboxlimit_wire_strings", "You've hit strings limit!" )
	language.Add( "undone_wirestring", "Undone Wire String" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_strings', 20)
end

TOOL.ClientConVar[ "model" ] = "models/kobilica/value.mdl"
TOOL.ClientConVar[ "numstrings" ] = "1"
TOOL.ClientConVar[ "string1" ] = ""
TOOL.ClientConVar[ "string2" ] = ""
TOOL.ClientConVar[ "string3" ] = ""
TOOL.ClientConVar[ "string4" ] = ""
TOOL.ClientConVar[ "string5" ] = ""
TOOL.ClientConVar[ "string6" ] = ""
TOOL.ClientConVar[ "string7" ] = ""
TOOL.ClientConVar[ "string8" ] = ""
TOOL.ClientConVar[ "string9" ] = ""
TOOL.ClientConVar[ "string10" ] = ""
TOOL.ClientConVar[ "string11" ] = ""
TOOL.ClientConVar[ "string12" ] = ""


if (SERVER) then
	ModelPlug_Register("value")
end

cleanup.Register( "wire_strings" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	// Get client's CVars
	local model		= self:GetClientInfo( "model" )
	local numstrings	= self:GetClientNumber( "numstrings" )
	
	//str is a table of strings so we can save a step later in adjusting the outputs
	local str = {}
	for i = 1, numstrings do
		str[i] = self:GetClientInfo( "string"..i )
	end
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_string" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(str)
		trace.Entity.string = str
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_strings" ) ) then return false end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local wire_string = MakeWireString( ply, model, trace.HitPos, Ang, str )
	
	local min = wire_string:OBBMins()
	wire_string:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const = WireLib.Weld(wire_string, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WireString")
		undo.AddEntity( wire_string )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_strings", wire_string )
	
	return true
end

function TOOL:RightClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_string" ) then
	    local i = 0
		for k,v in pairs(trace.Entity.string) do
			self:GetOwner():ConCommand("wire_string_string"..k.." "..v)
			i = i + 1
		end
		self:GetOwner():ConCommand("wire_string_numstrings "..i)
		return true
	end
end

if (SERVER) then

	function MakeWireString( pl, Model, Pos, Ang, str, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_strings" ) ) then return false end
	
		local wire_string = ents.Create( "gmod_wire_string" )
		if (!wire_string:IsValid()) then return false end

		wire_string:SetAngles( Ang )
		wire_string:SetPos( Pos )
		wire_string:SetModel( Model )
		wire_string:Spawn()
		
		//for old saves
		if type(str) != "table" then 
			local v = str
			str = {}
			str[v] = tostring(v)
		end
		
		wire_string:Setup(str)
		wire_string:SetPlayer( pl )

		local ttable = {
			str		        = str,
			pl              = pl
			}

		table.Merge(wire_string:GetTable(), ttable )
		
		pl:AddCount( "wire_strings", wire_string )

		return wire_string
	end

	duplicator.RegisterEntityClass("gmod_wire_string", MakeWireValue, "Model", "Pos", "Ang", "str", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireValue( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_string" ) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireValue( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_string_name", Description = "#Tool_wire_string_desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_string",
		
		Options = {
			Default = {
				wire_string_string = "0",
			}
		},
		
		CVars = {
			[0] = "wire_string_string",
		}
	})
	
	panel:AddControl("Slider", {
		Label = "Num of Strings",
		Type = "Integer",
		Min = "1",
		Max = "12",
		Command = "wire_string_numstrings"
	})
	
	for i = 1,12 do
		panel:AddControl("TextBox", {
			Label = tostring(i),
			MaxLength = 100,
			Command = "wire_string_string"..i
		})
	end
	
	ModelPlug_AddToCPanel(panel, "value", "wire_string", "#WireValueTool_model", nil, "#WireValueTool_model")
end
