/*******************************
	Wired RT Camera
	  for Wiremod
	  
	(C) Sebastian J.
********************************/

TOOL.Category		= "Wire - I/O"
TOOL.Name			= "RT Camera"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_rtcam_name", "Wired RT Camera" )
    language.Add( "Tool_wire_rtcam_desc", "Spawns a RT Cam which can be activated using wire" )
    language.Add( "Tool_wire_rtcam_0", "Primary: Create RT Camera" )
	language.Add( "Tool_wire_rtcam_button", "Open RT Screen" )
end

TOOL.Model = "models/dav0r/camera.mdl"

function TOOL:LeftClick( trace )

	if (CLIENT) then return end
		
	local ply 		= self:GetOwner()
	local pid 		= ply:UniqueID()
	
	local Pos = trace.StartPos
	
	local camera = ents.Create( "gmod_wire_rtcam" )
	if (!camera:IsValid()) then return false end
	
	camera:SetAngles( ply:EyeAngles() )
	camera:SetPos( Pos )
	camera:Spawn()
	
	camera:SetPlayer( ply )		
	camera:SetTracking( NULL, Vector(0) )
	
	undo.Create("RT Camera")
		undo.AddEntity( camera )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "cameras", camera )
	
	if !RenderTargetCamera || #ents.FindByClass( "gmod_rtcameraprop" ) == 1 then UpdateRenderTarget( camera ) end
	
	return false, camera
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then

	function MakeWireRTCam( pl, Pos, Ang )	
		local wire_cam = ents.Create( "gmod_wire_rtcam" )
		if (!wire_cam:IsValid()) then return false end

		wire_cam:SetAngles( Ang )
		wire_cam:SetPos( Pos )
		wire_cam:Spawn()
		wire_cam:SetPlayer( pl )
		
		return wire_cam
	end
	
	duplicator.RegisterEntityClass("gmod_wire_rtcam", MakeWireRTCam, "Pos", "Ang", "Vel", "aVel", "frozen")
end

function TOOL:Think()
end

function TOOL:DrawToolScreen( w, h )
	rtTexture = surface.GetTextureID( "pp/rt" )
	surface.SetTexture( rtTexture )
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.DrawTexturedRect( 0, 26, w, h - 48 )	
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_rtcam_name", Description = "#Tool_wire_rtcam_desc" })
	panel:AddControl("Button", { Text = "#Tool_wire_rtcam_button", Command = "rtcamera_window" })
	panel:AddControl("CheckBox", { Text = "#Show Monitor on Screen", Command = "rtcamera_draw" })
end
