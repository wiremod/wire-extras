TOOL.Category = "Wire Extras/Other"
TOOL.Name = "#Directional Radio Tool"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.ClientConVar[ "model" ] = "models/radio/ra_small_omni.mdl"
TOOL.ClientConVar[ "tx" ] = 1
TOOL.ClientConVar[ "freeze" ] = 0

if CLIENT then
    language.Add("tool.wdrk.name", "Wire Directional Radio Kit")
    language.Add("tool.wdrk.desc", "Spawn Directional Radio Antennae")
    language.Add("tool.wdrk.0", "Left-click: Spawn a Wire Directional Radio Antenna")
    language.Add("Undone_wdrk", "Undone Wire Directional Radio Antenna")
    language.Add("Cleanup_wdrk", "Wire Directional Radio Antennae")
    language.Add("Cleaned_wdrk", "Removed all Wire Directional Radio Antennae")
    language.Add("sboxlimit_wdrk", "Wire Directional Radio Antennae limit already reached!")
end

if SERVER then
	CreateConVar("sbox_maxwdrk", 10)

	function MakeRadioPart(ply, Ang, Pos, model, trace, tx, freeze)

                if not ply:CheckLimit("wdrk") then return false end

                local tmpitem = model:gsub("models/radio/", "")
                local itemclass = tmpitem:gsub(".mdl", "")

                local ent = ents.Create(itemclass)
                ent:Setup(tx)
                ent:SetPos(Pos)
                ent:SetAngles(Ang)
                ent:SetNWString("Owner", ply:Nick())
                ent:Spawn()
                ent:Activate()

                if freeze then
                        local phys = ent:GetPhysicsObject()
                        if phys:IsValid() then
                                phys:EnableMotion(false)
                                ply:AddFrozenPhysicsObject(ent, phys)
                        end
                end

                ply:AddCount("wdrk", ent)

                duplicator.RegisterEntityClass(ent, MakeRadioPart, "Ang", "Pos", "model", "trace", "tx", "freeze")

                return ent
        end
end

cleanup.Register("wdrk")

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if trace.Entity && trace.Entity:IsPlayer() then return false end

	local ply = self:GetOwner()
	local model = self:GetClientInfo("model")
	local tx = self:GetClientNumber("tx") ~= 0
	local freeze = self:GetClientNumber("freeze") ~= 0

	if trace.Entity:IsValid() && string.find(trace.Entity:GetClass(), "^ra_") && trace.Entity.pl == ply then return true end

	if not self:GetSWEP():CheckLimit("wdrk") then return false end

	if not util.IsValidModel(model) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local radio_item = MakeRadioPart(ply, Ang, trace.HitPos, model, trace, tx, freeze)

	local min = radio_item:OBBMins()
	radio_item:SetPos(trace.HitPos - trace.HitNormal * min.z)

	undo.Create("wdrk")
		undo.AddEntity(radio_item)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup("wdrk", radio_item)
	return true
end

function TOOL:UpdateGhostRadioParts(ent, player)
	if not ent then return end
	if not IsValid(ent) then return end

	local tr = util.GetPlayerTrace(player, player:GetAimVector())
	local trace = util.TraceLine(tr)
	if not trace.Hit then return end

	local cls = trace.Entity:GetClass()
		
	if trace.Entity and string.find(trace.Entity:GetClass(), "^ra_") or trace.Entity:IsPlayer() then
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
	if (not self.GhostEntity || not self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != m) then
		self:MakeGhostEntity(m, Vector(0,0,0), Angle(0,0,0))
	end

	self:UpdateGhostRadioParts(self.GhostEntity, self:GetOwner())
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", {
		Text = "#tool.wdrk.name",
		Description = "#tool.wdrk.desc"
	})

	panel:AddControl("CheckBox", {
                Label = "Freeze on spawn?",
                Description = "Freeze this device on spawn?",
                Command = "wdrk_freeze"
        })

	panel:AddControl("CheckBox", {
		Label = "Transmitter?",
		Description = "Antenna has built-in transmitter?",
		Command = "wdrk_tx"
	})

	panel:AddControl("PropSelect", {
		Label = "Antennae",
		ConVar = "wdrk_model",
		Category = "Wire Directional Radio Kit",
		Models = {
			["models/radio/ra_domestic_dish.mdl"] = {},
			["models/radio/ra_large_drum.mdl"] = {},
			["models/radio/ra_large_omni.mdl"] = {},
			["models/radio/ra_log.mdl"] = {},
			["models/radio/ra_orbital_dish.mdl"] = {},
			["models/radio/ra_panel.mdl"] = {},
			["models/radio/ra_sector.mdl"] = {},
			["models/radio/ra_small_drum.mdl"] = {},
			["models/radio/ra_small_omni.mdl"] = {},
			["models/radio/ra_uplink_dish.mdl"] = {}
		}
	})
end
