package feathers.controls
{
	public class TextInputExtended extends TextInput
	{
		public var hideErrorCallout:Boolean;
		
		override protected function createErrorCallout():void
		{
			if (hideErrorCallout)
			{
				return;
			}
			super.createErrorCallout();
		}
	}
}