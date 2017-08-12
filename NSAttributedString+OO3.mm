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

@implementation NSAttributedString (OO3)
+ (instancetype)attributedStringWithOO3XML: (NSXMLElement*)xml
                          withPartialStyle: (OOPartialStyle*)aPartialStyle
{
	auto *value = [NSMutableAttributedString new];
	NSMutableString *strProxy = value.mutableString;
	BOOL separate = NO;
	NSDictionary *attributes = nil;
	for (NSXMLElement *p in [xml elementsForName: @"p"])
	{
		if (separate)
		{
			[strProxy appendString: @"\n"];
		}
		separate = YES;
		for (NSXMLElement *run in [p elementsForName: @"run"])
		{
			for (NSXMLElement *e in run.children)
			{
				if ([e.name isEqualToString: @"style"])
				{
					auto *ps = [aPartialStyle.registry partialStyleForOO3XML: e
					                                            inheritsFrom: aPartialStyle];
					attributes = [ps.registry attributesForStyle: ps];
				}
				else if ([e.name isEqualToString: @"lit"])
				{
					NSDictionary *attrs = attributes;
					id str = [e stringValue];
					if (NSXMLElement *cell = [e elementForName: @"cell"])
					{
						str = [[cell attributeForName: @"name"] stringValue];
						NSString *href = [[cell attributeForName: @"href"] stringValue];
						NSMutableDictionary *mutableAttrs = [attrs mutableCopy];
						if (!mutableAttrs)
						{
							mutableAttrs = [NSMutableDictionary new];
							[mutableAttrs setObject: aPartialStyle
							                 forKey: OOPartialStyleKey];
						}
						attrs = mutableAttrs;
						NSURL *url = [NSURL URLWithString: href];
						[mutableAttrs setObject: url
						                 forKey: NSLinkAttributeName];
					}
					NSAttributedString *textRun = [[NSAttributedString alloc] initWithString: str
					                                                              attributes: attrs];
					[value appendAttributedString: textRun];
				}
			}
		}
	}
	// Avoid a redundant copy here if we're in an
	// NSMutableAttributedString subclass.
	if ([self isKindOfClass: [NSMutableAttributedString class]])
	{
		return value;
	}
	return [[self alloc] initWithAttributedString: value];
}
- (NSXMLElement*)oo3xmlValueWithPartialStyle: (OOPartialStyle*)aPartialStyle
{
	NSXMLElement *text = [NSXMLElement elementWithName: @"text"];
	NSUInteger i = 0;
	NSUInteger len = [self length];
	NSString *str = [self string];
	do {
		NSRange searchRange = { i, 0 };
		NSUInteger start;
		NSUInteger end;
		[str getParagraphStart: &start
		                   end: &end
		           contentsEnd: nullptr
		              forRange: searchRange];
		NSXMLElement *p = [NSXMLElement elementWithName: @"p"];
		while (start < end)
		{
			NSRange r;
			NSDictionary *attrs = [self attributesAtIndex: start effectiveRange: &r];
			r.length = std::min(r.length, end-start);
			if (r.length > 0)
			{
				NSXMLElement *run = [NSXMLElement elementWithName: @"run"];
				NSXMLElement *lit = [NSXMLElement elementWithName: @"lit"
				                                      stringValue: [str substringWithRange: r]];
				// FIXME: Recalculate the style if it's changed.
				// FIXME: Get a partial style that this should inherit from if we don't have one.
				OOPartialStyle *ps = [attrs objectForKey: OOPartialStyleKey];
				NSXMLElement *style = [ps oo3xmlValue];
				if (style)
				{
					[run addChild: style];
				}
				if (NSURL *href = [attrs objectForKey: NSLinkAttributeName])
				{
					auto *cell = [NSXMLElement elementWithName: @"cell"
					                      attributesDictionary: @{
					                                                @"href" : [href absoluteString],
					                                                @"name" : [str substringWithRange: r]
					                                             }];
					lit = [NSXMLElement elementWithName: @"lit"];
					[lit addChild: cell];
				}
				// FIXME: Create cell nodes for links and so on
				[run addChild: lit];
				// FIXME: Turn the attributes into a <style> element here
				(void)attrs;
				[p addChild: run];
			}
			start += r.length;
		}
		i = end;
		[text addChild: p];
	} while (i < len);
	return text;
}


@end
