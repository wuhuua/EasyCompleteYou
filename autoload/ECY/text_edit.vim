let s:fixendofline_exists = exists('+fixendofline')

function! ECY#text_edit#apply(uri, text_edits) abort
    let l:current_bufname = bufname('%')
    let l:target_bufname = UriToPath(a:uri)
    let l:cursor_position = s:GetPostion()

    call s:_switch(l:target_bufname)
    for l:text_edit in s:_normalize(a:text_edits)
        call s:_apply(bufnr(l:target_bufname), l:text_edit, l:cursor_position)
    endfor
    call s:_switch(l:current_bufname)

    if bufnr(l:current_bufname) == bufnr(l:target_bufname)
        call cursor(ECY#utils#LSPPositionToVimPostion('%', l:cursor_position))
    endif
endfunction

function! s:GetPostion(...) abort
    let l:line = line('.')
    let l:char = s:ToChar('%', l:line, col('.'))
    return { 'line': l:line - 1, 'character': l:char }
endfunction

function! s:ToChar(expr, lnum, col) abort
    let l:lines = getbufline(a:expr, a:lnum)
    if l:lines == []
        if type(a:expr) != v:t_string || !filereadable(a:expr)
            " invalid a:expr
            return a:col - 1
        endif
        " a:expr is a file that is not yet loaded as a buffer
        let l:lines = readfile(a:expr, '', a:lnum)
    endif
    let l:linestr = l:lines[-1]
    return strchars(strpart(l:linestr, 0, a:col - 1))
endfunction

" @summary Use this to convert textedit to vim list that is compatible with
" quickfix and locllist items
" @param uri = DocumentUri
" @param text_edit = TextEdit | TextEdit[]
" @returns []
function! ECY#text_edit#LSPToVimList(uri, text_edit) abort
    let l:result = []
    let l:cache = {}
    if type(a:text_edit) == type([]) " TextEdit[]
        for l:text_edit in a:text_edit
            let l:vim_loc = s:lsp_text_edit_item_to_vim(a:uri, l:text_edit, l:cache)
            if !empty(l:vim_loc)
                call add(l:result, l:vim_loc)
            endif
        endfor
    else " TextEdit
        let l:vim_loc = s:lsp_text_edit_item_to_vim(a:uri, a:text_edit, l:cache)
        if !empty(l:vim_loc)
            call add(l:result, l:vim_loc)
        endif
    endif
    return l:result
endfunction

function! s:ISFileURI(uri) abort
    return stridx(a:uri, 'file:///') == 0
endfunction

" @param uri = DocumentUri
" @param text_edit = TextEdit
" @param cache = {} empty dict
" @returns {
"   'filename',
"   'lnum',
"   'col',
"   'text',
" }
function! s:lsp_text_edit_item_to_vim(uri, text_edit, cache) abort
    if !s:ISFileURI(a:uri)
        return v:null
    endif

    let l:path = UriToPath(a:uri)
    let l:range = a:text_edit['range']
    let [l:line, l:col] = ECY#utils#LSPPositionToVimPostion(l:path, l:range['start'])

    let l:index = l:line - 1
    if has_key(a:cache, l:path)
        let l:text = a:cache[l:path][l:index]
    else
        let l:contents = getbufline(l:path, 1, '$')
        if !empty(l:contents)
            let l:text = get(l:contents, l:index, '')
        else
            let l:contents = readfile(l:path)
            let a:cache[l:path] = l:contents
            let l:text = get(l:contents, l:index, '')
        endif
    endif

    return {
        \ 'filename': l:path,
        \ 'lnum': l:line,
        \ 'col': l:col,
        \ 'text': l:text
        \ }
endfunction

"
" _apply
"
function! s:_apply(bufnr, text_edit, cursor_position) abort
    " create before/after line.
    let l:start_line = getline(a:text_edit['range']['start']['line'] + 1)
    let l:end_line = getline(a:text_edit['range']['end']['line'] + 1)
    let l:before_line = strcharpart(l:start_line, 0, a:text_edit['range']['start']['character'])
    let l:after_line = strcharpart(l:end_line, a:text_edit['range']['end']['character'], strchars(l:end_line) - a:text_edit['range']['end']['character'])

    " create new lines.
    let l:new_lines = s:SplitByEOL(a:text_edit['newText'])
    let l:new_lines[0] = l:before_line . l:new_lines[0]
    let l:new_lines[-1] = l:new_lines[-1] . l:after_line

  " save length.
    let l:new_lines_len = len(l:new_lines)
    let l:range_len = (a:text_edit['range']['end']['line'] - a:text_edit['range']['start']['line']) + 1

    " fixendofline
    let l:buffer_length = len(getbufline(a:bufnr, '^', '$'))
    let l:should_fixendofline = s:GetFixeddoline(a:bufnr)
    let l:should_fixendofline = l:should_fixendofline && l:new_lines[-1] ==# ''
    let l:should_fixendofline = l:should_fixendofline && l:buffer_length <= a:text_edit['range']['end']['line']
    let l:should_fixendofline = l:should_fixendofline && a:text_edit['range']['end']['character'] == 0
    if l:should_fixendofline
        call remove(l:new_lines, -1)
    endif

    " fix cursor pos
    if a:text_edit['range']['end']['line'] < a:cursor_position['line']
        " fix cursor line
        let a:cursor_position['line'] += l:new_lines_len - l:range_len
    elseif a:text_edit['range']['end']['line'] == a:cursor_position['line'] && a:text_edit['range']['end']['character'] <= a:cursor_position['character']
        " fix cursor line and col
        let a:cursor_position['line'] += l:new_lines_len - l:range_len
        let l:end_character = strchars(l:new_lines[-1]) - strchars(l:after_line)
        let l:end_offset = a:cursor_position['character'] - a:text_edit['range']['end']['character']
        let a:cursor_position['character'] = l:end_character + l:end_offset
    endif

    " append or delete lines.
    if l:new_lines_len > l:range_len
        call append(a:text_edit['range']['start']['line'], repeat([''], l:new_lines_len - l:range_len))
    elseif l:new_lines_len < l:range_len
        let l:offset = l:range_len - l:new_lines_len
        call s:delete(a:bufnr, a:text_edit['range']['start']['line'] + 1, a:text_edit['range']['start']['line'] + l:offset)
    endif

    " set lines.
    call setline(a:text_edit['range']['start']['line'] + 1, l:new_lines)
endfunction

"
" _normalize
"
function! s:_normalize(text_edits) abort
  let l:text_edits = type(a:text_edits) == type([]) ? a:text_edits : [a:text_edits]
  let l:text_edits = filter(copy(l:text_edits), { _, text_edit -> type(text_edit) == type({}) })
  let l:text_edits = s:_range(l:text_edits)
  let l:text_edits = sort(copy(l:text_edits), function('s:_compare', [], {}))
  let l:text_edits = s:_check(l:text_edits)
  return reverse(l:text_edits)
endfunction

"
" _range
"
function! s:_range(text_edits) abort
  for l:text_edit in a:text_edits
    if l:text_edit.range.start.line > l:text_edit.range.end.line || (
          \   l:text_edit.range.start.line == l:text_edit.range.end.line &&
          \   l:text_edit.range.start.character > l:text_edit.range.end.character
          \ )
      let l:text_edit.range = { 'start': l:text_edit.range.end, 'end': l:text_edit.range.start }
    endif
  endfor
  return a:text_edits
endfunction

"
" _check
"
" LSP Spec says `multiple text edits can not overlap those ranges`.
" This function check it. But does not throw error.
"
function! s:_check(text_edits) abort
  if len(a:text_edits) > 1
    let l:range = a:text_edits[0].range
    for l:text_edit in a:text_edits[1 : -1]
      if l:range.end.line > l:text_edit.range.start.line || (
      \   l:range.end.line == l:text_edit.range.start.line &&
      \   l:range.end.character > l:text_edit.range.start.character
      \ )
      endif
      let l:range = l:text_edit.range
    endfor
  endif
  return a:text_edits
endfunction

"
" _compare
"
function! s:_compare(text_edit1, text_edit2) abort
  let l:diff = a:text_edit1.range.start.line - a:text_edit2.range.start.line
  if l:diff == 0
    return a:text_edit1.range.start.character - a:text_edit2.range.start.character
  endif
  return l:diff
endfunction

"
" _switch
"
function! s:_switch(path) abort
  if bufnr(a:path) >= 0
    execute printf('keepalt keepjumps %sbuffer!', bufnr(a:path))
  else
    execute printf('keepalt keepjumps edit! %s', fnameescape(a:path))
  endif
endfunction

"
" delete
"
function! s:delete(bufnr, start, end) abort
  if exists('*deletebufline')
      call deletebufline(a:bufnr, a:start, a:end)
  else
      let l:foldenable = &foldenable
      setlocal nofoldenable
      execute printf('%s,%sdelete _', a:start, a:end)
      let &foldenable = l:foldenable
  endif
endfunction

function! s:SplitByEOL(text) abort
    return split(a:text, '\r\n\|\r\|\n', v:true)
endfunction

function! s:get_fixendofline(buf) abort
    let l:eol = getbufvar(a:buf, '&endofline')
    let l:binary = getbufvar(a:buf, '&binary')

    if s:fixendofline_exists
        let l:fixeol = getbufvar(a:buf, '&fixendofline')

        if !l:binary
            " When 'binary' is off and 'fixeol' is on, 'endofline' is not used
            "
            " When 'binary' is off and 'fixeol' is off, 'endofline' is used to
            " remember the presence of a <EOL>
            return l:fixeol || l:eol
        else
            " When 'binary' is on, the value of 'fixeol' doesn't matter
            return l:eol
        endif
    else
        " When 'binary' is off the value of 'endofline' is not used
        "
        " When 'binary' is on 'endofline' is used to remember the presence of
        " a <EOL>
        return !l:binary || l:eol
    endif
endfunction

function! s:GetFixeddoline(bufnr) abort
    return s:get_fixendofline(a:bufnr)
endfunction