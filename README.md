
# ansible-pyservice

Role for Python applications/services.


## Prerequisites

In order to be compatible with this role, a project must follow these rules:

* It must be available as a Git repository that is visible from the host.
* The repository directory must be pip-installable using `pip -e REPO_PATH`.
* At the top level, there must be a file named `pinned-requirements.txt` installable with `pip -r` which contains versions for all dependencies.
  * You may generate this file from a `pyproject.toml`, `setup.py` or `requirements.txt` file with the `pip-compile` utility in the `pip-tools` package. Do not forget to commit it and update it whenever there are changes.


## Overview of the installation

By default, the pyservice role will create a user, and the following hierarchy:

```bash
# Root for all pyservice-installed applications, owner is root
/applications        # Variable: {{ pyservice_global_root }}
  # uv binary is installed here
  /uv                # Variable: {{ uv_location }}
  # App directory; owner is the the app user
  /APP_NAME          # Variable: {{ pyservice_root }}
    # Application code and configuration
    /app             # Variable: {{ pyservice_dir }}
      # The repository is cloned here
      /code          # Variable: {{ pyservice_code_dir }}
      # Configuration files, certificates, keys, etc.
      /config        # Variable: {{ pyservice_config_dir }}
        # Default configuration file, provided for convenience but not mandatory
        config.yaml  # Variable: {{ pyservice_config }}
    # Application data (anything that must be backed up)
    /data            # Variable: {{ pyservice_code_dir }}
    # Virtual environment
    /uv
      /venv
/etc
  /systemd
    /system
      # Service files defined in {{ pyservice_services }}
      APP_NAME-xyz.service
      ...
      # Timer files for recurrent work, defined in {{ pyservice_timers }}
      APP_NAME-uvw.service
      APP_NAME-uvw.timer
      ...
```

Installation proceeds as follows:

1. `setup` tasks
  1. Deactivate all services related to the app and delete their files
  2. Clone the repository
  3. Install uv
  4. Run `uv sync`
  6. Optionally write files as defined in `pyservice_files`
2. (Do custom setup here)
3. `activate` tasks
  1. Write the service files and activate them

The application's work must be defined in two lists:

* `pyservice_services` for services that must be up at all times, such as a web server or an API
* `pyservice_timers` for recurrent work, such as scraping information or generating a report every day or week


## Important variables

The following variables can/must be set in the inventory:

* `pyservice_name`: The name of the application.
* `pyservice_module`: The name of the Python module defined by the application. Defaults to `{{ pyservice_name }}`.
* `pyservice_user`: The user under which the app should be run and which owns the configuration and data.
  * Set `pyservice_ensure_user` to `false` in order not to do this, if you want to control user creation.
* `pyservice_group`: The group to create the various directories under. Defaults to `{{ ansible_common_remote_group | default(pyservice_user) }}`.
* `pyservice_repo`: Path to the application repository.
  * If the repo is private, you should set `pyservice_ssh_key` to a private key that is authorized to read the repo (use the SSH URL for the repo), or set `pyservice_ssh_key_path` to the path to the proper file on the host.
* `pyservice_tag`: Tag or branch of the `pyservice_repo` to checkout.
* `uv_version`: UV version to use. See the list [here](https://github.com/astral-sh/uv/releases). **Minimum** allowed version should be 0.4.9 (that's the version in which `uv self update {{ uv_version }}` was added).


## Defining a service

The `pyservice_services` variable should contain a list of services. Each service has a name, description and associated command:

```yaml
pyservice_services:
  - name: web
    description: "Run the web interface for {{ pyservice_name }}"
    command: python -m {{ pyservice_module }} --config {{ pyservice_config }} web
```

The command is run in the environment created by the role, and it can be anything you want.


## Defining a timer

The `pyservice_timers` variable should contain a list of timers. Each timer has a name, description, schedule and associated command:

```yaml
pyservice_timers:
  - name: something
    description: "Do something every Monday at 2 AM"
    schedule: "Mon, 02:00"
    command: python -m {{ pyservice_module }} --config {{ pyservice_config }} do_something
```

The syntax for the schedule is described [here in section 4.2](https://wiki.archlinux.org/title/systemd/Timers). It ends up in an `OnCalendar` declaration, so you can look at the examples for that.

The command is run in the environment created by the role, and it can be anything you want.


## Writing file content

You can easily write files based on content that is in various variables:

```yaml
pyservice_files:
  - dest: "{{ pyservice_config_dir }}/certificate"
    content: "{{ certificate_contents }}"
    mode: "0600"  # default mode is also 0600
```


## Other variables

* `pyservice_global_root`: The path where all applications will be installed into subdirectories (defaults to `/applications`)
* `pyservice_root`: The path on the target system in which to put all the code, configuration and data. Defaults to `{{ pyservice_global_root }}/{{ pyservice_name }}`
* `pyservice_code_dir`: Path to the cloned repository.
* `pyservice_data_dir`: The path on the target system in which to put application data. Defaults to `{{ pyservice_root }}/data`
* `pyservice_dir`: The path on the target system in which to put all the code and configuration. Defaults to `{{ pyservice_root }}/app`
* `pyservice_config_dir`: The path on the target system in which to put configuration. Defaults to `{{ pyservice_dir }}/config`.
* `pyservice_config`: Path to the configuration file (defaults to `{{ pyservice_config_dir }}/config.yaml`)
* `uv_location`: The path where to put the uv binary (defaults to `{{ pyservice_global_root }}/bin`)
* `uv_isolate`: If true, uv will be put under `pyservice_dir` (defaults to false). It's pointless to change this if you change `uv_location`.
* `uv_run`: Put that in front of a shell command to run it in the app's environment.


## Example playbook

The typical playbook should run the `setup` tasks, then some custom operations, typically templating a configuration file, then run the `activate` tasks. The `pyservice_services`, `pyservice_timers` and `pyservice_files` variables can be defined in the playbook since it makes little sense to change them in the inventory, except possibly for the timer schedules.

```yaml
---
- hosts: all
  vars:
    pyservice_services:
      - name: web
        description: "Run the web interface for {{ pyservice_name }}"
        command: python -m {{ pyservice_module }} --config {{ pyservice_config }} web
    pyservice_timers:
      - name: something
        description: "Do something every Monday at 2 AM"
        schedule: "Mon, 02:00"
        command: python -m {{ pyservice_module }} --config {{ pyservice_config }} do_something
    pyservice_files:
      - dest: "{{ pyservice_config_dir }}/certificate"
        content: "{{ certificate_contents }}"
        mode: "0600"

  tasks:
  - name: Install
    import_role:
      name: pyservice
      tasks_from: setup

  - name: Template configuration
    ansible.builtin.template:
      src: "config.yaml"
      dest: "{{ pyservice_config }}"
      owner: "{{ pyservice_user }}"
      mode: "0600"

  - name: Activate
    import_role:
      name: pyservice
      tasks_from: activate
```
