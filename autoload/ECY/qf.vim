fun! ECY#qf#Init()
"{{{
  let g:ECY_qf_layout_style = 'button'
  let g:ECY_qf_layout = [float2nr(&columns * 0.5), &lines]
  let g:ECY_qf_res = []
  let g:ECY_qf_res_external = []
  let s:fz_res = []
  let g:ECY_action_map = {
        \'open#current_buffer': "\<Cr>", 
        \'open#new_tab': "\<C-t>",
        \'open#vertically': "\<C-v>",
        \'open#horizontally': "\<C-x>",
        \'select#next': "\<C-j>",
        \'select#prev': "\<C-k>",
        \}

  let s:default_action_fuc = {
        \'open#current_buffer': function('s:Open_current_buffer'),
        \'open#new_tab': function('s:Open_new_tab'),
        \'open#vertically': function('s:Open_vertically'),
        \'open#horizontally': function('s:Open_horizontally'),
        \'select#next': function('s:NextItem'),
        \'select#prev': function('s:PrevItem'),
        \}

  let g:ECY_action_fuc = deepcopy(s:default_action_fuc)

  let s:selecting_item_index = 0
  let s:MAX_TO_SHOW = 18

  let s:qf_preview = easy_windows#new()
"}}}
endf

function! s:GetRes() abort
"{{{
  let l:res = {}
  if s:selecting_item_index < len(s:fz_res)
    let l:res = s:fz_res[s:selecting_item_index]
  endif
  return l:res
"}}}
endfunction

function! s:Gerneral(CB) abort
"{{{
  return a:CB(s:GetRes())
"}}}
endfunction

"{{{actions
function! ECY#qf#OpenBuffer(res, windows_style) abort
"{{{
  if has_key(a:res, 'path')
    let l:pos = {}
    if has_key(a:res, 'range')
      let l:pos['line'] = a:res['range']['start']['line'] + 1
      let l:pos['colum'] = a:res['range']['start']['character']
    elseif has_key(a:res, 'position')
    endif
    if l:pos == {}
      call ECY#utils#OpenFile(a:res['path'], a:windows_style)
    else
      call ECY#utils#OpenFileAndMove(l:pos['line'],
            \l:pos['colum'], 
            \a:res['path'], a:windows_style)
    endif
  endif
  return 1
"}}}
endfunction

function! s:Open_current_buffer(res) abort
"{{{
  return ECY#qf#OpenBuffer(a:res, '')
"}}}
endfunction

function! s:Open_vertically(res) abort
"{{{
  return ECY#qf#OpenBuffer(a:res, 'v')
"}}}
endfunction

function! s:Open_horizontally(res) abort
"{{{
  return ECY#qf#OpenBuffer(a:res, 'h')
"}}}
endfunction

function! s:Open_new_tab(res) abort
"{{{
  return ECY#qf#OpenBuffer(a:res, 't')
"}}}
endfunction

fun! s:NextItem(...) abort
  let s:selecting_item_index += 1
  let s:selecting_item_index %= (s:MAX_TO_SHOW - 1)
endf

fun! s:PrevItem(...) abort
  let s:selecting_item_index -= 1
  let s:selecting_item_index %= (s:MAX_TO_SHOW - 1)
endf

"}}}

"{{{FuzzyMatch
fun! s:FindFirstChar(strs, char) abort
  let i = 0
  while i < len(a:strs)
    if a:strs[i] == a:char
      return i
    endif
    let i += 1
  endw
  return -1
endf

func s:SortCompare(i1, i2)
  if a:i1['goal'] >= a:i2['goal']
    return 1
  endif
  return -1
endfunc

function! ECY#qf#FuzzyMatch(items, patten, filter_item) abort
"{{{
  let l:res = []
  for item in a:items
    if !has_key(item, a:filter_item)
      continue
    endif

    let l:abbr = ''
    for item2 in item['abbr']
      let l:abbr .= item2['value'] . ' '
    endfor

    let l:abbr_len = len(l:abbr)
    if l:abbr_len < len(a:patten) || l:abbr_len == 0
      continue
    endif

    let i = 0
    let j = 0
    let l:goal = 0
    let l:match_pos = []
    let l:is_matched = v:true
    while i < len(a:patten)
      if j == l:abbr_len
        let l:is_matched = v:false
        break
      endif
      let l:temp = s:FindFirstChar(l:abbr[j:], a:patten[i])
      if l:temp == -1
        let l:is_matched = v:false
        break
      endif
      let j += l:temp
      call add(l:match_pos, j)
      let i += 1
      let j += 1
      let l:goal += j
    endw

    let item['match_pos'] = l:match_pos
    let item['goal'] = l:goal
    if l:is_matched
      call add(l:res, item)
    endif
  endfor
  return sort(l:res, function('s:SortCompare'))
"}}}
endfunction"}}}

fun! s:UpdateRes(input_value) abort
  let s:fz_res = ECY#qf#FuzzyMatch(g:ECY_qf_res, a:input_value, 'abbr')
  call s:RenderRes(s:fz_res)
  call s:UpdatePreview()
endf

fun! s:UpdatePreview() abort
"{{{
  let l:res = s:GetRes()
  call s:qf_preview._close()
  if l:res != {} && has_key(l:res, 'path')
    let l:path = l:res['path']
    let l:content = ECY#utils#GetPathContent(l:path)
    if l:content == []
      return
    endif

    let s:qf_preview = easy_windows#new()
    call s:qf_preview._open(l:content, {'x': g:ECY_qf_layout[0] + 1, 'y': 1, 
          \'height': g:ECY_qf_layout[1],
          \'width': g:ECY_qf_layout[0] - 3,
          \'use_border': 1})
    if has_key(l:res, 'position')
      call s:qf_preview._set_firstline(l:res['position']['line'])
    endif
  endif
