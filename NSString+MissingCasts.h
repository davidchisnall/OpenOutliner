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
 * Adds missing casts to `NSString`.  Foundation's `NSString` class does not
 * provide -{type}Value methods for unsigned values.  These are primarily used
 * in conjunction with C++ templates that match a method to the corresponding
 * type.
 */
@interface NSString (MissingCasts)
/**
 * Return the string as an `unsigned long`.
 */
- (unsigned long)unsignedLongValue;
/**
 * Return the string as an `unsigned long long`.
 */
- (unsigned long long)unsignedLongLongValue;
/**
 * Return the string as an `unsigned int`.
 */
- (unsigned int)unsignedIntValue;
/**
 * Return the string as an `NSUInteger`.
 */
- (NSUInteger)unsignedIntegerValue;
/**
 * Return the string as a string.
 */
- (NSString*)stringValue;
@end

@interface NSAttributedString (MissingCasts)
/**
 * Return the attributed string as a string.
 */
- (NSString*)stringValue;
@end
