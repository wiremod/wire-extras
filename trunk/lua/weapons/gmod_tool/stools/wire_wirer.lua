TOOL.Category		= "Wire - Data"
TOOL.Name			= "Wired Wirer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

/* If we're running on the client, setup the description strings */
if ( CLIENT ) then
    language.Add( "Tool_wire_wirer_name", "Wired Wirer Tool" )
    language.Add( "Tool_wire_wirer_desc", "Spawns a Wired Wirer." )
    language.Add( "Tool_wire_wirer_0", "Primary: Create/Update Wirer" )
	language.Add( "WireWirer_Range", "Max Range:" )
	language.Add( "WireWirer_Model", "Choose a Model:")
	language.Add( "WireWirer_Width", "Wire Width:" )
    language.Add( "WireWirer_Material", "Material:" )
    language.Add( "WireWirer_Colour", "Colour:" )
	language.Add( "WireWirer_WireTypeInputs", "Use Inputs for Wire Properties:" )
	language.Add( "WireWirer_TargetPos_Input", "Use Inputs for 3D Target Position Instead:" )
	language.Add( "SBoxLimit_wire_wirers", "You've hit the wired wierer limit!" )
    language.Add( "Undone_Wired Wirer", "Undone Wired Wirer" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_wirers', 10)
end

TOOL.ClientConVar[ "Model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "Range" ] = "1000"
TOOL.ClientConVar[ "Width" ] = "2"
TOOL.ClientConVar[ "WireMaterial" ] = "cable/cable2"
TOOL.ClientConVar[ "Color_R" ] = "255"
TOOL.ClientConVar[ "Color_G" ] = "255"
TOOL.ClientConVar[ "Color_B" ] = "255"
TOOL.ClientConVar[ "Wiretype_Input" ] = "0"
TOOL.ClientConVar[ "TargetPos_Input" ] = "0"

local transmodels = {
    ["models/jaanus/wiretool/wiretool_siren.mdl"] = {},
    ["models/jaanus/wiretool/wiretool_beamcaster.mdl"] = {},
	["models/jaanus/wiretool/wiretool_range.mdl"] = {}
					};

cleanup.Register( "wire_wirers" )

function TOOL:LeftClick( trace )
	/* Everything is server except the trace */
	if (!SERVER) then return true end
	
	/* Setup all of our local variables */
	local ply = self:GetOwner()

	//set some of the values
	local Range = self:GetClientNumber("Range")
	local Model = self:GetClientInfo("Model")
	local Width = self:GetClientNumber("Width")
	local WireMaterial = self:GetClientInfo("WireMaterial")
	local Color_R = self:GetClientNumber("Color_R")
	local Color_G = self:GetClientNumber("Color_G")
	local Color_B = self:GetClientNumber("Color_B")
	local Wiretype_Input = self:GetClientNumber("Wiretype_Input")
	local TargetPos_Input = self:GetClientNumber("TargetPos_Input")
	local WireColor = Vector(Color_R,Color_G,Color_B)
	
	if ( !self:GetSWEP():CheckLimit( "wire_wirers" ) ) then return false end
	
	/* Don't want to put one on a player or another wirer  also add suport for updating*/
	if (trace.Entity:IsPlayer()) then return false end
	if(trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_wirer" and trace.Entity.pl == ply) then
		trace.Entity:Setup(Range, Width, WireMaterial, WireColor, Wiretype_Input,TargetPos_Input)
		
		trace.Entity.Range = Range
		trace.Entity.WireWidth = Width
		trace.Entity.WireMaterial = WireMaterial
		trace.Entity.WireColor = WireColor
		trace.Entity.Wiretype_Input = Wiretype_Input
		trace.Entity.TargetPos_Input = TargetPos_Input
		trace.Entity.pl = ply
		
		return true
	end

	/* Normal to hit surface */
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	/* Make the WiredWirer*/
	local ent = MakeWiredWirer(ply, Model, trace.HitPos, Range, Width, WireMaterial, WireColor, Wiretype_Input, TargetPos_Input, Ang)
	
	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )

	/* Weld it to the surface, as long as it isn't the ground */
	if (!trace.HitWorld) then
		local const = WireLib.Weld(ent, trace.Entity, trace.PhysicsBone, true)
	end

	/* Add it to the undo list */
	undo.Create("Wired Wirer")
		undo.AddEntity(ent)
		if (!(const == nil)) then
			undo.AddEntity(const)
		end
		undo.SetPlayer(ply)
	undo.Finish()
	
	ply:AddCleanup( "wire_wirers", ent )
	
	return true
end

function TOOL:Reload(trace)
end


if (SERVER) then
	/* Makes a WiredWirer*/
	function MakeWiredWirer(pl, Model, Pos, Range, WireWidth, WireMaterial, WireColor, Wiretype_Input, TargetPos_Input, Ang, nocollide, Vel, aVel, frozen)
		if ( !pl:CheckLimit( "wire_wirers" ) ) then return false end
		
		local ent = ents.Create("gmod_wire_wirer")
		if (!ent:IsValid()) then return false end
		WireWidth = math.Clamp(math.abs(WireWidth),0,15)
		ent:SetAngles(Ang)
		ent:SetPos(Pos)
		if(!Model) then
			ent:SetModel("models/jaanus/wiretool/wiretool_siren.mdl")
		else
			ent:SetModel(Model)
		end
		ent:Spawn()
		ent:SetPlayer(pl)
		ent:Setup(Range, WireWidth, WireMaterial, WireColor, Wiretype_Input, TargetPos_Input)
		ent:Activate()
		
		ent:SetPlayer( pl )

		local ttable = {
		    Range = Range,
			WireWidth = WireWidth,
			WireMaterial = WireMaterial,
			WireColor = WireColor,
			Wiretype_Input = Wiretype_Input,
			TargetPos_Input =  TargetPos_Input,
			pl = pl
		}
		table.Merge(ent:GetTable(), ttable )
		
		pl:AddCount( "wire_wirers", ent )
		
		return ent
	end
	
	/* Register us for duplicator compatibility */
	duplicator.RegisterEntityClass("gmod_wire_wirer", MakeWiredWirer, "Model", "Pos", "Range", "WireWidth", "WireMaterial", "WireColor", "Wiretype_Input", "TargetPos_Input", "Ang", "nocollide", "Vel", "aVel", "frozen")
end

function TOOL:UpdateGhostWireWiredWirer( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_wirer" || trace.Entity:IsPlayer()) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo("Model") ) then
		self:MakeGhostEntity( self:GetClientInfo("Model"), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireWiredWirer( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel( panel )
	panel:AddControl("Header", { 
		Text = "#Tool_wire_wirer_name", 
		Description = "#Tool_wire_wirer_desc" 
	})
									 
	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire",

		Options = {
			Default = {
				wire_material = "cable/rope",
				wire_width = "3",
			}
		},

		CVars = {
			[0] = "wire_Width",
			[1] = "wire_Material",
		}
	})
	
	panel:AddControl( "PropSelect", { Label = "#WireWirer_Model",
								 ConVar = "wire_wirer_Model",
								 Category = "WiredWirer",
								 Models = transmodels } )
	
	panel:AddControl("Slider", {
		Label = "#WireWirer_Range",
		Type = "Float",
		Min = "1",
		Max = "100000",
		Command = "wire_wirer_Range"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireWirer_Width",
		Type = "Float",
		Min = "0",
		Max = "5",
		Command = "wire_wirer_Width"
	})
	
	panel:AddControl( "MatSelect", { 
			Height = "1", 
			Label = "#WireWirer_Material", 
			ItemWidth = 24, 
			ItemHeight = 64, 
			ConVar = "wire_wirer_WireMaterial", 
			Options = list.Get( "WireMaterials" ) 
		} )

	panel:AddControl("Color", {
		Label = "#WireWirer_Colour",
		Red = "wire_wirer_Color_R",
		Green = "wire_wirer_Color_G",
		Blue = "wire_wirer_Color_B",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireWirer_WireTypeInputs",
		Command = "wire_wirer_Wiretype_Input"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireWirer_TargetPos_Input",
		Command = "wire_wirer_TargetPos_Input"
	})
end
