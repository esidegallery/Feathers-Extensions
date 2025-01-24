package feathers.core
{
	import starling.display.DisplayObjectContainer;

	/** Modifies functionality so that invisible IFocusDisplayObjects are not counted as valid focus objects. */
	public class ExtendedFocusManager extends DefaultFocusManager
	{
		public function ExtendedFocusManager(root:DisplayObjectContainer)
		{
			super(root);
		}

		override protected function isValidFocus(child:IFocusDisplayObject):Boolean
		{
			if (child == null || !child.visible)
			{
				return false;
			}
			var parent:DisplayObjectContainer = child.parent;
			while (parent != null)
			{
				if (!parent.visible)
				{
					return false;
				}
				parent = parent.parent;
			}
			return super.isValidFocus(child);
		}
	}
}