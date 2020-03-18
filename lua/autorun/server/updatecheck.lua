--As of making this, HTTPFetch works really weird. Modifying variables only works inside the function.
--For an example, uncheck the two print statements below. Inside the function it's 1 or 0, outside the function it goes back to nil.
--I didn't see any uses of this on github either.
--Weird.


if not (file.Exists("wire-extras/updatecheck.txt", "data")) then
	hook.Add("PlayerInitialSpawn","WireExtrasUpdate",function()
		print("Wire Extras steam workshop updates currently discontinued. For up-to-date Wire Extras, visit the GitHub link. (But they only post minor fixes twice a year anyway)")
		file.CreateDir("wire-extras")
		file.Write("wire-extras/updatecheck.txt", "Wire Extras steam workshop updates currently discontinued. For up-to-date Wire Extras, visit the GitHub link. (But they only post minor fixes twice a year anyway)")
		hook.Remove("PlayerInitialSpawn","WireExtrasUpdate")
	end)
end

--local version = "bebc68c"
--local updateneeded = nil
--local haschecked = false

--local function CheckGithub()
--	http.Fetch("https://github.com/wiremod/wire-extras",
--		function( body, len, headers, code )
--			if string.find( body, version ) == nil then
--				updateneeded = 1
--				print([[--WIRE EXTRAS UPDATE--]])
--				print([[--There is a new version of Wire Extras on GitHub.--]])
--				print([[--Yell at Creed to update the Workshop.--]])
--			else
--				updateneeded = 0
--			end
--		end,
--		function(errormsg)
--			print("UWSVN Github Error: "..tostring(errormsg))
--		end)
--end
--CheckGithub()
--local function CheckGithubSpawn()
--	haschecked = true
--	CheckGithub()
--	hook.Remove("PlayerInitialSpawn","WireExtrasUpdate")
--end
--if not haschecked then
--	hook.Add("PlayerInitialSpawn","WireExtrasUpdate",CheckGithubSpawn)
--end