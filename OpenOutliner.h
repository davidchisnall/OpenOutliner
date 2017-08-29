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

#ifndef OpenOutliner_h
#define OpenOutliner_h

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "NSData+GZIP.h"
#import "NSColor+OO3.h"
#import "NSAttributedString+OO3.h"
#import "NSString+MissingCasts.h"
#import "NSXMLElement+OO.h"
#import "OOColumnInspectorController.h"
#import "OOOutlineColumn.h"
#import "OOOutlineDataSource.h"
#import "OOOutlineDocument.h"
#import "OOOutlineRow.h"
#import "OOOutlineRow+Pasteboard.h"
#import "OOOutlineTableRowView.h"
#import "OOOutlineValue.h"
#import "OOOutlineView.h"
#import "OOOutlineWindowController.h"
#import "OOUNIXDateFormatter.h"
#import "OOStyleRegistry.h"
#import "OpenOutliner.h"
#import "objcxx_helpers.h"

#ifndef _
#define _(x, ...) [NSString localizedStringWithFormat: x, ## __VA_ARGS__]
#endif

/**
 * Pasteboard type for outline rows within the current document.  This is used
 * for internal drag operations.  The pasteboard stores the (string) identifiers
 * of the rows, within the current document.
 */
extern NSString *OOOUtlineRowsPasteboardType;
/**
 * Pasteboard type for outline rows between documents, or with copy and paste
 * (where the original may not exist at paste time).  The pasteboard stores the
 * (string) OmniOutliner 3 XML representation.
 */
extern NSString *OOOUtlineXMLPasteboardType;

/**
 * Macro for defining an abstract method.  Throws an exception if invoked.
 */
#define OO_ABSTRACT_METHOD()                                  \
	do {                                                      \
	[NSException raise: NSInvalidArgumentException            \
				format: @"Abstract method [%@ %@]",           \
						[self class],                         \
                        NSStringFromSelector(_cmd)];          \
	return nil;                                               \
    } while (0)

/**
 * Macro for performing superclass initialisation.
 */
#define OO_SUPER_INIT()                                        \
	do {                                                       \
		if (!(self = [super init]))                            \
		{                                                      \
			return nil;                                        \
		}                                                      \
	} while (0)

/**
 * Macro for values that can be __unsafe_unreatained in production.  These are
 * turned into zeroing weak references for debug builds, to help debugging.
 */
#ifdef NDEBUG
#define DEBUG_WEAK __unsafe_unreatained
#define DEBUG_WEAK_PROPERTY unsafe_unreatained
#else
#define DEBUG_WEAK __weak
#define DEBUG_WEAK_PROPERTY weak
#endif

/**
 * Returns a unique identifier string.
 *
 * FIXME: This should probably simply generate a UUID, once I've checked that
 * longer strings don't break OmniOutliner.
 */
static inline NSString *identifierString()
{
	// Generate an 11-character alphanumeric string
	auto *str = [NSMutableString new];
	auto *set = [NSCharacterSet alphanumericCharacterSet];
	// Note: THis is not guaranteed to terminate, but it will do quickly if the
	// random number generator has a moderately good distribution.
	while ([str length] < 11)
	{
		unichar candidate = (unichar)arc4random_uniform('z' - '0') + '0';
		if (![set characterIsMember: candidate])
		{
			continue;
		}
		[str appendFormat: @"%c", candidate];
	}
	return [str copy];
}

#endif /* OpenOutliner_h */
