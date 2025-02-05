divert(`-1')
define(`xcounter',`0')dnl
define(`xcount',`define(`xcounter',eval(xcounter+1))')dnl

# quote(args) - convert args to single-quoted string
define(`quote', `ifelse(`$#', `0', `', ``$*'')')
# dquote(args) - convert args to quoted list of quoted strings
define(`dquote', ``$@'')
# dquote_elt(args) - convert args to list of double-quoted strings
define(`dquote_elt', `ifelse(`$#', `0', `', `$#', `1', ```$1''',
                             ```$1'',$0(shift($@))')')

# foreach(x, (item_1, item_2, ..., item_n), stmt)
#   parenthesized list, improved version
define(`foreach', `pushdef(`$1')_$0(`$1',
  (dquote(dquote_elt$2)), `$3')popdef(`$1')')
define(`_arg1', `$1')
define(`_foreach', `ifelse(`$2', `(`')', `',
  `define(`$1', _arg1$2)$3`'$0(`$1', (dquote(shift$2)), `$3')')')

# forloop_arg(from, to, macro) - invoke MACRO(value) for
#   each value between FROM and TO, without define overhead
define(`forloop_arg', `ifelse(eval(`($1) <= ($2)'), `1',
  `_forloop(`$1', eval(`$2'), `$3(', `)')')')
# forloop(var, from, to, stmt) - refactored to share code
define(`forloop', `ifelse(eval(`($2) <= ($3)'), `1',
  `pushdef(`$1')_forloop(eval(`$2'), eval(`$3'),
    `define(`$1',', `)$4')popdef(`$1')')')
define(`_forloop',
  `$3`$1'$4`'ifelse(`$1', `$2', `',
    `$0(incr(`$1'), `$2', `$3', `$4')')')

// xadd(destination, param2, param3, ...) -> destination = param2 + param3 + ...
define(xadd, `
        // M4: ADD
    define(`index', eval(`1'))
        mov     x9,     0                       // initialize x9 to 0
    foreach(`t', `$@', `
        ifelse(index, `1', `', `format(`
        mov     x10,    t                       // move next number to x10
        add     x9,     x9,     x10             // and Adds x10 to x9
        ')')
        define(`index', incr(index))
    ')
        mov     $1,     x9                      // result
')

// xaddAdd(variable) -> variable ++;
define(xaddAdd, `
        // M4: ADD ADD
        add     $1, $1, 1
')

// xaddEqual(variable, param2) -> variable += param2;
define(xaddEqual, `
        // M4: ADD EQUAL
        add     $1, $1, $2
')

// xminusEqual(variable, param2) -> variable += param2;
define(xminusEqual, `
        // M4: MINUS EQUAL
        sub     $1, $1, $2
')

// xmin(destination, x, y)
define(xmin, `
        // M4: MIN
        mov     x9,     $2
        mov     x10,    $3
        // csel    $1,     x9,     x10,    le

        format(`

        cmp     x9,     x10
        b.lt    if_%s
        b       else_%s
if_%s:  mov     $1,     x9
        b       end_%s
else_%s:mov     $1,     x10
        b       end_%s
end_%s:

        ', eval(xcounter), eval(xcounter), eval(xcounter), eval(xcounter), eval(xcounter), eval(xcounter), eval(xcounter))
        
        xcount()
')

// xmax(destination, x, y)
define(xmax, `
        // M4: MAX
        mov     x9,     $2
        mov     x10,    $3
        // csel    $1,     x9,     x10,    ge

        format(`

        cmp     x9,     x10
        b.gt    if_%s
        b       else_%s
if_%s:  mov     $1,     x9
        b       end_%s
else_%s:mov     $1,     x10
        b       end_%s
end_%s:

        ', eval(xcounter), eval(xcounter), eval(xcounter), eval(xcounter), eval(xcounter), eval(xcounter), eval(xcounter))
        
        xcount()
')

// xmul(destination, param2, param3, ...)
define(xmul, `
        // M4: MUL
    define(`index', eval(`1'))
        mov     x9,     1                       // initialize x9 to 1
    foreach(`t', `$@', `
        ifelse(index, `1', `', `format(`
        mov     x10,    t                       // move next multiplier to x10
        mul     x9,     x9,     x10             // and multiplies x10 to x9
        ')')
        define(`index', incr(index))
    ')
        mov     $1,     x9                      // result
')

// xprint(string, param1, param2, ...) -> Just like how to use printf :)
define(xprint, `
        // M4: PRINT
    define(`index', eval(`0'))
    define(`register_x_index', eval(`0'))
    define(`register_d_index', eval(`0'))

    foreach(`t', `$@', `
        define(`register_type', substr(t, 0, 1))
        
        ifelse(register_type, `d', `
                ifelse(index, `0', `', `format(`fmov     d%s,    %s', eval(register_d_index), `t')')
                define(`register_d_index', incr(register_d_index))
        ', `
                ifelse(index, `0', `', `format(`mov     x%s,    %s', eval(register_x_index), `t')')
                define(`register_x_index', incr(register_x_index))
        ')

        define(`index', incr(index))
    ')
        ldr     x0,     =$1
        bl      printf

    define(`index', eval(`0'))
    define(`register_x_index', eval(`0'))
    define(`register_d_index', eval(`0'))

    foreach(`t', `$@', `
        define(`register_type', substr(t, 0, 1))
        
        ifelse(register_type, `d', `
                ifelse(index, `0', `', `format(`fmov     d%s,    %s', eval(register_d_index), `t')')
                define(`register_d_index', incr(register_d_index))
        ', `
                ifelse(index, `0', `', `format(`mov     x%s,    %s', eval(register_x_index), `t')')
                define(`register_x_index', incr(register_x_index))
        ')

        define(`index', incr(index))
    ')
        ldr     x0,     =$1
        bl      logToFile
')


// xscan(string, destination)
define(xscan, `
        // M4: SCAN
        ldr     x0,     =$1                     // 1st parameter: scnocc, the formatted string
        ldr     x1,     =n                      // 2nd parameter: &n, the data to store for user input
        bl      scanf                           // scanf(scnocc, &n);
        ldr     x1,     =n                      // 2nd parameter: &n
        ldr     $2,    [x1]                     // int n = x1;

        ldr     x0,     =$1
        ldr     x1,     [x1]
        bl      logToFile

        ldr     x0,     =str_linebr
        bl      logToFile
')


// xrandSeed()
define(xrandSeed, `
        // M4: RAND SEED
        mov     x0,     0                       // 1st parameter: 0
        bl      time                            // time(0);
        bl      srand                           // srand(time(0));
')

// xrand(destination, and)
define(xrand, `
        // M4: RAND
        bl      rand                            // rand();
        and  	x9,     x0,     $2              // int x9 = rand() & $2;
        mov     $1,     x9                      // $1 = x9;
')

// xarray(base, element_amount, element_size)
define(xarray, `
        // M4: ARRAY
    format(`
        mov     x9,     0                           // loop Counter
loop_%s:
        cmp     x9,     $2                          // if reach amount
        b.eq    loop_end_%s

        mov     x10,    $3                          // get element size
        mul     x10,    x10,    x9                  // calculate element offset by index
        
        mov     x11,    $1                          // get base
        add     x10,    x10,    x11                 // calculate total offset, offset in array + base

        str 	xzr,    [fp,    x10]                // initialize with 0

        add     x9,     x9,     1                   // increment
        b       loop_%s

loop_end_%s:

    ', eval(xcounter), eval(xcounter), eval(xcounter), eval(xcounter))
    xcount()
')
// xreadArray(destination, base, size, index, ignore_fp = false)
define(xreadArray, `
        // M4: READ ARRAY
        mov     x9,     $3                          // x9 - size
        mov     x10,    $4                          // x10 - index
        mul     x9,     x9,     x10                 // calculate Offset = Size * Index
        add     x9,     x9,     $2                  // calculate Offset += Base

        ifelse(`$#', `5', `
        ldr     $1,     [x9]
        ', `
        ldr     $1,     [fp,   x9]
        ')     
')

// xwriteArray(value, base, size, index, ignore_fp = false)
define(xwriteArray, `
        // M4: WRITE ARRAY
        mov     x9,     $3                          // x9 - size
        mov     x10,    $4                          // x10 - index
        mul     x9,     x9,     x10                 // calculate Offset = Size * Index
        add     x9,     x9,     $2                  // calculate Offset += Base

        mov     x10,    $1

        ifelse(`$#', `5', `
        str     x10,    [x9]
        ', `
        str     x10,    [fp,   x9]
        ')
')

// xstruct(base, attribute1, attribute2, ...)
define(xstruct, `
        // M4: STRUCT
    define(`index', eval(`1'))
    foreach(`t', `$@', `
        ifelse(index, `1', `', `format(`
            xwriteStruct(xzr, $1, t)
        ')')
        define(`index', incr(index))
    ')
')

// xreadStruct(destination, base, attribute, ignore_fp = false)
define(xreadStruct, `
        // M4: READ STRUCT
        mov     x11,    $2                      // int base
        mov     x12,    $3                      // int attribute offset
        add     x9,     x11,    x12             // int offset = base + attribute

        ifelse(`$#', `4', `
        ldr	$1,     [x9]                    // load the value
        ', `
        ldr	$1,     [fp,   x9]              // load the value
        ')
')

// xwriteStruct(value, base, attribute, ignore_fp = true)
define(xwriteStruct, `
        define(`register_type', substr($1, 0, 1))
        define(`register_store', `x10')

        // M4: WRITE STRUCT
        mov     x11,    $2                      // int base
        mov     x12,    $3                      // int attribute offset
        add     x9,     x11,    x12             // int offset = base + attribute
        
        ifelse(register_type, `d', `
                fmov    d10,    $1              // float value
                define(`register_store', `d10')
        ', `
                mov     x10,    $1              // int value
                define(`register_store', `x10')
        ')
        
        ifelse(`$#', `4', `
        str	register_store,    [x9]                    // store the value
        ', `
        str	register_store,    [fp,   x9]              // store the value
        ')
')


// xalloc(size)
define(xalloc, `
        // M4: ALLOC
        add     sp,     sp,     $1              // allocate on SP
')
// xdealloc(size)
define(xdealloc, `
        // M4: DEALLOC
        mov     x9,     $1                      // move to x9
        sub     x9,     xzr,    x9              // negate the size again to positive
        add     sp,     sp,     x9              // dealloc on SP
')


// xfunc()
define(xfunc, `
        // M4: FUNC
        stp     fp,     lr,     [sp, alloc]!            // store FP and LR on stack, and allocate space for local variables
        mov     fp,     sp                              // update FP to current SP
        
        // Save registers
        str 	x19,    [fp, 16]
        str 	x20,    [fp, 24]
        str 	x21,    [fp, 32]
        str 	x22,    [fp, 40]
        str 	x23,    [fp, 48]
        str 	x24,    [fp, 56]
        str 	x25,    [fp, 64]
        str 	x26,    [fp, 72]
        str 	x27,    [fp, 80]
        str 	x28,    [fp, 88]

        // Reset registers to 0
        mov     x19,    0
        mov     x20,    0
        mov     x21,    0
        mov     x22,    0
        mov     x23,    0
        mov     x24,    0
        mov     x25,    0
        mov     x26,    0
        mov     x27,    0
        mov     x28,    0
')

// xret()
define(xret, `
        // M4: RET

        // Restore registers
        ldr 	x19,    [fp, 16]
        ldr 	x20,    [fp, 24]
        ldr 	x21,    [fp, 32]
        ldr 	x22,    [fp, 30]
        ldr 	x23,    [fp, 48]
        ldr 	x24,    [fp, 56]
        ldr 	x25,    [fp, 64]
        ldr 	x26,    [fp, 72]
        ldr 	x27,    [fp, 80]
        ldr 	x28,    [fp, 88]

        ldp     fp,     lr,     [sp], dealloc            // deallocate stack memory
        ret


')

// 

divert