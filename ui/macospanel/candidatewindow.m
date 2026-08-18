/* -*- mode: ObjC; c-basic-offset: 4; indent-tabs-mode: nil; -*- */
/* vim:set et sts=4: */
/* ibus - The Input Bus
 * Copyright (C) 2020-2026 Weixuan XIAO <veyx.shaw@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA.
 */

#import "candidatewindow.h"

#import <Cocoa/Cocoa.h>

static MacOSCandidateClickedFunc _click_cb = NULL;
static gpointer _click_data = NULL;
static gint _cursor_x = 0;
static gint _cursor_y = 0;
static gint _cursor_w = 0;
static gint _cursor_h = 0;

@interface CandidateView : NSView
@property (nonatomic, copy) NSAttributedString *string;
@property (nonatomic, strong) NSColor *bgColor;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, strong) NSMutableArray<NSValue *> *candidateFrames;
@property (nonatomic, assign) guint pageStart;
- (void)setAttributedString:(NSAttributedString *)str;
@end

@implementation CandidateView

- (void)setAttributedString:(NSAttributedString *)str
{
    self.string = str;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
    NSBezierPath *path;
    NSPoint origin;
    NSSize size;

    [[NSColor clearColor] set];
    NSRectFill ([self bounds]);

    if (self.string == nil)
        return;

    path = [NSBezierPath bezierPathWithRoundedRect:rect
                                           xRadius:self.radius
                                           yRadius:self.radius];
    [(self.bgColor ?: [NSColor colorWithCalibratedWhite:0.12 alpha:0.92]) set];
    [path fill];

    size = [self.string size];
    origin.x = rect.origin.x + 8;
    origin.y = rect.origin.y + (rect.size.height - size.height) / 2;
    [self.string drawAtPoint:origin];
}

- (void)mouseDown:(NSEvent *)event
{
    NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
    guint i;

    if (_click_cb == NULL || self.candidateFrames == nil)
        return;

    for (i = 0; i < [self.candidateFrames count]; i++) {
        NSRect frame = [[self.candidateFrames objectAtIndex:i] rectValue];
        if (NSPointInRect (point, frame)) {
            _click_cb (self.pageStart + i, _click_data);
            return;
        }
    }
}

@end

@interface CandidateWindowController : NSObject
@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) CandidateView *view;
@property (nonatomic, strong) NSMutableDictionary *attrs;
@property (nonatomic, strong) NSFont *font;
@property (nonatomic, strong) NSColor *fgColor;
@property (nonatomic, strong) NSColor *hlColor;
@property (nonatomic, copy) NSString *preedit;
@property (nonatomic, copy) NSString *auxiliary;
- (void)relayout;
@end

static CandidateWindowController *_controller = nil;

@implementation CandidateWindowController

