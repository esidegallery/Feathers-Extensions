package feathers.controls
{
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.events.FeathersEventType;
	import feathers.utils.touch.TapToEventExtended;

	import flash.utils.Dictionary;

	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	/**
	 * Extends list functioanlity to support Ctrl-click and Shift-click multiple selection.
	 */
	public class ListExtended extends List
	{
		private static const EVENT_CTRL_TAP:String = "listExtended_ctrlTap";
		private static const EVENT_SHIFT_TAP:String = "listExtended_shiftTap";

		public var touchWhitespaceToDeselect:Boolean;

		private var _internalAllowMultipleSelection:Boolean;
		
		private var ctrlTappedItem:Object;
		private var shiftTappedItem:Object;
		private var lastSelectedItem:Object;

		// private var renderers:Dictionary = new Dictionary(true);
		private var rendererToCtrlTap:Dictionary;
		private var rendererToShiftTap:Dictionary;

		override public function set allowMultipleSelection(value:Boolean):void
		{
			if (_internalAllowMultipleSelection != value)
			{
				_internalAllowMultipleSelection = value;
				super.allowMultipleSelection = _internalAllowMultipleSelection;
			}
		}
		override public function get allowMultipleSelection():Boolean
		{
			return _internalAllowMultipleSelection;
		}

		override protected function initialize():void
		{
			rendererToCtrlTap = new Dictionary(true);
			rendererToShiftTap = new Dictionary(true);

			addEventListener(TouchEvent.TOUCH, touchHandler);
			addEventListener(FeathersEventType.RENDERER_ADD, rendererAddHandler);
			addEventListener(FeathersEventType.RENDERER_REMOVE, rendererRemoveHandler);

			super.initialize();
		}

		protected function touchHandler(event:TouchEvent):void
		{
			// Deselect if touching whitespace (and not in selection mode):
			if (touchWhitespaceToDeselect && event.target == this && !isScrolling && event.getTouch(this, TouchPhase.ENDED))
			{
				selectedIndex = -1;
			}
			if (event.getTouch(this, TouchPhase.BEGAN))
			{
				trace("brah;");
			}
		}

		protected function rendererAddHandler(event:Event, renderer:IListItemRenderer):void
		{
			rendererToCtrlTap[renderer] = new TapToEventExtended(renderer as DisplayObject, EVENT_CTRL_TAP, false, true);
			rendererToShiftTap[renderer] = new TapToEventExtended(renderer as DisplayObject, EVENT_SHIFT_TAP, false, false, true);
			renderer.addEventListener(EVENT_CTRL_TAP, renderer_ctrlTapHandler);
			renderer.addEventListener(EVENT_SHIFT_TAP, renderer_shiftTapHandler);
		}

		protected function rendererRemoveHandler(event:Event, renderer:IListItemRenderer):void
		{
			var tte:TapToEventExtended = rendererToCtrlTap[renderer] as TapToEventExtended;
			if (tte !== null)
			{
				tte.target = null;
				delete rendererToCtrlTap[renderer];
			}
			tte = rendererToShiftTap[renderer] as TapToEventExtended;
			if (tte !== null)
			{
				tte.target = null;
				delete rendererToShiftTap[renderer];
			}
			renderer.removeEventListener(EVENT_CTRL_TAP, renderer_ctrlTapHandler);
			renderer.removeEventListener(EVENT_SHIFT_TAP, renderer_shiftTapHandler);
		}

		protected function renderer_ctrlTapHandler(event:Event):void
		{
			var renderer:IListItemRenderer = event.currentTarget as IListItemRenderer;
			if (renderer)
			{
				ctrlTappedItem = renderer.data;
			}
		}
		
		protected function renderer_shiftTapHandler(event:Event):void
		{
			var renderer:IListItemRenderer = event.currentTarget as IListItemRenderer;
			if (renderer)
			{
				shiftTappedItem = renderer.data;
			}
		}
		
		override protected function selectedIndices_changeHandler(event:Event):void
		{
			var currentShiftTappedItem:Object = shiftTappedItem;
			shiftTappedItem = null;
			var currentCtrlTappedItem:Object = ctrlTappedItem;
			ctrlTappedItem = null;
			
			getSelectedItems(_selectedItems);
			
			if (this._selectedIndices.length > 0)
			{
				_selectedIndices.removeEventListener(Event.CHANGE, selectedIndices_changeHandler); // Prevent nested calling of this method.
				this._selectedIndex = _selectedIndices.getItemAt(0) as int;
				
				// shift-tapped trumps ctrl-tapped.
				if (_internalAllowMultipleSelection && currentShiftTappedItem && lastSelectedItem)
				{
					var lastSelectedIndex:int = _dataProvider.getItemIndex(lastSelectedItem);
					var tappedIndex:int = _dataProvider.getItemIndex(currentShiftTappedItem);
					if (lastSelectedIndex > tappedIndex)
					{
						for (var i:int = lastSelectedIndex; i >= tappedIndex; i--)
						{
							if (_selectedIndices.getItemIndex(i) == -1)
							{
								_selectedIndices.addItemAt(i, _selectedIndices.length - 1);
							}
						}
					}
					else if (lastSelectedIndex < tappedIndex)
					{
						for (i = lastSelectedIndex; i <= tappedIndex; i++)
						{
							if (_selectedIndices.getItemIndex(i) == -1)
							{
								_selectedIndices.addItemAt(i, _selectedIndices.length - 1);
							}
						}
					}
					getSelectedItems(_selectedItems); // Necessary to commit any added selected indices (with shift key). 
					invalidate(INVALIDATION_FLAG_SELECTED);
				}
				else if (currentCtrlTappedItem && lastSelectedItem && _selectedItems.indexOf(lastSelectedItem) == -1) // Add last selected item to beginning of selectedItems if not already there:
				{
					_selectedItems.unshift(lastSelectedItem);
				}
				lastSelectedItem = selectedItems[selectedItems.length - 1];
				_selectedIndices.addEventListener(Event.CHANGE, selectedIndices_changeHandler);
			}
			else
			{
				lastSelectedItem = null;
				if (_selectedIndex < 0)
				{
					return;
				}
				this._selectedIndex = -1;
			}

			dispatchEventWith(Event.CHANGE);
		}
	}
}