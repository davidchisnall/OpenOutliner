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

#import "OpenOutliner.h"
#import <mutex>

/**
 * Array of all documents, protected by `lock` from concurrent access.
 */
static NSMutableArray<OOOutlineDocument*> *allDocs;
/**
 * Lock that protects `allDocs`.
 */
static std::mutex lock;


@implementation OOOutlineDocument
@synthesize
	allRows,
	columns,
	noteColumn,
	root,
	styleRegistry,
	titleStyle,
	windowHeight,
	windowWidth;

+ (NSArray<OOOutlineDocument*>*)allDocuments
{
	std::lock_guard<std::mutex> g(lock);
	return [allDocs copy];
}

+ (void)initialize
{
	if (allDocs == nil)
	{
		allDocs = [NSMutableArray new];
	}
}

- (void)dealloc
{
	std::lock_guard<std::mutex> g(lock);
	[allDocs removeObject: self];
}

+ (BOOL)autosavesInPlace
{
	// FIXME:
	return NO;
}

- (NSFileWrapper*)fileWrapperOfType: (NSString*)typeName
                              error: (NSError*_Nullable*)outError
{
	// FIXME: Set the error for other file types.
	if ([typeName isEqualToString: @"OmniOutliner3"])
	{
		NSData *contents = [[self oo3xmlValue] XMLDataWithOptions: NSXMLNodePrettyPrint];
		// Note:
		NSFileWrapper *wrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:
			@{
			  @"contents.xml" : [[NSFileWrapper alloc] initRegularFileWithContents: contents]
			 }];
		return wrapper;
	}
	return nil;
}
- (BOOL)parseOO3XMLColumns: (NSXMLElement*)xml
{
	columns = [NSMutableArray new];
	for (NSXMLElement *c in [xml elementsForName: @"column"])
	{
		// FIXME: Handle default styles.
		auto col = [[OOOutlineColumn alloc] initWithOO3XML: c
		                                        inDocument: self];
		if ([col isNoteColumn])
		{
			noteColumn = col;
		}
		else
		{
			[columns addObject: col];
		}
	}
	return YES;
}
- (NSXMLDocument*)oo3xmlValue
{
	NSXMLDocument *doc = [NSXMLDocument document];
	doc.standalone = NO;
	// Not sure why, but this DTD doens't seem to work
	static NSURL *oo3DTDURL = [NSURL URLWithString: @"http://www.omnigroup.com/namespace/OmniOutliner/xmloutline-v3.dtd"];
	doc.DTD = [[NSXMLDTD alloc] initWithContentsOfURL: oo3DTDURL
	                                          options: 0
	                                            error: nullptr];
	doc.DTD = [NSXMLDTD new];
	doc.DTD.publicID = @"-//omnigroup.com//DTD OUTLINE 3.0//EN";
	doc.DTD.systemID = @"http://www.omnigroup.com/namespace/OmniOutliner/xmloutline-v3.dtd";
	[doc.DTD setName: @"outline"];
	auto mkXML = [](NSString *name, NSDictionary *attrs)
		{
			return [NSXMLElement elementWithName: name
							attributesDictionary: attrs];
		};
	auto *outline = mkXML(@"outline",
	                      @{ @"xmlns" : @"http://www.omnigroup.com/namespace/OmniOutliner/v3" });
	[doc addChild: outline];
	// FIXME: Not yet handling:
	// settings
	auto addChildren = [&](NSString *name, auto dict, NSXMLElement *head=nil)
		{
			NSXMLElement *element = [NSXMLElement elementWithName: name];
			if (head)
			{
				[element addChild: head];
			}
			for (id val in dict)
			{
				[element addChild: [val oo3xmlValue]];
			}
			[outline addChild: element];
			return element;
		};

	auto *editor = mkXML(@"editor",
	                     @{ @"content-size" : NSStringFromRange({ (NSUInteger)windowWidth,
	                                                              (NSUInteger)windowHeight }) });
	[outline addChild: [styleRegistry oo3xmlValue]];
	[outline addChild: editor];
	addChildren(@"columns", columns, [noteColumn oo3xmlValue]);
	addChildren(@"root", root.children);

	NSError *e;
	[doc validateAndReturnError: &e];
	NSLog(@"Error: %@", e);
	return doc;
}
- (BOOL)readFromFileWrapper: (NSFileWrapper*)fileWrapper
                     ofType: (NSString*)typeName
                      error: (NSError*_Nullable __autoreleasing*)outError
{
	NSError *e;
	auto error = [&]()
		{
			if (!e)
			{
				return false;
			}
			if (outError)
			{
				*outError = e;
			}
			NSLog(@"Error: %@", e);
			//[NSApp presentError: e];
			return true;
		};

	NSLog(@"File type: %@", typeName);
	if ([typeName isEqualToString: @"OmniOutliner3"] &&
	    [fileWrapper isDirectory])
	{
		NSFileWrapper *contents = [fileWrapper.fileWrappers objectForKey: @"contents.xml"];
		if (!contents)
		{
			return NO;
		}
		NSData *fileData = [contents regularFileContents];
		if ([fileData isGzippedData])
		{
			fileData = [fileData gunzippedData];
		}
		NSXMLDocument *xml = [[NSXMLDocument alloc] initWithData: fileData options: 0 error:&e];
		if (error()) { return NO; }
#if 0
		NSData *dtdFile = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"xmloutline-v3" ofType: @"dtd"]];
		auto *dtd = [[NSXMLDTD alloc] initWithData: dtdFile options: 0 error: &e];
		if (error()) { return NO; }
		// This always reports no DTD found, yet [xml DTD] reports a DTD.
		[xml setDTD: dtd];
		[xml validateAndReturnError: &e];
		if (error()) { return NO; }
