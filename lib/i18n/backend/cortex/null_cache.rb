module I18n
  module Backend
    class Cortex
      class NullCache
        def fetch(*args)
          yield
        end

        def read(key)
        end

        def write(key, value)
          value
        end
      end
    end
  end
end
