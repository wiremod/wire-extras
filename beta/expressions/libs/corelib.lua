print("[II]", "Loading core library...")

EXPR_Parser.binaryFuncs["+"] = function ( opStack, andStack )
	local b = andStack:pop()
	local a = andStack:pop()
	
	if( a and b ) then
		andStack:push( a+b )
		return true
	end
	
	return false
end

EXPR_Parser.binaryFuncs["-"] = function ( opStack, andStack )
	local b = andStack:pop()
	local a = andStack:pop()
	
	if( a and b ) then
		andStack:push( a-b )
		return true
	end
	
	return false
end

EXPR_Parser.binaryFuncs["*"] = function ( opStack, andStack )
	local b = andStack:pop()
	local a = andStack:pop()
	
	if( a and b ) then
		andStack:push( a*b )
		return true
	end
	
	return false
end

EXPR_Parser.binaryFuncs["/"] = function ( opStack, andStack )
	local b = andStack:pop()
	local a = andStack:pop()
	
	if( a and b ) then
		andStack:push( a/b )
		return true
	end
	
	return false
end

EXPR_Parser.binaryFuncs["^"] = function ( opStack, andStack )
	local b = andStack:pop()
	local a = andStack:pop()
	
	if( a and b ) then
		andStack:push( a^b )
		return true
	end
	
	return false
end
