package feathers.extensions.maps
{
	public class MapVideoLayerOptions
	{
		public var index:int = -1;

		/**
		 * Supports <code>String</code>, <code>File</code> and <code>URLRequest</code> by default.
		 * Ultimately needs to resolve to a String.
		 */
		public var videoSource:Object;
		public var videoDisplayWidth:int = -1;
		public var videoDisplayHeight:int = -1;
		public var videoCodedHeight:int = -1;

		/** A number between 0 and 1. */
		public var volume:Number = 1;
	}
}