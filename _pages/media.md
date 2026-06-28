---
layout: page
title: Media Diet
id: media
permalink: /media/
---

# Media Diet

An index of what I've been reading, watching, and listening to — shows, movies, books, and the occasional year-in-review.

<section class="media-section">
  <p class="media-label">Year in review</p>
  <ul class="media-list">
    {% comment %}Top-level yearly recaps tagged mediadiet (or mediadiet/YYYY),
       excluding individual entries that live in MediaDiet/ subfolders.{% endcomment %}
    {% assign all_notes = site.notes | sort: "created_at_timestamp" | reverse %}
    {% for note in all_notes %}
      {% unless note.path contains 'MediaDiet/' %}
        {% assign is_diet = false %}
        {% for tag in note.tags %}
          {% if tag contains 'mediadiet' %}{% assign is_diet = true %}{% endif %}
        {% endfor %}
        {% if is_diet %}
          <li><a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a></li>
        {% endif %}
      {% endunless %}
    {% endfor %}
  </ul>
</section>

<section class="media-section">
  <p class="media-label">🎬 Movies</p>
  <ul class="media-list">
    {% assign movies = site.notes | where: "title", "Coop's 100 movies" | first %}
    {% if movies %}
      <li><a class="internal-link" href="{{ site.baseurl }}{{ movies.url }}">{{ movies.title }}</a></li>
    {% endif %}
  </ul>
</section>

<section class="media-section">
  <p class="media-label">📚 Books</p>
  <ul class="media-list">
    {% assign books = site.notes | where_exp: "n", "n.path contains 'MediaDiet/Books'" | sort: "title" %}
    {% for book in books %}
      <li><a class="internal-link" href="{{ site.baseurl }}{{ book.url }}">{{ book.title }}</a></li>
    {% endfor %}
  </ul>
</section>

<style>
  .wrapper { max-width: 46em; }

  .media-section { margin-top: 2.5em; }

  .media-label {
    font-size: var(--text-caption);
    text-transform: uppercase;
    letter-spacing: var(--tracking-caps);
    color: var(--color-text-tertiary);
    font-weight: var(--weight-medium);
    margin: 0 0 0.9em;
  }

  .media-list {
    list-style: none;
    margin: 0;
    padding: 0;
  }

  .media-list li {
    margin: 0;
    line-height: var(--leading-relaxed);
  }

  .media-list li + li {
    margin-top: 0.6em;
  }

  .media-list a {
    text-decoration: none;
    font-weight: var(--weight-medium);
    color: var(--color-text-primary);
    text-decoration-color: transparent;
  }

  .media-list a:hover {
    text-decoration: underline;
    text-decoration-color: var(--color-accent);
  }
</style>
