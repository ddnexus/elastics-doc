---
layout: doc
title: flex-backup
---

# {{ page.title }}

This gem provides the `flex-backup` executable  to `dump`, `load` and `stat` any [elasticsearch][] index.

    $ flex-backup --help
    flex-backup 1.0.0 (c) 2012-2013 by Domizio Demichelis

        flex-backup:
            Flex tool to dump/load data from/to elasticsearch.
        Usage:
            flex-backup <command> [options]
        <command>:
            dump   dumps the data from one or more elasticsearch indices
            load   loads a dumpfile
            stats  prints the full elasticsearch stats

        Notice: The load command will load the dump-file into elasticsearch without removing any pre-existent data.
                If you need fresh indices, use the flex:index:delete and flex:index:create rake tasks from your
                application, which will also recreate the mapping. If you need to reindex you can use flex:backup:reindex.

    Common options:
        -f, --file [FILE]                The path of the dumpfile (default: './flex-backup.dump')
        -r, --[no-]verbose               Run verbosely (default: 'true')

    Dump options:
        -i, --index [INDEX_OR_INDICES]   The index or comma separated indices to dump (default: all indices)
        -t, --type [TYPE_OR_TYPES]       The type or comma separated types to dump (default: all types)
        -s, --scroll [TIME]              The elasticsearch scroll time (default: 5m)
        -z, --size [SIZE]                The chunk size to dump per shard (default: 50 * number of shards)

    Load options:
        -m, --index-map [INDEX_MAP]      The index rename map (example: -m=dumped_index_name:loaded_index_name,a:b)
        -o, --timeout [SECONDS]          The http_client timeout for bulk loading (default: 20 seconds)
        -b, --batch-size [BATCH_SIZE]    The batch size to load (default: 1000)

    Other options:
        -v, --version                    Shows the version and exits
        -h, --help                       Displays this screen

It also provides a few tasks to `dump`, `load` and `reindex` {% see 1.4 %}.
