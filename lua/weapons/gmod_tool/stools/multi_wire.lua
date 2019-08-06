
--[[
Most of this code was originally from the normal wire tool, I just modified it so you could select multiple inputs and wire them to one single output.
-Incompatible
]]

TOOL.Category   = "Wire Extras/Obsolete"
TOOL.Name       = "Multi Wire"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Tab        = "Wire"

if ( CLIENT ) then
	language.Add( "Tool.multi_wire.name", "Multi-Wiring Tool" )
	language.Add( "Tool.multi_wire.desc", "Used to connect wirable props." )
	language.Add( "Tool_wire_desc", "Used to connect wirable props." )
	language.Add( "Tool.multi_wire.0", "Primary: Attach to selected input.\nSecondary: Next input.\nReload: Switch to Output" )
	language.Add( "Tool.multi_wire.1", "Primary: Attach to output.\nSecondary: Attach but continue.\nReload: Cancel." )
	language.Add( "Tool.multi_wire.2", "Primary: Confirm attach to output.\nSecondary: Next output.\nReload: Cancel." )
	language.Add( "Multi_WireTool_addlength", "Add Length:" )
	language.Add( "Multi_WireTool_width", "Width:" )
	language.Add( "Multi_WireTool_rigid", "Rigid:" )
	language.Add( "Multi_WireTool_breakable", "Breakable:" )
	language.Add( "Multi_WireTool_material", "Material:" )
	language.Add( "Multi_WireTool_colour", "Material:" )
	language.Add( "undone_multi_wire", "Undone Wire" )
end

//TOOL.ClientConVar[ "addlength" ] = "4"
TOOL.ClientConVar[ "width" ] = "2"
//TOOL.ClientConVar[ "rigid" ] = "0"
//TOOL.ClientConVar[ "breakable" ] = "0"
TOOL.ClientConVar[ "material" ] = "cable/cable2"
TOOL.ClientConVar[ "color_r" ] = "255"
TOOL.ClientConVar[ "color_g" ] = "255"
TOOL.ClientConVar[ "color_b" ] = "255"

TOOL.ForceLimit = 2000
TOOL.CurrentComponent = nil
TOOL.CurrentInput = nil
TOOL.Inputs = nil
TOOL.CurrentOutput = nil
TOOL.Outputs = nil
TOOL.enttbl = {}
TOOL.inputtbl = {}

util.PrecacheSound("weapons/pistol/pistol_empty.wav")

cleanup.Register( "wireconstraints" )

