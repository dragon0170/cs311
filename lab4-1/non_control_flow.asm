main:
        addi    sp,sp,-32
        sw      ra,28(sp)
        sw      s0,24(sp)
        addi    s0,sp,32
        addi    a5,zero,19
        sw      a5,-20(s0)
        addi    a5,zero,14
        sw      a5,-24(s0)
        lw      a4,-24(s0)
        lw      a5,-20(s0)
        add     a5,a4,a5
        addi    a0,zero,0
        not     a0,a0
        or      a0,zero,a0
        add    t3, a0, a5
        or     t2, a4, t3
        sll    t4, t3, t2
        srl    t5, t3, t2
        addi    t5, t2, 10
        xor     t6, t2, t5
        addi    t6, t4, 20
        andi    a0,a0,12
        addi    a0,a0,28
        slli    a0,a0,2 
        srli    a0,a0,4
        add     a2,a0,zero
        li      a7, 31
        ecall
        add     a0,a2,zero
        ori     a6,zero,14
        addi    a7,zero,4
        sll     a7,a6,a7
        xor     a7,a7,a0
        sub     a6,a6,a0
        srl     a7,a7,a6
        addi    a1,zero,63
        and     a3,a7,a1
        not     a2,a7
        sub     a6,a7,a6
        srli    a7,a7,3
        or      a3,a4,a5
        lw      ra,28(sp)
        lw      s0,24(sp)
        addi    sp,sp,32
        li      a7, 10
        addi    a7, a6, 5
        addi    a7, t5, 5
        addi    a7, a7, -4
        ecall
        li      a7, 10
        ecall
