# in protected mode, do process switch
#if 0
note:
Gate selector_code, switch_proc_offset, 0, (DA_386IGate+DA_DPL3)

when use idt to switch ring3 -> ring0, _DPL3 must be added.
then int instruction will change %ss: %esp, so tss ss0:esp0 need right value.

#endif

#define STACK_FRAME_FOR_SS 24

.code16
.data
.macro Descriptor Base, Limit, Attr
    .2byte  \Limit & 0xFFFF
    .2byte  \Base & 0xFFFF
    .byte   (\Base >> 16) & 0xFF
    .2byte  ((\Limit >> 8) & 0xF00) | (\Attr & 0xF0FF)
    .byte   (\Base >> 24) & 0xFF
.endm

.set    DA_386IGate, 0x8E    /* 32-bit Interrupt Gate */

/* Gate Descriptor data structure.
   Usage: Gate Selector, Offset, PCount, Attr
    Selector:  2byte
    Offset:    4byte
    PCount:    byte
    Attr:      byte */
.macro Gate  Selector, Offset, PCount, Attr
    .2byte     (\Offset & 0xFFFF)
    .2byte     \Selector
    .2byte     (\PCount & 0x1F) | ((\Attr << 8) & 0xFF00)
    .2byte     ((\Offset >> 16) & 0xFFFF)
.endm



.set    DA_32,  0x4000  /* 32-bit segment */
.set    DA_LIMIT_4K, 0x8000     /* 4K */
.set    DA_CR,   0x9A   /* Execute/Read */
.set    DA_DRW,  0x92   /* Read/Write */
.set    DA_DPL3,  0x60  /* DPL = 3 */
.set    DA_C,    0x98   /* Execute-Only */
.set    DA_DRWA, 0x93   /* Read/Write, accessed */
.set    DA_386TSS,   0x89    /* 32-bit TSS(Available) */

.set    SA_RPL3, 3


gdt0: Descriptor  0, 0, 0
gdt1: Descriptor  0, 0xfffff, DA_CR | DA_32 | DA_LIMIT_4K
gdt2: Descriptor  0, 0xfffff, DA_DRW | DA_32 | DA_LIMIT_4K
proc_a_desc:  Descriptor  0, 0xfffff, (DA_C + DA_32 + DA_DPL3)
proc_b_desc:  Descriptor  0, 0xfffff, (DA_C + DA_32 + DA_DPL3)
proc_data_desc:  Descriptor  0, 0xfffff, (DA_DRWA + DA_32 + DA_DPL3)
tss_desc: Descriptor  0, (TSS_LEN - 1), DA_386TSS


.set gdt_len, (. - gdt0)
gdt_ptr: .2byte (gdt_len -1 ) # limit
         .4byte 0             # base

.set selector_code, (gdt1-gdt0)
.set selector_data, (gdt2-gdt0)
.set sel_proc_a,  (proc_a_desc - gdt0 + SA_RPL3)
.set sel_proc_b,  (proc_b_desc - gdt0 + SA_RPL3)
.set sel_proc_data,  (proc_data_desc - gdt0 + SA_RPL3)
.set sel_tss,  (tss_desc - gdt0)


idt:
.rept 200
Gate selector_code, switch_proc_offset, 0, (DA_386IGate+DA_DPL3)
.endr
.set idt_len, (. - idt)  /* IDT Length */

idt_ptr: .2byte  (idt_len - 1)  /* IDT Limit */
         .4byte  0             /* IDT Base */

LABEL_TSS:
    .4byte  0           /* Back Link */
    .4byte  0  /* ESP0 */
    .4byte  0 /* SS0 */
    .4byte  0           /* ESP1 */
    .4byte  0           /* SS1 */
    .4byte  0           /* ESP2 */
    .4byte  0           /* SS2 */
    .4byte  0           /* CR3(PDBR) */
    .4byte  0           /* EIP */
    .4byte  0           /* EFLAGS */
    .4byte  0           /* EAX */
    .4byte  0           /* ECX */
    .4byte  0           /* EDX */
    .4byte  0           /* EBX */
    .4byte  0           /* ESP */
    .4byte  0           /* EBP */
    .4byte  0           /* ESI */
    .4byte  0           /* EDI */
    .4byte  0           /* ES */
    .4byte  0           /* CS */
    .4byte  0           /* SS */
    .4byte  0           /* DS */
    .4byte  0           /* FS */
    .4byte  0           /* GS */
    .4byte  0           /* LDT Segment Selector */
    .2byte  0           /* Trap Flag: 1-bit */
    .2byte  (. - LABEL_TSS + 2)     /* I/O Map Base Address */
    .byte   0xff        /* End */
.set    TSS_LEN, (. - LABEL_TSS)



.text
.global begin
begin:
  #xchg %bx, %bx #bochs magic break point

    /* Initialize 32-bits code segment descriptor. */
    xor     %eax, %eax
    mov     %cs, %ax
    shl     $4, %eax
#    addl    $seg_code32, %eax
    movw    %ax, (gdt1 + 2)
    shr     $16, %eax
    movb    %al, (gdt1 + 4)
    movb    %ah, (gdt1 + 7)

    /* Initialize 32-bits data segment descriptor. */
    xor     %eax, %eax
    mov     %cs, %ax
    shl     $4, %eax
