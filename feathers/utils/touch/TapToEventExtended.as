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
		}

		override protected function target_touchHandler(event:TouchEvent):void
		{
			if(!this._isEnabled)
			{
				this._touchPointID = -1;
				return;
			}

			if(this._touchPointID >= 0)
			{
				//a touch has begun, so we'll ignore all other touches.
				var touch:Touch = event.getTouch(this._target, null, this._touchPointID);
				if(!touch)
				{
					//this should not happen.
					return;
				}

				if(touch.phase == TouchPhase.ENDED)
				{
					var stage:Stage = this._target.stage;
					if(stage !== null)
					{
						var point:Point = Pool.getPoint();
						touch.getLocation(stage, point);
						if(this._target is DisplayObjectContainer)
						{
							var isInBounds:Boolean = DisplayObjectContainer(this._target).contains(stage.hitTest(point));
						}
						else
						{
							isInBounds = this._target === stage.hitTest(point);
						}
						Pool.putPoint(point);
						if(isInBounds &&
							(this._tapCount == -1 || this._tapCount == touch.tapCount) &&
							event.shiftKey == shiftKey &&
							event.ctrlKey == ctrlKey)
						{
							this._target.dispatchEventWith(this._eventType, bubbles);
						}
					}

					//the touch has ended, so now we can start watching for a
					//new one.
					this._touchPointID = -1;
				}
				return;
			}
			else
			{
				//we aren't tracking another touch, so let's look for a new one.
				touch = event.getTouch(DisplayObject(this._target), TouchPhase.BEGAN);
				if(!touch)
				{
					//we only care about the began phase. ignore all other
					//phases when we don't have a saved touch ID.
					return;
				}
				if(this._customHitTest !== null)
				{
					point = Pool.getPoint();
					touch.getLocation(DisplayObject(this._target), point);
					isInBounds = this._customHitTest(point);
					Pool.putPoint(point);
					if(!isInBounds)
					{
						return;
					}
				}

				//save the touch ID so that we can track this touch's phases.
				this._touchPointID = touch.id;
			}
		}
	}
}