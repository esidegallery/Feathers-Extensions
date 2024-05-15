package feathers.motion
{
	import feathers.motion.effectClasses.IEffectContext;

	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.DisplayObject;

	public class FadeTransition
	{
		protected static const SCREEN_REQUIRED_ERROR:String = "Cannot transition if both old screen and new screen are null.";

		/** Wrapper for <code>Fade.createFadeInTransition()</code> */
		public static function createFadeInTransition(duration:Number = 0.5, ease:Object = Transitions.EASE_OUT, tweenProperties:Object = null):Function
		{
			return Fade.createFadeInTransition(duration, ease, tweenProperties);
		}

		/** Wrapper for <code>Fade.createFadeOutTransition()</code> */
		public static function createFadeOutTransition(duration:Number = 0.5, ease:Object = Transitions.EASE_OUT, tweenProperties:Object = null):Function
		{
			return Fade.createFadeOutTransition(duration, ease, tweenProperties);
		}

		/** Wrapper for <code>Fade.createCrossfadeTransition()</code> */
		public static function createCrossfadeTransition(duration:Number = 0.5, ease:Object = Transitions.EASE_OUT, tweenProperties:Object = null):Function
		{
			return Fade.createCrossfadeTransition(duration, ease, tweenProperties);
		}

		public static function createFadeBetweenTransition(fadeOutDuration:Number = 0.3, fadeOutEase:Object = Transitions.EASE_IN, gapDuration:Number = 0.2, fadeInDuration:Number = 0.5, fadeInEase:Object = Transitions.EASE_OUT, tweenProperties:Object = null):Function
		{
			return function(oldScreen:DisplayObject, newScreen:DisplayObject, onComplete:Function, managed:Boolean = false):IEffectContext
			{
				if (oldScreen == null && newScreen == null)
				{
					throw new ArgumentError(SCREEN_REQUIRED_ERROR);
				}

				var hasNewScreen:Boolean = newScreen != null;
				var hasOldScreen:Boolean = oldScreen != null;

				if (hasNewScreen)
				{
					newScreen.alpha = 0;
					var fadeInTween:Tween = new Tween(newScreen, fadeInDuration, fadeInEase);
					fadeInTween.fadeTo(1);
					_applyTweenProperties(fadeInTween);
					fadeInTween.onComplete = onComplete;
				}
				if (oldScreen != null)
				{
					oldScreen.alpha = 1;
					var fadeOutTween:Tween = new Tween(oldScreen, fadeOutDuration, fadeOutEase);
					fadeOutTween.fadeTo(0);
					if (hasNewScreen)
					{
						fadeInTween.delay = fadeOutDuration + gapDuration;
					}
					else
					{
						_applyTweenProperties(fadeOutTween);
						fadeOutTween.onComplete = onComplete;
					}
				}

				if (fadeOutTween != null)
				{
					Starling.juggler.add(fadeOutTween);
				}
				if (fadeInTween != null)
				{
					Starling.juggler.add(fadeInTween);
				}

				// Not supporting managed.
				return null;

				function _applyTweenProperties(tween:Tween):void
				{
					if (tweenProperties)
					{
						for (var propertyName:String in tweenProperties)
						{
							tween[propertyName] = tweenProperties[propertyName];
						}
					}
				}
			};
		}
	}
}