#    addl    $seg_code32, %eax
    movw    %ax, (gdt2 + 2)
    shr     $16, %eax
    movb    %al, (gdt2 + 4)
    movb    %ah, (gdt2 + 7)


    # Initialize tss


        xor     %eax, %eax
        mov     %ds, %ax
        shl     $4, %eax
        addl    $(LABEL_TSS), %eax
        movw    %ax, (tss_desc + 2)
        shr     $16, %eax
        movb    %al, (tss_desc + 4)
        movb    %ah, (tss_desc + 7)



    /* Initialize 32-bits proc ring3 segment descriptor. */
    xor     %eax, %eax
    mov     %cs, %ax
    shl     $4, %eax
    movw    %ax, (proc_a_desc + 2)
    shr     $16, %eax
    movb    %al, (proc_a_desc + 4)
    movb    %ah, (proc_a_desc + 7)

  xor     %eax, %eax
  mov     %cs, %ax
  shl     $4, %eax
  add     $gdt0, %eax      /* eax <- gdt base*/
  movl    %eax, (gdt_ptr + 2)
  lgdt gdt_ptr

    /* Prepared for loading IDTR */
    xor     %eax, %eax
    mov     %ds, %ax
    shl     $4, %eax
    add     $idt, %eax      /* eax <- idt base*/
    movl    %eax, (idt_ptr + 2)

  cli

  lidt idt_ptr



  movw $selector_data, LABEL_TSS+8 # ss0
  movl $proc_stack_top, LABEL_TSS+4 # esp0




  # open a20 line
  inb $0x92, %al
  orb $0b00000010, %al
  outb %al, $0x92


  # enable protect mode
  movl %cr0, %eax
  orl $1, %eax
  movl %eax, %cr0


  ljmpl $selector_code, $seg_code32



  mov $0x4c00, %ax
  int $0x21           

.code32
seg_code32:
  #xchg %bx, %bx #bochs magic break point
  mov $selector_data, %ax
  mov %ax, %ds
  mov %ax, %ss
  mov $proc_stack_top, %esp

## set stack frame flag
  # get flag
  pushf
  movl (%esp), %eax
  popf
  movl %eax, stack_frame_a+12
  movl %eax, stack_frame_b+12
  cli

## set stack frame eip
  movl $proc_a, stack_frame_a+4
  movl $proc_b, stack_frame_b+4

## set stack frame cs
  xor     %eax, %eax
  movw $sel_proc_a, %ax
  #movw $selector_code, %ax
  movw %ax, stack_frame_a+8
  movw %ax, stack_frame_b+8


## set stack frame esp
  movw $proc_stack_top_a, stack_frame_a+16
  movw $proc_stack_top_b, stack_frame_b+16

## set stack frame ss
#  movw %ss, %ax
  movw $sel_proc_data, stack_frame_a+20
  movw $sel_proc_data, stack_frame_b+20


  movl $stack_frame_a, cur_proc
  movl cur_proc, %esp
  popl %eax
  xchg %bx, %bx #bochs magic break point

  movw $selector_data, LABEL_TSS+8 # ss0
  movl $stack_frame_a+STACK_FRAME_FOR_SS, LABEL_TSS+4 # esp0

  mov $sel_tss, %ax    /* Load TSS to TR register */
  ltr %ax

  iretl




  mov $selector_data, %ax
  int $0x30
  mov %ax, %ds
  mov %ax, %es
  mov %ax, %ss
  mov $0xb8004, %edi    /* Destination */
  movb $'P', (%edi)
  mov $0xb8005, %edi    /* Destination */
  movb $0x9, (%edi)




.global proc_a
proc_a:
1:
  mov $0x1, %ax
  push %ebx
  int $0x30
  jmp 1b

.global proc_b
proc_b:
1:
  mov $0x2, %al
  push %ecx
  int $0x30
  jmp 1b


.global int0x30
int0x30:
.set int0x30_offset, (. - seg_code32)
  mov $0x1, %cx;
  iret

.global switch_proc
switch_proc:
.set switch_proc_offset, (. - begin+0x100)
#  movw %cs:my_ss, %ds
#  movw %cs:my_ss, %ss
#  movw cur_proc, %sp
  push %eax
  mov $selector_data, %ax
  mov %ax, %ds

#if 0
  inb $0x21, %al
  orb $0x1 ,%al
  outb %al, $0x21
#endif

  movl cur_proc, %edx
  cmpl $stack_frame_a, %edx
  je 1f
  movl $stack_frame_a, cur_proc
  jmp 2f
1:
  movl $stack_frame_b, cur_proc
2:

#if 0
  cli
  inb $0x21, %al
  andb $0xfe ,%al
  outb %al, $0x21
#endif

  movl cur_proc, %eax
  addl $24, %eax
  movl %eax, LABEL_TSS+4 # esp0
  movl cur_proc, %esp
  pop %eax
  iret

stack_frame_a:
  .long 0x9# eax
  .long 0x0# eip
  .long 0x0# cs
  .long 0x2# flag
  .long 0x2# esp
  .long 0x2# ss

stack_frame_b:
  .long 0x9# ax
  .long 0x0# eip
  .long 0x0# cs
  .long 0x2# flag
  .long 0x2# esp
  .long 0x2# ss
cur_proc:
  .long 0x0

  .space  256, 0
proc_stack_top:

  .space  256, 0
proc_stack_top_a:

  .space  256, 0
proc_stack_top_b:
