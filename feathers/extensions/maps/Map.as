package feathers.extensions.maps
{
	import com.esidegallery.utils.MathUtils;

	import feathers.core.IFeathersControl;
	import feathers.utils.touch.TapToTrigger;

	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.utils.Pool;

	public class Map extends TouchSheetContainer
	{
		public static const MIN_ZOOM:int = 1;
		public static const MAX_ZOOM:int = 20;

		/**
		 * Defaults to <code>MapLayer</code>. The class contructor needs to have the following signature:<br/>
		 * <code>MapLayer(map:Map, id:String, options:MapLayerOptions, buffer:MapTilesBuffer)</code>
		 */
		public var mapLayerFactoryClass:Class = MapLayer;

		/**
		 * Defaults to <code>MapImageLayer</code>. The class contructor needs to have the following signature:<br/>
		 * <code>MapImageLayer(map:Map, id:String, options:MapImageLayerOptions)</code>
		 */
		public var imageLayerFactoryClass:Class = MapImageLayer;

		/**
		 * Defaults to <code>MapVideoLayer</code>. The class contructor needs to have the following signature:<br/>
		 * <code>MapVideoLayer(map:Map, id:String, options:MapVideoLayerOptions)</code>
		 */
		public var videoLayerFactoryClass:Class = MapVideoLayer;

		protected var _customMarkerSortCompareFunction:Function;
		public function get customMarkerSortCompareFunction():Function
		{
			return _customMarkerSortCompareFunction;
		}
		public function set customMarkerSortCompareFunction(value:Function):void
		{
			if (_customMarkerSortCompareFunction == value)
			{
				return;
			}
			_customMarkerSortCompareFunction = value;
			sortMarkers();
		}

		private var _zoomLevel:int;
		public function get zoomLevel():int
		{
			return _zoomLevel;
		}

		private var _scaleRatio:int;
		public function get scaleRatio():int
		{
			return _scaleRatio;
		}

		protected var mapTilesBuffer:MapTilesBuffer;

		protected var mapContainer:Sprite;
		protected var markersContainer:Sprite;

		protected var layers:Dictionary;
		protected var markers:Dictionary;

		public function Map()
		{
			clipContent = true;

			layers = new Dictionary;
			markers = new Dictionary;

			mapTilesBuffer = new MapTilesBuffer;

			mapContainer = new Sprite;
			markersContainer = new Sprite;
			mapContainer.addChild(markersContainer);

			content = mapContainer;
		}

		public function addMapLayer(id:String, options:MapLayerOptions = null):DisplayObject
		{
			var layer:MapLayer = layers[id] as MapLayer;

			if (layer == null && options != null)
			{
				var childIndex:uint = options.index >= 0 ? Math.min(options.index, mapContainer.numChildren) : mapContainer.numChildren;

				layer = new mapLayerFactoryClass(id, options, mapTilesBuffer) as MapLayer;
				if (layer == null)
				{
					throw new Error("layerFactoryClass is invalid");
				}

				mapContainer.addChildAt(layer, childIndex);
				mapContainer.addChild(markersContainer); // Markers above layers.

				layers[id] = layer;
			}

			return layer;
		}

		public function addImageLayer(id:String, options:MapImageLayerOptions):DisplayObject
		{
			var layer:MapImageLayer = layers[id] as MapImageLayer;

			if (layer == null && options != null)
			{
				var childIndex:uint = options.index >= 0 ? Math.min(options.index, mapContainer.numChildren) : mapContainer.numChildren;

				layer = new imageLayerFactoryClass(this, id, options) as MapImageLayer;
				if (layer == null)
				{
					throw new Error("imageLayerFactoryClass is invalid");
				}

				mapContainer.addChildAt(layer, childIndex);
				mapContainer.addChild(markersContainer); // Markers above layers.

				layers[id] = layer;
			}

			return layer;
		}

		public function addVideoLayer(id:String, options:MapVideoLayerOptions):DisplayObject
		{
			var layer:MapVideoLayer = layers[id] as MapVideoLayer;

			if (layer == null && options != null)
			{
				var childIndex:uint = options.index >= 0 ? Math.min(options.index, mapContainer.numChildren) : mapContainer.numChildren;

				layer = new videoLayerFactoryClass(this, id, options) as MapVideoLayer;
				if (layer == null)
				{
					throw new Error("videoLayerFactoryClass is invalid");
				}

				mapContainer.addChildAt(layer, childIndex);
				mapContainer.addChild(markersContainer); // Markers above layers.

				layers[id] = layer;
			}

			return layer;
		}

		public function removeLayer(id:String):DisplayObject
		{
			var layer:DisplayObject = layers[id] as DisplayObject;
			if (layer != null)
			{
				layer.removeFromParent(true);
				delete layers[id];
			}
			return layer;
		}

		public function removeAllLayers():void
		{
			for (var id:String in layers)
			{
				removeLayer(id);
			}
		}

		public function hasLayer(id:String):Boolean
		{
			return layers[id] != null;
		}

		public function getLayer(id:String):DisplayObject
		{
			return layers[id] as DisplayObject;
		}

		public function addMarker(id:String, x:Number, y:Number, displayObject:DisplayObject, data:Object = null, scaleWithMap:Boolean = false):MapMarker
		{
			if (!id || displayObject == null)
			{
				return null;
			}

			// Can't have markers with the same ID:
			removeMarker(id, true);

			var newMarker:MapMarker = new MapMarker(id, displayObject, data, scaleWithMap);
			markers[id] = newMarker;

			displayObject.name = id;
			displayObject.x = x;
			displayObject.y = y;

			new TapToTrigger(displayObject);
			displayObject.addEventListener(Event.TRIGGERED, markerDisplayObject_triggeredHandler);

			markersContainer.addChild(displayObject);
			sortMarkers();

			return newMarker;
		}

		public function getMarker(id:String):MapMarker
		{
			return markers[id] as MapMarker;
		}

		public function hasMarker(id:String):Boolean
		{
			return markers[id];
		}

		public function getAllMarkers():Vector.<MapMarker>
		{
			var allMarkers:Vector.<MapMarker> = new Vector.<MapMarker>;
			for (var id:Object in markers)
			{
				var marker:MapMarker = markers[id] as MapMarker;
				marker && allMarkers.push(marker);
			}
			return allMarkers;
		}

		public function removeMarker(id:String, dispose:Boolean = false):MapMarker
		{
			var mapMarker:MapMarker = getMarker(id);

			if (mapMarker)
			{
				var displayObject:DisplayObject = mapMarker.displayObject;
				if (displayObject)
				{
					displayObject.removeEventListener(MapEventType.MARKER_TRIGGERED, markerDisplayObject_triggeredHandler);
					displayObject.removeFromParent(dispose);
				}
				delete markers[id];
			}

			return mapMarker;
		}

		public function removeAllMarkers(dispose:Boolean = false):void
		{
			for (var id:String in markers)
			{
				removeMarker(id, dispose);
			}
		}

		public function sortMarkers():void
		{
			var markers:Vector.<MapMarker> = getAllMarkers();
			if (_customMarkerSortCompareFunction != null)
			{
				markers.sort(_customMarkerSortCompareFunction);
			}
			else
			{
				markers.sort(defaultMarkerSortCompareFunction);
			}
			for (var i:int = 0, l:int = markers.length; i < l; i++)
			{
				markersContainer.addChildAt(markers[i].displayObject, i);
			}
		}

		private function updateZoomAndScale():void
		{
			_scaleRatio = 1;
			var z:int = int(1 / currentScale / Starling.contentScaleFactor);
			while (z >= _scaleRatio << 1)
			{
				_scaleRatio <<= 1;
			}

			var s:uint = _scaleRatio;
			_zoomLevel = 1;
			while (s > 1)
			{
				s >>= 1;
				++_zoomLevel;
			}
		}

		protected function updateMarkers():void
		{
			var staticScale:Number = 1 / currentScale;

			for each (var marker:MapMarker in getAllMarkers())
			{
				if (marker.displayObject == null)
				{
					continue;
				}
				if (!marker.scaleWithMap)
				{
					marker.displayObject.scale = staticScale;
				}
			}
		}

		protected static function defaultMarkerSortCompareFunction(marker1:MapMarker, marker2:MapMarker):Number
		{
			if (marker1.alwaysOnTop && !marker2.alwaysOnTop)
			{
				return 1;
			}
			if (!marker1.alwaysOnTop && marker2.alwaysOnTop)
			{
				return -1;
			}

			if (marker1.scaleWithMap)
			{
				if (marker2.scaleWithMap) // Compare y's:
				{
					return marker1.displayObject.y - marker2.displayObject.y;
				}
				else // marker 2 will be higher:
				{
					return -1;
				}
			}

			if (marker2.scaleWithMap)
			{
				return 1;
			}
			else
			{
				return marker1.displayObject.y - marker2.displayObject.y;
			}
		}

		protected function update():void
		{
			updateZoomAndScale();
			updateMarkers();
			var viewport:Rectangle = getViewPort(Pool.getRectangle());
			for (var id:String in layers)
			{
				var layer:IUpdatableMapLayer = getLayer(id) as IUpdatableMapLayer;
				if (layer != null && !layer.suspendUpdates)
				{
					layer.update(viewport, _zoomLevel, _scaleRatio);
				}
			}
			Pool.putRectangle(viewport);
		}

		override protected function updateTouchSheetLimits():void
		{
			if (touchSheet == null)
			{
				return;
			}

			// Movement bounds dont default to content size, as this works differently in Map.
			// It is either to be set externally, or it will be free of any movement constraints.
			touchSheet.movementBounds = movementBounds;

			var paddedWidth:Number = actualWidth - (paddingH || 0) * 2;
			var paddedHeight:Number = actualHeight - (paddingV || 0) * 2;

			var minScale:Number = !isNaN(minimumScale) ? minimumScale : MapUtils.getScaleForScaleMode(minimumScaleMode, touchSheet.movementBounds.width, touchSheet.movementBounds.height, paddedWidth, paddedHeight);
			var maxScale:Number = !isNaN(maximumScale) ? maximumScale : MapUtils.getScaleForScaleMode(maximumScaleMode, touchSheet.movementBounds.width, touchSheet.movementBounds.height, paddedWidth, paddedHeight);

			touchSheet.minimumScale = MathUtils.isNotNaNOrInfinity(minScale) ? minScale : 0;
			touchSheet.maximumScale = MathUtils.isNotNaNOrInfinity(maxScale) ? Math.max(touchSheet.minimumScale, maxScale) : Number.MAX_VALUE;
		}

		private function markerDisplayObject_triggeredHandler(event:Event):void
		{
			if (touchSheet.wasManipulated)
			{
				return;
			}
			var displayObject:DisplayObject = event.currentTarget as DisplayObject;
			if (displayObject == null || displayObject is IFeathersControl && !(displayObject as IFeathersControl).isEnabled)
			{
				return;
			}

			var marker:MapMarker = getMarker(displayObject.name);
			if (marker == null)
			{
				return;
			}
			var velocity:Point = touchSheet.getVelocity(Pool.getPoint());
			if (Math.abs(velocity.length) < TouchSheet.MINIMUM_VELOCITY)
			{
				dispatchEventWith(MapEventType.MARKER_TRIGGERED, false, marker);
			}
			Pool.putPoint(velocity);
		}

		override protected function touchSheet_tweenUpdateHandler():void
		{
			// Update instantly to avoid a lag on statically sized markers:
			update();

			super.touchSheet_tweenUpdateHandler();
		}

		override protected function touchSheet_viewPortChangedHandler():void
		{
			update();

			super.touchSheet_viewPortChangedHandler();
		}
	}
}