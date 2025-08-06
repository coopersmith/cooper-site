---
layout: page
title: Scrapbook
permalink: /scrapbook/
description: A small gallery of images from my scrapbook.
---

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/simplelightbox/2.14.1/simple-lightbox.min.css" crossorigin="anonymous" referrerpolicy="no-referrer"/>

<div class="gallery">
  {% assign gallery = site.static_files | where_exp: "file", "file.path contains 'assets/scrapbook/'" %}
  {% for file in gallery %}
    <a href="{{ file.path | relative_url }}">
      <img src="{{ file.path | relative_url }}" alt="Scrapbook image {{ forloop.index }}" loading="lazy">
    </a>
  {% endfor %}
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/simplelightbox/2.14.1/simple-lightbox.min.js" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
<script>
  document.addEventListener('DOMContentLoaded', function() {
    var lightbox = new SimpleLightbox('.gallery a');
  });
</script>

<style>
.gallery {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 1rem;
}
.gallery img {
  width: 100%;
  height: auto;
  display: block;
}
</style>
