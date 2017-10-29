package feathers.utils
{
	import starling.core.Starling;
	
	public class CustomScreenDensityScaleFactorManager extends ScreenDensityScaleFactorManager
	{
		private var _scaleAdjustment:Number;
		public function get scaleAdjustment():Number
		{
			return _scaleAdjustment;
		}
		public function set scaleAdjustment(value:Number):void
		{
			_scaleAdjustment = value;
			_calculatedScaleFactor = calculateScaleFactor();
			updateStarlingStageDimensions();
		}
		
		public function CustomScreenDensityScaleFactorManager(starling:Starling, scaleAdjustment:Number = 1)
		{
			_scaleAdjustment = scaleAdjustment;
			super(starling);
		}

		override protected function calculateScaleFactor():Number
		{
			return super.calculateScaleFactor() * scaleAdjustment;
		}
	}
}