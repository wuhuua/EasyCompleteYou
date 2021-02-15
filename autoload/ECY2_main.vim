fun! ECY2_main#Init()
"{{{
  " test
  call rpc_main#NewClient('python C:/Users/qwer/Desktop/vimrc/myproject/ECY/RPC/EasyCompleteYou/python/client_main.py')
"}}}
endf

fun! ECY2_main#DoCmd(cmd_name, param_list)
"{{{

  let l:params = {
                \'buffer_path': utils#GetCurrentBufferPath(), 
                \'buffer_line': utils#GetCurrentLine(), 
                \'buffer_position': utils#GetCurrentLineAndPosition(), 
                \'buffer_content': utils#GetCurrentBufferContent(), 
                \'param_list': a:param_list,
                \'cmd_name': a:cmd_name,
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'DoCmd', 'params': l:params})
"}}}
endf

fun! ECY2_main#GetCodeLens()
"{{{
  let l:params = {
                \'buffer_path': utils#GetCurrentBufferPath(), 
                \'buffer_line': utils#GetCurrentLine(), 
                \'buffer_position': utils#GetCurrentLineAndPosition(), 
                \'buffer_content': utils#GetCurrentBufferContent(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'GetCodeLens', 'params': l:params})
"}}}
endf

fun! ECY2_main#GetWorkSpaceSymbol()
"{{{
  let l:params = {}

  call ECY#rpc#rpc_event#call({'event_name': 'OnWorkSpaceSymbol', 'params': l:params})
"}}}
endf

fun! ECY2_main#DoCodeAction()
"{{{

  let l:params = {
                \'buffer_path': utils#GetCurrentBufferPath(), 
                \'buffer_line': utils#GetCurrentLine(), 
                \'buffer_position': utils#GetCurrentLineAndPosition(), 
                \'buffer_content': utils#GetCurrentBufferContent(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'DoCodeAction', 'params': l:params})
"}}}
endf

fun! ECY2_main#IsWorkAtCurrentBuffer()
"{{{
  if exists( 'b:ECY_is_work_at_current_buffer' )
    return b:ECY_is_work_at_current_buffer
  endif

  let l:file_type = &filetype
  for item in g:ECY_file_type_blacklist
    if l:file_type =~ item
      return v:false
    endif
  endfor

  let l:threshold = g:ECY_disable_for_files_larger_than_kb * 1024

  let b:ECY_is_work_at_current_buffer =
        \ l:threshold > 0 && getfsize(utils#GetCurrentBufferPath()) > l:threshold

  if b:ECY_is_work_at_current_buffer
    " only echo once because this will only check once
    call utils#echo("ECY unavailable: the file exceeded the max size.")
  endif

  let b:ECY_is_work_at_current_buffer = !b:ECY_is_work_at_current_buffer

  return b:ECY_is_work_at_current_buffer
"}}}
endf
