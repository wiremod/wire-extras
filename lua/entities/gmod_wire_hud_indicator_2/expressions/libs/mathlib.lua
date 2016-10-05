print("[II]", "Loading math library...")

--ABS
EXPR_Parser.funcTable["abs"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.abs(a.value)} )
		return true
	end
	return false
end

--ACOS
EXPR_Parser.funcTable["acos"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.acos(a.value)} )	
		return true
	end
	return false
end

--ASIN
EXPR_Parser.funcTable["asin"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.asin(a.value)} )
		return true
	end
	return false
end

--ATAN
EXPR_Parser.funcTable["atan"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.atan(a.value)} )
		return true
	end
	return false
end

--ATAN2
EXPR_Parser.funcTable["atan2"] = function ( opStack, andStack )
	local b = andStack:pop("number")
	local a = andStack:pop("number")
	if( a and b ) then
		andStack:push( {type="VALUE", value=math.atan2(a.value,b.value)} )
		return true
	end
	return false
end

--CEIL
EXPR_Parser.funcTable["ceil"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.ceil(a.value)} )
		return true
	end
	return false
end

EXPR_Parser.funcTable["cos"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.cos(a.value)} )
		return true
	end
	return false
end

--COSH
EXPR_Parser.funcTable["cosh"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.cosh(a.value)} )
		return true
	end
	return false
end

--DEG
EXPR_Parser.funcTable["deg"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.deg(a.value)} )
		return true
	end
	return false
end

--EXP
EXPR_Parser.funcTable["exp"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.exp(a.value)} )
		return true
	end
	return false
end

--FLOOR
EXPR_Parser.funcTable["floor"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.floor(a.value)} )
		return true
	end
	return false
end

--FMOD
EXPR_Parser.funcTable["fmod"] = function ( opStack, andStack )
	local b = andStack:pop("number")
	local a = andStack:pop("number")
	if( a and b ) then
		andStack:push( {type="VALUE", value=math.fmod(a.value,b.value)} )
		return true
	end
	return false
end

--FREXP
EXPR_Parser.funcTable["frexp"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.frexp(a.value)} )
		return true
	end
	return false
end

--LDEXP
EXPR_Parser.funcTable["ldexp"] = function ( opStack, andStack )
	local b = andStack:pop("number")
	local a = andStack:pop("number")
	if( a and b ) then
		andStack:push( {type="VALUE", value=math.ldexp(a.value,b.value)} )
		return true
	end
	return false
end

--LOG
EXPR_Parser.funcTable["log"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.log(a.value)} )
		return true
	end
	return false
end

--LOG10
EXPR_Parser.funcTable["log10"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.log10(a.value)} )
		return true
	end
	return false
end

--MODF
EXPR_Parser.funcTable["modf"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.modf(a.value)} )
		return true
	end
	return false
end

--PI
EXPR_Parser.funcTable["pi"] = function ( opStack, andStack )
	andStack:push( {type="VALUE", value=math.pi("number")} )
	return true
end

--RAD
EXPR_Parser.funcTable["rad"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.rad(a.value)} )
		return true
	end
	return false
end

--RANDOM
EXPR_Parser.funcTable["rand"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.random(a.value)} )
		return true
	end
	return false
end

--SIN
EXPR_Parser.funcTable["sin"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.sin(a.value)} )
		return true
	end
	return false
end

--SINH
EXPR_Parser.funcTable["sinh"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.sinh(a.value)} )
		return true
	end
	return false
end

--SQRT
EXPR_Parser.funcTable["sqrt"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.sqrt(a.value)} )
		return true
	end
	return false
end

--TAN
EXPR_Parser.funcTable["tan"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.tan(a.value)} )
		return true
	end
	return false
end

--TANH
EXPR_Parser.funcTable["tanh"] = function ( opStack, andStack )
	local a = andStack:pop("number")
	if( a ) then
		andStack:push( {type="VALUE", value=math.tanh(a.value)} )
		return true
	end
	return false
end
