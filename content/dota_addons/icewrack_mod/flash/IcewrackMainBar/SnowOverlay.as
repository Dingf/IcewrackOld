package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	
	public class SnowOverlay extends MovieClip 
	{
		public var gameAPI : Object;
		public var globals : Object;
		public var elementName : String;
		
		private var texture : MovieClip;
		
		public function SnowOverlay() : void
		{
			// constructor code
		}
		
		public function onLoaded() : void 
		{
			visible = true;
			
			globals.resizeManager.AddListener(this);
			
			gameAPI.SubscribeToGameEvent("iw_ui_mainbar_set_visible", OnSetVisible);
			
			var mc = new MovieClip;
			
			mc["originalWidth"] = 1200;
			mc["originalHeight"] = 228;
			
			globals.LoadImage("images/ui/snow_overlay_16x9.png", mc, true);
			
			var sprite = new Sprite;
			sprite.addChild(mc);
			sprite.visible = true;
			
			texture = new MovieClip;
			texture.addChild(sprite);
			
			texture.mouseEnabled = false;
			texture.mouseChildren = false;
			texture.visible = true;
			texture.y = 852;
			
			this.addChild(texture);
		}
		
		private function OnSetVisible(args:Object) : void
		{
			if (args != null)
			{
				this.visible = args.is_visible; 
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
