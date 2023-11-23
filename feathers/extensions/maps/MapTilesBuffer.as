package feathers.extensions.maps
{
	import feathers.extensions.maps.MapTile;

	import starling.core.Starling;

	public class MapTilesBuffer
	{
		protected var tilePool:Vector.<MapTile> = new Vector.<MapTile>;
		protected var bufferingQueue:Vector.<MapTile> = new Vector.<MapTile>;

		public function MapTilesBuffer()
		{
			Starling.juggler.repeatCall(processQueue, 0.01); // 100 per second.
		}

		public function getTile(mapX:int, mapY:int, zoom:int):MapTile
		{
			var mapTile:MapTile = tilePool.pop();

			if (mapTile == null)
			{
				mapTile = new MapTile(mapX, mapY, zoom, this);
			}
			else
			{
				mapTile.mapX = mapX;
				mapTile.mapY = mapY;
				mapTile.zoom = zoom;
			}
			mapTile.visible = false;
			mapTile.alpha = 0;

			return mapTile;
		}

		public function add(mapTile:MapTile, prioritise:Boolean = false):void
		{
			if (bufferingQueue.indexOf(mapTile) < 0)
			{
				if (prioritise)
				{
					bufferingQueue.unshift(mapTile);
				}
				else
				{
					bufferingQueue.push(mapTile);
				}
			}
		}

		public function release(mapTile:MapTile):void
		{
			if (mapTile.source)
			{
				mapTile.source = null;
			}
			mapTile.loadInstantly = false;
			mapTile.delayedSource = null;
			mapTile.visible = false;
			tilePool.push(mapTile);
		}

		protected function processQueue():void
		{
			while (bufferingQueue.length > 0)
			{
				var mapTile:MapTile = bufferingQueue.shift();
				if (mapTile.isDisposed || !mapTile.delayedSource)
				{
					continue;
				}
				mapTile.source = mapTile.delayedSource;
				return;
			}
		}

		public function dispose():void
		{
			Starling.juggler.removeDelayedCalls(processQueue);
			for each (var tile:MapTile in tilePool)
			{
				if (tile.isDisposed)
				{
					return;
				}
				tile.dispose();
			}
			for each (tile in bufferingQueue)
			{
				if (tile.isDisposed)
				{
					return;
				}
				tile.dispose();
			}
			tilePool.length = 0;
			bufferingQueue.length = 0;
		}
	}
}