" File: panes.vim
" Author: Josiah Gordon <josiahg@gmail.com>
" Description: Tmux pane source for unite
" Last Modified: March 09, 2012
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

let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#tmux#panes#define() " {{{
    return s:source
endfunction " }}}

let s:source = {
            \ 'name' : 'tmux/panes',
            \ 'description' : 'tmux panes on this server',
            \ 'action_table': {},
            \ 'default_action': {'tmux': 'select'},
            \ 'alias_table' : {},
            \ }

let g:tmux_pane = ''
let s:socket = ''

function! s:source.gather_candidates(args, context)"{{{
    let candidates = []
    " The default socket will be the current one.
    let l:socket = ''
    " Make the default range be the current line.
    let l:range_start = line(".")
    let l:range_end = line(".")

    let l:source_id = ''
    " The default split type will be horizontal.
    let l:split_type = '-h'
    let l:action_type = 'send-buffer'

    " Parse arguments
    if len(a:args) > 0
        let l:socket = a:args[0]
        if len(a:args) > 1
            if type(a:args[1]) ==# 4
                let l:source_id = a:args[1].source_id
                let l:action_type = a:args[1].action_type
                let l:split_type = a:args[1].split_type
            elseif len(a:args) > 2
                let l:range_start = line(a:args[1])
                let l:range_end = line(a:args[2])
            else
                let l:range_start = line(a:args[1])
                let l:range_end = line("$")
            endif
        endif
    endif

    " Build the pane list for unite to display.
    for pane in s:get_pane_list(l:socket)
        if pane.id ==# l:source_id
            continue
        endif
        call add(candidates, {
            \ 'word' : pane['name'],
            \ 'kind' : 'tmux',
            \ 'type' : 'pane',
            \ 'socket' : l:socket,
            \ 'source': s:source.name,
            \ 'range_start': l:range_start,
            \ 'range_end': l:range_end,
            \ 'pane_id' : pane['id'],
            \ 'source_id' : l:source_id,
            \ 'split_type' : l:split_type,
            \ 'action_type' : l:action_type,
            \ })
    endfor
    return candidates
endfunction"}}}

function! s:get_pane_list(socket) "{{{
    let l:tmux_cmd = s:tmux_cmd(a:socket)

    " Tmux list-panes format string.
    let l:format = '"#{session_name}:#{window_index}.#{line}: [#{pane_width}x#{pane_height}] [#{window_name}] #{?pane_active,(active),} #{pane_id}"'

    " Get a list of the panes on the server.
    let temp_list = unite#util#system(
                \ l:tmux_cmd . " list-panes -a -F " . l:format)

    let pane_list = []
    for pane in split(temp_list, '\n')
        " Build the pane list.
        call add(pane_list, {
                    \ 'name': pane,
                    \ 'id': split(pane)[-1]
                    \ })
    endfor
    return pane_list
endfunction "}}}

" Setup the extra actions. {{{
let s:action_table = {
            \ 'send'    : {
            \   'description' : 'send buffer selection to selected pane',
            \   },
            \ 'break'   : {
            \   'description' : 'break the selected pane into its own window',
            \   },
            \ 'kill'   : {
            \   'description' : 'kill the selected pane',
            \   },
            \ 'join'    : {
            \   'description' : 'join the selected pane into another pane with a horizontal split',
            \   },
            \ 'vjoin'    : {
            \   'description' : 'join the selected pane into another pane with a vertical split',
            \   },
            \ 'swap'    : {
            \   'description' : 'swap two panes',
            \   },
            \ 'split'    : {
            \   'description' : 'split pane horizontaly',
            \   },
            \ 'vsplit'    : {
            \   'description' : 'split pane verticaly',
            \   },
            \ }
let s:source.action_table.tmux = s:action_table
" }}}

function! s:action_table.send.func(candidate) " {{{
    " Set the global target pane.
    let g:tmux_pane = a:candidate.pane_id
    call <SID>TmuxSendRange(a:candidate.range_start, a:candidate.range_end)
endfunction "}}}

function! s:action_table.break.func(candidate) " {{{
    let l:tmux_cmd = s:tmux_cmd(a:candidate.socket)
    call unite#util#system(
                \ l:tmux_cmd . " break-pane -d -t " . a:candidate.pane_id)
endfunction "}}}

function! s:action_table.kill.func(candidate) " {{{
    let l:tmux_cmd = s:tmux_cmd(a:candidate.socket)
    call unite#util#system(
                \ l:tmux_cmd . " kill-pane -t " . a:candidate.pane_id)
endfunction "}}}
let s:source.alias_table.delete = 'kill'

function! s:action_table.join.func(candidate) " {{{
    call unite#print_message("[tmux] Select the target pane")
    call unite#start([[
                \ 'tmux/panes', 
                \ a:candidate.socket,
                \ {
                \   'source_id' : a:candidate.pane_id,
                \   'action_type' : 'join',
                \   'split_type' : '-h',
                \ },
                \ ]])
endfunction "}}}

function! s:action_table.vjoin.func(candidate) " {{{
    call unite#print_message("[tmux] Select the target pane")
    call unite#start([[
                \ 'tmux/panes', 
                \ a:candidate.socket,
                \ {
                \   'source_id' : a:candidate.pane_id,
                \   'action_type' : 'join',
                \   'split_type' : '-v',
                \ },
                \ ]])
endfunction "}}}

function! s:action_table.split.func(candidate) " {{{
    let l:tmux_cmd = s:tmux_cmd(a:candidate.socket)
    call unite#util#system(
                \ l:tmux_cmd . " split-window -d " .
                \ " -t " . a:candidate.pane_id)
endfunction "}}}

function! s:action_table.vsplit.func(candidate) " {{{
    let l:tmux_cmd = s:tmux_cmd(a:candidate.socket)
    call unite#util#system(
                \ l:tmux_cmd . " split-window -dv " .
                \ " -t " . a:candidate.pane_id)
endfunction "}}}

function! s:action_table.swap.func(candidate) " {{{
    call unite#print_message("[tmux] Select the target pane")
    call unite#start([[
                \ 'tmux/panes',
                \ a:candidate.socket,
                \ {
                \   'source_id' : a:candidate.pane_id,
                \   'action_type' : 'swap',
                \   'split_type' : '-h',
                \ },
                \ ]])
endfunction "}}}

function! s:TmuxSendRange(range_start, range_end) " {{{
    let l:tmux_cmd = s:tmux_cmd(s:socket)
    " Send the specified range to g:tmux_pane
    for curline in range(a:range_start, a:range_end)
        let strline = getline(curline)
        " Only send the buffer if the line was not empty.
        if !empty(strline)
            call unite#util#system(
                        \ l:tmux_cmd . " set-buffer " . shellescape(strline))
            call unite#util#system(
                        \ l:tmux_cmd . " paste-buffer -d -t " . g:tmux_pane)
        endif
        " Always send a newline.
        call unite#util#system(
                    \ l:tmux_cmd . " send-keys -t " . g:tmux_pane . " C-M")
    endfor
endfunction " }}}

function! s:tmux_cmd(socket) " {{{
    let s:socket = a:socket
    " Setup the tmux command to use a different socket if socket is set.
    if empty(a:socket)
        return "tmux"
    else
        return "tmux -L " . a:socket
    endif
endfunction " }}}

command! -nargs=0 -range TmuxSend call <SID>TmuxSendRange(<line1>,<line2>)


let &cpo = s:save_cpo
unlet s:save_cpo
