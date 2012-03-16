" File: windows.vim
" Author: Josiah Gordon <josiahg@gmail.com>
" Description: tmux window source for unite
" Last Modified: March 16, 2012
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

function! unite#sources#tmux#windows#define() " {{{
    return s:source
endfunction " }}}

let s:source = {
            \ 'name' : 'tmux/windows',
            \ 'description' : 'tmux windows on this server',
            \ 'action_table': {},
            \ 'default_action': {'tmux': 'select'},
            \ 'alias_table' : {},
            \ }

function! s:source.gather_candidates(args, context)"{{{
    let candidates = []
    " The default socket will be the current one.
    let l:socket = ''
    let l:action_type = 'switch'
    let l:source_id = ''
    " Set the socket to what the user specified.
    if len(a:args) > 0
        let l:socket = a:args[0]
        if len(a:args) > 2
            let l:source_id = a:args[1]
            let l:action_type = a:args[2]
        endif
    endif

    " Build the window list for unite to display.
    for window in s:get_window_list(l:socket)
        if window.id ==# l:source_id
            continue
        endif
        call add(candidates, {
            \ 'word' : window['name'],
            \ 'kind' : 'tmux',
            \ 'type' : 'window',
            \ 'socket' : l:socket,
            \ 'source': s:source.name,
            \ 'window_id' : window['id'],
            \ 'source_id' : l:source_id,
            \ 'action_type' : l:action_type,
            \ })
    endfor
    return candidates
endfunction"}}}

" Setup the extra actions. {{{
let s:action_table = {
            \ 'new'    : {
            \   'description' : 'Create a new window after this one',
            \   },
            \ 'move'    : {
            \   'description' : 'Move window to a destination',
            \   },
            \ 'link'    : {
            \   'description' : 'Link window to another session',
            \   },
            \ 'unlink'    : {
            \   'description' : 'Un-link window from session',
            \   },
            \ 'swap'    : {
            \   'description' : 'Swap two windows',
            \   },
            \ 'kill'    : {
            \   'description' : 'Kill selected window',
            \   },
            \ }
let s:source.action_table.tmux = s:action_table
" }}}

function! s:action_table.new.func(candidate) " {{{
    let l:tmux_cmd = tmux#tmux_cmd(a:candidate.socket)
    call unite#util#system(l:tmux_cmd . " new-window -ad " .
                \ " -t " . a:candidate.window_id
                \ )
endfunction "}}}

function! s:action_table.move.func(candidate) " {{{
    call unite#print_message("[tmux] Select the target window")
    call unite#start([[
                \ 'tmux/windows',
                \ a:candidate.socket,
                \ a:candidate.window_id,
                \ 'move',
                \ ]])
endfunction "}}}

function! s:action_table.swap.func(candidate) " {{{
    call unite#print_message("[tmux] Select the target window")
    call unite#start([[
                \ 'tmux/windows',
                \ a:candidate.socket,
                \ a:candidate.window_id,
                \ 'swap',
                \ ]])
endfunction "}}}

function! s:action_table.kill.func(candidate) " {{{
    let l:tmux_cmd = tmux#tmux_cmd(a:candidate.socket)
    call unite#util#system(l:tmux_cmd . " kill-window " .
                \ " -t " . a:candidate.window_id
                \ )
endfunction "}}}
let s:source.alias_table.delete = 'kill'

function! s:action_table.link.func(candidate) " {{{
    call unite#print_message("[tmux] Select the target window")
    call unite#start([[
                \ 'tmux/sessions', 
                \ a:candidate.socket,
                \ a:candidate.window_id,
                \ 'link-window',
                \ ]])
endfunction "}}}

function! s:action_table.unlink.func(candidate) " {{{
    let l:tmux_cmd = tmux#tmux_cmd(a:candidate.socket)
    call unite#util#system(l:tmux_cmd . " unlink-window " .
                \ " -t " . a:candidate.window_id
                \ )
endfunction "}}}

function! s:get_window_list(socket) "{{{
    " Setup the tmux command to use a different socket if socket is set.
    let l:tmux_cmd = tmux#tmux_cmd(a:socket)

    " Get a list of the window on the server.
    let temp_list = unite#util#system(
                \ l:tmux_cmd . " list-windows -a")

    let window_list = []
    for window in split(temp_list, '\n')
        " Build the window list.
        call add(window_list, {
                    \ 'name': window,
                    \ 'id': substitute(split(window)[0], ':$', '', 'g'),
                    \ })
    endfor
    return window_list
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo
