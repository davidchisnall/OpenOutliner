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

/**
 * Helper methods for `NSXMLElement` to make constructing and accessing elements
 * easier.
 */
@interface NSXMLElement (OO)
/**
 * Returns either `nil` or the single child element with the specified name.
 * Throws an `NSInvalidArgumentException` exception if more than one child
 * element exists with the specified name.
 */
- (NSXMLElement*_Nullable)elementForName: (nonnull NSString*)aName;
/**
 * Constructs an element with the specified name and the provided attribute
 * dictionary.
 */
+ (instancetype _Nullable)elementWithName: (nonnull NSString*)aName
                     attributesDictionary: (nonnull NSDictionary*)attrs;
/**
 * Adds a single attribute with the corresponding name.
 */
- (nonnull instancetype)addAttribute: (nonnull NSString*)anAttr
                            withName: (nonnull NSString*)aName;
@end
