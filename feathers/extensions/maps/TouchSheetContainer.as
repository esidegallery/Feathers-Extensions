package feathers.extensions.maps
{
	import com.esidegallery.events.EventType;
	import com.esidegallery.utils.MathUtils;

	import feathers.core.FeathersControl;
	import feathers.events.FeathersEventType;
	import feathers.utils.math.clamp;
	import feathers.utils.touch.TapToEventExtended;

	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.animation.Transitions;
	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.utils.Pool;
	import starling.utils.ScaleMode;

	public class TouchSheetContainer extends FeathersControl
	{
		private static const INVALIDATION_FLAG_CONTENT:String = "content";

		private var _movementEnabled:Boolean = true;
		public function get movementEnabled():Boolean
		{
			return _movementEnabled;
		}
		public function set movementEnabled(value:Boolean):void
		{
			_movementEnabled = value;
			if (touchSheet != null)
			{
				touchSheet.movementEnabled = _movementEnabled;
			}
		}

		private var _zoomingEnabled:Boolean = true;
		public function get zoomingEnabled():Boolean
		{
			return _zoomingEnabled;
		}
		public function set zoomingEnabled(value:Boolean):void
		{
			_zoomingEnabled = value;
			if (touchSheet != null)
			{
				touchSheet.zoomingEnabled = _zoomingEnabled;
			}
		}

		/** The value to use for auto-animations & when specific value is ommitted. */
		public var defaultAnimationDuration:Number = 0.75;

		/** The value to use for auto-animations & when specific value is ommitted. */
		public var defaultAnimationTransition:String = Transitions.EASE_IN_OUT;

		public var mouseWheelZoomStep:Number = 0.2;

		private var _doubleTapToZoom:Boolean = true;
		public function get doubleTapToZoom():Boolean
		{
			return _doubleTapToZoom;
		}
		public function set doubleTapToZoom(value:Boolean):void
		{
			if (_doubleTapToZoom == value)
			{
				return;
			}
			_doubleTapToZoom = value;
			if (_doubleTapToZoom)
			{
				initDoubleTap();
			}
			else if (doubleTapToEvent != null)
			{
				doubleTapToEvent.target = null;
				doubleTapToEvent = null;
			}
		}

		/**
		 * The amount to zoom by when double tapping.
		 * If set to NaN and min/max scale is set, double tapping will ping pong between these values.
		 */
		public var doubleTapZoomStep:Number = 1;

		override public function set isEnabled(value:Boolean):void
		{
			super.isEnabled = value;
			if (touchSheet != null)
			{
				touchSheet.isEnabled = _isEnabled;
			}
		}

		private var _clipContent:Boolean;
		public function get clipContent():Boolean
		{
			return _clipContent;
		}
		public function set clipContent(value:Boolean):void
		{
			if (_clipContent == value)
			{
				return;
			}
			_clipContent = value;
			if (_clipContent)
			{
				super.mask = new Quad(1, 1);
			}
			else if (super.mask != null)
			{
				super.mask.dispose();
				super.mask = null;
			}
			invalidate(INVALIDATION_FLAG_SIZE);
		}

		protected var _content:DisplayObject;

		/** Note that any unset content isn't automatically disposed. */
		public function get content():DisplayObject
		{
			return _content;
		}
		public function set content(value:DisplayObject):void
		{
			if (_content == value)
			{
				return;
			}
			if (touchSheet != null)
			{
				disposeTouchSheet();
			}
			_content = value;
			invalidate(INVALIDATION_FLAG_CONTENT);
		}

		/**
		 * The view rectangle to set on <code>content</code> when set.
		 * This will be confined to any scale limits that have been set.</br>
		 * If set, overrides <code>initialScaleMode</code>. Overridden by <code>initialViewRectangle</code>.
		 */
		public var initialViewRectangle:Rectangle;

		/**
		 * The scale to set <code>content</code> when set.
		 * This will be confined to any scale limits that have been set.</br>
		 * If not NaN, overrides <code>initialScaleMode</code>. Overridden by <code>initialViewRectangle</code>.
		 */
		public var initialScale:Number = NaN;

		/**
		 * If set, The <code>ScaleMode</code> to set <code>content</code> when set.
		 * This will be confined to any scale limits that have been set.</br>
		 * Overridden by <code>initialScale</code> & <code>initialViewRectangle</code>.
		 */
		public var initialScaleMode:String = ScaleMode.SHOW_ALL;

		/** If not NaN, overrides <code>minimumScaleMode</code>. */
		public var minimumScale:Number = NaN;

		/**
		 * If set, the content can be zoomed out to the equivalent of this <code>ScaleMode</code>.<br/>
		 * Overridden by <code>minimumScale</code>.
		 */
		public var minimumScaleMode:String = ScaleMode.SHOW_ALL;

		/** If not NaN, overrides <code>maximumScaleMode</code>. */
		public var maximumScale:Number = NaN;

		/**
		 * If set, the content can be zoomed in to the equivalent of this <code>ScaleMode</code>.<br/>
		 * Overridden by <code>maximumScale</code>.
		 */
		public var maximumScaleMode:String;

		public function get currentScale():Number
		{
			return touchSheet != null ? touchSheet.scale : NaN;
		}

		public var movementBounds:Rectangle;

		private var _inertia:Number = 0.88;
		public function get inertia():Number
		{
			return _inertia;
		}
		public function set inertia(value:Number):void
		{
			_inertia = value;
			if (touchSheet != null)
			{
				touchSheet.inertia = _inertia;
			}
		}

		private var _touchElasticity:Number = 0.4;
		public function get touchElasticity():Number
		{
			return _touchElasticity;
		}
		public function set touchElasticity(value:Number):void
		{
			_touchElasticity = value;
			if (touchSheet != null)
			{
				touchSheet.touchElasticity = _touchElasticity;
			}
		}

		private var _nonTouchElasticity:Number = 0.85;
		public function get nonTouchElasticity():Number
		{
			return _nonTouchElasticity;
		}
		public function set nonTouchElasticity(value:Number):void
		{
			_nonTouchElasticity = value;
			if (touchSheet != null)
			{
				touchSheet.nonTouchElasticity = _nonTouchElasticity;
			}
		}

		public function get isTouching():Boolean
		{
			return touchSheet != null && touchSheet.isTouching;
		}

		public function get wasManipulated():Boolean
		{
			return touchSheet != null && touchSheet.wasManipulated;
		}

		protected var touchSheet:TouchSheetExtended;
		protected var doubleTapToEvent:TapToEventExtended;
		protected var dragDistance:Number;

		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			throw new Error("Use content property in TouchScreenContainer");
		}

		override public function removeChildAt(index:int, dispose:Boolean = false):DisplayObject
		{
			throw new Error("Use content property in TouchScreenContainer");
		}

		override public function set mask(value:DisplayObject):void
		{
			throw new Error("TouchScreenContainer manages its own mask");
		}

		public function forceTouchSheetUpdate():void
		{
			if (touchSheet == null)
			{
				return;
			}
			touchSheet.invalidate(INVALIDATION_FLAG_LAYOUT);
			touchSheet.validate();
		}

		/**
		 * @param duration If NaN, defaults to <code>defaultAnimationDuration</code>
		 * @param transition If null, defaults to <code>defaultAnimationTransition</code>
		 */
		public function showInitialView(duration:Number = 0, transition:String = null):void
		{
			if (touchSheet == null)
			{
				return;
			}

			updateTouchSheetLimits();
			updateTouchSheetViewport();

			if (initialViewRectangle != null && touchSheet.movementBounds != null)
			{
				tweenToViewRectangle(initialViewRectangle, 0);
			}
			else if (!isNaN(initialScale))
			{
				var scaleValue:Number = initialScale;
			}
			else
			{
				scaleValue = getScaleForScaleMode(initialScaleMode);
			}

			if (isNaN(duration))
			{
				duration = defaultAnimationDuration;
			}
			if (transition == null)
			{
				transition = defaultAnimationTransition;
			}

			if (!isNaN(scaleValue))
			{
				scaleTo(scaleValue, NaN, NaN, duration, transition);
			}
		}

		public function snapToBounds():void
		{
			if (touchSheet == null)
			{
				return;
			}

			updateTouchSheetLimits();
			updateTouchSheetViewport();
			touchSheet.snapToBounds();
		}

		public function scaleTo(toScale:Number, pivotX:Number = NaN, pivotY:Number = NaN, duration:Number = NaN, transition:String = null):void
		{
			if (touchSheet == null)
			{
				return;
			}

			updateTouchSheetLimits();
			updateTouchSheetViewport();

			if (isNaN(pivotX))
			{
				var viewCenter:Point = getViewCenter(Pool.getPoint());
				pivotX = viewCenter.x;
			}
			if (isNaN(pivotY))
			{
				viewCenter ||= getViewCenter(Pool.getPoint());
				pivotY = viewCenter.y;
			}
			if (isNaN(duration))
			{
				duration = defaultAnimationDuration;
			}
			if (!transition == null)
			{
				transition = defaultAnimationTransition;
			}
			Pool.putPoint(viewCenter);
			touchSheet.scaleTo(toScale, pivotX, pivotY, duration, transition, touchSheet_tweenUpdateHandler);
		}

		/**
		 * Animates to the passed coordinates &/or scale, keeping within movement & scale bounds.
		 * @param toCenterX The value, in TouchSheet's coordinate space, to tween the center of the viewport to. If NaN, no x tweening will take place.
		 * @param toCenterY The value, in TouchSheet's coordinate space, to tween the center of the viewport to. If NaN, no y tweening will take place.
		 * @param soScale If NaN, no scale tweening will take place.
		 * @param duration If NaN, defaults to <code>defaultAnimationDuration</code>
		 * @param transition If null, defaults to <code>defaultAnimationTransition</code>
		 */
		public function tweenTo(toCenterX:Number, toCenterY:Number, toScale:Number, duration:Number = NaN, transition:String = null):void
		{
			if (touchSheet == null)
			{
				return;
			}

			updateTouchSheetLimits();
			updateTouchSheetViewport();

			var viewCenter:Point = getViewCenter(Pool.getPoint());
			touchSheet.setPivot(!isNaN(toCenterX) ? toCenterX : viewCenter.x, !isNaN(toCenterY) ? toCenterY : viewCenter.y);

			toScale = !isNaN(toScale) ? clamp(toScale, touchSheet.minimumScale, touchSheet.maximumScale) : touchSheet.scale;
			if (isNaN(duration))
			{
				duration = defaultAnimationDuration;
			}
			if (transition == null)
			{
				transition = defaultAnimationTransition;
			}

			if (!isNaN(toCenterX) || !isNaN(toCenterY))
			{
				var minX:Number = Number.MIN_VALUE;
				var maxX:Number = Number.MAX_VALUE;
				var minY:Number = Number.MIN_VALUE;
				var maxY:Number = Number.MAX_VALUE;

				// Get movementBounds & pivot at final scale:
				var finalMovementBounds:Rectangle = Pool.getRectangle();
				finalMovementBounds.copyFrom(touchSheet.movementBounds);
				finalMovementBounds.x *= toScale;
				finalMovementBounds.y *= toScale;
				finalMovementBounds.width *= toScale;
				finalMovementBounds.height *= toScale;
				var finalPivot:Point = Pool.getPoint(touchSheet.pivotX, touchSheet.pivotY);
				finalPivot.x *= toScale;
				finalPivot.y *= toScale;

				if (actualWidth > finalMovementBounds.width) // Zoomed out beyond movement bounds:
				{
					minX = finalPivot.x + (actualWidth - finalMovementBounds.width) / 2;
					maxX = minX;
				}
				else // Zoomed within movement bounds:
				{
					minX = finalPivot.x - finalMovementBounds.right + actualWidth;
					maxX = finalPivot.x - finalMovementBounds.left;
				}
				if (actualHeight > finalMovementBounds.height) // Zoomed out beyond movement bounds:
				{
					minY = finalPivot.y + (actualHeight - finalMovementBounds.height) / 2;
					maxY = minY;
				}
				else // Zoomed within movement bounds:
				{
					minY = finalPivot.y - finalMovementBounds.bottom + actualHeight;
					maxY = finalPivot.y - finalMovementBounds.top;
				}

				// Convert view center from touchsheet coords to local coords:
				touchSheet.localToGlobal(viewCenter, viewCenter);
				globalToLocal(viewCenter, viewCenter);

				if (!isNaN(toCenterX))
				{
					var diff:Number = viewCenter.x - touchSheet.x;
					var toX:Number = touchSheet.x + diff;
					if (toX < minX)
					{
						toX = minX;
					}
					if (toX > maxX)
					{
						toX = maxX;
					}
				}
				if (!isNaN(toCenterY))
				{
					diff = viewCenter.y - touchSheet.y;
					var toY:Number = touchSheet.y + diff;
					if (toY < minY)
					{
						toY = minY;
					}
					if (toY > maxY)
					{
						toY = maxY;
					}
				}
				Pool.putRectangle(finalMovementBounds);
				Pool.putPoint(finalPivot);
			}

			Pool.putPoint(viewCenter);
			touchSheet.tweenTo(toX, toY, toScale, duration, transition, touchSheet_tweenUpdateHandler);
		}

		/**
		 * @param rectangle The view rectangle to tween to. This will be fit inside the viewport using <code>ScaleMode.SHOW_ALL</code>.
		 * @param duration If NaN, defaults to <code>defaultAnimationDuration</code>
		 * @param transition If null, defaults to <code>defaultAnimationTransition</code>
		 */
		public function tweenToViewRectangle(rectangle:Rectangle, duration:Number = NaN, transition:String = null):void
		{
			if (touchSheet == null)
			{
				return;
			}

			updateTouchSheetLimits();
			updateTouchSheetViewport();

			var rectAspect:Number = rectangle.width / rectangle.height;
			var viewportAspect:Number = touchSheet.viewPort.width / touchSheet.viewPort.height;
			if (rectAspect > viewportAspect)
			{
				var newScale:Number = touchSheet.viewPort.width / rectangle.width * touchSheet.scale;
			}
			else
			{
				newScale = touchSheet.viewPort.height / rectangle.height * touchSheet.scale;
			}
			tweenTo(rectangle.left + rectangle.width / 2, rectangle.top + rectangle.height / 2, newScale, duration, transition);
		}

		public function getViewPort(out:Rectangle = null):Rectangle
		{
			updateTouchSheetViewport();

			out ||= new Rectangle;
			if (touchSheet == null)
			{
				out.setTo(0, 0, 0, 0);
			}
			else
			{
				out.copyFrom(touchSheet.viewPort);
			}
			return out;
		}

		/** The center of the viewport in the TouchSheet's coordinate space. */
		public function getViewCenter(out:Point = null):Point
		{
			updateTouchSheetViewport();

			out ||= new Point();
			if (touchSheet == null || touchSheet.viewPort == null)
			{
				out.setTo(0, 0);
			}
			else
			{
				out.setTo(touchSheet.viewPort.left + touchSheet.viewPort.width * 0.5, touchSheet.viewPort.top + touchSheet.viewPort.height * 0.5);
			}
			return out;
		}

		public function globalToTouchSheetLocal(globalX:Number, globalY:Number, out:Point = null):Point
		{
			updateTouchSheetViewport();

			out ||= new Point;
			if (touchSheet == null)
			{
				out.setTo(0, 0);
			}
			else
			{
				out.setTo(globalX, globalY);
				touchSheet.globalToLocal(out, out);
			}
			return out;
		}

		public function getTouchSheetChildBounds(child:DisplayObject, out:Rectangle = null):Rectangle
		{
			out ||= new Rectangle;

			if (touchSheet == null)
			{
				out.setTo(0, 0, 0, 0);
			}
			else
			{
				child.getBounds(touchSheet, out);
			}

			return out;
		}

		public function getScaleForScaleMode(scaleMode:String):Number
		{
			if (touchSheet == null || touchSheet.movementBounds == null || (scaleMode != ScaleMode.SHOW_ALL && scaleMode != ScaleMode.NO_BORDER))
			{
				return NaN;
			}
			var touchSheetAspect:Number = touchSheet.movementBounds.width / touchSheet.movementBounds.height;
			var containerAspect:Number = actualWidth / actualHeight;
			if (scaleMode == ScaleMode.SHOW_ALL)
			{
				return touchSheetAspect > containerAspect ? actualWidth / touchSheet.movementBounds.width : actualHeight / touchSheet.movementBounds.height;
			}
			else
			{
				return touchSheetAspect > containerAspect ? actualHeight / touchSheet.movementBounds.height : actualWidth / touchSheet.movementBounds.width;
			}
		}

		protected function createTouchSheet(content:DisplayObject):void
		{
			touchSheet = new TouchSheetExtended(content);
			touchSheet.rotationEnabled = false;
			touchSheet.zoomingEnabled = _zoomingEnabled;
			touchSheet.isEnabled = _isEnabled;
			touchSheet.inertia = _inertia;
			touchSheet.touchElasticity = _touchElasticity;
			touchSheet.nonTouchElasticity = _nonTouchElasticity;
			touchSheet.requestUpdateViewport.add(updateTouchSheetViewport);
			touchSheet.viewPortChanged.add(touchSheet_viewPortChangedHandler);
			touchSheet.addEventListener(FeathersEventType.BEGIN_INTERACTION, dispatchEvent);
			touchSheet.addEventListener(FeathersEventType.END_INTERACTION, dispatchEvent);
			touchSheet.addEventListener(TouchSheetEventType.MOVE, dispatchEvent);
			touchSheet.addEventListener(TouchSheetEventType.ZOOM, dispatchEvent);
			touchSheet.addEventListener(TouchSheetEventType.ROTATE, dispatchEvent);
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			if (_doubleTapToZoom)
			{
				initDoubleTap();
			}
			super.addChildAt(touchSheet, 0);
			updateTouchSheetViewport();
			showInitialView();
			snapToBounds();
		}

		protected function disposeTouchSheet():void
		{
			touchSheet.requestUpdateViewport.removeAll();
			touchSheet.viewPortChanged.removeAll();
			touchSheet.removeChildAt(0);
			touchSheet.removeFromParent(true);
			touchSheet = null;
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			if (doubleTapToEvent != null)
			{
				doubleTapToEvent.target = null;
				doubleTapToEvent = null;
			}
		}

		protected function initDoubleTap():void
		{
			if (touchSheet == null)
			{
				return;
			}
			doubleTapToEvent = new TapToEventExtended(
					touchSheet,
					EventType.DOUBLE_TAP,
					false,
					false,
					false,
					2);
			touchSheet.addEventListener(EventType.DOUBLE_TAP, touchSheet_doubleTapListener);
		}

		override protected function draw():void
		{
			var contentInvalid:Boolean = isInvalid(INVALIDATION_FLAG_CONTENT);

			if (contentInvalid && _content != null)
			{
				createTouchSheet(_content);
			}

			super.draw();

			if (mask != null)
			{
				mask.width = actualWidth;
				mask.height = actualHeight;
			}
		}

		protected function updateTouchSheetViewport():void
		{
			if (touchSheet == null)
			{
				return;
			}
			getBounds(touchSheet, touchSheet.viewPort);
		}

		protected function updateTouchSheetLimits():void
		{
			if (touchSheet == null)
			{
				return;
			}
			if (movementBounds != null)
			{
				touchSheet.movementBounds = movementBounds;
			}
			else
			{
				touchSheet.movementBounds ||= new Rectangle;
				touchSheet.movementBounds.setTo(0, 0, touchSheet.content.width, touchSheet.content.height);
			}

			var minScale:Number = !isNaN(minimumScale) ? minimumScale : getScaleForScaleMode(minimumScaleMode);
			var maxScale:Number = !isNaN(maximumScale) ? maximumScale : getScaleForScaleMode(maximumScaleMode);

			touchSheet.minimumScale = MathUtils.isNotNaNOrInfinity(minScale) ? minScale : 0;
			touchSheet.maximumScale = MathUtils.isNotNaNOrInfinity(maxScale) ? Math.max(touchSheet.minimumScale, maxScale) : Number.MAX_VALUE;
		}

		override protected function feathersControl_addedToStageHandler(event:Event):void
		{
			super.feathersControl_addedToStageHandler(event);

			stage.starling.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, nativeStage_mouseWheelHandler);
		}

		override protected function feathersControl_removedFromStageHandler(event:Event):void
		{
			stage.starling.nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, nativeStage_mouseWheelHandler);

			super.feathersControl_removedFromStageHandler(event);
		}

		protected function enterFrameHandler():void
		{
			updateTouchSheetLimits();
		}

		protected function touchSheet_tweenUpdateHandler():void
		{
			dispatchEventWith(TouchSheetEventType.VIEW_PORT_CHANGED);
		}

		protected function touchSheet_viewPortChangedHandler():void
		{
			dispatchEventWith(TouchSheetEventType.VIEW_PORT_CHANGED);
		}

		protected function touchSheet_doubleTapListener(event:Event, touch:Touch):void
		{
			if (touchSheet.isTouching || !_zoomingEnabled)
			{
				return;
			}

			// Undo any movement between first and second tap:
			var velocity:Point = touchSheet.getVelocity(Pool.getPoint());
			touchSheet.x -= velocity.x;
			touchSheet.y -= velocity.y;
			Pool.putPoint(velocity);
			touchSheet.killVelocity();

			var pivot:Point = touch.getLocation(touchSheet, Pool.getPoint());
			if (doubleTapZoomStep == doubleTapZoomStep)
			{
				var delta:Number = touchSheet.scale * doubleTapZoomStep;
				touchSheet.scaleTo(touchSheet.scale + delta, pivot.x, pivot.y, defaultAnimationDuration, defaultAnimationTransition, touchSheet_tweenUpdateHandler);
			}
			else if (touchSheet.minimumScale == touchSheet.minimumScale && touchSheet.minimumScale != 0 &&
					touchSheet.maximumScale == touchSheet.maximumScale && touchSheet.maximumScale != Number.MAX_VALUE)
			{
				touchSheet.scaleTo(touchSheet.scale < touchSheet.maximumScale ? touchSheet.maximumScale : touchSheet.minimumScale, pivot.x, pivot.y, defaultAnimationDuration, defaultAnimationTransition, touchSheet_tweenUpdateHandler);
			}
			Pool.putPoint(pivot);
		}

		protected function nativeStage_mouseWheelHandler(event:MouseEvent):void
		{
			if (!_isEnabled || !_zoomingEnabled || !mouseWheelZoomStep || touchSheet == null || touchSheet.isTouching)
			{
				return;
			}
			var pivot:Point = Pool.getPoint(event.stageX, event.stageY);
			var hitTest:DisplayObject = stage.hitTest(pivot);

			if (hitTest == touchSheet || touchSheet.contains(hitTest))
			{
				touchSheet.globalToLocal(pivot, pivot);
				var delta:Number = touchSheet.scale * mouseWheelZoomStep * event.delta;
				touchSheet.scaleTo(touchSheet.scale + delta, pivot.x, pivot.y, defaultAnimationDuration, defaultAnimationTransition, touchSheet_tweenUpdateHandler);
			}

			Pool.putPoint(pivot);
		}

		public function disposeTweens():void
		{
			if (touchSheet != null)
			{
				touchSheet.disposeTweens();
			}
		}

		override public function dispose():void
		{
			disposeTouchSheet();

			super.dispose();
		}
	}
}

