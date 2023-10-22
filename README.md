##### Prerequisites

The setups steps expect following tools installed on the system.

- Ruby [3.1.2](https://github.com/organization/project-name/blob/master/.ruby-version#L1)
- Rails [7.0.8](https://github.com/organization/project-name/blob/master/Gemfile#L12)
- PostgreSQL 13 (brew install or download at https://postgresapp.com/)

##### 1. Check out the repository

##### 2. Edit database.yml file

Edit the database configuration as required.


##### 3. Create and setup the database

Run the following commands to create and setup the database.

```ruby
bundle exec rake db:create
bundle exec rake db:migrate
```

##### 4. Install the gems

```ruby
bundle install
```

##### 5. Start the Rails server

You can start the rails server using the command given below.

```ruby
rails s
```

And now you can visit the site with the URL http://localhost:3000

## Tests

#### Running Locally

You can run the tests using `bundle exec rspec spec`.

_Note:_ you need to ensure the test database is created and migrated first. This should already be done via the "Setup" steps above, but if not, `rails db:migrate` can be run separately, using the `RAILS_ENV=test` prefix.

