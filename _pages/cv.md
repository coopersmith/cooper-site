---
title: Cooper Smith
description: Product Design Leadership in Brooklyn, NY
permalink: /cv/
---

<div class="cv-container">
  <header class="cv-header">
    <h1>{{ site.data.cv.general.name }}</h1>
    <p class="byline">{{ site.data.cv.general.byline }}</p>
  </header>

  <section class="work-experience">
    <h2>Work Experience</h2>
    {% for role in site.data.cv.work_experience %}
      <div class="entry">
        <div class="year">{{ role.year }}</div>
        <div class="content">
          <h3>{{ role.company }}</h3>
          <div class="meta">
            {{ role.title }} • {{ role.location }}
            {% if role.url %}<a href="{{ role.url }}" class="external-link" target="_blank">↗</a>{% endif %}
          </div>
        </div>
      </div>
    {% endfor %}
  </section>

  <section class="projects">
    <h2>Projects</h2>
    {% for project in site.data.cv.projects %}
      <div class="entry">
        <div class="year">{{ project.year }}</div>
        <div class="content">
          <h3>{{ project.title }}</h3>
          <div class="meta">
            {{ project.company }}
            {% if project.url %}<a href="{{ project.url }}" class="external-link" target="_blank">↗</a>{% endif %}
          </div>
          {% if project.collaborators %}
            <div class="collaborators">
              with 
              {% for collaborator in project.collaborators %}
                <a href="{{ collaborator.url }}" class="external-link" target="_blank">{{ collaborator.name }}</a>{% unless forloop.last %}, {% endunless %}
              {% endfor %}
            </div>
          {% endif %}
        </div>
      </div>
    {% endfor %}
  </section>

  <section class="education">
    <h2>Education</h2>
    {% for edu in site.data.cv.education %}
      <div class="entry">
        <div class="year">{{ edu.year }}</div>
        <div class="content">
          <h3>{{ edu.school }}</h3>
          <div class="meta">
            {% if edu.degree %}{{ edu.degree }} • {% endif %}{{ edu.location }}
            {% if edu.url %}<a href="{{ edu.url }}" class="external-link" target="_blank">↗</a>{% endif %}
          </div>
        </div>
      </div>
    {% endfor %}
  </section>

  <section class="social">
    <h2>Connect</h2>
    {% for link in site.data.cv.social %}
      <div class="entry">
        <div class="year"></div>
        <div class="content">
          <a href="{{ link.url }}" class="external-link" target="_blank">
            {{ link.platform }}
            <span class="handle">@{{ link.handle }}</span>
          </a>
        </div>
      </div>
    {% endfor %}
  </section>
</div> 