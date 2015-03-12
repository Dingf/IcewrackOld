package
{
	
	import flash.display.MovieClip;
	import flash.utils.describeType;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	public class KillcamTest extends MovieClip
	{
		//these three variables are required by the engine
		public var gameAPI : Object;
		public var globals : Object;
		public var elementName : String;
		
		private var selectionTimer : Timer;
		
		public function KillcamTest()
		{
			// constructor code
		}
		public function onLoaded() : void 
		{
			
			selectionTimer = new Timer(10000.0, 1);
			selectionTimer.addEventListener(TimerEvent.TIMER, Test);
			selectionTimer.start();
			
			globals.Loader_killcam.movieClip.inspect.originalXScale = 2;
			globals.Loader_killcam.movieClip.inspect.originalYScale = 2;
			
			globals.Loader_killcam.movieClip.inspect.title.text = "What the hell is going on?";
			globals.Loader_killcam.movieClip.inspect.subtitle.text = "Uh...";
			globals.Loader_killcam.movieClip.inspect.visible = false;
			
			//x = 500;
			//globals.Loader_killcam.movieClip.inspect.y = 500;
		}
		
		private function Test(e:TimerEvent) : void
		{
			
			trace(describeType(globals.Loader_killcam.movieClip.inspect));
			globals.Loader_killcam.movieClip.inspect.originalXScale = 2;
			globals.Loader_killcam.movieClip.inspect.originalYScale = 2;
			
			globals.Loader_killcam.movieClip.inspect.title.text = "What the hell is going on?";
			globals.Loader_killcam.movieClip.inspect.subtitle.text = "Uh...";
			globals.Loader_killcam.movieClip.inspect.visible = false;
			
		}
	}
	
}
