package 
{
	import flash.display.MovieClip;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	public class IcewrackMainBar extends MovieClip
	{
		//these three variables are required by the engine
		public var gameAPI : Object;
		public var globals : Object;
		public var elementName : String;
		
		private var abilityIcons : Array = new Array(null, null, null, null, null, null);
		private var snowOverlay : MovieClip;
		
		private var selectedEntindex : Number = 0;
		private var selectionTimer : Timer;
		
		public function IcewrackMainBar() : void 
		{
		}
		
		public function onLoaded() : void 
		{
			visible = true;
			
			globals.resizeManager.AddListener(this);
			
			gameAPI.OnUnload = this.OnUnload;
			gameAPI.SubscribeToGameEvent("iw_ui_mainbar_return_values", OnUnitValuesReturn);
			//gameAPI.SubscribeToGameEvent("iw_ui_mainbar_return_abilities", OnUnitAbilityReturn);
						
			selectionTimer = new Timer(100.0);
			selectionTimer.addEventListener(TimerEvent.TIMER, QueryUnit);
			selectionTimer.start();
		}
		
		public function OnUnload() : Boolean
		{
			selectionTimer.stop();
			return true;
		}
		
		private function QueryUnit(e:TimerEvent) : void
		{
			if (globals != null)
			{
				var playerID = globals.Players.GetLocalPlayer();
				var selectedEntities = globals.Players.GetSelectedEntities(playerID);
				if ((selectedEntities != null) && (selectedEntities.length > 0))
				{
					if (selectedEntindex != selectedEntities[0])
					{
						selectedEntindex = selectedEntities[0];
						gameAPI.SendServerCommand("iw_ui_mainbar_request_abilities " + selectedEntities[0]);
						gameAPI.SendServerCommand("iw_ui_mainbar_request_known_list " + selectedEntities[0]);
					}
					gameAPI.SendServerCommand("iw_ui_mainbar_request_values " + selectedEntities[0]);
				}
				else
				{
					selectedEntindex = 0;
					xp_bar.width = 0;
					mp_mask.rotation = 180;
					sp_mask.rotation = -180;
					hp_bar.hp_percent.scaleY = 2.0;
					mp_indicator.visible = false;
					sp_indicator.visible = false;
				}
			}
		}
		
		private function OnUnitValuesReturn(args:Object) : void
		{
			if (args != null)
			{
				mp_mask.rotation = (args.maximum_mp == 0) ? 180.0 : (1.0 - (args.current_mp/args.maximum_mp)) * 180.0;
				sp_mask.rotation = (args.maximum_sp == 0) ? -180.0 : (1.0 - (args.current_sp/args.maximum_sp)) * -180.0;
				
				hp_bar.hp_percent.scaleY = (args.maximum_hp == 0) ? 1.0 : (1.0 - (args.current_hp/args.maximum_hp)) * 1.0;
				hp_bar.hp_percent.visible = (hp_bar.hp_percent.scaleY >= 0.01);
				
				xp_bar.width = (args.current_xp/args.maximum_xp) * 320.0;
				
				mp_indicator.rotation = mp_mask.rotation * 0.975;
				mp_indicator.visible = ((mp_mask.rotation != 0) && (mp_mask.rotation != 180.0));
				sp_indicator.rotation = sp_mask.rotation * 0.975;
				sp_indicator.visible = ((sp_mask.rotation != 0) && (sp_mask.rotation != -180.0));
				
				var values = IcewrackValues.GetInstance();
				values.currentHP = args.current_hp;
				values.maximumHP = args.maximum_hp;
				values.currentMP = args.current_mp;
				values.maximumMP = args.maximum_mp;
				values.currentSP = args.current_sp;
				values.maximumSP = args.maximum_sp;
				values.currentXP = args.current_xp;
				values.maximumXP = args.maximum_xp;
			}
		}
		
		//this handles the resizes - credits to SinZ
		public function onResize(re:Object) : void
		{
			//calculate the scaling ratio in the X and Y direction and apply it to the state
			var resWidth:int = 0;
			var resHeight:int = 0;
			if (re.IsWidescreen()) 
			{
				if (re.Is16by9()) 
				{
					//16:9
					resWidth = 1600;
					resHeight = 900;
					
				} else 
				{
					//16:10
					resWidth = 1280;
					resHeight = 768;
				}
			} else {
				//4:3
				resWidth = 1024;
				resHeight = 768;
			}

			var maxStageHeight:int = re.ScreenHeight / re.ScreenWidth * resWidth;
			var maxStageWidth:int = re.ScreenWidth / re.ScreenHeight * resHeight;

			this.scaleX = this.scaleY = re.ScreenHeight / 1080.0
			trace(re.ScreenHeight + " " + re.ScreenWidth)
			trace("this.scaleY = " + this.scaleY)
		}
	}
}