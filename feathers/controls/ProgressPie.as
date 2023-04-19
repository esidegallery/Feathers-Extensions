package feathers.controls
{
	import feathers.core.FeathersControl;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.utils.math.clamp;

	import flash.display.BlendMode;

	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.extensions.QuadSection;
	import starling.textures.RenderTexture;
	import starling.utils.Color;

	public class ProgressPie extends FeathersControl
	{
		private var _minimumValue:Number = 0;
		public function get minimumValue():Number
		{
			return _minimumValue;
		}
		public function set minimumValue(value:Number):void
		{
			if (_minimumValue == value)
			{
				return;
			}
			_minimumValue = value;
			invalidate(INVALIDATION_FLAG_DATA);
		}

		private var _maximumValue:Number = 1;

		/** Set to <code>Number.POSITIVE_INFINITY</code> to make progress indefinite. */
		public function get maximumValue():Number
		{
			return _maximumValue;
		}
		public function set maximumValue(value:Number):void
		{
			if (_maximumValue == value)
			{
				return;
			}
			_maximumValue = value;
			invalidate(INVALIDATION_FLAG_DATA);
		}

		private var _currentValue:Number = 0;
		public function get currentValue():Number
		{
			return _currentValue;
		}
		public function set currentValue(value:Number):void
		{
			if (_currentValue == value)
			{
				return;
			}
			_currentValue = value;
			invalidate(INVALIDATION_FLAG_DATA);
		}

		private var _innerRadius:Number = 0;
		public function get innerRadius():Number
		{
			return _innerRadius;
		}

		/** In radians, so 0 = no radius, 1 = entire redius. */
		public function set innerRadius(value:Number):void
		{
			if (_innerRadius == value)
			{
				return;
			}
			_innerRadius = value;
			invalidate(INVALIDATION_FLAG_LAYOUT);
		}

		private var _incompleteColor:uint = Color.BLACK;
		public function get incompleteColor():uint
		{
			return _incompleteColor;
		}
		public function set incompleteColor(value:uint):void
		{
			if (_incompleteColor == value)
			{
				return;
			}
			_incompleteColor = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _completeColor:uint = Color.WHITE;
		public function get completeColor():uint
		{
			return _completeColor;
		}
		public function set completeColor(value:uint):void
		{
			if (_completeColor == value)
			{
				return;
			}
			_completeColor = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _incompleteAlpha:Number = 1;
		public function get incompleteAlpha():Number
		{
			return _incompleteAlpha;
		}
		public function set incompleteAlpha(value:Number):void
		{
			if (_incompleteAlpha == value)
			{
				return;
			}
			_incompleteAlpha = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _completeAlpha:Number = 1;
		public function get completeAlpha():Number
		{
			return _completeAlpha;
		}
		public function set completeAlpha(value:Number):void
		{
			if (_completeAlpha == value)
			{
				return;
			}
			_completeAlpha = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _padding:Number = 0;
		public function get padding():Number
		{
			return _padding;
		}
		public function set padding(value:Number):void
		{
			if (_padding == value)
			{
				return;
			}
			_padding = value;
			invalidate(INVALIDATION_FLAG_LAYOUT);
		}

		private var _numSides:uint = 25;
		public function get numSides():uint
		{
			return _numSides;
		}
		public function set numSides(value:uint):void
		{
			if (_numSides == value)
			{
				return;
			}
			_numSides = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _horizontalAlign:String = HorizontalAlign.CENTER;
		public function get horizontalAlign():String
		{
			return _horizontalAlign;
		}
		public function set horizontalAlign(value:String):void
		{
			if (_horizontalAlign == value)
			{
				return;
			}
			_horizontalAlign = value;
			invalidate(INVALIDATION_FLAG_LAYOUT);
		}

		private var _verticalAlign:String = VerticalAlign.MIDDLE;
		public function get verticalAlign():String
		{
			return _verticalAlign;
		}
		public function set verticalAlign(value:String):void
		{
			if (_verticalAlign == value)
			{
				return;
			}
			_verticalAlign = value;
			invalidate(INVALIDATION_FLAG_LAYOUT);
		}

		/** In indefinite mode, how many seconds it takes for the pie to loop round. */
		private var _loopDuration:Number = 1.75;
		public function get loopDuration():Number
		{
			return _loopDuration;
		}
		public function set loopDuration(value:Number):void
		{
			if (_loopDuration == value)
			{
				return;
			}
			_loopDuration = value;
			disposeTweens();
			invalidate(INVALIDATION_FLAG_DATA);
		}

		protected var donutTexture:RenderTexture;
		protected var incompleteDisplay:DisplayObject;
		protected var completeDisplay:DisplayObject;
		protected var incompleteMask:QuadSection;
		protected var completeMask:QuadSection;

		protected var ratioTweenID:int;
		protected var rotationTweenID:int;
		protected var tweenTarget:Object;
		protected var swapMasks:Boolean;

		override protected function initialize():void
		{
			super.initialize();
		}

		override protected function draw():void
		{
			if (autoSizeIfNeeded() || isInvalid())
			{
				if (donutTexture != null)
				{
					donutTexture.dispose();
					donutTexture = null;
				}
				if (incompleteDisplay != null)
				{
					incompleteDisplay.removeFromParent(true);
					incompleteDisplay = null;
				}
				if (incompleteMask != null)
				{
					incompleteMask.removeFromParent(true);
					incompleteMask = null;
				}
				if (completeDisplay != null)
				{
					completeDisplay.removeFromParent(true);
					completeDisplay = null;
				}
				if (completeMask != null)
				{
					completeMask.removeFromParent(true);
					completeMask = null;
				}

				var outerRad:Number = Math.max(0, (Math.min(actualWidth, actualHeight) - padding * 2) / 2);
				var innerRad:Number = clamp(outerRad * _innerRadius, 0, outerRad);

				var contentCentre:Number = _padding + outerRad;
				switch (_horizontalAlign)
				{
					case HorizontalAlign.LEFT:
						var centreX:Number = contentCentre;
						break;
					case HorizontalAlign.RIGHT:
						centreX = actualWidth - contentCentre;
						break;
					default: // CENTER:
						centreX = actualWidth / 2;
						break;
				}
				switch (_verticalAlign)
				{
					case VerticalAlign.TOP:
						var centreY:Number = contentCentre;
						break;
					case VerticalAlign.BOTTOM:
						centreY = actualHeight - contentCentre;
						break;
					default: // CENTER:
						centreY = actualHeight / 2;
						break;
				}

				if (_maximumValue == Number.POSITIVE_INFINITY)
				{
					// Spinning animation:
					tweenTarget ||= {};

					if (ratioTweenID == 0)
					{
						tweenTarget.ratio = 0;
						var tween:Tween = new Tween(tweenTarget, loopDuration);
						tween.repeatCount = 0;
						tween.animate("ratio", 1);
						tween.onUpdate = function():void
						{
							invalidate(INVALIDATION_FLAG_DATA);
						};
						tween.onRepeat = function():void
						{
							swapMasks = !swapMasks;
						};
						ratioTweenID = Starling.juggler.add(tween);
					}

					if (rotationTweenID == 0)
					{
						tweenTarget.rotation = 0;
						tween = new Tween(tweenTarget, loopDuration * 0.57143);
						tween.repeatCount = 0;
						tween.animate("rotation", Math.PI * 2);
						rotationTweenID = Starling.juggler.add(tween);
					}

					var ratio:Number = tweenTarget.ratio;
					var rotation:Number = tweenTarget.rotation;
				}
				else
				{
					disposeTweens();

					if (_minimumValue == _maximumValue)
					{
						ratio = 1;
					}
					else
					{
						ratio = (_currentValue - _minimumValue) / (_maximumValue - _minimumValue);
						if (ratio < 0)
						{
							ratio = 0;
						}
						else if (ratio > 1)
						{
							ratio = 1;
						}
					}
					rotation = 0;
				}

				var canvas:Canvas = new Canvas;
				canvas.beginFill(Color.WHITE);
				canvas.drawCircle(outerRad, outerRad, outerRad);
				canvas.endFill();
				var scaleFactor:Number = stage != null ? stage.starling.contentScaleFactor : Starling.current.contentScaleFactor;
				donutTexture = new RenderTexture(outerRad * 2, outerRad * 2, true, scaleFactor);
				donutTexture.drawBundled(function():void
				{
					donutTexture.draw(canvas);
					if (innerRad > 0)
					{
						canvas.clear();
						canvas.beginFill();
						canvas.drawCircle(outerRad, outerRad, innerRad);
						canvas.endFill();
						canvas.blendMode = BlendMode.ERASE;
						donutTexture.draw(canvas);
					}
				}, 4);

				if (ratio < 1)
				{
					var image:Image = new Image(donutTexture);
					image.alignPivot();
					image.color = _incompleteColor;
					image.alpha = _incompleteAlpha;
					incompleteDisplay = image;
					incompleteDisplay.x = centreX;
					incompleteDisplay.y = centreY;
					if (ratio > 0)
					{
						incompleteMask = new QuadSection(outerRad * 2, outerRad * 2);
						incompleteMask.alignPivot();
						incompleteMask.rotation = rotation;
						incompleteMask.ratio = ratio;
						incompleteMask.x = centreX;
						incompleteMask.y = centreY;
						addChild(incompleteMask);
						incompleteDisplay.mask = incompleteMask;
						incompleteDisplay.maskInverted = !swapMasks;
					}
					addChild(incompleteDisplay);
				}

				if (ratio > 0)
				{
					image = new Image(donutTexture);
					image.alignPivot();
					image.color = _completeColor;
					image.alpha = _completeAlpha;
					completeDisplay = image;
					completeDisplay.x = centreX;
					completeDisplay.y = centreY;
					if (ratio < 1)
					{
						completeMask = new QuadSection(outerRad * 2, outerRad * 2);
						completeMask.alignPivot();
						completeMask.rotation = rotation;
						completeMask.ratio = ratio;
						completeMask.x = centreX;
						completeMask.y = centreY;
						addChild(completeMask);
						completeDisplay.mask = completeMask;
						completeDisplay.maskInverted = swapMasks;
					}
					addChild(completeDisplay);
				}
			}

			super.draw();
		}

		protected function autoSizeIfNeeded():Boolean
		{
			var needsWidth:Boolean = _explicitWidth !== _explicitWidth; // isNaN
			var needsHeight:Boolean = _explicitHeight !== _explicitHeight; // isNaN
			var needsMinWidth:Boolean = _explicitMinWidth !== _explicitMinWidth; // isNaN
			var needsMinHeight:Boolean = _explicitMinHeight !== _explicitMinHeight; // isNaN
			if (!needsWidth && !needsHeight && !needsMinWidth && !needsMinHeight)
			{
				return false;
			}

			var newMinWidth:Number = _explicitMinWidth || padding * 2;
			var newMinHeight:Number = _explicitMinHeight || padding * 2;
			var newWidth:Number = _explicitWidth || padding * 2;
			var newHeight:Number = _explicitHeight || padding * 2;
			return this.saveMeasurements(newWidth || newHeight, newHeight || newWidth, newMinWidth, newMinHeight);
		}

		protected function disposeTweens():void
		{
			swapMasks = false;
			tweenTarget = null;
			if (ratioTweenID != 0)
			{
				Starling.juggler.removeByID(ratioTweenID);
				ratioTweenID = 0;
			}
			if (rotationTweenID != 0)
			{
				Starling.juggler.removeByID(rotationTweenID);
				rotationTweenID = 0;
			}
		}

		override public function dispose():void
		{
			disposeTweens();
			if (donutTexture != null)
			{
				donutTexture.dispose();
				donutTexture = null;
			}

			super.dispose();
		}
	}
}