TOOL.Category = "Wire - Data"
TOOL.Name = "Radio Systems Tool"
TOOL.Command = nil
TOOL.ConfigName = ""

if (CLIENT) then
    language.Add("Tool_radiosystems_name", "Radio Systems")
    language.Add("Tool_radiosystems_desc", "Create Radio devices attached to any surface.")
    language.Add("Tool_radiosystems_0", "Left-Click: Spawn a Device.")
    language.Add("Undone_radiosystems", "Radio Systems Device Undone")
    language.Add("Cleanup_radiosystems", "Radio Systems Device")
    language.Add("Cleaned_radiosystems", "Cleaned up all Radio Systems Devices")
    language.Add("SBoxLimit_radiosystems", "Maximum number of Radio Systems Devices Reached")
end

if(SERVER) then
	CreateConVar("sbox_maxradiosystems", 10)
end

TOOL.ClientConVar[ "model" ] = "models/radio/ra_small_omni.mdl"
TOOL.ClientConVar[ "tx" ] = "1"
TOOL.ClientConVar[ "weld" ] = "1"

local radiosystems_models = {
	["models/radio/ra_domestic_dish.mdl"] = {},
	["models/radio/ra_large_drum.mdl"] = {},
	["models/radio/ra_large_omni.mdl"] = {},
	["models/radio/ra_log.mdl"] = {},
	["models/radio/ra_orbital_dish.mdl"] = {},
	["models/radio/ra_panel.mdl"] = {},
	["models/radio/ra_sector.mdl"] = {},
	["models/radio/ra_small_drum.mdl"] = {},
	["models/radio/ra_small_omni.mdl"] = {},
	["models/radio/ra_uplink_dish.mdl"] = {},
	["models/radio/ra_cell_tower1.mdl"] = {},
	["models/radio/ra_cell_tower2.mdl"] = {}
}

cleanup.Register("radiosystems")

function TOOL:LeftClick(trace)
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()
	local model = self:GetClientInfo("model")
	local tx = (self:GetClientNumber("tx") ~= 0)
	local weld = (self:GetClientNumber("weld") ~= 0)

	if (!trace.Entity:IsValid()) then nocollide = false end

	if (trace.Entity:IsValid() && string.find(trace.Entity:GetClass(), "^ra_") && trace.Entity.pl == ply) then return true end

	if (!self:GetSWEP():CheckLimit("radiosystems")) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end		-- Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local radio_item = Makeradiosystems(ply, Ang, trace.HitPos, model, tx)

	local min = radio_item:OBBMins()
	radio_item:SetPos(trace.HitPos - trace.HitNormal * min.z)

	if weld then
		local const = WireLib.Weld(radio_item, trace.Entity, trace.PhysicsBone, false, false, true)
	end

	undo.Create("Radio Systems")
		undo.AddEntity(radio_item)
		if weld then undo.AddEntity(const) end
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup("radiosystems", radio_item)
	return true
end

if (SERVER) then
	function Makeradiosystems(ply, ang, pos, model, tx, frozen)
		if (!ply:CheckLimit("radiosystems")) then return nil end

		local tmpitem = model:gsub("models/radio/", "")
		local itemclass = tmpitem:gsub(".mdl", "")

		local e = nil
		if itemclass == "ra_cell_tower1" || itemclass == "ra_cell_tower2"  then
			e = "prop_physics"
		else
			e = itemclass
		end

		local ent = ents.Create(e)
		if e == "prop_physics" then
			ent:SetModel("models/radio/" .. itemclass .. ".mdl")
		else
			ent:WireSetup(tx)
		end
		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:Spawn()
		ent:Activate()
		ent:SetNetworkedString("Owner", ply:Nick())
		ent.Class = itemclass
		if (frozen) then
			local phys = ent:GetPhysicsObject()
			if (phys:IsValid()) then
				phys:EnableMotion(false)
				ply:AddFrozenPhysicsObject(ent, phys)
			end
		end
		
		ply:AddCount("radiosystems", ent)

		duplicator.RegisterEntityClass(e, Makeradiosystems, "Ang", "pos", "model", "tx", "frozen")

		return ent
	end
end

function TOOL:UpdateGhostRadioSystems(ent, player)
	if (!ent) then return end
	if (!ent:IsValid()) then return end

	local tr = utilx.GetPlayerTrace(player, player:GetCursorAimVector())
	local trace = util.TraceLine(tr)
	if (!trace.Hit) then return end

	local cls = trace.Entity:GetClass()
		
	if (trace.Entity && string.find(trace.Entity:GetClass(), "^ra_") || trace.Entity:IsPlayer()) then
		ent:SetNoDraw(true)
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos(trace.HitPos - trace.HitNormal * min.z)
	ent:SetAngles(Ang)

	ent:SetNoDraw(false)
end

function TOOL:Think()
	local m = self:GetClientInfo("model")
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != m) then
		self:MakeGhostEntity(m, Vector(0,0,0), Angle(0,0,0))
	end

	self:UpdateGhostRadioSystems(self.GhostEntity, self:GetOwner())
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", {
		Text = "#Tool_radiosystems_name",
		Description = "#Tool_radiosystems_desc"
	})

	panel:AddControl("CheckBox", {
		Label = "Weld on spawn?",
		Description = "Weld this prop on spawn?",
		Command = "radiosystems_weld"
	})

	panel:AddControl("CheckBox", {
		Label = "Transmitter?",
		Description = "Should this antenna be a transmitter?",
		Command = "radiosystems_tx"
	})

	panel:AddControl("PropSelect", {
		Label = "Antennae",
		ConVar = "radiosystems_model",
		Category = "Radio Systems",
		Models = radiosystems_models
	})
end