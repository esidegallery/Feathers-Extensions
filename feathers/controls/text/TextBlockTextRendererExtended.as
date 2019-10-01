package feathers.controls.text
{
	import flash.display.DisplayObjectContainer;
	import flash.text.engine.TextLine;
	
	public class TextBlockTextRendererExtended extends TextBlockTextRenderer
	{
		public static const MEASURE_TEXT_RESULT:String = "measureTextResult";
		
		override protected function refreshTextLines(textLines:Vector.<TextLine>, textLineParent:DisplayObjectContainer, width:Number, height:Number, result:MeasureTextResult = null):MeasureTextResult
		{
			result = super.refreshTextLines(textLines, textLineParent, width, height, result);
			dispatchEventWith(MEASURE_TEXT_RESULT, false, result);
			return result;
		}
	}
}