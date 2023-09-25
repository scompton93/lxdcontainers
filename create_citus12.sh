#/bin/bash

for u in citus-coord-01 citus1 citus2 citus3
do
    echo "==== $u ===="
    lxc rm --force $u 2>/dev/null
    lxc cp dashing-kangaroo $u
    lxc start $u
done
sleep 5
lxc ls -c ns4 citus

for u in citus-coord-01 citus1 citus2 citus3
do
 
echo "==== NODE: $u ===="
 
lxc exec $u -- su - postgres -c 'psql db01'<<_eof_
select extname, extversion from pg_extension;
_eof_
 
done | less -S


lxc exec citus-coord-01 -- su - postgres -c 'psql db01'<<_eof_
    select citus_set_coordinator_host('citus-coord-01', 5432);
    insert into pg_dist_node(nodename)
        values ('citus1')
              ,('citus2')
              ,('citus3');
_eof_


lxc exec citus-coord-01 -- su - postgres -c 'psql db01'<<_eof_
set citus.enable_schema_based_sharding to on;
_eof_
