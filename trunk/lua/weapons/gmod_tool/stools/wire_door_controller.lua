TOOL.Category		= "Wire Extras/Other"
TOOL.Name			= "Door Controller"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if CLIENT then
	language.Add("Tool.wire_door_controller.name", "Door Controller (Wire)")
	language.Add("Tool.wire_door_controller.desc", "Spawns a door controller for use with the wire system.")
	language.Add("Tool.wire_door_controller.0", "Primary: Create Door Controller, Secondary: Link Door Controller, Reload: Unlink Door Controller")
	language.Add("Tool.wire_door_controller.1", "Now select the door to link to.")
	language.Add("sboxlimit_wire_door_controllers", "You've hit wire door controllers limit!")
	language.Add("undone_Wire Door Controller", "Undone Wire Door Controller")
end

if SERVER then
	CreateConVar("sbox_maxwire_door_controllers", 30)
end

TOOL.ClientConVar["Model"] = "models/jaanus/wiretool/wiretool_siren.mdl"

cleanup.Register("wire_door_controllers")


local function IsDoor(ent)
	if not ent or not IsValid(ent) then return false end
	local class = ent:GetClass()
	
	if class == "func_door" or class == "func_door_rotating" or class == "prop_door_rotating" then
		return true
	end
	
	return false
end

function TOOL:LeftClick(trace)
	if not trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	if not util.IsValidPhysicsObject(trace.Entity, trace.PhysicsBone) then return false end
	
	local model = self:GetClientInfo("Model")
	if not util.IsValidModel(model) or not util.IsValidProp(model) then return end
	local ply = self:GetOwner()
	
	if not self:GetSWEP():CheckLimit("wire_door_controllers") then return false end
	
	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90
	
	local ent = MakeWireDoorController(ply, trace.HitPos, ang, model)
	
	local min = ent:OBBMins()
	ent:SetPos(trace.HitPos - trace.HitNormal * min.z)
	
	local const = WireLib.Weld(ent, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("Wire Door Controller")
		undo.AddEntity(ent)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()
	
	ply:AddCleanup("wire_door_controllers", ent)
	
	return true
end

function TOOL:RightClick(trace)
	if not trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	
	if not trace.Entity:IsValid() then return false end
	
	if self:GetStage() == 0 and trace.Entity:GetClass() == "gmod_wire_door_controller" then
		self.Controller = trace.Entity
		self:SetStage(1)
		return true
	elseif self:GetStage() == 1 then
		if not IsDoor(trace.Entity) then
			self:GetOwner():PrintMessage(HUD_PRINTTALK, "Error: Entity is not a door.")
			return false
		end
		
		self.Controller:Link(trace.Entity)
		self:SetStage(0)
		self:GetOwner():PrintMessage(HUD_PRINTTALK, "Door Controller linked")
		return true
	end
	
	return false
end

function TOOL:Reload(trace)
	if not trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	
	self:SetStage(0)
	
	local ent = trace.Entity
	if not ent or not IsValid(ent) then return false end
	if not ent:GetClass() == "gmod_wire_door_controller" then return false end
	
	ent:Unlink()
	self:GetOwner():PrintMessage(HUD_PRINTTALK, "Door Controller unlinked")
	
	return true
end

if SERVER then
	function MakeWireDoorController(ply, pos, ang, model)
		if not ply:CheckLimit("wire_door_controllers") then return false end
		
		local ent = ents.Create("gmod_wire_door_controller")
		if not IsValid(ent) then return false end
		
		ent:SetAngles(ang)
		ent:SetPos(pos)
		ent:SetModel(model)
		ent:Spawn()
		ent:SetPlayer(ply)
		ent.pl = ply
		
		ply:AddCount("wire_door_controllers", ent)
		
		return ent
	end
end

function TOOL:UpdateGhostWireDoorController(ent, ply)
	if not IsValid(ent) then return end
	
	local trace = ply:GetEyeTrace()
	
	if not trace.Hit or trace.Entity:IsPlayer() or trace.Entity:GetClass() == "gmod_wire_door_controller" then
		ent:SetNoDraw(true)
		return
	end
	
	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90
	
	local min = ent:OBBMins()
	ent:SetPos(trace.HitPos - trace.HitNormal * min.z)
	ent:SetAngles(ang)
	
	ent:SetNoDraw(false)
end

function TOOL:Think()
	if not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() != self:GetClientInfo("Model") then
		self:MakeGhostEntity(self:GetClientInfo("Model"), Vector(0,0,0), Angle(0,0,0))
	end
	
	self:UpdateGhostWireDoorController(self.GhostEntity, self:GetOwner())
end

if CLIENT then
	function TOOL.BuildCPanel(panel)
		WireDermaExts.ModelSelect(panel, "wire_door_controller_model", list.Get("Wire_Misc_Tools_Models"), 1)
	end
end