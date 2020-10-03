# vim:set noet ts=4:
#
# ibus - The Input Bus
#
# Copyright (c) 2020 Weixuan XIAO <veyx.shaw@gmail.com>
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

libibus = $(top_builddir)/src/libibus-@IBUS_API_VERSION@.la

libexec_PROGRAMS = ibus-macos

ibus_macos_SOURCES = \
    $(protocol_sources) \
    main.mm \
    $(NULL)

ibus_macos_DEPENDENCIES = \
    $(libibus) \
    $(NULL)

ibus_macos_LDADD = \
    $(libibus) \
    $(GIO2_LIBS) \
    $(INPUT_METHOD_KIT) \
    $(NULL)

ibus_macos_CFLAGS = \
    $(INPUT_METHOD_KIT_CFLAGS) \
    -I$(top_srcdir)/src \
    -I$(top_builddir)/src \
    $(NULL)

$(libibus):
	(cd $(top_builddir)/src; make)

EXTRA_DIST = \
    README \
    $(NULL)

-include $(top_srcdir)/git.mk
