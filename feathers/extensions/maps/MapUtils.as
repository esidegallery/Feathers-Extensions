package feathers.extensions.maps
{
	public class MapUtils
	{
		public static function getMaxZoom(mapWidth:Number, mapHeight:Number, tileSize:int):int
		{
			var zoom:int = 1;
			var currentSize:int = Math.max(mapWidth, mapHeight);
			while (currentSize > tileSize)
			{
				currentSize *= 0.5;
				zoom++;
			}
			return zoom;
		}

		public static function getMinZoom(mapWidth:Number, mapHeight:Number, tileSize:int, minimumViewSize:Number):int
		{
			var zoom:int = getMaxZoom(mapWidth, mapHeight, tileSize);
			var currentSize:int = Math.max(mapWidth, mapHeight);
			while (currentSize > minimumViewSize)
			{
				currentSize *= 0.5;
				zoom--;
			}
			return zoom;
		}
	}
}