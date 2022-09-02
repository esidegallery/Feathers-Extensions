package feathers.utils.touch
{
	import feathers.events.ExclusiveTouch;
	import feathers.utils.pixelsToInches;

	import flash.geom.Point;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Stage;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.Pool;

	/**
	 * Extends TapToEvent to add support for modifier keys and event bubbling.
	 */
	public class TapToEventExtended extends TapToEvent
	{
		public static const MAX_MOVE_DISTANCE:Number = 0.1;

		public var shiftKey:Boolean;
		public var ctrlKey:Boolean;
		public var bubbles:Boolean;
		public var checkExclusiveTouch:Boolean;
		public var limitMoveDistance:Boolean;

		protected var previousTouchX:Number;
		protected var previousTouchY:Number;
		protected var cumulativeDistance:Number;

		/**
		 * @param target 
		 * @param eventType The event type to dispatch.
		 * @param bubbles Whether the event should bubble when dispatched.
		 * @param ctrlKey  Whether the Ctrl key needs to be active before the event will be dispatched.
		 * @param shiftKey Whether the Shift key needs to be active before the event will be dispatched.
		 * @param tapCount The number of times a component must be tapped before the event will be dispatched.
		 *        If the value of <code>tapCount</code> is <code>-1</code>, the event will be dispatched for every tap.
		 */
		public function TapToEventExtended(target:DisplayObject = null, eventType:String = null, bubbles:Boolean = false, ctrlKey:Boolean = false, shiftKey:Boolean = false, tapCount:int = -1, checkExclusiveTouch:Boolean = false, limitMoveDIstance:Boolean = false)
		{
			this.target = target;
			this.eventType = eventType;
			this.bubbles = bubbles;
			this.ctrlKey = ctrlKey;
			this.shiftKey = shiftKey;
			this.tapCount = tapCount;
			this.checkExclusiveTouch = checkExclusiveTouch;
			this.limitMoveDistance = limitMoveDIstance;
		}

		override protected function target_touchHandler(event:TouchEvent):void
		{
			if (!_isEnabled)
			{
				_touchPointID = -1;
				return;
			}

			if (_touchPointID >= 0)
			{
				// a touch has begun, so we'll ignore all other touches.
				var touch:Touch = event.getTouch(_target, null, _touchPointID);
				if (!touch)
				{
					// this should not happen.
					return;
				}

				if (touch.phase == TouchPhase.ENDED)
				{
					var stage:Stage = _target.stage;
					if (stage !== null && ExclusiveTouch.forStage(stage).getClaim(touch.id) === null)
					{
						var point:Point = Pool.getPoint();
						touch.getLocation(stage, point);
						if (_target is DisplayObjectContainer)
						{
							var isInBounds:Boolean = DisplayObjectContainer(_target).contains(stage.hitTest(point));
						}
						else
						{
							isInBounds = _target === stage.hitTest(point);
						}
						Pool.putPoint(point);
						if (isInBounds &&
							(_tapCount == -1 || _tapCount == touch.tapCount) &&
							event.shiftKey == shiftKey &&
							event.ctrlKey == ctrlKey)
						{
							_target.dispatchEventWith(_eventType, bubbles);
						}
					}

					// The touch has ended, so now we can start watching for a
					// new one.
					_touchPointID = -1;
				}
				else if (limitMoveDistance && touch.phase == TouchPhase.MOVED)
				{
					var currentPos:Point = Pool.getPoint(touch.globalX, touch.globalY);
					currentPos.offset(-previousTouchX, -previousTouchY);
					cumulativeDistance += pixelsToInches(Math.abs(currentPos.length));
					Pool.putPoint(currentPos);
					if (cumulativeDistance > MAX_MOVE_DISTANCE)
					{
						// The touch has moved past the max threshold, so cancel the touch:
						_touchPointID = -1;
					}
				}
				return;
			}
			else
			{
				// We aren't tracking another touch, so let's look for a new one.
				touch = event.getTouch(DisplayObject(_target), TouchPhase.BEGAN);
				if (!touch)
				{
					// We only care about the began phase. ignore all other
					// phases when we don't have a saved touch ID.
					return;
				}
				if (_customHitTest !== null)
				{
					point = Pool.getPoint();
					touch.getLocation(DisplayObject(_target), point);
					isInBounds = _customHitTest(point);
					Pool.putPoint(point);
					if (!isInBounds)
					{
						return;
					}
				}

				// Save the touch ID so that we can track this touch's phases.
				_touchPointID = touch.id;
				cumulativeDistance = 0;
				previousTouchX = touch.globalX;
				previousTouchY = touch.globalY;
			}
		}
	}
}