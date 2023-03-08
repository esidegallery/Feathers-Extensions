package feathers.controls.unthemed
{
	import feathers.controls.ScrollContainer;
	import feathers.skins.IStyleProvider;

	public class UnthemedScrollContainer extends ScrollContainer
	{
		public static var globalStyleProvider:IStyleProvider;
		override protected function get defaultStyleProvider():IStyleProvider
		{
			return globalStyleProvider;
		}
	}
}