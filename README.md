##### Prerequisites

The setups steps expect following tools installed on the system.

- Ruby [3.1.2](https://github.com/amratab/aspire/blob/main/.ruby-version#L1)
- Rails [7.0.8](https://github.com/amratab/aspire/blob/main/Gemfile#L7)
- PostgreSQL 13 (brew install or download at https://postgresapp.com/)

##### 1. Check out the repository

```bash
git clone git@github.com:amratab/aspire.git
```

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

##### Reports

- [Test coverage](https://github.com/amratab/aspire/blob/main/test_coverage_report.png)
- [ERD](https://github.com/amratab/aspire/blob/main/erd.pdf)
- [API Document](https://github.com/amratab/aspire/blob/main/api_document.pdf)

##### Description

- There are two types of users. Admin and Customers (based on enum value)
- Customers create loans with status pending. After this, using LoanService class, the installments get generated based on amount and term. Installments have pending status by default.
- An admin can see all the loans and a customer can see only their own loans.
- An admin can approve a loan updating the status of loan to approved and all its installments get udpated to status scheduled.
- Customer can view all the installments for their loan
- Admin can view installments for any loan.
- A user can repay their loan by pay api specifying the loan id and installment id.
- Once an installment is paid, the amount_paid is updated to the amount paid and status is updated to paid.
- If the loan amount is paid after the installment payment, loan is marked as paid and all the remaining installments are marked as paid.
- For validating amount paid in installment, I have followed this logic: If total loan amount pending is greater than installment amount then user can minimum of installment amount and pending loan amount. If total loan amount pending is less than installment amount, then user can pay the pending loan amount at max.

##### Choice explanations

- I have used services for transactional tasks like installment payments and loan creation with installments because this seems clean to either have all transactions succeed or none.
- I have written request specs to cover all happy and error cases for all APIs. I have also written unit test cases for models and some controller test cases and tried to achieve maximum coverage.
- I have used SimpleCov to generate test coverage report.
- I have generated API documentation using apimod and rspec-api-documentation.
- I have generated erd document using rails-erd.
  