import feathers.extensions.maps.TouchSheet;
import feathers.utils.math.clamp;

import flash.geom.Point;
import flash.geom.Rectangle;

import org.osflash.signals.Signal;

import starling.display.DisplayObject;
import starling.events.Touch;
import starling.utils.Pool;
import starling.utils.RectangleUtil;

class TouchSheetExtended extends TouchSheet
{
	public var requestUpdateViewport:Signal = new Signal;
	public var viewPortChanged:Signal = new Signal;

	public var previousViewPort:Rectangle = new Rectangle;
	public var viewPort:Rectangle = new Rectangle;
	public var movementBounds:Rectangle;

	/** The movement required to return within movement bounds. */
	private var movementGravity:Point = new Point;

	public function TouchSheetExtended(content:DisplayObject)
	{
		rotationEnabled = false;

		super(content);
	}

	public function snapToBounds():void
	{
		validate();
		disposeTweens();
		updateGravity();
		x += movementGravity.x;
		y += movementGravity.y;
		scale += scaleGravity;
	}

	override protected function updateGravity():void
	{
		super.updateGravity();

		movementGravity.setTo(0, 0);
		requestUpdateViewport.dispatch();

		if (viewPort == null || movementBounds == null)
		{
			return;
		}
		if (viewPort.width > movementBounds.width)
		{
			movementGravity.x = ((viewPort.left - movementBounds.left) + (viewPort.width - movementBounds.width) / 2) * scale;
		}
		else if (viewPort.left < movementBounds.left)
		{
			movementGravity.x = (viewPort.left - movementBounds.left) * scale;
		}
		else if (viewPort.right > movementBounds.right)
		{
			movementGravity.x = (viewPort.right - movementBounds.right) * scale;
		}

		if (viewPort.height > movementBounds.height)
		{
			movementGravity.y = ((viewPort.top - movementBounds.top) + (viewPort.height - movementBounds.height) / 2) * scale;
		}
		else if (viewPort.top < movementBounds.top)
		{
			movementGravity.y = (viewPort.top - movementBounds.top) * scale;
		}
		else if (viewPort.bottom > movementBounds.bottom)
		{
			movementGravity.y = (viewPort.bottom - movementBounds.bottom) * scale;
		}
	}

