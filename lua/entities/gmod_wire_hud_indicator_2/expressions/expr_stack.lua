EXPR_Stack = {}

function EXPR_Stack:new()
	local obj = {}
	setmetatable( obj, {__index = EXPR_Stack} )
	obj.elements = {}

	return obj
end

function EXPR_Stack:push( element )
	if( element ~= nil ) then
		table.insert( self.elements, element )
	else
		--Silently die, for now!
	end
end

function EXPR_Stack:pop( _type )
	if( table.maxn( self.elements ) == 0 ) then
		return nil
	end
	local value =  table.remove( self.elements )
	
	if( _type ~= nil and
		value.value ~= nil and
		type(value.value) ~= _type ) then
		
		self:push( value )
		return nil
	end
	
	return value
end

function EXPR_Stack:size()
	return table.maxn( self.elements )
end

function EXPR_Stack:collapse()
	local output = ""
	for key, tok in pairs(self.elements) do
		output = output .. tostring(tok.value)
	end
	return output
end

function EXPR_Stack:peek( depth )
	local depth = depth or 0
	local size = self:size()
	return self.elements[size+depth]
end

function EXPR_Stack:peekTop()
	local tok = self:pop()
	self:push( tok )
	return tok
end

function EXPR_Stack:print( prefix )
	local buffer = prefix or "STACK: "
	for key, value in pairs( self.elements) do
		if( type(value) == "table" and value.value ~= nil ) then
			buffer = buffer .. ",[" .. tostring(value.type) .. " " .. tostring(value.value) .. " " .. tostring(value.depth) .. "] "
		else
			buffer = buffer .. ",[" .. tostring(value) .. "] "
		end
	end

	print( buffer )
end

function EXPR_Stack:clear()
	self.elements = {}
end
