# enviroblyd
Envirobly instance daemon

```sh
ruby -Ilib/ bin/enviroblyd version

# In development override the hosts:
export ENVIROBLYD_IMDS_HOST=envirobly.test
export ENVIROBLYD_API_HOST=envirobly.test

ruby -Ilib/ bin/enviroblyd boot
```
