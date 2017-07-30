OpenOutliner
============

OpenOutliner is a (work-in-progress) outliner application.
It is intended as a replacement for OmniOutliner 3 for people who don't like OmniOutliner 5.

Why does this exist?
--------------------

Back in 2003, I purchased my first Mac, a PowerBook, which came with OmniOutliner 2 and OmniGraffle as bundled applications.
A few years later, I accidentally bought OmniOutliner 3 (I meant to buy a new version of OmniGraffle - a superb diagram package from the same company).
OmniOutliner 3 was a refinement on 2, but included some useful features, such as the ability to display notes as part of the outline, rather than in a separate inspector window.

I used OmniOutliner 3 a lot, including using it to produce outlines of my PhD thesis, my five books (four published, one under way), a lot of papers, my accounts, and so on.
It wasn't perfect, and there were a few features that I wished that it had, for example:

 * The ability to filter documents by arbitrary criteria.
 * The ability to use currencies other than my current locale's for currency columns.
 * The ability to use more complex (user-provided) summary calculations and put summaries at different depths in the outline.

Being closed source, it was also impossible to do a GNUstep port and so I could not run it on FreeBSD.

When I upgraded to macOS Sierra, OmniOutliner 3 stopped working.
Attempting to run it triggered an uncaught exception.
After so many years of use, I would happily have paid for a bug fix, but unfortunately this was not available.
OmniGroup offers a big discount on OmniOutliner 5 for owners of OmniOutliner 3, but unfortunately features that were part of the standard version of OmniOutliner 3 are now part of the Pro version and overall OmniOutliner 5 is significantly less appropriate for my uses than OmniOutliner 3.

The file format for OmniOutliner 3 is a bundle containing an XML file and additional files for any attachments.
OmniOutliner 5 uses a single file designed for 'better integration with third-party cloud services'.
Unfortunately, this makes it far less useful with revision control systems.

This trend to make OmniOutliner more appealing to hipsters has made it less useful to me.
I wish OmniGroup well in their development of OmniOutliner 3 and I suspect that they will find no shortage of hipsters willing to be parted from their money.
In the meantime, I would like a functional outliner, and so have written one.

OmniOutliner compatibility
--------------------------

OpenOutliner currently uses the OmniOutliner 3 file format directly, with some small modifications:

 * The XML is stored uncompressed.  This results in a trivial increase in disk usage, but means that diff tools work correctly.  OmniOutliner has no problems opening bundles with uncompressed XML.
 * The XML file is pretty printed.  This means that line diffs in git and other revision control systems are meaningful.  This works with OmniOutliner with the exception of links, which gain a new line before and after.  I consider this a small penalty, but will add a strict compatibility option in the future that makes this configurable.

The OmniOutliner 3 file format is mostly very sensible and I have few reasons to wish to change it.
Unfortunately, the way in which it stores dates is somewhat braindead, as they are stored with a fixed encoding and lack a display time zone, which results in ambiguities that can cause some very interesting artefacts with dates that don't include a time in the UI (they are encoded as dates with times set to midnight, so moving one time zone can result in the day changing).
I intend to switch to using a format that preserves this information better in the near future.

Current status
--------------

OpenOutliner can currently open and save all of my OmniOutliner 3 files and can open all of my OmniOutliner 2 files (which OmniOutliner 5 cannot).
There are some significant limitations that prevent it from being generally usable.
The rough status so far is:

 - [x] OmniOutliner 3 files can be opened and saved with no data loss (other than printing preferences).
 - [x] OmniOutliner 2 files can be opened.  I have no plans to support saving in this format, as nothing else appears to be able to open it.
 - [x] Support for all cell types supported by OmniOutliner 3:
   - [x] Rich text
   - [x] Dates
   - [x] Numbers (including currency)
   - [x] Enumerations
   - [x] Checkboxes
 - [ ] Basic Outliner functionality:
   - [x] Creating new documents
   - [x] Editing cells
   - [x] Creating new rows
   - [x] Deleting rows
   - [x] Drag and drop within a document
   - [x] Indenting and unindenting rows
   - [ ] Drag and drop between documents and to external editors
   - [ ] Embedding images / other media in the document
   - [ ] Column editing:
     - [X] Adding columns
     - [ ] Removing columns
     - [ ] Reordering columns
     - [-] Changing column properties (type, style, and so on)
 - [ ] Exporting
   - [ ] LaTeX
   - [ ] Plain text
   - [ ] Rich text
   - [ ] HTML
   - [ ] OPML (does anyone care about this?)
 - [ ] Printing (PDF export)
 - [ ] Non-ugly UI
 - [ ] Filtered views on outlines
 - [ ] Custom and per-outline-level summaries

See the issue tracker for a more complete list of known limitations.

If you have OmniOutliner 3 files for which are incorrectly handled, please file a bug report.

