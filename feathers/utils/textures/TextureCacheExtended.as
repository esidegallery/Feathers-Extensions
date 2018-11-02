package feathers.utils.textures
{
	import robotlegs.bender.framework.impl.UID;
	
	import starling.textures.Texture;

	public class TextureCacheExtended extends TextureCache
	{
		private var _uid:String;
		public function get uid():String
		{
			return _uid ||= UID.create(this);
		}
		
		public var preventDispose:Boolean;
		
		protected var _isDisposed:Boolean = false;
		public function get isDisposed():Boolean
		{
			return _isDisposed;
		}

		public function TextureCacheExtended(maxUnretainedTextures:int = 2147483647, preventDispose:Boolean = false, uid:String = null)
		{
			this.preventDispose = preventDispose;
			this._uid = uid;
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