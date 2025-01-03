let g:ECY_is_debug = 1
let g:ECY_debug_log_file_path = expand('<sfile>') . '.ECY_log'

let g:log_file = expand('<sfile>') . '.log'
let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h:h')
exe printf('so %s/test/startup.vim', g:repo_root)


let g:test_cpp = fnamemodify(expand('<sfile>'), ':h') . '/test.py'

function! s:T1() abort
    call OutputLine(g:test_cpp)
    call ECY#engine#Set('python', 'ECY_engines.python.jedi_ls')
    call ECY#utils#OpenFileAndMove(13, 7, g:test_cpp, 'h')
    let &ft = 'python'
    call OutputLine(ECY#utils#GetCurrentBufferContent())
endfunction

function! s:T2() abort
    call Type("\<Esc>a")
endfunction

function! s:T3() abort
    call Type("\<Tab>")
endfunction

function! s:T4() abort
    call Expect(getline(13), 'obj.test_name  # test_name')
endfunction

function! s:T5() abort
endfunction

function! s:T6() abort
endfunction

function! s:T7() abort
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1')}, 
            \{'fuc': function('s:T2'), 'delay': 10000}, 
            \{'fuc': function('s:T3')},
            \{'fuc': function('s:T4')},
            \{'fuc': function('s:T5')},
            \]})

call test_frame#Run()
