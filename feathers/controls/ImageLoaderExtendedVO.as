package feathers.controls
{
	import com.esidegallery.utils.substitute;

	public class ImageLoaderExtendedVO
	{
		public var source:Object;
		public var texturePreferredWidth:Number;
		public var texturePreferredHeight:Number;
		
		public function ImageLoaderExtendedVO(source:Object = null, texturePreferredWidth:Number = NaN, texturePreferredHeight:Number = NaN)
		{
			this.source = source;
			this.texturePreferredWidth = texturePreferredWidth;
			this.texturePreferredHeight = texturePreferredHeight;
		}

		public function toString():String
		{
			return substitute("[ImageLoaderExtendedVO('{0}',{1}×{2}", [source, texturePreferredWidth, texturePreferredHeight]);
		}
	}
}