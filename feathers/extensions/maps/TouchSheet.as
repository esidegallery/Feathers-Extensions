package feathers.extensions.maps
{
	import com.esidegallery.utils.UIDUtils;
	import com.greensock.easing.ExpoScaleEase;

	import feathers.core.FeathersControl;
	import feathers.events.FeathersEventType;
	import feathers.utils.math.clamp;
	import feathers.utils.pixelsToInches;

	import flash.geom.Point;

	import starling.animation.BasicTweenTarget;
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.Pool;
	import starling.utils.execute;

	[Event(type="starling.events.Event", name="beginInteraction")]

	/** <code>Event.data</code> was whether a manipulation (i.e. drag/scale/rotation) took place. */
	[Event(type="starling.events.Event", name="endInteraction")]
	[Event(type="starling.events.Event", name="move")]
	[Event(type="starling.events.Event", name="zoom")]
	[Event(type="starling.events.Event", name="rotate")]

	public class TouchSheet extends FeathersControl
	{
		/** Slowest velocity before auto-movement is stopped. */
		public static const MINIMUM_VELOCITY:Number = 0.1;

		protected static const MINIMUM_SCALE_GRAVITY:Number = 0.001;

		/** Previous velocities are saved for an accurate measurement at the end of a touch. */
		private static const MAXIMUM_SAVED_VELOCITY_COUNT:int = 3;

		/** Distance dragged (in inches) in an interaction before counted as a manipulation. */
		private static const MIN_DRAG_DISTANCE:Number = 0.2;

		private var _uid:String;
		public function get uid():String
		{
			return _uid ||= UIDUtils.generateUID(this);
		}
		public function set uid(value:String):void
		{
			_uid = value;
		}

		public function get content():DisplayObject
		{
			return getChildAt(0);
		}

		protected var _minimumScale:Number = 0;
		public function get minimumScale():Number
		{
			return _minimumScale;
		}
		public function set minimumScale(value:Number):void
		{
			if (_minimumScale == value)
			{
				return;
			}
			_minimumScale = value;
			disposeTweens();
		}

		protected var _maximumScale:Number = Number.MAX_VALUE;
		public function get maximumScale():Number
		{
			return _maximumScale;
		}
		public function set maximumScale(value:Number):void
		{
			if (_maximumScale == value)
			{
				return;
			}
			_maximumScale = value;
			disposeTweens();
		}

		public var movementEnabled:Boolean = true;

		public var zoomingEnabled:Boolean = true;

		public var rotationEnabled:Boolean = true;

		protected var _inertia:Number = 0.88;

		/** A number between 0 and 1, where 0 stops dead and 1 keeps moving forever. */
		public function get inertia():Number
		{
			return _inertia;
		}
		public function set inertia(value:Number):void
		{
			_inertia = clamp(value, 0, 1) || 0;
		}

		protected var _touchElasticity:Number = 0.4;
		public function get touchElasticity():Number
		{
			return _touchElasticity;
		}
		public function set touchElasticity(value:Number):void
		{
			_touchElasticity = clamp(value, 0, 1);
		}

		protected var _nonTouchElasticity:Number = 0.85;
		public function get nonTouchElasticity():Number
		{
			return _nonTouchElasticity;
		}
		public function set nonTouchElasticity(value:Number):void
		{
			_nonTouchElasticity = clamp(value, 0, 1);
		}

		protected var _isTouching:Boolean;
		public function get isTouching():Boolean
		{
			return _isTouching;
		}

		protected var _wasManipulated:Boolean;

		/** Whether a manipulation took place in the last interaction. */
		public function get wasManipulated():Boolean
		{
			return _wasManipulated;
		}

		override public function set isEnabled(value:Boolean):void
		{
			super.isEnabled = value;

			if (!_isEnabled)
			{
				endTouch();
			}
		}

		protected var touchID_a:int = -1;
		protected var touchID_b:int = -1;
		protected var touchCoords_a:Point = new Point;
		protected var touchCoords_b:Point = new Point;
		protected var tweenID:int = -1;

		/** Scale of TouchSheet at start of touch interaction. */
		protected var startScale:Number;

		/** Rotation of TouchSheet at start of touch interaction. */
		protected var startRotation:Number;

		/** Global coords of TouchSheet at start of touch interaction. */
		protected var startCoords:Point = new Point;

		/** Local (to parent) coords of previous frame. */
		protected var previousCoords:Point = new Point;

		/** Global coords of Touch at start of touch interaction. */
		protected var startTouchCoords:Point = new Point;

		/** The initial orientation between touch point A and B */
		protected var startTouchVector:Point = new Point;

		protected var velocity:Point = new Point;
		public function getVelocity(out:Point = null):Point
		{
			out ||= new Point;
			out.copyFrom(velocity);
			return out;
		}

		/** A number of velocies is stored to smooth out motion at the end of a touch. */
		protected var previousVelocities:Vector.<Point> = new Vector.<Point>;

		/** The amount to add to current scale to return within <code>minimumScale</code> & <code>maximumScale</code>. */
		protected var scaleGravity:Number;

		/** Distance dragged in the last interaction. */
		protected var _dragDistance:Number;
		public function get dragDistance():Number
		{
			return _dragDistance;
		}

		public function TouchSheet(content:DisplayObject)
		{
			addChild(content);
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			addEventListener(TouchEvent.TOUCH, touchHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
		}

		override protected function draw():void
		{
			var layoutInvalid:Boolean = isInvalid(INVALIDATION_FLAG_LAYOUT);
			if (layoutInvalid)
			{
				if (_isTouching)
				{
					commitTouch();
				}
				else
				{
					commitNonTouch();
				}
				updateGravity();
				applyGravity();
			}
		}

		protected function commitTouch():void
		{
			if (!_isTouching || !movementEnabled && !zoomingEnabled && !rotationEnabled)
			{
				return;
			}

			var previousCoords:Point = Pool.getPoint(x, y);
			var previousScale:Number = scale;
			var previousRotation:Number = rotation;

			if (!zoomingEnabled && !rotationEnabled || movementEnabled && touchID_b == -1) // Single-touch - movement only:
			{
				// Current touch coords:
				var point:Point = Pool.getPoint(touchCoords_a.x, touchCoords_a.y);
				// Movement from touch start:
				point.subtractToOutput(startTouchCoords, point);
				// New touch sheet coords (global):
				startCoords.addToOutput(point, point);
				// New touch sheet coords (local):
				parent.globalToLocal(point, point);
				// Apply new coords:
				x = point.x;
				y = point.y;
				Pool.putPoint(point);
			}
			else // Multi-touch gesture:
			{
				var touchACoords:Point = Pool.getPoint(touchCoords_a.x, touchCoords_a.y);
				var touchBCoords:Point = Pool.getPoint(touchCoords_b.x, touchCoords_b.y);
				var currentVector:Point = touchACoords.subtractToOutput(touchBCoords, Pool.getPoint());

				if (zoomingEnabled)
				{
					var deltaScale:Number = currentVector.length / startTouchVector.length;
					scale = startScale * deltaScale;
				}
				if (rotationEnabled)
				{
					var startAngle:Number = Math.atan2(startTouchVector.y, startTouchVector.x);
					var currentAngle:Number = Math.atan2(currentVector.y, currentVector.x);
					var deltaAngle:Number = currentAngle - startAngle;
					rotation = startRotation + deltaAngle;
				}
				if (movementEnabled)
				{
					// Midpoint between current touches:
					var midPoint:Point = Point.interpolateToOutput(touchACoords, touchBCoords, 0.5, Pool.getPoint());
					// Movement from start midpoint:
					midPoint.subtractToOutput(startTouchCoords, midPoint);
					// New touch sheet coords (global):
					startCoords.addToOutput(midPoint, midPoint);
					// New touch sheet coords (local):
					parent.globalToLocal(midPoint, midPoint);
					// Apply new coords:
					x = midPoint.x;
					y = midPoint.y;
					Pool.putPoint(midPoint);
				}

				Pool.putPoint(touchACoords);
				Pool.putPoint(touchBCoords);
				Pool.putPoint(currentVector);
			}

			var newCoords:Point = Pool.getPoint(x, y);
			var movement:Number = Math.abs(previousCoords.subtract(newCoords).length);
			_dragDistance += movement;
			var wasMoved:Boolean = movement > 0;
			var wasZoomed:Boolean = scale != previousScale;
			var wasRotated:Boolean = rotation != previousRotation;
			if (!_wasManipulated)
			{
				_wasManipulated = wasZoomed ||
					wasRotated ||
					pixelsToInches(_dragDistance) >= MIN_DRAG_DISTANCE;
			}
			if (wasMoved)
			{
				dispatchEventWith(TouchSheetEventType.MOVE);
			}
			if (wasZoomed)
			{
				dispatchEventWith(TouchSheetEventType.ZOOM);
			}
			if (wasRotated)
			{
				dispatchEventWith(TouchSheetEventType.ROTATE);
			}

			Pool.putPoint(previousCoords);
			Pool.putPoint(newCoords);

			saveVelocity();
		}

		protected function commitNonTouch():void
		{
			// Move according to velocity:
			x += velocity.x;
			y += velocity.y;
		}

		protected function startTouch(touchA:Touch, touchB:Touch):void
		{
			if (touchA == null)
			{
				return;
			}

			disposeTweens();

			if (touchB != null) // Multi-touch:
			{
				var touchACoords:Point = Pool.getPoint(touchA.globalX, touchA.globalY);
				var touchBCoords:Point = Pool.getPoint(touchB.globalX, touchB.globalY);
				touchACoords.subtractToOutput(touchBCoords, startTouchVector);
				// Set the new start coords to the halfway point between touch a and b:
				Point.interpolateToOutput(touchACoords, touchBCoords, 0.5, startTouchCoords);
				Pool.putPoint(touchACoords);
				Pool.putPoint(touchBCoords);
			}
			else // Single touch:
			{
				startTouchCoords.setTo(touchA.globalX, touchA.globalY);
			}

			// Move the pivot point to the new start touch coords:
			var newPivot:Point = globalToLocal(startTouchCoords, Pool.getPoint());
			setPivot(newPivot.x, newPivot.y);
			Pool.putPoint(newPivot);

			startScale = scale;
			startRotation = rotation;
			startCoords.setTo(x, y);
			parent.localToGlobal(startCoords, startCoords);

			if (!_isTouching)
			{
				_dragDistance = 0;
				_wasManipulated = false;
			}

			killVelocity();

			_isTouching = true;
			dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
		}

		protected function endTouch():void
		{
			if (!_isTouching)
			{
				return;
			}

			_isTouching = false;
			touchID_a = -1;
			touchID_b = -1;

			// Calculate the final velocity based on an average of the saved velocities:
			var weight:Number = 1;
			var totalWeight:Number = 0;
			var sumX:Number = 0;
			var sumY:Number = 0;
			while (previousVelocities.length > 0)
			{
				var v:Point = previousVelocities.shift();
				sumX += v.x * weight;
				sumY += v.y * weight;
				totalWeight += weight;
				Pool.putPoint(v);
				weight *= 1.33;
			}
			previousCoords.setTo(x, y);
			velocity.setTo(sumX / totalWeight || 0, sumY / totalWeight || 0);

			if (!_wasManipulated && pixelsToInches(_dragDistance) >= MIN_DRAG_DISTANCE)
			{
				_wasManipulated = true;
			}
			dispatchEventWith(FeathersEventType.END_INTERACTION, _wasManipulated);
		}

		/**
		 * Changes the pivot point to the passed non-NaN values without
		 * changing TouchSheet's visual location.
		 */
		public function setPivot(newX:Number, newY:Number):void
		{
			if (isNaN(newX) && isNaN(newY))
			{
				return;
			}

			newX = !isNaN(newX) ? newX : pivotX;
			newY = !isNaN(newY) ? newY : pivotY;

			// Move to pivot point in parent to cancel out movement:
			var pivot:Point = Pool.getPoint(newX, newY);
			localToGlobal(pivot, pivot);
			parent.globalToLocal(pivot, pivot);
			pivotX = newX;
			pivotY = newY;
			x = pivot.x;
			y = pivot.y;

			Pool.putPoint(pivot);
		}

		public function scaleTo(toScale:Number, pivotX:Number, pivotY:Number, duration:Number = 0.75, transition:String = Transitions.EASE_IN_OUT, onUpdate:Function = null):void
		{
			setPivot(pivotX, pivotY);
			tweenTo(NaN, NaN, toScale, duration, transition, onUpdate);
		}

		public function tweenTo(toX:Number, toY:Number, toScale:Number, duration:Number = 0.75, transition:String = Transitions.EASE_IN_OUT, onUpdate:Function = null):void
		{
			endTouch();
			disposeTweens();

			duration ||= 0;
			toScale = clamp(toScale, _minimumScale, _maximumScale) || scale;

			var fromX:Number = x;
			var fromY:Number = y;
			var fromScale:Number = scale;

			if (fromX == toX && fromY == toY && fromScale == toScale) // No change.
			{
				return;
			}
			if (duration <= 0)
			{
				_finishUp();
				return;
			}

			var tweenTarget:BasicTweenTarget = new BasicTweenTarget;
			var expoScaleEase:ExpoScaleEase = new ExpoScaleEase(fromScale, toScale);
			var expoMoveEase:ExpoScaleEase = new ExpoScaleEase(toScale, toScale);
			tweenID = Starling.juggler.tween(
					tweenTarget,
					duration,
					{
						ratio: 1,
						transition: transition,
						onUpdate: _tweenUpdateHandler,
						onComplete: _tweenCompleteHandler
					});

			function _tweenUpdateHandler():void
			{
				var scaleRatio:Number = expoScaleEase.getRatio(tweenTarget.ratio);
				var moveRatio:Number = expoMoveEase.getRatio(tweenTarget.ratio);

				scale = fromScale + (toScale - fromScale) * scaleRatio;
				if (!isNaN(toX))
				{
					x = fromX + (toX - fromX) * moveRatio;
				}
				if (!isNaN(toY))
				{
					y = fromY + (toY - fromY) * moveRatio;
				}
				if (onUpdate != null)
				{
					execute(onUpdate);
				}
			}

			function _tweenCompleteHandler():void
			{
				tweenID = -1;
				_finishUp();
			}

			function _finishUp():void
			{
				if (!isNaN(toX))
				{
					x = toX;
				}
				if (!isNaN(toY))
				{
					y = toY;
				}
				scale = toScale;
			}
		}

		public function killVelocity():void
		{
			velocity.setTo(0, 0);
			while (previousVelocities.length)
			{
				Pool.putPoint(previousVelocities.pop());
			}
			previousCoords.setTo(x, y);
		}

		protected function saveVelocity():void
		{
			var currentCoords:Point = Pool.getPoint(x, y);
			currentCoords.subtractToOutput(previousCoords, velocity);

			previousVelocities.push(Pool.getPoint(velocity.x, velocity.y));
			if (previousVelocities.length > MAXIMUM_SAVED_VELOCITY_COUNT)
			{
				Pool.putPoint(previousVelocities.shift());
			}

			previousCoords.copyFrom(currentCoords);
			Pool.putPoint(currentCoords);
		}

		protected function updateGravity():void
		{
			if (scale < _minimumScale)
			{
				scaleGravity = _minimumScale - scale;
			}
			else if (scale > _maximumScale)
			{
				scaleGravity = _maximumScale - scale;
			}
			else
			{
				scaleGravity = 0;
			}
		}

		protected function applyGravity():void
		{
			if (!_isTouching)
			{
				if (Math.abs(velocity.length) > MINIMUM_VELOCITY)
				{
					velocity.x *= _inertia;
					velocity.y *= _inertia;
				}
				else
				{
					killVelocity();
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

		protected function enterFrameHandler():void
		{
			// Layout needs to happen on every frame, but preferrably on validation,
			// so we invalidate on every frame.
			invalidate(INVALIDATION_FLAG_LAYOUT);
		}

		protected function touchHandler(event:TouchEvent):void
		{
			if (!_isEnabled)
			{
				return;
			}

			var prevAID:int = touchID_a;
			var prevBID:int = touchID_b;

			if (touchID_b != -1) // Check touchB has ended:
			{
				var touchB:Touch = event.getTouch(this, null, touchID_b);
				if (touchB == null || touchB.phase == TouchPhase.ENDED)
				{
					touchID_b = -1;
					touchB = null;
				}
			}
			if (touchID_a != -1) // Check touchA hasEnded:
			{
				var touchA:Touch = event.getTouch(this, null, touchID_a);
				if (touchA == null || touchA.phase == TouchPhase.ENDED)
				{
					// Touch B becomes touch A (if existed):
					touchID_a = touchID_b;
					touchA = touchB;
					touchID_b = -1;
					touchB = null;
				}
			}

			// Check for new touches:
			if (touchB == null || touchA == null)
			{
				var touches:Vector.<Touch> = event.getTouches(this, TouchPhase.BEGAN);
				for (var i:int = 0, l:int = touches.length; i < l; i++)
				{
					var touch:Touch = touches[i];
					if (touchA == null)
					{
						touchID_a = touch.id;
						touchA = touch;
					}
					else if (touchB == null)
					{
						touchID_b = touch.id;
						touchB = touch;
					}
					if (touchA != null && touchB != null)
					{
						break;
					}
				}
			}

			if (touchA == null)
			{
				endTouch();
				return;
			}

			if (prevAID != touchID_a || prevBID != touchID_b)
			{
				startTouch(touchA, touchB);
			}

			if (touchA != null)
			{
				touchCoords_a.setTo(touchA.globalX, touchA.globalY);
			}
			if (touchB != null)
			{
				touchCoords_b.setTo(touchB.globalX, touchB.globalY);
			}

			invalidate(INVALIDATION_FLAG_LAYOUT);
		}

		protected function removedFromStageHandler(event:Event):void
		{
			endTouch();
		}

		public function disposeTweens():void
		{
			if (tweenID == -1)
			{
				return;
			}
			Starling.juggler.removeByID(tweenID);
			tweenID = -1;
		}

		override public function dispose():void
		{
			endTouch();
			disposeTweens();
			killVelocity();

			super.dispose();
		}
	}
}