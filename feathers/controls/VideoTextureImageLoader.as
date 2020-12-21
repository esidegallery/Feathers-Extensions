package feathers.controls
{
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;

	import flash.display.BitmapData;
	import flash.display3D.textures.VideoTexture;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.Quad;
	import starling.display.Stage;
	import starling.rendering.Painter;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.Pool;
	import starling.utils.RectangleUtil;

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
			if (_videoSource == value)
			{
				return;
			}
			if (value != null && value is Texture && (value as Texture).base is VideoTexture)
			{
				_videoSource = value as Texture;
				invalidate(INVALIDATION_FLAG_VIDEO_SOURCE);
				return;
			}

			_textureScaleMultiplierX = 1;
			_textureScaleMultiplierY = 1;
			super.source = value;
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

		protected var _textureScaleMultiplierX:Number = 1;
		protected var _textureScaleMultiplierY:Number = 1;

		override protected function draw():void
		{
			var videoTextureInvalid:Boolean = isInvalid(INVALIDATION_FLAG_VIDEO_SOURCE);
			if (videoTextureInvalid)
			{
				commitVideoTexture();
			}

			super.draw();
		}

		protected function commitVideoTexture():void
		{
			_textureScaleMultiplierX = 1;
			_textureScaleMultiplierY = 1;

			if (_videoSource == null)
			{
				return;
			}

			if (_videoDisplayHeight > 0 && _videoCodedHeight > 0 && _videoDisplayHeight != _videoCodedHeight)
			{
				var cropRect:Rectangle = Pool.getRectangle(0, 0, _videoSource.width, _videoSource.height - (_videoCodedHeight - _videoDisplayHeight));
				var newSource:Texture = Texture.fromTexture(_videoSource, cropRect);
				Pool.putRectangle(cropRect);
			}
			else
			{
				newSource = _videoSource;
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
			super.source = newSource;
		}

		override protected function autoSizeIfNeeded():Boolean
		{
			var needsWidth:Boolean = this._explicitWidth !== this._explicitWidth; //isNaN
			var needsHeight:Boolean = this._explicitHeight !== this._explicitHeight; //isNaN
			var needsMinWidth:Boolean = this._explicitMinWidth !== this._explicitMinWidth; //isNaN
			var needsMinHeight:Boolean = this._explicitMinHeight !== this._explicitMinHeight; //isNaN
			if(!needsWidth && !needsHeight && !needsMinWidth && !needsMinHeight)
			{
				return false;
			}
			
			var heightScale:Number = 1;
			var widthScale:Number = 1;
			var textureScaleX:Number = textureScale * _textureScaleMultiplierX;
			var textureScaleY:Number = textureScale * _textureScaleMultiplierY;
			if(this.scaleContent && this.maintainAspectRatio &&
				this.scaleMode !== starling.utils.ScaleMode.NONE &&
				this.scale9Grid === null)
			{
				if(!needsHeight)
				{
					heightScale = this._explicitHeight / (this._currentTextureHeight * textureScaleY);
				}
				else if(this._explicitMaxHeight < this._currentTextureHeight)
				{
					heightScale = this._explicitMaxHeight / (this._currentTextureHeight * textureScaleY);
				}
				else if(this._explicitMinHeight > this._currentTextureHeight)
				{
					heightScale = this._explicitMinHeight / (this._currentTextureHeight * textureScaleY);
				}
				if(!needsWidth)
				{
					widthScale = this._explicitWidth / (this._currentTextureWidth * textureScaleX);
				}
				else if(this._explicitMaxWidth < this._currentTextureWidth)
				{
					widthScale = this._explicitMaxWidth / (this._currentTextureWidth * textureScaleX);
				}
				else if(this._explicitMinWidth > this._currentTextureWidth)
				{
					widthScale = this._explicitMinWidth / (this._currentTextureWidth * textureScaleX);
				}
			}
			
			var newWidth:Number = this._explicitWidth;
			if(needsWidth)
			{
				if(this._currentTextureWidth === this._currentTextureWidth) //!isNaN
				{
					newWidth = this._currentTextureWidth * textureScaleX * heightScale;
				}
				else
				{
					newWidth = 0;
				}
				newWidth += this._paddingLeft + this._paddingRight;
			}
			
			var newHeight:Number = this._explicitHeight;
			if(needsHeight)
			{
				if(this._currentTextureHeight === this._currentTextureHeight) //!isNaN
				{
					newHeight = this._currentTextureHeight * textureScaleY * widthScale;
				}
				else
				{
					newHeight = 0;
				}
				newHeight += this._paddingTop + this._paddingBottom;
			}
			
			//this ensures that an ImageLoader can recover from width or height
			//being set to 0 by percentWidth or percentHeight
			if(needsHeight && needsMinHeight)
			{
				//if no height values are set, use the original texture width
				//for the minWidth
				heightScale = 1;
			}
			if(needsWidth && needsMinWidth)
			{
				//if no width values are set, use the original texture height
				//for the minHeight
				widthScale = 1;
			}
			
			var newMinWidth:Number = this._explicitMinWidth;
			if(needsMinWidth)
			{
				if(this._currentTextureWidth === this._currentTextureWidth) //!isNaN
				{
					newMinWidth = this._currentTextureWidth * textureScaleX * heightScale;
				}
				else
				{
					newMinWidth = 0;
				}
				newMinWidth += this._paddingLeft + this._paddingRight;
			}
			
			var newMinHeight:Number = this._explicitMinHeight;
			if(needsMinHeight)
			{
				if(this._currentTextureHeight === this._currentTextureHeight) //!isNaN
				{
					newMinHeight = this._currentTextureHeight * textureScaleY * widthScale;
				}
				else
				{
					newMinHeight = 0;
				}
				newMinHeight += this._paddingTop + this._paddingBottom;
			}
			
			return this.saveMeasurements(newWidth, newHeight, newMinWidth, newMinHeight);
		}

		override protected function layout():void
		{
			if(!this.image || !this._currentTexture)
			{
				return;
			}
			if(this.scaleContent)
			{
				if(this.maintainAspectRatio && this.scale9Grid === null)
				{
					HELPER_RECTANGLE.x = 0;
					HELPER_RECTANGLE.y = 0;
					HELPER_RECTANGLE.width = this._currentTextureWidth * this.textureScale * this._textureScaleMultiplierX;
					HELPER_RECTANGLE.height = this._currentTextureHeight * this.textureScale * this._textureScaleMultiplierY;
					HELPER_RECTANGLE2.x = 0;
					HELPER_RECTANGLE2.y = 0;
					HELPER_RECTANGLE2.width = this.actualWidth - this._paddingLeft - this._paddingRight;
					HELPER_RECTANGLE2.height = this.actualHeight - this._paddingTop - this._paddingBottom;
					RectangleUtil.fit(HELPER_RECTANGLE, HELPER_RECTANGLE2, this.scaleMode, false, HELPER_RECTANGLE);
					this.image.x = HELPER_RECTANGLE.x + this._paddingLeft;
					this.image.y = HELPER_RECTANGLE.y + this._paddingTop;
					this.image.width = HELPER_RECTANGLE.width;
					this.image.height = HELPER_RECTANGLE.height;
				}
				else
				{
					this.image.x = this._paddingLeft;
					this.image.y = this._paddingTop;
					this.image.width = this.actualWidth - this._paddingLeft - this._paddingRight;
					this.image.height = this.actualHeight - this._paddingTop - this._paddingBottom;
				}
			}
			else
			{
				var imageWidth:Number = this._currentTextureWidth * this.textureScale * this._textureScaleMultiplierX;
				var imageHeight:Number = this._currentTextureHeight * this.textureScale * this._textureScaleMultiplierY;
				if(this._horizontalAlign === HorizontalAlign.RIGHT)
				{
					this.image.x = this.actualWidth - this._paddingRight - imageWidth;
				}
				else if(this._horizontalAlign === HorizontalAlign.CENTER)
				{
					this.image.x = this._paddingLeft + ((this.actualWidth - this._paddingLeft - this._paddingRight) - imageWidth) / 2;
				}
				else //left
				{
					this.image.x = this._paddingLeft;
				}
				if(this._verticalAlign === VerticalAlign.BOTTOM)
				{
					this.image.y = this.actualHeight - this._paddingBottom - imageHeight;
				}
				else if(this._verticalAlign === VerticalAlign.MIDDLE)
				{
					this.image.y = this._paddingTop + ((this.actualHeight - this._paddingTop - this._paddingBottom) - imageHeight) / 2;
				}
				else //top
				{
					this.image.y = this._paddingTop;
				}
				this.image.width = imageWidth;
				this.image.height = imageHeight;
			}
			if((!this.scaleContent || (this.maintainAspectRatio && this.scaleMode !== starling.utils.ScaleMode.SHOW_ALL)) &&
				(this.actualWidth != imageWidth || this.actualHeight != imageHeight))
			{
				var mask:Quad = this.image.mask as Quad;
				if(mask !== null)
				{
					mask.x = 0;
					mask.y = 0;
					mask.width = this.actualWidth;
					mask.height = this.actualHeight;
				}
				else
				{
					mask = new Quad(1, 1, 0xff00ff);
					//the initial dimensions cannot be 0 or there's a runtime error,
					//and these values might be 0
					mask.width = this.actualWidth;
					mask.height = this.actualHeight;
					this.image.mask = mask;
					this.addChild(mask);
				}
			}
			else
			{
				mask = this.image.mask as Quad;
				if(mask !== null)
				{
					mask.removeFromParent(true);
					this.image.mask = null;
				}
			}
		}

		override public function drawToBitmapData(out:BitmapData = null, color:uint = 0, alpha:Number = 0.0):BitmapData
		{
			var painter:Painter = Starling.painter;
            var stage:Stage = Starling.current.stage;
            var viewPort:Rectangle = Starling.current.viewPort;
            var stageWidth:Number  = stage.stageWidth;
            var stageHeight:Number = stage.stageHeight;
            var scaleX:Number = viewPort.width  / stageWidth;
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

                out ||= new BitmapData(painter.backBufferWidth  * backBufferScale,
                                       painter.backBufferHeight * backBufferScale);
            }
            else
            {
                bounds = getBounds(parent, HELPER_RECTANGLE);
                projectionX = bounds.x;
                projectionY = bounds.y;

                out ||= new BitmapData(Math.ceil(bounds.width  * totalScaleX),
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
            var stepWidth:Number  = painter.backBufferWidth  / scaleX;
            var stepHeight:Number = painter.backBufferHeight / scaleY;
            var positionInBitmap:Point = Pool.getPoint(0, 0);
            var boundsInBuffer:Rectangle = Pool.getRectangle(0, 0,
                    painter.backBufferWidth  * backBufferScale,
                    painter.backBufferHeight * backBufferScale);

            while (positionInBitmap.y < out.height)
            {
                stepX = projectionX;
                positionInBitmap.x = 0;
				
                while (positionInBitmap.x < out.width)
                {					
                    painter.clear(color, alpha);
                    painter.state.setProjectionMatrix(stepX, stepY, stepWidth, stepHeight,
                        stageWidth, stageHeight, stage.cameraPosition);

                    if (mask)   painter.drawMask(mask, this);

                    if (filter) filter.render(painter);
                    else         render(painter);

                    if (mask)   painter.eraseMask(mask, this);

                    painter.finishMeshBatch();
                    //line 478 - for some reason the bitmapdata is distorted depending the size of the stageHeight and stageWidth on windows. Throwing in an additional bitmapdata and using copyPixels method fixes it.
					var bmd:BitmapData = new BitmapData(stepWidth, stepHeight, true, 0x00ffffff);
					painter.context.drawToBitmapData(bmd, boundsInBuffer);
					out.copyPixels(bmd, boundsInBuffer,positionInBitmap);

                    stepX += stepWidth;
                    positionInBitmap.x += stepWidth * totalScaleX;
                }
                stepY += stepHeight;
                positionInBitmap.y += stepHeight * totalScaleY;
            }

            painter.popState();

            Pool.putRectangle(boundsInBuffer);
            Pool.putPoint(positionInBitmap);

            return out;
		}
	}
}