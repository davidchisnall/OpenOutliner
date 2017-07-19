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

/**
 * Superclass for all concrete subclasses of `OOOutlineValue`.  This provides a
 * convenient place to declare all methods that are implemented by these
 * objects.
 */
@interface OOConcreteOutlineValue : OOOutlineValue
@end
@interface OOConcreteOutlineValue (SubclassMethods)
- (instancetype)initWithOO3XML: (NSXMLElement*)xml
                      inColumn: (OOOutlineColumn*)aCol;
@end


@interface OOOutlineTextValue : OOConcreteOutlineValue @end
@interface OOOutlineEmptyValue : OOConcreteOutlineValue @end
@interface OOOutlineDateValue : OOConcreteOutlineValue @end
@interface OOOutlineEnumValue : OOConcreteOutlineValue @end
@interface OOOutlineNumberValue : OOConcreteOutlineValue @end


@implementation OOOutlineValue
+ (OOOutlineValue*)outlineValueWithOO3XML: (NSXMLElement*)xml
                                 inColumn: (OOOutlineColumn*)aCol
{
	object_map<NSString*, Class> subclasses =
		{
			{ @"text", [OOOutlineTextValue class] },
			{ @"enum", [OOOutlineEnumValue class] },
			{ @"date", [OOOutlineDateValue class] },
			{ @"number", [OOOutlineNumberValue class] },
			{ @"null", [OOOutlineEmptyValue class] }
		};
	if (subclasses.find(xml.name) == subclasses.end())
	{
		[NSException raise: NSInternalInconsistencyException
		            format: @"Unknown column type %@", xml.name];
	}
	// FIXME: Default column styles
	return [[subclasses[xml.name] alloc] initWithOO3XML: xml inColumn: aCol];
}
+ (instancetype)placeholder
{
	return [OOOutlineEmptyValue new];
}
- (id)value
{
	OO_ABSTRACT_METHOD();
}
- (NSXMLElement*)oo3xmlValue
{
	OO_ABSTRACT_METHOD();
}
- (instancetype)initWithValue: (id)aValue inColumn: (OOOutlineColumn*)aCol
{
	static std::unordered_map<OOOutlineColumnType, Class> subclasses =
	{
		{ OOOutlineColumnTypeText, [OOOutlineTextValue class] },
		{ OOOutlineColumnTypeEnumeration, [OOOutlineEnumValue class] },
		{ OOOutlineColumnTypeDate, [OOOutlineDateValue class] },
		{ OOOutlineColumnTypeNumber, [OOOutlineNumberValue class] },
	};
	OOOutlineColumnType columnType = [aCol columnType];
	if (subclasses.find(columnType) == subclasses.end())
	{
		[NSException raise: NSInternalInconsistencyException
		            format: @"Unknown column type %d", (int)columnType];
	}
	return [[subclasses[columnType] alloc] initWithValue: aValue
	                                            inColumn: aCol];
}
@end

@implementation OOOutlineTextValue
{
	NSMutableAttributedString *value;
	OOOutlineColumn *column;
}
- (OOOutlineTextValue*)initWithOO3XML: (NSXMLElement*)xml inColumn: (OOOutlineColumn*)aCol
{
	OO_SUPER_INIT();
	value = [NSMutableAttributedString attributedStringWithOO3XML: xml
	                                             withPartialStyle: aCol.style];
	column = aCol;
	return self;
}
- (instancetype)initWithValue: (id)aValue inColumn: (OOOutlineColumn*)aCol
{
	OO_SUPER_INIT();
	if ([aValue isKindOfClass: [NSString class]])
	{
		aValue = [[NSAttributedString alloc] initWithString: aValue];
	}
	NSAssert([aValue isKindOfClass: [NSAttributedString class]], @"Incorrect class");
	value = [aValue mutableCopy];
	column = aCol;
	return self;
}
- (NSString*)description
{
	return [value string];
}
- (id)value
{
	return value;
}
- (NSXMLElement*)oo3xmlValue
{
	return [value oo3xmlValueWithPartialStyle: column.style];
}
@end

