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

#import "OpenOutliner.h"
#import <functional>
#import <utility>
#import <vector>
#if __has_include(<optional>)
#import <optional>
using std::optional;
#else
#import <experimental/optional>
using std::experimental::optional;
#endif

@interface OOPartialStyle ()
{
@public
	/**
	 * The dictionary storing all of the attributes defined by this style (and
	 * not by the style from which it inherits).
	 */
	NSMutableDictionary *d;
	/**
	 * The partial style from which this inherits.
	 */
	OOPartialStyle *inheritsFrom;
}
@end

@interface OOStyleRegistry ()
- (NSXMLElement*)oo3xmlForPartialStyle: (OOPartialStyle*)aStyle;
@end

NSString *OOPartialStyleKey = @"OOPartialStyleKey";

@implementation OOPartialStyle
@synthesize registry;
- (id)init
{
	OO_SUPER_INIT();
	d = [NSMutableDictionary new];
	return self;
}
- (instancetype) subtract: (OOPartialStyle *)r
{
	std::vector<id> removals;
	for (id key in r->d)
	{
		id v = [r->d objectForKey: key];
		if (v && [[d objectForKey: key] isEqual: v])
		{
			removals.push_back(key);
		}
	}
	for (id key : removals)
	{
		[d removeObjectForKey: key];
	}
	if (r->inheritsFrom)
	{
		[self subtract: r->inheritsFrom];
	}
	return self;
}
- (NSXMLElement*)oo3xmlValue
{
	if ([d count] == 0)
	{
		return nil;
	}
	return [registry oo3xmlForPartialStyle: self];
}
/**
 * Recompute the style from attributes.  This will ignore any attributes that
 * are the same as the style from which this is derrived.
 */
- (void)recomputeWithAttributes: (NSDictionary*)attributes
{
	assert(0);
}
@end


