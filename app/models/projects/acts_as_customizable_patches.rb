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

  attr_accessor :_limit_custom_fields_validation_to_section_id

  # attr_accessor :_limit_custom_fields_validation_to_field_id
  # not needed for now, but might be relevant if we want to have edit dialogs just for one custom field

  included do
    has_many :project_custom_field_project_mappings, class_name: "ProjectCustomFieldProjectMapping", foreign_key: :project_id,
                                                     dependent: :destroy, inverse_of: :project
    has_many :project_custom_fields, through: :project_custom_field_project_mappings, class_name: "ProjectCustomField"

    def available_custom_fields(active: false)
      available_custom_fields = ProjectCustomField
        .includes(:project_custom_field_section)
        .order("custom_field_sections.position", :position_in_custom_field_section)

      if active
        available_custom_fields =
          available_custom_fields
            .visible
            .where(id: project_custom_field_project_mappings.select(:custom_field_id))
            .or(ProjectCustomField.required)
      end

      available_custom_fields
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
  end
end
