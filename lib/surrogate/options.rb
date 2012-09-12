class Surrogate
  class Options
    attr_accessor :options, :default_proc

    def initialize(options, default_proc)
      self.options, self.default_proc = options, default_proc
    end

    def has?(name)
      options.has_key? name
    end

    def [](key)
      options[key]
    end

    def to_hash
      options
    end

    # it would be much better to pass instance to initialize
    def default(instance, invocation, &no_default)
      if options.has_key? :default
        options[:default]
      elsif default_proc
        default_proc_as_method_on(instance).call(*invocation.args, &invocation.block)
      else
        no_default.call
      end
    end

    private

    def default_proc_as_method_on(instance)
      unique_name = "surrogate_temp_method_#{Time.now.to_i}_#{rand 10000000}"
      klass = instance.singleton_class
      klass.__send__ :define_method, unique_name, &default_proc
      as_method = klass.instance_method unique_name
      klass.__send__ :remove_method, unique_name
      as_method.bind instance
    end
  end
end

