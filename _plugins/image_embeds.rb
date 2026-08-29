# frozen_string_literal: true

# Library image embeds — the "insert from media library" half of the image
# CMS (see image_library.rb for the library itself).
#
# In a note or page, `![[img:<slug>]]` embeds the library image with that
# slug (the record's filename in _images/, i.e. the image's permanent ID),
# rendered as a <figure> that links through to the image's /photos/<slug>/
# page, with real dimensions (no layout shift), lazy loading, and alt/caption
# from the record. `![[img:<slug>|caption]]` overrides the record's caption
# for that one embed, Obsidian-alias style.
#
# Runs at :high priority so embeds are final HTML before
# BidirectionalLinksGenerator gets to the surrounding wikilinks. An unknown
# slug drops the embed and warns, so a typo can't break the build — same
# graceful degradation as readwise_transclusion.

require 'cgi'

module Jekyll
  class ImageEmbedsGenerator < Generator
    safe true
    priority :high

    EMBED_RE = /!\[\[img:([^\]|]+)(?:\|([^\]]*))?\]\]/

    def generate(site)
      images = site.collections['images']
      return unless images

      index = {}
      images.docs.each { |doc| index[File.basename(doc.path, '.md')] = doc }

      targets = (site.collections['notes']&.docs || []) + site.pages
      targets.each do |doc|
        next unless doc.content&.match?(EMBED_RE)

        doc.content = doc.content.gsub(EMBED_RE) do
          slug = Regexp.last_match(1).strip
          caption = Regexp.last_match(2)&.strip
          record = index[slug]
          if record
            render_figure(site, record, caption)
          else
            Jekyll.logger.warn 'ImageEmbeds:',
                               "#{doc.relative_path}: no library record for '#{slug}' — dropping the embed"
            ''
          end
        end
      end
    end

    private

    # What clicking an embedded figure does — `image_embeds.click` in
    # _config.yml: 'none' (not clickable), 'lightbox' (overlay scoped to the
    # post's images, assets/js/library-lightbox.js), 'page' (the image's
    # /photos/<slug>/ page).
    CLICK_MODES = %w[none lightbox page].freeze

    def click_mode(site)
      mode = (site.config.dig('image_embeds', 'click') || 'none').to_s
      return mode if CLICK_MODES.include?(mode)

      Jekyll.logger.warn 'ImageEmbeds:', "Unknown image_embeds.click '#{mode}' — using 'none'"
      'none'
    end

    def render_figure(site, record, caption_override)
      data = record.data
      baseurl = site.config['baseurl'].to_s
      alt = data['alt'] || data['title'] || ''
      caption = caption_override.to_s.empty? ? data['caption'] : caption_override
      width = data['width']
      height = data['height']

      # CDN derivatives sized for the 720px note column (passthrough to the
      # original outside Netlify — see image_cdn.rb).
      src = "#{baseurl}#{ImageCDN.url(site, data['image'], 960)}"
      srcset = ImageCDN.srcset(site, data['image'], width, 1440)
      srcset_attrs = srcset.empty? ? '' : %( srcset="#{CGI.escapeHTML(srcset)}" sizes="(max-width: 720px) 100vw, 720px")

      size_attrs = width && height ? %( width="#{width}" height="#{height}") : ''
      caption_html = caption.to_s.empty? ? '' : "\n  <figcaption>#{CGI.escapeHTML(caption.to_s)}</figcaption>"
      img = %(<img src="#{CGI.escapeHTML(src)}"#{srcset_attrs} alt="#{CGI.escapeHTML(alt.to_s)}" loading="lazy"#{size_attrs}>)

      body = case click_mode(site)
             when 'page'
               %(<a href="#{baseurl}#{record.url}" class="internal-link">#{img}</a>)
             when 'lightbox'
               # href is a large derivative: the lightbox displays it, and
               # no-JS visitors get the image directly. Capped at the
               # original's width so the CDN never upscales.
               large = "#{baseurl}#{ImageCDN.url(site, data['image'], [2048, width].compact.min)}"
               %(<a href="#{CGI.escapeHTML(large)}" class="internal-link" data-lightbox>#{img}</a>)
             else
               img
             end

      <<~HTML

        <figure class="library-image">
          #{body}#{caption_html}
        </figure>

      HTML
    end
  end
end
