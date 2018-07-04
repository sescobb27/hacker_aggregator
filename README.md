# HackerAggregator

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## API
```
stories_path  GET  /api/stories      HackerAggregator.StoriesController :index
stories_path  GET  /api/stories/:id  HackerAggregator.StoriesController :show
```

## Pagination
```
stories_path  GET  /api/stories?from=last_story_id      HackerAggregator.StoriesController :index
```
