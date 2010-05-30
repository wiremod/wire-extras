AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")
ThinkInterval = 0.05

if CAF and CAF.GetAddon then
	-- Resource Distribution 3+
	ResourceDistribution = CAF.GetAddon("Resource Distribution")
elseif RD_AddResource and RD_GetResourceAmount and RD_ConsumeResource then
	ResourceDistribution = {
		AddResource       = RD_AddResource,
		GetResourceAmount = RD_GetResourceAmount,
		ConsumeResource   = RD_ConsumeResource,
	}
else
	ResourceDistribution = nil
end
RD = ResourceDistribution -- might be necessary for backwards compatibility, but probably not

-- Allow an antenna to query for tx power
function ENT:TxDbw()
	return self.gain + (math.log10(self.txwatts)*10)
end

function ENT:Setup(tx)
	self.is_tx = tx
	
	if WireAddon then
		if self.is_tx then
			self.Inputs = Wire_CreateInputs(self.Entity, {"On", "TxWatts", "BaseMHz", "Channel1", "Channel2", "Channel3", "Channel4", "Channel5", "Channel6", "Channel7", "Channel8"})
			-- transmitters consume energy. 1 energy unit = 1 watt per second, 8 channels = 8 energy units (8 watts) per second
			if ResourceDistribution then ResourceDistribution.AddResource(self.Entity, "energy", 0) end
		else -- it's a receiver
			self.Inputs = Wire_CreateInputs(self.Entity, {"BaseMHz"})
			self.Outputs = Wire_CreateOutputs(self.Entity, {"Channel1", "Ch1dBm", "Channel2", "Ch2dBm", "Channel3", "Ch3dBm", "Channel4", "Ch4dBm", "Channel5", "Ch5dBm", "Channel6", "Ch6dBm", "Channel7", "Ch7dBm", "Channel8", "Ch8dBm"})
		end
	else
		print("This version of Radio Systems requires the 'Wire' addon to be installed.\n")
	end
end

-- Can we transmit? (Got enough resources?)
function ENT:CanTX()
	local status = true
	if CAF and CAF.GetAddonStatus then
		status = tobool(CAF.GetAddonStatus("Resource Distribution"))
	end
	if not self.is_tx or not self.active or not (self.txwatts > 0) then return false end
	if not ResourceDistribution or not status then return true end
	
	return (ResourceDistribution.GetResourceAmount(self, "energy") >= (self.txwatts * 8 * ThinkInterval))
end


-- Returns the background noise at this location in decibels relative to one milliwatt
function ENT:GetBgNoise()
	local firenoise = 0
	for k, v in pairs(ents.FindInSphere(self:GetPos(), 1000)) do
		if v:IsOnFire() then
			firenoise = firenoise + 1000/self:GetPos():Distance(v:GetPos())
		end
	end
	return math.random() + firenoise
end

-- this is called whenever a wire input changes value
function ENT:TriggerInput(iname, value)
	if self.is_tx then
		if iname == "On" then
			self.active = tobool(value)
		elseif iname == "TxWatts" then
			local m = GetConVarNumber("sv_rs_maxtxpower")
			if value > m then
				self.txwatts = m
			elseif value <= 0 then
				self.txwatts = 0
			else
				self.txwatts = value
			end
		elseif iname == "BaseMHz" then
			-- someone has changed the base frequency, update the frequencies
			-- of all the channels to be based on the new value
			self.txchannels = {}
			self.txchannels[self.Inputs.BaseMHz.Value + 2.5] = self.Inputs.Channel1.Value
			self.txchannels[self.Inputs.BaseMHz.Value + 7.5] = self.Inputs.Channel2.Value
			self.txchannels[self.Inputs.BaseMHz.Value + 12.5] = self.Inputs.Channel3.Value
			self.txchannels[self.Inputs.BaseMHz.Value + 17.5] = self.Inputs.Channel4.Value
			self.txchannels[self.Inputs.BaseMHz.Value + 22.5] = self.Inputs.Channel5.Value
			self.txchannels[self.Inputs.BaseMHz.Value + 27.5] = self.Inputs.Channel6.Value
			self.txchannels[self.Inputs.BaseMHz.Value + 32.5] = self.Inputs.Channel7.Value
			self.txchannels[self.Inputs.BaseMHz.Value + 37.5] = self.Inputs.Channel8.Value
		elseif iname == "Channel1" then
			self.txchannels[self.Inputs.BaseMHz.Value + 2.5] = value
		elseif iname == "Channel2" then
			self.txchannels[self.Inputs.BaseMHz.Value + 7.5] = value
		elseif iname == "Channel3" then
			self.txchannels[self.Inputs.BaseMHz.Value + 12.5] = value
		elseif iname == "Channel4" then
			self.txchannels[self.Inputs.BaseMHz.Value + 17.5] = value
		elseif iname == "Channel5" then
			self.txchannels[self.Inputs.BaseMHz.Value + 22.5] = value
		elseif iname == "Channel6" then
			self.txchannels[self.Inputs.BaseMHz.Value + 27.5] = value
		elseif iname == "Channel7" then
			self.txchannels[self.Inputs.BaseMHz.Value + 32.5] = value
		elseif iname == "Channel8" then
			self.txchannels[self.Inputs.BaseMHz.Value + 37.5] = value
		end
	end
