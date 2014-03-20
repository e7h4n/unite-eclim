"=============================================================================
" FILE: eclim.vim
" AUTHOR:  perfectworks <perfectworks@gmail.com>
" Last Modified: Aug 30, 2013.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
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

function! unite#sources#eclim#define() "{{{
  return s:source_eclim
endfunction"}}}

let s:source_eclim = {
      \ 'name' : 'eclim',
      \ 'description' : 'candidates from eclim locate list',
      \ 'default_kind' : 'file'
      \}

let s:command_locate = '-command locate_file -s "<scope>"'

function! s:LocateFileCommand(pattern) " {{{
  return s:command_locate . ' -i -p "' . a:pattern . '"'
endfunction " }}}

function! s:LocateFileConvertPattern(pattern, fuzzy) " {{{
  let pattern = a:pattern

  if a:fuzzy
    let pattern = '.*' . substitute(pattern, '\(.\)', '\1.*?', 'g')
    let pattern = substitute(pattern, '\.\([^*]\)', '\\.\1', 'g')
  else
    " if the user supplied a path, prepend a '.*/' to it so that they don't need
    " to type full paths to match.
    if pattern =~ '.\+/'
      let pattern = '.*/' . pattern
    endif
    let pattern = substitute(pattern, '\*\*', '.*', 'g')
    let pattern = substitute(pattern, '\(^\|\([^.]\)\)\*', '\1[^/]*?', 'g')
    let pattern = substitute(pattern, '\.\([^*]\)', '\\.\1', 'g')
    "let pattern = substitute(pattern, '\([^*]\)?', '\1.', 'g')
    let pattern .= '.*'
  endif

  return pattern
endfunction " }}}

function! s:source_eclim.change_candidates(args, context) "{{{
  if !exists(':PingEclim')
      return []
  endif

  if !eclim#PingEclim(0)
      return []
  endif

  let instance = eclim#client#nailgun#ChooseEclimdInstance()

  if type(instance) != g:DICT_TYPE
      return []
  endif

  let workspace = instance.workspace

  let input = a:context.input
  let input = s:LocateFileConvertPattern(input, 0)
  let input = '[^/]*' . input

  let command = substitute(s:LocateFileCommand(input), '<scope>', 'workspace', '')
  let results = eclim#Execute(command, {'workspace': workspace})
  if empty(results)
    return []
  endif

  let candidates = []

  for result in results
    call add(candidates, {
          \ 'word' : result.path,
          \ 'action__path': result.path
          \})
  endfor

  return candidates
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
