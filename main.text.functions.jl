using Gumbo



# ф-я: "есть кириллица в строке?":
has_cyrillic(s) = ismatch(r"[а-я]+?"i, s)
# есть латинница?
has_latin(s) = ismatch(r"[a-z]+?"i, s)
 

# "Определяет, имеет ли элемент el родителя с тегом tg"
function hasparent(tg::Symbol, el::Gumbo.HTMLElement)
 if tag(el) == tg
     return true
 else
    hasparent(tg, el.parent)
 end
end

hasparent(tg::Symbol, el::Gumbo.NullNode) = false
hasparent(tg::Symbol, el::Gumbo.HTMLText) = hasparent(tg, el.parent)

# "Определяет, имеет ли элемент el родителя с тегом, одним из tgs"
function hasparent(tgs::Set, el::Gumbo.HTMLElement)
 if in(tag(el), tgs)
     return true
 else
    hasparent(tgs, el.parent)
 end
end
hasparent(tgs::Set, el::Gumbo.NullNode) = false
hasparent(tgs::Set, el::Gumbo.HTMLText) = hasparent(tgs, el.parent)


                                                                                                                      

function words(s::AbstractString, len::Int=3)
 # возвращает список очищенных слов длиной не менее len
 split(s, r"\s+|[,.:;!?_\-\\\|\/\d\)\(\{\}\@\#\$\%\^\&\*\~\`\>\<]") |>
 ss->filter(ss) do s ismatch(r"[а-я]|[a-z]"i, s) end |>
 ss->filter(s->length(s)>=len, ss)
end



inline_elements = Set([:b, :big, :i, :small, :tt, 
    :abbr, :acronym, :cite, :code, :dfn, :em, :kbd, :strong, :samp, :time, :var,
    :a, :bdo, :br, :img, :map, :object, :q, :script, :span, :sub, :sup,
    :button, :input, :label, :select, :textarea])


ignore_elements = Set([:button, :input, :select, :textarea, :optgroup, :command, :datalist, 
    :frame, :frameset, :noframes, :style, :link, :script, :noscript,
    :canvas, :applet, :map, :marquee, :area, :base, :img, :figure, :cite, 
    :header, :footer, 
    :aside, :time, :label, :blockquote,
    #:form, # бывают большие формы
    :fieldset, :details, :dir, :center, 
])

# возвращает ссылку на родителя, если это не inline-элемент, иначе - на деда и.т.д.рекурсивно
contr(el::Gumbo.HTMLText) = in(el.parent|>tag, inline_elements) ? contr(el.parent) : el.parent 
contr(el::Gumbo.HTMLElement) = in(el.parent|>tag, inline_elements) ? contr(el.parent) : el.parent
contr(el::NullNode) = el
Gumbo.tag(el::Gumbo.NullNode) = :nollnodetag

link_elements = Set([:a, :img ])
inlink(el::Gumbo.HTMLText) = hasparent(link_elements, el.parent)

function group_HTMLText(ll) # ll - HTMLElements iterator
 filter(ll) do el
    typeof(el)<:Gumbo.HTMLText && # берем только HTMLText
    !hasparent(ignore_elements, el) # исключая плохие
 end |>
 It.group() do  e1,e2 # объединяем в группы контейнерные элементы с вложенными в них inline-элементами
    l1 = e1.text|>length
    l2 = e2.text|>length
    
    e1|>contr == e2|>contr ||
    ( ( !inlink(e1) || !inlink(e2) ) && e1|>contr == e2|>contr|>contr ) ||
    ( ( !inlink(e1) || !inlink(e2) ) && e1|>contr|>contr == e2|>contr ) ||
    ( l1>1 && l2>1 && ( !inlink(e1) || !inlink(e2) ) && e1|>contr|>contr == e2|>contr|>contr ) ||
    ( l1>1 && l2>1 && ( !inlink(e1) || !inlink(e2) ) && e1|>contr|>contr|>contr == e2|>contr|>contr|>contr ) ||
    ( l1>1 && l2>1 && !inlink(e1) && !inlink(e2) && e1|>contr|>contr|>contr|>contr == e2|>contr|>contr|>contr|>contr ) ||
    ( l1>1 && l2>1 && !inlink(e1) && !inlink(e2) && e1|>contr|>contr|>contr|>contr|>contr == e2|>contr|>contr|>contr|>contr|>contr )
 end  # на выходе список, сгруппированный по группам [массив]
	# все, что в одной группе - считать одним текстом

end

