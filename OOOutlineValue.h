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

@class OOOutlineColumn;

/**
 * Class cluster for values stored in outline cells (row / column
 * intersections).
 */
@interface OOOutlineValue : NSObject
/**
 * Construct a value from OmniOutliner 3 XML format in the specified column.
 */
+ (instancetype)outlineValueWithOO3XML: (NSXMLElement*)xml
                              inColumn: (OOOutlineColumn*)aCol;
/**
 * Returns a placeholder value.
 */
+ (instancetype)placeholder;
/**
 * Serialise as OmniOutliner 3 XML.
 */
- (NSXMLElement*)oo3xmlValue;
/**
 * Return the value that this object contains.  The type of this value depends
 * on the type of the column.
 */
- (id)value;
/**
 * Construct a new value with the specified object in a given column.  When
 * called on a placeholder value, this will construct a new value whose type
 * corresponds to the column type.
 */
- (instancetype)initWithValue: (id)aValue
                     inColumn: (OOOutlineColumn*)aCol;
@end
