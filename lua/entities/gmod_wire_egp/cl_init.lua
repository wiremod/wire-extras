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
	--EGP HOME SCREEN!
	--By mattwd0526
		--Dimond
		{image="box",X=0,Y=0,W=512,H=512,material="",Ang=0,R=10, G=10, B=10, A=255},
		{image="box",X=256,Y=256,W=362,H=362,material="",Ang=135,R=75, G=75, B=200, A=255},
		{image="box",X=256,Y=256,W=340,H=340,material="",Ang=135,R=10, G=10, B=10, A=255},
		{image="text",X=229,Y=28,text="E",falign=0,fsize=100,fid=4,R=200, G=50, B=50, A=255},
		{image="text",X=50,Y=200,text="G",falign=0,fsize=100,fid=4,R=200, G=50, B=50, A=255},
		{image="text",X=400,Y=200,text="P",falign=0,fsize=100,fid=4,R=200, G=50, B=50, A=255},
		{image="text",X=228,Y=375,text="2",falign=0,fsize=100,fid=4,R=200, G=50, B=50, A=255},
		{image="box",X=256,Y=256,W=256,H=256,material="expression 2/cog",Ang=45,R=255, G=50, B=50, A=255},
		{image="box",X=128,Y=241,W=256,H=30,material="",Ang=0,R=10, G=10, B=10, A=255},
		{image="box",X=241,Y=128,W=30,H=256,material="",Ang=0,R=10, G=10, B=10, A=255},
		{image="circle",X=256,Y=256,W=70,H=70,material="",R=255,G=50,B=50,A=255},
		{image="box",X=256,Y=256,W=362,H=362,material="gui/center_gradient",Ang=135,R=75, G=75, B=200, A=75},
		{image="box",X=256,Y=256,W=362,H=362,material="gui/center_gradient",Ang=45,R=75, G=75, B=200, A=75}
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
			EGP.Process(self)
		end)
		self.NeedsRender = false
	end
	
	self.GPU:Render()
	Wire_Render(self.Entity)
end
