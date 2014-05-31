TOOL.Category		= "Wire Extras/Tools"
TOOL.Name			= "Simulate Data"
TOOL.Tab			= "Wire"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool.wire_simulate_data.name", "Simulate Data Tool" )
    language.Add( "Tool.wire_simulate_data.desc", "Used to debug circuits by simulating data." )
    language.Add( "Tool.wire_simulate_data.0", "Primary: Attach to selected input.\nSecondary: Next input." )
end

TOOL.ClientConVar[ "type" ] = "NORMAL"
TOOL.ClientConVar[ "auto" ] = "1"
TOOL.ClientConVar[ "number" ] = "0"
TOOL.ClientConVar[ "string" ] = ""
TOOL.ClientConVar[ "vec1" ] = "0"
TOOL.ClientConVar[ "vec2" ] = "0"
TOOL.ClientConVar[ "vec3" ] = "0"
TOOL.ClientConVar[ "entity" ] = "0"
TOOL.ClientConVar[ "table" ] = ""
TOOL.ClientConVar[ "texp2" ] = "1"
TOOL.ClientConVar[ "array" ] = ""

TOOL.CurrentComponent = nil
TOOL.CurrentInput = nil
TOOL.Inputs = nil
TOOL.CurrentOutput = nil
TOOL.Outputs = nil

local function PrintError( player, arg1, arg2, arg3, arg4 )
	player:SendLua("GAMEMODE:AddNotify('Item "..arg1.." : "..arg2..arg3..arg4.."', NOTIFY_GENERIC ,5); surface.PlaySound('ambient/water/drip3.wav');")
end

function TOOL:LeftClick( trace )
	if !trace.Entity:IsValid() || trace.Entity:IsPlayer() || trace.Entity:IsWorld() then return false end
	if (self.CurrentInput && trace.Entity.Inputs[self.CurrentInput].Type) then
		local player = self:GetOwner()
		local type	= self:GetClientInfo("type")
		local data = nil
		if self:GetClientNumber("auto")==1 then type=trace.Entity.Inputs[self.CurrentInput].Type end
		if type!=trace.Entity.Inputs[self.CurrentInput].Type then return false end
		if type=="NORMAL" then data = self:GetClientNumber("number")
		elseif type=="STRING" then  data = self:GetClientInfo("string")
		elseif type=="VECTOR" || type=="ANGLE" then data = Vector(self:GetClientNumber("vec1"), self:GetClientNumber("vec2"), self:GetClientNumber("vec3"))
		elseif type=="ENTITY" then data = ents.GetByIndex(self:GetClientNumber("entity")) if !data:IsValid() then return false end
		elseif type=="TABLE" || type=="ARRAY" then
			if type=="TABLE" then data = self:GetClientInfo("table") else
			data = self:GetClientInfo("array") end
			local texp2 = self:GetClientNumber("texp2")
			local datatable = string.Explode( "|",data)
			local explode = {}
			local vtype = ""
			data = {}
			for a, b in pairs(datatable) do
				datatable[a] = string.gsub(datatable[a]," ", "")
				explode  = string.Explode("=",datatable[a])
					if table.getn(explode)!=2 then PrintError(player,a,"Wrong number of arguments","","") return false end
					for k, v in pairs(explode) do
						if string.Left(v,1)=="(" && string.Right(v,1)==")" then
							if k==1 && type=="ARRAY" then PrintError(player,a,"Array only takes integer indexes, not vector","","") return false end
							vtype = string.sub(v, 2, string.len(v)-1)
							vtype = string.Explode(",",vtype)
							if table.getn(vtype)!=3 then PrintError(player,a,"Vector requires 3 components","","") return false end
								for i=1, 3 do
									if _G.type(tonumber(vtype[i]))!="number" then PrintError(player,a,"Vector only takes numbers as arguments","","") return false end
								end
							explode[k] = Vector(vtype[1],vtype[2],vtype[3])
							vtype="v"
						elseif _G.type(tonumber(v))=="number" then vtype="n" explode[k]=tonumber(v) if k==1 && type=="ARRAY" && explode[k]>E2_MAX_ARRAY_SIZE then PrintError(player,a,"Array max limit of ",E2_MAX_ARRAY_SIZE," exceeded","","") return false end
						else if k==1 && type=="ARRAY" then PrintError(player,a,"Array only takes integer indexes, not string","","") return false end
							vtype="s" explode[k]=string.gsub(v,"\'","")
						end
					end
					if texp2==1 && type!="ARRAY" then
						if _G.type(explode[1])=="Vector" then explode[1] = vtype..explode[1][1]
						else explode[1] = vtype..explode[1]
						end
					end
				data[explode[1]] = explode[2]
			end
		end
		if (trace.Entity.Inputs) then
			Wire_Link_Clear(self.CurrentComponent, self.CurrentInput)
			trace.Entity:TriggerInput( self.CurrentInput, data)
			trace.Entity.Inputs[self.CurrentInput].Value = data
			return true
		end
	end
	return false
