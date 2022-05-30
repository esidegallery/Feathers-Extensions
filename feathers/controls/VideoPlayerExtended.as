package feathers.controls
{
	import feathers.media.VideoPlayer;

	public class VideoPlayerExtended extends VideoPlayer
	{
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