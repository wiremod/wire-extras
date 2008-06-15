AddCSLuaFile( "autorun/wiregates.lua" )
AddCSLuaFile( "autorun/_kilburnwiregates.lua" )

//***********************************************************
//		String Gates
//***********************************************************

local function AddStringGates()
	GateActions["string_concat"] = {
		group = "String",
		name = "Concatenate",
		inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
		inputtypes = { "STRING","STRING","STRING","STRING","STRING","STRING","STRING","STRING" },
		compact_inputs = 2,
		outputs = { "Str" },
		outputtypes = { "STRING" },
		output = function(gate, ...)
		    local result = ""
		    for k,v in ipairs(arg) do
			    if (v) then result = result..v end
			end
		    return result
		end,
		label = function(Out, ...)
		    local txt = ""
		    for k,v in ipairs(arg) do
			    if (v) then txt = txt..v..".." end
			end
		    return string.sub(txt, 1, -3).." = "..Out.Str
		end
	}

	GateActions["string_compare"] = {
		group = "String",
		name = "Compare",
		inputs = { "A", "B" },
		inputtypes = { "STRING", "STRING" },
		outputs = { "Out" },
		output = function(gate, A, B)
			if A==B then return 1
			else         return 0 end
		end,
		label = function(Out, A, B)
		    return A.." == "..B.." = "..Out.Out
		end
	}

	GateActions["string_comparei"] = {
		group = "String",
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

	GateActions["string_find"] = {
		group = "String",
		name = "Find",
		inputs = { "A", "B", "StartIndex" },
		inputtypes = { "STRING", "STRING" },
		outputs = { "Out" },
		output = function(gate, A, B, StartIndex)
			local r = string.find(A,B,StartIndex)
			if r==nil then r=0 end
			return r
		end,
		label = function(Out, A, B)
		    return "Find "..B.." in "..A.." = "..Out.Out
		end
	}

	GateActions["string_rep"] = {
		group = "String",
		name = "Repeat",
		inputs = { "A", "Num" },
		inputtypes = { "STRING" },
		outputs = { "Str" },
		outputtypes = { "STRING" },
		output = function(gate, A, Num)
			return string.rep(A,Num)
		end,
		label = function(Out, A, Num)
		    return A.." * "..Num.." = "..Out.Str
		end
	}

	GateActions["string_reverse"] = {
		group = "String",
		name = "Reverse",
		inputs = { "A" },
		inputtypes = { "STRING" },
		outputs = { "Out" },
		outputtypes = { "STRING" },
		output = function(gate, A)
			return string.reverse(A)
		end,
		label = function(Out, A)
		    return "Reverse("..A..") = "..Out.Out
		end
	}

	GateActions["string_identity"] = {
		group = "String",
		name = "Identity (String)",
		inputs = { "A" },
		inputtypes = { "STRING" },
		outputs = { "Out" },
		outputtypes = { "STRING" },
		output = function(gate, A)
			return A
		end,
		label = function(Out, A)
		    return A.." = "..Out.Out
		end
	}

	GateActions["string_len"] = {
		group = "String",
		name = "Length",
		inputs = { "A" },
		inputtypes = { "STRING" },
		outputs = { "Out" },
		output = function(gate, A)
			return string.len(A)
		end,
		label = function(Out, A)
		    return "#"..A.." = "..Out.Out
		end
	}

	GateActions["string_trim"] = {
		group = "String",
		name = "Trim",
		inputs = { "A" },
		inputtypes = { "STRING" },
		outputs = { "Out" },
		outputtypes = { "STRING" },
		output = function(gate, A)
			return string.Trim(A)
		end,
		label = function(Out, A, B)
		    return "Trim("..A..") = "..Out.Out
		end
	}
	--[[  doesn't work well, take this out

	GateActions["string_format"] = {
		group = "String",
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
		group = "String",
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
		group = "String",
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

	GateActions["string_sub"] = {
		group = "String",
		name = "Sub",
		inputs = { "A", "Start", "End" },
		inputtypes = { "STRING" },
		outputs = { "Out" },
		outputtypes = { "STRING" },
		output = function(gate, A, Start, End)
			return string.sub(A,Start,End)
		end,
		label = function(Out, A, Start, End)
		    return A.." ["..Start..","..End.."] = "..Out.Out
		end
	}

	GateActions["string_repl"] = {
		group = "String",
		name = "Replace",
		inputs = { "A", "Find", "Replace" },
		inputtypes = { "STRING","STRING","STRING" },
		outputs = { "Out" },
		outputtypes = { "STRING" },
		output = function(gate, A, Find, Replace)
			return string.gsub(A,Find,Replace)
		end,
		label = function(Out, A, Find, Replace)
		    return "Replace("..A..","..Find..","..Replace..") = "..Out.Out
		end
	}

	GateActions["string_lower"] = {
		group = "String",
		name = "Lower",
		inputs = { "A" },
		inputtypes = { "STRING" },
		outputs = { "Out" },
		outputtypes = { "STRING" },
		output = function(gate, A)
			return string.lower(A)
		end,
		label = function(Out, A, B)
		    return "Lower("..A..") = "..Out.Out
		end
	}

	GateActions["string_upper"] = {
		group = "String",
		name = "Upper",
		inputs = { "A" },
		inputtypes = { "STRING" },
		outputs = { "Out" },
		outputtypes = { "STRING" },
		output = function(gate, A)
			return string.upper(A)
		end,
		label = function(Out, A, B)
		    return "Upper("..A..") = "..Out.Out
		end
	}

	GateActions["string_char"] = {
		group = "String",
		name = "Byte > Character",
		inputs = { "A" },
		outputs = { "Out" },
		outputtypes = { "STRING" },
		output = function(gate, A)
			return string.char(A)
		end,
		label = function(Out, A, B)
		    return "Char("..A..") = "..Out.Out
		end
	}

	GateActions["string_byte"] = {
		group = "String",
		name = "Character > Byte",
		inputs = { "A", "B" },
		inputtypes = { "STRING" },
		outputs = { "Out" },
		output = function(gate, A,B)
			return string.byte(A,B)
		end,
		label = function(Out, A, B)
		    return "Byte("..A.."["..B.."]) = "..Out.Out
		end
	}

	GateActions["string_tostring"] = {
		group = "String",
		name = "Number > String",
		inputs = { "A" },
		outputs = { "Out" },
		outputtypes = { "STRING" },
		output = function(gate, A)
			return tostring(A)
		end,
		label = function(Out, A)
		    return A.." = "..Out.Out
		end
	}

	GateActions["string_tonumber"] = {
		group = "String",
		name = "String > Number",
		inputs = { "A" },
		inputtypes = { "STRING" },
		outputs = { "Out" },
		output = function(gate, A)
			return (tonumber(A) or 0)
		end,
		label = function(Out, A)
		    return A.." = "..Out.Out
		end
	}

	GateActions["string_entinfo"] = {
		group = "String",
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
		group = "String",
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

	GateActions["string_select"] = {
		group = "String",
		name = "Select (String)",
		inputs = { "Choice", "A", "B", "C", "D", "E", "F", "G", "H" },
		inputtypes = { "NORMAL", "STRING", "STRING", "STRING", "STRING", "STRING", "STRING", "STRING", "STRING" },
		outputs = { "Out" },
		outputtypes = { "STRING" },
		output = function(gate, Choice, ...)
			local idx = math.floor(Choice)
		    if (idx > 0) and (idx <= 8) then
				return arg[idx]
			end
		    
			return ""
		end,
		label = function(Out, Choice)
		    return "Select Choice:"..Choice.." Out:"..Out.Out
		end
	}

	GateActions["string_router"] = {
		group = "String",
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
		group = "String",
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
		group = "String",
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

	for name,gate in pairs(GateActions) do
		if !WireGatesSorted[gate.group] then WireGatesSorted[gate.group] = {} end
		WireGatesSorted[gate.group][name] = gate
	end
end

timer.Simple(1,AddStringGates)