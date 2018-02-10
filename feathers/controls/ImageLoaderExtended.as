package feathers.controls
{
	import com.esidegallery.enums.ScaleMode;
	import com.esidegallery.utils.ImageUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Image;
	import starling.display.Quad;
	import starling.utils.RectangleUtil;
	import starling.utils.ScaleMode;
	
	public class ImageLoaderExtended extends ImageLoader
	{
		private static const INVALIDATION_FLAG_TEXTURE_PREFERRED_SIZE:String = "texturePreferredSize";
		
		private static const HELPER_RECTANGLE:Rectangle = new Rectangle;
		private static const HELPER_RECTANGLE2:Rectangle = new Rectangle;
		
		public static var maxTextureDimensions:int = 4096;	
		
		protected var _textureScaleMultiplierX:Number = 1;
		protected var _textureScaleMultiplierY:Number = 1;
		
		private var _texturePreferredWidth:Number = NaN;
		public function get texturePreferredWidth():Number
		{
			return _texturePreferredWidth;
		}
		public function set texturePreferredWidth(value:Number):void
		{
			if (_texturePreferredWidth != value)
			{
				_texturePreferredWidth = value;
				invalidate(INVALIDATION_FLAG_TEXTURE_PREFERRED_SIZE);			
			}
		}

		private var _texturePreferredHeight:Number = NaN;
		public function get texturePreferredHeight():Number
		{
			return _texturePreferredHeight;
		}
		public function set texturePreferredHeight(value:Number):void
		{
			if (_texturePreferredHeight != value)
			{
				_texturePreferredHeight = value;
				invalidate(INVALIDATION_FLAG_TEXTURE_PREFERRED_SIZE);			
			}
		}
		
		public function get internalImage():Image
		{
			return image;
		}

		protected function calculateTextureScaleMultipliers():void
		{
			var newX:Number;
			if (_texturePreferredWidth > 0 && _currentTextureWidth > 0)
				newX = _texturePreferredWidth / _currentTextureWidth;
			else
				newX = 1;
			
			var newY:Number;
			if (_texturePreferredHeight > 0 && _currentTextureHeight > 0)
				newY = _texturePreferredHeight / _currentTextureHeight;
			else
				newY = 1;
			
			if (_textureScaleMultiplierX != newX || _textureScaleMultiplierY != newY)
				invalidate(INVALIDATION_FLAG_SIZE);
			
			_textureScaleMultiplierX = newX;
			_textureScaleMultiplierY = newY;
		}
		
		override protected function draw():void
		{
			if (isInvalid(INVALIDATION_FLAG_TEXTURE_PREFERRED_SIZE))
				calculateTextureScaleMultipliers();
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
		
		override protected function loader_completeHandler(event:flash.events.Event):void
		{
			var bitmap:Bitmap = Bitmap(this.loader.content);
			this.cleanupLoaders(false);
			
			var bitmapData:BitmapData = bitmap.bitmapData;
			if (bitmapData.width > maxTextureDimensions || bitmapData.height > maxTextureDimensions)
				bitmapData = ImageUtils.resize(bitmapData, maxTextureDimensions, maxTextureDimensions, com.esidegallery.enums.ScaleMode.MAINTAIN_RATIO);
			
			//if the upload is synchronous, attempt to reuse the existing
			//texture so that we don't need to create a new one.
			//when AIR-4198247 is fixed in a stable build, this can be removed
			//(perhaps with some kind of AIR version detection, though)
			var canReuseTexture:Boolean =
				this._texture !== null &&
				(!this._asyncTextureUpload || this._texture.root.uploadBitmapData.length === 1) &&
				this._texture.nativeWidth === bitmapData.width &&
				this._texture.nativeHeight === bitmapData.height &&
				this._texture.scale === this.scaleFactor &&
				this._texture.format === this.textureFormat;
			if(!canReuseTexture)
			{
				this.cleanupTexture();
			}
			if(this._delayTextureCreation && !this._isRestoringTexture)
			{
				this._pendingBitmapDataTexture = bitmapData;
				if(this._textureQueueDuration < Number.POSITIVE_INFINITY)
				{
					this.addToTextureQueue();
				}
			}
			else
			{
				this.replaceBitmapDataTexture(bitmapData);
			}
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
	}
}