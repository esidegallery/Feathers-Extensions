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

	/** <code>Event.data</code> is <code>Point</code> containing the amount moved since the previous move (or since interaction started). */
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

		protected var _elasticity:Number = 0.85;
		public function get elasticity():Number
		{
			return _elasticity;
		}
		public function set elasticity(value:Number):void
		{
			_elasticity = clamp(value, 0, 1);
		}

		/** Distance dragged (in inches) in an interaction before counted as a manipulation. */
		public var minimumDragDistance:Number = 0.2;

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

		/**
		 * If <code>isTouching = true</code>, and this flag isn't set by the time
		 * <code>enterFrameHandler</code> is triggered, then a stationary touch needs to be committed.
		 */
		protected var touchHandled:Boolean;
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

		/** Net movement in the current/last interaction (in the touchSheet's parent's space). */
		protected var _dragMovement:Point;

		/** Net movement in the current/last interaction (in the touchSheet's parent's space). */
		public function getDragMovement(out:Point = null):Point
		{
			out ||= new Point;
			if (_dragMovement != null)
			{
				out.copyFrom(_dragMovement);
			}
			else
			{
				out.setTo(0, 0);
			}
			return out;
		}

		public function TouchSheet(content:DisplayObject)
		{
			addChild(content);
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			addEventListener(TouchEvent.TOUCH, touchHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
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
				var touchMovement:Point = Pool.getPoint(touchCoords_a.x, touchCoords_a.y);
				// Movement from touch start:
				touchMovement.subtractToOutput(startTouchCoords, touchMovement);
			}
			else // Multi-touch gesture:
			{
				// Any multi-touch gesture counts as a manipulation:
				_wasManipulated = true;
				var touchACoords:Point = Pool.getPoint(touchCoords_a.x, touchCoords_a.y);
				var touchBCoords:Point = Pool.getPoint(touchCoords_b.x, touchCoords_b.y);
				var currentVector:Point = touchACoords.subtractToOutput(touchBCoords, Pool.getPoint());

				if (zoomingEnabled)
				{
					var deltaScale:Number = currentVector.length / startTouchVector.length;
					scale = startScale * deltaScale;
					var wasZoomed:Boolean = scale != previousScale;
				}
				if (rotationEnabled)
				{
					var startAngle:Number = Math.atan2(startTouchVector.y, startTouchVector.x);
					var currentAngle:Number = Math.atan2(currentVector.y, currentVector.x);
					var deltaAngle:Number = currentAngle - startAngle;
					rotation = startRotation + deltaAngle;
					var wasRotated:Boolean = rotation != previousRotation;
				}
				if (movementEnabled)
				{
					// Midpoint between current touches:
					touchMovement = Point.interpolateToOutput(touchACoords, touchBCoords, 0.5, Pool.getPoint());
					// Movement from start midpoint:
					touchMovement.subtractToOutput(startTouchCoords, touchMovement);
				}

				Pool.putPoint(touchACoords);
				Pool.putPoint(touchBCoords);
				Pool.putPoint(currentVector);
			}

			// Store the drag movement:
			_dragMovement.copyFrom(touchMovement);
			if (!_wasManipulated)
			{
				// Test drag movement passes threshold for manipulation:
				_wasManipulated = Math.abs(pixelsToInches(_dragMovement.x)) > minimumDragDistance ||
					Math.abs(pixelsToInches(_dragMovement.y)) > minimumDragDistance;
			}

			if (touchMovement != null && _wasManipulated)
			{
				// New touch sheet coords (global):
				startCoords.addToOutput(touchMovement, touchMovement);
				// New touch sheet coords (local):
				parent.globalToLocal(touchMovement, touchMovement);
				// Apply new coords:
				x = touchMovement.x;
				y = touchMovement.y;
				Pool.putPoint(touchMovement);
				var wasMoved:Boolean = previousCoords.x != x || previousCoords.y != y;
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
			saveVelocity();
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

			killVelocity();

			if (!_isTouching)
			{
				_dragMovement ||= Pool.getPoint();
				_dragMovement.setTo(0, 0);
				_wasManipulated = false;
				_isTouching = true;
				dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
			}
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
					scale += scaleGravity * (1 - _elasticity);
				}
			}
		}

		protected function enterFrameHandler():void
		{
			if (!_isTouching)
			{
				x += velocity.x;
				y += velocity.y;
				updateGravity();
				applyGravity();
			}
			else if (!touchHandled)
			{
				commitTouch();
			}
			touchHandled = false; // Ready for next frame.
		}

		protected function touchHandler(event:TouchEvent):void
		{
			if (!_isEnabled)
			{
				return;
			}

			touchHandled = true;
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

			commitTouch();
			updateGravity();
			applyGravity();
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
			Pool.putPoint(_dragMovement);
			_dragMovement = null;

			super.dispose();
		}
	}
}