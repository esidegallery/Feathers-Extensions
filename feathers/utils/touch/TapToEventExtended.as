package feathers.utils.touch
{
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
		public var shiftKey:Boolean;
		public var ctrlKey:Boolean;
		public var bubbles:Boolean;

		/**
		 * @param target 
		 * @param eventType The event type to dispatch.
		 * @param bubbles Whether the event should bubble when dispatched.
		 * @param ctrlKey  Whether the Ctrl key needs to be active before the event will be dispatched.
		 * @param shiftKey Whether the Shift key needs to be active before the event will be dispatched.
		 * @param tapCount The number of times a component must be tapped before the event will be dispatched.
		 *        If the value of <code>tapCount</code> is <code>-1</code>, the event will be dispatched for every tap.
		 */
		public function TapToEventExtended(target:DisplayObject = null, eventType:String = null, bubbles:Boolean = false, ctrlKey:Boolean = false, shiftKey:Boolean = false, tapCount:int = -1)
		{
			this.target = target;
			this.eventType = eventType;
			this.bubbles = bubbles;
			this.ctrlKey = ctrlKey;
			this.shiftKey = shiftKey;
			this.tapCount = tapCount;
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
					if (stage !== null)
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

					// the touch has ended, so now we can start watching for a
					// new one.
					_touchPointID = -1;
				}
				return;
			}
			else
			{
				// we aren't tracking another touch, so let's look for a new one.
				touch = event.getTouch(DisplayObject(_target), TouchPhase.BEGAN);
				if (!touch)
				{
					// we only care about the began phase. ignore all other
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

				// save the touch ID so that we can track this touch's phases.
				_touchPointID = touch.id;
			}
		}
	}
}