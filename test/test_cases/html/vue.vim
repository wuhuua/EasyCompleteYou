let g:ECY_is_debug = 1
let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h:h')
let g:ECY_debug_log_file_path = expand('<sfile>') . '.ECY_log'
let g:log_file = expand('<sfile>') . '.log'
exe printf('so %s/test/startup.vim', g:repo_root)

let g:test_cpp = fnamemodify(expand('<sfile>'), ':h') . '/test.vue'

function! s:T1() abort
    call OutputLine(g:test_cpp)
    call ECY#engine#Set('vue', 'ECY_engines.html.vls')
    call ECY2_main#InstallLS('ECY_engines.html.vls')
endfunction

function! s:T2() abort
    call ECY#utils#OpenFileAndMove(12, 18, g:test_cpp, 'h')
    call OutputLine(ECY#utils#GetCurrentBufferContent())
    call OutputLine(ECY#utils#GetCurrentLine())
    let &ft = 'vue'
endfunction

function! s:T3() abort
    call Type("\<Esc>a")
endfunction

function! s:T4() abort
    call Type("\<Tab>")
endfunction

function! s:T5() abort
    call Expect(getline(12), '      this.hello_world;')
endfunction

function! s:T6() abort
endfunction

function! s:T7() abort
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1'), 'delay': 25000},
            \{'fuc': function('s:T2')},
            \{'fuc': function('s:T3'), 'delay': 20000},
            \{'fuc': function('s:T4')},
            \]})

call test_frame#Run()