end


function TOOL:RightClick( trace )
	local stage = self:GetStage()

	if (stage < 2) then
		if (not trace.Entity:IsValid()) or (trace.Entity:IsPlayer()) then return end
	end
	
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
			
			local txt = ""
			if (self.CurrentComponent) and (self.CurrentComponent:IsValid()) and (self.CurrentInput)
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
			self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)
			
			
			if (self.CurrentComponent) and (self.CurrentComponent:IsValid()) then
			    self.CurrentComponent:SetNetworkedBeamString("BlinkWire", self.CurrentInput)
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
		    
            self.CurrentOutput = self.Outputs[iNextOutput] or "" --if that's nil then somethis is wrong with the ent
			
			local txt = "Output: "..self.CurrentOutput
			if (self.OutputsDesc) and (self.OutputsDesc[self.CurrentOutput]) then
				txt = txt.." ("..self.OutputsDesc[self.CurrentOutput]..")"
			end
			if (self.OutputsType) and (self.OutputsType[self.CurrentOutput])
			and (self.OutputsType[self.CurrentOutput] != "NORMAL") then
				txt = txt.." ["..self.OutputsType[self.CurrentOutput].."]"
			end
			self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)
		end
	end
end


function TOOL:Reload(trace)
	return false
end

function TOOL:Holster()
	self:SelectComponent(nil)
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
	panel:AddControl("Header", { Text = "#Tool.wire_simulate_data.name", Description = "#Tool.wire_simulate_data.desc" })
	panel:AddControl("ComboBox", {
		Label = "Data Type",
		MenuButton = "0",
		Folder = "wire_simulate_data",
		Options = {
			Number = {wire_simulate_data_type = "NORMAL"},
			String = {wire_simulate_data_type = "STRING"},
			Vector = {wire_simulate_data_type = "VECTOR"},
			Entity = {wire_simulate_data_type = "ENTITY"},
			Angle = {wire_simulate_data_type = "ANGLE"},
			Table = {wire_simulate_data_type = "TABLE"},
			Array = {wire_simulate_data_type = "ARRAY"},
		},

		CVars = {
			[0] = "wire_simulate_data_type",
		}
	})
	panel:AddControl("CheckBox", {
		Label = "Automatically Choose Type",
		Command = "wire_simulate_data_auto"
	})
	panel:AddControl("Slider", {
		Label = "Number Value:",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_simulate_data_number",
	})
	panel:AddControl( "TextBox", { 
		Label = "String Value:", 
		Description = "Output String", 
		MaxLength = "64",
		Text = "yeps",
		WaitForEnter = "true",
		Command = "wire_simulate_data_string", 
	} )
	panel:AddControl("Label", {
		Text = "Vector and Angle value:",
		Description = "Output Vector"
	} )
	panel:AddControl("Color", {
		Label = "Vector value:",
		Red = "wire_simulate_data_vec1",
		Green = "wire_simulate_data_vec2",
		Blue = "wire_simulate_data_vec3",
		ShowAlpha = 0,
		ShowHSV = 1,
		ShowRGB = 1,
		Multiplier = "1",
	})
	panel:AddControl("Slider", {
		Label = "EntityID value:",
		Type = "Integer",
		Min = "0",
		Max = "100",
		Command = "wire_simulate_data_entity",
	})
	panel:AddControl( "TextBox", { 
			Label = "Table:", 
			Description = "Output Table", 
			MaxLength = "64",
			Text = "",
			WaitForEnter = false,
			Command = "wire_simulate_data_table", 
	} )
	panel:AddControl("CheckBox", {
		Label = "Expression2 Compatible Table",
		Command = "wire_simulate_data_texp2"
	})
	panel:AddControl( "TextBox", { 
			Label = "Arrays:", 
			Description = "Output Array", 
			MaxLength = "64",
			Text = "",
			WaitForEnter = false,
			Command = "wire_simulate_data_array", 
	} )
	panel:AddControl("Label", {
		Text = "Arrays currently fail to transfer",
		Description = "Disclaimer"
	} )
end


function TOOL:SelectComponent(ent)
	if (CLIENT) then return end

	if (self.CurrentComponent == ent) then return end
	
    if (self.CurrentComponent) and (self.CurrentComponent:IsValid()) then
 	    self.CurrentComponent:SetNetworkedBeamString("BlinkWire", "")
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
	
	first = self.Inputs[1] or first

	self.CurrentInput = best or first
	if (self.CurrentInput) and (self.CurrentInput ~= "") then self.LastValidInput = self.CurrentInput end
	
	local txt = ""
	if (self.CurrentComponent) and (self.CurrentComponent:IsValid()) and (self.CurrentInput)
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
	self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)
	
	if (self.CurrentComponent) and (self.CurrentComponent:IsValid()) then
	    self.CurrentComponent:SetNetworkedBeamString("BlinkWire", self.CurrentInput)
	end
end


