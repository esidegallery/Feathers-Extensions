package feathers.motion
{
	import feathers.core.FeathersControl;
	import feathers.core.IStateContext;
	import feathers.core.IStateObserver;
	import feathers.core.IToggle;
	import feathers.events.FeathersEventType;

	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.extensions.starlingCallLater.callLater;
	import starling.extensions.starlingCallLater.clearCallLater;

	public class StateTweener implements IStateObserver
	{
		public var interruptBehavior:String = EffectInterruptBehavior.STOP;

		protected var _stateContext:IStateContext;
		public function get stateContext():feathers.core.IStateContext
		{
			return _stateContext;
		}
		public function set stateContext(value:feathers.core.IStateContext):void
		{
			if (_stateContext === value)
			{
				return;
			}
			if (_stateContext)
			{
				_stateContext.removeEventListener(FeathersEventType.STATE_CHANGE, stateContext_stageChangeHandler);
			}
			_stateContext = value;
			if (_stateContext)
			{
				_stateContext.addEventListener(FeathersEventType.STATE_CHANGE, stateContext_stageChangeHandler);
			}
			callLater(resetTween);
		}

		protected var _tweenTime:Number = 0.25;
		public function get tweenTime():Number
		{
			return _tweenTime;
		}
		public function set tweenTime(value:Number):void
		{
			if (value < 0)
			{
				value = 0;
			}
			if (_tweenTime != value)
			{
				_tweenTime = value;
				callLater(resetTween);
			}
		}

		protected var _tweenTransition:Object = Transitions.LINEAR;
		public function get tweenTransition():Object
		{
			return _tweenTransition;
		}
		public function set tweenTransition(value:Object):void
		{
			if (_tweenTransition != value)
			{
				_tweenTransition = value;
				callLater(resetTween);
			}
		}

		protected var defaultProperties:Object = new Object;
		public function setDefaultProperty(propertyName:String, value:Object):void
		{
			if (!(propertyName in defaultProperties) || defaultProperties[propertyName] != value)
			{
				defaultProperties[propertyName] = value;
				callLater(resetTween);
			}
		}
		public function hasDefaultProperty(propertyName:String):Boolean
		{
			return propertyName in defaultProperties;
		}
		public function getDefaultProperty(propertyName:String):Object
		{
			return defaultProperties[propertyName];
		}
		public function clearDefaultProperty(propertyName:String):void
		{
			if (propertyName in defaultProperties)
			{
				delete defaultProperties[propertyName];
				callLater(resetTween);
			}
		}

		protected var selectedProperties:Object = new Object;
		public function setSelectedProperty(propertyName:String, value:Object):void
		{
			if (!(propertyName in selectedProperties) || selectedProperties[propertyName] != value)
			{
				selectedProperties[propertyName] = value;
				callLater(resetTween);
			}
		}
		public function hasSelectedProperty(propertyName:String):Boolean
		{
			return propertyName in selectedProperties;
		}
		public function getSelectedProperty(propertyName:String):Object
		{
			return selectedProperties[propertyName];
		}
		public function clearSelectedProperty(propertyName:String):void
		{
			if (propertyName in selectedProperties)
			{
				delete selectedProperties[propertyName];
				callLater(resetTween);
			}
		}

		protected var disabledProperties:Object = new Object;
		public function setDisabledProperty(propertyName:String, value:Object):void
		{
			if (!(propertyName in disabledProperties) || disabledProperties[propertyName] != value)
			{
				disabledProperties[propertyName] = value;
				callLater(resetTween);
			}
		}
		public function hasDisabledProperty(propertyName:String):Boolean
		{
			return propertyName in disabledProperties;
		}
		public function getDisabledProperty(propertyName:String):Object
		{
			return disabledProperties[propertyName];
		}
		public function clearDisabledProperty(propertyName:String):void
		{
			if (propertyName in disabledProperties)
			{
				delete disabledProperties[propertyName];
				callLater(resetTween);
			}
		}

		/** 2D Object: The first axis being the state name, the second being the property name defining its value for the state. */
		protected var stateToProperties:Object = new Object;
		public function getPropertyForState(propertyName:String, state:String):Object
		{
			var properties:Object = stateToProperties[state];
			return properties && properties[propertyName];
		}
		public function setPropertyForState(propertyName:String, state:String, value:Object):void
		{
			var properties:Object = stateToProperties[state];
			if (!properties)
			{
				properties = new Object;
				stateToProperties[state] = properties;
			}
			if (properties[propertyName] != value)
			{
				properties[propertyName] = value;
				callLater(resetTween);
			}
		}
		public function hasPropertyForState(propertyName:String, state:String):Boolean
		{
			var properties:Object = stateToProperties[state];
			return properties && propertyName in properties;
		}
		/**
		 * @param propertyName
		 * @param state 
		 * @return Whether there was a property to clear.
		 */
		public function clearPropertyForState(propertyName:String, state:String):Boolean
		{
			var properties:Object = stateToProperties[state];
			if (properties && propertyName in properties)
			{
				delete properties[propertyName];
				callLater(resetTween);
				return true;
			}
			return false;
		}

		protected var _onStart:Function;
		public function get onStart():Function
		{
			return _onStart;
		}
		public function set onStart(value:Function):void
		{
			_onStart = value;
			if (tween)
			{
				tween.onStart = _onStart;
			}
		}

        protected var _onUpdate:Function;
        public function get onUpdate():Function
        {
        	return _onUpdate;
        }
        public function set onUpdate(value:Function):void
        {
        	_onUpdate = value;
			if (tween)
			{
				tween.onUpdate = _onUpdate;
			}
        }

        protected var _onComplete:Function;
        public function get onComplete():Function
        {
        	return _onComplete;
        }
        public function set onComplete(value:Function):void
        {
        	_onComplete = value;
			if (tween)
			{
				tween.onComplete = _onComplete;
			}
        }

		private var _tweenTarget:Object;
		public function get tweenTarget():Object
		{
			return _tweenTarget;
		}
		
		protected var tween:Tween;
		/** Used to track changes to target values of all properties. */
		protected var propertyToEndValue:Object

		public function StateTweener(tweenTarget:Object)
		{
			_tweenTarget = tweenTarget;
		}

		public function validate():void
		{
			clearCallLater(resetTween, true);
		}

		protected function stateContext_stageChangeHandler():void
		{
			resetTween();
		}

		protected function resetTween():void
		{
			clearCallLater(resetTween);

			if (!tweenTarget)
			{
				return;
			}
			
			var valuesChanged:Boolean = false;
			if (!propertyToEndValue)
			{
				propertyToEndValue = new Object;
				var firstTime:Boolean = true;
			}
			var referencedProperties:Object = new Object;

			if (_stateContext)
            {
				// Prioritise properties specifically for this state:
				var properties:Object = stateToProperties[_stateContext.currentState];
				for (var property:String in properties)
				{
					var value:Object = properties[property];
					if (!(property in propertyToEndValue) || propertyToEndValue[property] != value)
					{
						propertyToEndValue[property] = value;
						valuesChanged = true;
					}
					referencedProperties[property] = true;
				}

				// Add any unreferenced disabled properties if applicable:
				if (stateContext is FeathersControl &&
					!(stateContext as FeathersControl).isEnabled)
				{
					for (property in disabledProperties)
					{
						if (!(property in referencedProperties))
						{
							value = disabledProperties[property];
							if (!(property in propertyToEndValue) || propertyToEndValue[property] != value)
							{
								propertyToEndValue[property] = value;
								valuesChanged = true;
							}
							referencedProperties[property] = true;
						}
					}
				}

				// Then unreferenced selected properties if applicable:
				if (stateContext is IToggle &&
					(stateContext as IToggle).isSelected)
				{
					for (property in selectedProperties)
					{
						if (!(property in referencedProperties))
						{
							value = selectedProperties[property];
							if (!(property in propertyToEndValue) || propertyToEndValue[property] != value)
							{
								propertyToEndValue[property] = selectedProperties[property];
								valuesChanged = true;
							}
							referencedProperties[property] = true;
						}
					}	
				}
            }
			
			// Apply any unreferenced default properties:
			for (property in defaultProperties)
			{
				if (!(property in referencedProperties))
				{
					value = defaultProperties[property];
					if (!(property in propertyToEndValue) || propertyToEndValue[property] != value)
					{
						propertyToEndValue[property] = defaultProperties[property];
						valuesChanged = true;
					}
				}
			}

			if (_tweenTime > 0 && !firstTime && valuesChanged)
			{
				if (tween)
				{
					if (interruptBehavior == EffectInterruptBehavior.END)
					{
						try
						{
							for (property in propertyToEndValue)
							{
								_tweenTarget[property] = tween.getEndValue(property);
							}
						}
						catch (e:Error)
						{
							// Do nothing.
						}
					}
					tween.reset(_tweenTarget, _tweenTime, _tweenTransition);
				}
				else
				{
					tween = new Tween(_tweenTarget, _tweenTime, _tweenTransition);
				}
				for (property in propertyToEndValue)
				{
					tween.animate(property, propertyToEndValue[property]);
				}

				tween.onStart = _onStart;
				tween.onUpdate = _onUpdate;
				tween.onComplete = _onComplete;
				Starling.juggler.add(tween);
			}
			else
			{
				if (valuesChanged)
				{
					if (tween)
					{
						Starling.juggler.remove(tween);
					}
					if (_onStart != null)
					{
						_onStart.apply(this);
					}
					for (property in propertyToEndValue)
					{
						_tweenTarget[property] = propertyToEndValue[property];
					}
					if (_onUpdate != null)
					{
						_onUpdate.apply(this);
					}
					if (_onComplete != null)
					{
						_onComplete.apply(this);
					}
				}
			}
		}

		public function dispose():void
		{
			Starling.juggler.remove(tween);
			clearCallLater(resetTween);
		}
	}
}