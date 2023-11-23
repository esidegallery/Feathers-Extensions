package feathers.extensions.maps
{
	import flash.geom.Rectangle;

	public interface IUpdatableMapLayer
	{
		function get suspendUpdates():Boolean;
		function set suspendUpdates(value:Boolean):void;

		function update(viewport:Rectangle, zoomLevel:int, scaleRatio:int):void;
	}
}