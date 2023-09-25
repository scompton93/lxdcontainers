#/bin/bash

for u in citus-coord-01 syd-citus1 syd-citus2 syd-citus3 mel-citus1 mel-citus2 mel-citus3
do
    echo "==== $u ===="
    lxc rm --force $u 2>/dev/null
    lxc cp driving-shrimp $u
    lxc start $u
done
sleep 0.5
lxc ls -c ns4 citus

for u in syd-citus1 syd-citus2 syd-citus3 mel-citus1 mel-citus2 mel-citus3 citus-coord-01
do
 
echo "==== NODE: $u ===="
 
lxc exec $u -- su - postgres -c 'psql db01'<<_eof_
select extname, extversion from pg_extension;
_eof_
 
done | less -S

lxc exec citus-coord-01 -- su - postgres -c 'psql db01'<<_eof_
    select citus_set_coordinator_host('citus-coord-01', 5432);
    insert into pg_dist_node(nodename)
        values ('syd-citus1')
              ,('syd-citus2')
              ,('syd-citus3')
			  ,('mel-citus1')
			  ,('mel-citus2')
              ,('mel-citus3');
_eof_

lxc exec citus-coord-01 -- su - postgres -c 'psql db01'<<_eof_
    show citus.shard_replication_factor;
    alter system set citus.shard_replication_factor=2;
    select pg_reload_conf();
_eof_

lxc exec citus-coord-01 -- su - postgres -c 'psql db01'<<_eof_
    show citus.shard_replication_factor;
    alter system set citus.shard_count=3;
    select pg_reload_conf();
_eof_


lxc exec citus-coord-01 -- su - postgres -c 'psql db01'<<_eof_
 
-- create the table
    create table xevents (
        consignment_id bigint,
        tenant_id bigserial,
		test text,
        primary key (consignment_id, tenant_id)
    );
 
-- distribute the events among the nodes
    select create_distributed_table('xevents', 'tenant_id');

	insert into xevents (consignment_id,tenant_id, test) values (1,1,'big');
	insert into xevents (consignment_id,tenant_id, test) values (2,1,'lol');
	insert into xevents (consignment_id,tenant_id, test) values (3,2,'fish');	
_eof_

sleep 0.5

lxc exec citus-coord-01 -- su - postgres -c 'psql db01'<<_eof_ | less -S
select *
    from xevents;
_eof_
