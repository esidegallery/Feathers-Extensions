package feathers.controls
{
	import feathers.events.FeathersEventType;

	import flash.ui.Keyboard;

	import starling.events.Event;
	import starling.events.KeyboardEvent;

	/** Adds some extra features and fixes an occasional edge-case runtime error. */
	public class PickerListPatched extends PickerList
	{
		/**
		 * If true, the list's item renderer label field property will be set
		 * to the PickerList's labelField property.
		 */
		private var _autoSetListRendererLabelField:Boolean = true;
		public function get autoSetListRendererLabelField():Boolean
		{
			return _autoSetListRendererLabelField;
		}
		public function set autoSetListRendererLabelField(value:Boolean):void
		{
			if (_autoSetListRendererLabelField == value)
			{
				return;
			}
			_autoSetListRendererLabelField = value;
			invalidate(INVALIDATION_FLAG_DATA);
		}

		override protected function draw():void
		{
			var dataInvalid:Boolean = isInvalid(INVALIDATION_FLAG_DATA);

			if (dataInvalid)
			{
				if (_autoSetListRendererLabelField)
				{
					listProperties.@itemRendererProperties.labelField = _labelField;
				}
			}

			super.draw();
		}

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