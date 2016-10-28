#!/usr/bin/env julia

push!(LOAD_PATH,"/usr/local/rle/var/share3/TIKETS/juice/")
using Jbase
import File
import Flag

deb = false
statist = false
if length(filter( arg->ismatch(r"deb",arg), ARGS)) > 0
    deb = true
end
if length(filter( arg->ismatch(r"stat",arg), ARGS)) > 0
    statist = true
end

#include("./in-html-out-descr-text.jl") # возможно файлы .descr не нужны
include("./in-html-out-main-text.jl")

modules = [
#    Dict(:targetext=>".descr.text", :f=>in_html_out_descr_text, :fstr=>"in_html_out_descr_text" ), # ключевые слова с сайта/страницы
    Dict(:targetext=>".main.text", :f=>in_html_out_main_text, :fstr=>"in_html_out_main_text" ), # главный текст
]



 debinfo = deb ? (x...)->info(x...) : (x...)->nothing
 statinfo = statist ? (x...)->info(x...) : (x...)->nothing

 parsed_cnt = 0
 skipped_ready_cnt = 0
 skipped_tmp_cnt = 0
 skipped_err_cnt = 0

 # на STDIN ожидаем построчно имена *.saved файлов
 
 for saved_file in filter(eachline(STDIN)) do fname length(fname)<250 end
    saved_file = chomp(saved_file)
    debinfo("saved file: ", saved_file)

    for modul in modules
        
        text_file = replace(saved_file,r"\.saved$", modul[:targetext])
        if text_file==saved_file
            error("The same file name after repllace fname: $text_file")
        end    
        debinfo("text file: ",text_file)
        text_file_tmp = string(text_file, ".TMP")

	url_file = "$(saved_file).url"

	url = if isfile(url_file) 
	    readchomp(url_file)
	else
	    ""     
	end

        if isfile(text_file)
    	    debinfo("Already exists text file $text_file - skip")
    	    skipped_ready_cnt = skipped_ready_cnt + 1
            continue 
        end
        
        if isfile(text_file_tmp) # если есть TMP, 
    	    # то пропуск, даже если никто его не делает - повторная работа пока не делается
    	    # можно потом задать параметры на этот счет
    	    debinfo("Already tmp exists $text_file_tmp - skip")
    	    skipped_tmp_cnt = skipped_tmp_cnt + 1
            continue 
        end

	if File.iswait(text_file) 
	    debinfo("file $text_file: WAIT. continue...")
	    continue
	end    
        
        debinfo("Set flag...")
        if ! Flag.set(text_file)
    	    warn("can't set flag for $text_file")
    	    continue
    	end    
        
        saved_file_io = open(saved_file,"r")

        text_file_tmp_io = open( text_file_tmp, "w" )
        debinfo("Run $(modul[:fstr]) ($saved_file_io, $text_file_tmp_io, url=$url, deb=$deb)")
        is_parse_html_true = modul[:f]( saved_file_io, text_file_tmp_io, url=url, deb=deb )
        debinfo("parse return $is_parse_html_true")
        close( text_file_tmp_io )
        statinfo("parsed:$parsed_cnt / ready:$skipped_ready_cnt / tmp:$skipped_tmp_cnt / err: $skipped_err_cnt")        
        if is_parse_html_true
    	    mv( text_file_tmp, text_file, remove_destination=true)
    	    parsed_cnt = parsed_cnt + 1
    	else
    	    skipped_err_cnt = skipped_err_cnt + 1
    	end    
        debinfo("Unset flag for  $text_file")
        Flag.unset( text_file )

    end
 end

