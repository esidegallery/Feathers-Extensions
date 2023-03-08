package feathers.controls.unthemed
{
	import feathers.controls.SimpleScrollBar;
	import feathers.skins.IStyleProvider;

	public class UnthemedSimpleScrollBar extends SimpleScrollBar
	{
		public static var globalStyleProvider:IStyleProvider;
		override protected function get defaultStyleProvider():IStyleProvider
		{
			return globalStyleProvider;
		}
	}
}