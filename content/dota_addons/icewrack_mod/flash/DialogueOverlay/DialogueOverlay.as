package
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.TextFieldAutoSize;
	
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	
	public class DialogueOverlay extends MovieClip
	{
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		private var dialogueKV:Object;
		
		private var optionTextFormat:TextFormat = new TextFormat();
		private var optionsList:Vector.<TextField> = new Vector.<TextField>()
		
		private var nameTextFormat : TextFormat = new TextFormat();
		
		var nameTextField = new TextField();
		
		var titleNameField = new TextField();
		
		public function DialogueOverlay()
		{
			optionTextFormat.font = "$TitleFontBold";
		    optionTextFormat.size = 24;
		    optionTextFormat.color = 0xffffff;
		    optionTextFormat.align = TextFormatAlign.LEFT;
			
			nameTextFormat.font = "$TitleFontBold";
		    nameTextFormat.size = 36;
		    nameTextFormat.color = 0xffffff;
		    nameTextFormat.align = TextFormatAlign.LEFT;
		}
		
		public function onLoaded()
		{
			visible = true;
			
			globals.resizeManager.AddListener(this);
			
			dialogueKV = globals.GameInterface.LoadKVFile("scripts/npc/iw_game_states.txt");//globals.GameInterface.LoadKVFile("scripts\\npc\\iw_game_states.txt", "IcewrackGameStates", "");
			//C:\\Program Files (x86)\\Steam\\SteamApps\\common\\dota 2 beta\\dota_ugc\\game\\dota_addons\\icewrack_mod\\scripts\\npc\\
			trace(dialogueKV);
			
			for(var id:String in dialogueKV) {
				  var aaa:Object = dialogueKV[id];
				
				  trace(id + " = " + aaa);
				}
			nameTextField.defaultTextFormat = optionTextFormat;
			nameTextField.embedFonts = true;
			nameTextField.text = "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz";
			nameTextField.visible = true;
			nameTextField.multiline = true;
			nameTextField.wordWrap = true;
			nameTextField.autoSize = TextFieldAutoSize.LEFT;
			
			
			
			titleNameField.defaultTextFormat = nameTextFormat;
			titleNameField.embedFonts = true;
			titleNameField.text = "Name";
			titleNameField.visible = true;
			titleNameField.autoSize = TextFieldAutoSize.LEFT;
			
			this.overlay.choices.addChild(nameTextField);
			this.overlay.addChild(titleNameField);
			
			optionsList.push(nameTextField);
			
			titleNameField.width = 1000;
			titleNameField.x = 220;
			titleNameField.y = -236;
			
			nameTextField.width = 440;
			nameTextField.x = 0;
			nameTextField.y = 0;
			nameTextField.alpha = 0.75;
			trace("TEXT HEIGHT:: ")
			trace(nameTextField.height)
			var asdf = globals.GameInterface.LoadKVFile("C:\\Program Files (x86)\\Steam\\SteamApps\\common\\dota 2 beta\\dota_ugc\\game\\dota_addons\\icewrack_mod\\scripts\npc\\iw_game_states.txt", "hi", "");
			trace(describeType(asdf));
			var testing123 :Object = {  };
			var huh = "Hello lolz"
			testing123[huh] = "what?";
			testing123.asdf = "bbq//";
			globals.GameInterface.SaveKVFile(testing123, "C:\\Users\\Fangyuan Ding\\Downloads\\test.txt", "test", "");
			trace(globals.GameInterface.SaveKVFile)
		}/**/
		
		private function rebuildOptionsList() : void
		{
		}
		
		public function onResize(re:Object) : void
		{
			//calculate the scaling ratio in the X and Y direction and apply it to the state
			var resWidth:int = 0;
			var resHeight:int = 0;
			var i:int = 0;
			if (re.IsWidescreen()) 
			{
				if (re.Is16by9()) 
				{
					this.overlay.divider.x = 1280
					this.overlay.faderTop.width = this.overlay.faderBottom.width = 608
					this.overlay.faderTop.x = this.overlay.faderBottom.x = 1296
					
					
					
					titleNameField.width = 1020;
					nameTextField.width = 600;
					this.overlay.choices.width = this.overlay.choicesMask.width = 600
					this.overlay.choices.x = this.overlay.choicesMask.x = 1300
					
					/*for (i = 0; i < optionsList.length; i++)
					{
						optionsList[i].width = 600;
					}*/
					
					//this.overlay.asdf2.width = 1020
					//this.overlay.asdf2.x = 220
					
				}
				else 
				{
					this.overlay.divider.x = 1152
					this.overlay.faderTop.width = this.overlay.faderBottom.width = 544
					this.overlay.faderTop.x = this.overlay.faderBottom.x = 1168
					
					titleNameField.width = 892;
					nameTextField.width = 536;
					this.overlay.choices.width = this.overlay.choicesMask.width = 536
					this.overlay.choices.x = this.overlay.choicesMask.x = 1172
					
					/*for (i = 0; i < optionsList.length; i++)
					{
						optionsList[i].width = 536;
					}*/
					
					
					this.overlay.choices.scaleY = (11/15)
					//this.overlay.asdf2.width = 892
					//this.overlay.asdf2.x = 220
				}
			}
			else
			{
				this.overlay.divider.x = 960
				this.overlay.faderTop.width = this.overlay.faderBottom.width = 448
				this.overlay.faderTop.x = this.overlay.faderBottom.x = 978
					
					
				//364 * 
				titleNameField.width = 700;
				nameTextField.width = 440;
				//this.overlay.choices.width = this.overlay.choicesMask.width = 440
				this.overlay.choices.x = this.overlay.choicesMask.x = 982
				//this.overlay.choices.scaleX = this.overlay.choices.scaleY = re.ScreenWidth/1440.0;
				
				
				//trace("TEXT HEIGHT:: ")
				//trace(nameTextField.height)*/
				//this.overlay.asdf2.width = 700
				//this.overlay.asdf2.x = 220
			}

			//var maxStageHeight:int = re.ScreenHeight / re.ScreenWidth * resWidth;
			//var maxStageWidth:int = re.ScreenWidth / re.ScreenHeight * resHeight;
			this.overlay.x = 0;
			this.scaleX = this.scaleY = re.ScreenHeight / 1080.0
			trace(re.ScreenHeight + " " + re.ScreenWidth)
			trace("this.scaleY = " + this.scaleY)
		}
	}
	
}
