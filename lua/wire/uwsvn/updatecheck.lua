function WireLib.GetUWSVNVersion()
	local version = "306 (OLD VERSION)"
	local plainversion = 306
	local exported = true
	
	-- Try getting the version using the .svn files:
	if (file.Exists("lua/wire/uwsvn/.svn/entries", true)) then
		version = string.Explode("\n", file.Read("lua/wire/uwsvn/.svn/entries", true) or "")[4]
		exported = false
		plainversion = version
	elseif (file.Exists("wire_version.txt")) then -- Try getting the version by reading the text file:
		plainversion = file.Read("unsvn_version.txt")
		version = plainversion .. " (EXPORTED)"
	end
	
	return version, tonumber(plainversion), exported
end

-- Get online version
function WireLib.GetOnlineUWSVNVersion( callback )
	http.Get("http://svn.dagamers.net/wiremodextras/trunk/","",function(contents,size)
		local rev = tonumber(string.match( contents, "Revision ([0-9]+)" ))
		callback(rev,contents,size)
	end)
end
if (SERVER) then
	------------------------------------------------------------------
	-- Get the version
	------------------------------------------------------------------
	WireLib.UWSVNVersion = WireLib.GetUWSVNVersion()
	
	------------------------------------------------------------------
	-- Send the version to the client
	------------------------------------------------------------------
	local function recheck( ply, tries )
		timer.Simple(5,function(ply)
			if (ply and ply:IsValid()) then -- Success!
				umsg.Start("wire_uwsvn_rev",ply)
					umsg.String( WireLib.UWSVNVersion )
				umsg.End()
			else
				if (tries and tries > 3) then return end -- several failures.. stop trying
				recheck(ply, (tries or 0) + 1) -- Try again
			end
		end)
	end
	hook.Add("PlayerInitialSpawn","WirePlayerInitSpawn",recheck)
		

	-- Send the version to the client ON REQUEST
	local antispam = {}
	concommand.Add("Wire_RequestVersion_UWSVN",function(ply,cmd,args)
		if (!antispam[ply]) then antispam[ply] = 0 end
		if (antispam[ply] < CurTime()) then
			antispam[ply] = CurTime() + 0.5
			umsg.Start("wire_uwsvn_rev",ply)
				umsg.String( WireLib.UWSVNVersion )
			umsg.End()
		end
	end)
	
	------------------------------------------------------------------
	-- Wire_PrintVersion_UWSVN 
	-- prints the server's version on the client
	-- This doesn't use the above sending-to-client because it's meant to work even if the above code fails.
	------------------------------------------------------------------
	concommand.Add("Wire_PrintVersion_UWSVN",function(ply,cmd,args)
		if (ply and ply:IsValid()) then
			ply:ChatPrint("Server's UWSVN Version: " .. WireLib.UWSVNVersion)
		else
			print("Server's UWSVN Version: " .. WireLib.UWSVNVersion)
		end
	end)
	
	------------------------------------------------------------------
	-- Tags
	-- Adds "uwsvnexport####" or "uwsvnsvn####" to tags
	------------------------------------------------------------------
	
	local cvar = GetConVar("sv_tags")
	timer.Create("Wire_Tags",1,0,function()
		local tags = cvar:GetString()
		if (!tags:find( "uwsvn" )) then
			local version, plainversion, exported = WireLib.GetUWSVNVersion()
			local tag = "uwsvn" .. ( exported and "exported" or "svn" ) .. plainversion
			RunConsoleCommand( "sv_tags", tags .. "," .. tag )
		end	
	end)
	
else -- CLIENT

	------------------------------------------------------------------
	-- Get the version
	------------------------------------------------------------------
	WireLib.LocalUWSVNVersion = WireLib.GetUWSVNVersion()

	------------------------------------------------------------------
	-- Receive the version from the server
	------------------------------------------------------------------
	
	WireLib.UWSVNVersion = "-unknown-" -- We don't know the server's version yet
	
	usermessage.Hook("wire_uwsvn_rev",function(um)
		WireLib.UWSVNVersion = um:ReadString()
	end)
end
