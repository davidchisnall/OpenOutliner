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

@implementation OOColumnInspectorController
{
	/**
	 * The document that this inspector refers to.
	 */
	DEBUG_WEAK OOOutlineDocument *document;
	/**
	 * The current column being inspected.
	 */
	OOOutlineColumn *column;
}
@synthesize
	columnName;
- (void)windowDidLoad
{
	[super windowDidLoad];
	[self resetColumns];
	[columnName selectItemAtIndex: 0];
	auto f = makeScopedKVOValueChange(self, @"column");
	column = [document.columns objectAtIndex: 0];
}
- (IBAction)columnChanged: (NSComboBox*)sender
{
	auto *doc = document;
	NSUInteger idx = (NSUInteger)[sender indexOfSelectedItem];
	if (idx == -1ULL)
	{
		[column setTitle: [[NSAttributedString alloc] initWithString: [columnName stringValue]]];
		[self resetColumns];
		[[NSNotificationCenter defaultCenter] postNotificationName: OOOutlineColumnsDidChangeNotification
		                                                    object: doc];
		return;
	}
	auto f = makeScopedKVOValueChange(self, @"column");
	column = [doc.columns objectAtIndex: idx];
}
+ (NSSet*)keyPathsForValuesAffectingValueForKey: (NSString*)aKey
{
	if ([@"hasFormatter" isEqualToString: aKey] ||
		[@"enumerationValues" isEqualToString: aKey] ||
		[@"columnTypeIndex" isEqualToString: aKey])
	{
		return [NSSet setWithObject: @"column"];
	}
	return nil;
}
- (void)setColumnTypeIndex: (NSNumber*)anIndex
{
	switch ([anIndex intValue])
	{
		default:
			NSAssert(NO, @"Invalid column index");
		case 0:
			[column setColumnType: OOOutlineColumnTypeText];
			break;
		case 1:
			[column setColumnType: OOOutlineColumnTypeNumber];
			break;
		case 2:
			[column setColumnType: OOOutlineColumnTypeDate];
			break;
		case 3:
			[column setColumnType: OOOutlineColumnTypeEnumeration];
			break;
		case 4:
			[column setColumnType: OOOutlineColumnTypeCheckBox];
			break;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName: OOOutlineColumnsDidChangeNotification
														object: document];

}
- (NSNumber*)columnTypeIndex
{
	switch ([column columnType])
	{
		case OOOutlineColumnTypeText:
			return @(0);
		case OOOutlineColumnTypeNumber:
			return @(1);
		case OOOutlineColumnTypeDate:
			return @(2);
		case OOOutlineColumnTypeEnumeration:
			return @(3);
		case OOOutlineColumnTypeCheckBox:
			return @(4);
	}
	NSAssert(NO, @"Unknown column type!");
	return nil;
}

- (IBAction)addCoulumn: (id)sender
{
	auto *doc = document;
	auto *col = [[OOOutlineColumn alloc] initWithType: OOOutlineColumnTypeText
	                                       inDocument: doc];
	[col setTitle: [[NSAttributedString alloc] initWithString: @"Untitled"]];
	[doc addColumn: col];
	[self resetColumns];
}
- (IBAction)removeCoulumn: (id)sender
{
}
- (BOOL)hasFormatter
{
	return column.formatter != nil;
}
- (void)resetColumns
{
	auto *box = columnName;
	auto *doc = document;
	[box removeAllItems];
	for (OOOutlineColumn *col in doc.columns)
	{
		[box addItemWithObjectValue: col.title];
	}
	NSUInteger idx = (column != nil) ? [[doc columns] indexOfObjectIdenticalTo: column] : 0;
	[box selectItemAtIndex: (NSInteger)idx];
}
- (void)setOutlineDocument: (OOOutlineDocument*)anOutlineDocument
{
	document = anOutlineDocument;
	[self resetColumns];
}
- (NSMutableArray*)enumerationValues
{
	return nil;
}

@end