function TOOL:LeftClick( trace )
	if (trace.Entity:IsValid()) and (trace.Entity:IsPlayer()) then return end

	// If there's no physics object then we can't constraint it!
	--if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end  -- You don't need this for wiring! -Grocel

	local stage = self:GetStage()

	if (stage == 0) then
		if (CLIENT) then
		    if (self:GetWeapon():GetNetworkedString("WireCurrentInput")) then
				self:SetStage(0)
				return true
			end
		elseif (self.CurrentInput) then
			local wents = trace.Entity
			local winput = self.CurrentInput
			table.insert(self.enttbl, wents)
			table.insert(self.inputtbl, winput)
			wents.OldColor = wents:GetColor()
			wents:SetColor(Color(0,255,0,150))
			return true
		end

		return
	elseif (stage == 1) then
		if (CLIENT) then
			self:SetStage(0)
			return true
		end

		if (!WireLib.HasPorts(trace.Entity) or !trace.Entity.Outputs) then
			self:SetStage(0)

			Wire_Link_Cancel(self:GetOwner():UniqueID())

			self:GetOwner():SendLua( "GAMEMODE:AddNotify('Wire source invalid!', NOTIFY_GENERIC, 7);" )
			self.inputtbl = {}
			self.enttbl = {}
			return
		end

		self.Outputs = {}
		self.OutputsDesc = {}
		self.OutputsType = {}
		for key,v in pairs(trace.Entity.Outputs) do
			if v.Num then
				self.Outputs[v.Num] = key
				if (v.Desc) then
					self.OutputsDesc[key] = v.Desc
				end
				if (v.Type) then
					self.OutputsType[key] = v.Type
				end
			else
				table.insert(self.Outputs, key)
			end
		end

		local oname = nil
		for k,_ in pairs(trace.Entity.Outputs) do
			if (oname) then
				self:SelectComponent(nil)
				self.CurrentOutput = self.Outputs[1] //oname
				self.OutputEnt = trace.Entity
				self.OutputPos = trace.Entity:WorldToLocal(trace.HitPos)
				//self:GetWeapon():SetNWString("WireCurrentInput", "Output:"..self.CurrentOutput)

				local txt = "Output: "..self.CurrentOutput
				if (self.OutputsDesc) and (self.OutputsDesc[self.CurrentOutput]) then
					txt = txt.." ("..self.OutputsDesc[self.CurrentOutput]..")"
				end
				if (self.OutputsType) and (self.OutputsType[self.CurrentOutput])
				and (self.OutputsType[self.CurrentOutput] != "NORMAL") then
					txt = txt.." ["..self.OutputsType[self.CurrentOutput].."]"
				end
				self:GetWeapon():SetNWString("WireCurrentInput", txt)

				self:SetStage(2)
		        return true
		    end

		    oname = k
		end

		local material	= self:GetClientInfo("material")
		local width		= self:GetClientNumber("width")
		local color     = Color(self:GetClientNumber("color_r"), self:GetClientNumber("color_g"), self:GetClientNumber("color_b"))

		for k,v in pairs(self.enttbl) do
			if (IsValid(v)) then
				Wire_Link_Start(self:GetOwner():UniqueID(), v, v:WorldToLocal(v:GetPos()), self.inputtbl[k], material, color, width)
				Wire_Link_End(self:GetOwner():UniqueID(), trace.Entity, trace.Entity:WorldToLocal(trace.HitPos), oname, self:GetOwner())
				v:SetColor(v.OldColor or Color(255,255,255,255))
				v.OldColor = nil
			end
		end

		self.inputtbl = {}
		self.enttbl = {}
		self:SelectComponent(nil)
		self:SetStage(0)

	else
		if (CLIENT) then
			self:SetStage(0)
			return true
		end

		local material	= self:GetClientInfo("material")
		local width		= self:GetClientNumber("width")
		local color     = Color(self:GetClientNumber("color_r"), self:GetClientNumber("color_g"), self:GetClientNumber("color_b"))

		for k,v in pairs(self.enttbl) do
			if (IsValid(v)) then
				Wire_Link_Start(self:GetOwner():UniqueID(), v, v:WorldToLocal(v:GetPos()), self.inputtbl[k], material, color, width)
				Wire_Link_End(self:GetOwner():UniqueID(), self.OutputEnt, self.OutputPos, self.CurrentOutput, self:GetOwner())
				v:SetColor(v.OldColor or Color(255,255,255,255))
				v.OldColor = nil
			end
		end
		self:GetWeapon():SetNWString("WireCurrentInput", "")
		self.CurrentOutput = nil
		self.OutputEnt = nil
		self.OutputPos = nil
		--Making sure ents and inputs are cleared.
		self.inputtbl = {}
		self.enttbl = {}
		self:SelectComponent(nil)
		self:SetStage(0)
	end

	return true
end


