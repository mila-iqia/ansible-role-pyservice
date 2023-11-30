
# ansible-pyservice

Role for Python applications/services.


## Required variables

The following variables must be set in the inventory:

* `app_name`: The name of the application.
* `app_user`: The user under which the app should be run and which owns the configuration and data.
* `app_repo`: Path to the application repository. See the requirements for the repository in the Repository section below.
* `app_tag`: Tag or branch of the app_repo to checkout.
* `app_config_defaults`: Default configuration values to write to the app's configuration file.
* `app_config_dict`: The contents of that variable will be recursively combined with `app_config_defaults` and written to `app_config` in YAML format. Ideally it should not contain secrets like tokens or keys.
* `app_secrets_dict`: The contents of that variable will be written to `app_secrets` in YAML format. This is where tokens and keys can be defined. It can be empty.
  * Note: you can add `secrets: "{{ app_secrets }}"` in `app_config_dict` so that the configuration contains the location of the secrets file.

The config and secrets files are both created with permissions 0600 with `app_user` as the owner.


## Defining a service

The `app_services` variable should contain a list of services. Each service has a name, description and associated command:

```yaml
app_services:
  - name: web
    description: "Run the web interface for {{ app_name }}"
    command: python -m {{ app_module }} --config {{ app_config }} web
```

The command is run in the conda environment created by the role.


## Defining a timer

The `app_timers` variable should contain a list of timers. Each timer has a name, description, schedule and associated command:

```yaml
app_timers:
  - name: something
    description: "Do something every Monday at 2 AM"
    schedule: "Mon, 02:00"
    command: python -m {{ app_module }} --config {{ app_config }} do_something
```

The command is run in the conda environment created by the role.


## Variables

These variables may also be set to customize the install:

* `app_module`: The name of the application's Python module (defaults to `{{ app_name }}`)
* `python_version`: Python version to use.
* `conda_version`: Conda version to use. See the list [here](https://repo.anaconda.com/miniconda). Put the part of the name that's in between `Miniconda3` and `.sh`, e.g. `latest-Linux-aarch64` or `py311_23.10.0-1-Linux-x86_64`. Make sure it's the right architecture.


## Optional variables

The defaults should work just fine, but you can change these if you want:

* `global_app_root`: The path where all applications will be installed into subdirectories (defaults to `/applications`)
* `app_root`: The path on the target system in which to put all the code, configuration and data. Defaults to `{{ global_app_root }}/{{ app_name }}`
* `app_data_dir`: The path on the target system in which to put application data. Defaults to `{{ app_root }}/data`
* `app_dir`: The path on the target system in which to put all the code and configuration. Defaults to `{{ app_root }}/app`
* `app_config_dir`: The path on the target system in which to put configuration. Defaults to `{{ app_dir }}/config`.
* `conda_base`: The path where to find or install miniconda (defaults to `{{ global_app_root }}/miniconda3`)
* `conda_isolate`: If true, miniconda will be put under `app_dir` (defaults to false). It's pointless to change this if you change `conda_base`.


## Other variables

These variables you should not set, but they may be useful to define extra work to do in the playbook:

* `app_config`: Path to the configuration file.
* `app_code_dir`: Path to the cloned repository.
* `conda_run`: Put that in front of a shell command to run it in the app's conda environment.
* `app_data_files`: List of files in the data directory. You can use `app_data_files.matched == 0` to check if the directory is empty and do something special in that situation.


## Repository

The repository referenced by `app_repo` must follow certain rules in order to work with this role:

* The URL must be accessible from the host, evidently. It can be a path on the filesystem.
* The repository directory must be pip-installable using `pip -e {{ app_code_dir }}`.
* Must contain a file named `pinned-requirements.txt` installable with `pip -r` which contains versions for all dependencies. You may generate this file using the `pip-compile` utility in the `pip-tools` package. Do not forget to commit it and update it whenever there are changes.
* Should contain a Python package named `{{ app_module }}`.
