--servermessage module by greenarrow
--AddCSLuaFile ("autorun/shared/servermessagetypes.lua")
AddCSLuaFile ("autorun/client/smsg.lua")

--include ("autorun/shared/servermessagetypes.lua")



----------------------------------------------------------------SERVER SIDE MODULE--------------------------------------------------------------------

if SERVER then
	local table = table
	local ipairs = ipairs
	local type = type
	local tostring = tostring
	local tonumber = tonumber
	local concommand = concommand
	local LocalPlayer = LocalPlayer
	local Msg = Msg

	

	local function toentity(class, index)
		local ents  = ents.FindByClass(class)
		for k, ent in ipairs(ents) do
			if (ent:EntIndex() == index) then
				return ent
			end
		end
	end

	---------------------------------------Receiver object----------------------------------
	local smReceiver = {
		message = {}
	}
	
	local dataTypeLookup = {
		string = 4,
		entity = 5,
		short = 1,
		bool = 2
	}

	local dataTypeErrorMsg = "servermessage error: unexpected data type\n"

	function smReceiver.Create()
		local self = table.Copy (smReceiver)
		return self
	end

	function smReceiver:AddEntry(data, dataType)
		table.insert (self.message, {data = data, dataType = dataType})
	end

	function smReceiver:ReadShort()
		if (self.message[1].dataType == dataTypeLookup.short) then
			local rData = tonumber(self.message[1].data)
			table.remove (self.message, 1)
			return rData
		else
			Msg (dataTypeErrorMsg)
			return ""
		end
	end
	
	function smReceiver:ReadBool()
		--Msg("type = "..self.message[1].dataType..", dat = "..self.message[1].data.."\n")
		if (self.message[1].dataType == dataTypeLookup.bool) then
			local rBool = false
			if (tonumber(self.message[1].data) == 1) then
				rBool = true
				--Msg("true\n")
			end
			table.remove (self.message, 1)
			return rBool
		else
			Msg (dataTypeErrorMsg)
			return false
		end
	end

	function smReceiver:ReadString()
		if self.message[1] then	--put this on all
			if (self.message[1].dataType == dataTypeLookup.string) then
				local rData = self.message[1].data
				table.remove (self.message, 1)
				return rData
			else
				Msg (dataTypeErrorMsg)
				return ""
			end
		else
			Msg ("error\n")
		end
	end

	function smReceiver:ReadEntity()
		if (self.message[1].dataType == dataTypeLookup.entity) then
			local dividePos = string.find (self.message[1].data, "|")
			local entIndex = tonumber(string.sub (self.message[1].data, 1, dividePos - 1))
			local entClass = string.sub (self.message[1].data, dividePos + 1, -1)
			local foundEnt = toentity(entClass, entIndex)
			table.remove (self.message, 1)
			return foundEnt
		else
			Msg (dataTypeErrorMsg)
		end
	end

	--------------------------Servermessage module---------------------------------------------------

	module ("servermessage")

	--table of hook functions
	local hookFunctionTable = {}

	function Hook(msgName, hookFunction)
		--add function to hook table
		Msg("adding hook "..msgName..", func = "..type(hookFunction).."\n")
		hookFunctionTable[msgName] = hookFunction
	end

	--------------------------------------communications---------------------------

	local function ccServerMessage(player, commandName, args)
		local smRec = smReceiver.Create()
		local currentType = nil
		local messageName = nil
		--extract data for message name and entries
		for k, dat in ipairs (args) do
			if messageName then
				if !currentType then
					currentType = tonumber (dat)
				else
					smRec:AddEntry (dat, currentType)
					currentType = nil
				end
			else
				messageName = dat
			end
		end
		--call user hooked function
		smRec.player = player
		Msg ("msg "..messageName.."\n")
		hookFunctionTable[messageName] (smRec)
	end
	concommand.Add("ccservermessage", ccServerMessage)
end

