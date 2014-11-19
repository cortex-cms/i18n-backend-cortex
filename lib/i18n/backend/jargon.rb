require 'i18n'
require 'i18n/backend/transliterator'
require 'i18n/backend/base'
require 'gem_of_thrones'
require 'i18n/backend/jargon/version'
require 'i18n/backend/jargon/configuration'
require 'i18n/backend/jargon/etag_http_client'
require 'i18n/backend/jargon/null_cache'
require 'i18n/backend/jargon/lru_cache'

module I18n
  module Backend
    class Jargon
      include ::I18n::Backend::Base

      def self.initialized?
        @initialized ||= false
      end

      def self.stop_polling
        @stop_polling = true
      end

      def self.reload!
        @initialized = false
        @translations = nil
      end

      def self.available_locales
        init_translations unless initialized?
        download_localization
        @available_locales
      end

      def self.locale_path(locale)
        localization_path + "/#{locale}"
      end

      def self.localization_path
        "api/uuid/#{@config.uuid}"
      end

      protected

      def self.init_translations
        @http_client = EtagHttpClient.new(@config)
        @translations = LRUCache.new(@config[:memory_cache_size])
        start_polling if @config[:poll]
        @initialized = true
      end

      def self.start_polling
        Thread.new do
          until @stop_polling
            sleep(@config[:polling_interval])
            update_caches
          end
        end
      end

      def self.lookup(locale, key, scope = [], options = {})
        init_translations unless initialized?
        key = ::I18n.normalize_keys(locale, key, scope, options[:separator])[1..-1].join('.')
        lookup_key translations(locale), key
      end

      def self.translate(locale, key, options = {})
        raise InvalidLocale.new(locale) unless locale
        entry = key && lookup(locale, key, options[:scope], options)

        if options.empty?
          entry = resolve(locale, key, entry, options)
        else
          count, default = options.values_at(:count, :default)
          values = options.except(*RESERVED_KEYS)
          entry = entry.nil? && default ?
            default(locale, key, default, options) : resolve(locale, key, entry, options)
        end

        throw(:exception, I18n::MissingTranslation.new(locale, key, options)) if entry.nil?
        entry = entry.dup if entry.is_a?(String)

        entry = pluralize(locale, entry, count) if count
        entry = interpolate(locale, entry, values) if values
        entry
      end

      def self.resolve(locale, object, subject, options = {})
        return subject if options[:resolve] == false
        result = catch(:exception) do
          case subject
            when Symbol
              I18n.translate(subject, options.merge(:locale => locale, :throw => true))
            when Proc
              date_or_time = options.delete(:object) || object
              resolve(locale, object, subject.call(date_or_time, options))
            else
              subject
          end
        end
        result unless result.is_a?(MissingTranslation)
      end

      def self.translations(locale)
        @translations[locale] = (
          translations_from_cache(locale) ||
          download_and_cache_translations(locale)
        )
      end

      def self.update_caches
        @translations.keys.each do |locale|
          if @config[:cache].is_a?(NullCache)
            download_and_cache_translations(locale)
          else
            locked_update_cache(locale)
          end
        end
      end

      def self.locked_update_cache(locale)
        @aspirants ||= {}
        aspirant = @aspirants[locale] ||= GemOfThrones.new(
          :cache => @config[:cache],
            :timeout => (@config[:polling_interval] * 3).ceil,
            :cache_key => "i18n/backend/http/locked_update_caches/#{locale}"
        )
        if aspirant.rise_to_power
          download_and_cache_translations(locale)
        else
          update_memory_cache_from_cache(locale)
        end
      end

      def self.update_memory_cache_from_cache(locale)
        @translations[locale] = translations_from_cache(locale)
      end

      def self.translations_from_cache(locale)
        @config[:cache].read(cache_key(locale))
      end

      def self.cache_key(locale)
        "i18n/backend/http/translations/#{locale}"
      end

      def self.download_and_cache_translations(locale)
        @http_client.download(locale_path(locale)) do |result|
          translations = parse_locale(result)
          @config[:cache].write(cache_key(locale), translations)
          @translations[locale] = translations
        end
      rescue => e
        @config[:exception_handler].call(e)
        @translations[locale] = {} # do not write distributed cache
      end

      def self.download_localization
        @http_client.download(localization_path) do |result|
          @available_locales = parse_localization(result)
        end
      end

      def self.parse_locale(body)
        JSON.load(body)['locale']['data']
      end

      def self.parse_localization(body)
        JSON.load(body)['localization']['available_locales']
      end

      # hook for extension with other resolution method
      def self.lookup_key(translations, key)
        translations[key]
      end
    end
  end
end
