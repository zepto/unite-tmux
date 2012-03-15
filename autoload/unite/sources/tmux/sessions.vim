" File: sessions.vim
" Author: Josiah Gordon <josiahg@gmail.com>
" Description: Sessions actions source for unite
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

function! unite#sources#tmux#sessions#define() " {{{
    return s:source
endfunction " }}}

let s:source = {
            \ 'name' : 'tmux/sessions',
            \ 'description' : 'tmux sessions on this server',
            \ 'action_table': {},
            \ 'default_action': {'tmux': 'select'},
            \ 'alias_table' : {},
            \ }

function! s:source.gather_candidates(args, context)"{{{
    let candidates = []
    " The default socket will be the current one.
    let l:socket = ''
    let l:source_id = ''
    let l:action_type = 'switch'
    " Set the socket and range to what the user specified.
    if len(a:args) > 0
        let l:socket = a:args[0]
        if len(a:args) > 2
            let l:source_id = a:args[1]
            let l:action_type = a:args[2]
        endif
    endif

    " Build the session list for unite to display.
    for session in s:get_session_list(l:socket)
        if session.id ==# l:source_id
            continue
        endif
        call add(candidates, {
            \ 'word' : session['name'],
            \ 'kind' : 'tmux',
            \ 'type' : 'session',
            \ 'socket' : l:socket,
            \ 'source': s:source.name,
            \ 'session_id' : session['id'],
            \ 'source_id' : l:source_id,
            \ 'action_type' : l:action_type,
            \ })
    endfor
    return candidates
endfunction"}}}

" Setup the extra actions. {{{
let s:action_table = {
            \ 'new'    : {
            \   'description' : 'Create a new session',
            \   },
            \ 'linknew'    : {
            \   'description' : 'Create a new session linked with this one',
            \   },
            \ 'kill'    : {
            \   'description' : 'Kill selected session',
            \   },
            \ 'detach'    : {
            \   'description' : 'Detach all clients attached to this session',
            \   },
            \ 'lock'    : {
            \   'description' : 'Lock session',
            \   },
            \ }
let s:source.action_table.tmux = s:action_table
" }}}

function! s:action_table.linknew.func(candidate) " {{{
    let l:tmux_cmd = s:tmux_cmd(a:candidate.socket)
    call unite#util#system(l:tmux_cmd . " new-session -d " .
                \ " -t " . a:candidate.session_id
                \ )
endfunction "}}}

function! s:action_table.new.func(candidate) " {{{
    let l:tmux_cmd = s:tmux_cmd(a:candidate.socket)
    call unite#util#system(l:tmux_cmd . " new-session -d ")
endfunction "}}}

function! s:action_table.kill.func(candidate) " {{{
    let l:tmux_cmd = s:tmux_cmd(a:candidate.socket)
    call unite#util#system(l:tmux_cmd . " kill-session " .
                \ " -t " . a:candidate.session_id
                \ )
endfunction "}}}
let s:source.alias_table.delete = 'kill'

function! s:action_table.detach.func(candidate) " {{{
    let l:tmux_cmd = s:tmux_cmd(a:candidate.socket)
    call unite#util#system(l:tmux_cmd . " detach-client " .
                \ "-s " . a:candidate.session_id
                \ )
endfunction "}}}

function! s:action_table.lock.func(candidate) " {{{
    let l:tmux_cmd = s:tmux_cmd(a:candidate.socket)
    call unite#util#system(l:tmux_cmd . " lock-session " .
                \ " -t " . a:candidate.session_id
                \ )
endfunction "}}}

function! s:get_session_list(socket) "{{{
    let l:tmux_cmd = s:tmux_cmd(a:socket)

    " Get a list of the sessions on the server.
    let temp_list = unite#util#system(
                \ l:tmux_cmd . " list-sessions")

    let session_list = []
    for session in split(temp_list, '\n')
        " Build the session list.
        call add(session_list, {
                    \ 'name': session,
                    \ 'id': split(session)[0]
                    \ })
    endfor
    return session_list
endfunction "}}}

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
