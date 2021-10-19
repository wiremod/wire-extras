AddCSLuaFile( "wire/gates/freefall_string.lua" )

function string.instr(stringIn, toFind, start)
	local i = 1
	local start = start or 1
	
	if (stringIn == "" || type(stringIn) != "string") then return -2 end
	if (toFind == "" || type(toFind) != "string") then return -2 end
	
	local stringLength = string.len(stringIn)
	local findLength = string.len(toFind)
	
	for i = start,stringLength-(findLength-1) do
		if (string.sub(stringIn,i,i+(findLength-1)) == toFind) then
			return i
		end
		
		i = i + 1
	end
	
	return -1
end

GateActions("String")

GateActions["string_switchgate"] = {
	name = "Switch",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H", "Num" },
	inputtypes = { "STRING", "STRING", "STRING", "STRING", "STRING", "STRING", "STRING", "STRING", "NORMAL" },
	outputs = { "Out" },
	outputtypes = { "STRING" },
	output = function(gate, A, B, C, D, E, F, G, H, Num)
		if (Num == 1) then return A end
		if (Num == 2) then return B end
		if (Num == 3) then return C end
		if (Num == 4) then return D end
		if (Num == 5) then return E end
		if (Num == 6) then return F end
		if (Num == 7) then return G end
		if (Num == 8) then return H end
		if (Num < 1 || Num > 8) then return "" end
	end,
	label = function(Out, A, B, C, D, E, F, G, H, Num)
		return ("Selected: "..Out.Out)
	end
}

GateActions["string_hispeed_convert"] = {
	name = "Hi-Speed String Converter",
	inputs = { "String", "AddrRead" },
	inputtypes = { "STRING", "NORMAL" },
	output = function(gate, String, AddrRead )
		if (String ~= gate.LastString) then
			gate.LatchStore = {}
			for i = 1,string.len(String) do
				gate.LatchStore[i-1] = string.byte(string.sub(String,i,i))
			end
			gate.LastString = String
			gate.LatchSize = string.len(String)
		end
		
		AddrRead = math.floor(tonumber(AddrRead))
		
		if (AddrRead == 0) then return gate.LatchSize end
		
		if (AddrRead < 0) or ((AddrRead-1) >= gate.LatchSize) then return 0 end
		
		return gate.LatchStore[AddrRead-1] or 0
	end,
	reset = function(gate)
		gate.LatchStore = {}
		gate.LastString = ""
		gate.LatchSize = 0
	end,
	label = function(Out, String, AddrRead)
		return "String: "..String.."\nReadAddr:"..AddrRead.." = "..Out
	end,
	ReadCell = function(dummy,gate,Address)
		if (Address < 0) || ((Address-1) >= gate.LatchSize) then
			return 0
		else
			if (Address == 0) then
				return gate.LatchSize
			else
				return gate.LatchStore[Address-1] or 0
			end
		end
	end,
	WriteCell = function(dummy,gate,Address,value)
		return false
	end
}

GateActions()
