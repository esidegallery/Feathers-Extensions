package feathers.utils.textures
{
	public class TextureCacheExtended extends TextureCache
	{
		protected var _isDisposed:Boolean = false;
		public function get isDisposed():Boolean
		{
			return _isDisposed;
		}

		public function TextureCacheExtended(maxUnretainedTextures:int=2147483647)
		{
			super(maxUnretainedTextures);
		}
		
		override public function dispose():void
		{
			if (!_isDisposed)
			{
				super.dispose();
			}
			
			_isDisposed = true;
		}
	}
}