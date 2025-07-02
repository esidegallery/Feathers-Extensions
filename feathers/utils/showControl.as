package feathers.utils
{
	import feathers.core.IFeathersControl;
	import feathers.layout.ILayoutDisplayObject;

	import starling.display.DisplayObject;

	public function showControl(control:DisplayObject, show:Boolean = true):void
	{
		if (control == null)
		{
			return;
		}
		control.visible = show;
		if (control is ILayoutDisplayObject)
		{
			(control as ILayoutDisplayObject).includeInLayout = show;
		}
		if (control is IFeathersControl)
		{
			(control as IFeathersControl).isEnabled = show;
		}
	}
}