	override protected function applyGravity():void
	{
		if (!_isTouching)
		{
			if (Math.abs(velocity.length) > MINIMUM_VELOCITY || Math.abs(movementGravity.length) > MINIMUM_VELOCITY || Math.abs(scaleGravity) >= 0.001)
			{
				// Pull back according to gravity:
				x += movementGravity.x * (1 - _nonTouchElasticity);
				y += movementGravity.y * (1 - _nonTouchElasticity);
				scale += scaleGravity * (1 - _nonTouchElasticity);
				// Adjust velocity for the next frame:
				velocity.x *= _inertia * (movementGravity.x ? _nonTouchElasticity : 1);
				velocity.y *= _inertia * (movementGravity.y ? _nonTouchElasticity : 1);
			}
			else
			{
				killVelocity();
				x += movementGravity.x;
				y += movementGravity.y;
				scale += scaleGravity;
			}
		}

		if (touchID_b == -1)
		{
			if (Math.abs(scaleGravity) < MINIMUM_SCALE_GRAVITY)
			{
				scale = clamp(scale, _minimumScale, _maximumScale);
			}
			else
			{
				scale += scaleGravity * (1 - _nonTouchElasticity);
			}
		}
	}

	override protected function draw():void
	{
		super.draw();

		var changed:Boolean = !RectangleUtil.compare(previousViewPort, viewPort);
		previousViewPort.copyFrom(viewPort);
		if (changed)
		{
			viewPortChanged.dispatch();
		}
	}
}