" File: tmux.vim
" Author: Josiah Gordon <josiahg@gmail.com>
" Description: Tmux plugin to send buffers and commands to tmux panes.
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

" tmux#select_pane: Start unite tmux/panes to select a pane. " {{{
function! tmux#select_pane()
    Unite -buffer-name=tmux -default-action=selectpane tmux/panes
endfunction " }}}

" tmux#send_range: Send a range of text to g:tmux_pane. " {{{
function! tmux#send_range(range_start, range_end)
    if empty(g:tmux_pane)
        exe "Unite -buffer-name=tmux -default-action=send tmux/panes::".a:range_start.":".a:range_end
        return
    endif

    " Get the tmux command to use.
    let l:tmux_cmd = tmux#tmux_cmd(g:tmux_socket)

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

" tmux#set_command: Set g:command_to_send to input. " {{{
function! tmux#set_command()
    let g:command_to_send = input("Command to send: ", "", "file")
endfunction " }}}

" tmux#send_command: Send command to g:tmux_pane " {{{
function! tmux#send_command()
    if empty(g:tmux_pane)
        Unite -buffer-name=tmux -default-action=sendcommand tmux/panes
        return
    endif

    " Get the tmux command to use.
    let l:tmux_cmd = tmux#tmux_cmd(g:tmux_socket)

    " Get the command to send if there is none.
    if !exists("g:command_to_send")
        call tmux#set_command()
    endif

    " Put the command in a tmux buffer.
    call unite#util#system(l:tmux_cmd . " set-buffer " .
                \ shellescape(g:command_to_send)
                \ )
    " Paste and delete the buffer into the selected pane.
    call unite#util#system(l:tmux_cmd . " paste-buffer -dt " . g:tmux_pane)
    " Always send a newline.
    call unite#util#system(l:tmux_cmd . " send-keys -t " . g:tmux_pane . " C-M")
endfunction " }}}

" tmux#tmux_cmd: Return the tmux command. " {{{
function! tmux#tmux_cmd(...)
    " Setup the tmux command to use a different socket if socket is set.
    if empty(a:000) || a:000 ==# ['']
        return "tmux"
    else
        let g:tmux_socket = a:1
        return "tmux -L " . g:tmux_socket
    endif
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
