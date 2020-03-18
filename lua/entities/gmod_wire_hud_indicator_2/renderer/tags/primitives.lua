------------------------------------
-- Primitive HML tags for HML 1.0 --
------------------------------------
--
-- DO NOT EDIT!
--
-- Put custom tag definitions in lua files in this DIR instead!
-- Moggie100
--

----------------
-- Rectangles --
----------------
HMLRenderer.coreTags["rect"] = function ( self )
	local start = { x = 0, y = 0, visible=false }
	local finish = { x = 0, y = 0, visible=false }
	local color = { r = 255, g = 255, b = 255, a = 255 }
	local border = {}
	local rounded = false
	local roundedRadius = 8
	
	--Check if we can run! (BETA)
	if( HUD_System.opCount > HUD_System.maxOps ) then return false end
	HUD_System.opCount = HUD_System.opCount + 10
	
	-- Pick out the start coordinates
	if( self.start ) then
		start.visible = true
		local buffer =  HUD_System.eval:Calc( self.start, { x=self.xOffset, y=self.yOffset, w=self.width, h=self.height } )
		
		if( buffer and type(buffer.value) == "table" ) then
			if( buffer.value[3] ) then
				start = Vector( buffer.value[1].value, buffer.value[2].value, buffer.value[3].value ):ToScreen()
			else
				start.x = self.xOffset + buffer.value[1].value
				start.y = self.yOffset + buffer.value[2].value
			end
		end
	end
	
	-- Pick out the end coordinates
	if( self["end"] ) then
		local buffer =  HUD_System.eval:Calc( self["end"], { x=self.xOffset, y=self.yOffset, w=self.width, h=self.height } )
		
		
		if( buffer and type(buffer.value) == "table" ) then
			finish.visible = true
			
			if( buffer.value[3] ) then
				finish = Vector( buffer.value[1].value, buffer.value[2].value, buffer.value[3].value ):ToScreen()
			else
				finish.x = self.xOffset + buffer.value[1].value
				finish.y = self.yOffset + buffer.value[2].value
			end
		end
	
	-- Or a 'size' coordinate as an alternative
	elseif( self.size ) then
		local buffer =  HUD_System.eval:Calc( self.size, { x=self.xOffset, y=self.yOffset, w=self.width, h=self.height } )
		
		if( buffer and type(buffer.value) == "table" ) then
			finish.x = start.x + buffer.value[1].value
			finish.y = start.y + buffer.value[2].value
			finish.visible = true
		end
	
	-- Or even 'width'/'height' combos...
	elseif( self.width and self.height ) then
		local wBuffer =  HUD_System.eval:Calc( self.width, { x=self.xOffset, y=self.yOffset, w=self.width, h=self.height } )
		local hBuffer =  HUD_System.eval:Calc( self.height, { x=self.xOffset, y=self.yOffset, w=self.width, h=self.height } )
		
		if( wBuffer and hBuffer ) then
			finish.x = start.x + wBuffer.value
			finish.y = start.y + hBuffer.value
			finish.visible = true
		end
	end
	
	-- Inversion detection, flip the rectangle if required, else the bugger wont draw! --
	if( finish.x < start.x ) then
		local buffer = finish.x
		finish.x = start.x
		start.x = buffer
	end
	if( finish.y < start.y ) then
		local buffer = finish.y
		finish.y = start.y
		start.y = buffer
	end
	
	if( self.rounded ) then
		roundedRadius = HUD_System.eval:Calc( self.rounded ).value or 8
	end
	
	-- Check the visibilities of our coodinates (skipping this bit if we cant see it... obviously!)
	if( start.visible and finish.visible ) then
		
		-- At this point we should have enough data to render this element, except for color, so check it, as it
		-- determines what exactly is shown.
		if( self.color ) then
			local buffer =  HUD_System.eval:Calc( self.color )
			
			if( buffer and type(buffer.value) == "table" ) then
				-- Color with alpha channel!
				if( buffer.value[4] ) then
					color.r = buffer.value[1].value
					color.g = buffer.value[2].value
					color.b = buffer.value[3].value
					color.a = buffer.value[4].value
				
				-- Color with no alpha (assume opaque!)
				elseif( buffer.value[3] and buffer.value[2] and buffer.value[1] ) then
					color.r = buffer.value[1].value
					color.g = buffer.value[2].value
					color.b = buffer.value[3].value
					color.a = 255
					
				end
			end
		end
		
		if( rounded ) then
			draw.RoundedBox( roundedRadius, start.x, start.y, finish.x-start.x, finish.y-start.y, Color( color.r, color.g, color.b, color.a ) )
		else
			-- Set the color, and draw the background area!
			surface.SetDrawColor( color.r, color.g, color.b, color.a )
			surface.DrawRect( start.x, start.y, finish.x-start.x, finish.y-start.y )
		
			-- Check for a border, rendering if required!
			if( self.border ) then
				local buffer =  HUD_System.eval:Calc( self.border )
				
				if( buffer and type(buffer.value) == "table" ) then
					-- Color with alpha AND THICKNESS?!?!? :D
					if( buffer.value[5] ) then
						border.r = buffer.value[1].value
						border.g = buffer.value[2].value
						border.b = buffer.value[3].value
						border.a = buffer.value[4].value
						border.thickness = buffer.value[5].value
						
						
					-- Color with alpha channel!	
					elseif( buffer.value[4] ) then
						border.r = buffer.value[1].value
						border.g = buffer.value[2].value
						border.b = buffer.value[3].value
						border.a = buffer.value[4].value
						border.thickness = 1
					
					-- Color with no alpha (assume opaque!)
					elseif( buffer.value[3] and buffer.value[2] and buffer.value[1] ) then
						border.r = buffer.value[1].value
						border.g = buffer.value[2].value
						border.b = buffer.value[3].value
						border.a = 255
						border.thickness = 1
						
					end
				
				
					-- Draw the border! (Note: Same parameters as the area itself)
					surface.SetDrawColor( border.r, border.g, border.b, border.a )
					
					for i=0, border.thickness, 1 do
						surface.DrawOutlinedRect( start.x-i, start.y-i, finish.x-start.x+(2*i), finish.y-start.y+(2*i) )
					end
				end
			end
		end
	end
	
	--For each group, run the functions! (create them if required...)--
	if( self.empty ~= 1 ) then
		for k, v in ipairs(self) do
			if( type(v.tag) == "string" ) then
				v.tagName = v.tag
				v.tag = HMLRenderer.coreTags[v.tag]
			end
			v.xOffset = start.x
			v.yOffset = start.y
			v.width = finish.x - start.x
			v.height = finish.y - start.y
			
			if( type(v.tag) == "function" ) then
				status = v:tag()
				if( !status or type(status) == "string" ) then
					return "RECT > " ..tostring(status)
				end
			else
				return "RECT > Unknown tag! <" ..tostring(v.tagName).. "> has no handler!"
			end
		end
	end
	
	return true
