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

@class OOPartialStyle;

/**
 * Extensions to `NSAttributedString` for transforming to and from OmniOutliner
 * 3's XML representation.  This format stores text in `<text>` elements, which
 * contain one or more paragraphs in `p` elements.  Text in a paragraph is then
 * encoded in `<run>`s, which contain an optional `<style>` followed by a
 * `<lit>` element containing cdata.  The pair of style and lit correspond
 * directly to a run of text and its corresponding attributes, with the
 * exception that some style elements may be inherited (e.g. from row or column
 * default styles).  The inherited style elements are stored in fully expanded
 * form in the attributed string, but when constructing XML any that are not
 * present in the provided partial style are ignored.
 */
@interface NSAttributedString (sOO3)
/**
 * Construct a new attributed string by parsing a fragment in OmniOutliner 3 XML
 * format.
 */
+ (instancetype)attributedStringWithOO3XML: (NSXMLElement*)xml
                          withPartialStyle: (OOPartialStyle*)aPartialStyle;
/**
 * Provide an OmniOutliner 3 XML representation of this attributed string.
 * Style elements present in `aPartialStyle` are not emitted as XML.
 */
- (NSXMLElement*)oo3xmlValueWithPartialStyle: (OOPartialStyle*)aPartialStyle;
@end
