package feathers.controls
{
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;

	import flash.display.BitmapData;
	import flash.display3D.textures.VideoTexture;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Stage;
	import starling.rendering.Painter;
	import starling.textures.RenderTexture;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.Pool;
	import starling.utils.RectangleUtil;

	/**
	 * ImageLoader designed for displaying VideoPlayer textures.
	 * Supports setting of video display dimensions and coded height for aspect correction,
	 * plus the ability to freeze frame (via a RenderTexture) to facilitate seamless looping.
	 */
	public class VideoTextureImageLoader extends ImageLoader
	{
		private static const INVALIDATION_FLAG_VIDEO_SOURCE:String = "videoSource";

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
			if (_renderTexture != null)
			{
				// If renderTexture exists, then it takes precedence over videoSource:
				disposeRenderTexture();
			}
			else if (_videoSource == value)
			{
				return;
			}

			if (value != null && value is Texture && (value as Texture).base is VideoTexture)
			{
				_videoSource = value as Texture;
			}
			else
			{
				super.source = value;
			}

			invalidate(INVALIDATION_FLAG_VIDEO_SOURCE);
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
			invalidate(INVALIDATION_FLAG_VIDEO_SOURCE);
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
			invalidate(INVALIDATION_FLAG_VIDEO_SOURCE);
		}

		private var _videoCodedHeight:int;
		public function get videoCodedHeight():int
		{
			return _videoCodedHeight;
		}
		public function set videoCodedHeight(value:int):void
		{
			if (_videoCodedHeight == value)
			{
				return;
			}
			_videoCodedHeight = value;
			if (_videoSource == null)
			{
				return;
			}
			invalidate(INVALIDATION_FLAG_VIDEO_SOURCE);
		}

		protected var _renderTexture:RenderTexture;
		protected var _textureScaleMultiplierX:Number = 1;
		protected var _textureScaleMultiplierY:Number = 1;

		/**
		 * To be called on VideoPlayer's clear event, to ensure the no-longer-valid
		 * video texture will no longer be displayed. Will not clear the RenderTexture if being shown.
		 */
		public function clear():void
		{
			if (_videoSource == null)
			{
				return;
			}
			_videoSource = null;
			invalidate(INVALIDATION_FLAG_VIDEO_SOURCE);
			validate();
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

			invalidate(INVALIDATION_FLAG_VIDEO_SOURCE);
			validate();
		}

		override protected function draw():void
		{
			var videoSourceInvalid:Boolean = isInvalid(INVALIDATION_FLAG_VIDEO_SOURCE);
			if (videoSourceInvalid)
			{
				commitVideoSource();
			}

			super.draw();
		}

		protected function commitVideoSource():void
		{
			_textureScaleMultiplierX = 1;
			_textureScaleMultiplierY = 1;

			var newSource:Texture = _renderTexture || _videoSource;

			if (newSource == null)
			{
				return;
			}

			if (_videoDisplayHeight > 0 && _videoCodedHeight > 0 && _videoDisplayHeight != _videoCodedHeight)
			{
				var cropRect:Rectangle = Pool.getRectangle(0, 0, newSource.width, newSource.height - (_videoCodedHeight - _videoDisplayHeight));
				newSource = Texture.fromTexture(newSource, cropRect);
				Pool.putRectangle(cropRect);
			}

			if (_videoDisplayWidth > 0)
			{
				_textureScaleMultiplierX = _videoDisplayWidth / newSource.width;
			}
			if (_videoDisplayHeight > 0)
			{
				_textureScaleMultiplierY = _videoDisplayHeight / newSource.height;
			}

			setInvalidationFlag(INVALIDATION_FLAG_DATA);
			// Note that newSource may be a cropped subtexture of videoSource or renderTexture,
			// not necessarily the textures themselves:
			super.source = newSource;
		}

		override protected function autoSizeIfNeeded():Boolean
		{
			var needsWidth:Boolean = _explicitWidth !== _explicitWidth; // isNaN
			var needsHeight:Boolean = _explicitHeight !== _explicitHeight; // isNaN
			var needsMinWidth:Boolean = _explicitMinWidth !== _explicitMinWidth; // isNaN
			var needsMinHeight:Boolean = _explicitMinHeight !== _explicitMinHeight; // isNaN
			if (!needsWidth && !needsHeight && !needsMinWidth && !needsMinHeight)
			{
				return false;
			}

			var heightScale:Number = 1;
			var widthScale:Number = 1;
			var textureScaleX:Number = textureScale * _textureScaleMultiplierX;
			var textureScaleY:Number = textureScale * _textureScaleMultiplierY;
			if (scaleContent && maintainAspectRatio &&
					scaleMode !== starling.utils.ScaleMode.NONE &&
					scale9Grid === null)
			{
				if (!needsHeight)
				{
					heightScale = _explicitHeight / (_currentTextureHeight * textureScaleY);
				}
				else if (_explicitMaxHeight < _currentTextureHeight)
				{
					heightScale = _explicitMaxHeight / (_currentTextureHeight * textureScaleY);
				}
				else if (_explicitMinHeight > _currentTextureHeight)
				{
					heightScale = _explicitMinHeight / (_currentTextureHeight * textureScaleY);
				}
				if (!needsWidth)
				{
					widthScale = _explicitWidth / (_currentTextureWidth * textureScaleX);
				}
				else if (_explicitMaxWidth < _currentTextureWidth)
				{
					widthScale = _explicitMaxWidth / (_currentTextureWidth * textureScaleX);
				}
				else if (_explicitMinWidth > _currentTextureWidth)
				{
					widthScale = _explicitMinWidth / (_currentTextureWidth * textureScaleX);
				}
			}

			var newWidth:Number = _explicitWidth;
			if (needsWidth)
			{
				if (_currentTextureWidth === _currentTextureWidth) // !isNaN
				{
					newWidth = _currentTextureWidth * textureScaleX * heightScale;
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
				if (_currentTextureHeight === _currentTextureHeight) // !isNaN
				{
					newHeight = _currentTextureHeight * textureScaleY * widthScale;
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
				if (_currentTextureWidth === _currentTextureWidth) // !isNaN
				{
					newMinWidth = _currentTextureWidth * textureScaleX * heightScale;
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
				if (_currentTextureHeight === _currentTextureHeight) // !isNaN
				{
					newMinHeight = _currentTextureHeight * textureScaleY * widthScale;
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
				if (maintainAspectRatio && scale9Grid === null)
				{
					HELPER_RECTANGLE.x = 0;
					HELPER_RECTANGLE.y = 0;
					HELPER_RECTANGLE.width = _currentTextureWidth * textureScale * _textureScaleMultiplierX;
					HELPER_RECTANGLE.height = _currentTextureHeight * textureScale * _textureScaleMultiplierY;
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
				var imageWidth:Number = _currentTextureWidth * textureScale * _textureScaleMultiplierX;
				var imageHeight:Number = _currentTextureHeight * textureScale * _textureScaleMultiplierY;
				if (_horizontalAlign === HorizontalAlign.RIGHT)
				{
					image.x = actualWidth - _paddingRight - imageWidth;
				}
				else if (_horizontalAlign === HorizontalAlign.CENTER)
				{
					image.x = _paddingLeft + ((actualWidth - _paddingLeft - _paddingRight) - imageWidth) / 2;
				}
				else // left
				{
					image.x = _paddingLeft;
				}
				if (_verticalAlign === VerticalAlign.BOTTOM)
				{
					image.y = actualHeight - _paddingBottom - imageHeight;
				}
				else if (_verticalAlign === VerticalAlign.MIDDLE)
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
			if ((!scaleContent || (maintainAspectRatio && scaleMode !== starling.utils.ScaleMode.SHOW_ALL)) &&
					(actualWidth != imageWidth || actualHeight != imageHeight))
			{
				var mask:Quad = image.mask as Quad;
				if (mask !== null)
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
				if (mask !== null)
				{
					mask.removeFromParent(true);
					image.mask = null;
				}
			}
		}

		override public function drawToBitmapData(out:BitmapData = null, color:uint = 0, alpha:Number = 0.0):BitmapData
		{
			var painter:Painter = Starling.painter;
			var stage:Stage = Starling.current.stage;
			var viewPort:Rectangle = Starling.current.viewPort;
			var stageWidth:Number = stage.stageWidth;
			var stageHeight:Number = stage.stageHeight;
			var scaleX:Number = viewPort.width / stageWidth;
			var scaleY:Number = viewPort.height / stageHeight;
			var backBufferScale:Number = painter.backBufferScaleFactor;
			var totalScaleX:Number = scaleX * backBufferScale;
			var totalScaleY:Number = scaleY * backBufferScale;
			var projectionX:Number, projectionY:Number;
			var bounds:Rectangle;

			if (this is Stage)
			{
				projectionX = viewPort.x < 0 ? -viewPort.x / scaleX : 0.0;
				projectionY = viewPort.y < 0 ? -viewPort.y / scaleY : 0.0;

				out ||= new BitmapData(
						painter.backBufferWidth * backBufferScale,
						painter.backBufferHeight * backBufferScale);
			}
			else
			{
				bounds = getBounds(parent, Pool.getRectangle());
				projectionX = bounds.x;
				projectionY = bounds.y;

				out ||= new BitmapData(
						Math.ceil(bounds.width * totalScaleX),
						Math.ceil(bounds.height * totalScaleY));
			}

			color = Color.multiply(color, alpha); // premultiply alpha

			painter.pushState();
			painter.setupContextDefaults();
			painter.state.renderTarget = null;
			painter.state.setModelviewMatricesToIdentity();
			painter.setStateTo(transformationMatrix);

			// Images that are bigger than the current back buffer are drawn in multiple steps.

			var stepX:Number;
			var stepY:Number = projectionY;
			var stepWidth:int = painter.backBufferWidth / scaleX;
			var stepHeight:int = painter.backBufferHeight / scaleY;
			var positionInBitmap:Point = Pool.getPoint(0, 0);
			var boundsInBuffer:Rectangle = Pool.getRectangle(
					0, 0,
					Math.floor(painter.backBufferWidth * backBufferScale),
					Math.floor(painter.backBufferHeight * backBufferScale));

			while (positionInBitmap.y < out.height)
			{
				stepX = projectionX;
				positionInBitmap.x = 0;

				while (positionInBitmap.x < out.width)
				{
					painter.clear(color, alpha);
					painter.state.setProjectionMatrix(
							stepX, stepY, stepWidth, stepHeight,
							stageWidth, stageHeight, stage.cameraPosition);

					if (mask)
					{
						painter.drawMask(mask, this);
					}

					if (filter)
					{
						filter.render(painter);
					}
					else
					{
						render(painter);
					}

					if (mask)
					{
						painter.eraseMask(mask, this);
					}

					painter.finishMeshBatch();
					// For some reason the bitmapdata is distorted depending the size of the stageHeight and stageWidth on windows. Throwing in an additional bitmapdata and using copyPixels method fixes it.
					var bmd:BitmapData = new BitmapData(Math.ceil(stepWidth * backBufferScale), Math.ceil(stepHeight * backBufferScale), true, 0x00ffffff);
					painter.context.drawToBitmapData(bmd, boundsInBuffer);
					out.copyPixels(bmd, boundsInBuffer, positionInBitmap);

					stepX += stepWidth;
					positionInBitmap.x += Math.floor(stepWidth * totalScaleX);
				}
				stepY += stepHeight;
				positionInBitmap.y += Math.floor(stepHeight * totalScaleY);
			}

			painter.popState();

			Pool.putRectangle(bounds);
			Pool.putRectangle(boundsInBuffer);
			Pool.putPoint(positionInBitmap);

			return out;
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