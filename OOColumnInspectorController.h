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


#import <Cocoa/Cocoa.h>

@class OOOutlineDocument;

@interface OOColumnInspectorController : NSWindowController
/**
 * The combo box for the column being inspected.
 */
@property (nonatomic, weak) IBOutlet NSComboBox *columnName;
/**
 * Set the document that this inspector refers to.
 */
- (void)setOutlineDocument: (OOOutlineDocument*)anOutlineDocument;
/**
 * Action sent from the combo box when the selected column changes (either by
 * selecting a new column or by renaming the current one).
 */
- (IBAction)columnChanged: (id)sender;
/**
 * Action for the add column button.
 */
- (IBAction)addCoulumn: (id)sender;
/**
 * Action for the remove column button.
 *
 * FIXME: Currently does nothing.
 */
- (IBAction)removeCoulumn: (id)sender;
/**
 * Query whether the current column has a formatter.  Bound to the formatter
 * text field to disable it when there is no format for the current column.
 */
- (BOOL)hasFormatter;
/**
 * Values for the current enumeration.
 */
- (NSMutableArray*)enumerationValues;
@end
