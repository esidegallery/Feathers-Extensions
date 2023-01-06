package feathers.controls
{
	import feathers.events.FeathersEventType;

	import flash.ui.Keyboard;

	import starling.events.Event;
	import starling.events.KeyboardEvent;

	/** Fixes an occasional edge-case runtime error. */
	public class PickerListPatched extends PickerList
	{
		override protected function list_removedFromStageHandler(event:Event):void
		{
			if (list == null || list.stage == null)
			{
				return;
			}
			list.stage.removeEventListener(KeyboardEvent.KEY_UP, stage_keyUpHandler);
			list.removeEventListener(FeathersEventType.FOCUS_OUT, list_focusOutHandler);
		}

		override protected function stage_keyUpHandler(event:KeyboardEvent):void
		{
			if (_popUpContentManager != null && !_popUpContentManager.isOpen)
			{
				return;
			}
			if (event.keyCode == Keyboard.ENTER)
			{
				closeList();
			}
		}
	}
}