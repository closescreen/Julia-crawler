#!/usr/bin/env julia
# на STDIN подать html
# на выход печатает найденный текст

using Gumbo
import It # -- from juice
include("./main.text.functions.jl")

function in_html_out_main_text(io_in::IO, 
			  io_out::IO; 
			    warn_on_exeption::Bool=false,
			    url::AbstractString="", 
			    deb::Bool=false )

deb ? info("==in_html_out_text params: $warn_on_exeption, url=$url, deb=$deb") : nothing


html_content=""
try
 html_content = parsehtml(readstring(io_in));
catch ex
 if warn_on_exeption 
    warn(ex, io_in)
 end
 return false # дать понять вызывающему коду, что действие не выполнено
end




elements = html_content.root |> preorder |> group_HTMLText  
 # на выходе список, сгруппированный по группам [массив из GText]
	# все, что в одной группе - рассматривается как куски текста из одного большого фрагмента

# звезды за заголовок:
function get_headerstars(tt) #массив из HTMLText -> Pair(star=>HTMLText)
 map(tt) do t
    if hasparent(:head, t) && hasparent(:title,t)  
      (9=>t.text)
    elseif    hasparent(:h1,t)     
      (10=>t.text)
    elseif    hasparent(:h2,t)     
      (8=>t.text)
    elseif    hasparent(:h3,t)     
      (7=>t.text)
    else   
      (0=>"")
    end
 end |> sort |> reverse |> tt->isempty(tt)? (0=>""): first(tt)                              
end


function settstars(origtt::Array) # на входе массив  HTMLText 
 rv = Dict(:textstars => 0, :alltext=>"", :headerstars=>0, :htext=>"" )

 tt = origtt|>unique # повторяющиеся убираем

 headerstars_pair::Pair = filter(t->hasparent(:head, t),tt) |> tt->get_headerstars(tt)

 if headerstars_pair[1]>0
    rv[:headerstars], rv[:htext] = headerstars_pair
 end

 bodytt = filter(t->hasparent(:body, t),tt)
 rv[:alltext] = bodytt |> tt->join(map(t->replace(t.text,r"\s+"," "), tt), " ") 
 
 # звезды за кол-во слов без ссылок:
 wordstars = filter(t->!inlink(t), bodytt) |> tt->map(t->t.text, tt) |> tt->join(tt," ") |> words|>length
 rv[:textstars] = wordstars # + smth 

 # штрафы:
 penalti = matchall(r"[\:\;/\\\{\}\~\`\@\#\$\%\^\&\*\(\)\+\=\_\[\]\>\<\!\?\.]", rv[:alltext] )|>length
 rv[:textstars] -= penalti
 
 # доп штраф за ссылки:
 link_penalti = filter(t->inlink(t), bodytt) |> length #tt->map(t->t.text, tt) |> tt->join(tt," ") |> t->split(t,r"\s+") |>length
 rv[:textstars] -= link_penalti

 
 rv # - на выходе словарь
end 


starred_elements = map(settstars, elements) |>
    ee->filter(ee) do e
	e[:headerstars]>0 || e[:textstars]>0
    end


max_headerstars = map(e->e[:headerstars], starred_elements)|>ss->isempty(ss)? 0: maximum(ss)
#info("max_headerstars: $max_headerstars")
minlevel_headers = 2

title = filter(starred_elements) do e
 hs = e[:headerstars]
 hs==max_headerstars && hs>=minlevel_headers
end |> ee->map(e->(e[:headerstars], e[:htext]),ee)

max_textstars = map(e->e[:textstars], starred_elements)|>ss->isempty(ss)? 0: maximum(ss)
minlevel = max(round(Int, max_textstars/5), 10)

maintext =  filter(e->e[:textstars]>=minlevel, starred_elements) |> ee->map(e->(e[:textstars], e[:alltext]), ee)

map((title, maintext)) do ee 
    map(ee) do e
        join(e,"*")
    end |>
    ll->join(ll,"\n")
end |>
 tt->join(tt,"\n") |> 
 t->println(io_out,t)        
    

 
#deb ? info("text cleared") : nothing

#println(io_out, clearedtext)

return true # все ок, функция отработала
end # in_html_out_text





# ------------------------------------------------------


# ------ run in command-line mode: must have --run first param ----
if length(ARGS)>0 && ismatch(r"run", ARGS[1])
    deb=false
    if length(filter( arg->ismatch(r"deb",arg), ARGS)) > 0
	deb = true
    end

    url=""
    if (r=filter( arg->ismatch(r"url=.+",arg), ARGS))|>length > 0
	if (m=match(r"url=(?P<url>.+)",r[1])) != nothing
	    deb ? info("== url parameter = ",m[:url]) : ""
	    url = m[:url]
	end    
    end    
    
    in_html_out_main_text(STDIN,STDOUT,url=url,deb=deb)
end
    
    

