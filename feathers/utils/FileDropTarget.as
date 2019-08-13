package feathers.utils
{
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.filesystem.File;
	
	import feathers.dragDrop.DragData;
	import feathers.dragDrop.DragDropManager;
	import feathers.dragDrop.IDropTarget;
	import feathers.events.DragDropEvent;
	
	import starling.display.DisplayObject;
	
	public class FileDropTarget
	{
		/** Dispatched from the target when valid files are dropped.<br><code>Event.data</code> is <code>Vector.&lt;File&gt;</code>. */
		public static const EVENT_FILE_DRAG_DROP:String = "fileDragDrop";
		
		private var _target:DisplayObject;
		public function get target():DisplayObject
		{
			return _target;
		}
		public function set target(value:DisplayObject):void
		{
			if (_target)
			{
				_target.removeEventListener(DragDropEvent.DRAG_ENTER, target_dragEnterHandler);
				_target.removeEventListener(DragDropEvent.DRAG_EXIT, target_dragExitHandler);
				_target.removeEventListener(DragDropEvent.DRAG_DROP, target_dragDropHandler);
			}
			_target = value;
			if (_target && _target is IDropTarget)
			{
				_target.addEventListener(DragDropEvent.DRAG_ENTER, target_dragEnterHandler);
				_target.addEventListener(DragDropEvent.DRAG_EXIT, target_dragExitHandler);
				_target.addEventListener(DragDropEvent.DRAG_DROP, target_dragDropHandler);
			}
			else
			{
				throw new Error("Property target must implement feathers.dragDrop.IDropTarget.");
			}
		}
		
		public var validFileExtensions:Vector.<String>;
		public var allowMultipleFiles:Boolean;
		public var allowFolders:Boolean;
		public var allFilesMustBeValid:Boolean;
		public var dropEventBubbles:Boolean;
		public var customEventType:String;
		
		/**
		 * @param target A DisplayObject that implements IDropTarget that will become the file drop target.
		 * @param validFileExtensions Determines the file extensions that will be checked against.
		 * @param allowMultipleFiles Whether to allow multiple files
		 * @param allowFolders Whether to allow folders
		 * @param allFilesMustBeValid All files dragged in must be valid. e.g. if allowMultipleFiles is empty and allowFolders = true, then only folders can be dropped onto the target.
		 *        If this is false and validFileExtensions is null or empty, files of all extensions will pass. If validFileExtensions is populated, at least one file (including folders) must be valid.
		 * @param dropEventBubbles The target will dipatch <code>FileDropTarget.EVENT_FILE_DRAG_DROP</code> on a successful drop. Set to true to make it bubble. 
		 */
		public function FileDropTarget(target:DisplayObject, validFileExtensions:Vector.<String> = null, allowMultipleFiles:Boolean = false, allowFolders:Boolean = false, allFilesMustBeValid:Boolean = false, dropEventBubbles:Boolean = false, customEventType:String = null)
		{
			this.target = target;
			this.validFileExtensions = validFileExtensions;
			this.allowMultipleFiles = allowMultipleFiles;
			this.allowFolders = allowFolders;
			this.allFilesMustBeValid = allFilesMustBeValid;
			this.dropEventBubbles = dropEventBubbles;
			this.customEventType = customEventType;
		}
		
		public function checkDroppedFiles(files:Vector.<File>):Boolean
		{
			if (!allowMultipleFiles && files.length > 1)
			{
				return false;
			}
			
			var numValidFiles:int;
			var numInvalidFiles:int;
			
			for each (var file:File in files)
			{
				if (file.isDirectory)
				{
					if (!allowFolders)
					{
						return false;
					}
					else
					{
						numValidFiles++;
					}
				}
				else
				{
					if (validFileExtensions && file.extension && validFileExtensions.indexOf(file.extension.toLowerCase()) >= 0)
					{
						numValidFiles++;
					}
					else
					{
						numInvalidFiles++;
					}
				}
				
				if (numValidFiles && !allFilesMustBeValid)
				{
					return true;
				}
				else if (numInvalidFiles && allFilesMustBeValid)
				{
					return false;
				}
			}
			return Boolean(numValidFiles);
		}
		
		private function target_dragEnterHandler(event:DragDropEvent, dragData:DragData):void
		{
			if (dragData.hasDataForFormat(ClipboardFormats.FILE_LIST_FORMAT)
				&& checkDroppedFiles(Vector.<File>(dragData.getDataForFormat(ClipboardFormats.FILE_LIST_FORMAT))))
			{
				DragDropManager.acceptDrag(IDropTarget(target));
				NativeDragManager.dropAction = NativeDragActions.COPY;
			}
		}
		
		private function target_dragExitHandler():void
		{
			NativeDragManager.dropAction = NativeDragActions.NONE;
		}
		
		private function target_dragDropHandler(event:DragDropEvent, dragData:DragData):void
		{
			target.dispatchEventWith(customEventType || EVENT_FILE_DRAG_DROP, dropEventBubbles, Vector.<File>(dragData.getDataForFormat(ClipboardFormats.FILE_LIST_FORMAT)));
		}
	}
}