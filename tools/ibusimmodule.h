/* -*- mode: C; c-basic-offset: 4; indent-tabs-mode: nil; -*- */
/* vim:set et sts=4: */
/* ibus - The Input Bus
 * Copyright (C) 2022 Takao Fujiwara <takao.fujiwara1@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
 * USA
 */

#ifndef __IBUS_IM_MODULE_CONTEXT_H_
#define __IBUS_IM_MODULE_CONTEXT_H_

/**
 * ibus_im_module_get_id:
 * @argc: The length of argv
 * @argv: (array length=argc) (element-type utf8): argv from main()
 *
 * Retrieve im-module value from GTK instance.
 *
 * Returns: (nullable): im-module value.
 */
char * ibus_im_module_get_id (int argc, char *argv[]);

#endif
