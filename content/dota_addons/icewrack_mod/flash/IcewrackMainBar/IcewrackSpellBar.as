package
{
	import flash.display.MovieClip;
	
	public class IcewrackSpellBar extends MovieClip 
	{
		public var gameAPI : Object;
		public var globals : Object;
		public var elementName : String;
		
		private static var knownList : Array = new Array;
		private var abilityIcons : Array = new Array(null, null, null, null, null, null);
		
		public function SnowOverlay() : void
		{
			// constructor code
		}
		
		public function onLoaded() : void 
		{
			visible = true;
			
			globals.resizeManager.AddListener(this);
			gameAPI.SubscribeToGameEvent("iw_ui_spellbar_return_abilities", OnUnitAbilityReturn);
			gameAPI.SubscribeToGameEvent("iw_ui_spellbar_send_known_list", OnSendKnownAbilityList);
			
			var args : Object = { ability1:"iw_empty", ability2:"iw_empty", ability3:"iw_empty", 
								  ability4:"iw_empty", ability5:"iw_empty", ability6:"iw_empty" };
			
			OnUnitAbilityReturn(args);
		}
		
		private function OnSendKnownAbilityList(args:Object) : void
		{
			if (args.ability_list != null)
			{
				knownList.length = 0;
				var abilities = args.ability_list.split(" ")
				for (var i:int = 0; i < abilities.length; i++)
				{
					knownList.push(abilities[i]);
				}
				
				for (i = 0; i < abilityIcons.length; i++)
				{
					var spellIcon : SpellIcon = abilityIcons[i] as SpellIcon;
					if (spellIcon != null)
					{
						spellIcon.DestroyTooltip();
						spellIcon.CreateTooltip(knownList);
					}
				}
			}
		}
		
		public static function GetKnownAbilityList() : Array
		{
			return knownList;
		}
		
		private function OnUnitAbilityReturn(args:Object) : void
		{
			var abilityNames:Array = new Array(args.ability1, args.ability2, args.ability3, args.ability4, args.ability5, args.ability6);
			for (var i:int = 5; i >= 0; i--)
			{
				if (abilityIcons[i] != null)
				{
					this.removeChild(abilityIcons[i]);
					abilityIcons[i] = null;
				}
				
				var spellIcon = new SpellIcon;
				spellIcon.Create(gameAPI, globals, abilityNames[i], i, 64);
				this.addChild(spellIcon);
				spellIcon.x = 578 + (i * 72);
				spellIcon.y = 1006;
				
				abilityIcons[i] = spellIcon;
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
