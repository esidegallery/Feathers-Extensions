package feathers.utils.textures
{
	import robotlegs.bender.framework.impl.UID;
	
	import starling.extensions.starlingCallLater.callLater;
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
		
		public var debug:Boolean = true;

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
			debug && callLater(traceStats)
		}
		
		override public function removeTexture(key:String, dispose:Boolean = false):void
		{
			super.removeTexture(key, dispose);
			debug && callLater(traceStats)
		}
		
		override public function retainTexture(key:String):Texture
		{
			var val:Texture = super.retainTexture(key);
			debug && callLater(traceStats);
			return val;
		}
		
		override public function releaseTexture(key:String):void
		{
			super.releaseTexture(key);
			debug && callLater(traceStats)
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
		
		public function traceStats():void
		{
			trace(uid, getNumRetainedTextures(), "retained", getNumUnretainedTextures(), "unretained of", _maxUnretainedTextures);
		}
		
		override public function dispose():void
		{
			if (!_isDisposed && !preventDispose)
			{
				super.dispose();
				_isDisposed = true;
				if (debug)
				{
					trace(uid, "disposed");
				}
			}
		}
	}
}