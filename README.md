I18n-compatible backend for the [Cortex localization engine](cb-talent-development/cortex).

Install
=======

    gem install i18n-backend-cortex

Usage
=====

Initialize the backend with the Cortex host, and the UUID of the localization you are requesting.

```Ruby
require 'i18n/backend/cortex'

I18n.backend = I18n::Backend::Cortex.new({host: 'http://localhost:3000/', uuid: '61267710-4286-4db9-a074-3dd5ae9993c1'})
```

### Polling
Tries to update all used translations every 10 minutes (using `ETag` and `:cache`), can be stopped via `I18n.backend.stop_polling`.

If a `:cache` is given, all backends pick one master to do the polling, all others refresh from `:cache`

```Ruby
require 'i18n/backend/cortex'

I18n.backend = I18n::Backend::Cortex.new({host: 'http://localhost:3000/', uuid: '61267710-4286-4db9-a074-3dd5ae9993c1', cache: Rails.cache})

I18n.t('some.key') == "Old value"
# change in backend + wait 30 minutes
I18n.t('some.key') == "New value"
```

### :cache
If you pass `:cache => Rails.cache`, translations will be loaded from cache and updated in the cache.

The cache **MUST** support `:unless_exist`, so [gem_of_thrones](https://github.com/grosser/gem_of_thrones) can do its job. `MemCacheStore` + `LibmemcachedStore` + `ActiveSupport::Cache::MemoryStore` (edge) should work.

### Exceptions
To handle http exceptions provide e.g. `:exception_handler => lambda{|e| puts e }` (prints to stderr by default).

### Fallback
If the http backend is down, it does not translate, but also does not constantly try to poll for new translations. Your app will be untranslated, but not down.

You should either use `:default` for all `I18n.t` or use a `Chain`, so when Cortex is down, an app-defined English translation is used, for example.

```Ruby
I18n.backend = I18n::Backend::Chain.new(
  I18n::Backend::Cortex.new({host: 'http://localhost:3000/', uuid: '61267710-4286-4db9-a074-3dd5ae9993c1'}),
  I18n::Backend::Simple.new
)
```

Authors
======
[Colin Ewen](https://github.com/casao), [CB Content Enablement](https://github.com/cb-talent-development)

Forked from [i18n-backend-http](https://github.com/grosser/i18n-backend-http), created by [Michael Grosser](http://grosser.it)