end

-----------
-- Lines --
-----------
HMLRenderer.coreTags["line"] = function ( self )
	local start = { x = 0, y = 0, visible=false }
	local finish = { x = 0, y = 0, visible=false }
	local color = { r = 255, g = 255, b = 255, a = 255 }
	
	--Check if we can run! (BETA)
	if( HUD_System.opCount > HUD_System.maxOps ) then return false end
	HUD_System.opCount = HUD_System.opCount + 2
	
	-- Pick out the start coordinates
	if( self.start ) then
		start.visible = true
		local buffer =  HUD_System.eval:Calc( self.start, { x=self.xOffset, y=self.yOffset, w=self.width, h=self.height } )
		
		if( buffer and type(buffer.value) == "table" ) then
			if( buffer.value[3] ) then
				start = Vector( buffer.value[1].value, buffer.value[2].value, buffer.value[3].value ):ToScreen()
			else
				start.x = self.xOffset + buffer.value[1].value
				start.y = self.yOffset + buffer.value[2].value
			end
		end
	end
	
	-- Pick out the end coordinates
	if( self["end"] ) then
		local buffer =  HUD_System.eval:Calc( self["end"], { x=self.xOffset, y=self.yOffset, w=self.width, h=self.height } )
		
		if( buffer and type(buffer.value) == "table" ) then
			finish.visible = true
			if( buffer.value[3] ) then
				finish = Vector( buffer.value[1].value, buffer.value[2].value, buffer.value[3].value ):ToScreen()
			else
				finish.x = self.xOffset + buffer.value[1].value
				finish.y = self.yOffset + buffer.value[2].value
			end
		end
	end
	
	-- Check the visibilities of our coodinates (skipping this bit if we cant see it... obviously!)
	if( (start.visible and finish.visible) or self.clip == nil ) then
		
		-- At this point we should have enough data to render this element, except for color, so check it, as it
		-- determines what exactly is shown.
		if( self.color ) then
			local buffer =  HUD_System.eval:Calc( self.color )
			
			if( buffer and type(buffer.value) == "table" ) then
				-- Color with alpha channel!
				if( buffer.value[4] ) then
					color.r = buffer.value[1].value
					color.g = buffer.value[2].value
					color.b = buffer.value[3].value
					color.a = buffer.value[4].value
				
				-- Color with no alpha (assume opaque!)
				elseif( buffer.value[3] and buffer.value[2] and buffer.value[1] ) then
					color.r = buffer.value[1].value
					color.g = buffer.value[2].value
					color.b = buffer.value[3].value
					color.a = 255
					
				end
			end
		end
		
		-- Set the color, and draw the background area!
		surface.SetDrawColor( color.r, color.g, color.b, color.a )
		surface.DrawLine( start.x, start.y, finish.x, finish.y )
		
	end
	
	if( self.empty ~= 1 ) then
		print("[WW]", "A LINE element had subtags! Skipped!")
	end

	return true