@implementation OOOutlineDateValue
{
	NSDate *value;
}
- (instancetype)initWithOO3XML: (NSXMLElement*)xml  inColumn: (OOOutlineColumn*)aCol
{
	OO_SUPER_INIT();
	value = [NSDate dateWithString: [xml stringValue]];
	return self;
}
- (instancetype)initWithValue: (id)aValue inColumn: (OOOutlineColumn*)aCol
{
	OO_SUPER_INIT();
	NSAssert([aValue isKindOfClass: [NSDate class]], @"Incorrect class");
	value = [aValue mutableCopy];
	return self;
}
- (NSString*)description
{
	return [value description];
}
- (id)value
{
	return value;
}
- (NSXMLElement*)oo3xmlValue
{
	// FIXME: The OmniOutliner 3 format's way of dealing with dates is horrible
	// and assumes that we only ever have a single time zone.  You end up with
	// multiple time zones in the files and any kind of sorting becomes
	// nonsense.  This should be fixed soon, because the parsing is quite
	// permissive.
	return [NSXMLElement elementWithName: @"date"
	                         stringValue: [value description]];
}
@end
@implementation OOOutlineNumberValue
{
	NSDecimalNumber *value;
}
- (instancetype)initWithOO3XML: (NSXMLElement*)xml inColumn: (OOOutlineColumn*)aCol;
{
	OO_SUPER_INIT();
	value = [NSDecimalNumber decimalNumberWithString: [xml stringValue]];
	return self;
}
- (instancetype)initWithValue: (id)aValue inColumn: (OOOutlineColumn*)aCol
{
	OO_SUPER_INIT();
	NSAssert([aValue isKindOfClass: [NSDecimalNumber class]], @"Incorrect class");
	value = aValue;
	return self;
}
- (NSString*)description
{
	return [value description];
}
- (id)value
{
	return value;
}
- (NSXMLElement*)oo3xmlValue
{
	return [NSXMLElement elementWithName: @"number"
	                         stringValue: [value stringValue]];
}

@end



@implementation OOOutlineEnumValue
{
	NSAttributedString *text;
	NSString *enumValName;
}
- (instancetype)initWithOO3XML: (NSXMLElement*)xml  inColumn: (OOOutlineColumn*)aCol
{
	OO_SUPER_INIT();
	text = [[NSAttributedString alloc] initWithString: [xml stringValue]
	                                       attributes: [aCol defaultStyle]];
	enumValName = [[[xml attributeForName: @"idref"] stringValue] copy];
	NSAssert([[text string] isEqualToString: [[aCol enumValues] objectForKey: enumValName]], @"Mismatched enum!");
	return self;
}
- (NSXMLElement*)oo3xmlValue
{
	NSXMLElement *e = [NSXMLElement elementWithName: @"enum"
	                                    stringValue: [text string]];
	[e setAttributesWithDictionary: @{ @"idref": enumValName }];
	return e;
}
- (NSString*)description
{
	return [text description];
}
- (id)value
{
	return text;
}
- (instancetype)initWithValue: (id)aValue inColumn: (OOOutlineColumn*)aCol
{
	// FIXME: We should be setting the enum value id
	NSAssert([aValue isKindOfClass: [NSAttributedString class]], @"Incorrect class");
	text = [aValue mutableCopy];
	auto *keys = [aCol.enumValues allKeysForObject: [text string]];
	if ([keys count] == 0)
	{
		NSAssert(NO, @"Not yet implemented!");
	}
	enumValName = [keys objectAtIndex: 0];
	return self;
}
@end


@implementation OOOutlineEmptyValue
- (instancetype)initWithOO3XML: (NSXMLElement*)xml inColumn: (OOOutlineColumn*)aCol
{
	return [super init];
}
- (id)value
{
	// FIXME: Get rid of this class and replace it with a default (empty) value for the specified column
	return nil;
}
- (NSXMLElement*)oo3xmlValue
{
	return [NSXMLElement elementWithName: @"null"];
}
@end

@implementation OOConcreteOutlineValue @end
