package feathers.controls
{
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
	}
}