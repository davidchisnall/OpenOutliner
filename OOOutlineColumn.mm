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

namespace
{
/**
 * Template for computing a summary.  Uses the lambda provided as the first
 * argument to compute the summary for items at the current depth and
 * recursively invokes the summary class provided as `aSummary` for child nodes
 * that don't have a value.
 *
 * This helper exists to allow `OOOutlineSummary` classes to mostly share code.
 */
template<typename T>
Class computeSummary(T &acc, OOOutlineSummary *aSummary, OOOutlineRow *aRow, NSUInteger aCol)
{
	Class cls;
	for (OOOutlineRow *child in aRow.children)
	{
		auto *val = [child.values objectAtIndex: aCol];
		if (!val.value)
		{
			// FIXME: We should cache this, or we'll potentially end up computing it a *lot* of times.
			val = [aSummary computeSummaryForRow: child inColumn: aCol];
			// Skip empty cells that have no non-empty children
			if (!val.value)
			{
				continue;
			}
		}
		if (!cls)
		{
			cls = [val class];
		}
		acc(val.value);
	}
	return cls;
};
}

@implementation OOOutlineSummary
+ (instancetype)sharedInstance
{
	OO_ABSTRACT_METHOD();
	return nil;
}
- (OOOutlineValue*)computeSummaryForRow: (OOOutlineRow*)aRow inColumn: (NSUInteger)aCol
{
	OO_ABSTRACT_METHOD();
	return nil;
}
@end

/**
 * Helpers to define a singleton.  The singleton is created in `+initialize`
 * (the runtime is responsible for ensuring that this is thread safe) and
 * returned from `-sharedInstance`.
 */
#define SINGLETON(name) \
static OOOutlineSummary ## name *sharedInstance ## name;\
+ (void)initialize \
{ \
	sharedInstance ## name = [self new];\
}\
+ (instancetype)sharedInstance\
{\
	return sharedInstance ## name;\
}


/**
 * Summary class that computes the sum of all children.
 */
@interface OOOutlineSummarySum : OOOutlineSummary @end
@implementation OOOutlineSummarySum
SINGLETON(Sum)
- (OOOutlineValue*)computeSummaryForRow: (OOOutlineRow*)aRow inColumn: (NSUInteger)aCol
{
	NSDecimalNumber *accumulator = [NSDecimalNumber zero];
	auto acc = [&](NSNumber *next)
		{
			accumulator = [accumulator decimalNumberByAdding: [NSDecimalNumber decimalNumberWithDecimal: [next decimalValue]]];
			NSAssert(accumulator != nil, @"oops!");
		};
	Class cls = computeSummary(acc, self, aRow, aCol);
	return [[cls alloc] initWithValue: accumulator inColumn: nil];
}
@end

/**
 * Summary class that computes the mean of all children.
 */
@interface OOOutlineSummaryMean : OOOutlineSummary @end
@implementation OOOutlineSummaryMean
SINGLETON(Mean)
- (OOOutlineValue*)computeSummaryForRow: (OOOutlineRow*)aRow inColumn: (NSUInteger)aCol
{
	NSDecimalNumber *accumulator = [NSDecimalNumber zero];
	NSUInteger count = 0;
	auto acc = [&](NSNumber *next) {
		// Include zeroes, but not empty cells, in the summary
		if (next == nil)
		{
			return;
		}
		accumulator = [accumulator decimalNumberByAdding: [NSDecimalNumber decimalNumberWithDecimal: [next decimalValue]]];
		count++;
	};
	Class cls = computeSummary(acc, self, aRow, aCol);
	if (count == 0)
	{
		return nil;
	}
	accumulator = [accumulator decimalNumberByDividingBy: [NSDecimalNumber decimalNumberWithMantissa: count
	                                                                                        exponent: 0
	                                                                                      isNegative: NO]];
	return [[cls alloc] initWithValue: accumulator inColumn: nil];
}
@end

/**
 * Summary class that computes the minimum of all children.
 */
@interface OOOutlineSummaryMin : OOOutlineSummary @end
@implementation OOOutlineSummaryMin
SINGLETON(Min)
- (OOOutlineValue*)computeSummaryForRow: (OOOutlineRow*)aRow inColumn: (NSUInteger)aCol
{
	id obj;
	auto acc = [&](id next)
		{
			obj = (obj == nil) ? next :
				([obj isLessThanOrEqualTo: next] ? obj : next);
		};
	Class cls = computeSummary(acc, self, aRow, aCol);
	return [[cls alloc] initWithValue: obj inColumn: nil];
}
@end