function TOOL:RightClick( trace )
	if (trace.Entity:IsValid()) and (trace.Entity:IsPlayer()) then return end

	local stage = self:GetStage()

	// If there's no physics object then we can't constraint it!
	--if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end  -- You don't need this for wiring! -Grocel

	if (stage == 0) then
		if (CLIENT) then return end

		if (trace.Entity:IsValid()) then
			self:SelectComponent(trace.Entity)
		else
		    self:SelectComponent(nil)
		end
		if (not self.Inputs) or (not self.CurrentInput) then return end

		local iNextInput
		for k,v in pairs(self.Inputs) do
		    if (v == self.CurrentInput) then iNextInput = k+1 end
		end
		if (iNextInput) then
		    self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")

		    if (iNextInput > table.getn(self.Inputs)) then iNextInput = 1 end

		    self.CurrentInput = self.Inputs[iNextInput]
			if (self.CurrentInput) then self.LastValidInput = self.CurrentInput end

			/*if (self.CurrentComponent) and (self.CurrentComponent:IsValid()) and (self.CurrentInput)
			  and (self.CurrentComponent.Inputs) and (self.CurrentComponent.Inputs[self.CurrentInput])
			  and (self.CurrentComponent.Inputs[self.CurrentInput].Src) then
		    	self:GetWeapon():SetNWString("WireCurrentInput", "%"..(self.CurrentInput or ""))
			else
		    	self:GetWeapon():SetNWString("WireCurrentInput", self.CurrentInput or "")
			end*/

			local txt = ""
			if (IsValid(self.CurrentComponent)) and (WireLib.HasPorts(self.CurrentComponent)) and (self.CurrentInput)
			  and (self.CurrentComponent.Inputs) and (self.CurrentComponent.Inputs[self.CurrentInput])
			  and (self.CurrentComponent.Inputs[self.CurrentInput].Src) then
				txt = "%"..(self.CurrentInput or "")
			else
				txt = self.CurrentInput or ""
			end
			if (self.InputsDesc) and (self.InputsDesc[self.CurrentInput]) then
				txt = txt.." ("..self.InputsDesc[self.CurrentInput]..")"
			end
			if (self.InputsType) and (self.InputsType[self.CurrentInput])
			and (self.InputsType[self.CurrentInput] != "NORMAL") then
				txt = txt.." ["..self.InputsType[self.CurrentInput].."]"
			end
			self:GetWeapon():SetNWString("WireCurrentInput", txt)


			if (IsValid(self.CurrentComponent)) then
			    self.CurrentComponent:SetNWString("BlinkWire", self.CurrentInput)
			end
		end
	elseif (self.Outputs) then
		if (CLIENT) then return end

		local iNextOutput
		for k,v in pairs(self.Outputs) do
		    if (v == self.CurrentOutput) then iNextOutput = k+1 end
		end

		if (iNextOutput) then
		    self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")

		    if (iNextOutput > table.getn(self.Outputs)) then iNextOutput = 1 end

            self.CurrentOutput = self.Outputs[iNextOutput]

			local txt = "Output: "..self.CurrentOutput
			if (self.OutputsDesc) and (self.OutputsDesc[self.CurrentOutput]) then
				txt = txt.." ("..self.OutputsDesc[self.CurrentOutput]..")"
			end
			if (self.OutputsType) and (self.OutputsType[self.CurrentOutput])
			and (self.OutputsType[self.CurrentOutput] != "NORMAL") then
				txt = txt.." ["..self.OutputsType[self.CurrentOutput].."]"
			end
			self:GetWeapon():SetNWString("WireCurrentInput", txt)
		end
	end
end


function TOOL:Reload(trace)

	if (self:GetStage() == 0) then
		self:SetStage(1)
	else
		self:SetStage(0)
		for k,v in pairs(self.enttbl) do
			if (IsValid(v)) then
				v:SetColor(v.OldColor or Color(255,255,255,255))
				v.OldColor = nil
			end
		end

		self:GetWeapon():SetNWString("WireCurrentInput", "")
		self.CurrentOutput = nil
		self.OutputEnt = nil
		self.OutputPos = nil
		--Making sure ents and inputs are cleared.
		self.inputtbl = {}
		self.enttbl = {}
		self:SelectComponent(nil)
		self:SetStage(0)
	end

	return true
end

function TOOL:Holster()
	for k,v in pairs(self.enttbl) do
		if (IsValid(v)) then
			v:SetColor(v.OldColor or Color(255,255,255,255))
			v.OldColor = nil
		end
	end
	self:GetWeapon():SetNWString("WireCurrentInput", "")
	self.CurrentOutput = nil
	self.OutputEnt = nil
	self.OutputPos = nil
	--Making sure ents and inputs are cleared.
	self.inputtbl = {}
	self.enttbl = {}
	self:SelectComponent(nil)
	self:SetStage(0)
end


if (CLIENT) then

	function TOOL:DrawHUD()
	    local current_input = self:GetWeapon():GetNetworkedString("WireCurrentInput") or ""
		if (current_input ~= "") then
		    if (string.sub(current_input, 1, 1) == "%") then
		    	draw.WordBox(8, ScrW()/2+10, ScrH()/2+10, string.sub(current_input, 2), "Default", Color(150,50,50,192), Color(255,255,255,255) )
		    else
		    	draw.WordBox(8, ScrW()/2+10, ScrH()/2+10, current_input, "Default", Color(50,50,75,192), Color(255,255,255,255) )
			end
		end
	end

end


function TOOL:Think()
	if (self:GetStage() == 0) then
		local player = self:GetOwner()
		local tr = util.GetPlayerTrace(player, player:GetAimVector())
		local trace = util.TraceLine(tr)

		if (trace.Hit) and (trace.Entity:IsValid()) then
			self:SelectComponent(trace.Entity)
		else
            self:SelectComponent(nil)
		end
	end
end


