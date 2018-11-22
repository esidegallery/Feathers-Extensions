package feathers.utils
{
	import feathers.system.DeviceCapabilities;
	
	import starling.core.Starling;
	
	/** 
	 * Converts a value from pixels to inches based on the screen DPI and <code>contentScaleFactor</code>.
	 * @param px:Number The value in pixels.
	 * @param starling:Starling The Starling instance to use, if not passed, <code>Starling.current</code> is used. 
	 */
	public function inchesToPixels(inches:Number, starling:Starling = null):Number
	{
		starling ||= Starling.current;
		return inches * (DeviceCapabilities.dpi / starling.contentScaleFactor);
	}
}