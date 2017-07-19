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

#import <Foundation/Foundation.h>

@class OOOutlineValue;
@class OOOutlineDocument;

/**
 * The state of the checkbox associated with this row.
 */
typedef enum
{
	/**
	 * Indeterminate state, typically indicating that some child nodes are
	 * checked and some unchecked.
	 */
	OOOutlineRowCheckedIndeterminate = 0,
	/**
	 * The row is checked.
	 */
	OOOutlineRowChecked,
	/**
	 * The row is unchecked
	 */
	OOOutlineRowUnChecked
} OOOutlineRowCheckedState;

/**
 * Object encapsulating a row in the outline.  This is responsible for managing
 * values for each column and children.
 */
@interface OOOutlineRow : NSObject
/**
 * The children of this row.
 */
@property (nonatomic) NSMutableArray<OOOutlineRow*> *children;
/**
 * The values for this row.  Note that these are never reordered while the
 * document is loaded, even if the columns are moved.
 *
 * FIXME: We should; however, write them out in a different order if the columns
 * are reordered.
 */
@property (nonatomic) NSMutableArray<OOOutlineValue*> *values;
/**
 * The state of the checkbox associated with this row.
 *
 * FIXME: We probably should have an implicit value associated with the row and
 * move the checked state entirely into an `OOOutlineValue`, as we currently
 * don't support checkboxes in columns, but should.
 */
@property (nonatomic) OOOutlineRowCheckedState checkedState;
/**
 * The note associated with this row.
 */
@property (nonatomic) NSMutableAttributedString *note;
/**
 * Flag indicating whether this should be expanded in the outline view.  This is
 * a persistent property that is saved along with the document.
 */
@property (nonatomic) BOOL isExpanded;
/**
 * Flag indicating whether the note is visible in the outline view.  This is
 * a persistent property that is saved along with the document.
 */
@property (nonatomic) BOOL isNoteExpanded;
/**
 * The document that contains this row.
 */
@property (nonatomic, weak, readonly) OOOutlineDocument *document;
/**
 * The unique identifier for this row.
 */
@property (nonatomic) NSString *identifier;
/**
 * Construct a new row in the specified document.  The row will contain empty
 * cells for all of the columns.
 */
- (id)initInDocument: (OOOutlineDocument*)aDoc;
/**
 * Construct a new row from OmniOutliner 3 XML.
 */
- (id)initWithOO3XMLNode: (NSXMLElement*)xml
              inDocument: (OOOutlineDocument*)aDoc;
/**
 * Construct a new row from OmniOutliner 2 property list.
 */
- (id)initWithOO2Plist: (NSDictionary*)aPlist
           notesColumn: (NSUInteger)aColumn
            inDocument: (OOOutlineDocument*)aDoc;
/**
 * Serialise the row in OmniOutliner 3 XML format.
 */
- (NSXMLElement*)oo3xmlValue;
@end
