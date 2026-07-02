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

<style>
  .wrapper { max-width: 46em; }

  .changelog { margin-top: 2.5em; }

  .cl-group { margin-top: 2.6em; }
  .cl-group:first-child { margin-top: 1.6em; }

  .cl-month {
    font-size: var(--text-caption);
    text-transform: uppercase;
    letter-spacing: var(--tracking-caps);
    color: var(--color-text-tertiary);
    font-weight: var(--weight-medium);
    margin: 0 0 1.1em;
    padding-bottom: 0.5em;
    border-bottom: 0.25px solid var(--color-border);
  }

  .cl-list { list-style: none; margin: 0; padding: 0; }
  .cl-entry + .cl-entry { margin-top: 1.5em; }

  .cl-line { display: flex; gap: 1em; align-items: baseline; }

  .cl-date {
    flex: 0 0 auto;
    min-width: 3.6em;
    color: var(--color-text-tertiary);
    font-size: 0.9em;
    font-variant-numeric: tabular-nums;
    padding-top: 0.05em;
  }

  .cl-body { flex: 1 1 auto; min-width: 0; }

  .cl-title {
    font-weight: var(--weight-semibold);
    color: var(--color-text-primary);
  }

  .cl-summary {
    display: block;
    margin-top: 0.3em;
    color: var(--color-text-secondary);
    line-height: var(--leading-relaxed);
  }

  .cl-tag {
    display: inline-block;
    margin-left: 0.5em;
    padding: 0.08em 0.5em;
    border-radius: 999px;
    font-size: 0.68em;
    text-transform: uppercase;
    letter-spacing: var(--tracking-caps);
    font-weight: var(--weight-medium);
    vertical-align: 0.12em;
    color: var(--color-text-tertiary);
    background: var(--color-bg-secondary);
    border: 0.5px solid var(--color-border);
  }

  .cl-link {
    display: inline-block;
    margin-top: 0.35em;
    font-size: 0.82em;
    font-variant-numeric: tabular-nums;
    color: var(--color-text-tertiary);
    text-decoration: none;
  }
  .cl-link:hover { color: var(--color-text-primary); }

  @media (max-width: 600px) {
    .cl-line { display: block; }
    .cl-date { display: block; min-width: 0; margin-bottom: 0.25em; }
  }
</style>
