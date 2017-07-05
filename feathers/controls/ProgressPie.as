package feathers.controls
{
	import com.esidegallery.utils.MathUtils;
	
	import feathers.core.FeathersControl;
	
	import starling.display.graphics.NGon;
	
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
				invalidate(INVALIDATION_FLAG_DATA);
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
				invalidate(INVALIDATION_FLAG_DATA);
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
				invalidate(INVALIDATION_FLAG_DATA);
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
		
		private var _incompleteColor:uint = 0xffffff;
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
		
		override protected function initialize():void
		{
			super.initialize();
			
			incomplete = new NGon;
			addChild(incomplete);
			complete = new NGon;
			addChild(complete);
		}
		
		override protected function draw():void
		{
			super.draw();
			
			if (isInvalid(INVALIDATION_FLAG_STYLES))
			{
				if (incomplete.material.color != incompleteColor)
					incomplete.material.color = incompleteColor;
				if (complete.material.color != completeColor)
					complete.material.color = completeColor;
				if (incomplete.numSides != _numSides)
					incomplete.numSides = complete.numSides = _numSides;
			}
			if (isInvalid(INVALIDATION_FLAG_DATA))
			{
				if (_minimumValue == _maximumValue)
					var completeAngle:Number = 360;
				else
				{
					completeAngle = (_currentValue - _minimumValue) / (_maximumValue - _minimumValue) * 360;
					if (completeAngle < 0.000001)
						completeAngle = 0.000001;
					else if (completeAngle > 360)
						completeAngle = 360;
				}
				if (incomplete.startAngle != completeAngle)
				{
					incomplete.startAngle = completeAngle;
					complete.endAngle = completeAngle;
					setRequiresRedraw();
				}
			}
			
			autoSizeIfNeeded();
			layoutChildren();
		}
		
		protected function autoSizeIfNeeded():Boolean
		{
			var needsWidth:Boolean = _explicitWidth !== _explicitWidth; //isNaN
			var needsHeight:Boolean = _explicitHeight !== _explicitHeight; //isNaN
			var needsMinWidth:Boolean = _explicitMinWidth !== _explicitMinWidth; //isNaN
			var needsMinHeight:Boolean = _explicitMinHeight !== _explicitMinHeight; //isNaN
			if (!needsWidth && !needsHeight && !needsMinWidth && !needsMinHeight)
				return false;
			
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
				incomplete.radius = complete.radius = outerRad;
			if (incomplete.innerRadius != innerRad)
				incomplete.innerRadius = complete.innerRadius = innerRad;
			
			incomplete.x = incomplete.y 
				= complete.x = complete.y
				= padding + outerRad;
		}
	}
}