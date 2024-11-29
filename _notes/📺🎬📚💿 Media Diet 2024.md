
# Television Shows

```dataview
table without id
	file.link as Show,
	rating as Rating, 
	last as "Last seen"
where
		contains(file.tags, "#shows") and 
	contains(file.tags, "#mediadiet2024")
sort rating desc
```



# Albums
```dataview
table without id
	file.link as Album,
	artist as Artist,
	rating as Rating,
	year as Year
where
	contains(file.tags, "#albums") and 
	contains(file.tags, "#mediadiet2024")
sort rating desc
```



# Movies
```dataview
table without id
	file.link as Movie,
	year as Year,
	rating as Rating,
	last as "Watched"
where
	contains(file.tags, "#movies") and 
	contains(file.tags, "#mediadiet2024")
sort rating desc
```



# Books

```dataview
table without id
	file.link as Book,
	author as Author,
	year as Year,
	rating as Rating,
	created as Added,
	genre as Genre
where
	contains(file.tags, "#books") and 
	contains(file.tags, "#mediadiet2024")
sort rating desc, date asc
```


# Articles

```dataview
table without id
	file.link as Article
where
	contains(file.tags, "#articles") and 
	contains(file.tags, "#shortlist") and
	file.ctime >= date(2024-01-01) AND file.ctime <=date(2024-12-12)
sort rating desc, date asc
```




Created [[2024-06-04]]