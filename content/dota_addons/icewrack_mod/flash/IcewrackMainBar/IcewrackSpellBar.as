﻿package
{
	import flash.display.MovieClip;

	public class IcewrackSpellBar extends MovieClip 
	{
		public var gameAPI : Object;
		public var globals : Object;
		public var elementName : String;
		
		private static var knownList : Array = new Array;
		private var abilityIcons : Array = new Array(null, null, null, null, null, null);
		//private var abilityIconExtras : Array = new Array(null, null, null, null, null, null);
		
		public function IcewrackSpellBar() : void
		{
			// constructor code
		}
		
		public function onLoaded() : void 
		{
			visible = true;
			
			gameAPI.OnUnload = this.OnUnload;
			globals.resizeManager.AddListener(this);
			gameAPI.SubscribeToGameEvent("iw_ui_spellbar_return_ability", OnUnitAbilityReturn);
			gameAPI.SubscribeToGameEvent("iw_ui_spellbar_send_known_list", OnSendKnownAbilityList);
			gameAPI.SubscribeToGameEvent("iw_ui_mainbar_set_visible", OnSetVisible);
			
			for (var i:int = 0; i < 6; i++)
			{
				var args:Object = { slot:i, level:0, ability_name:"empty", mana_cost:0, stamina_cost:0 }
				OnUnitAbilityReturn(args);
			}
		}
		
		public function OnUnload() : Boolean
		{
			for (var i:int = 0; i < 6; i++)
			{
				if (abilityIcons[i] != null)
				{
					abilityIcons[i].OnUnload();
				}
			}
			return true;
		}
		
		private function OnSetVisible(args:Object) : void
		{
			if (args != null)
			{
				trace("Setting IcewrackSpellBar to")
				trace(args.is_visible)
				this.visible = args.is_visible; 
			}
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
			if (args != null)
			{
				var slot = args.slot
				if ((slot >= 0) && (slot < 6))
				{
					if (abilityIcons[slot] != null)
					{
						abilityIcons[slot].OnUnload();
						this.removeChild(abilityIcons[slot]);
						abilityIcons[slot] = null;
					}
						
					var spellIcon = new SpellIcon;
					spellIcon.Create(gameAPI, globals, args.ability_name, slot, 64);
					this.addChild(spellIcon);
					spellIcon.x = 578 + (slot * 72);
					spellIcon.y = 1006;
					abilityIcons[slot] = spellIcon;
					spellIcon.CreateExtras(args.mana_cost, args.stamina_cost);
					if (args.cd_start != args.cd_end)
					{
						spellIcon.SetCooldown(args.cd_start, args.cd_end);
					}
					if (args.level == 0)
					{
						spellIcon.SetActive(false);
					}
					spellIcon.OnUpdate();
				}
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
