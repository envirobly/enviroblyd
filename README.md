# enviroblyd
Envirobly instance daemon

## Installation

```sh
gem install enviroblyd --no-document
```

## Local development

```sh
ruby -Ilib/ bin/enviroblyctl version

# Run the test server (separate tab)
bin/dev

# Point the daemon to the test server
export ENVIROBLYD_INIT_URL=http://localhost:11880/initialize
export ENVIROBLYD_IMDS_HOST=localhost:11880
export ENVIROBLYD_API_HOST=localhost:11880

ruby -Ilib/ bin/enviroblyd

# Sending a test message after daemon is running:
bin/python-send-tcp-message '{ "script": "ls", "url": "http://localhost:11880/command" }'
```

### Publishing the gem

```sh
gem build enviroblyd.gemspec
gem install ./enviroblyd-$(ruby -Ilib/ bin/enviroblyctl version).gem --no-document
gem push enviroblyd-$(ruby -Ilib/ bin/enviroblyctl version).gem
```
