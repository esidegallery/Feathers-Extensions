package feathers.controls
{
	public class TabNavigatorExtended extends TabNavigator
	{
		public var autoShowFirstAddedItem:Boolean = true;
		
		override protected function initialize():void
		{
			super.initialize();
			
			tabBarFactory = function():TabBarExtended
			{
				var tabBar:TabBarExtended = new TabBarExtended;
				tabBar.autoSelectFirstTab = false;
				return tabBar;
			}
		}
		
		override protected function createTabBar():void
		{
			super.createTabBar();
			
			if (tabBar)
			{
				tabBar.enabledFunction = getTabEnabled;
			}
		}
		
		protected function getTabEnabled(id:String):Boolean
		{
			var item:TabNavigatorItem = this.getScreen(id);
			var value:Boolean = item && (item.properties.hasOwnProperty("isEnabled") ? item.properties.isEnabled : true);
			return value;
		}
		
		public function invalidateTabBarFactory():void
		{
			tabBar.invalidate("tabFactory");
		}
		
		override public function addScreenAt(id:String, item:TabNavigatorItem, index:int):void
		{
			this.addScreenInternal(id, item);
			this._tabBarDataProvider.addItemAt(id, index);
			if(this._selectedIndex < 0 && this._tabBarDataProvider.length === 1 && this.autoShowFirstAddedItem)
			{
				this.selectedIndex = 0;
			}
		}
	}
}