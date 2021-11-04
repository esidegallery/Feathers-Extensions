package feathers.utils.display
{
	import feathers.core.PopUpManager;

	import starling.display.DisplayObject;

	/**
	 * Returns the display index of the popup.
	 * @param target 
	 * @return -1 if not a popup
	 */
	public function getPopUpIndex(target:DisplayObject):int
	{
		if (!PopUpManager.isPopUp(target))
		{
			return -1;
		}
		return PopUpManager.root.getChildIndex(target);
	}
}