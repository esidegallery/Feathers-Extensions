package feathers.controls
{
	public class NumericStepperExtended extends NumericStepper
	{
		private var _textIsSelectable:Boolean = true;
		public function get textIsSelectable():Boolean
		{
			return _textIsSelectable;
		}
		public function set textIsSelectable(value:Boolean):void
		{
			if (_textIsSelectable != value)
			{
				_textIsSelectable = value;
				invalidate(INVALIDATION_FLAG_TEXT_EDITOR);
			}
		}

		private var _textIsEditable:Boolean = true;
		public function get textIsEditable():Boolean
		{
			return _textIsEditable;
		}
		public function set textIsEditable(value:Boolean):void
		{
			if (_textIsEditable != value)
			{
				_textIsEditable = value;
				invalidate(INVALIDATION_FLAG_TEXT_EDITOR);
			}
		}
		
		override protected function draw():void
		{
			if (isInvalid(INVALIDATION_FLAG_TEXT_EDITOR))
			{
				textInputFactory = function():TextInput
				{
					var textInput:TextInput = new TextInput;
					textInput.isEditable = _textIsEditable;
					textInput.isSelectable = _textIsSelectable;
					return textInput;
				};
			}
			super.draw();
		}
	}
}