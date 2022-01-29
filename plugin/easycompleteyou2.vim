" This is basic vim plugin boilerplate
let s:save_cpo = &cpo
set cpo&vim

let g:ECY_starttime = reltimefloat(reltime())

function! s:restore_cpo()
  let g:loaded_ECY2 = v:true
  let &cpo = s:save_cpo
  unlet s:save_cpo
endfunction

if !exists("g:os")
  if has("win64") || has("win32") || has("win16")
    let g:os = "Windows"
  else
    let g:os = substitute(system('uname'), '\n', '', '')
    if g:os == 'Darwin'
      let g:os = 'macOS'
    else
      let g:os = 'Linux'
    endif
  endif
endif

let g:is_vim = !has('nvim')

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                check require                                "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('g:loaded_ECY2')
  finish
elseif v:version < 800
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires Vim 8.0+." |
        \ echohl None
  call s:restore_cpo()
  finish
elseif &encoding !~? 'utf-\?8'
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires UTF-8 encoding. " .
        \ "Put the line 'set encoding=utf-8' into your vimrc." |
        \ echohl None
  call s:restore_cpo()
  finish
elseif ( g:is_vim && !has('patch-8.1.1491') ) || 
      \ (!g:is_vim && !has('nvim-0.5.0'))
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires NeoVim >= 0.5.0 ".
        \ "or Vim 8.1.1491+." |
        \ echohl None
  call s:restore_cpo()
  finish
elseif !exists( '*json_decode' )
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires with function of json_decode. ".
        \ "You should build Vim with this feature." |
        \ echohl None
  call s:restore_cpo()
  finish
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                 init vars                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ECY_use_floating_windows_to_be_popup_windows = 
      \get(g:, 'ECY_use_floating_windows_to_be_popup_windows', v:true)

if g:is_vim && exists('*nvim_win_set_config') " neovim
  " TODO:
  let g:has_floating_windows_support = 'neovim'
  let g:has_floating_windows_support = 'has_no' 

elseif exists('*popup_create') && 
      \exists('*win_execute') && 
      \exists('*popup_atcursor') && exists('*popup_close')
  let g:has_floating_windows_support = 'vim'
else
  let g:has_floating_windows_support = 'has_no'
  let g:ECY_use_floating_windows_to_be_popup_windows = v:false
endif
let g:has_floating_windows_support = 'vim'
let g:ECY_use_floating_windows_to_be_popup_windows = 1

