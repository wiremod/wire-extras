-- Helper function (copied from wire/welcome_menu.lua)
local function filterversion( version )
	if (type(version) == "number") then return version elseif (type(version) != "string") then return 0 end
	version = version:gsub( "[^%d]+", "" )
	return tonumber(version) or 0
end

hook.Add("Wire_WMenu_AddTabs","UWSVNTabs",function( self )
	------------------------------------------------------------------------------------------------
	-- UWSVN Version Check Tab
	------------------------------------------------------------------------------------------------
	
	local pnl = vgui.Create("DPanel")
	pnl.Paint = function( pnl ) surface.SetDrawColor(0,0,0,255) surface.DrawRect(0,0,pnl:GetWide(),pnl:GetTall()) end
	local index, info = self:AddTab("UWSVN Version", pnl, "gui/silkicons/newspaper", "Check if you need to update UWSVN", true, 500, 300 )
	
	local btn = vgui.Create("Wire_WMenu_Button",pnl)
	btn:SetText("Check for newer version")
	btn:SetSize( 350, 20 )
	btn:SetPos( 60, 60 )
	
	local lbl = vgui.Create("Wire_WMenu_Label",pnl)
	lbl:SetText("Click the button below to check.")
	lbl:SetPos( 4, 5 )
	lbl:SetSize( 475, 40 )
	lbl:SetBGColor( Color(75,75,185,255) )
	
	local lbl2 = vgui.Create("Wire_WMenu_Label",pnl)
	
	local function versioncheck(rev)
		if (!rev) then
			lbl:SetText("Error: Failed to get online version.")
			lbl:SetColor( nil ) -- Default color
			lbl:SetBGColor( Color(0,0,0,255) )
		else
			local onlineversion = filterversion(rev)
			local localversion = filterversion(WireLib.LocalUWSVNVersion)
			local serverversion = filterversion(WireLib.UWSVNVersion)
			
			if (!onlineversion or onlineversion == 0) then
				lbl:SetText("Error: Failed to get online version.")
				lbl:SetColor( nil ) -- Default color
				lbl:SetBGColor( Color(0,0,0,255) )
			else
			
				local add = "Both you and the server have the latest version."
				lbl:SetBGColor( Color(75,185,75,255) )
				if (localversion < onlineversion and serverversion < onlineversion) then
					add = "Both you and the server have an old version."
					lbl:SetBGColor( Color(185,75,75,255) )
				elseif (localversion < onlineversion and serverversion >= onlineversion) then
					add = "You have an old version, but the server has the latest."
					lbl:SetBGColor( Color(185,75,75,255) )
				elseif (localversion >= onlineversion and serverversion < onlineversion) then
					add = "You have the latest, but the server has an old version."
					lbl:SetBGColor( Color(185,75,75,255) )
				end
				
				lbl:SetText("Online UWSVN version found: " .. onlineversion .. "\n"..add)
				lbl:SetColor( Color(0,0,0,255) )
				if (serverversion == 0) then serverversion = "Failed to get server's version." end
				if (localversion == 0) then localversion = "Failed to get client's version." end
				lbl2:SetText("Your UWSVN version is: " .. (WireLib.LocalUWSVNVersion or localversion) .. "\n" ..
							"The server's UWSVN version is: " .. (WireLib.UWSVNVersion or serverversion) .. "\n" ..
							"The latest UWSVN version is: " .. onlineversion)
			end
		end
	end
	
	function btn:DoClick()
		lbl:SetText("Checking...")
		lbl:SetColor( nil )
		lbl:SetBGColor( Color(75,75,185,255) )
		if (!WireLib.UWSVNVersion or WireLib.UWSVNVersion == "-unknown-") then RunConsoleCommand("Wire_RequestVersion_UWSVN") end
		WireLib.GetOnlineUWSVNVersion(versioncheck)
	end
	local sver = tonumber(WireLib.UWSVNVersion)
	if (!sver or sver == 0) then sver = "- click above to check -" end
	lbl2:SetText("Your UWSVN version is: " .. WireLib.LocalUWSVNVersion .. "\n" ..
				"The server's UWSVN version is: " .. sver .. "\n" ..
				"The latest UWSVN version is: - click above to check -")
	lbl2:SetPos( 110, 160 )
	lbl2:SetColor( Color(0,0,0,255) )
	lbl2:SizeToContents()
end)