package
{
	import flash.display.MovieClip;
	
	public class IcewrackHPBar extends MovieClip
	{
		public var gameAPI : Object;
		public var globals : Object;
		public var elementName : String;
		
		private var modifierIcons : Array = new Array();
		
		public function IcewrackHPBar()
		{
			// constructor code
		}
		
		public function onLoaded() : void 
		{
			visible = false;
			
			globals.resizeManager.AddListener(this);
			
			gameAPI.SubscribeToGameEvent("iw_ui_hpbar_hide", OnHideRequest);
			gameAPI.SubscribeToGameEvent("iw_ui_hpbar_return_values", OnReturnValuesRequest);
			gameAPI.SubscribeToGameEvent("iw_ui_hpbar_start_modifiers", OnStartModifiers);
			gameAPI.SubscribeToGameEvent("iw_ui_hpbar_return_modifier", OnReturnModifierRequest);
			gameAPI.SubscribeToGameEvent("iw_ui_hpbar_finished_modifiers", OnFinishedModifiers);
		}
		
		public function OnHideRequest(args:Object) : void
		{
			visible = false;
		}
		
		public function OnReturnValuesRequest(args:Object) : void
		{
			trace(globals.Players.GetPlayerHeroEntityIndex( 0 ))
			if ((args.name != null) && (args.current_hp != null) && (args.maximum_hp != null) && (args.game_time != null))
			{
				hp_mask.scaleX = 2.0 * args.current_hp/args.maximum_hp;
				bar_text.unit_name.text = args.name;
				for (var i:int = 0; i < modifierIcons.length; i++)
				{
					if (modifierIcons[i] != null)
					{
						modifierIcons[i].SetTime(args.game_time);
					}
				}
				visible = true;
			}
		}
		
		public function OnStartModifiers(args:Object) : void
		{
			for (var i:int = 0; i < modifierIcons.length; i++)
			{
				if (modifierIcons[i] != null)
				{
					modifierIcons[i].visible = false;
					this.removeChild(modifierIcons[i]);
				}
			}
			modifierIcons.length = 0;
		}
		
		public function ModifierSort(v1, v2) : int
		{
			var t1 = v1.GetEndTime()
			var t2 = v2.GetEndTime()
			
			if (t1 == 0) { t1 = 999999999 }
			if (t2 == 0) { t1 = 999999999 }
			
			if (t1 > t2)      { return 1 }
			else if (t1 < t2) { return -1; }
			else              { return 0;  }
		}
		
		public function OnFinishedModifiers(args:Object) : void
		{
			modifierIcons.sort(ModifierSort);
			var counter = 0;
			for (var i:int = 0; i < modifierIcons.length; i++)
			{
				if (modifierIcons[i] != null)
				{
					modifierIcons[i].visible = true;
					modifierIcons[i].x = 820 + ((counter % 8) * 40);
					modifierIcons[i].y = 108 + (int(counter/8) * 40);
					counter++;
				}
			}
		}
		
		public function OnReturnModifierRequest(args:Object) : void
		{
			var size = modifierIcons.push(new ModifierIcon);
			var modIcon = modifierIcons[size-1];
			modIcon.Create(gameAPI, globals, args);
			this.addChild(modIcon);
		}
		
		public function onResize(re:Object) : void
		{
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
