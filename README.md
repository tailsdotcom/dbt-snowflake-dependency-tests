# dbt-snowflake-dependency-tests
A DBT Package for testing dependencies of snowflake models

This is a [dbt](http://www.getdbt.com) package for asserting snowflake model
dependencies. It uses the `get_object_references` function in snowflake, and
is designed to be installed as a `post-hook` on models. It works by analysing
the created view, and looking at what it's object dependencies are and then
validating those against the given patterns.

_NB: Because it works by analysing the constructed views, it will not work on
materialised views, because they exist only as tables, not as views to be
interrogated._

## How to install
TBD

## How to Use
TBC

## What to expect
TBC

# Contributing
Contributions and pull requests are encouraged to this repo. Bear in mind that
there is currently no automated testing present, and so all changes will need
to be tested manually against a snowflake instance before releasing. Please
be patient for this process.
