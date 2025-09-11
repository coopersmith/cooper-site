---
layout: page
title: 2025 Media Diet
permalink: /2025-reading-list/
---

# 2025 Media Diet

A dynamic view of all the books, movies, and TV shows I'm consuming in 2025, automatically pulled from my notes.

## 📚 Books

### Currently Reading
{% assign current_books = site.notes | where_exp: "item", "item.tags contains 'books'" | where_exp: "item", "item.tags contains 'MediaDiet2025' or item.tags contains 'mediadiet/2025'" | where_exp: "item", "item.start and item.end == nil" %}

{% if current_books.size > 0 %}
<div class="media-grid">
  {% for book in current_books %}
    <div class="media-item media-item--reading">
      <div class="media-status">📖 Reading</div>
      <h4><a href="{{ site.baseurl }}{{ book.url }}">{{ book.title }}</a></h4>
      {% if book.author %}
        <p class="media-author">by {{ book.author | join: ", " }}</p>
      {% endif %}
      {% if book.start %}
        <p class="media-date">Started: {{ book.start | date: "%B %d, %Y" }}</p>
      {% endif %}
    </div>
  {% endfor %}
</div>
{% else %}
<p><em>No books currently being read.</em></p>
{% endif %}

### Completed Books
{% assign completed_books = site.notes | where_exp: "item", "item.tags contains 'books'" | where_exp: "item", "item.tags contains 'MediaDiet2025' or item.tags contains 'mediadiet/2025'" | where_exp: "item", "item.end" | sort: "end" | reverse %}

{% if completed_books.size > 0 %}
<div class="media-grid">
  {% for book in completed_books %}
    <div class="media-item media-item--completed">
      <div class="media-status">✅ Completed</div>
      <h4><a href="{{ site.baseurl }}{{ book.url }}">{{ book.title }}</a></h4>
      {% if book.author %}
        <p class="media-author">by {{ book.author | join: ", " }}</p>
      {% endif %}
      {% if book.rating %}
        <p class="media-rating">
          {% assign stars = book.rating %}
          {% for i in (1..stars) %}★{% endfor %}
          {% assign empty_stars = 10 | minus: stars %}
          {% for i in (1..empty_stars) %}☆{% endfor %}
          ({{ book.rating }}/10)
        </p>
      {% endif %}
      {% if book.end %}
        <p class="media-date">Finished: {{ book.end | date: "%B %d, %Y" }}</p>
      {% endif %}
    </div>
  {% endfor %}
</div>
{% else %}
<p><em>No books completed yet this year.</em></p>
{% endif %}

## 🎬 Movies

{% assign movies_2025 = site.notes | where_exp: "item", "item.tags contains 'movies' or item.categories contains 'Movies'" | where_exp: "item", "item.tags contains 'MediaDiet2025' or item.tags contains 'mediadiet/2025'" | sort: "date" | reverse %}

{% if movies_2025.size > 0 %}
<div class="media-grid">
  {% for movie in movies_2025 %}
    <div class="media-item media-item--movie">
      <div class="media-status">🎬 Movie</div>
      <h4><a href="{{ site.baseurl }}{{ movie.url }}">{{ movie.title }}</a></h4>
      {% if movie.director %}
        <p class="media-author">Directed by {{ movie.director | join: ", " }}</p>
      {% endif %}
      {% if movie.year %}
        <p class="media-year">{{ movie.year }}</p>
      {% endif %}
      {% if movie.rating %}
        <p class="media-rating">
          {% assign stars = movie.rating %}
          {% for i in (1..stars) %}★{% endfor %}
          {% assign empty_stars = 10 | minus: stars %}
          {% for i in (1..empty_stars) %}☆{% endfor %}
          ({{ movie.rating }}/10)
        </p>
      {% endif %}
      {% if movie.date %}
        <p class="media-date">Watched: {{ movie.date | date: "%B %d, %Y" }}</p>
      {% endif %}
    </div>
  {% endfor %}
</div>
{% else %}
<p><em>No movies logged yet this year.</em></p>
{% endif %}

## 📺 TV Shows

{% assign tv_2025 = site.notes | where_exp: "item", "item.tags contains 'tv' or item.tags contains 'television' or item.categories contains 'TV'" | where_exp: "item", "item.tags contains 'MediaDiet2025' or item.tags contains 'mediadiet/2025'" | sort: "date" | reverse %}

{% if tv_2025.size > 0 %}
<div class="media-grid">
  {% for show in tv_2025 %}
    <div class="media-item media-item--tv">
      <div class="media-status">📺 TV</div>
      <h4><a href="{{ site.baseurl }}{{ show.url }}">{{ show.title }}</a></h4>
      {% if show.creator %}
        <p class="media-author">Created by {{ show.creator | join: ", " }}</p>
      {% endif %}
      {% if show.season %}
        <p class="media-season">Season {{ show.season }}</p>
      {% endif %}
      {% if show.rating %}
        <p class="media-rating">
          {% assign stars = show.rating %}
          {% for i in (1..stars) %}★{% endfor %}
          {% assign empty_stars = 10 | minus: stars %}
          {% for i in (1..empty_stars) %}☆{% endfor %}
          ({{ show.rating }}/10)
        </p>
      {% endif %}
      {% if show.date %}
        <p class="media-date">Watched: {{ show.date | date: "%B %d, %Y" }}</p>
      {% endif %}
    </div>
  {% endfor %}
</div>
{% else %}
<p><em>No TV shows logged yet this year.</em></p>
{% endif %}

## 📊 2025 Stats

{% assign total_books = completed_books.size %}
{% assign total_movies = movies_2025.size %}
{% assign total_tv = tv_2025.size %}
{% assign reading_books = current_books.size %}

<div class="media-stats">
  <div class="stat-item">
    <span class="stat-number">{{ total_books }}</span>
    <span class="stat-label">Books Completed</span>
  </div>
  <div class="stat-item">
    <span class="stat-number">{{ reading_books }}</span>
    <span class="stat-label">Currently Reading</span>
  </div>
  <div class="stat-item">
    <span class="stat-number">{{ total_movies }}</span>
    <span class="stat-label">Movies Watched</span>
  </div>
  <div class="stat-item">
    <span class="stat-number">{{ total_tv }}</span>
    <span class="stat-label">TV Shows</span>
  </div>
</div>

---

<small>This page automatically updates as I add new media notes with the `MediaDiet2025` tag. Check back regularly to see what I'm consuming!</small>