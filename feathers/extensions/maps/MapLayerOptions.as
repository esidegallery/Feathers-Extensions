package feathers.extensions.maps
{
	import feathers.utils.textures.TextureCache;

	import flash.geom.Rectangle;

	public class MapLayerOptions
	{
		public var index:int = -1;
		public var tileSize:int;

		/**
		 * How a tile URL is generated. A string which is substituted in the following way:
		 * <li>"{x}" becomes the x coordinate of the tile</li>
		 * <li>"{y}" becomes the x coordinate of the tile</li>
		 * <li>"{z}" becomes the x coordinate of the tile</li>
		 */
		public var urlTemplate:String;

		/**
		 * This needs to be set appropriately to ensure the correct tiles are loaded at the given zoom level.
		 * Use <code>MapUtils.getMaxZoom()</code> to calculate this value.
		 */
		public var maximumZoomLevel:int;

		public var blendMode:String;

		public var minimumZoomVisibility:int = Map.MIN_ZOOM;

		public var maximumZoomVisibility:int = Map.MAX_ZOOM;

		/** Whether the first requested batch of tiles are loaded without buffering or animation. */
		public var loadInitialTilesInstantly:Boolean;

		/** Whether the loading of tiles is prioritised over other layers. */
		public var prioritiseTileLoading:Boolean;

		/** Whether loaded tiles are faded in when shown. */
		public var animateShowTiles:Boolean = true;

		/**
		 * The number of levels beyond their current zoom level that tiles stay visible.
		 * Used to reduce gaps when changing zoom level.
		 */
		public var removeTileZoomThreshold:int;

		/**
		 * Tiles are created only if they intersect with the viewport bounds.
		 * This value adds a margin to those bounds so that tiles are loaded earlier.
		 */
		public var tileCreationMargin:int;

		/** For non-looping maps, limit tile creation to the coords if set. */
		public var limitTileCreationTo:Rectangle;

		public var tilesTextureCache:TextureCache;
	}
}