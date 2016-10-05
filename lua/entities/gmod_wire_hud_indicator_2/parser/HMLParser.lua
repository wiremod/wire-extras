include( "Constants.lua" )
include("entities/gmod_wire_hud_indicator_2/util/tables.lua")

HMLParser = {}

function HMLParser:new( code )
	local obj = {}
	setmetatable( obj, {__index = HMLParser} )


	obj.code = code
	obj.tree = {}
	obj.valid = false
	obj.constants = HMLConstants()
	obj.inputs = {}
	obj.validTypes = {}
	obj.tagIndex = 0
	
	obj.validTypes['2'] = "vector2"
	obj.validTypes['3'] = "vector3"
	obj.validTypes['4'] = "vector4"
	obj.validTypes['s'] = "string"
	obj.validTypes['c'] = "color"
	obj.validTypes['a'] = "alpha_color"
	obj.validTypes[''] = "numeric"

	return obj
end

function HMLParser:exec( newcode )
	local result = nil

	if( newcode ~= nil ) then
		self.code = newcode
	end


	if( self.code ~= nil ) then

		Msg("Currently attempting to parse:\n" .. self.code .. "\n")

		self.inputs = {}

		Msg("Parsing HML...")
		result = self:collect( self.code )
		Msg("Done\n")
	else
		result = false
		Msg("No code to parse!\n")
	end

	return result
end

function HMLParser:toString( var )
	if( type(var) == "string" ) then return var end
	return ""
end

function HMLParser:getInputTable()
	return self.inputs
end

function HMLParser:toNumber( var )
	local output = tonumber( var )

	print( type( var ), " = ", output )

	if( output ~= nil ) then return output end

	return 0
end

function HMLParser:toBoolean( var )
	if( type(var) == "boolean" ) then return var end
	return false
end

function HMLParser:toTable( var )
	if( type(var) == "table" ) then return var end
	return {}
end

function HMLParser:parseargs(s)
	local arg = {}
	local foundInputs = false
	
	--print( "--Parsing Arguments--" )
	--print( "string: ", s )

	--These should have inputs created on the SENT...
	for key, value in string.gmatch(s, "([%a_]+)%=([^;]-);") do
		foundInputs = false
		
		for type, name in string.gmatch(value, "([234sca]?)@(%u[%w_]+)") do
			print("Input: ", type, name)
			
			if( self.validTypes[type] ~= nil ) then
				self.inputs[name] = {}
				self.inputs[name].type = self.validTypes[type]
				self.inputs[name].value = 0
			else
				print("[WW]", "Input " ..tostring(name).. " was an unknown type (" ..tostring(type).. ") and was not added to the input table! No updates will be performed on this input!")
			end
			
			foundInputs = true
			
		end
		
		arg[key] = value
	end

	return arg
end

function HMLParser:collect(s)
	local stack = {}
	local top = {}
	table.insert(stack, top)
	local ni,c,tag,xarg, empty
	local i, j = 1, 1

	while true do
		ni,j,c,tag,xarg, empty = string.find(s, "<(%/?)([!%-%w]+)(.-)(%/?)>", i)
		if not ni then break end
		local text = string.sub(s, i, ni-1)

		if not string.find(text, "^%s*$") then
			table.insert(top, text)
		end
		
		self.tagIndex = self.tagIndex + 1
		
		if( tag == "!--" ) then
			--print("Skipped comment -> '" ..tostring(xarg).. "'" )
			
		else
			if empty == "/" then  -- empty element tag
				local newTag = self:parseargs(xarg)
				newTag.empty = 1
				newTag.tag = tag
				newTag.uid = self.tagIndex
				table.insert(top, newTag)

			elseif c == "" then   -- start tag
				top = self:parseargs(xarg)
				top.tag = tag
				top.uid = self.tagIndex
				table.insert(stack, top)   -- new level

			else  -- end tag
				local toclose = table.remove(stack)  -- remove top
				top = stack[#stack]
				top.uid = self.tagIndex
				if #stack < 1 then
					HMLError("nothing to close with "..tag)
				end

				if toclose.tag ~= tag then
					toclose.tag = toclose.tag or "nil"
					HMLError("trying to close "..toclose.tag.." with "..tag)
				else
					table.insert(top, toclose)
				end


			end
		end

		i = j + 1
	end

	local text = string.sub(s, i)

	if not string.find(text, "^%s*$") then
		table.insert(stack[#stack], text)
	end

	if #stack > 1 then
		local output = "UNKNOWN, probably syntax"
		if( stack ~= nil and stack.n ~= nil ) then
			output = output .. "stack=" .. tostring(stack) .. ", stack=" .. tostring(stack.n)
			if( stack[stack.n] ~= nil and stack[stack.n].tag ~= nil ) then
				output = output .. "stack[n]=" .. tostring(stack[stack.n]) .. ", stack[n].tag=" .. tostring(stack[stack.n].tag)
			end
		end

		HMLError("Incomplete XML: Unclosed/Missing tags '"..output)
		return false
	end

	return stack[1]
end
