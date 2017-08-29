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

thread_local OOOutlineDocument __unsafe_unretained *currentDocument;



@implementation OOOutlineRow (Pasteboard)

+ (NSArray<NSString*>*)readableTypesForPasteboard: (NSPasteboard*)pasteboard
{
	return @[ OOOUtlineRowsPasteboardType, OOOUtlineXMLPasteboardType ];
}
- (NSPasteboardWritingOptions)writingOptionsForType: (NSString*)type
                                         pasteboard: (NSPasteboard *)pasteboard
{
	return 0;
}
- (NSArray<NSString*>*)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
	if ([[pasteboard name] isEqualToString: NSDragPboard])
	{
		return @[ OOOUtlineRowsPasteboardType, (NSString*)kUTTypeUTF8PlainText, OOOUtlineXMLPasteboardType ];
	}
	return @[ (NSString*)kUTTypeUTF8PlainText, OOOUtlineXMLPasteboardType ];
}
- (void)writeToString: (NSMutableString*)aString withIndent: (NSUInteger)anIndent
{
	NSUInteger column = 0;
	auto *cols = self.document.columns;
	for (NSUInteger i=0 ; i<anIndent ; i++)
	{
		[aString appendString: @"\t"];
	}
	NSUInteger colCount = [cols count];
	for (OOOutlineValue *val in self.values)
	{
		OOOutlineColumn *col = [cols objectAtIndex: column];
		NSString *str;
		id value = [val value];
		if ([value isKindOfClass: [NSDate class]])
		{
			str = [value description];
		}
		else
		{
			str = get<NSString*>(value);
		}
		NSUInteger columnWidth = [col textExportWidth];
		if (str != nil)
		{
			[aString appendString: str];
		}
		column++;
		if (column == colCount)
		{
			break;
		}
		if ([str length] < columnWidth)
		{
			columnWidth -= [str length];
			for (NSUInteger i=0 ; i< columnWidth ; i++)
			{
				[aString appendString: @" "];
			}
		}
		[aString appendString: @"\t"];
	}
}
- (nullable id)pasteboardPropertyListForType:(NSString *)type
{
	if ([type isEqualToString: OOOUtlineRowsPasteboardType])
	{
		return self.identifier;
	}
	if ([type isEqualToString: (NSString*)kUTTypeUTF8PlainText])
	{
		NSUInteger indent = -1ULL;
		OOOutlineRow *parent = self;
		auto *doc = self.document;
		while ((parent = [doc parentForRow: parent]))
		{
			indent++;
		}
		auto *str = [NSMutableString new];
		[self writeToString: str withIndent: indent];
		return str;
	}
	if ([type isEqualToString: OOOUtlineXMLPasteboardType])
	{
		return [[self oo3xmlValue] XMLString];
	}
	return nil;
}
- (nullable id)initWithPasteboardPropertyList: (id)propertyList
                                       ofType: (NSString *)type
{
	if ([type isEqualToString: OOOUtlineRowsPasteboardType])
	{
		NSString *ident = [[NSString alloc] initWithData: propertyList
		                                        encoding: NSUTF8StringEncoding];
		for (OOOutlineDocument *doc in [OOOutlineDocument allDocuments])
		{
			if (OOOutlineRow *row = [[doc allRows] objectForKey: ident])
			{
				return row;
			}
		}
	}
	if ([type isEqualToString: OOOUtlineXMLPasteboardType])
	{
		NSString *str = [[NSString alloc] initWithData: propertyList
		                                      encoding: NSUTF8StringEncoding];
		NSError *err = nil;
		auto *element = [[NSXMLElement alloc] initWithXMLString: str
														  error: &err];
		if (err)
		{
			[NSApp presentError: err];
			return nil;
		}
		return [self initWithOO3XMLNode: element inDocument: currentDocument];
	}
	return nil;
}
@end
