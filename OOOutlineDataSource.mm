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
#include <vector>

/**
 * Helper class that handles events from cells in the outline view.
 */
@interface OOOutlineCellDelegate : NSObject <NSTextFieldDelegate>
/**
 * The row for which this is handling actions.
 */
@property (nonatomic) OOOutlineRow *row;
/**
 * The column number for which this is handling actions.
 */
@property (nonatomic) NSUInteger columnNumber;
/**
 * The column for which this is handling actions.
 */
@property (nonatomic) OOOutlineColumn *column;
/**
 * The controller displaying the outline.
 */
@property (nonatomic, unsafe_unretained) OOOutlineDataSource *controller;
@end

@interface OOOutlineDataSource ()
- (void)clearCacheAndUpdate;
@end

auto *OOOUtlineRowsPasteboardType = @"org.theravensnest.openoutliner.internal.drag";

namespace {
/**
 * Find the parent and indexes of all of the specified rows.  When removing rows
 * from the outline, we must find their parents and remove them.  We don't want
 * to remove any of the nodes where we're already removing the parents.
 */
void collectRowsToRemove(OOOutlineDocument *doc,
                         NSArray<OOOutlineRow*> *rows,
                         object_map<OOOutlineRow*, NSMutableIndexSet*> &removals)
{
	NSSet *set = [NSSet setWithArray: rows];
	for (OOOutlineRow *r : rows)
	{
		OOOutlineRow *p = [doc parentForRow: r];
		// Skip any where we're already removing the parent.
		if ([set containsObject: p])
		{
			continue;
		}
		auto idx = [p.children indexOfObject: r];
		auto &idxs = removals[p];
		if (!idxs)
		{
			idxs = [NSMutableIndexSet indexSetWithIndex: idx];
		}
		else
		{
			[idxs addIndex: idx];
		}
	}
}

struct scoped_undo_grouping
{
	NSUndoManager *undo;
	scoped_undo_grouping(NSUndoManager *u, NSString *name) :
		undo(u)
	{
		[undo beginUndoGrouping];
		[undo setActionName: _(name)];
		NSLog(@"");
	}
	template<typename T>
	T record(T receiver)
	{
		return [undo prepareWithInvocationTarget: receiver];
	}
	~scoped_undo_grouping()
	{
		[undo endUndoGrouping];
	}
};
} // Anon namespace

@implementation OOOutlineCellDelegate
@synthesize
	column,
	columnNumber,
	controller,
	row;

