package
{
	import flash.display.MovieClip;
	import flash.utils.describeType;
	
	public class ScaleformFileSave extends MovieClip
	{
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		private var chunkList:Vector.<String> = new Vector.<String>();
		
		public function ScaleformFileSave()
		{
			// constructor code
		}
		
		public function onLoaded() : void
		{
			visible = true;
			gameAPI.SubscribeToGameEvent("iw_ui_sfs_save_game", OnSaveGame);
			gameAPI.SubscribeToGameEvent("iw_ui_sfs_make_save_list", OnMakeSaveList);
		}
		
		private function ParseKVString(kvString:String) : Object
		{
			var kvData : Object = {}
			var objStack = new Vector.<Object>();
			objStack.push(kvData);
			
			var kvTokens = kvString.split("\t");
			var currentObj = objStack[objStack.length-1];
			for (var i = 0; i < kvTokens.length; i++)
			{
				var s1 = kvTokens[i];
				if (s1 == "}")
				{
					objStack.pop();
					currentObj = objStack[objStack.length-1];
				}
				else
				{
					var s2 = kvTokens[++i];
					if (s2 == "{")
					{
						var newObj = {}
						currentObj[s1] = newObj
						currentObj = newObj
						objStack.push(newObj);
					}
					else
					{
						currentObj[s1] = s2
					}
				}
			}
			return kvData;
		}
		
		public function OnMakeSaveList(args:Object) : void
		{
			if (args != null)
			{
				globals.GameInterface.SaveKVFile(ParseKVString(args.save_data), args.filename, "IcewrackSaveList", "");
				gameAPI.SendServerCommand("iw_ui_save_complete");
			}
		}
		
		public function OnSaveGame(args:Object) : void
		{
			if (args != null)
			{
				chunkList.push(args.save_data);
				if (args.is_last == true)
				{
					var saveString = "";
					for (var i:int = 0; i < chunkList.length; i++)
					{
						saveString = saveString + chunkList[i];
					}
				
					globals.GameInterface.SaveKVFile(ParseKVString(saveString), args.filename, "IcewrackSaveFile", "");
				}
			}
		}
	}
}
