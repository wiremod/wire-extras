print("[II]", "Loading string library...")

--Maps 'string.byte' as 'toByte'
EXPR_Parser.funcTable["toByte"] = function ( opStack, andStack )
	local a = andStack:pop("string")
	if( a ) then
		andStack:push( string.byte(a) )
		return true
	end
	return false
end

--Maps 'string.char' as 'toChar'
EXPR_Parser.funcTable["toChar"] = function ( opStack, andStack )
	local a = andStack:pop("string")
	if( a ) then
		andStack:push( string.char(a) )
		return true
	end
	return false
end

--Maps 'string.len' as 'length'
EXPR_Parser.funcTable["length"] = function ( opStack, andStack )
	local a = andStack:pop("string")
	if( a ) then
		andStack:push( string.len(a) )
		return true
	end
	return false
end

--Maps 'string.lower' as 'toLower'
EXPR_Parser.funcTable["toLower"] = function ( opStack, andStack )
	local a = andStack:pop("string")
	if( a ) then
		andStack:push( string.lower(a) )
		return true
	end
	return false
end

--Maps 'string.upper' as 'toUpper'
EXPR_Parser.funcTable["toUpper"] = function ( opStack, andStack )
	local a = andStack:pop("string")
	if( a ) then
		andStack:push( string.upper(a) )
		return true
	end
	return false
end

--Maps 'string.reverse' as 'reverse'
EXPR_Parser.funcTable["reverse"] = function ( opStack, andStack )
	local a = andStack:pop("string")
	if( a ) then
		andStack:push( string.reverse(a) )
		return true
	end
	return false
end
