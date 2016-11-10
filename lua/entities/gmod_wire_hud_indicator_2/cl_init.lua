include('util/errors.lua')
include('shared.lua')
include('H2Editor.lua')
include('parser/HMLParser.lua')
include('renderer/HMLRenderer.lua')
include('expression_parser.lua')

//--RUNS CLIENTSIDE--//

ENT.RenderGroup 		= RENDERGROUP_BOTH

Msg("Loading clientside HUD2 data...\n")

HUD_System = {}
	HUD_System.TestMode = false
	HUD_System.editor = nil
	HUD_System.parser = nil
	HUD_System.entityInputs = nil
	HUD_System.cacheDelay = 0
	HUD_System.hookedEnts = {}
	HUD_System.uploading = false
	HUD_System.eval = EXPR_Parser:new()
	
	HUD_System.opCount = 0
	HUD_System.maxOps = 500
	HUD_System.showStatus = false

HUD_EditorPanel = null			-- The editor window reference
HUD_TestModeWin = null			-- The preview window reference


function openH2Editor()

	if( HUD_System.editor == nil ) then
		HUD_System.editor = vgui.Create( "Expression2EditorFrame" )
		HUD_System.editor:Setup("HML Editor", "HUD2", "HML")
	end
	
	--HUD_System.editor:LoadFile( "HUD2/sample.txt" )
	HUD_System.editor:Open()


	if( HUD_System.parser == nil ) then
		HUD_System.parser = HMLParser:new( "" )
		HUD_System.renderer = HMLRenderer:new()
	end

end
concommand.Add("openH2Editor", openH2Editor, nil);


function HUD2_setMaxOps( player, command, arguments )
	
	if( arguments and arguments[1] ) then
		HUD_System.maxOps = tonumber(arguments[1]) or 0
		print("[II]", "Set maxOps to" ..tostring(HUD_System.maxOps))
		return true;
	end
	
	print("[WW]", "Wrong arguments for setHUD2MaxOps! Expects one argument.")
	
	return false;
end
concommand.Add("HUD2_setMaxOps", setHUD2MaxOps, nil);

function HUD2_showStats( player, command, arguments )
	
	PrintTitledTable("args", arguments)
	
	return true;
end
concommand.Add("HUD2_showStats", HUD2_showStats, nil);


function HUD2_uploadCode( entID, file )

	print( "Uploading code..." )
	HUD_System.uploading = true

	if( HUD_System.editor ) then
		local tableBuffer = { eindex = entID, code = HUD_System.editor:GetCode() }
		net.Start( "HMLUpload" )
			net.WriteTable( tableBuffer )
		net.SendToServer()

		GAMEMODE:AddNotify("<HML> Uploaded!", NOTIFY_CLEANUP, 3)
	else
		GAMEMODE:AddNotify("[WW] No loaded HML!", NOTIFY_CLEANUP, 3)
	end

	HUD_System.uploading = false
	return true
end
concommand.Add("HUD2_uploadCode", HUD2_uploadCode, nil);




//-- Hook the user message 'HUD2_SYNC' and keep our lookup table up to date! --//
local function HUD2_Sync( um )
	local eindex = um:ReadShort()
	local name = um:ReadString()
	local inType = um:ReadShort()

	if( HUD_System.hookedEnts[eindex] == nil or HUD_System.hookedEnts[eindex].renderer == nil ) then return end

	local NORMAL = 0
	local STRING = 1
	local COLOR = 2
	local COLOR_ALPHA = 3
	local VECTOR2 = 4
	local VECTOR3 = 5
	local VECTOR4 = 6

	-- These should be saved in TOKEN format, so they can just be dropped in to expressions on the fly!
	-- Although, line numbers and other meta data can be ignored - the tokenizer will do that for us.
	-- 
	-- Alpha'd colors are vector4's but with lower precision, hence the additional type - even though its not used by wiremod at the mo AFAIK. -Moggie100
	if ( inType == NORMAL ) then
		HUD_System.hookedEnts[eindex].renderer.inputs[name] = { type="VALUE", value=um:ReadFloat() }

	elseif( inType == STRING ) then
		HUD_System.hookedEnts[eindex].renderer.inputs[name] = { type="VALUE", value=um:ReadString() }

	elseif( inType == COLOR ) then
		HUD_System.hookedEnts[eindex].renderer.inputs[name] = { type="COLLECTION", value = { {value=um:ReadShort(), type="VALUE"}, {value=um:ReadShort(), type="VALUE"}, {value=um:ReadShort(), type="VALUE"}, 255} }

	elseif( inType == COLOR_ALPHA ) then
		HUD_System.hookedEnts[eindex].renderer.inputs[name] = { type="COLLECTION", value = { {value=um:ReadShort(), type="VALUE"}, {value=um:ReadShort(), type="VALUE"}, {value=um:ReadShort(), type="VALUE"}, {value=um:ReadShort(), type="VALUE"}} }

	elseif( inType == VECTOR2 ) then
		HUD_System.hookedEnts[eindex].renderer.inputs[name] = { type="COLLECTION", value = { {value=um:ReadFloat(), type="VALUE"}, {value=um:ReadFloat(), type="VALUE"}} }

	elseif( inType == VECTOR3 ) then
		local inVec = um:ReadVector()
		HUD_System.hookedEnts[eindex].renderer.inputs[name] = { type="COLLECTION", value = { {value=inVec.x, type="VALUE"}, {value=inVec.y, type="VALUE"}, {value=inVec.z}} }

	elseif( inType == VECTOR4 ) then
		HUD_System.hookedEnts[eindex].renderer.inputs[name] = { type="COLLECTION", value = { {value=um:ReadFloat(), type="VALUE"}, {value=um:ReadFloat(), type="VALUE"}, {value=um:ReadFloat(), type="VALUE"}, {value=um:ReadFloat(), type="VALUE"}} }

	end

