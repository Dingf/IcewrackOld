package
{
	//Data transfer object that shares values between UI elements (like HP, MP, etc.)
	public class IcewrackValues
	{
		private static var locked:Boolean = true;
		private static var instance:IcewrackValues;
		
		//Breaks encapsulation, but since we're just storing these values for transfer, it doesn't really matter
		public var currentHP:Number;
		public var maximumHP:Number;
		public var currentMP:Number;
		public var maximumMP:Number;
		public var currentSP:Number;
		public var maximumSP:Number;
		public var currentXP:Number;
		public var maximumXP:Number;
		
		public function IcewrackValues()
		{
			if (locked)
			{
				throw new Error("Cannot construct this class normally; use GetInstance() instead");
			}
		}
		
		public static function GetInstance() : IcewrackValues
		{
			if (instance == null)
			{
				locked = false;
				instance = new IcewrackValues();
				locked = true;
			}
			return instance;
		}

	}
}