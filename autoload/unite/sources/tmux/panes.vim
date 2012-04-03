" File: panes.vim
" Author: Josiah Gordon <josiahg@gmail.com>
" Description: Tmux pane source for unite
" Last Modified: April 03, 2012
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
    let l:action_type = ''

    " Parse arguments
    if len(a:args) > 0
        let l:socket = a:args[0]
        if len(a:args) > 1
            if type(a:args[1]) ==# 4
                " The type of argument 1 is a dictionary so grab the values out
                " of it.
                let l:source_id = a:args[1].source_id
                let l:action_type = a:args[1].action_type
                let l:split_type = a:args[1].split_type
            elseif len(a:args) > 2
                if a:args[1] > 0
                    let l:range_start = a:args[1]
                else
                    let l:range_start = line(a:args[1])
                endif
                if a:args[2] > 0
                    let l:range_end = a:args[2]
                else
                    let l:range_end = line(a:args[2])
                endif
            else
                if a:args[1] > 0
                    let l:range_start = a:args[1]
                else
                    let l:range_start = line(a:args[1])
                endif
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

" Setup the extra actions. {{{
let s:action_table = {
            \ 'selectpane'    : {
            \   'description' : 'set selected pane as the default pane to send to',
            \   },
            \ 'sendcommand'    : {
            \   'description' : 'send one command to selected pane',
            \   },
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

function! s:action_table.sendcommand.func(candidate) " {{{
    " Send a command to the selected tmux pane.
    " Set the global target pane.
    let g:tmux_pane = a:candidate.pane_id
    call tmux#send_command()
endfunction "}}}

function! s:action_table.selectpane.func(candidate) " {{{
    " Set the global target pane.
    let g:tmux_pane = a:candidate.pane_id
endfunction "}}}

function! s:action_table.send.func(candidate) " {{{
    " Send a range of text from the vim buffer to the selected tmux pane.
    " Set the global target pane.
    let g:tmux_pane = a:candidate.pane_id
    call tmux#send_range(a:candidate.range_start, a:candidate.range_end)
endfunction "}}}

function! s:action_table.break.func(candidate) " {{{
    " Break the selected pane out of its window.
    let l:tmux_cmd = tmux#tmux_cmd(a:candidate.socket)
    call unite#util#system(
                \ l:tmux_cmd . " break-pane -d -t " . a:candidate.pane_id)
endfunction "}}}

function! s:action_table.kill.func(candidate) " {{{
    " Kill the selected pane.
    let l:tmux_cmd = tmux#tmux_cmd(a:candidate.socket)
    call unite#util#system(
                \ l:tmux_cmd . " kill-pane -t " . a:candidate.pane_id)
endfunction "}}}
let s:source.alias_table.delete = 'kill'

function! s:action_table.join.func(candidate) " {{{
    " Join two panes creating a horizontal split in the target pane.
    call unite#print_message("[tmux] Select the target pane")

    " Open unite tmux/panes to select the target pane to split and join.
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
    " Join to panes creating a vertical split in the target pane.
    call unite#print_message("[tmux] Select the target pane")

    " Open unite tmux/panes to select the target pane to split and join to.
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
    " Horizontally split the selected pane
    let l:tmux_cmd = tmux#tmux_cmd(a:candidate.socket)
    call unite#util#system(
                \ l:tmux_cmd . " split-window -d " .
                \ " -t " . a:candidate.pane_id)
endfunction "}}}

function! s:action_table.vsplit.func(candidate) " {{{
    " Split a pain vertically
    let l:tmux_cmd = tmux#tmux_cmd(a:candidate.socket)
    call unite#util#system(
                \ l:tmux_cmd . " split-window -dv " .
                \ " -t " . a:candidate.pane_id)
endfunction "}}}

function! s:action_table.swap.func(candidate) " {{{
    " Swap two panes
    call unite#print_message("[tmux] Select the target pane")

    " Open unite tmux/panes to select the pane to swap with the currently
    " selected one.
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

function! s:get_pane_list(socket) "{{{
    let l:tmux_cmd = tmux#tmux_cmd(a:socket)

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


let &cpo = s:save_cpo
unlet s:save_cpo
