package
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.TextFieldAutoSize;
	
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.events.MouseEvent;
	
	public class DialogueOverlay extends MovieClip
	{
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		private var dialogueKV:Object;
		
		private var screenWidth:Number = 0;
		private var screenHeight:Number = 0;
		
		private var normalTextFormat:TextFormat = new TextFormat();
		private var titleTextFormat:TextFormat = new TextFormat();
		
		private var nameTextField:TextField = new TextField();
		private var dialogueTextField:TextField = new TextField();
		private var optionsList:Vector.<TextField> = new Vector.<TextField>();
		
		private var optionsScrollTween:Tween;
		
		public function DialogueOverlay()
		{
			this.overlay.faderTop.mouseEnabled = false;
			this.overlay.faderBottom.mouseEnabled = false;
			
			normalTextFormat.font = "$TitleFont";
		    normalTextFormat.size = 20;
		    normalTextFormat.color = 0xffffff;
		    normalTextFormat.align = TextFormatAlign.LEFT;
			
			titleTextFormat.font = "$TitleFontBold";
		    titleTextFormat.size = 36;
		    titleTextFormat.color = 0xffffff;
		    titleTextFormat.align = TextFormatAlign.LEFT;
			
			nameTextField.defaultTextFormat = titleTextFormat;
			nameTextField.embedFonts = true;
			nameTextField.text = "Name";
			nameTextField.visible = true;
			nameTextField.autoSize = TextFieldAutoSize.LEFT;
			
			dialogueTextField.defaultTextFormat = normalTextFormat;
			dialogueTextField.embedFonts = true;
			dialogueTextField.text = "Roses are red, violets are blue. This text is hidden, now go away. Shoo!";
			dialogueTextField.visible = true;
			dialogueTextField.multiline = true;
			dialogueTextField.wordWrap = true;
			dialogueTextField.autoSize = TextFieldAutoSize.LEFT;
			
			this.overlay.addChild(nameTextField);
			this.overlay.addChild(dialogueTextField);
			
			nameTextField.width = 1000;
			nameTextField.x = 220;
			nameTextField.y = -236;
			
			dialogueTextField.width = 1000;
			dialogueTextField.x = 220;
			dialogueTextField.y = -192;
			dialogueTextField.alpha = 0.75;
			
			AddOption("Lorem ipsum dolor sit amet. (Persuade)");
			AddOption("The quick brown fox jumped over the lazy dog. (Bribe)");
			AddOption("And the moon too, because why the fuck not. (Intimidate)");
			
			ResizeOptionList();
		}
		
		public function onLoaded()
		{
			visible = true;
			
			globals.resizeManager.AddListener(this);
			dialogueKV = globals.GameInterface.LoadKVFile("scripts/npc/iw_dialogue_states.txt");
		}
		
		private function OnOptionMouseOver(e:MouseEvent)
		{
			e.target.alpha = 1.0;
			if (optionsScrollTween != null)
			{
				optionsScrollTween.stop();
			}
			optionsScrollTween = new Tween(this.overlay.choices, "y", Regular.easeOut, this.overlay.choices.y, -128.0 - (e.target.y + (e.target.height)/2), 0.5, true);
			optionsScrollTween.start();
		}
		
		private function OnOptionMouseOut(e:MouseEvent)
		{
			e.target.alpha = 0.5;
		}
		
		private function AddOption(optionText:String) : void
		{
			var optionTextField = new TextField();
			optionTextField.defaultTextFormat = normalTextFormat;
			optionTextField.embedFonts = true;
			optionTextField.text = optionText;
			optionTextField.visible = true;
			optionTextField.multiline = true;
			optionTextField.wordWrap = true;
			optionTextField.autoSize = TextFieldAutoSize.LEFT;
			optionTextField.alpha = 0.5;
			optionTextField.x = 0;
			optionTextField.y = 0;
			
			optionTextField.addEventListener(MouseEvent.ROLL_OVER, OnOptionMouseOver);
			optionTextField.addEventListener(MouseEvent.ROLL_OUT, OnOptionMouseOut);
			
			this.overlay.choices.addChild(optionTextField);
			optionsList.push(optionTextField);
		}
		
		private function ResizeOptionList() : void
		{
			var currentY:Number = 0;
			for (var i:int = 0; i < optionsList.length; i++)
			{
				var optionTextField = optionsList[i];
				if ((screenHeight * 16)/9 == screenWidth)
					optionTextField.width = 600;
				else if ((screenHeight * 16)/10 == screenWidth)
					optionTextField.width = 536;
				else
					optionTextField.width = 440;
				optionTextField.y = currentY;
				currentY += optionTextField.height;
			}
			
			var middleOption = optionsList[int(optionsList.length/2)]
			this.overlay.choices.y = -128.0 - (middleOption.y + (middleOption.height)/2) 
		}
		
		public function onResize(re:Object) : void
		{
			screenWidth = re.ScreenWidth;
			screenHeight = re.ScreenHeight;
			if (re.IsWidescreen()) 
			{
				if (re.Is16by9()) 
				{
					this.overlay.divider.x = 1280
					this.overlay.faderTop.width = this.overlay.faderBottom.width = 608
					this.overlay.faderTop.x = this.overlay.faderBottom.x = 1296
					this.overlay.choices.x = this.overlay.choicesMask.x = 1300
					nameTextField.width = dialogueTextField.width = 1020;
					
				}
				else 
				{
					this.overlay.divider.x = 1152
					this.overlay.faderTop.width = this.overlay.faderBottom.width = 544
					this.overlay.faderTop.x = this.overlay.faderBottom.x = 1168
					this.overlay.choices.x = this.overlay.choicesMask.x = 1172
					nameTextField.width = dialogueTextField.width = 892;
				}
			}
			else
			{
				this.overlay.divider.x = 960
				this.overlay.faderTop.width = this.overlay.faderBottom.width = 448
				this.overlay.faderTop.x = this.overlay.faderBottom.x = 978
				this.overlay.choices.x = this.overlay.choicesMask.x = 982
				nameTextField.width = dialogueTextField.width = 700;
			}

			ResizeOptionList();
			this.overlay.x = 0;
			this.scaleX = this.scaleY = re.ScreenHeight / 1080.0
			trace(re.ScreenHeight + " " + re.ScreenWidth)
			trace("this.scaleY = " + this.scaleY)
		}
	}
	
}
