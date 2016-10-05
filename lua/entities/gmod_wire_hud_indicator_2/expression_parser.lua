include( "util/tables.lua" )
include( "expressions/expr_tokenizer.lua" )
include( "expressions/expr_stack.lua" )

funcTable = {}
binaryFuncs = {}

--Runtime Code
EXPR_Parser = {}
EXPR_Parser.binaryFuncs = {}
EXPR_Parser.funcTable = {}

include( "expressions/libs/mathlib.lua" )
include( "expressions/libs/stringlib.lua" )
include( "expressions/libs/logiclib.lua" )
include( "expressions/libs/corelib.lua" ) --Corelib must be loaded LAST so it overwrites any user mods!

print( "[II]", "Loaded libraries..." )


function EXPR_Parser:new()
	local obj = {}
	setmetatable( obj, {__index = EXPR_Parser} )
	obj.expr = EXPR_TOKENIZER:new()
	obj.opStack = EXPR_Stack:new()
	obj.andStack = EXPR_Stack:new()

	print("[II]", "Built a new expression parser!")

	return obj
end

function EXPR_Parser:DoOp( context )
	local doOp = self.opStack:pop()
	
	-- Build a new context
	local newContext = context or {}
	newContext.min = 0
	newContext.max = 100
	
	if( context.x and context.y and context.w and context.h ) then
		if( doOp.depth == 0 ) then			-- x --
			newContext.min = context.x
			newContext.max = context.x+context.w
			
		elseif( doOp.depth == 1 ) then		-- y --
			newContext.min = context.y
			newContext.max = context.y+context.h
			
		end
	end

	if( self.binaryFuncs[doOp.value] ) then
	
		--Make an operation cost us something!
		HUD_System.opCount = HUD_System.opCount + 1
	
		return self.binaryFuncs[doOp.value]( self.opStack, self.andStack, newContext )
		
	elseif( doOp.value == "#" ) then
		return true
	end

	print("[EE] Unknown operator! --> ", "'"..tostring(doOp.value).."'" )
	self.opStack:push( doOp )
	return nil
end

function EXPR_Parser:DoFunc( context )
	local doOp = self.opStack:pop()
	
	-- Build a new context
	local newContext = context or {}
	newContext.min = 0
	newContext.max = 100
	
	if( context.x and context.y and context.w and context.h ) then
		if( doOp.depth == 0 ) then			-- x --
			newContext.min = context.x
			newContext.max = context.x+context.w
			
		elseif( doOp.depth == 1 ) then		-- y --
			newContext.min = context.y
			newContext.max = context.y+context.h
			
		end
	end

	if( self.funcTable[doOp.value] ) then
	
		--Make a function cost us something!
		HUD_System.opCount = HUD_System.opCount + 1
	
		return self.funcTable[doOp.value]( self.opStack, self.andStack, newContext )
	end

	self.opStack:push( doOp )
	return nil
end

