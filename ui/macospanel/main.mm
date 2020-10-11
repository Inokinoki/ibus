/* -*- mode: C; c-basic-offset: 4; indent-tabs-mode: nil; -*- */
/* vim:set et sts=4: */
/* ibus - The Input Bus
 * Copyright (C) 2020 Weixuan XIAO <veyx.shaw@gmail.com>
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

#include <ibus.h>

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface CandidateWindow : NSObject {
    NSWindow            *_window;
    NSView              *_view;
    NSMutableDictionary *_attr;

    NSColor             *_fgColor;
    NSColor             *_hlColor;
    NSFont              *_font;
}

-(void)setFont:(NSFont *)font;
-(NSFont*)font;

-(NSColor*)bgColor;
-(void)setBgColor:(NSColor*)color;

-(void)showCandidates:(NSArray*)candiArray around:(NSRect)cursorRect;
-(void)hideCandidates;

-(void)setRadius:(float)radius;

@property (retain, nonatomic) NSColor *fgColor;
@property (retain, nonatomic) NSColor *hlColor;

@end


/******************** App Delegate *********************/
@interface MyAppDelegate : NSObject <NSApplicationDelegate>
{
    CandidateWindow *win;
}
@end

@implementation MyAppDelegate

-(id) init
{
    self = [super init];
    if (self)
    {
        NSMutableArray* candidates = [NSMutableArray array];

        win = [[CandidateWindow alloc] init];

        NSRect cursorRect = NSMakeRect(800, 400, 200, 40);

        for (int i=0; i<3; ++i) {
            NSString *string = @"Test";
            [candidates addObject:string];
        }

        [win showCandidates:candidates around:cursorRect];
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    // make the window visible when the app is about to finish launching //
    [win makeKeyAndOrderFront:self];
    /* do layout and cool stuff here */
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    /* initialize your code stuff here */
}

- (void)dealloc
{
    // release your window and other stuff //
    [win release];
    [super dealloc];
}

@end
/******************** App Delegate *********************/

static IBusBus *_bus = NULL;
static NSApplication *app = NULL;

static void
_bus_disconnected_cb (IBusBus  *bus,
                      gpointer  user_data)
{
    // Close app
    [app terminate: app];

    g_debug ("Connection closed by ibus-daemon\n");
    g_printerr ("Connection closed by ibus-daemon\n");
    g_clear_object (&_bus);
    ibus_quit ();
}

int
main (int    argc,
      char **argv)
{
    if (_bus != NULL)
        return 0;

    ibus_init ();

    _bus = ibus_bus_new ();

    // On disconnect
    g_signal_connect (_bus, "disconnected",
                        G_CALLBACK (_bus_disconnected_cb), NULL);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ibus_main ();
    });

    @autoreleasepool
    {
        app = [NSApplication sharedApplication];
        [app setDelegate:[[[MyAppDelegate alloc] init] autorelease]];
        [app run];
    }

    return EXIT_SUCCESS;
}

@interface CandidateView : NSView {
    NSAttributedString  *_string;
    NSColor             *_bgColor;
    float                _radius;
}

-(void)setAttributedString:(NSAttributedString *)str;
-(void)setBgColor:(NSColor*)color;

@property (retain, nonatomic) NSColor *bgColor;

@end

@implementation CandidateView

@synthesize bgColor  = _bgColor;

-(void)setAttributedString:(NSAttributedString *)str
{
    _string = str;
    [self setNeedsDisplay:YES];
}

-(void)setRadius:(float)radius
{
    _radius = radius;
}

- (void)drawRect:(NSRect)rect 
{
    if (!_string)
        return;

    [[NSColor clearColor] set];
    NSRectFill([self bounds]);

    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:_radius yRadius:_radius];
    [_bgColor set];
    [path fill];

    NSPoint stringOrigin;
    NSSize stringSize = [_string size];
    stringOrigin.x = rect.origin.x + (rect.size.width  - stringSize.width)/2;
    stringOrigin.y = rect.origin.y + (rect.size.height - stringSize.height + 1)/2;

    [_string drawAtPoint:stringOrigin];
}

@end

@implementation CandidateWindow

@synthesize fgColor  = _fgColor;
@synthesize hlColor  = _hlColor;

-(id)init
{
    _font = [NSFont systemFontOfSize:16];
    _fgColor = [NSColor whiteColor];
    _hlColor = [NSColor blueColor];

    _attr = [[NSMutableDictionary alloc] init];
    [_attr setObject:_fgColor forKey:NSForegroundColorAttributeName];
    [_attr setObject:_font forKey:NSFontAttributeName];

    _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(800, 400, 200, 40)
                                styleMask:NSBorderlessWindowMask
                                backing:NSBackingStoreBuffered
                                defer:NO];

    [_window setAlphaValue:1.0];
    [_window setLevel:NSScreenSaverWindowLevel+1];
    [_window setHasShadow:YES];    
    [_window setOpaque:NO];

    _view = [[CandidateView alloc] initWithFrame:[[_window contentView] frame]];
    [_window setContentView:_view];

    [_window makeKeyWindow];
    
    return self;
}

-(NSFont *)font
{
    return _font;
}

-(void)setFont:(NSFont*)font
{
    _font = font;
    [_attr setObject:_font forKey:NSFontAttributeName];
}

-(NSColor*)bgColor
{
    return [(CandidateView*)_view bgColor];
}

-(void)setBgColor:(NSColor*)color
{
    [(CandidateView*)_view setBgColor:color];
}     

-(void)setRadius:(float)radius
{
    [(CandidateView*)_view setRadius:radius];
}

-(void)showCandidates:(NSArray *)candiArray around:(NSRect)cursorRect
{
    if ([candiArray count] == 0) {
        [self hideCandidates];
        return;
    }

    [_attr setObject:_fgColor forKey:NSForegroundColorAttributeName];
    [_attr setObject:_font forKey:NSFontAttributeName];

    int i;
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    for (i=0; i<[candiArray count]; i++) {
        NSString *str = [NSString stringWithFormat:@"%d.%@ ", i+1, [candiArray objectAtIndex:i]];
        NSAttributedString *astr = [[NSAttributedString alloc] initWithString:str attributes:_attr];
        [string appendAttributedString:astr];
        
        if (i==0)
            [string addAttribute:NSForegroundColorAttributeName 
                    value:_hlColor
                    range:NSMakeRange(0, [str length])];
    }
    
    NSRect winRect = NSMakeRect(800, 400, 200, 40);
    NSSize strSize = [string size];

    // tuningFrameForScreen (&winRect, strSize, cursorRect);
    
    [(CandidateView*)_view setAttributedString:string];

    [_window setFrame:winRect display:YES animate:NO];
    [_window orderFront:nil];
}

-(void)hideCandidates
{
    [_window orderOut:self];
}

@end
