   /* Door stool: Orgiginal code by High6 */
  /*       Modified by Doridian          */
 /*              v1.6b                  */
/*                                     */
local defaultlimit = 5

TOOL.ClientConVar[ "class" ] = "prop_dynamic"
TOOL.ClientConVar[ "model" ] = "models/props_combine/combine_door01.mdl"
TOOL.ClientConVar[ "open" ] = "1"
TOOL.ClientConVar[ "close" ] = "2"
TOOL.ClientConVar[ "autoclose" ] = "0"
TOOL.ClientConVar[ "closetime" ] = "5"
TOOL.ClientConVar[ "hardware" ] = "1"
cleanup.Register( "door" )

TOOL.Category		= "Wire - Physics"		// Name of the category
TOOL.Name			= "#Door"		// Name to display
TOOL.Command		= nil				// Command on click (nil for default)
TOOL.ConfigName		= ""				// Config file name (nil for default)

local GhostEntity
--prop_door_rotating
--prop_dynamic
if SERVER then
	local Doors = {}
	
	local function Save( save )
	
		saverestore.WriteTable( Doors, save )
		
	end
	
	local function Restore( restore )
	
		Doors = saverestore.ReadTable( restore )
		
	end
	
	saverestore.AddSaveHook( "Doors", Save )
	saverestore.AddRestoreHook( "Doors", Restore )
	
	
if !ConVarExists("sbox_maxdoors") then CreateConVar("sbox_maxdoors", defaultlimit, FCVAR_NOTIFY ) end
	function makedoor(ply,trace,ang,model,open,close,autoclose,closetime,class,hardware)
		if ( !ply:CheckLimit( "doors" ) ) then return nil end
		local entit = ents.Create("wired_door")
		entit:SetModel("models/jaanus/wiretool/wiretool_gate.mdl")
		local minn = entit:OBBMins()
		local newpos = Vector(trace.HitPos.X,trace.HitPos.Y,trace.HitPos.Z - (trace.HitNormal.z * minn.z) )
		entit:SetPos( newpos )
		entit:SetAngles(Angle(0,ang.Yaw,0))
		entit:Spawn()	
		entit:Activate() 
		entit:SetPlayer( ply )
		ply:AddCount( "doors", entit )
		ply:AddCleanup( "doors", entit )
		
		local index = ply:UniqueID()
		Doors[ index ] 			= Doors[ index ] or {}
		Doors[ index ][1] 	= Doors[ index ][1] or {}
		table.insert( Doors[ index ][1], entit )
		
		
		undo.Create("Door")
		undo.AddEntity( entit )
		undo.SetPlayer( ply )
		undo.Finish()
		entit.Entity:makedoor(ply,trace,ang,model,open,close,autoclose,closetime,class,hardware)
	end
end

if ( CLIENT ) then

	language.Add( "Tool_wire_door_name", "Door" )
	language.Add( "Tool_wire_door_desc", "Spawn a Door" )
	language.Add( "Tool_wire_door_0", "Click somewhere to spawn a door." )

	language.Add( "Undone_door", "Undone door" )
	language.Add( "Cleanup_door", "door" )
	language.Add( "SBoxLimit_doors", "Max Doors Reached!" )
	language.Add( "Cleaned_door", "Cleaned up all doors" )

end


function TOOL:LeftClick( tr )
	if CLIENT then return true end	
	local model	= self:GetClientInfo( "model" )
	local open = self:GetClientNumber( "open" ) 
	local close = self:GetClientNumber( "close" )  
	local class = self:GetClientInfo( "class" )
	if class ~= "prop_dynamic" and class ~= "prop_door_rotating" then return false end
	local ply = self:GetOwner()
	local ang = ply:GetAimVector():Angle() 
	local autoclose = self:GetClientNumber( "autoclose" )  
	local closetime = self:GetClientNumber( "closetime" )  
	local hardware = self:GetClientNumber( "hardware" )  
	if ( !self:GetSWEP():CheckLimit( "doors" ) ) then return false end
	makedoor(ply,tr,ang,model,open,close,autoclose,closetime,class,hardware)
	
	return true

end

function TOOL.BuildCPanel( CPanel )

	// HEADER
	CPanel:AddControl( "Header", { Text = "#Tool_wire_door_name", Description	= "#Tool_wire_door_desc" }  )
	
	// PRESETS
	local params = { Label = "#Presets", MenuButton = 1, Folder = "door", Options = {}, CVars = {} }
			
		params.Options.default = {
			wire_door_model = "models/props_combine/combine_door01.mdl",
			wire_door_open	= 1,
			wire_door_close	= 2 }
			
		table.insert( params.CVars, "wire_door_open" )
		table.insert( params.CVars, "wire_door_close" )
		table.insert( params.CVars, "wire_door_model" )
		
	CPanel:AddControl( "ComboBox", params )
	
	
	// KEY
	// CPanel:AddControl( "Numpad", { Label = "#Door Open",Label2 = "#Door Close", Command = "wire_door_open",Command2 = "wire_door_close", ButtonSize = 22 } )
	
	
	// EMITTERS
	local params = { Label = "#Models", Height = 150, Options = {} }

	params.Options[ "TallCombineDoor" ] = { wire_door_class = "prop_dynamic",wire_door_model = "models/props_combine/combine_door01.mdl" }
	params.Options[ "ElevatorDoor" ] = { wire_door_class = "prop_dynamic",wire_door_model = "models/props_lab/elevatordoor.mdl" }
	params.Options[ "CombineDoor" ] = { wire_door_class = "prop_dynamic",wire_door_model = "models/combine_gate_Vehicle.mdl" }
	params.Options[ "SmallCombineDoor" ] = { wire_door_class = "prop_dynamic",wire_door_model = "models/combine_gate_citizen.mdl" }
	params.Options[ "Door1" ] = { wire_door_hardware = "1",wire_door_class = "prop_door_rotating",wire_door_model = "models/props_c17/door01_left.mdl" }
	params.Options[ "Door2" ] = { wire_door_hardware = "2",wire_door_class = "prop_door_rotating",wire_door_model = "models/props_c17/door01_left.mdl" }
	params.Options[ "KlabBlastDoor(by †Omen†)" ] = { wire_door_class = "prop_dynamic",wire_door_model = "models/props_doors/doorKLab01.mdl" }

	CPanel:AddControl( "ListBox", params )
	CPanel:AddControl( "Slider",  { Label	= "#AutoClose Delay",
								Type	= "Float",
								Min		= 0,
								Max		= 100,
								Command = "wire_door_closetime" }	 )
	CPanel:AddControl( "Checkbox", { Label = "#AutoClose", Command = "wire_door_autoclose" } )

end

function TOOL:UpdateGhostThruster( ent, Player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( Player, Player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
		local ang = Player:GetAimVector():Angle() 
		local minn = ent:OBBMins()
		local newpos = Vector(trace.HitPos.X,trace.HitPos.Y,trace.HitPos.Z - (trace.HitNormal.z * minn.z))
		ent:SetPos( newpos )
		ent:SetAngles(Angle(0,ang.Yaw,0))
	
end


function TOOL:Think()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostThruster( self.GhostEntity, self:GetOwner() )
	
end
