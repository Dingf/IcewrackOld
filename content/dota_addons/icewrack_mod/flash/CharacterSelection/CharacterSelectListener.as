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
		public var gameAPI : Object;
		public var globals : Object;
		public var elementName : String;
		
		private var queryTimer : Timer;
		private var queriedEnthandle : Number = -1;
		
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
			
			names["npc_dota_hero_sven"] = "Sven, Rogue Knight";
			names["npc_dota_hero_dragon_knight"] = "Davion, Dragon Knight";
			names["npc_dota_hero_drow_ranger"] = "Traxex, Drow Ranger";
			names["npc_dota_hero_bounty_hunter"] = "Gondar, Bounty Hunter";
			names["npc_dota_hero_lina"] = "Lina, the Slayer";
			names["npc_dota_hero_warlock"] = "Demnok, Warlock";
			
			lores["npc_dota_hero_sven"] = "Rogue Knight follows his own path.";
			lores["npc_dota_hero_drow_ranger"] = "I am Traxex, ranger of the Drow. Or so I've been called. But the truth is, I am not a Drow... nor Keen, nor Oglodi, nor any other race that I've seen so far. Which leaves me wondering: What am I?\n\nThe Drow used to tell me of my parents, refugees from the far north who were mercilessly cut down by bandits. It is this reason alone that brings me here. In this frozen wasteland, I wonder, which will I find first - the answers that I seek, or my fate?";
			lores["npc_dota_hero_lina"] = "God, I really hate my sissster sometimes. It's b-bad enough that she alwaysss played the favorite, or that shhhe got me shipped off to some d-desert in the middle of nowhere. N-no no, that'sss not enough for poor Rylai. She just HAD to ssstart a veritable ice age to make me m-miserable forever, didn't she?\n\nSssoo c-cold... I swear, when I f-find her...";
			lores["npc_dota_hero_warlock"] = "Like moths to a flame, these fools come, searching for fame and fortune. Ha! The real treasure lies far, far deeper. Can you not hear it? The trembling whispers of shadows, their dark promises of power emanating from beneath the icy earth. All for one who knows where to look. . .\n\nAlas, this land is dangerous and untamed. If I am to succeed in this endeavor, I shall require allies to command - human, or otherwise. . .";
			
			
			







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
					loreTextField.x = re.ScreenWidth * (61/192);
				}
				else 
				{
					nameTextField.scaleX = nameTextField.scaleY = re.ScreenWidth/1728.0;
					nameTextField.width = 1728;
					loreTextField.scaleX = loreTextField.scaleY = re.ScreenWidth/1728.0;
					loreTextField.x = re.ScreenWidth * (257/864);
				}
			}
			else
			{
				nameTextField.scaleX = nameTextField.scaleY = re.ScreenWidth/1440.0;
				nameTextField.width = 1440;
				loreTextField.scaleX = loreTextField.scaleY = re.ScreenWidth/1440.0;
				loreTextField.x = re.ScreenWidth * (37/144);
			}

			var maxStageHeight:int = re.ScreenHeight / re.ScreenWidth * resWidth;
			var maxStageWidth:int = re.ScreenWidth / re.ScreenHeight * resHeight;

			nameTextField.x = 0;
			nameTextField.y = re.ScreenHeight/4.8;
			nameTextField.height = 500;
			loreTextField.width = 700;
			loreTextField.y = re.ScreenHeight/4.0;
			loreTextField.height = 1000;

			//this.scaleX = this.scaleY = 
			trace(re.ScreenHeight + " " + re.ScreenWidth)
			trace("this.scaleY = " + this.scaleY)
		}
	}
}