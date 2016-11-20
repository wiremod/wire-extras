--Note - code by night-eagle withing this file

include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

ENT.widgetLookup = {}
ENT.panelEnabled = false
ENT.clpanelEnabled = false
ENT.schemeTable = {}
ENT.panelWoken = false
ENT.panelInitEnable = false
ENT.drawParams = {}
ENT.lastDrawn = true
ENT.stillDraw = false


function ENT:Think()
end



function ENT:Draw()
	self.Entity:DrawModel()
	if (!self.panelInitEnable or !self.panelWoken or !self.currentScheme) then return true end	--!self.currentScheme is temp safeguard
	local showAlways = false
	
	local ang = self.Entity:GetAngles()
	local rot = Vector(-90,90,0)
	ang:RotateAroundAxis(ang:Right(), rot.x)
	ang:RotateAroundAxis(ang:Up(), rot.y)
	ang:RotateAroundAxis(ang:Forward(), rot.z)
	local pos = self.Entity:GetPos() + (self.Entity:GetForward() * self.z)
	
	cam.Start3D2D(pos, ang, self.res)
		local trace = {}
			trace.start = LocalPlayer():GetShootPos()
			trace.endpos = (LocalPlayer():GetAimVector() * self.workingDistance) + trace.start
			trace.filter = LocalPlayer()
		local trace = util.TraceLine(trace)
		--Msg("sd = "..tostring(self.stillDraw)..",sa = "..tostring (showAlways).."\n")
		if (trace.Entity == self.Entity or self.stillDraw or showAlways) then	
			local pos = self.Entity:WorldToLocal(trace.HitPos)
			local cx = (self.x1 - pos.y) / (self.x1 - self.x2)
			local cy = (self.y1 - pos.z) / (self.y1 - self.y2)
			
			surface.SetDrawColor(self.currentScheme.background.r, self.currentScheme.background.g, self.currentScheme.background.b, 255)
			surface.DrawRect(self.XdrawOffs, self.YdrawOffs, self.XdrawCoef * self.drawParams.screenWidth, self.YdrawCoef * self.drawParams.screenHeight)
			
			for k, modu in ipairs(self.pWidgets) do
				--Msg(string.format("drawing widget: x=%d, y=%d, h=%d, w=%d. startx=%d, starty=%d, endx=%d, endy=%d", modu.X, modu.Y, modu.modType.height, modu.modType.width, x + modu.X, y + modu.Y, x + modu.X + modu.modType.width, y + modu.Y + modu.modType.height))
				if (modu.visible) then
					modu.modType.modDraw(self.Entity, modu)
				end
			end
			
			if (cx >= 0 and cy >= 0 and cx <= 1 and cy <= 1) then
				surface.SetDrawColor (self.currentScheme.cursor.r, self.currentScheme.cursor.g, self.currentScheme.cursor.b, 255)
				surface.SetTexture (surface.GetTextureID ("gui/arrow"))
				surface.DrawTexturedRectRotated (self.x + (self.w * cx) + self.ox, self.y + (self.h * cy) + self.oy, 16, 16, 45)
			end
			
			self.lastDrawn = (trace.Entity == self.Entity)
		
		else
			if self.lastDrawn and not self.stillDraw then
				--Msg("starting timer\n")
				self.lastDrawn = false
				self.stillDraw = true
				timer.Create("drawFadeT"..tostring(self:EntIndex()), 5, 1, endDrawTimer, self.Entity)
				--timer.Simple(3, endDrawTimer, self.Entity)
				timer.Start("drawFadeT"..tostring(self:EntIndex()))
			end
		end
		
	cam.End3D2D()
	--end night-eagle's code
	if (self:HasWire()) then
		Wire_Render(self.Entity)
	end
end

function endDrawTimer(ent)
	if not IsValid( ent ) then return end

	--Msg("endt\n")
	--ent.lastDrawn = true
	ent.stillDraw = false
	timer.Destroy("drawFadeT"..tostring(ent:EntIndex()))  
end


function MakeFonts()
	--local fontSize = 380
	if (!guiPfontsMade) then
		guiPfontsMade = true
		local fontSize = 280
		for i = 1, 15 do
			surface.CreateFont( "guipfont" .. i, {font = "coolvetica", size = fontSize / i, weight = 400, antialias = false, additive = false} )
		end
	end
end

--hmm?
function ENT:IsTranslucent()
	return true
end
