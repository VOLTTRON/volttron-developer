# VOLTTRON Agent Developer Instructions

The following documentation steps through the process of creating a simple agent that listens
to the entire message bus and writes it to the log file.  This agent uses pipenv for its base,
however you could use poetry or another package manager if you choose (support for installing from
a directory is limited to poetry, pipenv, and pip installations only).  

The second part of the tutorial is for seasoned VOLTTRON veterans with agents that 
need to be ported to the new modular code base, but also want to have them 
available for the 8.x environment.

With every tutorial there are requirements in order to make them work.  This one is no different,
the following requirements should be installed system-wide, so they are available to be
used throughout the tutorial.

## Requirements

System level requirements:

```bash
# Python 3.8 is required for the installation of VOLTTRON
sudo apt-get update
sudo apt-get install -y build-essential \
  libffi-dev \
  python3.8-dev \ 
  python3.8-venv \
  openssl \
  libssl-dev \
  libevent-dev \
  pipenv
```

## Agent Step by Step Using Pipenv

The VOLTTRON team uses virtual environments for Python development and Pipenv for the
dependency management of those environments.  For this quickstart guide we will walk you
through building a new listener agent.

 1. Open terminal and create a folder to hold the code for the agent.
    ```bash
    $> mkdir volttron-listener
    $> cd volttron-listener
    ```
    
 2. Initialize volttron-server to a new environment
    ```bash
    $> pipenv install volttron-server 
    ``` 
    This will create an environment and install volttron-server in it. At this point
    there should be a Pipfile and Pipfile.lock file in the current working directory.
 
 3. Create a setup.py file and copy the following to it
    
    ```python
    from os import path
    from setuptools import setup, find_packages
    
    MAIN_MODULE = 'agent'
    
    # Find the agent package that contains the main module
    packages = find_packages('.')
    agent_package = ''
    for package in find_packages():
        # Because there could be other packages such as tests
        if path.isfile(package + '/' + MAIN_MODULE + '.py') is True:
            agent_package = package
    if not agent_package:
        raise RuntimeError('None of the packages under {dir} contain the file '
                           '{main_module}'.format(main_module=MAIN_MODULE + '.py',
                                                  dir=path.abspath('.')))
    
    # Find the version number from the main module
    agent_module = agent_package + '.' + MAIN_MODULE
        
    # Setup
    setup(
        name=agent_package + 'agent',
        version="0.1",
        install_requires=['volttron-client'],
        packages=packages,
        entry_points={
            'setuptools.installation': [
                'eggsecutable = ' + agent_module + ':main',
            ]
        }
    )
    ```
    
 4. Create a directory for your agent code to go into and cd into that directory
    ```bash
    $> mkdir mylistener
    $> cd mylistener
    ```
    
 5. Create an agent.py module within the mylistener directory with the following code.    

    ```python
    import logging
    
    from volttron import utils    
    from volttron.utils import vip_main
    from volttron.client.vip.agent import Agent, Core, PubSub
    
    utils.setup_logging()
    _log = logging.getLogger(__name__)
    
    class MyListener(Agent):
    
        def __init__(self, config_path, **kwargs):
            super().__init__(**kwargs)
            self.config = utils.load_config(config_path)
    
        @Core.receiver('onstart')
        def onstart(self, sender, **kwargs):
            _log.info("MyListener has started")
            
        @PubSub.subscribe('pubsub', '', all_platforms=True)
        def on_match(self, peer, sender, bus, topic, headers, message):
            _log.debug(f"Peer: {peer}, Sender: {sender}:, Bus: {bus}, "
                       f"Topic: {topic}, Headers: {headers}, Message: {message}")
    
    def main():
        try:
            vip_main(MyListener, version="0.1")
        except Exception as e:
            _log.exception('unhandled exception')
    if __name__ == '__main__':
        # Entry point for script
        sys.exit(main())
    ```
    
 6. Create an empty __init__.py file inside the mylistener
    ```bash
    $> touch __init__.py
    ```
 7. Cd to the parent directory(volttron-listener) and create Wheel and source distribution
    ```bash
    $> cd ..
    $> pipenv run python setup.py bdist_wheel sdist
    ```
  
 7. Start VOLTTRON
 
    ```bash
    $> pipenv run volttron -vv
    ```

 8. Open a new terminal to the same volttron-listener directory
    
    ```bash
    $> pipenv run vctl install dist/mylisteneragent-0.1-py3-none-any.whl --start
    $> pipenv run vctl status
    ```
    
