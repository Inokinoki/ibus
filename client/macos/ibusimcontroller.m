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

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#import "ibusimcontroller.h"
#import "keymap.h"

#import <AppKit/AppKit.h>
#import <ibus.h>

static IBusBus *_bus = NULL;

IBusBus *
ibus_macos_get_bus (void)
{
    return _bus;
}

void
ibus_macos_set_bus (IBusBus *bus)
{
    if (_bus != NULL)
        g_object_unref (_bus);
    _bus = bus ? g_object_ref (bus) : NULL;
}

@interface IBusIMController () {
    @public
    IBusInputContext *_context;
    id                _client;
    gboolean          _preedit_visible;
    gboolean          _focused;
}
- (void)createContextIfNeeded;
- (void)destroyContext;
- (void)updateCursorLocation;
- (void)updateSurroundingText;
@end

static void
_context_commit_text_cb (IBusInputContext *context,
                         IBusText         *text,
                         IBusIMController *self)
{
    if (self->_client == nil || text == NULL || text->text == NULL)
        return;
    NSString *string = [NSString stringWithUTF8String:text->text];
    [self->_client insertText:string
             replacementRange:NSMakeRange (NSNotFound, 0)];
    self->_preedit_visible = FALSE;
}

static NSAttributedString *
preedit_to_attributed_string (IBusText *text)
{
    NSString *string;
    NSMutableAttributedString *attr;

    if (text == NULL || text->text == NULL)
        return [[NSAttributedString alloc] initWithString:@""];

    string = [NSString stringWithUTF8String:text->text];
    attr = [[NSMutableAttributedString alloc] initWithString:string];
    [attr addAttribute:NSUnderlineStyleAttributeName
                 value:@(NSUnderlineStyleSingle)
                 range:NSMakeRange (0, [string length])];
    return attr;
}

static void
_context_update_preedit_text_cb (IBusInputContext *context,
                                 IBusText         *text,
                                 gint              cursor_pos,
                                 gboolean          visible,
                                 guint             mode,
                                 IBusIMController *self)
{
    if (self->_client == nil)
        return;

    if (!visible || text == NULL || text->text == NULL || text->text[0] == '\0') {
        [self->_client setMarkedText:@""
                      selectionRange:NSMakeRange (0, 0)
                    replacementRange:NSMakeRange (NSNotFound, 0)];
        self->_preedit_visible = FALSE;
        return;
    }

    NSAttributedString *attr = preedit_to_attributed_string (text);
    NSUInteger cursor = MIN ((NSUInteger) cursor_pos, [attr length]);
    [self->_client setMarkedText:attr
                  selectionRange:NSMakeRange (cursor, 0)
                replacementRange:NSMakeRange (NSNotFound, 0)];
    self->_preedit_visible = TRUE;
}

static void
_context_show_preedit_text_cb (IBusInputContext *context,
                               IBusIMController *self)
{
    self->_preedit_visible = TRUE;
}

static void
_context_hide_preedit_text_cb (IBusInputContext *context,
                               IBusIMController *self)
{
    if (self->_client != nil) {
        [self->_client setMarkedText:@""
                      selectionRange:NSMakeRange (0, 0)
                    replacementRange:NSMakeRange (NSNotFound, 0)];
    }
    self->_preedit_visible = FALSE;
}

static void
_context_forward_key_event_cb (IBusInputContext *context,
                               guint             keyval,
                               guint             keycode,
                               guint             state,
                               IBusIMController *self)
{
    gunichar ch;

    if (self->_client == nil)
        return;
    if (state & IBUS_RELEASE_MASK)
        return;

    ch = ibus_keyval_to_unicode (keyval);
    if (ch == 0)
        return;

    gchar buf[8] = { 0 };
    gint n = g_unichar_to_utf8 (ch, buf);
    buf[n] = '\0';
    NSString *string = [NSString stringWithUTF8String:buf];
    [self->_client insertText:string
             replacementRange:NSMakeRange (NSNotFound, 0)];
}

static void
_context_delete_surrounding_text_cb (IBusInputContext *context,
                                     gint              offset_from_cursor,
                                     guint             nchars,
                                     IBusIMController *self)
{
    NSRange selected;
    NSInteger location;

    if (self->_client == nil)
        return;

    selected = [self->_client selectedRange];
    location = (NSInteger) selected.location + offset_from_cursor;
    if (location < 0)
        location = 0;
    [self->_client insertText:@""
             replacementRange:NSMakeRange ((NSUInteger) location, nchars)];
}

static void
_context_require_surrounding_text_cb (IBusInputContext *context,
                                      IBusIMController *self)
{
    [self updateSurroundingText];
}

static void
_context_destroy_cb (IBusInputContext *context,
                     IBusIMController *self)
{
    if (self->_context == context)
        self->_context = NULL;
}

@implementation IBusIMController

- (id)initWithServer:(IMKServer *)server
            delegate:(id)delegate
              client:(id)inputClient
{
    self = [super initWithServer:server delegate:delegate client:inputClient];
    if (self) {
        _client = inputClient;
        [self createContextIfNeeded];
    }
    return self;
}

- (void)dealloc
{
    [self destroyContext];
}

