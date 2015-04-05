package 
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.MouseEvent;
	import flash.filters.ColorMatrixFilter;

	public class SpellIcon extends MovieClip
	{
		public var gameAPI : Object;
		public var globals : Object;
		
		private var spellName : String;
		private var spellSlot : Number;
		private var scale : Number;
		private var secondary : Boolean;
		private var active : Boolean = true;
		
		private var texture : Sprite;
		private var desaturatedTexture : Sprite;
		private var overState : Sprite;
		private var border : Sprite;
		
		private var values:Object = IcewrackValues.GetInstance();
		private var updateTimer : Timer = null;
		
		private var extras : SpellIconExtras = null;
		private var tooltip : Tooltip = null;
		
		private static var desaturateFilter : ColorMatrixFilter = new ColorMatrixFilter(
			[0.299, 0.587, 0.114, 0, 0,
			 0.299, 0.587, 0.114, 0, 0,
			 0.299, 0.587, 0.114, 0, 0,
			 0,     0,     0,     1, 0])
		
		public function SpellIcon() : void
		{
		
		}
		
		public function OnUnload() : void
		{
			if (extras != null)
			{
				extras.OnUnload();
				extras = null;
			}
			if (updateTimer != null)
			{
				updateTimer.stop();
				updateTimer = null;
			}
			DestroyTooltip();
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
		
		public function OnUpdate()
		{
			if (desaturatedTexture != null)
			{
				if (active == false)
				{
					desaturatedTexture.visible = true;
					if (extras != null)
					{
						extras.visible = false;
					}
				}
				else if ((extras != null) && (values != null))
				{
					desaturatedTexture.visible = false;
					extras.oom.visible = false;
					extras.oos.visible = false;
					extras.ooms.visible = false;
					if ((values.currentMP < extras.GetManaCost()) && (values.currentSP < extras.GetStaminaCost()))
					{
						desaturatedTexture.visible = true;
						extras.ooms.visible = true;
					}
					else if (values.currentMP < extras.GetManaCost())
					{
						desaturatedTexture.visible = true;
						extras.oom.visible = true;
					}
					else if (values.currentSP < extras.GetStaminaCost())
					{
						desaturatedTexture.visible = true;
						extras.oos.visible = true;
					}
				}
			}
		}
		
		public function SetActive(activeState:Boolean) : void
		{
			active = activeState;
		}
		
		public function SetCooldown(cdStart:Number, cdEnd:Number) : void
		{
			if (extras != null)
			{
				extras.SetCooldown(cdStart, cdEnd);
			}
		}

		public function Create(gameAPI:Object, globals:Object, resName:String, slot:Number, size:Number, isSecondary:Boolean = false)
		{
			this.gameAPI = gameAPI;
			this.globals = globals;
			
			this.spellName = resName;
			this.spellSlot = slot;
			this.scale = size/128.0;
			this.secondary = isSecondary;
			
			texture = LoadImage("images/spellicons/" + resName + ".png", 128.0 * scale, 128.0 * scale);
			desaturatedTexture = LoadImage("images/spellicons/" + resName + ".png", 128.0 * scale, 128.0 * scale);
			desaturatedTexture.filters = [desaturateFilter];
			desaturatedTexture.visible = false;
			
			if (isSecondary == false)
			{
				extras = new SpellIconExtras(0, 0);
				extras.scaleX = extras.scaleY = size/128.0;
				extras.x = extras.y = 64 * scale;
				extras.visible = false;
				this.addChild(extras);
			}
			
			overState = LoadImage("images/ui/spellicon_over_128px.png", 128.0 * scale, 128.0 * scale);
			overState.visible = false;
			
			border = LoadImage("images/ui/spellicon_border_144px.png", 144.0 * scale, 144.0 * scale);
			border.x = border.y = -8.0 * scale;
			
			OnUpdate();
			updateTimer = new Timer(100.0);
			updateTimer.addEventListener(TimerEvent.TIMER, OnUpdate);
			updateTimer.start();

			addEventListener(MouseEvent.ROLL_OVER, OnMouseOver);
			addEventListener(MouseEvent.ROLL_OUT, OnMouseOut);
			
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			addEventListener(MouseEvent.CLICK, OnMouseClick); 
		}
		
		//Technically, the extras are already created (so that they will appear under the border instead of on top of it)
		//This just initializes the extras and makes them visible
		public function CreateExtras(manaCost:Number, staminaCost:Number)
		{
			if (this.secondary == false)
			{
				extras.SetManaCost(manaCost);
				extras.SetStaminaCost(staminaCost);
				extras.visible = true;
			}
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