- (id)init
{
    self = [super init];
    if (self) {
        NSRect frame = NSMakeRect (0, 0, 200, 40);
        self.font = [NSFont systemFontOfSize:16];
        self.fgColor = [NSColor whiteColor];
        self.hlColor = [NSColor colorWithCalibratedRed:0.45 green:0.75 blue:1.0 alpha:1.0];
        self.attrs = [NSMutableDictionary dictionary];
        [self.attrs setObject:self.fgColor forKey:NSForegroundColorAttributeName];
        [self.attrs setObject:self.font forKey:NSFontAttributeName];

        self.window = [[NSWindow alloc] initWithContentRect:frame
                                                  styleMask:NSWindowStyleMaskBorderless
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
        [self.window setAlphaValue:1.0];
        [self.window setLevel:NSFloatingWindowLevel];
        [self.window setHasShadow:YES];
        [self.window setOpaque:NO];
        [self.window setBackgroundColor:[NSColor clearColor]];
        [self.window setIgnoresMouseEvents:NO];
        [self.window setCollectionBehavior:
            NSWindowCollectionBehaviorCanJoinAllSpaces |
            NSWindowCollectionBehaviorStationary |
            NSWindowCollectionBehaviorIgnoresCycle];

        self.view = [[CandidateView alloc] initWithFrame:[[self.window contentView] frame]];
        self.view.radius = 6.0;
        [self.window setContentView:self.view];
    }
    return self;
}

- (NSPoint)cocoaPointForIBus
{
    NSRect screen = [[NSScreen mainScreen] frame];
    /* IBus cursor location uses a top-left origin. */
    CGFloat x = (CGFloat) _cursor_x;
    CGFloat y = screen.size.height - (CGFloat) (_cursor_y + _cursor_h);
    return NSMakePoint (x, y - 4);
}

- (void)relayout
{
    NSSize size;
    NSRect winRect;
    NSPoint origin;
    NSAttributedString *current = self.view.string;

    if (current == nil) {
        [self.window orderOut:nil];
        return;
    }

    size = [current size];
    origin = [self cocoaPointForIBus];
    winRect = NSMakeRect (origin.x, origin.y - (size.height + 16),
                          size.width + 16, size.height + 12);
    [self.window setFrame:winRect display:YES animate:NO];
    [self.window orderFront:nil];
}

@end

void
macos_candidate_window_init (void)
{
    if (_controller == nil)
        _controller = [[CandidateWindowController alloc] init];
}

void
macos_candidate_window_set_click_cb (MacOSCandidateClickedFunc func,
                                     gpointer                  user_data)
{
    _click_cb = func;
    _click_data = user_data;
}

void
macos_candidate_window_set_cursor_location (gint x,
                                            gint y,
                                            gint w,
                                            gint h)
{
    _cursor_x = x;
    _cursor_y = y;
    _cursor_w = w;
    _cursor_h = h;
    if (_controller != nil)
        [_controller relayout];
}

void
macos_candidate_window_update_preedit (IBusText *text,
                                       guint     cursor_pos,
                                       gboolean  visible)
{
    macos_candidate_window_init ();
    if (!visible || text == NULL || text->text == NULL)
        _controller.preedit = nil;
    else
        _controller.preedit = [NSString stringWithUTF8String:text->text];
}

void
macos_candidate_window_update_auxiliary (IBusText *text,
                                         gboolean  visible)
{
    macos_candidate_window_init ();
    if (!visible || text == NULL || text->text == NULL)
        _controller.auxiliary = nil;
    else
        _controller.auxiliary = [NSString stringWithUTF8String:text->text];
}

void
macos_candidate_window_update_lookup_table (IBusLookupTable *table,
                                            gboolean         visible)
{
    guint i;
    guint n;
    guint page_size;
    guint cursor;
    guint page_start;
    guint page_end;
    NSMutableAttributedString *string;
    NSMutableArray<NSValue *> *frames;
    CGFloat x_offset = 8;

    macos_candidate_window_init ();

    if (!visible || table == NULL) {
        macos_candidate_window_hide ();
        return;
    }

    n = ibus_lookup_table_get_number_of_candidates (table);
    page_size = ibus_lookup_table_get_page_size (table);
    cursor = ibus_lookup_table_get_cursor_pos (table);
    if (page_size == 0)
        page_size = n > 0 ? n : 1;
    page_start = (cursor / page_size) * page_size;
    page_end = MIN (page_start + page_size, n);

    if (page_end <= page_start) {
        macos_candidate_window_hide ();
        return;
    }

    string = [[NSMutableAttributedString alloc] init];
    frames = [NSMutableArray array];

    if (_controller.preedit != nil) {
        NSString *prefix = [NSString stringWithFormat:@"%@  ", _controller.preedit];
        NSAttributedString *astr =
            [[NSAttributedString alloc] initWithString:prefix
                                            attributes:_controller.attrs];
        [string appendAttributedString:astr];
        x_offset += [astr size].width;
    }
    if (_controller.auxiliary != nil) {
        NSString *prefix = [NSString stringWithFormat:@"%@  ", _controller.auxiliary];
        NSAttributedString *astr =
            [[NSAttributedString alloc] initWithString:prefix
                                            attributes:_controller.attrs];
        [string appendAttributedString:astr];
        x_offset += [astr size].width;
    }

    for (i = page_start; i < page_end; i++) {
        IBusText *cand = ibus_lookup_table_get_candidate (table, i);
        const gchar *cand_text = (cand && cand->text) ? cand->text : "";
        NSString *str = [NSString stringWithFormat:@"%u.%s ",
                                  (unsigned) (i - page_start + 1), cand_text];
        NSAttributedString *astr =
            [[NSAttributedString alloc] initWithString:str
                                            attributes:_controller.attrs];
        NSRange range = NSMakeRange ([string length], [str length]);
        [string appendAttributedString:astr];
        if (i == cursor) {
            [string addAttribute:NSForegroundColorAttributeName
                           value:_controller.hlColor
                           range:range];
        }
        {
            NSSize size = [astr size];
            NSRect frame = NSMakeRect (x_offset, 0, size.width, size.height + 12);
            [frames addObject:[NSValue valueWithRect:frame]];
            x_offset += size.width;
        }
    }

    _controller.view.candidateFrames = frames;
    _controller.view.pageStart = page_start;
    [_controller.view setAttributedString:string];
    [_controller relayout];
}

void
macos_candidate_window_hide (void)
{
    if (_controller == nil)
        return;
    [_controller.view setAttributedString:nil];
    _controller.view.candidateFrames = nil;
    [_controller.window orderOut:nil];
}
