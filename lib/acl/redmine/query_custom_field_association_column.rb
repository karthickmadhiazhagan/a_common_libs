class QueryCustomFieldAssociationColumn < QueryCustomFieldColumn
  attr_accessor :target_class, :target_key, :attribute

  def initialize(custom_field, attribute, target_class, target_key, options={})
    self.name = "ldap_cf_#{custom_field.id}_#{attribute}".to_sym
    @attribute = attribute
    @target_class = target_class
    @target_key = target_key

    self.sortable = options[:sortable] || false
    if self.sortable
      self.sortable = "ldap_cf_#{custom_field.id}_#{attribute}.#{self.sortable}"
    end
    self.groupable = false
    if options[:groupable] && self.sortable
      self.groupable = self.sortable
    end
    self.totalable = false
    @caption_key = options[:caption] || "field_#{name}".to_sym
    @inline = true
    @cf = custom_field
  end

  def caption
    l(:label_acl_attribute_of_user, name: @cf.name, object_name: @caption_key)
  end

  def value_object(object)
    cv = super(object)

    if cv.present?
      if cv.is_a?(Array)
        cv.map { |r| a = @cf.cast_value(r.value); a.present? ? a.send(@attribute) : nil }.compact
      elsif cv
        cv = @cf.cast_value(cv.value)
        cv.present? ? cv.send(@attribute) : nil
      else
        nil
      end
    end
  end

  def value(object)
    v = self.value_object(object)
    return nil if v.nil?
    if v.is_a?(Array)
      v.map { |it| it.to_s }
    else
      v.to_s
    end
  end

  def css_classes
    super + "-#{@attribute}"
  end
end