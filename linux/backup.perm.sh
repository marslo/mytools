# credit: https://unix.stackexchange.com/a/128499/29178
find . -printf '%m\t%u\t%g\t%p\n' > file.perm.txt
