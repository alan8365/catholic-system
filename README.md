# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

- Ruby version
  - ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [arm64-darwin21]

## Database initialization

Testing: 
```shell
rake db:test:prepare
```

## Swagger
Create an integration spec to describe and test your API.
```shell
rails generate rspec:swagger API::MyController
```

Make swagger json file before spec file change
```shell
rake rswag:specs:swaggerize
```


## TODO

* System dependencies

* Configuration

* Database creation

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
