---
layout: page
title: Best Photos
permalink: /best-photos/
description: A curated collection of my favorite photographs from travels and adventures.
---

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/simplelightbox/2.14.1/simple-lightbox.min.css" crossorigin="anonymous" referrerpolicy="no-referrer"/>

# Best Photos

A carefully curated collection of my favorite photographs from various travels and adventures around the world.

<div class="best-photos-gallery">
  <!-- Como, Italy -->
  <a href="{{ site.baseurl }}/assets/como2023/Como - 1.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/como2023/Como - 1.jpeg" alt="Lake Como sunset reflection" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/lisbon/Lisbon - 1.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/lisbon/Lisbon - 1.jpeg" alt="Lisbon street scene" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/marthasvineyard/20200720-L1001893.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/marthasvineyard/20200720-L1001893.jpeg" alt="Martha's Vineyard coastal view" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/como2023/Como - 5.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/como2023/Como - 5.jpeg" alt="Como architecture detail" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/southafrica2024/DSC01170.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/southafrica2024/DSC01170.jpeg" alt="South Africa landscape" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/paris2022/Paris - 2.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/paris2022/Paris - 2.jpeg" alt="Parisian street photography" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/lisbon/Lisbon - 7.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/lisbon/Lisbon - 7.jpeg" alt="Lisbon architecture" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/como2023/Como - 3.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/como2023/Como - 3.jpeg" alt="Lake Como villa" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/marthasvineyard/348540_0015_Original.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/marthasvineyard/348540_0015_Original.jpeg" alt="Martha's Vineyard film photography" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/southafrica2024/DSC01619.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/southafrica2024/DSC01619.jpeg" alt="South Africa wildlife" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/lisbon/Lisbon - 10.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/lisbon/Lisbon - 10.jpeg" alt="Lisbon cityscape" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/paris2022/Paris - 4.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/paris2022/Paris - 4.jpeg" alt="Paris cafe culture" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/como2023/Como - 8.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/como2023/Como - 8.jpeg" alt="Como lakeside moment" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/marthasvineyard/348540_0018_Original.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/marthasvineyard/348540_0018_Original.jpeg" alt="Martha's Vineyard beach scene" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/southafrica2024/DSC02282.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/southafrica2024/DSC02282.jpeg" alt="South Africa adventure" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/lisbon/Lisbon - 5.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/lisbon/Lisbon - 5.jpeg" alt="Lisbon golden hour" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/como2023/Como - 11.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/como2023/Como - 11.jpeg" alt="Como evening light" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/paris2022/Paris - 1.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/paris2022/Paris - 1.jpeg" alt="Paris street art" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/marthasvineyard/348541_0015_Original.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/marthasvineyard/348541_0015_Original.jpeg" alt="Martha's Vineyard nature" loading="lazy">
  </a>
  
  <a href="{{ site.baseurl }}/assets/southafrica2024/DSC01739.jpeg" class="gallery-item">
    <img src="{{ site.baseurl }}/assets/southafrica2024/DSC01739.jpeg" alt="South Africa sunset" loading="lazy">
  </a>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/simplelightbox/2.14.1/simple-lightbox.min.js" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
<script>
  document.addEventListener('DOMContentLoaded', function() {
    var lightbox = new SimpleLightbox('.best-photos-gallery a', {
      nav: true,
      navText: ['‹', '›'],
      showCounter: true,
      close: true,
      closeText: '×',
      widthRatio: 0.9,
      heightRatio: 0.9,
      disableRightClick: true,
      enableKeyboard: true
    });
  });
</script>

<style>
.best-photos-gallery {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
  margin: 2rem 0;
}

.best-photos-gallery .gallery-item {
  display: block;
  overflow: hidden;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  aspect-ratio: 1;
}

.best-photos-gallery .gallery-item:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

.best-photos-gallery img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
  transition: transform 0.3s ease;
}

.best-photos-gallery .gallery-item:hover img {
  transform: scale(1.05);
}

/* Responsive adjustments */
@media (max-width: 768px) {
  .best-photos-gallery {
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 1rem;
    margin: 1rem 0;
  }
}

@media (max-width: 480px) {
  .best-photos-gallery {
    grid-template-columns: repeat(2, 1fr);
    gap: 0.75rem;
  }
}

/* Lightbox customizations */
.sl-overlay {
  background: rgba(0, 0, 0, 0.9);
}

.sl-navigation button {
  font-size: 2rem;
  color: white;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  border-radius: 50%;
  width: 50px;
  height: 50px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.3s ease;
}

.sl-navigation button:hover {
  background: rgba(255, 255, 255, 0.2);
}

.sl-close {
  font-size: 2rem;
  color: white;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  border-radius: 50%;
  width: 50px;
  height: 50px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.3s ease;
}

.sl-close:hover {
  background: rgba(255, 255, 255, 0.2);
}

.sl-counter {
  color: white;
  font-size: 1rem;
  background: rgba(0, 0, 0, 0.5);
  padding: 0.5rem 1rem;
  border-radius: 20px;
}
</style>