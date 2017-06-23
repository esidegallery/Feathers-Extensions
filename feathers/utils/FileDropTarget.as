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
		/** Dispatched from the target when valid files are dropped. <code>Event.data</code> is <code>Vector.&lt;File&gt;</code>. */
		public static const FILE_DRAG_DROP:String = "fileDragDrop";
		
		public function FileDropTarget(target:DisplayObject, allowMultipleFiles:Boolean = true, validFileExtensions:Vector.<String> = null, allFilesMustBeValid:Boolean = false, atLeastOneFileMustBeValid:Boolean = true, dropEventBubbles:Boolean = false)
		{
			this.target = target;
			this.allowMultipleFiles = allowMultipleFiles;
			this.validFileExtensions = validFileExtensions;
			this.allFilesMustBeValid = allFilesMustBeValid;
			this.atLeastOneFileMustBeValid = atLeastOneFileMustBeValid;
			this.dropEventBubbles = dropEventBubbles;
		}
		
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
				throw new Error("Property target must implement feathers.dragDrop.IDropTarget.");
		}
		
		public var allowMultipleFiles:Boolean;
		public var validFileExtensions:Vector.<String>;
		public var allFilesMustBeValid:Boolean;
		public var atLeastOneFileMustBeValid:Boolean;
		public var dropEventBubbles:Boolean;
		
		public function checkDroppedFiles(files:Vector.<File>):Boolean
		{
			if (!allowMultipleFiles && files.length > 1)
				return false;
			
			if (!validFileExtensions)
				return true;
			
			var validFiles:int;
			var invalidFiles:int;
			
			for each (var file:File in files)
			{
				if (validFileExtensions.indexOf(file.extension) >= 0)
				{
					if (!allFilesMustBeValid || atLeastOneFileMustBeValid)
						return true;
					validFiles ++;
				}
				else
					invalidFiles ++;
			}
			return validFiles && !invalidFiles;
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
			target.dispatchEventWith(FILE_DRAG_DROP, dropEventBubbles, Vector.<File>(dragData.getDataForFormat(ClipboardFormats.FILE_LIST_FORMAT)));
		}
	}
}