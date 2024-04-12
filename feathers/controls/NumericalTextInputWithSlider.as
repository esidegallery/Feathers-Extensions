package feathers.controls
{
	import feathers.events.FeathersEventType;
	import feathers.layout.RelativePosition;
	import feathers.skins.IStyleProvider;
	import feathers.utils.display.getPopUpIndex;
	import feathers.utils.math.roundToNearest;

	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;

	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.utils.StringUtil;

	[Event(name="open", type="starling.events.Event")]
	[Event(name="close", type="starling.events.Event")]

	public class NumericalTextInputWithSlider extends TextInput
	{
		/** Intended for 2-digit inputs. */
		public static const ALTERNATIVE_STYLE_NAME_NARROW:String = "narrow";

		/** Intended for 4-digit inputs. */
		public static const ALTERNATIVE_STYLE_NAME_WIDE:String = "wide";

		public static const DEFAULT_CHILD_STYLE_NAME_SLIDER:String = "numericalTextInputWithSlider_slider";

		private static const INVALIDATION_FLAG_PARAMETERS:String = "parameters";

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
			if (_softMinimum == value)
			{
				return;
			}
			_softMinimum = value;
			invalidate(INVALIDATION_FLAG_PARAMETERS);
		}

		private var _hardMinimum:Number = 0;

		/** The absolute minimum of the slider. */
		public function get hardMinimum():Number
		{
			return _hardMinimum;
		}
		public function set hardMinimum(value:Number):void
		{
			if (_hardMinimum == value)
			{
				return;
			}
			_hardMinimum = value;
			invalidate(INVALIDATION_FLAG_PARAMETERS);
		}

		private var _softMaximum:Number = NaN;
		public function get softMaximum():Number
		{
			return _softMaximum;
		}
		public function set softMaximum(value:Number):void
		{
			if (_softMaximum == value)
			{
				return;
			}
			_softMaximum = value;
			invalidate(INVALIDATION_FLAG_PARAMETERS);
		}

		private var _hardMaximum:Number = 0;
		public function get hardMaximum():Number
		{
			return _hardMaximum;
		}
		public function set hardMaximum(value:Number):void
		{
			if (_hardMaximum == value)
			{
				return;
			}
			_hardMaximum = value;
			invalidate(INVALIDATION_FLAG_PARAMETERS);
		}

		public function get value():Number
		{
			// We need to round to step on the fly to avoid a weird rounding error I can't get to the bottom of:
			return roundToNearest(slider.value, slider.step);
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
			// Same as super.text, without dispatching a change.
			if (value == null)
			{
				// Don't allow null:
				value = "";
			}
			if (_text == value)
			{
				return;
			}
			_text = value;
			invalidate(INVALIDATION_FLAG_DATA);
		}

		private var _liveDragging:Boolean = true;
		public function get liveDragging():Boolean
		{
			return _liveDragging;
		}
		public function set liveDragging(value:Boolean):void
		{
			if (_liveDragging == value)
			{
				return;
			}
			_liveDragging = value;
			if (!_liveDragging && pendingDispatchChangeOnEndInteraction)
			{
				dispatchChange();
			}
		}

		private var _isDragging:Boolean;
		/** Whether the slider is being dragged. */
		public function get isDragging():Boolean
		{
			return _isDragging;
		}

		private var sliderCallout:Callout;
		private var slider:Slider;
		private var pendingDispatchChangeOnEndInteraction:Boolean;

		public function NumericalTextInputWithSlider()
		{
			super();

			restrict = "0-9.";
			addEventListener(FeathersEventType.ENTER, enterHandler);

			slider = new Slider; // Instantiating slider now, so it can be used immediately.
			slider.thumbFactory = function():BasicButton
			{
				var thumb:Button = new Button;
				thumb.isFocusEnabled = false;
				return thumb;
			};
			slider.styleNameList.add(DEFAULT_CHILD_STYLE_NAME_SLIDER);
			slider.isFocusEnabled = false;
			slider.addEventListener(Event.CHANGE, slider_changeHandler);
			slider.addEventListener(FeathersEventType.BEGIN_INTERACTION, slider_beginInteractionHandler);
			slider.addEventListener(FeathersEventType.END_INTERACTION, slider_endInteractionHandler);
		}

		override protected function draw():void
		{
			if (isInvalid(INVALIDATION_FLAG_PARAMETERS))
			{
				// Reset slider's value (via setSliderValue) to force an adjustment of the range:
				setSliderValue(value);
			}
			super.draw();
		}

		private function showSliderCallout():void
		{
			if (sliderCallout != null)
			{
				return;
			}

			setSliderValue(value); // To force the parameters to rescale:

			sliderCallout = Callout.show(slider, this, new <String>[RelativePosition.BOTTOM], false);
			sliderCallout.padding = 12;
			sliderCallout.disposeContent = false;
			dispatchEventWith(Event.OPEN);

			var starling:Starling = stage != null ? stage.starling : Starling.current;
			var priority:int = getPopUpIndex(sliderCallout);
			starling.nativeStage.addEventListener(flash.events.KeyboardEvent.KEY_DOWN, sliderCallout_nativeStage_keyDownHandler, false, priority, true);
			sliderCallout.addEventListener(Event.REMOVED_FROM_STAGE, sliderCallout_removedFromStageHandler);
		}

		protected function commitSliderValue():void
		{
			text = String(value); // We need to do this to avoid a weird rounding error.
		}

		private function commitInputText():void
		{
			var newValue:Number = NaN;
			var trimmed:String = StringUtil.trim(text);
			if (trimmed) // Only apply change if text is populated:
			{
				newValue = Number(trimmed);
			}
			if (newValue == newValue && newValue != value)
			{
				slider.removeEventListener(Event.CHANGE, slider_changeHandler);
				setSliderValue(newValue);
				slider.addEventListener(Event.CHANGE, slider_changeHandler);
				dispatchChange();
			}
		}

		protected function setSliderValue(value:Number):void
		{
			// Clamp to absolute parameters:
			slider.minimum = _softMinimum == _softMinimum ? Math.max(Math.min(value, _softMinimum), _hardMinimum) : _hardMinimum;
			slider.maximum = _softMaximum == _softMaximum ? Math.min(Math.max(value, _softMaximum), _hardMaximum) : _hardMaximum;
			slider.value = value;
			commitSliderValue();
		}

		override public function setFocus():void
		{
			super.setFocus();
			if (!visible || _touchPointID >= 0)
			{
				return;
			}
			if (_isEditable || _isSelectable)
			{
				selectRange(0, _text.length);
			}
		}

		protected function dispatchChange():void
		{
			dispatchEventWith(Event.CHANGE, false, value);
			pendingDispatchChangeOnEndInteraction = false;
		}

		protected function enterHandler():void
		{
			commitInputText();
			showSliderCallout();
		}

		override protected function feathersControl_addedToStageHandler(event:Event):void
		{
			super.feathersControl_addedToStageHandler(event);

			var starling:Starling = stage != null ? stage.starling : Starling.current;
			starling.stage.addEventListener(starling.events.KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
		}

		override protected function feathersControl_removedFromStageHandler(event:Event):void
		{
			super.feathersControl_removedFromStageHandler(event);

			var starling:Starling = stage != null ? stage.starling : Starling.current;
			starling.stage.removeEventListener(starling.events.KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
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
			if (focusManager.focus != null && sliderCallout != null)
			{
				sliderCallout.close();
			}
		}

		private function slider_changeHandler():void
		{
			commitSliderValue();
			if (!_liveDragging && _isDragging)
			{
				pendingDispatchChangeOnEndInteraction = true;
			}
			else
			{
				dispatchChange();
			}
		}

		private function slider_beginInteractionHandler():void
		{
			_isDragging = true;
		}

		private function slider_endInteractionHandler():void
		{
			_isDragging = false;
			focusManager.focus = this;
			if (pendingDispatchChangeOnEndInteraction)
			{
				dispatchChange();
			}
		}

		protected function stage_keyDownHandler(event:starling.events.KeyboardEvent):void
		{
			if (!hasFocus && sliderCallout == null)
			{
				return;
			}

			if (event.keyCode == Keyboard.PAGE_UP)
			{
				event.preventDefault();
				slider.value += slider.step * 10;
			}
			else if (event.keyCode == Keyboard.PAGE_DOWN)
			{
				event.preventDefault();
				slider.value -= slider.step * 10;
			}
			else if (event.keyCode == Keyboard.UP)
			{
				event.preventDefault();
				slider.value += slider.step * (event.shiftKey ? 10 : 1);
			}
			else if (event.keyCode == Keyboard.DOWN)
			{
				event.preventDefault();
				slider.value -= slider.step * (event.shiftKey ? 10 : 1);
			}

			focusManager.focus = this;
		}

		private function sliderCallout_nativeStage_keyDownHandler(event:flash.events.KeyboardEvent):void
		{
			if (event.isDefaultPrevented() || sliderCallout == null)
			{
				return;
			}
			if (event.keyCode == Keyboard.ESCAPE)
			{
				event.preventDefault();
				sliderCallout.removeFromParent(true);
			}
		}

		private function sliderCallout_removedFromStageHandler():void
		{
			dispatchEventWith(Event.CLOSE);
			commitSliderValue();
			var starling:Starling = stage != null ? stage.starling : Starling.current;
			starling.nativeStage.removeEventListener(flash.events.KeyboardEvent.KEY_DOWN, sliderCallout_nativeStage_keyDownHandler);
			sliderCallout = null;
		}

		override public function dispose():void
		{
			if (sliderCallout != null)
			{
				sliderCallout.removeFromParent(true);
				sliderCallout = null;
			}
			if (slider != null)
			{
				slider.dispose();
				slider = null;
			}

			super.dispose();
		}
	}
}