" File: tmux.vim
" Author: Josiah Gordon <josiahg@gmail.com>
" Description: tmux kind for tmux unite source
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

function! unite#kinds#tmux#define()
    return s:kind
endfunction

let s:kind = {
            \ 'name' : 'tmux',
            \ 'default_action' : 'select',
            \ 'action_table' : {},
            \ 'parents' : ['common'],
            \ 'alias_table' : {},
            \ }

let s:kind.action_table = {
            \ 'switch'  : {
            \   'description' : "Switch to selected session/window/pane",
            \   },
            \ 'select'  : {
            \   'description' : "Select the session/window/pane to act upon",
            \   },
            \ }

function! s:kind.action_table.switch.func(candidate) " {{{
    let l:tmux_cmd = s:tmux_cmd(a:candidate.socket)
    let l:destination = split(a:candidate.word)[0]
    let l:split_dest = split(l:destination, ':')
    let l:session = l:split_dest[0] . ':'
    if a:candidate.type ==# "session" " {{{
        call unite#util#system(l:tmux_cmd . " switch-client -t " . l:destination)
        " }}}
    elseif a:candidate.type ==# "window" " {{{
        let l:window = l:split_dest[1]
        call unite#util#system(l:tmux_cmd . " switch-client -t " . l:session)
        call unite#util#system(l:tmux_cmd . " select-window -t " . l:window)
        " }}}
    elseif a:candidate.type ==# "pane" " {{{
        let l:window_pane = split(l:split_dest[1], '\.')
        let l:window = l:window_pane[0]
        let l:pane = l:window_pane[1]
        call unite#util#system(l:tmux_cmd . " switch-client -t " . l:session)
        call unite#util#system(l:tmux_cmd . " select-window -t " . l:window)
        call unite#util#system(l:tmux_cmd . " select-pane -t " . l:pane)
        " }}}
    endif
endfunction " }}}

function! s:kind.action_table.select.func(candidate) " {{{
    let l:source_id = a:candidate.source_id
    let l:source = a:candidate.source
    let l:action = a:candidate.action_type
    if empty(l:source_id) && l:action !=# 'send-buffer'
        call s:kind.action_table.switch.func(a:candidate)
    else
        let l:tmux_cmd = s:tmux_cmd(a:candidate.socket)
        if l:source ==# 'tmux/sessions' " {{{
            let l:target_id = a:candidate.session_id
            if l:action =~# 'link-window' " {{{
                call unite#util#system(
                            \ l:tmux_cmd . " link-window -d " .
                            \ " -s " . l:source_id .
                            \ " -t " . l:target_id
                            \ )
                " }}}
            elseif l:action =~# 'switch-client' " {{{
                call unite#util#system(
                            \ l:tmux_cmd . " switch-client " .
                            \ " -c " . l:source_id .
                            \ " -t " . l:target_id
                            \ )
                " }}}
            endif " }}}
        elseif l:source ==# 'tmux/windows' " {{{
            let l:target_id = a:candidate.window_id
            if l:action =~# 'move' " {{{
                let l:dest_session = split(l:target_id, ':')[0]
                let l:dest_id = split(l:target_id, ':')[1] + 1
                call unite#util#system(
                            \ l:tmux_cmd . " move-window -d " .
                            \ " -s " . l:source_id .
                            \ " -t " . l:dest_session . ':' . l:dest_id
                            \ )
                " }}}
            elseif l:action =~# 'swap' " {{{
                call unite#util#system(
                            \ l:tmux_cmd . " swap-window -d " .
                            \ " -s " . l:source_id .
                            \ " -t " . l:target_id
                            \ )
            endif " }}}
            " }}}
        elseif l:source ==# 'tmux/panes' " {{{
            let l:target_id = a:candidate.pane_id
            if l:action ==# 'send-buffer' " {{{
                let l:range_start = a:candidate.range_start
                let l:range_end = a:candidate.range_end
                let g:tmux_pane = l:target_id
                execute ":" . l:range_start . "," . l:range_end . "TmuxSend"
                " }}}
            elseif l:action ==# 'join' " {{{
                let l:split_type = a:candidate.split_type
                call unite#util#system(
                            \ l:tmux_cmd . " join-pane -d " .
                            \ l:split_type .
                            \ " -s " . l:source_id .
                            \ " -t " . l:target_id
                            \ )
                " }}}
            elseif l:action ==# 'swap' " {{{
                call unite#util#system(
                            \ l:tmux_cmd . " swap-pane -d " .
                            \ " -s " . l:source_id .
                            \ " -t " . l:target_id
                            \ )
            endif " }}}
        endif " }}}
    endif
endfunction " }}}

function! s:tmux_cmd(socket) " {{{
    " Setup the tmux command to use a different socket if socket is set.
    if empty(a:socket)
        return "tmux"
    else
        return "tmux -L " . a:socket
    endif
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo
