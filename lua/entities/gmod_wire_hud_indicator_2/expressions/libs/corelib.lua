print("[II]", "Loading core library...")

EXPR_Parser.binaryFuncs["+"] = function ( opStack, andStack )
	local b = andStack:pop()
	local a = andStack:pop()
	local result = { type="COLLECTION", value={} }
	
	if( a and b ) then
	
		-- String concatination
		if( type(a.value) == "string" or type(b.value) == "string" ) then
			andStack:push( {value=tostring(a.value) .. tostring(b.value), type="VALUE"} )
			return true
		
		-- Numeric addition
		elseif( type(a.value) == "number" and type(b.value) == "number" ) then
			andStack:push( {value=a.value+b.value, type="VALUE"} )
			return true
		
		-- Table/vector addition
		elseif( type(a.value) == "table" and type(b.value) == "table" ) then
			
			local aDepth = table.maxn( a.value )
			local bDepth = table.maxn( b.value )
			
			-- Where both are 3D
			if( aDepth == 3 and bDepth == 3 ) then
				result.value[1] = { value=a.value[1].value+b.value[1].value, type="VALUE" }
				result.value[2] = { value=a.value[2].value+b.value[2].value, type="VALUE" }
				result.value[3] = { value=a.value[3].value+b.value[3].value, type="VALUE" }
				
				andStack:push( result )
				return true
			
			-- Where both are 2D
			elseif( aDepth == 2 and bDepth == 2 ) then
				result.value[1] = { value=a.value[1].value+b.value[1].value, type="VALUE" }
				result.value[2] = { value=a.value[2].value+b.value[2].value, type="VALUE" }
				
				andStack:push( result )
				return true
			
			-- Where 'b' is a 3D vector
			elseif( aDepth == 2 and bDepth == 3 ) then
				local screen = Vector( b.value[1].value, b.value[2].value, b.value[3].value ):ToScreen()
				
				b[1] = { value=screen.x, type="VALUE" }
				b[2] = { value=screen.y, type="VALUE" }
				b[3] = nil
				
				result.value[1] = { value=a.value[1].value+b.value[1].value, type="VALUE" }
				result.value[2] = { value=a.value[2].value+b.value[2].value, type="VALUE" }
				
				andStack:push( result )
				return true
				
			-- Where 'a' is a 3D vector
			elseif( aDepth == 3 and bDepth == 2 ) then
				local screen = Vector( a.value[1].value, a.value[2].value, a.value[3].value ):ToScreen()
				
				a.value[1] = { value=screen.x, type="VALUE" }
				a.value[2] = { value=screen.y, type="VALUE" }
				a.value[3] = nil
				
				result.value[1] = { value=a.value[1].value+b.value[1].value, type="VALUE" }
				result.value[2] = { value=a.value[2].value+b.value[2].value, type="VALUE" }
				
				andStack:push( result )
				return true
				
			end
			
		end
	end
	
	return false
end

EXPR_Parser.binaryFuncs["-"] = function ( opStack, andStack, context )
	local b = andStack:pop()
	local a = {value=0, type="VALUE"}
	
	if( andStack:peekTop().type == "VALUE" ) then
		a = andStack:pop()
	end
	
	if( a and b ) then
		
		-- Numeric subtraction
		if( type(a.value) == "number" and type(b.value) == "number" ) then
			andStack:push( {value=a.value-b.value, type="VALUE"} )
			return true
		
		-- Table/vector addition
		elseif( type(a.value) == "table" and type(b.value) == "table" ) then
			
			local aDepth = table.maxn( a.value )
			local bDepth = table.maxn( b.value )
			
			-- Where both are 3D
			if( aDepth == 3 and bDepth == 3 ) then
				result.value[1] = { value=a.value[1].value-b.value[1].value, type="VALUE" }
				result.value[2] = { value=a.value[2].value-b.value[2].value, type="VALUE" }
				result.value[3] = { value=a.value[3].value-b.value[3].value, type="VALUE" }
				
				andStack:push( result )
				return true
			
			-- Where both are 2D
			elseif( aDepth == 2 and bDepth == 2 ) then
				result.value[1] = { value=a.value[1].value-b.value[1].value, type="VALUE" }
				result.value[2] = { value=a.value[2].value-b.value[2].value, type="VALUE" }
				
				andStack:push( result )
				return true
			
			-- Where 'b' is a 3D vector
			elseif( aDepth == 2 and bDepth == 3 ) then
				local screen = Vector( b.value[1].value, b.value[2].value, b.value[3].value ):ToScreen()
				
				b[1] = { value=screen.x, type="VALUE" }
				b[2] = { value=screen.y, type="VALUE" }
				b[3] = nil
				
				result.value[1] = { value=a.value[1].value-b.value[1].value, type="VALUE" }
				result.value[2] = { value=a.value[2].value-b.value[2].value, type="VALUE" }
				
				andStack:push( result )
				return true
				
			-- Where 'a' is a 3D vector
			elseif( aDepth == 3 and bDepth == 2 ) then
				local screen = Vector( a.value[1].value, a.value[2].value, a.value[3].value ):ToScreen()
				
				a.value[1] = { value=screen.x, type="VALUE" }
				a.value[2] = { value=screen.y, type="VALUE" }
				a.value[3] = nil
				
				result.value[1] = { value=a.value[1].value-b.value[1].value, type="VALUE" }
				result.value[2] = { value=a.value[2].value-b.value[2].value, type="VALUE" }
				
				andStack:push( result )
				return true
				
			end
			
		end
	end
	
	return false
end

EXPR_Parser.binaryFuncs["*"] = function ( opStack, andStack )
	local b = andStack:pop()
	local a = andStack:pop()
	
	if( a and b ) then
		if( type(a.value) == "string" ) then
			andStack:push( {value=a.value:rep(b.value), type="VALUE"} )
			return true
			
		elseif( type(b.value) == "string" ) then
			andStack:push( {value=b.value:rep(a.value), type="VALUE"} )
			return true
			
		elseif( type(a.value) == "string" and type(b.value) == "string" ) then
			return false
			
		elseif( type(a.value) == "number" and type(b.value) == "number" ) then
			andStack:push( {value=a.value*b.value, type="VALUE"} )
			return true
		end
	end
	
	return false
end

EXPR_Parser.binaryFuncs["/"] = function ( opStack, andStack )
	local b = andStack:pop("number")
	local a = andStack:pop("number")
	
	if( a and b ) then
		andStack:push( {value=a.value/b.value, type="VALUE"} )
		return true
	end
	
	return false
end

EXPR_Parser.binaryFuncs["^"] = function ( opStack, andStack )
	local b = andStack:pop("number")
	local a = andStack:pop("number")
	
	if( a and b ) then
		andStack:push( {value=a.value^b.value, type="VALUE"} )
		return true
	end
	
	return false
end
