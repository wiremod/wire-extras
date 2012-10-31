TOOL.Category = "Wire - RFID"
TOOL.Name = "User Reader"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
	language.Add("Tool.wire_rfid_reader_act.name", "RFID User Reader Tool (Wire)")
	language.Add("Tool.wire_rfid_reader_act.desc", "Spawn/link a Wire RFID User Reader.")
	language.Add("Tool.wire_rfid_reader_act.0", "Primary: Create User reader. Secondary: Link reader.")
	language.Add("Tool.wire_rfid_reader_act.1", "Now select the entity to link to.")
	language.Add("WireUserReaderTool_pod", "User Reader:")
    language.Add("WireUserReaderTool_NoColorChg", "Don't change colour on state changed" )
	language.Add("sboxlimit_wire_rfid_reader_acts", "You've hit your User Reader limit!")
	language.Add("Undone_Wire User Reader", "Undone Wire User Reader")
end

if SERVER then
	CreateConVar('sbox_maxwire_rfid_reader_acts', 20)
end

TOOL.ClientConVar[ "NoColorChg" ] = 0

TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"

cleanup.Register("wire_rfid_reader_acts")

function TOOL:LeftClick(trace)
	if not trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()

	local NoColorChg = (self:GetClientNumber("NoColorChg")!=0)
	
	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_rfid_reader_act" and trace.Entity:GetTable().pl == ply then
		trace.Entity:Setup( nil,NoColorChg )
		return true
	end

	if not self:GetSWEP():CheckLimit("wire_rfid_reader_acts") then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_rfid_reader_act = MakeWireUserReader(ply, trace.HitPos, Ang, nil, NoColorChg)

	wire_rfid_reader_act:SetPos(trace.HitPos - trace.HitNormal * wire_rfid_reader_act:OBBMins().z)
	
	local const = WireLib.Weld(wire_rfid_reader_act, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire User Reader")
		undo.AddEntity(wire_rfid_reader_act)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup("wire_rfid_reader_acts", wire_rfid_reader_act)

	return true
end

function TOOL:RightClick(trace)
	if (self:GetStage() == 0) and (trace.Entity:GetClass() == "gmod_wire_rfid_reader_act") then
		self.UserReader = trace.Entity
		self:SetStage(1)
		return true
	elseif self:GetStage() == 1 and trace.Entity.Use then
		self.UserReader:Setup(trace.Entity)
		self:SetStage(0)
		self.UserReader = nil
		return true
	else
		return false
	end
end

function TOOL:Reload(trace)
	self:SetStage(0)
	self.UserReader = nil
end

if SERVER then

	function MakeWireUserReader(pl, Pos, Ang, target, NoColorChg)
		if not pl:CheckLimit("wire_rfid_reader_acts") then return false end
		
		local wire_rfid_reader_act
		wire_rfid_reader_act = ents.Create("gmod_wire_rfid_reader_act")
		
		if not wire_rfid_reader_act:IsValid() then return false end

		wire_rfid_reader_act:SetAngles(Ang)
		wire_rfid_reader_act:SetPos(Pos)
		wire_rfid_reader_act:Spawn()
		
		wire_rfid_reader_act:Setup(target,NoColorChg)
		
		wire_rfid_reader_act:SetPlayer(pl)

		local ttable = {
			pl = pl,
		}
		
		table.Merge(wire_rfid_reader_act:GetTable(), ttable)
		
		pl:AddCount("wire_rfid_reader_acts", wire_rfid_reader_act)
		
		return wire_rfid_reader_act
	end
	
	duplicator.RegisterEntityClass("gmod_wire_rfid_reader_act", MakeWirePod, "Pos", "Ang", "target","NoColorChg","Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireUserReader(ent, player)
	if  not ent or not ent:IsValid() then return end

	local tr = util.GetPlayerTrace(player, player:GetAimVector())
	local trace = util.TraceLine(tr)

	if not trace.Hit or trace.Entity:IsPlayer() or trace.Entity:GetClass() == "gmod_wire_rfid_reader_act" then
		ent:SetNoDraw(true)
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	ent:SetPos(trace.HitPos - trace.HitNormal * ent:OBBMins().z)
	ent:SetAngles(Ang)

	ent:SetNoDraw(false)
end

function TOOL:Think()
	if not self.GhostEntity or not self.GhostEntity:IsValid() or self.GhostEntity:GetModel() ~= self.Model then
		self:MakeGhostEntity(self.Model, Vector(0,0,0), Angle(0,0,0))
	end

	self:UpdateGhostWireUserReader(self.GhostEntity, self:GetOwner())
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_rfid_reader_act.name", Description = "#Tool.wire_rfid_reader_act.desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_rfid_reader_act",

		Options = {
			Default = {
				wire_rfid_reader_act_rfid_reader_act = "0",
			}
		},
		CVars = {
		}
	})
		
	panel:AddControl("CheckBox", {
		Label = "#WireUserReaderTool_NoColorChg",
		Command = "wire_rfid_reader_act_NoColorChg"
	})
end
