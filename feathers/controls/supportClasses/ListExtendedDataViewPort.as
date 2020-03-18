package feathers.controls.supportClasses
{
	import feathers.controls.renderers.IDragAndDropItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.display.RenderDelegate;
	import feathers.dragDrop.DragData;
	import feathers.dragDrop.DragDropManager;
	import feathers.events.DragDropEvent;
	import feathers.events.ExclusiveTouch;
	import feathers.system.DeviceCapabilities;

	import flash.geom.Point;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.Pool;
	import feathers.layout.IDragDropLayout;
	import feathers.layout.TiledRowsLayout;

	public class ListExtendedDataViewPort extends ListDataViewPort
	{
		// override protected function dragEnterHandler(event:DragDropEvent):void
		// {
		// 	_acceptedDrag = false;
		// 	if (!_dropEnabled)
		// 	{
		// 		return;
		// 	}
		// 	if (!event.dragData.hasDataForFormat(_dragFormat))
		// 	{
		// 		return;
		// 	}
		// 	DragDropManager.acceptDrag(owner);
		// 	refreshDropIndicator(event.localX, event.localY);

		// 	_acceptedDrag = true;
		// 	_dragLocalX = event.localX;
		// 	_dragLocalY = event.localY;
		// 	addEventListener(Event.ENTER_FRAME, dragScroll_enterFrameHandler);
		// }

		// override protected function dragDropHandler(event:DragDropEvent):void
		// {
		// 	_acceptedDrag = false;
		// 	if (_dropIndicatorSkin)
		// 	{
		// 		_dropIndicatorSkin.removeFromParent(false);
		// 	}
		// 	_dragLocalX = -1;
		// 	_dragLocalY = -1;
		// 	removeEventListener(Event.ENTER_FRAME, dragScroll_enterFrameHandler);

		// 	var item:Object = event.dragData.getDataForFormat(_dragFormat);
		// 	var dropIndex:int = dataProvider.length;
		// 	if (layout is IDragDropLayout)TiledRowsLayout
		// 	{
		// 		var layout:IDragDropLayout = IDragDropLayout(layout);
		// 		dropIndex = layout.getDropIndex(
		// 			horizontalScrollPosition + event.localX,
		// 			verticalScrollPosition + event.localY,
		// 			_layoutItems, 0, 0, visibleWidth, visibleHeight);
		// 	}
		// 	var dropOffset:int = 0;
		// 	if (event.dragSource == owner)
		// 	{
		// 		var oldIndex:int = dataProvider.getItemIndex(item);
		// 		if (oldIndex < dropIndex)
		// 		{
		// 			dropOffset = -1;
		// 		}

		// 		//if we wait to remove this item in the dragComplete handler,
		// 		//the wrong index might be removed.
		// 		dataProvider.removeItem(item);
		// 		_droppedOnSelf = true;
		// 	}
		// 	dataProvider.addItemAt(item, dropIndex + dropOffset);
		// }

		// override protected function dragCompleteHandler(event:DragDropEvent):void
		// {
		// 	if (!event.isDropped)
		// 	{
		// 		//nothing to modify
		// 		return;
		// 	}
		// 	if (_droppedOnSelf)
		// 	{
		// 		//already modified the data provider in the dragDrop handler
		// 		_droppedOnSelf = false;
		// 		return;
		// 	}
		// 	var item:Object = event.dragData.getDataForFormat(_dragFormat);
		// 	dataProvider.removeItem(item);
		// }
		
		override protected function itemRenderer_drag_touchHandler(event:TouchEvent):void
		{
			// Modified so that selected 
			if (!_dragEnabled || !stage)
			{
				_dragTouchPointID = -1;
				return;
			}
			var itemRenderer:IListItemRenderer = IListItemRenderer(event.currentTarget);
			if (DragDropManager.isDragging)
			{
				_dragTouchPointID = -1;
				return;
			}
			if (itemRenderer is IDragAndDropItemRenderer)
			{
				var dragProxy:DisplayObject = IDragAndDropItemRenderer(itemRenderer).dragProxy;
				if (dragProxy)
				{
					var touch:Touch = event.getTouch(dragProxy, null, _dragTouchPointID);
					if (!touch)
					{
						return;
					}
				}
			}
			if (_dragTouchPointID != -1)
			{
				var exclusiveTouch:ExclusiveTouch = ExclusiveTouch.forStage(stage);
				if (exclusiveTouch.getClaim(_dragTouchPointID))
				{
					_dragTouchPointID = -1;
					return;
				}
				touch = event.getTouch(DisplayObject(itemRenderer), null, _dragTouchPointID);
				if (touch.phase == TouchPhase.MOVED)
				{
					var point:Point = touch.getLocation(this, Pool.getPoint());
					var currentDragX:Number = point.x;
					var currentDragY:Number = point.y;
					Pool.putPoint(point);
					
					var starling:Starling = stage.starling;
					var verticalInchesMoved:Number = (currentDragX - _startDragX) / (DeviceCapabilities.dpi / starling.contentScaleFactor);
					var horizontalInchesMoved:Number = (currentDragY - _startDragY) / (DeviceCapabilities.dpi / starling.contentScaleFactor);
					if (Math.abs(horizontalInchesMoved) > _minimumDragDropDistance ||
						Math.abs(verticalInchesMoved) > _minimumDragDropDistance)
					{
						// if (owner.selectedIndices.indexOf(itemRenderer.index) == -1)
						// {
							owner.selectedIndex = itemRenderer.index;
						// }

						var dragData:DragData = new DragData();
						// var numItems:int = owner.selectedItems.length;
						// if (numItems > 1)
						// {
						// 	dragData.setDataForFormat(_dragFormat, new ListCollection(owner.selectedItems))
						// }
						// else
						// {
							dragData.setDataForFormat(_dragFormat, itemRenderer.data);
						// }
						
						//we don't create a new item renderer here because
						//it might remove accessories or icons from the original
						//item renderer that is still visible in the list.
						var avatar:RenderDelegate = new RenderDelegate(DisplayObject(itemRenderer));
						avatar.touchable = false;
						avatar.alpha = 0.8;

						_droppedOnSelf = false;
						point = touch.getLocation(DisplayObject(itemRenderer),  Pool.getPoint());
						DragDropManager.startDrag(owner, touch, dragData, DisplayObject(avatar), -point.x, -point.y);
						Pool.putPoint(point);
						exclusiveTouch.claimTouch(_dragTouchPointID, DisplayObject(itemRenderer));
						_dragTouchPointID = -1;
					}
				}
				else if (touch.phase == TouchPhase.ENDED)
				{
					_dragTouchPointID = -1;
				}
			}
			else
			{
				//we aren't tracking another touch, so let's look for a new one.
				touch = event.getTouch(DisplayObject(itemRenderer), TouchPhase.BEGAN);
				if (!touch)
				{
					//we only care about the began phase. ignore all other
					//phases when we don't have a saved touch ID.
					return;
				}
				_dragTouchPointID = touch.id;
				point = touch.getLocation(this, Pool.getPoint());
				_startDragX = point.x;
				_startDragY = point.y;
				Pool.putPoint(point);
			}
		}
	}
}