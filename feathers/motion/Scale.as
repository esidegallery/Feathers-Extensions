package feathers.motion
{
	import feathers.core.IFeathersControl;
	import feathers.motion.effectClasses.IEffectContext;
	import feathers.motion.effectClasses.TweenEffectContext;

	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.display.DisplayObject;

	public class Scale
	{
		/**
		 * @param fromScaleX:Number
		 * @param fromScaleY:Number
		 * @param duration:Number
		 * @param ease:Object
		 * @param interruptBehavior:String
		 */
		public static function createScaleFromEffect(fromScaleX:Number, fromScaleY:Number, duration:Number = 0.5, ease:Object = Transitions.EASE_OUT, interruptBehavior:String = EffectInterruptBehavior.END):Function
		{
			return function(target:DisplayObject):IEffectContext
			{
				var finalScaleX:Number = target.scaleX;
				var finalScaleY:Number = target.scaleY;
				if (target is IFeathersControl)
				{
					(target as IFeathersControl).suspendEffects();
				}
				target.scaleX = fromScaleX;
				target.scaleY = fromScaleY;
				if (target is IFeathersControl)
				{
					(target as IFeathersControl).resumeEffects();
				}
				var tween:Tween = new Tween(target, duration, ease);
				tween.animate("scaleX", finalScaleX);
				tween.animate("scaleY", finalScaleY);
				var context:TweenEffectContext = new TweenEffectContext(target, tween, interruptBehavior);
				return context;
			}
		}

		/**
		 * @param toScaleX:Number
		 * @param toScaleY:Number
		 * @param duration:Number
		 * @param ease:Object
		 * @param interruptBehavior:String
		 */
		public static function createScaleToEffect(toScaleX:Number, toScaleY:Number, duration:Number = 0.5, ease:Object = Transitions.EASE_OUT, interruptBehavior:String = EffectInterruptBehavior.END):Function
		{
			return function(target:DisplayObject):IEffectContext
			{
				if (target is IFeathersControl)
				{
					(target as IFeathersControl).suspendEffects();
				}
				if (target is IFeathersControl)
				{
					(target as IFeathersControl).resumeEffects();
				}
				var tween:Tween = new Tween(target, duration, ease);
				tween.animate("scaleX", toScaleX);
				tween.animate("scaleY", toScaleY);
				var context:TweenEffectContext = new TweenEffectContext(target, tween, interruptBehavior);
				return context;
			}
		}
	}
}