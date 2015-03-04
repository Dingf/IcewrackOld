package 
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.filters.ColorMatrixFilter;

	public class SpellIcon extends MovieClip
	{
		public var gameAPI : Object;
		public var globals : Object;
		
		private var spellName : String;
		private var spellSlot : Number;
		private var scale : Number;
		private var secondary : Boolean;
		
		private var texture : Sprite;
		//private var desaturatedTexture : Sprite;
		private var overState : Sprite;
		private var border : Sprite;
		
		//private var extras : SpellIconExtras = null;
		private var tooltip : Tooltip = null;
		
		private static var desaturateFilter : ColorMatrixFilter = new ColorMatrixFilter(
			[0.299, 0.587, 0.114, 0, 0,
			 0.299, 0.587, 0.114, 0, 0,
			 0.299, 0.587, 0.114, 0, 0,
			 0,     0,     0,     1, 0])
		
		public function SpellIcon() : void
		{
		}
		
		private function OnMouseOver(e:MouseEvent)
		{
			trace("MouseOver");
			overState.visible = true;
			
			if (spellName != "empty")
			{
				var point : Point = this.localToGlobal(new Point(0, 0));
				var adjScale : Number = scale * (this.secondary ? this.parent.parent.parent.scaleY : this.parent.scaleY);
				
				//TODO: Figure out how to use the actionpanel version instead (which presumably shows the current spell level, things like that)
				globals.Loader_rad_mode_panel.gameAPI.OnShowAbilityTooltip(point.x + adjScale * 128.0, point.y + adjScale * 32, spellName);
			}
			else
			{
				globals.Loader_rad_mode_panel.gameAPI.OnHideAbilityTooltip();
			}
		}
		
		private function OnMouseOut(e:MouseEvent)
		{
			trace("MouseOut");
			overState.visible = false;
			globals.Loader_rad_mode_panel.gameAPI.OnHideAbilityTooltip();
			//texture.x = overState.x = 0;
			//texture.y = overState.y = 0;
		}
		
		private function OnMouseDown(e:MouseEvent)
		{
			trace("MouseDown");
			//texture.x = overState.x = -1;
			//texture.y = overState.y = -1;
		}
		
		private function OnMouseUp(e:MouseEvent)
		{
			trace("MouseUp");
			//texture.x = overState.x = 0;
			//texture.y = overState.y = 0;
		}
		
		private function OnMouseClick(e:MouseEvent)
		{
			trace("MouseClick");
			if (this.secondary == true)
			{
				gameAPI.SendServerCommand("iw_ui_spellbar_rebind \"" + this.spellSlot + " " + this.spellName + "\"");
			}
			else if (tooltip != null)
			{
				if (tooltip.visible == true)
				{
					tooltip.visible = false;
					var point : Point = this.localToGlobal(new Point(0, 0));
					var adjScale : Number = scale * (this.secondary ? this.parent.parent.parent.scaleY : this.parent.scaleY);
					
					//TODO: Figure out how to use the actionpanel version instead (which shows the current level, things like that)
					globals.Loader_rad_mode_panel.gameAPI.OnShowAbilityTooltip(point.x + adjScale * 128.0, point.y + adjScale * 32, spellName);
				}
				else
				{
					tooltip.visible = true;
					globals.Loader_rad_mode_panel.gameAPI.OnHideAbilityTooltip();
				}
			}
		}
		
		//Arguments:
		//----------------------------------------------------------------
		//szName - name of spell
		//szTextureName - name of spell texture (should be the same as above)
		//nSize - size of the spell icon (in px)
		public function Create(gameAPI:Object, globals:Object, resName:String, /*manaCost:Number, */slot:Number, size:Number, isSecondary:Boolean = false)
		{
			this.gameAPI = gameAPI;
			this.globals = globals;
			
			this.spellName = resName;
			this.spellSlot = slot;
			this.scale = size/128.0;
			this.secondary = isSecondary;
			
			texture = LoadImage("images/spellicons/" + resName + ".png", 128.0 * scale, 128.0 * scale);
			//desaturatedTexture = LoadImage("images/spellicons/" + resName + ".png", 128.0 * scale, 128.0 * scale);
			//desaturatedTexture.filters = [desaturateFilter];
			//desaturatedTexture.visible = false;
			overState = LoadImage("images/ui/spellicon_over_128px.png", 128.0 * scale, 128.0 * scale);
			overState.visible = false;
			
			if (isSecondary == false)
			{
				//extras = new SpellIconExtras(manaCost);
				//extras.width = 128.0 * scale;
				//extras.height = 128.0 * scale;
			}
			
			border = LoadImage("images/ui/spellicon_border_144px.png", 144.0 * scale, 144.0 * scale);
			border.x = border.y = -8.0 * scale;
			
			addEventListener(MouseEvent.ROLL_OVER, OnMouseOver);
			addEventListener(MouseEvent.ROLL_OUT, OnMouseOut);
			
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			addEventListener(MouseEvent.CLICK, OnMouseClick); 
		}
		
		public function DestroyTooltip() : void
		{
			if (tooltip != null)
			{
				tooltip = null;
			}
		}
		
		public function CreateTooltip(knownList:Array) : void
		{
			if ((tooltip == null) && (knownList.length > 0))
			{
				tooltip = new Tooltip();
				tooltip.visible = false;
				this.addChild(tooltip);
				tooltip.x = (this.scale * 64) - 22;
				tooltip.y = -24;
				
				var listSize = knownList.length;
				
				tooltip.main_window.height = 14 + (Math.ceil(listSize/4.0) * 70);
				tooltip.main_window.width = tooltip.transparency.width = 14 + (Math.min(listSize, 4) * 70);
				
				for (var i:int = 0; i < listSize; i++)
				{
					var spellIcon = new SpellIcon();
					spellIcon.Create(gameAPI, globals, knownList[i], /*0,*/ this.spellSlot, 64, true);
					tooltip.addChild(spellIcon);
					
					spellIcon.x = 10 + ((i % 4) * 70);
					spellIcon.y = -70 - (int(i/4) * 70);
				}
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