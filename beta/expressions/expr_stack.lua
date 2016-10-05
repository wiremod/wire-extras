EXPR_Stack = {}

function EXPR_Stack:new()
	local obj = {}
	setmetatable( obj, {__index = EXPR_Stack} )
	obj.elements = {}

	return obj
end

function EXPR_Stack:push( element )
	table.insert( self.elements, element )
end

function EXPR_Stack:pop()
	if( table.maxn( self.elements ) == 0 ) then
		return nil
	end
	return table.remove( self.elements )
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
		buffer = buffer .. "," .. tostring(value)
	end
	
	print( buffer )
end
