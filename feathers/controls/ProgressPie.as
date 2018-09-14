package feathers.controls
{
	import com.esidegallery.utils.MathUtils;
	
	import feathers.core.FeathersControl;
	
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.graphics.NGon;
	import starling.events.Event;
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
			if (_minimumValue != value)
			{
				minimumValue = value;
				invalidateData();
			}
		}

		private var _maximumValue:Number = 1;
		public function get maximumValue():Number
		{
			return _maximumValue;
		}
		public function set maximumValue(value:Number):void
		{
			if (_maximumValue != value)
			{
				_maximumValue = value;
				invalidateData();
			}
		}

		private var _currentValue:Number = 0;
		public function get currentValue():Number
		{
			return _currentValue;
		}
		public function set currentValue(value:Number):void
		{
			if (_currentValue != value)
			{
				_currentValue = value;
				invalidateData();
			}
		}

		private var _innerRadius:Number = 0;
		public function get innerRadius():Number
		{
			return _innerRadius;
		}
		/** In radians, so 0 = no radius, 1 = entire redius. */
		public function set innerRadius(value:Number):void
		{
			if (_innerRadius != value)
			{
				_innerRadius = value;
				invalidate(INVALIDATION_FLAG_LAYOUT);
			}
		}
		
		protected var _showIncomplete:Boolean = true;
		public function get showIncomplete():Boolean
		{
			return _showIncomplete;
		}
		public function set showIncomplete(value:Boolean):void
		{
			if (_showIncomplete != value)
			{
				_showIncomplete = value;
				invalidate(INVALIDATION_FLAG_STYLES);
			}
		}
		
		private var _incompleteColor:uint = Color.WHITE;
		public function get incompleteColor():uint
		{
			return _incompleteColor;
		}
		public function set incompleteColor(value:uint):void
		{
			if (_incompleteColor != value)
			{
				_incompleteColor = value;
				invalidate(INVALIDATION_FLAG_STYLES);
			}
		}

		private var _completeColor:uint = 0;
		public function get completeColor():uint
		{
			return _completeColor;
		}
		public function set completeColor(value:uint):void
		{
			if (_completeColor != value)
			{
				_completeColor = value;
				invalidate(INVALIDATION_FLAG_STYLES);
			}
		}
		
		private var _padding:Number = 0;
		public function get padding():Number
		{
			return _padding;
		}
		public function set padding(value:Number):void
		{
			if (_padding != value)
			{
				_padding = value;
				invalidate(INVALIDATION_FLAG_LAYOUT);
			}
		}
		
		private var _numSides:uint = 25;
		public function get numSides():uint
		{
			return _numSides;
		}
		public function set numSides(value:uint):void
		{
			if (_numSides != value)
			{
				_numSides = value;
				invalidate(INVALIDATION_FLAG_STYLES);
			}
		}

		protected var incomplete:NGon;
		protected var complete:NGon;
		
		private var autoTween1:Tween;
		private var autoTween2:Tween;
		private var tweenTarget:Object = {start: 0, end: 0};
		private var tweenSwapStartAndEnd:Boolean;
		private var tweenAngleIsObtuse:Boolean;
		
		/** In indefinite mode, how many seconds it takes for the ring to loop round. */ 
		public var loopDuration:Number = 1.75;
		
		override protected function initialize():void
		{
			super.initialize();
			
			incomplete = new NGon;
			addChild(incomplete);
			complete = new NGon;
			addChild(complete);
			
			addEventListener(Event.REMOVED_FROM_STAGE, disposeTweens);
		}
		
		override protected function draw():void
		{
			super.draw();
			
			if (isInvalid(INVALIDATION_FLAG_STYLES))
			{
				if (incomplete.visible != showIncomplete)
				{
					incomplete.visible = showIncomplete;
				}
				if (incomplete.material.color != incompleteColor)
				{
					incomplete.material.color = incompleteColor;
				}
				if (complete.material.color != completeColor)
				{
					complete.material.color = completeColor;
				}
				if (incomplete.numSides != _numSides)
				{
					incomplete.numSides = complete.numSides = _numSides;
				}
			}
			if (isInvalid(INVALIDATION_FLAG_DATA))
			{
				if (_maximumValue == Number.MAX_VALUE)
				{
					if (!autoTween1)
					{
						tweenTarget.start = tweenTarget.end = 0;
						tweenUpdateHandler();
						autoTween1 = new Tween(tweenTarget, loopDuration);
						autoTween1.repeatCount = 0;
						autoTween1.onUpdate = tweenUpdateHandler;
						autoTween1.animate("start", 360);
						
						autoTween2 = new Tween(tweenTarget, loopDuration * 0.57143);
						autoTween2.repeatCount = 0;
						autoTween2.animate("end", 360);
						
						Starling.juggler.add(autoTween1);
						Starling.juggler.add(autoTween2);
					}
				}
				else if (autoTween1)
				{
					disposeTweens();
				}
				
				if (!autoTween1)
				{
					if (_minimumValue == _maximumValue)
					{
						var completeStartAngle:Number = 0;
						var completeEndAngle:Number = 360;
					}
					else
					{
						completeStartAngle = 0;
						completeEndAngle = (_currentValue - _minimumValue) / (_maximumValue - _minimumValue) * 360;
						if (completeEndAngle < 0.000001)
						{
							completeEndAngle = 0.000001;
						}
						else if (completeEndAngle > 360)
						{
							completeEndAngle = 360;
						}
					}
					if (incomplete.startAngle != completeEndAngle || incomplete.endAngle != completeStartAngle)
					{
						incomplete.startAngle = completeEndAngle;
						incomplete.endAngle = completeStartAngle;
						complete.startAngle = completeStartAngle;
						complete.endAngle = completeEndAngle;
						setRequiresRedraw();
					}
				}
			}
			
			autoSizeIfNeeded();
			layoutChildren();
		}
		
		override public function set alpha(value:Number):void
		{
			super.alpha = value;
		}
		
		private function tweenUpdateHandler():void
		{
			var start:Number = tweenTarget.start;
			var end:Number = tweenTarget.end;
			if (end < start)
			{
				end += 360;
			}
			var isObtuseNow:Boolean = end - start > 180;
			if (isObtuseNow != tweenAngleIsObtuse && end - start < 180) // Detects a crossover between start and end.
			{
				tweenSwapStartAndEnd = !tweenSwapStartAndEnd;
			}
			complete.startAngle = tweenSwapStartAndEnd ? end : start;
			complete.endAngle = tweenSwapStartAndEnd ? start : end;
			incomplete.startAngle = complete.endAngle;
			incomplete.endAngle = complete.startAngle;
			tweenAngleIsObtuse = isObtuseNow;
			setRequiresRedraw();
		}
		
		protected function autoSizeIfNeeded():Boolean
		{
			var needsWidth:Boolean = _explicitWidth !== _explicitWidth; //isNaN
			var needsHeight:Boolean = _explicitHeight !== _explicitHeight; //isNaN
			var needsMinWidth:Boolean = _explicitMinWidth !== _explicitMinWidth; //isNaN
			var needsMinHeight:Boolean = _explicitMinHeight !== _explicitMinHeight; //isNaN
			if (!needsWidth && !needsHeight && !needsMinWidth && !needsMinHeight)
			{
				return false;
			}
			
			var newMinWidth:Number = _explicitMinWidth || 0;
			var newMinHeight:Number = _explicitMinHeight || 0;
			var newWidth:Number = _explicitWidth || padding * 2;
			var newHeight:Number = _explicitHeight || padding * 2;
			return this.saveMeasurements(newWidth || newHeight, newHeight || newWidth, newMinWidth, newMinHeight);
		}
		
		protected function layoutChildren():void
		{
			var outerRad:Number = Math.max(0, (Math.min(actualWidth, actualHeight) - padding * 2) / 2);
			var innerRad:Number = MathUtils.minMax(outerRad * innerRadius, 0, outerRad);
			if (incomplete.radius != outerRad)
			{
				incomplete.radius = complete.radius = outerRad;
			}
			if (incomplete.innerRadius != innerRad)
			{
				incomplete.innerRadius = complete.innerRadius = innerRad;
			}
			
			incomplete.x = incomplete.y 
				= complete.x = complete.y
				= padding + outerRad;
		}
		
		private function disposeTweens():void
		{
			Starling.juggler.removeTweens(tweenTarget);
			if (autoTween1)
			{
				autoTween1.onUpdate = null;
				autoTween1.reset(null, 0);
			}
			if (autoTween2)
			{
				autoTween2.reset(null, 0);
			}
			autoTween1 = null;
			autoTween2 = null;
		}
		
		public function invalidateData():void
		{
			invalidate(INVALIDATION_FLAG_DATA);
		}
		
		override public function dispose():void
		{
			disposeTweens();
			super.dispose();
		}
	}
}