# frozen_string_literal: true

require "cgi"

# Wires the cocktail <-> cabinet database together at BUILD time.
#
# In the Obsidian vault, cocktails and cabinet bottles cross-reference each
# other through an Obsidian *Bases* view (`Cocktails.base`). A cabinet note
# embeds the drinks that use it with
#
#     ## Cocktails Using This
#
#     ![[Cocktails.base#By Ingredient]]
#
# and a cocktail note embeds its siblings with
#
#     ## Variants
#
#     ![[Cocktails.base#Variants]]
#
# Bases views are an Obsidian-only feature — on the published site those embeds
# are dead text. This generator reconstructs both pivots from the notes'
# frontmatter so the website has the same cross-linking the vault does, without
# adding anything Bases- or site-specific to the vault.
#
# What it does, once per build:
#   1. Indexes every note tagged `cocktails` and every note tagged `cabinet`.
#   2. Resolves each cocktail's `ingredients` wikilinks to cabinet notes, and
#      records the reverse ("which cocktails use this bottle") on each bottle.
#   3. Groups cocktails into families by their `type` (e.g. all Manhattans),
#      giving each cocktail its list of variants.
#   4. Decorates every note with display-ready data (clean name, category,
#      stock status, resolved ingredient/similar links) for the layouts.
#   5. Replaces the `![[Cocktails.base#...]]` embeds with the generated lists —
#      dropping the introducing heading when a pivot is empty, so no bare
#      "## Variants" section is left behind.
#
# Runs at :high priority so it executes before BidirectionalLinksGenerator:
# the lists it injects are already plain HTML anchors, and any *other*
# wikilinks in the note (e.g. "Used in: [[Bensonhurst]]") are left for that
# generator to resolve as usual.
module CocktailCabinet
  # The Bases embed, optionally introduced by a heading.
  #   group 1 (lead)    : start-of-string or the newline before the block
  #   group 2 (heading) : optional "## Heading\n\n" that only exists to intro
  #                       the embed — captured so it can be dropped with the
  #                       embed when the pivot is empty.
  #   group 3 (section) : the Bases view name ("By Ingredient" / "Variants")
  BASE_EMBED = /(\A|\n)?([ \t]*[#]{1,6}[ \t]*[^\n]*\n\s*\n)?[ \t]*!\[\[Cocktails\.base[#]([^\]]+)\]\][ \t]*/

  class Generator < Jekyll::Generator
    priority :high

    def generate(site)
      collection = site.collections["notes"]
      return unless collection

      cocktails = collection.docs.select { |d| cocktail?(d) }
      cabinet   = collection.docs.select { |d| cabinet?(d) }
      return if cocktails.empty? && cabinet.empty?

      # name -> note lookups (by cleaned filename and by title)
      @cabinet_by_key  = {}
      @cocktail_by_key = {}
      cabinet.each  { |d| keys_for(d).each { |k| @cabinet_by_key[k]  ||= d } }
      cocktails.each { |d| keys_for(d).each { |k| @cocktail_by_key[k] ||= d } }

      # Decorate bottles first (cocktails push themselves onto bottles' lists).
      cabinet.each  { |d| decorate_cabinet(d) }
      cocktails.each { |d| decorate_cocktail(d) }

      # Families: cocktails sharing a normalized `type` are variants of each
      # other (the Manhattan family, the Negroni family, ...).
      families = Hash.new { |h, k| h[k] = [] }
      cocktails.each do |d|
        key = d.data["family_key"]
        families[key] << d if key && !key.empty?
      end
      cocktails.each do |d|
        sibs = families[d.data["family_key"]] || []
        d.data["variants"] = sibs.reject { |x| x.equal?(d) }
                                 .sort_by { |x| x.data["display_name"].to_s.downcase }
      end

      # Sort/dedupe the reverse pivot on each bottle.
      cabinet.each do |d|
        d.data["cocktails"] = Array(d.data["cocktails"]).uniq
                                   .sort_by { |c| c.data["display_name"].to_s.downcase }
      end

      # Bake the embeds now that both pivots are populated.
      cabinet.each  { |d| bake(d, d.data["cocktails"]) }
      cocktails.each { |d| bake(d, d.data["variants"]) }
    end

    private

    # --- classification -----------------------------------------------------

    def cocktail?(doc)
      Array(doc.data["tags"]).map(&:to_s).include?("cocktails")
    end

    def cabinet?(doc)
      Array(doc.data["tags"]).map(&:to_s).include?("cabinet")
    end

    # --- decoration ---------------------------------------------------------

    def decorate_cabinet(doc)
      name = clean_bottle_name(base(doc))
      doc.data["display_name"] = name
      doc.data["title"] ||= name

      category = doc.data["type"].to_s.strip
      doc.data["category"] = category.empty? ? "Other" : category

      doc.data["stock_nyc"] = present(doc.data["nyc"])
      doc.data["stock_ri"]  = present(doc.data["ri"])
      doc.data["stocked"]   = stocked?(doc)
      doc.data["cocktails"] ||= []

      doc.data["similar_links"] = Array(doc.data["similar"]).map do |raw|
        resolve_ref(raw, @cabinet_by_key)
      end
    end

    def decorate_cocktail(doc)
      name = clean_cocktail_name(base(doc))
      doc.data["display_name"] = name
      doc.data["title"] ||= name

      # Family (the `type` wikilink — Manhattan, Negroni, ...).
      raw_type = Array(doc.data["type"]).first
      fam = link_name(raw_type)
      unless fam.empty?
        doc.data["family_display"] = clean_cocktail_name(fam)
        doc.data["family_key"] = normalize(fam)
        parent = @cocktail_by_key[normalize(fam)]
        doc.data["family_url"] = parent.url if parent && !parent.equal?(doc)
      end

      # Ingredients -> cabinet bottles (and the reverse pivot).
      doc.data["ingredient_links"] = Array(doc.data["ingredients"]).map do |raw|
        display = link_name(raw)
        note = @cabinet_by_key[normalize(display)]
        if note
          note.data["cocktails"] ||= []
          note.data["cocktails"] << doc
          {
            "name"    => note.data["display_name"] || display,
            "url"     => note.url,
            "stocked" => stocked?(note),
          }
        else
          { "name" => display, "url" => nil, "stocked" => false }
        end
      end
    end

    # Resolve a wikilink to { name, url } against a lookup, falling back to the
    # bare name when no note exists.
    def resolve_ref(raw, lookup)
      display = link_name(raw)
      note = lookup[normalize(display)]
      {
        "name" => note ? (note.data["display_name"] || display) : display,
        "url"  => note&.url,
      }
    end

    # --- embed baking -------------------------------------------------------

    def bake(doc, list)
      return unless doc.content.include?("Cocktails.base#")

      doc.content = doc.content.gsub(BASE_EMBED) do
        lead    = Regexp.last_match(1).to_s
        heading = Regexp.last_match(2).to_s
        html    = render_links(list)
        html ? "#{lead}#{heading}#{html}" : lead
      end
    end

    # A plain-HTML list of note links, or nil when empty. Emitted as raw block
    # HTML so kramdown passes it through untouched; the anchors are final, so
    # they're immune to the later wikilink pass.
    def render_links(list)
      list = Array(list)
      return nil if list.empty?

      items = list.map do |d|
        label = CGI.escapeHTML(d.data["display_name"].to_s)
        %(<li><a class="internal-link" href="#{d.url}">#{label}</a></li>)
      end.join
      "\n<ul class=\"cocktail-pivot\">#{items}</ul>\n"
    end

    # --- helpers ------------------------------------------------------------

    # Filename without extension.
    def base(doc)
      File.basename(doc.basename, File.extname(doc.basename))
    end

    # Lookup keys for a note: cleaned filename and title, normalized.
    def keys_for(doc)
      [normalize(base(doc)), normalize(doc.data["title"])].reject(&:empty?).uniq
    end

    # The linkable name inside a wikilink. Handles a display alias
    # (`[[path|Alias]]` -> "Alias") and a vault path (`[[a/b/Name]]` -> "Name").
    def link_name(raw)
      s = raw.to_s.gsub(/\A\[\[|\]\]\z/, "").strip
      s = s.split("|", 2).last.to_s.strip if s.include?("|")
      s = s.split("/").last.to_s.strip if s.include?("/")
      s
    end

    # Lowercase, non-alphanumerics to spaces, collapse — so "Rye whiskey",
    # "rye-whiskey" and "🥃 Rye Whiskey" all match.
    def normalize(str)
      str.to_s.downcase.gsub(/[^a-z0-9]+/, " ").strip
    end

    # Drop a leading emoji/symbol run from a bottle name ("🍌 Banana" -> "Banana").
    def clean_bottle_name(str)
      str.to_s.sub(/\A[^\p{Alnum}(\[]+/u, "").strip
    end

    # Cocktail display name: drop a leading emoji and a trailing "cocktail"
    # qualifier ("Manhattan cocktail" -> "Manhattan", "Brooklyn (cocktail)" ->
    # "Brooklyn").
    def clean_cocktail_name(str)
      clean_bottle_name(str).sub(/\s*\(cocktail\)\s*\z/i, "").sub(/\s+cocktail\s*\z/i, "").strip
    end

    def present(val)
      s = val.to_s.strip
      s.empty? ? nil : s
    end

    def stocked?(doc)
      present(doc.data["nyc"]) || present(doc.data["ri"]) ? true : false
    end
  end
end
