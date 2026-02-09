#!/bin/sh

API_KEY="your_opnsense_api_key"
API_SECRET="your_opnsense_api_secret"
SERVER="https://URL:PORT"
ALIAS="your_alias_name"

# Step 1: Get the alias UUID
alias_uuid=$(curl -s -k -u "$API_KEY:$API_SECRET" \
  "$SERVER/api/firewall/alias/get_alias_u_u_i_d/$ALIAS" \
  | grep -oE '[0-9a-f-]{36}')

if [ -z "$alias_uuid" ]; then
  echo "Alias $ALIAS not found!"
  exit 1
fi

# Step 2: Get all item UUIDs inside the alias
item_uuids=$(curl -s -k -u "$API_KEY:$API_SECRET" \
  "$SERVER/api/firewall/alias/get_item/$alias_uuid" \
  | grep -oE '[0-9a-f-]{36}')

# Step 3: Delete each item UUID
if [ -n "$item_uuids" ]; then
  echo "Deleting existing addresses inside $ALIAS..."
  for item_uuid in $item_uuids; do
    echo "Deleting item $item_uuid"
    curl -s -k -u "$API_KEY:$API_SECRET" -X POST \
      "$SERVER/api/firewall/alias/del_item/$item_uuid"
  done
else
  echo "No items found in $ALIAS."
fi

# Step 4: Fetch OSPF networks
networks=$(vtysh -c "show ip route ospf" | awk '/O/{print $2}' | cut -d',' -f1)

# Step 4a: Add static network(s) manually
networks="$networks x.x.x.x/y" # e.g. 192.168.0.0/24

# Step 5: Add networks to alias
for net in $networks; do
  echo "Adding $net to $ALIAS..."
  curl -s -k -u "$API_KEY:$API_SECRET" \
    -X POST -H "Content-Type: application/json" \
    -d "{\"address\":\"$net\"}" \
    "$SERVER/api/firewall/alias_util/add/$ALIAS"
done

# Step 6: Reconfigure alias (Apply changes)
echo "Reconfiguring $ALIAS..."
curl -s -k -u "$API_KEY:$API_SECRET" -X POST \
  "$SERVER/api/firewall/alias/reconfigure/$alias_uuid"

echo "Alias $ALIAS rebuilt and applied successfully."
