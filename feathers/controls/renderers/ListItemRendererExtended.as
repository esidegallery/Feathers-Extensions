package feathers.controls.renderers
{
	import starling.display.DisplayObject;
	
	public class ListItemRendererExtended extends DefaultListItemRenderer
	{
		private var _iconPropertiesFunction:Function;
		public function get iconPropertiesFunction():Function
		{
			return _iconPropertiesFunction;
		}
		public function set iconPropertiesFunction(value:Function):void
		{
			if (_iconPropertiesFunction != value)
			{
				_iconPropertiesFunction = value;
				invalidate(INVALIDATION_FLAG_DATA);
			}
		}
		
		override protected function itemToIcon(item:Object):DisplayObject
		{
			if (_iconPropertiesFunction != null)
			{
				refreshIconSource(null);
				
				var properties:Object;
				
				if (_iconPropertiesFunction.length == 2)
				{
					properties = _iconPropertiesFunction(item, IListItemRenderer(this).index);
				}
				else
				{
					properties = _iconPropertiesFunction(item);
				}
				
				for (var propertyName:String in properties)
				{
					var propertyValue:Object = properties[propertyName];
					iconLoader[propertyName] = propertyValue;
				}
				
				return iconLoader;
			}
			else
			{
				return super.itemToIcon(item);
			}
		}
	}
}