- (void)edited: sender
{
	NSControl *view = sender;
	if ((NSInteger)columnNumber == -1)
	{
		row.note = [[view attributedStringValue] copy];
		return;
	}
	OOOutlineValue *val = [row.values objectAtIndex: columnNumber];
	OOOutlineValue *newVal = [[[val class] alloc] initWithValue: [view objectValue]
	                                                   inColumn: column];
	auto *vals = row.values;
	scoped_undo_grouping undo([row.document undoManager], @"edit cell");
	[undo.record(controller) clearCacheAndUpdate];
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

@implementation OOOutlineDataSource
{
	/**
	 * Cache of the mapping from outline rows to children.  The children are
	 * either other outline rows or notes.
	 */
	object_map<OOOutlineRow*, std::vector<id>> childNodes;
	/**
	 * Vector indexed by column of map tables containing weak-to-strong maps
	 * from rows to `OOOutlineCellDelegate` instances.  This allows us to
	 * recycle these objects.
	 */
	std::vector<NSMapTable*> targets;
}
@synthesize
	document,
	view;

- (void)awakeFromNib
{
	OOOutlineDocument *doc = document;
	NSOutlineView *v = view;
	auto *cols = [doc columns];
	auto *c = [cols objectAtIndex: 0];
	auto *tc = [v outlineTableColumn];
	[tc setMinWidth: c.minWidth];
	[tc setMaxWidth: c.maxWidth];
	[tc setTitle: [c.title string]];
	[tc setWidth: c.width];
	[tc setIdentifier: @"0"];
	targets.push_back([NSMapTable weakToStrongObjectsMapTable]);
	targets.push_back([NSMapTable weakToStrongObjectsMapTable]);
	for (NSUInteger i = 1 ; i<[doc columnCount] ; i++)
	{
		c = [cols objectAtIndex: i];
		tc = [[NSTableColumn alloc] initWithIdentifier: [NSString stringWithFormat: @"%d", (int)i]];
		[tc setMinWidth: c.minWidth];
		[tc setMaxWidth: c.maxWidth];
		[tc setTitle: [c.title string]];
		[v addTableColumn: tc];
		// Adding the column to the table will reset its width to minWidth, so we must set its width afterwards.
		[tc setWidth: c.width];
		targets.push_back([NSMapTable weakToStrongObjectsMapTable]);
	}
	std::function<void(OOOutlineRow*)> visit = [&](OOOutlineRow *r)
		{
			if ([r isExpanded])
			{
				[view expandItem: r];
			}
			for (OOOutlineRow *c in r.children)
			{
				visit(c);
			}
		};
	visit(doc.root);
	[v registerForDraggedTypes: @[ OOOUtlineRowsPasteboardType ]];
}

- (id)outlineView: (NSOutlineView*)outlineView
            child: (NSInteger)index
           ofItem: item
{
	if (item == nil)
	{
		item  = document.root;
	}
	return childNodes[item][(size_t)index];
}
- (BOOL)outlineView: (NSOutlineView*)outlineView
   isItemExpandable: item
{
	return [self outlineView: outlineView numberOfChildrenOfItem: item] > 0;
}
- (NSInteger)outlineView: (NSOutlineView*)outlineView
  numberOfChildrenOfItem: item
{
	if (item == nil)
	{
		item  = document.root;
	}
	if (![item isKindOfClass: [OOOutlineRow class]])
	{
		return 0;
	}

	auto &children = childNodes[item];
	if (children.empty())
	{
		for (OOOutlineRow *child in [item children])
		{
			children.push_back(child);
			if (child.note)
			{
				children.push_back(child.note);
			}
		}
	}
	return (NSInteger)children.size();
}
-         (id)outlineView: (NSOutlineView*)outlineView
objectValueForTableColumn: (NSTableColumn*)tableColumn
                   byItem: (OOOutlineRow*)item
{
	@try
	{
		NSUInteger idx = get<NSUInteger>([tableColumn identifier]);
		if ([item isKindOfClass: [OOOutlineRow class]])
		{
			id val = [[[item values] objectAtIndex: idx] value];
			if (val == nil)
			{
				OOOutlineColumn *col = [document.columns objectAtIndex: idx];
				if (auto *summary = col.summary)
				{
					val = [summary computeSummaryForRow: item
					                           inColumn: idx].value;
				}
			}
			return val;
		}
		return idx == 0 ? item : nil;
	}
	@catch (...)
	{
		// FIXME: Big hammer error handling.  We shouldn't be getting exceptions
		// here at all.
		return nil;
	}
}
- (BOOL)outlineView: (NSOutlineView*)outlineView
        isGroupItem: item
{
	return [item isKindOfClass: [NSAttributedString class]];
}
- (NSView*)outlineView: (NSOutlineView*)outlineView
    viewForTableColumn: (NSTableColumn*)tableColumn
                  item: item
{
	// TODO: This code creates a lot of views.  Some caching
	// might be appropriate, but profile first to see if it's
	// actually a bottleneck.
	OOOutlineDocument *doc = document;
	NSInteger idx = get<NSInteger>([tableColumn identifier]);
	if (tableColumn == nil)
	{
		NSAssert([item isKindOfClass: [NSAttributedString class]], @"Group rows should be notes");
		NSInteger row = [outlineView rowForItem: item];
		NSTableRowView *rv = [outlineView rowViewAtRow: row makeIfNecessary: NO];
		NSRect b = rv ? [rv bounds] : NSMakeRect(0, 0, [view bounds].size.width, 20);
		rv.backgroundColor = [NSColor whiteColor];
		b.size.width -= 5;
		auto *v = [[NSTextField alloc] initWithFrame: b];
		v.font = [NSFont systemFontOfSize: 10];
		v.bezeled = YES;
		v.bezelStyle = NSTextFieldRoundedBezel;
		NSTextFieldCell *c = v.cell;
		v.drawsBackground = NO;
		v.backgroundColor = [NSColor colorWithRed: 0.45
		                                    green: 0.5
		                                     blue: 1
		                                    alpha: 0.5];
		c.placeholderString = @"notes";
		OOOutlineCellDelegate *d = [targets[0] objectForKey: item];
		if (!d)
		{
			d = [OOOutlineCellDelegate new];
			d.columnNumber = (NSUInteger)-1;
			d.column = doc.noteColumn;
			d.row = [outlineView itemAtRow: row - 1];
			d.controller = self;
			[targets[0] setObject: d forKey: item];
		}
		v.target = d;
		v.action = @selector(edited:);
		return v;
	}
	auto *modelColumn = [doc.columns objectAtIndex: (NSUInteger)idx];
	auto setDelegate = [&](auto *v) {
		OOOutlineCellDelegate *d = [targets[(size_t)idx+1] objectForKey: item];
		if (!d)
		{
			d = [OOOutlineCellDelegate new];
			d.columnNumber = (NSUInteger)idx;
			d.column = [doc.columns objectAtIndex: (NSUInteger)idx];
			d.row = item;
			d.controller = self;
			[targets[(size_t)idx+1] setObject: d forKey: item];
		}
		v.target = d;
		v.action = @selector(edited:);
	};
	auto applyStyle = [&](auto *v) {
		v.formatter = modelColumn.formatter;
		v.drawsBackground = NO;
		v.allowsEditingTextAttributes = YES;
		v.editable = YES;
		setDelegate(v);
	};
	// If this is an enumeration, present it as a combo box, populated with the enumeration kinds.
	if (modelColumn.columnType == OOOutlineColumnTypeEnumeration)
	{
		auto *v = [NSComboBox new];
		v.bordered = NO;
		[v addItemsWithObjectValues: [[modelColumn enumValues] allValues]];
		v.bordered = NO;
		v.buttonBordered = NO;
		v.bezeled = NO;
		v.completes = YES;
		applyStyle(v);
		v.delegate = v.target;
		return v;
	}
	else if (modelColumn.columnType == OOOutlineColumnTypeCheckBox)
	{
		auto *v = [NSButton new];
		v.allowsMixedState = YES;
		[v setButtonType: NSSwitchButton];
		[v setTitle: @""];
		setDelegate(v);
		return v;
	}
	auto *v = [NSTextField new];
	v.bordered = NO;
	applyStyle(v);
	return v;
}

- (CGFloat)outlineView: (NSOutlineView*)outlineView
     heightOfRowByItem: item
{
	return 20;
}

- (void)clearCacheAndUpdate
{
	childNodes.clear();
	[view reloadItem: nil reloadChildren: YES];
}

- (BOOL)outlineView: (NSOutlineView*)outlineView
         acceptDrop: (id<NSDraggingInfo>)info
               item: (OOOutlineRow*)item
         childIndex: (NSInteger)index
{
	auto *doc = document;
	NSArray<OOOutlineRow*> *rows = [[info draggingPasteboard] readObjectsForClasses: @[ [OOOutlineRow class] ] options: nil];
	auto *insertIndexes = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange((NSUInteger)index,  [rows count])];
	object_map<OOOutlineRow*, NSMutableIndexSet*> removals;
	collectRowsToRemove(doc, rows, removals);
	scoped_undo_grouping undo([doc undoManager], @"move rows");
	// Register the reload first, so that it will be invoked after undoing all
	// of the changes.
	[undo.record(self) clearCacheAndUpdate];
	[item.children insertObjects: rows atIndexes: insertIndexes];
	[undo.record(item.children) removeObjectsAtIndexes: insertIndexes];
	for (auto r : removals)
	{
		if (r.first == item)
		{
			[r.second shiftIndexesStartingAtIndex: (NSUInteger)index
			                                   by: (NSInteger)[rows count]];
		}
		auto *toRemove = [r.first.children objectsAtIndexes: r.second];
		[undo.record(r.first.children) insertObjects: toRemove
		                                   atIndexes: r.second];
		[r.first.children removeObjectsAtIndexes: r.second];
	}
	[self clearCacheAndUpdate];
	return YES;
}
- (NSDragOperation)outlineView: (NSOutlineView*)outlineView
                  validateDrop: (id<NSDraggingInfo>)info
                  proposedItem: item
            proposedChildIndex: (NSInteger)index
{
	if (outlineView == view)
	{
		return NSDragOperationMove;
	}
	return NSDragOperationCopy;
}

