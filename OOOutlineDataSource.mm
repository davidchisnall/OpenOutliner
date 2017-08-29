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

} // Anon namespace

@implementation OOOutlineDataSource
{
	/**
	 * Weak to strong map of items to row views.  Lets us access the row view
	 * without having to query the outline view, which could end up with 
	 * infinite recursion.
	 */
	NSMapTable *rowViews;
	/**
	 * Lazily created window controller for the column inspector.
	 */
	OOColumnInspectorController *columnInspector;
}
@synthesize
	document,
	view;

- (void)awakeFromNib
{
	rowViews = [NSMapTable weakToStrongObjectsMapTable];
	OOOutlineDocument *doc = document;
	NSOutlineView *v = view;
	[v setAllowsColumnSelection: YES];
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
	[[NSNotificationCenter defaultCenter] addObserver: self
	                                         selector: @selector(columnsDidChange:)
	                                             name: OOOutlineColumnsDidChangeNotification
	                                           object: doc];
}
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}
- (void)columnsDidChange: (NSNotification*)aNotification
{
	auto *cols = [document columns];
	OOOutlineDocument *doc = document;
	targets.clear();
	NSOutlineView *v = view;
	auto *c = [cols objectAtIndex: 0];
	auto *tc = [v outlineTableColumn];
	[tc setMinWidth: c.minWidth];
	[tc setMaxWidth: c.maxWidth];
	[tc setTitle: [c.title string]];
	[tc setWidth: c.width];
	[tc setIdentifier: @"0"];
	NSUInteger removeIdx = 0;
	while ([v numberOfColumns] > 1)
	{
		auto *col = [[v tableColumns] objectAtIndex: removeIdx];
		if (col == tc)
		{
			removeIdx++;
			continue;
		}
		[v removeTableColumn: col];
	}
	targets.push_back([NSMapTable weakToStrongObjectsMapTable]);
	targets.push_back([NSMapTable weakToStrongObjectsMapTable]);
	for (NSUInteger i = 1 ; i<[doc columnCount] ; i++)
	{
		targets.push_back([NSMapTable weakToStrongObjectsMapTable]);
		c = [cols objectAtIndex: i];
		tc = [[NSTableColumn alloc] initWithIdentifier: [NSString stringWithFormat: @"%d", (int)i]];
		[tc setMinWidth: c.minWidth];
		[tc setMaxWidth: c.maxWidth];
		[tc setTitle: [c.title string]];
		[v addTableColumn: tc];
		// Adding the column to the table will reset its width to minWidth, so we must set its width afterwards.
		[tc setWidth: c.width];
	}
	[v reloadItem: nil reloadChildren: YES];
}
- (id)outlineView: (NSOutlineView*)outlineView
            child: (NSInteger)index
           ofItem: (OOOutlineRow*)item
{
	if (item == nil)
	{
		item  = document.root;
	}
	return [item.children objectAtIndex: (NSUInteger)index];
}
- (BOOL)outlineView: (NSOutlineView*)outlineView
   isItemExpandable: item
{
	return [self outlineView: outlineView numberOfChildrenOfItem: item] > 0;
}
- (NSInteger)outlineView: (NSOutlineView*)outlineView
  numberOfChildrenOfItem: (OOOutlineRow*)item
{
	if (item == nil)
	{
		item  = document.root;
	}
	return (NSInteger)[item.children count];
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
	auto *modelColumn = [doc.columns objectAtIndex: (NSUInteger)idx];
	auto applyStyle = [&](auto *v) {
		v.formatter = modelColumn.formatter;
		v.drawsBackground = NO;
		v.allowsEditingTextAttributes = YES;
		v.editable = YES;
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
		return v;
	}
	auto *v = [NSTextField new];
	v.bordered = NO;
	applyStyle(v);
	return v;
}
- (NSTableRowView*)outlineView: (NSOutlineView*)outlineView
                rowViewForItem: (id)anItem
{
	OOOutlineTableRowView *v = [rowViews objectForKey: anItem];
	if (v == nil)
	{
		v = [OOOutlineTableRowView new];
		[v setOutlineView: view];
		[v setRow: anItem];
		[rowViews setObject: v forKey: anItem];
	}
	return v;
}


