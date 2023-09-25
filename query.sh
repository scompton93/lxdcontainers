#!/bin/bash

# Check if the SQL query parameter is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <SQL query>"
    exit 1
fi

# Store the SQL query in a variable
sql_query="$1"

# Define the LXC container name
container_name="citus-coord-01"

# Execute the SQL query within the LXC container
lxc exec "$container_name" -- su - postgres -c "psql db01" <<_eof_ | less -S
$sql_query
_eof_
