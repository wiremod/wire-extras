include('shared.lua')

function ENT:Initialize()
	self.GPU = GPULib.WireGPU( self )

	self.RenderTable = {}
	self:EGP_Update( EGP.HomeScreen )
end

function ENT:EGP_Update( Table )
	self.NeedsUpdate = true
	self.NextUpdate = Table
end

function ENT:_EGP_Update( bool )
	if (!bool) then return end
	self.NeedsUpdate = nil
	local Table = self.NextUpdate or self.RenderTable
	if (Table) then
		self.GPU:RenderToGPU( function()
			render.Clear( 0, 0, 0, 0 )
			surface.SetDrawColor(0,0,0,255)
			surface.DrawRect(0,0,512,512)
			for k,v in ipairs( Table ) do 
				if (v.parent and v.parent != 0) then
					local x, y, angle = EGP:GetGlobalPos( self, v.index )
					EGP:EditObject( v, { x = x, y = y, angle = angle } )
				end
				local oldtex = EGP:SetMaterial( v.material )
				v:Draw() 
				EGP:FixMaterial( oldtex )
			end
		end)
	end
end

function ENT:Draw()
	self.Entity.DrawEntityOutline = function() end
	self.Entity:DrawModel()
	Wire_Render(self.Entity)
	self:_EGP_Update( self.NeedsUpdate )
	self.GPU:Render()
end

function ENT:OnRemove()
	self.GPU:Finalize()
end