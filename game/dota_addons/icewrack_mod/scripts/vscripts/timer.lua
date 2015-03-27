--[[
    Timers
]]

TIMER_THINK_INTERVAL = 0.03
TIMER_STOP = -1

if CTimer == nil then
    CTimer = class({constructor = function(self, hCallback, fDuration, fFrequency, fDelay, bUseRealTime)
        if not hCallback then
            error("Error creating timer: hCallback is missing or nil")
        end
        if not fDuration or fDuration < 0 then
            error("Error creating timer: fDuration must be greater than or equal to zero")
        end
        if fFrequency and fFrequency <= 0 then
            error("Error creating timer: fFrequency must be greater than zero if defined")
        end

		self._bPauseFlag = false
		self._bStopFlag = false
        self._hCallback = hCallback
        self._fDuration = fDuration
        self._fFrequency = fFrequency
		self._bUseRealTime = bUseRealTime
		if self._bUseRealTime == nil then
			self._bUseRealTime = false
		end
		self._fStartTime = self._bUseRealTime and Time() or GameRules:GetGameTime()
		if fDelay then
			self._fStartTime = self._fStartTime + fDelay
		end
		self._fLastTickTime = self._fStartTime
		self._fPauseTime = 0
        
        table.insert(CTimer._stTimerList, self)
    end},
    { _stTimerList = {},
	  _shTimerDummy = nil }, nil)
end

function CTimer:GetEndTime()
	return self._fStartTime + self._fDuration
end

function CTimer:PauseTimer()
	if not self._bPauseFlag then
		self._bPauseFlag = true
		self._fPauseTime = self._bUseRealTime and Time() or GameRules:GetGameTime()
	end
end

function CTimer:UnpauseTimer()
	if self._bPauseFlag then
		self._bPauseFlag = false
		local fCurrentTime = self._bUseRealTime and Time() or GameRules:GetGameTime()
		self._fStartTime = self._fStartTime + (fCurrentTime - fPauseTime)
	end
end

function CTimer:StopTimer()
	self._bStopFlag = true
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
			if v._bStopFlag then
				CTimer._stTimerList[k] = nil
			elseif not v._bPauseFlag then
				local fThinkTime = v._bUseRealTime and fRealTime or fGameTime
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
    end
    return TIMER_THINK_INTERVAL
end

CTimer._shTimerDummy = CreateUnitByName("iw_npc_generic_dummy", Vector(0, 0, 0), false, nil, nil, 0)
if IsValidEntity(CTimer._shTimerDummy) then
	CTimer._shTimerDummy:AddAbility("internal_dummy_buff")
	CTimer._shTimerDummy:FindAbilityByName("internal_dummy_buff"):SetLevel(1)
	CTimer._shTimerDummy:SetThink(ProcessTimers, "TimerThink", TIMER_THINK_INTERVAL)
end