end


---------------------------
-- Circles! Yes CIRCLES! --
---------------------------
HMLRenderer.coreTags["circle"] = function ( self )
	local position = { x=10, y=10, visible=false }
	local radius = HUD_System.eval:Calc(self.radius).value or 10
	local color = { r = 255, g = 255, b = 255, a = 255 }
	local x,y,r2
	local filled = 0
	
	if( self.filled ) then filled = HUD_System.eval:Calc(self.filled).value or 0 end
	
	-- Pick out the coordinates
	if( self.position ) then
		position.visible = true
		local buffer =  HUD_System.eval:Calc( self.position, { x=self.xOffset, y=self.yOffset, w=self.width, h=self.height } )
		
		if( buffer ) then
			if( buffer.value[3] ) then
				position = Vector( buffer.value[1].value, buffer.value[2].value, buffer.value[3].value ):ToScreen()
			else
				position.x = self.xOffset + buffer.value[1].value
				position.y = self.yOffset + buffer.value[2].value
			end
		end
		
	elseif( self.pos ) then
		position.visible = true
		local buffer =  HUD_System.eval:Calc( self.pos, { x=self.xOffset, y=self.yOffset, w=self.width, h=self.height } )
		
		if( buffer and buffer.value ) then
			if( buffer.value[3] ) then
				position = Vector( buffer.value[1].value, buffer.value[2].value, buffer.value[3].value ):ToScreen()
			else
				position.x = self.xOffset + buffer.value[1].value
				position.y = self.yOffset + buffer.value[2].value
			end
		end
	end

	
	if( position.visible or self.clip == nil ) then
		if( radius > 0 ) then
			if( self.color ) then
				local buffer =  HUD_System.eval:Calc( self.color )
				
				if( buffer and type(buffer.value) == "table" ) then
					-- Color with alpha channel!
					if( buffer.value[4] ) then
						color.r = buffer.value[1].value
						color.g = buffer.value[2].value
						color.b = buffer.value[3].value
						color.a = buffer.value[4].value
					
					-- Color with no alpha (assume opaque!)
					elseif( buffer.value[3] and buffer.value[2] and buffer.value[1] ) then
						color.r = buffer.value[1].value
						color.g = buffer.value[2].value
						color.b = buffer.value[3].value
						color.a = 255
						
					end
				end
			end
			
			surface.SetDrawColor( color.r, color.g, color.b, color.a )

			----------------------------------------
			-- Now the magic circle drawing code! --
			----------------------------------------

			if( filled == 0 ) then
				r2 = radius * radius
				surface.DrawRect( position.x, position.y + radius, 1, 1 )
				surface.DrawRect( position.x, position.y - radius, 1, 1 )
				surface.DrawRect( position.x + radius, position.y, 1, 1 )
				surface.DrawRect( position.x - radius, position.y, 1, 1 )

				y = radius
				x = 1
				y = math.sqrt(r2-1) + 0.5
				while x < y do
				
					--Check if we can run! (BETA)
					if( HUD_System.opCount > HUD_System.maxOps ) then return false end
					HUD_System.opCount = HUD_System.opCount + 1
				
					surface.DrawRect( position.x + x, position.y + y, 1, 1 )
					surface.DrawRect( position.x + x, position.y - y, 1, 1 )
					surface.DrawRect( position.x - x, position.y + y, 1, 1 )
					surface.DrawRect( position.x - x, position.y - y, 1, 1 )
					surface.DrawRect( position.x + y, position.y + x, 1, 1 )
					surface.DrawRect( position.x + y, position.y - x, 1, 1 )
					surface.DrawRect( position.x - y, position.y + x, 1, 1 )
					surface.DrawRect( position.x - y, position.y - x, 1, 1 )
					x = x + 1
					y = math.sqrt(r2 - (x*x)) + 0.5
				end

				if( x == y ) then
					surface.DrawRect( position.x + x, position.y + y, 1, 1 )
					surface.DrawRect( position.x + x, position.y - y, 1, 1 )
					surface.DrawRect( position.x - x, position.y + y, 1, 1 )
					surface.DrawRect( position.x - x, position.y - y, 1, 1 )
				end
			else
				r2 = radius * radius
				surface.DrawLine( position.x, position.y + radius, position.x, position.y - radius )
				surface.DrawLine( position.x + radius, position.y, position.x - radius, position.y )

				y = radius
				x = 1
				y = math.sqrt(r2-1) + 0.5
				while x < y do
					
					--Check if we can run! (BETA)
					if( HUD_System.opCount > HUD_System.maxOps ) then return false end
					HUD_System.opCount = HUD_System.opCount + 1
					
					surface.DrawLine( position.x + x, position.y + y, position.x + x, position.y - y )
					surface.DrawLine( position.x - x, position.y + y, position.x - x, position.y - y )
					surface.DrawLine( position.x + y, position.y + x, position.x + y, position.y - x )
					surface.DrawLine( position.x - y, position.y + x, position.x - y, position.y - x )
					x = x + 1
					y = math.sqrt(r2 - (x*x)) + 0.5
				end

				if( x == y ) then
					surface.DrawLine( position.x + x, position.y + y, position.x + x, position.y - y )
					surface.DrawLine( position.x - x, position.y + y, position.x - x, position.y - y )
				end
			end
		end
	end
	
	if( self.empty ~= 1 ) then
		print("[WW]", "A CIRCLE element had subtags! Skipped!")
	end
	
	return true
