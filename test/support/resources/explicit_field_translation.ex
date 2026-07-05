# SPDX-FileCopyrightText: 2020 ash_graphql contributors <https://github.com/ash-project/ash_graphql/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshGraphql.Test.ExplicitFieldTranslation do
  @moduledoc false

  use Ash.Resource,
    domain: AshGraphql.Test.Domain,
    data_layer: Ash.DataLayer.Ets

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:explicit_field_code, :name])
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :explicit_field_code, :string do
      allow_nil?(false)
    end

    attribute :name, :string do
      allow_nil?(false)
    end
  end
end
