--	gui Panel Test entity - greenarrow

include('shared.lua')

function ENT:Initialize()
	guiP_PanelInit(self.Entity, 200, 200)		-- Initialize panel
	self:BuildPanel()							-- calls function in shared.lua (in this in test entity, not the library)
end
