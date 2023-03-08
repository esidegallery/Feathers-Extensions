package feathers.controls.unthemed
{
	import feathers.controls.Header;
	import feathers.skins.IStyleProvider;

	public class UnthemedHeader extends Header
	{
		public static var globalStyleProvider:IStyleProvider;
		override protected function get defaultStyleProvider():IStyleProvider
		{
			return globalStyleProvider;
		}
	}
}