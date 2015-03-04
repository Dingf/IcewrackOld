package
{
	import flash.display.MovieClip;
	import flash.utils.Timer;
	import flash.utils.getDefinitionByName;
	import flash.events.TimerEvent;
	import flash.events.MouseEvent;
	import flash.text.engine.EastAsianJustifier;
	
	public class CharacterSelectMenu extends MovieClip
	{
		public var gameAPI : Object;
		public var globals : Object;
		public var elementName : String;
		
		private var queryTimer : Timer;
		private var queriedEnthandle : Number = -1;
		
		private var acceptButton : Object = null;
		private var returnButton : Object = null;
		
		//These are necessary because the buttons are created after onResize, but
		//their positions/scale still need to be updated accordingly
		private var acceptButtonX : Number = 0;
		private var acceptButtonY : Number = 0;
		private var acceptButtonScale : Number = 1;
		
		private var returnButtonX : Number = 0;
		private var returnButtonY : Number = 0;
		private var returnButtonScale : Number = 1;

		public function CharacterSelectMenu() {}
		
		public function test(e:MouseEvent)
		{
			if (queriedEnthandle != -1)
			{
				var classname:String = globals.Entities.GetClassname(queriedEnthandle);
				gameAPI.SendServerCommand("iw_ui_character_select_accept " + classname);
			}
		}
		
		public function onLoaded() : void 
		{
			visible = true;
			gameAPI.OnUnload = this.OnUnload;
			
			globals.resizeManager.AddListener(this);
			
			var ValveBigButton = getDefinitionByName("button_big");
			acceptButton = new ValveBigButton();
			acceptButton.label = "Accept";
			acceptButton.enabled = false;
			acceptButton.x = acceptButtonX;
			acceptButton.y = acceptButtonY;
			acceptButton.scaleX = acceptButton.scaleY = acceptButtonScale;
			acceptButton.addEventListener(MouseEvent.CLICK, test);
			
			returnButton = new ValveBigButton();
			returnButton.label = "Back";
			returnButton.x = returnButtonX;
			returnButton.y = returnButtonY;
			returnButton.scaleX = returnButton.scaleY = returnButtonScale;
			//returnButton.addEventListener(MouseEvent.CLICK, test);
			
			addChild(ValveBigButton(acceptButton));
			addChild(ValveBigButton(returnButton));
						
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
						if (acceptButton != null)
						{
							acceptButton.enabled = true;
						}
					}
					else
					{
						if (acceptButton != null)
						{
							acceptButton.enabled = false;
						}
					}
					queriedEnthandle = queriedUnit;
				}
			}
		}
		
		public function onResize(re:Object) : void
		{
			//calculate the scaling ratio in the X and Y direction and apply it to the state
			var resWidth:int = 0;
			var resHeight:int = 0;
			if (re.IsWidescreen()) 
			{
				if (re.Is16by9()) 
				{
					acceptButtonScale = re.ScreenWidth/1200.0;
					acceptButtonX = re.ScreenWidth * (97/240);
					returnButtonScale = re.ScreenWidth/1200.0;
					returnButtonX = re.ScreenWidth * (1/60);
				}
				else 
				{
					acceptButtonScale = re.ScreenWidth/1080.0;
					acceptButtonX = re.ScreenWidth * (85/216);
					returnButtonScale = re.ScreenWidth/1080.0;
					returnButtonX = re.ScreenWidth * (1/54);
				}
			}
			else
			{
				acceptButtonScale = re.ScreenWidth/900.0;
				acceptButtonX = re.ScreenWidth * (67/180);
				returnButtonScale = re.ScreenWidth/900.0;
				returnButtonX = re.ScreenWidth * (1/45);
			}

			var maxStageHeight:int = re.ScreenHeight / re.ScreenWidth * resWidth;
			var maxStageWidth:int = re.ScreenWidth / re.ScreenHeight * resHeight;

			acceptButtonY = re.ScreenHeight/1.1;
			returnButtonY = re.ScreenHeight/1.1;

			if (acceptButton != null)
			{
				acceptButton.x = acceptButtonX;
				acceptButton.y = acceptButtonY;
				acceptButton.scaleX = acceptButton.scaleY = acceptButtonScale;
			}
			if (returnButton != null)
			{
				returnButton.x = returnButtonX;
				returnButton.y = returnButtonY;
				returnButton.scaleX = returnButton.scaleY = returnButtonScale;
			}
			
			//this.scaleX = this.scaleY = 
			trace(re.ScreenHeight + " " + re.ScreenWidth)
			trace("this.scaleY = " + this.scaleY)
		}
	}
	
}
		
		
			
			//public function replaceWithValveComponent(mc:MovieClip, type:String, keepDimensions:Boolean = false) : MovieClip {
   /* var parent = mc.parent;
    var oldx = mc.x;
    var oldy = mc.y;
    var oldwidth = mc.width;
    var oldheight = mc.height;
    
    var newObjectClass = getDefinitionByName("button_big");
    var newObject = new newObjectClass();
    newObject.x = 500;
    newObject.y = 500;
    if (keepDimensions) {
        newObject.width = oldwidth;
        newObject.height = oldheight;
    }*/
    
    //addChild(newObject);