package feathers.controls
{
	public class TextInputExtended extends TextInput
	{
		public var showErrorCallout:Boolean = true;
		
		override protected function createErrorCallout():void
		{
			if (showErrorCallout)
			{
				super.createErrorCallout();
			}
		}
	}
}