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

    def render_figure(site, record, caption_override)
      data = record.data
      baseurl = site.config['baseurl'].to_s
      src = "#{baseurl}#{data['image']}"
      alt = data['alt'] || data['title'] || ''
      caption = caption_override.to_s.empty? ? data['caption'] : caption_override
      width = data['width']
      height = data['height']

      size_attrs = width && height ? %( width="#{width}" height="#{height}") : ''
      caption_html = caption.to_s.empty? ? '' : "\n  <figcaption>#{CGI.escapeHTML(caption.to_s)}</figcaption>"

      <<~HTML

        <figure class="library-image">
          <a href="#{baseurl}#{record.url}" class="internal-link"><img src="#{CGI.escapeHTML(src)}" alt="#{CGI.escapeHTML(alt.to_s)}" loading="lazy"#{size_attrs}></a>#{caption_html}
        </figure>

      HTML
    end
  end
end