- (BOOL)outlineView: (NSOutlineView*)outlineView
         writeItems: (NSArray*)items
       toPasteboard: (NSPasteboard*)pasteboard
{
	[pasteboard writeObjects: items];
	return YES;
}
- (IBAction)addRow: sender
{
	auto *doc = document;
	auto *v = view;
	OOOutlineRow *selected = [v itemAtRow: [v selectedRow]];
	OOOutlineRow *row = [doc parentForRow: selected];
	if (row == nil)
	{
		row = doc.root;
	}
	auto *children = row.children;
	NSUInteger idx = selected ? [children indexOfObject: selected] + 1 : 0;
	auto *newRow = [[OOOutlineRow alloc] initInDocument: doc];
	scoped_undo_grouping undo([doc undoManager], @"insert row");
	[undo.record(self) clearCacheAndUpdate];
	[undo.record(children) removeObjectAtIndex: idx];
	[children insertObject: newRow atIndex: idx];
	[self clearCacheAndUpdate];
	[v selectRowIndexes: [NSIndexSet indexSetWithIndex: (NSUInteger)[v rowForItem: newRow]] byExtendingSelection: NO];
}
- (IBAction)deleteSelectedRows:(id)sender
{
	NSIndexSet *selectedRows = [view selectedRowIndexes];
	auto *v = view;
	auto *rows = [NSMutableArray new];
	for (auto i : IndexSetRange<>(selectedRows))
	{
		id item = [v itemAtRow: (NSInteger)i];
		if ([item isKindOfClass: [OOOutlineRow class]])
		{
			[rows addObject: item];
		}
	}
	auto *doc = document;
	object_map<OOOutlineRow*, NSMutableIndexSet*> removals;
	collectRowsToRemove(doc, rows, removals);
	scoped_undo_grouping undo([doc undoManager], @"delete rows");
	// Register the reload first, so that it will be invoked after undoing all
	// of the changes.
	[undo.record(self) clearCacheAndUpdate];
	for (auto r : removals)
	{
		auto *toRemove = [r.first.children objectsAtIndexes: r.second];
		[undo.record(r.first.children) insertObjects: toRemove
		                                   atIndexes: r.second];
		[r.first.children removeObjectsAtIndexes: r.second];
	}
	[self clearCacheAndUpdate];

}
#ifdef TRACE_METHOD_QUERIES
- (BOOL)respondsToSelector:(SEL)aSelector
{
	if (![super respondsToSelector: aSelector])
	{
		NSLog(@"%@", NSStringFromSelector(aSelector));
		return NO;
	}
	return YES;
}
#endif

@end
