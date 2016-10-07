# кусок логики из хромовского приложения (порядок поиска)
       src = utils.processUrl(src);
    112
    113         found =
    114             // pattern classification 2: check host+path hash
    115             matchesHost(db.patterns.host_path, src.host, src.path) ||
    116             // class 1: check host hash
    117             matchesHost(db.patterns.host, src.host) ||
    118             // class 3: check path hash
    119             matchesPath(src.path) ||
    120             // class 4: check regex patterns
    121             matchesRegex(src.host_with_path);
    122
    123         // check firstPartyExceptions
    124         if (conf.ignore_first_party &&
    125             found !== false &&
    126             db.firstPartyExceptions[found] &&
    127             utils.fuzzyUrlMatcher(tab_url, db.firstPartyExceptions[found])) {
    128             return false;
    129         }
    130
    131         return found;
    132     }
