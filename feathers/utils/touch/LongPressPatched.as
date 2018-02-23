package feathers.utils.touch
{
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	public class LongPressPatched extends LongPress
	{
		override public function set target(value:DisplayObject):void
		{
			if(target == value)
			{
				return;
			}
			if (target)
			{
				target.removeEventListener(Event.ENTER_FRAME, target_enterFrameHandler);
			}
			super.target = value;
		}
		
		public function LongPressPatched(target:DisplayObject = null)
		{
			super(target);
		}
	}
}