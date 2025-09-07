# Ansible setup

This sample setup organizes playbooks, roles, inventory, and files with variables by function. Tags at the play and task level provide greater granularity and control.

## Folder Structure


```text
├── ansible.cfg             # 
├── data                    # data folder for extra config
│   └── config.json         # extra config
├── data.yml                # load extra config from data folder
├── inventories             # inventory files
│   ├── production          # inventory and var files for production hosts
│   │   ├── group_vars      # group vars
│   │   │   ├── all.yml     # here we assign variables to all production hosts
│   │   │   ├── group1.yml  # here we assign variables to group1
│   │   │   └── group2.yml  # here we assign variables to group1
│   │   ├── hosts.yml       # inventory file for production hosts
│   │   └── host_vars       # host vars
│   │       ├── host1.yml   # here we assign variables specific to host1
│   │       └── host2.yml   # here we assign variables specific to host1
│   ├── staging             # inventory and var files for staging hosts
│   │   ├── group_vars      # group vars
│   │   │   ├── all.yml     # here we assign variables to all staging hosts
│   │   │   ├── group1.yml  # here we assign variables to group1
│   │   │   └── group2.yml  # here we assign variables to group1
│   │   ├── hosts.yml       # inventory file for staging hosts
│   │   └── host_vars       # host vars
│   │       ├── host1.yml   # here we assign variables specific to host1
│   │       └── host2.yml   # here we assign variables specific to host1
├── main.yml                # main playbook
├── playbook_group1.yml     # playbook for group1
├── playbook_group2.yml     # playbook for group1
├── README.md               # 
├── requirements.yml        # here we list required roles and modules
└── roles                   # roles
    └── my-role             # role: my-role
        ├── tasks           #
        │   └── main.yml    # main task file for role
        └── vars            # 
            └── main.yml    # variables associated with this role
```

#### `inventories`

This folder contains inventory files for different environments; `production` and `staging`.

All the hosts are localhost. They are grouped as follows:

```text
@all:
  |--@ungrouped:
  |--@group1:
  |  |--host1
  |--@group2:
  |  |--host2
```

Modify the hosts and grouping as per your requirement.

Set host specific vars in `inventories/environment/host_vars/my-host.yml`
Set group specific vars in `inventories/environment/grou_vars/my-group.yml`

#### `data`

`data/config.json` contains additional data that you might require for your plays/tasks.

## Run playbook patterns:

### Environment Specific

```bash
ansible-playbook main.yml -i inventories/production
ansible-playbook main.yml -i inventories/staging
```

### Group specific

```bash
ansible-playbook main.yml -i inventories/production --limit group1
ansible-playbook main.yml -i inventories/staging --limit group2
```

### Host specific

```bash
ansible-playbook main.yml -i inventories/production --limit host1
ansible-playbook main.yml -i inventories/staging --limit host2
```

### Tag Specific

```bash
ansible-playbook main.yml -i inventories/production -t my-tag1
ansible-playbook main.yml -i inventories/production -t tag-group1
```

## References

Sample Ansible Setup [https://docs.ansible.com/ansible/latest/tips_tricks/sample_setup.html](https://docs.ansible.com/ansible/latest/tips_tricks/sample_setup.html)
