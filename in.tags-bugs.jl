#!/usr/bin/env julia

push!(LOAD_PATH,"/usr/local/rle/var/share3/TIKETS/juice/")
using DebInfo
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
    
    # в этом месте при многопроцессной обработке случаются перезаписи флага, поэтому приняты доп меры:
    nc = Flag.newcontent() # для дополнительной защиты сохраняем данные флага
    Flag.set( bugsfile, nc) || continue # if set return false, then it's mean flag is in work
    fc = Flag.read( bugsfile ) # читаем эти же данные флага из файла
    # если то, что записали не сходится с тем, что прочитали, значит кто-то уже переписал - уходим:
    haskey( nc, "UUID") && (string(nc["UUID"]) == fc["UUID"]) || continue 
    
    try
    cmd = pipeline( tagsfile, `awk -F* '$1=="script" || $1=="img" || $1=="iframe" || $1=="link" '`)
    open(cmd) do rio
        #readline(rio)|>info
        tmpname = File.tmpname( bugsfile)
        open( pipeline(`gzip`, tmpname), "w") do wio
            UrlsBugs.main(rio, wio, urlfield=2, printempty=printempty)
        end
        isfile( tmpname) && mv( tmpname, bugsfile)
    end
    catch e
     info( "$e ", catch_stacktrace() )
    end 
    
    Flag.unset(bugsfile)
    
    statinfo("skipempty:$skipempty, skipready:$skipready, skipemptyready:$skipemptyready, todo:$todo")

end    










