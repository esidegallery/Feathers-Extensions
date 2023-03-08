package feathers.controls.unthemed
{
	import feathers.controls.Callout;
	import feathers.skins.IStyleProvider;
	
	public class UnthemedCallout extends Callout
	{
		public static var globalStyleProvider:IStyleProvider;
		override protected function get defaultStyleProvider():IStyleProvider
		{
			return globalStyleProvider;
		}
	}
}