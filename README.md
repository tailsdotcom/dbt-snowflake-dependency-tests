# DBT Snowflake Dependency Tests
A DBT Package for testing dependencies of snowflake models. This was developed
at a hackday at [tails.com](http://tails.com/careers) and is used in our production
dbt architecture.

> *tl;dr:* If you use DBT and Snowflake, use this to make sure that you keep your
> dependencies tidy and understandable.

This is a [dbt](http://www.getdbt.com) package for asserting snowflake model
dependencies. It uses the `get_object_references` function in snowflake, and
is designed to be installed as a `post-hook` on models. It works by analysing
the created view, and looking at what it's object dependencies are and then
validating those against the given patterns.

_NB: Because it works by analysing the constructed views, it will not work on
materialised views, because they exist only as tables, not as views to be
interrogated._

If you like dbt, like dogs and live in the London area - maybe you'll like
working at [tails.com](http://tails.com/careers). If that sounds up your street,
then get in touch. We're always looking for smart people and we'd love to hear from you!

## How to install
To install the package just add it to your `packages.yml` file. If you've never
used packages before, then you can [read more about them here](https://docs.getdbt.com/docs/package-management).

```yaml
packages:
  - git: "https://github.com/tailsdotcom/dbt-snowflake-dependency-tests.git"
    revision: "0.1.0"
```

## How to Use
The package is designed to be run as a `post-hook`, so you can simply reference
it in your `dbt_project.yml`.

```yaml
models:
  my_project:
    base:
      schema: base
      materialized: view
      post-hook:
        - "{{ dbt_sf_dep_check.assert_refs(allow_rules=['foo_db\\..*', 'bar_db\\..*'], except_models=['my_fancy_model']) }}"
```

The function `dbt_sf_dep_check.assert_refs` accepts two key word arguments:
- `allow_rules` which is a list of regex expressions to match combinations of
  database and schema names. For example `'foo_db\\..*'` will match any of the
  schemas in the database `FOO_DB` (yep it's case insensitive). Note that you
  you need to escape any backslashes which you want to appear in your eventual
  regex, as otherwise the yaml parser will get rid of them.
- `expect_models` which accepts a list of model names to skip the checks for.
  Given that adding it as a `post-hook` for a schema will run it for all models,
  you may still have some which don't play nice. In particular any models referencing
  snowflake performance tables will probably fail and will need to be in this list.

NB: Because we're calling a macro in the dbt jinja context, your patterns can include
references is the `target`, for example below where we want to make sure that we only
depend on objects in the current target database and schema with the extension `_base`.

```
post-hook:
    - "{{ dbt_sf_dep_check.assert_refs(allow_rules=[target.database + '\\.' + target.schema + '_base'] }}"
```

## What to expect
If any of your models don't follow the rules you've set above, then you'll get an
error at runtime.

```
...
Completed with 1 errors:

Database Error in model my_problem_model (models/base/my_problem_model.sql)
  Invalid Dependencides for view. Invalid dependencies: PROBLEM_DB.PROBLEM_SCHEMA. Allowed patterns are: ['foo_db\\..*', 'bar_db\\..*']
  compiled SQL at target/compiled/my_project/base/my_problem_model.sql
```

The error message helpfully says which dependent object it's found, and reminds
the user what values *are* allowed.

# Contributing
Contributions, feedback, issues and pull requests are encouraged to this repo. Bear in mind that
there is currently no automated testing present, and so all changes will need
to be tested manually against a snowflake instance before releasing. Please
be patient for this process.
