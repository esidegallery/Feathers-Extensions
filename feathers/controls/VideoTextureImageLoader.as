package feathers.controls
{
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.utils.drawToBitmapData;

	import flash.display.BitmapData;
	import flash.display3D.textures.VideoTexture;
	import flash.geom.Rectangle;

	import starling.display.Image;
	import starling.display.Quad;
	import starling.textures.RenderTexture;
	import starling.textures.Texture;
	import starling.utils.RectangleUtil;

	/**
	 * ImageLoader designed for displaying VideoPlayer textures.
	 * Supports setting of actual video display dimensions for aspect correction,
	 * plus the ability to freeze frame (via a RenderTexture) to facilitate seamless looping.
	 */
	public class VideoTextureImageLoader extends ImageLoader
	{
		private static const HELPER_RECTANGLE:Rectangle = new Rectangle;
		private static const HELPER_RECTANGLE2:Rectangle = new Rectangle;

		private var _videoSource:Texture;
		override public function get source():Object
		{
			if (_videoSource != null)
			{
				return _videoSource;
			}
			validate();
			return super.source;
		}
		override public function set source(value:Object):void
		{
			disposeRenderTexture();

			if (!value)
			{
				_videoSource = null;
				super.source = value;
				return;
			}

			if (!(value is Texture) || !((value as Texture).base is VideoTexture))
			{
				throw new Error("VideoTextureImageLoader only supports VideoPlayer textures.");
			}

			_videoSource = value as Texture;
			refreshCurrentTexture();
		}

		private var _videoDisplayWidth:int;
		public function get videoDisplayWidth():int
		{
			return _videoDisplayWidth;
		}
		public function set videoDisplayWidth(value:int):void
		{
			if (_videoDisplayWidth == value)
			{
				return;
			}
			_videoDisplayWidth = value;
			if (_videoSource == null)
			{
				return;
			}
			invalidate(INVALIDATION_FLAG_LAYOUT);
		}

		private var _videoDisplayHeight:int;
		public function get videoDisplayHeight():int
		{
			return _videoDisplayHeight;
		}
		public function set videoDisplayHeight(value:int):void
		{
			if (_videoDisplayHeight == value)
			{
				return;
			}
			_videoDisplayHeight = value;
			if (_videoSource == null)
			{
				return;
			}
			invalidate(INVALIDATION_FLAG_LAYOUT);
		}

		protected var _renderTexture:RenderTexture;

		/**
		 * To be called on VideoPlayer's clear event, to ensure the no-longer-valid
		 * video texture will no longer be displayed. Will not clear the RenderTexture if being shown.
		 */
		public function clear():void
		{
			_videoSource = null;
			refreshImageSource();
		}

		/**
		 * Draws the current frame to a RenderTexture,
		 * which will be automatically disposed of.
		 */
		public function freezeFrame():void
		{
			disposeRenderTexture();
			if (_videoSource == null || _videoSource.width == 0 || _videoSource.height == 0)
			{
				return;
			}

			var image:Image = new Image(_videoSource);
			_renderTexture = new RenderTexture(image.width, image.height);
			_renderTexture.draw(image);
			image.dispose();

			refreshImageSource();
		}

		protected function refreshImageSource():void
		{
			super.source = _renderTexture || _videoSource;
		}

		override protected function autoSizeIfNeeded():Boolean
		{
			var needsWidth:Boolean = _explicitWidth != _explicitWidth; // isNaN
			var needsHeight:Boolean = _explicitHeight != _explicitHeight; // isNaN
			var needsMinWidth:Boolean = _explicitMinWidth != _explicitMinWidth; // isNaN
			var needsMinHeight:Boolean = _explicitMinHeight != _explicitMinHeight; // isNaN
			if (!needsWidth && !needsHeight && !needsMinWidth && !needsMinHeight)
			{
				return false;
			}

			var sourceWidth:Number = _videoDisplayWidth || _currentTextureWidth || NaN;
			var sourceHeight:Number = _videoDisplayHeight || _currentTextureHeight || NaN;

			var heightScale:Number = 1;
			var widthScale:Number = 1;
			var textureScaleX:Number = textureScale;
			var textureScaleY:Number = textureScale;
			if (scaleContent && maintainAspectRatio &&
					scaleMode != starling.utils.ScaleMode.NONE &&
					scale9Grid == null)
			{
				if (!needsHeight)
				{
					heightScale = _explicitHeight / (sourceHeight * textureScaleY);
				}
				else if (_explicitMaxHeight < sourceHeight)
				{
					heightScale = _explicitMaxHeight / (sourceHeight * textureScaleY);
				}
				else if (_explicitMinHeight > sourceHeight)
				{
					heightScale = _explicitMinHeight / (sourceHeight * textureScaleY);
				}
				if (!needsWidth)
				{
					widthScale = _explicitWidth / (sourceWidth * textureScaleX);
				}
				else if (_explicitMaxWidth < sourceWidth)
				{
					widthScale = _explicitMaxWidth / (sourceWidth * textureScaleX);
				}
				else if (_explicitMinWidth > sourceWidth)
				{
					widthScale = _explicitMinWidth / (sourceWidth * textureScaleX);
				}
			}

			var newWidth:Number = _explicitWidth;
			if (needsWidth)
			{
				if (sourceWidth == sourceWidth) // !isNaN
				{
					newWidth = sourceWidth * textureScaleX * heightScale;
				}
				else
				{
					newWidth = 0;
				}
				newWidth += _paddingLeft + _paddingRight;
			}

			var newHeight:Number = _explicitHeight;
			if (needsHeight)
			{
				if (sourceHeight == sourceHeight) // !isNaN
				{
					newHeight = sourceHeight * textureScaleY * widthScale;
				}
				else
				{
					newHeight = 0;
				}
				newHeight += _paddingTop + _paddingBottom;
			}

			// This ensures that an ImageLoader can recover from width or height
			// being set to 0 by percentWidth or percentHeight
			if (needsHeight && needsMinHeight)
			{
				// If no height values are set, use the original texture width
				// for the minWidth
				heightScale = 1;
			}
			if (needsWidth && needsMinWidth)
			{
				// If no width values are set, use the original texture height
				// for the minHeight
				widthScale = 1;
			}

			var newMinWidth:Number = _explicitMinWidth;
			if (needsMinWidth)
			{
				if (sourceWidth == sourceWidth) // !isNaN
				{
					newMinWidth = sourceWidth * textureScaleX * heightScale;
				}
				else
				{
					newMinWidth = 0;
				}
				newMinWidth += _paddingLeft + _paddingRight;
			}

			var newMinHeight:Number = _explicitMinHeight;
			if (needsMinHeight)
			{
				if (sourceHeight == sourceHeight) // !isNaN
				{
					newMinHeight = sourceHeight * textureScaleY * widthScale;
				}
				else
				{
					newMinHeight = 0;
				}
				newMinHeight += _paddingTop + _paddingBottom;
			}

			return saveMeasurements(newWidth, newHeight, newMinWidth, newMinHeight);
		}

		override protected function layout():void
		{
			if (!image || !_currentTexture)
			{
				return;
			}
			if (scaleContent)
			{
				if (maintainAspectRatio && scale9Grid == null)
				{
					HELPER_RECTANGLE.x = 0;
					HELPER_RECTANGLE.y = 0;
					HELPER_RECTANGLE.width = (_videoDisplayWidth || _currentTextureWidth) * textureScale;
					HELPER_RECTANGLE.height = (_videoDisplayHeight || _currentTextureHeight) * textureScale;
					HELPER_RECTANGLE2.x = 0;
					HELPER_RECTANGLE2.y = 0;
					HELPER_RECTANGLE2.width = actualWidth - _paddingLeft - _paddingRight;
					HELPER_RECTANGLE2.height = actualHeight - _paddingTop - _paddingBottom;
					RectangleUtil.fit(HELPER_RECTANGLE, HELPER_RECTANGLE2, scaleMode, false, HELPER_RECTANGLE);
					image.x = HELPER_RECTANGLE.x + _paddingLeft;
					image.y = HELPER_RECTANGLE.y + _paddingTop;
					image.width = HELPER_RECTANGLE.width;
					image.height = HELPER_RECTANGLE.height;
				}
				else
				{
					image.x = _paddingLeft;
					image.y = _paddingTop;
					image.width = actualWidth - _paddingLeft - _paddingRight;
					image.height = actualHeight - _paddingTop - _paddingBottom;
				}
			}
			else
			{
				var imageWidth:Number = (_videoDisplayWidth || _currentTextureWidth) * textureScale;
				var imageHeight:Number = (_videoDisplayHeight || _currentTextureHeight) * textureScale;
				if (_horizontalAlign == HorizontalAlign.RIGHT)
				{
					image.x = actualWidth - _paddingRight - imageWidth;
				}
				else if (_horizontalAlign == HorizontalAlign.CENTER)
				{
					image.x = _paddingLeft + ((actualWidth - _paddingLeft - _paddingRight) - imageWidth) / 2;
				}
				else // left
				{
					image.x = _paddingLeft;
				}
				if (_verticalAlign == VerticalAlign.BOTTOM)
				{
					image.y = actualHeight - _paddingBottom - imageHeight;
				}
				else if (_verticalAlign == VerticalAlign.MIDDLE)
				{
					image.y = _paddingTop + ((actualHeight - _paddingTop - _paddingBottom) - imageHeight) / 2;
				}
				else // top
				{
					image.y = _paddingTop;
				}
				image.width = imageWidth;
				image.height = imageHeight;
			}
			if ((!scaleContent || (maintainAspectRatio && scaleMode != starling.utils.ScaleMode.SHOW_ALL)) &&
					(actualWidth != imageWidth || actualHeight != imageHeight))
			{
				var mask:Quad = image.mask as Quad;
				if (mask != null)
				{
					mask.x = 0;
					mask.y = 0;
					mask.width = actualWidth;
					mask.height = actualHeight;
				}
				else
				{
					mask = new Quad(1, 1, 0xff00ff);
					// The initial dimensions cannot be 0 or there's a runtime error,
					// and these values might be 0
					mask.width = actualWidth;
					mask.height = actualHeight;
					image.mask = mask;
					addChild(mask);
				}
			}
			else
			{
				mask = image.mask as Quad;
				if (mask != null)
				{
					mask.removeFromParent(true);
					image.mask = null;
				}
			}
		}

		override public function drawToBitmapData(out:BitmapData = null, color:uint = 0, alpha:Number = 0.0):BitmapData
		{
			return feathers.utils.drawToBitmapData(this, out, color, alpha);
		}

		protected function disposeRenderTexture():void
		{
			if (_renderTexture == null)
			{
				return;
			}
			_renderTexture.dispose();
			_renderTexture = null;
		}

		override public function dispose():void
		{
			disposeRenderTexture();
			super.dispose();
		}
	}
}