end

function ENT:Randomize()
	for i=1, 8 do
		local c = tostring(i)
		Wire_TriggerOutput(self.Entity, "Channel" .. c, math.random() * 10)
		Wire_TriggerOutput(self.Entity, "Ch" .. c .. "dBm", -math.random()*1000)
	end
end

function ENT:Think()
	if not WireAddon then return end
	
	if self:CanTX() then
		if ResourceDistribution then
			local amt = ResourceDistribution.GetResourceAmount(self, "energy")
			if amt < (self.txwatts * 8 * ThinkInterval) then
				ResourceDistribution.ConsumeResource(self, "energy", amt)
			else
				ResourceDistribution.ConsumeResource(self, "energy", (self.txwatts * 8 * ThinkInterval))
			end
		end
		
		if self.txwatts >= 200 then
			local e = ents.FindInCone(self:GetPos(), self:GetForward(), self.txwatts/5, self.beamWidth)
			for k, v in pairs(e) do
				if v:IsPlayer() then v:TakeDamage(self.txwatts / 500 + (100/self:GetPos():Distance(v:GetPos())), self) end
			end
		end
	end
	
	-- Find all antennas on the map
	local ants = ents.FindByClass("ra_*")
	
	-- Lists of discovered transmitters (not using FindInCone this time because I wrote this code just before ents.FindInCone became available
	-- and there's too much to change now. It works ok.)
	local txs = {}
	
	-- Loss due to angle offset
	local angleloss = 0
	
	-- Loss due to polarity skew
	local skewloss = 0
	
	-- If we found antennas
	if ants and #ants > 0 then
		for k, v in pairs(ants) do
			
			-- Find the vector from the receiver to the transmitter and vice-versa
			local vecToTx = v:GetPos() - self:GetPos()
			local vecFromTx = self:GetPos() - v:GetPos()
			
			-- Normalize the above to obtain the direction both ways
			local normVectToTx = vecToTx:GetNormalized()
			local normVectFromTx = vecFromTx:GetNormalized()
			
			-- Find the direction of the receiver and transmitter
			local myAngle = self:GetForward()
			local txAngle = v:GetForward()
			
			-- Find the loss due to polarity skew
			-- If both antennas are not cross polarity, determine the loss due to skew
			if self.pol ~= 0 and v.pol ~= 0 then
				-- Both are the same polarity by default
				local skew = 0
				-- One vertical, one horizontal
				if self.pol ~= v.pol then skew = 1.5707963267949 end
				skewloss = math.abs(math.sin(math.rad(v:GetAngles().r) - math.rad(self:GetAngles().r) + skew) * 20)
			end
			
			local onedir = math.abs(math.acos(normVectToTx:DotProduct(myAngle)))
			local otherdir = math.abs(math.acos(txAngle:DotProduct(normVectFromTx)))
			
			angleloss = (onedir + otherdir) * 30
			
			-- Calculate the received signal strength (strength + self.gain)
			-- If this transmitter is operational, within our field of vision, and we are within its beam
			if v:CanTX() and math.deg(onedir) <= (self.beamWidth/2.0) and math.deg(otherdir) <= (v.beamWidth/2.0) then
				table.insert(txs, v)
			end
		end
		
		local spectrum = {}
		
		if #txs == 0 then
			self:Randomize()
			return
		end
		
		for k, v in pairs(txs) do
			local dist = self:GetPos():Distance(v:GetPos()) / GetConVarNumber("sv_rs_scale")
			local dBm = (math.log10((10^(v:TxDbw()/10)) / (4 * math.pi * dist * dist)) * 10) + 30
			for freq, signal in pairs(v.txchannels) do
				if spectrum[freq] == nil then
					spectrum[freq] = {}
					spectrum[freq][dBm] = signal
				else
					for sfreq, stable in pairs(spectrum) do
						if freq == sfreq then
							stable[dBm] = signal
						end
					end
				end
			end
		end
		
		-- The set of channels that have detected a signal
		local setset = {false, false, false, false, false, false, false, false}
		
		for freq, t in pairs(spectrum) do
			-- Are any of my receiving frequencies in this table?
			if freq >= self.Inputs.BaseMHz.Value and freq < self.Inputs.BaseMHz.Value + 40 then
				
				-- Allow for signal loss due to misaligned tuner frequency
				local driftloss = 0 -- dB
				local choffset = freq - self.Inputs.BaseMHz.Value
				if choffset >= 0 and choffset < 5 then
					driftloss = 10 * math.abs(2.5 - choffset)
				elseif choffset >= 5 and choffset < 10 then
					driftloss = 10 * math.abs(7.5 - choffset)
				elseif choffset >= 10 and choffset < 15 then
					driftloss = 10 * math.abs(12.5 - choffset)
				elseif choffset >= 15 and choffset < 20 then
					driftloss = 10 * math.abs(17.5 - choffset)
				elseif choffset >= 20 and choffset < 25 then
					driftloss = 10 * math.abs(22.5 - choffset)
				elseif choffset >= 25 and choffset < 30 then
					driftloss = 10 * math.abs(27.5 - choffset)
				elseif choffset >= 30 and choffset < 35 then
					driftloss = 10 * math.abs(32.5 - choffset)
				elseif choffset >= 35 and choffset < 40 then
					driftloss = 10 * math.abs(37.5 - choffset)
				end
				
				-- Initialize the signal and the strength
				local sig, dBm = 0, -100
				-- Count the number of received signals on this frequency
				local count = 0; for k,v in pairs(spectrum[freq]) do count = count + 1 end
				
				if count == 1 then
					for k, v in pairs(spectrum[freq]) do dBm = k; sig = v end
				elseif count > 1 then
					-- Initialize the strongest and second strongest received signals on this frequency
					local top = -999 -- dBm
					local lower = -1000 -- dBm
					
					-- Find the highest and second highest strength signals on this frequency
					for k, v in pairs(spectrum[freq]) do if k > top then top = k end end
					for k, v in pairs(spectrum[freq]) do if k > lower and k < top then lower = k end end
					
					-- Find the strength of the received signal as being the strongest - the second strongest
					dBm = top - lower
					
					-- We have a signal lock, return the strongest signal being carried by this frequency
					sig = spectrum[freq][top]
				end
				
				dBm = dBm + self.gain - driftloss - angleloss - skewloss - self:GetBgNoise()
				
				-- If the received signal after noise is less than the receiver's sensitivity threshold, then the data received is just random noise
				if dBm < GetConVarNumber("sv_rs_rxsensitivitythreshold") then
					sig = math.random() * 1000
				end
				
				local receiveCh = 0
				
				if freq >= self.Inputs.BaseMHz.Value and freq < self.Inputs.BaseMHz.Value + 5 then
					receiveCh = 1
				elseif freq >= self.Inputs.BaseMHz.Value + 5 and freq < self.Inputs.BaseMHz.Value + 10 then
					receiveCh = 2
				elseif freq >= self.Inputs.BaseMHz.Value + 10 and freq < self.Inputs.BaseMHz.Value + 15 then
					receiveCh = 3
				elseif freq >= self.Inputs.BaseMHz.Value + 15 and freq < self.Inputs.BaseMHz.Value + 20 then
					receiveCh = 4
				elseif freq >= self.Inputs.BaseMHz.Value + 20 and freq < self.Inputs.BaseMHz.Value + 25 then
					receiveCh = 5
				elseif freq >= self.Inputs.BaseMHz.Value + 25 and freq < self.Inputs.BaseMHz.Value + 30 then
					receiveCh = 6
				elseif freq >= self.Inputs.BaseMHz.Value + 30 and freq < self.Inputs.BaseMHz.Value + 35 then
					receiveCh = 7
				elseif freq >= self.Inputs.BaseMHz.Value + 35 and freq < self.Inputs.BaseMHz.Value + 40 then
					receiveCh = 8
				end
				
				if receiveCh ~= 0 then
					local c = tostring(receiveCh)
					Wire_TriggerOutput(self.Entity, "Channel" .. c, sig)
					Wire_TriggerOutput(self.Entity, "Ch" .. c .. "dBm", dBm)
					setset[receiveCh] = true
				end
			end
		end
		
		-- set the remaining channels randomly
		for i=1,8 do
			if not setset[i] then
				Wire_TriggerOutput(self.Entity, "Channel" .. tostring(i), math.random() * 10)
				Wire_TriggerOutput(self.Entity, "Ch" .. tostring(i) .. "dBm", -math.random()*1000)
			end
		end
	end
	self.Entity:NextThink(CurTime() + ThinkInterval)
end
