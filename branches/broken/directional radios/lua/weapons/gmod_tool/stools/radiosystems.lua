TOOL.Category = "Wire - Data"
TOOL.Name = "#Radio Systems Tool"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.ClientConVar[ "model" ] = "models/radio/ra_small_omni.mdl"
TOOL.ClientConVar[ "tx" ] = "1"
TOOL.ClientConVar[ "freeze" ] = "0"
TOOL.ClientConVar[ "weld" ] = "1"

if CLIENT then
    language.Add("Tool_radiosystems_name", "Radio Systems")
    language.Add("Tool_radiosystems_desc", "Create Radio devices attached to any surface.")
    language.Add("Tool_radiosystems_0", "Left-Click: Spawn a Device.")
    language.Add("Undone_radiosystems", "Radio Systems Device Undone")
    language.Add("Cleanup_radiosystems", "Radio Systems Device")
    language.Add("Cleaned_radiosystems", "Cleaned up all Radio Systems Devices")
    language.Add("SBoxLimit_radiosystems", "Maximum number of Radio Systems Devices Reached")
end

if SERVER then
	CreateConVar("sbox_maxradiosystems", 10)

	function MakeRadioSystems(ply, Ang, Pos, model, tx, weld, nocollide, frozen)
			print("Calling MakeRadioSystems1\n")
			if not ply:CheckLimit("radiosystems") then return nil end
			local tmpitem = model:gsub("models/radio/", "")
			local itemclass = tmpitem:gsub(".mdl", "")

			local ent = nil
			if itemclass == "ra_cell_tower1" or itemclass == "ra_cell_tower2" then
					print("Calling MakeRadioSystems2\n")
					ent = ents.Create("prop_physics")
					ent:SetModel("models/radio/" .. itemclass .. ".mdl")
			else
					print("Calling MakeRadioSystems3\n")
					ent = ents.Create(itemclass)
					ent:Setup(tx)
			end

			table.Merge(ent:GetTable(), {
				ply = ply,
				Ang = Ang,
				Pos = Pos,
				model = model,
				tx = tx,
				weld = weld,
				nocollide = nocollide,
				frozen = frozen
			})

			print("Calling MakeRadioSystems4\n")

			ent:SetPos(Pos)
			ent:SetAngles(Ang)
			ent:Spawn()
			ent:Activate()

			print("Calling MakeRadioSystems5\n")

			if frozen then
				print("Calling MakeRadioSystems6\n")
				local phys = ent:GetPhysicsObject()
				if phys:IsValid() then
						print("Calling MakeRadioSystems7\n")
						phys:EnableMotion(false)
						ply:AddFrozenPhysicsObject(ent, phys)
				end
			end

			ply:AddCount("radiosystems", ent)

			return ent
		end

	duplicator.RegisterEntityClass("ra_domestic_dish", MakeRadioSystems, "Ang", "Pos", "model", "tx", "weld", "nocollide", "frozen")
	duplicator.RegisterEntityClass("ra_large_drum", MakeRadioSystems, "Ang", "Pos", "model", "tx", "weld", "nocollide", "frozen")
	duplicator.RegisterEntityClass("ra_large_omni", MakeRadioSystems, "Ang", "Pos", "model", "tx", "weld", "nocollide", "frozen")
	duplicator.RegisterEntityClass("ra_log", MakeRadioSystems, "Ang", "Pos", "model", "tx", "weld", "nocollide", "frozen")
	duplicator.RegisterEntityClass("ra_orbital_dish", MakeRadioSystems, "Ang", "Pos", "model", "tx", "weld", "nocollide", "frozen")
	duplicator.RegisterEntityClass("ra_panel", MakeRadioSystems, "Pos", "model", "tx", "weld", "nocollide", "frozen")
	duplicator.RegisterEntityClass("ra_sector", MakeRadioSystems, "Ang", "Pos", "model", "tx", "weld", "nocollide", "frozen")
	duplicator.RegisterEntityClass("ra_small_drum", MakeRadioSystems, "Ang", "Pos", "model", "tx", "weld", "nocollide", "frozen")
	duplicator.RegisterEntityClass("ra_small_omni", MakeRadioSystems, "Ang", "Pos", "model", "tx", "weld", "nocollide", "frozen")
	duplicator.RegisterEntityClass("ra_uplink_dish", MakeRadioSystems, "Ang", "Pos", "model", "tx", "weld", "nocollide", "frozen")
	duplicator.RegisterEntityClass("ra_cell_tower1", MakeRadioSystems, "Ang", "Pos", "model", "tx", "weld", "nocollide", "frozen")
	duplicator.RegisterEntityClass("ra_cell_tower2", MakeRadioSystems, "Ang", "Pos", "model", "tx", "weld", "nocollide", "frozen")
end

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
	if CLIENT then return true end
	if trace.Entity and ValidEntity(trace.Entity) then
		if trace.Entity:IsPlayer() then return false end
	else
		if not self:GetSWEP():CheckLimit("radiosystems") then return false end
	end

	local ply = self:GetOwner()
	local model = self:GetClientInfo("model")
	local tx = (self:GetClientNumber("tx") ~= 0)
	local freeze = (self:GetClientNumber("freeze") ~= 0)
	local weld = (self:GetClientNumber("weld") ~= 0)

	if trace.Entity:IsValid() && string.find(trace.Entity:GetClass(), "^ra_") && trace.Entity.pl == ply then return true end

	if not util.IsValidModel(model) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local radio_item = MakeRadioSystems(ply, Ang, trace.HitPos, model, tx, weld, false, freeze)

	local min = radio_item:OBBMins()
	radio_item:SetPos(trace.HitPos - trace.HitNormal * min.z)

	if weld then local const = WireLib.Weld(radio_item, trace.Entity, trace.PhysicsBone, nil, true, true) end

	undo.Create("RadioSystems")
		undo.AddEntity(radio_item)
		if weld then undo.AddEntity(const) end
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup("radiosystems", radio_item)
	return true
end

function TOOL:UpdateGhostRadioSystems(ent, player)
	if not ent or not ValidEntity(ent) then return end

	local tr = utilx.GetPlayerTrace(player, player:GetCursorAimVector())
	local trace = util.TraceLine(tr)
	if not trace and not trace.Hit then return end

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
	if not self.GhostEntity or not ValidEntity(self.GhostEntity) or self.GhostEntity:GetModel() != m then
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
                Label = "Freeze on spawn?",
                Description = "Freeze this prop on spawn?",
                Command = "radiosystems_freeze"
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