namespace {

/**
 * Superclass for all style attributes.  This handles the generic part of
 * serialising and deserialising OmniOutliner 3 XML style elements and requires
 * subclasses to handle the specific data.
 */
struct style_attribute
{
	/**
	 * The version for this element.  I have no idea what this is actually for -
	 * it appears to be to allow elements to be introduced and ignored by
	 * earlier versions of OmniOutliner.  We simply preserve the values that are
	 * there and insert values for knowns style elements that seem to be
	 * sensible.
	 */
	NSUInteger version;
	/**
	 * The key for this property.
	 */
	NSString *key;
	/**
	 * The group to which this belongs.  This is used to differentiate
	 * paragraph, underline, and font attributes.
	 */
	NSString *group;
	/**
	 * The name of this attribute.
	 */
	NSString *name;
	/**
	 * The name of the kind of value, used to differentiate numeric, boolean,
	 * and so on.
	 */
	NSString *className;
	/**
	 * Construct from OmniOutliner 3 XML.
	 */
	virtual id fromOO3XML(NSXMLElement*) = 0;
	/**
	 * Emit OmniOutliner 3 XML taking the value from a partial style.
	 */
	virtual NSXMLElement* toOO3XML(id) = 0;
	/**
	 * Emit OmniOutliner 3 XML for this attribute in the style registry at the
	 * start of an OmniOutliner 3 document.
	 */
	virtual NSXMLElement* toOO3XML() = 0;
	/**
	 * The default value.
	 */
	virtual id defaultValue() = 0;
	/**
	 * Construct a style attribute with all of the required keys.
	 */
	style_attribute(NSUInteger aVersion,
	                NSString *aKey,
	                NSString *aGroup,
	                NSString *aName,
	                NSString *aClassName) :
		version(aVersion),
		key(aKey),
		group(aGroup),
		name(aName),
		className(aClassName) {}
	/**
	 * Construct a style attribute from an OmniOutliner 3 style registry
	 * attribute XML element.
	 */
	style_attribute(NSXMLElement *e)
	{
		version = get<typeof(version)>([[e attributeForName: @"version"] stringValue]);
		key = [[e attributeForName: @"key"] stringValue];
		group = [[e attributeForName: @"group"] stringValue];
		name = [[e attributeForName: @"name"] stringValue];
		className = [[e attributeForName: @"class"] stringValue];
	}
	virtual ~style_attribute() {}
	/**
	 * Create a unique pointer to an instance of a subclass of this class, from
	 * the specified OmniOutliner 3 XML representation.
	 */
	static std::unique_ptr<style_attribute> create(NSXMLElement *e);
protected:
	/**
	 * Constructs an OmniOutliner 3 XML element for a reference to this style
	 * attribute.
	 */
	NSXMLElement *oo3XMLElement()
	{
		return [NSXMLElement elementWithName: @"value"
		                attributesDictionary: @{ @"key" : key }];
	}
	/**
	 * Constructs an OmniOutliner 3 XML element for the definition of this style
	 * attribute.
	 */
	NSXMLElement *oo3XMLStyleElement()
	{
		NSXMLElement *e = [NSXMLElement elementWithName: @"style-attribute"];
		[e addAttribute: [NSString stringWithFormat: @"%d", (int)version]
		       withName: @"version"];
		[e addAttribute: key withName: @"key"];
		[e addAttribute: group withName: @"group"];
		[e addAttribute: name withName: @"name"];
		[e addAttribute: className withName: @"class"];
		return e;
	}

};

/**
 * Style attribute storing a string.
 */
class string_style_attribute : public style_attribute
{
	NSString *defaultVal;
	id fromOO3XML(NSXMLElement *e) override
	{
		return [e stringValue];
	}
	NSXMLElement* toOO3XML(id obj) override
	{
		auto *e = oo3XMLElement();
		[e setStringValue: obj];
		return e;
	}
	NSXMLElement* toOO3XML() override
	{
		auto *e = oo3XMLStyleElement();
		[e setStringValue: defaultVal];
		return e;
	}
	id defaultValue() override
	{
		return defaultVal;
	}
public:
	string_style_attribute(NSXMLElement *e) : style_attribute(e), defaultVal([e stringValue])
	{}
	string_style_attribute(NSUInteger aVersion,
	                       NSString *aKey,
	                       NSString *aGroup,
	                       NSString *aName,
	                       NSString *aDefault) :
		style_attribute(aVersion, aKey, aGroup, aName, @"string"),
		defaultVal(aDefault) {}
};

/**
 * Style attribute storing a color.
 */
class color_style_attribute : public style_attribute
{
	NSColor *defaultVal;
	id fromOO3XML(NSXMLElement *e) override
	{
		return [NSColor colourWithOO3XML: [e elementForName: @"color"]];
	}
	NSXMLElement* toOO3XML(id obj) override
	{
		auto *e = oo3XMLElement();
		[e addChild: [(NSColor*)obj oo3xmlValue]];
		return e;
	}
	NSXMLElement* toOO3XML() override
	{
		auto *e = oo3XMLStyleElement();
		[e addChild: [defaultVal oo3xmlValue]];
		return e;
	}
	id defaultValue() override
	{
		return defaultVal;
	}
public:
	color_style_attribute(NSXMLElement *e) :
		style_attribute(e),
		defaultVal([NSColor colourWithOO3XML: [e elementForName: @"color"]]) {}
	color_style_attribute(NSUInteger aVersion,
	                      NSString *aKey,
	                      NSString *aGroup,
	                      NSString *aName,
	                      NSColor *aDefault) :
		style_attribute(aVersion, aKey, aGroup, aName, @"string"),
		defaultVal(aDefault) {}
};

/**
 * Style attribute storing a boolean value.
 */
class bool_style_attribute : public style_attribute
{
	BOOL defaultVal;
	NSString *boolToString(BOOL b)
	{
		return b ? @"yes" : @"no";
	}
	id fromOO3XML(NSXMLElement *e) override
	{
		return [NSNumber numberWithBool: [[e stringValue] boolValue]];
	}
	NSXMLElement* toOO3XML(id obj) override
	{
		auto *e = oo3XMLElement();
		[e setStringValue: boolToString([obj boolValue])];
		return e;
	}
	NSXMLElement* toOO3XML() override
	{
		auto *e = oo3XMLStyleElement();
		[e setStringValue: boolToString(defaultVal)];
		return e;
	}
	id defaultValue() override
	{
		return  @(defaultVal);
	}

public:
	bool_style_attribute(NSXMLElement *e) : style_attribute(e), defaultVal([[e stringValue] boolValue])
	{}
	bool_style_attribute(NSUInteger aVersion,
	                     NSString *aKey,
	                     NSString *aGroup,
	                     NSString *aName,
	                     BOOL aDefault) :
		style_attribute(aVersion, aKey, aGroup, aName, @"string"),
		defaultVal(aDefault) {}
};

/**
 * Templated style attribute storing a numeric value.  This is intended to be
 * instantiated with `NSInteger` or `CGFloat` types, though could handle any
 * numeric type.
 */
template<typename T>
class number_style_attribute : public style_attribute
{
	T defaultVal;
	/**
	 * Optional minimum value.
	 */
	optional<T> min;
	/**
	 * Optional maximum value.
	 */
	optional<T> max;
	BOOL isIntegral()
	{
		return std::is_integral<T>::value;
	}
	id fromOO3XML(NSXMLElement *e) override
	{
		T val = get<T>([e stringValue]);
		if (min && (val < *min))
		{
			return nil;
		}
		if (max && (val > *max))
		{
			return nil;
		}
		return box_number(val);
	}
	NSXMLElement* toOO3XML(id obj) override
	{
		auto *e = oo3XMLElement();
		[e setStringValue: [obj stringValue]];
		return e;
	}
	NSXMLElement* toOO3XML() override
	{
		auto *e = oo3XMLStyleElement();
		[e addAttribute: isIntegral() ? @"1" : @"0" withName: @"integral"];
		if (min)
		{
			[e addAttribute: [@(*min) stringValue] withName: @"min"];
		}
		if (max)
		{
			[e addAttribute: [@(*max) stringValue] withName: @"max"];
		}
		[e setStringValue: [@(defaultVal) stringValue]];
		return e;
	}
	id defaultValue() override
	{
		return  @(defaultVal);
	}
public:
	number_style_attribute(NSXMLElement *e) :
		style_attribute(e),
		defaultVal(get<T>([e stringValue]))
	{
		if (NSString *minStr = [[e attributeForName: @"min"] stringValue])
		{
			min = get<T>(minStr);
		}
		if (NSString *maxStr = [[e attributeForName: @"max"] stringValue])
		{
			max = get<T>(maxStr);
		}
		NSCAssert(get<int>([[e attributeForName: @"integral"] stringValue]) == isIntegral(),
						  @"Mismatch between integral and floating point types");
	}
	number_style_attribute(NSUInteger aVersion,
						 NSString *aKey,
						 NSString *aGroup,
						 NSString *aName,
						 T aDefault,
						 T aMin,
						 T aMax) :
		style_attribute(aVersion, aKey, aGroup, aName, @"string"),
		defaultVal(aDefault),
 		min(aMin),
		max(aMax) {}

};

/**
 * Style attribute storing an enumerated type.
 */
class enum_style_attribute : public style_attribute
{
	/**
	 * Map from value names to their integer representations.
	 */
	object_map<NSString*, int> values;
	/**
	 * Map from integers to their names.  This should be the inverse of
	 * `values`.
	 */
	std::map<int, NSString*> keys;
	int defaultVal;
	id fromOO3XML(NSXMLElement *e) override
	{
		NSString *key = [e stringValue];
		return @(values.at(key));
	}
	NSXMLElement* toOO3XML(id obj) override
	{
		auto *e = oo3XMLElement();
		[e setStringValue: keys.at([obj intValue])];
		return e;
	}
	NSXMLElement* toOO3XML() override
	{
		auto *e = oo3XMLStyleElement();
		NSXMLElement *table = [NSXMLElement elementWithName: @"enum-name-table"];
		[table addAttribute: [@(defaultVal) stringValue] withName: @"default-value"];
		for (auto &[value, key] : keys)
		{
			NSXMLElement *v = [NSXMLElement elementWithName: @"enum-name-table-element"];
			[v addAttribute: [@(value) stringValue]
			       withName: @"value"];
			[v addAttribute: key withName: @"name"];
			[table addChild: v];
		}
		[e addChild: table];
		return e;
	}
	id defaultValue() override
	{
		return  @(defaultVal);
	}

public:
	enum_style_attribute(NSXMLElement *e) : style_attribute(e)
	{
		NSXMLElement *table = [e elementForName: @"enum-name-table"];
		defaultVal = get<int>([[table attributeForName: @"default-value"] stringValue]);
		for (NSXMLElement *c in [table elementsForName: @"enum-name-table-element"])
		{
			NSString *key = [[c attributeForName: @"name"] stringValue];
			int value = [[[c attributeForName: @"value"] stringValue] intValue];
			keys[value] = key;
			values[key] = value;
		}
	}
	enum_style_attribute(NSUInteger aVersion,
						 NSString *aKey,
						 NSString *aGroup,
						 NSString *aName,
						 int aDefault,
						 object_map<NSString*,int> &names) :
		style_attribute(aVersion, aKey, aGroup, aName, @"string"),
		values(std::move(names)),
		defaultVal(aDefault)
 	{
		for (auto &[key, value] : values)
		{
			keys[value] = key;
		}
	}
};



std::unique_ptr<style_attribute> style_attribute::create(NSXMLElement *e)
{
	NSString *cls = [[e attributeForName: @"class"] stringValue];
	if ([cls isEqualToString: @"string"])
	{
		return std::make_unique<string_style_attribute>(e);
	}
	if ([cls isEqualToString: @"color"])
	{
		return std::make_unique<color_style_attribute>(e);
	}
	if ([cls isEqualToString: @"bool"])
	{
		return std::make_unique<bool_style_attribute>(e);
	}
	if ([cls isEqualToString: @"number"])
	{
		if ([[[e attributeForName: @"integral"] stringValue] intValue] == 1)
		{
			return std::make_unique<number_style_attribute<NSInteger>>(e);
		}
		return std::make_unique<number_style_attribute<CGFloat>>(e);
	}
	if ([cls isEqualToString: @"enum"])
	{
		return std::make_unique<enum_style_attribute>(e);
	}
	// FIXME: Silently ignore these, rather than crashing.  Crash for now
	// because it will help things get fixed if we've missed anything important.
	assert(0);
	return nullptr;
}

/**
 * Helper function template that constructs a new attribute of the desired type
 * and adds it to the map.
 */
template<typename T, typename M, class ...Ts>
void addToMap(M &map,
              NSUInteger aVersion,
              NSString *aKey,
              NSString *aGroup,
              NSString *aName,
              Ts... xs)
{
	map[aKey] = std::make_unique<T>(aVersion, aKey, aGroup, aName, xs...);
}

// FIXME: Currently not handling paragraph-tab-stop-interval or
// paragraph-tab-stops

struct OOStyle
{
	NSString *fontFamily = @"Helvetica";
	NSColor *fontFill = [NSColor blackColor];
	NSFontTraitMask fontTraits = 0;
	CGFloat fontSize = 12;
	NSInteger fontWeight = 5;
	NSTextAlignment paragraphAlignment = NSTextAlignmentLeft;
	NSWritingDirection paragraphBaseWritingDirection = NSWritingDirectionNatural;
	CGFloat paragraphFirstLineIndent;
	NSUnderlineStyle underlineStyle = NSUnderlineStyleNone;
	bool isBold()
	{
		return fontTraits &= NSFontBoldTrait;
	}
	bool isItalic()
	{
		return fontTraits &= NSFontItalicTrait;
	}
	template<typename T>
	void apply_all_fields(T &x)
	{
#define APPLY(f) x(@ #f, f)
		APPLY(fontFamily);
		APPLY(fontFill);
		APPLY(fontTraits);
		APPLY(fontSize);
		APPLY(fontWeight);
		APPLY(paragraphAlignment);
		APPLY(paragraphBaseWritingDirection);
		APPLY(paragraphFirstLineIndent);
		APPLY(underlineStyle);
#undef APPLY
	}
	OOPartialStyle *asPartialStyle()
	{
		auto *d = [OOPartialStyle new];
		auto add = [&](NSString *key, auto &val)
			{
				[d->d setObject: get_as_object(val)
					  forKey: key];
			};
		apply_all_fields(add);
		return d;
	}
	OOStyle& operator+=(OOPartialStyle *ps)
	{
		auto set = [&](NSString *key, auto &val)
		{
			id obj = [ps->d objectForKey: key];
			if (obj)
			{
				val = get<typeof(val)>(obj);
			}
		};
		apply_all_fields(set);
		return *this;
	}
	OOStyle(OOPartialStyle *d)
	{
		(*this) += d;
	}
	NSDictionary *attributes()
	{
		NSFontManager *fm = [NSFontManager sharedFontManager];
		NSFont *f = [fm fontWithFamily: fontFamily
		                        traits: fontTraits
		                        weight: fontWeight
		                          size: fontSize];
		NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new];
		[ps setParagraphStyle: [NSParagraphStyle defaultParagraphStyle]];
		ps.baseWritingDirection = paragraphBaseWritingDirection;
		ps.firstLineHeadIndent = paragraphFirstLineIndent;
		ps.alignment = paragraphAlignment;
		return
		    @{
		        NSForegroundColorAttributeName : fontFill,
		        NSFontAttributeName            : f,
		        NSParagraphStyleAttributeName  : ps,
		        NSUnderlineStyleAttributeName  : @(underlineStyle)
		     };
	}
	OOStyle() {}
	OOStyle(NSDictionary *dict)
	{
		if (NSFont *f = [dict objectForKey: NSFontAttributeName])
		{
			NSFontManager *fm = [NSFontManager sharedFontManager];
			fontFamily = [f familyName];
			fontTraits = [fm  traitsOfFont: f];
			fontWeight = [fm weightOfFont: f];
			fontSize = [f pointSize];
		}
		if (NSColor *c = [dict objectForKey: NSForegroundColorAttributeName])
		{
			fontFill = c;
		}
		if (NSParagraphStyle *ps = [dict objectForKey: NSParagraphStyleAttributeName])
		{
			paragraphBaseWritingDirection = ps.baseWritingDirection;
			paragraphFirstLineIndent = ps.firstLineHeadIndent;
			paragraphAlignment = ps.alignment;
		}
		if (NSNumber *us = [dict objectForKey: NSUnderlineStyleAttributeName])
		{
			underlineStyle = get<NSUnderlineStyle>(us);
		}
	}
};

} // anon namespace


