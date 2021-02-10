package feathers.utils.textures
{
	import com.esidegallery.utils.IHasUID;
	import com.esidegallery.utils.UIDUtils;

	import starling.textures.Texture;

	public class TextureCacheExtended extends TextureCache implements IHasUID
	{
		private var _uid:String;
		public function get uid():String
		{
			return _uid ||= UIDUtils.generateUID(this);
		}
		public function set uid(value:String):void
		{
			_uid = value;
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