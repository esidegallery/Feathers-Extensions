package feathers.utils.touch
{
	import feathers.events.FeathersEventType;

	import flash.geom.Point;
	import flash.utils.getTimer;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Stage;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.Pool;

	/** 
	 * <ul>
	 * <li><code>LONG_PRESS</code><code>Event.data</code> is set to the touch ID (<code>int</code>).</li>
	 * <li>New <code>bubbleEvents</code> property.
	 * <li>New <code>touchBeganEventType</code> and <code>touchEndedEventType</code> properties.
	 * <li>Fixes not using cutomHitTest when <code>longPressDuration</code> has elapsed.</li>
	 * </ul>
	 */
	public class LongPressExtended extends LongPress
	{
		public var touchBeganEventType:String;
		public var touchEndedEventType:String;
		public var bubbleEvents:Boolean;

		public function LongPressExtended(target:DisplayObject = null)
		{
			super(target);
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

				if (touch.phase == TouchPhase.MOVED)
				{
					_touchLastGlobalPosition.x = touch.globalX;
					_touchLastGlobalPosition.y = touch.globalY;
				}
				else if (touch.phase == TouchPhase.ENDED)
				{
					_target.removeEventListener(Event.ENTER_FRAME, target_enterFrameHandler);

					// re-enable the other events
					if (_tapToTrigger)
					{
						_tapToTrigger.isEnabled = true;
					}
					if (_tapToSelect)
					{
						_tapToSelect.isEnabled = true;
					}

					if (touchEndedEventType)
					{
						_target.dispatchEventWith(touchEndedEventType, bubbleEvents, _touchPointID);
					}

					// the touch has ended, so now we can start watching for a new one.
					_touchPointID = -1;
				}
				return;
			}
			else
			{
				// we aren't tracking another touch, so let's look for a new one.
				touch = event.getTouch(_target, TouchPhase.BEGAN);
				if (!touch)
				{
					// we only care about the began phase. ignore all other
					// phases when we don't have a saved touch ID.
					return;
				}
				if (_customHitTest !== null)
				{
					var point:Point = Pool.getPoint();
					touch.getLocation(_target, point);
					var isInBounds:Boolean = _customHitTest(point);
					Pool.putPoint(point);
					if (!isInBounds)
					{
						return;
					}
				}

				// save the touch ID so that we can track this touch's phases.
				_touchPointID = touch.id;

				if (touchBeganEventType)
				{
					_target.dispatchEventWith(touchBeganEventType, bubbleEvents, _touchPointID);
				}

				// save the position so that we can do a final hit test
				_touchLastGlobalPosition.x = touch.globalX;
				_touchLastGlobalPosition.y = touch.globalY;

				_touchBeginTime = getTimer();
				_target.addEventListener(Event.ENTER_FRAME, target_enterFrameHandler);
			}
		}

		override protected function target_enterFrameHandler(event:Event):void
		{
			var accumulatedTime:Number = (getTimer() - _touchBeginTime) / 1000;
			if (accumulatedTime >= _longPressDuration)
			{
				_target.removeEventListener(Event.ENTER_FRAME, target_enterFrameHandler);

				var stage:Stage = _target.stage;
				if (_customHitTest !== null)
				{
					var point:Point = _target.globalToLocal(_touchLastGlobalPosition, Pool.getPoint());
					var isInBounds:Boolean = _customHitTest(point);
					Pool.putPoint(point);
				}
				else if (_target is DisplayObjectContainer)
				{
					isInBounds = DisplayObjectContainer(_target).contains(stage.hitTest(_touchLastGlobalPosition));
				}
				else
				{
					isInBounds = _target === stage.hitTest(_touchLastGlobalPosition);
				}
				if (isInBounds)
				{
					// disable the other events
					if (_tapToTrigger)
					{
						_tapToTrigger.isEnabled = false;
					}
					if (_tapToSelect)
					{
						_tapToSelect.isEnabled = false;
					}

					_target.dispatchEventWith(FeathersEventType.LONG_PRESS, bubbleEvents, _touchPointID);
				}
			}
		}
	}
}