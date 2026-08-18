# vim:set noet ts=4:
#
# ibus - The Input Bus
#
# Copyright (c) 2020-2026 Weixuan XIAO <veyx.shaw@gmail.com>
#
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of the
# License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 USA.

NULL =

libibus = $(top_builddir)/src/libibus-@IBUS_API_VERSION@.la

libexec_PROGRAMS = ibus-ui-macos

component_DATA = \
	macospanel.xml \
	$(NULL)
componentdir = $(pkgdatadir)/component

ibus_ui_macos_SOURCES = \
    main.m \
    panel.c \
    candidatewindow.m \
    $(top_srcdir)/client/macos/glibrunloop.m \
    $(NULL)

noinst_HEADERS = \
    candidatewindow.h \
    panel.h \
    $(NULL)

ibus_ui_macos_DEPENDENCIES = \
    $(libibus) \
    $(NULL)

ibus_ui_macos_LDADD = \
    $(libibus) \
    @GOBJECT2_LIBS@ \
    @GLIB2_LIBS@ \
    @GIO2_LIBS@ \
    $(NULL)

ibus_ui_macos_LDFLAGS = \
    -framework Cocoa \
    -framework AppKit \
    -framework Foundation \
    -framework CoreFoundation \
    $(NULL)

ibus_ui_macos_CFLAGS = \
    @GLIB2_CFLAGS@ \
    @GIO2_CFLAGS@ \
    -I$(top_srcdir)/src \
    -I$(top_builddir)/src \
    -I$(top_builddir) \
    -I$(srcdir) \
    -I$(top_srcdir)/client/macos \
    $(NULL)

ibus_ui_macos_OBJCFLAGS = \
    -fobjc-arc \
    @GLIB2_CFLAGS@ \
    @GIO2_CFLAGS@ \
    -I$(top_srcdir)/src \
    -I$(top_builddir)/src \
    -I$(top_builddir) \
    -I$(srcdir) \
    -I$(top_srcdir)/client/macos \
    $(NULL)

$(libibus):
	$(MAKE) -C $(top_builddir)/src

macospanel.xml: macospanel.xml.in
	$(AM_V_GEN) sed \
		-e 's|@VERSION[@]|$(VERSION)|g' \
		-e 's|@libexecdir[@]|$(libexecdir)|g' $< > $@.tmp && \
		mv $@.tmp $@

EXTRA_DIST = \
	macospanel.xml.in \
	$(NULL)

CLEANFILES = \
	macospanel.xml \
	$(NULL)

-include $(top_srcdir)/git.mk
