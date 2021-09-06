package feathers.motion
{
	import feathers.motion.effectClasses.IEffectContext;
	import feathers.motion.effectClasses.TweenEffectContext;

	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.DisplayObject;

	public class Crossfade
	{
		protected static const SCREEN_REQUIRED_ERROR:String = "Cannot transition if both old screen and new screen are null.";
		
		public static function createTransition(duration:Number = 0.5, ease:Object = Transitions.EASE_OUT, tweenProperties:Object = null):Function
		{
			return function(oldScreen:DisplayObject, newScreen:DisplayObject, onComplete:Function, managed:Boolean = false):IEffectContext
			{
				if (oldScreen == null && newScreen == null)
				{
					throw new ArgumentError(SCREEN_REQUIRED_ERROR);
				}
				var tween:CrossfadeTween = new CrossfadeTween(newScreen, oldScreen, duration, ease, onComplete, tweenProperties);
				if (managed)
				{
					return new TweenEffectContext(null, tween);
				}
				Starling.juggler.add(tween);
				return null;
			}
		}
	}
}

import feathers.display.RenderDelegate;

import starling.animation.Tween;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.filters.FragmentFilterPatched;

class CrossfadeTween extends Tween
{
	private var navigator:DisplayObjectContainer;
	private var savedNewScreen:DisplayObject;
	private var savedOldScreen:DisplayObject;
	private var targetDelegate:RenderDelegate;
	private var onCompleteCallback:Function;

	public function CrossfadeTween(newScreen:DisplayObject, oldScreen:DisplayObject,
		duration:Number, ease:Object, onCompleteCallback:Function,
		tweenProperties:Object)
	{
		if (newScreen != null)
		{
			navigator = newScreen.parent;
			targetDelegate = new RenderDelegate(newScreen);
			targetDelegate.blendMode = newScreen.blendMode;
			targetDelegate.rotation = newScreen.rotation;
			targetDelegate.scaleX = newScreen.scaleX;
			targetDelegate.scaleY = newScreen.scaleY;
			targetDelegate.alpha = 0;
			navigator.addChild(targetDelegate);
			newScreen.visible = false;
			savedNewScreen = newScreen;
		}
		else if (oldScreen != null)
		{
			navigator = oldScreen.parent;
			targetDelegate = RenderDelegate(oldScreen);
			targetDelegate.blendMode = oldScreen.blendMode;
			targetDelegate.rotation = oldScreen.rotation;
			targetDelegate.scaleX = oldScreen.scaleX;
			targetDelegate.scaleY = oldScreen.scaleY;
			targetDelegate.alpha = 1;
			navigator.addChild(targetDelegate);
			oldScreen.visible = false;
			savedOldScreen = oldScreen;
		}

		// Unfortunately, still needed:
		targetDelegate.filter = new FragmentFilterPatched;
		super(targetDelegate, duration, ease);

		if (targetDelegate.alpha == 0)
		{
			fadeTo(1);
		}
		else
		{
			fadeTo(0);
		}

		if (tweenProperties != null)
		{
			for(var propertyName:String in tweenProperties)
			{
				this[propertyName] = tweenProperties[propertyName];
			}
		}

		this.onCompleteCallback = onCompleteCallback;
		onComplete = cleanupTween;
	}

	private function cleanupTween():void
	{
		if (targetDelegate != null)
		{
			if (targetDelegate.filter != null)
			{
				targetDelegate.filter.dispose();
				targetDelegate.filter = null;
			}
			targetDelegate.removeFromParent(true);
		}
		if (savedNewScreen != null)
		{
			savedNewScreen.visible = true;
			savedNewScreen = null;
		}
		if (savedOldScreen != null)
		{
			savedOldScreen.visible = true;
			savedOldScreen = null;
		}
		if (onCompleteCallback != null)
		{
			onCompleteCallback();
		}
	}
}