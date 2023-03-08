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

		override protected function saveMeasurements(width:Number, height:Number, minWidth:Number = 0, minHeight:Number = 0):Boolean
		{
			// In some cases, these values can flip-flop between values of different precision,
			// In other cases the layout of renderers can malfunction.
			// Rounding up seems to fix this.
			if (width == width)
			{
				width = Math.ceil(width);
			}
			if (height == height)
			{
				height = Math.ceil(height);
			}
			if (minWidth == minWidth)
			{
				minWidth = Math.ceil(minWidth);
			}
			if (minHeight == minHeight)
			{
				minHeight = Math.ceil(minHeight);
			}
			return super.saveMeasurements(width, height, minWidth, minHeight);
		}
	}
}