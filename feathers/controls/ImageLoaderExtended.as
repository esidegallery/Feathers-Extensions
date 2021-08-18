package feathers.controls
{
	import com.esidegallery.enums.ScaleMode;
	import com.esidegallery.utils.IHasUID;
	import com.esidegallery.utils.ImageUtils;
	import com.esidegallery.utils.UIDUtils;

	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.utils.textures.TextureCache;
	import feathers.utils.textures.TextureCacheExtended;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import org.osflash.signals.Promise;

	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Stage;
	import starling.rendering.Painter;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.Pool;
	import starling.utils.RectangleUtil;
	import starling.utils.ScaleMode;
	
	public class ImageLoaderExtended extends ImageLoader implements IHasUID
	{
		protected static const INVALIDATION_FLAG_TEXTURE_PREFERRED_SIZE:String = "texturePreferredSize";
		
		private static const HELPER_RECTANGLE:Rectangle = new Rectangle;
		private static const HELPER_RECTANGLE2:Rectangle = new Rectangle;

		private var _uid:String;
		public function get uid():String
		{
			return _uid ||= UIDUtils.generateUID(this);
		}
		public function set uid(value:String):void
		{
			_uid = value;
		}
		
		/** 
		 * If the source is set to a Promise, by default the previous image is cleared while waiting for promise to dispatch.
		 * Setting this flag keeps the previous image intil that happens.
		 */
		public var keepPreviousSourceUntilPromiseLoaded:Boolean = false;
		
		protected var _texturePreferredWidth:Number = NaN;
		public function get texturePreferredWidth():Number
		{
			return _texturePreferredWidth;
		}
		public function set texturePreferredWidth(value:Number):void
		{
			if (_texturePreferredWidth == value)
			{
				return;
			}
			_texturePreferredWidth = value;
			invalidate(INVALIDATION_FLAG_TEXTURE_PREFERRED_SIZE);			
		}
		
		protected var _texturePreferredHeight:Number = NaN;
		public function get texturePreferredHeight():Number
		{
			return _texturePreferredHeight;
		}
		public function set texturePreferredHeight(value:Number):void
		{
			if (_texturePreferredHeight == value)
			{
				return;
			}
			_texturePreferredHeight = value;
			invalidate(INVALIDATION_FLAG_TEXTURE_PREFERRED_SIZE);			
		}
		
		protected var _textureScaleMultiplierX:Number = 1;
		protected var _textureScaleMultiplierY:Number = 1;
		
		protected var _sourcePromise:Promise;
		
		/**
		 * If set as an <code>ImageLoaderExtendedVO</code>, its properties are instantly resolved to those of 
		 * <code>ImageLoaderExtended</code> with the same name.<br/>
		 * If set as a <code>Promise</code>, the promise is kept as the source until it is dispatched, 
		 * upon which the source is set to its payload.
		 */
		override public function get source():Object
		{
			if (super.source != null)
			{
				return super.source;
			}
			return _sourcePromise;
		}
		override public function set source(value:Object):void
		{
			disposeSourcePromise();
			if (value is ImageLoaderExtendedVO)
			{
				var ilevo:ImageLoaderExtendedVO = value as ImageLoaderExtendedVO;
				texturePreferredWidth = ilevo.texturePreferredWidth;
				texturePreferredHeight = ilevo.texturePreferredHeight;
				super.source = ilevo.source;
			}
			else if (value is Promise)
			{
				_sourcePromise = value as Promise; 
				if (!_sourcePromise.isDispatched && !keepPreviousSourceUntilPromiseLoaded)
				{
					super.source = null;
				}
				_sourcePromise.addOnce(sourcePromiseHandler);
			}
			else
			{
				super.source = value;
			}
		}
		
		override public function set textureCache(value:TextureCache):void
		{
			if (value is TextureCacheExtended && (value as TextureCacheExtended).isDisposed)
			{
				super.textureCache = null;
			}
			else
			{
				super.textureCache = value;
			}
		}
		
		protected function sourcePromiseHandler(value:Object):void
		{
			_sourcePromise = null;
			source = value;
			validate();
		}
		
		public function get internalImage():Image
		{
			return image;
		}
		
		protected function calculateTextureScaleMultipliers():void
		{
			var newX:Number;
			if (_texturePreferredWidth > 0 && _currentTextureWidth > 0)
			{
				newX = _texturePreferredWidth / _currentTextureWidth;
			}
			else
			{
				newX = 1;
			}
			
			var newY:Number;
			if (_texturePreferredHeight > 0 && _currentTextureHeight > 0)
			{
				newY = _texturePreferredHeight / _currentTextureHeight;
			}
			else
			{
				newY = 1;
			}
			
			if (_textureScaleMultiplierX != newX || _textureScaleMultiplierY != newY)
			{
				invalidate(INVALIDATION_FLAG_SIZE);
			}
			
			_textureScaleMultiplierX = newX;
			_textureScaleMultiplierY = newY;
		}
		
		override protected function draw():void
		{
			var texturePreserredSizeInvalid:Boolean = isInvalid(INVALIDATION_FLAG_TEXTURE_PREFERRED_SIZE);
			if (texturePreserredSizeInvalid)
			{
				calculateTextureScaleMultipliers();
			}
			super.draw();
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

		override public function drawToBitmapData(out:flash.display.BitmapData = null, color:uint = 0, alpha:Number = 0.0):flash.display.BitmapData
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
		
		override protected function loader_completeHandler(event:flash.events.Event):void
		{
			var bitmapData:BitmapData = Bitmap(this.loader.content).bitmapData;
			if (bitmapData.width > Texture.maxSize || bitmapData.height > Texture.maxSize)
			{
				Bitmap(this.loader.content).bitmapData = ImageUtils.resize(bitmapData, Texture.maxSize, Texture.maxSize, com.esidegallery.enums.ScaleMode.FIT);
			}
			super.loader_completeHandler(event);
		}
		
		override protected function refreshCurrentTexture():void
		{
			super.refreshCurrentTexture();
			calculateTextureScaleMultipliers();
		}
		
		override protected function cleanupTexture():void
		{
			super.cleanupTexture();
			calculateTextureScaleMultipliers();
		}
		
		public function disposeSourcePromise():void
		{
			if (_sourcePromise == null)
			{
				return;
			}
			_sourcePromise.remove(sourcePromiseHandler);
			_sourcePromise = null;
		}
		
		override public function dispose():void
		{
			disposeSourcePromise();
			super.dispose();
		}
	}
}