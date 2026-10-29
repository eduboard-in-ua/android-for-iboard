reset:
#if defined(CONFIG_SPL_BUILD)
    /* Set up a stack aligned to 16 bytes. */
    ldr	x0, =(CONFIG_SPL_STACK)
#else
    ldr	x0, =(CONFIG_SYS_INIT_SP_ADDR)
#endif
    bic	sp, x0, #0xf
    mov	x0, sp
    bl	board_init_f_alloc_reserve
    mov	sp, x0
    mov	x18, x0
    bl	board_init_f_init_reserve

    bl	_main
hang:
    wfi
    b hang
