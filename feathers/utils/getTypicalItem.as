package feathers.utils
{
	import feathers.data.IListCollection;

	/**
	 * Iterates through the <code>dataSource</code> comparing the lengths of each item, returning the longest based on its <code>labelField</code>.<br/>
	 * Probably not recommended for very long data sources.
	 */
	public function getTypicalItem(dataSource:Object, labelField:String = "label", prompt:String = null):*
	{
		if (dataSource == null || !dataSource.hasOwnProperty("length") || dataSource["length"] < 1)
		{
			return null;
		}

		var longestItem:* = prompt;
		var longestLength:int = prompt != null ? prompt.length : null;
		var item:*;
		var length:int;

		for (var i:int = 0, l:int = dataSource.length; i < l; i++)
		{
			if (dataSource is IListCollection)
			{
				item = (dataSource as IListCollection).getItemAt(i);
			}
			else
			{
				item = dataSource[i];
			}
			if (item is Object && labelField && (item as Object).hasOwnProperty(labelField))
			{
				length = String(item[labelField]).length;
			}
			else
			{
				length = String(item).length;
			}

			if (length > longestLength)
			{
				longestItem = item;
				longestLength = length;
			}
		}
		return longestItem;
	}
}