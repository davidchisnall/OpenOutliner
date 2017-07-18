/*-
 * Copyright (c) 2017 David T. Chisnall
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

/**
 * This file contains a number of helpers that allow better interoperability
 * between the Objective-C and C++ parts of Objective-C++.
 */


#import <Foundation/NSObject.h>
#include <unordered_map>
#include <map>
#include <type_traits>

namespace {
/**
 * Helper template defining object equality.  This is used with C++ standard
 * unordered maps and sets to allow Objective-C objects to be stored.
 */
template<typename X>
struct object_equal
{
	bool operator()(const X s1, const X s2) const
	{
		return (s1 == s2) || [s1 isEqual: s2];
	}
};

/**
 * Helper template defining object hashes.  This is used with C++ standard
 * unordered maps and sets to allow Objective-C objects to be stored.
 */
template<typename X>
struct object_hash
{
	size_t operator()(const X s1) const
	{
		return (size_t)[s1 hash];
	}
};

/**
 * Helper template defining object ordering.  This is used with C++ standard
 * ordered collections (`std::map`, `std::set`) to allow Objective-C objects to
 * be stored.
 */
template<typename T>
struct object_compare
{
	constexpr bool operator()(const T &lhs, const T &rhs) const
	{
		return [lhs compare: rhs] == NSOrderedAscending;
	}
};

/**
 * The get<>() template function gets a value of the specified type from an
 * object.  This is intended to be used in other templates to specialise object
 * accessors based on template arguments.
 */
template<typename T, typename std::enable_if_t<!std::is_enum<T>::value, int> = 0>
T get(id v)
{
	return v;
}

#define APPLY_TYPE(type, name, capitalizedName, encodingChar) \
	template<>                                                \
	[[gnu::unused]]                                           \
	type get(id v)                                            \
	{                                                         \
		return [v name ## Value];                             \
	}
#include "type_encoding_cases.h"

template<>
[[gnu::unused]]
NSString *get(id v)
{
	return [v stringValue];
}

/**
 * `box_number` returns an `NSNumber` instance corresponding to the specified
 * type.  This function has overloads for all of the primitive number types,
 * allowing it to be used in templates.
 */
#define APPLY_TYPE(type, name, capitalizedName, encodingChar) \
	[[gnu::unused]]                                           \
	NSNumber *box_number(type v)                              \
	{                                                         \
		return [NSNumber numberWith ## capitalizedName: v];   \
	}
#include "type_encoding_cases.h"


template<typename T, typename std::enable_if<std::is_enum<T>::value, int>::type = 0>
[[gnu::unused]]
T get(id v)
{
	return static_cast<T>(get<int>(v));
}


/**
 * `get_as_object<>` returns an object encapsulating the specified value.  This is
 * either the object, when called with object arguments, or an `NSValue`
 * instance wrapping the object otherwise.
 *
 * As with `get<>`, this is intended to be used in conjunction with other templates.
 */
template<typename T, typename std::enable_if<std::is_convertible<T, id>::value, int>::type = 0>
[[gnu::unused]]
id get_as_object(T &val)
{
	return val;
}

template<typename T, typename std::enable_if<std::is_pod<T>::value, int>::type = 0>
[[gnu::unused]]
id get_as_object(T &val)
{
	return [NSValue valueWithBytes: &val
						  objCType: @encode(T)];
}

template <typename K=id, typename V=id>
using object_map = std::unordered_map<K, V, object_hash<K>, object_equal<K>>;
template <typename K=id, typename V=id>
using object_ordered_map = std::map<K, V, object_compare<K>>;

}
