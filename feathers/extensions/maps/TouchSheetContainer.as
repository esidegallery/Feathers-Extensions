package feathers.extensions.maps
{
	import com.esidegallery.events.EventType;
	import com.esidegallery.utils.IHasUID;
	import com.esidegallery.utils.MathUtils;
	import com.esidegallery.utils.UIDUtils;

	import feathers.core.FeathersControl;
	import feathers.events.FeathersEventType;
	import feathers.utils.math.clamp;
	import feathers.utils.touch.TapToEventExtended;

	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.animation.Transitions;
	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.utils.MatrixUtil;
	import starling.utils.Pool;
	import starling.utils.RectangleUtil;
	import starling.utils.ScaleMode;

	public class TouchSheetContainer extends FeathersControl implements IHasUID
	{
		protected static const INVALIDATION_FLAG_CONTENT:String = "content";

		private var _uid:String;
		public function get uid():String
		{
			return _uid ||= UIDUtils.generateUID(this);
		}
		public function set uid(value:String):void
		{
			_uid = value;
		}

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
			if (doubleTapToEvent != null)
			{
				doubleTapToEvent.isEnabled = _isEnabled;
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

		/** If not NaN, the smaller of this and <code>minimumScaleMode</code> will be applied. */
		public var minimumScale:Number = NaN;

		/**
		 * If set, the content can be zoomed out to the equivalent of this <code>ScaleMode</code>.<br/>
		 * If <code>minimumScale</code> is not NaN, the smaller of the two will be applied.
		 */
		public var minimumScaleMode:String = ScaleMode.SHOW_ALL;

		/** If not NaN, the larger of this and <code>maximumScaleMode</code> will be applied. */
		public var maximumScale:Number = NaN;

		/**
		 * If set, the content can be zoomed in to the equivalent of this <code>ScaleMode</code>.<br/>
		 * If <code>maximumScale</code> is not NaN, the larger of the two will be applied.
		 */
		public var maximumScaleMode:String;

		/** Padding to add to the touchsheet's content, at view scale. */
		public var paddingH:Number;

		/** Padding to add to the touchsheet's content, at view scale. */
		public var paddingV:Number;

		public function get currentScale():Number
		{
			return touchSheet != null ? touchSheet.scale : NaN;
		}

		public var movementBounds:Rectangle;

		private var _inertia:Number = TouchSheet.DEFAULT_INERTIA;
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

		private var _elasticity:Number = TouchSheet.DEFAULT_ELASTICITY;
		public function get elasticity():Number
		{
			return _elasticity;
		}
		public function set elasticity(value:Number):void
		{
			_elasticity = value;
			if (touchSheet != null)
			{
				touchSheet.elasticity = _elasticity;
			}
		}

		private var _minimumDragDistance:Number = TouchSheet.DEFAULT_MINIMUM_DRAG_DISTANCE;

		/** Distance dragged (in inches) in an interaction before counted as a manipulation. */
		public function get minimumDragDistance():Number
		{
			return _minimumDragDistance;
		}
		public function set minimumDragDistance(value:Number):void
		{
			_minimumDragDistance = value;
			if (touchSheet != null)
			{
				touchSheet.minimumDragDistance = _minimumDragDistance;
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

			if (isNaN(duration))
			{
				duration = defaultAnimationDuration;
			}
			if (transition == null)
			{
				transition = defaultAnimationTransition;
			}

			if (initialViewRectangle != null)
			{
				tweenToViewRectangle(initialViewRectangle, duration, transition);
				return;
			}
			if (initialScaleMode == ScaleMode.SHOW_ALL)
			{
				var viewport:Rectangle = getViewPort(Pool.getRectangle());
				// We fit the viewport to the opposite scale mode to get the right effect:
				RectangleUtil.fit(viewport, movementBounds, ScaleMode.NO_BORDER, false, viewport);
				tweenToViewRectangle(viewport, duration, transition);
				Pool.putRectangle(viewport);
				return;
			}
			if (initialScaleMode == ScaleMode.NO_BORDER)
			{
				viewport = getViewPort(Pool.getRectangle());
				RectangleUtil.fit(viewport, movementBounds, ScaleMode.SHOW_ALL, false, viewport);
				tweenToViewRectangle(viewport, duration, transition);
				Pool.putRectangle(viewport);
				return;
			}
			if (!isNaN(initialScale))
			{
				scaleTo(initialScale, NaN, NaN, duration, transition);
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
			if (transition == null)
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

				var paddedWidth:Number = actualWidth - (paddingH || 0) * 2;
				var paddedHeight:Number = actualHeight - (paddingV || 0) * 2;

				if (paddedWidth > finalMovementBounds.width) // Zoomed out beyond movement bounds:
				{
					minX = (finalMovementBounds.left + finalPivot.x) + (actualWidth - finalMovementBounds.width) / 2;
					maxX = minX;
				}
				else // Zoomed within movement bounds:
				{
					minX = actualWidth - paddingH - (finalMovementBounds.right - finalPivot.x);
					maxX = finalPivot.x - finalMovementBounds.left + paddingH;
				}

				if (paddedHeight > finalMovementBounds.height) // Zoomed out beyond movement bounds:
				{
					minY = (finalMovementBounds.top + finalPivot.y) + (actualHeight - finalMovementBounds.height) / 2;
					maxY = minY;
				}
				else // Zoomed within movement bounds:
				{
					minY = actualHeight - paddingV - (finalMovementBounds.bottom - finalPivot.y);
					maxY = finalPivot.y - finalMovementBounds.top + paddingV;
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

		public function killVelocity():void
		{
			if (touchSheet == null)
			{
				return;
			}

			touchSheet.killVelocity();
		}

		public function getViewPort(out:Rectangle = null):Rectangle
		{
			updateTouchSheetViewport();

			out ||= new Rectangle;
			if (touchSheet == null)
			{
				out.setEmpty();
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

		public function getDragMovement(out:Point = null):Point
		{
			out ||= new Point;
			if (touchSheet != null)
			{
				touchSheet.getDragMovement(out);
			}
			else
			{
				out.setTo(0, 0);
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
				out.setEmpty();
			}
			else
			{
				child.getBounds(touchSheet, out);
			}

			return out;
		}

		protected function createTouchSheet(content:DisplayObject):void
		{
			touchSheet = new TouchSheetExtended(content);
			touchSheet.rotationEnabled = false;
			touchSheet.movementEnabled = _movementEnabled;
			touchSheet.zoomingEnabled = _zoomingEnabled;
			touchSheet.isEnabled = _isEnabled;
			touchSheet.inertia = _inertia;
			touchSheet.elasticity = _elasticity;
			touchSheet.minimumDragDistance = _minimumDragDistance;
			touchSheet.requestUpdateViewport.add(updateTouchSheetViewport);
			touchSheet.viewPortChanged.add(touchSheet_viewPortChangedHandler);
			touchSheet.addEventListener(FeathersEventType.BEGIN_INTERACTION, touchSheet_beginInteractionHandler);
			touchSheet.addEventListener(FeathersEventType.END_INTERACTION, touchSheet_endInteractionHandler);
			touchSheet.addEventListener(TouchSheetEventType.MOVE, touchSheet_moveHandler);
			touchSheet.addEventListener(TouchSheetEventType.ZOOM, touchSheet_zoomHandler);
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			if (_doubleTapToZoom)
			{
				initDoubleTap();
			}
			super.addChildAt(touchSheet, 0);
		}

		protected function disposeTouchSheet():void
		{
			if (touchSheet != null)
			{
				touchSheet.requestUpdateViewport.removeAll();
				touchSheet.viewPortChanged.removeAll();
				touchSheet.removeChildAt(0);
				touchSheet.removeFromParent(true);
				touchSheet = null;
			}
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
			doubleTapToEvent.isEnabled = _isEnabled;
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

			if (contentInvalid)
			{
				showInitialView();
				snapToBounds();
			}

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

			touchSheet.viewPort ||= new Rectangle;

			var padH:Number = paddingH || 0;
			var padV:Number = paddingV || 0;
			var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
			var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
			var matrix:Matrix = Pool.getMatrix();
			var point:Point = Pool.getPoint();

			getTransformationMatrix(touchSheet, matrix);

			MatrixUtil.transformCoords(matrix, padH, padV, point);
			minX = minX < point.x ? minX : point.x;
			maxX = maxX > point.x ? maxX : point.x;
			minY = minY < point.y ? minY : point.y;
			maxY = maxY > point.y ? maxY : point.y;

			MatrixUtil.transformCoords(matrix, padH, actualHeight - padV, point);
			minX = minX < point.x ? minX : point.x;
			maxX = maxX > point.x ? maxX : point.x;
			minY = minY < point.y ? minY : point.y;
			maxY = maxY > point.y ? maxY : point.y;

			MatrixUtil.transformCoords(matrix, actualWidth - padH, padV, point);
			minX = minX < point.x ? minX : point.x;
			maxX = maxX > point.x ? maxX : point.x;
			minY = minY < point.y ? minY : point.y;
			maxY = maxY > point.y ? maxY : point.y;

			MatrixUtil.transformCoords(matrix, actualWidth - padH, actualHeight - padV, point);
			minX = minX < point.x ? minX : point.x;
			maxX = maxX > point.x ? maxX : point.x;
			minY = minY < point.y ? minY : point.y;
			maxY = maxY > point.y ? maxY : point.y;

			Pool.putMatrix(matrix);
			Pool.putPoint(point);

			touchSheet.viewPort.x = minX;
			touchSheet.viewPort.y = minY;
			touchSheet.viewPort.width = maxX - minX;
			touchSheet.viewPort.height = maxY - minY;
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

			var paddedWidth:Number = actualWidth - (paddingH || 0) * 2;
			var paddedHeight:Number = actualHeight - (paddingV || 0) * 2;

			var scaleModeScale:Number = MapUtils.getScaleForScaleMode(minimumScaleMode, touchSheet.movementBounds.width, touchSheet.movementBounds.height, paddedWidth, paddedHeight);
			if (MathUtils.isNotNaNOrInfinity(minimumScale))
			{
				touchSheet.minimumScale = MathUtils.isNotNaNOrInfinity(scaleModeScale) ? Math.min(minimumScale, scaleModeScale) : minimumScale;
			}
			else
			{
				touchSheet.minimumScale = MathUtils.isNotNaNOrInfinity(scaleModeScale) ? scaleModeScale : 0;
			}

			scaleModeScale = MapUtils.getScaleForScaleMode(maximumScaleMode, touchSheet.movementBounds.width, touchSheet.movementBounds.height, paddedWidth, paddedHeight);
			if (MathUtils.isNotNaNOrInfinity(maximumScale))
			{
				touchSheet.maximumScale = MathUtils.isNotNaNOrInfinity(scaleModeScale) ? Math.max(maximumScale, scaleModeScale) : maximumScale;
			}
			else
			{
				touchSheet.maximumScale = MathUtils.isNotNaNOrInfinity(scaleModeScale) ? scaleModeScale : Number.MAX_VALUE;
			}
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

		protected function touchSheet_beginInteractionHandler(event:Event):void
		{
			dispatchEvent(event);
		}

		protected function touchSheet_endInteractionHandler(event:Event):void
		{
			dispatchEvent(event);
		}

		protected function touchSheet_moveHandler(event:Event):void
		{
			dispatchEvent(event);
		}

		protected function touchSheet_zoomHandler(event:Event):void
		{
			dispatchEvent(event);
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
				touchSheet.scaleTo(touchSheet.scale + delta, pivot.x, pivot.y, defaultAnimationDuration, Transitions.EASE_OUT, touchSheet_tweenUpdateHandler);
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
import starling.events.Event;
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
		if (_isTouching && _elasticity == 0)
		{
			x += movementGravity.x;
			y += movementGravity.y;
			scale += scaleGravity;
		}

		if (!_isTouching)
		{
			if (Math.abs(velocity.length) > MINIMUM_VELOCITY || Math.abs(movementGravity.length) > MINIMUM_VELOCITY || Math.abs(scaleGravity) >= 0.001)
			{
				// Pull back according to gravity:
				x += movementGravity.x * (1 - _elasticity);
				y += movementGravity.y * (1 - _elasticity);
				scale += scaleGravity * (1 - _elasticity);
				// Adjust velocity for the next frame:
				velocity.x *= _inertia * (movementGravity.x ? _elasticity : 1);
				velocity.y *= _inertia * (movementGravity.y ? _elasticity : 1);
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
				scale += scaleGravity * (1 - _elasticity);
			}
		}
	}

	override protected function draw():void
	{
		super.draw();

		// Note: tween updates happen after draw(), so perhaps a smarter way of detecting & dispatching viewport changes is necessary.
		var changed:Boolean = !RectangleUtil.compare(previousViewPort, viewPort);
		previousViewPort.copyFrom(viewPort);
		if (changed)
		{
			viewPortChanged.dispatch();
		}
	}

	override protected function enterFrameHandler():void
	{
		invalidate(INVALIDATION_FLAG_DATA);

		super.enterFrameHandler();
	}
}