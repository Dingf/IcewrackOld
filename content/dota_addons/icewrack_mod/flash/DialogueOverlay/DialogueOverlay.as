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
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	public class DialogueOverlay extends MovieClip
	{
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		private var dialogueKV:Object;
		private var dialogueNodeID:String;
		
		private var screenWidth:Number = 0;
		private var screenHeight:Number = 0;
		
		private var normalTextFormat:TextFormat = new TextFormat();
		private var titleTextFormat:TextFormat = new TextFormat();
		
		private var nameTextField:TextField = new TextField();
		private var dialogueTextField:TextField = new TextField();
		private var optionsList:Vector.<TextField> = new Vector.<TextField>();
		
		private var optionsScrollTween:Tween = null;
		private var overlayFadeTween:Tween = null;
		private var overlayFadeTimer:Timer;
		
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
			
			ResizeOptionsList();
		}
		
		public function onLoaded()
		{
			this.overlay.alpha = 0;
			this.overlay.faderTop.visible = false;
			this.overlay.faderBottom.visible = false;
			this.overlay.choices.visible = false;
			
			globals.resizeManager.AddListener(this);
			globals.GameInterface.AddMouseInputConsumer();
			
			dialogueKV = globals.GameInterface.LoadKVFile("scripts/npc/iw_dialogue_nodes.txt");
			
			gameAPI.SubscribeToGameEvent("iw_ui_dialogue_set_node", OnSetDialogueNode);
		}
		
		private function LoadDialogueNode(node:String)
		{
			if ((node != null) && (dialogueKV[node] != null))
			{
				dialogueNodeID = node;
				
				var dialogueNode:Object = dialogueKV[node]
				dialogueTextField.text = dialogueNode["Text"];
				
				ClearOptionsList();
				for (var i:int = 1;; i++)
				{
					var option:Object = dialogueNode["Options"][i.toString()];
					if (option == null)
						break;
					AddOption(option["Text"]);
					var preconditions:Object = option["Preconditions"];
					if (preconditions != null)
					{
						var skipFlag:Boolean = false;
						for (var k:String in preconditions)
						{
							var v = preconditions[k];
							if (GameStateInfo.EvaluatePrecondition(k, v) == false)
							{
								skipFlag = true;
								break;
							}
						}
						if (skipFlag)
							optionsList[optionsList.length-1].visible = false;
					}
				}
				ResizeOptionsList();
			}
		}
		
		public function OnSetDialogueNode(args:Object)
		{
			if (args != null)
			{
				nameTextField.text = args.unit_name;
				LoadDialogueNode(args.node);
				
				overlayFadeTimer = new Timer(250, 1);
				overlayFadeTimer.addEventListener(TimerEvent.TIMER, OnOverlayFadeIn);
				if (overlayFadeTween != null)
					overlayFadeTween.stop()
				overlayFadeTween = new Tween(this.overlay, "alpha", None.easeNone, this.overlay.alpha, 1.0, 0.25, true);
				
				overlayFadeTimer.start();
				overlayFadeTween.start();
				visible = true;
			}
		}
		
		private function OnOverlayFadeIn(e:TimerEvent)
		{
			this.overlay.faderTop.visible = true;
			this.overlay.faderBottom.visible = true;
			this.overlay.choices.visible = true;
		}
		
		private function OnOverlayFadeOut(e:TimerEvent)
		{
			visible = false;
		}
		
		private function OnOptionMouseOver(e:MouseEvent)
		{
			e.target.alpha = 1.0;
			if (optionsScrollTween != null)
				optionsScrollTween.stop();
			optionsScrollTween = new Tween(this.overlay.choices, "y", Regular.easeOut, this.overlay.choices.y, -128.0 - (e.target.y + (e.target.height)/2), 0.75, true);
			optionsScrollTween.start();
		}
		
		private function OnOptionMouseOut(e:MouseEvent)
		{
			e.target.alpha = 0.5;
		}
		
		private function OnOptionMouseClick(e:MouseEvent)
		{
			//This is not at all efficient, but there probably won't be too many options... right?
			for (var i:int = 1; i <= optionsList.length; i++)
			{
				if (optionsList[i-1] == e.target)
				{
					var dialogueNode:Object = dialogueKV[dialogueNodeID];
					if ((dialogueNode != null) && (dialogueNode["Options"] != null))
					{
						var optionNode:Object = dialogueNode["Options"][i.toString()];
						if (optionNode != null)
						{
							var postconditions:Object = optionNode["Postconditions"];
							if (postconditions != null)
							{
								for (var k:String in postconditions)
								{
									var v = postconditions[k];
									GameStateInfo.EvaluatePostcondition(k, v);
									gameAPI.SendServerCommand("iw_ui_dialogue_postcondition \"" + k + " " + GameStateInfo.GetGameStateValue(k) + "\"");
								}
							}
							
							var nextNodeIndex = optionNode["NextNode"]
							if (nextNodeIndex == "0")
							{
								overlayFadeTimer = new Timer(250, 1);
								overlayFadeTimer.addEventListener(TimerEvent.TIMER, OnOverlayFadeOut);
								if (overlayFadeTween != null)
									overlayFadeTween.stop();
								this.overlay.faderTop.visible = false;
								this.overlay.faderBottom.visible = false;
								this.overlay.choices.visible = false;
								overlayFadeTween = new Tween(this.overlay, "alpha", None.easeNone, this.overlay.alpha, 0.0, 0.25, true);
								
								overlayFadeTimer.start();
								overlayFadeTween.start();
							}
							else if (nextNodeIndex == "-1")
								break;
							else
								LoadDialogueNode(nextNodeIndex);
						}
					}
					break;
				}
			}
		}
		
		private function AddOption(optionText:String) : void
		{
			var optionTextField = new TextField();
			optionTextField.visible = true;
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
			optionTextField.addEventListener(MouseEvent.CLICK, OnOptionMouseClick);
			
			this.overlay.choices.addChild(optionTextField);
			optionsList.push(optionTextField);
		}
		
		private function ClearOptionsList() : void
		{
			for (var i:int = 0; i < optionsList.length; i++)
			{
				var optionTextField = optionsList[i];
				this.overlay.choices.removeChild(optionTextField);
			}
			optionsList.length = 0;
		}
		
		private function ResizeOptionsList() : void
		{
			var currentY:Number = 0;
			for (var i:int = 0; i < optionsList.length; i++)
			{					
				var optionTextField = optionsList[i];
				if (optionTextField.visible == true)
				{
					if ((screenHeight * 16)/9 == screenWidth)
						optionTextField.width = 600;
					else if ((screenHeight * 16)/10 == screenWidth)
						optionTextField.width = 536;
					else
						optionTextField.width = 440;
					optionTextField.y = currentY;
					currentY += optionTextField.height;
				}
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

			ResizeOptionsList();
			this.overlay.x = 0;
			this.scaleX = this.scaleY = re.ScreenHeight / 1080.0
			trace(re.ScreenHeight + " " + re.ScreenWidth)
			trace("this.scaleY = " + this.scaleY)
		}
	}
	
}
