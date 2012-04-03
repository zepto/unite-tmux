" File: tmux.vim
" Author: Josiah Gordon <josiahg@gmail.com>
" Description: Tmux source for unite to control tmux.
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

function! unite#sources#tmux#define() " {{{
    let l:sources = []
    for source_cmd in s:get_commands()
        let source = call('unite#sources#tmux#' . source_cmd . '#define', [])
        if type(source) == 4
            call add(l:sources, source)
        elseif type(source) == 3
            call extend(l:sources, source)
        endif
        unlet source
    endfor
    return add(l:sources, s:source)
endfunction " }}}

let s:source = {
            \ 'name' : 'tmux',
            \ 'description' : 'tmux sources',
            \ }

function! s:source.gather_candidates(args, context) "{{{
    " Create the list of tmux sources [clients, panes, servers, windows]
    call unite#print_message('[tmux] tmux sources')
    return map(s:get_commands(), '{
                \ "word" : v:val,
                \ "source" : s:source.name,
                \ "kind" : "source",
                \ "action__source_name" : "tmux/" . v:val,
                \ }')
endfunction "}}}

function! s:get_commands() " {{{
    " Return a list of vimscripts in the tmux directory
    return map(
                \ split(
                \   globpath(&runtimepath, 'autoload/unite/sources/tmux/*.vim'),
                \   '\n'
                \ ),
                \ 'fnamemodify(v:val, ":t:r")'
                \ )
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
