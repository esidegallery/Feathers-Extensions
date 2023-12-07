package feathers.extensions.maps
{
	import feathers.controls.VideoPlayerExtended;
	import feathers.controls.VideoTextureImageLoader;
	import feathers.events.FeathersEventType;
	import feathers.extensions.maps.Map;
	import feathers.extensions.maps.MapVideoLayerOptions;

	import flash.filesystem.File;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;

	import starling.display.Sprite;
	import starling.events.Event;

	/** To be dispatched when the video is ready, so that map can update its viewport. */
	[Event(name="ready", type="starling.events.Event")]

	public class MapVideoLayer extends Sprite
	{
		protected var _options:MapVideoLayerOptions;
		public function get options():MapVideoLayerOptions
		{
			return _options;
		}

		protected var _map:Map;
		protected var _id:String;
		protected var _videoPlayer:VideoPlayerExtended;
		protected var _videoDisplay:VideoTextureImageLoader;

		protected var _paused:Boolean;
		public function get paused():Boolean
		{
			return _paused;
		}
		public function set paused(value:Boolean):void
		{
			_paused = value;
			if (_videoPlayer == null)
			{
				return;
			}
			if (_paused && _videoPlayer.isPlaying)
			{
				_videoPlayer.pause();
			}
			else if (!_paused && !_videoPlayer.isPlaying)
			{
				_videoPlayer.play();
			}
		}

		private var _volume:Number;
		public function get volume():Number
		{
			return _volume;
		}
		public function set volume(value:Number):void
		{
			_volume = value;
			if (_videoPlayer == null)
			{
				return;
			}
			_videoPlayer.soundTransform = new SoundTransform(_volume);
		}

		public function MapVideoLayer(map:Map, id:String, options:MapVideoLayerOptions)
		{
			_map = map;
			_id = id;
			_options = options || new MapVideoLayerOptions;

			initialize();
		}

		protected function initialize():void
		{
			if (options.videoPlayerFactory != null)
			{
				_videoPlayer = new options.videoPlayerFactory as VideoPlayerExtended;
			}
			else
			{
				_videoPlayer = new VideoPlayerExtended;
			}
			volume = options.volume;
			if (_options.videoSource is File)
			{
				_videoPlayer.videoSource = (_options.videoSource as File).url;
			}
			else if (_options.videoSource is URLRequest)
			{
				_videoPlayer.videoSource = (_options.videoSource as URLRequest).url;
			}
			else
			{
				_videoPlayer.videoSource = String(_options.videoSource);
			}
			_videoPlayer.addEventListener(Event.READY, videoPlayer_readyHandler);
			_videoPlayer.addEventListener(Event.COMPLETE, videoPlayer_completeHandler);
			_videoPlayer.addEventListener(FeathersEventType.CLEAR, videoPlayer_clearHandler);
			addChild(_videoPlayer);

			_videoDisplay = new VideoTextureImageLoader;
			_videoDisplay.scaleContent = false;
			addChild(_videoDisplay);
		}

		protected function videoPlayer_readyHandler(event:Event):void
		{
			if (_paused)
			{
				_videoPlayer.pause();
			}
			_videoDisplay.source = _videoPlayer.texture;
			_videoDisplay.videoDisplayWidth = _options.videoDisplayWidth != -1 ? _options.videoDisplayWidth : NaN;
			_videoDisplay.videoDisplayHeight = _options.videoDisplayHeight != -1 ? _options.videoDisplayHeight : NaN;
			_videoDisplay.validate();
			dispatchEventWith(Event.READY);
		}

		protected function videoPlayer_completeHandler(event:Event):void
		{
			_videoDisplay.freezeFrame();
			_videoPlayer.replay();
		}

		protected function videoPlayer_clearHandler(event:Event):void
		{
			_videoDisplay.clear();
		}
	}
}