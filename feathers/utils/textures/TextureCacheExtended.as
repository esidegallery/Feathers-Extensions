package feathers.utils.textures
{
	import robotlegs.bender.framework.impl.UID;

	import starling.textures.Texture;

	public class TextureCacheExtended extends TextureCache
	{
		protected var _uid:String;
		public function get uid():String
		{
			_uid ||= UID.create(this);
			return _uid;
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

		public function getNumRetainedTextures():int
		{
			var num:int = 0;
			if (_retainedTextures)
			{
				for each (var key:Object in this._retainedTextures)
				{
					num++;
				}
			}
			return num;
		}
		
		public function getNumUnretainedTextures():int
		{
			return _unretainedKeys ? _unretainedKeys.length : 0;
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