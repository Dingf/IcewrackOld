package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	public class SpellButtonOverlay extends MovieClip
	{
		public var gameAPI : Object;
		public var globals : Object;
		
		private function OnMouseOver(e:MouseEvent)
		{
			trace("NewMouseOver");
			//overState.visible = true;
			
			//var point : Point = this.localToGlobal(new Point(0, 0));
			//var adjScale : Number = scale * this.parent.scaleY;
			
			//TODO: Figure out how to use the actionpanel version instead (which shows the current level, things like that)
			//globals.Loader_rad_mode_panel.gameAPI.OnShowAbilityTooltip(point.x + adjScale * 128.0, point.y + adjScale * 32, spellName);
		}
		
		private function OnMouseOut(e:MouseEvent)
		{
			trace("NewMouseOut");
			//overState.visible = false;
			//globals.Loader_rad_mode_panel.gameAPI.OnHideAbilityTooltip();
			//texture.x = overState.x = 0;
			//texture.y = overState.y = 0;
		}
		
		private function OnMouseDown(e:MouseEvent)
		{
			trace("NewMouseDown");
			//texture.x = overState.x = -1;
			//texture.y = overState.y = -1;
		}
		
		private function OnMouseUp(e:MouseEvent)
		{
			trace("NewMouseUp");
			//texture.x = overState.x = 0;
			//texture.y = overState.y = 0;
		}
		
		private function OnMouseClick(e:MouseEvent)
		{
			trace("NewMouseClick");
		}
		
		public function SpellButtonOverlay()
		{
		}
		
		public function onLoaded() : void 
		{
			visible = true;
			
			addEventListener(MouseEvent.ROLL_OVER, OnMouseOver);
			addEventListener(MouseEvent.ROLL_OUT, OnMouseOut);
			
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			addEventListener(MouseEvent.CLICK, OnMouseClick); 
			
			gameAPI.SubscribeToGameEvent("iw_ui_mainbar_return_abilities", OnUnitAbilityReturn);
		}
		
		private function OnUnitAbilityReturn(args:Object) : void
		{
			trace("uh...")
			var abilityNames:Array = new Array(args.ability1, args.ability2, args.ability3, args.ability4, args.ability5, args.ability6);
			for (var i:int = 0; i < 6; i++)
			{
				trace(abilityNames[i]);
				/*if (abilityIcons[i] != null)
				{
					this.removeChild(abilityIcons[i]);
					abilityIcons[i] = null;
				}
				
				var spellIcon = new SpellIcon;
				spellIcon.Create(gameAPI, globals, abilityNames[i], 64);
				this.addChild(spellIcon);
				spellIcon.x = 578 + (i * 72);
				spellIcon.y = 1006;
				
				abilityIcons[i] = spellIcon;*/
			}
		}
	}
	
}
