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

#import "OOUNIXDateFormatter.h"
#include <vector>

@implementation OOUNIXDateFormatter
@synthesize format;
- (NSDate*)dateFromString: (NSString*)aString
{
	struct tm time = { 0 };
	strptime([aString UTF8String], [format UTF8String], &time);
	auto interval = mktime(&time);
	return [NSDate dateWithTimeIntervalSince1970: interval];
}
- (NSString*)stringForObjectValue: (id)anObject
{
	if (anObject == nil)
	{
		return nil;
	}
	if ([anObject isKindOfClass: [NSString class]])
	{
		return anObject;
	}
	if (![anObject isKindOfClass: [NSDate class]])
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"Unexpected class: %@", [anObject class]];
	}
	return [self stringFromDate: anObject];
}
- (BOOL)getObjectValue: (out id  _Nullable*)obj
             forString: (NSString*)string
      errorDescription: (out NSString*_Nullable*)error
{
	*obj = [self dateFromString: string];
	return YES;
}
- (NSString*)stringFromDate: (NSDate*)aDate
{
	struct tm time;
	std::vector<char> buf;
	buf.reserve(128);

	time_t interval = (time_t)[aDate timeIntervalSince1970];
	time = *localtime(&interval);
	// Keep doubling the buffer until it works.
	while (strftime(buf.data(), buf.capacity(), [format UTF8String], &time) == 0)
	{
		buf.reserve(buf.capacity()*2);
	}
	return [NSString stringWithCString: buf.data() encoding: NSUTF8StringEncoding];

}
@end
