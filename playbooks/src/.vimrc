

set list

" set tab as 4 space$                                                           
set ts=4                                                                   
set expandtab
set hlsearch
set cc=80                                              
highlight Comment ctermfg=darkcyan


autocmd BufWritePre *.py :%s/\s\+$//e
