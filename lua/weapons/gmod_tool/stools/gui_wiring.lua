TOOL.Category		= "Wire Extras/Tools"
TOOL.Name			= "GUI Wiring"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language.Add( "Tool.gui_wiring.name", "GUI Wiring Tool" )
	language.Add( "Tool.gui_wiring.desc", "Used to connect wirable props." )
	language.Add( "Tool.gui_wiring.0", "Primary: Select entity.\nSecondary: Deselect entity.\nReload: Open GUI." )
	
	language.Add( "Tool_gui_wiring_showports", "Show overlay of ports in HUD" )
    language.Add( "GUI_WiringTool_width", "Width:" )
    language.Add( "GUI_WiringTool_material", "Material:" )
    language.Add( "GUI_WiringTool_colour", "Color:" )
	language.Add( "undone_gui_wiring", "Undone Wire" )
end

TOOL.ClientConVar[ "showports" ] = "1"

TOOL.ClientConVar[ "width" ] = "0"
TOOL.ClientConVar[ "material" ] = "cable/cable2"
TOOL.ClientConVar[ "color_r" ] = "255"
TOOL.ClientConVar[ "color_g" ] = "255"
TOOL.ClientConVar[ "color_b" ] = "255"

cleanup.Register( "wireconstraints" )

local Components = {}

local function IsWire(entity) --try to find out if the entity is wire
	if (WireLib.HasPorts(entity)) then return true end
	--if entity.IsWire == true then return true end --this shold always be true if the ent is wire compatible, but only is if the base of the entity is "base_wire_entity" THIS NEEDS TO BE FIXED <-- CHALLENGE ACCEPTED! -Grocel
	--if entity.Inputs or entity.Outputs then return true end --this is how the wire STool gun does it
	return false
end

function TOOL:LeftClick(trace)
	local ent = trace.Entity
	if (!ent:IsValid()) then return end
	if (!IsWire(ent)) then return end
	if (CLIENT) then return true end

	
	ply_idx = self:GetOwner()
	Components[ply_idx] = Components[ply_idx] or {}

	if table.HasValue(Components[ply_idx],ent) then return end
	
	table.insert(Components[ply_idx], ent)
	
	local TmpClr = ent:GetColor()
	ent.OldColorR, ent.OldColorG, ent.OldColorB, ent.OldColorA = TmpClr.r, TmpClr.g, TmpClr.b, TmpClr.a
	ent:SetColor(Color(255,0,0,128))
	
	return true
end


function TOOL:RightClick(trace)
	local ent = trace.Entity
	if (!ent:IsValid()) then return end
	if (!IsWire(ent)) then return end
	if (CLIENT) then return true end

	ply_idx = self:GetOwner()
	if not Components[ply_idx] then return end

	for k,cmp in ipairs(Components[ply_idx]) do
		if (cmp == ent) then
			table.remove(Components[ply_idx], k)
			break
		end
	end
	
	ent:SetColor(Color(ent.OldColorR or 255, ent.OldColorG or 255, ent.OldColorB or 255, ent.OldColorA or 255))
	ent.OldColorR = nil
	ent.OldColorG = nil
	ent.OldColorB = nil
	ent.OldColorA = nil
	
	return true
end

