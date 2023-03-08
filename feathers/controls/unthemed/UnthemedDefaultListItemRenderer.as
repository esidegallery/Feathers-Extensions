package feathers.controls.unthemed
{
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.skins.IStyleProvider;

	public class UnthemedDefaultListItemRenderer extends DefaultListItemRenderer
	{
		public static var globalStyleProvider:IStyleProvider;
		override protected function get defaultStyleProvider():IStyleProvider
		{
			return globalStyleProvider;
		}
	}
}