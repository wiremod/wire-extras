-- It should be noted that token indexes are unique per pass, and are not ENSURED to be contiguous!

EXPR_TOKENIZER = {}

function EXPR_TOKENIZER:new()
	local obj = {}
	setmetatable( obj, {__index = EXPR_TOKENIZER} )

	--Recognised patterns
	obj.pattern = {}
	obj.pattern.digit = "(%-?)(%d+%.?%d*)"
	obj.pattern.op = "([%^%+%-%*%/%\\])"
	obj.pattern.func = "([%a_%%]+)"
	obj.pattern.input = "([234sca]?)@(%u[%w_]+)"

	--The input to consume
	obj.input = ""
	obj.token = nil
	obj.line = 1
	obj.tokenIndex = 0

	return obj
end

-- Sets the string to be read.  This is consumed internally upon tokenization!
function EXPR_TOKENIZER:setInput( newInput )
	self.input = newInput
	self.tokenIndex = 0
	
	return {type="VALUE", value=0, line=self.line, token=self.tokenIndex}
end

-- Does a lookup for the named/typed variable in the local lookup table, if set, else returns '0'
function EXPR_TOKENIZER:getInputValue( name )
	local value = nil
	
	--Make a function cost us something!
	HUD_System.opCount = HUD_System.opCount + 5
	
	if( HUD_System.entityInputs ~= nil and type(HUD_System.entityInputs) == "table" and HUD_System.entityInputs[name] ~= nil ) then
		value = HUD_System.entityInputs[name]
	end
	
	return value
end

function EXPR_TOKENIZER:getNextToken()
	
	self.tokenIndex = self.tokenIndex + 1
	
	--print("INPUT: ", self.input )
	
	--This is a special edge case, in case it ever happens again - because I cant find where its being caused from...
	if( type(self.input) == "number" ) then
		local buffer = self.input
		self.input = ""
		return {type="VALUE", value=buffer, line=self.line, token=self.tokenIndex}
	end
	
	if( self.input:match( "^%s*\n" ) ) then
		self.line = self.line + 1
		
		return self.getNextToken()
		
	elseif( self.input:match( "^%s*(%{)" ) ) then
		local _start, _end, found = self.input:find( "^%s*(%{)" )
		self.input = self.input:sub( _end+1 )
		return {type="OPENGROUP", value="{", line=self.line, token=self.tokenIndex}
	
	elseif( self.input:match( "^%s*(%})" ) ) then
		local _start, _end, found = self.input:find( "^%s*(%})" )
		self.input = self.input:sub( _end+1 )
		return {type="CLOSEGROUP", value="}", line=self.line, token=self.tokenIndex}
	
	elseif( self.input:match( "^%s*(,)" ) ) then
		local _start, _end, found = self.input:find( "^%s*(,)" )
		self.input = self.input:sub( _end+1 )
		return {type="BREAK", value=",", line=self.line, token=self.tokenIndex}
		
	elseif( self.input:match( "^%s*(%()" ) ) then
		local _start, _end, found = self.input:find( "^%s*(%()" )
		self.input = self.input:sub( _end+1 )
		return {type="OPENBRACE", value="(", line=self.line, token=self.tokenIndex}

	elseif( self.input:match( "^%s*(%))" ) ) then
		self.input = self.input:sub( 2 )
		return {type="CLOSEBRACE", value=")", line=self.line, token=self.tokenIndex}
	
	elseif( self.input:match( "^%s*"..self.pattern.input ) ) then
		local _start, _end, type, name = self.input:find( self.pattern.input )
		self.input = self.input:sub( _end+1 )
		
		local newToken = self:getInputValue( name ) or { type="VALUE", value=0 }
		newToken.line = self.line
		newToken.token = self.tokenIndex
		
		return newToken

	elseif( self.input:match( "^%s*"..self.pattern.func ) ) then
		local _start, _end, func = self.input:find( "^%s*"..self.pattern.func )
		self.input = self.input:sub( _end+1 )
		return {type="FUNC", value=func, line=self.line, token=self.tokenIndex}

	elseif( self.input:match( "^%s*"..self.pattern.op ) ) then
		local _start, _end, op = self.input:find( self.pattern.op )
		self.input = self.input:sub( _end+1 )

		if ( op == "+" ) then
			return {type="OP", value="+", line=self.line, token=self.tokenIndex}

		elseif( op == "-" ) then
			return {type="OP", value="-", line=self.line, token=self.tokenIndex}

		elseif( op == "*" ) then
			return {type="OP", value="*", line=self.line, token=self.tokenIndex}

		elseif( op == "\\" or op == "/" ) then
			return {type="OP", value="/", line=self.line, token=self.tokenIndex}

		elseif( op == "^" ) then
			return {type="OP", value="^", line=self.line, token=self.tokenIndex}

		end

		print("ERR! Got what appears to be an operator... but couldn't recognise it!")
		return nil

	elseif( self.input:match( "^%s*"..self.pattern.digit ) ) then
		local _start, _end, sign, magnitude = self.input:find( self.pattern.digit )
		self.input = self.input:sub( _end+1 )
		
		if( sign == "-" ) then
			return {type="VALUE", value=0-tonumber(magnitude), line=self.line, token=self.tokenIndex}
		else
			return {type="VALUE", value=tonumber(magnitude), line=self.line, token=self.tokenIndex}
		end
	
	elseif( self.input:match( "^%s*([\"'])(.-)%1" ) ) then
		local _start, _end, _quote, quotedPart = string.find(self.input, "([\"'])(.-)%1")
		
		self.input = self.input:sub( _end+1 )
		
		--return nil
		return {type="VALUE", value=quotedPart, line=self.line, token=self.tokenIndex}
	
	end

	if( self.input:len() > 0 ) then
		local _start, _end, spaces = string.find( self.input, "^(%s+)$" )
		if( spaces == self.input ) then
			return nil
		end
		print("[EE]\tUntokenable input!")
		print("[EE]\tRemaining string: " .. self.input )
	end

	return nil
end
