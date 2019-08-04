module ZSpec
  class Key
    def initialize(options = {})
      @sink = options[:sink]
      @key_name = options[:key_name]
    end

    def set(message)
      @sink.set(@key_name, message)
    end

    def get
      @sink.get @key_name
    end

    def incr
      @sink.incr @key_name
    end

    def decr
      @sink.decr @key_name
    end

    def clear
      @sink.clear @key_name
    end
  end
end
