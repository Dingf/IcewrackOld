package
{
	import flash.display.MovieClip;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	
	public class SpellIconExtras extends MovieClip
	{
		private var manaCost:Number = 0;
		private var staminaCost:Number = 0;
		
		private var cooldownStart:Number = 0;
		private var cooldownEnd:Number = 0;
		private var cooldownTime:Number = 0;
		
		private var updateTimer:Timer = null;
		
		private var leftCDTween:Tween = null;
		private var rightCDTween:Tween = null;
		
		public function SpellIconExtras(manaCost:Number, staminaCost:Number)
		{
			visible = true;
			cd.visible = false;
			oom.visible = false;
			oos.visible = false;
			ooms.visible = false;
			SetManaCost(manaCost);
			SetStaminaCost(staminaCost);
		}
		
		public function OnUnload()
		{
			if (updateTimer != null)
			{
				updateTimer.stop();
				updateTimer = null;
			}
		}
		
		public function GetManaCost() : Number
		{
			return this.manaCost;
		}
		
		public function GetStaminaCost() : Number
		{
			return this.staminaCost;
		}
		
		public function SetManaCost(cost:Number) : void
		{
			if (cost > 0)
			{
				mana.visible = true;
				mana.manaText.text = cost.toString();
				this.manaCost = cost;
			}
			else
			{
				mana.visible = false;
			}
		}
		
		public function SetStaminaCost(cost:Number) : void
		{
			if (cost > 0)
			{
				stamina.visible = true;
				stamina.staminaText.text = cost.toString();
				this.staminaCost = cost;
			}
			else
			{
				stamina.visible = false;
			}
		}
		
		public function OnUpdate() : void
		{
			if ((cooldownStart != 0) || (cooldownEnd != 0))
			{
				cooldownTime += 0.1
				var percentage = (cooldownTime > cooldownEnd) ? 1.0 : (cooldownTime - cooldownStart)/(cooldownEnd - cooldownStart);
				var secondsLeft = int(cooldownEnd - cooldownTime) + 1;
				cd.cdText.text = secondsLeft.toString();
				if ((percentage > 0.5) && (leftCDTween == null))
				{
					leftCDTween = new Tween(cd.left_mask, "rotation", None.easeNone, 0, 180, (cooldownEnd - cooldownStart)/2.0, true);
					leftCDTween.start();
					cd.right_cd.visible = false;
				}
				if (percentage >= 1.0)
				{
					updateTimer.stop();
					updateTimer = null;
					cooldownStart = 0;
					cooldownEnd = 0;
					cd.visible = false;
					if (leftCDTween != null)
					{
						leftCDTween.stop();
						leftCDTween = null;
					}
					if (rightCDTween != null)
					{
						rightCDTween.stop();
						rightCDTween = null;
					}
				}
			}
		}
		
		public function SetCooldown(cdStart:Number, cdEnd:Number) : void
		{
			cd.visible = true;
				
			cooldownStart = cdStart;
			cooldownEnd = cdEnd;
			cooldownTime = 0;
			
			if (leftCDTween != null)
			{
				leftCDTween.stop();
				leftCDTween = null;
			}
			if (rightCDTween != null)
			{
				rightCDTween.stop();
				rightCDTween = null;
			}
			
			var turnPercent;
			var halfTime = cooldownStart + (cooldownEnd - cooldownStart)/2.0;
			if (halfTime >= 0)
			{
				turnPercent = 1.0 + (-2.0 * halfTime)/(cooldownEnd - cooldownStart)
				rightCDTween = new Tween(cd.right_mask, "rotation", None.easeNone, turnPercent * 180.0, 180, halfTime, true);
				rightCDTween.start();
			}
			else
			{
				turnPercent = (-2.0 * halfTime)/(cooldownEnd - cooldownStart)
				leftCDTween = new Tween(cd.left_mask, "rotation", None.easeNone, turnPercent * 180.0, 180, (cooldownEnd - cooldownStart)/2.0 + halfTime, true);
				leftCDTween.start();
				cd.right_cd.visible = false;
			}
			OnUpdate();
			updateTimer = new Timer(100);
			updateTimer.addEventListener(TimerEvent.TIMER, OnUpdate);
			updateTimer.start();
		}
	}
	
}
