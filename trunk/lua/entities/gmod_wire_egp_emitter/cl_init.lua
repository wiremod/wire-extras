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
	
	self.Render = {
	--EGP HOME SCREEN!
	--By mattwd0526
		--Dimond
		--{image="box",X=0,Y=0,W=512,H=512,material="",Ang=0,R=10, G=10, B=10, A=255},
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


function ENT:Receive(um)
	if self.FirstDraw == true then
		self.Render = {}
		self.FirstDraw  = false
	end
	self:ReceiveEntry(um)
end

function ENT:Draw()
	self.Entity.DrawEntityOutline = function() end
	self.Entity:DrawModel()
	local pos = self:LocalToWorld( Vector( -64, 0, 135 ) )
	local ang = self:LocalToWorldAngles( Angle(0,0,90) )
	cam.Start3D2D( pos , ang , 0.25 )
		render.SetScissorRect(  0,  0,  512,  512,  true )
		EGP.Process(self)
	cam.End3D2D()

	
end
