package feathers.styles
{
	import feathers.core.IStateContext;
	import feathers.core.IStateObserver;
	import feathers.motion.StateTweener;

	import starling.styles.ColorTransformStyle;

	public class StateColorFillStyle extends ColorTransformStyle implements IStateObserver
	{
		protected static const PROPERTY_COLOR:String = "color";

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

		public function get defaultColor():uint
		{
			var value:* = stateTweener.getDefaultProperty(PROPERTY_COLOR);
			return value is uint ? value : uint.MAX_VALUE;
		}
		public function set defaultColor(value:uint):void
		{
			if (value == uint.MAX_VALUE)
			{
				stateTweener.clearDefaultProperty(PROPERTY_COLOR);
			}
			else
			{
				stateTweener.setDefaultProperty(PROPERTY_COLOR, value);
			}
		}

		public function get disabledColor():uint
		{
			var value:* = stateTweener.getDisabledProperty(PROPERTY_COLOR);
			return value is uint ? value : uint.MAX_VALUE;
		}
		public function set disabledColor(value:uint):void
		{
			if (value == uint.MAX_VALUE)
			{
				stateTweener.clearDisabledProperty(PROPERTY_COLOR);
			}
			else
			{
				stateTweener.setDisabledProperty(PROPERTY_COLOR, value);
			}
		}

		public function get selectedColor():uint
		{
			var value:* = stateTweener.getSelectedProperty(PROPERTY_COLOR);
			return value is uint ? value : uint.MAX_VALUE;
		}
		public function set selectedColor(value:uint):void
		{
			if (value == uint.MAX_VALUE)
			{
				stateTweener.clearSelectedProperty(PROPERTY_COLOR);
			}
			else
			{
				stateTweener.setSelectedProperty(PROPERTY_COLOR, value);
			}
		}

		public function getColorForState(state:String):uint
		{
			var value:* = stateTweener.getPropertyForState(PROPERTY_COLOR, state);
			return value is uint ? value : uint.MAX_VALUE;
		}
		public function setColorForState(state:String, value:uint):void
		{
			if (value == uint.MAX_VALUE)
			{
				stateTweener.clearPropertyForState(PROPERTY_COLOR, state);
			}
			else
			{
				stateTweener.setPropertyForState(PROPERTY_COLOR, state, value);
			}
		}
		
		protected var stateTweener:StateTweener;

		public function StateColorFillStyle()
		{
			stateTweener = new StateTweener(this)
		}

		public function validate():void
		{
			stateTweener.validate();
		}
	}
}