- (CGFloat)outlineView: (NSOutlineView*)outlineView
     heightOfRowByItem: (OOOutlineRow*)aRow
{
	if ([aRow note] != nil)
	{
		return 43;
	}
	return 23;
}

- (BOOL)outlineView: (NSOutlineView*)outlineView
         acceptDrop: (id<NSDraggingInfo>)info
               item: (OOOutlineRow*)item
         childIndex: (NSInteger)index
{
	auto *doc = document;
	auto *v = view;
	NSArray<OOOutlineRow*> *rows = [[info draggingPasteboard] readObjectsForClasses: @[ [OOOutlineRow class] ] options: nil];
	auto *insertIndexes = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange((NSUInteger)index,  [rows count])];
	object_map<OOOutlineRow*, NSMutableIndexSet*> removals;
	collectRowsToRemove(doc, rows, removals);
	scoped_undo_grouping undo([doc undoManager], @"move rows");
	// Register the reload first, so that it will be invoked after undoing all
	// of the changes.
	[undo.record(v) reloadItem: nil reloadChildren: YES];
	[item.children insertObjects: rows atIndexes: insertIndexes];
	[undo.record(item.children) removeObjectsAtIndexes: insertIndexes];
	for (auto &[ row, indexes] : removals)
	{
		if (row == item)
		{
			[indexes shiftIndexesStartingAtIndex: (NSUInteger)index
			                                  by: (NSInteger)[rows count]];
		}
		auto *toRemove = [row.children objectsAtIndexes: indexes];
		[undo.record(row.children) insertObjects: toRemove
		                               atIndexes: indexes];
		[row.children removeObjectsAtIndexes: indexes];
	}
	[v reloadItem: nil reloadChildren: YES];
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
	OOOutlineRow *parent = row;
	if (row == doc.root)
	{
		parent = nil;
	}
	auto *children = row.children;
	NSUInteger idx = selected ? [children indexOfObject: selected] + 1 : 0;
	auto *newRow = [[OOOutlineRow alloc] initInDocument: doc];
	scoped_undo_grouping undo([doc undoManager], @"insert row");
	[undo.record(v) reloadItem: parent reloadChildren: YES];
	[undo.record(children) removeObjectAtIndex: idx];
	[children insertObject: newRow atIndex: idx];
	[v reloadItem: parent reloadChildren: YES];
	[v selectRowIndexes: [NSIndexSet indexSetWithIndex: (NSUInteger)[v rowForItem: newRow]] byExtendingSelection: NO];
}
- (NSArray<OOOutlineRow*>*)selectedRows
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
	return rows;
}
- (IBAction)deleteSelectedRows:(id)sender
{
	auto *rows = [self selectedRows];
	auto *doc = document;
	auto *v = view;
	object_map<OOOutlineRow*, NSMutableIndexSet*> removals;
	collectRowsToRemove(doc, rows, removals);
	scoped_undo_grouping undo([doc undoManager], @"delete rows");
	// Register the reload first, so that it will be invoked after undoing all
	// of the changes.
	[undo.record(v) reloadItem: nil reloadChildren: YES];
	for (auto &[row, indexes] : removals)
	{
		auto *toRemove = [row.children objectsAtIndexes: indexes];
		[undo.record(row.children) insertObjects: toRemove
		                               atIndexes: indexes];
		[row.children removeObjectsAtIndexes: indexes];
	}
	[v reloadItem: nil reloadChildren: YES];

}
- (NSSet<OOOutlineRow*>*)selectedRowsExcludingChildren
{
	auto *rows = [self selectedRows];
	auto *rowSet = [NSMutableSet setWithArray: rows];
	auto *doc = document;
	// Filter out any rows that have a parent in the selection.
	// These will be moved as a result of moving their parents.
	for (OOOutlineRow *row : rows)
	{
		OOOutlineRow *parent = row;
		while ((parent = [doc parentForRow: parent]))
		{
			if ([rowSet containsObject: parent])
			{
				[rowSet removeObject: row];
				break;
			}
		}
	}
	return rowSet;
}

