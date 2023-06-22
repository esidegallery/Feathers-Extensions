package feathers.motion.effectClasses
{
	import feathers.motion.effectClasses.BaseEffectContext;
	import feathers.motion.effectClasses.IEffectContext;

	import starling.display.DisplayObject;

	public class ParallelEasedEffectContext extends BaseEffectContext implements IEffectContext
	{
		public function ParallelEasedEffectContext(target:DisplayObject, functions:Array, transition:Object = null)
		{
			var duration:Number = 0;
			var count:int = functions.length;
			for (var i:int = 0; i < count; i++)
			{
				var func:Function = functions[i] as Function;
				var context:IEffectContext = IEffectContext(func(target));
				_contexts[i] = context;
				var contextDuration:Number = context.duration;
				if (contextDuration > duration)
				{
					duration = contextDuration;
				}
			}
			super(target, duration, transition);
		}

		protected var _contexts:Vector.<IEffectContext> = new <IEffectContext>[];

		override protected function updateEffect():void
		{
			var ratio:Number = _position * _duration;
			var contextCount:int = _contexts.length;
			for (var i:int = 0; i < contextCount; i++)
			{
				var context:IEffectContext = _contexts[i] as IEffectContext;
				context.position = ratio / context.duration;
			}
		}
	}
}