function EXPR_Parser:Calc( input, context, expectedType )
	local result = result or 0
	local ops = {}
	context = context or {}
	input = tostring(input) or ""
	
	ops["%"] = 10
	ops["^"] = 4
	ops["/"] = 3
	ops["*"] = 2
	ops["+"] = 1
	ops["-"] = 0
	ops["{"] = -2
	ops[","] = -3
	ops["#"] = -4

	self.expr:setInput( input )

	math.randomseed( os.time() )

	--Initial clear + sentinal
	self.opStack:clear()
	self.andStack:clear()
	self.opStack:push( {value="#", type="SENTINAL", depth=0 } )

	while true do
		local tok = self.expr:getNextToken()
		if ( tok == nil ) then break end
		
		--print( "Read: ", tok.type )
		-- PrintTitledTable( "Read: ", tok )
		
		--Operand
		if( tok.type == "VALUE" or tok.type == "COLLECTION" ) then
			self.andStack:push( tok )

		--Operator
		elseif( tok.type == "OP" ) then
			tok.depth = self.opStack:peekTop().depth
			
			--If we have operators in the stack...
			if( self.opStack:size() > 0 ) then
				local lastOp = self.opStack:peekTop()

				--If the operator has lower precidence than the last, do it!
				if( ops[tok.value] < ops[lastOp.value] ) then
					while( self.opStack:peekTop().value ~= "#" and self.opStack:peekTop().value ~= "," and self.opStack:peekTop().value ~= "{" ) do
						if( self:DoOp( context ) == nil ) then
							return nil
						end
					end
				end

			end

			self.opStack:push( tok )

		--Push left-braces onto the stack as a sentinal...
		elseif( tok.type == "OPENBRACE" ) then
			self.opStack:push( {value="#", char=tok.value, type=tok.type} )
		
		--Collapse the braces!
		elseif( tok.type == "CLOSEBRACE" ) then
			
			while( self.opStack:peekTop().value ~= "#" and self.opStack:peekTop().value ~= "{" ) do
				
				--Collapsing arrays costs!
				HUD_System.opCount = HUD_System.opCount + 1
				
				if( self.opStack:peekTop().value == "," ) then
					self.opStack:pop()
				else
					if( self:DoOp( context ) == nil ) then
						return nil
					end
				end
			end
			self.opStack:pop()

			if( self.funcTable[self.opStack:peekTop().value] ) then
				self:DoFunc( context )
			end

		--If its a function, just push it for now...
		elseif( tok.type == "FUNC" ) then
			tok.depth = self.opStack:peekTop().depth
			
			self.opStack:push( tok )
		
		--Groups (vectors, mainly...)
		elseif( tok.type == "OPENGROUP" ) then
			tok.depth = 0 --Reset the depth count for this new group
			self.opStack:push( tok )
			self.andStack:push( tok )
		
		elseif( tok.type == "BREAK" ) then
			--Evaluate, we're at the end of a section!
			
			tok.depth = self.opStack:peekTop().depth + 1
			
			while( self.opStack:peekTop().value ~= "#" and self.opStack:peekTop().value ~= "," and self.opStack:peekTop().value ~= "{" ) do
				if( self:DoOp( context ) == nil ) then
					return nil
				end
			end
			
			self.opStack:push( tok )
		
		elseif( tok.type == "CLOSEGROUP" ) then
			--Compact the operands until we get a "{"... REMEMBER TO REMOVE "," AND "{" OPS AS WELL!
			local result = {}
			
			while( self.opStack:peekTop().value ~= "#" and self.opStack:peekTop().value ~= "," and self.opStack:peekTop().value ~= "{" ) do
				if( self:DoOp( context ) == nil ) then
					print("[EE]\tOperation failed to execute!")
					return nil
				end
			end
			
			while( self.andStack:peekTop().value ~= "{" and self.andStack:peekTop().value ~= "}" ) do
				if( self.andStack:size() == 0 ) then
					print("[EE]\tUnexpected EOL!")
					self.opStack:print("opStack")
					self.andStack:print("andStack")
					return nil
				end
				
				if( self.opStack:peekTop().value == "," ) then
					self.opStack:pop() --Discard the BREAK char.
				else
					table.insert( result, 1, self.andStack:pop() )
				end
				
			end
			
			self.andStack:pop()	--Removes the "{" on the AND stack!
			self.opStack:pop()	--Removes the "{" on the OP stack!
			self.andStack:push( {value=result, type="COLLECTION"} )
		
		--Unknown symbol! STOP!
		else
			print("[EE]\tUnknown (but tokenized) symbol!")
			print("[EE]\tTrace: ", tok.type, tok.value)
			self.opStack:print("opStack")
			self.andStack:print("andStack")
			print( "" )
			print("[EE]\tLibrary mismatch?")
			
			return nil
		end
		
		--self.opStack:print("opStack")
		--self.andStack:print("andStack")
		
	end

	while self.opStack:size() > 1 do
		if( self:DoOp( context ) == nil ) then
			print( "[EE] More than one op in the stack, but no operands left!" )
			return nil
		end
	end
	
	if( self.andStack:peekTop() ~= nil and self.andStack:peekTop().value ~= nil ) then
	
		if( expectedType and type(self.andStack:peekTop().value) != expectedType ) then
			return nil
		end
		
		local result = self.andStack:pop()
		
		if( type(result.value) == "table" ) then
			return result, table.maxn(result.value)
		else
			return result
		end
	end
	return nil
end
