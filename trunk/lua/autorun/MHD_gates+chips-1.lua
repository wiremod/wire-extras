AddCSLuaFile( "autorun/_kilburnwiregates.lua" )
AddCSLuaFile( "autorun/MHD_gates+chips-1.lua" )

//**********************************************
// Arithmetic Gates
//**********************************************
local function AddMHDGates()
	GateActions["PHI"] = {
		group = "Arithmetic",
		name = "Phi",
		inputs = { },
		outputs = { "Algebra", "Trig", "666" },
		output = function(gate)
			return
				(1 + math.sqrt(5)) / 2,
				2*math.cos(math.rad(36)),
				-(math.sin(math.rad(666)) + math.cos(math.rad(6*6*6)))
		end	
	}
	//Q: What is Phi?
	//A: Phi is a irrational decimal value of approx. 1.6180339887...
	//   Phi resembles the ratio of the sides of an ordinay A4 paper sheet. -- that is bullshit, A4 is 1.41:1, very far from phi. The "Letter" format is closer.
	//   Phi resembles the screen ratio of widescreens (16:9 or 16:10 is roughly the same as Phi:1).
	//   Phi is the approximate ratio between two sucsessing fibbonachi numbers (1,1,2,3,5,8,13,21,35...).
	//   Phi resembles the expansion coefficient of snail shells.
	//   Phi resembles the expansion acceleration of the universe. -- wtf?
	--   Phi is a/b = (a+b)/a
	
	//**********************************************
	// Memory Chips
	//**********************************************
	
	GateActions["ram1024k"] = {
		group = "Memory",
		name = "RAM(1M = 1024k)",
		inputs = { "Clk", "AddrRead", "AddrWrite", "Data" },
		output = function(gate, Clk, AddrRead, AddrWrite, Data )
			AddrRead = math.floor(tonumber(AddrRead))
			AddrWrite = math.floor(tonumber(AddrWrite))
			if (Clk > 0) then
				if (AddrWrite < 1048575) and (AddrWrite >= 0) then
					gate.LatchStore[AddrWrite] = Data
				end
			end
			return gate.LatchStore[AddrRead] or 0
		end,
		reset = function(gate)
			gate.LatchStore = {}
			for i = 0,1048575 do
				gate.LatchStore[i] = 0
			end
		end,
		label = function(Out, Clk, AddrRead, AddrWrite, Data)
			return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk..
			"\nReadAddr:"..AddrRead.." = "..Out
		end,
		ReadCell = function(dummy,gate,Address)
			if Address < 0 then return 0 end
			if Address >= 1048576 then return 0 end
			
			return gate.LatchStore[Address] or 0
		end,
		WriteCell = function(dummy,gate,Address,value)
			if Address < 0 then return false end
			if Address >= 1048576 then return false end
			
			gate.LatchStore[Address] = value
			return true
		end
	}
	
	GateActions["ram64x64x64"] = {
		group = "Memory",
		name = "RAM(64x64x64 store)",
		inputs = { "Clk", "AddrRX", "AddrRY", "AddrRZ", "AddrWX", "AddrWY", "AddrWZ", "Data" },
		output = function(gate, Clk, AddrRX, AddrRY, AddrRZ, AddrWX, AddrWY, AddrWZ, Data)
			ReadX = math.floor(tonumber(AddrRX))
			ReadY = math.floor(tonumber(AddrRY))
			ReadZ = math.floor(tonumber(AddrRZ))
			WriteX = math.floor(tonumber(AddrWX))
			WriteY = math.floor(tonumber(AddrWY))
			WriteZ = math.floor(tonumber(AddrWZ))
			if (Clk > 0) then
				if (WriteX < 64) and (WriteX >= 0) and (WriteY < 64) and (WriteY >= 0) and (WriteZ < 64) and (WriteZ >= 0) then
					gate.LatchStore[WriteX + WriteY*64 + WriteZ*4096] = Data
				end
			end
			
			if (ReadX < 0) or (ReadX >= 64) or (ReadY < 0) or (ReadY >= 64) or (ReadZ < 0) or (ReadZ >= 64) then
				return 0
			end
			
			return gate.LatchStore[ReadX + ReadY*64 + ReadZ*4096] or 0
		end,
		reset = function(gate)
			gate.LatchStore = {}
			for i = 0,262143 do
				gate.LatchStore[i] = 0
			end
		end,
		label = function(Out, Clk, AddrRX, AddrRY, AddrRZ, AddrWX, AddrWY, AddrWZ, Data)
			return "WriteAddr:"..AddrWX..", "..AddrWY..", "..AddrWZ..
				"\nReadAddr:"..AddrRX..", "..AddrRY..", "..AddrRZ..
				"\nData:"..Data.."  Clock:"..Clk
		end,
		ReadCell = function(dummy,gate,Address)
			if Address < 0 then return 0 end
			if Address >= 262144 then return 0 end
			
			return gate.LatchStore[Address] or 0
		end,
		WriteCell = function(dummy,gate,Address,value)
			if Address < 0 then return false end
			if Address >= 262144 then return false end
			
			gate.LatchStore[Address] = value
			return true
		end
	}
	
	for name,gate in pairs(GateActions) do
		if !WireGatesSorted[gate.group] then WireGatesSorted[gate.group] = {} end
		WireGatesSorted[gate.group][name] = gate
	end
end

timer.Simple(1,AddMHDGates)