- (IBAction)increaseIndentLevel: (id)sender
{
	auto *v = view;
	auto *selectedIndexes = [v selectedRowIndexes];
	auto *rows = [self selectedRowsExcludingChildren];
	if ([rows count] == 0)
	{
		return;
	}
	auto *doc = document;
	scoped_undo_grouping undo([doc undoManager], @"indent");
	[undo.record(v) reloadItem: nil reloadChildren: YES];
	std::vector<OOOutlineRow*> rowsToExpand;
	for (OOOutlineRow *row in rows)
	{
		auto *parent = [doc parentForRow: row];
		NSUInteger idx = [parent.children indexOfObject: row];
		// You can't increase the indent level of a node that is already the
		// first child of its parent, because there's no new parent to attach it
		// to without reordering.
		if (idx == 0)
		{
			continue;
		}
		auto *newParent = [parent.children objectAtIndex: idx-1];
		[undo.record(parent.children) insertObject: row atIndex: idx];
		[undo.record(newParent.children) removeObjectAtIndex: [newParent.children count]];
		[newParent.children addObject: row];
		[parent.children removeObjectAtIndex: idx];
		if (!newParent.isExpanded)
		{
			[undo.record(newParent) setIsExpanded: NO];
			[newParent setIsExpanded: YES];
		}
		rowsToExpand.push_back(newParent);
	}
	[v reloadItem: nil reloadChildren: YES];
	for (OOOutlineRow *row in rows)
	{
		[[rowViews objectForKey: row] layout];
	}
	for (auto *r : rowsToExpand)
	{
		[v expandItem: r];
	}
	[v selectRowIndexes: selectedIndexes byExtendingSelection: NO];
}
- (void)runBlock: (void(^)(void))aBlock
{
	aBlock();
}
- (IBAction)decreaseIndentLevel: (id)sender
{
	auto *v = view;
	auto *selectedIndexes = [v selectedRowIndexes];
	auto *rows = [self selectedRowsExcludingChildren];
	if ([rows count] == 0)
	{
		return;
	}
	auto *collapsedRows = [NSMutableArray new];
	auto *doc = document;
	scoped_undo_grouping undo([doc undoManager], @"unindent");
	[undo.record(self) runBlock: ^()
		{
			for (OOOutlineRow *row in collapsedRows)
			{
				[v expandItem: row];
			}
		}];
	[undo.record(v) reloadItem: nil reloadChildren: YES];
	for (OOOutlineRow *row in rows)
	{
		auto *parent = [doc parentForRow: row];
		auto *grandparent = [doc parentForRow: parent];
		if (grandparent == nil)
		{
			continue;
		}
		NSUInteger newIdx = [grandparent.children indexOfObject: parent] +1;
		NSUInteger oldIdx = [parent.children indexOfObject: row];
		[undo.record(parent.children) insertObject: row atIndex: oldIdx];
		[undo.record(grandparent.children) removeObjectAtIndex: newIdx];
		[grandparent.children insertObject: row atIndex: newIdx];
		[parent.children removeObjectAtIndex: oldIdx];
		if ([parent isExpanded] && ([parent.children count] == 0))
		{
			[collapsedRows addObject: parent];
		}
	}
	[v reloadItem: nil reloadChildren: YES];
	for (OOOutlineRow *row in rows)
	{
		[[rowViews objectForKey: row] layout];
	}
	[v selectRowIndexes: selectedIndexes byExtendingSelection: NO];
}
- (IBAction)editNotes: (id)sender
{
	auto *v = view;
	NSInteger selectedRow = [v selectedRow];
	if (selectedRow == -1)
	{
		return;
	}
	OOOutlineRow *row = [v itemAtRow: selectedRow];
	// If this is already a notes row, then don't try to add it.
	if (![row isKindOfClass: [OOOutlineRow class]])
	{
		return;
	}
	if (![row note])
	{
		[row setNote: [NSMutableAttributedString new]];
		[v noteHeightOfRowsWithIndexesChanged: [NSIndexSet indexSetWithIndex: (NSUInteger)selectedRow]];
		[v reloadItem: row reloadChildren: YES];
	}
	[[rowViews objectForKey: row] editNote];
}
- (IBAction)inspectColumns: (id)sender
{
	if (columnInspector == nil)
	{
		columnInspector = [[OOColumnInspectorController alloc] initWithWindowNibName: @"ColumnInspector"];
		[columnInspector setOutlineDocument: document];
	}
	[[columnInspector window] makeKeyAndOrderFront: self];
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
