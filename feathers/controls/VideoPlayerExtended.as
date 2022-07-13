package feathers.controls
{
	import com.esidegallery.utils.IHasUID;
	import com.esidegallery.utils.UIDUtils;

	import feathers.media.VideoPlayer;

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
				var connection:NetConnection = new NetConnection();
				connection.connect(null);
				return connection;
			};
			_netStreamFactory = function(netConnection:NetConnection):NetStream
			{
				return new NetStream(netConnection);
			}
		}
	}
}