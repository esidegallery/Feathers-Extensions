package feathers.extensions.maps
{
	import feathers.controls.ImageLoader;
	import feathers.extensions.maps.MapTilesBuffer;

	import flash.events.IOErrorEvent;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;

	import starling.core.Starling;
	import starling.events.Event;
	import starling.textures.Texture;

	public class MapTile extends ImageLoader
	{
		protected static const INVALIDATION_FLAG_SOURCE:String = "source";

		public var mapX:int;
		public var mapY:int;
		public var zoom:int;

		public var loadInstantly:Boolean;
		public var prioritiseBuffering:Boolean;
		public var delayedSource:Object;
		public var animateShow:Boolean;

		public function get isDisposed():Boolean
		{
			return _isDisposed;
		}

		/**
		 * The actual value referenced.
		 * Set accoring to <code>animateShow</code> and other circumstances.
		 */
		private var _animateShow:Boolean;
		private var buffer:MapTilesBuffer;
		private var tweenID:int = -1;

		public function MapTile(mapX:int, mapY:int, zoom:int, buffer:MapTilesBuffer)
		{
			super();

			this.mapX = mapX;
			this.mapY = mapY;
			this.zoom = zoom;
			this.buffer = buffer;
		}

		override protected function initialize():void
		{
			super.initialize();

			addEventListener(Event.COMPLETE, show);
		}

		protected function show():void
		{
			visible = true;
			if (_animateShow && alpha < 1 && tweenID == -1)
			{
				tweenID = Starling.juggler.tween(this, 0.1, {
							alpha: 1,
							onComplete: tween_completeHandler
						});
			}
			else
			{
				if (tweenID != -1)
				{
					Starling.juggler.removeByID(tweenID);
				}
				alpha = 1;
				dispatchReady();
			}
		}

		private function tween_completeHandler():void
		{
			tweenID = -1;
			dispatchReady();
		}

		private function dispatchReady():void
		{
			dispatchEventWith(Event.READY);
		}

		override protected function layout():void
		{
			if (image == null || _currentTexture == null)
			{
				return;
			}

			image.x = 0;
			image.y = 0;
			image.width = actualWidth;
			image.height = actualHeight;
		}

		override public function set source(value:Object):void
		{
			if (value != null && source == value)
			{
				_animateShow = !_texture && animateShow;
				show();
				return;
			}

			if (loadInstantly)
			{
				super.source = value;
				return;
			}

			if (_textureCache != null)
			{
				var cacheKey:String = sourceToTextureCacheKey(value);
				if (cacheKey && _textureCache.hasTexture(cacheKey))
				{
					_animateShow = false;
					super.source = value;
					return;
				}
			}

			if (!delayedSource)
			{
				delayedSource = value;
				buffer.add(this, prioritiseBuffering);
				return;
			}

			_animateShow = animateShow;

			super.source = value;
		}

		override protected function replaceRawTextureData(rawData:ByteArray):void
		{
			var starling:Starling = stage !== null ? stage.starling : Starling.current;
			if (!starling.contextValid)
			{
				setTimeout(replaceRawTextureData, 1, rawData);
				return;
			}
			verifyCurrentStarling();

			if (findSourceInCache())
			{
				// Someone else added this URL to the cache while we were in the
				// middle of loading it. we can reuse the texture from the cache!

				// Don't forget to clear the ByteArray, though...
				rawData.clear();

				// Then invalidate so that everything is resized correctly
				invalidate(INVALIDATION_FLAG_DATA);
				return;
			}

			if (!_texture)
			{
				if (_asyncTextureUpload)
				{
					_texture = Texture.fromAtfData(rawData, scaleFactor, false, _uploadComplete);
				}
				else
				{
					try
					{
						_texture = Texture.fromAtfData(rawData, scaleFactor);
					}
					catch (error:Error)
					{
						cleanupTexture();
						invalidate(INVALIDATION_FLAG_DATA);
						dispatchEventWith(starling.events.Event.IO_ERROR, false, new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, error.toString()));
						return;
					}
					_uploadComplete();
				}
				_texture.root.onRestore = createTextureOnRestore(_texture,
						_source, textureFormat, scaleFactor);
				if (_textureCache)
				{
					var cacheKey:String = sourceToTextureCacheKey(_source);
					if (cacheKey !== null)
					{
						_textureCache.addTexture(cacheKey, _texture, true);
					}
				}
			}
			else
			{
				if (_asyncTextureUpload)
				{
					_texture.root.uploadAtfData(rawData, 0, _uploadComplete);
				}
				else
				{
					_texture.root.uploadAtfData(rawData);
					_uploadComplete();
				}
			}

			function _uploadComplete():void
			{
				rawData.clear();
				_isTextureOwner = _textureCache === null;
				_isRestoringTexture = false;
				_isLoaded = true;
				invalidate(INVALIDATION_FLAG_DATA);
				dispatchEventWith(starling.events.Event.COMPLETE);
			}
		}

		override protected function feathersControl_removedFromStageHandler(event:Event):void
		{
			disposeTween();

			super.feathersControl_removedFromStageHandler(event);
		}

		protected function disposeTween():void
		{
			if (tweenID == -1)
			{
				return;
			}
			Starling.juggler.removeByID(tweenID);
		}

		override public function dispose():void
		{
			disposeTween();

			super.dispose();
		}
	}
}