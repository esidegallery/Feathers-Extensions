package feathers.utils.textures
{
	import starling.textures.Texture;

	public class TextureCacheExtended extends TextureCache
	{
		public var preventDispose:Boolean;
		
		protected var _isDisposed:Boolean = false;
		public function get isDisposed():Boolean
		{
			return _isDisposed;
		}

		public function TextureCacheExtended(maxUnretainedTextures:int = 2147483647, preventDispose:Boolean = false)
		{
			this.preventDispose = preventDispose;
			super(maxUnretainedTextures);
		}
		
		override public function addTexture(key:String, texture:Texture, retainTexture:Boolean = true):void
		{
			if (!isDisposed)
			{
				super.addTexture(key, texture, retainTexture);
			}
		}
		
		override public function dispose():void
		{
			if (!_isDisposed && !preventDispose)
			{
				super.dispose();
				_isDisposed = true;
			}
		}
	}
}