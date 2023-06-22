package feathers.motion
{
	import feathers.motion.effectClasses.IEffectContext;
	import feathers.motion.effectClasses.ParallelEasedEffectContext;

	import starling.display.DisplayObject;

	public class ParallelEased
	{
		public static function createParallelEffect(ease:Object, effect1:Function, effect2:Function, ...rest:Array):Function
		{
			rest[rest.length] = effect1;
			rest[rest.length] = effect2;
			return function(target:DisplayObject):IEffectContext
			{
				return new ParallelEasedEffectContext(target, rest, ease);
			};
		}
	}
}