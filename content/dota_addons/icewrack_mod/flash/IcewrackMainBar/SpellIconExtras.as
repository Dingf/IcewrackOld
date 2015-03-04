package
{
	import flash.display.MovieClip;
	
	public class SpellIconExtras extends MovieClip
	{
		public function SpellIconExtras(manaCost:Number)
		{
			cd.visible = false;
			oom.visible = false;
			if (manaCost > 0)
			{
				mana.visible = true;
				mana.manaText.text = manaCost.toString();
			}
			else
			{
				mana.visible = false;
			}
			
		}
	}
	
}