/**
 * Summary class that computes the maximum of all children.
 */
@interface OOOutlineSummaryMax : OOOutlineSummary @end
@implementation OOOutlineSummaryMax
SINGLETON(Max)
- (OOOutlineValue*)computeSummaryForRow: (OOOutlineRow*)aRow inColumn: (NSUInteger)aCol
{
	id obj;
	auto acc = [&](id next)
		{
			obj = (obj == nil) ? next :
			([obj isGreaterThanOrEqualTo: next] ? obj : next);
		};
	Class cls = computeSummary(acc, self, aRow, aCol);
	return [[cls alloc] initWithValue: obj inColumn: nil];
}
@end


@implementation OOOutlineColumn
{
	/**
	 * The document containing this column.
	 */
	DEBUG_WEAK OOOutlineDocument *document;
}
@synthesize
	title,
	columnType,
	defaultStyle,
	enumValues,
	formatter,
	identifier,
	isNoteColumn,
	isOutlineColumn,
	maxWidth,
	minWidth,
	style,
	summary,
	textExportWidth,
	width;

- (instancetype)initWithOO2Plist: (NSDictionary*)aDictionary
                     columnIndex: (NSUInteger)anIndex
                      inDocument: (OOOutlineDocument*)aDocument
{
	OO_SUPER_INIT();
	NSDictionary *col = [[aDictionary objectForKey: @"Columns"] objectAtIndex: anIndex];
	auto getValue = [&](NSString *name, auto &val)
		{
			val = get<typeof(val)>([col objectForKey: name]);
		};
	NSString *titleString;
	getValue(@"Title", titleString);
	title = [[NSAttributedString alloc] initWithString: titleString
	                                        attributes: nil];
	getValue(@"MaximumWidth", maxWidth);
	getValue(@"MinimumWidth", minWidth);
	getValue(@"Width", width);
	getValue(@"Identifier", identifier);
	document = aDocument;
	isNoteColumn = [[aDictionary objectForKey: @"NoteColumn"] isEqualToString: identifier];
	isOutlineColumn = [[aDictionary objectForKey: @"OutlineColumn"] isEqualToString: identifier];
	columnType = OOOutlineColumnTypeText;
	// FIXME: Ignore the style stuff for now.
	return self;
}

