package
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	public class ModifierIcon extends MovieClip
	{
		public var gameAPI : Object;
		public var globals : Object;
		
		private var startTime : Number;
		private var endTime : Number;
		private var spellName : String;
		
		private var texture : Sprite;
		
		public function ModifierIcon() : void
		{
		}
		
		public function GetEndTime() : Number
		{
			return endTime;
		}
		
		public function Create(gameAPI:Object, globals:Object, args:Object)
		{
			visible = true;
			
			this.gameAPI = gameAPI;
			this.globals = globals;
			
			if (args.debuff)
			{
				positive_bar.visible = false;
			}
			else
			{
				negative_bar.visible = false;
			}
			
			startTime = args.start_time;
			endTime = args.end_time;
			
			spellName = args.name;
			
			//positive_bar.visible = false;
			
			//negative_bar.right_mask.rotation = 50.0;
			
			texture = LoadImage("images/spellicons/" + spellName + ".png", 28, 28);
			texture.x = texture.y = -14;
			
		}
		
		public function SetTime(time:Number) : void
		{
			var percentage = (time > endTime) ? 1.0 : (time - startTime)/(endTime - startTime);
			if (percentage <= 0.5)
			{
				positive_bar.left_mask.rotation = 0.0;
				negative_bar.left_mask.rotation = 0.0;
				positive_bar.right_mask.rotation = 360.0 * percentage;
				negative_bar.right_mask.rotation = 360.0 * percentage;
			}
			else
			{
				positive_bar.left_mask.rotation = 360.0 * (percentage - 0.5);
				negative_bar.left_mask.rotation = 360.0 * (percentage - 0.5);
				positive_bar.right_mask.x = 500;//rotation = 180.0;
				negative_bar.right_mask.x = 500;//rotation = 180.0;
			}
		}
		
		private function LoadImage(imgPath:String, imgWidth:Number, imgHeight:Number) : Sprite
		{
			var mc = new MovieClip;
			
			mc["originalWidth"] = imgWidth;
			mc["originalHeight"] = imgHeight;
			
			globals.LoadImage(imgPath, mc, true);
			
			var sprite = new Sprite;
			sprite.addChild(mc);
			sprite.visible = true;
			
			this.addChild(sprite);
			return sprite;
		}
	}
}