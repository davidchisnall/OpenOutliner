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
#import <objc/runtime.h>
#import <objc/message.h>

@implementation OOOutlineView
- (void)keyDown:(NSEvent *)event
{
	OOOutlineDataSource *delegate = self.delegate;
	auto keycode = [event keyCode];
	bool shift = [event modifierFlags] & NSEventModifierFlagShift;
	NSLog(@"keycode: %d", (int)keycode);
	switch (keycode)
	{
		default:
			[super keyDown: event];
			break;
		case 36:
		{
			if (shift)
			{
				[delegate addRow: self];
				break;
			}
			OOOutlineTableRowView *rv = [self rowViewAtRow: [self selectedRow] makeIfNecessary: NO];
			[rv editColumn];
			break;
		}
		case 48:
			if (shift)
			{
				[delegate decreaseIndentLevel: self];
			}
			else
			{
				[delegate increaseIndentLevel: self];
			}
			break;
		case 51:
			[delegate deleteSelectedRows: self];
			break;
	}
}
- (BOOL)respondsToSelector: (SEL)aSelector
{
	// The responder chain will query whether we can respond to a particular
	// message before sending it.  Allow us to proxy messages for the delegate
	// to let it handle actions.
	if ([super respondsToSelector: aSelector])
	{
		return YES;
	}
	if ([self.delegate respondsToSelector: aSelector])
	{
		return YES;
	}
	return NO;
}
- (id)forwardingTargetForSelector:(SEL)aSelector
{
	// If we don't respond to a method, let the delegate try.
	return self.delegate;
}
- (void)copy: (id)sender
{
	auto *pb = [NSPasteboard generalPasteboard];
	auto *selection = [self selectedRowIndexes];
	auto *selectedObjects = [NSMutableArray new];
	for (NSUInteger i : IndexSetRange<>(selection))
	{
		NSAssert([[self itemAtRow: static_cast<NSInteger>(i)] conformsToProtocol: @protocol(NSPasteboardWriting)],
		         @"Trying to write invalid object to pasteboard");
		[selectedObjects addObject: [self itemAtRow: static_cast<NSInteger>(i)]];
	}
	[pb clearContents];
	[pb writeObjects: selectedObjects];
}
- (void)paste: (id)sender
{
	OOOutlineDataSource *delegate = self.delegate;
	[delegate pasteFromPasteboard: [NSPasteboard generalPasteboard]];
}
- (BOOL)validateMenuItem: (NSMenuItem *)item
{
	OOOutlineDataSource *delegate = self.delegate;
	NSString *selName = NSStringFromSelector([item action]);
	NSString *firstCharUpper = [[selName substringToIndex: 1] uppercaseString];
	NSString *rest = [selName substringFromIndex: 1];
	NSString *querySelName = [NSString stringWithFormat: @"can%@%@", firstCharUpper, rest];
	SEL querySel = NSSelectorFromString(querySelName);
	if ([delegate respondsToSelector: querySel])
	{
		return ((BOOL(*)(id, SEL))objc_msgSend)(delegate, querySel);
	}
	return YES;
}

@end
