---
title: Changelog
description: A running, human-readable log of what I've been building on this site.
permalink: /changelog/
---

<h1>Changelog</h1>
<p class="subtitle">A running, human-readable log of what I've been building on this site — written up from each merged pull request.</p>

{% comment %}
  _data/changelog.yml is maintained newest-first (by date, then PR number) by
  scripts/generate_changelog.rb, so we group in file order rather than re-sorting.
  group_by_exp keeps first-appearance order, giving newest months first.
{% endcomment %}
{% assign groups = site.data.changelog | group_by_exp: "e", "e.date | date: '%B %Y'" %}

<div class="changelog">
  {% for group in groups %}
    <section class="cl-group">
      <p class="cl-month">{{ group.name }}</p>
      <ul class="cl-list">
        {% for e in group.items %}
          <li class="cl-entry">
            <div class="cl-line">
              <span class="cl-date">{{ e.date | date: "%b %-d" }}</span>
              <span class="cl-body">
                <span class="cl-title">{{ e.title }}</span>
                {% if e.category %}<span class="cl-tag cl-tag--{{ e.category }}">{{ e.category }}</span>{% endif %}
                <span class="cl-summary">{{ e.summary }}</span>
                {% if e.url %}<a class="cl-link" href="{{ e.url }}">#{{ e.number }} ↗</a>{% endif %}
              </span>
            </div>
          </li>
        {% endfor %}
      </ul>
    </section>
  {% endfor %}
</div>
