package feathers.extensions.maps
{
	import feathers.controls.ImageLoader;
	import feathers.extensions.maps.Map;
	import feathers.extensions.maps.MapImageLayerOptions;

	import starling.display.Sprite;
	import starling.utils.ScaleMode;

	public class MapImageLayer extends Sprite
	{
		protected var _options:MapImageLayerOptions;
		public function get options():MapImageLayerOptions
		{
			return _options;
		}

		protected var _map:Map;
		protected var _id:String;
		protected var _imageLoader:ImageLoader;

		public function MapImageLayer(map:Map, id:String, options:MapImageLayerOptions)
		{
			_map = map;
			_id = id;
			_options = options || new MapImageLayerOptions;

			initialize();
		}

		protected function initialize():void
		{
			if (_options.imageLoaderFactory != null)
			{
				_imageLoader = _options.imageLoaderFactory() as ImageLoader;
			}
			else
			{
				_imageLoader = new ImageLoader;
			}
			_imageLoader.scaleMode = ScaleMode.NONE;
			_imageLoader.maintainAspectRatio = false;
			if (!isNaN(_options.displayWidth))
			{
				_imageLoader.width = _options.displayWidth;
			}
			if (!isNaN(_options.displayHeight))
			{
				_imageLoader.height = _options.displayHeight;
			}
			_imageLoader.source = _options.imageSource;
			_imageLoader.textureCache = _options.textureCache;
			addChild(_imageLoader);
		}
	}
}