#!/usr/bin/env julia

# на STDIN подать html
# на выход печатает найденный текст

using Gumbo

immutable GMeta  # -- для разных типов будут разные функции награждения звездочками 
 el::Dict{Symbol,Any}
end

immutable GText
 el::Dict{Symbol,Any}
end


function in_html_out_descr_text(io_in::IO, 
			  io_out::IO; 
			    warn_on_exeption::Bool=false,
			    url::AbstractString="", 
			    deb::Bool=false )

deb ? info("==in_html_out_text params: $warn_on_exeption, url=$url, deb=$deb") : nothing

# url можно использвать для определения ссылок на себя


html_content=""
try
 html_content = parsehtml(readstring(io_in));
catch ex
 if warn_on_exeption 
    warn(ex, io_in)
 end    
 return false # дать понять вызывающему коду, что действие не выполнено
end

# ф-я: "есть кириллица в строке?":
has_cyrillic(s) = ismatch(r"[аяоеуюиыАЯОЕУЮЫИ]+?",s)
# есть латинница?
has_latin(s) = ismatch(r"[euoai]+?"i,s)
 
# преобразование HTMLElement{:meta} в словарь:
function tomydict{T<:Gumbo.HTMLElement{:meta}}(el::T)
 GMeta(Dict{Symbol,Any}(
    :gpt=> tag(el.parent.parent)::Symbol,
    :ptg=> tag(el.parent)::Symbol,
    :ats=> Dict(Symbol(k)=>lowercase(v) for (k,v) in attrs(el)), 
    :txt=> "" 
 ))
end


# преобразование Gumbo.HTMLText в словарь:
function tomydict{T<:Gumbo.HTMLText}(el::T)
#info("Found Gumbo.HTMLText: $el")
 GText(Dict{Symbol,Any}( 
     :gpt=> tag(el.parent.parent)::Symbol, # <--grandpa tag
     :ptg=> tag(el.parent)::Symbol, # <--parent tag 
     :ats=> Dict(Symbol(k)=>lowercase(v) for (k,v) in attrs(el.parent)),  # <--attributes of current el :key=>"value"
     :txt=> strip(replace(el.text, "\n", ""),' ') # <--многострочный text - в одну строку
 ))
end

# ---------- за что награждаем звездочками :meta: ------

function setstars(e::GMeta)
 el = e.el::Dict
 ats = el[:ats]::Dict
 
 stars = 0

 #info(el)
 
 if (get(ats, :name, "")=="description") && haskey(ats, :content) && !isempty(ats[:content])
    el[:txt] = el[:txt]*ats[:content]
    stars += 12
 end
 
 if (get(ats, :name, "")=="keywords") && haskey(ats, :content) && !isempty(ats[:content]) && length(ats[:content])<80
    el[:txt] = el[:txt]*ats[:content]
    stars += 15
 end

# if (get(ats, :name, "")=="robots") && haskey(ats, :content) && ismatch(r"none|noindex", ats[:content])
#    # сайт говорит, что не нужно индексировать
#    el[:txt] = el[:txt]*ats[:content]
#    stars = 100 # чтоб поднялось в топ
# end
    
 el[:stars] = stars
 e
end

# ------- за что награждаем звездочками :text: -------

function setstars(e::GText) 
    el = e.el
    deb ? info(e) : nothing # info всего что сюда дошло
    stars=0 # звездочек

    # за has_cyrillic:
    if el[:txt] |> has_cyrillic
	stars+=3
    end

    if el[:txt] |> has_latin
	stars+=2
    end

    
    # за head+title: 
    if el[:ptg] == :title
	stars+=3
	if el[:gpt] == :head
	    stars+=4
	end    
    end

    hdict = Dict(:h1=>8, :h2=>6, :h3=>4)

    if haskey(hdict, el[:gpt]) 
	stars+=hdict[ el[:gpt] ]
    end
    
    if haskey(hdict, el[:ptg])
	stars+=hdict[ el[:ptg] ]
    end
    
    if el[:ptg] == :p
	stars+=3
	if el[:gpt] == :div
	    stars+=3
	end
    end	
    
    if el[:ptg] == :span
	stars+=2
	if el[:gpt] == :p
	    stars+=2
	end
    end	    
    
    
    if el[:ptg] == :a
	let href = get(el[:ats], :href, "")
	    if href=="/" # за a href=/ (указание сайта на свой корень)
		stars += 1  
	    else
		# можно еще проверять href==ur
	    end
	end
    end

    # о посетителе во 2-м лице
    let re = r"Вы\s|\sвы\s|\sты\s|Ты\s|Тебе\s|\sтебе\s|Вас\s|\sвас\s|Вам\s|\sвам\s|Сервис|\sсервис\s|Услуг|услуг",
	m = match(re, el[:txt])
	
	if m!=nothing
	    deb ? info(m) : nothing
	    stars+=1
	end
    end


    # о себе в 3-м лице
    let re = r"Сервис|\sсервис\s|Услуг|услуг",
	m = match(re, el[:txt])
	
	if m!=nothing
	    deb ? info(m) : nothing
	    stars+=1 # но м.б. реклама на сайте
	end
    end


    # о себе в 1-м лице
    let re = r"Мы\s|\sмы\s|Я\s|\sя\s",
	m = match(re, el[:txt])
	if m!=nothing
	    deb ? info(m) : nothing
	    stars+=1
	end
    end

    
    el[:stars] = stars # награждение

    e # возврат измененного елемента
end
# --------------------------------------------------

 
filtered = filter(preorder(html_content.root)) do el
    #info("Found Gumbo.HTMLText in filter: $el")
    typeof(el)<:Gumbo.HTMLText || typeof(el)<:Gumbo.HTMLElement{:meta}  # перечисляем типы, которые возьмем
 end |> 
 ee->map(tomydict, ee) #|> dump |> error
 # на выходе список из Dict 
 # ( :gpt=>:grandpatag, :ptg=>:parenttag, :ats=>{:k=>"v"}, :txt=>text)

clearedtext = filter(filtered) do e
    e.el[:ptg] != :script
 end |>
 ee->map(setstars, ee) |> # -- награждение звездочками
 ee->filter(ee) do e
	( !isempty(e.el[:txt]) &&
	    e.el[:stars]>2 #|| 
		#has_cyrillic(e.el[:txt])
	)
    	 # -- что после награждения оставляем
 end |>
 ee->map(ee) do e
    # для сортировки преобразуем елемент в тюпл:
    ats = join([ "$k=$v" for (k,v) in e.el[:ats] ],",")
    (e.el[:stars], e.el[:gpt], e.el[:ptg], ats, e.el[:txt])
 end |>
 ee->sort!(ee)|>reverse |> # больше звездочек - первые
 ee->take(ee,5) |> # -- сколько первых строк взять
 ee->map(e->join(e,"*"),ee) |>
 ll->join(ll,"\n")
 
deb ? info("text cleared") : nothing

println(io_out, clearedtext)
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
    
    in_html_out_descr_text(STDIN,STDOUT,url=url,deb=deb)
end
    
    

