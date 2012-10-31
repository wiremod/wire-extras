TOOL.Category = "Wire - Physics"
TOOL.Name = "Touchplate"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["model"] = "models/props_phx/construct/metal_plate1.mdl"
TOOL.ClientConVar["only_players"] = "1"

if CLIENT then
	language.Add("Tool_wire_touchplate_name", "Wired Touchplate")
	language.Add("Tool_wire_touchplate_desc", "Spawns a touchplate for use with the wire system.")
	language.Add("Tool_wire_touchplate_0", "Primary: Create touchplate. Secondary: Copy model.")
	
	language.Add("undone_WireTouchplate", "Undone Wire Touchplate")
	language.Add("Cleanup_wire_touchplates", "Wired Touchplates")
	language.Add("Cleaned_wire_touchplates", "Cleaned up all Wire Touchplates")
	language.Add("SBoxLimit_wire_touchplates", "You've reached the touchplates limit!")
else
    CreateConVar("sbox_maxwire_touchplates", 30)
end

function TOOL:LeftClick(trace)
	local ent = trace.Entity
	if ent and ent:IsPlayer() then return false end
	if SERVER and !util.IsValidPhysicsObject(ent, trace.PhysicsBone) then return false end
	if CLIENT then return true end
	
	local ply = self:GetOwner()
	
	if not self:GetSWEP():CheckLimit("wire_touchplates") then return false end

	local targetPhys = ent:GetPhysicsObjectNum(trace.PhysicsBone)
	
	local model = self:GetClientInfo("model")
	local only_players = self:GetClientNumber("only_players") ~= 0
	
	if not util.IsValidModel(model) then return false end
	if not util.IsValidProp(model) then return false end
	
	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90
	local tp_ent = MakeWireTouchplate(ply, trace.HitPos, ang, model, only_players)
	local obb_min = tp_ent:OBBMins()
	tp_ent:SetPos(trace.HitPos - trace.HitNormal * obb_min.z)
	tp_ent:GetPhysicsObject():Wake()
	
	undo.Create("WireTouchplate")
	undo.AddEntity(tp_ent)
	undo.SetPlayer(ply)
	undo.Finish()
	
	ply:AddCleanup("wire_touchplates", tp_ent)
	
	return true
end

function TOOL:UpdateGhost(ent, player)
	if not ent or not IsValid(ent) then return end

	local trace = player:GetEyeTrace()
	if not trace or not trace.Hit then return end

	if trace.Entity and trace.Entity:IsPlayer() then
		ent:SetNoDraw(true)
		return
	else
		ent:SetNoDraw(false)
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos(trace.HitPos - trace.HitNormal * min.z)
	ent:SetAngles(Ang)
end

function TOOL:Think()
	local m = self:GetClientInfo("model")
	if not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() != m then
		self:MakeGhostEntity(m, Vector(0,0,0), Angle(0,0,0))
	end

	self:UpdateGhost(self.GhostEntity, self:GetOwner())
end

function TOOL:RightClick(trace)
	local tr_ent = trace.Entity
	if not tr_ent or not tr_ent:IsValid() then return false end
	
	local model = tr_ent:GetModel()
	if game.SinglePlayer() and SERVER then
		self:GetOwner():ConCommand( "wire_touchplate_model " .. model ) -- this will run serverside if SP
		self:GetOwner():ChatPrint( "Touchplate model changed to '" .. model .. "'" )
	elseif CLIENT then -- else we can just as well run it client side instead
		RunConsoleCommand("wire_touchplate_model", model)
		self:GetOwner():ChatPrint( "Touchplate model changed to '" .. model .. "'" )
	end
	return true
end

cleanup.Register("wire_touchplates")

function TOOL.BuildCPanel(panel)
	panel:CheckBox("Only trigger for players", "wire_touchplate_only_players")
end
