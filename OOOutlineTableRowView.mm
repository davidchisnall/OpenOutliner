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

@implementation OOOutlineTableRow
{
	NSTextField *noteView;
	OOOutlineRow *row;
}

- (instancetype)initWithFrame: (NSRect)frameRect
{
	if (!(self = [super initWithFrame: frameRect]))
	{
		return nil;
	}
	[self setAutoresizesSubviews: NO];
	return self;
}
- (IBAction)noteEdited: (id)sender
{
	row.note = [[sender attributedStringValue] copy];
}
- (void)setNote: (NSA)
- (void)setRow: (OOOutlineRow*)aRow
{
	row = aRow;
	auto *note = [aRow note];
	if ((note != nil) && (noteView == nil))
	{
		NSRect b = [self bounds];
		b.size.height += 40;
		[self setBounds: b];
		b.size.height = 40;
		b.origin.x += 20;
		noteView = [[NSTextField alloc] initWithFrame: b];
		// FIXME: style from note column
		noteView.font = [NSFont systemFontOfSize: 10];
		noteView.bezeled = YES;
		noteView.bezelStyle = NSTextFieldRoundedBezel;
		NSTextFieldCell *c = noteView.cell;
		noteView.drawsBackground = NO;
		noteView.backgroundColor = [NSColor colorWithRed: 0.45
		                                           green: 0.5
		                                            blue: 1
		                                           alpha: 0.5];
		c.placeholderString = @"notes";
		noteView.target = self;
		noteView.action = @selector(noteEdited:);
		[self setNeedsDisplay: YES];
	}
	else if (!(note == nil) && (noteView != nil))
	{
		[noteView removeFromSuperview];
		noteView = nil;
		[self setNeedsDisplay: YES];
	}
}
- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	// Drawing code here.
}

@end
