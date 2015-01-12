#include "v8.h"
#include <vector>

namespace v8 {
	
	class NativeScriptExtension {
	public:
		static uint8_t* GetAddress(const v8::Handle<v8::Object>& obj);

		static void GetClosureObjects(v8::Isolate *isolate, const v8::Handle<v8::Function>& func, std::vector<v8::Local<v8::Value> >& result);
		
		static void GetAssessorPair(v8::Isolate *isolate, const v8::Handle<v8::Object>& obj, const v8::Handle<v8::String>& propName, v8::Handle<v8::Value>& getter, v8::Handle<v8::Value>& setter);

		static v8::Handle<v8::Array> GetPropertyKeys(v8::Isolate *isolate, const v8::Handle<v8::Object>& object);

	private:
		NativeScriptExtension();
	};
}

