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
- (instancetype)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame: frameRect]) == nil)
	{
		return nil;
	}
	return self;
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
		frame.size.height = 23;
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
		b.origin.y += 23;
		noteView = [[NSTextField alloc] initWithFrame: b];
		// FIXME: style from note column
		noteView.font = [NSFont systemFontOfSize: 10];
		noteView.bezeled = YES;
		noteView.bezelStyle = NSTextFieldRoundedBezel;
		NSTextFieldCell *c = noteView.cell;
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
	if ([@"note" isEqualToString: keyPath])
	{
		[self setupNote: [(OOOutlineRow*)object note]];
	}
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
- (void)addSubview: (NSView*)view
{
	[super addSubview: view];
	BOOL found = NO;
	for (NSInteger i=0, e=[self numberOfColumns] ; i<e ; i++)
	{
		if (view == [self viewAtColumn: i])
		{
			found = YES;
			break;
		}
	}
	if (!found)
	{
		return;
	}
	if ([view respondsToSelector: @selector(setDelegate:)])
	{
		[(id)view setDelegate: self];
	}
	if (![view isKindOfClass: [NSControl class]])
	{
		return;
	}
	auto *control = (NSControl*)view;
	control.target = self;
	control.action = @selector(edited:);
}
- (void)willRemoveSubview: (NSView*)view
{
	[super willRemoveSubview: view];
	if (view == noteView)
	{
		return;
	}
	if ([view respondsToSelector: @selector(setDelegate:)])
	{
		[(id)view setDelegate: nil];
	}
	if (![view isKindOfClass: [NSControl class]])
	{
		return;
	}
	auto *control = (NSControl*)view;
	control.target = nil;
}
- (void)edited: sender
{
	NSUInteger columnNumber = -1;
	for (NSInteger i=0, e=[self numberOfColumns] ; i<e ; i++)
	{
		if (sender == [self viewAtColumn: i])
		{
			columnNumber = i;
			break;
		}
	}
	if (columnNumber == -1)
	{
		return;
	}
	auto *doc = row.document;
	auto *column = [doc.columns objectAtIndex: columnNumber];
	NSControl *view = sender;
	OOOutlineValue *val = [row.values objectAtIndex: columnNumber];
	id obj = [view isKindOfClass: [NSComboBox class]]
		? [(NSComboBox*)view objectValueOfSelectedItem]
		: [view objectValue];
	OOOutlineValue *newVal = [[[val class] alloc] initWithValue: obj
	                                                   inColumn: column];
	auto *vals = row.values;
	scoped_undo_grouping undo([doc undoManager], @"edit cell");
	OOOutlineView *parent = (OOOutlineView*)[self superview];
	NSAssert([parent isKindOfClass: [OOOutlineView class]], @"Incorrect superview!");
	auto *oldValue = [vals objectAtIndex: columnNumber];
	newVal = [column value: oldValue willChangeTo: newVal];
	[undo.record(parent) reloadItem: nil reloadChildren: YES];
	[undo.record(vals) replaceObjectAtIndex: columnNumber
	                             withObject: [vals objectAtIndex:columnNumber]];
	[vals replaceObjectAtIndex: columnNumber
	                withObject: newVal];

}
- (void)comboBoxSelectionDidChange: (NSNotification*)aNotification
{
	[self edited: [aNotification object]];
}

@end
