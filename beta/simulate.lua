dofile( "../lua/entities/gmod_wire_hud_indicator_2/util/tables.lua" )
dofile( "expressions/expr_tokenizer.lua" )
dofile( "expressions/expr_stack.lua" )

funcTable = {}
binaryFuncs = {}

--Runtime Code
EXPR_Parser = {}
EXPR_Parser.binaryFuncs = {}
EXPR_Parser.funcTable = {}

dofile( "expressions/libs/mathlib.lua" )
dofile( "expressions/libs/corelib.lua" )

print( "[II]", "Loaded libraries..." )


function EXPR_Parser:new()
	local obj = {}
	setmetatable( obj, {__index = EXPR_Parser} )
	obj.expr = EXPR_TOKENIZER:new()
	obj.opStack = EXPR_Stack:new()
	obj.andStack = EXPR_Stack:new()

	return obj
end

function EXPR_Parser:DoOp()
	local doOp = self.opStack:pop()

	print("OP: " .. tostring(doOp) )

	if( self.binaryFuncs[doOp] ) then
		return self.binaryFuncs[doOp]( self.opStack, self.andStack )
	end

	print("ERR! Unknown operator!")
	self.opStack:push( doOp )
	return nil
end

function EXPR_Parser:DoFunc()
	local doOp = self.opStack:pop()

	print("FUNC: " .. tostring( doOp ) )

	if( self.funcTable[doOp] ) then
		return self.funcTable[doOp]( self.opStack, self.andStack )
	end

	self.opStack:push( doOp )
	return nil
end

function EXPR_Parser:Calc( input )
	local result = result or 0
	local input = input or ""
	local ops = {}
	ops["^"] = 4
	ops["/"] = 3
	ops["*"] = 2
	ops["+"] = 1
	ops["-"] = 0
	ops["#"] = -1

	self.expr:setInput( input )

	math.randomseed( os.time() )

	--Initial sentinal
	self.opStack:push( "#" )

	while true do
		local tok = self.expr:getNextToken()
		if ( tok == nil ) then break end

		--Operand
		if( tok.type == "VALUE" ) then
			self.andStack:push( tok.value )

		--Operator
		elseif( tok.type == "OP" ) then

			--If we have operators in the stack...
			if( self.opStack:size() > 0 ) then
				local lastOp = self.opStack:peekTop()

				--If the operator has lower precidence than the last, do it!
				if( ops[tok.value] < ops[lastOp] ) then
					while( self.opStack:peekTop() ~= "#" ) do
						if( self:DoOp() == nil ) then
							return nil
						end
					end
				end

			end

			self.opStack:push( tok.value )

		--Push left-braces onto the stack as a sentinal...
		elseif( tok.type == "OPENBRACE" ) then
			self.opStack:push( "#" )

		--Collapse the braces!
		elseif( tok.type == "CLOSEBRACE" ) then

			while( self.opStack:peekTop() ~= "#" ) do
				--if( DoOp() == nil ) then return nil end

				if( self:DoOp() == nil ) then
					return nil
				end
			end
			self.opStack:pop()

			if( self.funcTable[self.opStack:peekTop()] ) then
				self:DoFunc()
			end

		--If its a function, just push it for now...
		elseif( tok.type == "FUNC" ) then
			self.opStack:push( tok.value )

		--Unknown symbol! STOP!
		else
			print("ERR! Unknown symbol!")
			return nil
		end
	end

	while self.opStack:size() > 1 do
		if( self:DoOp() == nil ) then
			return nil
		end
	end

	return self.andStack:pop()
end
