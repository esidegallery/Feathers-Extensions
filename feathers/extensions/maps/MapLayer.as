package feathers.extensions.maps
{
	import feathers.extensions.maps.IUpdatableMapLayer;
	import feathers.extensions.maps.Map;
	import feathers.extensions.maps.MapLayerOptions;
	import feathers.extensions.maps.MapTile;
	import feathers.extensions.maps.MapTilesBuffer;
	import feathers.utils.textures.TextureCache;

	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	import starling.display.BlendMode;
	import starling.display.Sprite;
	import starling.utils.Pool;

	public class MapLayer extends Sprite implements IUpdatableMapLayer
	{
		protected var _options:MapLayerOptions;
		public function get options():MapLayerOptions
		{
			return _options;
		}

		protected var id:String;
		protected var urlTemplate:String;
		protected var tilesDictionary:Dictionary = new Dictionary(true);
		protected var tileSize:int;
		protected var minZoomVisibility:int;
		protected var maxZoomVisibility:int;
		protected var removeTileZoomThreshold:int;
		protected var tileCreationMargin:int;
		protected var firstLoad:Boolean = true;

		protected var mapTilesBuffer:MapTilesBuffer;

		/** Required to calculate the ${z} portion of the URL from the map zoom level. */
		protected var maximumZoom:int;

		protected var tilesTextureCache:TextureCache;

		protected var _suspendUpdates:Boolean;
		public function get suspendUpdates():Boolean
		{
			return _suspendUpdates;
		}
		public function set suspendUpdates(value:Boolean):void
		{
			_suspendUpdates = value;
		}

		public function MapLayer(id:String, options:MapLayerOptions, buffer:MapTilesBuffer)
		{
			super();

			this.id = id;

			_options = options;
			mapTilesBuffer = buffer;

			urlTemplate = _options.urlTemplate;
			if (!urlTemplate)
			{
				throw new Error("urlTemplate option is required");
			}
			tileSize = _options.tileSize;
			if (!tileSize)
			{
				throw new Error("tileSize option is required");
			}
			removeTileZoomThreshold = _options.removeTileZoomThreshold || 0;
			minZoomVisibility = _options.minimumZoomVisibility;
			maxZoomVisibility = _options.maximumZoomVisibility;
			tileCreationMargin = _options.tileCreationMargin || 0;
			blendMode = _options.blendMode || BlendMode.NORMAL;
			maximumZoom = _options.maximumZoomLevel || Map.MAX_ZOOM;
			tilesTextureCache = _options.tilesTextureCache;
		}

		/**
		 * Check tiles and create new ones if needed.
		 */
		protected function checkTiles(area:Rectangle, zoom:int, scale:int):void
		{
			var relativeZoom:int = maximumZoom - zoom;
			if (relativeZoom < minZoomVisibility || relativeZoom > maxZoomVisibility)
			{
				return;
			}

			var actualTileSize:Number = tileSize * scale;

			var limit:Rectangle = options.limitTileCreationTo;
			if (limit != null)
			{
				var minX:int = Math.max(area.left, limit.left) / actualTileSize;
				var maxX:int = Math.min(area.right, limit.right) / actualTileSize;
				var minY:int = Math.max(area.top, limit.top) / actualTileSize;
				var maxY:int = Math.min(area.bottom, limit.bottom) / actualTileSize;
			}
			else
			{
				minX = area.left / actualTileSize;
				maxX = area.right / actualTileSize;
				minY = area.top / actualTileSize;
				maxY = area.bottom / actualTileSize;
			}

			// Move in a spiral from the center:
			var directionX:int = 1;
			var directionY:int = 0;
			var currentX:int = minX + (maxX - minX) / 2;
			var currentY:int = minY + (maxY - minY) / 2;
			var currentSegmentLength:int = 1;
			var currentSegmentIndex:int;

			var total:int = (maxX - minX + 1) * (maxY - minY + 1); // Adding the 1s to make inclusive.
			var completed:int = 0;

			while (true) // Break loop from inside.
			{
				if (currentX >= minX && currentX <= maxX && currentY >= minY && currentY <= maxY)
				{
					createTile(currentX, currentY, actualTileSize, zoom, scale);
					completed++;
					if (completed >= total)
					{
						break;
					}
				}
				currentX += directionX;
				currentY += directionY;
				currentSegmentIndex++;

				if (currentSegmentIndex == currentSegmentLength)
				{
					// Current segment complete:
					currentSegmentIndex = 0;
					// 'Rotate' directions:
					var prevDirectionX:int = directionX;
					directionX = -directionY;
					directionY = prevDirectionX;
					// Increase segment length every 2 rotations:
					if (directionY == 0)
					{
						currentSegmentLength++;
					}
				}
			}
		}

		/**
		 * Removes tiles no-longer required.
		 */
		protected function checkNotUsedTiles(area:Rectangle, zoom:int):void
		{
			var relativeZoom:int = maximumZoom - zoom;
			for each (var tile:MapTile in tilesDictionary)
			{
				var tileBounds:Rectangle = tile.getBounds(tile.parent, Pool.getRectangle());
				if (relativeZoom < minZoomVisibility || relativeZoom > maxZoomVisibility || !area.intersects(tileBounds) || Math.abs(zoom - tile.zoom) > removeTileZoomThreshold)
				{
					removeTile(tile);
				}
			}
		}

		protected function createTile(x:int, y:int, actualTileSize:Number, zoom:int, scale:int):MapTile
		{
			var key:String = getKey(x, y, zoom);

			var tile:MapTile = tilesDictionary[key] as MapTile;
			if (tile)
			{
				addChild(tile);
			}
			else
			{
				var url:String = urlTemplate.replace("{z}", maximumZoom - zoom).replace("{x}", x).replace("{y}", y);
				tile = mapTilesBuffer.getTile(x, y, zoom);
				addChild(tile);

				tile.loadInstantly ||= (_options.loadInitialTilesInstantly && firstLoad);
				tile.prioritiseBuffering = options.prioritiseTileLoading;
				tile.animateShow = _options.animateShowTiles;
				tile.textureCache = tilesTextureCache;
				tile.source = url;
				tile.setSize(tileSize, tileSize);
				tile.move(x * actualTileSize, y * actualTileSize);
				tile.scaleX = tile.scaleY = scale;

				tilesDictionary[key] = tile;
			}
			return tile;
		}

		protected function removeTile(tile:MapTile):MapTile
		{
			mapTilesBuffer.release(tile);
			tile.removeFromParent();
			var key:String = getKey(tile.mapX, tile.mapY, tile.zoom);
			tilesDictionary[key] = null;
			delete tilesDictionary[key];
			return tile;
		}

		protected function getKey(x:int, y:int, zoom:int):String
		{
			return x + "x" + y + "x" + zoom;
		}

		public function update(viewport:Rectangle, zoomLevel:int, scaleRatio:int):void
		{
			if (tileCreationMargin)
			{
				viewport.inflate(tileCreationMargin, tileCreationMargin);
			}

			checkTiles(viewport, zoomLevel, scaleRatio);
			checkNotUsedTiles(viewport, zoomLevel);
			firstLoad = false;
		}
	}
}