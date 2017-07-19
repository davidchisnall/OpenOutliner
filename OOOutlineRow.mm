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

@implementation OOOutlineRow
@synthesize
	checkedState,
	children,
	document,
	identifier,
	isExpanded,
	isNoteExpanded,
	note,
	values;

- (id)initInDocument: (OOOutlineDocument*)aDoc
{
	return [self initWithOO3XMLNode: nil inDocument: aDoc];
}
- (id)initWithOO3XMLNode: (NSXMLElement*)xml
              inDocument: (OOOutlineDocument*)aDoc
{
	OO_SUPER_INIT();
	static object_map<NSString*, OOOutlineRowCheckedState> checked_names = {
		{ @"indeterminate", OOOutlineRowCheckedIndeterminate},
		{ @"checked", OOOutlineRowChecked },
		{ @"unchecked", OOOutlineRowUnChecked }
	};
	children = [NSMutableArray new];
	values = [NSMutableArray new];
	document = aDoc;
	if (xml)
	{
		for (NSXMLElement *c in [xml elementsForName: @"children"])
		{
			for (NSXMLElement *e in [c elementsForName: @"item"])
			{
				[children addObject: [[OOOutlineRow alloc] initWithOO3XMLNode: e
				                                                   inDocument: aDoc]];
			}
		}
		if (NSXMLElement *e = [xml elementForName: @"values"])
		{
			auto *cols = aDoc.columns;
			NSUInteger i = 0;
			for (NSXMLElement *v in e.children)
			{
				OOOutlineColumn *col = [cols objectAtIndex: i++];
				[values addObject: [OOOutlineValue outlineValueWithOO3XML: v
				                                                 inColumn: col]];
			}
		}
		isExpanded = [[[xml attributeForName: @"expanded"] stringValue] boolValue];
		if (auto *n = [xml elementForName: @"note"])
		{
			note = [NSMutableAttributedString attributedStringWithOO3XML: [n elementForName: @"text"]
			                                            withPartialStyle: aDoc.noteColumn.style];
			isNoteExpanded = [[[n attributeForName: @"expanded"] stringValue] boolValue];
		}
		identifier = [[xml attributeForName: @"id"] stringValue];
		if (NSString *checked = [[xml attributeForName: @"state"] stringValue])
		{
			checkedState = checked_names[checked];
		}
	}
	else
	{
		for (NSUInteger i=0, e=[aDoc.columns count] ; i<e ; ++i)
		{
			[values addObject: [OOOutlineValue placeholder]];
		}
	}
	if (!identifier)
	{
		identifier = identifierString();
	}
	[[aDoc allRows] setObject: self forKey: identifier];
	return self;
}
- (id)initWithOO2Plist: (NSDictionary*)aPlist
           notesColumn: (NSUInteger)aColumn
            inDocument: (OOOutlineDocument*)aDoc
{
	if (!(self = [self initInDocument: aDoc]))
	{
		return nil;
	}
	[values removeAllObjects];
	isExpanded = [[aPlist objectForKey: @"Expanded"] boolValue];
	NSUInteger idx = 0;
	NSUInteger columnIndex = 0;
	for (NSString *child in [aPlist objectForKey: @"Cols"])
	{
		NSData *rtf = [child dataUsingEncoding: NSUTF8StringEncoding];
		NSAttributedString *contents = [[NSAttributedString alloc] initWithRTF: rtf
		                                                    documentAttributes: nil];
		if (idx++ == aColumn)
		{
			if ([contents length] > 0)
			{
				note = [contents mutableCopy];
			}
		}
		else
		{
			[values addObject: [[OOOutlineValue alloc] initWithValue: contents
			                                                inColumn: [aDoc.columns objectAtIndex: columnIndex++]]];
		}
	}
	for (NSDictionary *child in [aPlist objectForKey: @"Children"])
	{
		[children addObject: [[OOOutlineRow alloc] initWithOO2Plist: child
														notesColumn: aColumn
		                                                 inDocument: aDoc]];
	}
	return self;
}

- (NSXMLElement*)oo3xmlValue
{
	NSXMLElement *row = [NSXMLElement elementWithName: @"item"];
	static std::unordered_map<OOOutlineRowCheckedState, NSString*> checked_names = {
		{ OOOutlineRowCheckedIndeterminate, @"indeterminate"},
		{ OOOutlineRowChecked, @"checked" },
		{ OOOutlineRowUnChecked, @"unchecked" }
	};
	[row setAttributesWithDictionary: @{
	                                     @"id"    : identifier,
	                                     @"state" : checked_names[checkedState]
	                                   }];
	if (isExpanded)
	{
		[row addAttribute: @"yes" withName: @"expanded"];
	}
	NSXMLElement *vals = [NSXMLElement elementWithName: @"values"];
	for (OOOutlineValue *val in values)
	{
		[vals addChild: [val oo3xmlValue]];
	}
	[row addChild: vals];
	if (note)
	{
		NSXMLElement *noteXML = [NSXMLElement elementWithName: @"note"];
		if (isNoteExpanded)
		{
			[noteXML addAttribute: @"yes" withName: @"expanded"];
		}
		[noteXML addChild: [note oo3xmlValueWithPartialStyle: document.noteColumn.style]];
		[row addChild: noteXML];
	}
	if ([children count] > 0)
	{
		NSXMLElement *childs = [NSXMLElement elementWithName: @"children"];
		for (OOOutlineRow *child in children)
		{
			[childs addChild: [child oo3xmlValue]];
		}
		[row addChild: childs];
	}
	return row;
}
@end
