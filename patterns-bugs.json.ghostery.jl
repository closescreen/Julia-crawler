#!/usr/bin/env julia
#> из дрквовидной ghostery bugs.json печатает паттерны построчно
#> patterns-bugs.json.ghostery.jl "bugs.json" "host"|"path"|"host_path"|"regex" > my-out-file.txt

if length(ARGS) < 1  error("First param - json filename") end

json_file=ARGS[1]

if length(ARGS) < 2  error("Second param must be one of: host,path,host_path,regex") end
variant=ARGS[2]

if isempty(variant) error("Second param must be one of: host,path,host_path,regex") end

allowed = Set(["host","path","host_path","regex"])

if !in(variant,allowed) error(string("Allowed only: ", allowed)) end

import JSON

json=JSON.parsefile(json_file)

if !haskey(json,"patterns") error("Not found key \"patterns\"!") end

# ----------------------------------------

function print_host_path(d,delim="*") 
 println(join((
        get(d, :host, ""), 
        get(d, :path, ""),
        get(d, :regex, ""),
        d[:app]["name"], 
        d[:app]["cat"]), delim))
end


# -------- host+path: ---------------------
if variant=="host_path"
    
    function walk_host_path(f,j,k,v,s)
        if k=="\$"
         for i in v
          aid = j["bugs"][ string(i["id"]) ]["aid"]
          app = j["apps"][string(aid)]
          f( Dict{Any,Any}(:host=>s, :path=>i["path"], :app=>app ))
         end
        else
         s = isempty(s) ? k : string(k,".",s)
         for (k,v) in v
          walk_host_path(f,j,k,v,s)
         end
        end
    end

    for (k,v) in json["patterns"]["host_path"]
     walk_host_path(print_host_path, json, k, v, "")
    end

# ---------- host: ---------------------
elseif variant=="host"
    
    function walk_host(f,j,k,v,s)
        if k=="\$"
         id = v
         aid = j["bugs"][ string(id) ]["aid"]
         app = j["apps"][ string(aid) ]
         f( Dict{Any,Any}(:host=>s, :app=>app ))
        else
         s = isempty(s) ? k : string(k,".",s)
         for (k,v) in v
          walk_host(f,j,k,v,s)
         end
        end
    end

    for (k,v) in json["patterns"]["host"]
     walk_host(print_host_path, json, k, v, "")
    end

# -------------- path: -------------------
elseif variant=="path"
    
    function walk_path(f,j,k,v)
        id = v
        aid = j["bugs"][ string(id) ]["aid"]
        app = j["apps"][ string(aid) ]
        f( Dict{Any,Any}(:path=>k, :app=>app ))
    end

    for (k,v) in json["patterns"]["path"]
     walk_path(print_host_path, json, k, v)
    end

# ----- regex: ... ?
elseif variant=="regex"
    function walk_regex(f,j,k,v)
        id = k
        aid = j["bugs"][ string(id) ]["aid"]
        app = j["apps"][ string(aid) ]
        f( Dict{Any,Any}(:host=>"", :path=>"", :regex=>v, :app=>app ), "\t")
    end

    function print_re(d,delim="\t") 
        println(join((
            get(d, :regex, ""),
            d[:app]["name"], 
            d[:app]["cat"]), delim))
    end


    for (k,v) in json["patterns"]["regex"]
     walk_regex(print_re, json, k, v)
    end

else
    error(string("Bad variant ",variant))

end    



