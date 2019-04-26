package feathers.motion
{
	import feathers.core.IFeathersControl;
	import feathers.motion.effectClasses.IEffectContext;
	import feathers.motion.effectClasses.TweenEffectContext;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.display.DisplayObject;
	import starling.utils.Align;

	public class Scale
	{
		/**
		 * @param fromScaleX:Number
		 * @param fromScaleY:Number
		 * @param duration:Number
		 * @param ease:Object
		 * @param pivotHorizontalAlign:String A value of <code>starling.utils.Align</code>.
		 * @param pivotVerticalAlign:String A value of <code>starling.utils.Align</code>.
		 * @param interruptBehavior:String
		 */
		public static function createScaleFromEffect(fromScaleX:Number, fromScaleY:Number, duration:Number = 0.5, ease:Object = Transitions.EASE_OUT, pivotHorizontalAlign:String = Align.CENTER, pivotVerticalAlign:String = Align.CENTER, interruptBehavior:String = EffectInterruptBehavior.END):Function
		{
			return function(target:DisplayObject):IEffectContext
			{
				var finalScaleX:Number = target.scaleX;
				var finalScaleY:Number = target.scaleY;
				if (target is IFeathersControl)
				{
					(target as IFeathersControl).suspendEffects();
				}
				target.alignPivot(pivotHorizontalAlign, pivotVerticalAlign);
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
	}
}