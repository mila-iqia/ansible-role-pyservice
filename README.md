
# ansible-pyservice

Role for Python applications/services.


## Required variables

The following variables must be set in the inventory:

* `app_name`: The name of the application.
* `app_user`: The user under which the app should be run and which owns the configuration and data.
* `app_group`: The group to create the various directories under.
* `app_repo`: Path to the application repository. See the requirements for the repository in the Repository section below.
* `app_tag`: Tag or branch of the app_repo to checkout.


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


## Writing file content

You can easily write files based on content that is in various variables:

```yaml
app_files:
  - dest: "{{ app_config_dir }}/certificate"
    content: "{{ certificate_contents }}"
    mode: "0600"  # default mode is also 0600
```


## Variables

These variables may also be set to customize the install:

* `app_ensure_user`: Whether to create `app_user` if it does not exist.
* `app_module`: The name of the application's Python module (defaults to `{{ app_name }}`)
* `python_version`: Python version to use.
* `conda_version`: Conda version to use. See the list [here](https://repo.anaconda.com/miniconda). Put the part of the name that's in between `Miniconda3` and `.sh`, e.g. `latest-Linux-aarch64` or `py311_23.10.0-1-Linux-x86_64`. Make sure it's the right architecture.
* `app_ssh_key`: The contents of a SSH key file that authorizes the git action to checkout the repository.
* `app_ssh_key_path`: *Alternatively*, the path to an SSH file already present on the machine which authorizes the git action to checkout the repository.


## Optional variables

The defaults should work just fine, but you can change these if you want:

* `global_app_root`: The path where all applications will be installed into subdirectories (defaults to `/applications`)
* `app_root`: The path on the target system in which to put all the code, configuration and data. Defaults to `{{ global_app_root }}/{{ app_name }}`
* `app_data_dir`: The path on the target system in which to put application data. Defaults to `{{ app_root }}/data`
* `app_dir`: The path on the target system in which to put all the code and configuration. Defaults to `{{ app_root }}/app`
* `app_config_dir`: The path on the target system in which to put configuration. Defaults to `{{ app_dir }}/config`.
* `app_config`: Path to the configuration file (defaults to `{{ app_config_dir }}/config.yaml`)
* `conda_base`: The path where to find or install miniconda (defaults to `{{ global_app_root }}/miniconda3`)
* `conda_isolate`: If true, miniconda will be put under `app_dir` (defaults to false). It's pointless to change this if you change `conda_base`.


## Other variables

These variables you should not set, but they may be useful to define extra work to do in the playbook:

* `app_code_dir`: Path to the cloned repository.
* `conda_run`: Put that in front of a shell command to run it in the app's conda environment.
* `app_data_files`: List of files in the data directory. You can use `app_data_files.matched == 0` to check if the directory is empty and do something special in that situation.


## Repository

The repository referenced by `app_repo` must follow certain rules in order to work with this role:

* The URL must be accessible from the host, evidently. It can be a path on the filesystem.
* The repository directory must be pip-installable using `pip -e {{ app_code_dir }}`.
* Must contain a file named `pinned-requirements.txt` installable with `pip -r` which contains versions for all dependencies. You may generate this file using the `pip-compile` utility in the `pip-tools` package. Do not forget to commit it and update it whenever there are changes.
* Should contain a Python package named `{{ app_module }}`.
