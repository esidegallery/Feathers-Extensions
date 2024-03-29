package feathers.skins
{
	import feathers.core.IMeasureDisplayObject;
	import feathers.core.IStateContext;
	import feathers.core.IStateObserver;
	import feathers.motion.StateTweener;

	import flash.display.BitmapData;
	import flash.errors.IllegalOperationError;
	import flash.geom.Rectangle;

	import starling.display.Image;
	import starling.events.Event;
	import starling.filters.ColorMatrixFilterPatched;
	import starling.textures.Texture;
	import starling.utils.Color;

	public class DuoToneImageSkin extends Image implements IMeasureDisplayObject, IStateObserver
	{
		private static const HELPER_RECTANGLE:Rectangle = new Rectangle;

		/** The blackColor property that is referenced and tweened. */
		protected static const BLACK_COLOR:String = "blackColor";

		/** The whiteColor property that is referenced and tweened. */
		protected static const WHITE_COLOR:String = "whiteColor";

		/** The blackAlpha property that is referenced and tweened. */
		protected static const BLACK_ALPHA:String = "blackAlpha";

		/** The whiteAlpha property that is referenced and tweened. */
		protected static const WHITE_ALPHA:String = "whiteAlpha";

		protected var _explicitWidth:Number = NaN;
		public function get explicitWidth():Number
		{
			return _explicitWidth;
		}
		override public function set width(value:Number):void
		{
			if (_explicitWidth == value)
			{
				return;
			}
			if (value != value && _explicitWidth != _explicitWidth) // isNaN
			{
				return;
			}
			_explicitWidth = value;
			if (value == value) // !isNaN
			{
				super.width = value;
			}
			else if (texture != null)
			{
				// return to the original width of the texture
				scaleX = 1;
				readjustSize(texture.frameWidth);
			}
			else
			{
				readjustSize();
			}
			dispatchEventWith(Event.RESIZE);
		}

		protected var _explicitHeight:Number = NaN;
		public function get explicitHeight():Number
		{
			return _explicitHeight;
		}
		override public function set height(value:Number):void
		{
			if (_explicitHeight == value)
			{
				return;
			}
			if (value != value && _explicitHeight != _explicitHeight) // isNaN
			{
				return;
			}
			_explicitHeight = value;
			if (value == value) // !isNaN
			{
				super.height = value;
			}
			else if (texture != null)
			{
				// return to the original height of the texture
				scaleY = 1;
				readjustSize(-1, texture.frameHeight);
			}
			else
			{
				readjustSize();
			}
			dispatchEventWith(Event.RESIZE);
		}

		protected var _explicitMinWidth:Number = NaN;
		public function get explicitMinWidth():Number
		{
			return _explicitMinWidth;
		}
		public function get minWidth():Number
		{
			if (_explicitMinWidth == _explicitMinWidth) // !isNaN
			{
				return _explicitMinWidth;
			}
			return 0;
		}
		public function set minWidth(value:Number):void
		{
			if (_explicitMinWidth == value)
			{
				return;
			}
			if (value != value && _explicitMinWidth != _explicitMinWidth) // isNaN
			{
				return;
			}
			_explicitMinWidth = value;
			dispatchEventWith(Event.RESIZE);
		}

		protected var _explicitMaxWidth:Number = Number.POSITIVE_INFINITY;
		public function get explicitMaxWidth():Number
		{
			return _explicitMaxWidth;
		}
		public function get maxWidth():Number
		{
			return _explicitMaxWidth;
		}
		public function set maxWidth(value:Number):void
		{
			if (_explicitMaxWidth == value)
			{
				return;
			}
			if (value != value && _explicitMaxWidth != _explicitMaxWidth) // isNaN
			{
				return;
			}
			_explicitMaxWidth = value;
			dispatchEventWith(Event.RESIZE);
		}

		protected var _explicitMinHeight:Number = NaN;
		public function get explicitMinHeight():Number
		{
			return _explicitMinHeight;
		}
		public function get minHeight():Number
		{
			if (_explicitMinHeight == _explicitMinHeight) // !isNaN
			{
				return _explicitMinHeight;
			}
			return 0;
		}
		public function set minHeight(value:Number):void
		{
			if (_explicitMinHeight == value)
			{
				return;
			}
			if (value != value && _explicitMinHeight != _explicitMinHeight) // isNaN
			{
				return;
			}
			_explicitMinHeight = value;
			dispatchEventWith(Event.RESIZE);
		}

		protected var _explicitMaxHeight:Number = Number.POSITIVE_INFINITY;
		public function get explicitMaxHeight():Number
		{
			return _explicitMaxHeight;
		}
		public function get maxHeight():Number
		{
			return _explicitMaxHeight;
		}
		public function set maxHeight(value:Number):void
		{
			if (_explicitMaxHeight == value)
			{
				return;
			}
			if (value != value && _explicitMaxHeight != _explicitMaxHeight) // isNaN
			{
				return;
			}
			_explicitMaxHeight = value;
			dispatchEventWith(Event.RESIZE);
		}

		protected var _minTouchWidth:Number = 0;
		public function get minTouchWidth():Number
		{
			return _minTouchWidth;
		}
		public function set minTouchWidth(value:Number):void
		{
			_minTouchWidth = value;
		}

		protected var _minTouchHeight:Number = 0;
		public function get minTouchHeight():Number
		{
			return _minTouchHeight;
		}
		public function set minTouchHeight(value:Number):void
		{
			_minTouchHeight = value;
		}

		public function get stateContext():IStateContext
		{
			return stateTweener.stateContext;
		}
		public function set stateContext(value:IStateContext):void
		{
			stateTweener.stateContext = value;
		}

		override public function set color(value:uint):void
		{
			if (restrictColor)
			{
				throw new IllegalOperationError("To set the color of an ImageSkin, use defaultColor or setColorForState().");
			}
			super.color = value;
		}

		/** Set the <code>uint.MAX_VALUE</code> to clear/ignore this property. */
		public function get defaultWhiteColor():uint
		{
			var value:* = stateTweener.getDefaultProperty(WHITE_COLOR);
			return value is uint ? value as uint : uint.MAX_VALUE;
		}
		public function set defaultWhiteColor(value:uint):void
		{
			if (value == uint.MAX_VALUE)
			{
				stateTweener.clearDefaultProperty(WHITE_COLOR);
			}
			else
			{
				stateTweener.setDefaultProperty(WHITE_COLOR, value);
			}
		}

		/** Set the <code>uint.MAX_VALUE</code> to clear/ignore this property. */
		public function get selectedWhiteColor():uint
		{
			var value:* = stateTweener.getSelectedProperty(WHITE_COLOR);
			return value is uint ? value as uint : uint.MAX_VALUE;
		}
		public function set selectedWhiteColor(value:uint):void
		{
			if (value == uint.MAX_VALUE)
			{
				stateTweener.clearSelectedProperty(WHITE_COLOR);
			}
			else
			{
				stateTweener.setSelectedProperty(WHITE_COLOR, value);
			}
		}

		/** Set the <code>uint.MAX_VALUE</code> to clear/ignore this property. */
		public function get disabledWhiteColor():uint
		{
			var value:* = stateTweener.getDisabledProperty(WHITE_COLOR);
			return value is uint ? value as uint : uint.MAX_VALUE;
		}
		public function set disabledWhiteColor(value:uint):void
		{
			if (value == uint.MAX_VALUE)
			{
				stateTweener.clearDisabledProperty(WHITE_COLOR);
			}
			else
			{
				stateTweener.setDisabledProperty(WHITE_COLOR, value);
			}
		}

		/** Set the <code>uint.MAX_VALUE</code> to clear/ignore this property. */
		public function setWhiteColorForState(state:String, value:uint):void
		{
			if (value == uint.MAX_VALUE)
			{
				stateTweener.clearPropertyForState(WHITE_COLOR, state);
			}
			else
			{
				stateTweener.setPropertyForState(WHITE_COLOR, state, value);
			}
		}
		public function getWhiteColorForState(state:String):uint
		{
			var value:* = stateTweener.getPropertyForState(WHITE_COLOR, state);
			return value is uint ? value as uint : uint.MAX_VALUE;
		}

		/** Set the <code>uint.MAX_VALUE</code> to clear/ignore this property. */
		public function get defaultBlackColor():uint
		{
			var value:* = stateTweener.getDefaultProperty(BLACK_COLOR);
			return value is uint ? value as uint : uint.MAX_VALUE;
		}
		public function set defaultBlackColor(value:uint):void
		{
			if (value == uint.MAX_VALUE)
			{
				stateTweener.clearDefaultProperty(BLACK_COLOR);
			}
			else
			{
				stateTweener.setDefaultProperty(BLACK_COLOR, value);
			}
		}

		/** Set the <code>uint.MAX_VALUE</code> to clear/ignore this property. */
		public function get selectedBlackColor():uint
		{
			var value:* = stateTweener.getSelectedProperty(BLACK_COLOR);
			return value is uint ? value as uint : uint.MAX_VALUE;
		}
		public function set selectedBlackColor(value:uint):void
		{
			if (value == uint.MAX_VALUE)
			{
				stateTweener.clearSelectedProperty(BLACK_COLOR);
			}
			else
			{
				stateTweener.setSelectedProperty(BLACK_COLOR, value);
			}
		}

		/** Set the <code>uint.MAX_VALUE</code> to clear/ignore this property. */
		public function get disabledBlackColor():uint
		{
			var value:* = stateTweener.getDisabledProperty(BLACK_COLOR);
			return value is uint ? value as uint : uint.MAX_VALUE;
		}
		public function set disabledBlackColor(value:uint):void
		{
			if (value == uint.MAX_VALUE)
			{
				stateTweener.clearDisabledProperty(BLACK_COLOR);
			}
			else
			{
				stateTweener.setDisabledProperty(BLACK_COLOR, value);
			}
		}

		/** Set to <code>NaN</code> to clear/ignore this property. */
		public function setBlackColorForState(state:String, value:uint):void
		{
			if (value == uint.MAX_VALUE)
			{
				stateTweener.clearPropertyForState(BLACK_COLOR, state);
			}
			else
			{
				stateTweener.setPropertyForState(BLACK_COLOR, state, value);
			}
		}
		public function getBlackColorForState(state:String):uint
		{
			var value:* = stateTweener.getPropertyForState(BLACK_COLOR, state);
			return value is uint ? value as uint : uint.MAX_VALUE;
		}

		/** Set to <code>NaN</code> to clear/ignore this property. */
		public function get defaultWhiteAlpha():Number
		{
			var value:Number = stateTweener.getDefaultProperty(WHITE_ALPHA) as Number;
			return value == value ? value : NaN;
		}
		public function set defaultWhiteAlpha(value:Number):void
		{
			if (value != value) // isNaN
			{
				stateTweener.clearDefaultProperty(WHITE_ALPHA);
			}
			else
			{
				stateTweener.setDefaultProperty(WHITE_ALPHA, value);
			}
		}

		/** Set to <code>NaN</code> to clear/ignore this property. */
		public function get selectedWhiteAlpha():Number
		{
			var value:Number = stateTweener.getSelectedProperty(WHITE_ALPHA) as Number;
			return value == value ? value : NaN;
		}
		public function set selectedWhiteAlpha(value:Number):void
		{
			if (value != value) // isNaN
			{
				stateTweener.clearSelectedProperty(WHITE_ALPHA);
			}
			else
			{
				stateTweener.setSelectedProperty(WHITE_ALPHA, value);
			}
		}

		/** Set the <code>NaN</code> to clear/ignore this property. */
		public function get disabledWhiteAlpha():Number
		{
			var value:Number = stateTweener.getSelectedProperty(WHITE_ALPHA) as Number;
			return value == value ? value : NaN;
		}
		public function set disabledWhiteAlpha(value:Number):void
		{
			if (value != value) // isNaN
			{
				stateTweener.clearDisabledProperty(WHITE_ALPHA);
			}
			else
			{
				stateTweener.setDisabledProperty(WHITE_ALPHA, value);
			}
		}

		/** Set the <code>uint.MAX_VALUE</code> to clear/ignore this property. */
		public function setWhiteAlphaForState(state:String, value:Number):void
		{
			if (value != value) // isNaN
			{
				stateTweener.clearPropertyForState(WHITE_ALPHA, state);
			}
			else
			{
				stateTweener.setPropertyForState(WHITE_ALPHA, state, value);
			}
		}
		public function getWhiteAlphaForState(state:String):uint
		{
			var value:Number = stateTweener.getPropertyForState(WHITE_ALPHA, state) as Number;
			return value == value ? value : NaN;
		}

		/** Set to <code>NaN</code> to clear/ignore this property. */
		public function get defaultBlackAlpha():Number
		{
			var value:Number = stateTweener.getDefaultProperty(BLACK_ALPHA) as Number;
			return value == value ? value : NaN;
		}
		public function set defaultBlackAlpha(value:Number):void
		{
			if (value != value) // isNaN
			{
				stateTweener.clearDefaultProperty(BLACK_ALPHA);
			}
			else
			{
				stateTweener.setDefaultProperty(BLACK_ALPHA, value);
			}
		}

		/** Set to <code>NaN</code> to clear/ignore this property. */
		public function get selectedBlackAlpha():Number
		{
			var value:Number = stateTweener.getSelectedProperty(BLACK_ALPHA) as Number;
			return value == value ? value : NaN;
		}
		public function set selectedBlackAlpha(value:Number):void
		{
			if (value != value) // isNaN
			{
				stateTweener.clearSelectedProperty(BLACK_ALPHA);
			}
			else
			{
				stateTweener.setSelectedProperty(BLACK_ALPHA, value);
			}
		}

		/** Set the <code>NaN</code> to clear/ignore this property. */
		public function get disabledBlackAlpha():Number
		{
			var value:Number = stateTweener.getSelectedProperty(BLACK_ALPHA) as Number;
			return value == value ? value : NaN;
		}
		public function set disabledBlackAlpha(value:Number):void
		{
			if (value != value) // isNaN
			{
				stateTweener.clearDisabledProperty(BLACK_ALPHA);
			}
			else
			{
				stateTweener.setDisabledProperty(BLACK_ALPHA, value);
			}
		}

		/** Set the <code>uint.MAX_VALUE</code> to clear/ignore this property. */
		public function setBlackAlphaForState(state:String, value:Number):void
		{
			if (value != value) // isNaN
			{
				stateTweener.clearPropertyForState(BLACK_ALPHA, state);
			}
			else
			{
				stateTweener.setPropertyForState(BLACK_ALPHA, state, value);
			}
		}
		public function getBlackAlphaForState(state:String):uint
		{
			var value:Number = stateTweener.getPropertyForState(BLACK_ALPHA, state) as Number;
			return value == value ? value : NaN;
		}

		public function get tweenTime():Number
		{
			return stateTweener.tweenTime;
		}
		public function set tweenTime(value:Number):void
		{
			stateTweener.tweenTime = value;
		}

		public function get tweenTransition():Object
		{
			return stateTweener.tweenTransition;
		}
		public function set tweenTransition(value:Object):void
		{
			stateTweener.tweenTransition = value;
		}

		public function get tweenInterruptBehavior():String
		{
			return stateTweener.interruptBehavior;
		}
		public function set tweenInterruptBehavior(value:String):void
		{
			stateTweener.interruptBehavior = value;
		}

		/** Prevents <code>color</code> being set directly (once instantiated). */
		protected var restrictColor:Boolean = false;
		protected var colorMatrixFilter:ColorMatrixFilterPatched;

		/** Holds the color values to be tweened. */
		protected var filterTweenTarget:Object;
		protected var stateTweener:StateTweener;

		public function DuoToneImageSkin(texture:Texture)
		{
			super(texture);

			// After construction, color may only be set via state-specific members:
			restrictColor = true;

			colorMatrixFilter = new ColorMatrixFilterPatched;
			filter = colorMatrixFilter;

			filterTweenTarget = new Object;
			filterTweenTarget[BLACK_COLOR] = Color.BLACK;
			filterTweenTarget[WHITE_COLOR] = Color.WHITE;
			filterTweenTarget[BLACK_ALPHA] = 1;
			filterTweenTarget[WHITE_ALPHA] = 1;

			stateTweener = new StateTweener(filterTweenTarget);
			stateTweener.setDefaultProperty(BLACK_COLOR, filterTweenTarget[BLACK_COLOR]);
			stateTweener.setDefaultProperty(WHITE_COLOR, filterTweenTarget[WHITE_COLOR]);
			stateTweener.setDefaultProperty(WHITE_ALPHA, filterTweenTarget[WHITE_ALPHA]);
			stateTweener.setDefaultProperty(BLACK_ALPHA, filterTweenTarget[BLACK_ALPHA]);
			stateTweener.onUpdate = applyFilterValues;

			applyFilterValues();
		}

		public function validate():void
		{
			stateTweener.validate();
		}

		override public function readjustSize(width:Number = -1, height:Number = -1):void
		{
			super.readjustSize(width, height);
			if (_explicitWidth == _explicitWidth) // !isNaN
			{
				super.width = _explicitWidth;
			}
			if (_explicitHeight == _explicitHeight) // !isNaN
			{
				super.height = _explicitHeight;
			}
		}

		protected function applyFilterValues():void
		{
			colorMatrixFilter.reset();
			colorMatrixFilter.duoTone(filterTweenTarget[BLACK_COLOR], filterTweenTarget[WHITE_COLOR], filterTweenTarget[BLACK_ALPHA], filterTweenTarget[WHITE_ALPHA]);
		}

		override public function drawToBitmapData(out:BitmapData = null, color:uint = 0, alpha:Number = 0.0):BitmapData
		{
			return starling.utils.drawToBitmapData(this, out, color, alpha);
		}

		override public function dispose():void
		{
			stateTweener.dispose();
			colorMatrixFilter.dispose();
			super.dispose();
		}
	}
}