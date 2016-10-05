-------------------------------
-- Core HML tags for HML 1.0 --
-------------------------------
--
-- DO NOT EDIT!
--
-- Put custom tag definitions in lua files in this DIR instead!
-- Moggie100
--


-----------------
-- HML itself! --
-----------------
HMLRenderer.coreTags["hml"] = function( self )
	
	--Check if we can run! (BETA)
	if( HUD_System.opCount > HUD_System.maxOps ) then return false end
	HUD_System.opCount = HUD_System.opCount + 1
	
	
	--For each group, run the functions! (create them if required...)--
	if( self.empty ~= 1 ) then
		for k, v in ipairs(self) do
			if( type(v.tag) == "string" ) then
				v.tagName = v.tag
				v.tag = HMLRenderer.coreTags[v.tag]
			end
			v.xOffset = 0
			v.yOffset = 0
			v.width = surface.ScreenWidth()
			v.height = surface.ScreenHeight()
			
			if( type(v.tag) == "function" ) then
				status = v:tag()
				if( !status or type(status) == "string" ) then
					return "HML > " ..tostring(status)
				end
			else
				return "HML > Unknown tag! <" ..tostring(v.tagName).. "> has no handler!"
			end
		end
	end
	
	return true
end

--------------------------------------------
-- Shows the status of THIS HUD indicator --
--------------------------------------------
HMLRenderer.coreTags["status"] = function ( self )
	HUD_System.showStatus = true
	return true
end
