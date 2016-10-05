print("[II]", "Loading logic library...")

--Clamps a value between a minimum and a maximum
EXPR_Parser.funcTable["clamp"] = function ( opStack, andStack )
	--local params = andStack:pop("table")
	local max = andStack:pop("number")
	local min = andStack:pop("number")
	local value = andStack:pop("number")
	
	if( max and min and value ) then
		--local value, min, max = params[1], params[2], params[3]
		
		if( value > max ) then
			andStack:push( max )
			
		elseif( value < min ) then
			andStack:push( min )
			
		else
			andStack:push( value )
			
		end
		
		return true
	end
	return false
end

--Clamps a value between a minimum and a maximum
EXPR_Parser.binaryFuncs["%"] = function ( opStack, andStack, context )
	local value = andStack:pop("number")
	
	if( context == nil or context.max == nil or context.min == nil ) then
		print( "[EE]\tTried to perform a percentage calculation without a context!" )
		PrintTitledTable("Supplied Context:", context)
		return false
	end
	
	if( value and value.value == nil ) then
		print( "[EE]\tHad a context, but no value was passed with this token's meta data!" )
		PrintTitledTable("TOKEN:", value )
		return false
	end
	
	if( value and value.value ) then
		local result = ((context.max-context.min)/100)*value.value

		andStack:push( { type="VALUE", value=result } )
		
		return true
	end
	return false
end

