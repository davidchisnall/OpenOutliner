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
@class OOOutlineView;

/**
 * The controller for the outline view.
 *
 * FIXME: This class has a silly name.
 */
@interface OOOutlineDataSource : NSObject
/**
 * The document for which this object is the controller.
 */
@property (nonatomic, weak) IBOutlet OOOutlineDocument *document;
/**
 * The outline view that displays this outline.
 */
@property (nonatomic, weak) IBOutlet OOOutlineView *view;
/**
 * Add a row.  Invoked by the outline view or a menu in response to a new row UI
 * instruction.
 */
- (IBAction)addRow: (id)sender;
/**
 * Delete selected rows.  Invoked by the outline view or a menu in response to a
 * delete  row UI instruction.
 */
- (IBAction)deleteSelectedRows: (id)sender;
@end
