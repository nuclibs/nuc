package nuc.utils;

class Emitter {

	@:noCompletion public var bindings:Map<EventType<Dynamic>, Array<EmitHandler<Dynamic>>>;

	var _toRemove:Array<EmitDef<Dynamic>>;
	var _toAdd:Array<EmitHandler<Dynamic>>;
	var _processing:Bool;

	public function new() {
		bindings = new Map();

		_toRemove = [];
		_toAdd = [];
		_processing = false;
	}

	public function emit<T>(event:EventType<T>, ?data:T) {
		var list = bindings.get(event);

		if(list != null) {
			_processing = true;
			for (e in list) {
				e.callback(data);
			}
			_processing = false;

			if(_toRemove.length > 0) {
				for (e in _toRemove) {
					removeHandler(e.event, e.handler);
				}
				_toRemove.splice(0, _toRemove.length);
			}

			if(_toAdd.length > 0) {
				for (eh in _toAdd) {
					addHandler(eh);
				}
				_toAdd.splice(0, _toAdd.length);
			}
		}
	}

	public function on<T>(event:EventType<T>, handler:(e:T)->Void, priority:Int = 0) {
		if(hasHandler(event, handler)) return;
		
		if(_processing) {
			for (e in _toAdd) {
				if(e.callback == handler) return;
			}
			_toAdd.push(new EmitHandler<T>(event, handler, priority));
		} else {
			addHandler(new EmitHandler<T>(event, handler, priority));
		}
	}

	public function off<T>(event:EventType<T>, handler:(e:T)->Void):Bool {
		if(!hasHandler(event, handler)) return false;
		
		if(_processing) {
			for (e in _toRemove) {
				if(e.handler == handler) return false;
			}
			_toRemove.push(new EmitDef(event, handler));
		} else {
			removeHandler(event, handler);
		}

		return true;
	}

	function hasHandler<T>(event:EventType<T>, handler:(e:T)->Void):Bool {
		var list = bindings.get(event);

		if(list != null) {
			for (eh in list) {
				if(eh.callback == handler) return true;
			}
		}

		return false;
	}

	function addHandler<T>(emitHandler:EmitHandler<T>) {
		var list = bindings.get(emitHandler.event);
		if(list == null) {
			list = new Array<EmitHandler<T>>();
			list.push(emitHandler);
			bindings.set(emitHandler.event, list);
		} else {
			var atPos:Int = list.length;
			for (i in 0...list.length) {
				if (emitHandler.priority < list[i].priority) {
					atPos = i;
					break;
				}
			}
			list.insert(atPos, emitHandler);
		}
	}

	function removeHandler<T>(event:EventType<T>, handler:(e:T)->Void) {
		var list = bindings.get(event);
		
		var i = 0;
		while(i < list.length) {
			if(list[i].callback == handler) {
				list.splice(i, 1);
			} else {
				i++;
			}
		}

		if(list.length == 0) bindings.remove(event);
	}
	
}

private class EmitDef<T> {

	public var event:EventType<T>;
	public var handler:(e:T)->Void;

	public function new(event:EventType<T>, handler:(e:T)->Void) {
		this.event = event;
		this.handler = handler;
	}

}

private class EmitHandler<T> {

	public var event:EventType<T>;
	public var callback:(e:T)->Void;
	public var priority:Int;

	public function new(event:EventType<T>, callback:(e:T)->Void, priority:Int) {
		this.event = event;
		this.callback = callback;
		this.priority = priority;
	}

}