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

#import "keymap.h"

#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <ibus.h>

typedef struct {
    guint mac_vk;
    guint keyval;
} MacKeyMap;

static const MacKeyMap special_keys[] = {
    { kVK_Return,        IBUS_KEY_Return },
    { kVK_Tab,           IBUS_KEY_Tab },
    { kVK_Space,         IBUS_KEY_space },
    { kVK_Delete,        IBUS_KEY_BackSpace },
    { kVK_Escape,        IBUS_KEY_Escape },
    { kVK_ForwardDelete, IBUS_KEY_Delete },
    { kVK_Home,          IBUS_KEY_Home },
    { kVK_End,           IBUS_KEY_End },
    { kVK_PageUp,        IBUS_KEY_Page_Up },
    { kVK_PageDown,      IBUS_KEY_Page_Down },
    { kVK_LeftArrow,     IBUS_KEY_Left },
    { kVK_RightArrow,    IBUS_KEY_Right },
    { kVK_DownArrow,     IBUS_KEY_Down },
    { kVK_UpArrow,       IBUS_KEY_Up },
    { kVK_Help,          IBUS_KEY_Help },
    { kVK_F1,            IBUS_KEY_F1 },
    { kVK_F2,            IBUS_KEY_F2 },
    { kVK_F3,            IBUS_KEY_F3 },
    { kVK_F4,            IBUS_KEY_F4 },
    { kVK_F5,            IBUS_KEY_F5 },
    { kVK_F6,            IBUS_KEY_F6 },
    { kVK_F7,            IBUS_KEY_F7 },
    { kVK_F8,            IBUS_KEY_F8 },
    { kVK_F9,            IBUS_KEY_F9 },
    { kVK_F10,           IBUS_KEY_F10 },
    { kVK_F11,           IBUS_KEY_F11 },
    { kVK_F12,           IBUS_KEY_F12 },
    { kVK_F13,           IBUS_KEY_F13 },
    { kVK_F14,           IBUS_KEY_F14 },
    { kVK_F15,           IBUS_KEY_F15 },
    { kVK_F16,           IBUS_KEY_F16 },
    { kVK_F17,           IBUS_KEY_F17 },
    { kVK_F18,           IBUS_KEY_F18 },
    { kVK_F19,           IBUS_KEY_F19 },
    { kVK_F20,           IBUS_KEY_F20 },
    { kVK_ANSI_KeypadEnter, IBUS_KEY_KP_Enter },
    { kVK_ANSI_KeypadDecimal, IBUS_KEY_KP_Decimal },
    { kVK_ANSI_KeypadMultiply, IBUS_KEY_KP_Multiply },
    { kVK_ANSI_KeypadPlus, IBUS_KEY_KP_Add },
    { kVK_ANSI_KeypadClear, IBUS_KEY_Clear },
    { kVK_ANSI_KeypadDivide, IBUS_KEY_KP_Divide },
    { kVK_ANSI_KeypadMinus, IBUS_KEY_KP_Subtract },
    { kVK_ANSI_KeypadEquals, IBUS_KEY_KP_Equal },
    { kVK_ANSI_Keypad0,  IBUS_KEY_KP_0 },
    { kVK_ANSI_Keypad1,  IBUS_KEY_KP_1 },
    { kVK_ANSI_Keypad2,  IBUS_KEY_KP_2 },
    { kVK_ANSI_Keypad3,  IBUS_KEY_KP_3 },
    { kVK_ANSI_Keypad4,  IBUS_KEY_KP_4 },
    { kVK_ANSI_Keypad5,  IBUS_KEY_KP_5 },
    { kVK_ANSI_Keypad6,  IBUS_KEY_KP_6 },
    { kVK_ANSI_Keypad7,  IBUS_KEY_KP_7 },
    { kVK_ANSI_Keypad8,  IBUS_KEY_KP_8 },
    { kVK_ANSI_Keypad9,  IBUS_KEY_KP_9 },
};

static guint
lookup_special_keyval (guint mac_vk)
{
    guint i;
    for (i = 0; i < G_N_ELEMENTS (special_keys); i++) {
        if (special_keys[i].mac_vk == mac_vk)
            return special_keys[i].keyval;
    }
    return 0;
}

static guint
modifier_state_from_flags (NSEventModifierFlags flags)
{
    guint state = 0;
    if (flags & NSEventModifierFlagShift)
        state |= IBUS_SHIFT_MASK;
    if (flags & NSEventModifierFlagCapsLock)
        state |= IBUS_LOCK_MASK;
    if (flags & NSEventModifierFlagControl)
        state |= IBUS_CONTROL_MASK;
    if (flags & NSEventModifierFlagOption)
        state |= IBUS_MOD1_MASK;
    if (flags & NSEventModifierFlagCommand)
        state |= IBUS_SUPER_MASK | IBUS_MOD4_MASK;
    if (flags & NSEventModifierFlagNumericPad)
        state |= IBUS_MOD2_MASK;
    return state;
}

gboolean
ibus_macos_event_to_key (NSEvent *event,
                         guint   *keyval,
                         guint   *keycode,
                         guint   *state)
{
    guint mac_vk;
    guint special;
    NSEventType type;

    g_return_val_if_fail (event != nil, FALSE);
    g_return_val_if_fail (keyval != NULL && keycode != NULL && state != NULL,
                          FALSE);

    type = [event type];
    if (type != NSEventTypeKeyDown && type != NSEventTypeKeyUp)
        return FALSE;

    mac_vk = [event keyCode];
    *keycode = mac_vk;
    *state = modifier_state_from_flags ([event modifierFlags]);
    if (type == NSEventTypeKeyUp)
        *state |= IBUS_RELEASE_MASK;

    special = lookup_special_keyval (mac_vk);
    if (special != 0) {
        *keyval = special;
        return TRUE;
    }

    NSString *chars = [event charactersIgnoringModifiers];
    if ([chars length] > 0) {
        unichar c = [chars characterAtIndex:0];
        if (c >= 0x20 && c != 0x7f) {
            *keyval = ibus_unicode_to_keyval ((gunichar) c);
            return TRUE;
        }
    }

    *keyval = IBUS_KEY_VoidSymbol;
    return TRUE;
}
