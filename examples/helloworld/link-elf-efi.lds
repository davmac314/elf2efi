ENTRY(EfiMain)

SECTIONS {

    /* We'll start .text at the 4kb mark and align later sections on a 4kb
     * boundary. This doesn't seem to be strictly necessary. */

    .text 0x1000 : {
        *(.text*)
    }

    . = ALIGN(0x1000);

    .data : {
        *(.data)
    }

    . = ALIGN(0x1000);

    .rodata : {
        *(.rodata*)
    }

    . = ALIGN(0x1000);

    .bss . : {
        *(.bss)
    }

    /* Debug sections: */
    /* .debug_info .debug_abbrev .debug_loc .debug_aranges .debug_line .debug_macinfo .debug_str */

    /* if not wanted, there's no need to change this: just pass -s (strip)
     * to ld */

    .debug_aranges 0 :  { *(.debug_aranges)  }
    .debug_str 0 :      { *(.debug_str)      }
    .debug_loc 0 :      { *(.debug_loc)      }
    .debug_abbrev 0 :   { *(.debug_abbrev)   }
    .debug_info 0 :     { *(.debug_info)     }
    .debug_ranges 0 :   { *(.debug_ranges)   }
    .debug_macinfo 0 :  { *(.debug_macinfo)  }
    .debug_pubnames 0 : { *(.debug_pubnames) }
    .debug_pubtypes 0 : { *(.debug_pubtypes) }
    .debug_frame 0 :    { *(.debug_frame)    }
    .debug_line 0 :     { *(.debug_line)     }

    /DISCARD/ : {
        
        /* discard exception handling frames. */
        *(.eh_frame)
        *(.rela.eh_frame)

        /* also discard other stuff that's not needed or problematic */
        *(.comment)
        *(.note.gnu.property)
        *(.note.GNU-stack)
        *(.dynamic)
    }
}
