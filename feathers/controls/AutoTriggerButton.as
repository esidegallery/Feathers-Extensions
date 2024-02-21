package feathers.controls
{
	import com.esidegallery.utils.substitute;

	import starling.events.Event;
	import starling.extensions.Timer;

	public class AutoTriggerButton extends Button
	{
		protected static const INVALIDATION_FLAG_TIMER:String = "timer";

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

		protected var countdownDisplay:Label;
		protected var countdownTimer:Timer;

		public function AutoTriggerButton()
		{
			countdownDisplay = new Label;

			defaultIcon = countdownDisplay;
		}

		override protected function initialize():void
		{
			super.initialize();
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
			countdownDisplay.text = substitute("({0})", [countdownTimer.repeatCount - countdownTimer.currentCount]);
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