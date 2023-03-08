package feathers.controls.unthemed
{
	import feathers.controls.Label;
	import feathers.skins.IStyleProvider;

	/** Provides its own styleProviders so the Theme doesn't get applied. */
	public class UnthemedLabel extends Label
	{
		public static var globalStyleProvider:IStyleProvider;
		override protected function get defaultStyleProvider():IStyleProvider
		{
			return globalStyleProvider;
		}
	}
}