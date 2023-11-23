package feathers.extensions.maps
{
	public class TouchSheetEventType
	{
		/** Dispatched when the touchsheet is moved during a touch interaction. */
		public static const MOVE:String = "move";

		/** Dispatched when the touchsheet is zoomed/scaled during a touch interaction. */
		public static const ZOOM:String = "zoom";

		/** Dispatched when the touchsheet is rotated during a touch interaction. */
		public static const ROTATE:String = "rotate";

		/** Dispatched by TouchSheetContainer when the viewport bounds have changed for any reason. */
		public static const VIEW_PORT_CHANGED:String = "viewPortChanged";
	}
}