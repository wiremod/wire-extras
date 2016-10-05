--servermessage module by greenarrow

--include ("autorun/shared/servermessagetypes.lua")



if CLIENT then
	local table = table
	local ipairs = ipairs
	local type = type
	local tostring = tostring
	local tonumber = tonumber
	local concommand = concommand
	local LocalPlayer = LocalPlayer
	local Msg = Msg
	
	module ("smsg")
	
	local dataTypeLookup = {
		string = 4,
		entity = 5,
		short = 1,
		bool = 2
	}

	function Start (msgName)
		--start usermessage
		if inMessage then
			Msg ("WARNING: starting a new clumsg without finishing the old one\n")
		end
		currentMsg = {name = msgName, data = {}}
		inMessage = true
	end

	function Short (short)
		if short then
			table.insert(currentMsg.data, {dataType = dataTypeLookup.short, data = tostring(short)})
		else
			Msg ("smsg error: nil value\n")
		end
	end

	function String (dataString)
		if dataString then
			--add entry to data table
			table.insert(currentMsg.data, {dataType = dataTypeLookup.string, data = dataString})
		else
			Msg ("smsg error: nil value\n")
		end
	end

	function Entity (ent)
		if ent then
			local entClass = ent:GetClass()
			local entIndex = ent:EntIndex()
			local entString = tostring(entIndex) .."|".. entClass
			table.insert(currentMsg.data, {dataType = dataTypeLookup.entity, data = entString})
		else
			Msg ("smsg error: nil value\n")
		end
	end
	
	function Bool (boolVal)
		local intValue = 0
		if boolVal then
			intValue = 1
		end
		--Msg("intval = "..intValue..", type = "..dataTypeLookup.bool.."\n")
		table.insert(currentMsg.data, {dataType = dataTypeLookup.bool, data = tostring(intValue)})
	end

	function End ()
		--send message
		local player = LocalPlayer()
		local message = currentMsg.name

		for k, dat in ipairs (currentMsg.data) do
			message = message .. ' ' .. dat.dataType .. ' "' .. dat.data .. '"'
		end
		--Msg("sending message ["..message.."]\n")
		player:ConCommand ("ccservermessage "..message.."\n")
		inMessage = false
	end
end

