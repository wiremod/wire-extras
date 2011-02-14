//***********************************************************
//		String Gates
//***********************************************************

GateActions("String")

GateActions["string_comparei"] = {
	name = "Compare (Ignore Case)",
	inputs = { "A", "B" },
	inputtypes = { "STRING", "STRING" },
	outputs = { "Out" },
	output = function(gate, A, B)
		if string.lower(A)==string.lower(B) then return 1
		else         return 0 end
	end,
	label = function(Out, A, B)
		return A.." == "..B.." = "..Out.Out
	end
}

--[[  doesn't work well, take this out

GateActions["string_format"] = {
	name = "Format",
	inputs = { "String", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "STRING","STRING","STRING","STRING","STRING","STRING","STRING","STRING","STRING" },
	compact_inputs = 2,
	outputs = { "Str" },
	outputtypes = { "STRING" },
	output = function(gate, ...)
		local params = {}
		local i = 1
		for k,v in ipairs(arg) do
			if (v) then
				params[i] = v
				i = i+1
			end
		end
		return string.format((arg[1] or ""), unpack(params))
	end,
	label = function(Out, ...)
		local txt = "Format("..arg[1]..")"
		local i = 0
		for k,v in ipairs(arg) do
			if (v) then
				if (i>0) then
					txt = txt.."\n"..i..": "..v
					i = i+1
				end
			end
		end
		return txt.." = "..Out.Str
	end
}
]]

GateActions["string_left"] = {
	name = "Left",
	inputs = { "A", "Length" },
	inputtypes = { "STRING" },
	outputs = { "Out" },
	outputtypes = { "STRING" },
	output = function(gate, A, Length)
		return string.Left(A,Length)
	end,
	label = function(Out, A, Length)
		return "Left("..A..","..Length..") = "..Out.Out
	end
}

GateActions["string_right"] = {
	name = "Right",
	inputs = { "A", "Length" },
	inputtypes = { "STRING" },
	outputs = { "Out" },
	outputtypes = { "STRING" },
	output = function(gate, A, Length)
		return string.Right(A,Length)
	end,
	label = function(Out, A, Length)
		return "Right("..A..","..Length..") = "..Out.Out
	end
}

GateActions["string_entinfo"] = {
	name = "Entity String Decoder",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputs = { "Class", "Name", "Model", "SteamID" },
	outputtypes = { "STRING","STRING","STRING","STRING" },
	output = function(gate, Ent)
		local class,name,model,steamid="","","",""
		if(!Ent or !Ent:IsValid()) then return "","","","" end
		
		if(Ent.GetClass) then class  =Ent:GetClass() end
		if(Ent.GetName ) then name   =Ent:GetName () end
		if(Ent.GetModel) then model  =Ent:GetModel() end
		if(Ent.SteamID ) then steamid=Ent:SteamID () end
		
		return class, name, model, steamid
	end,
	label = function(Out)
		return "Class : "..Out.Class.."\nName : "..Out.Name.."\nModel : "..Out.Model.."\nSteamID : "..Out.SteamID
	end
}

GateActions["string_if"] = {
	name = "If Then Else (String)",
	inputs = { "A", "B", "C" },
	inputtypes = { "NORMAL", "STRING", "STRING" },
	outputs = { "Out" },
	outputtypes = { "STRING" },
	output = function(gate, A, B, C)
		if (A) and (A > 0) then return B end
		return C
	end,
	label = function(Out, A, B, C)
		return "if "..A.." then "..B.." else "..C.." = "..Out.Out
	end
}

GateActions["string_router"] = {
	name = "Router (String)",
	inputs = { "Path", "Data" },
	inputtypes = { "NORMAL", "STRING" },
	outputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	outputtypes = { "STRING","STRING","STRING","STRING","STRING","STRING","STRING","STRING" },
	output = function(gate, Path, Data)
		local result = { "", "", "", "", "", "", "", "" }

		local idx = math.floor(Path)
		if (idx > 0) and (idx <= 8) then
			result[idx] = Data
		end
		
		return unpack(result)
	end,
	label = function(Out, Path, Data)
		return "Router Path:"..Path.." Data:"..Data
	end
}

GateActions["string_latch"] = {
	name = "Latch (String Memory)",
	inputs = { "Data", "Clk" },
	inputtypes = { "STRING", "NORMAL" },
	outputs = { "Out" },
	outputtypes = { "STRING" },
	output = function(gate, Data, Clk)
		local clk = (Clk > 0)
		if (gate.PrevValue ~= clk) then
			gate.PrevValue = clk
			if (clk) then
				gate.LatchStore = Data
			end
		end
		return gate.LatchStore or ""
	end,
	reset = function(gate)
		gate.LatchStore = ""
		gate.PrevValue = nil
	end,
	label = function(Out, Data, Clk)
		return "Latch Data:"..Data.."  Clock:"..Clk.." = "..Out.Out
	end
}

GateActions["string_dlatch"] = {
	name = "D-Latch (String Memory)",
	inputs = { "Data", "Clk" },
	inputtypes = { "STRING", "NORMAL" },
	outputs = { "Out" },
	outputtypes = { "STRING" },
	output = function(gate, Data, Clk)
		if (Clk > 0) then
			gate.LatchStore = Data
		end
		return gate.LatchStore or ""
	end,
	reset = function(gate)
		gate.LatchStore = ""
	end,
	label = function(Out, Data, Clk)
		return "D-Latch Data:"..Data.."  Clock:"..Clk.." = "..Out.Out
	end
}

GateActions()
