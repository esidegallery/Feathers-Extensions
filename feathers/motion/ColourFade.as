package feathers.motion
{
	import feathers.motion.effectClasses.IEffectContext;
	import feathers.motion.effectClasses.TweenEffectContext;

	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.DisplayObject;

	public class ColourFade
	{
		protected static const SCREEN_REQUIRED_ERROR:String = "Cannot transition if both old screen and new screen are null.";

		public static function createBlackFadeTransition(duration:Number = 0.75, ease:Object = Transitions.EASE_OUT_IN, tweenProperties:Object = null):Function
		{
			return createColorFadeTransition(0x000000, duration, ease, tweenProperties);
		}

		public static function createWhiteFadeTransition(duration:Number = 0.75, ease:Object = Transitions.EASE_OUT_IN, tweenProperties:Object = null):Function
		{
			return createColorFadeTransition(0xffffff, duration, ease, tweenProperties);
		}

		public static function createColorFadeTransition(color:uint, duration:Number = 0.75, ease:Object = Transitions.EASE_OUT_IN, tweenProperties:Object = null):Function
		{
			return function(oldScreen:DisplayObject, newScreen:DisplayObject, onComplete:Function, managed:Boolean = false):IEffectContext
			{
				if (oldScreen == null && newScreen == null)
				{
					throw new ArgumentError(SCREEN_REQUIRED_ERROR);
				}

				if (oldScreen)
				{
					oldScreen.visible = true;
				}

				if (newScreen)
				{
					newScreen.visible = false;
					var tween:ColorFadeTween = new ColorFadeTween(newScreen, oldScreen, color, duration, ease, onComplete, tweenProperties);
				}
				else // We only have the old screen
				{
					tween = new ColorFadeTween(oldScreen, null, color, duration, ease, onComplete, tweenProperties);
				}

				if (managed)
				{
					return new TweenEffectContext(null, tween);
				}
				Starling.juggler.add(tween);
				return null;
			};
		}
	}
}

import starling.animation.Tween;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Quad;

class ColorFadeTween extends Tween
{
	private var _otherTarget:DisplayObject;
	private var _overlay:Quad;
	private var _onCompleteCallback:Function;

	public function ColorFadeTween(target:DisplayObject, otherTarget:DisplayObject,
			color:uint, duration:Number, ease:Object, onCompleteCallback:Function,
			tweenProperties:Object)
	{
		super(target, duration, ease);

		if (tweenProperties)
		{
			for (var propertyName:String in tweenProperties)
			{
				this[propertyName] = tweenProperties[propertyName];
			}
		}

		_otherTarget = otherTarget;

		onUpdate = updateOverlay;
		_onCompleteCallback = onCompleteCallback;
		onComplete = cleanupTween;

		var navigator:DisplayObjectContainer = target.parent;
		_overlay = new Quad(1, 1, color);
		_overlay.width = navigator.width;
		_overlay.height = navigator.height;
		_overlay.alpha = 0;
		_overlay.touchable = false;
		navigator.addChild(_overlay);
	}

	private function updateOverlay():void
	{
		var fadeColourInTo:Number = 5 / 12;
		var solidColourTo:Number = 8 / 12;
		if (progress < fadeColourInTo)
		{
			target.visible = false;
			if (_otherTarget)
			{
				_otherTarget.visible = true;
			}
			_overlay.alpha = progress / fadeColourInTo;
		}
		else if (progress < solidColourTo)
		{
			target.visible = false;
			if (_otherTarget)
			{
				_otherTarget.visible = false;
			}
			_overlay.alpha = 1;
		}
		else
		{
			target.visible = true;
			if (_otherTarget)
			{
				_otherTarget.visible = false;
			}
			_overlay.alpha = 1 - (progress - solidColourTo) / (1 - solidColourTo);
		}
	}

	private function cleanupTween():void
	{
		_overlay.removeFromParent(true);
		target.visible = true;
		if (_otherTarget)
		{
			_otherTarget.visible = true;
		}
		if (_onCompleteCallback !== null)
		{
			_onCompleteCallback();
		}
	}
}