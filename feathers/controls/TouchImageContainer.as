package feathers.controls
{
	import flash.geom.Point;
	
	import feathers.events.FeathersEventType;
	import feathers.layout.TouchImageContainerLayout;
	import feathers.utils.display.calculateScaleRatioToFit;
	import feathers.utils.textures.TextureCache;
	import feathers.utils.touch.TouchSheet;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	public class TouchImageContainer extends ScrollContainer
	{
		public function TouchImageContainer()
		{
			super();
			layout = new TouchImageContainerLayout;
			hasElasticEdges = false;
		}
		
		private var _texturePreferredWidth:Number;
		public function get texturePreferredWidth():Number
		{
			return _texturePreferredWidth;
		}
		public function set texturePreferredWidth(value:Number):void
		{
			if (_texturePreferredWidth != value)
			{
				_texturePreferredWidth = value;
				invalidate(INVALIDATION_FLAG_DATA);
			}
		}

		private var _texturePreferredHeight:Number;
		public function get texturePreferredHeight():Number
		{
			return _texturePreferredHeight;
		}
		public function set texturePreferredHeight(value:Number):void
		{
			if (_texturePreferredHeight != value)
			{
				_texturePreferredHeight = value;
				invalidate(INVALIDATION_FLAG_DATA);
			}
		}
		
		private var _source:Object;
		public function get source():Object
		{
			return _source;
		}
		public function set source(value:Object):void
		{
			if (_source != value)
			{
				_source = value;
				invalidate(INVALIDATION_FLAG_DATA);
			}
		}

		private var _textureCache:TextureCache;
		public function get textureCache():TextureCache
		{
			return _textureCache;
		}
		public function set textureCache(value:TextureCache):void
		{
			_textureCache = value;
		}
		
		protected var touchSheet:TouchSheet = null;
		protected var image:ImageLoaderExtended = null;
		
		/**
		 * @private
		 * If the scale value is less than this after a zoom gesture ends, the
		 * scale will be animated back to this value. The default scale may be
		 * updated when a new texture is loaded.
		 */
		protected var _defaultScale:Number = 1;
		protected var _gestureCompleteTween:Tween = null;
		
		override public function hitTest(localPoint:Point):DisplayObject
		{
			var target:DisplayObject = super.hitTest(localPoint);
			if(target === this)
			{
				// The TouchSheet may not fill the entire width and height of
				// the item renderer, but we want the gestures to work from
				// anywhere within the item renderer's bounds.
				return this.touchSheet;
			}
			return target;
		}
		
		override protected function initialize():void
		{
			super.initialize();
			
			this.image = new ImageLoaderExtended;
			this.image.addEventListener(Event.COMPLETE, image_completeHandler);
			this.image.addEventListener(FeathersEventType.ERROR, image_errorHandler);
			
			//this is a custom version of TouchSheet designed to work better
			//with Feathers scrolling containers
			this.touchSheet = new TouchSheet(this.image);
			//you can disable certain features of this TouchSheet
			this.touchSheet.zoomEnabled = true;
			this.touchSheet.rotateEnabled = false;
			this.touchSheet.moveEnabled = false;
			//and events are dispatched when any of the gestures are performed
			this.touchSheet.addEventListener(TouchSheet.MOVE, touchSheet_gestureHandler);
			this.touchSheet.addEventListener(TouchSheet.ROTATE, touchSheet_gestureHandler);
			this.touchSheet.addEventListener(TouchSheet.ZOOM, touchSheet_gestureHandler);
			//on TouchPhase.ENDED, any gestures performed are complete
			this.touchSheet.addEventListener(TouchEvent.TOUCH, touchSheet_touchHandler);
			this.addChild(this.touchSheet);
		}
		
		override protected function draw():void
		{
			var dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
			if (dataInvalid)
			{
				image.textureCache = _textureCache;
				image.texturePreferredWidth = _texturePreferredWidth;
				image.texturePreferredHeight = _texturePreferredHeight;
				image.source = _source;
				
				//stop any active animations because it's a new image
				if(this._gestureCompleteTween !== null)
				{
					this.stage.starling.juggler.remove(this._gestureCompleteTween);
					this._gestureCompleteTween = null;
				}
				//reset all of the transformations because it's a new image
				this._defaultScale = 1;
				this.resetTransformation();
			}
			
			super.draw();
		}
		
		protected function resetTransformation():void
		{
			this.touchSheet.rotation = 0;
			this.touchSheet.scale = this._defaultScale;
			this.touchSheet.pivotX = 0;
			this.touchSheet.pivotY = 0;
			this.touchSheet.x = 0;
			this.touchSheet.y = 0;
		}
		
		protected function image_completeHandler(event:Event):void
		{
			//when an image first loads, we want it to fill the width and height
			//of the item renderer, without being larger than the item renderer
			var imageWidth:Number = isNaN(image.texturePreferredWidth) ? image.originalSourceWidth : image.texturePreferredWidth;
			var imageHeight:Number = isNaN(image.texturePreferredHeight) ? image.originalSourceHeight : image.texturePreferredHeight;
			
			this._defaultScale = calculateScaleRatioToFit(
				imageWidth, imageHeight,
				this.viewPort.visibleWidth, this.viewPort.visibleHeight);
			if(this._defaultScale > 1)
			{
				//however, we only want to make large images smaller. small
				//images should not be made larger because they'll get blurry.
				//the user can zoom in, if desired.
				this._defaultScale = 1;
			}
			this.touchSheet.scale = this._defaultScale;
			this.touchSheet.visible = true;
		}
		
		/**
		 * @private
		 */
		protected function image_errorHandler(event:Event):void
		{
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}
		
		protected function touchSheet_touchHandler(event:TouchEvent):void
		{
			var touch:Touch = event.getTouch(this.touchSheet, TouchPhase.BEGAN);
			touch && trace(touch.id);
			//the current gesture is complete on TouchPhase.ENDED
			touch = event.getTouch(this.touchSheet, TouchPhase.ENDED);
			if(touch === null)
			{
				return;
			}
			
			//if the scale is smaller than the default, animate it back
			var targetScale:Number = this.touchSheet.scale;
			if(targetScale < this._defaultScale)
			{
				targetScale = this._defaultScale;
			}
			if(this.touchSheet.scale !== targetScale)
			{
				this._gestureCompleteTween = new Tween(this.touchSheet, 0.15, Transitions.EASE_OUT);
				this._gestureCompleteTween.scaleTo(targetScale);
				this._gestureCompleteTween.onComplete = this.gestureCompleteTween_onComplete;
				this.stage.starling.juggler.add(this._gestureCompleteTween);
			}
		}
		
		protected function touchSheet_gestureHandler(event:Event):void
		{
			//if the animation from the previous gesture is still active, stop
			//it immediately when a new gesture starts
			if(this._gestureCompleteTween !== null)
			{
				this.stage.starling.juggler.remove(this._gestureCompleteTween);
				this._gestureCompleteTween = null;
			}
		}
		
		protected function gestureCompleteTween_onComplete():void
		{
			this._gestureCompleteTween = null;
		}
	}
}