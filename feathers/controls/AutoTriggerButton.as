package feathers.controls
{
	import com.esidegallery.utils.substitute;

	import feathers.layout.RelativePosition;

	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.extensions.Timer;

	public class AutoTriggerButton extends Button
	{
		protected static const INVALIDATION_FLAG_TIMER:String = "timer";

		public static const DEFAULT_CHILD_STYLE_NAME_COUNTDOWN_LABEL:String = "autotriggerbutton-countdown-label";

		private var _autoCloseDelay:int = 10;

		/** In whole seconds. */
		public function get autoCloseDelay():int
		{
			return _autoCloseDelay;
		}
		public function set autoCloseDelay(value:int):void
		{
			if (_autoCloseDelay == value)
			{
				return;
			}
			_autoCloseDelay = value;
			invalidate(INVALIDATION_FLAG_TIMER);
		}

		private var _showCountdownAsDefaultIcon:Boolean = true;
		public function get showCountdownAsDefaultIcon():Boolean
		{
			return _showCountdownAsDefaultIcon;
		}
		public function set showCountdownAsDefaultIcon(value:Boolean):void
		{
			if (_showCountdownAsDefaultIcon == value)
			{
				return;
			}
			_showCountdownAsDefaultIcon = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		protected var countdownDisplay:Label;
		protected var countdownTimer:Timer;

		public function AutoTriggerButton()
		{
			iconPosition = RelativePosition.RIGHT;
		}

		override protected function draw():void
		{
			var timerInvalid:Boolean = isInvalid(INVALIDATION_FLAG_TIMER);

			if (timerInvalid)
			{
				refreshTimer();
			}

			super.draw();
		}

		override protected function getCurrentIcon():DisplayObject
		{
			if (_showCountdownAsDefaultIcon)
			{
				if (countdownDisplay == null)
				{
					countdownDisplay = new Label;
					countdownDisplay.styleName = DEFAULT_CHILD_STYLE_NAME_COUNTDOWN_LABEL;
				}
				refreshCountdownDisplay();
				return countdownDisplay;
			}
			else if (countdownDisplay != null)
			{
				countdownDisplay.removeFromParent(true);
				countdownDisplay = null;
			}
			return super.getCurrentIcon();
		}

		protected function refreshTimer():void
		{
			if (countdownTimer == null)
			{
				countdownTimer = new Timer(1000, _autoCloseDelay);
				countdownTimer.addEventListener(Timer.EVENT_TIMER, refreshCountdownDisplay);
				countdownTimer.addEventListener(Timer.EVENT_TIMER_COMPLETE, timer_timerCompleteHandler);
			}
			else
			{
				countdownTimer.reset();
				countdownTimer.repeatCount = _autoCloseDelay;
			}
			refreshCountdownDisplay();
			countdownTimer.start();
		}

		protected function refreshCountdownDisplay():void
		{
			if (countdownDisplay == null)
			{
				return;
			}
			countdownDisplay.text = substitute("({0})", [Math.max(countdownTimer.repeatCount - countdownTimer.currentCount, 0)]);
		}

		protected function timer_timerCompleteHandler():void
		{
			dispatchEventWith(Event.TRIGGERED);
		}

		override public function dispose():void
		{
			if (countdownTimer != null)
			{
				countdownTimer.dispose();
				countdownTimer = null;
			}

			super.dispose();
		}
	}
}