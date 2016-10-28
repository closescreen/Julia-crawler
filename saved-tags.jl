#!/usr/bin/env julia
include("./in-html-out-tags.jl")
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

debinfo = deb ? (x...)->info(x...) : (x...)->nothing
statinfo = statist ? (x...)->info(x...) : (x...)->nothing

    parsed_cnt = 0
    skipped_ready_cnt = 0
    skipped_tmp_cnt = 0
    skipped_err_cnt = 0
    
    docontinue = 0
    # на STDIN ожидаем построчно имена *.saved файлов

    for saved_file in eachline(STDIN)
        if docontinue > 0
            docontinue-=1
            continue
        end    
        saved_file = chomp(saved_file)
        debinfo("saved file: ", saved_file)

        tags_file = replace(saved_file,r"\.saved$",".tags")
        debinfo("tags file: ",tags_file)
        tags_file_tmp = string(tags_file, ".TMP")

	url_file = "$(saved_file).url"

	url = if isfile(url_file) 
	    readchomp(url_file) 
	else "" end

	root = if (m=match(r"(?P<root>.+?://[^/]*)",url)) != nothing
	    m[:root]
	else
	    ""    
	end    

        if isfile(tags_file)
    	    debinfo("Already $tags_file - skip")
    	    skipped_ready_cnt = skipped_ready_cnt + 1
            continue 
        end
        
        if isfile(tags_file_tmp) # если есть TMP, 
    	    # то пропуск, даже если никто его не делает - повторная работа пока не делается
    	    # можно потом задать параметры на этот счет
    	    debinfo("Already $tags_file_tmp - skip")
    	    skipped_tmp_cnt = skipped_tmp_cnt + 1
            continue 
        end

	if File.iswait(tags_file) 
	    debinfo("file $tags_file: WAIT. continue...")
	    docontinue = 10
	    continue
	end    
        
        debinfo("Set flag...")
        if ! Flag.set(tags_file)
    	    #warn("can't set flag for $tags_file")
    	    # скорее всего здесь непонятки с другим процессом который обогнал этот после проверок
    	    docontinue = 10
    	    continue
    	end    
        
        saved_file_io = open(saved_file,"r")

        tags_file_tmp_io = open( tags_file_tmp, "w" )
        debinfo("Run in_html_out_tags($saved_file_io, $tags_file_tmp_io)")
        is_parse_html_true = in_html_out_tags( saved_file_io, tags_file_tmp_io, root=root, deb=deb )
        debinfo("parse return $is_parse_html_true")
        close( tags_file_tmp_io )
        statinfo("parsed:$parsed_cnt / ready:$skipped_ready_cnt / tmp:$skipped_tmp_cnt / err: $skipped_err_cnt")        
        if is_parse_html_true 
    	    if isfile(tags_file_tmp)
    	        mv( tags_file_tmp, tags_file, remove_destination=true)
    	        parsed_cnt = parsed_cnt + 1
            end    	        
    	else
    	    skipped_err_cnt = skipped_err_cnt + 1
    	end    
        debinfo("Unset flag for  $tags_file")
        Flag.unset( tags_file )

    end