Congratulations you now have a working volttron environment.  There is a lot more to
VOLTTRON than this simple agent, however this agent shows the patterns for larger
agents.  In the following section we will port an agent from the VOLTTRON 8.x platform 
to the modular code base.  The process will actually allow the agent to be installed
on both the 8.x platform and the modular code base.

## Porting an Existing Agents

This tutorial unlike the one above will not use pipenv as a package manager.  Instead ther
will be a plain virtual environment in which we can install volttron-server and the upgraded
existing agent.  This tutorial is made in two parts, the first we upgrade the agent and
install it on the 8.x platform and second we create a virtual environment and install the
modular code and the agent.

### Run against 8.x VOLTTRON

 1. Create a directory for your agent for our example 'mynewlistener'
    ```bash
    $> mkdir mynewlistener
    $> cd mynewlistener
    ```
 2. Copy the current volttron/examples/ListenerAgent to your directory
    ```bash
    $> cp volttron/examples/ListenerAgent . -R
    ```
    
 3. Modify the top of the file ./ListenerAgent/listener/agents.py file to have both import statements
    as follows:
    ```python
    try:
        # Attempt to import from 8.x version of VOLTTRON if not successful to import then
        # attempt to import from modular version of VOLTTRON.
        from volttron.platform.agent import utils
        from volttron.platform.messaging.health import STATUS_GOOD
        from volttron.platform.vip.agent import Agent, Core, PubSub
        from volttron.platform.vip.agent.subsystems.query import Query

    except ImportError:

        from volttron import utils
        from volttron.client.messaging.health import STATUS_GOOD
        from volttron.client.vip.agent import Agent, Core, PubSub
        from volttron.client.vip.agent.subsystems.query import Query
    ```
 4. Activate the VOLTTRON 8.x environment and install the agent
    ```bash
    $> cd <yourvolttronsourcedirectory>
    $> source env/bin/activate
    $(volttron)> cd <yourmynewlistenerdirectory>
    $(volttron)> volttron -vv -l volttron.log &
    $(volttron)> vctl install ListenerAgent --start
    $(volttron)> tail -f volttron.log
    # ctrl-d to exit tail.
    ```
 5. Once verified that the listener is running as expected stop volttron
    ```bash
    $(volttron)> vctl shutdown --platform
    ```
 6. Remove VOLTTRON home and deactivate
    ```bash
    $(volttron)> rm -rf ~/.volttron
    $(volttron)> deactivate
    $>
    ```
 
### Run against modular VOLTTRON server

 1. Move to a different directory (modularcode) and create a virtual environment
    ```bash
    $> cd .. && mkdir modularcode && cd modularcode
    $> python3 -m venv venv
    ```
    
 2. Activate the new envrironment
    ```bash
    $> source venv/bin/activate
    ```
    
 3. Install volttron-server the environment.
    ```bash
    $(venv)> pip install volttron-server
    ```
    
 4. Change directory to the 'mynewlistener' directory
    ```bash
    $(venv) cd /mynewlistener
    ```
       
 5. Start volttron. Below command will start moduler VOLTTRON server
     ```bash
     $(venv)> volttron -vv -l volttron.log &
     ```
 
 6. Install and start the listener agent
    ```bash
    $(venv)> vctl install ListenerAgent --start
    ```
 7. Verify successful start through the log or status
    ```bash
    $(venv) vctl status
    # or
    $(venv) tail -f volttron.log
    ```
    
That's it for this agent.  There are a lot of agents where this will be enough to do the
transition. For other items there may be some more things to modify, however VOLTTRON team will have a
full disclosure of those in the upcoming white paper and will update this repository accordingly.



