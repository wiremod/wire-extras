HMLRenderer = {}
HMLRenderer.coreTags = {}
HMLRenderer.customTags = {}

include( "valid_fonts.lua" )

include( "tags/core.lua" )
include( "tags/primitives.lua" )
include( "tags/presets.lua" )
--include( "tags/vgui.lua" )

function HMLRenderer:new()
	local obj = {}
	setmetatable( obj, {__index = HMLRenderer} )

	obj.default = {}
	obj.default.color = {}
	obj.default.color.background = {50,50,75,100}
	obj.default.color.foreground = {255,255,255,255}
	obj.default.font = "Default"
	obj.default.clip = false
	obj.clip = false
	obj.cacheRefresh = false
	obj.inputs = {}
	obj.parser = EXPR_Parser:new()
	obj.skip = 0

	obj.renderTable = nil

	return obj
end

function HMLRenderer:SetDefaults()
	--Do nothing, stuff will happen later!
end

function HMLRenderer:SetRenderTable( newTable )
	self.renderTable = newTable
end

function HMLRenderer:GetRenderTable()
	return self.renderTable
end

function HMLRenderer:Draw()
	local t = self.renderTable
	
	if( self.skip > 0 ) then
		self.skip = self.skip - 1
		return true
	end
	
	HUD_System.showStatus = false
	
	if( SERVER ) then
		Msg("[EE]\tRenderer invoked serverside!\n")
		return true
	end

	if( t == nil ) then
		--Abort! Nothing to render!
		return true
	end

	if( type(t) ~= "table" ) then
		HMLError("Invalid variable type supplied! Expects a table!")
		self.renderTable = nil
		return false
	end

	--Set the defaults here, can be overridden with custom defaults!--
	self:SetDefaults()
	
	--For each group, run!--
	for k, v in ipairs(t) do
		if( type(v.tag) == "string" ) then
			v.tagName = v.tag
			v.tag = self.coreTags[v.tag]
		end
		v.xOffset = 0
		v.yOffset = 0
		v.width = surface.ScreenWidth()
		v.height = surface.ScreenHeight()
		
		if( type(v.tag) == "function" ) then
			status = v:tag()
			if( !status or type(status) == "string" ) then
				HMLError( "ROOT > " ..tostring(status) )
				self.skip = 500
			end
		else
			HMLError( "ROOT > Unknown tag! <" ..tostring(v.tagName).. "> has no handler!", 15 )
			self.skip = 500
		end
	end
	
	if( HUD_System.showStatus ) then
		local usage = math.floor((HUD_System.opCount/HUD_System.maxOps)*100)
		local position = { x=30, y=200 }
		
		draw.RoundedBox( 8, position.x, position.y, 320, 70, Color( 50, 50, 75, 128 ) )
		draw.DrawText( "HUD 2 Status", "default", position.x+10, position.y+10, Color(255,255,255,255), TEXT_ALIGN_LEFT )
		draw.DrawText( "OpCount: " ..tostring(HUD_System.opCount).. " of " ..tostring(HUD_System.maxOps), "ConsoleText", position.x+10, position.y+35, Color(255,255,255,255), TEXT_ALIGN_LEFT )
		draw.DrawText( "Usage: " ..tostring(usage).. "%", "ConsoleText", position.x+10, position.y+45, Color(255,255,255,255), TEXT_ALIGN_LEFT )
	end
	
	return true
end