- (instancetype)initWithOO3XML: (NSXMLElement*)xml
                    inDocument: (OOOutlineDocument*)aDocument
{
	OO_SUPER_INIT();
	// FIXME: Document default title style (stored in <root><style> element.
	title = [NSMutableAttributedString attributedStringWithOO3XML: [[xml elementForName: @"title"] elementForName: @"text"]
	                                             withPartialStyle: nil];
	static object_map<NSString*, OOOutlineColumnType> columnTypes =
		{
			{ @"text", OOOutlineColumnTypeText },
			{ @"number", OOOutlineColumnTypeNumber },
			{ @"date", OOOutlineColumnTypeDate },
			{ @"enumeration", OOOutlineColumnTypeEnumeration},
			{ @"checkbox", OOOutlineColumnTypeCheckBox }
		};
	columnType = columnTypes[[[xml attributeForName: @"type"] stringValue]];
	static object_map<NSString*, Class> summaryTypes =
		{
			{ nil, nil },
			{ @"none", nil },
			{ @"hidden", nil },
			{ @"sum", [OOOutlineSummarySum class] },
			// FIXME: State should be a tri-state logic thing, but we don't yet
			// have a value class for it Left blank for now, so that we will get
			// an exception if it's used
			//{ @"state", [OOOutlineSummaryState class] },
			{ @"average", [OOOutlineSummaryMean class] },
			{ @"minimum", [OOOutlineSummaryMin class] },
			{ @"maximum", [OOOutlineSummaryMax class] },
		};
	isNoteColumn = [[[xml attributeForName: @"is-note-column"] stringValue] boolValue];
	isOutlineColumn = [[[xml attributeForName: @"is-outline-column"] stringValue] boolValue];
	summary = [summaryTypes[[[xml attributeForName: @"summary"] stringValue]] sharedInstance];
	auto intAttr = [&](NSString *attr)
		{
			return get<NSUInteger>([[xml attributeForName: attr] stringValue]);
		};
	minWidth = intAttr(@"minimum-width");
	width = intAttr(@"width");
	maxWidth = intAttr(@"maximum-width");
	textExportWidth = intAttr(@"text-export-width");
	identifier = [[[xml attributeForName: @"id"] stringValue] copy];
	style = [aDocument.styleRegistry partialStyleForOO3XML: [xml elementForName: @"style"]
	                                          inheritsFrom: nil];
	assert(style);
	defaultStyle = [aDocument.styleRegistry attributesForStyle: style];
	if (NSXMLElement *f = [xml elementForName: @"formatter"])
	{
		NSString *type = [[f attributeForName: @"type"] stringValue];
		if ([type isEqualToString: @"number"])
		{
			auto *nf = [NSNumberFormatter new];
			[nf setFormat: [f stringValue]];
			formatter = nf;
		}
		else if ([type isEqualToString: @"date"])
		{
			auto *df = [OOUNIXDateFormatter new];
			// FIXME: allow-natural-language ?
			df.formatString = [f stringValue];
			formatter = df;
		}
		else
		{
			NSLog(@"Unknown formatter type: %@", type);
		}
	}
	if (columnType == OOOutlineColumnTypeEnumeration)
	{
		enumValues = [NSMutableDictionary new];
		NSXMLElement *enumXML = [xml elementForName: @"enumeration"];
		for (NSXMLElement *member in [enumXML elementsForName: @"member"])
		{
			auto *text = [NSMutableAttributedString attributedStringWithOO3XML: [member elementForName: @"text"]
			                                                  withPartialStyle: style];
			[enumValues	setObject: [text string]
			               forKey: [[member attributeForName: @"id"] stringValue]];
		}
	}
	return self;
}
- (NSXMLElement*)oo3xmlValue
{
	// FIXME: style
	NSXMLElement *col = [NSXMLElement elementWithName: @"column"];
	static std::unordered_map<OOOutlineColumnType, NSString*> columnTypes =
	{
		{ OOOutlineColumnTypeText, @"text" },
		{ OOOutlineColumnTypeNumber, @"number" },
		{ OOOutlineColumnTypeDate, @"date" },
		{ OOOutlineColumnTypeEnumeration, @"enumeration"}
	};
	// FIXME: sort direction (if any)
	[col setAttributesAsDictionary: @{
									  @"id"    : identifier,
									  @"type"  : columnTypes[columnType],
									  @"width" : [NSString stringWithFormat: @"%ld", (long)width],
									  @"minimum-width" : [NSString stringWithFormat: @"%ld", (long)minWidth],
									  @"maximum-width" : [NSString stringWithFormat: @"%ld", (long)maxWidth],
									  @"text-export-width" : [NSString stringWithFormat: @"%ld", (long)textExportWidth]
									 }];
	auto flag = [&](BOOL flag, NSString *name)
	{
		if (flag)
		{
			[col addAttribute: @"yes"
			         withName: name];
		}
	};
	flag(isNoteColumn, @"is-note-column");
	flag(isOutlineColumn, @"is-outline-column");
	NSXMLElement *styleNode = [style oo3xmlValue];
	if (styleNode)
	{
		[col addChild: styleNode];
	}
	NSXMLElement *titleNode = [NSXMLElement elementWithName: @"title"];
	[titleNode addChild: [title oo3xmlValueWithPartialStyle: document.titleStyle]];
	[col addChild: titleNode];
	if (formatter)
	{
		NSString *type;
		NSString *formatString;
		if ([formatter isKindOfClass: [NSNumberFormatter class]])
		{
			type = @"number";
			formatString = [(NSNumberFormatter*)formatter format];
		}
		else if ([formatter isKindOfClass: [OOUNIXDateFormatter class]])
		{
			type = @"date";
			formatString = [(OOUNIXDateFormatter*)formatter formatString];
		}
		NSAssert(formatString != nil, @"format string must not be nil!");
		NSXMLElement *formatterElement = [NSXMLElement elementWithName: @"formatter"
		                                                   stringValue: formatString];
		[formatterElement setAttributesAsDictionary: @{ @"type" : type }];
		[col addChild: formatterElement];
	}
	if (enumValues)
	{
		NSXMLElement *enumList = [NSXMLElement elementWithName: @"enumeration"];
		for (NSString *ident in enumValues)
		{
			NSXMLElement *member = [NSXMLElement elementWithName: @"member"];
			[member setAttributesAsDictionary: @{ @"id" : ident }];
			auto *elem = [[NSAttributedString alloc] initWithString: [enumValues objectForKey: ident]
			                                             attributes: defaultStyle];
			[member addChild: [elem oo3xmlValueWithPartialStyle: style]];
			[enumList addChild: member];
		}
		[col addChild: enumList];
	}
	return col;
}
@end
