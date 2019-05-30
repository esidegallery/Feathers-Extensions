package feathers.motion
{
	import starling.display.DisplayObject;

	public function emptyTransition(oldScreen:DisplayObject, newScreen:DisplayObject, completeCallback:Function):void
	{
		completeCallback();
	}
}