# libcouchbase FFI bindings for Ruby

[![Build Status](https://secure.travis-ci.org/cotag/libcouchbase.svg)](http://travis-ci.org/cotag/libcouchbase)

An alternative to the official [couchbase-client](https://github.com/couchbase/couchbase-ruby-client)

* This client is non-blocking where possible using Fibers, which makes it simple to write performant code in Frameworks like [Rails](http://rubyonrails.org/).
* Client is threadsafe and reentrant

This is a low level wrapper around libcouchbase. For a more friendly ActiveModel interface see [couchbase-orm](https://github.com/acaprojects/couchbase-orm)

## Couchbase 5 Changes

The Couchbase 5 Admin Console blows away flags on documents if you edit them in the interface.
Flags were being used to store document formats, however these were mainly implemented for compatibility with the defunct official client.


To prevent this being an issue we've made the following changes from version 1.2 of this library:

1. All writes will result in valid JSON being saved to the database
   * No more `raw strings` they will be saved as `"raw strings"`
   * Existing raw strings will still be read correctly
2. Since there are no more raw strings, append / prepend are no longer needed (not that we ever used them)


## Runtime Support:

* Native Ruby
  * Blocks the current thread while performing operations
  * Multiple operations can occur simultaneously on different threads
  * For [Rails](http://rubyonrails.org/) and similar, this has optimal performance when running on [Puma](http://puma.io/)
* [EventMachine](https://github.com/eventmachine/eventmachine)
  * Requires the use of [em-synchrony](https://github.com/igrigorik/em-synchrony) or for the EM run block to be [wrapped by a fiber](https://github.com/igrigorik/em-http-request/blob/master/examples/fibered-http.rb#L27)
  * When running [Rails](http://rubyonrails.org/) you'll have best results with [Thin](https://github.com/macournoyer/thin) and [Rack Fiber Pool](https://github.com/alebsack/rack-fiber_pool)
  * Requests block the current Fiber, yielding so the reactor loop is not blocked
* [Libuv](https://github.com/cotag/libuv)
  * When running [Rails](http://rubyonrails.org/) you'll have best results with [SpiderGazelle](https://github.com/cotag/spider-gazelle)
  * Requests block the current Fiber, yielding so the reactor loop is not blocked

Syntax is the same across all runtimes and you can perform multiple operations simultaneously then wait for the results of those operations.

Operations are also aware of the context they are being executed in.
For instance if you perform a request in an EventMachine thread pool, it will execute as Native Ruby and on the event loop it'll be non-blocking.


## Installation

This GEM includes the [libcouchbase c-library](https://github.com/couchbase/libcouchbase) with requires [cmake](https://cmake.org/) for the build process.
The library is built on installation.

* Ensure [cmake](https://cmake.org/install/) is installed
* Run `gem install libcouchbase`


The library is designed to run anywhere [Rails](http://rubyonrails.org/) runs:

* Ruby 2.2+
* JRuby 9.1+
* Rubinius 3.76+


Tested on the following Operating Systems:

* OSX / MacOS
* Linux
* Windows
  * Ruby x64 2.4+ with MSYS2 DevKit


## Usage

First, you need to load the library:

```ruby
require 'libcouchbase'
```

The client will automatically adjust configuration when the cluster rebalances its nodes when nodes are added or deleted therefore this client is "smart".
By default the client will connect to the default bucket on localhost.

```ruby
bucket = Libcouchbase::Bucket.new
```

To connect to other buckets, other than the default

```ruby
# Same as Libcouchbase::Bucket.new
bucket = Libcouchbase::Bucket.new(hosts: '127.0.0.1', bucket: 'default', password: nil)

# To connect to other buckets, you can also specify multiple hosts:
bucket = Libcouchbase::Bucket.new(hosts: ['cb1.org', 'cb2.org'], bucket: 'app_data', password: 'goodluck')
```

By default connections use `:quiet` mode. This mean it won't raise
exceptions when the given key does not exist:

```ruby
bucket.get(:missing_key)            #=> nil
```

It could be useful when you are trying to make you code a bit efficient
by avoiding exception handling. (See `#add` and `#replace` operations).
You can turn on these exceptions by passing `:quiet => false` when you
are instantiating the connection or change corresponding attribute:

```ruby
bucket.quiet = false
bucket.get("missing-key")                    #=> raise Libcouchbase::Error::KeyNotFound
bucket.get("missing-key", :quiet => true)    #=> nil
```


The library supports both synchronous and asynchronous operations.
In asynchronous mode all operations will return control to caller
without blocking current thread. By default all operations are
synchronous, using Fibers on event loops to prevent blocking the
reactor. Use asynchronous operations if you want mulitple operations
to execute in parallel.


```ruby
# Perform operations in Async and then wait for the results
results = []
results << bucket.get(:key1, async: true)
results << bucket.get(:key2, async: true)
bucket.wait_results(results)          #=> ['key1_val', 'key2_val']

# Is equivalent to:
bucket.get(:key1, :key2)              #=> ['key1_val', 'key2_val']

# Process result without waiting or blocking the thread at all
# This will execute on the couchbase reactor loop so it is
# recommended not to block in the callback - spin up a new thread
# or schedule the work to occur next_tick etc
promise = bucket.get(:key1, async: true)
promise.then  { |result| puts result }
promise.catch { |error|  puts error  }
promise.finally { puts 'operation complete' }
```


### Get

```ruby
val = bucket.get("foo")

# Get extended details
result = bucket.get("foo", extended: true)
result.key      #=> "foo"
result.value    #=> {some: "value"}
result.cas      #=> 123445
result.metadata #=> {flags: 0}
```


Get multiple values. In quiet mode will put `nil` values on missing
positions:

```ruby
vals = bucket.get(:foo, :bar, "baz")
```

Hash-like syntax

```ruby
val = bucket[:foo]
```

Return a key-value hash

```ruby
val = bucket.get(:foo, :bar, "baz", assemble_hash: true)
val #=> {:foo => val1, :bar => val2, "baz" => val3}
```


### Touch

```ruby
# Expire in 30 seconds
bucket.touch(:foo, expire_in: 30
bucket.touch(:foo, ttl: 30)
bucket.touch(:foo, expire_at: (Time.now + 30))
```


### Set

The add command will fail if the key already exists. It accepts the same
options as set command above.

```ruby
bucket.add("foo", "bar")
bucket.add("foo", "bar", ttl: 30)
```


### Replace

The replace command will fail if the key already exists. It accepts the same
options as set command above.

```ruby
bucket.replace("foo", "bar")
```


### Increment/Decrement

These commands increment the value assigned to the key.
A Couchbase increment is atomic on a distributed system.

```ruby
bucket.set(:foo, 1)
bucket.incr(:foo)           #=> 2
bucket.incr(:foo, delta: 2) #=> 4
bucket.incr(:foo, 2)        #=> 6
bucket.incr(:foo, -1)       #=> 5

bucket.decr(:foo)           #=> 4
bucket.decr(:foo, 2)        #=> 2

bucket.incr(:missing1, initial: 10)      #=> 10
bucket.incr(:missing1, initial: 10)      #=> 11
bucket.incr(:missing2, create: true)     #=> 0
bucket.incr(:missing2, create: true)     #=> 1
```


### Delete

```ruby
bucket.delete(:foo)
bucket.delete(:foo, cas: 8835713818674332672)
```


### Flush

Delete all items in the bucket. This must be enabled on the cluster to work

```ruby
bucket.flush
```

### Subdocument queries

These allow you to modify keys within documents. There is a block form.

```ruby
c.subdoc(:foo) { |subdoc|
    subdoc.get('sub.key')
    subdoc.exists?('other.key')
    subdoc.get_count('some.array')
} # => ["sub key val", true, 23]
```

There is an inline form

```ruby
c.subdoc(:foo).get(:bob).execute! # => { age: 13, working: false }
c.subdoc(:foo)
    .get(:bob)
    .get(:jane)
    .execute! # => [{ age: 13, working: false }, { age: 47, working: true }]
```

You can't perform lookups and mutations in the same request.

```ruby
# multi-mutation example
c.subdoc(:foo)
    .counter('bob.age', 1)
    .dict_upsert('bob.address', {
        number: 23
        street: 'Daily Ave'
        suburb: 'Some Town'
    }).execute! # => 14 (the new counter value)
```

By default, subkeys are created if they don't exist

```ruby
c.put(:some_key, {name: 'bob'})
c.subdoc(:some_key).dict_add('non.existant.key', {
  random: 123,
  hash: 'values'
}).execute! 
```

Possible lookup operations are:

* `get`
* `exists?`
* `get_count`

Possible mutation operations

* `counter` increments the subkey by integer value passed
* `dict_upsert` replaces the subkey with value passed
* `dict_add`
* `array_add_first`
* `array_add_last`
* `array_add_unique`
* `array_insert`
* `replace`

You can see additional docs here: https://developer.couchbase.com/documentation/server/current/sdk/subdocument-operations.html


### Views (Map/Reduce queries)

If you store structured data, they will be treated as documents and you
can handle them in map/reduce function from Couchbase Views. For example,
store a couple of posts using memcached API:

```ruby
    c['biking'] = {:title => 'Biking',
                   :body => 'My biggest hobby is mountainbiking. The other day...',
                   :date => '2009/01/30 18:04:11'}
    c['bought-a-cat'] = {:title => 'Bought a Cat',
                         :body => 'I went to the the pet store earlier and brought home a little kitty...',
                         :date => '2009/01/30 20:04:11'}
    c['hello-world'] = {:title => 'Hello World',
                        :body => 'Well hello and welcome to my new blog...',
                        :date => '2009/01/15 15:52:20'}
```

Now let's create design doc with sample view and save it in file
'blog.json':

```JSON
    {
      "_id": "_design/blog",
      "language": "javascript",
      "views": {
        "recent_posts": {
          "map": "function(doc){if(doc.date && doc.title){emit(doc.date, doc.title);}}"
        }
      }
    }
```

This design document could be loaded into the database like this (also you can
pass the ruby Hash or String with JSON encoded document):

```ruby
    c.save_design_doc(File.open('blog.json'))
```

To execute view you need to fetch it from design document `_design/blog`:

```ruby
    blog = c.design_docs['blog']
    blog.views                       #=> ["recent_posts"]

    # Returns an Enumerator
    res = blog.view('recent_posts')  #=> #<Libcouchbase::Results:0x007fbaed12c988>

    # Results are lazily loaded by the enumerator
    # Results are stored for re-use until `res` goes out of scope
    # Actual database query happens here, by default documents are included
    res.each do |row|
        # Returns extended results by default
        row.key
        row.value
        row.cas
        row.metadata #=> {emitted: val, geometry: spatial_val, format: :document, flags: 0}
    end

    # You can however stream results to save memory and the results are not saved
    res.stream do |row|
        # Row is cleaned up as soon as possible
    end

    # For IDs only:
    res = blog.view(:recent_posts, include_docs: false)
```


### N1QL Queries

If N1QL indexes have been created, then you can query them

```ruby
results = bucket.n1ql
  .select('*')
  .from(:default)
  .where('port == 10001')
  .results

# Results are lazily loaded by the enumerator
# Results are stored for re-use until `results` goes out of scope
# Actual database query happens here
results.each do |row|
    # Each row is a Hash of the data requested
end

# You can however stream results to save memory and the results are not saved
results.stream do |row|
    # Row is cleaned up as soon as possible
end
```


### Full Text Search

If Full Text Search indexes have been created, then you can query them

```ruby
results = bucket.full_text_search(:index_name, 'query')

# Results are lazily loaded by the enumerator
# Results are stored for re-use until `res` goes out of scope
# Actual database query happens here
results.each do |row|
    # Each row is a Hash of the data requested
end

# You can however stream results to save memory and the results are not saved
results.stream do |row|
    # Row is cleaned up as soon as possible
end
```

Full text search supports more complex queries, you can pass in a Hash as the query
and provide any other options supported by FTS: http://developer.couchbase.com/documentation/server/current/fts/fts-queries.html

```ruby
bucket.full_text_search(:index_name, {
    boost: 1,
    query: "geo.accuracy:rooftop"
}, size: 10, from: 0, explain: true, fields: ['*'])
```


