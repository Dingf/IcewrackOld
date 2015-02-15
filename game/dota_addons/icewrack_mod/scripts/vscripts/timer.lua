--[[
    Timers
]]

TIMER_THINK_INTERVAL = 0.03
TIMER_CLEANUP_INTERVAL = 10.0
TIMER_STOP = -1

if CTimer == nil then
    CTimer = class({constructor = function(self, hCallback, fDuration, fFrequency, fDelay, bIgnorePause)
        if not hCallback then
            error("Error creating timer: hCallback is missing or nil")
        end
        if not fDuration or fDuration < 0 then
            error("Error creating timer: fDuration must be greater than or equal to zero")
        end
        if fFrequency and fFrequency <= 0 then
            error("Error creating timer: fFrequency must be greater than zero if defined")
        end
		if fDelay and fDelay < 0 then
            error("Error creating timer: fDelay must be greater than or equal to zero if defined")
		end

        self._hCallback = hCallback
        self._fDuration = fDuration
        self._fFrequency = fFrequency
		self._bIgnorePause = bIgnorePause
		self._fStartTime = bIgnorePause and Time() or GameRules:GetGameTime()
		self._fLastTickTime = self._fStartTime
		
		if fDelay then
			self._fStartTime = self._fStartTime + fDelay
		end
        
        table.insert(CTimer._stTimerList, self)
    end},
    {_stTimerList = {}}, nil)
end

function CTimer:GetEndTime()
	return self._fStartTime + self._fDuration
end

function CTimer:ResetTimer(fStartTime)
	self._fStartTime = fStartTime
end

function ClearTimers()
    CTimer._stTimerList = {}
end

function ProcessTimers()
    local fRealTime = Time()
	local fGameTime = GameRules:GetGameTime()
    for k,v in pairs(CTimer._stTimerList) do
        if v then
			local fThinkTime = v._bIgnorePause and fRealTime() or fGameTime
			if fThinkTime >= v._fStartTime then
				--A zero duration timer will run indefinitely
				if v._fDuration and v._fDuration ~= 0.0 and fThinkTime >= v._fStartTime + v._fDuration then
					v._hCallback()
					CTimer._stTimerList[k] = nil
				elseif v._fFrequency and fThinkTime >= v._fLastTickTime + v._fFrequency then
					if v._hCallback() == TIMER_STOP then
						CTimer._stTimerList[k] = nil
					end
					v._fLastTickTime = v._fLastTickTime + v._fFrequency
				end
			end
        end
    end
    return TIMER_THINK_INTERVAL
end
