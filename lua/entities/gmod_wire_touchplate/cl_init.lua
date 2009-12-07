include('shared.lua')

-- get rid of outline
function ENT:Draw()
	self:DrawModel()
end
