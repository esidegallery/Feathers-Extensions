package feathers.extensions.maps
{
	import starling.utils.ScaleMode;

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

		public static function getScaleForScaleMode(scaleMode:String, movementBoundsWidth:Number, movementBoundsHeight:Number, containerWidth:Number, containerHeight:Number):Number
		{
			if (isNaN(movementBoundsWidth) || isNaN(movementBoundsHeight) || isNaN(containerWidth) || isNaN(containerHeight) || (scaleMode != ScaleMode.SHOW_ALL && scaleMode != ScaleMode.NO_BORDER))
			{
				return NaN;
			}
			var touchSheetAspect:Number = movementBoundsWidth / movementBoundsHeight;
			var containerAspect:Number = containerWidth / containerHeight;
			if (scaleMode == ScaleMode.SHOW_ALL)
			{
				return touchSheetAspect > containerAspect ? containerWidth / movementBoundsWidth : containerHeight / movementBoundsHeight;
			}
			else
			{
				return touchSheetAspect > containerAspect ? containerHeight / movementBoundsHeight : containerWidth / movementBoundsWidth;
			}
		}
	}
}