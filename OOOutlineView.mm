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

@implementation OOOutlineView
- (IBAction)addRow: (id)sender;
{
	OOOutlineDataSource *delegate = self.delegate;
	[delegate addRow: sender];
}
- (IBAction)deleteSelectedRows: (id)sender
{
	OOOutlineDataSource *delegate = self.delegate;
	[delegate deleteSelectedRows: sender];
}
- (IBAction)increaseIndentLevel: (id)sender
{
	OOOutlineDataSource *delegate = self.delegate;
	[delegate increaseIndentLevel: sender];
}
- (IBAction)decreaseIndentLevel: (id)sender
{
	OOOutlineDataSource *delegate = self.delegate;
	[delegate decreaseIndentLevel: sender];
}

- (void)keyDown:(NSEvent *)event
{
	OOOutlineDataSource *delegate = self.delegate;
	auto keycode = [event keyCode];
	bool shift = [event modifierFlags] & NSEventModifierFlagShift;
	switch (keycode)
	{
		default:
			[super keyDown: event];
			break;
		case 36:
			if (shift)
			{
				[delegate addRow: self];
			}
			break;
		case 48:
			if (shift)
			{
				[delegate decreaseIndentLevel: self];
			}
			else
			{
				[self increaseIndentLevel: self];
			}
			break;
		case 51:
			[delegate deleteSelectedRows: self];
			break;
	}
}

@end