" must put these outside a function
let g:ECY_base_dir = expand('<sfile>:p:h:h')
let g:ECY_base_dir = tr(g:ECY_base_dir, '\', '/')
let g:ECY_buffer_version = {}
let g:ECY_windows_are_showing = {}
let g:ECY_is_debug = get(g:,'ECY_is_debug', v:false)

let g:ECY_python_script_folder_dir = g:ECY_base_dir . '/python'
let g:ECY_client_main_path = g:ECY_python_script_folder_dir . '/client_main.py'
let g:ECY_source_folder_dir = g:ECY_base_dir . '/engines'
let g:ECY_debug_log_file_path = 
      \get(g:,'ECY_debug_log_file_path', g:ECY_python_script_folder_dir . '/ECY_debug.log')
let g:ECY_client_main_path = printf("%s/ECY_%s.exe", g:ECY_python_script_folder_dir, g:os)

if exists('g:ycm_disable_for_files_larger_than_kb')
  let g:ECY_disable_for_files_larger_than_kb = g:ycm_disable_for_files_larger_than_kb
else
  let g:ECY_disable_for_files_larger_than_kb
        \= get(g:,'ECY_disable_for_files_larger_than_kb', 1024)
endif

let g:ECY_file_type_blacklist
      \= get(g:,'ECY_file_type_blacklist', ['log'])

let g:ECY_preview_windows_size = 
      \get(g:,'ECY_preview_windows_size',[[30, 70], [2, 14]])

if g:has_floating_windows_support == 'vim'
  let i = g:ECY_preview_windows_size[0][1]
  let g:ECY_cut_line = ''
  while i != 0
    let g:ECY_cut_line .= '-'
    let i -= 1
  endw
endif

function! s:Goto(types, is_preview) abort
"{{{
  if a:types == 'definitions' || a:types == 'definition'
    call ECY2_main#Goto('', 'GotoDefinition', a:is_preview)
  elseif a:types == 'declaration'
    call ECY2_main#Goto('', 'GotoDeclaration', a:is_preview)
  elseif a:types == 'implementation'
    call ECY2_main#Goto('', 'GotoImplementation', a:is_preview)
  elseif a:types == 'typeDefinition' || a:types == 'type_definition'
    call ECY2_main#Goto('', 'GotoTypeDefinition', a:is_preview)
  else
    echo a:types
  endif
"}}}
endfunction

function! g:ECYGotoMenu() abort
"{{{
  let content = [
        \ ["&Definition\t", "call ECY2_main#Goto('', 'GotoDefinition', 0)"],
        \ ["De&claration\t", "call ECY2_main#Goto('', 'GotoDeclaration', 0)"],
        \ ["&Implementation\t", "call ECY2_main#Goto('', 'Implementation', 0)"],
        \ ["&TypeDefinition\t", "call ECY2_main#Goto('', 'TypeDefinition', 0)"],
        \ ['-'],
        \ ["Definition Preview\t", "call ECY2_main#Goto('', 'GotoDefinition', 1)"],
        \ ["Declaration Preview\t", "call ECY2_main#Goto('', 'GotoDeclaration', 1)"],
        \ ["Implementation Preview\t", "call ECY2_main#Goto('', 'Implementation', 1)"],
        \ ["TypeDefinition Preview\t", "call ECY2_main#Goto('', 'TypeDefinition', 1)"],
        \ ]
  " set cursor to the last position
  let opts = {'index': g:quickui#context#cursor, 
        \'title': ECY#switch_engine#GetBufferEngineName()}
  call quickui#context#open(content, opts)
"}}}
endfunction

function! s:Menu() abort
"{{{
  let content = [
        \ ["&Hover\t", 'ECYHover' ],
        \ ["&Format\t", 'ECYFormat'],
        \ ["&Rename\t", 'ECYRename' ],
        \ ["&Symbol\t", 'ECYSymbol' ],
        \ ["&FoldLine\t", 'ECYFoldLine'],
        \ ["&DocSymbol\t", 'ECYDocSymbol' ],
        \ ["&Goto\t", 'call g:ECYGotoMenu()'],
        \ ["S&eleteRange\t", 'ECYSeleteRange'],
        \ ]
  " set cursor to the last position
  let opts = {'index': g:quickui#context#cursor, 
        \'title': ECY#switch_engine#GetBufferEngineName()}
  call quickui#context#open(content, opts)
"}}}
endfunction

vmap <C-h> <ESC>:call ECY2_main#DoCodeAction({'range_type': 'selected_range'})<CR>
nmap <C-h> :call ECY2_main#DoCodeAction({'range_type': 'current_line'})<CR>

nmap vae :ECYSeleteRange<CR>
nmap var :ECYSeleteRangeParent<CR>
nmap vat :ECYSeleteRangeChild<CR>

vmap ae <ESC>:ECYSeleteRangeParent<CR>
vmap ar <ESC>:ECYSeleteRangeParent<CR>
vmap at <ESC>:ECYSeleteRangeChild<CR>

command! -nargs=* ECY                  call s:Menu()
command! -nargs=* ECYGoto              call s:Goto(<q-args>, 0)
command! -nargs=* ECYGotoP             call s:Goto(<q-args>, 1)
command! -nargs=0 ECYHover             call ECY2_main#Hover()
command! -nargs=0 ECYFormat            call ECY2_main#Format()
command! -nargs=0 ECYRename            call ECY2_main#Rename()
command! -nargs=0 ECYReStart           call ECY2_main#ReStart()
command! -nargs=* ECYInstallLS         call ECY2_main#InstallLS(<q-args>)
command! -nargs=* ECYUnInstallLS       call ECY2_main#UnInstallLS(<q-args>)
command! -nargs=0 ECYDocSymbol         call ECY2_main#GetDocumentSymbol()
command! -nargs=0 ECYDocSymbols        call ECY2_main#GetDocumentSymbol()
command! -nargs=0 ECYSymbol            call ECY2_main#GetWorkSpaceSymbol()
command! -nargs=0 ECYSymbols           call ECY2_main#GetWorkSpaceSymbol()
command! -nargs=0 ECYSeleteRange       call ECY2_main#SeleteRange()
command! -nargs=0 ECYSeleteRangeParent call ECY#selete_range#Parent()
command! -nargs=0 ECYSeleteRangeChild  call ECY#selete_range#Child()
command! -nargs=0 ECYFoldLine          call ECY2_main#FoldingRangeCurrentLine()
command! -nargs=0 ECYFold              call ECY2_main#FoldingRange()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                     Go                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call easy_windows#init()
call ECY#completion#Init()
call ECY2_main#Init()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                    end                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ECY_endtime = reltimefloat(reltime())
let g:ECY_start_time = g:ECY_endtime - g:ECY_starttime

call s:restore_cpo()
