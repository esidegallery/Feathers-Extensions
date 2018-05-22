package feathers.controls
{
	public class TextInputExtended extends TextInput
	{
		public var showErrorCallout:Boolean = true;
		
		public function TextInputExtended()
		{
			super();
		}
		
		override protected function createErrorCallout():void
		{
			if (showErrorCallout)
			{
				super.createErrorCallout();
			}
		}
	}
}