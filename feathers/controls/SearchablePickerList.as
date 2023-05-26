package feathers.controls
{
	import feathers.skins.IStyleProvider;

	public class SearchablePickerList extends PickerListPatched
	{
		public static var globalStyleProvider:IStyleProvider;
		override protected function get defaultStyleProvider():IStyleProvider
		{
			return globalStyleProvider;
		}

		/** Defaults to labelField if not set. */
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
			invalidate(INVALIDATION_FLAG_DATA);
		}

		public function SearchablePickerList()
		{
			popUpContentManager = new CustomDropDownPopUpContentManager;
			buttonFactory = function():Button
			{
				return new ToggleButton;
			};
			listFactory = function():List
			{
				return new SearchableList;
			};
			toggleButtonOnOpenAndClose = true;
		}

		override protected function draw():void
		{
			var dataInvalid:Boolean = isInvalid(INVALIDATION_FLAG_DATA);

			if (dataInvalid)
			{
				listProperties.searchField = _searchField || _labelField;
			}

			super.draw();
		}
	}
}

import feathers.controls.popups.DropDownPopUpContentManager;
import feathers.skins.IStyleProvider;
import feathers.utils.display.getPopUpIndex;

import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Quad;
import starling.events.KeyboardEvent;

class CustomDropDownPopUpContentManager extends DropDownPopUpContentManager
{
	public function CustomDropDownPopUpContentManager()
	{
		// We need to set the popups as modal in order to create a focus manager for the content:
		isModal = true;
		// We therefore set an invisible, non-touchable, overlay:
		overlayFactory = function():DisplayObject
		{
			var overlay:Quad = new Quad(1, 1);
			overlay.alpha = 0;
			overlay.touchable = false;
			return overlay;
		};
	}

	override public function open(content:DisplayObject, source:DisplayObject):void
	{
		super.open(content, source);

		// Re-add the eventlistener at the new priority:
		var priority:int = getPopUpIndex(content);
		Starling.current.nativeStage.removeEventListener(KeyboardEvent.KEY_DOWN, nativeStage_keyDownHandler);
		Starling.current.nativeStage.addEventListener(KeyboardEvent.KEY_DOWN, nativeStage_keyDownHandler, false, priority, true);
	}
}