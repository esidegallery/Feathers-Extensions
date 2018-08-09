package feathers.controls
{
	import feathers.data.IListCollection;
	import feathers.events.CollectionEventType;
	
	import starling.events.Event;
	
	public class TabBarExtended extends TabBar
	{
		protected static const FIELD_TOOLTIP:String = "toolTip";
		
		public var autoSelectFirstTab:Boolean = true;
		
		override public function set dataProvider(value:IListCollection):void
		{
			if(this._dataProvider == value)
			{
				return;
			}
			var oldSelectedIndex:int = this.selectedIndex;
			var oldSelectedItem:Object = this.selectedItem;
			if(this._dataProvider)
			{
				this._dataProvider.removeEventListener(CollectionEventType.ADD_ITEM, dataProvider_addItemHandler);
				this._dataProvider.removeEventListener(CollectionEventType.REMOVE_ITEM, dataProvider_removeItemHandler);
				this._dataProvider.removeEventListener(CollectionEventType.REMOVE_ALL, dataProvider_removeAllHandler);
				this._dataProvider.removeEventListener(CollectionEventType.REPLACE_ITEM, dataProvider_replaceItemHandler);
				this._dataProvider.removeEventListener(CollectionEventType.FILTER_CHANGE, dataProvider_filterChangeHandler);
				this._dataProvider.removeEventListener(CollectionEventType.UPDATE_ITEM, dataProvider_updateItemHandler);
				this._dataProvider.removeEventListener(CollectionEventType.UPDATE_ALL, dataProvider_updateAllHandler);
				this._dataProvider.removeEventListener(CollectionEventType.RESET, dataProvider_resetHandler);
			}
			this._dataProvider = value;
			if(this._dataProvider)
			{
				this._dataProvider.addEventListener(CollectionEventType.ADD_ITEM, dataProvider_addItemHandler);
				this._dataProvider.addEventListener(CollectionEventType.REMOVE_ITEM, dataProvider_removeItemHandler);
				this._dataProvider.addEventListener(CollectionEventType.REMOVE_ALL, dataProvider_removeAllHandler);
				this._dataProvider.addEventListener(CollectionEventType.REPLACE_ITEM, dataProvider_replaceItemHandler);
				this._dataProvider.addEventListener(CollectionEventType.FILTER_CHANGE, dataProvider_filterChangeHandler);
				this._dataProvider.addEventListener(CollectionEventType.UPDATE_ITEM, dataProvider_updateItemHandler);
				this._dataProvider.addEventListener(CollectionEventType.UPDATE_ALL, dataProvider_updateAllHandler);
				this._dataProvider.addEventListener(CollectionEventType.RESET, dataProvider_resetHandler);
			}
			if(!this._dataProvider || this._dataProvider.length == 0 || !autoSelectFirstTab)
			{
				this.selectedIndex = -1;
			}
			else
			{
				this.selectedIndex = 0;
			}
			//this ensures that Event.CHANGE will dispatch for selectedItem
			//changing, even if selectedIndex has not changed.
			if(this.selectedIndex == oldSelectedIndex && this.selectedItem != oldSelectedItem)
			{
				this.dispatchEventWith(Event.CHANGE);
			}
			this.invalidate(INVALIDATION_FLAG_DATA);
		}
		
		override protected function defaultTabInitializer(tab:ToggleButton, item:Object):void
		{
			super.defaultTabInitializer(tab, item);
			
			if (item.hasOwnProperty(FIELD_TOOLTIP))
			{
				tab.toolTip = item.toolTip;
			}
		}
	}
}