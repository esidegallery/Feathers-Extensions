package feathers.controls
{
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.controls.popups.IPopUpContentManager;
	import feathers.controls.popups.OverlayPopUpContentManager;
	import feathers.data.IListCollection;
	import feathers.skins.IStyleProvider;

	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	import starling.events.Event;
	import starling.utils.StringUtil;

	public class SearchableList extends List
	{
		public static const DEFAULT_CHILD_STYLE_NAME_SEARCH_POP_UP_LABEL:String = "searchable-list-search-tooltip";

		public static const INVALIDATION_FLAG_POP_UP_LABEL:String = "popUpLabel";
		public static const INVALIDATION_FLAG_SEARCH:String = "search";

		public static var globalStyleProvider:IStyleProvider;
		override protected function get defaultStyleProvider():IStyleProvider
		{
			return globalStyleProvider;
		}

		public static function defaultSearchFunction(textToMatch:String, data:IListCollection, searchField:String):int
		{
			if (!textToMatch || data == null || data.length == 0)
			{
				return -1;
			}
			textToMatch = textToMatch.toLowerCase();
			itemText: for (var i:int = 0, l:int = data.length; i < l; i++)
			{
				var item:Object = data.getItemAt(i);
				if (searchField != null && item != null && item.hasOwnProperty(searchField))
				{
					var labelResult:Object = item[searchField];
					if (labelResult is String)
					{
						var itemText:String = labelResult as String;
					}
					else if (labelResult != null)
					{
						itemText = labelResult.toString();
					}
				}
				else if (item is String)
				{
					itemText = item as String;
				}
				else if (item !== null)
				{
					// We need to use strict equality here because the data can be
					// non-strictly equal to null.
					itemText = item.toString();
				}

				if (itemText.toLowerCase().indexOf(textToMatch) == 0)
				{
					return i;
				}
			}
			return -1;
		}

		public static function defaultPopUpLabelFactory():Label
		{
			var popUp:Label = new Label();
			popUp.touchable = false;
			popUp.styleNameList.add(DEFAULT_CHILD_STYLE_NAME_SEARCH_POP_UP_LABEL);
			return popUp;
		}

		private var _popUpLabelFactory:Function = defaultPopUpLabelFactory;
		public function get popUpLabelFactory():Function
		{
			return _popUpLabelFactory;
		}
		public function set popUpLabelFactory(value:Function):void
		{
			if (_popUpLabelFactory == value)
			{
				return;
			}
			_popUpLabelFactory = value;
			invalidate(INVALIDATION_FLAG_POP_UP_LABEL);
		}

		private var _searchField:String;
		public function get searchField():String
		{
			return _searchField;
		}
		public function set searchField(value:String):void
		{
			if (_searchField == value)
			{
				return;
			}
			_searchField = value;
			invalidate(INVALIDATION_FLAG_SEARCH);
		}

		/**
		 * <p>The function is expected to have the following signature:</p>
		 * <pre>function(textToMatch:String, data:IListCollection, searchField:String):Boolean</pre>
		 */
		private var _searchFunction:Function = defaultSearchFunction;
		public function get searchFunction():Function
		{
			return _searchFunction;
		}
		public function set searchFunction(value:Function):void
		{
			if (value == null)
			{
				// Using setter deliberately:
				searchFunction = defaultSearchFunction;
				return;
			}

			if (_searchFunction == value)
			{
				return;
			}

			_searchFunction = value;
			invalidate(INVALIDATION_FLAG_SEARCH);
		}

		private var _clearSearchDelay:Number = 4;
		public function get clearSearchDelay():Number
		{
			return _clearSearchDelay;
		}
		public function set clearSearchDelay(value:Number):void
		{
			if (_clearSearchDelay == value)
			{
				return;
			}
			_clearSearchDelay = value;
			resetClearSearchTimeOut();
			invalidate(INVALIDATION_FLAG_SEARCH);
		}

		private var _searchText:String = "";
		public function get searchText():String
		{
			return _searchText;
		}
		public function set searchText(value:String):void
		{
			if (!value && value != "")
			{
				value = "";
			}
			if (_searchText == value)
			{
				return;
			}
			_searchText = value;
			resetClearSearchTimeOut();
			invalidate(INVALIDATION_FLAG_SEARCH);
		}

		protected var _popUpContentManager:IPopUpContentManager;
		public function get popUpContentManager():IPopUpContentManager
		{
			return _popUpContentManager;
		}
		public function set popUpContentManager(value:IPopUpContentManager):void
		{
			if (processStyleRestriction(arguments.callee))
			{
				return;
			}

			if (_popUpContentManager != null)
			{
				popUpContentManager.removeEventListener(Event.CLOSE, popUpContentManager_closeHandler);
			}
			_popUpContentManager = value;
			if (_popUpContentManager != null)
			{
				popUpContentManager.addEventListener(Event.CLOSE, popUpContentManager_closeHandler);
			}
		}

		protected var popUpLabel:Label;

		/** Timeout before the search is cleared. */
		protected var clearSearchTimeoutID:int;

		public function clearSearch():void
		{
			clearTimeout(clearSearchTimeoutID);
			disposePopUpLabel();
			searchText = null;
		}

		public function SearchableList()
		{
			popUpContentManager = new OverlayPopUpContentManager;
		}

		override protected function initialize():void
		{
			addEventListener(Event.CHANGE, changeHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, function():void
			{
				clearSearch();
			});

			super.initialize();
		}

		override protected function draw():void
		{
			var searchInvalid:Boolean = isInvalid(INVALIDATION_FLAG_SEARCH);
			var popUpLabelInvalid:Boolean = isInvalid(INVALIDATION_FLAG_POP_UP_LABEL);

			if (popUpLabelInvalid)
			{
				disposePopUpLabel();
			}
			if (popUpLabelInvalid || searchInvalid)
			{
				refreshPopUpLabel();
			}
			if (searchInvalid)
			{
				doSearch();
			}

			super.draw();
		}

		protected function refreshPopUpLabel():void
		{
			if (popUpLabel == null)
			{
				var factory:Function = _popUpLabelFactory || defaultPopUpLabelFactory;
				popUpLabel = Label(factory());
			}

			popUpLabel.text = searchText;

			if (searchText && this.isCreated)
			{
				if (!popUpContentManager.isOpen)
				{
					popUpContentManager.open(popUpLabel, this);
					popUpLabel.validate();
				}
			}
			else
			{
				disposePopUpLabel();
			}
		}

		protected function doSearch():void
		{
			if (!searchText)
			{
				return;
			}

			var index:int = _searchFunction(searchText, _dataProvider, _searchField);
			if (index >= 0)
			{
				removeEventListener(Event.CHANGE, changeHandler);
				selectedIndex = index;
				addEventListener(Event.CHANGE, changeHandler);
				scrollToDisplayIndex(index);
			}

			resetClearSearchTimeOut(true);
		}

		protected function disposePopUpLabel():void
		{
			if (popUpContentManager.isOpen)
			{
				popUpContentManager.close();
			}
			if (popUpLabel != null)
			{
				popUpLabel.removeFromParent(true);
				popUpLabel = null;
			}
		}

		protected function resetClearSearchTimeOut(start:Boolean = false):void
		{
			clearTimeout(clearSearchTimeoutID);
			if (start && _searchText)
			{
				clearSearchTimeoutID = setTimeout(clearSearch, _clearSearchDelay * 1000);
			}
		}

		protected function changeHandler():void
		{
			clearSearch();
		}

		override protected function nativeStage_keyDownHandler(event:KeyboardEvent):void
		{
			super.nativeStage_keyDownHandler(event);

			if (event.isDefaultPrevented())
			{
				return;
			}

			if (event.keyCode == Keyboard.ESCAPE)
			{
				clearSearch();
				event.preventDefault();
				return;
			}

			if (event.charCode == Keyboard.BACKSPACE)
			{
				searchText = searchText.substr(0, searchText.length - 1);
				event.preventDefault();
				return;
			}

			if (event.charCode == Keyboard.SPACE)
			{
				var character:String = " ";
			}
			else
			{
				character = String.fromCharCode(event.charCode);
				character = character && StringUtil.trim(character);
			}
			if (!character)
			{
				return;
			}
			searchText += character;
			event.preventDefault();
		}

		protected function popUpContentManager_closeHandler(event:Event):void
		{
			disposePopUpLabel();
		}

		override public function dispose():void
		{
			clearTimeout(clearSearchTimeoutID);
			popUpContentManager.dispose();
			disposePopUpLabel();

			super.dispose();
		}
	}
}