if CLIENT then
	local DoWireTable = nil
	local UnWireTable = nil
	
	local DWLMakers = nil
	
	local DOutButtons = nil
	local DInpButtons = nil

	local CSelInp = nil
	local CSelOut = nil

	local GUIWiring_GUI = nil

	local GUIWiring_DisplayWires = nil
	
	local function GUIWiring_RecvStart()
		Components = {}
		DWLMakers = {}
		DOutButtons = {}
		DInpButtons = {}
		DoWireTable = {}
		UnWireTable = {}
		GUIWiring_DisplayWires = {}
	end
	net.Receive("GUIWiring_Start",GUIWiring_RecvStart)
	
	local function GUIWiring_RecvEntPart()
		local ent = net.ReadEntity()
		if not (ent and ent:IsValid()) then return end
		if not (IsWire(ent)) then return end

		local strMsg = net.ReadString()

		Components[ent] = von.deserialize( strMsg )
	end
	net.Receive("GUIWiring_EntPart",GUIWiring_RecvEntPart)
	
	local function GUIWiring_RecvEnd()
		GUIWiring_ShowGUI()
	end
	net.Receive("GUIWiring_End",GUIWiring_RecvEnd)
	
	local function GUIWiring_RecvWL(um)
		local ent = um:ReadEntity()
		if not (ent and ent:IsValid()) then return end
		if not (IsWire(ent)) then return end
		local btn = DWLMakers[tostring(ent)]
		if not (btn and btn:IsValid()) then return end
		local dat = von.deserialize(um:ReadString())
		btn.BtnId = "link"
		btn:SetPort(ent,dat)
		DWLMakers[tostring(ent)] = nil
	end
	net.Receive("GUIWiring_WL",GUIWiring_RecvWL)
	
	local function GUIWiring_Perform()
		RunConsoleCommand("gui_wiring_start")
		for _,v in pairs(UnWireTable) do
			RunConsoleCommand("gui_wiring_unwire",v.Input.Entity:EntIndex(),v.Input.Name)
		end
		for _,v in pairs(DoWireTable) do
			RunConsoleCommand("gui_wiring_wire",v.Input.Entity:EntIndex(),v.Input.Name,v.Output.Entity:EntIndex(),v.Output.Name)
		end
		RunConsoleCommand("gui_wiring_end")
		GUIWiring_HideGUI(true)
	end

	function GUIWiring_GetEntPortKey(ent,port)
		return tostring(ent).."_"..port
	end

	local function GUIWiring_SetDisplayWire(ient,iname,oent,oname)
		local ipk = GUIWiring_GetEntPortKey(ient,iname)
		local opk = GUIWiring_GetEntPortKey(oent,oname)
		if GUIWiring_DisplayWires[ipk] then GUIWiring_DisplayWires[ipk] = nil end
		local ib = DInpButtons[ipk]
		local ob = DOutButtons[opk]
		if not (ib and ob) then return end
		GUIWiring_DisplayWires[ipk] = {ib,ob}
	end
	local function GUIWiring_SetWire(inb,outb,alreadythere)
		if not inb then inb = CSelInp end
		if not outb then outb = CSelOut end
		if not (inb and inb:IsValid() and outb and outb:IsValid()) then return end
		if inb.Port.Type != outb.Port.Type then
			inb:SetDefaultColor()
			outb:SetDefaultColor()
			CSelInp = nil
			CSelOut = nil
			return
		end
		local ient = inb.Entity
		local iname = inb.Port.Name
		local oent = outb.Entity
		local oname = outb.Port.Name
		if not (IsWire(ient) and IsWire(oent)) then return end
		GUIWiring_SetDisplayWire(ient,iname,oent,oname)
		inb.Port.Src = oent
		inb.Port.SrcId = outb.BtnId
		if not alreadythere then
			local pvk = GUIWiring_GetEntPortKey(ient,iname)
			local pvt = {}
			pvt.Input = inb.Port
			if not pvt.Input.Entity then pvt.Input.Entity = ient end
			pvt.Output = outb.Port
			if not pvt.Output.Entity then pvt.Output.Entity = oent end
			UnWireTable[pvk] = nil
			DoWireTable[pvk] = pvt
			inb:SetDefaultColor()
			outb:SetDefaultColor()
			CSelInp = nil
			CSelOut = nil
		end
	end

	function GUIWiring_HideGUI(doperform)
		if GUIWiring_GUI and GUIWiring_GUI.Close then GUIWiring_GUI:Close(doperform) end
	end

	function GUIWiring_ShowGUI()
		GUIWiring_HideGUI()
		local wiringGui = vgui.Create("DPanel")
		GUIWiring_GUI = wiringGui
		function wiringGui:Close(doperform)
			wiringGui:Remove()
			if not doperform then
				RunConsoleCommand("gui_wiring_start")
				RunConsoleCommand("gui_wiring_end")
			end
			Components = nil
			DoWireTable = nil
			UnWireTable = nil
			DWLMakers = nil
			DOutButtons = nil
			DInpButtons = nil
			CSelInp = nil
			CSelOut = nil
			GUIWiring_GUI = nil
			GUIWiring_DisplayWires = nil
		end
		--wiringGui:SetTitle("Wiring GUI - By Doridian")
		wiringGui:SetPos(0,0)
		wiringGui:SetSize(ScrW(),ScrH())

		local wApplyCancelGUI = vgui.Create("DFrame",wiringGui)
		wApplyCancelGUI:SetTitle("Wiring GUI - By Doridian")
		wApplyCancelGUI:ShowCloseButton(false)
		wApplyCancelGUI:SetSize(215,80)
		wApplyCancelGUI:SetPos((wiringGui:GetWide()-wApplyCancelGUI:GetWide()) / 2,wiringGui:GetTall()-80)
		
		local btnW = vgui.Create("DButton",wApplyCancelGUI)
		btnW:SetText("Wire it!")
		btnW:SetSize(100,50)
		btnW:SetPos(5,25)
		function btnW:DoClick()
			GUIWiring_Perform()
			wiringGui:Close(true)
		end
		local btnC = vgui.Create("DButton",wApplyCancelGUI)
		btnC:SetText("Cancel")
		btnC:SetSize(100,50)
		btnC:SetPos(110,25)
		function btnC:DoClick()
			wiringGui:Close()
		end
		
		
		for k,v in pairs(Components) do
			v[5] = k
			local eGui = vgui.Create("DGUIWiringFrame",wiringGui)
			eGui:SetComponent(v)
			k.WOut = v[2]
		end
		
		for _,btnI in pairs(DInpButtons) do
			if btnI.Port and btnI.Port.Src and btnI.Port.Src.WOut then
				local portO = btnI.Port.Src.WOut[btnI.Port.SrcId]
				if portO then
					btnO = DOutButtons[GUIWiring_GetEntPortKey(portO.Entity,portO.Name)]
					if btnO then
						GUIWiring_SetWire(btnI,btnO,true)
					end
				end
			end
		end
		
		function wiringGui:CalcButtonPos(btn)
			if not (btn and btn:IsValid()) then return -1,-1 end
			local x1,y1 = btn:GetPos()
			local w,h = btn:GetSize()
			x1 = x1 + (w/2)
			y1 = y1 + (h/2)
			local x2,y2 = btn:GetParent():GetPos()
			return x1+x2,y1+y2
		end
		
		function wiringGui:Paint()
			for k,v in pairs(GUIWiring_DisplayWires) do
				local x1,y1 = wiringGui:CalcButtonPos(v[1])
				if x1 < 0 then GUIWiring_DisplayWires[k] = nil DoWireTable[k] = nil UnWireTable[k] = nil end
				local x2,y2 = wiringGui:CalcButtonPos(v[2])
				if x2 < 0 then GUIWiring_DisplayWires[k] = nil DoWireTable[k] = nil UnWireTable[k] = nil end
				if x1 > 0 and x2 > 0 then
					surface.SetDrawColor(255,255,0,255)
					surface.DrawLine(x1,y1,x2,y2)
				end
			end
			return true
		end
		wiringGui:MakePopup()
	end

	local function GUIWiring_SetUnWire(ent,port,pvk)
		if not pvk then pvk = GUIWiring_GetEntPortKey(ent,port.Name) end
		local btn = DInpButtons[pvk]
		if not (btn and btn:IsValid()) then return end
		btn.Port.Src = nil
		btn.Port.SrcId = nil
		btn:SetDefaultColor()
		local pvt = {}
		pvt.Input = port
		if not pvt.Input.Entity then pvt.Input.Entity = ent end
		UnWireTable[pvk] = pvt
		DoWireTable[pvk] = nil
		GUIWiring_DisplayWires[pvk] = nil
	end

	local PANEL = {}
	PANEL.Inputs = nil
	PANEL.Outputs = nil
	PANEL.EName = nil
	PANEL.Entity = nil
	function PANEL:Init()
		self:SetDraggable( true )
		self:SetSizable( false )
		self:SetScreenLock( true )
		self:SetDeleteOnClose( true )
		self:SetTitle( "Untitled DGUIWiringFrame" )
	end
	function PANEL:SetComponent(vx)
		local kx = vx[5]
		local ekey = kx:EntIndex()
		local nam = vx[3] or kx.WireDebugName or kx.PrintName or ""
		nam = nam .. " ("..tostring(kx)..")"
		self.Entity = kx
		self.EName = nam
		self.Inputs = vx[1]
		self.Outputs = vx[2]
		self:SetTitle(nam)
		local curY1 = 25
		if self.Inputs then
			for k,v in pairs(self.Inputs) do
				local btn = vgui.Create("DGUIWiringInputButton",self)
				btn:SetPort(self.Entity,v)
				btn:SetPos(5,curY1)
				btn:SetSize(90,25)
				btn.BtnId = k
				curY1 = curY1 + 30
			end
		end
		local curY2 = 25
		if self.Outputs then
			for k,v in pairs(self.Outputs) do
				local btn = vgui.Create("DGUIWiringOutputButton",self)
				btn:SetPos(100,curY2)
				btn:SetSize(90,25)
				btn.BtnId = k
				btn:SetPort(self.Entity,v)
				curY2 = curY2 + 30		
			end
		end
		if not vx[4] then
			local btn = vgui.Create("DGUIWiringOutputButton",self)
			btn:SetPos(100,curY2)
			btn:SetSize(90,25)
			btn:MakeWLCreator(self.Entity)
			curY2 = curY2 + 30	
		end
		local curY = math.max(curY1,curY2)
		self:SetSize(195,curY)
		self:Center()
	end
	PANEL.RealClose = PANEL.Close
	function PANEL:Close()
		if PANEL.Component and PANEL.Component.Entity then
			for k,v in pairs(DoWireTable) do
				if v and v.Input and v.Input.Entity == PANEL.Component.Entity then DoWireTable[k] = nil
				elseif v and v.Output and v.Output.Entity == PANEL.Component.Entity then DoWireTable[k] = nil end
			end
			for k,v in pairs(UnWireTable) do
				if v and v.Input and v.Input.Entity == PANEL.Component.Entity then UnWireTable[k] = nil end
			end
		end
		self:SetVisible( false )

		if ( self:GetDeleteOnClose() ) then
			self:Remove()
		end
	end
	function PANEL:Paint()
		draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), Color(0,0,0,200) )
		surface.SetDrawColor( 0, 0, 0, 150 )
		surface.DrawRect( 0, 22, self:GetWide(), 1 )
		return false
	end
	vgui.Register( "DGUIWiringFrame", PANEL, "DFrame" )

	local PANEL = {}
	PANEL.CR = 0
	PANEL.CG = 0
	PANEL.CB = 0
	PANEL.CA = 255
	PANEL.Entity = nil
	PANEL.Port = nil
	PANEL.PVK = ""
	function PANEL:SetPort(ent,port)
		if not IsWire(ent) then return end
		self.IsWirelinkCreator = nil
		self.Entity = ent
		port.Entity = port.Entity or ent
		self.Port = port
		local tmp = port.Name
		if port.Type != "NORMAL" then
			tmp = tmp .. " ["..port.Type.."]"
		end
		self:SetText(tmp)
		self:SetDefaultColor()
		self.PVK = GUIWiring_GetEntPortKey(self.Entity,self.Port.Name)
		self:SetEntTable()
	end
	function PANEL:SetEntTable()
		self.Entity.Inputs = self.Entity.Inputs or {}
		self.Entity.Inputs[self.Port.Name] = self
		DInpButtons[self.PVK] = self
	end
	function PANEL:Paint( w, h )
		derma.SkinHook( "Paint", "Button", self, w, h )
		surface.SetDrawColor(self.CR,self.CG,self.CB,self.CA)
		surface.DrawRect(0,0,self:GetWide(),self:GetTall())
		derma.SkinHook( "PaintOver", "Button", self, w, h )
		return false
	end
	function PANEL:SetDefaultColor()
		if not self.Port.Src then
			self.CR = 0
		else
			self.CR = 255
		end
		self.CG = 0
		self.CB = 0
		self.CA = 255
	end
	function PANEL:DoClick()
		if CSelInp and CSelInp.SetDefaultColor then CSelInp:SetDefaultColor() end
		if CSelInp == self then CSelInp = nil return end
		CSelInp = self
		if not self.Port.Src then
			self.CR = 0
		else
			self.CR = 255
		end
		self.CG = 0
		self.CB = 255
		self.CA = 255	
		if CSelOut then GUIWiring_SetWire() end
	end
	function PANEL:DoRightClick()
		GUIWiring_SetUnWire(self.Entity,self.Port,self.PVK)
	end
	vgui.Register( "DGUIWiringInputButton", PANEL, "DButton" )
	local PANEL = table.Copy(PANEL)
	function PANEL:MakeWLCreator(ent)
		self.Entity = ent
		self.IsWirelinkCreator = 2
		self:SetText("Add Wirelink")
		DWLMakers[tostring(ent)] = self
	end
	function PANEL:DoClick()
		if self.IsWirelinkCreator then
			if self.IsWirelinkCreator == 2 then
				RunConsoleCommand("gui_wiring_wirelink",self.Entity:EntIndex())
				self.IsWirelinkCreator = 1
			end
			return
		end
		if CSelOut and CSelOut.SetDefaultColor then CSelOut:SetDefaultColor() end
		if CSelOut == self then CSelOut = nil return end
		CSelOut = self
		self.CR = 0
		self.CG = 255
		self.CB = 0
		self.CA = 255	
		if CSelInp then GUIWiring_SetWire() end
	end
	function PANEL:SetEntTable()
		self.Entity.Outputs = self.Entity.Outputs or {}
		self.Entity.Outputs[self.Port.Name] = self
		DOutButtons[self.PVK] = self
	end
	function PANEL:DoRightClick()
		--Nothing to do here
	end
	vgui.Register( "DGUIWiringOutputButton", PANEL, "DButton" )
	
