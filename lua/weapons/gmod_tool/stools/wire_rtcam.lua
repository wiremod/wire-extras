/*******************************
	Wired RT Camera
	  for Wiremod
	  
	(C) Sebastian J.
********************************/

TOOL.Category		= "Wire Extras/Visuals"
TOOL.Name			= "RT Camera"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool.wire_rtcam.name", "Wired RT Camera" )
    language.Add( "Tool.wire_rtcam.desc", "Spawns a RT Cam which can be activated using wire" )
    language.Add( "Tool.wire_rtcam.0", "Primary: Create RT Camera" )
	language.Add( "Tool.wire_rtcam.button", "Open RT Screen" )
	language.Add( "Tool.wire_rtcam.monitor", "Show monitor on screen" )
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
-- Global Function to update the render target --This was removed by garry, adding it here fixes the tool.

function UpdateRenderTarget( ent )
	if ( !ent || !ent:IsValid() ) then return end

	if ( !RenderTargetCamera || !RenderTargetCamera:IsValid() ) then
	
		RenderTargetCamera = ents.Create( "point_camera" )
		RenderTargetCamera:SetKeyValue( "GlobalOverride", 1 )
		RenderTargetCamera:Spawn()
		RenderTargetCamera:Activate()
		RenderTargetCamera:Fire( "SetOn", "", 0.0 )

	end
	Pos = ent:LocalToWorld( Vector( 12,0,0 ) )
	RenderTargetCamera:SetPos(Pos)
	RenderTargetCamera:SetAngles(ent:GetAngles())
	RenderTargetCamera:SetParent(ent)

	RenderTargetCameraProp = ent
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
	panel:AddControl("Header", { Text = "#Tool.wire_rtcam.name", Description = "#Tool.wire_rtcam.desc" })
	panel:AddControl("Button", { Text = "#Tool.wire_rtcam.button", Command = "rtcamera_window" })
	panel:AddControl("CheckBox", { Label = "#Tool.wire_rtcam.monitor", Command = "rtcamera_draw" })
end
