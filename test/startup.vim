function! OutputLine(msg) abort
  let g:log_info .= string(a:msg) . "\n"
  call writefile(split(g:log_info, "\n"), g:log_file, 'b')
endfunction

function! Expect(value, expected) abort
  if a:value != a:expected
    call OutputLine('Failded')
    call OutputLine(printf('Extended: "%s"', a:expected))
    call OutputLine(printf('Actual: "%s"', a:value))
    throw "Wrong case."
  endif
endfunction

function! QuitVim() abort
  call OutputLine('test ok.')
  qall!
endfunction

function! Type(keys) abort
    call feedkeys(a:keys, 'i')
endfunction

function! AddLine(str)
  put! =a:str
endfunction

function AddRTP(path) abort
  if isdirectory(a:path)
    let path = substitute(a:path, '\\\+', '/', 'g')
    let path = substitute(path, '/$', '', 'g')
    let &runtimepath = escape(path, '\,') . ',' . &runtimepath
    let after = path . '/after'
    if isdirectory(after)
      let &runtimepath .= ',' . after
    endif
  endif
endfunction

function SoPath(path) abort
  exe 'source ' . a:path
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                    init                                    "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h')
let g:log_info = ''
" call SoPath(printf('%s/test/plug.vim', g:repo_root))
call AddRTP(g:repo_root)
call SoPath(printf('%s/plugin/easycompleteyou2.vim', g:repo_root))

set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8
scriptencoding utf-8

call OutputLine(g:repo_root)
call SoPath(printf('%s/test/test_frame.vim', g:repo_root))
