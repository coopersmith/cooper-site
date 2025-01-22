---
title: Cooper Smith
description: Product Design Leadership in Brooklyn, NY
permalink: /cv/
---

## Work Experience

{% for role in site.data.cv.work_experience %}
### {{ role.company }}
**{{ role.title }}** • {{ role.location }} • {{ role.year }}
{% if role.url %}<a href="{{ role.url }}" target="_blank">↗</a>{% endif %}
{% endfor %}

## Projects

{% for project in site.data.cv.projects %}
### {{ project.title }}
{{ project.company }} • {{ project.year }}
{% if project.url %}<a href="{{ project.url }}" target="_blank">↗</a>{% endif %}
{% endfor %}

## Education

{% for edu in site.data.cv.education %}
### {{ edu.school }}
{% if edu.degree %}{{ edu.degree }} • {% endif %}{{ edu.location }} • {{ edu.year }}
{% if edu.url %}<a href="{{ edu.url }}" target="_blank">↗</a>{% endif %}
{% endfor %}

## Connect

{% for link in site.data.cv.social %}
- [{{ link.platform }}]({{ link.url }})
{% endfor %} 