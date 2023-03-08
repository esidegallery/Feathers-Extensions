package feathers.controls.unthemed
{
	import feathers.controls.Button;
	import feathers.skins.IStyleProvider;

	public class UnthemedButton extends Button
	{
		public static var globalStyleProvider:IStyleProvider;
		override protected function get defaultStyleProvider():IStyleProvider
		{
			return globalStyleProvider;
		}
	}
}