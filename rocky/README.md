```bash
# 1. Edit vars.yml with your DuckDNS token and subdomain
nano vars.yml

# 2. Update inventory.ini with your server IP
nano inventory.ini

# 3. Test connection to your server
ansible -i inventory.ini web_servers -m ping

# 4. Run the playbook in check mode (dry run)
ansible-playbook deploy-web-stack.yml --check

# 5. Run the playbook for real
ansible-playbook deploy-web-stack.yml

# 6. If you want to see detailed output
ansible-playbook deploy-web-stack.yml -vv

# 7. To run on localhost instead of remote server
echo "[web_servers]" > inventory_local.ini
echo "localhost ansible_connection=local" >> inventory_local.ini
ansible-playbook -i inventory_local.ini deploy-web-stack.yml
```