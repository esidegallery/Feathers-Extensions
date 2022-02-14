package feathers.controls.popups
{
	import feathers.controls.popups.IPopUpContentManager;
	import feathers.core.IFeathersControl;
	import feathers.core.IValidating;
	import feathers.core.PopUpManager;
	import feathers.core.ValidationQueue;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.utils.geom.matrixToScaleX;
	import feathers.utils.geom.matrixToScaleY;

	import flash.errors.IllegalOperationError;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.Stage;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.utils.Align;
	import starling.utils.Pool;

	public class OverlayPopUpContentManager extends EventDispatcher implements IPopUpContentManager
	{
		protected const HELPER_RECT:Rectangle = new Rectangle;

		private var _verticalAlign:String = VerticalAlign.TOP;
		public function get verticalAlign():String
		{
			return _verticalAlign;
		}
		public function set verticalAlign(value:String):void
		{
			if (_verticalAlign == value)
			{
				return;
			}
			_verticalAlign = value;
			lastOriginX = NaN;
			lastOriginY = NaN;
			lastOriginWidth = NaN;
			lastOriginHeight = NaN;
		}

		private var _horizontalAlign:String = HorizontalAlign.RIGHT;
		public function get horizontalAlign():String
		{
			return _horizontalAlign;
		}
		public function set horizontalAlign(value:String):void
		{
			if (_horizontalAlign == value)
			{
				return;
			}
			_horizontalAlign = value;
			lastOriginX = NaN;
			lastOriginY = NaN;
			lastOriginWidth = NaN;
			lastOriginHeight = NaN;
		}

		private var _padding:Number = 0;
		public function get padding():Number
		{
			return _padding;
		}
		public function set padding(value:Number):void
		{
			if (_padding == value)
			{
				return;
			}
			_padding = value;
			lastOriginX = NaN;
			lastOriginY = NaN;
			lastOriginWidth = NaN;
			lastOriginHeight = NaN;
		}

		private var _fitContentMinWidthToOrigin:Boolean = false;
		protected function get fitContentMinWidthToOrigin():Boolean
		{
			return _fitContentMinWidthToOrigin;
		}
		protected function set fitContentMinWidthToOrigin(value:Boolean):void
		{
			if (_fitContentMinWidthToOrigin == value)
			{
				return;
			}
			_fitContentMinWidthToOrigin = value;
			lastOriginX = NaN;
			lastOriginY = NaN;
			lastOriginWidth = NaN;
			lastOriginHeight = NaN;
		}

		private var _fitContentMaxWidthToOrigin:Boolean = true;
		protected function get fitContentMaxWidthToOrigin():Boolean
		{
			return _fitContentMaxWidthToOrigin;
		}
		protected function set fitContentMaxWidthToOrigin(value:Boolean):void
		{
			if (_fitContentMaxWidthToOrigin == value)
			{
				return;
			}
			_fitContentMaxWidthToOrigin = value;
			lastOriginX = NaN;
			lastOriginY = NaN;
			lastOriginWidth = NaN;
			lastOriginHeight = NaN;
		}

		public function get isOpen():Boolean
		{
			return content != null;
		}

		protected var content:DisplayObject;
		protected var source:DisplayObject;
		protected var lastOriginX:Number;
		protected var lastOriginY:Number;
		protected var lastOriginWidth:Number;
		protected var lastOriginHeight:Number;

		public function open(content:DisplayObject, source:DisplayObject):void
		{
			if (isOpen)
			{
				throw new IllegalOperationError("Pop-up content is already open. Close the previous content before opening new content.");
			}

			// Make sure the content is scaled the same as the source:
			var matrix:Matrix = Pool.getMatrix();
			source.getTransformationMatrix(PopUpManager.root, matrix);
			content.scaleX = matrixToScaleX(matrix)
			content.scaleY = matrixToScaleY(matrix);
			Pool.putMatrix(matrix);

			this.content = content;
			this.source = source;

			PopUpManager.addPopUp(content, false, false);
			if (content is IFeathersControl)
			{
				content.addEventListener(FeathersEventType.RESIZE, content_resizeHandler);
			}
			content.addEventListener(Event.REMOVED_FROM_STAGE, close);

			layout();

			dispatchEventWith(Event.OPEN);

			var stage:Stage = this.source.stage;
			stage.addEventListener(Event.ENTER_FRAME, stage_enterFrameHandler);
		}

		public function close():void
		{
			if (!isOpen)
			{
				return;
			}

			var stage:Stage = content.stage;
			stage.removeEventListener(Event.ENTER_FRAME, stage_enterFrameHandler);
			if(content is IFeathersControl)
			{
				content.removeEventListener(FeathersEventType.RESIZE, content_resizeHandler);
			}
			content.removeEventListener(Event.REMOVED_FROM_STAGE, close);
			content.removeFromParent(false);
			source = null;
			content = null;
			dispatchEventWith(Event.CLOSE);
		}

		protected function layout(originBoundsInParent:Rectangle = null):void
		{
			if (source is IValidating)
			{
				(source as IValidating).validate();
			}

			if (!isOpen)
			{
				return;
			}

			var paddingH:Number = _padding * source.scaleX;
			var paddingV:Number = _padding * source.scaleY;
			
			if (originBoundsInParent == null)
			{
				originBoundsInParent = source.getBounds(PopUpManager.root, HELPER_RECT);
			}
			var paddedSourceWidth:Number = originBoundsInParent.width - paddingH * 2;
			var uiContent:IFeathersControl = content as IFeathersControl;
			if (uiContent != null)
			{
				if (_fitContentMinWidthToOrigin && uiContent.minWidth < paddedSourceWidth)
				{
					uiContent.minWidth = paddedSourceWidth;
				}
				if (_fitContentMaxWidthToOrigin && uiContent.maxWidth > paddedSourceWidth)
				{
					uiContent.maxWidth = paddedSourceWidth;
				}
			}
			else
			{
				if (_fitContentMinWidthToOrigin && content.width < paddedSourceWidth)
				{
					content.width = paddedSourceWidth;
				}
				if (_fitContentMaxWidthToOrigin && content.width > paddedSourceWidth)
				{
					content.width = paddedSourceWidth;
				}
			}

			var stage:Stage = source.stage;
			
			// We need to be sure that the source is properly positioned before
			// positioning the content relative to it.
			var validationQueue:ValidationQueue = ValidationQueue.forStarling(stage.starling);
			if (validationQueue && !validationQueue.isValidating)
			{
				// Force a COMPLETE validation of everything
				// but only if we're not already doing that...
				validationQueue.advanceTime(0);
			}

			originBoundsInParent = source.getBounds(PopUpManager.root, originBoundsInParent);
			lastOriginX = originBoundsInParent.x;
			lastOriginY = originBoundsInParent.y;
			lastOriginWidth = originBoundsInParent.width;
			lastOriginHeight = originBoundsInParent.height;
			paddedSourceWidth = originBoundsInParent.width - paddingH * 2;
			var paddedSourceHeight:Number = originBoundsInParent.height - paddingV * 2;

			switch (_horizontalAlign)
			{
				case Align.RIGHT:
				{
					var hMultiplier:Number = 1;
					break;
				}
				case Align.CENTER:
				{
					hMultiplier = 0.5;
					break;
				}
				default:
				{
					hMultiplier = 0;
					break;
				}
			}
			switch (_verticalAlign)
			{
				case Align.BOTTOM:
				{
					var vMultiplier:Number = 1;
					break;
				}
				case Align.CENTER:
				case VerticalAlign.MIDDLE:
				{
					vMultiplier = 0.5;
					break;
				}
				default:
				{
					vMultiplier = 0;
					break;
				}
			}
			
			content.x = lastOriginX + paddingH + (paddedSourceWidth - content.width) * hMultiplier;
			content.y = lastOriginY + paddingV + (paddedSourceHeight - content.height) * vMultiplier;
		}

		protected function content_resizeHandler():void
		{
			layout();
		}

		protected function stage_enterFrameHandler():void
		{
			source.getBounds(PopUpManager.root, HELPER_RECT);
			if (HELPER_RECT.x != lastOriginX || 
				HELPER_RECT.y != lastOriginY ||
				HELPER_RECT.width != lastOriginWidth ||
				HELPER_RECT.height != lastOriginHeight)
			{
				layout(HELPER_RECT);
			}
		}

		public function dispose():void
		{
			close();
		}
	}
}