package feathers.controls
{
	import feathers.core.PropertyProxy;

	import starling.display.DisplayObject;

	/** Makes <code>properties</code> a <code>PropertyProxy</code> so that props can be nested/drilled. */
	public class TabNavigatorItemExtended extends TabNavigatorItem
	{
		private var _propertiesProxy:PropertyProxy;
		override public function get properties():Object
		{
			if (!_propertiesProxy)
			{
				_propertiesProxy = new PropertyProxy;
			}
			return _propertiesProxy;
		}
		override public function set properties(value:Object):void
		{
			if (_propertiesProxy == value)
			{
				return;
			}
			_propertiesProxy = PropertyProxy(value);
		}

		public function TabNavigatorItemExtended(classOrFunctionOrDisplayObject:Object = null, label:String = null, icon:DisplayObject = null)
		{
			super(classOrFunctionOrDisplayObject, label, icon);
		}

		override public function getScreen():DisplayObject
		{
			var viewInstance:DisplayObject;
			if (_screenDisplayObject !== null)
			{
				viewInstance = _screenDisplayObject;
			}
			else if (_screenClass !== null)
			{
				var ViewType:Class = Class(_screenClass);
				viewInstance = new ViewType();
			}
			else if (_screenFunction !== null)
			{
				viewInstance = DisplayObject(_screenFunction.call());
			}
			if (!(viewInstance is DisplayObject))
			{
				throw new ArgumentError("TabNavigatorItem \"getScreen()\" must return a Starling display object.");
			}
			if (_propertiesProxy)
			{
				for (var propertyName:String in _propertiesProxy)
				{
					viewInstance[propertyName] = _propertiesProxy[propertyName];
				}
			}

			return viewInstance;
		}
	}
}