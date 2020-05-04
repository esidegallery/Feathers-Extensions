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
	
	/** When dispatching the <code>LONG_PRESS</code> event, <code>LongPressExtended</code> sets <code>Event.data</code> to the touch ID (<code>int</code>). */ 
	public class LongPressExtended extends LongPress
	{
		public var touchBeganEventType:String;
		public var touchEndedEventType:String;
		public var bubbleEvents:Boolean;
		
		public function LongPressExtended(target:DisplayObject=null)
		{
			super(target);
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
				
				if(touch.phase == TouchPhase.MOVED)
				{
					this._touchLastGlobalPosition.x = touch.globalX;
					this._touchLastGlobalPosition.y = touch.globalY;
				}
				else if(touch.phase == TouchPhase.ENDED)
				{
					this._target.removeEventListener(Event.ENTER_FRAME, target_enterFrameHandler);
					
					//re-enable the other events
					if(this._tapToTrigger)
					{
						this._tapToTrigger.isEnabled = true;
					}
					if(this._tapToSelect)
					{
						this._tapToSelect.isEnabled = true;
					}
					
					if (this.touchEndedEventType)
					{
						this._target.dispatchEventWith(this.touchEndedEventType, this.bubbleEvents, this._touchPointID);
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
					var point:Point = Pool.getPoint();
					touch.getLocation(DisplayObject(this._target), point);
					var isInBounds:Boolean = this._customHitTest(point);
					Pool.putPoint(point);
					if(!isInBounds)
					{
						return;
					}
				}
				
				//save the touch ID so that we can track this touch's phases.
				this._touchPointID = touch.id;
				
				if (this.touchBeganEventType)
				{
					this._target.dispatchEventWith(this.touchBeganEventType, this.bubbleEvents, this._touchPointID);
				}
				
				//save the position so that we can do a final hit test
				this._touchLastGlobalPosition.x = touch.globalX;
				this._touchLastGlobalPosition.y = touch.globalY;
				
				this._touchBeginTime = getTimer();
				this._target.addEventListener(Event.ENTER_FRAME, target_enterFrameHandler);
			}
		}
		
		override protected function target_enterFrameHandler(event:Event):void
		{
			var accumulatedTime:Number = (getTimer() - this._touchBeginTime) / 1000;
			if(accumulatedTime >= this._longPressDuration)
			{
				this._target.removeEventListener(Event.ENTER_FRAME, target_enterFrameHandler);
				
				var stage:Stage = this._target.stage;
				if(this._target is DisplayObjectContainer)
				{
					var isInBounds:Boolean = DisplayObjectContainer(this._target).contains(stage.hitTest(this._touchLastGlobalPosition));
				}
				else
				{
					isInBounds = this._target === stage.hitTest(this._touchLastGlobalPosition);
				}
				if(isInBounds)
				{
					//disable the other events
					if(this._tapToTrigger)
					{
						this._tapToTrigger.isEnabled = false;
					}
					if(this._tapToSelect)
					{
						this._tapToSelect.isEnabled = false;
					}
					
					this._target.dispatchEventWith(FeathersEventType.LONG_PRESS, this.bubbleEvents, this._touchPointID);
				}
			}
		}
	}
}