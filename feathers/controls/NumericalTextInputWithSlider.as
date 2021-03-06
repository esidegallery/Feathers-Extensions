package feathers.controls
{
	import app.manager.view.theme.ManagerTheme;

	import feathers.events.FeathersEventType;
	import feathers.layout.RelativePosition;
	import feathers.skins.IStyleProvider;

	import starling.events.Event;
	import starling.utils.StringUtil;

	public class NumericalTextInputWithSlider extends TextInput
	{
		/** Intended for 2-digit inputs. */
		public static const ALTERNATIVE_STYLE_NAME_NARROW:String = "narrow";
		/** Intended for 4-digit inputs. */
		public static const ALTERNATIVE_STYLE_NAME_WIDE:String = "wide";
		
		public static const DEFAULT_CHILD_STYLE_NAME_SLIDER:String = "numericalTextInputWithSlider_slider";
		
		private static const INVALIDATION_FLAG_PARAMETERS:String = "parameters";
		
		private var sliderCallout:Callout;
		private var slider:Slider;
		
		public static var globalStyleProvider:IStyleProvider;
		override protected function get defaultStyleProvider():IStyleProvider
		{
			return globalStyleProvider;
		}
		
		private var _softMinimum:Number = NaN;
		/** The minimum value of the slider, which can be extended via the text input up to <code>hardMinimum</code>. */
		public function get softMinimum():Number
		{
			return _softMinimum;
		}
		public function set softMinimum(value:Number):void
		{
			if (_softMinimum != value)
			{
				_softMinimum = value;
				invalidate(INVALIDATION_FLAG_PARAMETERS);
			}
		}

		private var _hardMinimum:Number = 0;
		/** The absolute minimum of the slider. */
		public function get hardMinimum():Number
		{
			return _hardMinimum;
		}
		public function set hardMinimum(value:Number):void
		{
			if (_hardMinimum != value)
			{
				_hardMinimum = value;
				invalidate(INVALIDATION_FLAG_PARAMETERS);
			}
		}
		
		private var _softMaximum:Number = NaN;
		public function get softMaximum():Number
		{
			return _softMaximum;
		}
		public function set softMaximum(value:Number):void
		{
			if (_softMaximum != value)
			{
				_softMaximum = value;
				invalidate(INVALIDATION_FLAG_PARAMETERS);
			}
		}

		private var _hardMaximum:Number = 0;
		public function get hardMaximum():Number
		{
			return _hardMaximum;
		}
		public function set hardMaximum(value:Number):void
		{
			if (_hardMaximum != value)
			{
				_hardMaximum = value;
				invalidate(INVALIDATION_FLAG_PARAMETERS);
			}
		}

		public function get value():Number
		{
			return slider.value;
		}
		public function set value(value:Number):void
		{
			setSliderValue(value);
		}
		
		public function get stepSize():Number
		{
			return slider.step;
		}
		public function set stepSize(value:Number):void
		{
			slider.step = value;
		}

		override public function set text(value:String):void
		{
			// Same as super, without dispatching a change:
			if (!value)
			{
				//don't allow null or undefined
				value = "";
			}
			if (this._text == value)
			{
				return;
			}
			this._text = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}
		
		public function NumericalTextInputWithSlider()
		{
			super();
			
			restrict = "0-9.";
			addEventListener(FeathersEventType.ENTER, commitInputText);
			
			slider = new Slider; // Instantiating slider now, so it can be used immediately.
			slider.styleNameList.add(DEFAULT_CHILD_STYLE_NAME_SLIDER);
			slider.isFocusEnabled = false;
			slider.addEventListener(Event.CHANGE, slider_changeHandler);
		}
		
		override protected function draw():void
		{
			if (isInvalid(INVALIDATION_FLAG_PARAMETERS))
			{
				// Re-set slider's value (via setSliderValue) to force an adjustment of the range:
				setSliderValue(value);
			}
			super.draw();
		}
		
		override protected function focusInHandler(event:Event):void
		{
			super.focusInHandler(event);
			showSliderCallout();
		}
		
		override protected function focusOutHandler(event:Event):void
		{
			super.focusOutHandler(event);
			commitInputText();
		}
		
		private function slider_changeHandler():void
		{
			commitSliderValue();
			dispatchEventWith(Event.CHANGE, false, slider.value);
		}
		
		private function showSliderCallout():void
		{
			setSliderValue(value); // To force the parameters to rescale:
			sliderCallout = Callout.show(slider, this, new <String>[RelativePosition.BOTTOM], false);
			sliderCallout.paddingLeft
				= sliderCallout.paddingRight 
				= sliderCallout.paddingTop
				= sliderCallout.paddingBottom
				= ManagerTheme.SIZE_CONTROL_GUTTER;
			sliderCallout.disposeContent = false;
			sliderCallout.addEventListener(Event.CLOSE, commitSliderValue);
		}
		
		private function commitSliderValue():void
		{
			text = String(slider.value);
		}
		
		private function commitInputText():void
		{
			var newValue:Number = NaN;
			var trimmed:String = StringUtil.trim(text);
			if (trimmed) // Only apply change if text is populated:
			{
				newValue = Number(trimmed);
			}
			if (!isNaN(newValue))
			{
				setSliderValue(newValue);
			}
		}
		
		protected function setSliderValue(value:Number):void
		{
			// Clamp to absolute parameters:
			slider.minimum = !isNaN(_softMinimum) ? Math.max(Math.min(value, _softMinimum), _hardMinimum) : _hardMinimum;
			slider.maximum = !isNaN(_softMaximum) ? Math.min(Math.max(value, _softMaximum), _hardMaximum) : _hardMaximum;
			slider.value = value;
			commitSliderValue();
		}
		
		override public function dispose():void
		{
			if (sliderCallout)
			{
				sliderCallout.disposeContent = true;
				sliderCallout.dispose();
			}
			sliderCallout = null;
			
			super.dispose();
		}
	}
}