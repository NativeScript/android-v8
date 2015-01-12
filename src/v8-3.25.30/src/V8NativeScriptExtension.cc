#include "V8NativeScriptExtension.h"
#include "api.h"
#include "checks.h"
#include "contexts.h"
#include "globals.h"
#include "handles.h"

using namespace v8;

template<typename T>
class unsafe_arr
{
public:
	unsafe_arr()
		: m_capacity(16), m_size(0)
	{
		m_data = alloc_data(m_capacity);
	}

	void push_back(const T& e)
	{
		if (m_size == m_capacity)
		{
			resize();
		}
		m_data[m_size++] = e;
	}

	T* data() const
	{
		return m_data;
	}

	size_t size() const
	{
		return m_size;
	}

	static void release_data(T *data)
	{
		free(data);
	}

private:
	T* alloc_data(size_t size)
	{
		T *data = reinterpret_cast<T*>(malloc(size * sizeof(T)));
		return data;
	}

	void resize()
	{
		size_t capacity = 2 * m_capacity;
		T *data = alloc_data(capacity);
		size_t size = m_size * sizeof(T);
		memcpy(data, m_data, size);
		release_data(m_data);
		m_data = data;
		m_capacity = capacity;
	}

	size_t m_capacity;
	size_t m_size;
	T *m_data;
};


NativeScriptExtension::NativeScriptExtension()
{
}


uint8_t* NativeScriptExtension::GetAddress(const Handle<Object>& obj)
{
	i::Handle<i::JSObject> h = Utils::OpenHandle(*obj);

	return h->address();
}


Local<Value>* NativeScriptExtension::GetClosureObjects(Isolate *isolate, const Handle<Function>& func, int *length)
{
	unsafe_arr< Local<Value> > arr;

	i::Handle<i::JSFunction> fun = Utils::OpenHandle(*func);

	i::Isolate* internal_isolate = reinterpret_cast<i::Isolate*>(isolate);

	i::Context *cxt = fun->context();

	i::ContextLookupFlags cxtFlags = i::FOLLOW_CHAINS;

	while (!cxt->IsNativeContext())
	{
		i::ScopeInfo *si = cxt->closure()->shared()->scope_info();
		
		int len = si->length();
		
		for (int i = 0; i < len; i++)
		{
			i::Object *cur = si->get(i);

			if (cur->IsString())
			{
				i::String *s = i::String::cast(cur);

				i::Handle<i::String> name = i::Handle<i::String>(s, internal_isolate);

				PropertyAttributes attr;
				i::BindingFlags bf;
				int idx;

				i::Handle<i::Object> o = cxt->Lookup(name, cxtFlags, &idx, &attr, &bf);

				if (idx >= 0)
				{
					i::Handle<i::Object> obj = i::Handle<i::Object>(cxt->get(idx), internal_isolate);

					if (!obj->IsPrimitive())
					{
						Local<Value> local = Utils::ToLocal(obj);

						arr.push_back(local);

						//obj->Print();
						//printf(", name=%s, %d \n\n", name->ToAsciiArray(), si->get(i)->IsString());
					}
				}
			}
		}

		cxt = cxt->previous();
	}

	*length = arr.size();
	return arr.data();
}


void NativeScriptExtension::ReleaseClosureObjects(Local<Value>* closureObjects)
{
	unsafe_arr< Local<Value> >::release_data(closureObjects);
}


void NativeScriptExtension::GetAssessorPair(Isolate *isolate, const Handle<Object>& obj, const Handle<String>& propName, Handle<Value>& getter, Handle<Value>& setter)
{
	i::Isolate* intiso = reinterpret_cast<i::Isolate*>(isolate);

	i::Handle<i::JSObject> o = Utils::OpenHandle(*obj);

	i::Handle<i::String> intname = Utils::OpenHandle(*propName);

	i::AccessorPair *mh = o->GetLocalPropertyAccessorPair(*intname);

	if (mh != NULL)
	{
		i::Handle<i::Object> g = i::Handle<i::Object>(mh->getter(), intiso);

		if (!g->IsTheHole())
		{
			getter = Utils::ToLocal(g);
		}

		i::Handle<i::Object> s = i::Handle<i::Object>(mh->setter(), intiso);

		if (!s->IsTheHole())
		{
			setter = Utils::ToLocal(s);
		}
	}
}


Handle<Array> NativeScriptExtension::GetPropertyKeys(Isolate *isolate, const Handle<Object>& object)
{
	i::Handle<i::JSObject> obj = Utils::OpenHandle(*object);

	i::Handle<i::FixedArray> arr = GetEnumPropertyKeys(obj, false);

	int len = arr->length();

	Handle<Array> keys = Array::New(isolate, len);
	for (int i = 0; i < len; i++)
	{
		i::Handle<i::Object> elem = i::Handle<i::Object>(arr->get(i), obj->GetIsolate());
		Handle<Value> val = Utils::ToLocal(elem);
		keys->Set(i, val);
	}
	
	return keys;
}

