package feathers.controls
{
	import feathers.core.FeathersControl;
	import feathers.skins.IStyleProvider;

	import flash.geom.Rectangle;
	import flash.utils.getTimer;

	import starling.display.Image;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.textures.RenderTexture;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.Color;

	/** Draws a striped, animated Photoshop-style marquee. */
	public class Marquee extends FeathersControl
	{
		public static var globalStyleProvider:IStyleProvider;
		override protected function get defaultStyleProvider():IStyleProvider
		{
			return globalStyleProvider;
		}

		private var _fps:Number = 4;
		public function get fps():Number
		{
			return _fps;
		}
		public function set fps(value:Number):void
		{
			if (processStyleRestriction(arguments.callee))
			{
				return;
			}
			if (_fps == value)
			{
				return;
			}
			_fps = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _borderSize:int = 1;
		public function get borderSize():int
		{
			return _borderSize;
		}
		public function set borderSize(value:int):void
		{
			if (processStyleRestriction(arguments.callee))
			{
				return;
			}
			if (_borderSize == value)
			{
				return;
			}
			_borderSize = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _stripeSize:int = 4;
		public function get stripeSize():int
		{
			return _stripeSize;
		}
		public function set stripeSize(value:int):void
		{
			if (processStyleRestriction(arguments.callee))
			{
				return;
			}
			if (_stripeSize == value)
			{
				return;
			}
			_stripeSize = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _color1:uint = Color.BLACK;
		public function get color1():uint
		{
			return _color1;
		}
		public function set color1(value:uint):void
		{
			if (processStyleRestriction(arguments.callee))
			{
				return;
			}
			if (_color1 == value)
			{
				return;
			}
			_color1 = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _color2:uint = Color.WHITE;
		public function get color2():uint
		{
			return _color2;
		}
		public function set color2(value:uint):void
		{
			if (processStyleRestriction(arguments.callee))
			{
				return;
			}
			if (_color2 == value)
			{
				return;
			}
			_color2 = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		protected var border_top:Image;
		protected var border_right:Image;
		protected var border_bottom:Image;
		protected var border_left:Image;

		protected var texture_h:Texture;
		protected var texture_v:Texture;

		protected var tileGrid_h:Rectangle = new Rectangle;
		protected var tileGrid_v:Rectangle = new Rectangle;

		protected var currentFrame:int;

		override protected function initialize():void
		{
			touchable = false;

			border_top = new Image(null);
			border_top.textureSmoothing = TextureSmoothing.NONE;
			addChild(border_top);

			border_right = new Image(null);
			border_right.textureSmoothing = TextureSmoothing.NONE;
			addChild(border_right);

			border_bottom = new Image(null);
			border_bottom.textureSmoothing = TextureSmoothing.NONE;
			addChild(border_bottom);

			border_left = new Image(null);
			border_left.textureSmoothing = TextureSmoothing.NONE;
			addChild(border_left);

			super.initialize();
		}

		override protected function draw():void
		{
			var stylesInvalid:Boolean = isInvalid(INVALIDATION_FLAG_STYLES);
			var sizeInvalid:Boolean = isInvalid(INVALIDATION_FLAG_SIZE);

			if (stylesInvalid)
			{
				commitStyles();
			}

			if (autoSizeIfNeeded())
			{
				sizeInvalid = true;
			}

			if (stylesInvalid || sizeInvalid)
			{
				layoutChildren();
			}

			super.draw();
		}

		protected function commitStyles():void
		{
			disposeTextures();

			var color1Quad:Quad = new Quad(_stripeSize, _stripeSize, _color1);

			// It's quicker to create a larger texture than to tile a very small one:
			var numIterations:int = 20;
			var renderTexture:RenderTexture = new RenderTexture(_stripeSize * 2 * numIterations, _borderSize);
			renderTexture.clear(color2, 1);
			renderTexture.drawBundled(function():void
				{
					for (var i:int = 0; i < numIterations; i++)
					{
						color1Quad.x = _stripeSize * 2 * i;
						renderTexture.draw(color1Quad);
					}
				});

			texture_h = renderTexture;
			texture_v = Texture.fromTexture(renderTexture, renderTexture.region, renderTexture.frame, true);

			border_top.texture = texture_h;
			border_top.readjustSize();

			border_right.texture = texture_v;
			border_right.readjustSize();

			border_bottom.texture = texture_h;
			border_bottom.readjustSize();

			border_left.texture = texture_v;
			border_left.readjustSize();
		}

		protected function autoSizeIfNeeded():Boolean
		{
			var needsWidth:Boolean = isNaN(this.explicitWidth);
			var needsHeight:Boolean = isNaN(this.explicitHeight);

			if (!needsWidth && !needsHeight)
			{
				return false;
			}

			var minSize:Number = Math.min(_borderSize, _stripeSize) * 2;
			var maxSize:Number = Math.max(_borderSize, _stripeSize) * 2;

			return saveMeasurements(maxSize, maxSize, minSize, minSize);
		}

		protected function layoutChildren():void
		{
			border_top.x = 0;
			border_top.y = 0;
			border_top.width = actualWidth - _borderSize;
			border_top.height = _borderSize;

			border_right.x = actualWidth - _borderSize;
			border_right.y = 0;
			border_right.width = _borderSize;
			border_right.height = actualHeight - _borderSize;

			border_bottom.x = _borderSize;
			border_bottom.y = actualHeight - _borderSize;
			border_bottom.width = actualWidth - _borderSize;
			border_bottom.height = _borderSize;

			border_left.x = 0;
			border_left.y = _borderSize;
			border_left.width = _borderSize;
			border_left.height = actualHeight - _borderSize;

			updateTileGrids();
		}

		protected function updateTileGrids():void
		{
			if (texture_h == null && texture_v == null)
			{
				return;
			}
			var frame:int = getTimer() / 1000 * fps % fps;
			if (frame == currentFrame)
			{
				return;
			}
			currentFrame = frame;

			var factor:Number = frame / fps;
			tileGrid_h.setTo(_stripeSize * 2 * factor, 0, texture_h.width, texture_h.height);
			tileGrid_v.setTo(0, _stripeSize * 2 * factor, texture_v.width, texture_v.height);

			border_top.tileGrid = tileGrid_h;
			border_right.tileGrid = tileGrid_v;
			border_bottom.tileGrid = tileGrid_h;
			border_left.tileGrid = tileGrid_v;
		}

		override protected function feathersControl_addedToStageHandler(event:Event):void
		{
			super.feathersControl_addedToStageHandler(event);
			addEventListener(Event.ENTER_FRAME, updateTileGrids);
		}

		override protected function feathersControl_removedFromStageHandler(event:Event):void
		{
			super.feathersControl_removedFromStageHandler(event);
			removeEventListener(Event.ENTER_FRAME, updateTileGrids);
		}

		protected function disposeTextures():void
		{
			if (texture_h != null)
			{
				texture_h.dispose();
				texture_h = null;
			}
			if (texture_v != null)
			{
				texture_v.dispose();
				texture_v = null;
			}
		}

		override public function dispose():void
		{
			disposeTextures();
			super.dispose();
		}
	}
}