module SimpleStrongParams
  class StrongParams
    attr_writer :non_model_namespaces, :default_added_params, :default_removed_params
    attr_reader :injected_params, :injected_class, :fetched, :extra_options, :attrs, :add_params, :remove_params
    attr_accessor :model_params, :model_string, :model_name

    def initialize(params, klass, user, options = {})
      @injected_user = user
      @injected_params = params
      @injected_class = klass
      @prescribed_options = [:model_string, :model_name, :add_params, :remove_params, :attrs, :fetch, :permit_all, :permit]
      @model_string = options[:model_string]
      @model_name = options[:model_name]
      @attrs = options[:attrs]
      @add_params = options[:add_params].presence || []
      @remove_params = options[:remove_params].presence || []
      @fetched = options[:fetch]
      @permit_all = options[:permit_all]
      @extra_options = options.except(*@prescribed_options)
      @empty_options = options.empty?
      @permit_hash = options[:permit] || {}
      @default_removed_params = klass.default_removed_params.presence
      @default_added_params = klass.default_added_params.presence
      @non_model_namespaces = klass.non_model_namespaces.presence
    end

    def determine_strong_params
      return simple_strong_params if empty_options?
      return get_simple_params if extra_options?
      determine_model_string_and_name
      columns = create_attributes_to_permit
      symbolized_model_name = model_string.underscore.to_sym

      if fetched
        fetched_key = fetched_key? ? fetched : symbolized_model_name
        self.model_params = injected_params.fetch(fetched_key, {})
      end
      self.model_params ||= injected_params.require(symbolized_model_name)
      permit_all? ? model_params.permit! : model_params.permit(*columns)
    end

    def empty_options?
      @empty_options
    end

    def extra_options?
      @extra_options.present?
    end

    def no_extra_options?
      !extra_options?
    end

    def permit_all?
      @permit_all
    end

    def fetched_key?
      injected_params.key?(fetched)
    end

    def determine_model_string_and_name
      self.model_string ||= model_name.name.underscore.gsub("/","_") if model_name
      self.model_string ||= injected_params[:controller].include?("/") ? find_model_string : injected_class.controller_name.classify
      self.model_name ||= get_model_name(model_string.to_s.classify)
    end

    def simple_params?
      get_simple_params
    end

    def get_simple_params
      return if no_extra_options?
      built_up_params = nil
      extra_options.each do |key, attrs|
        built_up_params = simple_params(key, attrs)
      end
      built_up_params
    end

    def create_attributes_to_permit
      attrs || (params_to_permit + add_params - remove_params)
    end

    def simple_params(key, attrs = [])
      injected_params.require(key).permit(*attrs)
    end

    def simple_strong_params
      self.model_string ||= injected_params[:controller].include?("/") ? find_model_string : injected_class.controller_name.classify
      self.model_name ||= get_model_name(model_string.classify)
      injected_params.require(model_string.underscore.to_sym).permit(*params_to_permit)
    end

    def find_model_string(custom_namespaces = [])
      namespaces = custom_namespaces.presence || non_model_namespaces
      name = injected_class.class.name.chomp("Controller")
      namespaces.each {|namespace| name = name.gsub((namespace + "::"), "") if name.include?(namespace)}
      name.classify
    end

    def get_model_name(name)
      begin
        name.constantize
      rescue NameError
        return false
      end
    end

    def params_to_permit(model = nil)
      model ||= model_name
      model.column_names - default_removed_params + default_added_params
    end

    def nested_params_to_permit(model)
      params_to_permit(model) + ["_destroy", "id"]
    end

    def default_removed_params
      @default_removed_params ||= ["id", "created_at", "updated_at"]
    end

    def default_added_params
      @default_added_params ||= []
    end

    def non_model_namespaces
      @non_model_namespaces ||= []
    end
  end
end
