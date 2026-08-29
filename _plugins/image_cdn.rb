# frozen_string_literal: true

# Netlify Image CDN URLs for library images — phase 3 of the image CMS.
#
# `/.netlify/images?url=<path>&w=<width>` serves a resized, format-negotiated
# (AVIF/WebP per Accept header), EXIF-stripped derivative of a deployed
# asset, generated on demand and cached at the edge. The full-res originals
# stay deployed as the CDN's source of truth but no page links to them, so
# visitors get ~200KB variants instead of multi-MB originals (and the GPS
# EXIF in the originals stops being one click away).
#
# The endpoint only exists on Netlify, so the transform is a passthrough
# everywhere else (local `jekyll serve` keeps working against the raw
# files). Detection: the NETLIFY env var Netlify sets in builds, or
# `image_cdn: force: true` in _config.yml for testing the URLs locally.
#
# Liquid filters (used by photos_stream.html, photo.html, head.html):
#   {{ photo.image | cdn_image: 1280 }}
#     → one derivative URL at the given width
#   {{ photo.image | cdn_srcset: photo.width, 2400 }}
#     → a srcset ladder, capped at min(original width, display cap) so the
#       CDN is never asked to upscale; empty string when the CDN is off
#       (callers omit the attribute).
#
# image_embeds.rb calls ImageCDN directly for the same treatment.

require 'erb'

module ImageCDN
  # Widths offered across all surfaces; per-call caps trim the ladder.
  LADDER = [480, 640, 960, 1280, 1600, 2048, 2560, 3200].freeze

  def self.enabled?(site)
    return @enabled unless @enabled.nil?

    @enabled = ENV['NETLIFY'] == 'true' || !!site.config.dig('image_cdn', 'force')
  end

  def self.url(site, src, width)
    return src.to_s unless enabled?(site)

    "/.netlify/images?url=#{ERB::Util.url_encode(src.to_s)}&w=#{width.to_i}"
  end

  def self.srcset(site, src, original_width = nil, cap = nil)
    return '' unless enabled?(site)

    limit = [original_width, cap].compact.map(&:to_i).reject(&:zero?).min
    widths = LADDER.dup
    if limit
      widths = (widths + [limit]).uniq.select { |w| w <= limit }.sort
    end
    widths.map { |w| "#{url(site, src, w)} #{w}w" }.join(', ')
  end

  module Filters
    def cdn_image(src, width)
      ImageCDN.url(@context.registers[:site], src, width)
    end

    def cdn_srcset(src, original_width = nil, cap = nil)
      ImageCDN.srcset(@context.registers[:site], src, original_width, cap)
    end
  end
end

Liquid::Template.register_filter(ImageCDN::Filters)
