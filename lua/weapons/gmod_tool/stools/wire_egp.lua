--Wire EGP by Goluch/Doridian/TomyLobo
--YAY Wire Lib GPU Thanx dude

TOOL.Category		= "Wire - Display"
TOOL.Name			= "EGP V2"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool_wire_egp_name", "E2 Graphics Processor" )
    language.Add( "Tool_wire_egp_desc", "EGP Tool" )
    language.Add( "Tool_wire_egp_0", "Primary: Create EGP , Secondry: Create EGP Emitter" )
	language.Add( "sboxlimit_wire_egps", "You've hit EGP limit!" )
	language.Add( "Undone_wireegp", "Undone EGP" )
	language.Add("Tool_wire_egp_createflat", "Create flat to surface")
end


TOOL.ClientConVar["model"] = "models/kobilica/wiremonitorbig.mdl"
TOOL.ClientConVar["createflat"] = 1

if (SERVER) then
	CreateConVar('sbox_maxwire_egps', 20)
end

cleanup.Register( "wire_egps" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	
	if ( !self:GetSWEP():CheckLimit( "wire_egps" ) ) then return false end
	
	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end
	
	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local model = self:GetClientInfo("model")
	local CreateFlat = self:GetClientNumber("createflat")
	local wire_egp
	
	if (CreateFlat == 0) then
		Ang.pitch = Ang.pitch + 90
	end
	
	if (string.find(self:GetClientInfo( "model" ),"models/hunter/plates/"))  or (string.find(self:GetClientInfo( "model" ),"models/cheeze/pcb")) then
		Ang.pitch = Ang.pitch + 90
	end
	
	wire_egp = MakeWireEGP(ply, trace.HitPos, Ang, model)
	 
	local min = wire_egp:OBBMins()
	wire_egp:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_egp, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("wireegp")
		undo.AddEntity( wire_egp )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_egps", wire_egp )

	return true
end

function TOOL:RightClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	if ( !self:GetSWEP():CheckLimit( "wire_egps" ) ) then return false end
	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local model = self:GetClientInfo("model")
	local wire_egp = MakeWireEGPEmit(ply, trace.HitPos, Ang)
	local min = wire_egp:OBBMins()
	wire_egp:SetPos( trace.HitPos - trace.HitNormal * min.z )
	local const = WireLib.Weld(wire_egp, trace.Entity, trace.PhysicsBone, true)
	undo.Create("wireegp")
		undo.AddEntity( wire_egp )
		undo.SetPlayer( ply )
	undo.Finish()
	ply:AddCleanup( "wire_egps", wire_egp )
end

if (SERVER) then
	function MakeWireEGP( pl, Pos, Ang, model)
		if ( !pl:CheckLimit( "wire_egps" ) ) then return false end
		
		local wire_egp = ents.Create( "gmod_wire_egp" )
		if (!wire_egp:IsValid()) then return false end
		wire_egp:SetModel(model)

		wire_egp:SetAngles( Ang )
		wire_egp:SetPos( Pos )
		wire_egp:Spawn()
		wire_egp:SetPlayer(pl)
		
		local ttable = {
			pl = pl,
			model = model
		}
		table.Merge(wire_egp:GetTable(), ttable )
		pl:AddCount( "wire_egps", wire_egp )
		return wire_egp
	end
	duplicator.RegisterEntityClass("gmod_wire_egp", MakeWireEGP, "Pos", "Ang", "Model")
	
	function MakeWireEGPEmit( pl, Pos, Ang)
		if ( !pl:CheckLimit( "wire_egps" ) ) then return false end
		
		local wire_egp = ents.Create( "gmod_wire_egp_emitter" )
		if (!wire_egp:IsValid()) then return false end
		wire_egp:SetModel("models/bull/dynamicbutton.mdl")

		wire_egp:SetAngles( Ang + Angle(90,0,0) )
		wire_egp:SetPos( Pos )
		wire_egp:Spawn()
		wire_egp:SetPlayer(pl)
		
		local ttable = {
			pl = pl,
		}
		table.Merge(wire_egp:GetTable(), ttable )
		pl:AddCount( "wire_egps", wire_egp )
		return wire_egp
	end
	duplicator.RegisterEntityClass("gmod_wire_egp", MakeWireEGP, "Pos", "Ang")
end

function TOOL:UpdateGhostWireEGP( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr = utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace = util.TraceLine( tr )
	if (!trace.Hit) then return end
	local Ang = trace.HitNormal:Angle()
	
	if (self:GetClientNumber("createflat") == 0) then
		Ang.pitch = Ang.pitch + 90
	end
	
	if (string.find(self:GetClientInfo( "model" ),"models/hunter/plates/"))  or (string.find(self:GetClientInfo( "model" ),"models/cheeze/pcb")) then
		Ang.pitch = Ang.pitch + 90
	end
	
	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )
	ent:SetNoDraw( false )
end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) || (not self.GhostEntity:GetModel()) ) then
		local Emitter = self:GetClientNumber("emitter")
		local model = self:GetClientInfo( "model" )
		self:MakeGhostEntity( model, Vector(0,0,0), Angle(0,0,0) )
	end
	self:UpdateGhostWireEGP( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	if !(EGP) then return end
	panel:SetSpacing( 10 )
	panel:SetName( "E2 Graphics Processor" )
	
	panel:AddControl( "Label", { Text = "EGP2 by Goluch|Doridian|Tomylobo" }  )
	
	panel:AddControl("Header", { Text = "#Tool_wire_egp_name", Description = "#Tool_wire_egp_desc" })
	WireDermaExts.ModelSelect(panel, "wire_egp_model", list.Get( "WireScreenModels" ), 2)
	panel:AddControl("Checkbox", {Label = "#Tool_wire_egp_createflat",Command = "wire_egp_createflat"})
	panel:AddControl( "Label", { Text = "REV: " .. EGP.Rev }  )
	panel:AddControl( "Label", { Text = "Update Log:" }  )
	
	local scroll = vgui.Create("DPanelList")
	scroll:SetSize( 200, 300 )
	scroll:EnableVerticalScrollbar( true )
	for _,v in pairs(EGP.Log) do
		local layout = v.S
		local logg = vgui.Create("DLabel")
		logg:SetText(layout)
		scroll:AddItem( logg )
	end
	panel:AddItem( scroll )
	
end
	
function TOOL:RenderToolScreen()
	cam.Start2D()
		if not EGP or not EGP.Process then return end
		self.Render = {
			{image = "box",X = 0,Y = 0,W = 256,H = 256,R = 0,G = 0,B = 0,A = 255},
			{image = "box",X = 50,Y = 50,W = 150,H = 150,R = 255,G = 0,B = 0,A = 255,material = "expression 2/cog"},
			{image = "text",X = 128,Y = 100,R = 0,G = 0,B = 0,A = 255,text = "EGP",fsize = 50,fid = 4,falign = 1},
			{image = "text",X = 128,Y = 102,R = 255,G = 0,B = 0,A = 255,text = "EGP",fsize = 47,fid = 4,falign = 1}
		}
		
		EGP.Process(self)
		--Yes the tool screen is an egp screen now too.
		
	cam.End2D()
end