end



------------------------
-- Basic Text Drawing --
------------------------
HMLRenderer.coreTags["text"] = function ( self )
	local position	=	{ x=10, y=10, visible=false }
	local backColor	=	nil
	local textColor	=	{ r=255, g=255, b=255, a=255 }
	local myFont	=	HUD_System.eval:Calc(self.font) or "Default"
	local value		=	HUD_System.eval:Calc(self.value) or "NIL"
	
	if( myFont.value ) then myFont = myFont.value else myFont = "Default" end
	if( value.value ) then value = value.value else value = "NIL" end
	
	--Check if we can run! (BETA)
	if( HUD_System.opCount > HUD_System.maxOps ) then return false end
	HUD_System.opCount = HUD_System.opCount + 2
	
	-- Pick out the coordinates
	if( self.position ) then
		position.visible = true
		local buffer =  HUD_System.eval:Calc( self.position, { x=self.xOffset, y=self.yOffset, w=self.width, h=self.height } )
		
		if( buffer ) then
			if( buffer.value[3] ) then
				position = Vector( buffer.value[1].value, buffer.value[2].value, buffer.value[3].value ):ToScreen()
			else
				position.x = self.xOffset + buffer.value[1].value
				position.y = self.yOffset + buffer.value[2].value
			end
		end
		
	elseif( self.pos ) then
		position.visible = true
		local buffer =  HUD_System.eval:Calc( self.pos, { x=self.xOffset, y=self.yOffset, w=self.width, h=self.height } )
		
		if( buffer and buffer.value ) then
			if( buffer.value[3] ) then
				position = Vector( buffer.value[1].value, buffer.value[2].value, buffer.value[3].value ):ToScreen()
			else
				position.x = self.xOffset + buffer.value[1].value
				position.y = self.yOffset + buffer.value[2].value
			end
		end
	end


	--check if its valid, else skip+warn
	if( H2Fonts[ myFont ] ~= nil ) then
		myFont = H2Fonts[ myFont ]
	else
		HMLWarning("Invalid font " .. tostring(myFont))
		myFont = "Default"
	end

	if( self.color ) then
		local buffer =  HUD_System.eval:Calc( self.color )
		
		if( buffer and type(buffer.value) == "table" ) then
			-- Color with alpha channel!
			if( buffer.value[4] ) then
				color.r = buffer.value[1].value
				color.g = buffer.value[2].value
				color.b = buffer.value[3].value
				color.a = buffer.value[4].value
			
			-- Color with no alpha (assume opaque!)
			elseif( buffer.value[3] and buffer.value[2] and buffer.value[1] ) then
				color.r = buffer.value[1].value
				color.g = buffer.value[2].value
				color.b = buffer.value[3].value
				color.a = 255
				
			end
		end
	end
	
	if( self.background ) then
		local buffer =  HUD_System.eval:Calc( self.background )
		
		if( buffer and type(buffer.value) == "table" ) then
			backColor = {}
			
			-- Color with alpha channel!
			if( buffer.value[4] ) then
				backColor.r = buffer.value[1].value
				backColor.g = buffer.value[2].value
				backColor.b = buffer.value[3].value
				backColor.a = buffer.value[4].value
			
			-- Color with no alpha (assume opaque!)
			elseif( buffer.value[3] and buffer.value[2] and buffer.value[1] ) then
				backColor.r = buffer.value[1].value
				backColor.g = buffer.value[2].value
				backColor.b = buffer.value[3].value
				backColor.a = 255
				
			end
		end
	end

	if( position.visible ) then
		if( backColor ~= nil ) then
			draw.WordBox( 8, position.x, position.y, value, myFont, Color(backColor.r, backColor.g, backColor.b, backColor.a), Color(textColor.r, textColor.g, textColor.b, textColor.a) )
		else
			draw.DrawText( value, myFont, position.x, position.y, Color(textColor.r, textColor.g, textColor.b, textColor.a), TEXT_ALIGN_LEFT )
		end
	end


	return true
end
