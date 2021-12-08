package feathers.utils
{
	import feathers.dragDrop.DragData;
	import feathers.dragDrop.DragDropManager;
	import feathers.dragDrop.IDragSource;

	import flash.desktop.Clipboard;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.display.Sprite;
	import flash.events.FocusEvent;
	import flash.events.NativeDragEvent;
	import flash.geom.Point;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Stage;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	/**
	 * Converts NativeDragEvents to Feathers drag actions!
	 * 
	 * The Feathers DragData object dispatched will match the formats and data of the NativeDragEvent.
	 * 
	 * This class needs to extend starling.display.DisplayObject, due to the way DragDropManager
	 * retrieves the stage property, but it shouldn't be added to the stage.
	 * Instead, pass stage to the constructor.
	 */
	public class NativeDragSource extends DisplayObject implements IDragSource
	{
		/** An array of ClipboardFormats values. Leave null to accept all formats. */
		public var validClipboardFormats:Array;
		
		/** Ensures touch IDs are all unique, should there be more than one NativeDragSource instance (different Starling stages). */
		private static var nextTouchID:uint = 1000000;
		
		private var _stage:Stage;
		/** Provided for DragDropManager's sake. */
		override public function get stage():Stage
		{
			return _stage;
		}
		
		private var useNativeOverlay:Boolean;
		
		private var touchID:uint;
		private var overlay:Sprite;
		
		private var dragData:DragData;
		private var touchPosition:Point = new Point;
		
		private function get starling():Starling
		{
			return _stage.starling;
		}
		
		/**
		 * @param stage            The Starling stage instance.
		 * @param useNativeOverlay Whether the starling's nativeOverlay will be used to listen
		 *                         for NativeDragEvents. If false, then a new flash.display.Sprite will
		 *                         be created and added to the native stage. This Sprite's graphics object
		 *                         will be used to draw a transparent rect covering the stage.
		 */
		public function NativeDragSource(stage:Stage, useNativeOverlay:Boolean = false)
		{
			if (stage == null)
			{
				throw new ArgumentError("Stage must not be null.");
			}
			
			this._stage = stage;
			this.useNativeOverlay = useNativeOverlay;
			
			if (useNativeOverlay)
			{
				overlay = starling.nativeOverlay;
			}
			else
			{
				overlay = new Sprite;
				starling.nativeStage.addChildAt(overlay, 0);
			}
			drawOverlayGraphics();
			
			touchID = nextTouchID++;
			
			starling.nativeStage.addEventListener(FocusEvent.MOUSE_FOCUS_CHANGE, nativeStage_mouseFocusChangeHandler, false, int.MAX_VALUE, true);
			_stage.addEventListener(Event.RESIZE, stage_resizeHandler);
			overlay.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, nativeDragHandler);
		}
		
		override public function dispose():void
		{
			if (_stage == null)
			{
				return;
			}
			
			endDrag();
			
			_stage.removeEventListener(Event.RESIZE, stage_resizeHandler);
			_stage.removeEventListener(TouchEvent.TOUCH, stage_touchHandler);
			overlay.removeEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, nativeDragHandler);
			
			overlay.graphics.clear();
			if (!useNativeOverlay && starling.nativeStage.contains(overlay))
			{
				starling.nativeStage.removeChild(overlay);
			}
			starling.nativeStage.removeEventListener(FocusEvent.MOUSE_FOCUS_CHANGE, nativeStage_mouseFocusChangeHandler);
			
			overlay = null;
			dragData = null;
			touchPosition = null;
			_stage = null;
			
			super.dispose();
		}
		
		protected function nativeStage_mouseFocusChangeHandler(event:FocusEvent):void
		{
			if (event.relatedObject == overlay)
			{
				// We don't want overlay to interfere with Feathers' focus system:
				event.preventDefault();
				event.stopImmediatePropagation();
			}
		}

		protected function nativeDragHandler(event:NativeDragEvent):void
		{
			if (!hasValidFormat(event.clipboard))
			{
				endDrag();
				return;
			}
			
			touchPosition.setTo(event.stageX, event.stageY);
			
			if (event.type == NativeDragEvent.NATIVE_DRAG_ENTER)
			{
				dragData = new DragData;
				var clipboard:Clipboard = event.clipboard;
				for (var i:int = 0, formats:Array = clipboard.formats; i < formats.length; i++)
				{
					dragData.setDataForFormat(formats[i], clipboard.getData(formats[i]));
				}
				
				NativeDragManager.acceptDragDrop(overlay);
				// The IDropTargets should specify the dropAction accordingly:
				NativeDragManager.dropAction = NativeDragActions.NONE;
				
				initiateDrag();
			}
			else if (event.type == NativeDragEvent.NATIVE_DRAG_OVER)
			{
				updateDrag();
			}
			else if (event.type == NativeDragEvent.NATIVE_DRAG_EXIT)
			{
				cancelDrag();
			}
			else
			{
				endDrag();
			}
		}
		
		protected function hasValidFormat(clipboard:Clipboard):Boolean
		{
			if (validClipboardFormats == null)
			{
				return true;
			}
			
			for each (var format:String in validClipboardFormats)
			{
				if (clipboard.hasFormat(format))
				{
					return true;
				}
			}
			
			return false;
		}
		
		protected function initiateDrag():void
		{
			// Enqueue a fake BEGIN TouchEvent with the same x and y as the triggering NativeDragEvent, then listen for it.
			// This is the only way to get the touch event to pass to DragDropManager.startDrag()
			_stage.addEventListener(TouchEvent.TOUCH, stage_touchHandler);
			// Begin at 0,0 to minimise the impact of this event (e.g. initiating a drag on a scroller).
			starling.touchProcessor.enqueue(touchID, TouchPhase.BEGAN, 0, 0);
			
			addOverlayListeners();
		}
		
		protected function updateDrag():void
		{
			// Enqueue a fake MOVED TouchEvent with the same x and y as the triggering NativeDragEvent.
			starling.touchProcessor.enqueue(touchID, TouchPhase.MOVED, touchPosition.x, touchPosition.y);
		}
		
		protected function endDrag():void
		{
			starling.touchProcessor.enqueue(touchID, TouchPhase.ENDED, touchPosition.x, touchPosition.y);
			removeOverlayListeners();
		}
		
		protected function cancelDrag():void
		{
			DragDropManager.cancelDrag();
			dragData = null;
			removeOverlayListeners();
		}
		
		protected function addOverlayListeners():void
		{
			overlay.addEventListener(NativeDragEvent.NATIVE_DRAG_OVER, nativeDragHandler);
			overlay.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, nativeDragHandler);
			overlay.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, nativeDragHandler);
		}
		
		protected function removeOverlayListeners():void
		{
			overlay.removeEventListener(NativeDragEvent.NATIVE_DRAG_OVER, nativeDragHandler);
			overlay.removeEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, nativeDragHandler);
			overlay.removeEventListener(NativeDragEvent.NATIVE_DRAG_DROP, nativeDragHandler);
		}
		
		/** 
		 * Listens for the initial event that was enqueued in initiateDrag(),
		 * so that the event's touch instance can be passed to DragDropManager.startDrag().
		 */
		protected function stage_touchHandler(event:TouchEvent):void
		{
			var touch:Touch = event.getTouch(_stage, TouchPhase.BEGAN, touchID);
			if (touch != null && dragData != null)
			{
				_stage.removeEventListener(TouchEvent.TOUCH, stage_touchHandler);
				DragDropManager.startDrag(this, touch, dragData);
				dragData = null;
			}
			event.stopImmediatePropagation();
		}
		
		protected function drawOverlayGraphics():void
		{
			overlay.graphics.clear();
			overlay.graphics.beginFill(0, 0);
			overlay.graphics.drawRect(0, 0, _stage.stageWidth, _stage.stageHeight);
			overlay.graphics.endFill();
		}
		
		protected function stage_resizeHandler(event:Event):void
		{
			drawOverlayGraphics();
		}
	}
}