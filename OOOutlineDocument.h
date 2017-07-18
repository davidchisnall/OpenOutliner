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

@class OOOutlineColumn;
@class OOOutlineRow;
@class OOStyleRegistry;

/**
 * An outline document
 */
@interface OOOutlineDocument : NSDocument
/**
 * A virtual root row.  This is not rendered and exists to provide a uniform
 * interface for all rows.
 */
@property (nonatomic, readonly) OOOutlineRow *root;
/**
 * The number of columns in the document.
 */
@property (nonatomic, readonly) NSUInteger columnCount;
/**
 * The columns in this document.
 *
 * FIXME: This returns a mutable array, but currently modifying it will break
 * all of the things.
 */
@property (nonatomic, readonly) NSMutableArray<OOOutlineColumn*> *columns;
/**
 * The notes column, providing properties that should be applied to all notes.
 */
@property (nonatomic, readonly) OOOutlineColumn *noteColumn;
/**
 * The style registry, which manages styles applied at different levels in the
 * document.
 */
@property (nonatomic, readonly) OOStyleRegistry *styleRegistry;
/**
 * The style that should be applied to column titles.
 */
@property (nonatomic, readonly) OOPartialStyle *titleStyle;
/**
 * The width of the window, in points.
 */
@property (nonatomic) CGFloat windowWidth;
/**
 * The height of the window, in points.
 */
@property (nonatomic) CGFloat windowHeight;
/**
 * Map from unique identifiers to outline rows.  This contains all of the rows
 * in the document in a strong-to-weak map (so deleting a row will implicitly
 * remove it from this list).
 */
@property (nonatomic, readonly) NSMapTable *allRows;
/**
 * Global array of all documents currently open.  This exists to make it
 * possible to materialise items across documents.
 */
+ (NSArray<OOOutlineDocument*>*)allDocuments;
/**
 * Find the parent for a specified row.
 */
- (OOOutlineRow*)parentForRow: (OOOutlineRow*)aRow;
@end
