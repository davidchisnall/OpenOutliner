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

@implementation NSColor (OO3)
+ (instancetype)colourWithOO3XML: (NSXMLElement*)xml
{
	auto floatAttr = [&](NSString *name)
		{
			return [[[xml attributeForName: name] stringValue] doubleValue];
		};
	auto floatAttrOrDefault = [&](NSString *name, CGFloat f)
		{
			if (auto *attr = [xml attributeForName: name])
			{
				f = [[attr stringValue] doubleValue];
			}
			return f;
		};
	auto hasAttr = [&](NSString *name)
		{
			return [xml attributeForName: name] != nil;
		};
	if (NSString *space = [[xml attributeForName: @"space"] stringValue])
	{
		if ([space isEqualToString: @"srgb"])
		{
			return [self colorWithSRGBRed: floatAttr(@"r")
			                        green: floatAttr(@"g")
			                         blue: floatAttr(@"b")
			                        alpha: floatAttrOrDefault(@"a", 1)];
		}
		NSLog(@"Ignoring unknown space: %@", space);
	}
	if (hasAttr(@"w"))
	{
		return [self colorWithWhite: floatAttr(@"w")
		                      alpha: floatAttrOrDefault(@"a", 1)];
	}
	if (hasAttr(@"r") && hasAttr(@"g") && hasAttr(@"b"))
	{
		return [self colorWithSRGBRed: floatAttr(@"r")
		                        green: floatAttr(@"g")
		                         blue: floatAttr(@"b")
		                        alpha: floatAttrOrDefault(@"a", 1)];
	}
	if (hasAttr(@"c") && hasAttr(@"m") && hasAttr(@"y") && hasAttr(@"k"))
	{
		return [self colorWithDeviceCyan: floatAttr(@"c")
		                         magenta: floatAttr(@"m")
		                          yellow: floatAttr(@"y")
		                           black: floatAttr(@"k")
		                           alpha: floatAttrOrDefault(@"a", 1)];
	}

	return nil;
}
- (NSXMLElement*)oo3xmlValue
{
	NSColorSpace *cs = [self colorSpace];
	NSXMLElement *xml = [NSXMLElement elementWithName: @"color"];
	NSColor *c = self;
	auto setAttr = [&](NSString *name, CGFloat val)
		{
			[xml addAttribute: [NSString stringWithFormat: @"%lf", (double)val]
			         withName: name];
		};
	auto addAlpha = [&]()
		{
			CGFloat a = [self alphaComponent];
			if (a != 1)
			{
			    [xml addAttribute: [NSString stringWithFormat: @"%lf", (double)a]
			             withName: @"a"];
			}
		};

	switch ([cs colorSpaceModel])
	{
		case NSColorSpaceModelGray:
			setAttr(@"w", [self whiteComponent]);
			addAlpha();
			return xml;
		case NSColorSpaceModelCMYK:
			setAttr(@"c", [self cyanComponent]);
			setAttr(@"m", [self magentaComponent]);
			setAttr(@"y", [self yellowComponent]);
			setAttr(@"k", [self blackComponent]);
			addAlpha();
			return xml;
		default:
			c = [self colorUsingColorSpace: [NSColorSpace sRGBColorSpace]];
		case NSColorSpaceModelRGB:
			if (cs == [NSColorSpace sRGBColorSpace])
			{
				[xml addAttribute: @"srgb"
				         withName: @"space"];
			}
			setAttr(@"r", [c redComponent]);
			setAttr(@"g", [c greenComponent]);
			setAttr(@"b", [c blueComponent]);
			addAlpha();
			return xml;
	}

	return nil;
}
@end
