# frozen_string_literal: true

require 'dotenv/load'

Jekyll::Hooks.register :site, :after_init, priority: :high do |site|
  site.config['env'] = ENV.to_h

  split_keys =
    site.config['env'].map do |key, value|
      key.downcase.split('.').reverse.inject(value) do |v, h|
        { h => v }
      end
    end

  merged_keys =
    split_keys.reduce do |m, c|
      Jekyll::Utils.deep_merge_hashes m, c
    end

  site.config.merge merged_keys
end
