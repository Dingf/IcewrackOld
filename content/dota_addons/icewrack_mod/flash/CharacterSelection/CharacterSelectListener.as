package
{
	import flash.display.MovieClip;
	import flash.utils.Timer;
	import flash.utils.Dictionary;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.TextFieldAutoSize;
	import flash.filters.DropShadowFilter;
	
	public class CharacterSelectListener extends MovieClip
	{
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		private var queryTimer:Timer;
		private var queriedEnthandle:Number = -1;
		
		private var nameTextField:TextField = new TextField();
		private static var names:Dictionary = new Dictionary();
		
		private var loreTextField:TextField = new TextField();
		private static var lores:Dictionary = new Dictionary();
		
		public function CharacterSelectListener() {}
		
		public function onLoaded() : void 
		{
			visible = true;
			gameAPI.OnUnload = this.OnUnload;
			
			globals.resizeManager.AddListener(this);
			
			var heroList:Array = new Array("npc_dota_hero_sven",
										   "npc_dota_hero_dragon_knight",
										   "npc_dota_hero_drow_ranger",
										   "npc_dota_hero_bounty_hunter",
										   "npc_dota_hero_lina",
										   "npc_dota_hero_warlock");
			
			for (var i:String in heroList)
			{
				var heroName = heroList[i];
				names[heroName] = globals.GameInterface.Translate("#fullname_" + heroName);
				lores[heroName] = globals.GameInterface.Translate("#intro_" + heroName);
			}
			
			var nameTextFormat:TextFormat = new TextFormat();
			nameTextFormat.font = "$TitleFontBold";
		    nameTextFormat.size = 36;
		    nameTextFormat.color = 0xffffff;
		    nameTextFormat.align = TextFormatAlign.CENTER;

			nameTextField.defaultTextFormat = nameTextFormat;
			nameTextField.embedFonts = true;
			nameTextField.text = "Hey! You're not supposed to see this! Shoo.";
			nameTextField.visible = false;
			
			var loreTextFormat:TextFormat = new TextFormat();
			loreTextFormat.font = "$TextFontBold";
		    loreTextFormat.size = 20;
		    loreTextFormat.color = 0xc0c0c0;
		    loreTextFormat.align = TextFormatAlign.CENTER;
			
			var dsFilter:DropShadowFilter = new DropShadowFilter(0, 90, 0x000000, 0.75, 4, 4, 1.0);

			loreTextField.defaultTextFormat = loreTextFormat;
			loreTextField.embedFonts = true;
			loreTextField.multiline = true;
			loreTextField.wordWrap = true;
			loreTextField.autoSize = TextFieldAutoSize.CENTER;
			loreTextField.text = "I said shoo. Go on now.";
			loreTextField.filters = [dsFilter];
			loreTextField.visible = false;

			addChild(nameTextField);
			addChild(loreTextField);
						
			queryTimer = new Timer(100.0);
			queryTimer.addEventListener(TimerEvent.TIMER, QueryUnit);
			queryTimer.start();
		}
		
		public function OnUnload() : Boolean
		{
			queryTimer.stop();
			return true;
		}
		
		private function QueryUnit(e:TimerEvent) : void
		{
			if (globals != null)
			{
				var playerID = globals.Players.GetLocalPlayer();
				var queriedUnit = globals.Players.GetQueryUnit(playerID);
				if (queriedUnit != queriedEnthandle)
				{
					if (queriedUnit != -1)
					{
						var classname:String = globals.Entities.GetClassname(queriedUnit);
						if (classname != null)
						{
							gameAPI.SendServerCommand("iw_ui_character_select_update " + classname);
							if (names[classname] != null)
							{
								nameTextField.text = names[classname];
								nameTextField.visible = true;
							}
							else
							{
								nameTextField.visible = false;
							}
							
							if (lores[classname] != null)
							{
								loreTextField.text = lores[classname];
								loreTextField.visible = true;
							}
							else
							{
								loreTextField.visible = false;
							}
						}
					}
					else
					{
						gameAPI.SendServerCommand("iw_ui_character_select_update clear");
						nameTextField.visible = false;
						loreTextField.visible = false;
					}
					queriedEnthandle = queriedUnit;
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
					nameTextField.scaleX = nameTextField.scaleY = re.ScreenWidth/1920.0;
					nameTextField.width = 1920;
					loreTextField.scaleX = loreTextField.scaleY = re.ScreenWidth/1920.0;
					loreTextField.x = re.ScreenWidth * (5/16);
				}
				else 
				{
					nameTextField.scaleX = nameTextField.scaleY = re.ScreenWidth/1728.0;
					nameTextField.width = 1728;
					loreTextField.scaleX = loreTextField.scaleY = re.ScreenWidth/1728.0;
					loreTextField.x = re.ScreenWidth * (7/24);
				}
			}
			else
			{
				nameTextField.scaleX = nameTextField.scaleY = re.ScreenWidth/1440.0;
				nameTextField.width = 1440;
				loreTextField.scaleX = loreTextField.scaleY = re.ScreenWidth/1440.0;
				loreTextField.x = re.ScreenWidth * 0.25;
			}

			var maxStageHeight:int = re.ScreenHeight / re.ScreenWidth * resWidth;
			var maxStageWidth:int = re.ScreenWidth / re.ScreenHeight * resHeight;

			nameTextField.x = 0;
			nameTextField.y = re.ScreenHeight/4.8;
			nameTextField.height = 500;
			loreTextField.width = 720;
			loreTextField.y = re.ScreenHeight/4.0;
			loreTextField.height = 1000;

			//this.scaleX = this.scaleY = 
			trace(re.ScreenHeight + " " + re.ScreenWidth)
			trace("this.scaleY = " + this.scaleY)
		}
	}
}