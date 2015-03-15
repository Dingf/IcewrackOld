package
{
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	
	public class GameStateInfo extends MovieClip
	{
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		private static var gameStates:Dictionary = new Dictionary();
		
		public function GameStateInfo()
		{
			// constructor code
		}
		
		public function onLoaded() : void
		{
			visible = true;
			
			var gameStateKV = globals.GameInterface.LoadKVFile("scripts/npc/iw_game_states.txt");
			for (var k:String in gameStateKV)
			{
				var v:String = gameStateKV[k];
				gameStates[k] = parseInt(v, 10);
			}
			
			gameAPI.SubscribeToGameEvent("iw_ui_gamestate_update", OnUpdateGameState);
		}
		
		private function OnUpdateGameState(args:Object) : void
		{
			if (args != null)
			{
				gameStates[args.state_name] = args.state_value;
			}
		}
		
		public static function GetGameStateValue(stateName:String) : Number
		{
			return gameStates[stateName];
		}
		
		public static function EvaluatePrecondition(stateName:String, condition:String) : Boolean
		{
			if (gameStates[stateName] != null)
			{
				var conditionTokens = condition.split(" ");
				var operator = conditionTokens[0];
				var stateValue = parseInt(conditionTokens[1], 10);
				
				if (operator == "==")
					return gameStates[stateName] == stateValue;
				else if (operator == "!=")
					return gameStates[stateName] != stateValue;
				else if (operator == ">")
					return gameStates[stateName] > stateValue;
				else if (operator == ">=")
					return gameStates[stateName] >= stateValue;
				else if (operator == "<")
					return gameStates[stateName] < stateValue;
				else if (operator == "<=")
					return gameStates[stateName] <= stateValue;
				else
					return false;
			}
			return false;
		}
		
		public static function EvaluatePostcondition(stateName:String, condition:String) : Boolean
		{
			if (gameStates[stateName] != null)
			{
				var conditionTokens = condition.split(" ");
				var operator = conditionTokens[0];
				var stateValue = parseInt(conditionTokens[1], 10);
				
				if (operator == "=")
					gameStates[stateName] = stateValue;
				else if (operator == "+=")
					gameStates[stateName] += stateValue;
				else if (operator == "-=")
					gameStates[stateName] -= stateValue;
				else if (operator == "*=")
					gameStates[stateName] *= stateValue;
				else if (operator == "/=")
					gameStates[stateName] /= stateValue;
				else
					return false;
				return true;
			}
			return false;
		}
	}
	
}
