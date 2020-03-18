package feathers.controls
{
	import com.esidegallery.utils.substitute;

	import feathers.controls.renderers.IListItemRenderer;
	import feathers.controls.supportClasses.ListExtendedDataViewPort;
	import feathers.events.DragDropEvent;
	import feathers.events.FeathersEventType;

	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	/**
	 * Extends list functioanlity to support Ctrl-click and Shift-click multiple selection.
	 */
	public class ListExtended extends List
	{
		private static const EVENT_CTRL_TAP:String = "listExtended_ctrlTap";
		private static const EVENT_SHIFT_TAP:String = "listExtended_shiftTap";

		public var touchWhitespaceToDeselect:Boolean = true;

		override public function set allowMultipleSelection(value:Boolean):void
		{
			if (!value)
			{
				throw new Error("ListExtended.allowMultipleSelection cannot be disabled.")
			}
		}

		private var lastSelectedIndex:int = -1;
		private var touchedSelectedIndex:int = -1;

		private var ctrlActive:Boolean;
		private var shiftActive:Boolean;

		override protected function initialize():void
		{
			_allowMultipleSelection = true;

			dataViewPort = new ListExtendedDataViewPort;
			dataViewPort.owner = this;
			viewPort = dataViewPort;

			addEventListener(FeathersEventType.RENDERER_ADD, rendererAddHandler);
			addEventListener(TouchEvent.TOUCH, touchHandler);
			addEventListener(DragDropEvent.DRAG_START, clearLastTouch);
			addEventListener(FeathersEventType.SCROLL_START, clearLastTouch);

			super.initialize();
		}

		public function rendererAddHandler(event:Event, renderer:IListItemRenderer):void
		{
			if (!renderer)
			{
				return;
			}

			renderer.addEventListener(TouchEvent.TOUCH, renderer_touchHandler);
		}

		protected function touchHandler(event:TouchEvent):void
		{
			var touch:Touch = event.getTouch(this);
			if (touch === null)
			{
				return;
			}
			if (touch.phase == TouchPhase.BEGAN)
			{
				ctrlActive = event.ctrlKey;
				shiftActive = event.shiftKey;
			}
			else if (touch.phase === TouchPhase.ENDED)
			{
				if (touchWhitespaceToDeselect && 
					event.target == this &&
					!ctrlActive &&
					!shiftActive &&
					!isScrolling)
				{
					selectedIndex = -1
				}
				else if (touchedSelectedIndex != -1 &&
					!isScrolling)
				{
					_selectedIndices.removeEventListener(Event.CHANGE, selectedIndices_changeHandler);

					if (shiftActive)
					{
						var changed:Boolean = selectIndices(lastSelectedIndex, touchedSelectedIndex);
						lastSelectedIndex = touchedSelectedIndex;
					}
					else if (ctrlActive && _selectedIndices.contains(touchedSelectedIndex))
					{
						_selectedIndices.removeItem(touchedSelectedIndex);
						lastSelectedIndex = -1;
						changed = true;
					}
					else if (_selectedIndices.length > 1 || _selectedIndex != touchedSelectedIndex)
					{
						selectedIndex = touchedSelectedIndex;
						lastSelectedIndex = touchedSelectedIndex;
						changed = true;
					}

					_selectedIndices.addEventListener(Event.CHANGE, selectedIndices_changeHandler);
				}

				clearLastTouch();
				
				if (changed)
				{
					getSelectedItems(_selectedItems); // Necessary to commit selected indices. 
					invalidate(INVALIDATION_FLAG_SELECTED);
					dispatchEventWith(Event.CHANGE);
				}
			}
		}

		protected function renderer_touchHandler(event:TouchEvent):void
		{
			var renderer:IListItemRenderer = event.currentTarget as IListItemRenderer;
			var touch:Touch = event.getTouch(renderer as DisplayObject, TouchPhase.BEGAN);
			if (touch !== null && 
				renderer.isSelected)
			{
				// Record renderer so we can apply changes manually if necessary:
				touchedSelectedIndex = renderer.index;
				trace("touchedSelectedIndex =", touchedSelectedIndex);
			}
		}

		override protected function selectedIndices_changeHandler(event:Event):void
		{
			trace("selectedIndices_changeHandler()");
			getSelectedItems(_selectedItems);
			
			if (_selectedIndices.length > 0)
			{
				_selectedIndices.removeEventListener(Event.CHANGE, selectedIndices_changeHandler); // Prevent nested calling of this method.

				var currentSelectedIndex:int = _selectedIndices.getItemAt(_selectedIndices.length - 1) as int;
				_selectedIndex = currentSelectedIndex;
				
				if (shiftActive)
				{
					selectIndices(lastSelectedIndex, currentSelectedIndex);
				}
				else if (!ctrlActive)
				{
					_selectedIndices.data = new <int>[currentSelectedIndex];
				}
				
				lastSelectedIndex = currentSelectedIndex;

				_selectedIndices.addEventListener(Event.CHANGE, selectedIndices_changeHandler);
			}
			else
			{
				lastSelectedIndex = -1;
				if (_selectedIndex < 0)
				{
					return;
				}
				this._selectedIndex = -1;
			}

			getSelectedItems(_selectedItems); // Necessary to commit selected indices. 
			invalidate(INVALIDATION_FLAG_SELECTED);
			dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @param fromIndex 
		 * @param toIndex 
		 * @return Whether any selected indices were changed
		 */
		protected function selectIndices(fromIndex:int, toIndex:int):Boolean
		{
			if (fromIndex == -1 || toIndex == -1)
			{
				return false;
			}

			trace(substitute("selectIndices({0}, {1})", [fromIndex, toIndex]));

			var changed:Boolean;

			if (fromIndex > toIndex)
			{
				for (var i:int = fromIndex; i >= toIndex; i--)
				{
					if (!_selectedIndices.contains(i))
					{
						_selectedIndices.push(i);
						changed = true;
					}
				}
			}
			else if (fromIndex < toIndex)
			{
				for (i = fromIndex; i <= toIndex; i++)
				{
					if (!_selectedIndices.contains(i))
					{
						_selectedIndices.push(i);
						changed = true;
					}
				}
			}

			return changed;
		}

		protected function clearLastTouch():void
		{
			trace("clearLastTouch()");
			ctrlActive = false;
			shiftActive = false;
			touchedSelectedIndex = -1;
		}
	}
}