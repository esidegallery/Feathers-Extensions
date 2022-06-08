package feathers.controls
{
	import com.esidegallery.utils.IHasUID;
	import com.esidegallery.utils.UIDUtils;

	import feathers.media.VideoPlayer;

	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;

	public class VideoPlayerExtended extends VideoPlayer implements IHasUID
	{
		private var _uid:String;
		public function get uid():String
		{
			return _uid ||= UIDUtils.generateUID(this, true);
		}
		public function set uid(value:String):void
		{
			_uid = value;
		}

		/**
		 * This will result in a READY event being dispatched again,
		 * which is useful for when looping the video.
		 */
		public function replay():void
		{
			if (_texture == null || netStream == null)
			{
				return;
			}
			stop();
			videoTexture_onRestore();
			play();
		}

		public function VideoPlayerExtended()
		{
			_netConnectionFactory = function():NetConnection
			{
				trace(uid, "netConnectionFactory");
				var connection:NetConnection = new NetConnection();
				connection.connect(null);
				return connection;
			};
			_netStreamFactory = function(netConnection:NetConnection):NetStream
			{
				trace(uid, "netStreamFactory");
				return new NetStream(netConnection);
			}
		}

		override protected function disposeNetConnection():void
		{
			if (_netConnection == null)
			{
				return;
			}
			trace(uid, "disposeNetConnection()");
			super.disposeNetConnection();
		}

		override protected function disposeNetStream():void
		{
			if (_netStream == null)
			{
				return;
			}
			trace(uid, "disposeNetStream()");
			super.disposeNetStream();
		}

		override protected function netConnection_netStatusHandler(event:NetStatusEvent):void
		{
			trace(uid, "netConnection_netStatusHandler", event.info.code);
			super.netConnection_netStatusHandler(event);
		}

		override protected function netStream_netStatusHandler(event:NetStatusEvent):void
		{
			trace(uid, "netStream_netStatusHandler", event.info.code);
			super.netStream_netStatusHandler(event);
		}
	}
}