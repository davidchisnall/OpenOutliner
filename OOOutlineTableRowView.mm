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

@implementation OOOutlineTableRowView
{
	/**
	 * The view used for editing notes.  Will be `nil` if the row does not have 
	 * notes.
	 */
	NSTextField *noteView;
	/**
	 * The model object for this view.
	 */
	OOOutlineRow *row;
	/**
	 * The outline view containing this row.
	 */
	DEBUG_WEAK OOOutlineView *outlineView;
}
- (void)setOutlineView: (OOOutlineView*)anOutlineView
{
	outlineView = anOutlineView;
}
/**
 * Action method called when the notes view is edited.
 */
- (IBAction)noteEdited: (id)sender
{
	auto *string = [sender attributedStringValue];
	if ([string length] ==0)
	{
		row.note = nil;
	}
	else
	{
		row.note = [string mutableCopy];
	}
}
- (void)dealloc
{
	[row removeObserver: self forKeyPath: @"note"];
}
/**
 * Lay out the views, making sure that the notes view is below the column views
 * and spanning the entire width.
 */
- (void)layout
{
	[super layout];
	NSInteger numberOfColumns = [self numberOfColumns];
	for (NSInteger i=0 ; i<numberOfColumns ; i++)
	{
		NSView *columnView = [self viewAtColumn: i];
		auto frame = [columnView frame];
		frame.size.height = 20;
		[columnView setFrame: frame];
	}
	if (noteView != nil)
	{
		auto firstColumnFrame = [[self viewAtColumn: 0] frame];
		auto frame = [noteView frame];
		frame.origin.x = firstColumnFrame.origin.x;
		frame.size.width = [self bounds].size.width - frame.origin.x;
		[noteView setFrame: frame];
	}
}
/**
 * Handle the change of the note.  This may involve creating or destroying a
 * view to display the note and resizing the row.
 */
- (void)setupNote: (NSAttributedString*)aNote
{
	BOOL newNote = (aNote != nil);
	BOOL oldNote = (noteView != nil);
	if (newNote && !oldNote)
	{
		NSRect b = [self bounds];
		b.size.height = 20;
		b.origin.y += 20;
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
		[self addSubview: noteView];
		[self setNeedsDisplay: YES];
	}
	else if (!newNote && oldNote)
	{
		[noteView removeFromSuperview];
		noteView = nil;
		[self setNeedsDisplay: YES];
	}
	if (newNote)
	{
		[noteView setAttributedStringValue: aNote];
	}
	if (newNote != oldNote)
	{
		auto *v = outlineView;
		assert(v != nil);
		NSIndexSet *idx = [NSIndexSet indexSetWithIndex: (NSUInteger)[v rowForItem: row]];
		[v noteHeightOfRowsWithIndexesChanged: idx];
	}
}
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context
{
	[self setupNote: [(OOOutlineRow*)object note]];
}
- (void)setRow: (OOOutlineRow*)aRow
{
	[row removeObserver: self forKeyPath: @"note"];
	row = aRow;
	[aRow addObserver: self
	       forKeyPath: @"note"
	          options: NSKeyValueObservingOptionNew
	          context: nullptr];
	[self setupNote: [aRow note]];

}
- (void)editNote
{
	[noteView becomeFirstResponder];
}
- (void)editColumn
{
	[[self viewAtColumn: 0] becomeFirstResponder];
}
- (void)drawRect:(NSRect)dirtyRect
{
	// FIXME: Display the notes a bit better.
	// Also display an icon to expand and contract notes.
	[super drawRect:dirtyRect];
}

@end
