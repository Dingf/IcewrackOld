package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	
	public class BGShadow extends MovieClip 
	{
		public var gameAPI : Object;
		public var globals : Object;
		public var elementName : String;
		
		private var texture : MovieClip;
		
		public function BGShadow() : void
		{
			// constructor code
		}
		
		public function onLoaded() : void 
		{
			visible = true;
			
			globals.resizeManager.AddListener(this);
			
			var mc = new MovieClip;
			
			mc["originalWidth"] = 1200;
			mc["originalHeight"] = 269;
			
			globals.LoadImage("images/ui/mainbar_shadow_16x9.png", mc, true);
			
			var sprite = new Sprite;
			sprite.addChild(mc);
			sprite.visible = true;
			
			texture = new MovieClip;
			texture.addChild(sprite);
			
			texture.mouseEnabled = false;
			texture.mouseChildren = false;
			texture.visible = true;
			texture.y = 811;
			
			this.addChild(texture);
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
			
			//this.y = re.ScreenHeight - 1080
			
			
			this.scaleX = this.scaleY = re.ScreenHeight / 1080.0
			trace(re.ScreenHeight + " " + re.ScreenWidth)
			trace("this.scaleY = " + this.scaleY)
			
			
			//this.globals.Loader_actionpanel.movieClip.middle.abilities["Ability1"].scaleX = (0.5 * this.scaleX);
			//this.globals.Loader_actionpanel.movieClip.middle.abilities["Ability1"].scaleY = (0.5 * this.scaleY);
			
            // Scale hud to screen
           /* this.scaleX = re.ScreenWidth/maxStageWidth;
            this.scaleY = re.ScreenHeight/maxStageHeight;
			
			
			
			
			hud.x = 552 * (maxStageWidth/1920)
			hud.y = 978 * (maxStageHeight/1080);
			hud.width = 1920 *(maxStageWidth/1920);
			hud.height = 280 * (maxStageHeight/1080);
			
			trace(re.ScreenHeight + " " + re.ScreenWidth)
			trace(hud.scaleX + " " + hud.scaleY)*/
			
			//You will probably want to scale your elements by 1/scale to keep their original resolution
			
			//Elements are aligned to the top left of the screen in the engine, if you have panels that are not, reposition them here.
		}
	}
	
}
