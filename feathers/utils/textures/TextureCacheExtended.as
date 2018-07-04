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
		
		public function flush(dispose:Boolean = false):void
		{
			if (dispose)
			{
				for each(var texture:Texture in this._unretainedTextures)
				{
					texture.dispose();
				}
				for each(texture in this._retainedTextures)
				{
					texture.dispose();
				}
			}
			_unretainedKeys = new <String>[];
			_unretainedTextures = {};
			_retainedTextures = {};
			_retainCounts = {};
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