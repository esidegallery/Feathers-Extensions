package feathers.controls.text
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.FontType;
	import flash.text.engine.CFFHinting;
	import flash.text.engine.ElementFormat;
	import flash.text.engine.FontDescription;
	import flash.text.engine.FontLookup;
	import flash.text.engine.FontPosture;
	import flash.text.engine.FontWeight;
	import flash.text.engine.Kerning;
	import flash.text.engine.RenderingMode;
	import flash.text.engine.TextLine;

	import starling.core.Starling;
	import starling.text.TextFormat;
	import starling.utils.Align;
	import starling.utils.Pool;
	import starling.utils.SystemUtil;

	/**
	 * <p>Adds the following functionality:</p>
	 * <li><code>maxLines</code></li>
	 * <li><code>isTruncated</code></li>
	 * <li><code>autoToolTipWhenTruncated</code></li>
	 */
	public class TextBlockTextRendererExtended extends TextBlockTextRenderer
	{
		private static const HELPER_TEXT_LINES:Vector.<TextLine> = new <TextLine>[];
		private static const HELPER_MATRIX:Matrix = new Matrix;

		public function get isTruncated():Boolean
		{
			return _lastMeasurementWasTruncated;
		}

		protected var _customToolTip:String;

		/**
		 * Will be overridden when <code>autoToolTipWhenTruncated = true</code>
		 * and text is truncated.
		 */
		override public function set toolTip(value:String):void
		{
			if (_customToolTip == value)
			{
				return;
			}
			_customToolTip = value;
			invalidate(INVALIDATION_FLAG_SIZE); // Validates the text lines.
		}

		private var _autoToolTipWhenTruncated:Boolean;

		/**
		 * Automatically sets the tooltip to the full text when it it truncated, overriding any
		 * value set externally via <code>toolTip</code>.
		 */
		public function get autoToolTipWhenTruncated():Boolean
		{
			return _autoToolTipWhenTruncated;
		}
		public function set autoToolTipWhenTruncated(value:Boolean):void
		{
			if (_autoToolTipWhenTruncated == value)
			{
				return;
			}
			_autoToolTipWhenTruncated = value;
			invalidate(INVALIDATION_FLAG_SIZE); // Validates the text lines.
		}

		private var _maxLines:int = 0;
		public function get maxLines():int
		{
			return _maxLines;
		}
		public function set maxLines(value:int):void
		{
			if (_maxLines == value)
			{
				return;
			}
			_maxLines = value;
			invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * CFF hinting is recommended for smaller text, and can look add at the baseline at larger sizes.
		 * This sets the text size at and above which CFF hinting will be disabled. 
		 * This value will also take Starling content scale factor into account.
		 */
		private var _disableCFFHintingThreshold:Number = 26;
		public function get disableCFFHintingThreshold():Number
		{
			return _disableCFFHintingThreshold;
		}
		public function set disableCFFHintingThreshold(value:Number):void
		{
			if (_disableCFFHintingThreshold == value)
			{
				return;
			}
			_disableCFFHintingThreshold = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		public function TextBlockTextRendererExtended()
		{
			super();

			_truncationText = "…";
		}

		override protected function refreshTextLines(textLines:Vector.<TextLine>,
				textLineParent:DisplayObjectContainer, width:Number, height:Number,
				result:MeasureTextResult = null):MeasureTextResult
		{
			// clamp the width and height values to a valid range so that it
			// doesn't break the measurement
			if (width < 0)
			{
				width = 0;
			}
			else if (width > MAX_TEXT_LINE_WIDTH)
			{
				width = MAX_TEXT_LINE_WIDTH;
			}
			if (height < 0)
			{
				height = 0;
			}

			var lineCount:int = textLines.length;
			// copy the invalid text lines over to the helper vector so that we
			// can reuse them
			HELPER_TEXT_LINES.length = 0;
			for (var i:int = 0; i < lineCount; i++)
			{
				HELPER_TEXT_LINES[i] = textLines[i];
			}
			textLines.length = 0;

			this.refreshTextElementText();

			var wasTruncated:Boolean = false;
			var maxLineWidth:Number = 0;
			var yPosition:Number = 0;
			if (width >= 0)
			{
				var line:TextLine = null;
				var lineStartIndex:int = 0;
				var pushIndex:int = textLines.length;
				var inactiveTextLineCount:int = HELPER_TEXT_LINES.length;
				while (true)
				{
					this._truncationOffset = 0;
					var lastLine:Boolean = !this._wordWrap || _maxLines > 0 && pushIndex == _maxLines - 1;
					var canTruncate:Boolean = this._truncateToFit && this._textElement && lastLine;
					var previousLine:TextLine = line;
					var lineWidth:Number = width;
					if (lastLine)
					{
						lineWidth = MAX_TEXT_LINE_WIDTH;
					}
					if (inactiveTextLineCount > 0)
					{
						var inactiveLine:TextLine = HELPER_TEXT_LINES[0];
						line = this.textBlock.recreateTextLine(inactiveLine, previousLine, lineWidth, 0, true);
						if (line)
						{
							HELPER_TEXT_LINES.shift();
							inactiveTextLineCount--;
						}
					}
					else
					{
						line = this.textBlock.createTextLine(previousLine, lineWidth, 0, true);
						if (line)
						{
							textLineParent.addChild(line);
						}
					}
					if (!line)
					{
						// end of text
						break;
					}
					var lineLength:int = line.rawTextLength;
					var isTruncated:Boolean = false;
					var difference:Number = 0;
					while (canTruncate && (difference = line.width - width) > FUZZY_TRUNCATION_DIFFERENCE)
					{
						isTruncated = true;
						if (this._truncationOffset == 0)
						{
							// this will quickly skip all of the characters after
							// the maximum width of the line, instead of going
							// one by one.
							var endIndex:int = line.getAtomIndexAtPoint(width, 0);
							if (endIndex >= 0)
							{
								this._truncationOffset = line.rawTextLength - endIndex;
							}
						}
						this._truncationOffset++;
						var truncatedTextLength:int = lineLength - this._truncationOffset;
						// we want to start at this line so that the previous
						// lines don't become invalid.
						var truncatedText:String = this._text.substr(lineStartIndex, truncatedTextLength) + this._truncationText;
						var lineBreakIndex:int = this._text.indexOf(LINE_FEED, lineStartIndex);
						if (lineBreakIndex < 0)
						{
							lineBreakIndex = this._text.indexOf(CARRIAGE_RETURN, lineStartIndex);
						}
						if (lineBreakIndex >= 0)
						{
							truncatedText += this._text.substr(lineBreakIndex);
						}
						this._textElement.text = truncatedText;
						line = this.textBlock.recreateTextLine(line, null, lineWidth, 0, true);
						if (truncatedTextLength <= 0)
						{
							break;
						}
					}
					if (pushIndex > 0)
					{
						yPosition += this._currentLeading;
					}

					if (line.width > maxLineWidth)
					{
						maxLineWidth = line.width;
					}
					yPosition += this.calculateLineAscent(line);
					line.y = yPosition;
					yPosition += line.totalDescent;
					textLines[pushIndex] = line;
					pushIndex++;
					lineStartIndex += lineLength;
					wasTruncated ||= isTruncated;
				}
			}
			if (textLines !== this._measurementTextLines)
			{
				// no need to align the measurement text lines because they won't
				// be rendered
				this.alignTextLines(textLines, width, this._currentHorizontalAlign);
			}
			if (this._currentHorizontalAlign === Align.RIGHT)
			{
				maxLineWidth = width;
			}
			else if (this._currentHorizontalAlign === Align.CENTER)
			{
				maxLineWidth = (width + maxLineWidth) / 2;
			}

			inactiveTextLineCount = HELPER_TEXT_LINES.length;
			for (i = 0; i < inactiveTextLineCount; i++)
			{
				line = HELPER_TEXT_LINES[i];
				textLineParent.removeChild(line);
			}
			HELPER_TEXT_LINES.length = 0;
			if (result === null)
			{
				result = new MeasureTextResult(maxLineWidth, yPosition, wasTruncated);
			}
			else
			{
				result.width = maxLineWidth;
				result.height = yPosition;
				result.isTruncated = wasTruncated;
			}

			if (textLines !== this._measurementTextLines)
			{
				if (result.width >= 1 && result.height >= 1 &&
						this._nativeFilters !== null && this._nativeFilters.length > 0)
				{
					var starling:Starling = this.stage !== null ? this.stage.starling : Starling.current;
					var scaleFactor:Number = starling.contentScaleFactor;
					HELPER_MATRIX.identity();
					HELPER_MATRIX.scale(scaleFactor, scaleFactor);
					var bitmapData:BitmapData = new BitmapData(result.width, result.height, true, 0x00ff00ff);
					var rect:Rectangle = Pool.getRectangle();
					bitmapData.draw(this._textLineContainer, HELPER_MATRIX, null, null, rect);
					this.measureNativeFilters(bitmapData, rect);
					bitmapData.dispose();
					bitmapData = null;
					this._textSnapshotOffsetX = rect.x;
					this._textSnapshotOffsetY = rect.y;
					this._textSnapshotNativeFiltersWidth = rect.width;
					this._textSnapshotNativeFiltersHeight = rect.height;
					Pool.putRectangle(rect);
				}
				else
				{
					this._textSnapshotOffsetX = 0;
					this._textSnapshotOffsetY = 0;
					this._textSnapshotNativeFiltersWidth = 0;
					this._textSnapshotNativeFiltersHeight = 0;
				}
			}
			if (_autoToolTipWhenTruncated && result.isTruncated)
			{
				super.toolTip = text;
			}
			else
			{
				super.toolTip = _customToolTip;
			}
			return result;
		}

		override protected function getElementFormatFromFontStyles():ElementFormat
		{
			if (this.isInvalid(INVALIDATION_FLAG_STYLES) || this.isInvalid(INVALIDATION_FLAG_STATE))
			{
				var textFormat:TextFormat;
				if (this._fontStyles !== null)
				{
					textFormat = this._fontStyles.getTextFormatForTarget(this);
				}
				if (textFormat !== null)
				{
					var fontWeight:String = FontWeight.NORMAL;
					if (textFormat.bold)
					{
						fontWeight = FontWeight.BOLD;
					}
					var fontPosture:String = FontPosture.NORMAL;
					if (textFormat.italic)
					{
						fontPosture = FontPosture.ITALIC;
					}
					var fontLookup:String = FontLookup.DEVICE;
					if (SystemUtil.isEmbeddedFont(textFormat.font, textFormat.bold, textFormat.italic, FontType.EMBEDDED_CFF))
					{
						fontLookup = FontLookup.EMBEDDED_CFF;
					}
					var fontDescription:FontDescription = new FontDescription(
							textFormat.font,
							fontWeight,
							fontPosture,
							fontLookup,
							RenderingMode.CFF,
							textFormat.size * Starling.contentScaleFactor >= disableCFFHintingThreshold ? CFFHinting.NONE : CFFHinting.HORIZONTAL_STEM);
					this._fontStylesElementFormat = new ElementFormat(fontDescription, textFormat.size, textFormat.color);
					if (textFormat.kerning)
					{
						this._fontStylesElementFormat.kerning = Kerning.ON;
					}
					else
					{
						this._fontStylesElementFormat.kerning = Kerning.OFF;
					}
					var letterSpacing:Number = textFormat.letterSpacing / 2;
					// adobe documentation recommends splitting it between
					// left and right
					// http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/text/engine/ElementFormat.html#trackingRight
					this._fontStylesElementFormat.trackingRight = letterSpacing;
					this._fontStylesElementFormat.trackingLeft = letterSpacing;
					this._currentLeading = textFormat.leading;
					this._currentVerticalAlign = textFormat.verticalAlign;
					this._currentHorizontalAlign = textFormat.horizontalAlign;
				}
				else if (this._fontStylesElementFormat === null)
				{
					// fallback to a default so that something is displayed
					this._fontStylesElementFormat = new ElementFormat();
					this._currentLeading = 0;
					this._currentVerticalAlign = Align.TOP;
					this._currentHorizontalAlign = Align.LEFT;
				}
			}
			return this._fontStylesElementFormat;
		}
	}
}