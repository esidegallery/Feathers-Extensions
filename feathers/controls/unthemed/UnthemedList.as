package feathers.controls.unthemed
{
	import feathers.controls.List;
	import feathers.skins.IStyleProvider;
	
	public class UnthemedList extends List
	{
		public static var globalStyleProvider:IStyleProvider;
		override protected function get defaultStyleProvider():IStyleProvider
		{
			return globalStyleProvider;
		}
	}
}