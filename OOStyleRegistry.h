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
 * Key used for storing a reference to partial styles in the attributes
 * dictionary of an `NSAttributedString`.
 */
extern NSString *OOPartialStyleKey;

/**
 * `OOPartialStyle` defines a set of overrides in a style.  These are managed by
 * the `OOStyleRegistry` and implement differential inheritance for styles.
 * This design is modelled on the OmniOutliner 3 mechanism for handling styles, 
 * where the file describes a default for each attribute and allows these to be 
 * overwritten per column, cell, and so on.
 *
 * This makes it possible to store only the differences to the parent style when
 * saving.  It also makes it possible to recompute styles.  The partial style is
 * stored in the attributes dictionary with `OOPartialStyleKey`.
 */
@interface OOPartialStyle : NSObject
/**
 * The style registry defining this style.
 */
@property (nonatomic) OOStyleRegistry *registry;
/**
 * Serialise this value as OmniOutliner 3 XML.
 */
- (NSXMLElement*)oo3xmlValue;
/**
 * Recompute the style from attributes.  This will ignore any attributes that
 * are the same as the style from which this is derrived.
 */
- (void)recomputeWithAttributes: (NSDictionary*)attributes;
@end

/**
 * The registry for partial styles.  Instances of this are responsible for
 * constructing chains of partial styles.
 */
@interface OOStyleRegistry : NSObject
/**
 * Construct from OmniOutliner 3 XML.
 */
- (instancetype)initWithOO3XML: (NSXMLElement*)xml;
/**
 * Construct a complete set of attributes (suitable for use in an
 * `NSAttributedString` from a partial style and all of the partial styles from
 * which it inherits.
 */
- (NSDictionary*)attributesForStyle: (OOPartialStyle*)styles;
/**
 * Construct a partial style from OmniOutliner 3 XML, which inherits from a
 * specified style.
 */
- (OOPartialStyle*)partialStyleForOO3XML: (NSXMLElement*)xml
                            inheritsFrom: (OOPartialStyle*)aPartialStyle;
/**
 * Construct a partial style from a set of attributes (such as those in an
 * `NSAttributedString`), inheriting from another partial style.  Any style
 * attributes from the dictionary that are unchanged from the parent will be
 * assumed to be inherited.
 */
- (OOPartialStyle*)partialStyleFromAttributes: (NSDictionary*)aDictionary
                                 inheritsFrom: (OOPartialStyle*)aPartialStyle;
/**
 * Serialise as OmniOutliner 3 XML.
 */
- (NSXMLElement*)oo3xmlValue;
@end
