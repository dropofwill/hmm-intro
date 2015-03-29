# Credits

## Code snippets used throughout

```
vals = 1 <= arguments.length ? slice.call(arguments, 0) : [];

// Somewhere later...
app.some_function.apply(some_scope, vals);
```

This lets you have variable length argument lists. [Explanation here](http://www.informit.com/articles/article.aspx?p=1834699&seqNum=4)

``` void 0 ```

This is a safer way to use undefined since it is a statement (that *always* returns undefined) and cannot be overwritten (undefined can). [Explanation here](http://stackoverflow.com/questions/7452341/what-does-void-0-mean)