end
usermessage.Hook("HUD2_SYNC", HUD2_Sync)


//-- Hook the user message 'HUD2_REG' so we get register messages
local function HUD2_Register( um )
	local eindex = um:ReadShort()

	HUD_System.hookedEnts[eindex] = { renderer = HMLRenderer:new() }
	
	GAMEMODE:AddNotify("[HUD] Linking to HUD extention...", NOTIFY_CLEANUP, 3)
	
end
usermessage.Hook("HUD2_REG", HUD2_Register)


//-- Hook the user message 'HUD2_UNREG' so we can unregister
local function HUD2_Register( um )
	local eindex = um:ReadShort()

	HUD_System.hookedEnts[eindex] = nil
	GAMEMODE:AddNotify("[HUD] Link broken!", NOTIFY_CLEANUP, 3)
end
usermessage.Hook("HUD2_UNREG", HUD2_Register)

function HML_RenderTableUpdate( len )
	local tbl = net.ReadTable()

	local eindex = tbl.eindex
	local renderTable = tbl.table

	--Ensure that we have a renderer to work with...
	if( HUD_System.hookedEnts[eindex] == nil or HUD_System.hookedEnts[eindex].renderer == nil ) then
		HUD_System.hookedEnts[eindex] = { renderer = HMLRenderer:new() }
	end

	HUD_System.hookedEnts[eindex].renderer:SetRenderTable( renderTable )

	PrintTable( tbl )
	GAMEMODE:AddNotify("[HUD] New HUD data acquired...", NOTIFY_CLEANUP, 3)
end
net.Receive( "RenderTableUpdate", HML_RenderTableUpdate )




function H2DrawHML()

	--Ensure we have objects to use...
	if( HUD_System.parser == nil ) then
		HUD_System.parser = HMLParser:new( "" )
	end

	local forceRefresh = true

	--Reset the opCount--
	HUD_System.opCount = 0
	
	for eindex, data in pairs(HUD_System.hookedEnts) do
		-- Check to see if we've lost the entity...
		if( ents.GetByIndex( eindex ) ) then
			-- Ensure we have a renderer to use...
			data.renderer = data.renderer or HMLRenderer:new()

			data.renderer.cacheRefresh = forceRefresh
			
			HUD_System.entityInputs = HUD_System.hookedEnts[eindex].renderer.inputs
			
			if( data.renderer:GetRenderTable() != nil ) then
				if( data.renderer:Draw( t ) == false ) then
					HUD_System.NextCheckTime = CurTime() + 3.0
					HUD_System.NextCheckTime = HUD_System.NextCheckTime + 3
					data.renderer:SetRenderTable( nil )
					HMLError( "Render Error!" )
				end
			else
				draw.WordBox( 8, 30, 190, "A HUD indicator is hooked, but has no associated render table!", "HudHintTextLarge", Color(255,0,0,100), Color(255,255,255) )
			end
		
		else
			-- Missing entity! Purge its data!
			GAMEMODE:AddNotify("[HUD] Lost connection to HUD entity!", NOTIFY_CLEANUP, 3)
			data = nil
			
		end
	end
	
	if( HUD_System.uploading ) then
		draw.WordBox( 8, 30, 160, "Uploading HML...", "HudHintTextLarge", Color(50,50,75,128), Color(255,255,255) )
	end

end
hook.Add("HUDPaint", "H2DrawHML", H2DrawHML)


function clickedOnScreen( click, mousecode, vec )
	print( "Placeholder for more awesome stuff later -Moggie100 (HUD2)" )
end
hook.Add( "CallScreenClickHook", "ClickedOnTheScreen", clickedOnScreen )
