package feathers.filters
{
	import feathers.core.IStateContext;
	import feathers.core.IStateObserver;
	import feathers.motion.EffectInterruptBehavior;
	import feathers.motion.StateTweener;

	import starling.filters.ColorMatrixFilter;

	public class StateColorMatrixFilter extends ColorMatrixFilter implements IStateObserver
	{
		protected static const PROPERTY_BRIGHTNESS:String = "brightness";
		protected static const PROPERTY_CONTRAST:String = "contrast";
		protected static const PROPERTY_HUE:String = "hue";
		protected static const PROPERTY_SATURATION:String = "saturation";

		public function get stateContext():IStateContext
		{
			return stateTweener.stateContext;
		}
		public function set stateContext(value:IStateContext):void
		{
			stateTweener.stateContext = value;
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

		/** Set to NaN to clear. */
		public function get defaultBrightness():Number
		{
			var value:Number = stateTweener.getDefaultProperty(PROPERTY_BRIGHTNESS) as Number;
			return value == value ? value : NaN;
		}
		public function set defaultBrightness(value:Number):void
		{
			if (value == value)
			{
				stateTweener.setDefaultProperty(PROPERTY_BRIGHTNESS, value);
			}
			else
			{
				stateTweener.clearDefaultProperty(PROPERTY_BRIGHTNESS);
			}
		}

		/** Set to NaN to clear. */
		public function get disabledBrightness():Number
		{
			var value:Number = stateTweener.getDisabledProperty(PROPERTY_BRIGHTNESS) as Number;
			return value == value ? value : NaN;
		}
		public function set disabledBrightness(value:Number):void
		{
			if (value == value)
			{
				stateTweener.setDisabledProperty(PROPERTY_BRIGHTNESS, value);
			}
			else
			{
				stateTweener.clearDisabledProperty(PROPERTY_BRIGHTNESS);
			}
		}

		/** Set to NaN to clear. */
		public function get selectedBrightness():Number
		{
			var value:Number = stateTweener.getSelectedProperty(PROPERTY_BRIGHTNESS) as Number;
			return value == value ? value : NaN;
		}
		public function set selectedBrightness(value:Number):void
		{
			if (value == value)
			{
				stateTweener.setSelectedProperty(PROPERTY_BRIGHTNESS, value);
			}
			else
			{
				stateTweener.clearSelectedProperty(PROPERTY_BRIGHTNESS);
			}
		}

		/** Set to NaN to clear. */
		public function getBrightnessForState(state:String):Number
		{
			var value:Number = stateTweener.getPropertyForState(PROPERTY_BRIGHTNESS, state) as Number;
			return value == value ? value : NaN;
		}
		public function setBrightnessForState(state:String, value:Number):void
		{
			if (value == value)
			{
				stateTweener.setPropertyForState(PROPERTY_BRIGHTNESS, state, value);
			}
			else
			{
				stateTweener.clearPropertyForState(PROPERTY_BRIGHTNESS, state);
			}
		}

		/** Holds the color values to be tweened. */
		protected var filterTweenTarget:Object;
		protected var stateTweener:StateTweener;

		public function StateColorMatrixFilter()
		{
			filterTweenTarget = new Object;
			stateTweener = new StateTweener(filterTweenTarget);
			stateTweener.setDefaultProperty(PROPERTY_BRIGHTNESS, 0);
			stateTweener.setDefaultProperty(PROPERTY_CONTRAST, 0);
			stateTweener.setDefaultProperty(PROPERTY_HUE, 0);
			stateTweener.setDefaultProperty(PROPERTY_SATURATION, 0);
			stateTweener.interruptBehavior = EffectInterruptBehavior.END;
			stateTweener.onUpdate = applyFilterValues;
		}

		public function validate():void
		{
			stateTweener.validate();
		}

		protected function applyFilterValues():void
		{
			reset();
			if (PROPERTY_BRIGHTNESS in filterTweenTarget)
			{
				adjustBrightness(filterTweenTarget[PROPERTY_BRIGHTNESS] || 0);
			}
			if (PROPERTY_CONTRAST in filterTweenTarget)
			{
				adjustBrightness(filterTweenTarget[PROPERTY_CONTRAST] || 0);
			}
			if (PROPERTY_HUE in filterTweenTarget)
			{
				adjustBrightness(filterTweenTarget[PROPERTY_BRIGHTNESS] || 0);
			}
			if (PROPERTY_SATURATION in filterTweenTarget)
			{
				adjustBrightness(filterTweenTarget[PROPERTY_BRIGHTNESS] || 0);
			}
		}

		override public function dispose():void
		{
			stateTweener.dispose();
			super.dispose();
		}
	}
}