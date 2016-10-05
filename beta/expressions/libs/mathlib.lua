print("[II]", "Loading math library...")

--ABS
EXPR_Parser.funcTable["abs"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.abs(a) )
		return true
	end
	return false
end

--ACOS
EXPR_Parser.funcTable["acos"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.acos(a) )	
		return true
	end
	return false
end

--ASIN
EXPR_Parser.funcTable["asin"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.asin(a) )
		return true
	end
	return false
end

--ATAN
EXPR_Parser.funcTable["atan"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.atan(a) )
		return true
	end
	return false
end

--ATAN2
EXPR_Parser.funcTable["atan2"] = function ( opStack, andStack )
	local b = andStack:pop()
	local a = andStack:pop()
	if( a and b ) then
		andStack:push( math.atan2(a,b) )
		return true
	end
	return false
end

--CEIL
EXPR_Parser.funcTable["ceil"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.ceil(a) )
		return true
	end
	return false
end

EXPR_Parser.funcTable["cos"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.cos(a) )
		return true
	end
	return false
end

--COSH
EXPR_Parser.funcTable["cosh"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.cosh(a) )
		return true
	end
	return false
end

--DEG
EXPR_Parser.funcTable["deg"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.deg(a) )
		return true
	end
	return false
end

--EXP
EXPR_Parser.funcTable["exp"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.exp(a) )
		return true
	end
	return false
end

--FLOOR
EXPR_Parser.funcTable["floor"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.floor(a) )
		return true
	end
	return false
end

--FMOD
EXPR_Parser.funcTable["fmod"] = function ( opStack, andStack )
	local b = andStack:pop()
	local a = andStack:pop()
	if( a and b ) then
		andStack:push( math.fmod(a,b) )
		return true
	end
	return false
end

--FREXP
EXPR_Parser.funcTable["frexp"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.frexp(a) )
		return true
	end
	return false
end

--LDEXP
EXPR_Parser.funcTable["ldexp"] = function ( opStack, andStack )
	local b = andStack:pop()
	local a = andStack:pop()
	if( a and b ) then
		andStack:push( math.ldexp(a,b) )
		return true
	end
	return false
end

--LOG
EXPR_Parser.funcTable["log"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.log(a) )
		return true
	end
	return false
end

--LOG10
EXPR_Parser.funcTable["log10"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.log10(a) )
		return true
	end
	return false
end

--MODF
EXPR_Parser.funcTable["modf"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.modf(a) )
		return true
	end
	return false
end

--PI
EXPR_Parser.funcTable["pi"] = function ( opStack, andStack )
	andStack:push( math.pi() )
	return true
end

--RAD
EXPR_Parser.funcTable["rad"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.rad(a) )
		return true
	end
	return false
end

--RANDOM
EXPR_Parser.funcTable["rand"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.random(a) )
		return true
	end
	return false
end

--SIN
EXPR_Parser.funcTable["sin"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.sin(a) )
		return true
	end
	return false
end

--SINH
EXPR_Parser.funcTable["sinh"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.sinh(a) )
		return true
	end
	return false
end

--SQRT
EXPR_Parser.funcTable["sqrt"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.sqrt(a) )
		return true
	end
	return false
end

--TAN
EXPR_Parser.funcTable["tan"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.tan(a) )
		return true
	end
	return false
end

--TANH
EXPR_Parser.funcTable["tanh"] = function ( opStack, andStack )
	local a = andStack:pop()
	if( a ) then
		andStack:push( math.tanh(a) )
		return true
	end
	return false
end
