package feathers.controls.unthemed
{
	import feathers.controls.renderers.LayoutGroupListItemRenderer;
	import feathers.skins.IStyleProvider;

	public class UnthemedLayoutGroupListItemRenderer extends LayoutGroupListItemRenderer
	{
		public static var globalStyleProvider:IStyleProvider;
		override protected function get defaultStyleProvider():IStyleProvider
		{
			return globalStyleProvider;
		}
	}
}