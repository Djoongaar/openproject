#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects::ActsAsCustomizablePatches
  extend ActiveSupport::Concern

  attr_accessor :_limit_custom_fields_validation_to_section_id, :_query_available_custom_fields_on_global_level

  # attr_accessor :_limit_custom_fields_validation_to_field_id
  # not needed for now, but might be relevant if we want to have edit dialogs just for one custom field

  included do
    has_many :project_custom_field_project_mappings, class_name: "ProjectCustomFieldProjectMapping", foreign_key: :project_id,
                                                     dependent: :destroy, inverse_of: :project
    has_many :project_custom_fields, through: :project_custom_field_project_mappings, class_name: "ProjectCustomField"

    before_update :set_query_available_custom_fields_to_global_level

    def set_query_available_custom_fields_to_global_level
      # query the available custom fields on a global level when updating custom field values
      # in order to support implicit activation of custom fields when values are provided during an update
      self._query_available_custom_fields_on_global_level = true
    end

    def with_all_available_custom_fields
      # query the available custom fields on a global level when updating custom field values
      # in order to support implicit activation of custom fields when values are provided during an update
      self._query_available_custom_fields_on_global_level = true
      result = yield
      self._query_available_custom_fields_on_global_level = nil

      result
    end

    def available_custom_fields
      # TODO: Add caching here.
      # overrides acts_as_customizable
      # in contrast to acts_as_customizable, custom_fields are enabled per project
      # thus we need to check the project_custom_field_project_mappings
      custom_fields = ProjectCustomField
        .includes(:project_custom_field_section)
        .order("custom_field_sections.position", :position_in_custom_field_section)

      # Do not hide the invisble fields when accessing via the _query_available_custom_fields_on_global_level
      # flag. Due to the internal working of the acts_as_customizable plugin, when a project admin updates
      # the custom fields, it will clear out all the hidden fields that are not visible for them.
      # This happens because the `#ensure_custom_values_complete` will gather all the `custom_field_values`
      # and assigns them to the custom_fields association. If the `custom_field_values` do not contain the
      # hidden fields, they will be cleared from the association. The `custom_field_values` will contain the
      # hidden fields, only if they are returned from this method. Hence we should not hide them,
      # when accessed with the _query_available_custom_fields_on_global_level flag on.
      unless _query_available_custom_fields_on_global_level
        custom_fields = custom_fields.visible
      end

      # available_custom_fields is called from within the acts_as_customizable module
      # we don't want to adjust these calls, but need a way to query the available custom fields on a global level in some cases
      # thus we pass in this parameter as an instance flag implicitly here,
      # which is not nice but helps us to touch acts_as_customizable as little as possible
      #
      # additionally we provide the `global` parameter to allow querying the available custom fields on a global level
      # when we have explicit control over the call of `available_custom_fields`
      unless new_record? || _query_available_custom_fields_on_global_level
        custom_fields = custom_fields
          .where(id: project_custom_field_project_mappings.select(:custom_field_id))
          .or(ProjectCustomField.required)
      end

      custom_fields
    end

    def all_available_custom_fields
      with_all_available_custom_fields { available_custom_fields }
    end

    def custom_field_values_to_validate
      # Limit the set of available custom fields when the validation is limited to a section
      if _limit_custom_fields_validation_to_section_id
        custom_field_values.select do |cfv|
          cfv.custom_field.custom_field_section_id == _limit_custom_fields_validation_to_section_id
        end
      else
        custom_field_values
      end
    end

    # we need to query the available custom fields on a global level when updating custom field values
    # in order to support implicit activation of custom fields when values are provided during an update
    def custom_field_values=(values)
      with_all_available_custom_fields { super }
    end

    # We need to query the available custom fields on a global level when
    # trying to set a custom field which is not enabled via the API e.g. custom_field_123="foo"
    # This implies implicit activation of the disabled custom fields via the API. As a side effect,
    # we will have empty CustomValue objects created for each custom field, regardless of its
    # enabled/disabled state in the project.
    def for_custom_field_accessor(method_symbol)
      with_all_available_custom_fields { super }
    end
  end
end