"}}}
endf

fun! s:RenderRes(fz_res) abort
"{{{
  let l:MATCH_HL = 'Search'
  let l:to_show = []
  if len(a:fz_res) <= s:selecting_item_index || s:selecting_item_index < 0
    let s:selecting_item_index = 0
  endif
  call s:qf_res._delete_match(l:MATCH_HL)
  call s:qf_res._delete_match('Error')

  let l:max_len = {}

  let i = 0
  for item in a:fz_res
    if i == s:MAX_TO_SHOW
      break
    endif

    let j = 0
    for item2 in item['abbr']
      let l:value_len = len(item2['value'])
      if !has_key(l:max_len, j)
        let l:max_len[j] = l:value_len
      endif

      if l:max_len[j] < l:value_len
        let l:max_len[j] = l:value_len
      endif

      let j += 1
    endfor

    let i += 1
  endfor

  let i = 0
  for item in a:fz_res
    if i == s:MAX_TO_SHOW
      break
    endif
    let l:prev_mark = '  '
    if i == s:selecting_item_index
      let l:prev_mark = '> '
    endif

    let l:temp = ''
    let j = 0
    for item2 in item['abbr']
      let l:diff = l:max_len[j] - len(item2['value']) + 1
      let l:temp .= item2['value']
      let k = 0
      while k < l:diff
        let l:temp .= ' '
        let k += 1
      endw
      let j += 1
    endfor

    call add(l:to_show, l:prev_mark . l:temp)
    let i += 1
  endfor
  call s:qf_res._set_text(l:to_show)

  let i = 0
  for item in a:fz_res
    if i == s:MAX_TO_SHOW
      break
    endif

    if !has_key(item, 'match_pos')
      continue
    endif
    
    for pos in item['match_pos']
      call s:qf_res._add_match(l:MATCH_HL, [[i + 1, pos + 3]])
    endfor
    let i += 1
  endfor

  if len(a:fz_res) == 0
    call s:qf_res._set_text(['Empty Result.'])
    call s:qf_res._add_match('Error', [[1]])
  endif
"}}}
endf

fun! ECY#qf#Close() abort
  call s:qf_res._close()
  call s:qf_preview._close()
  return 1
endf

function! Input(opts) abort
"{{{
   let l:input = ''
   let l:key_map = has_key(a:opts, 'key_map') ? a:opts['key_map'] : {}

   while 1
      redraw
      echohl Constant
      echon '>> '
      echohl Normal
      echon l:input

      let l:char_nr = getchar()
      let l:char = nr2char(l:char_nr)
      if  l:char_nr == "\<BS>"
         let l:char = "\<BS>"
      endif

      if l:char == "\<BS>"
         let l:value_len = len(l:input)
         if l:value_len > 1
           let l:input = l:input[0 : l:value_len - 2]
         else
           let l:input = ''
         endif
      elseif l:char == "\<C-u>"
         let l:input = ''
      elseif has_key(l:key_map, l:char) && has_key(l:key_map[l:char], 'callback')
         let l:res = l:key_map[l:char]['callback']()
         if l:res == 1
           break
         endif
      elseif l:char == "\<ESC>"
         break
      else
         let l:input .= l:char
      endif

      if has_key(a:opts, 'input_cb')
         call a:opts['input_cb'](l:input)
      endif
   endw

   if has_key(a:opts, 'exit_cb')
      call a:opts['exit_cb']()
   endif
"}}}
endfunction

fun! s:ECYQF(lists, opts) abort
"{{{
  let s:selecting_item_index = 0
  let s:qf_res = easy_windows#new()
  call s:qf_res._open([], {'at_cursor': 0, 
        \'width': &columns,
        \'height': 10,
        \'x': 1,
        \'y': &lines - 10,
        \'use_border': 0})

  let g:ECY_qf_res = a:lists
  let s:fz_res = g:ECY_qf_res
  call s:RenderRes(g:ECY_qf_res)

  let l:temp_map = {}
  for item in keys(g:ECY_action_map)
    let l:temp = {}
    if has_key(a:opts, 'key_map') && has_key(a:opts['key_map'], item)
      let l:temp['callback'] = function('s:Gerneral', [a:opts['key_map'][item]])
    else
      let l:temp['callback'] = function('s:Gerneral', [g:ECY_action_fuc[item]])
    endif
    let l:temp_map[g:ECY_action_map[item]] = l:temp
  endfor

  call Input({'input_cb': function('s:UpdateRes'), 
        \'exit_cb': function('ECY#qf#Close'),
        \'key_map': l:temp_map,
        \'use_border': 0})
"}}}
endf

function! s:Open_cb(lists, opts, timer_id) abort
"{{{
  let g:ECY_qf_res = a:lists

  let g:ECY_action_fuc = deepcopy(s:default_action_fuc)
  if has_key(a:opts, 'action')
    for item in keys(a:opts['action'])
      let g:ECY_action_fuc[item] = a:opts['action'][item]
    endfor
  endif

  if exists('g:leaderf_loaded')
    call s:ECYQF(g:ECY_qf_res, a:opts)
    " call g:LeaderfECY_Start()
  elseif exists('g:loaded_clap')
    execute "Clap ECY"
  else
    call s:ECYQF(g:ECY_qf_res, a:opts)
  endif
"}}}
endfunction

fun! ECY#qf#Open(lists, opts) abort
  call timer_start(1, function('s:Open_cb', [a:lists, a:opts]))
endf

call ECY#qf#Init()
