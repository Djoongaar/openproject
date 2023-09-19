# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'
require 'contracts/shared/model_contract_shared_context'

RSpec.shared_examples_for 'meeting is not readable' do
  let(:user) { build_stubbed(:user) }
  let(:meeting) { build_stubbed(:structured_meeting) }
  let(:item) { build_stubbed(:meeting_agenda_item, meeting:) }
  let(:contract) { described_class.new(item, user) }

  context 'when :meeting is not editable' do
    let(:meeting) { build_stubbed(:structured_meeting, state: :closed) }

    it_behaves_like 'contract is invalid', base: I18n.t(:text_meeting_not_editable_anymore)
  end
end
