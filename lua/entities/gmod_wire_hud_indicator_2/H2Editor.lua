include( "parser/HMLParser.lua" )

H2Editor = {}

function H2Editor:new( newFile )

	if( newFile == nil ) then return nil end

	local obj = {}
	setmetatable( obj, {__index = H2Editor} )
	obj.file = newFile


	self.panel = vgui.Create( "Expression2EditorFrame" )
	self.panel:Setup( "<HML /> Editor", "HUD2")
	self.panel:Center()
	self.panel:SetV( true )
	self.panel:MakePopup()
	self.panel.chip = chip
	self.panel.tool = self
	self.panel:SetCode("<hml>\n\n<!-- Code here! -->\n\n</hml>")

	return obj
end


function H2Editor:open( newFile )
	self.file = newFile

	GAMEMODE:AddNotify('<HML /> Opening editor...', NOTIFY_GENERIC, 7);

	--Customize various stuff--
	function self.panel:SaveFile(Line, close)
		self:ExtractName()
		if(close and self.chip) then
			if(tool.HUD_Validate(HUD_EditorPanel:GetCode())) then return end
			--tool.HUD_SyncAndUpload()
			self:Close()
		return end
		if(!Line or Line == self.Location .. "/" .. ".txt") then
			Derma_StringRequest( "Save to New File", "", "filename",
			function( strTextOut )
				self:SaveFile( self.Location .. "/" .. string.Replace(strTextOut," ","_") .. ".txt", close )
			end )
		return end
		file.Write(Line , self:GetCode())
		if(!self.chip) then self:ChosenFile(Line) end
		if(close) then self:Close() end

		GAMEMODE:AddNotify('<HML /> Saved!', NOTIFY_GENERIC, 7);
	end

end
