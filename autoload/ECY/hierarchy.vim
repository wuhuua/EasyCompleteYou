function! ECY#hierarchy#Init() abort
  
endfunction

function! ECY#hierarchy#Start() abort
"{{{
  let l:params = {
                \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'PrepareCallHierarchy', 'params': l:params})
"}}}
endfunction

function! s:Incoming(res) abort
"{{{
  if a:res != {}
    call ECY#rpc#rpc_event#call({'event_name': 'IncomingCalls', 'params': {'item_index': a:res['item_index']}})
  endif
  return 1
"}}}
endfunction

function! s:Outgoing(res) abort
"{{{
  if a:res != {}
    call ECY#rpc#rpc_event#call({'event_name': 'OutgoingCalls', 'params': {'item_index': a:res['item_index']}})
  endif
  return 1
"}}}
endfunction

function! s:Prev(res) abort
"{{{
  call ECY#rpc#rpc_event#call({'event_name': 'RollUpHierarchy', 'params': {}})
  return 1
"}}}
endfunction

function! ECY#hierarchy#Start_res(res) abort
"{{{
  let l:action = {
        \'open#vertically': function('s:Incoming'), 
        \'res#up': function('s:Prev'), 
        \'open#horizontally': function('s:Outgoing')}

  call ECY#qf#Open(a:res, {'action': l:action})
"}}}
endfunction
