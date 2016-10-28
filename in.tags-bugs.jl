#!/usr/bin/env julia

push!(LOAD_PATH,"/usr/local/rle/var/share3/TIKETS/juice/")
using Jbase
import File
import Sh
include("./in-urls-out-bugs.jl")
using UrlsBugs

deb = false # debug на stderr
statist = false # отображать статистику на stderr
recalc_bugs = false # пересчитывать ли *.bugs файлы
printempty = false # печатать ли строки tags для которых не нашлось bugs (для отладки)

# параметры deb,stat,recalc - включают соответствующую установку:
if length(filter( arg->ismatch(r"deb",arg), ARGS)) > 0
    deb = true
end

if length(filter( arg->ismatch(r"stat",arg), ARGS)) > 0
    statist = true
end

if length(filter( arg->ismatch(r"recalc-bugs",arg), ARGS)) > 0
    recalc_bugs = true
end

if length(filter( arg->ismatch(r"printempty",arg), ARGS)) > 0
    printempty = true
end


debinfo = debinfofun(deb) # debug on
statinfo = debinfofun(statist)

# На STDIN подать имена *.tags файлов
# ( создает соответствующие *.bugs файлы )

skipempty=0;
skipready=0; 
skipemptyready=0;
todo=0;
    
for tagsfile in eachline(STDIN)

    tagsfile = chomp(tagsfile)

    if filesize(tagsfile)==0
	skipempty = skipempty+1
	continue
    end


    bugsfile = replace(tagsfile, r"\.tags",".bugs")
    if bugsfile==tagsfile
	error("bugsfile == tagsfile ($tagsfile)")
    end	

    if File.goodsize(bugsfile) && !recalc_bugs 
	skipready = skipready+1
	continue 
    end

    if isfile(bugsfile) && !recalc_bugs
	skipemptyready = skipemptyready+1
    end	

    
    if File.iswait(bugsfile) 
        continue
    end

    debinfo("Todo: $bugsfile")
    todo = todo+1
    
    Flag.set(bugsfile)
    
    withopen( Sh.c("cat $tagsfile | awk -F* '\$1==\"script\" || \$1==\"img\" || \$1==\"iframe\" || \$1==\"link\" '"), Sh.viatmp(bugsfile)) do rio,wio
	UrlsBugs.main(rio, wio, urlfield=2, printempty=printempty)
    end
    
    Flag.unset(bugsfile)
    
    statinfo("skipempty:$skipempty, skipready:$skipready, skipemptyready:$skipemptyready, todo:$todo")

end    










