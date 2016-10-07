#!/usr/bin/env julia

# на STDIN подать html
# на выход печатает найденные теги
# (см. в конце файла код запуска)

using Gumbo


function in_html_out_tags(io_in::IO, 
			io_out::IO; 
			    warn_on_exeption::Bool=false,
			    root::AbstractString="", 
			    deb::Bool=false	)
#deb пока не используется
deb ? info("==in_html_out_tags params: $warn_on_exeption, $root, $deb") : nothing
# root - корневой адрес , напр. http://dom.ru 
#  используется, если есть, для определения внутренняя_ли? абсолютная ссылка
#  если абсолютная ссылка содержит $root, значит - внутренняя

html_content=""
try
 html_content = parsehtml(readstring(io_in));
catch ex
 if warn_on_exeption 
    warn(ex, io_in)
 end    
 return false # дать понять вызывающему коду, что действие не выполнено
end

# список типов, которые внимательно смотрим:
mytags = Dict(
    # добавить img, чтобы находить
    # <img width=\"0\" height=\"0\" src=\"http://ssp.adriver.ru/cgi-bin/sync.cgi?
    Gumbo.HTMLElement{:img} => 
	Dict(	:printed_type=>"img",
		:wanted_attrs=>[ 
                             ( "src", # -- имя атрибута 
                               x->true # -- фильтр-функция (в данном случае всегда тру)
                             ), 
                           ],
		:final_prepare => function(x::AbstractString)
                                m = match(r"\".*?\/\/(?P<url>.+?)\"",x)
                                return m==nothing ? x : m[:url]
                              end
	    ),

    Gumbo.HTMLElement{:a} => 
       Dict(:printed_type=>"a", 
            :wanted_attrs=>[ 
                             ( "href", # -- имя атрибута 
                                x->true  # берем все, "внуренность" ссылки определим потом
                             #  x->begin # -- фильтр-функция (здесь - только относительные ссылки)
                             #    rv1 = !ismatch(r"//",x) 
                             #    rv2= ismatch(r"^[\\\"\']*?/",x) 
                             #    rv = rv1 && rv2
                             #    #info("filter got $x -> $rv1 && $rv2 = $rv")
                             #    rv
                             #  end    
                             ), 
                           ],
            :final_prepare => function(x::AbstractString)
        			# если вернуть пустую строку, результат не будет печататься
				if !isempty(root)
                            	    # имеем root, можем определить внутренние ссылки из абсолютных
                            	    r1 = Regex(s"^[\\\"\']*?(?P<root>"*root*s")(?P<url>/.+)[\\\"\']*?")
        			    m1 = match(r1, x)
        			    #deb ? info("x=$x, r1=$r1, m1=$m1") : nothing
        			    if m1 != nothing
        				return m1[:url]
        			    end
				end
				        			 
        			# попробуем найти относительные ссылки 
        			if ismatch(r"://",x) # ссылка абсолютная
        			    return ""
        			end    
        			if ismatch(r"^//",x) return "" end # аналогично
        			
        			# ссылки относительные:

        			if ismatch(r"^[\\\"\'\s]?/[\s\\\"\']?$", x)
        			    #deb ? info("SKIP ROOT A: x=$x") : nothing        			
        			    return "" # ссылка на корень не нужна
        			end
        			
                            	m2 = match(r"^[\\\"\']*?/(?P<url>.+?)[\\\"\']",x)
                            	if m2 !=nothing
                            	    return m2[:url]
                            	end
                                #info("final_prepare got: $x return: $m")
                                return x
                              end                                                            
       ), 

    Gumbo.HTMLElement{:link} => 
       Dict(:printed_type=>"link", 
            :wanted_attrs=>[ 
                             ( "href", # -- имя атрибута 
                               x->true # -- фильтр-функция (здесь - берем все)
                             ), 
                           ],
		:final_prepare => function (x::AbstractString)
                                m = match(r"\".*?\/\/(?P<url>.+?)\"",x)
                                return m==nothing ? x : m[:url]
                              end
       ), 


    Gumbo.HTMLElement{:iframe} => 
       Dict(:printed_type=>"iframe", 
            :wanted_attrs=>[ 
                             ( "src", # -- имя атрибута 
                               x->true # -- фильтр-функция (здесь - берем все)
                             ), 
                           ],
		:final_prepare => function (x::AbstractString)
                                m = match(r"\".*?\/\/(?P<url>.+?)\"",x)
                                return m==nothing ? x : m[:url]
                              end
       ), 


    Gumbo.HTMLElement{:script} => 
       Dict(:printed_type=>"script",
            :final_prepare => function (script)
        			#if ismatch(r"adriver",script)
        			#    info("scripthandler got $script") 
        			#end    
                                m = match(r"src\s*\=\s*\"http\://(?P<url>.+?)\"",script)
                                if m!=nothing
                                  #info("match1 $m ") 
                                  return m[:url]
                                else
                                  #m2 = match(r"\/\/(?P<url>[^\"\']+?\/[^\"\']+?)\"",script)
                                  m2 = match(r"//(?P<url>[^\"\'\(\)\:\\]+?)[\\\"]",script)
                                  if m2!=nothing && ismatch(r"\.",m2[:url])
	                	    #info("match2 $m2 ") 
                            	    return m2[:url]
                                  else
                                    # ограничения по количеству {0,N} сделаны для защиты от ошибок превышения лимита
                                    m3 = match(r"\"(?P<url>[^\"\']{0,250}?\.[^\"\']{0,250}?/[^\"\']{0,500}?\.js)",script) 
                                    if m3!=nothing
                            	      #info("match3 $m3 ") 
                                      return m3[:url]
                                    else    
                                      return ""
                                    end    
                                  end        
                                end    
                              end    
       ),
)


for el in postorder(html_content.root)
 mytype = typeof(el)
 dict = get(mytags, mytype, Dict())
 if isempty(dict)
    continue
 end    
 
 printed_type = get(dict, :printed_type,"UNKNOWN")
 wanted_attrs = get(dict, :wanted_attrs, [])
 final_prepare = get(dict, :final_prepare, x->x)
 printed_attrs = []
 el_attrs = attrs(el)
 joined_attrs = ""
 if isempty(wanted_attrs)
    joined_attrs = replace( string(el), r"\n", "\\n" )
 else    
    for (wanted_at, filter_func) in wanted_attrs
        wanted_val = get( el_attrs, wanted_at, "" )
        if !filter_func(wanted_val) # -- filter_func must return true/false
            continue 
        end    
        push!( printed_attrs, wanted_val ) # было join([wanted_at,wanted_val],"=>"))
    end
    joined_attrs = join(printed_attrs,",")
 end
 
 final_prepared = isempty(joined_attrs) ? "" : final_prepare(joined_attrs)
 if isempty(final_prepared)
    continue
 end 
 println(io_out, join([printed_type, final_prepared],"*")) 
end

return true # все ок, функция отработала
end # function in_html_out_tags
# ------------------------------------------------------

# ------ run in command-line mode: must have --run first param ----
if length(ARGS)>0 && ismatch(r"run", ARGS[1])
    deb=false
    if length(filter( arg->ismatch(r"deb",arg), ARGS)) > 0
	deb = true
    end
    root=""
    if (r=filter( arg->ismatch(r"root=.+",arg), ARGS))|>length > 0
	if (m=match(r"root=(?P<root>.+)",r[1])) != nothing
	    deb ? info("== root parameter = ",m[:root]) : ""
	    root = m[:root]
	end    
    end    
    in_html_out_tags(STDIN,STDOUT,root=root,deb=deb)
end
    
    

