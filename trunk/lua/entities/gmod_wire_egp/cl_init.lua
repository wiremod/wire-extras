--ToDo: add angle and texture
--Note: anybody that knows how to do this pleae do.
include('shared.lua')

local function validEGP(ent)
	if not ValidEntity(ent) then return false end
	if not ent.Render then return false end
	return true
end

function ENT:Initialize()
	self:InitializeShared()
	
	self.GPU = WireGPU(self.Entity)
	self.Render = {
		{
			image = "box",
			X = 100,
			Y = 100,
			W = 300,
			H = 300,
			R = 255,
			G = 0,
			B = 0,
			A = 255,
			material = "expression 2/cog"
		},
		{
			image = "text",
			X = 256,
			Y = 200,
			R = 255,
			G = 0,
			B = 0,
			A = 0,
			text = "EGP",
			fsize = 90,
			fid = 4,
			falign = 1,
		},
		{
			image = "text",
			X = 256,
			Y = 202,
			R = 255,
			G = 0,
			B = 0,
			A = 255,
			text = "EGP",
			fsize = 87,
			fid = 4,
			falign = 1,
		}
	}
	
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
			local RatioX = 1
			local w = 1024
			local h = 1024
			--add changable backround colour some time.
			--render.SetViewPort(0, 0, w, h) --test
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(0, 0, w, h)
			EGP.Process(self.Render)
		end)
		self.NeedsRender = false
	end
	
	self.GPU:Render()
	Wire_Render(self.Entity)
end
