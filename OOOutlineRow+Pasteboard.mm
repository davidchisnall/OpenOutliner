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

@implementation OOOutlineRow (Pasteboard)

+ (NSArray<NSString*>*)readableTypesForPasteboard: (NSPasteboard*)pasteboard
{
	return @[ OOOUtlineRowsPasteboardType ];
}
- (NSArray<NSString*>*)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
	return @[ OOOUtlineRowsPasteboardType ];
}
- (nullable id)pasteboardPropertyListForType:(NSString *)type
{
	if ([type isEqualToString: OOOUtlineRowsPasteboardType])
	{
		return self.identifier;
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
	return nil;
}
@end
