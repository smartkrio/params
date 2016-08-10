# Modules for work with parameters and client

## Settings

Database settings here: `lib/config/database.yml`

## Install dependensies

```
bundle install
```

## Migrate database

```
rake db:migrate
```

## How to use

Firstly in your script:
```
require './lib/outsoft.rb'
```

All methods for work with parameters here `lib/outsoft/params.rb`
To create parameter in root level:
```
Outsoft::Params.add name: 'my_new_param', value_type: 'int', value: 1, label: 'My new param'
```

To create parameter in nested level:
```
Outsoft::Params.add name: 'my_new_group', value_type: 'group', label: 'My new group'
Outsoft::Params.add_by_path path: 'my_new_group', name: 'my_new_nested_value', value_type: 'int', value: 1, label: 'My new nested value'
```

To update params:
```
Outsoft::Params.update path: 'my_new_group.my_new_nested_value', value: 12
```

To remove params:
```
Outsoft::Params.remove path: 'my_new_group.my_new_nested_value'
```


All methods for work with clients here `lib/outsoft/clients.rb`. 
It has method `create`, to create client:
```
Outsoft::Params.add name: 'new_group', value_type: 'group', label: 'My new group'
Outsoft::Params.add_by_path path: 'new_group', name: 'new_param', value_type: 'int', label: 'Some param', value: 10
Outsoft::Clients.create data: { id: 1 }
Outsoft::Clients.create data: { id: 2, extra: [['exists_param', 'some value']] }
```

To update clients:
```
Outsoft::Clients.update id: 1, predefined: [{'path' => 'new_group.new_param', 'value' => 11}], extra: [['Cat`s count', '1'] ,['Car model', 'Ford']]

```

See more examples in `spec/outsoft/*`

## How to import and export params

To set current environment:
``` OUTSOFT_ENV=<your_environment> <some script>```

Example: 
``` 
OUTSOFT_ENV=development rspec
OUTSOFT_ENV=development rake db:migrate

```

To export your params in test enveironment:
``` 
OUTSOFT_ENV=development rake db:export[test]

```

To import your params from test enveironment:
``` 
OUTSOFT_ENV=development rake db:import[test]

```