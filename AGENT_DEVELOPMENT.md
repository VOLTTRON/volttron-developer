# VOLTTRON Agent Developer Instructions

## Requirements

System level requirements:

```bash
# Python 3.8 is required for the installation of VOLTTRON
sudo apt-get update
sudo apt-get install -y build-essential \
  libffi-dev \
  python3-dev \ 
  python3-venv \
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
    
 4. Create a directory for your agent code to go into
    ```bash
    $> mkdir mylistener
    ```
    
 5. Create an agent.py module within the mylistener directory with the following code.    

    ```python
    import logging
    
    from volttron import utils
    from volttron.utils.commands import vip_main
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
            vip_main(MyListener, version=__version__)
        except Exception as e:
            _log.exception('unhandled exception')
    if __name__ == '__main__':
        # Entry point for script
        sys.exit(main())
    ```
    
 6. Create Wheel and Source distribution
    ```bash
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

## Agents on both 8.x and Modular Code Base

In this tutorial the example/Listener agent will be ported to run on both VOLTTRON 8.x
and on the new modular framework.  At this point you must have cloned/downloaded
the VOLTTRON 8.x code in a folder called volttron.

This assumes you are comfortable with the current process of installing agents and working
with the patterns of 8.x VOLTTRON.

### Setup

 1. Create a directory for your agent
 2. Copy the current volttron/examples/ListenerAgent to your directory
 3. Modify the top of the file listener/agents.py file to have both import statements
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

        from volttron.utils.commands import vip_main
        from volttron.client.messaging.health import STATUS_GOOD
        from volttron.client.vip.agent import Agent, Core, PubSub
        from volttron.client.vip.agent.subsystems.query import Query
    ```
 4. Start VOLTTRON 8.x and install the agent from the new directory.
 5. Stop VOLTTRON and create a new virtual environment
 6. Activate the new envrionment
 7. pip install volttron-server (current version is 0.3.11)
 8. Remove the ~/.volttron directory as it is not backward compatible with 8.x
 9. Start VOLTTRON 
 10. Install the new agent from it's directory
 
That's it for this agent.  There are a lot of agents where this will be enough to do the
transition.  For other items there may be some more things to modify, however I will have a
full disclosure of those in the upcoming white paper and will update this repository as I go.



