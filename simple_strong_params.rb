require "simple_strong_params/lib/simple_strong_params/strong_params"
module SimpleStrongParams
  def strong_params(options = {})
    options = options.presence || strong_params_options
    SimpleStrongParams::StrongParams.new(params, self, specified_user, options).determine_strong_params
  end

  def default_removed_params
    ["id", "created_at", "updated_at"]
  end

  def specified_user
    if current_user
      @specified_user ||= current_user
    end
    @specified_user
  end

  def specified_user=(specified_user)
    # if the controller uses something other than current_user to identify user, change it with this method
    @specified_user=specified_user
  end

  def default_added_params
    []
  end

  def strong_params_options
    # if the options list gets too long, break it out into this method which then gets called
    # by the strong_params method in the controller. options must match those in strong_params method
    # or a hash of param keys and the the attrs they are to permit
    {}
  end

  def strong_params!(key = nil)
   key ? params.require(key).permit! : strong_params({:permit_all => true})
  end

  def permitted_params(model_name)
    # use this method when _strong_params is not fine grained enough
    model_name.column_names - default_removed_params + default_added_params
  end

  def nested_destroy(model_name)
    # (:id, "id")etc. allows for variations in how we have written existing tests
    # use this when nested attributes are needed and you need to be able to destroy objects
    permitted_params(model_name) + ["_destroy", :_destroy, "id", :id]
  end
end