@implementation OOStyleRegistry
{
	OOStyle defaultStyle;
	object_map<NSString*, std::unique_ptr<style_attribute>> attributes;
}
- (instancetype)init
{
	OO_SUPER_INIT();
	addToMap<string_style_attribute>(attributes,
	                                 0,
	                                 @"font-family",
	                                 @"font",
	                                 @"family",
	                                 @"Helvetica");
	addToMap<color_style_attribute>(attributes,
	                                1,
	                                @"font-fill",
	                                @"font",
	                                @"fill color",
	                                [NSColor blackColor]);
	addToMap<bool_style_attribute>(attributes,
	                               0,
	                               @"font-italic",
	                               @"font",
	                               @"italic",
	                               NO);
	addToMap<number_style_attribute<CGFloat>>(attributes,
	                                          0,
	                                          @"font-size",
	                                          @"font",
	                                          @"size",
	                                          12,
	                                          1,
	                                          65536);
	addToMap<number_style_attribute<NSInteger>>(attributes,
	                                            0,
	                                            @"font-weight",
	                                            @"font",
	                                            @"weight",
	                                            5,
	                                            1,
	                                            14);
	addToMap<enum_style_attribute>(attributes,
	                               0,
	                               @"paragraph-alignment",
	                               @"paragraph",
	                               @"alignment",
	                               (int)NSTextAlignmentNatural,
	                               object_map<NSString*,int>(
	                                 {
	                                   { @"left", NSTextAlignmentLeft },
	                                   { @"right", NSTextAlignmentRight },
	                                   { @"center", NSTextAlignmentCenter },
	                                   { @"justified", NSTextAlignmentJustified },
	                                   { @"natural", NSTextAlignmentNatural },
	                                 }));
	addToMap<enum_style_attribute>(attributes,
	                               0,
	                               @"paragraph-base-writing-direction",
	                               @"paragraph",
	                               @"writing direction",
	                               (int)NSWritingDirectionNatural,
	                               object_map<NSString*,int>(
	                                 {
	                                   { @"natural", NSWritingDirectionNatural },
	                                   { @"left-to-right", NSWritingDirectionLeftToRight },
	                                   { @"right-to-left", NSWritingDirectionRightToLeft }
	                                 }));
	addToMap<number_style_attribute<NSInteger>>(attributes,
	                                            0,
	                                            @"paragraph-first-line-head-indent",
	                                            @"paragraph",
	                                            @"first line head indent",
	                                            0,
	                                            -1000,
	                                            1000);
	addToMap<enum_style_attribute>(attributes,
	                               0,
	                               @"underline-style",
	                               @"underline",
	                               @"style",
	                               (int)NSUnderlineStyleNone,
	                               object_map<NSString*,int>(
	                                 {
	                                   { @"none", NSUnderlineStyleNone },
	                                   { @"single", NSUnderlineStyleSingle },
	                                   { @"thick", NSUnderlineStyleThick },
	                                   { @"double", NSUnderlineStyleDouble },
	                                 }));
	return self;
}
- (NSDictionary*)attributesForStyle: (OOPartialStyle*)aStyle
{
	OOStyle s = defaultStyle;
	std::function<void(OOPartialStyle*)> collect = [&](OOPartialStyle* ps)
		{
			if (ps->inheritsFrom)
			{
				collect(ps->inheritsFrom);
			}
			s += ps;
		};
	if (!aStyle)
	{
		aStyle = [OOPartialStyle new];
		aStyle.registry = self;
	}
	else
	{
		collect(aStyle);
	}
	NSMutableDictionary *dict = [s.attributes() mutableCopy];
	[dict setObject: aStyle forKey: OOPartialStyleKey];
	return dict;
}
- (OOPartialStyle*)partialStyleForOO3XML: (NSXMLElement*)xml
                            inheritsFrom: (OOPartialStyle*)aPartialStyle
{
	NSAssert((xml == nil) || [[xml name] isEqualToString: @"style"], @"Invalid style");
	auto *ps = [OOPartialStyle new];
	for (NSXMLElement *val in [xml elementsForName: @"value"])
	{
		try
		{
			NSString *key = [[val attributeForName: @"key"] stringValue];
			[ps->d setObject: attributes.at(key)->fromOO3XML(val) forKey: key];
		} catch (std::out_of_range &e)
		{
			NSLog(@"No handler for: %@", val);
		}
	}
	ps.registry = self;
	ps->inheritsFrom = aPartialStyle;
	return ps;
}
- (OOPartialStyle*)partialStyleFromAttributes: (NSDictionary*)aDictionary
                                 inheritsFrom: (OOPartialStyle*)aPartialStyle
{
	OOStyle s(aDictionary);
	OOPartialStyle *ps = s.asPartialStyle();
	[ps subtract: aPartialStyle];
	ps->inheritsFrom = aPartialStyle;
	ps.registry = self;
	return ps;
}
- (NSXMLElement*)oo3xmlForPartialStyle: (OOPartialStyle*)aPartialStyle
{
	NSXMLElement *e = [NSXMLElement elementWithName: @"style"];
	for (NSString *key in aPartialStyle->d)
	{
		id val = [aPartialStyle->d objectForKey: key];
		[e addChild: attributes[key]->toOO3XML(val)];
	}
	return e;
}
- (instancetype)initWithOO3XML: (NSXMLElement*)xml
{
	if (xml == nil)
	{
		return [self init];
	}
	OO_SUPER_INIT();
	NSAssert([[xml name] isEqualToString: @"style-attribute-registry"],
	         @"Invalid style registry");
	for (NSXMLElement *attr in [xml elementsForName: @"style-attribute"])
	{
		auto attribute = style_attribute::create(attr);
		if (!attribute->key)
		{
			continue;
		}
		attributes[attribute->key] = std::move(attribute);
	}
	return self;
}
- (NSXMLElement*)oo3xmlValue
{
	NSXMLElement *xml = [NSXMLElement elementWithName: @"style-attribute-registry"];
	for (auto &kv : attributes)
	{
		[xml addChild: kv.second->toOO3XML()];
	}
	return xml;
}
@end
