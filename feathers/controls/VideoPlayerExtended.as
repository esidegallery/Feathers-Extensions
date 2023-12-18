package feathers.controls
{
	import com.esidegallery.utils.IHasUID;
	import com.esidegallery.utils.UIDUtils;

	import feathers.media.VideoPlayer;

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
	}
}