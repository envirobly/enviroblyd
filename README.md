# enviroblyd
Envirobly instance daemon

## Installation

```sh
gem install enviroblyd --no-document
```

## Local development

```sh
ruby -Ilib/ bin/enviroblyctl version

# In development override the hosts:
export ENVIROBLYD_IMDS_HOST=envirobly.test
export ENVIROBLYD_API_HOST=envirobly.test

ruby -Ilib/ bin/enviroblyd
```

### Publishing the gem

```sh
gem build enviroblyd.gemspec
gem install ./enviroblyd-$(ruby -Ilib/ bin/enviroblyctl version).gem --no-document
gem push enviroblyd-$(ruby -Ilib/ bin/enviroblyctl version).gem
```
