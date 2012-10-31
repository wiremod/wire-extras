TOOL.Category = "Wire - RFID"
TOOL.Name = "Target Filter"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
	language.Add("Tool_wire_rfid_filter_name", "RFID Target Filter Tool (Wire)")
	language.Add("Tool_wire_rfid_filter_desc", "Spawn/link a Wire RFID filter for target finders.")
	language.Add("Tool_wire_rfid_filter_0", "Primary: Create filter. Secondary: Link to target finder.")
	language.Add("Tool_wire_rfid_filter_1", "Now select the target finder to link to.")
	language.Add("WireTargetFilterTool_pod", "Target Filter:")
	
	language.Add("ToolWireTargetFilter_FilterType", "Filter:")
	language.Add("ToolWireTargetFilter_CondA", "Condition A:")
	language.Add("ToolWireTargetFilter_CondB", "Condition B:")
	language.Add("ToolWireTargetFilter_CondC", "Condition C:")
	language.Add("ToolWireTargetFilter_CondD", "Condition D:")
	language.Add("ToolWireTargetFilter_FilterA", "Value A:")
	language.Add("ToolWireTargetFilter_FilterB", "Value B:")
	language.Add("ToolWireTargetFilter_FilterC", "Value C:")
	language.Add("ToolWireTargetFilter_FilterD", "Value D:")
	
	language.Add("sboxlimit_wire_rfid_filters", "You've hit your Target Filter limit!")
	language.Add("Undone_Wire Target Filter", "Undone Wire Target Filter")
end

if SERVER then
	CreateConVar('sbox_maxwire_rfid_filters', 20)
end

TOOL.ClientConVar[ "a" ] = "0"
TOOL.ClientConVar[ "b" ] = "0"
TOOL.ClientConVar[ "c" ] = "0"
TOOL.ClientConVar[ "d" ] = "0"
TOOL.ClientConVar[ "ca" ] = "0"
TOOL.ClientConVar[ "cb" ] = "0"
TOOL.ClientConVar[ "cc" ] = "0"
TOOL.ClientConVar[ "cd" ] = "0"
TOOL.ClientConVar[ "filtertype" ] = "0"

TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"

cleanup.Register("wire_rfid_filters")

