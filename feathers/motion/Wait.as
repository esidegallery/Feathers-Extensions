package feathers.motion
{
	import feathers.motion.effectClasses.IEffectContext;
	import feathers.motion.effectClasses.TweenEffectContext;

	import starling.animation.Tween;
	import starling.display.DisplayObject;

	/**
	 * Waits for the duration before completing. To be used in effect sequences.
	 */
	public class Wait
	{
		public static function createEffect(duration:Number):Function
		{
			return function(target:DisplayObject):IEffectContext
			{
				var tween:Tween = new Tween({prop: 0}, duration);
				tween.animate("prop", 1);
				return new TweenEffectContext(target, tween);
			}
		}
	}
}