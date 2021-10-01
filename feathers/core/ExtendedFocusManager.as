package feathers.core
{
	import starling.display.DisplayObjectContainer;

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

		override public function set focus(value:IFocusDisplayObject):void
		{
			super.focus = value;
			trace("FM", focus);
		}
	}
}