#endif
		allRows = [NSMapTable strongToWeakObjectsMapTable];
		auto *docRoot = [xml rootElement];
		auto *rowRoot = [docRoot elementForName: @"root"];
		styleRegistry = [[OOStyleRegistry alloc] initWithOO3XML: [docRoot elementForName: @"style-attribute-registry"]];
		if (auto *s = [rowRoot elementForName: @"style"])
		{
			titleStyle = [styleRegistry partialStyleForOO3XML: s inheritsFrom: nil];
		}
		[self parseOO3XMLColumns: [docRoot elementForName: @"columns"]];
		root = [[OOOutlineRow alloc] initInDocument: self];
		NSXMLElement *editorNode = [docRoot elementForName: @"editor"];
		NSRange r = NSRangeFromString([[editorNode attributeForName: @"content-size"] stringValue]);
		windowWidth = r.location;
		windowHeight = r.length;
		// FIXME: Restore selected row / column
		@try
		{
			for (NSXMLElement *item in [rowRoot elementsForName: @"item"])
			{
				[root.children addObject: [[OOOutlineRow alloc] initWithOO3XMLNode: item
				                                                        inDocument: self]];
			}
		}
		@catch (NSException *e)
		{
			NSLog(@"Exception: %@", e);
			[NSApp reportException: e];
			return NO;
		}
		std::lock_guard<std::mutex> g(lock);
		[allDocs addObject: self];
		return YES;
	}
	if ([typeName isEqualToString: @"OmniOutliner2"] &&
		![fileWrapper isDirectory])
	{
		NSDictionary *docRoot = [NSPropertyListSerialization propertyListWithData: [fileWrapper regularFileContents]
		                                                                  options: NSPropertyListImmutable
		                                                                   format: nullptr
		                                                                    error: &e];
		if (error()) { return NO; }
		allRows = [NSMapTable strongToWeakObjectsMapTable];
		styleRegistry = [[OOStyleRegistry alloc] init];
		// FIXME: Should this be something sensible?
		titleStyle = nil;
		columns = [NSMutableArray new];
		NSUInteger colCount = [[docRoot objectForKey: @"Columns"] count];
		assert(colCount > 0);
		NSUInteger notesIdx = -1ULL;
		for (NSUInteger i=0 ; i<colCount ; i++)
		{
			// FIXME: Handle default styles.
			auto col = [[OOOutlineColumn alloc] initWithOO2Plist: docRoot
			                                         columnIndex: i
			                                          inDocument: self];
			if ([col isNoteColumn])
			{
				noteColumn = col;
				notesIdx = i;
			}
			else
			{
				[columns addObject: col];
			}
		}
		NSDictionary *rootNode = [docRoot objectForKey: @"Root Item"];
		assert(rootNode);
		root = [[OOOutlineRow alloc] initInDocument: self];
		// Window size is not encoded in OO2 files, so just pick some sane(ish) values.
		windowWidth = 400;
		windowHeight = 600;
		@try
		{
				[root.children addObject: [[OOOutlineRow alloc] initWithOO2Plist: rootNode
				                                                     notesColumn: notesIdx
				                                                      inDocument: self]];
		}
		@catch (NSException *e)
		{
			NSLog(@"Exception: %@", e);
			[NSApp reportException: e];
			return NO;
		}
		std::lock_guard<std::mutex> g(lock);
		[allDocs addObject: self];
		return YES;
	}
	return NO;
}
- (NSString*)windowNibName
{
	return @"OutlineDocumentWindow";
}
- (NSUInteger)columnCount
{
	return [columns count];
}
- (id)initWithType: (NSString*)typeName
             error: (NSError*_Nullable __autoreleasing *)outError
{
	OO_SUPER_INIT();
	allRows = [NSMapTable strongToWeakObjectsMapTable];
	styleRegistry = [[OOStyleRegistry alloc] init];
	columns = [NSMutableArray new];
	auto *outlineColumn = [[OOOutlineColumn alloc] initWithType: OOOutlineColumnTypeText
	                                                 inDocument: self];
	outlineColumn.isOutlineColumn = YES;
	[columns addObject: outlineColumn];
	noteColumn = [[OOOutlineColumn alloc] initWithType: OOOutlineColumnTypeText
	                                        inDocument: self];
	noteColumn.isNoteColumn = YES;
	root = [[OOOutlineRow alloc] initInDocument: self];
	windowWidth = 400;
	windowHeight = 600;
	[root.children addObject: [[OOOutlineRow alloc] initInDocument: self]];
	std::lock_guard<std::mutex> g(lock);
	[allDocs addObject: self];
	return self;
}
- (OOOutlineRow*)parentForRow: (OOOutlineRow*)aRow
{
	std::function<OOOutlineRow*(OOOutlineRow*)> recurse;
	recurse = [&](OOOutlineRow *r) -> OOOutlineRow*
		{
			for (OOOutlineRow *c in r.children)
			{
				if (c == aRow)
				{
					return r;
				}
				if (auto *ret = recurse(c))
				{
					return ret;
				}
			}
			return nil;
		};
	return recurse(root);
}
@end
