# volttron-developer

This repository has miscellaneous scripts for helping to maintain VOLTTRON
related repositories.  

## Requirements

The script uses pipenv.  We need to use the default dependencies of volttron plus
pipenv.  

```bash 
$> sudo apt install pipenv
```

## setup-environment.sh

This script will clone the core repositories.  Please read and edit the script before
executing the following command.  Directions for variables are set inline within
the script for documentation.

```bash
$> bash setup-environment.sh
```

After running the script you will have the core repositories cloned with the specified
branches in your REPO_ROOT.  Assuming REPO_ROOT is /repo the following should be your
tree.

```bash
$> tree -L 1
.
├── volttron-client
├── volttron-server
└── volttron-utils
```

Each repository has its own virtual environment synced with pipenv.  The next task
is to have the volttron-server environment as the main environment and have the other
volttron-utils and volttron-client be able to be edited.

##  Adding environment links

Usually when installing packages using pipenv you would exicute ```pipenv install package```.
However for us we want everything to be editable in our projects so that it makes development
easier.  

1. Open a command line to the volttron-server repository
2. execute ```pipenv install -e ../volttron-client --dev```
3. execute ```pipenv install -e ../volttron-utils --dev```
4. execute ```pipenv install -e . --dev```

Executing ```pipenv run volttron -vv``` should start the volttron server at this point in time.

### Other handy commands

- ```pipenv --rm``` removes your virtual environment
- ```pipenv --venv``` shows you the path to the virtual environment
- ```pipenv shell``` activates the current projects virtual environment.
- ```pipenv graph``` shows a dependency graph of all dependencies for the environment
- ```pipenv install <package>``` installs a package into environment.
- ```pipenv install <package> --dev``` installs a development dependency.
- ```pipenv uninstall <package>``` uninstalls a package
- ```pipenv run <command>``` executes command in the python environment of the directory.
- ```pipenv lock -r > requirements.txt``` generates a requirements.txt from the Pipfile.lock
- ```pipenv sync``` syncs changes from Pipfile to lock file
- ```pipenv-setup sync``` syncs changes to the setup.py file for the repository.

## Pycharm Setup

Open volttron-server project. Set the python intepreter to the python under volttron-server's virtual environment. The path to the virtual environment can be got by running the command ```pipenv --venv``` from within volttron-server source directory.
In pycharm go to:
Settings -> Python Interpreter -> Virtual Environment(on the left) -> On the right pick existing environment. Give the path to python in your volttron-server's virtual environment. Check the box that says "make this available to all projects"

![Pycharm Interpretor Settings](images/pycharm-interpreter.png)


Open volttron-client project, and volttron-utils project. For both pick the option attach when you get a popup. All projects should be referencing the same python environment (volttron-server) from the virtualenv settings
within the projects.

![Pycharm Open Projects](images/pycharm-open-projects.png)


One can rename the project by highlighting the top of the tree volttron-server and choosing 'rename project' 
option from the file menu.

Clicking the "Projects" menu allows you to see the project files instead of the project view.

![Pycharm Project File View](images/pycharm-open-project-file-view.png)



## Debugging VOLTTRON in Pycharm

The following are run from the same python environment and are highlighted red where
either changes need to be made from the default or are areas that should be verified
are correct for the different use cases.

Make sure that your pycharm settings are gevent compatible

![Pycharm Gevent Compatible](images/pycharm-gevent.png)

Create a Run/Debug configuration for volttron and vctl like the following

![Pycharm Run volttron -vv](images/pycharm-config-debug-volttron.png)

![Pycharm Run vctl -vv command](images/pycharm-config-debug-volttron-control.png)