function TOOL:LeftClick(trace)
	if not trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()

	local a = self:GetClientNumber("a");
	local b = self:GetClientNumber("b");
	local c = self:GetClientNumber("c");
	local d = self:GetClientNumber("d");
	local ca = self:GetClientNumber("ca");
	local cb = self:GetClientNumber("cb");
	local cc = self:GetClientNumber("cc");
	local cd = self:GetClientNumber("cd");
	local typ = self:GetClientNumber("filtertype");
	
	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_rfid_filter" and trace.Entity:GetTable().pl == ply then
		trace.Entity:Setup( a,b,c,d,ca,cb,cc,cd,typ )
		return true
	end

	if not self:GetSWEP():CheckLimit("wire_rfid_filters") then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_rfid_filter = MakeWireTargetFilter(ply, trace.HitPos, Ang, a, b, c, d, ca, cb, cc, cd, filtertype)

	wire_rfid_filter:SetPos(trace.HitPos - trace.HitNormal * wire_rfid_filter:OBBMins().z)
	
	local const = WireLib.Weld(wire_rfid_filter, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Target Filter")
		undo.AddEntity(wire_rfid_filter)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup("wire_rfid_filters", wire_rfid_filter)

	return true
end

function TOOL:RightClick(trace)
	if (self:GetStage() == 0) and (trace.Entity:GetClass() == "gmod_wire_rfid_filter") then
		self.TargetFilter = trace.Entity
		self:SetStage(1)
		return true
	elseif (self:GetStage()) == 1 and (trace.Entity:GetClass() == "gmod_wire_target_finder") then
		self.TargetFilter:Setup(nil,nil,nil,nil,nil,nil,nil,nil,nil,trace.Entity)
		self:SetStage(0)
		self.TargetFilter = nil
		return true
	else
		return false
	end
end

function TOOL:Reload(trace)
	self:SetStage(0)
	self.TargetFilter = nil
end

if SERVER then

	function MakeWireTargetFilter(pl, Pos, Ang, a,b,c,d,ca,cb,cc,cd,filtertype,target)
		if not pl:CheckLimit("wire_rfid_filters") then return false end
		
		local wire_rfid_filter
		wire_rfid_filter = ents.Create("gmod_wire_rfid_filter")
		
		if not wire_rfid_filter:IsValid() then return false end

		wire_rfid_filter:SetAngles(Ang)
		wire_rfid_filter:SetPos(Pos)
		wire_rfid_filter:Spawn()
		
		wire_rfid_filter:Setup(a,b,c,d,ca,cb,cc,cd,filtertype,target)
		
		wire_rfid_filter:SetPlayer(pl)

		local ttable = {
			a=a,
			b=b,
			c=c,
			d=d,
			ca=ca,
			cb=cb,
			cc=cc,
			cd=cd,
			filtertype=filtertype,
			
			pl = pl,
		}
		
		table.Merge(wire_rfid_filter:GetTable(), ttable)
		
		pl:AddCount("wire_rfid_filters", wire_rfid_filter)
		
		return wire_rfid_filter
	end
	
	duplicator.RegisterEntityClass("gmod_wire_rfid_filter", MakeWireTargetFilter, "Pos", "Ang", "a","b","c","d","ca","cb","cc","cd","filtertype","target","Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireTargetFilter(ent, player)
	if  not ent or not ent:IsValid() then return end

	local tr = util.GetPlayerTrace(player, player:GetAimVector())
	local trace = util.TraceLine(tr)

	if not trace.Hit or trace.Entity:IsPlayer() or trace.Entity:GetClass() == "gmod_wire_rfid_filter" then
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

	self:UpdateGhostWireTargetFilter(self.GhostEntity, self:GetOwner())
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_rfid_filter_name", Description = "#Tool_wire_rfid_filter_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_rfid_filter",

		Options = {
			Default = {
				wire_rfid_filter_rfid_filter = "0",
			}
		},
		CVars = {
		}
	})
	
	panel:AddControl("ComboBox", {
		Label = "#ToolWireTargetFilter_FilterType",
		MenuButton = "0",

		Options = {
			["Do not target"]				= { wire_rfid_filter_filtertype = "0" },
			["Target only"]				    = { wire_rfid_filter_filtertype = "1" },
			["Do not target (any values)"]	= { wire_rfid_filter_filtertype = "2" },
			["Target only (any values)"]    = { wire_rfid_filter_filtertype = "3" },
		}
	})
	
	panel:AddControl("ComboBox", {
		Label = "#ToolWireTargetFilter_CondA",
		MenuButton = "0",

		Options = {
			["Equal"]				        = { wire_rfid_filter_ca = "0" },
			["Not Equal"]				    = { wire_rfid_filter_ca = "1" },
			["Less Than"]	                = { wire_rfid_filter_ca = "2" },
			["Greater Than"]                = { wire_rfid_filter_ca = "3" },
			["Less or Equal"]	            = { wire_rfid_filter_ca = "4" },
			["Greater or Equal"]            = { wire_rfid_filter_ca = "5" },
			["Ignore"]                      = { wire_rfid_filter_ca = "6" },
		}
	})
	panel:AddControl("Slider", {
		Label = "#ToolWireTargetFilter_FilterA",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_rfid_filter_a"
	})
	
	panel:AddControl("ComboBox", {
		Label = "#ToolWireTargetFilter_CondB",
		MenuButton = "0",

		Options = {
			["Equal"]				        = { wire_rfid_filter_cb = "0" },
			["Not Equal"]				    = { wire_rfid_filter_cb = "1" },
			["Less Than"]	                = { wire_rfid_filter_cb = "2" },
			["Greater Than"]                = { wire_rfid_filter_cb = "3" },
			["Less or Equal"]	            = { wire_rfid_filter_cb = "4" },
			["Greater or Equal"]            = { wire_rfid_filter_cb = "5" },
			["Ignore"]                      = { wire_rfid_filter_cb = "6" },
		}
	})
	panel:AddControl("Slider", {
		Label = "#ToolWireTargetFilter_FilterB",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_rfid_filter_b"
	})
	
	panel:AddControl("ComboBox", {
		Label = "#ToolWireTargetFilter_CondC",
		MenuButton = "0",

		Options = {
			["Equal"]				        = { wire_rfid_filter_cc = "0" },
			["Not Equal"]				    = { wire_rfid_filter_cc = "1" },
			["Less Than"]	                = { wire_rfid_filter_cc = "2" },
			["Greater Than"]                = { wire_rfid_filter_cc = "3" },
			["Less or Equal"]	            = { wire_rfid_filter_cc = "4" },
			["Greater or Equal"]            = { wire_rfid_filter_cc = "5" },
			["Ignore"]                      = { wire_rfid_filter_cc = "6" },
		}
	})
	panel:AddControl("Slider", {
		Label = "#ToolWireTargetFilter_FilterC",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_rfid_filter_c"
	})
	
	panel:AddControl("ComboBox", {
		Label = "#ToolWireTargetFilter_CondD",
		MenuButton = "0",

		Options = {
			["Equal"]				        = { wire_rfid_filter_cd = "0" },
			["Not Equal"]				    = { wire_rfid_filter_cd = "1" },
			["Less Than"]	                = { wire_rfid_filter_cd = "2" },
			["Greater Than"]                = { wire_rfid_filter_cd = "3" },
			["Less or Equal"]	            = { wire_rfid_filter_cd = "4" },
			["Greater or Equal"]            = { wire_rfid_filter_cd = "5" },
			["Ignore"]                      = { wire_rfid_filter_cd = "6" },
		}
	})
	panel:AddControl("Slider", {
		Label = "#ToolWireTargetFilter_FilterD",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_rfid_filter_d"
	})
end
