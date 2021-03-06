/****************************************************************************
 * app/app.ld
 *
 *   Copyright (C) 2015 Gregory Nutt. All rights reserved.
 *   Author: Gregory Nutt <gnutt@nuttx.org>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 * 3. Neither the name NuttX nor the names of its contributors may be
 *    used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 ****************************************************************************/

/* The STM32F446RE has 512KiB of FLASH beginning at address 0x0800:0000 and
 * 112KiB of SRAM beginning at address 0x2000:0000. With an addtional 16 KiB
 * located at 0x2001:c000.
 * When booting from FLASH, FLASH memory is aliased to address 0x0000:0000
 * where the code expects to begin execution by jumping to the entry point
 * in the 0x0800:0000 address range.
 * The bootloader only uses the first 16KiB of flash.
 * Paramater storage will use the next 2 16KiB Sectors.
 */

MEMORY
{
    flash (rx)  : ORIGIN = 0x0800C000, LENGTH  = 464K
    sram (rwx)  : ORIGIN = 0x20000000, LENGTH  = 112K
    sram1 (rwx) : ORIGIN = 0x2001C000, LENGTH = 16K
}

OUTPUT_ARCH(arm)

__stack = ORIGIN(sram) + LENGTH(sram) - 4;

ENTRY(__start)      /* treat __start as the anchor for dead code stripping */
EXTERN(app_vectors)  /* force the vectors to be included in the output */
/*
 * Ensure that abort() is present in the final object.  The exception handling
 * code pulled in by libgcc.a requires it (and that code cannot be easily avoided).
 */
/* EXTERN(abort) */
SECTIONS
{
  .text : {
    _stext = ABSOLUTE(.);
    *(.app_vectors)
    . = ALIGN(8);
    KEEP(*(.app_descriptor)) /* Firmware image descriptor */
    *(.text .text.*)
    *(.fixup)
    *(.gnu.warning)
    *(.rodata .rodata.*)
    *(.gnu.linkonce.t.*)
    *(.got)
    *(.gcc_except_table)
    *(.gnu.linkonce.r.*)
    _etext = ABSOLUTE(.);
  } > flash

/*
 * Init functions (static constructors and the like)
 */
  .init_section : {
    _sinit = ABSOLUTE(.);
    KEEP(*(.init_array .init_array.*))
    _einit = ABSOLUTE(.);
  } > flash

  .ARM.extab : {
    *(.ARM.extab*)
  } > flash

  __exidx_start = ABSOLUTE(.);
  .ARM.exidx : {
    *(.ARM.exidx*)
  } > flash
  __exidx_end = ABSOLUTE(.);

  _eronly = ABSOLUTE(.);

  .data : {
    _sdata = ABSOLUTE(.);
    *(.data .data.*)
    *(.gnu.linkonce.d.*)
    CONSTRUCTORS
    _edata = ABSOLUTE(.);
  } > sram AT > flash

  .bss : {
    _sbss = ABSOLUTE(.);
    *(.bss .bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
    _ebss = ABSOLUTE(.);
  } > sram

  /* Stabs debugging sections. */
  .stab 0 : { *(.stab) }
  .stabstr 0 : { *(.stabstr) }
  .stab.excl 0 : { *(.stab.excl) }
  .stab.exclstr 0 : { *(.stab.exclstr) }
  .stab.index 0 : { *(.stab.index) }
  .stab.indexstr 0 : { *(.stab.indexstr) }
  .comment 0 : { *(.comment) }
  .debug_abbrev 0 : { *(.debug_abbrev) }
  .debug_info 0 : { *(.debug_info) }
  .debug_line 0 : { *(.debug_line) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  .debug_aranges 0 : { *(.debug_aranges) }
}
