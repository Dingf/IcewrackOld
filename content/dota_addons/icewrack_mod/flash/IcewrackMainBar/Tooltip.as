package
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	public class Tooltip extends MovieClip
	{
		private function OnMouseOver(e:MouseEvent)
		{
			trace("TTMouseOver");
			parent.mouseEnabled = false;
		}
		
		private function OnMouseOut(e:MouseEvent)
		{
			trace("TTMouseOut");
			visible = false;
			parent.mouseEnabled = true;
		}
		
		private function OnMouseDown(e:MouseEvent)
		{
			trace("TTMouseDown");
			//texture.x = overState.x = -1;
			//texture.y = overState.y = -1;
		}
		
		private function OnMouseUp(e:MouseEvent)
		{
			trace("TTMouseUp");
			//texture.x = overState.x = 0;
			//texture.y = overState.y = 0;
		}
		
		private function OnMouseClick(e:MouseEvent)
		{
			trace("TTMouseClick");
		}
		
		public function Tooltip()
		{
			addEventListener(MouseEvent.ROLL_OVER, OnMouseOver);
			addEventListener(MouseEvent.ROLL_OUT, OnMouseOut);
			
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			addEventListener(MouseEvent.CLICK, OnMouseClick); 
		}
	}
	
}
