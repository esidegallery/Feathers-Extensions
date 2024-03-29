package feathers.extensions.maps
{
	import feathers.utils.textures.TextureCache;

	public class MapImageLayerOptions
	{
		public var index:int = -1;
		public var imageSource:Object;
		public var displayWidth:Number;
		public var displayHeight:Number;

		/** Set to override the default of <code>VideoPlayerExtended</code>. */
		public var imageLoaderFactory:Function;
		public var textureCache:TextureCache;
	}
}