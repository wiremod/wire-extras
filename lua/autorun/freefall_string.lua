AddCSLuaFile( "autorun/freefall_string.lua" )

function string.instr(stringIn, toFind, start)
	local i = 1
	
	if (start == nil || type(start) != "number") then
		i = 1
	else
		i = start
	end
	
	if (stringIn == "" || type(stringIn) != "string") then return -2 end
	if (toFind == "" || type(toFind) != "string") then return -2 end
	
	local stringLength = string.len(stringIn)
	local findLength = string.len(toFind)
	
	while (i < stringLength + (findLength-1)) do
		if (string.sub(stringIn,i,i+(findLength-1)) == toFind) then
			return i
		end
		
		i = i + 1
	end
	
	return -1
end

AddCSLuaFile( "autorun/wiregates.lua" )

function freefallwiregates()
	GateActions["string_switchgate"] = {
		group = "String",
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
	
	GateActions["advduperam"] = {
	    group = "Memory",
	    name = "Adv. Dupe. Teleporter Data RAM",
		timed = true,
	    inputs = { "Clk", "AddrRead", "AddrWrite", "Data","Send" },
		inputtypes = { "NORMAL","NORMAL","NORMAL","STRING","NORMAL" },
		outputs = { "Data","Blocks","IsSending","IsReceiving" },
		outputtypes = { "STRING","NORMAL","NORMAL","NORMAL" },
	    output = function(gate, Clk, AddrRead, AddrWrite, Data, Send )
			AddrRead = math.floor(tonumber(AddrRead))
			AddrWrite = math.floor(tonumber(AddrWrite))
			local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
			
			if (gate.Receiving == 0) then
				gate.AddrWrite = AddrWrite
			end
			if (gate.Sending == 0) then
				gate.AddrRead = AddrRead
			end
			
	        if (Clk > 0) then
				if (Data != "" && string.sub(Data,1,5) == "Data:" && (gate.AddrWrite != gate.AddrRead || gate.Sending == 0)) then
					if (string.sub(Data,6,10) == "Start") then
						gate.Store[gate.AddrWrite] = {}
						gate.Store[gate.AddrWrite].List = {}
						gate.Store[gate.AddrWrite].BlockCount = 0
						
						gate.Receiving = 1
						
						gate.Store[gate.AddrWrite].BlockCount = tonumber(string.sub(Data,12,string.len(Data)))
					elseif (gate.Receiving == 1) then
						pos = string.instr(Data,":",6)
						BlockNum = tonumber(string.sub(Data,6,pos-1))
						
						gate.Store[gate.AddrWrite].List[BlockNum] = string.sub(Data,pos+1,string.len(Data))
						
						if (BlockNum == (gate.Store[gate.AddrWrite].BlockCount - 1)) then
							gate.Receiving = 0
						end
					end			
				end
			end
			
			if (DeltaTime >= 0.1 && gate.Sending == 1) then
				gate.SendBlockNum = gate.SendBlockNum + 1
				gate.PrevTime = CurTime()
				if (gate.SendBlockNum == gate.Store[gate.AddrRead].BlockCount) then
					gate.Sending = 0
				end
			end
			
			if (gate.Sending == 0) then
				if (Send > 0) then
					Msg("Send Called\n")
					if (gate.Store[gate.AddrRead] && (gate.Receiving == 0 || gate.AddrRead != gate.AddrWrite)) then
						if (gate.Store[gate.AddrRead].List && gate.Store[gate.AddrRead].BlockCount > 0) then
							gate.Sending = 1
							gate.SendBlockNum = -2
							gate.PrevTime = 0
						end
					end
				end
			
				if (gate.Receiving == 1 && AddrRead == gate.AddrWrite) then
					return "",0,0,1
				else
					if (gate.Store[AddrRead]) then
						return "", gate.Store[AddrRead].BlockCount or 0,0,gate.Receiving or 0
					else
						return "", 0,0,gate.Receiving or 0
					end
				end
			else
				if (gate.SendBlockNum == -1) then
					return "Data:Start:"..gate.Store[gate.AddrRead].BlockCount, gate.Store[AddrRead].BlockCount or 0,1,gate.Receiving or 0
				elseif (gate.SendBlockNum > -1) then
					return "Data:"..gate.SendBlockNum..":"..gate.Store[gate.AddrRead].List[gate.SendBlockNum], gate.Store[AddrRead].BlockCount or 0,1,gate.Receiving or 0
				end
			end
	    end,
	    reset = function(gate)
	        gate.Store = {}
			gate.Receiving = 0
			gate.Sending = 0
	    end,
	    label = function(Out, Clk, AddrRead, AddrWrite, Data)
		    return ""
	    end
	}

	for name,gate in pairs(GateActions) do
		if !WireGatesSorted[gate.group] then WireGatesSorted[gate.group] = {} end
		WireGatesSorted[gate.group][name] = gate
	end
end

timer.Simple(.1, freefallwiregates)
