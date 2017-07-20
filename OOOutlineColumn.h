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

@class OOOutlineRow;
@class OOOutlineValue;
@class OOOutlineDocument;
@class OOStyleRegistry;
@class OOPartialStyle;

/**
 * The type of a column in the outline.
 */
typedef enum
{
	/**
	 * The column contains rich text.
	 *
	 * Data in these columns should be represented as `NSAttributedString`
	 * instances.
	 */
	OOOutlineColumnTypeText,
	/**
	 * The column contains some kind of number, with a specified formatter.
	 * This is also used for currency columns.
	 *
	 * Data in these columns should be represented as `NSDecimalNumber`
	 * instances.
	 */
	OOOutlineColumnTypeNumber,
	/**
	 * The column contains dates.
	 *
	 * Data in these columns should be represented as `NSDate` instances.
	 */
	OOOutlineColumnTypeDate,
	/**
	 * The column contains enumerations.
	 *
	 * Data in these columns should be represented as `NSAttributedString`
	 * instances, but should be checked against the enumerations in the column
	 * using only the string value.
	 */
	OOOutlineColumnTypeEnumeration,
	/**
	 * The column contains a checkbox.
	 *
	 * Data in these columns should be represented as an `NSNumber` 
	 * containing a valid `NSControlStateValue`.
	 */
	OOOutlineColumnTypeCheckBox
} OOOutlineColumnType;

/**
 * Abstract superclass for class that computes summaries of columns.
 *
 * This is used for sum, mean, minimum, maximum, and so on.  Instances of this
 * class are stateless and so can be shared among documents.  All state is
 * maintained in the `-computeSummaryForRow:inColumn:` method.
 */
@interface OOOutlineSummary : NSObject
/**
 * Return a singleton instance of this class.
 */
+ (instancetype)sharedInstance;
/**
 * Constructs an outline value that corresponds to the summary of the children
 * of `aRow` for `aCol`.
 */
- (OOOutlineValue*)computeSummaryForRow: (OOOutlineRow*)aRow
                               inColumn: (NSUInteger)aCol;
@end

/**
 * An outline column.  This class encapsulates all of the data corresponding to
 * the properties of the column, in the same way that `NSTableColumn`
 * describes properties of, but does not contain cells in the column.
 */
@interface OOOutlineColumn : NSObject
/**
 * The title of the column.
 */
@property (nonatomic) NSAttributedString *title;
/**
 * The default style for elements in this column.  This is computed from
 * `style`, applying document-wide properties.
 */
@property (nonatomic, readonly) NSDictionary *defaultStyle;
/**
 * Enumeration values in this column.  This is a map from enumeration id (a
 * unique string identifier for the value) to attributed strings representing
 * the value to display for these identifiers.
 *
 * This property is `nil` for columns of any type other than
 * `OOOutlineColumnTypeEnumeration`.
 */
@property (nonatomic) NSMutableDictionary *enumValues;
/**
 * The kind of data stored in this column.
 */
@property (nonatomic) OOOutlineColumnType columnType;
/**
 * The width of the column, in points.
 */
@property (nonatomic) NSUInteger width;
/**
 * The minimum width of the column, in points.
 */
@property (nonatomic) NSUInteger minWidth;
/**
 * The maximum width of the column, in points.
 */
@property (nonatomic) NSUInteger maxWidth;
/**
 * The formatter that should be applied to data for this column.  This is unused
 * for `OOOutlineColumnTypeText` columns.
 */
@property (nonatomic) NSFormatter *formatter;
/**
 * The object that computes the summary of columns.  This is `nil` if the column
 * does not automatically compute summaries.
 */
@property (nonatomic) OOOutlineSummary *summary;
/**
 * The unique identifier for this column.
 */
@property (nonatomic) NSString *identifier;
/**
 * Identifies whether this is the special column for notes.  Documents contain
 * one notes column, which defines the styling for notes and does not correspond
 * to a column in the outline view.
 */
@property (nonatomic, readonly) BOOL isNoteColumn;
/**
 * Is this the leftmost column, which requires some special handling?
 */
@property (nonatomic, readonly) BOOL isOutlineColumn;
/**
 * The width of this column for text export.  Currently unused.
 *
 * FIXME: This should be updated when text in the column is changed, to provide
 * the maximum width of the column.
 */
@property (nonatomic) NSUInteger textExportWidth;
/**
 * The style properties for this coulmn.
 */
@property (nonatomic, readonly) OOPartialStyle *style;
/**
 * Construct the column from OmniOutliner 3 XML.
 */
- (instancetype)initWithOO3XML: (NSXMLElement*)xml
                    inDocument: (OOOutlineDocument*)aDocument;
/**
 * Construct the column from OmniOutliner 2 property lists.  The first is the
 * entry from the `Columns` dictionary, the second from the `Styles dictionary.
 */
- (instancetype)initWithOO2Plist: (NSDictionary*)aDictionary
                     columnIndex: (NSUInteger)anIndex
                      inDocument: (OOOutlineDocument*)aDocument;

/**
 * Encode the column as OmniOutliner 3 XML.
 */
- (NSXMLElement*)oo3xmlValue;
@end
