#!/usr/bin/env julia

module UrlsBugs

"Returns patterns-host+path dictionary" 
function php() 
    rv = Dict{AbstractString,Array{AbstractString,1}}()
#    for l in open(`cat "patterns-host_path.ghostery.txt"`) |> t->t[1] |> eachline
    # используются все файлы в текущей директории с именем по шаблону:
    for l in open(`bash -c "cat patterns-host_path.*.txt"`) |> t->t[1] |> eachline

        rec = split(chomp(l),'\*')
        get!(rv, join(rec[1:2],"/"), rec[3:end])
    end
    rv
end

"Returns patterns-host dictionary" 
function ph() 
    rv = Dict{AbstractString,Array{AbstractString,1}}()
#    for l in open(`cat "patterns-host.ghostery.txt"`) |> t->t[1] |> eachline
    # используются все файлы в текущей директории с именем по шаблону:
    for l in open(`bash -c "cat patterns-host.*.txt"`) |> t->t[1] |> eachline

        rec = split(chomp(l),'\*')
        get!(rv, rec[1], rec[3:end])
    end
    rv
end

"Returns patterns-path dictionary" 
function pp() 
    rv = Dict{AbstractString,Array{AbstractString,1}}()
    # используются все файлы в текущей директории с именем по шаблону:
    for l in open(`bash -c "cat patterns-path.*.txt"`) |> t->t[1] |> eachline
        rec = split(chomp(l),'\*')
        get!(rv, rec[2], rec[3:end])
    end
    rv
end

"Returns patterns-regex dictionary" 
function pr() 
    rv = Dict{AbstractString,Array{AbstractString,1}}()
#    for l in open(`cat "patterns-regex.ghostery.txt"`) |> t->t[1] |> eachline
    # используются все файлы в текущей директории с именем по шаблону:
    for l in open(`bash -c "cat patterns-regex.*.txt"`) |> t->t[1] |> eachline
        rec = split(chomp(l),'\t')
        get!(rv, rec[1], rec[2:end])
    end
    rv
end

"""
Ключи словаря должны быть ::Regex
Сопоставляет каждый ключ словаря dict с данной строкой key и возвращает первое значение словаря, 
 которое как регулярка подошло к key, иначе - возвращает default
"""
function getmatch(arr, key::AbstractString, default)
 for rv in arr
  if ismatch(rv[1], key)
   return rv[2]
  end 
 end
 return default 
end
#----------------------


php1 = php() # "trumba.com/scripts/spuds.js" => AbstractString["Trumba","widget"] 
php2 = ( [Regex(k), v] for (k,v) in php1 )::Base.Generator

ph1 = ph()   # "adcode.adengage.com" => AbstractString["AdEngage","ad"] 
ph2 = ( [Regex(k), v] for (k,v) in ph1 )::Base.Generator

pp1 = pp()   # "/image.ng/" => AbstractString["DoubleClick DART","ad"]

pr1 = pr()   # "ucoz\\.(.*)\\/(stat|main)\\/" => AbstractString["uCoz","tracker"]
pr2 = ( [Regex(k), v] for (k,v) in pr1 )::Base.Generator

#----------------------
function main(io_in::IO, io_out::IO; printempty=true, urlfield=1)
 # на STDIN подать строки с url dom/path
 
 lead_fields =  urlfield==1 ? ln::Array->"" :
                urlfield==2 ? ln::Array->ln[1] :
                ln::Array->join(ln[1:(urlfield-1)], '*')

 
 for rl in io_in |> eachline
  ln = chomp(rl) # [something1*]dom1/path1[*something2]
  ln_array = split(ln,'*')
  dom_path = ln_array[urlfield] # if raised error, then "urlfield" is wrong.  
  dom_path_array = split( dom_path, '/', limit=2 )
  dom = dom_path_array[1]
  path = length(dom_path_array)==2 ? dom_path_array[2] : ""
  
 
  # словарь с ключами host/path:
  php_desc = get(php1, dom_path, nothing) # поиск в словаре patterns-host-path по строке dom_path (значение - массив строк описания)
  if php_desc!=nothing
   println(io_out, join([lead_fields(ln_array); dom_path; php_desc], '*'))
   continue
  else # если точного совпадения по ключу не было
   # ищем по ключам этого же словаря, как по регекспам
   php_desc2 = getmatch(php2, dom_path, nothing) 
   if php_desc2!=nothing
    println(io_out, join([lead_fields(ln_array); dom_path; php_desc2], '*'))
    continue
   end
  end

#----enable:
  # словарь с ключами host:
  ph_desc = get(ph1, dom, nothing)
  if ph_desc!=nothing
   println(io_out, join([lead_fields(ln_array); dom; ph_desc], '*'))
   continue
  else # нет совпадения по ключам
   # ищем по ключам этого же словаря, как по регекспам
   #info("Note: enabled getmatch by ph")
   ph_desc2 = getmatch(ph2, dom, nothing) 
   if ph_desc2!=nothing
    println(io_out, join([lead_fields(ln_array); dom; ph_desc2], '*'))
    continue
   end    
  end

# --uncomment:
  pp_desc = get(pp1, path, nothing)
  if pp_desc!=nothing
   println(io_out, join([lead_fields(ln_array); path; pp_desc], '*'))
   continue
  end

# ---uncomment:
  pr_desc = getmatch(pr2, dom_path, nothing)
  if pr_desc!=nothing
   println(io_out, join([lead_fields(ln_array); dom_path; pr_desc], '*'))
   continue
  end
 
  # если не найдено - печатаем исходный урл с пустым результатом:
  if printempty
    println(io_out, join([lead_fields(ln_array),dom_path,"",""],"*"))
  end    
 end # for  
end

end # -- of module --


# --------------------- main ----------------------------------------------------
# "Запуск main если запущено с аргументами"
if length(ARGS)>0 && ismatch(r"run",ARGS[1])
 printempty = ismatch(r"printempty",get(ARGS,2,""))
 if (m=match(r"urlfield=(?P<urlfield>\d+)",get(ARGS,3,""))) != nothing
    urlfield = m[:urlfield]
    urlfield = parse(Int,urlfield)
 else
    urlfield = 1    
 end  
 UrlsBugs.main(STDIN,STDOUT,printempty=printempty,urlfield=urlfield)
else
 ##info("With no params - do nothing")
end
#



