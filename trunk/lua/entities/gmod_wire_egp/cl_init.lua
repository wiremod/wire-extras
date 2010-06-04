include('shared.lua')

local function validEGP(ent)
	if not ValidEntity(ent) then return false end
	if not ent.Render then return false end
	return true
end

function ENT:Initialize()
	self:InitializeShared()
	
	self.GPU = WireGPU(self.Entity)
	self.Render = EGP.HomeScreen
	
	self.FirstDraw = true
	self.NeedsRender = true
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

function ENT:Receive(um)
	if self.FirstDraw then
		self.Render = {}
		self.FirstDraw = nil
	end
	self:ReceiveEntry(um)
	self.NeedsRender = true
end

function ENT:Draw()
	self.Entity.DrawEntityOutline = function() end
	self.Entity:DrawModel()
	if self.NeedsRender then
		self.GPU:RenderToGPU(function()	
			render.Clear( 0, 0, 0, 0 )
			EGP.Process(self)
		end)
		self.NeedsRender = false
	end
	
	self.GPU:Render()
	Wire_Render(self.Entity)
end