end

function TOOL:Reload(trace)
	if CLIENT then return end
	local ply = self:GetOwner()
	if not Components[ply] then return end
	net.Start("GUIWiring_Start")
	net.Send( ply )
	for _,v in pairs(Components[ply]) do
		local stbl = von.serialize( {v.Inputs,v.Outputs,v.WireDebugName,v.extended} )

		net.Start( "GUIWiring_EntPart" )
			net.WriteEntity( v )
			net.WriteString( stbl )
		net.Send( ply )
	end
	net.Start("GUIWiring_End")
	net.Send( ply )
end

if SERVER then
	util.AddNetworkString( "GUIWiring_EntPart" )
	util.AddNetworkString( "GUIWiring_Start")
	util.AddNetworkString( "GUIWiring_End")
	util.AddNetworkString( "GUIWiring_WL")
	
	local material = {}
	local color = {}
	local width = {}
	local wOn = {}
	
	local function GUIWiring_Wirelink(ply,ent)
		if not table.HasValue(Components[ply],ent) then return end
		if ent.extended then return end
		ent.extended = true
		Wirelib.CreateWirelinkOutput( ply, ent, {true} )
		if not ent.Outputs["wirelink"] then return end
		net.Start("GUIWiring_WL")
			net.WriteEntity(ent)
			net.WriteString( von.serialize( ent.Outputs["wirelink"] ) )
		net.Send( ply )
	end
	local function GUIWring_WirelinkCmd(ply,cmd,args)
		if not (#args == 1 and ply:IsValid() and ply:IsPlayer()) then return end
		local ent = ents.GetByIndex(args[1])
		if IsValid(ent) and IsWire(ent) then
			GUIWiring_Wirelink(ply,ent)
		end
	end
	concommand.Add("gui_wiring_wirelink",GUIWring_WirelinkCmd)
	
	local function GUIWiring_StartWire(ply)
		if wOn[ply] then return end
		material[ply] = ply:GetInfo("gui_wiring_material")
		color[ply] = Color(ply:GetInfoNum("gui_wiring_color_r", 255),ply:GetInfoNum("gui_wiring_color_g", 255),ply:GetInfoNum("gui_wiring_color_b", 255))
		width[ply] = ply:GetInfoNum("gui_wiring_width", 1)
		wOn[ply] = true
	end
	concommand.Add("gui_wiring_start",GUIWiring_StartWire)
	
	local function GUIWiring_DoWire(ply,ient,iname,oent,oname)
		if not (wOn[ply] and table.HasValue(Components[ply],ient) and table.HasValue(Components[ply],oent)) then return end
		Wire_Link_Start(ply:UniqueID(), ient, ient:OBBCenter(), iname, material[ply], color[ply], width[ply])
		Wire_Link_End(ply:UniqueID(), oent, oent:OBBCenter(), oname, ply)
	end
	local function GUIWiring_UnWire(ply,ient,iname)
		if not (wOn[ply] and table.HasValue(Components[ply],ient)) then return end
		Wire_Link_Clear(ient,iname)
	end

	local function GUIWiring_DoWireConCmd(ply,cmd,args)
		if not (#args == 4 and ply:IsValid() and ply:IsPlayer()) then return end
		local ent = ents.GetByIndex(args[1])
		local inp = args[2]
		local oent = ents.GetByIndex(args[3])
		local out = args[4]
		if IsValid(ent) and IsWire(ent) and inp != "" and IsValid(oent) and IsWire(oent) and out != "" then
			GUIWiring_DoWire(ply,ent,inp,oent,out)
		end		
	end
	concommand.Add("gui_wiring_wire",GUIWiring_DoWireConCmd)
	local function GUIWiring_UnWireConCmd(ply,cmd,args)
		if not (#args == 2 and ply:IsValid() and ply:IsPlayer()) then return end
		local ent = ents.GetByIndex(args[1])
		local inp = args[2]
		if IsValid(ent) and IsWire(ent) and inp != "" then
			GUIWiring_UnWire(ply,ent,inp)
		end
	end
	concommand.Add("gui_wiring_unwire",GUIWiring_UnWireConCmd)
	
	local function GUIWiring_EndWire(ply,force)
		if !force and !wOn[ply] then return end
		material[ply] = nil
		color[ply] = nil
		width[ply] = nil
		wOn[ply] = nil
		if not Components[ply] then return end
		for _,v in pairs(Components[ply]) do
			if (IsValid(v)) then
				v:SetColor(Color(v.OldColorR or 255, v.OldColorG or 255, v.OldColorB or 255, v.OldColorA or 255))
				v.OldColorR = nil
				v.OldColorG = nil
				v.OldColorB = nil
				v.OldColorA = nil
			end
		end
		Components[ply] = nil
	end
	concommand.Add("gui_wiring_end",GUIWiring_EndWire)
	
	local function GUIWiring_Disconnect(ply)
		GUIWiring_EndWire(ply,true)
	end
	hook.Add("PlayerDisconnected","GUIWiring_Disconnect",GUIWiring_Disconnect)
end

local LastOverBoxInput = ""
local LastOverBoxOutput = ""

function TOOL:Think() --get and transmit the info on the overlay, but only when needed
	local ply = self:GetOwner()
	if(CLIENT) then return end
	local Trace = ply:GetEyeTraceNoCursor()
	
	local ShowPorts = self:GetClientNumber("showports") ~= 0
	
	if(Trace.Hit and Trace.Entity and Trace.Entity:IsValid() and IsWire(Trace.Entity) and ShowPorts) then
		local Ent = Trace.Entity
		--get the inputs and put their current use state in-between
		if(Ent.Inputs) then
			local InputString = ""
			for InputIdx, CurInput in pairs_sortvalues(Ent.Inputs, WireLib.PortComparator) do
				InputString = InputString..InputIdx
				if(CurInput.Type != "NORMAL") then
					InputString = InputString.." ["..CurInput.Type.."]"
				end
				if(CurInput.Src and CurInput.Src:IsValid()) then -- check whether the input is wired up or not
					InputString = InputString..",W\n"
				else
					InputString = InputString..",N\n"
				end
			end
			
			if(InputString != LastOverBoxInput) then
				self:GetWeapon():SetNetworkedString("WireDebugOverlayInputs", InputString)
				LastOverBoxInput = InputString
			end
		else
			if(LastOverBoxInput != "") then
				LastOverBoxInput = ""
				self:GetWeapon():SetNetworkedString("WireDebugOverlayInputs", "")
			end
		end
		
		--get the outputs
		if(Ent.Outputs) then
			local OutputString = ""
			for OutputIdx, CurOutput in pairs_sortvalues(Ent.Outputs, WireLib.PortComparator) do
				OutputString = OutputString..OutputIdx
				if(CurOutput.Type != "NORMAL") then
					OutputString = OutputString.." ["..CurOutput.Type.."]"
				end
				OutputString = OutputString.."\n"
			end
			
			if(OutputString != LastOverBoxOutput) then
				self:GetWeapon():SetNetworkedString("WireDebugOverlayOutputs", OutputString)
				LastOverBoxOutput = OutputString
			end
		else
			if(LastOverBoxOutput != "") then
				LastOverBoxOutput = ""
				self:GetWeapon():SetNetworkedString("WireDebugOverlayOutputs", "")
			end
		end
	else
		if(LastOverBoxInput != "") then
			LastOverBoxInput = ""
			self:GetWeapon():SetNetworkedString("WireDebugOverlayInputs", "")
		end
		
		if(LastOverBoxOutput != "") then
			LastOverBoxOutput = ""
			self:GetWeapon():SetNetworkedString("WireDebugOverlayOutputs", "")
		end
	end

end

if CLIENT then

	function TOOL:DrawHUD()
		local InputText = self:GetWeapon():GetNetworkedString("WireDebugOverlayInputs") or ""
		local OutputText = self:GetWeapon():GetNetworkedString("WireDebugOverlayOutputs") or ""
		
		if(InputText != "") then
			surface.SetFont("Trebuchet24")
			local Inputs = string.Explode("\n",InputText)
			local InputsUsed = {}
			for i, Input in ipairs(Inputs) do
				InputsUsed[i] = string.Right(Input,2) == ",W"
				Inputs[i] = string.sub(Inputs[i],1,-3)
			end
			
			local FontHeight = draw.GetFontHeight("Trebuchet24")+1
			local MaxWidth = 0
			for i, Input in ipairs(Inputs) do
				local W, H = surface.GetTextSize(Input)
				if(W > MaxWidth) then
					MaxWidth = W
				end
			end
			
			
			draw.RoundedBox(8,
				ScrW()/2-(MaxWidth+16)-20,
				ScrH()/2-#Inputs*FontHeight/2-8,
				MaxWidth+16,
				(#Inputs-1)*FontHeight+16,
				Color(109,146,129,192)
			)
			
			for i, Input in ipairs(Inputs) do
				local TextCol = Color(255,255,255)
				if(InputsUsed[i] == true) then
					TextCol = Color(255,0,0)
				end
				draw.Text({
					text = Input or "",
					font = "Trebuchet24",
					pos = {ScrW()/2-(MaxWidth+16)-12, (FontHeight)*(i-1)+(ScrH()/2-#Inputs*FontHeight/2)},
					color = TextCol
				})
			end
			
		end
		
		if(OutputText != "") then
			surface.SetFont("Trebuchet24")
			local Outputs = string.Explode("\n",OutputText)
			
			local FontHeight = draw.GetFontHeight("Trebuchet24")+1
			local MaxWidth = 0
			for i, Output in ipairs(Outputs) do
				local W, H = surface.GetTextSize(Output)
				if(W > MaxWidth) then
					MaxWidth = W
				end
			end
			
			
			draw.RoundedBox(8,
				ScrW()/2+20,
				ScrH()/2-#Outputs*FontHeight/2-8,
				MaxWidth+16,
				(#Outputs-1)*FontHeight+16,
				Color(109,146,129,192)
			)
			
			for i, Output in ipairs(Outputs) do
				draw.Text({
					text = Output or "",
					font = "Trebuchet24",
					pos = {ScrW()/2+28, (FontHeight)*(i-1)+(ScrH()/2-#Outputs*FontHeight/2)},
					color = Color(255,255,255)
				})
			end
		end
		
		
	end
end


function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.gui_wiring.name", Description = "#Tool.gui_wiring.desc" })
	
	panel:AddControl("CheckBox", {
			Label = "#Tool_gui_wiring_showports",
			Command = "gui_wiring_showports"
		})
	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire",

		Options = {
			Default = {
				wire_material = "cable/rope",
				wire_width = "0",
			}
		},

		CVars = {
			[0] = "gui_wiring_width",
			[1] = "gui_wiring_material",
		}
	})

	panel:AddControl("Slider", {
		Label = "#GUI_WiringTool_width",
		Type = "Float",
		Min = "0",
		Max = "20",
		Command = "gui_wiring_width"
	})
	
	panel:AddControl( "MatSelect", {
		Height = "1",
		Label = "#GUI_WiringTool_material",
		ItemWidth = 24,
		ItemHeight = 64,
		ConVar = "gui_wiring_material",
		Options = list.Get( "WireMaterials" )
	} )

	panel:AddControl("Color", {
		Label = "#GUI_WiringTool_colour",
		Red = "gui_wiring_color_r",
		Green = "gui_wiring_color_g",
		Blue = "gui_wiring_color_b",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
end
