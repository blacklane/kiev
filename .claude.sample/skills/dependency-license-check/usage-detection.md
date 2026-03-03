# Usage Detection: Production vs Dev/Test

How to determine whether a dependency is used in production runtime or only in dev/test/CI.


## Dependency Files by Language
- **Ruby:** `Gemfile`, `Gemfile.lock`

---
## Ruby

- Default group in `Gemfile` -> **Production** (loaded at runtime)
- `:development`, `:test` groups -> **Dev/test only**

```ruby
# Gemfile — production gem
gem 'rails'
gem 'pg'

# Gemfile — dev/test only
group :development, :test do
  gem 'rspec-rails'
  gem 'rubocop'
end
```

**Check which group a gem belongs to:**
```bash
# Look at the Gemfile directly
grep '<gem_name>' Gemfile
# Check if the gem is in a dev/test group
grep -A2 'group :development' Gemfile | grep '<gem_name>'
grep -A2 'group :test' Gemfile | grep '<gem_name>'
```

**When installing**, always add to the correct group:
- `bundle add <gem>` -> adds to default group (production)
- `bundle add <gem> --group development,test` -> adds to dev/test group

**Common dev/test gems** (should NOT be in default group): rspec, rubocop, pry, byebug, factory_bot, faker, simplecov, webmock, vcr.

**Note:** Bundler's `require: false` does NOT make a gem dev-only — it just prevents auto-require. The group determines production vs dev/test.

---

## Standalone Binaries vs Linked Libraries

For restricted licenses (GPL/LGPL/AGPL), the distinction between standalone binaries and linked libraries matters:

- **Standalone binary/CLI** (e.g., a linter, formatter, compiler): Runs as a separate process. Not linked into our code. **Allowed in dev/CI.**
- **Linked library** (e.g., imported Go package, npm dependency bundled in build, Gradle `implementation` dep, SPM linked target): Compiled/bundled into our application. **Restricted in production.**