- (void)createContextIfNeeded
{
    IBusBus *bus = ibus_macos_get_bus ();
    gchar *client_name;
    const gchar *prgname;

    if (_context != NULL)
        return;
    if (bus == NULL || !ibus_bus_is_connected (bus))
        return;

    prgname = g_get_prgname ();
    client_name = g_strdup_printf ("macos-im:%s",
                                   prgname ? prgname : "unknown");
    _context = ibus_bus_create_input_context (bus, client_name);
    g_free (client_name);
    if (_context == NULL)
        return;

    ibus_input_context_set_client_commit_preedit (_context, TRUE);
    ibus_input_context_set_post_process_key_event (_context, TRUE);
    ibus_input_context_set_capabilities (
            _context,
            IBUS_CAP_PREEDIT_TEXT |
            IBUS_CAP_FOCUS |
            IBUS_CAP_SURROUNDING_TEXT);

    g_signal_connect (_context, "commit-text",
                      G_CALLBACK (_context_commit_text_cb),
                      (__bridge void *) self);
    g_signal_connect (_context, "update-preedit-text-with-mode",
                      G_CALLBACK (_context_update_preedit_text_cb),
                      (__bridge void *) self);
    g_signal_connect (_context, "show-preedit-text",
                      G_CALLBACK (_context_show_preedit_text_cb),
                      (__bridge void *) self);
    g_signal_connect (_context, "hide-preedit-text",
                      G_CALLBACK (_context_hide_preedit_text_cb),
                      (__bridge void *) self);
    g_signal_connect (_context, "forward-key-event",
                      G_CALLBACK (_context_forward_key_event_cb),
                      (__bridge void *) self);
    g_signal_connect (_context, "delete-surrounding-text",
                      G_CALLBACK (_context_delete_surrounding_text_cb),
                      (__bridge void *) self);
    g_signal_connect (_context, "require-surrounding-text",
                      G_CALLBACK (_context_require_surrounding_text_cb),
                      (__bridge void *) self);
    g_signal_connect (_context, "destroy",
                      G_CALLBACK (_context_destroy_cb),
                      (__bridge void *) self);
}

- (void)destroyContext
{
    if (_context == NULL)
        return;
    g_signal_handlers_disconnect_by_data (_context, (__bridge void *) self);
    g_object_unref (_context);
    _context = NULL;
}

- (void)updateCursorLocation
{
    NSRect rect;
    NSRect screen;
    gint x, y;

    if (_context == NULL || _client == nil)
        return;

    rect = [_client firstRectForCharacterRange:[_client selectedRange]
                                   actualRange:NULL];
    screen = [[NSScreen mainScreen] frame];
    x = (gint) rect.origin.x;
    /* IBus uses a top-left origin; Cocoa uses bottom-left. */
    y = (gint) (screen.size.height - (rect.origin.y + rect.size.height));
    ibus_input_context_set_cursor_location (_context,
                                            x, y,
                                            (gint) rect.size.width,
                                            (gint) rect.size.height);
}

- (void)updateSurroundingText
{
    NSRange selected;
    NSInteger start;
    NSUInteger length;
    NSAttributedString *surrounding;
    const gchar *utf8;
    IBusText *text;

    if (_context == NULL || _client == nil)
        return;

    selected = [_client selectedRange];
    if (selected.location == NSNotFound)
        return;

    start = (NSInteger) selected.location - 20;
    if (start < 0)
        start = 0;
    length = (selected.location - (NSUInteger) start) + selected.length + 20;
    surrounding = [_client attributedSubstringFromRange:
                           NSMakeRange ((NSUInteger) start, length)];
    if (surrounding == nil)
        return;

    utf8 = [[surrounding string] UTF8String];
    if (utf8 == NULL)
        return;
    text = ibus_text_new_from_string (utf8);
    ibus_input_context_set_surrounding_text (
            _context,
            text,
            (guint) (selected.location - (NSUInteger) start),
            (guint) (selected.location - (NSUInteger) start + selected.length));
}

- (void)activateServer:(id)sender
{
    _client = sender;
    [self createContextIfNeeded];
    if (_context != NULL) {
        _focused = TRUE;
        ibus_input_context_focus_in (_context);
        [self updateCursorLocation];
        [self updateSurroundingText];
    }
}

- (void)deactivateServer:(id)sender
{
    if (_context != NULL && _focused) {
        ibus_input_context_focus_out (_context);
        _focused = FALSE;
    }
}

- (void)commitComposition:(id)sender
{
    if (_context != NULL)
        ibus_input_context_reset (_context);
    if (_client != nil && _preedit_visible) {
        [_client setMarkedText:@""
                selectionRange:NSMakeRange (0, 0)
              replacementRange:NSMakeRange (NSNotFound, 0)];
    }
    _preedit_visible = FALSE;
}

- (BOOL)handleEvent:(NSEvent *)event client:(id)sender
{
    guint keyval = 0;
    guint keycode = 0;
    guint state = 0;
    gboolean handled;

    _client = sender;
    [self createContextIfNeeded];
    if (_context == NULL)
        return NO;

    if (!ibus_macos_event_to_key (event, &keyval, &keycode, &state))
        return NO;

    [self updateCursorLocation];
    handled = ibus_input_context_process_key_event (_context,
                                                    keyval, keycode, state);
    ibus_input_context_post_process_key_event (_context);
    return handled ? YES : NO;
}

@end