i::Handle<i::FixedArray> NativeScriptExtension::GetEnumPropertyKeys(const i::Handle<i::JSObject>& object, bool cache_result)
{
	i::Isolate* isolate = object->GetIsolate();
	if (object->HasFastProperties()) {
		if (object->map()->instance_descriptors()->HasEnumCache()) {
			int own_property_count = object->map()->EnumLength();
			// If we have an enum cache, but the enum length of the given map is set
			// to kInvalidEnumCache, this means that the map itself has never used the
			// present enum cache. The first step to using the cache is to set the
			// enum length of the map by counting the number of own descriptors that
			// are not DONT_ENUM or SYMBOLIC.
			if (own_property_count == i::kInvalidEnumCacheSentinel) {
				own_property_count = object->map()->NumberOfDescribedProperties(
					//i::OWN_DESCRIPTORS, DONT_SHOW);
					i::OWN_DESCRIPTORS, NONE);

				if (cache_result) object->map()->SetEnumLength(own_property_count);
			}

			i::DescriptorArray* desc = object->map()->instance_descriptors();
			i::Handle<i::FixedArray> keys(desc->GetEnumCache(), isolate);

			// In case the number of properties required in the enum are actually
			// present, we can reuse the enum cache. Otherwise, this means that the
			// enum cache was generated for a previous (smaller) version of the
			// Descriptor Array. In that case we regenerate the enum cache.
			if (own_property_count <= keys->length()) {
				isolate->counters()->enum_cache_hits()->Increment();
				return i::ReduceFixedArrayTo(keys, own_property_count);
			}
		}

		i::Handle<i::Map> map(object->map());

		if (map->instance_descriptors()->IsEmpty()) {
			isolate->counters()->enum_cache_hits()->Increment();
			if (cache_result) map->SetEnumLength(0);
			return isolate->factory()->empty_fixed_array();
		}

		isolate->counters()->enum_cache_misses()->Increment();
		//int num_enum = map->NumberOfDescribedProperties(i::ALL_DESCRIPTORS, DONT_SHOW);
		int num_enum = map->NumberOfDescribedProperties(i::ALL_DESCRIPTORS, NONE);


		i::Handle<i::FixedArray> storage = isolate->factory()->NewFixedArray(num_enum);
		i::Handle<i::FixedArray> indices = isolate->factory()->NewFixedArray(num_enum);

		i::Handle<i::DescriptorArray> descs =
			i::Handle<i::DescriptorArray>(object->map()->instance_descriptors(), isolate);

		int real_size = map->NumberOfOwnDescriptors();
		int enum_size = 0;
		int index = 0;

		for (int i = 0; i < descs->number_of_descriptors(); i++) {
			i::PropertyDetails details = descs->GetDetails(i);
			i::Object* key = descs->GetKey(i);
			if (!key->IsSymbol()) {
				if (i < real_size) ++enum_size;
				storage->set(index, key);
				if (!indices.is_null()) {
					if (details.type() != i::FIELD) {
						indices = i::Handle<i::FixedArray>();
					}
					else {
						int field_index = descs->GetFieldIndex(i);
						if (field_index >= map->inobject_properties()) {
							field_index = -(field_index - map->inobject_properties() + 1);
						}
						indices->set(index, i::Smi::FromInt(field_index));
					}
				}
				index++;
			}
		}
		ASSERT(index == storage->length());

		i::Handle<i::FixedArray> bridge_storage =
			isolate->factory()->NewFixedArray(
			i::DescriptorArray::kEnumCacheBridgeLength);
		i::DescriptorArray* desc = object->map()->instance_descriptors();
		desc->SetEnumCache(*bridge_storage,
			*storage,
			indices.is_null() ? i::Object::cast(i::Smi::FromInt(0))
			: i::Object::cast(*indices));
		if (cache_result) {
			object->map()->SetEnumLength(enum_size);
		}

		return i::ReduceFixedArrayTo(storage, enum_size);
	}
	else {
		i::Handle<i::NameDictionary> dictionary(object->property_dictionary());
		int length = dictionary->NumberOfEnumElements();
		if (length == 0) {
			return i::Handle<i::FixedArray>(isolate->heap()->empty_fixed_array());
		}
		i::Handle<i::FixedArray> storage = isolate->factory()->NewFixedArray(length);
		dictionary->CopyEnumKeysTo(*storage);
		return storage;
	}
}
