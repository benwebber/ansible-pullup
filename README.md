# ansible-pullup

**ansible-pullup** is a simple wrapper around **ansible-pull** that makes it easy to localize configurations.

**ansible-pullup** is designed to solve a specific set of problems:

1. You use Ansible and **ansible-pull** to configure a number of machines.
2. You want to use a single repository to store all your Ansible configuration.
3. Clients need to select which roles to apply, but you cannot rely on hostnames.
4. Certain machines require local configuration which cannot or should not live in the Ansible repository.

The original use case for **ansible-pullup** was configuring a number of workstations, but you may find it useful for other purposes (e.g., bootstrapping cloud instances).

## Terminology

* Ansible repository

    Repository where you store your Ansible roles and playbooks.
* `local.yml`

    The default playbook **ansible-pull** executes. This playbook should be at the root of your Ansible repository.

## Usage

Create a `~/.pullup.yml` file and point it to your Ansible repository.

```yaml
---
# Path to ansible-pull repo.
pullup_repo: git@example.org:ansible-roles.git

# Role or task tags to execute.
pullup_tags: []

# Play to execute before applying the remote configuration.
pullup_pre_apply_play: ~/.pre-apply.yml

# Play to execute after applying the remote configuration.
pullup_post_apply_play: ~/.post-apply.yml
```

Then, update `local.yml` to include the **ansible-pullup** plays:

```yaml
---
- include: "{{ pullup_pre_apply_play | default('no-op.yml') }}"

- name: ansible-pullup
  hosts: localhost
  # Default roles and tasks go here.

- include: "{{ pullup_post_apply_play | default('no-op.yml') }}"
```

Next, add `no-op.yml` to your Ansible repository.

```yaml
---
- name: no-op
  hosts: localhost
  gather_facts: false
```

Finally, run **ansible-pullup**:

```
$ ansible-pullup
```

Run `ansible-pullup -h` for all configuration options.

## Hooks

Execute custom plays before or after applying the remote configuration. The path to each play is relative to the **ansible-pullup** configuration file.

* `pullup_pre_apply_play`

    Runs before applying the remote configuration.
* `pullup_post_apply_play`

    Runs after applying the remote configuration.

## FAQ

### Why not use **ansible-pull** directly?

When you point **ansible-pull** at your Ansible repository, it tries to execute the following playbooks in order:

* `<fqdn>.yml`
* `<hostname>.yml`
* `local.yml`

If you want to maintain machine-specific configuration, you need to create playbooks named after each host. This doesn't scale well with dynamic fleets.

### How do I choose which roles to apply?

Tag each role in the remote configuration's `local.yml` playbook:

```yaml
- hosts: localhost
  roles:
    - role: user
      tags: [user]
    - role: tools
      tags: [tools]
```

Then, in your `~/.pullup.yml` configuration, specify which tags you want to execute:

```yaml
pullup_repo: git@example.org:ansible-roles.git
pullup_tags:
  - tools
```

### Why do I need to tag each role?

Tags are the only way to select roles at runtime. You cannot, for instance, template the roles like so:

```yaml
- hosts: all
  roles: "{{ roles }}"
```

Ansible [does not automatically tag roles](https://github.com/ansible/ansible/issues/17434), so we need to be explicit.

### Why aren't my extra tasks executing?

If you specify tags to execute in `pullup.yml`, make sure you tag your custom plays with `always`:

```yaml
- hosts: localhost
  tags:
    - always
```

### What is `no-op.yml` for?

The hook includes would fail otherwise.
