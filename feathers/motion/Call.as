package feathers.motion
{
	import feathers.motion.effectClasses.IEffectContext;
	import feathers.motion.effectClasses.TweenEffectContext;

	import starling.animation.Tween;
	import starling.display.DisplayObject;
	import starling.utils.execute;

	/**
	 * Calls a function as an effect action. 
	 * The function can accept an optional <code>target:DisplayObject</code> argument.
	 */
	public class Call
	{
		public static function createEffect(functionToCall:Function):Function
		{
			return function(target:DisplayObject):IEffectContext
			{
				var called:Boolean = false;
				var tween:Tween = new Tween({prop: 0}, 0);
				// onComplete doesn't fire, so using onUpdate!
				tween.onUpdate = function():void
				{
					if (!called)
					{
						execute(functionToCall, target);
						called = true;
					}
				}
				tween.animate("prop", 1);
				return new TweenEffectContext(target, tween);
			}
		}
	}
}