function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_name", Description = "#Tool_wire_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire",

		Options = {
			Default = {
				//wire_addlength = "4",
				wire_material = "cable/rope",
				wire_width = "3",
				//wire_rigid = "0",
				//wire_breakable = "1"
			}
		},

		CVars = {
			[0] = "multi_wire_width",
			[1] = "multi_wire_material",
			//[0] = "multi_wire_addlength",
			//[3] = "multi_wire_rigid",
			//[4] = "multi_wire_breakable"
		}
	})

	/*panel:AddControl("Slider", {
		Label = "#Multi_WireTool_addlength",
		Type = "Float",
		Min = "-1000",
		Max = "1000",
		Command = "multi_wire_addlength"
	})*/

	panel:AddControl("Slider", {
		Label = "#Multi_WireTool_width",
		Type = "Float",
		Min = "1",
		Max = "20",
		Command = "multi_wire_width"
	})

	/*panel:AddControl("CheckBox", {
		Label = "#Multi_WireTool_rigid",
		Command = "multi_wire_rigid"
	})

	panel:AddControl("CheckBox", {
		Label = "#Multi_WireTool_breakable",
		Command = "multi_wire_breakable"
	})*/

	panel:AddControl("MaterialGallery", {
		Label = "#Multi_WireTool_material",
		Height = "64",
		Width = "28",
		Rows = "1",
		Stretch = "1",

		Options = {
			["Wire"] = { Material = "cable/rope_icon", multi_wire_material = "cable/rope" },
			["Cable 2"] = { Material = "cable/cable_icon", multi_wire_material = "cable/cable2" },
			["XBeam"] = { Material = "cable/xbeam", multi_wire_material = "cable/xbeam" },
			["Red Laser"] = { Material = "cable/redlaser", multi_wire_material = "cable/redlaser" },
			["Blue Electric"] = { Material = "cable/blue_elec", multi_wire_material = "cable/blue_elec" },
			["Physics Beam"] = { Material = "cable/physbeam", multi_wire_material = "cable/physbeam" },
			["Hydra"] = { Material = "cable/hydra", multi_wire_material = "cable/hydra" },

		//new wire materials by Acegikmo
			["Arrowire"] = { Material = "arrowire/arrowire", multi_wire_material = "arrowire/arrowire" },
			["Arrowire2"] = { Material = "arrowire/arrowire2", multi_wire_material = "arrowire/arrowire2" },
		},

		CVars = {
			[0] = "multi_wire_material"
		}
	})

	panel:AddControl("Color", {
		Label = "#Multi_WireTool_colour",
		Red = "multi_wire_color_r",
		Green = "multi_wire_color_g",
		Blue = "multi_wire_color_b",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
end


function TOOL:SelectComponent(ent)
	if (CLIENT) then return end

	if (self.CurrentComponent == ent) then return end

    if (IsValid(self.CurrentComponent)) then
 	    self.CurrentComponent:SetNWString("BlinkWire", "")
	end

	self.CurrentComponent = ent
	self.CurrentInput = nil
	self.Inputs = {}
	self.InputsDesc = {}
	self.InputsType = {}

	local best = nil
	local first = nil
	if (ent) and (ent.Inputs) then
		for k,v in pairs(ent.Inputs) do
		    if (not first) then first = k end
		    if (k == self.LastValidInput) then best = k end
			if v.Num then
				self.Inputs[v.Num] = k
			else
				table.insert(self.Inputs, k)
			end
			if (v.Desc) then
				self.InputsDesc[k] = v.Desc
			end
			if (v.Type) then
				self.InputsType[k] = v.Type
			end
		end
	end

	//table.sort(self.Inputs)
	first = self.Inputs[1] or first

	self.CurrentInput = best or first
	if (self.CurrentInput) and (self.CurrentInput ~= "") then self.LastValidInput = self.CurrentInput end

	local txt = ""
	if (IsValid(self.CurrentComponent)) and (WireLib.HasPorts(self.CurrentComponent)) and (WireLib.HasPorts(self.CurrentComponent)) and (self.CurrentInput)
	  and (self.CurrentComponent.Inputs) and (self.CurrentComponent.Inputs[self.CurrentInput])
	  and (self.CurrentComponent.Inputs[self.CurrentInput].Src) then
    	txt = "%"..(self.CurrentInput or "")
	else
    	txt = self.CurrentInput or ""
	end
	if (self.InputsDesc) and (self.InputsDesc[self.CurrentInput]) then
		txt = txt.." ("..self.InputsDesc[self.CurrentInput]..")"
	end
	if (self.InputsType) and (self.InputsType[self.CurrentInput])
	and (self.InputsType[self.CurrentInput] != "NORMAL") then
		txt = txt.." ["..self.InputsType[self.CurrentInput].."]"
	end
	self:GetWeapon():SetNWString("WireCurrentInput", txt)

	if (IsValid(self.CurrentComponent)) then
	    self.CurrentComponent:SetNWString("BlinkWire", self.CurrentInput)
	end
end
