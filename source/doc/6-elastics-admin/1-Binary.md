---
layout: doc
badge: elastics-admin
title: elastics-admin - Binary
alias_index: true
---

# {{ page.title }}

This gem provides the `elastics-admin` executable  to `dump`, `load` and `stat` and eventually rename any [elasticsearch][] index. It also provides a few rake tasks to do the same {% see 1.4 %}, plus the live-reindex feature {% see 6.2 %}.

> __Notice__: If you need to migrate data or alter the index while you have a live app that uses it, the elastics live-reindexing feature may suit better to your need {% see 6.2 %}.

    $ elastics-admin --help
    elastics-admin 1.0.1 (c) 2012-2013 by Domizio Demichelis

        elastics-admin:
            Generic binary tool to dump/load data from/to any elasticsearch index (no app needed).
            If you need to migrate data, use the elastics live-reindexing.
        Usage:
            elastics-admin <command> [options]
        <command>:
            dump    dumps the data from one or more elasticsearch indices
            load    loads a dumpfile
            stats   prints the full elasticsearch stats

        Notice: The load command will load the dump-file into elasticsearch without removing any pre-existent data.
                If you need fresh indices, use the elastics:index:delete and elastics:index:create rake tasks from your
                application, which will also recreate the mapping.

    Common options:
        -f, --file [FILE]                The path of the dumpfile (default: './elastics.dump')
        -r, --[no-]verbose               Run verbosely (default: 'true')

    Dump options:
        -i, --index [INDEX_OR_INDICES]   The index or comma separated indices to dump (default: all indices)
        -t, --type [TYPE_OR_TYPES]       The type or comma separated types to dump (default: all types)
        -s, --scroll [TIME]              The elasticsearch scroll time (default: 5m)
        -z, --size [SIZE]                The chunk size to dump per shard (default: 50 * number of shards)

    Load options:
        -m, --index-map [INDEX_MAP]      The index rename map (example: -m=dumped_index_name:loaded_index_name,a:b)
        -o, --timeout [SECONDS]          The http_client timeout for bulk loading (default: 60 seconds)
        -b, --batch-size [BATCH_SIZE]    The batch size to load (default: 500)

    Other options:
        -v, --version                    Shows the version and exits
        -h, --help                       Displays this screen
