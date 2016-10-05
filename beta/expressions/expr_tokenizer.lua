EXPR_TOKENIZER = {}

function EXPR_TOKENIZER:new()
	local obj = {}
	setmetatable( obj, {__index = EXPR_TOKENIZER} )
	
	--Recognised patterns
	obj.pattern = {}
	obj.pattern.digit = "(%-?)(%d+%.?%d*)(%%?)"
	obj.pattern.input = "(.?#%u[%w_]+)"
	obj.pattern.op = "([%^%+%-%*%/%\\])"
	obj.pattern.func = "([%a_]+)"
	
	--The input to consume
	obj.input = ""
	obj.token = nil

	return obj
end

function EXPR_TOKENIZER:setInput( newInput )
	self.input = newInput:gsub( "(%s)", "" )
end

function EXPR_TOKENIZER:getNextToken()


	if( self.input:match( "^%s*(%()" ) ) then
		self.input = self.input:sub( 2 )
		return {type="OPENBRACE", value="("}
	
	elseif( self.input:match( "^%s*(%))" ) ) then
		self.input = self.input:sub( 2 )
		return {type="CLOSEBRACE", value=")"}

	elseif( self.input:match( "^%s*"..self.pattern.func ) ) then
		local func = self.input:match( "^([%a_]+)" )
		self.input = self.input:sub( func:len()+1 )
		return {type="FUNC", value=func}
		
	elseif( self.input:match( "^%s*"..self.pattern.input ) ) then
		print("INPUT")
		local name = self.input:match( "^%s*"..self.pattern.input )
		self.input = self.input:sub( name:len()+1 )
		return {type="VALUE", value="4"}
	
	elseif( self.input:match( "^%s*"..self.pattern.op ) ) then
		local op = self.input:match( self.pattern.op )
		self.input = self.input:sub( 2 )
		
		if ( op == "+" ) then
			return {type="OP", value="+"}
		
		elseif( op == "-" ) then
			return {type="OP", value="-"}
		
		elseif( op == "*" ) then
			return {type="OP", value="*"}
		
		elseif( op == "\\" or op == "/" ) then
			return {type="OP", value="/"}
		
		elseif( op == "^" ) then
			return {type="OP", value="^"}
		
		end
		
		print("ERR! Got what appears to be an operator... but couldn't recognise it!")
		return nil
	
	elseif( self.input:match( "^%s*"..self.pattern.digit ) ) then
		local sign, magnitude, percent = self.input:match( self.pattern.digit )
		self.input = self.input:sub( (sign..magnitude..percent):len()+1 )
		
		return {type="VALUE", value=tonumber(sign..magnitude)}
	
	end
	
	if( self.input:len() > 0 ) then
		print("ERR! Untokenable input!")
	end
	
	return nil
end
