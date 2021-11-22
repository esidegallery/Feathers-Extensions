package feathers.utils.display
{
	import feathers.core.PopUpManager;

	import starling.display.DisplayObject;

	/**
	 * Returns the display index of the popup or it's first popup ancestor.
	 * @param target 
	 * @return -1 if target or any of its ancestors are not a popup
	 */
	public function getPopUpIndex(target:DisplayObject):int
	{
		while (target != null && !PopUpManager.isPopUp(target))
		{
			target = target.parent;
		}
		return PopUpManager.root.getChildIndex(target);
	}
}