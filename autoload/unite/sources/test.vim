"=============================================================================
" FILE: tab.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: March 08, 2012
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditionso
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#test#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'test',
      \ 'action_table': {},
      \ 'default_action': {'common': 'send'},
      \ 'description' : 'candidates from tmux pane list',
      \}

let s:tmux_cmd = "tmux"
let g:tmux_pane = ''

function! g:do_stuff(candidate)
    echomsg a:candidate
endfunction

command! DoStuff call <SID>do_stuff

function! s:source.gather_candidates(args, context)"{{{
    let candidates = []
    " The default socket will be the current one.
    let l:socket = ''
    " Make the default range be the current line.
    let l:range_start = line(".")
    let l:range_end = line(".")
    " Set the socket and range to what the user specified.
    if len(a:args) > 0
        let l:socket = a:args[0]
        if len(a:args) > 2
            let l:range_start = line(a:args[1])
            let l:range_end = line(a:args[2])
        else
            let l:range_start = line(a:args[1])
            let l:range_end = line("$")
        endif
    endif

    " Build the pane list for unite to display.
    for pane in s:get_pane_list(l:socket)
        call add(candidates, {
            \ 'word' : pane['name'],
            \ 'kind' : 'common',
            \ 'source': 'tmux',
            \ 'range_start': l:range_start,
            \ 'range_end': l:range_end,
            \ 'pane_id' : pane['id']
            \ })
            " \ 'action__command' : ":call g:do_stuff(".'"'.pane.'"'.")"
            " \ })
    endfor
    return candidates
endfunction"}}}

" Setup the default action to send.
let s:action_table = {}
let s:action_table.send = {
            \ 'description': 'send buffer selection to selected pane',
            \ }
let s:source.action_table.common = s:action_table

function! s:action_table.send.func(candidate) " {{{
    " Set the global target pane.
    let g:tmux_pane = a:candidate.pane_id
    call <SID>TmuxSendRange(a:candidate.range_start, a:candidate.range_end)
endfunction "}}}

function! s:get_pane_list(socket) "{{{
    " Setup the tmux command to use a different socket if socket is set.
    if empty(a:socket)
        let s:tmux_cmd = "tmux"
    else
        let s:tmux_cmd = "tmux -L " . a:socket
    endif

    " Tmux list-panes format string.
    let l:format = '"#{pane_id} #{session_name}:#{window_index}.#{line}: [#{pane_width}x#{pane_height}] [#{window_name}] #{?pane_active,(active),}"'

    " Get a list of the panes on the server.
    let temp_list = vimproc#system(s:tmux_cmd . " list-panes -a -F " . l:format)

    let pane_list = []
    for pane in split(temp_list, '\n')
        " Build the pane list.
        call add(pane_list, {
                    \ 'name': pane,
                    \ 'id': split(pane)[0]
                    \ })
    endfor
    return pane_list
endfunction "}}}

function! s:TmuxSendRange(range_start, range_end) " {{{
    " Send the specified range to g:tmux_pane
    for curline in range(a:range_start, a:range_end)
        let strline = getline(curline)
        " Only send the buffer if the line was not empty.
        if !empty(strline)
            call vimproc#system(
                        \ s:tmux_cmd . " set-buffer " . shellescape(strline))
            call vimproc#system(
                        \ s:tmux_cmd . " paste-buffer -d -t " . g:tmux_pane)
        endif
        " Always send a newline.
        call vimproc#system(s:tmux_cmd . " send-keys -t " . g:tmux_pane . " C-M")
    endfor
endfunction " }}}

command! -nargs=0 -range TmuxSend call <SID>TmuxSendRange(<line1>,<line2>)


let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
