package 
{
	import flash.display.MovieClip;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.MouseEvent;
	
	public class IcewrackMainBar extends MovieClip
	{
		//these three variables are required by the engine
		public var gameAPI : Object;
		public var globals : Object;
		public var elementName : String;
		
		private var abilityIcons : Array = new Array(null, null, null, null, null, null);
		private var snowOverlay : MovieClip;
		
		private var selectedEntindex : Number = 0;
		private var selectionTimer : Timer;
		
		private var rollOverTimer:Timer = null;
		
		private var currentHP:Number = 0;
		private var maximumHP:Number = 0;
		private var currentMP:Number = 0;
		private var maximumMP:Number = 0;
		private var currentSP:Number = 0;
		private var maximumSP:Number = 0;
		private var currentXP:Number = 0;
		private var maximumXP:Number = 0;
		
		
		public function IcewrackMainBar()
		{
		}
		
		public function onLoaded() : void 
		{
			visible = true;
			
			globals.resizeManager.AddListener(this);
			
			gameAPI.OnUnload = this.OnUnload;
			gameAPI.SubscribeToGameEvent("iw_ui_mainbar_return_values", OnUnitValuesReturn);
			gameAPI.SubscribeToGameEvent("iw_ui_mainbar_set_visible", OnSetVisible);
			
			this.hp_region.addEventListener(MouseEvent.ROLL_OVER, OnHPBarRollOver);
			this.hp_region.addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
			this.mp_region.addEventListener(MouseEvent.ROLL_OVER, OnMPBarRollOver);
			this.mp_region.addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
			this.sp_region.addEventListener(MouseEvent.ROLL_OVER, OnSPBarRollOver);
			this.sp_region.addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
			this.xp_region.addEventListener(MouseEvent.ROLL_OVER, OnXPBarRollOver);
			this.xp_region.addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
						
			selectionTimer = new Timer(100.0);
			selectionTimer.addEventListener(TimerEvent.TIMER, QueryUnit);
			selectionTimer.start();
		}
		
		public function OnUnload() : Boolean
		{
			selectionTimer.stop();
			if (rollOverTimer != null)
			{
				rollOverTimer.stop();
			}
			return true;
		}
		
		private function OnHPBarRollOver(e:MouseEvent) : void
		{
			if (rollOverTimer == null)
			{
				rollOverTimer = new Timer(50.0);
				rollOverTimer.addEventListener(TimerEvent.TIMER, OnHPBarUpdate);
				rollOverTimer.start();
			}
			
			globals.Loader_overlay.movieClip.hud_overlay.dropped_item_tooltip.itemName.text = "HP:" + currentHP + "/" + maximumHP;
			globals.Loader_overlay.movieClip.showDroppedItemTooltip(e.stageX, e.stageY, "0xffffff");
		}
		
		private function OnHPBarUpdate(e:TimerEvent) : void
		{
			globals.Loader_overlay.movieClip.hud_overlay.dropped_item_tooltip.itemName.text = "HP:" + currentHP + "/" + maximumHP;
			globals.Loader_overlay.movieClip.showDroppedItemTooltip(stage.mouseX, stage.mouseY, "0xffffff");
		}
		
		private function OnMPBarRollOver(e:MouseEvent) : void
		{
			if (rollOverTimer == null)
			{
				rollOverTimer = new Timer(50.0);
				rollOverTimer.addEventListener(TimerEvent.TIMER, OnMPBarUpdate);
				rollOverTimer.start();
			}
			
			globals.Loader_overlay.movieClip.hud_overlay.dropped_item_tooltip.itemName.text = "MP:" + currentMP + "/" + maximumMP;
			globals.Loader_overlay.movieClip.showDroppedItemTooltip(e.stageX, e.stageY, "0xffffff");
		}
		
		private function OnMPBarUpdate(e:TimerEvent) : void
		{
			globals.Loader_overlay.movieClip.hud_overlay.dropped_item_tooltip.itemName.text = "MP:" + currentMP + "/" + maximumMP;
			globals.Loader_overlay.movieClip.showDroppedItemTooltip(stage.mouseX, stage.mouseY, "0xffffff");
		}
		
		private function OnSPBarRollOver(e:MouseEvent) : void
		{
			if (rollOverTimer == null)
			{
				rollOverTimer = new Timer(50.0);
				rollOverTimer.addEventListener(TimerEvent.TIMER, OnSPBarUpdate);
				rollOverTimer.start();
			}
			
			globals.Loader_overlay.movieClip.hud_overlay.dropped_item_tooltip.itemName.text = "SP:" + int(currentSP) + "/" + int(maximumSP);
			globals.Loader_overlay.movieClip.showDroppedItemTooltip(e.stageX, e.stageY, "0xffffff");
		}
		
		private function OnSPBarUpdate(e:TimerEvent) : void
		{
			globals.Loader_overlay.movieClip.hud_overlay.dropped_item_tooltip.itemName.text = "SP:" + int(currentSP) + "/" + int(maximumSP);
			globals.Loader_overlay.movieClip.showDroppedItemTooltip(stage.mouseX, stage.mouseY, "0xffffff");
		}
		
		private function OnXPBarRollOver(e:MouseEvent) : void
		{
			if (rollOverTimer == null)
			{
				rollOverTimer = new Timer(50.0);
				rollOverTimer.addEventListener(TimerEvent.TIMER, OnXPBarUpdate);
				rollOverTimer.start();
			}
			
			globals.Loader_overlay.movieClip.hud_overlay.dropped_item_tooltip.itemName.text = "XP:" + currentXP + "/" + maximumXP;
			globals.Loader_overlay.movieClip.showDroppedItemTooltip(e.stageX, e.stageY, "0xffffff");
		}
		
		private function OnXPBarUpdate(e:TimerEvent) : void
		{
			globals.Loader_overlay.movieClip.hud_overlay.dropped_item_tooltip.itemName.text = "XP:" + currentXP + "/" + maximumXP;
			globals.Loader_overlay.movieClip.showDroppedItemTooltip(stage.mouseX, stage.mouseY, "0xffffff");
		}
		
		
		private function OnRollOut(e:MouseEvent) : void
		{
			globals.Loader_overlay.movieClip.hud_overlay.dropped_item_tooltip.visible = false;
			if (rollOverTimer != null)
			{
				rollOverTimer.stop();
				rollOverTimer = null;
			}
		}
		
		private function QueryUnit(e:TimerEvent) : void
		{
			if (globals != null)
			{
				var playerID = globals.Players.GetLocalPlayer();
				var selectedEntities = globals.Players.GetSelectedEntities(playerID);
				if ((selectedEntities != null) && (selectedEntities.length > 0))
				{
					if (selectedEntindex != selectedEntities[0])
					{
						selectedEntindex = selectedEntities[0];
						gameAPI.SendServerCommand("iw_ui_mainbar_request_abilities " + selectedEntities[0]);
						gameAPI.SendServerCommand("iw_ui_mainbar_request_known_list " + selectedEntities[0]);
					}
					gameAPI.SendServerCommand("iw_ui_mainbar_request_values " + selectedEntities[0]);
				}
				else
				{
					selectedEntindex = 0;
					xp_bar.width = 0;
					mp_mask.rotation = 180;
					sp_mask.rotation = -180;
					hp_bar.hp_percent.scaleY = 2.0;
					mp_indicator.visible = false;
					sp_indicator.visible = false;
				}
			}
		}
		
		private function OnSetVisible(args:Object) : void
		{
			if (args != null)
			{
				this.visible = args.is_visible; 
			}
		}
		
		private function OnUnitValuesReturn(args:Object) : void
		{
			if (args != null)
			{
				currentHP = args.current_hp;
				maximumHP = args.maximum_hp;
				currentMP = args.current_mp;
				maximumMP = args.maximum_mp;
				currentSP = args.current_sp;
				maximumSP = args.maximum_sp;
				currentXP = args.current_xp;
				maximumXP = args.maximum_xp;
				
				mp_mask.rotation = (maximumMP == 0) ? 180.0 : (1.0 - (currentMP/maximumMP)) * 180.0;
				sp_mask.rotation = (maximumSP == 0) ? -180.0 : (1.0 - (currentSP/maximumSP)) * -180.0;
				
				hp_bar.hp_percent.scaleY = (maximumHP == 0) ? 1.0 : (1.0 - (currentHP/maximumHP)) * 1.0;
				hp_bar.hp_percent.visible = (hp_bar.hp_percent.scaleY >= 0.01);
				
				xp_bar.width = (currentXP/maximumXP) * 320.0;
				
				mp_indicator.rotation = mp_mask.rotation * 0.975;
				mp_indicator.visible = ((mp_mask.rotation != 0) && (mp_mask.rotation != 180.0));
				sp_indicator.rotation = sp_mask.rotation * 0.975;
				sp_indicator.visible = ((sp_mask.rotation != 0) && (sp_mask.rotation != -180.0));
				
				var values = IcewrackValues.GetInstance();
				values.currentHP = args.current_hp;
				values.maximumHP = args.maximum_hp;
				values.currentMP = args.current_mp;
				values.maximumMP = args.maximum_mp;
				values.currentSP = args.current_sp;
				values.maximumSP = args.maximum_sp;
				values.currentXP = args.current_xp;
				values.maximumXP = args.maximum_xp;
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