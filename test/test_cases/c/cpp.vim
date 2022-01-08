let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h:h')
let g:log_file = expand('<sfile>') . '.log'
exe printf('so %s/test/startup.vim', g:repo_root)



function! s:T1() abort
    call Expect(g:ECY_installer_config, {})
    call ECY2_main#InstallLS('ECY_engines.cpp.clangd.clangd')
endfunction

function! s:T2() abort
    new
    let &ft = 'c'
    call ECY#switch_engine#InitDefaultEngine(&ft)
    let g:ECY_file_type_info2[&ft]['filetype_using'] = 'ECY_engines.cpp.clangd.clangd'
    call Type("\<Esc>i123\n13")
endfunction

function! s:T3() abort
endfunction

function! s:T4() abort
endfunction

function! s:T5() abort
endfunction

function! s:T6() abort
endfunction

function! s:T7() abort
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1'), 'delay': 35000}, 
            \{'fuc': function('s:T2')}, 
            \{'fuc': function('s:T3')},
            \{'fuc': function('s:T4')},
            \{'fuc': function('s:T5')},
            \{'fuc': function('s:T6')},
            \{'fuc': function('s:T7')},
            \]})

call test_frame#Run()
